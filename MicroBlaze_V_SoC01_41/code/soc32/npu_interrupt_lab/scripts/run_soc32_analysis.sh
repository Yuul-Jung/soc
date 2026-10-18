#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 32: NPU AXI4-Lite + IRQ OOC ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc32_irq_ooc.tcl
