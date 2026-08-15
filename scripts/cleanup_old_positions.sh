#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

retention_seconds="${AIS_RETENTION_SECONDS:-7200}"
if ! printf '%s' "$retention_seconds" | grep -Eq '^[0-9]+$'; then
    retention_seconds=7200
fi

rows_deleted=$(mysql_query_raw "
    DELETE FROM positions
    WHERE timestamp < (NOW() - INTERVAL $retention_seconds SECOND);
    SELECT ROW_COUNT();
" 2>/dev/null | tail -n 1)

rows_deleted=${rows_deleted:-0}
printf '%s\n' "$rows_deleted"
