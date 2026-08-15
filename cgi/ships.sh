#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/common.sh"

implementation=$(get_request_param implementation || true)

case "$implementation" in
    simple)
        exec "$SCRIPT_DIR/ships_simple.sh"
        ;;
    optimized|"")
        exec "$SCRIPT_DIR/ships_optimized.sh"
        ;;
    *)
        print_json_header "400 Bad Request"
        print_json "error" "Unknown implementation"
        ;;
esac