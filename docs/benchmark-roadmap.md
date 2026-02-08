# Benchmark Roadmap

Snapshot aligned to ecosystem metadata from `docs/ecosystem/repos.json` (generated on 2026-02-08 UTC).

## Phase 1: Baseline Harnesses

Goal: establish reproducible baselines for core claims.

- LLM baseline harness (`ternary`, `llama.cpp`, `t81lib`)
- Memory/energy ledger ingestion (`ternary-memory-research`)
- Matrix validation and metadata CI (already in this repo)

Deliverables:
- `benchmarks/results/` schema and sample result files
- fixed hardware profiles for benchmark comparability
- baseline runs checked into versioned artifacts

## Phase 2: Cross-Repo Parity and Correctness

Goal: ensure performance claims remain tied to correctness.

- RTL/emulator parity reporting (`t81-hardware`)
- Compiler ABI/lowering conformance (`ternary_gcc_plugin`)
- GGUF parsing/validation scaling (`ternary-tools`)

Deliverables:
- pass/fail gates for parity suites
- ABI conformance report templates
- reproducibility checklist for each suite

## Phase 3: Applied Throughput and Efficiency

Goal: quantify end-to-end gains under controlled conditions.

- Fabric offload reference benchmarks (`ternary-fabric`)
- Crypto throughput/decrypt/pow sweeps (`trinity*`)
- Userspace pager working-set benchmarks (`ternary-pager`)

Deliverables:
- baseline vs optimized comparisons by workload class
- confidence intervals and run-to-run variance summaries
- regression thresholds for CI/nightly jobs

## Guardrails

- Every benchmark row must map to a source repository and suite contract.
- Metrics without reproducible harness configuration are considered informational, not authoritative.
- Repository metadata snapshots should be refreshed before adding or removing benchmark targets.
