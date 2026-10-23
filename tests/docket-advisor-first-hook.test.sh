#!/bin/bash

# Behavior suite for the advisor-first hook (hooks/docket-advisor-first-hook.sh).
#
# WHY THIS EXISTS. docket-run's standing ruling sends every operator-bound
# decision to the advisor first. In one run four question sets reached the
# operator unreviewed, one already had a clear advisor verdict and was re-asked,
# and the advisor later contradicted the conductor's own pick. A prose rule
# cannot see the question being sent; the hook reads the transcript.
# Each rule has a failure that reads as success: a hook that ignores the window
# since the last operator answer lets a stale review cover a new question; one
# that counts a launch not yet answered lets the conductor ask before the
# advisor has spoken; one that accepts any advisor brief lets a review of
# something else cover the question; one that ignores run notes forces a
# re-review of a decision already ruled; one that checks sessions conducting no
# run, or subagents, blocks work the ruling never covered.
#
# HOW. A stub `docket` answers `run status` and `run note list`; a fixture JSONL
# transcript carries the conductor's calls, advisor launches and hand-backs.
# Needs bash and jq.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${ADVISOR_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-advisor-first-hook.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/advisor-first.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
FIX="${WORK}/fix"
BIN="${WORK}/bin"
mkdir -p "$FIX" "$BIN"
TRANSCRIPT="${WORK}/t.jsonl"

cat > "${BIN}/docket" <<'EOF'
#!/bin/bash
[ -f "$FIX/down" ] && exit 1
if [ "$1 $2" = "run status" ]; then cat "$FIX/runs.json"; exit 0; fi
if [ "$1 $2" = "run note" ]; then
    [ -f "$FIX/notes-down" ] && exit 1
    [ -f "$FIX/notes-$4.json" ] && cat "$FIX/notes-$4.json" || printf '{"ok":true,"data":{"notes":[]}}\n'
    exit 0
fi
exit 1
EOF
chmod +x "${BIN}/docket"

SEQ=0
# line <json>: append one transcript line.
line() { printf '%s\n' "$1" >> "$TRANSCRIPT"; }
nextid() { SEQ=$(cat "$WORK/seq" 2>/dev/null || echo 0); SEQ=$((SEQ + 1)); echo "$SEQ" > "$WORK/seq"; printf "toolu_%04d" "$SEQ"; }
# use <id> <name> <input json>: an assistant tool_use.
use() { line "$(jq -cn --arg id "$1" --arg n "$2" --argjson i "$3" '{type:"assistant",message:{content:[{type:"tool_use",id:$id,name:$n,input:$i}]}}')"; }
# result <id> <text>: a user tool_result.
result() { line "$(jq -cn --arg id "$1" --arg t "$2" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,content:$t}]}}')"; }
# text <text>: a user text line (notices and hand-backs).
text() { line "$(jq -cn --arg t "$1" '{type:"user",message:{content:$t}}')"; }

reset() {
    rm -f "$FIX"/notes-*.json "$FIX/down" "$FIX/notes-down"
    printf '{"ok":true,"data":{"runs":[{"run":"RUN-158","status":"active"}],"total":1}}\n' > "$FIX/runs.json"
    : > "$TRANSCRIPT"
    echo 0 > "$WORK/seq"
    local id; id=$(nextid)
    use "$id" Bash '{"command":"docket next --run RUN-158"}'
    result "$id" "ok"
}
# answered: an AskUserQuestion and the operator's answer to it.
answered() {
    local id; id=$(nextid)
    use "$id" AskUserQuestion '{"questions":[{"header":"Earlier","question":"An earlier question?","options":[]}]}'
    result "$id" 'Your questions have been answered: "An earlier question?"="Yes"'
}
# advisor <aid> <prompt> [async|sync|pending]: a launch, with its completion.
advisor() {
    local aid="$1" prompt="$2" mode="${3:-async}" id; id=$(nextid)
    use "$id" Agent "$(jq -cn --arg p "$prompt" '{description:"Review",subagent_type:"advisor",prompt:$p}')"
    if [ "$mode" = sync ]; then
        result "$id" "Advisor report: pick the first option."
    else
        result "$id" "Async agent launched successfully.
agentId: ${aid} (internal ID)"
        [ "$mode" = pending ] || text "<task-notification><task-id>${aid}</task-id><status>completed</status></task-notification>"
    fi
}
# result_err <id> <text>: a tool_result flagged as an error (a hook refusal or an operator rejection).
result_err() { line "$(jq -cn --arg id "$1" --arg t "$2" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,is_error:true,content:$t}]}}')"; }
# attach_done <aid>: a completion notice queued mid-turn, as an attachment line.
attach_done() { line "$(jq -cn --arg t "<task-notification><task-id>$1</task-id><status>completed</status></task-notification>" '{type:"attachment",attachment:{type:"queued_command",prompt:$t}}')"; }
queue_done() { line "$(jq -cn --arg t "<task-notification><task-id>$1</task-id><status>completed</status></task-notification>" '{type:"queue-operation",operation:"enqueue",content:$t}')"; }
handback() { line "$(jq -cn --arg a "$1" '{type:"user",origin:{kind:"peer",from:$a,handback:true},message:{content:"Another Claude session sent a message:\nreport"}}')"; }
# launch_only <aid> <prompt>: an async launch with no completion yet.
launch_only() { advisor "$1" "$2" pending; }
# note <run> <text...>: run notes.
notes() { local r="$1"; shift; jq -cn --args '{ok:true,data:{notes:($ARGS.positional | map({text:.}))}}' "$@" > "$FIX/notes-$r.json"; }

