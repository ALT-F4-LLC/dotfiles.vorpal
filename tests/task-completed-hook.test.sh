#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${SCRIPT_DIR}/../src/user/task-completed-hook.sh"

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

run_hook() {
    printf '%s' "$1" | bash "$HOOK"
}

assert_exit_zero() {
    if [ "$1" -eq 0 ]; then
        pass "$2"
    else
        fail "$2 (exit=$1)"
    fi
}

assert_valid_json() {
    if printf '%s' "$1" | jq -e . >/dev/null 2>&1; then
        pass "$2"
    else
        fail "$2 (stdout was not valid JSON: $1)"
    fi
}

assert_empty_object() {
    local normalized
    normalized=$(printf '%s' "$1" | jq -c . 2>/dev/null)
    if [ "$normalized" = "{}" ]; then
        pass "$2"
    else
        fail "$2 (expected {}, got: $1)"
    fi
}

assert_decision_block() {
    local decision
    decision=$(printf '%s' "$1" | jq -r '.decision // empty' 2>/dev/null)
    if [ "$decision" = "block" ]; then
        pass "$2"
    else
        fail "$2 (expected decision=block, got: $1)"
    fi
}

assert_reason_contains() {
    local reason
    reason=$(printf '%s' "$1" | jq -r '.reason // empty' 2>/dev/null)
    case "$reason" in
        *"$2"*) pass "$3" ;;
        *) fail "$3 (reason did not contain '$2': $reason)" ;;
    esac
}

FIXTURE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/taskcompletedhook.XXXXXX") || {
    printf 'FATAL: could not create fixture dir\n' >&2
    exit 2
}
trap 'rm -rf "$FIXTURE_DIR"' EXIT

write_transcript() {
    local name="$1"
    shift
    printf '%s\n' "$@" > "${FIXTURE_DIR}/${name}.jsonl"
}

CLAIM_LINE='{"message":{"content":[{"type":"tool_use","name":"TaskUpdate","input":{"taskId":"7","status":"in_progress"}}]}}'
OTHER_LINE='{"message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
SEND_TEAMLEAD_LINE='{"message":{"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"team-lead","message":"done"}}]}}'
SEND_PEER_LINE='{"message":{"content":[{"type":"tool_use","name":"SendMessage","input":{"to":"peer","message":"hi"}}]}}'

write_transcript "no_report" "$CLAIM_LINE" "$OTHER_LINE"
write_transcript "report_to_lead" "$CLAIM_LINE" "$SEND_TEAMLEAD_LINE"
write_transcript "report_to_peer" "$CLAIM_LINE" "$SEND_PEER_LINE"
write_transcript "no_claim_fallback" "$OTHER_LINE" "$SEND_PEER_LINE"
write_transcript "shape_drift" '{"message":{"content":[{"type":"weird_new_shape","stuff":"x"}]}}' '{"totally":"different top-level shape"}'
write_transcript "send_before_claim" "$SEND_TEAMLEAD_LINE" "$CLAIM_LINE"

payload() {
    local transcript="$1" teammate="${2-impl-X}" task_id="${3-7}"
    jq -n --arg t "$transcript" --arg n "$teammate" --arg id "$task_id" \
        '{task_id: $id, teammate_name: $n, transcript_path: $t}'
}

case_block_no_report() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/no_report.jsonl")"); rc=$?
    assert_exit_zero "$rc" "block/no-report: exit 0"
    assert_valid_json "$out" "block/no-report: valid JSON"
    assert_decision_block "$out" "block/no-report: decision=block"
    assert_reason_contains "$out" "PREMATURE-COMPLETION-BLOCKED" "block/no-report: reason has marker"
}

case_allow_report_to_lead() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/report_to_lead.jsonl")"); rc=$?
    assert_exit_zero "$rc" "allow/report-to-lead: exit 0"
    assert_empty_object "$out" "allow/report-to-lead: {}"
}

case_allow_report_to_peer() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/report_to_peer.jsonl")"); rc=$?
    assert_exit_zero "$rc" "allow/report-to-peer (recipient-agnostic): exit 0"
    assert_empty_object "$out" "allow/report-to-peer (recipient-agnostic): {}"
}

case_allow_fallback_no_claim() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/no_claim_fallback.jsonl")"); rc=$?
    assert_exit_zero "$rc" "allow/fallback (row 7): exit 0"
    assert_empty_object "$out" "allow/fallback (row 7): {}"
}

case_allow_empty_teammate_name() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/no_report.jsonl" "")"); rc=$?
    assert_exit_zero "$rc" "allow/empty teammate_name (row 2): exit 0"
    assert_empty_object "$out" "allow/empty teammate_name (row 2): {}"
}

case_allow_team_lead_teammate_name() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/no_report.jsonl" "team-lead")"); rc=$?
    assert_exit_zero "$rc" "allow/team-lead teammate_name (row 3): exit 0"
    assert_empty_object "$out" "allow/team-lead teammate_name (row 3): {}"
}

case_allow_malformed_payload() {
    local out rc
    out=$(printf 'not json at all' | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "allow/malformed payload (row 1): exit 0"
    assert_empty_object "$out" "allow/malformed payload (row 1): {}"
}

case_allow_missing_transcript() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/does-not-exist.jsonl")"); rc=$?
    assert_exit_zero "$rc" "allow/missing transcript (row 4): exit 0"
    assert_empty_object "$out" "allow/missing transcript (row 4): {}"
}

case_allow_shape_drift_canary() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/shape_drift.jsonl")"); rc=$?
    assert_exit_zero "$rc" "allow/shape-drift canary (row 5): exit 0"
    assert_empty_object "$out" "allow/shape-drift canary (row 5): {}"
}

case_block_send_before_claim() {
    local out rc
    out=$(run_hook "$(payload "${FIXTURE_DIR}/send_before_claim.jsonl")"); rc=$?
    assert_exit_zero "$rc" "block/ordering (send before claim): exit 0"
    assert_decision_block "$out" "block/ordering (send before claim): decision=block"
}

case_injection_safety() {
    local sentinel out rc
    sentinel="${FIXTURE_DIR}/pwned"
    out=$(jq -n --arg t "${FIXTURE_DIR}/no_report.jsonl" --arg n "impl-X" \
        --arg subj "\$(touch ${sentinel})" \
        '{task_id: "7", teammate_name: $n, transcript_path: $t, task_subject: $subj, task_description: $subj}' \
        | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "injection: exit 0"
    assert_valid_json "$out" "injection: valid JSON"
    assert_decision_block "$out" "injection: correct decision (block, unaffected by payload content)"
    if [ -e "$sentinel" ]; then
        fail "injection: sentinel file was created (payload was executed)"
        rm -f "$sentinel"
    else
        pass "injection: no side effect (sentinel file not created)"
    fi
}

if [ ! -f "$HOOK" ]; then
    printf 'FATAL: hook not found at %s\n' "$HOOK" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'FATAL: jq is required to run this test\n' >&2
    exit 2
fi

case_block_no_report
case_allow_report_to_lead
case_allow_report_to_peer
case_allow_fallback_no_claim
case_allow_empty_teammate_name
case_allow_team_lead_teammate_name
case_allow_malformed_payload
case_allow_missing_transcript
case_allow_shape_drift_canary
case_block_send_before_claim
case_injection_safety

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
