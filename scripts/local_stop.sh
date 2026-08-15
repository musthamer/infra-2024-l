#!/bin/bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Bitte als root ausfuehren. Beispiel: sudo bash scripts/local_stop.sh"
    exit 1
fi

a2dissite infra-2024-l-local >/dev/null 2>&1 || true
service apache2 restart
bash "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/services_stop.sh" >/dev/null 2>&1 || true

echo "Lokale Apache-Site infra-2024-l-local wurde deaktiviert."