#!/bin/bash

set -uo pipefail

emit_empty() {
    printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_empty

[ -e "${HOME}/.claude/teammate-idle-hook.debug" ] && printf '%s\n' "$DATA" >> "${HOME}/.claude/teammate-idle-hook.log" 2>/dev/null || true

if ! command -v jq >/dev/null 2>&1; then
    emit_empty
fi

AGENT_TYPE=$(printf '%s' "$DATA" | jq -r '.agent_type // empty' 2>/dev/null) || emit_empty
TEAMMATE_NAME=$(printf '%s' "$DATA" | jq -r '.teammate_name // empty' 2>/dev/null) || emit_empty

# Resolve the actual idling teammate's name (DKT-289). Live-fire instrumentation
# confirmed the TeammateIdle payload never carries agent_id, and transcript_path
# is always the ambient root session -- so DKT-262's agent_id/transcript_path
# resolution never fires and always falls through to the ambient agent_type
# ("team-lead"). The payload does carry teammate_name (the same field
# task-completed-hook.sh uses for its identical ambient-event class, DKT-206)
# already set to the real idling teammate's display name -- use it directly.
# Falls back to agent_type only when teammate_name is absent.
NAME="$TEAMMATE_NAME"
[ -n "$NAME" ] || NAME="$AGENT_TYPE"

SUFFIX="idle: shutdown is lead-initiated — do NOT self-emit shutdown_request or any other structured shutdown/plan protocol message. Ephemeral teammates: first land your Docket mirror/close comment, THEN confirm your completion report/verdict was delivered to team-lead via SendMessage (mirror-first — team-lead.md Rule 2); THEN idle and AWAIT team-lead's shutdown_request, replying shutdown_response (approve) when it arrives. Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."

if [ -n "$NAME" ]; then
    REMINDER="Teammate '${NAME}' ${SUFFIX}"
else
    REMINDER="Teammate ${SUFFIX}"
fi

jq -n --arg msg "$REMINDER" '{systemMessage: $msg}' 2>/dev/null || emit_empty

exit 0
