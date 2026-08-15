#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
RUNTIME_DIR="$REPO_ROOT/runtime"
LOG_DIR="$RUNTIME_DIR/logs"
PID_DIR="$RUNTIME_DIR/pids"

mkdir -p "$RUNTIME_DIR" "$LOG_DIR" "$PID_DIR"

source "$REPO_ROOT/cgi/db_config.sh"
source "$REPO_ROOT/cgi/common.sh"

if [ "$DB_HOST" = "mysql-server" ]; then
    DB_HOST="127.0.0.1"
fi

EMAIL_QUEUE_HOST="${EMAIL_QUEUE_HOST:-127.0.0.1}"
EMAIL_QUEUE_PORT="${EMAIL_QUEUE_PORT:-4000}"

mysql_query_raw() {
    local sql="$1"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "$sql"
}

mysql_escape_runtime() {
    sql_escape "$1"
}

pid_is_running() {
    local pid="$1"
    [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1
}

read_pid_file() {
    local pid_file="$1"
    if [ -f "$pid_file" ]; then
        cat "$pid_file"
    fi
}
