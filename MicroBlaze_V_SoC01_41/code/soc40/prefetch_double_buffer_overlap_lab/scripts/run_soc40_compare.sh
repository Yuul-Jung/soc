#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT_DIR"

vivado -mode batch -nolog -nojournal \
  -source scripts/run_soc40_soc39_baseline_post_route.tcl

vivado -mode batch -nolog -nojournal \
  -source scripts/run_soc40_overlap_post_route.tcl
