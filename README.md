# t81-benchmarks

Rigorous, reproducible benchmarks across the `t81dev` ecosystem.

This repository tracks comparable evidence for:
- LLM inference (`T3_K` vs `Q4/Q5` baselines)
- Memory and storage footprint
- Energy and efficiency proxies
- Crypto throughput and cost
- Hardware/simulator parity where relevant

## Scope

`t81-benchmarks` is the measurement layer for the `t81dev` projects. It does not redefine semantics from upstream repositories. Instead, it standardizes benchmark inputs, metrics, and result formats so claims are reproducible and comparable.

## Repository Layout

- `benchmarks/benchmark-matrix.tsv`: source-of-truth matrix mapping repos -> benchmark suites -> primary metrics.
- `benchmarks/suite-definitions.md`: benchmark suite definitions and acceptance criteria.
- `benchmarks/profiles/`: reproducibility profiles for hardware/runtime classes.
- `benchmarks/suites/`: runnable suite harnesses.
- `benchmarks/results/schema.json`: canonical schema for benchmark output files.
- `benchmarks/results/`: suite output artifacts (JSON).
- `docs/ecosystem/`: generated GitHub ecosystem snapshot and inventory.
- `scripts/sync-ecosystem.sh`: refreshes repository metadata from the GitHub API.
- `scripts/validate-benchmark-matrix.sh`: sanity checks matrix integrity.
- `scripts/validate-results.sh`: schema/profile validation for benchmark result artifacts.
- `scripts/test-llm-parser.sh`: fixture-backed parser sanity test for the LLM suite runner.
- `scripts/test-llm-parser-failure.sh`: fixture-backed negative-path test for parser failure handling.
- `.github/workflows/validate.yml`: CI validation for benchmark metadata.

## Quick Start

```bash
./scripts/sync-ecosystem.sh t81dev
./scripts/validate-benchmark-matrix.sh
python3 -m venv .venv
source .venv/bin/activate
pip install jsonschema
./scripts/validate-results.sh
./scripts/test-llm-parser.sh
./scripts/test-llm-parser-failure.sh
```

## Current Snapshot

The initial benchmark matrix was seeded against repositories visible at:
- https://github.com/t81dev

Snapshot date: `2026-02-08`.

## Next Expansion

1. Implement metric extraction for the `llm_inference_t3k_vs_q4q5` harness.
2. Expand deterministic runtime suite result ingestion from `t81-vm` perf reports.
3. Add suite harnesses for hardware, memory, and crypto domains.
4. Add nightly/weekly benchmark runners where environments are stable.
