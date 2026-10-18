#!/usr/bin/env bash
set -euo pipefail

COV_DIR="${1:-./coverage}"
COV_NAME="${2:-soc21}"
REPORT_DIR="${3:-./coverage_report}"

mkdir -p "$REPORT_DIR"

xcrg \
  -cov_db_dir "$COV_DIR" \
  -cov_db_name "$COV_NAME" \
  -report_dir "$REPORT_DIR" \
  -report_format html

echo "Coverage report:"
echo "  $REPORT_DIR/dashboard.html"
