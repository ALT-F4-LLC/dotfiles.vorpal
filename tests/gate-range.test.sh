#!/bin/bash

# Behavior suite for .docket/bin/gate-range, the sourced helper gates use to
# turn DOCKET_GATE_BASE into the committed range they scan.
#
# THE PROPERTY UNDER TEST, own-gate mode: a resolvable base yields
# `<sha>..HEAD`; an unset or unresolvable base yields no range when
# DOCKET_GATE names another gate or none, and exits 2 naming the gate when
# DOCKET_GATE names the calling gate.
#
# SEAM. Each case sources the helper in a fresh bash inside a throwaway git
# repo under $TMPDIR and prints the range it set.

set -uo pipefail

# A `tests` gate run leaks the engine's DOCKET_GATE and the real repo's
# DOCKET_GATE_BASE into this suite; each case sets exactly what it tests.
unset DOCKET_GATE DOCKET_GATE_BASE

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HELPER="${GATE_RANGE_HELPER:-${REPO_ROOT}/.docket/bin/gate-range}"

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

[ -f "$HELPER" ] || fatal "helper not found at ${HELPER}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/gate-range-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

REPO="${WORK}/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@test
git -C "$REPO" config user.name test
git -C "$REPO" commit -q --allow-empty -m base || fatal "fixture commit failed"
BASE_SHA=$(git -C "$REPO" rev-parse HEAD)
# A ref whose name is option-shaped: it resolves only when rev-parse is told
# the argument is not an option.
git -C "$REPO" update-ref refs/tags/--opt-base "$BASE_SHA" || fatal "fixture tag failed"
git -C "$REPO" commit -q --allow-empty -m change || fatal "fixture commit failed"

OUT=""
ERR=""
RC=0
MODE=own-gate
# resolve [VAR=value ...]: sources the helper with only the given DOCKET_*
# variables set, calls it as gate `sample-gate` in $MODE, and captures the
# range it set, stderr, and exit status.
resolve() {
    OUT=$(cd "$REPO" && env "$@" bash -c '
        set -euo pipefail
        . "$1"
        gate_range sample-gate "$2"
        printf "%s" "$GATE_RANGE"
    ' _ "$HELPER" "$MODE" 2>"${WORK}/stderr")
    RC=$?
    ERR=$(cat "${WORK}/stderr")
}

# expect <label> <rc> <range> [stderr-fragment]
expect() {
    local label="$1" rc="$2" range="$3" fragment="${4:-}"
    if [ "$RC" -ne "$rc" ]; then
        fail "${label}: expected exit ${rc}, got ${RC} (stdout '${OUT}', stderr '${ERR}')"
    elif [ "$OUT" != "$range" ]; then
        fail "${label}: expected range '${range}', got '${OUT}'"
    elif [ -n "$fragment" ] && [[ "$ERR" != *"$fragment"* ]]; then
        fail "${label}: expected stderr to contain '${fragment}', got '${ERR}'"
    else
        pass "$label"
    fi
}

UNRESOLVABLE=0000000000000000000000000000000000000000

resolve DOCKET_GATE=sample-gate "DOCKET_GATE_BASE=${BASE_SHA}"
expect "resolvable base yields <sha>..HEAD" 0 "${BASE_SHA}..HEAD"

resolve "DOCKET_GATE_BASE=${BASE_SHA}"
expect "resolvable base yields <sha>..HEAD outside the gate" 0 "${BASE_SHA}..HEAD"

resolve
expect "base unset, DOCKET_GATE unset: no range" 0 ""

resolve DOCKET_GATE=other-gate
expect "base unset, another gate: no range" 0 ""

resolve DOCKET_GATE=other-gate "DOCKET_GATE_BASE=${UNRESOLVABLE}"
expect "base unresolvable, another gate: no range" 0 ""

resolve DOCKET_GATE=other-gate "DOCKET_GATE_BASE=--help"
expect "option-shaped base, another gate: no range" 0 ""

resolve DOCKET_GATE=sample-gate "DOCKET_GATE_BASE=--opt-base"
expect "option-shaped ref name resolves as a revision, not an option" 0 "${BASE_SHA}..HEAD"

resolve DOCKET_GATE=sample-gate
expect "own gate, base unset: exits 2 naming the gate" 2 "" "sample-gate FAILED: DOCKET_GATE_BASE"

resolve DOCKET_GATE=sample-gate "DOCKET_GATE_BASE=${UNRESOLVABLE}"
expect "own gate, base unresolvable: exits 2 naming the gate" 2 "" "sample-gate FAILED: DOCKET_GATE_BASE"

MODE=bogus-mode
resolve "DOCKET_GATE_BASE=${BASE_SHA}"
expect "unknown mode exits 2 naming the gate" 2 "" "sample-gate FAILED: gate_range: unknown mode 'bogus-mode'"
MODE=own-gate

echo
if [ "$FAIL" -gt 0 ]; then
    printf '%d passed, %d failed\n' "$PASS" "$FAIL"
    exit 1
fi
printf 'all %d passed\n' "$PASS"
