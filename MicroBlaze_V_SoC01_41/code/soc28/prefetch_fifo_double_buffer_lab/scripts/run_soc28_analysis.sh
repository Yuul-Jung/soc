#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 28: generic OOC memory/FIFO inference ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc28_generic_ooc.tcl

echo
echo "=== SoC 28: Basys3 board implementation ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc28_board_analysis.tcl
