#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
MON_DIR="$REPO_ROOT/monitoring"

if ! command -v gnuplot >/dev/null 2>&1; then
    echo "gnuplot not installed. Install it and run:"
    echo "  gnuplot monitoring/login_load.gnuplot"
    echo "  gnuplot monitoring/queue_load.gnuplot"
    echo "  gnuplot monitoring/throughput.gnuplot"
    exit 0
fi

cd "$MON_DIR"
gnuplot login_load.gnuplot
gnuplot queue_load.gnuplot
gnuplot throughput.gnuplot

echo "Generated monitoring/login_load.png"
echo "Generated monitoring/queue_load.png"
echo "Generated monitoring/throughput.png"
