#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

LOCK_FILE="$RUNTIME_DIR/watcher.lock"
exec 7>"$LOCK_FILE"
if ! flock -n 7; then
    echo "[$(date -Iseconds)] watcher lock already held, exiting duplicate instance." >> "$LOG_DIR/watcher.log"
    exit 0
fi

TCP_PID_FILE="$PID_DIR/tcp_server.pid"
WORKER_PID_FILE="$PID_DIR/email_worker.pid"

start_tcp() {
    nohup bash "$SCRIPT_DIR/workuser_tcp_server.sh" >> "$LOG_DIR/tcp_server.log" 2>&1 &
    echo $! > "$TCP_PID_FILE"
}

start_worker() {
    nohup bash "$SCRIPT_DIR/email_worker.sh" >> "$LOG_DIR/email_worker.log" 2>&1 &
    echo $! > "$WORKER_PID_FILE"
}

while true; do
    tcp_pid=$(read_pid_file "$TCP_PID_FILE")
    if ! pid_is_running "$tcp_pid"; then
        start_tcp
    fi

    worker_pid=$(read_pid_file "$WORKER_PID_FILE")
    if ! pid_is_running "$worker_pid"; then
        start_worker
    fi

    sleep 3
done
