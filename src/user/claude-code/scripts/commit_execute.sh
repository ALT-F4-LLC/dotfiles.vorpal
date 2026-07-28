#!/bin/bash
# Consolidates commit/SKILL.md Steps 1, 4, and 5 (plus a call into Step 3's
# commit_msg_check.sh) into one script invocation, so Step 5's Sandbox-context
# invariant holds BY CONSTRUCTION: precheck -> validate -> stage -> commit ->
# verify all run inside a single Bash call, so no cross-call $TMPDIR
# divergence is possible between writing the draft and consuming it.
#
# Pipeline:
#   1. Pathspec validation: reject any operand containing a glob
#      metacharacter (*, ?, [), git's `:` magic-pathspec prefix, a bare
#      '-A'/'--all' flag, one that resolves to the repo root, or one whose
#      resolved path does not exist on disk.
#   2. Dirty-index precheck: abort if the index already holds staged
#      content OUTSIDE the given fileset.
#   3. commit_msg_check.sh <draft-file> — forbidden-content gate.
#   4. Non-blank assertion: reject a draft that is empty or contains only
#      whitespace.
#   5. Scoped `git add -- <files>`.
#   6. Staged-set equality check: the post-add staged set must equal the
#      pre-add pending-change set scoped to <files> — fails loudly (non-zero
#      exit + message), never eyeballed.
#   7. `git commit --cleanup=verbatim -F <draft-file>`.
#   8. Post-commit byte-compare of `git log -1 --format=%B` against the
#      draft file — fails loudly on mismatch; never self-fixes with --amend.
#
# UNWIRED (2026-07-28, DKT-168 fix round): this script is authored but not
# yet invoked from commit/SKILL.md, which still runs its original hand-run
# Steps 1/4/5. Known gap, tracked as DKT-175: guard-no-commit-hook.sh
# pattern-matches literal Bash command text for git add/commit/push, and
# ~/.claude/settings.json's permissions.ask prefix-matchers do the same —
# both are blind to git writes executed INSIDE this script, in every
# permission mode (auto/default/acceptEdits/bypassPermissions). This
# script's own checks below (pathspec validation, index scoping, draft
# non-blank/message-content validation, staged-set equality) ARE genuine
# safety properties of the pipeline itself — pathspec validation now rejects
# glob metacharacters and non-existent resolved paths (2026-07-28 fix round
# 2), closing the whole-repo-sweep gap a bare repo-root/`:`-prefix denylist
# left open. They are NOT a substitute for the missing external
# permission-mode enforcement described above.
set -uo pipefail

usage() {
    echo "Usage: commit_execute.sh <draft-file> <file1> [file2 ...]" >&2
    echo "" >&2
    echo "  Runs commit/SKILL.md Steps 1, 4, 5 (and Step 3's forbidden-" >&2
    echo "  content check) as one pipeline against the already-drafted" >&2
    echo "  <draft-file>. Never runs git push or git commit --amend." >&2
    echo "  Exits 0 on a clean commit, non-zero with a Blocked: message" >&2
    echo "  on any gate failure, 2 on usage error." >&2
    exit 2
}

[ "$#" -ge 2 ] || usage

DRAFT_FILE="$1"
shift
FILES=("$@")

[ -f "$DRAFT_FILE" ] || {
    echo "commit_execute.sh: draft file not found: $DRAFT_FILE" >&2
    exit 2
}

# --cleanup=verbatim below (required to make the post-commit byte-compare
# exact) disables git's own refusal of an empty/whitespace-only message, so
# that gate has to be reproduced here explicitly.
NONBLANK=$(tr -d '[:space:]' < "$DRAFT_FILE")
[ -n "$NONBLANK" ] || {
    echo "Blocked: draft commit message is empty or contains only whitespace ($DRAFT_FILE) — write real commit message content before invoking Skill(commit)." >&2
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_tool() {
    local name="$1"
    local candidate="${SCRIPT_DIR}/${name}"
    if [ -f "$candidate" ]; then
        echo "$candidate"
        return 0
    fi
    candidate="$HOME/.claude/scripts/${name}"
    if [ -f "$candidate" ]; then
        echo "$candidate"
        return 0
    fi
    return 1
}

COMMIT_MSG_CHECK=$(resolve_tool commit_msg_check.sh) || {
    echo "commit_execute.sh: commit_msg_check.sh not found (checked ${SCRIPT_DIR} and ~/.claude/scripts)" >&2
    exit 2
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "commit_execute.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

for f in "${FILES[@]}"; do
    case "$f" in
        -A|--all)
            echo "commit_execute.sh: refusing bare pathspec '$f' — name explicit files or directories" >&2
            exit 2
            ;;
        :*)
            echo "commit_execute.sh: refusing magic pathspec '$f' — name explicit files or directories" >&2
            exit 2
            ;;
        *[\*\?\[]*)
            echo "commit_execute.sh: refusing pathspec '$f' — contains a glob metacharacter (*, ?, or [); name explicit files or directories" >&2
            exit 2
            ;;
    esac
    RESOLVED=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$f") || {
        echo "commit_execute.sh: cannot resolve pathspec '$f'" >&2
        exit 2
    }
    if [ "$RESOLVED" = "$REPO_ROOT" ]; then
        echo "commit_execute.sh: refusing pathspec '$f' — resolves to repo root, name explicit files or directories" >&2
        exit 2
    fi
    [ -e "$RESOLVED" ] || {
        echo "commit_execute.sh: refusing pathspec '$f' — resolved path does not exist on disk ($RESOLVED)" >&2
        exit 2
    }
