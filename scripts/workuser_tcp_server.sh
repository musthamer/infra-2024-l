#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

LOCK_FILE="$RUNTIME_DIR/tcp_server.lock"
exec 8>"$LOCK_FILE"
if ! flock -n 8; then
    echo "[$(date -Iseconds)] TCP server lock already held, exiting duplicate instance." >> "$LOG_DIR/tcp_server.log"
    exit 0
fi

handler="$SCRIPT_DIR/workuser_handle_connection.sh"

run_with_ncat() {
    ncat --listen --keep-open "$EMAIL_QUEUE_HOST" "$EMAIL_QUEUE_PORT" --sh-exec "$handler"
}

run_with_nc_exec() {
    nc -lk -p "$EMAIL_QUEUE_PORT" -s "$EMAIL_QUEUE_HOST" -c "$handler"
}

echo "[$(date -Iseconds)] TCP server starting on ${EMAIL_QUEUE_HOST}:${EMAIL_QUEUE_PORT}" >> "$LOG_DIR/tcp_server.log"

while true; do
    if command -v ncat >/dev/null 2>&1; then
        run_with_ncat >> "$LOG_DIR/tcp_server.log" 2>&1
    elif command -v nc >/dev/null 2>&1 && nc -h 2>&1 | grep -q -- ' -c '; then
        run_with_nc_exec >> "$LOG_DIR/tcp_server.log" 2>&1
    else
        echo "[$(date -Iseconds)] ERROR: neither ncat nor nc with -c support is available." >> "$LOG_DIR/tcp_server.log"
        sleep 5
    fi

    sleep 1
done