# ask_in <header> <question> [<header2> <question2>]
ask_in() {
    local qs
    qs=$(jq -cn --args '[$ARGS.positional as $p | range(0; ($p | length); 2) | {header: $p[.], question: $p[. + 1], options: []}]' "$@")
    jq -cn --arg p "$TRANSCRIPT" --argjson q "$qs" '{hook_event_name:"PreToolUse",tool_name:"AskUserQuestion",transcript_path:$p,tool_input:{questions:$q}}'
}

# run <name> <want exit> <payload> [expected text in stderr]
run() {
    local name="$1" want="$2" input="$3" text="${4:-}" rc
    printf '%s' "$input" | PATH="${BIN}:${PATH}" FIX="$FIX" bash "$HOOK" >/dev/null 2>"${WORK}/err"
    rc=$?
    if [ "$rc" -ne "$want" ]; then fail "${name}: exit ${rc}, want ${want} ($(head -c 200 "${WORK}/err"))"; return; fi
    if [ -n "$text" ] && ! grep -q -- "$text" "${WORK}/err"; then fail "${name}: stderr lacks '${text}'"; return; fi
    pass "$name"
}

# 1. No advisor launch since the last answer: denied, naming the ruling.
reset; answered
run "a question with no advisor launch since the last answer is denied" 2 "$(ask_in 'CI row' 'May I add the row?')" "advisor-first"
reset
run "a question with no advisor launch at all is denied" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"

# 2. A completed advisor review whose brief names the header: allowed.
reset; answered; advisor a1 "Review this drafted question. Header: CI row. Options: add, skip."
run "a completed advisor review naming the header allows" 0 "$(ask_in 'CI row' 'May I add the row?')"
run "the header match ignores case" 0 "$(ask_in 'ci ROW' 'May I add the row?')"

# 3. A run note citing an advisor ruling for the step: allowed.
reset; answered; notes RUN-158 "Advisor ruled: STEP-9001 retries once, narrowed."
run "a run note recording an advisor ruling for the step allows" 0 "$(ask_in 'Retry' 'Retry STEP-9001?')"
reset; answered; notes RUN-158 "Operator note: STEP-9001 retries once."
run "a run note that does not mention the advisor does not cover the question" 2 "$(ask_in 'Retry' 'Retry STEP-9001?')" "Retry"
reset; answered; notes RUN-158 "Advisor ruled: STEP-9002 retries once."
run "a run note about another step does not cover the question" 2 "$(ask_in 'Retry' 'Retry STEP-9001?')" "Retry"

# 4. The launch must be complete, recent, an advisor, and about this question.
reset; answered; advisor a2 "Review the question with header CI row." pending
run "a launch with no completion notice does not count" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; advisor a3 "Review the question with header CI row." sync
run "a launch whose result is the report itself counts" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; advisor a4 "Review the question with header CI row."; answered
run "a review from before the last operator answer is stale" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; advisor a5 "Review something unrelated: the migration plan."
run "an advisor brief about something else does not cover the question" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; id=$(nextid)
use "$id" Agent '{"description":"x","subagent_type":"Explore","prompt":"Look at header CI row."}'; result "$id" "done"
run "a launch of a non-advisor agent does not count" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; advisor a6 "Review this: May I add the row? Options: add or skip."
run "a brief carrying the full question text counts" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; advisor a7 "Review the restart of STEP-9001."
run "a brief naming the step id in the question counts" 0 "$(ask_in 'Hold' 'Hold STEP-9001?')"
reset; answered; advisor a8 "Review header CI row."
run "a brief covering one of two questions denies and names the other" 2 "$(ask_in 'CI row' 'Add it?' 'Park' 'Park it?')" "Park"
grep -q 'CI row' "${WORK}/err" && fail "the covered question was named" || pass "the covered question is not named"
reset; answered; advisor a9 "Review header CI row and header Park."
run "a brief covering both questions allows" 0 "$(ask_in 'CI row' 'Add it?' 'Park' 'Park it?')"
reset; answered; advisor a10 "Review header CI row."; notes RUN-158 "Advisor ruled STEP-9003: skip."
run "a brief for one question and a note for the other allows" 0 "$(ask_in 'CI row' 'Add it?' 'Skip' 'Skip STEP-9003?')"

