# Benchmark Publication Bundle (2026-08)

- Snapshot time (UTC): 2026-08-01T15:29:23Z
- t81-benchmarks commit: `17e4e2365dbdd89ac4349036b6cb6610ae2b8585`
- Benchmark matrix SHA256: `7be2de4825e60e840b0128d6c66b5127f95b1f950269c4cf07d7c233ad02b484`
- Result artifact count: `3`
- Ecosystem manifest: `2026-02-08-v5` / vm pin `4158a42156a085a2b722205be951576fc01969b9`

## Validation Checklist

- [x] `./scripts/validate-benchmark-matrix.sh`
- [x] `./scripts/validate-results.sh`
- [x] `./scripts/test-llm-parser.sh`
- [x] `./scripts/test-llm-parser-failure.sh`
- [x] `./scripts/sync-ecosystem.sh t81dev`

## Included Result Artifacts

- `benchmarks/results/deterministic_runtime_bench/sample-2026-02-08-vm-perf.json`
- `benchmarks/results/llm_inference_t3k_vs_q4q5/sample-2026-02-08.json`
- `benchmarks/results/schema.json`
