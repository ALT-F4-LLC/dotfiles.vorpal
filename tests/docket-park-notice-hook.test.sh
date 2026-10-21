#!/bin/bash

# Behavior suite for the park-notice hook (hooks/docket-park-notice-hook.sh).
#
# WHY THIS EXISTS. docket-run says to send one PushNotification for each new
# waiting-human park, and a conductor let parks pile up for fifteen hours with
# no push, so the operator learned of them only by asking. A prose rule cannot
# see a park; the hook reads the engine's event log and the transcript.
# Each rule has a failure that reads as success: a hook that blocks only at
# Stop misses a park routed mid-turn while work keeps moving; one that ignores
# the push lets the unannounced park through; one that accepts any push, not
# one naming the step, lets a stale push cover a new park; one that ignores
# resolved parks nags forever; one that checks runs the transcript never names
# blocks another session's conductor.
#
# HOW. A stub `docket` answers `run status` and `events list --run R --kind K`
# from fixture files; a fixture JSONL transcript carries the PushNotification
# calls. Needs bash and jq.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${PARK_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-park-notice-hook.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/park-notice.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
FIX="${WORK}/fix"
BIN="${WORK}/bin"
mkdir -p "$FIX" "$BIN"
TRANSCRIPT="${WORK}/t.jsonl"

# The stub answers the three calls the hook makes, from $FIX.
cat > "${BIN}/docket" <<'EOF'
#!/bin/bash
[ -f "$FIX/down" ] && exit 1
[ -f "$FIX/events-down" ] && [ "$1 $2" = "events list" ] && exit 1
if [ "$1 $2" = "run status" ]; then cat "$FIX/runs.json"; exit 0; fi
if [ "$1 $2" = "events list" ]; then
    kind="" run="" tail=""
    while [ $# -gt 0 ]; do case "$1" in --kind) kind="$2" ;; --run) run="$2" ;; --tail) tail="$2" ;; esac; shift; done
    [ -n "$run" ] && [ -n "$tail" ] || exit 1
    [ -f "$FIX/fail-$kind" ] && exit 1
    f="$FIX/events-$run-$kind.json"
    [ -f "$f" ] || printf '{"ok":true,"data":{"events":[],"total":0}}\n' > "$f"
    tf="$FIX/total-$kind"; [ -f "$tf" ] || tf="$FIX/total"
    if [ -f "$tf" ]; then jq -c --argjson t "$(cat "$tf")" '.data.total = $t' "$f"; else jq -c '.data.total = (.data.events | length)' "$f"; fi
    exit 0
fi
exit 1
EOF
chmod +x "${BIN}/docket"

T0=1792000000   # session start, seconds
iso() { date -u -r "$1" +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d "@$1" +%Y-%m-%dT%H:%M:%S.000Z; }

# transcript: a user line at T0 naming the run, then optional pushes.
reset() {
    rm -f "$FIX"/events-*.json "$FIX/down" "$FIX/total" "$FIX/events-down" "$FIX"/fail-* "$FIX"/total-*
    printf '{"ok":true,"data":{"runs":[{"run":"RUN-158","status":"active"}],"total":1}}\n' > "$FIX/runs.json"
    jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"drive the run"}}' > "$TRANSCRIPT"
    conduct RUN-158 $((T0 + 1))
}
# conduct <run> <epoch seconds>: the session drives the run through its own tool call.
conduct() {
    jq -cn --arg ts "$(iso "$2")" --arg c "docket next --run $1" \
        '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:$c}}]}}' >> "$TRANSCRIPT"
}
# push <epoch seconds> <message>
push() {
    jq -cn --arg ts "$(iso "$1")" --arg m "$2" \
        '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"PushNotification",input:{message:$m}}]}}' >> "$TRANSCRIPT"
}
# park <step id> <seq> <epoch seconds> [detail]
park() {
    local f="$FIX/events-${PARK_RUN:-RUN-158}-step-routed.json" cur
    [ -f "$f" ] && cur=$(jq -c '.data.events' "$f") || cur='[]'
    jq -cn --argjson cur "$cur" --arg s "$1" --argjson q "$2" --argjson at "$(( $3 * 1000 ))" --arg d "${4:-waiting-human}" \
        '{ok:true,data:{events:($cur + [{seq:$q,at_ms:$at,kind:"step-routed",run:"RUN-158",issue:"ISS-1",step_id:$s,data:{detail:$d}}])}}' > "$f"
}
# clear <kind> <step id> <seq>
clear_park() {
    local f="$FIX/events-${PARK_RUN:-RUN-158}-$1.json" cur
    [ -f "$f" ] && cur=$(jq -c '.data.events' "$f") || cur='[]'
    jq -cn --argjson cur "$cur" --arg s "$2" --argjson q "$3" --arg k "$1" \
        '{ok:true,data:{events:($cur + [{seq:$q,kind:$k,run:"RUN-158",issue:"ISS-1",step_id:$s}])}}' > "$f"
}

