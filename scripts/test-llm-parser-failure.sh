#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SUITE_RUNNER="$ROOT_DIR/benchmarks/suites/llm_inference_t3k_vs_q4q5/run.sh"
FIXTURE_DIR="$ROOT_DIR/benchmarks/suites/llm_inference_t3k_vs_q4q5/fixtures"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
generated_result=""
cleanup() {
  if [ -n "$generated_result" ] && [ -f "$generated_result" ]; then
    rm "$generated_result" || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

mock_bin="$tmp_dir/bin"
mkdir -p "$mock_bin"

cat > "$mock_bin/llama-cli" <<'MOCK'
#!/usr/bin/env bash
model=""
while [ $# -gt 0 ]; do
  case "$1" in
    -m)
      model="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if echo "$model" | grep -qi 'q4'; then
  cat "__FIXTURE__/llama-cli-q4-missing-tps.log"
else
  cat "__FIXTURE__/llama-cli-t3.log"
fi
MOCK

cat > "$mock_bin/llama-perplexity" <<'MOCK'
#!/usr/bin/env bash
if [ "${1:-}" = "--help" ]; then
  echo "--file <path>"
  exit 0
fi

echo "Final estimate: PPL = 6.40"
MOCK

sed -i.bak "s|__FIXTURE__|$FIXTURE_DIR|g" "$mock_bin/llama-cli"
rm "$mock_bin/llama-cli.bak"
chmod +x "$mock_bin/llama-cli" "$mock_bin/llama-perplexity"

q4_model="$tmp_dir/model-q4.gguf"
t3_model="$tmp_dir/model-t3.gguf"
dataset="$tmp_dir/wikitext2.txt"
printf 'placeholder\n' > "$q4_model"
printf 'placeholder\n' > "$t3_model"
printf 'sample text\n' > "$dataset"

run_output="$(PATH="$mock_bin:$PATH" "$SUITE_RUNNER" \
  --profile cpu_x86_64_avx2 \
  --q4-model "$q4_model" \
  --t3-model "$t3_model" \
  --ppl-dataset "$dataset" \
  --max-tokens 16)"

generated_result="$(printf '%s\n' "$run_output" | awk '/^Wrote / {print $2}' | tail -n1)"
if [ -z "$generated_result" ] || [ ! -f "$generated_result" ]; then
  echo "Runner did not produce a result file" >&2
  exit 1
fi

jq -e '.outcome.status == "failed"' "$generated_result" >/dev/null
jq -e '.metrics.tokens_per_sec_q4 == null' "$generated_result" >/dev/null
jq -e '.metrics.tokens_per_sec_t3 == 78.12' "$generated_result" >/dev/null

echo "LLM parser failure-path test passed."
