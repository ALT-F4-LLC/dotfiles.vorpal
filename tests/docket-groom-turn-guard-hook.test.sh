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
REAL_OPEN="${REPO_ROOT}/src/user/claude_code/skills/docket-groom/scripts/ledger-open.sh"

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
        | GROOM_LEDGER_GLOB="$GLOB" GROOM_REPORT_LINT="${LINT_OVERRIDE:-$REAL_LINT}" GROOM_LEDGER_OPEN="$REAL_OPEN" GROOM_BLOCK_CAP="${CAP_OVERRIDE:-25}" bash "$HOOK" >/dev/null 2>"${WORK}/err"
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

# Goal-mode ledgers: the replay of the session that ended on a report with
# unresolved items. "reported": true must not release it.
rm -f "${PAD}"/docket-groom-*.json "${PAD}"/*.blocks
GL="${PAD}/docket-groom-docket-20261017T000001Z.json"
printf '{"mode":"goal","reported":true,"ledger":[{"id":"A-1","judged":true,"state":"run-ready"},{"id":"A-2","judged":true,"state":"open"}]}\n' > "$GL"
transcript "Final report. Not done: A-2 needs a decision. Grooming complete."
run "goal ledger with an open item is blocked though reported" 2
run "goal ledger ignores stop_hook_active" 2 true
grep -q 'ledger-open.sh' "${WORK}/err" && pass "goal deny names the ledger script" || fail "goal deny lacks the script name"

transcript "Clean text with no hand-back phrase."
run "goal block does not depend on the closing text" 2

printf '{"mode":"goal","reported":true,"waiting_on":"workflow wf_1","ledger":[{"id":"A-2","judged":true,"state":"open"}]}\n' > "$GL"
run "goal ledger with a recorded wait is allowed" 0

printf '{"mode":"goal","reported":true,"ledger":[{"id":"A-2","judged":true,"state":"open"}]}\n' > "$GL"
rm -f "${GL}.blocks"
CAP_OVERRIDE=2 run "goal block 1 of cap 2" 2
CAP_OVERRIDE=2 run "goal block 2 of cap 2" 2
CAP_OVERRIDE=2 run "goal block cap releases the session" 0

printf '{"mode":"goal","reported":true,"ledger":[{"id":"A-2","judged":true,"state":"operator-blocked"}]}\n' > "$GL"
rm -f "${GL}.blocks"
run "operator-blocked is open in goal mode" 2

printf '{"mode":"goal","reported":true,"ledger":[{"id":"A-2","judged":true,"state":"waiting"}],"gaps":[{"id":"g1","resolution":"linked B-9"}]}\n' > "$GL"
run "all terminal states and resolved gaps are allowed" 0

printf '{"mode":"goal","reported":true,"ledger":[{"id":"A-2","judged":true,"state":"waiting"}],"gaps":[{"id":"g1"}]}\n' > "$GL"
rm -f "${GL}.blocks"
run "an unresolved gap is open" 2

# entries without "judged" count; epics do not; an empty goal ledger is an error
printf '{"mode":"goal","ledger":[{"id":"A-3","state":"open"},{"id":"E-1","kind":"epic","judged":false}]}\n' > "$GL"
rm -f "${GL}.blocks"
run "entry without a judged field is open" 2
printf '{"mode":"goal","ledger":[]}\n' > "$GL"
"$REAL_OPEN" "$GL" >/dev/null 2>&1; [ $? -eq 2 ] && pass "empty goal ledger exits 2" || fail "empty goal ledger did not exit 2"
printf '{"mode":"goal","ledger":[{"id":"A-2","judged":true,"state":"retired"}]}\n' > "$GL"
"$REAL_OPEN" "$GL" --final >/dev/null && fail "--final after the path skipped verified" || pass "--final is honored after the path"

# block count resets when the open count falls
printf '{"mode":"goal","ledger":[{"id":"A","judged":true,"state":"open"},{"id":"B","judged":true,"state":"open"}]}\n' > "$GL"
rm -f "${GL}.blocks"
CAP_OVERRIDE=1 run "reset: first block" 2
CAP_OVERRIDE=1 run "reset: cap reached releases" 0
printf '{"mode":"goal","ledger":[{"id":"A","judged":true,"state":"retired"},{"id":"B","judged":true,"state":"open"}]}\n' > "$GL"
CAP_OVERRIDE=1 run "reset: progress earns another block" 2

# ledger-open.sh --final
printf '{"mode":"goal","ledger":[{"id":"A-2","judged":true,"state":"retired"}]}\n' > "$GL"
"$REAL_OPEN" "$GL" >/dev/null && pass "ledger-open exits 0 when nothing is open" || fail "ledger-open nonzero on a finished ledger"
"$REAL_OPEN" --final "$GL" >/dev/null && fail "--final passed without verified" || pass "--final requires verified"
printf '{"mode":"goal","verified":true,"ledger":[{"id":"A-2","judged":true,"state":"retired"}]}\n' > "$GL"
"$REAL_OPEN" --final "$GL" >/dev/null && pass "--final passes when verified" || fail "--final failed a verified ledger"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
