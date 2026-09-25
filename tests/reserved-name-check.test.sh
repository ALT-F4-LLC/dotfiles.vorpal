#!/bin/bash

# Behavior suite for .docket/bin/reserved-name-check.
#
# THE PROPERTY UNDER TEST: the gate sees every docs/spec/ path the step
# changed, committed since DOCKET_GATE_BASE as well as staged, unstaged and
# untracked, because the engine commits a step's work before its
# record-time gate rerun. Running as its own gate without a usable base it
# fails closed (exit 2); any other caller without a base scans the tree only.
#
# SEAM. Each case builds a throwaway git repo under $TMPDIR with the gate
# copied into its own .docket/bin/ (the gate anchors to the repo holding the
# script), so a fixture run never reads the real worktree.

set -uo pipefail

# A `tests` gate run leaks the engine's DOCKET_GATE and the real repo's
# DOCKET_GATE_BASE into this suite; each case sets exactly what it tests.
unset DOCKET_GATE DOCKET_GATE_BASE

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${RESERVED_NAME_CHECK_GATE:-${REPO_ROOT}/.docket/bin/reserved-name-check}"

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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/reserved-name-check-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_repo <dir>: a git repo with the gate under .docket/bin/ and one
# committed PRD, docs/spec/widget.md, so docs/spec/ exists at the baseline.
build_repo() {
    local dir="$1"
    mkdir -p "${dir}/.docket/bin" "${dir}/docs/spec"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@test
    git -C "$dir" config user.name test
    cp "$GATE" "${dir}/.docket/bin/reserved-name-check"
    chmod +x "${dir}/.docket/bin/reserved-name-check"
    printf '# Widget\n' > "${dir}/docs/spec/widget.md"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m baseline || fatal "baseline commit failed in ${dir}"
}

commit_all() { # <dir>
    git -C "$1" add -A
    git -C "$1" commit -q -m change || fatal "fixture commit failed in $1"
}

OUT=""
ERR=""
RC=0
# run_gate <dir> [VAR=value ...]: runs the fixture's gate with only the given
# DOCKET_* variables set, capturing stdout, stderr and exit status.
run_gate() {
    local dir="$1"
    shift
    OUT=$(env "$@" "${dir}/.docket/bin/reserved-name-check" 2>"${WORK}/stderr")
    RC=$?
    ERR=$(cat "${WORK}/stderr")
}

expect() { # <name> <want-rc> <stdout|stderr> <needle>
    local name="$1" want="$2" stream="$3" needle="$4" text
    if [ "$stream" = stderr ]; then text="$ERR"; else text="$OUT"; fi
    if [ "$RC" -ne "$want" ]; then
        fail "${name}: exit ${RC}, want ${want}; stdout: ${OUT}; stderr: ${ERR}"
    elif [[ "$text" != *"$needle"* ]]; then
        fail "${name}: ${stream} lacks '${needle}'; stdout: ${OUT}; stderr: ${ERR}"
    else
        pass "$name"
    fi
}

# Committed since the base: a clean tree must not hide the change.
for rel in docs/spec/nested/thing.md docs/spec/notes.txt; do
    d="${WORK}/committed-${rel//\//_}"
    build_repo "$d"
    prior=$(git -C "$d" rev-parse HEAD)
    mkdir -p "$(dirname "${d}/${rel}")"
    printf '# Thing\n' > "${d}/${rel}"
    commit_all "$d"
    run_gate "$d" DOCKET_GATE=reserved-name-check "DOCKET_GATE_BASE=${prior}"
    expect "committed ${rel} since the base is refused" 1 stderr "$rel"
done

# Uncommitted with the base at HEAD: the tree still counts.
d="${WORK}/modified"
build_repo "$d"
mkdir -p "${d}/docs/spec/nested"
printf '# Thing\n' > "${d}/docs/spec/nested/thing.md"
commit_all "$d"
printf 'more\n' >> "${d}/docs/spec/nested/thing.md"
run_gate "$d" DOCKET_GATE=reserved-name-check "DOCKET_GATE_BASE=$(git -C "$d" rev-parse HEAD)"
expect "modified nested path with base at HEAD is refused" 1 stderr docs/spec/nested/thing.md

d="${WORK}/untracked"
build_repo "$d"
mkdir -p "${d}/docs/spec/nested"
printf '# Thing\n' > "${d}/docs/spec/nested/thing.md"
run_gate "$d" DOCKET_GATE=reserved-name-check "DOCKET_GATE_BASE=$(git -C "$d" rev-parse HEAD)"
expect "untracked nested path with base at HEAD is refused" 1 stderr docs/spec/nested/thing.md

d="${WORK}/reserved"
build_repo "$d"
printf '# Architecture\n' > "${d}/docs/spec/architecture.md"
run_gate "$d" DOCKET_GATE=reserved-name-check "DOCKET_GATE_BASE=$(git -C "$d" rev-parse HEAD)"
expect "untracked reserved name with base at HEAD passes" 0 stdout "docs/spec/architecture.md -> reserved (spec-author)"

# Own gate without a usable base fails closed.
d="${WORK}/nobase"
build_repo "$d"
run_gate "$d" DOCKET_GATE=reserved-name-check
expect "own gate with base unset exits 2" 2 stderr DOCKET_GATE_BASE
run_gate "$d" DOCKET_GATE=reserved-name-check DOCKET_GATE_BASE=deadbeef
expect "own gate with unresolvable base exits 2" 2 stderr DOCKET_GATE_BASE

# Any other caller without a base scans the working tree as before.
d="${WORK}/treeonly"
build_repo "$d"
mkdir -p "${d}/docs/spec/nested"
printf '# Thing\n' > "${d}/docs/spec/nested/thing.md"
run_gate "$d"
expect "no gate and no base scans the tree" 1 stderr docs/spec/nested/thing.md
run_gate "$d" DOCKET_GATE=doc-validate
expect "another gate without a base scans the tree" 1 stderr docs/spec/nested/thing.md

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
