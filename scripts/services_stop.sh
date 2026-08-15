#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

stop_process() {
    local name="$1"
    local pid_file="$2"
    local pid

    pid=$(read_pid_file "$pid_file")
    if pid_is_running "$pid"; then
        kill "$pid" >/dev/null 2>&1 || true
        sleep 1
        if pid_is_running "$pid"; then
            kill -9 "$pid" >/dev/null 2>&1 || true
        fi
        echo "$name stopped"
    else
        echo "$name not running"
    fi

    rm -f "$pid_file"
}

stop_process "watcher" "$PID_DIR/watcher.pid"
stop_process "email_worker" "$PID_DIR/email_worker.pid"
stop_process "tcp_server" "$PID_DIR/tcp_server.pid"

rm -f "$RUNTIME_DIR/watcher.lock" "$RUNTIME_DIR/tcp_server.lock" "$RUNTIME_DIR/email_worker.lock"
