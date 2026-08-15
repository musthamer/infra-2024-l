#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/cgi-bin/project_2024}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
OUT_DIR="$REPO_ROOT/monitoring"
OUT_FILE="$OUT_DIR/login_load.csv"

mkdir -p "$OUT_DIR"
echo "concurrency,request_id,http_code,time_total,success" > "$OUT_FILE"

EMAIL="load_$(date +%s)@example.com"
PASSWORD="secret12345"

curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "firstname=Load&lastname=User&email=${EMAIL//@/%40}&phonenumber=1000&password=$PASSWORD" "$BASE_URL/register.sh" >/dev/null || true

run_batch() {
    local concurrency="$1"
    local total="$2"

    seq 1 "$total" | xargs -P "$concurrency" -I{} bash -lc '
      COOKIE=$(mktemp)
      BODY=$(mktemp)
      code=$(curl -s -o "$BODY" -w "%{http_code}" -c "$COOKIE" -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "emailLogin='"${EMAIL//@/%40}"'&passwordLogin='"$PASSWORD"'" '"$BASE_URL"'/login.sh)
      time=$(curl -s -o /dev/null -w "%{time_total}" -b "$COOKIE" '"$BASE_URL"'/verify_session.sh)
      success=0
      [ "$code" = "200" ] && success=1
      echo '"$concurrency"',{},$code,$time,$success >> '"$OUT_FILE"'
      rm -f "$COOKIE" "$BODY"
    '
}

run_batch 1 5
run_batch 5 20
run_batch 10 30
run_batch 25 50
run_batch 50 100

echo "Login load results written to $OUT_FILE"
