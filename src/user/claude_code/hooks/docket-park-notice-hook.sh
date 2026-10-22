#!/bin/bash

# Hold a conductor to the push docket-run requires for every new waiting-human
# park: one PushNotification naming the run, the gate and the parked step.
#
# Runs at Stop and after a Workflow or a `docket next` / `docket dispatch`
# call, so a park routed mid-turn is caught on the next wave or dispatch call
# and one left over at turn end is caught at Stop. A park is outstanding when
# its step-routed event reads waiting-human and nothing later clears it: a
# step-resolved, step-skipped or step-superseded event for its step, or an
# issue-abandoned event for its issue. It is announced when this session's
# transcript holds a PushNotification, sent after the park was routed, that
# names the step id.
#
# Only runs this session's own tool calls drive are checked (`docket next` or a
# run-moving `docket dispatch` verb with `--run RUN-N`, or the conductor token
# path, as docket-driven-runs.jq beside this hook tests it; a read-only
# `--run` call does not count), and only parks routed after the transcript
# began, so another session's runs and earlier sessions' parks never block this
# one. An unattended run (its latest operator-authority mode note) is skipped,
# since unattended mode queues questions instead of pushing. A run id that
# appears only in the session-start listing or in prose names nothing. A
# subagent is never held to it.
#
# Missing jq, docket or docket-driven-runs.jq, an unreadable transcript, or any
# unreadable or truncated engine answer allows. A step-routed list cut at the
# newest 5000 loses only the oldest parks, which leans toward allow. A conductor
# that holds its run id in a shell variable is not recognized, and a switch to
# attended whose mode note failed to write still reads as unattended. The Stop
# path honors stop_hook_active so one block cannot trap a session; the tool-call
# path blocks until the push is sent, which is the point of it.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || allow
command -v docket >/dev/null 2>&1 || allow
DATA=$(cat 2>/dev/null) || allow

EVENT=$(printf '%s' "$DATA" | jq -r '.hook_event_name // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || allow

# A subagent's payload carries the parent's transcript path, and only the
# parent can send the push, so a subagent is never held to it.
[ -n "$(printf '%s' "$DATA" | jq -r '.agent_id // empty' 2>/dev/null)" ] && allow

case "$EVENT" in
    Stop)
        [ "$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && allow
        ;;
    PostToolUse)
        TOOL=$(printf '%s' "$DATA" | jq -r '.tool_name // empty' 2>/dev/null)
        case "$TOOL" in
            Workflow) ;;
            Bash)
                CMD=$(printf '%s' "$DATA" | jq -r '.tool_input.command // empty' 2>/dev/null)
                [[ "$CMD" =~ docket([[:space:]]+-[^[:space:]]+)*[[:space:]]+(next|dispatch)([[:space:]]|$) ]] || allow
                ;;
            *) allow ;;
        esac
        ;;
    *) allow ;;
esac

RUNS=$(docket run status --limit 0 --json 2>/dev/null \
    | jq -r '.data.runs // [] | .[].run | select(type == "string" and test("^RUN-[0-9]+$"))' 2>/dev/null) || allow
[ -n "$RUNS" ] || allow

# The test of whether a call drives a run lives beside this hook, shared with
# the advisor-first hook; without it nothing can be judged, so allow.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
DRIVES_DEF=$(cat "${HOOK_DIR}/docket-driven-runs.jq" 2>/dev/null) && [ -n "$DRIVES_DEF" ] || allow

