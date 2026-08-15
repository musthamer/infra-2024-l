#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
BASE_URL="${BASE_URL:-http://localhost:8080/cgi-bin/project_2024}"
RESULTS_DIR="$REPO_ROOT/tests"
RESULTS_FILE="$RESULTS_DIR/results_matrix.csv"

mkdir -p "$RESULTS_DIR"

bash "$SCRIPT_DIR/services_start.sh" >/dev/null 2>&1 || true

EMAIL="test_$(date +%s)@example.com"
PASSWORD="secret12345"
COOKIE=$(mktemp)
BODY=$(mktemp)
trap 'rm -f "$COOKIE" "$BODY"' EXIT

echo "requirement,test,result,details" > "$RESULTS_FILE"

record_result() {
    local requirement="$1"
    local test_name="$2"
    local result="$3"
    local details="$4"
    printf '%s,%s,%s,%s\n' "$requirement" "$test_name" "$result" "${details//,/; }" >> "$RESULTS_FILE"
}

request_get() {
    local url="$1"
    local cookie_file="${2:-}"
    if [ -n "$cookie_file" ]; then
        curl -s -o "$BODY" -w '%{http_code}' -b "$cookie_file" "$url"
    else
        curl -s -o "$BODY" -w '%{http_code}' "$url"
    fi
}

request_post() {
    local url="$1"
    local data="$2"
    local out_cookie="${3:-}"
    if [ -n "$out_cookie" ]; then
        curl -s -o "$BODY" -w '%{http_code}' -c "$out_cookie" -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "$data" "$url"
    else
        curl -s -o "$BODY" -w '%{http_code}' -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "$data" "$url"
    fi
}

register_code=$(request_post "$BASE_URL/register.sh" "firstname=Test&lastname=Suite&email=${EMAIL//@/%40}&phonenumber=12345&password=$PASSWORD")
if [ "$register_code" = "200" ]; then
    record_result "registration" "register new user" "PASS" "http=200"
else
    record_result "registration" "register new user" "FAIL" "http=$register_code"
fi

bad_login_code=$(request_post "$BASE_URL/login.sh" "emailLogin=${EMAIL//@/%40}&passwordLogin=wrongpass" "")
if [ "$bad_login_code" = "401" ]; then
    record_result "login failure" "wrong password" "PASS" "http=401"
else
    record_result "login failure" "wrong password" "FAIL" "http=$bad_login_code"
fi

ok_login_code=$(request_post "$BASE_URL/login.sh" "emailLogin=${EMAIL//@/%40}&passwordLogin=$PASSWORD" "$COOKIE")
if [ "$ok_login_code" = "200" ]; then
    record_result "login success" "correct credentials" "PASS" "http=200"
else
    record_result "login success" "correct credentials" "FAIL" "http=$ok_login_code"
fi

verify_code=$(request_get "$BASE_URL/verify_session.sh" "$COOKIE")
if [ "$verify_code" = "200" ]; then
    record_result "session validation" "verify current session" "PASS" "http=200"
else
    record_result "session validation" "verify current session" "FAIL" "http=$verify_code"
fi

unauth_ships_code=$(request_get "$BASE_URL/ships.sh?implementation=optimized")
if [ "$unauth_ships_code" = "401" ]; then
    record_result "unauth ships" "optimized without cookie" "PASS" "http=401"
else
    record_result "unauth ships" "optimized without cookie" "FAIL" "http=$unauth_ships_code"
fi

auth_opt_code=$(request_get "$BASE_URL/ships.sh?implementation=optimized" "$COOKIE")
auth_opt_body=$(cat "$BODY")
auth_simple_code=$(request_get "$BASE_URL/ships.sh?implementation=simple" "$COOKIE")
auth_simple_body=$(cat "$BODY")

if [ "$auth_opt_code" = "200" ] && [ "$auth_simple_code" = "200" ]; then
    record_result "ships endpoint" "simple and optimized status" "PASS" "both 200"
else
    record_result "ships endpoint" "simple and optimized status" "FAIL" "opt=$auth_opt_code simple=$auth_simple_code"
fi

python3 - <<'PY' "$auth_opt_body" "$auth_simple_body" "$RESULTS_FILE"
import json,sys
opt=json.loads(sys.argv[1])
simp=json.loads(sys.argv[2])
out=sys.argv[3]
with open(out,'a',encoding='utf-8') as f:
    if len(opt.get('ships',[]))==len(simp.get('ships',[])) and len(opt.get('tracks',[]))==len(simp.get('tracks',[])):
        f.write('implementation equivalence,count equivalence,PASS,ship and track counts match\n')
    else:
        f.write('implementation equivalence,count equivalence,FAIL,ship/track counts differ\n')
