#!/usr/bin/env bash
set -euo pipefail

MATRIX="benchmarks/benchmark-matrix.tsv"

if [ ! -f "$MATRIX" ]; then
  echo "Missing $MATRIX" >&2
  exit 1
fi

header="$(head -n1 "$MATRIX")"
expected=$'repo\tdomain\tsuite\tprimary_metrics\tstatus\tnotes'
if [ "$header" != "$expected" ]; then
  echo "Invalid header in $MATRIX" >&2
  echo "Expected: $expected" >&2
  echo "Actual:   $header" >&2
  exit 1
fi

data_lines="$(tail -n +2 "$MATRIX" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
if [ "$data_lines" -eq 0 ]; then
  echo "No benchmark rows found in $MATRIX" >&2
  exit 1
fi

# Validate status values and duplicate (repo,suite) pairs.
awk -F '\t' '
BEGIN {
  ok = 1
}
NR == 1 { next }
NF > 0 {
  if ($5 != "planned" && $5 != "in_progress" && $5 != "active" && $5 != "blocked") {
    printf("Invalid status on line %d: %s\n", NR, $5) > "/dev/stderr"
    ok = 0
  }
  key = $1 "::" $3
  if (seen[key]++) {
    printf("Duplicate repo/suite pair on line %d: %s\n", NR, key) > "/dev/stderr"
    ok = 0
  }
}
END {
  if (!ok) {
    exit 1
  }
}
' "$MATRIX"

echo "Benchmark matrix validation passed ($data_lines rows)."
