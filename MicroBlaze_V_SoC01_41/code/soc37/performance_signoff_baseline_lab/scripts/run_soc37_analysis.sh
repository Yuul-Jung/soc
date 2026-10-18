#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 37: NPU post-route performance baseline ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc37_npu_post_route.tcl
