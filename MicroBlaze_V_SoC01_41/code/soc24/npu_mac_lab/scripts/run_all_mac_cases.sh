#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

for variant in basic pipelined; do
  echo
  echo "============================================================"
  echo "SoC 24 MAC analysis: ${variant}"
  echo "============================================================"

  vivado \
    -mode batch \
    -nolog \
    -nojournal \
    -source scripts/run_mac_analysis.tcl \
    -tclargs "$variant"
done

echo
echo "Compare reports/basic and reports/pipelined."
