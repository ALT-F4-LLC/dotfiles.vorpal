#!/bin/bash
# Shared "Tree-state fingerprint" recipe for the report-emission skill family
# (code-review-verdict, verify-ac), previously hand-duplicated in each
# skill's report template as `git diff HEAD | shasum` (first 12 hex chars).
# Prints the fingerprint used for a report's `+dirty:<sha12>` field and for
# Round-N / G5 carry-forward comparison against a prior recorded fingerprint.
#
# The fingerprint hashes `git diff HEAD` (tracked changes, staged and
# unstaged) plus, for every untracked file (`git ls-files --others
# --exclude-standard`), its repo-root-relative path and blob content --
# `git diff HEAD` alone is blind to untracked files, so without this an
# edit to a new, not-yet-tracked file would leave the fingerprint
# unchanged. Both inputs are already git's own stable sort order, so the
# combination is deterministic for a given tree state.
#
# .claude/agent-memory/ is excluded from the untracked-file fold: it's
# agent orchestration bookkeeping (pitfalls.md, dispatch-ledger.md) written
# mid-cycle, not code under review -- folding it in made the fingerprint
# change on every write to it, defeating Round-N/G5 carry-forward.
#
# Invocation: ~/.claude/scripts/tree_fingerprint.sh (no args, no flags)
# Prints exactly the 12-char fingerprint to stdout with a trailing newline.
# Callers decide when to invoke it (e.g. only when `git status --porcelain`
# is non-empty -- unlike `git diff HEAD`, this also catches untracked
# files) and how to format it (e.g. `+dirty:<output>`).
set -euo pipefail

if [ "$#" -gt 0 ]; then
    echo "Usage: tree_fingerprint.sh (no arguments)" >&2
    exit 2
fi

git rev-parse --show-toplevel >/dev/null 2>&1 || {
    echo "tree_fingerprint.sh: not inside a git repository" >&2
    exit 2
}

TOPLEVEL=$(git rev-parse --show-toplevel)

{
    git diff HEAD
    git ls-files --others --exclude-standard --full-name | while IFS= read -r f; do
        case "$f" in
            .claude/agent-memory/*) continue ;;
        esac
        printf '%s\n' "$f"
        git hash-object -- "${TOPLEVEL}/${f}"
    done
} | shasum | cut -c1-12
