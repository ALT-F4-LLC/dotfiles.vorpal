#!/bin/bash

set -uo pipefail

# TaskCompleted premature-completion block (DKT-227). Fires when a teammate
# marks a task completed; BLOCKS if the resolved teammate transcript shows no
# report SendMessage after the task claim. BOUNDARY vs subagent-report-hook.sh
# (SubagentStop): that sibling only NUDGES at turn-end on an unsent
# report-EMISSION line -- this hook is the hard block at task-marking time.

BLOCK_REASON='PREMATURE-COMPLETION-BLOCKED: no completion report to team-lead found in your transcript for this task. Send your completion report via SendMessage to team-lead (mirror durable evidence to Docket where your role doctrine requires it) BEFORE marking this task completed, then retry TaskUpdate. If this task genuinely carries no report obligation, send team-lead a one-line status note instead.'

# --- Row-attribution debug channel (DKT-227 Phase 1d) ------------------------
# Iff ${HOME}/.claude/task-completed-hook.debug exists, every exit path
# appends one attributed line to ${HOME}/.claude/task-completed-hook.log via
# this single shared wrapper -- attribution by construction at every exit
# site rather than per-site logging edits. Zero writes of any kind when the
# toggle is absent. All fields are defaulted and the append is best-effort so
# neither `set -u` nor a write failure can ever affect the decision or exit
# code.
DEBUG_TOGGLE="${HOME:-}/.claude/task-completed-hook.debug"
DEBUG_LOG="${HOME:-}/.claude/task-completed-hook.log"
TASK_ID=""
TEAMMATE_NAME=""
RESOLVED_PATH=""
RESOLUTION_KEY=""

emit_debug() {
    [ -e "$DEBUG_TOGGLE" ] || return 0
    local row="${1:--}" decision="${2:--}" key="${3:--}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    { printf 'ts=%s row=%s task=%s teammate=%s resolved=%s key=%s decision=%s\n' \
        "$ts" "$row" "${TASK_ID:--}" "${TEAMMATE_NAME:--}" "${RESOLVED_PATH:--}" "$key" "$decision" \
        >> "$DEBUG_LOG"; } 2>/dev/null || true
}

emit_empty() {
    emit_debug "${1:-}" "allow" "${2:-}"
    printf '{}\n'
    exit 0
}

emit_block() {
    emit_debug "${1:-}" "block" "${2:-}"
    jq -n --arg reason "$BLOCK_REASON" '{decision: "block", reason: $reason}' 2>/dev/null || printf '{}\n'
    exit 0
}

# GNU-first: on GNU coreutils, `stat -f` is --file-system (no format arg) and
# colliding with a literal '%m' argument prints filesystem-info noise to
# stdout before falling through, corrupting the mtime value. Trying `-c`
# first means GNU resolves cleanly without ever reaching `-f`; on BSD/macOS
# `-c` fails fast (unsupported flag, no stdout) so the `-f` fallback still
# runs clean there. The numeric guard rejects whatever garbage either branch
# might still produce, independent of which branch produced it.
file_mtime() {
    local f="$1" mtime
    mtime=$(stat -c '%Y' "$f" 2>/dev/null || stat -f '%m' "$f" 2>/dev/null)
    case "$mtime" in
        ''|*[!0-9]*) return 1 ;;
    esac
    printf '%s\n' "$mtime"
}

DATA=$(cat 2>/dev/null) || emit_empty 1

if ! command -v jq >/dev/null 2>&1; then
    emit_empty 1
fi

# Row 1: payload unparsable
TASK_ID=$(printf '%s' "$DATA" | jq -r '.task_id // empty' 2>/dev/null) || emit_empty 1
TEAMMATE_NAME=$(printf '%s' "$DATA" | jq -r '.teammate_name // empty' 2>/dev/null) || emit_empty 1
TRANSCRIPT_PATH=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null) || emit_empty 1

# Row 2: no teammate (solo session or main agent)
if [ -z "$TEAMMATE_NAME" ]; then
    emit_empty 2
fi

# Row 3: team-lead's own bookkeeping tasks (this repo's topology; not correctness-bearing)
if [ "$TEAMMATE_NAME" = "team-lead" ]; then
    emit_empty 3
fi

# Row 4: transcript_path empty or absent
if [ -z "$TRANSCRIPT_PATH" ]; then
    emit_empty 4
fi

