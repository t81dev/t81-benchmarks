#!/usr/bin/env bash
set -euo pipefail

SUITE="llm_inference_t3k_vs_q4q5"
OUT_DIR="benchmarks/results/${SUITE}"
PROFILE_ID=""
Q4_MODEL=""
T3_MODEL=""
THREADS=8
CTX=4096
TOKENS=256
PROMPT="Explain balanced ternary in one paragraph."
PPL_DATASET=""
DRY_RUN=0

usage() {
  cat <<USAGE
Usage: $0 --profile <profile_id> --q4-model <path> --t3-model <path> [options]

Options:
  --threads <n>         Thread count (default: 8)
  --ctx-size <n>        Context length (default: 4096)
  --max-tokens <n>      Max generated tokens (default: 256)
  --prompt <text>       Prompt for generation benchmark
  --ppl-dataset <path>  Optional text dataset for perplexity via llama-perplexity
  --dry-run             Emit schema-valid placeholder result (no inference run)
  --help                Show this help
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE_ID="$2"; shift 2 ;;
    --q4-model) Q4_MODEL="$2"; shift 2 ;;
    --t3-model) T3_MODEL="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --ctx-size) CTX="$2"; shift 2 ;;
    --max-tokens) TOKENS="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --ppl-dataset) PPL_DATASET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [ -z "$PROFILE_ID" ] || [ -z "$Q4_MODEL" ] || [ -z "$T3_MODEL" ]; then
  echo "--profile, --q4-model, and --t3-model are required." >&2
  usage
  exit 1
fi

if [ ! -f "benchmarks/profiles/${PROFILE_ID}.json" ]; then
  echo "Unknown profile: ${PROFILE_ID} (expected benchmarks/profiles/${PROFILE_ID}.json)" >&2
  exit 1
fi

if [ ! -f "$Q4_MODEL" ] || [ ! -f "$T3_MODEL" ]; then
  echo "Model file missing." >&2
  exit 1
fi

if [ -n "$PPL_DATASET" ] && [ ! -f "$PPL_DATASET" ]; then
  echo "Perplexity dataset missing: $PPL_DATASET" >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 0 ] && ! command -v llama-cli >/dev/null 2>&1; then
  echo "llama-cli not found in PATH; use --dry-run or install llama-cli." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
run_id="${SUITE}_${ts}"
out_file="${OUT_DIR}/${run_id}.json"
commit="$(git rev-parse --verify HEAD 2>/dev/null || printf '0000000000000000000000000000000000000000')"
q4_size_gb="$(python3 - <<PY
import os
print(round(os.path.getsize('${Q4_MODEL}') / (1024**3), 4))
PY
)"
t3_size_gb="$(python3 - <<PY
import os
print(round(os.path.getsize('${T3_MODEL}') / (1024**3), 4))
PY
)"

format_peak_rss_mb() {
  # Input is KB (Linux /usr/bin/time -f %M or macOS -l output).
  awk -v kb="$1" 'BEGIN { printf "%.3f", kb / 1024.0 }'
}

extract_tps() {
  local log_file="$1"
  local tps

  # Prefer eval-time throughput if present.
  tps="$(grep -i 'eval time' "$log_file" | grep -Eo '[0-9]+([.][0-9]+)? tokens per second' | awk '{print $1}' | tail -n1 || true)"

  if [ -z "$tps" ]; then
    tps="$(grep -Ei 'tokens per second' "$log_file" | grep -Eo '[0-9]+([.][0-9]+)? tokens per second' | awk '{print $1}' | tail -n1 || true)"
  fi

  if [ -z "$tps" ]; then
    printf 'null\n'
  else
    printf '%s\n' "$tps"
  fi
}

extract_peak_rss_kb_from_time_log() {
  local log_file="$1"
  local rss_kb

  # GNU time format if used.
  rss_kb="$(awk '/^MAXRSS_KB=/ { print $1 }' "$log_file" | tail -n1 | cut -d= -f2)"
  if [ -n "$rss_kb" ]; then
    printf '%s\n' "$rss_kb"
    return 0
  fi

  # macOS /usr/bin/time -l output: "<num>  maximum resident set size"
  rss_kb="$(awk '/maximum resident set size/ { print $1 }' "$log_file" | tail -n1)"
  if [ -n "$rss_kb" ]; then
    printf '%s\n' "$rss_kb"
    return 0
  fi

  printf 'null\n'
}

run_and_measure_generation() {
  local model_path="$1"
  local log_file="$2"

  : > "$log_file"

  if /usr/bin/time -f 'MAXRSS_KB=%M' true >/dev/null 2>&1; then
    /usr/bin/time -f 'MAXRSS_KB=%M' \
      llama-cli -m "$model_path" -p "$PROMPT" -n "$TOKENS" -t "$THREADS" -c "$CTX" --no-warmup \
      >> "$log_file" 2>&1
  else
    /usr/bin/time -l \
      llama-cli -m "$model_path" -p "$PROMPT" -n "$TOKENS" -t "$THREADS" -c "$CTX" --no-warmup \
      >> "$log_file" 2>&1
  fi

  local tps
  local rss_kb
  local rss_mb

  tps="$(extract_tps "$log_file")"
  rss_kb="$(extract_peak_rss_kb_from_time_log "$log_file")"

  if [ "$rss_kb" = "null" ]; then
    rss_mb="null"
  else
    rss_mb="$(format_peak_rss_mb "$rss_kb")"
  fi

  printf '%s\t%s\n' "$tps" "$rss_mb"
}

