#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

job_id="test_$(date +%s)_${RANDOM}${RANDOM}"
payload=$(printf 'type=login;email=tcp-test@example.com;session=test;ts=%s' "$(date +%s)" | base64 -w 0)
request="V1|ENQUEUE_EMAIL|$job_id|$payload"

response=""
exec 3<>"/dev/tcp/${EMAIL_QUEUE_HOST}/${EMAIL_QUEUE_PORT}" 2>/dev/null || true
if [ -e /proc/$$/fd/3 ]; then
    printf '%s\n' "$request" >&3
    IFS= read -r -t 2 response <&3 || true
    exec 3<&-
    exec 3>&-
fi

if [ -z "$response" ] && command -v ncat >/dev/null 2>&1; then
    response=$(ncat "$EMAIL_QUEUE_HOST" "$EMAIL_QUEUE_PORT" -w 2 2>/dev/null <<< "$request" || true)
fi

echo "response=$response"
if ! printf '%s' "$response" | grep -Eq "^ACK\|V1\|$job_id\|QUEUED$"; then
    echo "TCP enqueue test failed"
    exit 1
fi

sleep 2
status=$(mysql_query_raw "SELECT status FROM email_jobs WHERE job_id='$job_id' LIMIT 1;" | tail -n 1)

echo "job_status=$status"
if [ "$status" != "completed" ] && [ "$status" != "pending" ] && [ "$status" != "processing" ]; then
    echo "Unexpected queue status"
    exit 1
fi