done

# --- Step 1: dirty-index precheck ------------------------------------------

STAGED_ALL_BEFORE=$(git diff --cached --name-only) || {
    echo "commit_execute.sh: git diff --cached failed — aborting, cannot verify index state" >&2
    exit 1
}
STAGED_IN_SCOPE_BEFORE=$(git diff --cached --name-only -- "${FILES[@]}") || {
    echo "commit_execute.sh: git diff --cached (scoped) failed — aborting, cannot verify index state" >&2
    exit 1
}
OUT_OF_SCOPE=$(comm -23 \
    <(printf '%s\n' "$STAGED_ALL_BEFORE" | sed '/^$/d' | sort) \
    <(printf '%s\n' "$STAGED_IN_SCOPE_BEFORE" | sed '/^$/d' | sort))

if [ -n "$OUT_OF_SCOPE" ]; then
    echo "Blocked: index already has staged changes ($(printf '%s' "$OUT_OF_SCOPE" | tr '\n' ' ')) that are not part of this commit's fileset. Resolve (unstage or hand off) before invoking Skill(commit) — never commit through someone else's staged work." >&2
    exit 1
fi

# Expected post-add fileset: everything with a pending change (staged,
# unstaged, or untracked) scoped to the given pathspecs, captured BEFORE
# `git add` runs. --untracked-files=all expands untracked directories to
# their individual files, matching what `git add` actually stages — the
# default mode collapses an untracked dir to one "?? dir/" line, which
# would false-positive-mismatch against the per-file staged set below.
EXPECTED_FILESET=$(git status --porcelain --untracked-files=all -- "${FILES[@]}" \
    | sed -E 's/^.{3}//; s/.* -> //' \
    | sort -u) || {
    echo "commit_execute.sh: git status failed — aborting, cannot verify index state" >&2
    exit 1
}

# --- Step 3 (of SKILL.md): forbidden-content gate --------------------------

"$COMMIT_MSG_CHECK" "$DRAFT_FILE" || {
    echo "commit_execute.sh: aborting — draft failed commit_msg_check.sh" >&2
    exit 1
}

# --- Step 4: scoped stage + staged-set equality check ----------------------

git add -- "${FILES[@]}" || {
    echo "commit_execute.sh: git add failed — nothing committed" >&2
    exit 1
}

ACTUAL_STAGED=$(git diff --cached --name-only | sort -u)

if [ "$ACTUAL_STAGED" != "$EXPECTED_FILESET" ]; then
    echo "Blocked: staged fileset does not match the intended scope after \`git add\` (staged: $(printf '%s' "$ACTUAL_STAGED" | tr '\n' ' ')| intended: $(printf '%s' "$EXPECTED_FILESET" | tr '\n' ' ')) — index changed concurrently. Re-run from Step 1." >&2
    exit 1
fi

# --- Step 5: commit + post-commit byte-compare ------------------------------

# --cleanup=verbatim: git's default cleanup strips trailing whitespace and
# collapses consecutive blank lines before committing, which would make a
# benign draft false-positive against the raw byte-compare below. Verbatim
# disables that transform so the committed message matches the draft
# byte-for-byte with no compare-side normalization needed.
git commit --cleanup=verbatim -F "$DRAFT_FILE" || {
    echo "commit_execute.sh: git commit failed — index left staged, nothing committed" >&2
    exit 1
}

COMMIT_SHA=$(git rev-parse HEAD)
ACTUAL_MSG=$(git log -1 --format=%B "$COMMIT_SHA")
EXPECTED_MSG=$(cat "$DRAFT_FILE")

if [ "$ACTUAL_MSG" != "$EXPECTED_MSG" ]; then
    echo "Blocked: post-commit message mismatch — commit ${COMMIT_SHA} does not match the checked draft. Do not amend; report this SHA to the calling agent for explicit operator authorization to fix." >&2
    exit 1
fi

echo "commit_execute.sh: committed ${COMMIT_SHA}"
git log -1 --format='%s' "$COMMIT_SHA"
