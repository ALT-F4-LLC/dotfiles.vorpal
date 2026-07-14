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

AGENT_ID=$(printf '%s' "$DATA" | jq -r '.agent_id // empty' 2>/dev/null) || emit_empty
AGENT_TYPE=$(printf '%s' "$DATA" | jq -r '.agent_type // empty' 2>/dev/null) || emit_empty
TRANSCRIPT_PATH=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null) || emit_empty

# Resolve the actual idling teammate's name (DKT-262). At TeammateIdle-fire
# time, agent_type reflects the AMBIENT root session and is always
# "team-lead" regardless of which teammate idled -- the same class of
# harness behavior already documented for TaskCompleted in
# task-completed-hook.sh (DKT-206). agent_id is per-instance-unique (mirrors
# subagent-report-hook.sh's SubagentStop resolution -- LIVE-PROBE its
# availability for TeammateIdle specifically before fully trusting in prod,
# per that hook's own load-bearing-assumption precedent), so when present,
# resolve the teammate's own transcript filename via a direct substring
# match and derive its readable name via the same fixed-pattern parameter
# expansion task-completed-hook.sh uses -- this takes priority over
# agent_type since it identifies the real instance rather than the ambient
# session. Falls back to agent_type when agent_id is absent or unresolved.
NAME=""

if [ -n "$AGENT_ID" ] && [ -n "$TRANSCRIPT_PATH" ]; then
    case "$TRANSCRIPT_PATH" in
        */subagents/agent-*.jsonl)
            RESOLVED_JSONL="$TRANSCRIPT_PATH"
            ;;
        *)
            CANDIDATES_DIR="${TRANSCRIPT_PATH%.jsonl}/subagents"
            RESOLVED_JSONL=""
            if [ -d "$CANDIDATES_DIR" ] && [ -r "$CANDIDATES_DIR" ]; then
                for CAND in "$CANDIDATES_DIR"/agent-*.jsonl; do
                    [ -f "$CAND" ] && [ -r "$CAND" ] || continue
                    case "${CAND##*/}" in
                        *"$AGENT_ID"*) RESOLVED_JSONL="$CAND"; break ;;
                    esac
                done
            fi
            ;;
    esac

    if [ -n "$RESOLVED_JSONL" ]; then
        BASE="${RESOLVED_JSONL##*/}"
        NAME_NOEXT="${BASE%.jsonl}"
        NAME_NOPREFIX="${NAME_NOEXT#agent-a}"
        if [ "$NAME_NOPREFIX" != "$NAME_NOEXT" ]; then
            DERIVED_NAME="${NAME_NOPREFIX%-????????????????}"
            [ "$DERIVED_NAME" != "$NAME_NOPREFIX" ] && NAME="$DERIVED_NAME"
        fi
    fi
fi

# Fall back to agent_type (best-effort, may itself be ambient-wrong) only
# when resolution above found nothing; NAME is always a plain string here,
# never a literal unexpanded placeholder.
[ -n "$NAME" ] || NAME="$AGENT_TYPE"

SUFFIX="idle: shutdown is lead-initiated — do NOT self-emit shutdown_request or any other structured shutdown/plan protocol message. Ephemeral teammates: first confirm your completion report/verdict was delivered to team-lead via SendMessage and your Docket issue is closed/commented; THEN idle and AWAIT team-lead's shutdown_request, replying shutdown_response (approve) when it arrives. Persistent advisors idling between turns is expected and needs no shutdown_request. If you still have an open assigned task or unsent report, finish it instead of idling."

if [ -n "$NAME" ]; then
    REMINDER="Teammate '${NAME}' ${SUFFIX}"
else
    REMINDER="Teammate ${SUFFIX}"
fi

jq -n --arg msg "$REMINDER" '{systemMessage: $msg}' 2>/dev/null || emit_empty

exit 0
