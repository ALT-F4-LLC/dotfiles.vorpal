#!/bin/bash
# Shared init-specs Step 3 "Verify" checks — validates generated docs/spec/*.md
# files against the Spawning Template's structural requirements. Previously five
# checks hand-typed inline in SKILL.md (target-set existence, frontmatter delimiter,
# and three `grep -L` checks for mermaid/last_updated/Gaps & Risks), which meant
# hand-inverting `grep -L` (files-WITHOUT-a-match) semantics five times over — a
# recurring source of subtle inversion bugs. Encoded once here as direct
# pass/fail conditions instead (no `-L` inversion to get wrong).
set -uo pipefail

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

    first_line=$(head -1 "$f")
    if [ "$first_line" != "---" ]; then
        reasons+=("malformed frontmatter (first line is not ---)")
    fi

    if ! grep -q '```mermaid' "$f"; then
        reasons+=("missing mermaid diagram")
    fi

    if ! grep -qF "last_updated: \"${TODAY}\"" "$f"; then
        reasons+=("last_updated does not match \"${TODAY}\"")
    fi

    if ! grep -q '^## Gaps & Risks' "$f"; then
        reasons+=("missing '## Gaps & Risks' section")
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
