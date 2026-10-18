#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC39: SoC38 serial baseline ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc39_soc38_serial_post_route.tcl

echo "=== SoC39: parallel4 optimized ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc39_parallel4_post_route.tcl
