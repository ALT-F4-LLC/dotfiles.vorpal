#!/bin/bash
# Cumulative-diff attribution for review: resolves an issue's declared file
# set via `docket issue file list`, emits the in-scope diff for those files,
# then a remainder listing of changed files OUTSIDE the declared set —
# replacing the manual issue-file-list-vs-diff cross-reference that
# security-engineer/staff-engineer/sdet review workflows previously did by
# hand. Diff scope is the unstaged working tree (git diff, no --cached),
# matching this repo's shared-tree self-review convention (never `git add`
# to inspect — see self_review_scan.sh).
#
# `git diff` never reports untracked (not-yet-`git add`ed) files, so they are
# unioned in separately via `git ls-files --others --exclude-standard`
# (mirroring self_review_scan.sh's untracked handling): a declared-but-
# untracked file is shown via `git diff --no-index` against /dev/null (the
# whole file as added lines) instead of `git diff`, and an undeclared-but-
# untracked file falls into the remainder listing like any other change.
set -euo pipefail

usage() {
    echo "Usage: phase_diff.sh <issue-id>" >&2
    echo "" >&2
    echo "  Resolves <issue-id>'s declared file set via 'docket issue file" >&2
    echo "  list', emits the in-scope diff (git diff -- <declared files>)," >&2
    echo "  then a remainder listing of changed files outside that set." >&2
    echo "  No declared files -> everything changed is remainder." >&2
    exit 2
}

[ "$#" -eq 1 ] || usage
case "$1" in
    -h|--help) usage ;;
esac

ISSUE_ID="$1"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "phase_diff.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

FILE_LIST_JSON=$(docket issue file list "$ISSUE_ID" --json) || {
    echo "phase_diff.sh: failed to list files for ${ISSUE_ID}" >&2
    exit 1
}

DECLARED_FILES=()
while IFS= read -r f; do
    if [ -n "$f" ]; then
        DECLARED_FILES+=("$f")
    fi
done < <(printf '%s' "$FILE_LIST_JSON" | jq -r '.data[]?')

CHANGED_FILES=()
while IFS= read -r f; do
    if [ -n "$f" ]; then
        CHANGED_FILES+=("$f")
    fi
done < <(git diff --name-only)

UNTRACKED_FILES=()
while IFS= read -r f; do
    if [ -n "$f" ]; then
        UNTRACKED_FILES+=("$f")
    fi
done < <(git ls-files --others --exclude-standard)

if [ "${#UNTRACKED_FILES[@]}" -gt 0 ]; then
    CHANGED_FILES+=("${UNTRACKED_FILES[@]}")
fi

# is_untracked <file>: true if <file> is in UNTRACKED_FILES (guards the
# empty-array case — bash 3.2's `set -u` treats `"${arr[@]}"` on a
# zero-element array as an unbound-variable error).
is_untracked() {
    local f="$1" u
    if [ "${#UNTRACKED_FILES[@]}" -eq 0 ]; then
        return 1
    fi
    for u in "${UNTRACKED_FILES[@]}"; do
        [ "$f" = "$u" ] && return 0
    done
    return 1
}

echo "=== phase_diff: ${ISSUE_ID} ==="
echo "Declared files: ${#DECLARED_FILES[@]}"
echo "Changed files (working tree): ${#CHANGED_FILES[@]}"
echo ""

if [ "${#DECLARED_FILES[@]}" -eq 0 ]; then
    echo "--- In-scope diff (declared files) ---"
    echo "(none — issue has no declared files)"
    echo ""
    echo "--- Remainder (changed files outside declared scope) ---"
    if [ "${#CHANGED_FILES[@]}" -eq 0 ]; then
        echo "(none — working tree is clean)"
    else
        printf '%s\n' "${CHANGED_FILES[@]}"
    fi
    exit 0
fi

echo "--- In-scope diff (declared files) ---"
TRACKED_DECLARED=()
UNTRACKED_DECLARED=()
for f in "${DECLARED_FILES[@]}"; do
    if is_untracked "$f"; then
        UNTRACKED_DECLARED+=("$f")
    else
        TRACKED_DECLARED+=("$f")
    fi
done

if [ "${#TRACKED_DECLARED[@]}" -gt 0 ]; then
    git diff -- "${TRACKED_DECLARED[@]}"
fi
if [ "${#UNTRACKED_DECLARED[@]}" -gt 0 ]; then
    for f in "${UNTRACKED_DECLARED[@]}"; do
        git diff --no-index -- /dev/null "$f" || true
    done
fi

echo ""
echo "--- Remainder (changed files outside declared scope) ---"
REMAINDER=()
if [ "${#CHANGED_FILES[@]}" -gt 0 ]; then
    for f in "${CHANGED_FILES[@]}"; do
        is_declared=0
        for d in "${DECLARED_FILES[@]}"; do
            if [ "$f" = "$d" ]; then
                is_declared=1
                break
            fi
        done
        if [ "$is_declared" -eq 0 ]; then
            REMAINDER+=("$f")
        fi
    done
fi

if [ "${#REMAINDER[@]}" -eq 0 ]; then
    echo "(none — all changed files are within declared scope)"
else
    printf '%s\n' "${REMAINDER[@]}"
fi
