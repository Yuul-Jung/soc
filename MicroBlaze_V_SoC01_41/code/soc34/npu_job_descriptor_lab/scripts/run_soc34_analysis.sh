#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

echo "=== SoC 34: Job Descriptor / Data Plane OOC ==="
vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_soc34_job_ooc.tcl
