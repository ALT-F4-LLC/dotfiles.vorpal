#!/bin/bash

# Behavior suite for the groom turn guard Stop hook
# (hooks/docket-groom-turn-guard-hook.sh).
#
# WHY THIS EXISTS. A docket-groom pass ended turns on "still open" progress
# reports and the operator typed "continue" to get the next step. Prose rules
# and a self-run lint did not hold, since neither can see the final message
# before it is sent. The hook reads it. Each rule has a failure that reads as
# success: a hook that blocks without a ledger traps unrelated sessions; one
# that ignores "reported": true blocks the final report itself; one that
# ignores stop_hook_active can loop forever; one that treats an unreadable
# transcript or missing lint as a hit locks the operator out.
#
# HOW. A fixture scratchpad ledger, a fixture JSONL transcript and a stub
# lint (the real report-lint.sh is also run once). Needs bash, jq, grep.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GROOM_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-groom-turn-guard-hook.sh}"
REAL_LINT="${REPO_ROOT}/src/user/claude_code/skills/docket-groom/scripts/report-lint.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
[ -f "$REAL_LINT" ] || fatal "report-lint.sh not found"
command -v jq >/dev/null 2>&1 || fatal "jq is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/groom-turn-guard.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SESSION="11111111-2222-3333-4444-555555555555"
PAD="${WORK}/claude-1/slug/${SESSION}/scratchpad"
mkdir -p "$PAD"
GLOB="${WORK}/claude-*/*/@SESSION@/scratchpad/docket-groom-*.json"
TRANSCRIPT="${WORK}/t.jsonl"

# transcript <assistant text>
transcript() {
    jq -cn --arg t "$1" '{type:"user",message:{content:"go"}}, {type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$TRANSCRIPT"
}

# run <name> <want exit> [stop_hook_active] [session id]
run() {
    local name="$1" want="$2" active="${3:-false}" sid="${4:-$SESSION}" rc
    jq -cn --arg s "$sid" --arg p "$TRANSCRIPT" --argjson a "$active" \
        '{session_id:$s, transcript_path:$p, stop_hook_active:$a}' \
        | GROOM_LEDGER_GLOB="$GLOB" GROOM_REPORT_LINT="${LINT_OVERRIDE:-$REAL_LINT}" bash "$HOOK" >/dev/null 2>"${WORK}/err"
    rc=$?
    [ "$rc" -eq "$want" ] && pass "$name" || fail "${name}: exit ${rc}, want ${want}"
}

printf '{"reported": false}\n' > "${PAD}/docket-groom-docket-20261017T000000Z.json"

transcript $'Round 2 applied.\nStill open for this pass: splits.'
run "hand-back on an unreported ledger is blocked" 2
grep -q 'groom turn guard' "${WORK}/err" && pass "deny message names the guard" || fail "deny message lacks the guard name"

run "stop_hook_active allows the retry" 0 true
run "another session id is not blocked" 0 false "99999999-0000-0000-0000-000000000000"

transcript "Round 2 applied. Asking the next batch."
run "clean closing text is allowed" 0

printf '{"reported": true}\n' > "${PAD}/docket-groom-docket-20261017T000000Z.json"
transcript $'Final report.\nBlocked on the operator: x.\nStill open: none'
run "reported ledger is not blocked" 0

printf '{"reported": false}\n' > "${PAD}/docket-groom-docket-20261017T000000Z.json"
rm -f "${PAD}"/docket-groom-*.json
transcript "Still open: splits."
run "no ledger is allowed" 0

printf '{"reported": false}\n' > "${PAD}/docket-groom-docket-20261017T000000Z.json"
rm -f "$TRANSCRIPT"
run "unreadable transcript is allowed" 0

transcript "Still open: splits."
LINT_OVERRIDE="${WORK}/missing-lint.sh" run "missing lint script is allowed" 0

jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"Bash"}]}}' > "$TRANSCRIPT"
run "assistant entry without text is allowed" 0

transcript "Still open: splits."
printf 'not json' | GROOM_LEDGER_GLOB="$GLOB" GROOM_REPORT_LINT="$REAL_LINT" bash "$HOOK" >/dev/null 2>&1
[ $? -eq 0 ] && pass "malformed payload is allowed" || fail "malformed payload was blocked"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