# --- Teammate-transcript resolution (DKT-227 Phase 1d, TDD Revision 3) -------
# The harness derives transcript_path from the AMBIENT session id at hook-fire
# time, which for a teammate's own TaskUpdate call resolves to the PARENT
# (team-lead's) main session transcript, not the teammate's own subagent
# transcript (DKT-206 comments 312/323, live-reproduced). Resolve the actual
# completing teammate's transcript before evaluating any evidence rows below.
#
# Dual-key resolution, FILENAME-first with a meta-fallback. DKT-227 Phase 1c
# smoke proved meta-only resolution fails open via row 5 whenever a
# teammate's .meta.json sidecar has not yet been born at completion-attempt
# time -- .jsonl files exist from spawn for every instance of a name, so the
# filename key always has live evidence available and its within-set
# newest-mtime tiebreak genuinely selects the live instance even across a
# same-name respawn. The meta-fallback only fires when the filename key finds
# zero candidates (filename-scheme drift). Each key is a separate loop with
# its own reset accumulators; the two candidate sets are never merged, and
# there is exactly one shared row-5 check after whichever key ran. The parent
# transcript is NEVER used as an evidence fallback -- every resolution
# failure below fails OPEN (allow), matching the rest of this script's
# fail-open posture.
case "$TRANSCRIPT_PATH" in
    */subagents/agent-*.jsonl)
        # Already shaped as a teammate's own subagent transcript -- pass through.
        RESOLVED_PATH="$TRANSCRIPT_PATH"
        RESOLUTION_KEY="passthrough"
        ;;
    *)
        SESSION_DIR="${TRANSCRIPT_PATH%.jsonl}"
        CANDIDATES_DIR="${SESSION_DIR}/subagents"

        # Row 5: resolution failure -- subagents/ absent or unreadable
        if [ ! -d "$CANDIDATES_DIR" ] || [ ! -r "$CANDIDATES_DIR" ]; then
            emit_empty 5
        fi

        # --- Filename key (primary). For each agent-a*.jsonl, derive the
        # embedded name via fixed-pattern parameter expansion ONLY (strip the
        # .jsonl suffix, strip the agent-a prefix, strip the trailing
        # -{16char} segment), skipping any file whose layout doesn't match.
        # teammate_name is never interpolated into a glob, regex, or
        # constructed path -- only compared as a plain string, so untrusted
        # payload content cannot traverse or widen the scan.
        FN_MATCH_COUNT=0
        FN_NEWEST_MTIME=-1
        FN_NEWEST_JSONL=""
        FN_TIE=0

        for CAND_JSONL in "$CANDIDATES_DIR"/agent-a*.jsonl; do
            [ -e "$CAND_JSONL" ] || continue
            [ -f "$CAND_JSONL" ] && [ -r "$CAND_JSONL" ] || continue

            BASE="${CAND_JSONL##*/}"

            NAME_NOEXT="${BASE%.jsonl}"
            [ "$NAME_NOEXT" != "$BASE" ] || continue

            NAME_NOPREFIX="${NAME_NOEXT#agent-a}"
            [ "$NAME_NOPREFIX" != "$NAME_NOEXT" ] || continue

            DERIVED_NAME="${NAME_NOPREFIX%-????????????????}"
            [ "$DERIVED_NAME" != "$NAME_NOPREFIX" ] || continue

            [ "$DERIVED_NAME" = "$TEAMMATE_NAME" ] || continue

            FN_MATCH_COUNT=$((FN_MATCH_COUNT + 1))

            CAND_MTIME=$(file_mtime "$CAND_JSONL") || continue

            if [ "$CAND_MTIME" -gt "$FN_NEWEST_MTIME" ]; then
                FN_NEWEST_MTIME=$CAND_MTIME
                FN_NEWEST_JSONL=$CAND_JSONL
                FN_TIE=0
            elif [ "$CAND_MTIME" -eq "$FN_NEWEST_MTIME" ]; then
                FN_TIE=1
            fi
        done

        # --- Meta key (fallback, DKT-223 scan). Only runs when the filename
        # key found zero candidates (filename-scheme drift). Scans every
        # agent-*.meta.json for an EXACT (plain string) match on
        # teammate_name against its "name" field.
        MT_MATCH_COUNT=0
        MT_NEWEST_MTIME=-1
        MT_NEWEST_JSONL=""
        MT_TIE=0

        if [ "$FN_MATCH_COUNT" -eq 0 ]; then
            for META in "$CANDIDATES_DIR"/agent-*.meta.json; do
                [ -e "$META" ] || continue
                [ -f "$META" ] && [ -r "$META" ] || continue

                CAND_NAME=$(jq -r '.name // empty' "$META" 2>/dev/null) || continue
                [ "$CAND_NAME" = "$TEAMMATE_NAME" ] || continue

                CAND_JSONL="${META%.meta.json}.jsonl"
                [ -f "$CAND_JSONL" ] || continue

                MT_MATCH_COUNT=$((MT_MATCH_COUNT + 1))

                CAND_MTIME=$(file_mtime "$CAND_JSONL") || continue

                if [ "$CAND_MTIME" -gt "$MT_NEWEST_MTIME" ]; then
                    MT_NEWEST_MTIME=$CAND_MTIME
                    MT_NEWEST_JSONL=$CAND_JSONL
                    MT_TIE=0
                elif [ "$CAND_MTIME" -eq "$MT_NEWEST_MTIME" ]; then
                    MT_TIE=1
                fi
            done
        fi

        # Select the operative key: filename wins whenever it has any
        # candidates; meta is consulted only as a fallback. The two
        # candidate sets are never merged.
        if [ "$FN_MATCH_COUNT" -gt 0 ]; then
            OP_MATCH_COUNT=$FN_MATCH_COUNT
            OP_TIE=$FN_TIE
            OP_NEWEST_JSONL=$FN_NEWEST_JSONL
            RESOLUTION_KEY="filename"
        elif [ "$MT_MATCH_COUNT" -gt 0 ]; then
            OP_MATCH_COUNT=$MT_MATCH_COUNT
            OP_TIE=$MT_TIE
            OP_NEWEST_JSONL=$MT_NEWEST_JSONL
            RESOLUTION_KEY="meta"
        else
            OP_MATCH_COUNT=0
            OP_TIE=0
            OP_NEWEST_JSONL=""
            RESOLUTION_KEY="-"
        fi

        # Row 5: zero exact-name matches in the operative key, or no strict
        # newest-mtime winner within it
        if [ "$OP_MATCH_COUNT" -eq 0 ] || [ "$OP_TIE" -eq 1 ] || [ -z "$OP_NEWEST_JSONL" ]; then
            emit_empty 5 "$RESOLUTION_KEY"
        fi

        RESOLVED_PATH="$OP_NEWEST_JSONL"
        ;;
