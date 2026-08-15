#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080/cgi-bin/project_2024}"
EMAIL="${TEST_EMAIL:-testlocal@example.com}"
PASS="${TEST_PASSWORD:-secret123}"

before=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "SELECT COUNT(*) FROM email_jobs;")

curl -s -c /tmp/infra_cookie.txt -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "emailLogin=${EMAIL//@/%40}&passwordLogin=$PASS" "$BASE_URL/login.sh" > /tmp/login_resp.json

sleep 2

after=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "SELECT COUNT(*) FROM email_jobs;")
latest=$(mysql -h 127.0.0.1 -u infra-2024-l -p"aqsfm6hUFhvub99ORFrG" infra-2024-l_db -N -B -e "SELECT status FROM email_jobs ORDER BY created_at DESC LIMIT 1;")

echo "before_jobs=$before"
echo "after_jobs=$after"
echo "latest_status=$latest"
cat /tmp/login_resp.json
