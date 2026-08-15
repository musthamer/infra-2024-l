#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/cgi-bin/project_2024}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
OUT_DIR="$REPO_ROOT/monitoring"
OUT_FILE="$OUT_DIR/requests.csv"
DURATION_SECONDS="${DURATION_SECONDS:-30}"

mkdir -p "$OUT_DIR"
echo "unix_time,endpoint,http_code,time_total" > "$OUT_FILE"

COOKIE=$(mktemp)
trap 'rm -f "$COOKIE"' EXIT

EMAIL="metrics_$(date +%s)@example.com"
PASSWORD="secret12345"

curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "firstname=Metrics&lastname=User&email=${EMAIL//@/%40}&phonenumber=9999&password=$PASSWORD" "$BASE_URL/register.sh" >/dev/null || true
curl -s -c "$COOKIE" -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "emailLogin=${EMAIL//@/%40}&passwordLogin=$PASSWORD" "$BASE_URL/login.sh" >/dev/null || true

start_ts=$(date +%s)
while true; do
    now=$(date +%s)
    if [ $((now - start_ts)) -ge "$DURATION_SECONDS" ]; then
        break
    fi

    code=$(curl -s -o /dev/null -w '%{http_code}' -b "$COOKIE" "$BASE_URL/ships.sh?implementation=optimized")
    t=$(curl -s -o /dev/null -w '%{time_total}' -b "$COOKIE" "$BASE_URL/ships.sh?implementation=optimized")
    echo "$now,ships_optimized,$code,$t" >> "$OUT_FILE"
    sleep 1
done

echo "Throughput metrics written to $OUT_FILE"
