#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 36: frozen hardware OOC regression ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc36_hardware_freeze_ooc.tcl
