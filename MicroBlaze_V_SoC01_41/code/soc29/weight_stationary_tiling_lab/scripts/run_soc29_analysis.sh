#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 29: generic OOC ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc29_generic_ooc.tcl

echo
echo "=== SoC 29: Basys3 board implementation ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc29_board_analysis.tcl
