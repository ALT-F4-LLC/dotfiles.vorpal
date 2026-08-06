#!/bin/bash
# Mechanizes the "Tree-state fingerprint" carry-forward comparison documented
# in verify-ac/SKILL.md Pre-flight §3a and code-review-verdict/SKILL.md's
# Round-N re-review recipe: given the fingerprint recorded in a PRIOR report
# and the fingerprint of the CURRENT tree (both `<rev>[+dirty:<sha12>]`, the
# format both skills' FULL Output templates emit via tree_fingerprint.sh --
# repo: src/user/claude-code/scripts/tree_fingerprint.sh), decides which
# prior findings carry forward vs. require re-verification.
#
# The two fingerprint components compare independently, per the documented
# recipe:
#   - rev: `git diff --name-only <prior-rev>..<current-rev>` enumerates
#     exactly which files moved between the two recorded commits -- carry
#     forward any evidence path absent from that list.
#   - dirty (`+dirty:<sha12>`, present only when the tree had uncommitted
#     changes at recording time): a hash-equality check only -- a dirty-hash
#     mismatch means the uncommitted diff itself changed since the prior
#     round, which cannot be localized to specific files from the hash
#     alone, so it conservatively re-verifies everything.
#
# Invocation:
#   verify_carry_forward.sh <prior-fingerprint> <current-fingerprint> [evidence-path ...]
# - Fingerprints: `<rev>` or `<rev>+dirty:<sha12>` (e.g. `a1b2c3d` or
#   `a1b2c3d+dirty:7ce0e4734cb4`); `<current-fingerprint>`'s rev may be `HEAD`.
# - [evidence-path ...]: optional, one or more per-criterion evidence paths.
#   Omit for a whole-tree changed-file summary.
#
# Output: one `[CARRY-FORWARD]` or `[RE-VERIFY]` line per evidence path (or a
# whole-tree summary when no paths are given).
# Exit 0: nothing needs re-verification. Exit 1: at least one thing does.
# Exit 2: usage or git error.
set -euo pipefail

usage() {
    echo "Usage: verify_carry_forward.sh <prior-fingerprint> <current-fingerprint> [evidence-path ...]" >&2
    exit 2
}

[ "$#" -ge 2 ] || usage

PRIOR="$1"
CURRENT="$2"
shift 2

git rev-parse --show-toplevel >/dev/null 2>&1 || {
    echo "verify_carry_forward.sh: not inside a git repository" >&2
    exit 2
}

rev_of() {
    case "$1" in
        *+dirty:*) echo "${1%%+dirty:*}" ;;
        *) echo "$1" ;;
    esac
}

dirty_of() {
    case "$1" in
        *+dirty:*) echo "${1#*+dirty:}" ;;
        *) echo "" ;;
    esac
}

if [ "$PRIOR" = "$CURRENT" ]; then
    echo "[CARRY-FORWARD] fingerprint unchanged (${PRIOR}) -- all prior findings carry forward"
    exit 0
fi

PRIOR_REV=$(rev_of "$PRIOR")
CURRENT_REV=$(rev_of "$CURRENT")
PRIOR_DIRTY=$(dirty_of "$PRIOR")
CURRENT_DIRTY=$(dirty_of "$CURRENT")

for rev in "$PRIOR_REV" "$CURRENT_REV"; do
    git cat-file -e "${rev}^{commit}" 2>/dev/null || {
        echo "verify_carry_forward.sh: rev '${rev}' not found in this repository" >&2
        exit 2
    }
done

DIRTY_CHANGED=0
[ "$PRIOR_DIRTY" = "$CURRENT_DIRTY" ] || DIRTY_CHANGED=1

CHANGED_FILES=""
if [ "$PRIOR_REV" != "$CURRENT_REV" ]; then
    # --name-only (not --stat): --stat truncates long paths with "..." to fit
    # terminal width, which would break the exact-match check against
    # evidence paths below.
    if ! CHANGED_FILES=$(git diff --name-only "${PRIOR_REV}..${CURRENT_REV}" | sort -u); then
        echo "verify_carry_forward.sh: git diff --name-only ${PRIOR_REV}..${CURRENT_REV} failed" >&2
        exit 2
    fi
fi

ANY_REVERIFY=0

if [ "$#" -eq 0 ]; then
    if [ "$DIRTY_CHANGED" -eq 1 ]; then
        echo "[RE-VERIFY] working tree dirty-hash changed since prior round ('${PRIOR_DIRTY:-none}' -> '${CURRENT_DIRTY:-none}') -- cannot enumerate specific files for this component, re-run all evidence"
        ANY_REVERIFY=1
    fi
    if [ -n "$CHANGED_FILES" ]; then
        echo "[RE-VERIFY] files changed between ${PRIOR_REV}..${CURRENT_REV}:"
        echo "$CHANGED_FILES" | sed 's/^/  /'
        ANY_REVERIFY=1
    fi
    if [ "$ANY_REVERIFY" -eq 0 ]; then
        echo "[CARRY-FORWARD] rev unchanged (${PRIOR_REV}) and no dirty-hash change -- all prior findings carry forward"
        exit 0
    fi
    exit 1
fi

for path in "$@"; do
    if [ "$DIRTY_CHANGED" -eq 1 ]; then
        echo "[RE-VERIFY] ${path} (dirty-hash changed, cannot rule out)"
        ANY_REVERIFY=1
        continue
    fi

    # Normalize through git's own pathspec resolution so a `./`-prefixed
    # path, an absolute path, or git's quoting of a non-ASCII path still
    # matches the repo-root-relative form `git diff --name-only` emits
    # above. A path git cannot resolve (unknown to git, or untracked) is
    # never silently carried forward -- it re-verifies instead.
    RESOLVED=$(git ls-files --full-name -- "$path" 2>/dev/null | head -n1) || true
    if [ -z "$RESOLVED" ]; then
        echo "[RE-VERIFY] ${path} (unresolvable via git -- cannot rule out)"
        ANY_REVERIFY=1
    elif [ -n "$CHANGED_FILES" ] && echo "$CHANGED_FILES" | grep -qxF "$RESOLVED"; then
        echo "[RE-VERIFY] ${path}"
        ANY_REVERIFY=1
    else
        echo "[CARRY-FORWARD] ${path}"
    fi
done

[ "$ANY_REVERIFY" -eq 0 ]
