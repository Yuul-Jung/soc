#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

run_case() {
  local variant="$1"
  local period="$2"

  echo
  echo "============================================================"
  echo "SoC 22: ${variant}, ${period} ns"
  echo "============================================================"

  vivado \
    -mode batch \
    -nolog \
    -nojournal \
    -source scripts/run_timing_lab.tcl \
    -tclargs "$variant" "$period"
}

# Basys3 normal timing requirement.
run_case unpipelined 10.0
run_case pipelined   10.0

# Optional timing-stress comparison.
run_case unpipelined 5.0
run_case pipelined   5.0

echo
echo "All four timing experiments completed."
echo "Compare reports/*/05_timing_summary_post_route.rpt"
