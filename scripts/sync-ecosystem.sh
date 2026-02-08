#!/usr/bin/env bash
set -euo pipefail

ORG="${1:-t81dev}"
OUT_DIR="docs/ecosystem"
JSON_OUT="$OUT_DIR/repos.json"
TSV_OUT="$OUT_DIR/repos.tsv"
MD_OUT="$OUT_DIR/repository-inventory.md"

mkdir -p "$OUT_DIR"

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

page=1
printf '[]' > "$tmp_json"

while :; do
  page_data="$(curl -fsSL "https://api.github.com/users/${ORG}/repos?per_page=100&page=${page}")"
  count="$(jq 'length' <<<"$page_data")"
  if [ "$count" -eq 0 ]; then
    break
  fi

  jq -s '.[0] + .[1]' "$tmp_json" <(printf '%s' "$page_data") > "${tmp_json}.next"
  mv "${tmp_json}.next" "$tmp_json"
  page=$((page + 1))
done

jq 'sort_by(.name | ascii_downcase)' "$tmp_json" > "$JSON_OUT"

jq -r '.[] | [.name, (.language // ""), (.default_branch // ""), (.description // ""), .html_url] | @tsv' "$JSON_OUT" > "$TSV_OUT"

snapshot_date="$(date -u +%F)"
repo_count="$(jq 'length' "$JSON_OUT")"

{
  echo "# Repository Inventory"
  echo
  printf 'Organization: `%s`\n' "$ORG"
  echo
  printf 'Snapshot date (UTC): `%s`\n' "$snapshot_date"
  echo
  printf 'Repository count: `%s`\n' "$repo_count"
  echo
  echo "| Repo | Language | Default Branch | Description |"
  echo "|---|---|---|---|"
  jq -r '.[] | "| [\(.name)](\(.html_url)) | \((.language // "-")) | \((.default_branch // "-")) | \((.description // "-") | gsub("\\n"; " ")) |"' "$JSON_OUT"
} > "$MD_OUT"

echo "Wrote: $JSON_OUT"
echo "Wrote: $TSV_OUT"
echo "Wrote: $MD_OUT"
