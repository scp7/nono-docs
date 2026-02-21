#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DOCS_DIR="${1:-${REPO_ROOT}/.local-aggregate/output}"

if [[ ! -d "${DOCS_DIR}" ]]; then
  echo "Docs directory not found: ${DOCS_DIR}" >&2
  echo "Run ./scripts/local-aggregate.sh first, or pass a docs directory path." >&2
  exit 1
fi

tmp_routes="$(mktemp)"
tmp_missing="$(mktemp)"
trap 'rm -f "${tmp_routes}" "${tmp_missing}"' EXIT

rg --files "${DOCS_DIR}" -g '*.mdx' | while read -r file; do
  perl -ne '
    while (/href="(\/[^"]+)"/g) { print "$1\n"; }
    while (/\]\((\/[^)]+)\)/g) { print "$1\n"; }
  ' "${file}"
done | sed -E 's/[#?].*$//' | sort -u > "${tmp_routes}"

while read -r route; do
  [[ -z "${route}" ]] && continue

  case "${route}" in
    /assets/*|/logo/*|/favicon*|/mintlify*)
      continue
      ;;
  esac

  page="${route#/}"
  if [[ ! -f "${DOCS_DIR}/${page}.mdx" && ! -f "${DOCS_DIR}/${page}/index.mdx" && ! -f "${DOCS_DIR}/${page}" ]]; then
    echo "MISSING: ${route}" >> "${tmp_missing}"
  fi
done < "${tmp_routes}"

if [[ -s "${tmp_missing}" ]]; then
  echo "Broken internal doc links found:"
  cat "${tmp_missing}"
  exit 1
fi

echo "OK: No missing internal doc routes found in ${DOCS_DIR}"
