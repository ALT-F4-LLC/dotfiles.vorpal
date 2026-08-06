#!/bin/bash
# Computes a stable digest for one `## <heading>` section of a markdown doc,
# so an issue's Source-digest citation can be recomputed and compared against
# the live source at transcription, fix-round re-check, and handoff time.
set -euo pipefail

usage() {
    echo "Usage: section_digest.sh <doc-path> '<heading>'" >&2
}

if [[ $# -ne 2 ]]; then
    usage
    exit 2
fi

doc_path="$1"
heading="$2"

if [[ ! -f "$doc_path" ]]; then
    echo "section_digest.sh: no such file: $doc_path" >&2
    exit 2
fi

section_body=$(awk -v heading="## ${heading}" '
    $0 == heading { found=1; next }
    found && /^## / { exit }
    found { print }
' "$doc_path")

if [[ -z "$section_body" ]] && ! grep -qxF "## ${heading}" "$doc_path"; then
    echo "section_digest.sh: heading not found: ## ${heading}" >&2
    exit 2
fi

printf '%s' "$section_body" | shasum -a 256 | cut -c1-12
