#!/bin/bash

set -uo pipefail

# SubagentStop silent-completion nudge (DKT-253).
#
# Fires at a subagent turn-end. Detects the report-emission skill family's #1
# defect class: a structured verdict emitted into context (trailing
# "... emitted (...)" confirmation line) but NOT SendMessage'd to the calling
# agent in the same turn. Injects a corrective nudge via
# hookSpecificOutput.additionalContext.
#
# BOUNDARY vs task-completed-hook.sh (TaskCompleted): that hook BLOCKS at
# task-marking time when NO report SendMessage exists anywhere after the task
# claim; THIS hook only NUDGES at turn-end, and only when a report-EMISSION
# confirmation line is present but unsent. Different event, trigger, and
# response -- they do not overlap in enforcement.
#
# WHY the emission-line gate (not "any quiet turn"): SubagentStop fires on
# EVERY subagent turn-end, including the many legitimate read/grep/edit turns
# that carry no SendMessage. The emission-confirmation line is the discriminator
# that separates "finished a deliverable, unsent" from "still working" -- so the
# scan runs ONLY when that line is present in last_assistant_message.
#
# Fail-open throughout: any parse/resolution/race failure emits {} (allow). A
# wrong transcript guess can only MISS a violation, never fabricate a false
# nudge (the emission gate must pass first, and resolution misses allow).
#
# TWO load-bearing assumptions -- LIVE-PROBE before trusting in prod:
#   (1) SubagentStop stdin exposes .last_assistant_message and .agent_id, and
#       .transcript_path resolves to (or via agent_id to) the SUBAGENT's own
#       transcript. If (1) drifts, resolution fails -> allow (miss, not false
#       nudge).
#   (2) additionalContext on SubagentStop re-prompts the stopped subagent. If it
#       does NOT, the nudge is inert -- switch emit_nudge to
#       {decision:"block", reason:...} (heavier; counts against
#       CLAUDE_CODE_STOP_HOOK_BLOCK_CAP).

EMIT_RE='(Code review|Verification report|Design QA report|Design review) emitted \('

emit_allow() { printf '{}\n'; exit 0; }

emit_nudge() {
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "SubagentStop",
            additionalContext: "SILENT-COMPLETION NUDGE: your context shows a report-emission skill confirmation line (\"... emitted (...)\") but no SendMessage this turn. The in-context emission is your working artifact, NOT the deliverable -- SendMessage the structured verdict body (not summarized) to team-lead (team mode) or the peer (standalone) BEFORE ending this turn. If you already delivered it, ignore this."
        }
    }' 2>/dev/null || printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_allow
command -v jq >/dev/null 2>&1 || emit_allow

# Gate 1 (stdin only): did this turn emit a report-emission confirmation line?
LAST_MSG=$(printf '%s' "$DATA" | jq -r '.last_assistant_message // empty' 2>/dev/null) || emit_allow
printf '%s' "$LAST_MSG" | grep -qE "$EMIT_RE" 2>/dev/null || emit_allow

# Resolve the subagent's own transcript. agent_id is unique, so resolution is a
# direct filename-substring match -- no newest-mtime tiebreak (unlike the
# teammate_name key in task-completed-hook.sh). agent_id is compared only as a
# quoted literal in a case pattern, never interpolated into a glob or path.
AGENT_ID=$(printf '%s' "$DATA" | jq -r '.agent_id // empty' 2>/dev/null) || emit_allow
TRANSCRIPT_PATH=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null) || emit_allow
[ -n "$TRANSCRIPT_PATH" ] || emit_allow

case "$TRANSCRIPT_PATH" in
    */subagents/agent-*.jsonl)
        RESOLVED_PATH="$TRANSCRIPT_PATH"
        ;;
    *)
        [ -n "$AGENT_ID" ] || emit_allow
        SESSION_DIR="${TRANSCRIPT_PATH%.jsonl}"
        CANDIDATES_DIR="${SESSION_DIR}/subagents"
        [ -d "$CANDIDATES_DIR" ] && [ -r "$CANDIDATES_DIR" ] || emit_allow
        RESOLVED_PATH=""
        for CAND in "$CANDIDATES_DIR"/agent-*.jsonl; do
            [ -f "$CAND" ] && [ -r "$CAND" ] || continue
            case "${CAND##*/}" in
                *"$AGENT_ID"*) RESOLVED_PATH="$CAND"; break ;;
            esac
        done
        [ -n "$RESOLVED_PATH" ] || emit_allow
        ;;
esac
[ -r "$RESOLVED_PATH" ] || emit_allow

scan() {
    jq -R -r --arg re "$EMIT_RE" '
        (try fromjson catch empty)
        | (.message.content // []) as $c
        | if ($c | type) == "array" then
            (if ($c | any(.type == "text" and ((.text // "") | test($re)))) then "1" else "0" end)
            + ":" +
            (if ($c | any(.type == "tool_use" and .name == "SendMessage")) then "1" else "0" end)
          else "0:0" end
    ' "$RESOLVED_PATH" 2>/dev/null
}

evaluate() {
    local idx=0 last_emit=-1 last_send=-1 line
    while IFS= read -r line; do
        case "$line" in
            1:*) last_emit=$idx ;;
        esac
        case "$line" in
            *:1) last_send=$idx ;;
        esac
        idx=$((idx + 1))
    done <<< "$1"
    if [ "$last_emit" -ge 0 ] && [ "$last_send" -lt "$last_emit" ]; then
        return 0
    fi
    return 1
}

SCAN=$(scan)

if ! printf '%s' "$SCAN" | grep -q '^1:' 2>/dev/null; then
    sleep 0.2 2>/dev/null || true
    SCAN=$(scan)
fi

if evaluate "$SCAN"; then
    emit_nudge
fi

emit_allow
