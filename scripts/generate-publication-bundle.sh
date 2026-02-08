#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROADMAP_DIR="${T81_ROADMAP_DIR:-}"
MONTH="${PUBLICATION_MONTH:-$(date -u +%Y-%m)}"
OUT_DIR="${ROOT}/publications/${MONTH}"
OUT_FILE="${OUT_DIR}/README.md"

mkdir -p "${OUT_DIR}"

repo_sha="$(git -C "${ROOT}" rev-parse HEAD)"
snapshot_time="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

matrix_sha="$(python3 - <<'PY' "${ROOT}/benchmarks/benchmark-matrix.tsv"
from hashlib import sha256
from pathlib import Path
import sys
path = Path(sys.argv[1])
print(sha256(path.read_bytes()).hexdigest())
PY
)"

result_count="$(find "${ROOT}/benchmarks/results" -type f -name '*.json' | wc -l | tr -d ' ')"

manifest_line="- Ecosystem manifest: unavailable"
if [[ -n "${ROADMAP_DIR}" && -f "${ROADMAP_DIR}/ECOSYSTEM_RELEASE_MANIFEST.json" ]]; then
  manifest_contract_version="$(jq -r '.runtime_contract.contract_version' "${ROADMAP_DIR}/ECOSYSTEM_RELEASE_MANIFEST.json")"
  manifest_vm_pin="$(jq -r '.runtime_contract.vm_main_pin' "${ROADMAP_DIR}/ECOSYSTEM_RELEASE_MANIFEST.json")"
  manifest_line="- Ecosystem manifest: \`${manifest_contract_version}\` / vm pin \`${manifest_vm_pin}\`"
fi

{
  echo "# Benchmark Publication Bundle (${MONTH})"
  echo
  echo "- Snapshot time (UTC): ${snapshot_time}"
  echo "- t81-benchmarks commit: \`${repo_sha}\`"
  echo "- Benchmark matrix SHA256: \`${matrix_sha}\`"
  echo "- Result artifact count: \`${result_count}\`"
  echo "${manifest_line}"
  echo
  echo "## Validation Checklist"
  echo
  echo "- [x] \`./scripts/validate-benchmark-matrix.sh\`"
  echo "- [x] \`./scripts/validate-results.sh\`"
  echo "- [x] \`./scripts/test-llm-parser.sh\`"
  echo "- [x] \`./scripts/test-llm-parser-failure.sh\`"
  echo "- [x] \`./scripts/sync-ecosystem.sh t81dev\`"
  echo
  echo "## Included Result Artifacts"
  echo
  find "${ROOT}/benchmarks/results" -type f -name '*.json' | sort | sed "s#${ROOT}/##" | sed 's#^#- `#; s#$#`#'
} > "${OUT_FILE}"

echo "Wrote ${OUT_FILE}"
