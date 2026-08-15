#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

WORKER_ID="worker_$(hostname)_$$"
LOCK_FILE="$RUNTIME_DIR/email_worker.lock"
EMAIL_LOG_FILE="$LOG_DIR/email_simulation.log"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "[$(date -Iseconds)] Worker already running, exiting." >> "$LOG_DIR/email_worker.log"
    exit 0
fi

echo "[$(date -Iseconds)] Worker started as $WORKER_ID" >> "$LOG_DIR/email_worker.log"

cleanup_counter=0

while true; do
    mysql_query_raw "
        UPDATE email_jobs
        SET status = 'pending', worker_id = NULL, started_at = NULL
        WHERE status = 'processing'
          AND started_at IS NOT NULL
          AND started_at < (NOW() - INTERVAL 120 SECOND);
    " >/dev/null 2>&1 || true

    rows_claimed=$(mysql_query_raw "
        UPDATE email_jobs
        SET status = 'processing',
            worker_id = '$WORKER_ID',
            started_at = NOW(),
            attempts = attempts + 1,
            error_message = NULL
        WHERE status = 'pending'
        ORDER BY created_at ASC
        LIMIT 1;
        SELECT ROW_COUNT();
    " 2>/dev/null | tail -n 1)

    rows_claimed=${rows_claimed:-0}

    if [ "$rows_claimed" = "0" ]; then
        cleanup_counter=$((cleanup_counter + 1))
        if [ "$cleanup_counter" -ge 30 ]; then
            "$SCRIPT_DIR/cleanup_old_positions.sh" >/dev/null 2>&1 || true
            "$SCRIPT_DIR/cleanup_expired_sessions.sh" >/dev/null 2>&1 || true
            cleanup_counter=0
        fi
        sleep 1
        continue
    fi

    job_row=$(mysql_query_raw "
        SELECT job_id, payload
        FROM email_jobs
        WHERE status = 'processing'
          AND worker_id = '$WORKER_ID'
        ORDER BY started_at ASC
        LIMIT 1;
    " 2>/dev/null)

    if [ -z "$job_row" ]; then
        sleep 1
        continue
    fi

    IFS=$'\t' read -r job_id payload <<< "$job_row"

    if [ -z "$job_id" ]; then
        sleep 1
        continue
    fi

    if printf '%s' "$payload" | grep -Eq '^type=login;email='; then
        printf '%s|%s|%s\n' "$(date -Iseconds)" "$job_id" "$payload" >> "$EMAIL_LOG_FILE"
        mysql_query_raw "
            UPDATE email_jobs
            SET status = 'completed',
                finished_at = NOW(),
                error_message = NULL
            WHERE job_id = '$job_id';
        " >/dev/null 2>&1 || true
    else
        escaped_error=$(mysql_escape_runtime "Unsupported payload")
        mysql_query_raw "
            UPDATE email_jobs
            SET status = 'failed',
                finished_at = NOW(),
                error_message = '$escaped_error'
            WHERE job_id = '$job_id';
        " >/dev/null 2>&1 || true
    fi
done
