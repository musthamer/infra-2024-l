#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

service_state() {
    local name="$1"
    local pid_file="$2"
    local pid

    pid=$(read_pid_file "$pid_file")
    if pid_is_running "$pid"; then
        printf '%s: RUNNING (pid %s)\n' "$name" "$pid"
    else
        printf '%s: DOWN\n' "$name"
    fi
}

apache_state="UNKNOWN"
if command -v service >/dev/null 2>&1; then
    if service apache2 status >/dev/null 2>&1; then
        apache_state="RUNNING"
    else
        apache_state="DOWN"
    fi
fi

mariadb_state="UNKNOWN"
if command -v service >/dev/null 2>&1; then
    if service mariadb status >/dev/null 2>&1; then
        mariadb_state="RUNNING"
    else
        mariadb_state="DOWN"
    fi
fi

printf 'Apache: %s\n' "$apache_state"
printf 'MariaDB: %s\n' "$mariadb_state"
service_state "TCP server" "$PID_DIR/tcp_server.pid"
service_state "Email worker" "$PID_DIR/email_worker.pid"
service_state "Watcher" "$PID_DIR/watcher.pid"

queue_pending="unknown"
if mysql_query_raw "SELECT 1;" >/dev/null 2>&1; then
    queue_pending=$(mysql_query_raw "SELECT COUNT(*) FROM email_jobs WHERE status='pending';" 2>/dev/null | tail -n 1)
fi

printf 'Queue pending: %s\n' "${queue_pending:-unknown}"
