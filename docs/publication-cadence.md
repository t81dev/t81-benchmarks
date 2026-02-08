# Benchmark Publication Cadence

## Cadence

- Frequency: monthly
- Window: first full week of each month
- Owner: `@t81dev`

## Minimum Publication Set

1. Valid `benchmarks/benchmark-matrix.tsv`.
2. Valid benchmark result artifacts in `benchmarks/results/` against `benchmarks/results/schema.json`.
3. At least one refreshed runtime evidence artifact tied to current ecosystem baseline.
4. Updated summary note in `docs/benchmark-roadmap.md` when scope changes.

## Publication Checklist

1. Run `./scripts/validate-benchmark-matrix.sh`.
2. Run `./scripts/validate-results.sh`.
3. Run parser checks:
   - `./scripts/test-llm-parser.sh`
   - `./scripts/test-llm-parser-failure.sh`
4. Refresh ecosystem snapshot: `./scripts/sync-ecosystem.sh t81dev`.
5. Commit updated artifacts and include publication date in commit message.
6. Generate/update monthly publication bundle: `./scripts/generate-publication-bundle.sh`.
7. Verify publication bundle workflow health: `.github/workflows/monthly-publication-bundle.yml`.

## Next Window

- Next scheduled publication window: 2026-03-02 through 2026-03-08 (UTC).
