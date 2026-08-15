#!/bin/bash

EMAIL_QUEUE_HOST="${EMAIL_QUEUE_HOST:-127.0.0.1}"
EMAIL_QUEUE_PORT="${EMAIL_QUEUE_PORT:-4000}"

send_tcp_request() {
    local request_line="$1"
    local response=""

    exec 3<>"/dev/tcp/${EMAIL_QUEUE_HOST}/${EMAIL_QUEUE_PORT}" 2>/dev/null || true
    if [ -e /proc/$$/fd/3 ]; then
        printf '%s\n' "$request_line" >&3
        IFS= read -r -t 2 response <&3 || true
        exec 3<&-
        exec 3>&-
        printf '%s' "$response"
        return 0
    fi

    if command -v ncat >/dev/null 2>&1; then
        response=$(ncat "$EMAIL_QUEUE_HOST" "$EMAIL_QUEUE_PORT" -w 2 2>/dev/null <<< "$request_line" || true)
        printf '%s' "$response"
        return 0
    fi

    if command -v nc >/dev/null 2>&1; then
        response=$(nc "$EMAIL_QUEUE_HOST" "$EMAIL_QUEUE_PORT" -w 2 2>/dev/null <<< "$request_line" || true)
        printf '%s' "$response"
        return 0
    fi

    return 1
}

enqueue_login_email_job() {
    local email="$1"
    local session_id="$2"
    local timestamp job_id payload request_line response

    if ! valid_email "$email"; then
        return 1
    fi

    timestamp=$(date +%s)
    job_id="job_${timestamp}_$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)"
    payload=$(printf 'type=login;email=%s;session=%s;ts=%s' "$email" "$session_id" "$timestamp" | base64 -w 0)
    request_line="V1|ENQUEUE_EMAIL|$job_id|$payload"

    response=$(send_tcp_request "$request_line") || return 1

    if printf '%s' "$response" | grep -Eq "^ACK\|V1\|${job_id}\|QUEUED$"; then
        return 0
    fi

    return 1
}