# Milliseconds since the epoch for a transcript line's ISO timestamp.
MS_DEF='def ms: (sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601 * 1000)
    + ((capture("\\.(?<f>[0-9]+)Z$")? // {f: "0"}).f + "00" | .[0:3] | tonumber);'

# The newest events of one kind for one run, or nothing when the engine's answer
# is missing or, for a clearing kind, truncated: a partial list could hide a
# clearing, and an unreadable log cannot establish a missing push. A truncated
# step-routed list only loses the oldest parks.
events_of() {
    docket events list --run "$1" --kind "$2" --tail 5000 --json 2>/dev/null \
        | jq -ce --arg k "$2" 'select(.ok == true and ($k == "step-routed" or (.data.total // 0) <= (.data.events | length))) | .data.events' 2>/dev/null
}

# The transcript is read once, and only when some run names this session's
# calls. A malformed or partly written line is skipped, never fatal.
LOADED=""
load_transcript() {
    [ -n "$LOADED" ] && return
    LOADED=1
    START_MS=$(head -n 40 "$TRANSCRIPT" 2>/dev/null | jq -Rrn "$MS_DEF"'
        [ inputs | (try fromjson catch null) | objects | .timestamp? | select(type == "string") | try ms catch empty ] | min // empty' 2>/dev/null)
    # Every tool call the session made: {ms, name, text}. The timestamp lives on
    # the transcript line, not the content block.
    CALLS=$(jq -Rc "$MS_DEF"'(try fromjson catch null) | objects | select(.type == "assistant") | . as $l | $l.message.content? | arrays | .[]
        | select(type == "object" and .type == "tool_use")
        | {ms: (try ($l.timestamp | ms) catch 0), name: (.name // ""), text: (.input.command? // (.input | tostring))}' \
        "$TRANSCRIPT" 2>/dev/null)
}

MISSING=""
for R in $RUNS; do
    # A cheap necessary condition first: a run the transcript never names
    # with --run or the token path cannot be driven here, so it costs no
    # engine query.
    grep -qE "(conductor\\.d/|--run[ =])${R}([^0-9]|\$)" "$TRANSCRIPT" 2>/dev/null || continue
    load_transcript
    # This session conducts the run only when its own tool calls drive it:
    # a run id in the session-start listing or in prose names nothing.
    printf '%s\n' "$CALLS" | jq -e --arg r "$R" "$DRIVES_DEF"' select(.text | drives($r))' >/dev/null 2>&1 || continue

    ROUTED=$(events_of "$R" step-routed) || continue
    [ -n "$ROUTED" ] || continue
    # The lists travel on stdin: thousands of events overrun the kernel's
    # per-argument limit as a --argjson value.
    CLEARED=$(for K in step-resolved step-skipped step-superseded issue-abandoned; do
                  events_of "$R" "$K" || exit 1
              done | jq -cs 'add // []' 2>/dev/null) || continue
    OPEN=$(printf '%s\n%s\n' "$ROUTED" "$CLEARED" | jq -cs '
        .[1] as $cleared
        | .[0][] | select((.data.detail // "") | startswith("waiting-human"))
        | select(.step_id != null)
        | . as $p
        | select(($cleared | map(select(.seq > $p.seq and (if .kind == "issue-abandoned" then .issue == $p.issue else .step_id == $p.step_id end))) | length) == 0)
        | {step_id, at_ms}' 2>/dev/null) || continue
    [ -n "$OPEN" ] || continue

    # An unattended run replaces ask-and-notify with a queue (docket-run's
    # unattended ruling), so it is not held to the push. The mode is the latest
    # operator-authority note with the fixed text, written since this session
    # began: a new session starts attended, so an older note is stale. Any other
    # state, or an unreadable answer, is attended.
    MODE=$(docket events list --run "$R" --kind run-note-added --tail 200 --json 2>/dev/null \
        | jq -r --argjson start "${START_MS:-9999999999999}" '
            [.data.events[]? | select(.data.authority == "operator" and .at_ms >= $start
                  and ((.data.text // "") | startswith("conductor escalation mode: ")))]
                 | last | .data.text // ""' 2>/dev/null)
    [[ "$MODE" == "conductor escalation mode: unattended;"* ]] && continue
    while IFS= read -r P; do
        [ -n "$P" ] || continue
        STEP=$(printf '%s' "$P" | jq -r '.step_id')
        AT=$(printf '%s' "$P" | jq -r '.at_ms')
        # Parks routed before the transcript began belong to an earlier session;
        # with no readable start, START_MS is empty and the test fails toward allow.
        [ "$AT" -ge "$START_MS" ] 2>/dev/null || continue
        if ! printf '%s\n' "$CALLS" | jq -e --arg s "$STEP" --argjson at "$AT" \
                'select((.name | test("PushNotification$")) and .ms >= $at and (.text | test($s + "([^0-9]|$)")))' \
                >/dev/null 2>&1; then
            MISSING="${MISSING:+$MISSING, }$STEP ($R)"
        fi
    done <<< "$OPEN"
done

[ -n "$MISSING" ] || allow

deny "Held-question push missing: ${MISSING} parked waiting-human and no PushNotification naming the step has been sent since. Send one PushNotification that names the run, the gate and the step id(s), then continue the loop; ask the question once nothing unaffected can move (docket-run: a gate that parks one issue does not stop the run)."
