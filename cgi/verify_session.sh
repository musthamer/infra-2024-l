#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/db_config.sh"
source "$SCRIPT_DIR/common.sh"

cleanup_expired_sessions

session_id=$(get_cookie_value session_id)
if [ -z "$session_id" ]; then
    session_id=$(get_request_param session_id || true)
fi

if [ -z "$session_id" ]; then
    print_json_header "401 Unauthorized"
    print_json "error" "Session ungültig oder abgelaufen"
    exit 0
fi

escaped_session_id=$(sql_escape "$session_id")
run_mysql_query_or_exit session_result "
    SELECT users.email
    FROM sessions
    JOIN users ON sessions.user_id = users.id
    WHERE sessions.session_id = '$escaped_session_id'
      AND sessions.created_at >= (NOW() - INTERVAL $SESSION_TTL_SECONDS SECOND)
    LIMIT 1;
"

if [ -n "$session_result" ]; then
    print_json_header
    printf '{"status":"success","user_email":"%s"}\n' "$(json_escape "$session_result")"
else
    print_json_header "401 Unauthorized"
    print_json "error" "Session ungültig oder abgelaufen"
fi
