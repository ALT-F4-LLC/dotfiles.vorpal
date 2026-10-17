#!/bin/bash

# Block a Stop that would end a docket-groom turn on a hand-back.
#
# A groom pass persists its ledger to the session scratchpad as
# docket-groom-<project>-<pass id>.json and sets "reported": true in it just
# before the final report. The hook acts only when the session has such a
# ledger and the pass is unfinished: unreported, or (goal mode) with items
# still open per scripts/ledger-open.sh, whatever "reported" says.
#
# Two modes. A ledger without "mode": "goal" is an attended pass: the hook
# blocks one Stop whose last assistant text hits report-lint.sh, and the next
# Stop is allowed (stop_hook_active), so a lint hit on a legitimate wait
# cannot trap the session. A ledger with "mode": "goal" is an unattended pass
# run under /goal: the hook blocks every Stop while ledger-open.sh reports
# open items, whatever the closing text says, and ignores stop_hook_active.
# Three things end that block: the open count reaching zero, a recorded wait
# ("waiting_on" non-empty, for a background job whose notice re-invokes the
# session), and a per-ledger block cap (GROOM_BLOCK_CAP, default 25 blocks
# since the open count last fell, kept in <ledger>.blocks) so an item no edit
# can resolve cannot lock the session. The hook never runs --final, so the
# verified check and the report are enforced by the /goal condition alone.
# Missing jq, an unreadable transcript, no ledger, or no lint script all allow.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || allow
DATA=$(cat 2>/dev/null) || allow

STOP_ACTIVE=$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null)
SESSION=$(printf '%s' "$DATA" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$SESSION" ] && [ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || allow
case "$SESSION" in *[!A-Za-z0-9-]*) allow ;; esac

LINT="${GROOM_REPORT_LINT:-$HOME/.claude/skills/docket-groom/scripts/report-lint.sh}"
OPEN="${GROOM_LEDGER_OPEN:-$HOME/.claude/skills/docket-groom/scripts/ledger-open.sh}"
CAP="${GROOM_BLOCK_CAP:-25}"

# The glob is unquoted on purpose; GROOM_LEDGER_GLOB (with @SESSION@) lets
# tests point it at a fixture.
LEDGER_GLOB="${GROOM_LEDGER_GLOB:-/private/tmp/claude-*/*/@SESSION@/scratchpad/docket-groom-*.json /tmp/claude-*/*/@SESSION@/scratchpad/docket-groom-*.json}"
LEDGER_GLOB=${LEDGER_GLOB//@SESSION@/$SESSION}

GOAL_LEDGER=""
ACTIVE=""
for f in $LEDGER_GLOB; do
    [ -f "$f" ] || continue
    if jq -e '.mode == "goal"' "$f" >/dev/null 2>&1; then
        if [ -x "$OPEN" ] && ! "$OPEN" "$f" >/dev/null 2>&1; then GOAL_LEDGER="$f"; break; fi
        continue
    fi
    if jq -e '.reported != true' "$f" >/dev/null 2>&1; then ACTIVE=1; fi
done

if [ -n "$GOAL_LEDGER" ]; then
    jq -e '(.waiting_on // "") != ""' "$GOAL_LEDGER" >/dev/null 2>&1 && allow
    # <ledger>.blocks holds "<blocks> <open count at the last block>"; the
    # block count resets whenever the open count falls, so progress earns
    # more stops. A write that fails allows the Stop: the cap could not fire.
    OUT=$("$OPEN" "$GOAL_LEDGER" 2>/dev/null)
    NOW=$(printf '%s\n' "$OUT" | sed -n 's/^open=//p' | head -1)
    case "$NOW" in ''|*[!0-9]*) NOW=0 ;; esac
    read -r BLOCKS LAST < "${GOAL_LEDGER}.blocks" 2>/dev/null || { BLOCKS=0; LAST=$NOW; }
    case "$BLOCKS" in ''|*[!0-9]*) BLOCKS=0 ;; esac
    case "$LAST" in ''|*[!0-9]*) LAST=$NOW ;; esac
    [ "$NOW" -lt "$LAST" ] && BLOCKS=0
    [ "$BLOCKS" -ge "$CAP" ] && allow
    printf '%s %s\n' $((BLOCKS + 1)) "$NOW" > "${GOAL_LEDGER}.blocks" 2>/dev/null || allow
    SUMMARY=$(printf '%s\n' "$OUT" | head -4 | tr '\n' ';')
    deny "Stop blocked by groom turn guard: this pass runs under /goal and its ledger is not finished (${SUMMARY}). The operator never types \"continue\" and is not asked: decide each item with the advisor, apply it, record its terminal state in the ledger, and run scripts/ledger-open.sh --final until it exits 0. For a background job, record it in \"waiting_on\" before ending the turn."
fi

[ "$STOP_ACTIVE" = "true" ] && allow
[ -x "$LINT" ] || allow
[ -n "$ACTIVE" ] || allow

# The last assistant entry that carries text, from the transcript tail.
TEXT=$(tail -n 60 "$TRANSCRIPT" 2>/dev/null | jq -rs '
    [ .[] | select(.type == "assistant")
      | (.message.content | if type == "array" then map(select(.type == "text").text) | join("\n") else (. // "") end)
      | select(length > 0) ] | last // empty' 2>/dev/null) || allow
[ -n "$TEXT" ] || allow

HITS=$(printf '%s\n' "$TEXT" | "$LINT" 2>/dev/null) && allow
[ -n "$HITS" ] || allow

deny "Stop blocked by groom turn guard: the closing text hands work back (${HITS//$'\n'/; }). The operator never types \"continue\": do the item, ask it through AskUserQuestion, or record it under a SKILL.md §5 gate state worded as that state, then end the turn. If this is a legitimate wait, say so in a state's wording; the next Stop attempt is allowed."
