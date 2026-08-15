#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
EMAIL="${TEST_EMAIL:-testlocal@example.com}"
PASSWORD="${TEST_PASSWORD:-secret123}"
COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

echo "[1/4] Register user (idempotent if email already exists)"
curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
	-d "firstname=Test&lastname=User&email=${EMAIL//@/%40}&phonenumber=123456&password=$PASSWORD" \
	"$BASE_URL/cgi-bin/project_2024/register.sh" || true
echo

echo "[2/4] Login"
curl -s -c "$COOKIE_JAR" -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
	-d "emailLogin=${EMAIL//@/%40}&passwordLogin=$PASSWORD" \
	"$BASE_URL/cgi-bin/project_2024/login.sh"
echo

echo "[3/4] Verify session"
curl -s -b "$COOKIE_JAR" "$BASE_URL/cgi-bin/project_2024/verify_session.sh"
echo

echo "[4/4] Ship endpoint (optimized)"
curl -s -b "$COOKIE_JAR" "$BASE_URL/cgi-bin/project_2024/ships.sh?implementation=optimized"
echo

echo "[4b/4] Ship endpoint (simple)"
curl -s -b "$COOKIE_JAR" "$BASE_URL/cgi-bin/project_2024/ships.sh?implementation=simple"
echo