#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/sandbox-bypass-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST is caller-scoped, the same split as the trust-guard
# suite: a Bash call with dangerouslyDisableSandbox=true must DENY when
# agent_type names an executor archetype and ALLOW (silence) for the main
# conversation or any other seat. The command text is irrelevant to the
# verdict — the flag is the whole offence.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - an executor's lift goes through because the flag arrived in
#     a shape the hook did not read (string "true", missing agent_type on a
#     real executor), and the sandbox is off for that call.
#   FALSE DENY  - a sandboxed executor call, or the operator's own
#     ask-confirmed lift in the main conversation, blocked.
#
# SEAM. One decision from stdin JSON; the exit code is the entire verdict.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/sandbox-bypass-guard-hook.sh}"

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

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

verdict_of() {
    local input="$1" rc
    "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

# build_input <command> <agent_type or ""> <bypass: true|false|absent|string>
build_input() {
    local cmd="$1" agent="${2:-}" bypass="${3:-absent}"
    jq -nc --arg c "$cmd" --arg a "$agent" --arg b "$bypass" '
        {tool_name:"Bash", tool_input:{command:$c}}
        | if $a != "" then .agent_type = $a else . end
        | if $b == "true" then .tool_input.dangerouslyDisableSandbox = true
          elif $b == "false" then .tool_input.dangerouslyDisableSandbox = false
          elif $b == "string" then .tool_input.dangerouslyDisableSandbox = "true"
          else . end'
}

assert_verdict() {
    local cmd="$1" agent="$2" bypass="$3" want="$4" label="$5" got
    got=$(verdict_of "$(build_input "$cmd" "$agent" "$bypass")")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

GOCMD='GOCACHE="/tmp/claude-501/STEP-1.d/gocache" vorpal run go:1.26.0 test ./...'

case_executor_lift_denies() {
    assert_verdict "$GOCMD" executor-write true DENY "executor-write: vorpal go test with lift"
    assert_verdict "$GOCMD" executor-read true DENY "executor-read: vorpal go test with lift"
    assert_verdict "$GOCMD" executor-research true DENY "executor-research: vorpal go test with lift"
    assert_verdict "ls" executor-write true DENY "executor-write: harmless command, lift still denied"
    assert_verdict "cargo test" executor-write true DENY "executor-write: cargo test with lift"
}

case_executor_sandboxed_allows() {
    assert_verdict "$GOCMD" executor-write absent ALLOW "executor-write: vorpal go test, flag absent"
    assert_verdict "$GOCMD" executor-write false ALLOW "executor-write: vorpal go test, flag false"
    assert_verdict "$GOCMD" executor-read absent ALLOW "executor-read: flag absent"
    assert_verdict "$GOCMD" executor-research false ALLOW "executor-research: flag false"
}

case_other_callers_allow() {
    assert_verdict "$GOCMD" "" true ALLOW "main conversation: lift stays with the harness"
    assert_verdict "$GOCMD" general-purpose true ALLOW "general-purpose seat: not in scope"
    assert_verdict "$GOCMD" Explore true ALLOW "Explore seat: not in scope"
    assert_verdict "$GOCMD" executor true ALLOW "bare 'executor' is not an archetype"
    assert_verdict "$GOCMD" executor-writer true ALLOW "near-miss archetype name"
}

case_only_bash_and_only_boolean_true() {
    # The harness sends the flag as a JSON boolean; a string "true" is not a
    # lift and must not deny, or a future schema quirk turns into false denies.
    assert_verdict "$GOCMD" executor-write string ALLOW "string \"true\" is not the boolean flag"
    local raw
    raw=$(jq -nc '{tool_name:"Read", tool_input:{file_path:"/x", dangerouslyDisableSandbox:true}, agent_type:"executor-write"}')
    local got
    got=$(verdict_of "$raw")
    [ "$got" = "ALLOW" ] && pass "non-Bash tool carrying the flag (ALLOW)" || fail "non-Bash tool carrying the flag (want ALLOW, got ${got})"
}

case_malformed_input_allows() {
    local got
    got=$(verdict_of '')
    [ "$got" = "ALLOW" ] && pass "empty stdin (ALLOW)" || fail "empty stdin (want ALLOW, got ${got})"
    got=$(verdict_of 'not json')
    [ "$got" = "ALLOW" ] && pass "non-JSON stdin (ALLOW)" || fail "non-JSON stdin (want ALLOW, got ${got})"
}

# The deny reason must keep telling the executor what to do instead, so a
# denied lift ends in a sandboxed retry rather than a stalled step.
DENY_REASON='sandbox bypass blocked: dangerouslyDisableSandbox is never available to an executor step'

case_deny_reason_is_fixed() {
    local err
    err=$("$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "$GOCMD" executor-write true)")
    case "$err" in
        "${DENY_REASON}"*) pass "deny reason text unchanged" ;;
        *) fail "deny reason changed or missing: ${err}" ;;
    esac
    case "$err" in
        *"Run the same command sandboxed"*) pass "deny reason names the sandboxed retry" ;;
        *) fail "deny reason no longer tells the executor to run sandboxed" ;;
    esac
}

case_executor_lift_denies
case_executor_sandboxed_allows
case_other_callers_allow
case_only_bash_and_only_boolean_true
case_malformed_input_allows
case_deny_reason_is_fixed

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
