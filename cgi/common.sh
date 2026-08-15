#!/bin/bash

APP_COOKIE_PATH="${APP_COOKIE_PATH:-/}"
SESSION_TTL_SECONDS="${SESSION_TTL_SECONDS:-28800}"

if ! printf '%s' "$SESSION_TTL_SECONDS" | grep -Eq '^[0-9]+$'; then
    SESSION_TTL_SECONDS=28800
fi

REQUEST_BODY_CACHE=""
REQUEST_BODY_LOADED=0

json_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//"/\\"}
    value=${value//$'\n'/ }
    value=${value//$'\r'/ }
    printf '%s' "$value"
}

url_decode() {
    local value="${1//+/ }"
    printf '%b' "${value//%/\\x}"
}

parse_query_string() {
    local query="$1"
    local pair key value

    IFS='&' read -r -a pairs <<< "$query"
    for pair in "${pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        key=$(url_decode "$key")
        value=$(url_decode "$value")
        if printf '%s' "$key" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
            printf -v "$key" '%s' "$value"
        fi
    done
}

print_json() {
    local status="$1"
    local message="$2"

    printf '{"status":"%s","message":"%s"}\n' "$(json_escape "$status")" "$(json_escape "$message")"
}

print_json_header() {
    local status_line="${1:-}"
    if [ -n "$status_line" ]; then
        echo "Status: $status_line"
    fi
    echo "Content-type: application/json"
    echo ""
}

print_json_error_and_exit() {
    local status_line="$1"
    local message="$2"

    print_json_header "$status_line"
    print_json "error" "$message"
    exit 0
}

sql_escape() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//\'/\'\'}
    printf '%s' "$value"
}

get_cookie_value() {
    local cookie_name="$1"
    local cookie_line

    cookie_line=$(printf '%s' "${HTTP_COOKIE:-}" | tr ';' '\n' | sed 's/^ *//' | grep "^${cookie_name}=" || true)
    printf '%s' "$cookie_line" | cut -d '=' -f 2-
}

get_request_param() {
    local param_name="$1"
    local query="${QUERY_STRING:-}"
    local pair key value

    IFS='&' read -r -a pairs <<< "$query"
    for pair in "${pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        key=$(url_decode "$key")
        if [ "$key" = "$param_name" ]; then
            url_decode "$value"
            return 0
        fi
    done

    return 1
}

read_request_body() {
    if [ "$REQUEST_BODY_LOADED" -eq 1 ]; then
        printf '%s' "$REQUEST_BODY_CACHE"
        return
    fi

    if [ "${REQUEST_METHOD:-GET}" = "POST" ]; then
        REQUEST_BODY_CACHE=$(cat)
    else
        REQUEST_BODY_CACHE=""
    fi

    REQUEST_BODY_LOADED=1
    printf '%s' "$REQUEST_BODY_CACHE"
}

get_param_from_encoded_data() {
    local param_name="$1"
    local encoded_data="$2"
    local pair key value

    IFS='&' read -r -a pairs <<< "$encoded_data"
    for pair in "${pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        key=$(url_decode "$key")
        if [ "$key" = "$param_name" ]; then
            url_decode "$value"
            return 0
        fi
    done

    return 1
}

get_request_param_any() {
    local param_name="$1"
    local method="${REQUEST_METHOD:-GET}"
    local body

    if [ "$method" = "POST" ]; then
        read_request_body >/dev/null
        body="$REQUEST_BODY_CACHE"
        if get_param_from_encoded_data "$param_name" "$body"; then
            return 0
        fi
    fi

    get_request_param "$param_name"
}

require_session_email() {
    local session_id
    local escaped_session_id
    local session_result
    local query_rc
    local query_err_file

    session_id=$(get_cookie_value session_id)
    if [ -z "$session_id" ]; then
        return 1
    fi

    escaped_session_id=$(sql_escape "$session_id")
    query_err_file=$(mktemp)
    session_result=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
        SELECT users.email
        FROM sessions
        JOIN users ON users.id = sessions.user_id
        WHERE sessions.session_id = '$escaped_session_id'
          AND sessions.created_at >= (NOW() - INTERVAL $SESSION_TTL_SECONDS SECOND)
        LIMIT 1;
    " 2>"$query_err_file")
    query_rc=$?

    if [ "$query_rc" -ne 0 ]; then
        cat "$query_err_file" >&2
        rm -f "$query_err_file"
        return 2
    fi

    rm -f "$query_err_file"

    if [ -z "$session_result" ]; then
        return 1
    fi

    printf '%s' "$session_result"
}

