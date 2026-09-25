#!/bin/bash

# Behavior suite for .docket/bin/tdd-preflight's change selection.
#
# THE PROPERTY UNDER TEST: executors commit before `docket step record`, so
# the record-time rerun must see TDDs committed since DOCKET_GATE_BASE, not
# only the uncommitted tree. Running as its own gate (DOCKET_GATE=
# tdd-preflight) without a resolvable base is a refusal (exit 2); outside its
# own gate with no base it keeps the working-tree scan.
#
# SEAM. Each case builds a throwaway git fixture repo under $TMPDIR with the
# gate copied into its .docket/bin/ (the gate anchors to its own repository),
# and runs it with an explicit environment.

set -uo pipefail

# The engine exports both to every gate it spawns, including `just tests`.
# Cases below state the environment they need; an inherited value would
# silently change which branch of the gate runs.
unset DOCKET_GATE DOCKET_GATE_BASE

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${REPO_ROOT}/.docket/bin/tdd-preflight"

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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/tdd-preflight-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# fresh_repo <name>: a repo with one base commit holding the gate and a
# well-named TDD. Prints the repo path.
fresh_repo() {
    local dir="${WORK}/$1"
    mkdir -p "${dir}/.docket/bin" "${dir}/docs/tdd"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email test@test
    git -C "$dir" config user.name test
    cp "$GATE" "${dir}/.docket/bin/tdd-preflight"
    chmod +x "${dir}/.docket/bin/tdd-preflight"
    printf '# Existing\n' > "${dir}/docs/tdd/existing-feature.md"
    git -C "$dir" add -A
    git -C "$dir" commit -qm base || fatal "fixture commit failed in ${dir}"
    printf '%s\n' "$dir"
}

commit_all() { # <dir> <msg>
    git -C "$1" add -A
    git -C "$1" commit -qm "$2" || fatal "fixture commit failed in $1"
}

head_of() { git -C "$1" rev-parse HEAD; }

# run_gate <dir> [VAR=value ...]: runs the fixture's gate with the given
# environment additions; sets RC, OUT, ERR.
run_gate() {
    local dir="$1"
    shift
    OUT=$(cd "$WORK" && env "$@" "${dir}/.docket/bin/tdd-preflight" 2>"${WORK}/stderr")
    RC=$?
    ERR=$(cat "${WORK}/stderr")
}

expect() { # <name> <want-rc> [stderr-substring]
    local name="$1" want="$2" needle="${3:-}"
    if [ "$RC" -ne "$want" ]; then
        fail "${name}: exit ${RC}, want ${want}; stdout: ${OUT}; stderr: ${ERR}"
    elif [ -n "$needle" ] && [[ "$ERR" != *"$needle"* ]]; then
        fail "${name}: stderr does not name '${needle}': ${ERR}"
    else
        pass "$name"
    fi
}

# --- committed since the base ---------------------------------------------

r=$(fresh_repo committed-kebab)
base=$(head_of "$r")
printf '# Bad\n' > "${r}/docs/tdd/Not_Kebab.md"
commit_all "$r" bad
run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE="$base"
expect "committed non-kebab TDD since the base is refused" 1 "docs/tdd/Not_Kebab.md"

r=$(fresh_repo committed-nested)
base=$(head_of "$r")
mkdir -p "${r}/docs/tdd/nested"
printf '# Nested\n' > "${r}/docs/tdd/nested/feature.md"
commit_all "$r" nested
run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE="$base"
expect "committed nested TDD since the base is refused" 1 "docs/tdd/nested/feature.md"

# --- uncommitted on top of the base ---------------------------------------

r=$(fresh_repo modified)
printf '# Bad\n' > "${r}/docs/tdd/Not_Kebab.md"
commit_all "$r" bad
printf 'more\n' >> "${r}/docs/tdd/Not_Kebab.md"
run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE="$(head_of "$r")"
expect "modified non-kebab TDD at the base is refused" 1 "docs/tdd/Not_Kebab.md"

r=$(fresh_repo untracked)
printf '# Bad\n' > "${r}/docs/tdd/Not_Kebab.md"
run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE="$(head_of "$r")"
expect "untracked non-kebab TDD at the base is refused" 1 "docs/tdd/Not_Kebab.md"

r=$(fresh_repo untracked-good)
printf '# Good\n' > "${r}/docs/tdd/good-feature.md"
run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE="$(head_of "$r")"
expect "untracked kebab-case TDD at the base passes" 0

# --- own gate without a usable base ---------------------------------------

r=$(fresh_repo own-gate-unset)
run_gate "$r" DOCKET_GATE=tdd-preflight
expect "own gate with DOCKET_GATE_BASE unset exits 2" 2 "DOCKET_GATE_BASE is unset"

run_gate "$r" DOCKET_GATE=tdd-preflight DOCKET_GATE_BASE=deadbeef
expect "own gate with an unresolvable DOCKET_GATE_BASE exits 2" 2 "DOCKET_GATE_BASE 'deadbeef'"

# --- no base outside the own gate: working-tree scan ----------------------

r=$(fresh_repo scan-no-gate)
printf '# Bad\n' > "${r}/docs/tdd/Not_Kebab.md"
run_gate "$r"
expect "no gate and no base scans the working tree" 1 "docs/tdd/Not_Kebab.md"

r=$(fresh_repo scan-other-gate)
printf '# Bad\n' > "${r}/docs/tdd/Not_Kebab.md"
run_gate "$r" DOCKET_GATE=doc-validate
expect "another gate and no base scans the working tree" 1 "docs/tdd/Not_Kebab.md"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
