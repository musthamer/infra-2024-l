#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/db_config.sh"

if [ "${REQUEST_METHOD:-GET}" = "POST" ]; then
    read_request_body >/dev/null
fi

session_id=$(get_cookie_value session_id)
if [ -z "$session_id" ]; then
    session_id=$(get_request_param_any session_id || true)
fi

if [ -n "$session_id" ]; then
    escaped_session_id=$(sql_escape "$session_id")

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "
        DELETE FROM sessions WHERE session_id = '$escaped_session_id';
    " >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Content-type: application/json"
        echo "Set-Cookie: session_id=; Path=$APP_COOKIE_PATH; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Lax"
        echo ""
        print_json "success" "Abmeldung erfolgreich"
    else
        print_json_header "500 Internal Server Error"
        print_json "error" "Fehler beim Löschen der Session"
    fi
else
    print_json_header "401 Unauthorized"
    print_json "error" "Keine gültige Sitzung gefunden"
fi
