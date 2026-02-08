# Benchmark Suite Definitions

This document defines the benchmark suites listed in `benchmarks/benchmark-matrix.tsv`.

## Status Labels

- `planned`: suite is defined but harness/results are not yet checked in.
- `in_progress`: harness exists or is being built, but baseline is incomplete.
- `active`: suite has runnable harness and at least one reproducible baseline.
- `blocked`: suite cannot run due to missing dependency/input/environment.

## Global Result Contract

- Every benchmark output JSON must validate against `benchmarks/results/schema.json`.
- Every benchmark output must reference a valid `profile_id` from `benchmarks/profiles/`.
- Suite outputs belong under `benchmarks/results/<suite>/`.

## Suite Contracts

- `llm_inference_t3k_vs_q4q5`
  Compare equivalent prompts and context windows across T3_K and Q4/Q5-class quantizations.
  Required outputs: throughput, memory peak, quality metric (perplexity or task score), model size.
  Harness path: `benchmarks/suites/llm_inference_t3k_vs_q4q5/run.sh`.

- `llm_kernel_perf`
  Microbench packed ternary matmul and supporting kernels under fixed tensor shapes.
  Required outputs: latency distribution, throughput, CPU utilization.

- `python_quantization_pipeline`
  End-to-end conversion and export path via Python APIs/CLI.
  Required outputs: conversion time, artifact sizes, round-trip checks.

- `llama_cpp_reference_baseline`
  Reference baseline for model loading + generation on known hardware.
  Required outputs: load time, throughput, memory peak.

- `deterministic_runtime_bench`
  Deterministic runtime replay and trace generation throughput.
  Required outputs: execution throughput, replay parity, state hash parity.
  Baseline source:
  - `t81-vm/docs/benchmarks/vm-perf-baseline.json`
  - `t81-vm/scripts/perf-regression-check.py`

- `rtl_emulator_parity`
  Compare hardware simulation outputs with software emulator traces.
  Required outputs: parity pass rate, regression duration, cycle counts.

- `fabric_offload_reference`
  Evaluate latency/energy proxy changes from ternary fabric interception.
  Required outputs: baseline vs offload latency, energy proxy, offload hit rate.

- `sense_headroom_energy`
  Aggregate guard/jitter/energy tuples under controlled sweeps.
  Required outputs: headroom bins, latency, energy per word, pass/fail labels.

- `userspace_pager_effective_ws`
  Measure memory-traffic reduction versus paging/decode overhead.
  Required outputs: fault costs, traffic, effective working-set behavior.

- `gcc_plugin_lowering_correctness`
  Validate helper ABI lowering correctness and overhead in test programs.
  Required outputs: compile-time impact, ABI test pass/fail, runtime deltas.

- `gguf_inspection_scaling`
  Stress test GGUF parsing/validation over representative model sizes.
  Required outputs: parse latency, memory usage, validation outcomes.

- `cipher_throughput`
  Measure encryption throughput and cost by algorithm under fixed payloads.
  Required outputs: throughput, CPU time, optional compression effects.

- `decrypt_throughput`
  Measure decryption speed and integrity check reliability for `.t81z` data.
  Required outputs: throughput, latency distribution, validation outcomes.

- `pow_search_efficiency`
  Characterize search performance by difficulty/entropy constraints.
  Required outputs: nonces/sec, success rate, entropy distribution.
