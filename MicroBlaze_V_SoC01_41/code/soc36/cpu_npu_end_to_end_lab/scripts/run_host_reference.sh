#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

gcc \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  "${ROOT_DIR}/reference/soc36_host_reference.c" \
  -o "${ROOT_DIR}/reference/soc36_host_reference"

"${ROOT_DIR}/reference/soc36_host_reference"
