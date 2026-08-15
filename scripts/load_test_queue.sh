#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
OUT_DIR="$REPO_ROOT/monitoring"
OUT_FILE="$OUT_DIR/queue_load.csv"

mkdir -p "$OUT_DIR"
echo "batch_size,submitted,accepted,completed,failed,duration_seconds,avg_completion_seconds" > "$OUT_FILE"

send_job() {
    local job_id="$1"
    local payload request response

    payload=$(printf 'type=login;email=queue-load@example.com;session=%s;ts=%s' "$job_id" "$(date +%s)" | base64 -w 0)
    request="V1|ENQUEUE_EMAIL|$job_id|$payload"

    response=""
    exec 3<>"/dev/tcp/127.0.0.1/4000" 2>/dev/null || true
    if [ -e /proc/$$/fd/3 ]; then
        printf '%s\n' "$request" >&3
        IFS= read -r -t 2 response <&3 || true
        exec 3<&-
        exec 3>&-
    fi

    if [ -z "$response" ] && command -v ncat >/dev/null 2>&1; then
        response=$(ncat 127.0.0.1 4000 -w 2 2>/dev/null <<< "$request" || true)
    fi

    if [ -z "$response" ] && command -v nc >/dev/null 2>&1; then
        response=$(nc 127.0.0.1 4000 -w 2 2>/dev/null <<< "$request" || true)
    fi

    if printf '%s' "$response" | grep -Eq "^ACK\|V1\|$job_id\|QUEUED$"; then
        echo 1
    else
        echo 0
    fi
}

run_batch() {
    local batch_size="$1"
    local start_ts end_ts accepted completed failed total_latency avg_latency batch_tag wait_seconds

    start_ts=$(date +%s)
    accepted=0
    batch_tag="batch_${batch_size}_${start_ts}"

    for i in $(seq 1 "$batch_size"); do
        job_id="${batch_tag}_$i"
        accepted=$((accepted + $(send_job "$job_id")))
    done

    wait_seconds=0
    while [ "$wait_seconds" -lt 30 ]; do
        done_count=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
            SELECT COUNT(*)
            FROM email_jobs
            WHERE job_id LIKE '${batch_tag}_%'
              AND status IN ('completed', 'failed');
        " | tail -n 1)

        done_count=${done_count:-0}
        if [ "$done_count" -ge "$accepted" ]; then
            break
        fi

        sleep 1
        wait_seconds=$((wait_seconds + 1))
    done

    completed=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
        SELECT COUNT(*)
        FROM email_jobs
        WHERE job_id LIKE '${batch_tag}_%'
          AND status='completed';
    " | tail -n 1)

    failed=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
        SELECT COUNT(*)
        FROM email_jobs
        WHERE job_id LIKE '${batch_tag}_%'
          AND status='failed';
    " | tail -n 1)

    total_latency=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
        SELECT COALESCE(SUM(TIMESTAMPDIFF(SECOND, created_at, finished_at)), 0)
        FROM email_jobs
        WHERE job_id LIKE '${batch_tag}_%'
          AND status='completed'
          AND finished_at IS NOT NULL;
    " | tail -n 1)

    if [ "${completed:-0}" -gt 0 ]; then
        avg_latency=$((total_latency / completed))
    else
        avg_latency=0
    fi

    end_ts=$(date +%s)
    echo "$batch_size,$batch_size,$accepted,${completed:-0},${failed:-0},$((end_ts - start_ts)),$avg_latency" >> "$OUT_FILE"
}

run_batch 1
run_batch 10
run_batch 50
run_batch 100

echo "Queue load results written to $OUT_FILE"