# run <name> <want exit> <event json fragment> [expected text in stderr]
run() {
    local name="$1" want="$2" input="$3" text="${4:-}" rc
    printf '%s' "$input" | PATH="${BIN}:${PATH}" FIX="$FIX" bash "$HOOK" >/dev/null 2>"${WORK}/err"
    rc=$?
    if [ "$rc" -ne "$want" ]; then fail "${name}: exit ${rc}, want ${want}"; return; fi
    if [ -n "$text" ] && ! grep -q -- "$text" "${WORK}/err"; then fail "${name}: stderr lacks '${text}'"; return; fi
    pass "$name"
}
stop_in() { jq -cn --arg p "$TRANSCRIPT" --argjson a "${1:-false}" '{hook_event_name:"Stop",transcript_path:$p,stop_hook_active:$a}'; }
tool_in() { jq -cn --arg p "$TRANSCRIPT" --arg t "$1" --arg c "${2:-}" '{hook_event_name:"PostToolUse",transcript_path:$p,tool_name:$t,tool_input:{command:$c}}'; }

# 1. Stop with a new park and no push: blocked, naming the step.
reset; park STEP-9001 100 $((T0 + 60))
run "Stop: an unannounced park blocks and names the step" 2 "$(stop_in)" "STEP-9001"

# 2. The same park with a push naming it: allowed.
push $((T0 + 120)) "RUN-158 held: STEP-9001 waits on the operator (gate: security-vote)"
run "Stop: a push naming the step allows" 0 "$(stop_in)"

# 3. A park routed mid-turn, the turn not ending: the next wave or dispatch call blocks.
reset; park STEP-9002 101 $((T0 + 60))
run "PostToolUse Workflow: an unannounced park blocks" 2 "$(tool_in Workflow)" "STEP-9002"
run "PostToolUse docket dispatch: an unannounced park blocks" 2 "$(tool_in Bash 'docket dispatch close DISPATCH-4')" "STEP-9002"
run "PostToolUse docket next: an unannounced park blocks" 2 "$(tool_in Bash 'docket next --run RUN-158')" "STEP-9002"
# 3b. The failing variant: the park stays unannounced across later tool calls.
run "PostToolUse: the park stays blocked across repeated calls" 2 "$(tool_in Workflow)" "STEP-9002"
push $((T0 + 90)) "RUN-158: STEP-9002 parked, held while other work moves"
run "PostToolUse Workflow: the push allows" 0 "$(tool_in Workflow)"
run "PostToolUse docket dispatch: the push allows" 0 "$(tool_in Bash 'docket dispatch close DISPATCH-4')"

# 4. Calls that are not a wave or dispatch call are left alone.
reset; park STEP-9003 102 $((T0 + 60))
run "PostToolUse Bash that is not docket next/dispatch is allowed" 0 "$(tool_in Bash 'git status')"
run "PostToolUse of another tool is allowed" 0 "$(tool_in Read)"
run "an unknown hook event is allowed" 0 "$(jq -cn --arg p "$TRANSCRIPT" '{hook_event_name:"SessionStart",transcript_path:$p}')"

