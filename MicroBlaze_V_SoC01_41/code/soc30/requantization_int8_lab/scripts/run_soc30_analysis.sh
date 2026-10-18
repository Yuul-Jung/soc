#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 30: generic requantization OOC ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc30_generic_ooc.tcl

echo
echo "=== SoC 30: Basys3 board implementation ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc30_board_analysis.tcl
