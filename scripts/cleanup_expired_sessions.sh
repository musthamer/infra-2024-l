#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common_runtime.sh"

rows_deleted=$(mysql_query_raw "
    DELETE FROM sessions
    WHERE created_at < (NOW() - INTERVAL $SESSION_TTL_SECONDS SECOND);
    SELECT ROW_COUNT();
" 2>/dev/null | tail -n 1)

rows_deleted=${rows_deleted:-0}
printf '%s\n' "$rows_deleted"
