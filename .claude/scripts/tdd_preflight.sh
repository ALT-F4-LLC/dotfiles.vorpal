#!/bin/bash
# Chains check_citations.py <artifact.md> (path-citation existence check) with,
# when companion.md is given, a numbered-cross-reference reconciliation grep
# between the two docs (staff-engineer.md:90 "Numbered-cross-reference
# reconciliation") — catches renumbering drift between paired docs (e.g. a TDD
# and its companion ADR, or two files with a parity-locked block). Exits
# non-zero on any unresolved citation or cross-reference mismatch.
set -uo pipefail

usage() {
    echo "Usage: tdd_preflight.sh <artifact.md> [companion.md]" >&2
    exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

ARTIFACT="$1"
COMPANION="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "tdd_preflight.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

[ -f "$ARTIFACT" ] || {
    echo "tdd_preflight.sh: artifact not found: ${ARTIFACT}" >&2
    exit 1
}
if [ -n "$COMPANION" ]; then
    [ -f "$COMPANION" ] || {
        echo "tdd_preflight.sh: companion not found: ${COMPANION}" >&2
        exit 1
    }
fi

FAIL=0

echo "=== citations: ${ARTIFACT} ==="
python3 "${SCRIPT_DIR}/check_citations.py" "$ARTIFACT" --base "$REPO_ROOT"
[ "$?" -ne 0 ] && FAIL=1

if [ -n "$COMPANION" ]; then
    echo
    echo "=== citations: ${COMPANION} ==="
    python3 "${SCRIPT_DIR}/check_citations.py" "$COMPANION" --base "$REPO_ROOT"
    [ "$?" -ne 0 ] && FAIL=1

    echo
    echo "=== numbered cross-reference reconciliation: ${ARTIFACT} <-> ${COMPANION} ==="

    # Label vocabulary for numbered cross-references, case-insensitive:
    # "§3.2", "step 6", "decision 4", "item (3)", "criterion 2".
    REF_PATTERN='(§|[Ss]tep|[Dd]ecision|[Ii]tem|[Cc]riterion)[[:space:]]*\(?#?[[:space:]]*[0-9]+(\.[0-9]+)*'
    ANCHOR_HEADING_PATTERN='^#{1,6}[[:space:]]+(§[[:space:]]*)?[0-9]+(\.[0-9]+)*'
    ANCHOR_LABEL_PATTERN='^\**(Decision|Step|Item|Criterion)[[:space:]]+\(?[0-9]+(\.[0-9]+)*\)?'

    extract_refs() {
        grep -ohE "$REF_PATTERN" "$1" | grep -oE '[0-9]+(\.[0-9]+)*' | sort -u
    }

    extract_anchors() {
        {
            grep -ohE "$ANCHOR_HEADING_PATTERN" "$1" | grep -oE '[0-9]+(\.[0-9]+)*'
            grep -ohE "$ANCHOR_LABEL_PATTERN" "$1" | grep -oE '[0-9]+(\.[0-9]+)*'
        } | sort -u
    }

    ARTIFACT_REFS=$(extract_refs "$ARTIFACT")
    COMPANION_REFS=$(extract_refs "$COMPANION")
    ARTIFACT_ANCHORS=$(extract_anchors "$ARTIFACT")
    COMPANION_ANCHORS=$(extract_anchors "$COMPANION")
    ALL_ANCHORS=$(printf '%s\n%s\n' "$ARTIFACT_ANCHORS" "$COMPANION_ANCHORS" | sort -u)

    MISMATCH=0
    check_refs_against_anchors() {
        local refs="$1" label="$2"
        [ -z "$refs" ] && return
        while IFS= read -r num; do
            [ -z "$num" ] && continue
            if ! printf '%s\n' "$ALL_ANCHORS" | grep -qxF "$num"; then
                echo "  MISSING: ${label} references '${num}' — no matching numbered anchor found in either doc"
                MISMATCH=1
            fi
        done <<< "$refs"
    }

    check_refs_against_anchors "$ARTIFACT_REFS" "$ARTIFACT"
    check_refs_against_anchors "$COMPANION_REFS" "$COMPANION"

    if [ "$MISMATCH" -eq 0 ]; then
        echo "  OK: all numbered cross-references resolved against anchors in either doc"
    else
        FAIL=1
    fi
fi

echo
if [ "$FAIL" -ne 0 ]; then
    echo "tdd_preflight.sh: FAIL (see above)"
    exit 1
fi
echo "tdd_preflight.sh: OK"
exit 0
