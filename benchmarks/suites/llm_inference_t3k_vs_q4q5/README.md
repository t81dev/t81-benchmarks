# Suite: llm_inference_t3k_vs_q4q5

Compares balanced ternary `T3_K` inference against `Q4/Q5` baselines under fixed prompt and runtime settings.

## Required Inputs

- Local GGUF model files for at least one `T3_K` model and one `Q4/Q5` baseline.
- `llama-cli` binary available in `PATH`.
- A reproducibility profile from `benchmarks/profiles/`.
- Optional: `llama-perplexity` binary and `--ppl-dataset` text file for PPL metrics.

## Run

```bash
benchmarks/suites/llm_inference_t3k_vs_q4q5/run.sh --help
```

Example dry run (schema-valid sample output):

```bash
benchmarks/suites/llm_inference_t3k_vs_q4q5/run.sh \
  --profile cpu_apple_m2_max \
  --q4-model /path/to/model-q4.gguf \
  --t3-model /path/to/model-t3.gguf \
  --dry-run
```

Example measured run:

```bash
benchmarks/suites/llm_inference_t3k_vs_q4q5/run.sh \
  --profile cpu_x86_64_avx2 \
  --q4-model /models/gemma-q4.gguf \
  --t3-model /models/gemma-t3k.gguf \
  --threads 16 \
  --ctx-size 4096 \
  --max-tokens 256 \
  --ppl-dataset /datasets/wikitext2.txt
```

## Output

Writes JSON result files to:

- `benchmarks/results/llm_inference_t3k_vs_q4q5/`

Each output must conform to `benchmarks/results/schema.json`.
The runner marks output `completed` when generation throughput and RSS metrics are extracted for both models.
