#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/sandbox-friction-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST: the ledger receives one row for a real sandbox
# denial, a sandbox lift, or a classifier denial, and nothing for a command
# whose output merely quotes the words of a denial. Measured before the quoted
# span filter: about two thirds of one day's "sandbox-denial" rows were
# briefs, fragments, and source comments being printed by cat/grep/sed.
#
# DEFECT CLASS. Two failure directions:
#   FALSE ROW   - prose in backticks or quotes recorded as a denial, which
#     inflates every count the friction report and the operator read.
#   MISSED ROW  - a real errno line, a lift, or a classifier refusal not
#     recorded, which is the evidence loop going blind.
#
# SEAM. HOME is pointed at a scratch directory so the ledger under test is
# private; the row count and its `kind` are the whole verdict. The hook must
# exit 0 on every input.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${FRICTION_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/sandbox-friction-hook.sh}"

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

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/sandbox-friction-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT
LEDGER="${SANDBOX}/.claude/friction/sandbox.jsonl"

# run_hook <input json>; prints the kind of the row written, or NONE.
run_hook() {
    local input="$1" before after rc
    before=$(wc -l <"$LEDGER" 2>/dev/null || echo 0)
    HOME="$SANDBOX" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    [ "$rc" -eq 0 ] || { printf 'EXIT%s' "$rc"; return; }
    after=$(wc -l <"$LEDGER" 2>/dev/null || echo 0)
    if [ "$after" -gt "$before" ]; then
        tail -n 1 "$LEDGER" | jq -r '.kind'
    else
        printf 'NONE'
    fi
}

# post_input <command> <stdout> [bypass true|false]
post_input() {
    local cmd="$1" out="$2" bypass="${3:-false}"
    jq -nc --arg c "$cmd" --arg o "$out" --argjson b "$bypass" \
        '{hook_event_name:"PostToolUse",tool_name:"Bash",session_id:"s",cwd:"/repo",tool_input:{command:$c,dangerouslyDisableSandbox:$b},tool_response:{stdout:$o,stderr:"",interrupted:false}}'
}

assert_kind() {
    local input="$1" want="$2" label="$3" got
    got=$(run_hook "$input")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

case_real_denials_are_recorded() {
    assert_kind "$(post_input 'diff <(echo a) <(echo b)' 'diff: /dev/fd/11: Operation not permitted')" \
        sandbox-denial "errno line from diff"
    assert_kind "$(post_input 'go mod download' 'verifying go.mod: open /Users/x/go/pkg/sumdb/latest: operation not permitted')" \
        sandbox-denial "errno line from go"
    assert_kind "$(post_input 'docket issue list' 'unable to open database file (14)')" \
        sandbox-denial "sqlite open failure"
    assert_kind "$(post_input 'go test ./...' 'Get "https://proxy.golang.org": x509: OSStatus -26276')" \
        sandbox-denial "TLS trust daemon failure with a quoted URL on the same line"
    assert_kind "$(post_input 'ls' 'ok' true)" \
        unsandboxed-retry "lift with clean output"
    assert_kind "$(post_input 'ls' 'x: Operation not permitted' true)" \
        unsandboxed-retry "lift that still hit a denial keeps the lift kind"
}

case_quoted_prose_is_not_a_denial() {
    assert_kind "$(post_input 'cat brief.md' 'Under the agent sandbox the classic case is listener binds (test suites failing `bind: operation not permitted` on a unix socket)')" \
        NONE "backticked denial words in a brief"
    assert_kind "$(post_input 'sed -n 1,5p x.rs' '// without this every sandboxed docket invocation fails with "unable to open database file (14)"')" \
        NONE "double-quoted denial words in a source comment"
    assert_kind "$(post_input 'grep -n tls SKILL.md' 'so a stdlib HTTPS fetch fails `x509: OSStatus -26276` even in this session')" \
        NONE "backticked TLS status in a skill body"
    assert_kind "$(post_input 'cat notes.md' 'nothing to see here')" \
        NONE "clean output"
}

case_mixed_output_keeps_the_real_line() {
    local input evidence
    input=$(post_input 'bash run.sh' 'brief says `bind: operation not permitted` is expected
diff: /dev/fd/12: Operation not permitted')
    assert_kind "$input" sandbox-denial "real errno line after quoted prose"
    evidence=$(tail -n 1 "$LEDGER" | jq -r '.evidence')
    case "$evidence" in
        *'/dev/fd/12: Operation not permitted'*) pass "evidence carries the real line" ;;
        *) fail "evidence lost the real line: ${evidence}" ;;
    esac
    case "$evidence" in
        *'bind: operation'*) fail "evidence still carries the quoted prose" ;;
        *) pass "evidence drops the quoted prose" ;;
    esac
}

case_classifier_denials_are_recorded() {
    local input
    input=$(jq -nc '{hook_event_name:"PermissionDenied",tool_name:"Bash",session_id:"s",cwd:"/repo",tool_input:{command:"kubectl apply -f x"},reason:"Blocked by classifier"}')
    assert_kind "$input" classifier-denial "classifier refusal"
}

case_never_blocks() {
    local got
    got=$(run_hook '')
    [ "$got" = "NONE" ] && pass "empty stdin exits 0, no row" || fail "empty stdin (got ${got})"
    got=$(run_hook 'not json')
    [ "$got" = "NONE" ] && pass "non-JSON exits 0, no row" || fail "non-JSON (got ${got})"
}

case_real_denials_are_recorded
case_quoted_prose_is_not_a_denial
case_mixed_output_keeps_the_real_line
case_classifier_denials_are_recorded
case_never_blocks

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
