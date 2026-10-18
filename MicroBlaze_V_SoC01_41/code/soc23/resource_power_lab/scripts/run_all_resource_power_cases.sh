#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

for variant in unpipelined pipelined; do
  echo
  echo "============================================================"
  echo "SoC 23 Resource/Power: ${variant}"
  echo "============================================================"

  vivado \
    -mode batch \
    -nolog \
    -nojournal \
    -source scripts/run_resource_power_lab.tcl \
    -tclargs "$variant"
done

echo
echo "Both variants completed."
echo
echo "Compare:"
echo "  reports/unpipelined/03_utilization_post_route.rpt"
echo "  reports/pipelined/03_utilization_post_route.rpt"
echo "  reports/unpipelined/10_power_normalized_activity.rpt"
echo "  reports/pipelined/10_power_normalized_activity.rpt"