# 5. A push that does not name the step, or that predates the park, does not cover it.
reset; park STEP-9004 103 $((T0 + 200))
push $((T0 + 300)) "RUN-158: STEP-90041 is parked"
run "a push naming a different step (prefix match) does not cover it" 2 "$(stop_in)" "STEP-9004"
reset; park STEP-9005 104 $((T0 + 200))
push $((T0 + 100)) "RUN-158: STEP-9005 will park soon"
run "a push sent before the park was routed does not cover it" 2 "$(stop_in)" "STEP-9005"

# 6. Resolved or skipped parks are not outstanding.
reset; park STEP-9006 105 $((T0 + 60)); clear_park step-resolved STEP-9006 110
run "a resolved park is not outstanding" 0 "$(stop_in)"
reset; park STEP-9007 106 $((T0 + 60)); clear_park step-skipped STEP-9007 111
run "a skipped park is not outstanding" 0 "$(stop_in)"
reset; park STEP-9008 107 $((T0 + 60)); clear_park step-resolved STEP-9008 50
run "a resolve that predates the park does not clear it" 2 "$(stop_in)" "STEP-9008"

# 7. Only waiting-human routes count, and only recent ones in runs this transcript names.
reset; park STEP-9009 108 $((T0 + 60)) "pass"
run "a route that is not waiting-human is allowed" 0 "$(stop_in)"
reset; park STEP-9010 109 $((T0 - 500))
run "a park routed before the transcript began is allowed" 0 "$(stop_in)"
reset; park STEP-9011 112 $((T0 + 60)) "waiting-human: the step recorded only gap artifacts; operator disposes"
run "a waiting-human route with a reason still blocks" 2 "$(stop_in)" "STEP-9011"
reset; park STEP-9012 113 $((T0 + 60))
jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"nothing about runs"}}' > "$TRANSCRIPT"
run "a run the transcript never names is allowed" 0 "$(stop_in)"
# The session-start hook writes the live run listing into every transcript that
# starts while a run is active; it names the run but drives nothing.
jq -cn --arg ts "$(iso $T0)" '{type:"attachment",timestamp:$ts,attachment:{type:"hook_success",hookName:"SessionStart:startup",content:"Active Docket engine runs in this repo (docket run status --json):\n{\"runs\":[{\"run\":\"RUN-158\"}]}"}}' > "$TRANSCRIPT"
run "a run named only in the session-start listing is allowed" 0 "$(stop_in)"
jq -cn --arg ts "$(iso $T0)" '{type:"assistant",timestamp:$ts,message:{content:[{type:"text",text:"RUN-158 is parked on STEP-9012 --run RUN-158"}]}}' > "$TRANSCRIPT"
run "a run named only in prose is allowed" 0 "$(stop_in)"
jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"x"}}' > "$TRANSCRIPT"; conduct RUN-1580 $((T0 + 1))
run "a longer run id is not a match for the run (prefix)" 0 "$(stop_in)"
reset; printf '{"ok":true,"data":{"runs":[{"run":"RUN-158"},{"run":"RUN-159"}],"total":2}}\n' > "$FIX/runs.json"
PARK_RUN=RUN-159 park STEP-9030 130 $((T0 + 60))
run "a live run the session does not conduct is allowed" 0 "$(stop_in)"
conduct RUN-159 $((T0 + 2))
run "once the session conducts that run it is blocked" 2 "$(stop_in)" "STEP-9030 (RUN-159)"
reset; park STEP-9031 131 $((T0 + 60)); clear_park step-superseded STEP-9031 140
run "a superseded park is not outstanding" 0 "$(stop_in)"
reset; park STEP-9032 132 $((T0 + 60)); echo 1001 > "$FIX/total-step-routed"
run "a step-routed list cut at the newest events still blocks an unannounced park" 2 "$(stop_in)" "STEP-9032"
rm -f "$FIX/total"
reset; park STEP-9033 133 $((T0 + 60))
jq -cn '{type:"user",message:{content:"no timestamps"}}' > "$TRANSCRIPT"; jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"Bash",input:{command:"docket next --run RUN-158"}}]}}' >> "$TRANSCRIPT"
run "a transcript with no timestamps is allowed" 0 "$(stop_in)"
# Same second, later millisecond: a push after the park covers it.
reset; park STEP-9034 134 $((T0 + 60)); jq -c '.data.events[0].at_ms += 100' "$FIX/events-RUN-158-step-routed.json" > "$FIX/x" && mv "$FIX/x" "$FIX/events-RUN-158-step-routed.json"
jq -cn --arg ts "$(iso $((T0 + 60)))" '{type:"assistant",timestamp:($ts | sub("\\.000Z$"; ".500Z")),message:{content:[{type:"tool_use",name:"PushNotification",input:{message:"RUN-158 STEP-9034 parked"}}]}}' >> "$TRANSCRIPT"
run "a push in the same second but a later millisecond covers the park" 0 "$(stop_in)"
reset; park STEP-9035 135 $((T0 + 60)); jq -c '.data.events[0].at_ms += 900' "$FIX/events-RUN-158-step-routed.json" > "$FIX/x" && mv "$FIX/x" "$FIX/events-RUN-158-step-routed.json"
jq -cn --arg ts "$(iso $((T0 + 60)))" '{type:"assistant",timestamp:($ts | sub("\\.000Z$"; ".500Z")),message:{content:[{type:"tool_use",name:"PushNotification",input:{message:"RUN-158 STEP-9035 parked"}}]}}' >> "$TRANSCRIPT"
run "a push in the same second but an earlier millisecond does not cover the park" 2 "$(stop_in)" "STEP-9035"

