#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$SCRIPT_DIR/../runtime"

bash "$SCRIPT_DIR/services_start.sh"

watcher_pid_file="$SCRIPT_DIR/../runtime/pids/watcher.pid"

while true; do
    if [ -f "$watcher_pid_file" ]; then
        watcher_pid=$(cat "$watcher_pid_file")
        if kill -0 "$watcher_pid" >/dev/null 2>&1; then
            wait "$watcher_pid" || true
        fi
    fi

    bash "$SCRIPT_DIR/services_start.sh"
    sleep 2
done
