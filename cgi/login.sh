#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/db_config.sh"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/email_queue_client.sh"

if [ "${REQUEST_METHOD:-GET}" = "POST" ]; then
    read_request_body >/dev/null
fi

emailLogin=$(get_request_param_any emailLogin || true)
passwordLogin=$(get_request_param_any passwordLogin || true)

if ! valid_email "$emailLogin" || [ -z "$passwordLogin" ]; then
    print_json_header "400 Bad Request"
    print_json "error" "Invalid login data"
    exit 0
fi

cleanup_expired_sessions

escaped_email=$(sql_escape "$emailLogin")
run_mysql_query_or_exit user_row "
    SELECT id, firstname, password
    FROM users
    WHERE email = '$escaped_email'
    LIMIT 1;
"

if [ -z "$user_row" ]; then
    print_json_header "401 Unauthorized"
    print_json "error" "Fehler bei der Anmeldung"
    exit 0
fi

IFS=$'\t' read -r user_id user_firstname stored_password <<< "$user_row"

if ! verify_password_hash "$passwordLogin" "$stored_password"; then
    print_json_header "401 Unauthorized"
    print_json "error" "Fehler bei der Anmeldung"
    exit 0
fi

session_id=$(generate_session_id)
escaped_session_id=$(sql_escape "$session_id")
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
    INSERT INTO sessions (session_id, user_id)
    VALUES ('$escaped_session_id', '$user_id');
" >/dev/null 2>&1

if [ "$?" -ne 0 ]; then
    print_json_header "500 Internal Server Error"
    print_json "error" "Fehler bei der Erstellung der Sitzung"
    exit 0
fi

if [ "${PASSWORD_HASH_NEEDS_UPGRADE:-0}" -eq 1 ]; then
    upgrade_password_hash_for_user "$user_id" "$passwordLogin" || true
fi

queue_status="queued"
queue_message="queued"
if ! enqueue_login_email_job "$emailLogin" "$session_id"; then
    queue_status="failed"
    queue_message="email queue unavailable"
fi

echo "Content-type: application/json"
echo "Set-Cookie: session_id=$session_id; Path=$APP_COOKIE_PATH; HttpOnly; SameSite=Lax"
echo ""
printf '{"status":"success","message":"Login erfolgreich","user_email":"%s","email_queue":"%s","queue_message":"%s"}\n' \
    "$(json_escape "$emailLogin")" \
    "$(json_escape "$queue_status")" \
    "$(json_escape "$queue_message")"
