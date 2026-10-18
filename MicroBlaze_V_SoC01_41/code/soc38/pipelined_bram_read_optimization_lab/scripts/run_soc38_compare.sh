#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 38 baseline post-route ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc38_baseline_post_route.tcl

echo "=== SoC 38 optimized fast-read post-route ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc38_fastread_post_route.tcl
