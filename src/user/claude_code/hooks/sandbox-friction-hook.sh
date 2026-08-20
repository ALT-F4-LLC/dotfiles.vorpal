#!/bin/bash

# sandbox-friction — PostToolUse: Bash.
#
# The evidence half of the sandbox self-improving loop (operator ruling,
# 2026-08-20). The allowlist is EVIDENCE-ONLY, which is only honest if evidence
# reaches the operator faster than a weekly shadow sweep: the wrong Go module
# cache path cost ~1,650 sandbox lifts over sixteen days before anybody looked,
# and the only reason it surfaced at all was a post-mortem nobody had scheduled.
#
# This hook records, and records ONLY. It appends one line per friction event to
# a ledger; `sandbox-friction-report` turns that ledger into DOT issues. Nothing
# here files, prompts, blocks, or writes to the observed repo.
#
# THREE ABSOLUTES, because this runs after EVERY Bash call in every session:
#   1. It must never block. Every path exits 0. A hook that can deny is a hook
#      that can wedge an unattended executor, which is the failure this whole
#      configuration exists to avoid.
#   2. It must never print on the happy path. A PostToolUse hook that narrates
#      becomes noise on thousands of calls and gets ignored exactly when it
#      matters (measured 2026-08-17: a condensed-policy advisory scrolled past
#      unread through three panels and two waves).
#   3. It must be cheap. One grep against the output, an early exit, and no
#      work at all for the overwhelming majority of calls that are fine.

#
# It is registered on TWO events, because sandbox friction has two shapes and
# only one of them leaves a command output to read:
#   PostToolUse:Bash      — the command ran and hit the sandbox boundary, or ran
#                           with dangerouslyDisableSandbox. Evidence for the
#                           filesystem and network allowlists.
#   PermissionDenied:Bash — auto mode's classifier refused the call, so the
#                           command never ran and PostToolUse never fires. This
#                           is the ONLY record of the events that accumulate
#                           toward auto mode's pause threshold (3 consecutive or
#                           20 total, not configurable), at which point auto mode
#                           starts prompting and an unattended executor stalls.
#                           Evidence for `autoMode.allow` / `autoMode.environment`
#                           — which are unset today precisely because nothing was
#                           recording this and there was nothing to write them
#                           from (7-day census 2026-08-20: zero observed).

set -uo pipefail

LEDGER_DIR="$HOME/.claude/friction"
LEDGER="$LEDGER_DIR/sandbox.jsonl"

INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || true)

# Signatures of a sandbox boundary being hit. Kept deliberately narrow: a
# false positive here becomes a bogus issue somebody has to triage and close,
# which is how a self-improving loop stops being trusted.
DENIAL_RE='Operation not permitted|operation not permitted|unable to open database file|x509: OSStatus -26276|tls: failed to verify certificate'

KIND=""
EVIDENCE=""
BYPASSED=false

if [ "$EVENT" = "PermissionDenied" ]; then
    # Always recorded. A classifier denial is rare and always actionable, and
    # unlike a sandbox denial it has no output to match against.
    KIND="classifier-denial"
    EVIDENCE=$(printf '%s' "$INPUT" | jq -r '.reason // "" | .[0:300]' 2>/dev/null || true)
else
    # tool_response shape varies by tool; for Bash it carries stdout/stderr.
    # Take the whole blob as text rather than guessing field names by version.
    RESPONSE=$(printf '%s' "$INPUT" | jq -r '.tool_response // empty | if type == "string" then . else tojson end' 2>/dev/null || true)
    if [ "$(printf '%s' "$INPUT" | jq -r '.tool_input.dangerouslyDisableSandbox // false' 2>/dev/null || echo false)" = "true" ]; then
        BYPASSED=true
        KIND="unsandboxed-retry"
    fi
    if printf '%s' "$RESPONSE" | grep -qE "$DENIAL_RE"; then
        [ -n "$KIND" ] || KIND="sandbox-denial"
        # The denied path or host is the actionable part — it is what an
        # allowlist entry would name. Keep a bounded excerpt, not a build log.
        EVIDENCE=$(printf '%s' "$RESPONSE" | grep -oE ".{0,120}(${DENIAL_RE}).{0,60}" 2>/dev/null | head -3 | tr '\n' ' ' | cut -c1-600)
    fi
    [ -n "$KIND" ] || exit 0
fi

mkdir -p "$LEDGER_DIR" 2>/dev/null || exit 0

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // "" | .[0:400]' 2>/dev/null || true)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || true)
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)

jq -n -c \
    --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg kind "$KIND" \
    --arg session "$SESSION" \
    --arg cwd "$CWD" \
    --arg command "$COMMAND" \
    --arg evidence "$EVIDENCE" \
    --argjson bypassed "$BYPASSED" \
    '{at: $at, kind: $kind, session: $session, cwd: $cwd, command: $command, bypassed: $bypassed, evidence: $evidence}' \
    >>"$LEDGER" 2>/dev/null || true

exit 0