extract_ppl() {
  local log_file="$1"
  local ppl
  ppl="$(grep -Ei 'ppl' "$log_file" | grep -Eo '[0-9]+([.][0-9]+)?' | tail -n1 || true)"
  if [ -z "$ppl" ]; then
    printf 'null\n'
  else
    printf '%s\n' "$ppl"
  fi
}

run_and_measure_perplexity() {
  local model_path="$1"
  local dataset_path="$2"
  local log_file="$3"

  if [ -z "$dataset_path" ] || ! command -v llama-perplexity >/dev/null 2>&1; then
    printf 'null\n'
    return 0
  fi

  : > "$log_file"

  # Dataset flag names can vary by llama.cpp version; support common variants.
  if llama-perplexity --help 2>&1 | grep -q -- '--file '; then
    llama-perplexity -m "$model_path" --file "$dataset_path" -t "$THREADS" -c "$CTX" >> "$log_file" 2>&1 || {
      printf 'null\n'
      return 0
    }
  else
    llama-perplexity -m "$model_path" -f "$dataset_path" -t "$THREADS" -c "$CTX" >> "$log_file" 2>&1 || {
      printf 'null\n'
      return 0
    }
  fi

  extract_ppl "$log_file"
}

if [ "$DRY_RUN" -eq 1 ]; then
  q4_tps=null
  t3_tps=null
  q4_rss=null
  t3_rss=null
  q4_ppl=null
  t3_ppl=null
  status="dry_run"
  notes="Dry-run output. Replace null metrics with measured values from inference harness."
else
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  q4_gen_log="$tmp_dir/q4_generation.log"
  t3_gen_log="$tmp_dir/t3_generation.log"
  q4_ppl_log="$tmp_dir/q4_ppl.log"
  t3_ppl_log="$tmp_dir/t3_ppl.log"

  read -r q4_tps q4_rss < <(run_and_measure_generation "$Q4_MODEL" "$q4_gen_log")
  read -r t3_tps t3_rss < <(run_and_measure_generation "$T3_MODEL" "$t3_gen_log")

  q4_ppl="$(run_and_measure_perplexity "$Q4_MODEL" "$PPL_DATASET" "$q4_ppl_log")"
  t3_ppl="$(run_and_measure_perplexity "$T3_MODEL" "$PPL_DATASET" "$t3_ppl_log")"

  if [ "$q4_tps" = "null" ] || [ "$t3_tps" = "null" ] || [ "$q4_rss" = "null" ] || [ "$t3_rss" = "null" ]; then
    status="failed"
    notes="Metric extraction failed for one or more required generation metrics."
  else
    status="completed"
    if [ -n "$PPL_DATASET" ] && [ "$q4_ppl" = "null" -o "$t3_ppl" = "null" ]; then
      notes="Generation metrics completed. Perplexity unavailable from llama-perplexity output."
    elif [ -n "$PPL_DATASET" ] && ! command -v llama-perplexity >/dev/null 2>&1; then
      notes="Generation metrics completed. llama-perplexity is not installed."
    elif [ -z "$PPL_DATASET" ]; then
      notes="Generation metrics completed. Perplexity not requested."
    else
      notes="Generation and perplexity metrics completed."
    fi
  fi
fi

cat > "$out_file" <<EOF_JSON
{
  "schema_version": "1.0.0",
  "run_id": "${run_id}",
  "suite": "${SUITE}",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "${commit}",
  "profile_id": "${PROFILE_ID}",
  "inputs": {
    "workload": "single_prompt_generation",
    "dataset": {
      "name": "${PPL_DATASET}",
      "split": "n/a",
      "samples": 1
    },
    "models": [
      {
        "label": "q4_baseline",
        "format": "gguf",
        "quantization": "Q4/Q5",
        "reference": "${Q4_MODEL}",
        "size_gb": ${q4_size_gb}
      },
      {
        "label": "t3_candidate",
        "format": "gguf",
        "quantization": "T3_K",
        "reference": "${T3_MODEL}",
        "size_gb": ${t3_size_gb}
      }
    ],
    "runtime": {
      "binary": "llama-cli",
      "threads": ${THREADS},
      "ctx_size": ${CTX},
      "max_tokens": ${TOKENS}
    }
  },
  "metrics": {
    "tokens_per_sec_q4": ${q4_tps},
    "tokens_per_sec_t3": ${t3_tps},
    "peak_rss_mb_q4": ${q4_rss},
    "peak_rss_mb_t3": ${t3_rss},
    "wikitext2_ppl_q4": ${q4_ppl},
    "wikitext2_ppl_t3": ${t3_ppl},
    "model_size_gb_q4": ${q4_size_gb},
    "model_size_gb_t3": ${t3_size_gb}
  },
  "outcome": {
    "status": "${status}",
    "notes": "${notes}"
  }
}
EOF_JSON

echo "Wrote ${out_file}"
