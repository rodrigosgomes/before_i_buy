#!/usr/bin/env bash
set -euo pipefail

coverage_file="${1:-coverage/lcov.info}"
minimum_percent="${2:-80}"

if [[ ! -f "$coverage_file" ]]; then
  echo "Coverage file not found: $coverage_file" >&2
  exit 1
fi

awk -F: -v minimum="$minimum_percent" '
  /^LF:/ { found += $2 }
  /^LH:/ { hit += $2 }
  END {
    if (found == 0) {
      print "Coverage contains no executable lines" > "/dev/stderr"
      exit 1
    }

    coverage = (hit / found) * 100
    printf "Line coverage: %.2f%% (minimum: %.2f%%)\n", coverage, minimum
    exit coverage < minimum
  }
' "$coverage_file"
