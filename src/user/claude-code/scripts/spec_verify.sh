#!/bin/bash
# Shared init-specs Step 3 "Verify" checks — validates generated docs/spec/*.md
# files against the Spawning Template's structural requirements. Chains
# `doc_validate.py --type spec` (frontmatter contract, maturity allow-list,
# >=3 H2 headings, "## Gaps & Risks" presence, mermaid diagram) for every check
# that is generic across docs/spec/ files, then applies the one check
# doc_validate.py cannot perform on its own: that last_updated matches this
# run's today_date (doc_validate.py has no notion of "today"; a mismatch means
# the agent ignored the pre-flight context, not a general frontmatter defect).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_VALIDATE="${SCRIPT_DIR}/doc_validate.py"

usage() {
    echo "Usage: spec_verify.sh <today_date> <file...>" >&2
    echo "  today_date: expected last_updated value, e.g. 2026-07-12" >&2
    echo "  Emits a PASS/FAIL line per file (failure reasons indented below it)." >&2
    echo "  Exits 0 if every file passes all checks, 1 if any file fails or is missing." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

TODAY="$1"
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "spec_verify.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

overall_status=0

for f in "$@"; do
    if [ ! -f "$f" ]; then
        echo "FAIL: $f"
        echo "  - missing (not found on disk)"
        overall_status=1
        continue
    fi

    reasons=()

    validate_output=$(python3 "$DOC_VALIDATE" --type spec "$f" 2>&1 >/dev/null)
    if [ -n "$validate_output" ]; then
        while IFS= read -r line; do
            reasons+=("$line")
        done <<< "$validate_output"
    fi

    if ! grep -qF "last_updated: \"${TODAY}\"" "$f"; then
        reasons+=("last_updated does not match \"${TODAY}\"")
    fi

    if [ "${#reasons[@]}" -eq 0 ]; then
        echo "PASS: $f"
    else
        echo "FAIL: $f"
        for r in "${reasons[@]}"; do
            echo "  - $r"
        done
        overall_status=1
    fi
done

exit "$overall_status"
