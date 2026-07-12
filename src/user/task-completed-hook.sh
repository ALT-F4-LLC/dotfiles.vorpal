#!/bin/bash

set -uo pipefail

BLOCK_REASON='PREMATURE-COMPLETION-BLOCKED: no completion report to team-lead found in your transcript for this task. Send your completion report via SendMessage to team-lead (mirror durable evidence to Docket where your role doctrine requires it) BEFORE marking this task completed, then retry TaskUpdate. If this task genuinely carries no report obligation, send team-lead a one-line status note instead.'

emit_empty() {
    printf '{}\n'
    exit 0
}

emit_block() {
    jq -n --arg reason "$BLOCK_REASON" '{decision: "block", reason: $reason}' 2>/dev/null || printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_empty

if ! command -v jq >/dev/null 2>&1; then
    emit_empty
fi

# Row 1: payload unparsable
TASK_ID=$(printf '%s' "$DATA" | jq -r '.task_id // empty' 2>/dev/null) || emit_empty
TEAMMATE_NAME=$(printf '%s' "$DATA" | jq -r '.teammate_name // empty' 2>/dev/null) || emit_empty
TRANSCRIPT_PATH=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null) || emit_empty

# Row 2: no teammate (solo session or main agent)
if [ -z "$TEAMMATE_NAME" ]; then
    emit_empty
fi

# Row 3: team-lead's own bookkeeping tasks (this repo's topology; not correctness-bearing)
if [ "$TEAMMATE_NAME" = "team-lead" ]; then
    emit_empty
fi

# Row 4: transcript absent or unreadable
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -r "$TRANSCRIPT_PATH" ]; then
    emit_empty
fi

# Row 5: shape-drift canary -- zero recognizable tool_use records of any name
ANY_TOOLUSE_COUNT=$(jq -R -c '
    (try fromjson catch empty)
    | (.message.content // [])[]?
    | select(.type == "tool_use")
' "$TRANSCRIPT_PATH" 2>/dev/null | wc -l | tr -d ' ')

if [ "${ANY_TOOLUSE_COUNT:-0}" -eq 0 ]; then
    emit_empty
fi

# Rows 6-8: scan SendMessage (any recipient) and this task's claiming TaskUpdate, in transcript order
EVENTS=$(jq -R -c '
    (try fromjson catch empty)
    | (.message.content // [])[]?
    | select(.type == "tool_use")
    | select(.name == "SendMessage" or .name == "TaskUpdate")
    | {name, taskId: (.input.taskId // null), status: (.input.status // null)}
' "$TRANSCRIPT_PATH" 2>/dev/null)

LAST_CLAIM_IDX=-1
LAST_SEND_IDX=-1
ANY_SEND=0
IDX=0

while IFS= read -r EVENT; do
    [ -z "$EVENT" ] && continue
    EVENT_NAME=$(printf '%s' "$EVENT" | jq -r '.name' 2>/dev/null)
    if [ "$EVENT_NAME" = "TaskUpdate" ]; then
        EVENT_TASK_ID=$(printf '%s' "$EVENT" | jq -r '.taskId // empty' 2>/dev/null)
        EVENT_STATUS=$(printf '%s' "$EVENT" | jq -r '.status // empty' 2>/dev/null)
        if [ "$EVENT_TASK_ID" = "$TASK_ID" ] && [ "$EVENT_STATUS" = "in_progress" ]; then
            LAST_CLAIM_IDX=$IDX
        fi
    elif [ "$EVENT_NAME" = "SendMessage" ]; then
        ANY_SEND=1
        LAST_SEND_IDX=$IDX
    fi
    IDX=$((IDX + 1))
done <<< "$EVENTS"

# Row 6: an outbound SendMessage (any recipient) after this task's claim
if [ "$LAST_CLAIM_IDX" -ge 0 ] && [ "$LAST_SEND_IDX" -gt "$LAST_CLAIM_IDX" ]; then
    emit_empty
fi

# Row 7: no local claim record for this task, but some SendMessage exists anywhere
if [ "$LAST_CLAIM_IDX" -lt 0 ] && [ "$ANY_SEND" -eq 1 ]; then
    emit_empty
fi

# Row 8: no report evidence found
emit_block
