#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."
vivado -mode batch -nolog -nojournal -source scripts/run_soc35_full_ooc.tcl
