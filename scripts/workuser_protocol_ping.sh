#!/bin/bash
set -u

HOST="${EMAIL_QUEUE_HOST:-127.0.0.1}"
PORT="${EMAIL_QUEUE_PORT:-4000}"
JOB_ID="ping_$(date +%s)"
REQUEST="V1|PING|$JOB_ID|-"

response=""
exec 3<>"/dev/tcp/${HOST}/${PORT}" 2>/dev/null || true
if [ -e /proc/$$/fd/3 ]; then
    printf '%s\n' "$REQUEST" >&3
    IFS= read -r -t 2 response <&3 || true
    exec 3<&-
    exec 3>&-
fi

if [ -z "$response" ] && command -v ncat >/dev/null 2>&1; then
    response=$(ncat "$HOST" "$PORT" -w 2 2>/dev/null <<< "$REQUEST" || true)
fi

if [ -z "$response" ] && command -v nc >/dev/null 2>&1; then
    response=$(nc "$HOST" "$PORT" -w 2 2>/dev/null <<< "$REQUEST" || true)
fi

printf '%s\n' "$response"
