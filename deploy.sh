#!/bin/bash

set -euo pipefail

TARGET_WEB="/var/www/html/$USER-web/project_2024"
TARGET_CGI="/usr/lib/cgi-bin/project_2024"

mkdir -p "$TARGET_WEB" "$TARGET_CGI"
cp -a www/* "$TARGET_WEB/"
cp -a cgi/* "$TARGET_CGI/"
cp -a scripts ./scripts_deployed_snapshot

find "$TARGET_CGI" -type f -name '*.sh' -exec chmod +x {} +
echo "Deployment complete: web + cgi copied."
