#!/bin/bash
set -euo pipefail

MMSI="${1:-222222222}"

if ! printf '%s' "$MMSI" | grep -Eq '^(211111111|222222222)$'; then
    echo "Only demo MMSIs are allowed: 211111111 or 222222222"
    exit 1
fi

mysql -uroot infra-2024-l_db -e "
UPDATE positions
SET timestamp = NOW() - INTERVAL 12 MINUTE
WHERE ship_mmsi = '$MMSI';
"

echo "Set demo ship $MMSI inactive"
