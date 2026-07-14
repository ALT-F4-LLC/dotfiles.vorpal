#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${SCRIPT_DIR}/../src/user/claude-code/hooks/teammate-idle-hook.sh"

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

run_hook_empty() {
    printf '' | bash "$HOOK"
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

assert_system_message_nonempty() {
    local msg
    msg=$(printf '%s' "$1" | jq -r '.systemMessage // ""' 2>/dev/null)
    if [ -n "$msg" ]; then
        pass "$2"
    else
        fail "$2 (systemMessage empty or absent)"
    fi
}

assert_system_message_contains() {
    local msg
    msg=$(printf '%s' "$1" | jq -r '.systemMessage // ""' 2>/dev/null)
    case "$msg" in
        *"$2"*) pass "$3" ;;
        *) fail "$3 (systemMessage did not contain '$2': $msg)" ;;
    esac
}

assert_no_system_message() {
    local has
    has=$(printf '%s' "$1" | jq 'has("systemMessage")' 2>/dev/null)
    if [ "$has" = "false" ]; then
        pass "$2"
    else
        fail "$2 (expected no systemMessage key, got: $1)"
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

case_agent_type_present() {
    local out rc
    out=$(run_hook '{"agent_type":"senior-engineer"}'); rc=$?
    assert_exit_zero "$rc" "agent_type present: exit 0"
    assert_valid_json "$out" "agent_type present: valid JSON"
    assert_system_message_nonempty "$out" "agent_type present: non-empty systemMessage"
    assert_system_message_contains "$out" "senior-engineer" "agent_type present: systemMessage includes agent_type value"
}

case_no_agent_type() {
    local out rc
    out=$(run_hook '{}'); rc=$?
    assert_exit_zero "$rc" "no agent_type: exit 0"
    assert_valid_json "$out" "no agent_type: valid JSON"
    assert_system_message_nonempty "$out" "no agent_type: non-empty generic systemMessage"
}

case_malformed_stdin() {
    local out rc
    out=$(run_hook 'not json at all'); rc=$?
    assert_exit_zero "$rc" "malformed stdin: exit 0"
    assert_valid_json "$out" "malformed stdin: valid JSON"
    assert_empty_object "$out" "malformed stdin: fail-open empty object"
    assert_no_system_message "$out" "malformed stdin: no systemMessage key"
}

case_empty_stdin() {
    local out rc
    out=$(run_hook_empty); rc=$?
    assert_exit_zero "$rc" "empty stdin: exit 0"
    assert_valid_json "$out" "empty stdin: valid JSON"
    assert_system_message_nonempty "$out" "empty stdin: non-empty generic systemMessage"
}

case_agent_id_resolves_real_teammate_name() {
    local fixture_dir out rc
    fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/idlehook.XXXXXX") || {
        printf 'FATAL: could not create scratch dir for agent_id resolution test\n' >&2
        exit 2
    }
    mkdir -p "${fixture_dir}/session/subagents"
    : > "${fixture_dir}/session.jsonl"
    : > "${fixture_dir}/session/subagents/agent-asenior-engineer-1234567890abcdef.jsonl"

    out=$(jq -n --arg tp "${fixture_dir}/session.jsonl" \
        '{agent_id:"asenior-engineer-1234567890abcdef",agent_type:"team-lead",transcript_path:$tp}' \
        | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "agent_id resolves real teammate: exit 0"
    assert_valid_json "$out" "agent_id resolves real teammate: valid JSON"
    assert_system_message_contains "$out" "senior-engineer" "agent_id resolution overrides ambient agent_type='team-lead' (DKT-262)"

    rm -rf "$fixture_dir"
}

case_agent_id_unresolvable_falls_back_to_agent_type() {
    local fixture_dir out rc
    fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/idlehook.XXXXXX") || {
        printf 'FATAL: could not create scratch dir for agent_id fallback test\n' >&2
        exit 2
    }
    mkdir -p "${fixture_dir}/session/subagents"
    : > "${fixture_dir}/session.jsonl"

    out=$(jq -n --arg tp "${fixture_dir}/session.jsonl" \
        '{agent_id:"anonexistent-9999999999999999",agent_type:"security-engineer",transcript_path:$tp}' \
        | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "agent_id unresolvable: exit 0"
    assert_system_message_contains "$out" "security-engineer" "agent_id unresolvable falls back to agent_type"

    rm -rf "$fixture_dir"
}

case_transcript_already_subagent_shaped() {
    local fixture_dir out rc
    fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/idlehook.XXXXXX") || {
        printf 'FATAL: could not create scratch dir for passthrough test\n' >&2
        exit 2
    }
    mkdir -p "${fixture_dir}/subagents"
    local own_jsonl="${fixture_dir}/subagents/agent-astaff-engineer-abcdef1234567890.jsonl"
    : > "$own_jsonl"

    out=$(jq -n --arg tp "$own_jsonl" \
        '{agent_id:"astaff-engineer-abcdef1234567890",agent_type:"team-lead",transcript_path:$tp}' \
        | bash "$HOOK"); rc=$?
    assert_exit_zero "$rc" "already subagent-shaped transcript_path: exit 0"
    assert_system_message_contains "$out" "staff-engineer" "passthrough resolution from an already subagent-shaped transcript_path"

    rm -rf "$fixture_dir"
}

case_injection_safety() {
    local sentinel_dir sentinel out rc
    sentinel_dir=$(mktemp -d "${TMPDIR:-/tmp}/idlehook.XXXXXX") || {
        printf 'FATAL: could not create scratch dir for injection test\n' >&2
        exit 2
    }
    sentinel="${sentinel_dir}/pwned"
    out=$(run_hook "{\"agent_type\":\"\$(touch ${sentinel})\"}"); rc=$?
    assert_exit_zero "$rc" "injection: exit 0"
    assert_valid_json "$out" "injection: valid JSON"
    assert_system_message_contains "$out" "\$(touch ${sentinel})" "injection: payload JSON-escaped inside systemMessage"
    if [ -e "$sentinel" ]; then
        fail "injection: sentinel file was created (payload was executed)"
        rm -f "$sentinel"
    else
        pass "injection: no side effect (sentinel file not created)"
    fi
    rmdir "$sentinel_dir" 2>/dev/null || true
}

if [ ! -f "$HOOK" ]; then
    printf 'FATAL: hook not found at %s\n' "$HOOK" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'FATAL: jq is required to run this test\n' >&2
    exit 2
fi

case_agent_type_present
case_no_agent_type
case_malformed_stdin
case_empty_stdin
case_agent_id_resolves_real_teammate_name
case_agent_id_unresolvable_falls_back_to_agent_type
case_transcript_already_subagent_shaped
case_injection_safety

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
