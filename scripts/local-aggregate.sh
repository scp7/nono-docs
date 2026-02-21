#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

BASE_DOCS_DIR="${BASE_DOCS_DIR:-${REPO_ROOT}/docs}"
CLI_REPO_DIR="${CLI_REPO_DIR:-${REPO_ROOT}/../nono}"
PY_REPO_DIR="${PY_REPO_DIR:-${REPO_ROOT}/../nono-py}"
TS_REPO_DIR="${TS_REPO_DIR:-${REPO_ROOT}/../nono-ts}"
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/.local-aggregate}"
OUT_DOCS_DIR="${OUT_DIR}/output"

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Missing required file: $1" >&2
    exit 1
  fi
}

require_dir() {
  if [[ ! -d "$1" ]]; then
    echo "Missing required directory: $1" >&2
    exit 1
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but was not found in PATH." >&2
  exit 1
fi

require_dir "${BASE_DOCS_DIR}"
require_file "${BASE_DOCS_DIR}/docs.json"
require_dir "${CLI_REPO_DIR}/docs/cli"
require_file "${CLI_REPO_DIR}/docs/docs.json"
require_dir "${PY_REPO_DIR}/docs/python"
require_file "${PY_REPO_DIR}/docs/docs.json"
require_dir "${TS_REPO_DIR}/docs/typescript"
require_file "${TS_REPO_DIR}/docs/docs.json"

rm -rf "${OUT_DOCS_DIR}"
mkdir -p "${OUT_DOCS_DIR}"

cp -R "${BASE_DOCS_DIR}/." "${OUT_DOCS_DIR}/"
cp -R "${CLI_REPO_DIR}/docs/cli" "${OUT_DOCS_DIR}/"
cp -R "${PY_REPO_DIR}/docs/python" "${OUT_DOCS_DIR}/"
cp -R "${TS_REPO_DIR}/docs/typescript" "${OUT_DOCS_DIR}/"

jq --slurpfile cli "${CLI_REPO_DIR}/docs/docs.json" \
   --slurpfile py "${PY_REPO_DIR}/docs/docs.json" \
   --slurpfile ts "${TS_REPO_DIR}/docs/docs.json" \
   '
   ($cli[0].navigation.groups) as $cli_groups |
   ($py[0].navigation.groups) as $py_groups |
   ($ts[0].navigation.groups) as $ts_groups |
   .navigation.tabs |= map(
     if .tab == "CLI" then .groups = $cli_groups
     elif .tab == "Python" then .groups = $py_groups
     elif .tab == "TypeScript" then .groups = $ts_groups
     else .
     end
   )
   ' "${OUT_DOCS_DIR}/docs.json" > "${OUT_DOCS_DIR}/docs.json.tmp"
mv "${OUT_DOCS_DIR}/docs.json.tmp" "${OUT_DOCS_DIR}/docs.json"

echo "Local aggregate complete:"
echo "  ${OUT_DOCS_DIR}"
echo
echo "To preview:"
echo "  cd \"${OUT_DOCS_DIR}\" && mintlify dev"
