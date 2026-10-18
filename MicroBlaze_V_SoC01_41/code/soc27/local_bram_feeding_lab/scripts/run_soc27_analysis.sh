#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 27: generic BRAM inference ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc27_memory_inference.tcl

echo
echo "=== SoC 27: Basys3 board implementation ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc27_board_analysis.tcl
