#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

bash "$SCRIPT_DIR/services_stop.sh" || true

pkill -f 'workuser_tcp_server.sh' || true
pkill -f 'email_worker.sh' || true
pkill -f 'service_watcher.sh' || true
pkill -f 'ncat --listen --keep-open' || true

sleep 1

bash "$SCRIPT_DIR/services_start.sh"
