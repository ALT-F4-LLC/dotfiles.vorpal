#!/bin/bash

# Block one Stop that would end a docket-groom turn on a hand-back.
#
# A groom pass persists its ledger to the session scratchpad as
# docket-groom-<project>-<pass id>.json and sets "reported": true in it just
# before the final report. This hook acts only when the session has such a
# ledger still unreported AND the last assistant text hits report-lint.sh
# (the "still open" / "your call" / "not re-judged" family). The deny asks
# the model to do the item, ask it, or name the gate state; the next Stop is
# allowed (stop_hook_active), so a lint hit on a legitimate wait cannot
# trap the session. Missing jq, an unreadable transcript, no ledger, or no
# lint script all allow.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || allow
DATA=$(cat 2>/dev/null) || allow

[ "$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && allow
SESSION=$(printf '%s' "$DATA" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$SESSION" ] && [ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || allow
case "$SESSION" in *[!A-Za-z0-9-]*) allow ;; esac

LINT="${GROOM_REPORT_LINT:-$HOME/.claude/skills/docket-groom/scripts/report-lint.sh}"
[ -x "$LINT" ] || allow

# An unreported ledger for this session marks a pass in progress. The glob
# is unquoted on purpose; GROOM_LEDGER_GLOB (with @SESSION@) lets tests point it at a fixture.
LEDGER_GLOB="${GROOM_LEDGER_GLOB:-/private/tmp/claude-*/*/@SESSION@/scratchpad/docket-groom-*.json /tmp/claude-*/*/@SESSION@/scratchpad/docket-groom-*.json}"
LEDGER_GLOB=${LEDGER_GLOB//@SESSION@/$SESSION}
ACTIVE=""
for f in $LEDGER_GLOB; do
    [ -f "$f" ] || continue
    if jq -e '.reported != true' "$f" >/dev/null 2>&1; then ACTIVE=1; break; fi
done
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
