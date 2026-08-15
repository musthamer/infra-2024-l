#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

TCP_PID_FILE="$PID_DIR/tcp_server.pid"
WORKER_PID_FILE="$PID_DIR/email_worker.pid"
WATCHER_PID_FILE="$PID_DIR/watcher.pid"

start_process_if_needed() {
    local name="$1"
    local pid_file="$2"
    local cmd="$3"

    local pid
    pid=$(read_pid_file "$pid_file")
    if pid_is_running "$pid"; then
        echo "$name already running (pid $pid)"
        return
    fi

    nohup bash -lc "$cmd" >> "$LOG_DIR/${name}.log" 2>&1 &
    echo $! > "$pid_file"
    echo "$name started (pid $(cat "$pid_file"))"
}

start_process_if_needed "tcp_server" "$TCP_PID_FILE" "$SCRIPT_DIR/workuser_tcp_server.sh"
start_process_if_needed "email_worker" "$WORKER_PID_FILE" "$SCRIPT_DIR/email_worker.sh"
start_process_if_needed "watcher" "$WATCHER_PID_FILE" "$SCRIPT_DIR/service_watcher.sh"

bash "$SCRIPT_DIR/services_status.sh"