# 5. Sessions and calls the ruling does not cover.
reset; : > "$TRANSCRIPT"
run "a session that conducts no run is allowed" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; : > "$TRANSCRIPT"; id=$(nextid); use "$id" Bash '{"command":"docket events list --run RUN-158 --kind step-routed"}'; result "$id" ok
run "a read-only --run call does not make the session the conductor" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; id=$(nextid); use "$id" Bash '{"command":"cat ~/.docket/conductor.d/RUN-158.token"}'; : > "$TRANSCRIPT"; use "$id" Bash '{"command":"cat ~/.docket/conductor.d/RUN-158.token"}'; result "$id" ok
run "the conductor token path makes the session the conductor" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; printf '{"ok":true,"data":{"runs":[{"run":"RUN-159","status":"active"}],"total":1}}\n' > "$FIX/runs.json"
run "a live run the session does not conduct is allowed" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset
run "a subagent is never held to the ruling" 0 "$(ask_in 'CI row' 'May I add the row?' | jq -c '. + {agent_id:"a1"}')"
run "another tool is allowed" 0 "$(ask_in 'CI row' 'May I add the row?' | jq -c '.tool_name = "Read"')"

# 6. Failure safety.
reset; printf '{"ok":true,"data":{"runs":[],"total":0}}\n' > "$FIX/runs.json"
run "no live run is allowed" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; : > "$FIX/down"
run "an unreadable engine is allowed" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; rm -f "$TRANSCRIPT"
run "a missing transcript is allowed" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset
printf '' | PATH="${BIN}:${PATH}" FIX="$FIX" bash "$HOOK" >/dev/null 2>&1; [ $? -eq 0 ] && pass "empty stdin is allowed" || fail "empty stdin blocked"
run "a payload with no questions is allowed" 0 "$(ask_in | jq -c '.tool_input.questions = []')"
PATH="/usr/bin:/bin" bash "$HOOK" < /dev/null >/dev/null 2>&1; [ $? -eq 0 ] && pass "no docket on PATH is allowed" || fail "no docket blocked"

# 7. The hook's own refusal is not an operator answer, so it voids no review.
reset; answered; launch_only b1 "Review header CI row."
id=$(nextid); use "$id" AskUserQuestion '{"questions":[{"header":"CI row","question":"May I add the row?","options":[]}]}'
result_err "$id" "PreToolUse:AskUserQuestion hook error: [bash ~/.claude/hooks/docket-advisor-first-hook.sh]: refused"
text "<task-notification><task-id>b1</task-id><status>completed</status></task-notification>"
run "a refused ask between the launch and its completion does not void the review" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; advisor b2 "Review header CI row."
id=$(nextid); use "$id" AskUserQuestion '{"questions":[{"header":"CI row","question":"May I add the row?","options":[]}]}'
result_err "$id" "The user doesn't want to proceed with this tool use. The tool use was rejected."
run "an operator's rejection of the question is an answer and voids earlier reviews" 2 "$(ask_in 'CI row' 'May I add the row?')"

# 8. Completion shapes the harness writes mid-turn.
reset; answered; launch_only c1 "Review header CI row."; attach_done c1
run "a completion notice queued as an attachment line counts" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only c2 "Review header CI row."; queue_done c2
run "a completion notice in a queue-operation line counts" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only c3 "Review header CI row."; handback c3
run "a hand-back whose origin names the launch counts" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only c4 "Review header CI row."
text "<task-notification><task-id>c4</task-id><status>killed</status></task-notification>"
run "a notice that is not a completed one does not count" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only c5 "Review header CI row."
use "$(nextid)" Bash '{"command":"echo from=\"c5\""}'
line "$(jq -cn '{type:"assistant",message:{content:[{type:"text",text:"The advisor <task-id>c5</task-id> <status>completed</status> said from=\"c5\""}]}}')"
run "an id quoted in assistant text completes nothing" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only c6 "Review header CI row."; attach_done c7
run "a completion notice for a different launch does not count" 2 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; id=$(nextid)
use "$id" Agent '{"description":"x","subagent_type":"advisor","prompt":"Review header CI row."}'; result "$id" "Async agent launched successfully.
agentId: c8 (internal)"; attach_done c8
run "a completion notice after the launch counts when its id is the full id" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; attach_done c9; launch_only c9 "Review header CI row."
run "a completion notice from before the launch does not count" 2 "$(ask_in 'CI row' 'May I add the row?')"

