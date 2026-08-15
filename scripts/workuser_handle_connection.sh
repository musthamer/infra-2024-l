#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

PROTOCOL_LOG="$LOG_DIR/protocol.log"
trap '' PIPE

respond() {
    local line="$1"
    echo "[$(date -Iseconds)] RESP $line" >> "$PROTOCOL_LOG"
    printf '%s\n' "$line" || true
}

read -r request_line || {
    respond 'ERR|V1|EMPTY|No request'
    exit 0
}

echo "[$(date -Iseconds)] REQ $request_line" >> "$PROTOCOL_LOG"

IFS='|' read -r version command job_id payload extra <<< "$request_line"

if [ "$version" != "V1" ]; then
    respond "ERR|V1|${job_id:-UNKNOWN}|Unsupported protocol version"
    exit 0
fi

if [ -n "${extra:-}" ]; then
    respond "ERR|V1|${job_id:-UNKNOWN}|Malformed request"
    exit 0
fi

if ! valid_job_id "$job_id"; then
    respond "ERR|V1|${job_id:-UNKNOWN}|Invalid job id"
    exit 0
fi

case "$command" in
    ENQUEUE_EMAIL)
        if [ -z "$payload" ] || ! printf '%s' "$payload" | grep -Eq '^[A-Za-z0-9+/=]+$'; then
            respond "ERR|V1|$job_id|Invalid payload"
            exit 0
        fi

        decoded_payload=$(printf '%s' "$payload" | base64 -d 2>/dev/null || true)
        if [ -z "$decoded_payload" ]; then
            respond "ERR|V1|$job_id|Payload decode error"
            exit 0
        fi

        escaped_job_id=$(mysql_escape_runtime "$job_id")
        escaped_payload=$(mysql_escape_runtime "$decoded_payload")

        mysql_query_raw "
            INSERT INTO email_jobs (job_id, job_type, payload, status)
            VALUES ('$escaped_job_id', 'email_login', '$escaped_payload', 'pending')
            ON DUPLICATE KEY UPDATE job_id = job_id;
        " >/dev/null 2>&1

        if [ "$?" -eq 0 ]; then
            respond "ACK|V1|$job_id|QUEUED"
        else
            respond "ERR|V1|$job_id|Database error"
        fi
        ;;
    PING)
        respond "ACK|V1|$job_id|PONG"
        ;;
    *)
        respond "ERR|V1|$job_id|Unsupported command"
        ;;
esac
