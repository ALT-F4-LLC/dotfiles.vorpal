#!/bin/bash

# Behavior suite for .docket/bin/citation-check.
#
# THE PROPERTY UNDER TEST: a design doc changed by this step, committed or
# not, is read and must cite evidence. The engine reruns the gate after the
# executor commits, so a selection built from the working tree alone sees
# nothing and passes vacuously; DOCKET_GATE_BASE names the commit the step
# started from, and the committed range base..HEAD joins the uncommitted
# sources. Running as its own gate (DOCKET_GATE=citation-check) without a
# resolvable base fails closed with exit 2; any other caller without a base
# keeps the working-tree scan.
#
# SEAM. Each case builds a throwaway git repo under $TMPDIR with the gate
# copied into its own .docket/bin/ (the gate resolves its repo root from its
# own location, so the copy scans the fixture, never the real worktree).

set -uo pipefail

unset DOCKET_GATE DOCKET_GATE_BASE

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${REPO_ROOT}/.docket/bin/citation-check"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$GATE" ] || fatal "gate not found at ${GATE}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/citation-check-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_repo <dir>: a git repo with the gate under .docket/bin/ and one
# committed, cited design doc.
build_repo() {
    local dir="$1"
    mkdir -p "${dir}/.docket/bin" "${dir}/docs/design"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@test
    git -C "$dir" config user.name test
    cp "$GATE" "${dir}/.docket/bin/citation-check"
    chmod +x "${dir}/.docket/bin/citation-check"
    printf '# Cited\n\nSee DOT-1.\n' > "${dir}/docs/design/cited.md"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m init || fatal "fixture commit failed in ${dir}"
}

UNCITED=$'# Uncited\n\nA claim with no evidence.\n'

# run_gate <dir> [VAR=value ...]: runs the fixture's gate with only the
# named DOCKET_* variables set; sets RC, OUT, ERR.
run_gate() {
    local dir="$1"
    shift
    env -u DOCKET_GATE -u DOCKET_GATE_BASE "$@" \
        "${dir}/.docket/bin/citation-check" > "${WORK}/out" 2> "${WORK}/err"
    RC=$?
    OUT=$(cat "${WORK}/out")
    ERR=$(cat "${WORK}/err")
}

expect_uncited() { # <label> <file>
    if [ "$RC" -eq 1 ] && printf '%s' "$ERR" | grep -qF "$2"; then
        pass "$1"
    else
        fail "$1 (rc=${RC}, stdout=${OUT}, stderr=${ERR})"
    fi
}

# AC1: a committed uncited doc in base..HEAD is checked.
repo="${WORK}/committed"
build_repo "$repo"
base=$(git -C "$repo" rev-parse HEAD)
printf '%s' "$UNCITED" > "${repo}/docs/design/committed.md"
git -C "$repo" add -A
git -C "$repo" commit -q -m doc || fatal "commit failed"
run_gate "$repo" DOCKET_GATE=citation-check DOCKET_GATE_BASE="$base"
expect_uncited "committed uncited doc in base..HEAD fails" "docs/design/committed.md"

# AC2: with a base at HEAD, uncommitted docs still count.
repo="${WORK}/modified"
build_repo "$repo"
printf '%s' "$UNCITED" > "${repo}/docs/design/cited.md"
run_gate "$repo" DOCKET_GATE=citation-check DOCKET_GATE_BASE="$(git -C "$repo" rev-parse HEAD)"
expect_uncited "modified uncited doc with base at HEAD fails" "docs/design/cited.md"

repo="${WORK}/untracked"
build_repo "$repo"
printf '%s' "$UNCITED" > "${repo}/docs/design/new.md"
run_gate "$repo" DOCKET_GATE=citation-check DOCKET_GATE_BASE="$(git -C "$repo" rev-parse HEAD)"
expect_uncited "untracked uncited doc with base at HEAD fails" "docs/design/new.md"

# AC3: as its own gate, a missing or unresolvable base fails closed.
repo="${WORK}/nobase"
build_repo "$repo"
for label in unset unresolvable; do
    if [ "$label" = unset ]; then
        run_gate "$repo" DOCKET_GATE=citation-check
    else
        run_gate "$repo" DOCKET_GATE=citation-check DOCKET_GATE_BASE=no-such-commit
    fi
    if [ "$RC" -eq 2 ] && printf '%s' "$ERR" | grep -qF DOCKET_GATE_BASE; then
        pass "own gate with ${label} base exits 2 naming DOCKET_GATE_BASE"
    else
        fail "own gate with ${label} base (rc=${RC}, stderr=${ERR})"
    fi
done

# AC3: without a base, other callers keep the working-tree scan.
repo="${WORK}/worktree-scan"
build_repo "$repo"
printf '%s' "$UNCITED" > "${repo}/docs/design/new.md"
run_gate "$repo"
expect_uncited "DOCKET_GATE unset scans the working tree" "docs/design/new.md"
run_gate "$repo" DOCKET_GATE=ac-commands
expect_uncited "another gate without a base scans the working tree" "docs/design/new.md"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
