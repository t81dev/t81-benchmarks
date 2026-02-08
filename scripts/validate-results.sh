#!/usr/bin/env bash
set -euo pipefail

RESULT_SCHEMA="benchmarks/results/schema.json"
PROFILE_DIR="benchmarks/profiles"

if [ ! -f "$RESULT_SCHEMA" ]; then
  echo "Missing schema: $RESULT_SCHEMA" >&2
  exit 1
fi

if [ ! -d "$PROFILE_DIR" ]; then
  echo "Missing profile directory: $PROFILE_DIR" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

python3 - <<'PY'
import json
import pathlib
import sys

try:
    import jsonschema
except ModuleNotFoundError:
    print("Missing python package: jsonschema", file=sys.stderr)
    print("Install with: python3 -m venv .venv && source .venv/bin/activate && pip install jsonschema", file=sys.stderr)
    sys.exit(1)

schema_path = pathlib.Path("benchmarks/results/schema.json")
profiles_dir = pathlib.Path("benchmarks/profiles")
results_dir = pathlib.Path("benchmarks/results")

schema = json.loads(schema_path.read_text())
validator = jsonschema.Draft202012Validator(schema)

profile_ids = set()
for profile in sorted(profiles_dir.glob("*.json")):
    data = json.loads(profile.read_text())
    pid = data.get("profile_id")
    if not isinstance(pid, str) or not pid:
      print(f"Invalid profile_id in {profile}", file=sys.stderr)
      sys.exit(1)
    if pid in profile_ids:
      print(f"Duplicate profile_id: {pid}", file=sys.stderr)
      sys.exit(1)
    profile_ids.add(pid)

if not profile_ids:
    print("No profiles found.", file=sys.stderr)
    sys.exit(1)

result_files = sorted(results_dir.rglob("*.json"))
result_files = [p for p in result_files if p != schema_path and p.parent != profiles_dir]

if not result_files:
    print("No result json files found under benchmarks/results/", file=sys.stderr)
    sys.exit(1)

failed = False
for result_file in result_files:
    data = json.loads(result_file.read_text())

    errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
    if errors:
      failed = True
      for err in errors:
        path = ".".join(str(x) for x in err.path)
        where = path if path else "<root>"
        print(f"Schema error in {result_file} at {where}: {err.message}", file=sys.stderr)

    pid = data.get("profile_id")
    if pid not in profile_ids:
      failed = True
      print(f"Unknown profile_id '{pid}' in {result_file}", file=sys.stderr)

if failed:
    sys.exit(1)

print(f"Result validation passed ({len(result_files)} files, {len(profile_ids)} profiles).")
PY