cleanup_expired_sessions() {
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
        DELETE FROM sessions
        WHERE created_at < (NOW() - INTERVAL $SESSION_TTL_SECONDS SECOND);
    " >/dev/null 2>&1 || true
}

require_session_or_exit() {
    local user_email
    local session_rc

    user_email=$(require_session_email)
    session_rc=$?
    if [ "$session_rc" -ne 0 ]; then
        case "$session_rc" in
            2)
                print_json_error_and_exit "500 Internal Server Error" "Database error"
                ;;
            *)
                print_json_error_and_exit "401 Unauthorized" "Unauthorized"
                ;;
        esac
    fi

    if [ -z "$user_email" ]; then
        print_json_error_and_exit "401 Unauthorized" "Unauthorized"
    fi

    REQUIRED_SESSION_EMAIL="$user_email"
}

run_mysql_query_or_exit() {
    local output_var_name="$1"
    local sql_query="$2"
    local query_output
    local query_rc
    local query_err_file

    query_err_file=$(mktemp)
    query_output=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "$sql_query" 2>"$query_err_file")
    query_rc=$?

    if [ "$query_rc" -ne 0 ]; then
        cat "$query_err_file" >&2
        rm -f "$query_err_file"
        print_json_error_and_exit "500 Internal Server Error" "Database error"
    fi

    rm -f "$query_err_file"
    printf -v "$output_var_name" '%s' "$query_output"
}

valid_email() {
    printf '%s' "$1" | grep -Eq '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$'
}

valid_mmsi() {
    printf '%s' "$1" | grep -Eq '^[0-9]{9}$'
}

valid_job_id() {
    printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_-]{8,64}$'
}

valid_unix_timestamp() {
    printf '%s' "$1" | grep -Eq '^[0-9]{1,12}$'
}

generate_password_hash() {
    local plain="$1"
    local salt

    if command -v openssl >/dev/null 2>&1; then
        salt=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
        openssl passwd -6 -salt "$salt" "$plain" 2>/dev/null
        return $?
    fi

    printf 'legacy-sha256$%s' "$(printf '%s' "$plain" | sha256sum | awk '{print $1}')"
}

verify_password_hash() {
    local plain="$1"
    local stored="$2"
    local salt recomputed

    PASSWORD_HASH_NEEDS_UPGRADE=0

    if printf '%s' "$stored" | grep -Eq '^\$6\$'; then
        salt=$(printf '%s' "$stored" | cut -d '$' -f 3)
        recomputed=$(openssl passwd -6 -salt "$salt" "$plain" 2>/dev/null || true)
        [ "$recomputed" = "$stored" ]
        return $?
    fi

    if printf '%s' "$stored" | grep -Eq '^legacy-sha256\$[0-9a-f]{64}$'; then
        recomputed=$(printf '%s' "$plain" | sha256sum | awk '{print $1}')
        if [ "legacy-sha256$recomputed" = "$stored" ]; then
            PASSWORD_HASH_NEEDS_UPGRADE=1
            return 0
        fi
        return 1
    fi

    if printf '%s' "$stored" | grep -Eq '^[0-9a-f]{64}$'; then
        recomputed=$(printf '%s' "$plain" | sha256sum | awk '{print $1}')
        if [ "$recomputed" = "$stored" ]; then
            PASSWORD_HASH_NEEDS_UPGRADE=1
            return 0
        fi
        return 1
    fi

    return 1
}

upgrade_password_hash_for_user() {
    local user_id="$1"
    local plain="$2"
    local escaped_hash
    local new_hash

    new_hash=$(generate_password_hash "$plain")
    if [ -z "$new_hash" ]; then
        return 1
    fi

    escaped_hash=$(sql_escape "$new_hash")
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
        UPDATE users
        SET password = '$escaped_hash'
        WHERE id = '$user_id'
        LIMIT 1;
    " >/dev/null 2>&1
}

generate_session_id() {
    if command -v pwgen >/dev/null 2>&1; then
        pwgen 40 1
        return
    fi

    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 20
        return
    fi

    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40
}