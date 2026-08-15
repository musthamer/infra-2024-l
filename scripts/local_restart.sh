#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ "${EUID}" -ne 0 ]; then
    echo "Bitte als root ausfuehren. Beispiel: sudo bash scripts/local_restart.sh"
    exit 1
fi

bash "$SCRIPT_DIR/local_stop.sh"
bash "$SCRIPT_DIR/local_start.sh"
