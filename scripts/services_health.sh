#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

exit_code=0

check_pid() {
    local pid_file="$1"
    local label="$2"
    local pid

    pid=$(read_pid_file "$pid_file")
    if pid_is_running "$pid"; then
        printf '%s: OK\n' "$label"
    else
        printf '%s: FAIL\n' "$label"
        exit_code=1
    fi
}

if mysql_query_raw "SELECT 1;" >/dev/null 2>&1; then
    echo "Database: OK"
else
    echo "Database: FAIL"
    exit_code=1
fi

check_pid "$PID_DIR/tcp_server.pid" "TCP server"
check_pid "$PID_DIR/email_worker.pid" "Email worker"
check_pid "$PID_DIR/watcher.pid" "Watcher"

if command -v service >/dev/null 2>&1 && service apache2 status >/dev/null 2>&1; then
    echo "Apache: OK"
else
    echo "Apache: FAIL"
    exit_code=1
fi

ping_response=$(bash "$SCRIPT_DIR/workuser_protocol_ping.sh" 2>/dev/null || true)
if printf '%s' "$ping_response" | grep -Eq '^ACK\|V1\|ping_[0-9]+\|PONG$'; then
    echo "TCP protocol: OK"
else
    echo "TCP protocol: FAIL"
    exit_code=1
fi

exit "$exit_code"
