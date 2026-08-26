#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-trust-guard-hook.sh
# (DOT-812).
#
# THE PROPERTY UNDER TEST is caller-scoped, not command-scoped: the same
# `docket trust add/rm` invocation must DENY when agent_type names an
# executor archetype and ALLOW when it does not (main conversation, or any
# other agent type) -- that split is the whole point of this hook, and every
# case group below is organized around it rather than around the text
# matcher alone.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - a real `docket trust add/rm` invocation from an executor
#     whose shape or agent_type the matcher fails to recognize, so the write
#     that repoints a gate goes through unblocked.
#   FALSE DENY  - a read, a query, or prose that merely mentions
#     "docket trust add", or a main-conversation call, denied anyway.
#
# SEAM. No engine, no `docket` binary, no filesystem: this hook makes exactly
# one decision from its stdin JSON and nothing else, so the suite is a single
# process reading the hook's exit code.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-trust-guard-hook.sh}"

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

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT

TOOLS_DIR="${SANDBOX}/tools"
mkdir -p "$TOOLS_DIR"
for tool in bash cat jq awk; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR}/${tool}"
done

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). No
# permissionDecision envelope is emitted -- exit 2 is a pre-permission hard
# stop and exit 0 is silence -- so the exit code is the entire verdict.
verdict_of() {
    local input="$1" rc
    PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

build_input() {
    local cmd="$1" agent="${2:-}"
    if [ -n "$agent" ]; then
        jq -nc --arg c "$cmd" --arg a "$agent" \
            '{tool_name:"Bash",tool_input:{command:$c},agent_type:$a}'
    else
        jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}'
    fi
}

assert_verdict() {
    local cmd="$1" agent="$2" want="$3" label="$4" got
    got=$(verdict_of "$(build_input "$cmd" "$agent")")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

assert_verdict_raw() {
    local raw="$1" want="$2" label="$3" got
    got=$(verdict_of "$raw")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

# ---- THE PROPERTY: same command, verdict turns on agent_type alone --------

case_executor_archetypes_deny() {
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-read DENY \
        "executor-read: docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-write DENY \
        "executor-write: docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-research DENY \
        "executor-research: docket trust add"
    assert_verdict "docket trust rm erik" executor-write DENY \
        "executor-write: docket trust rm"
}

case_main_conversation_and_other_agents_allow() {
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" "" ALLOW \
        "no agent_type (main conversation): docket trust add"
    assert_verdict "docket trust rm erik" "" ALLOW \
        "no agent_type (main conversation): docket trust rm"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" planner ALLOW \
        "agent_type=planner (not an executor archetype): docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" groomer ALLOW \
        "agent_type=groomer (not an executor archetype): docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" general-purpose ALLOW \
        "agent_type=general-purpose (not an executor archetype): docket trust add"
}

# ---- MUST ALLOW: ordinary docket verbs, any caller -------------------------

case_ordinary_docket_verbs_allow() {
    assert_verdict "docket trust list" executor-write ALLOW \
        "executor: docket trust list (read-only verb, not add/rm)"
    assert_verdict "docket issue list" executor-write ALLOW \
        "executor: unrelated docket verb"
    assert_verdict "docket trust show erik" executor-write ALLOW \
        "executor: docket trust show (not add/rm)"
}

# ---- MUST NOT CATCH: prose / read-only, from an executor -------------------

case_must_not_catch_prose_and_reads() {
    assert_verdict 'docket issue comment add D-1 -m "never run docket trust add"' \
        executor-write ALLOW "prose mentioning docket trust add inside -m body"
    assert_verdict 'echo "the phrase docket trust add appears here"' \
        executor-write ALLOW "single-quoted-content prose"
}

# ---- MUST DENY: separator/subshell-glued shapes, from an executor ---------

case_must_deny_glued_separator_class() {
    assert_verdict "cd /x && docket trust add erik key" executor-write DENY \
        "&& docket trust add"
    assert_verdict "cd /x &&docket trust add erik key" executor-write DENY \
        "&&docket trust add (no space)"
    assert_verdict "(docket trust rm erik)" executor-write DENY \
        "(docket trust rm) subshell"
    assert_verdict "/usr/local/bin/docket trust add erik key" executor-write DENY \
        "absolute path to docket binary"
}

# ---- MUST DENY: separately-quoted tokens forming a real invocation --------

case_must_deny_separately_quoted_tokens() {
    assert_verdict '"docket" "trust" "add" erik key' executor-write DENY \
        "separately-quoted docket/trust/add (bash-unquotes to a real call)"
}

# ---- Input edge cases: fail open, never mid-parse --------------------------

case_input_edge_cases() {
    assert_verdict_raw '{"tool_name":"Read","tool_input":{"file_path":"x"},"agent_type":"executor-write"}' \
        ALLOW "non-Bash tool_name allows regardless of agent_type"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":""},"agent_type":"executor-write"}' \
        ALLOW "empty command string allows"
    assert_verdict_raw '{"tool_name":"Bash","agent_type":"executor-write"}' \
        ALLOW "missing tool_input allows"
    assert_verdict_raw 'not json at all' \
        ALLOW "malformed (non-JSON) stdin fails open to allow"
    assert_verdict_raw '' \
        ALLOW "empty stdin fails open to allow"
}

case_executor_archetypes_deny
case_main_conversation_and_other_agents_allow
case_ordinary_docket_verbs_allow
case_must_not_catch_prose_and_reads
case_must_deny_glued_separator_class
case_must_deny_separately_quoted_tokens
case_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
