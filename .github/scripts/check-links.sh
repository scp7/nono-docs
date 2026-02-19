#!/usr/bin/env bash
# Check for broken internal links in the aggregated nono docs output.
#
# Scans all .mdx files in the output directory for:
#   - Internal hrefs (href="/...")
#   - Image/asset references (src="/..." or ![...](/...))
#   - Navigation entries in docs.json
#
# Validates each against the set of files that actually exist in the output.
# Exits 1 if any broken references are found.
#
# Usage: check-links.sh [output-dir]
set -euo pipefail

OUTPUT_DIR="${1:-output}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  echo "ERROR: '$OUTPUT_DIR' directory not found. Run from the repo root after aggregation." >&2
  exit 1
fi

# Temp files for valid path/asset sets and collected errors
VALID_PATHS=$(mktemp)
VALID_ASSETS=$(mktemp)
ERRORS=$(mktemp)
trap 'rm -f "$VALID_PATHS" "$VALID_ASSETS" "$ERRORS"' EXIT

# Build set of valid doc paths from .mdx files
find "$OUTPUT_DIR" -name "*.mdx" | sort | while IFS= read -r f; do
  rel="${f#"$OUTPUT_DIR"/}"
  # /cli/internals/security-model
  echo "/${rel%.mdx}"
  # index files also reachable as parent: /cli/internals
  if [[ "$rel" == */index.mdx ]]; then
    echo "/${rel%/index.mdx}"
  fi
done | sort -u > "$VALID_PATHS"

# Build set of valid asset paths (non-.mdx files)
find "$OUTPUT_DIR" -type f ! -name "*.mdx" | sort | while IFS= read -r f; do
  echo "/${f#"$OUTPUT_DIR"/}"
done | sort -u > "$VALID_ASSETS"

err() { echo "  $*" >> "$ERRORS"; }

check_path() {
  local path="${1%%#*}"  # strip anchor
  path="${path%/}"       # strip trailing slash
  [[ -z "$path" ]] && path="/"
  grep -qxF "$path" "$VALID_PATHS"
}

check_asset() {
  grep -qxF "$1" "$VALID_ASSETS"
}

# Check docs.json navigation entries
DOCS_JSON="$OUTPUT_DIR/docs.json"
if [[ -f "$DOCS_JSON" ]]; then
  while IFS= read -r page; do
    path="/$page"
    if ! check_path "$path"; then
      err "docs.json: nav entry '$path' has no corresponding .mdx file"
    fi
  done < <(jq -r '.. | objects | .pages? // empty | .[]? | select(type == "string")' "$DOCS_JSON")
fi

# Check each .mdx file for broken hrefs and asset references
while IFS= read -r mdx_file; do
  label="${mdx_file#"$OUTPUT_DIR"/}"

  # Internal hrefs: href="/..."
  while IFS= read -r raw; do
    if ! check_path "$raw"; then
      path="${raw%%#*}"; path="${path%/}"
      err "$label: broken href '$raw' (no page at '$path')"
    fi
  done < <(grep -oP 'href="\K(/[^"#][^"]*)' "$mdx_file" 2>/dev/null || true)

  # Markdown images: ![alt](/path)
  while IFS= read -r asset; do
    if ! check_asset "$asset"; then
      err "$label: broken image '![...]($asset)'"
    fi
  done < <(grep -oP '!\[[^\]]*\]\(\K(/[^)#\s]+)' "$mdx_file" 2>/dev/null || true)

  # HTML/JSX src attributes: src="/..."
  while IFS= read -r asset; do
    if ! check_asset "$asset"; then
      err "$label: broken src '$asset'"
    fi
  done < <(grep -oP '\bsrc="\K(/[^"]+)' "$mdx_file" 2>/dev/null || true)

done < <(find "$OUTPUT_DIR" -name "*.mdx" | sort)

# Report
NUM_PATHS=$(wc -l < "$VALID_PATHS")
NUM_ASSETS=$(wc -l < "$VALID_ASSETS")
NUM_ERRORS=$(wc -l < "$ERRORS" | tr -d ' ')

if [[ "$NUM_ERRORS" -gt 0 ]]; then
  echo "Found $NUM_ERRORS broken reference(s):"
  echo ""
  cat "$ERRORS"
  echo ""
  exit 1
fi

echo "OK: all internal links valid ($NUM_PATHS pages, $NUM_ASSETS assets checked)"
