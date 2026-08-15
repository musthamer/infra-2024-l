#!/bin/bash

echo "Content-type: application/json"
echo ""

source db_config.sh

# Session-ID aus den URL-Parametern lesen
session_id=$(echo "$QUERY_STRING" | sed -n 's/^.*session_id=\([^&]*\).*$/\1/p')

if [ -n "$session_id" ]; then
    session_result=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sse "
    SELECT users.email FROM sessions
    JOIN users ON sessions.user_id = users.id
    WHERE session_id='$session_id';
    ")

    if [ "$session_result" ]; then
        user_email=$session_result
        echo '{"status":"success", "user_email":"'$user_email'"}'
    else
        echo '{"status":"error", "message":"Session ungültig oder abgelaufen"}'
    fi
else
    echo '{"status":"error", "message":"Session-ID fehlt"}'
fi
