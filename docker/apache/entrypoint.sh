#!/bin/bash
set -e

if [ -d /usr/lib/cgi-bin/project_2024 ]; then
    find /usr/lib/cgi-bin/project_2024 -type f -name '*.sh' -exec chmod +x {} +
fi

exec "$@"