#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

exit_code=0

for pid_file in "$PID_DIR/tcp_server.pid" "$PID_DIR/email_worker.pid" "$PID_DIR/watcher.pid"; do
    pid=$(read_pid_file "$pid_file")
    if ! pid_is_running "$pid"; then
        exit_code=1
    fi
done

if ! mysql_query_raw "SELECT 1;" >/dev/null 2>&1; then
    exit_code=1
fi

exit "$exit_code"