# 8. Loop and failure safety.
reset; park STEP-9013 114 $((T0 + 60))
run "Stop: stop_hook_active allows the retry" 0 "$(stop_in true)"
printf '{"ok":true,"data":{"runs":[],"total":0}}\n' > "$FIX/runs.json"
run "no live run is allowed" 0 "$(stop_in)"
reset; park STEP-9014 115 $((T0 + 60)); : > "$FIX/down"
run "an unreadable engine is allowed" 0 "$(stop_in)"
reset; park STEP-9015 116 $((T0 + 60)); rm -f "$TRANSCRIPT"
run "a missing transcript is allowed" 0 "$(stop_in)"
reset; park STEP-9016 117 $((T0 + 60))
printf '' | PATH="${BIN}:${PATH}" FIX="$FIX" bash "$HOOK" >/dev/null 2>&1; [ $? -eq 0 ] && pass "empty stdin is allowed" || fail "empty stdin blocked"
PATH="/usr/bin:/bin" bash "$HOOK" < /dev/null >/dev/null 2>&1; [ $? -eq 0 ] && pass "no docket on PATH is allowed" || fail "no docket blocked"

reset; park STEP-9040 140 $((T0 + 60)); : > "$FIX/events-down"
run "events failing after run status succeeds is allowed" 0 "$(stop_in)"
rm -f "$FIX/events-down"
reset; jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"x"}}' > "$TRANSCRIPT"
jq -cn --arg ts "$(iso $((T0 + 1)))" '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:"docket run report RUN-158"}}]}}' >> "$TRANSCRIPT"
park STEP-9050 150 $((T0 + 60))
run "a tool call that only reads the run's report does not make the session its conductor" 0 "$(stop_in)"
# A failed or truncated clearing query cannot establish that nothing cleared.
reset; park STEP-9060 160 $((T0 + 60)); : > "$FIX/fail-step-resolved"
run "a failed clearing query is allowed" 0 "$(stop_in)"
reset; park STEP-9061 161 $((T0 + 60)); echo 2000 > "$FIX/total-step-resolved"
run "a truncated clearing query is allowed" 0 "$(stop_in)"
# Abandoning the issue clears its parked step with no step-level event.
reset; park STEP-9062 162 $((T0 + 60)); clear_park issue-abandoned STEP-9099 170
run "an issue-abandoned event for the park's issue clears it" 0 "$(stop_in)"
reset; park STEP-9063 163 $((T0 + 60)); clear_park issue-abandoned STEP-9099 40
run "an abandon that predates the park does not clear it" 2 "$(stop_in)" "STEP-9063"
# A subagent's payload carries the parent's transcript.
reset; park STEP-9064 164 $((T0 + 60))
run "a subagent is never held to the push" 0 "$(tool_in Workflow | jq -c '. + {agent_id:"a1"}')"
# Reading a run's events is not conducting it.
reset; jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"x"}}' > "$TRANSCRIPT"
jq -cn --arg ts "$(iso $((T0 + 1)))" '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:"docket events list --run RUN-158 --kind step-routed"}}]}}' >> "$TRANSCRIPT"
park STEP-9065 165 $((T0 + 60))
run "a read-only --run call does not make the session the conductor" 0 "$(stop_in)"
reset; jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"x"}}' > "$TRANSCRIPT"
jq -cn --arg ts "$(iso $((T0 + 1)))" '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:"cat ~/.docket/conductor.d/RUN-158.token"}}]}}' >> "$TRANSCRIPT"
park STEP-9066 166 $((T0 + 60))
run "reading the conductor token path makes the session the conductor" 2 "$(stop_in)" "STEP-9066"
# Unattended mode queues questions instead of pushing; the latest operator
# note with the fixed text decides, and anything else is attended.
UNATT="conductor escalation mode: unattended; conductor-internal, changes nothing in executor instructions"
ATT="conductor escalation mode: attended; conductor-internal, changes nothing in executor instructions"
# mode_note <seq> <authority> <text>
mode_note() {
    local f="$FIX/events-RUN-158-run-note-added.json" cur at="${4:-$(( (T0 + 30) * 1000 ))}"
    [ -f "$f" ] && cur=$(jq -c '.data.events' "$f") || cur='[]'
    jq -cn --argjson cur "$cur" --argjson q "$1" --arg a "$2" --arg x "$3" --argjson at "$at" \
        '{ok:true,data:{events:($cur + [{seq:$q,at_ms:$at,kind:"run-note-added",run:"RUN-158",data:{authority:$a,text:$x}}])}}' > "$f"
}
reset; park STEP-9070 170 $((T0 + 60)); mode_note 10 operator "$UNATT"
run "an unattended run is not held to the push" 0 "$(stop_in)"
reset; park STEP-9071 171 $((T0 + 60)); mode_note 10 operator "$UNATT"; mode_note 20 operator "$ATT"
run "switching back to attended holds the run to the push again" 2 "$(stop_in)" "STEP-9071"
reset; park STEP-9072 172 $((T0 + 60)); mode_note 10 conductor "$UNATT"
run "an unattended note without operator authority does not count" 2 "$(stop_in)" "STEP-9072"
reset; park STEP-9073 173 $((T0 + 60)); mode_note 10 operator "conductor escalation mode: unattended-ish"
run "a note that is not the fixed text does not count" 2 "$(stop_in)" "STEP-9073"
reset; park STEP-9074 174 $((T0 + 60)); : > "$FIX/fail-run-note-added"
run "an unreadable mode note reads as attended" 2 "$(stop_in)" "STEP-9074"
# A new session starts attended, so an unattended note older than this session is stale.
reset; park STEP-9075 175 $((T0 + 60)); mode_note 10 operator "$UNATT" $(( (T0 - 500) * 1000 ))
run "an unattended note from an earlier session is stale and does not skip the run" 2 "$(stop_in)" "STEP-9075"
# A newline ends a command: the second line's --run does not belong to the first.
reset; jq -cn --arg ts "$(iso $T0)" '{type:"user",timestamp:$ts,message:{content:"x"}}' > "$TRANSCRIPT"
jq -cn --arg ts "$(iso $((T0 + 1)))" --arg c $'docket next --json\ndocket events list --run RUN-158' '{type:"assistant",timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:$c}}]}}' >> "$TRANSCRIPT"
park STEP-9076 176 $((T0 + 60))
run "a --run on a later line of a multi-line command does not make the session the conductor" 0 "$(stop_in)"
# 9. Two parks, one announced: only the unannounced one is named.
reset; park STEP-9020 120 $((T0 + 60)); park STEP-9021 121 $((T0 + 61))
push $((T0 + 100)) "RUN-158: STEP-9020 parked"
run "two parks, one announced: the other is named" 2 "$(stop_in)" "STEP-9021"
grep -q 'STEP-9020' "${WORK}/err" && fail "the announced step was named" || pass "the announced step is not named"

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