# 9. A step id matches whole, so STEP-12 is not STEP-123.
reset; answered; advisor d1 "Review the restart of STEP-123."
run "a brief naming STEP-123 does not cover a question about STEP-12" 2 "$(ask_in 'Hold' 'Hold STEP-12?')"
reset; answered; notes RUN-158 "Advisor ruled STEP-123: skip."
run "a run note about STEP-123 does not cover a question about STEP-12" 2 "$(ask_in 'Retry' 'Retry STEP-12?')"
reset; answered; advisor d2 "Review the restart of STEP-12."
run "a brief naming STEP-12 covers a question about STEP-12" 0 "$(ask_in 'Hold' 'Hold STEP-12?')"


# 10. A header word elsewhere in an unrelated brief covers nothing; a header
# introduced as one does.
reset; answered; advisor e1 "Review the scope of the migration plan."
run "a bare header word in an unrelated brief does not cover the question" 2 "$(ask_in 'Scope' 'Narrow the change to one file?')" "Scope"
reset; answered; advisor e2 "Review the drafted question, header \"Scope\": narrow it?"
run "a quoted header introduced as one covers the question" 0 "$(ask_in 'Scope' 'Narrow the change to one file?')"

# 11. A read-only dispatch verb does not make the session the conductor.
reset; : > "$TRANSCRIPT"; id=$(nextid); use "$id" Bash '{"command":"docket dispatch verify --run RUN-158"}'; result "$id" ok
run "a read-only docket dispatch verify --run does not make the session the conductor" 0 "$(ask_in 'CI row' 'May I add the row?')"

# 12. A note list the engine cannot answer allows.
reset; answered; : > "$FIX/notes-down"
run "an unreadable run note list allows" 0 "$(ask_in 'Retry' 'Retry STEP-9001?')"

# 13. A malformed transcript line is skipped, not fatal.
reset; answered; printf '{"type":"assistant","message":{"content":[{"type":"tool_use"\n' >> "$TRANSCRIPT"
run "a malformed transcript line does not disable the check" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"

# 14. A failed advisor result is not a review, regardless of its text.
reset; answered; id=$(nextid)
use "$id" Agent '{"subagent_type":"advisor","prompt":"Review this: May I add the row?"}'
result_err "$id" "Permission to use Agent has been denied."
run "a permission-denied advisor launch does not count" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"
reset; answered; id=$(nextid)
use "$id" Agent '{"subagent_type":"advisor","prompt":"Review the restart of STEP-9001."}'
result_err "$id" "PreToolUse:Agent hook error: [bash ~/.claude/hooks/docket-spawn-guard-hook.sh]: refused"
run "an advisor launch refused by a spawn hook does not count" 2 "$(ask_in 'Retry' 'Retry STEP-9001?')" "Retry"
reset; answered; id=$(nextid)
use "$id" Agent '{"subagent_type":"advisor","prompt":"Review header CI row."}'
result_err "$id" "Advisor report: pick the first option."
run "an error result with report-like text does not count" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"
reset; answered; id=$(nextid)
use "$id" Agent '{"subagent_type":"advisor","prompt":"Review header CI row."}'
result_err "$id" "Async agent launched successfully.
agentId: f1 (internal ID)"
attach_done f1
run "an error result with async launch text and a later completion does not count" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"
advisor f2 "Review header CI row." sync
run "a successful review after a failed launch allows" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; id=$(nextid)
use "$id" Agent '{"subagent_type":"advisor","prompt":"Review header CI row."}'
line "$(jq -cn --arg id "$id" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,is_error:false,content:"Advisor report: pick the first option."}]}}')"
run "an explicitly non-error advisor report allows" 0 "$(ask_in 'CI row' 'May I add the row?')"
reset; answered; launch_only f3 "Review header CI row."; id=$(nextid)
use "$id" TaskOutput '{"task_id":"f3"}'
result_err "$id" '<task-notification><task-id>f3</task-id><status>completed</status></task-notification> from="f3"'
run "an error tool result cannot complete a pending advisor launch" 2 "$(ask_in 'CI row' 'May I add the row?')" "CI row"

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
