#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "SoC41 requires an existing implemented Vivado project."
echo "Example Vivado Tcl:"
echo "  open_project <project.xpr>"
echo "  open_run impl_1"
echo "  source scripts/collect_soc41_signoff_reports.tcl"
echo
echo "After actual report/board values are entered:"
echo "  python3 scripts/evaluate_soc41_signoff.py data/soc41_signoff_input.json"
