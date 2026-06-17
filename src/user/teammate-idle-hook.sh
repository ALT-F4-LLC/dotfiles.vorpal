#!/bin/bash

set -uo pipefail

emit_empty() {
    printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_empty

if ! command -v jq >/dev/null 2>&1; then
    emit_empty
fi

AGENT_TYPE=$(printf '%s' "$DATA" | jq -r '.agent_type // empty' 2>/dev/null) || emit_empty

REMINDER="Teammate idle: shutdown is lead-initiated — do NOT self-emit shutdown_request or any other structured shutdown/plan protocol message. Ephemeral teammates: first confirm your completion report/verdict was delivered to team-lead via SendMessage and your Docket issue is closed/commented; THEN idle and AWAIT team-lead's shutdown_request, replying shutdown_response (approve) when it arrives. Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."

if [ -n "$AGENT_TYPE" ]; then
    REMINDER="Teammate '${AGENT_TYPE}' idle: shutdown is lead-initiated — do NOT self-emit shutdown_request or any other structured shutdown/plan protocol message. Ephemeral teammates: first confirm your completion report/verdict was delivered to team-lead via SendMessage and your Docket issue is closed/commented; THEN idle and AWAIT team-lead's shutdown_request, replying shutdown_response (approve) when it arrives. Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."
fi

jq -n --arg msg "$REMINDER" '{systemMessage: $msg}' 2>/dev/null || emit_empty

exit 0