esac

# Row 6: resolved teammate transcript unreadable
if [ ! -r "$RESOLVED_PATH" ]; then
    emit_empty 6 "$RESOLUTION_KEY"
fi

# Row 7: shape-drift canary -- zero recognizable tool_use records of any name
count_tooluse() {
    jq -R -c '
        (try fromjson catch empty)
        | (.message.content // [])[]?
        | select(.type == "tool_use")
    ' "$RESOLVED_PATH" 2>/dev/null | wc -l | tr -d ' '
}

ANY_TOOLUSE_COUNT=$(count_tooluse)

if [ "${ANY_TOOLUSE_COUNT:-0}" -eq 0 ]; then
    # Bounded re-read: a completion-attempt line racing the sidecar's own
    # flush can transiently show zero tool_use records. Strictly on this
    # zero-tool_use path only -- steady-state completions with tool activity
    # never pay this cost.
    sleep 0.2 2>/dev/null || true
    ANY_TOOLUSE_COUNT=$(count_tooluse)

    if [ "${ANY_TOOLUSE_COUNT:-0}" -eq 0 ]; then
        # Still zero after the re-read: allow only when the transcript also
        # has zero assistant-envelope records (array .message.content) --
        # whole-envelope drift, or the transcript hasn't started yet. A
        # parseable, quiet transcript WITH assistant-envelope records but no
        # sends is the violation class, not drift, so it falls through to
        # rows 8-10 instead of allowing here.
        ANY_ARRAY_CONTENT_COUNT=$(jq -R -c '
            (try fromjson catch empty)
            | select(type == "object")
            | select((.message.content? // null) | type == "array")
        ' "$RESOLVED_PATH" 2>/dev/null | wc -l | tr -d ' ')

        if [ "${ANY_ARRAY_CONTENT_COUNT:-0}" -eq 0 ]; then
            emit_empty 7 "$RESOLUTION_KEY"
        fi
    fi
fi

# Rows 8-9: scan SendMessage (any recipient) and this task's claiming TaskUpdate,
# in transcript order, within the RESOLVED teammate transcript.
EVENTS=$(jq -R -c '
    (try fromjson catch empty)
    | (.message.content // [])[]?
    | select(.type == "tool_use")
    | select(.name == "SendMessage" or .name == "TaskUpdate")
    | {name, taskId: (.input.taskId // null), status: (.input.status // null)}
' "$RESOLVED_PATH" 2>/dev/null)

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

# Row 8: an outbound SendMessage (any recipient) after this task's claim
if [ "$LAST_CLAIM_IDX" -ge 0 ] && [ "$LAST_SEND_IDX" -gt "$LAST_CLAIM_IDX" ]; then
    emit_empty 8 "$RESOLUTION_KEY"
fi

# Row 9: no local claim record for this task, but some SendMessage exists anywhere
if [ "$LAST_CLAIM_IDX" -lt 0 ] && [ "$ANY_SEND" -eq 1 ]; then
    emit_empty 9 "$RESOLUTION_KEY"
fi

# Row 10: no report evidence found
emit_block 10 "$RESOLUTION_KEY"
