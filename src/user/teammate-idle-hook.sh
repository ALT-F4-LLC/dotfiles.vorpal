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

REMINDER="Teammate idle: before idling, ephemeral teammates must emit shutdown_request to team-lead as the final tool call (after the Docket issue is closed and the completion report is sent). Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."

if [ -n "$AGENT_TYPE" ]; then
    REMINDER="Teammate '${AGENT_TYPE}' idle: before idling, ephemeral teammates must emit shutdown_request to team-lead as the final tool call (after the Docket issue is closed and the completion report is sent). Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."
fi

jq -n --arg msg "$REMINDER" '{systemMessage: $msg}' 2>/dev/null || emit_empty

exit 0