PY

invalid_impl_code=$(request_get "$BASE_URL/ships.sh?implementation=invalid" "$COOKIE")
if [ "$invalid_impl_code" = "400" ]; then
    record_result "implementation selector" "invalid implementation" "PASS" "http=400"
else
    record_result "implementation selector" "invalid implementation" "FAIL" "http=$invalid_impl_code"
fi

invalid_since_code=$(request_get "$BASE_URL/ships.sh?implementation=optimized&since=abc123" "$COOKIE")
if [ "$invalid_since_code" = "400" ]; then
    record_result "since validation" "invalid since" "PASS" "http=400"
else
    record_result "since validation" "invalid since" "FAIL" "http=$invalid_since_code"
fi

if bash "$SCRIPT_DIR/test_tcp_queue.sh" >/dev/null 2>&1; then
    record_result "tcp queue" "enqueue and process" "PASS" "tcp ack received"
else
    record_result "tcp queue" "enqueue and process" "FAIL" "enqueue failed"
fi

bad_proto=""
exec 8<>"/dev/tcp/127.0.0.1/4000" 2>/dev/null || true
if [ -e /proc/$$/fd/8 ]; then
    printf 'BAD|REQ\n' >&8
    IFS= read -r -t 2 bad_proto <&8 || true
    exec 8<&-
    exec 8>&-
elif command -v ncat >/dev/null 2>&1; then
    bad_proto=$(ncat 127.0.0.1 4000 -w 2 2>/dev/null <<< 'BAD|REQ' || true)
elif command -v nc >/dev/null 2>&1; then
    bad_proto=$(nc 127.0.0.1 4000 -w 2 2>/dev/null <<< 'BAD|REQ' || true)
fi

if printf '%s' "$bad_proto" | grep -q '^ERR|V1|'; then
    record_result "tcp protocol" "invalid protocol request" "PASS" "error returned"
else
    record_result "tcp protocol" "invalid protocol request" "FAIL" "response=$bad_proto"
fi

# Cleanup test scoped to demo MMSI only
mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
INSERT INTO ships (mmsi, timestamp, ship_name)
VALUES ('211111111', NOW(), 'Demo Vessel Alpha')
ON DUPLICATE KEY UPDATE timestamp=VALUES(timestamp), ship_name=VALUES(ship_name);
INSERT INTO positions (ship_mmsi, latitude, longitude, timestamp)
VALUES ('211111111', 53.500000, 8.500000, NOW() - INTERVAL 3 HOUR);
" >/dev/null 2>&1 || true

before_cleanup=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "SELECT COUNT(*) FROM positions WHERE ship_mmsi='211111111' AND timestamp < (NOW() - INTERVAL 2 HOUR);")
bash "$SCRIPT_DIR/cleanup_old_positions.sh" >/dev/null 2>&1 || true
after_cleanup=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "SELECT COUNT(*) FROM positions WHERE ship_mmsi='211111111' AND timestamp < (NOW() - INTERVAL 2 HOUR);")

if [ "${before_cleanup:-0}" -gt 0 ] && [ "${after_cleanup:-1}" -eq 0 ]; then
    record_result "ais cleanup" "delete old positions" "PASS" "old rows removed"
else
    record_result "ais cleanup" "delete old positions" "FAIL" "before=$before_cleanup after=$after_cleanup"
fi

# Session expiration practical test by aging current session
session_id=$(awk '$6=="session_id" {print $7}' "$COOKIE" | tail -n 1)
if [ -n "$session_id" ]; then
    mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "
        UPDATE sessions
        SET created_at = NOW() - INTERVAL 10 HOUR
        WHERE session_id = '$session_id';
    " >/dev/null 2>&1 || true
fi

expired_verify_code=$(request_get "$BASE_URL/verify_session.sh" "$COOKIE")
if [ "$expired_verify_code" = "401" ]; then
    record_result "session expiration" "expired session rejected" "PASS" "http=401"
else
    record_result "session expiration" "expired session rejected" "FAIL" "http=$expired_verify_code"
fi

# DB failure behavior (direct CGI execution)
out_db_fail=$(QUERY_STRING='since=0' HTTP_COOKIE="session_id=$session_id" DB_HOST='invalid-host-for-test' bash "$REPO_ROOT/cgi/ships_optimized.sh" 2>/dev/null || true)
if printf '%s' "$out_db_fail" | grep -q 'Status: 500 Internal Server Error'; then
    record_result "db failure" "ships optimized db down" "PASS" "500 structured error"
else
    record_result "db failure" "ships optimized db down" "FAIL" "unexpected output"
fi

echo "Test matrix written to $RESULTS_FILE"
