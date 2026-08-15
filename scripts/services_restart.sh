#!/bin/bash
set -u

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

bash "$SCRIPT_DIR/services_stop.sh"
bash "$SCRIPT_DIR/services_start.sh"
