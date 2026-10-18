#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$ROOT_DIR"

vivado \
  -mode batch \
  -nolog \
  -nojournal \
  -source scripts/run_vector_controller_analysis.tcl
