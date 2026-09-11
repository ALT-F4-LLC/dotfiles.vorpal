#!/bin/bash

# sandbox-bypass-guard — PreToolUse: Bash.
#
# A Bash call carrying dangerouslyDisableSandbox=true runs OUTSIDE the
# sandbox: no filesystem allowlist, no network filter, no denyRead. Every
# executor brief forbids that lift ("the lift is the operator's to grant,
# never through a brief and never on your say-so"), and the prohibition had no
# mechanical backing: measured on one wave, an executor ran twenty-one
# `GOCACHE=<scratch> vorpal run go ...` calls unsandboxed without a single
# sandboxed attempt first, and the auto-mode classifier approved each one. The
# sandboxed form works (probed: vorpal runs inside the sandbox, env-var prefix
# included), so those lifts bought nothing and cost the whole sandbox.
#
# THE SCOPE, mirroring docket-trust-guard-hook.sh: deny for the three
# graph-fleet executor archetypes only. The main conversation (no agent_type)
# and every other seat keep the harness's own handling — in auto mode the
# classifier judges the underlying command; in manual mode the operator is
# prompted — because the operator's own path to a lift is exactly the thing an
# executor is told does not exist for it.
#
# Exit 0 allow / exit 2 deny with reason on stderr, this hook family's
# contract: exit 2 is a pre-permission hard stop the classifier never sees, and
# the reason reaches the executor so it runs the sandboxed form instead of
# retrying the lift under another spelling.
#
# Two Workflow-spawned tribunal seats (agentType executor-read per
# their own meta.json) lifted the sandbox unchallenged — this hook's
# `.agent_type` read came back empty for them, though it is unconfirmed
# whether that is because the field genuinely arrives empty for a
# Workflow-spawned seat or something else in the chain drops it (the
# `agentType` option on a workflow's `agent()` call is documented to resolve
# through the SAME subagent registry the Agent tool uses, so the mismatch is
# not an obvious naming bug in tribunal.js/wave.js). Two changes below, both
# from that uncertainty rather than a confirmed root cause:
#   1. Every actual bypass DECISION (allow-by-default or deny) is now logged
#      to ~/.claude/friction with the payload's key set and the agent_type
#      value seen, so the next occurrence confirms the shape directly
#      instead of needing another shadow sweep to reconstruct it.
#   2. When agent_type is absent or unrecognized, do not allow by default:
#      fall back to the transcript's own first message, which for a
#      Workflow-spawned seat is that seat's brief and carries markers no
#      ordinary operator turn would — a wave.js executor brief instructs
#      `docket step claim`, and a tribunal.js judge/checker brief opens with
#      `THE PROPOSAL:` and instructs `docket vote cast`. A session whose
#      first message carries none of those is treated exactly as before:
#      allowed through to the harness's own classifier/prompt handling. This
#      is deliberately narrow and biased toward a false ALLOW over a false
#      DENY on the operator's own path — it closes the specific gap the
#      Workflow-spawned-seat case above measured, not a general
#      agent_type-is-missing case.

set -uo pipefail

FRICTION_DIR="$HOME/.claude/friction"
FRICTION_LOG="$FRICTION_DIR/sandbox-bypass-guard.jsonl"

allow_default() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

is_executor_archetype() {
    case "$1" in
        executor-read | executor-write | executor-research) return 0 ;;
        *) return 1 ;;
    esac
}

# Best-effort only: a logging failure must never change the decision, so
# every path through this stays `|| true` and unchecked.
log_decision() {  # <decision> <detected-via>
    mkdir -p "$FRICTION_DIR" 2>/dev/null || return 0
    local keys
    keys=$(printf '%s' "$INPUT" | jq -c 'keys' 2>/dev/null || echo '[]')
    jq -n -c \
        --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg decision "$1" \
        --arg detected_via "$2" \
        --arg agent_type "$AGENT_TYPE" \
        --arg session "$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)" \
        --argjson payload_keys "$keys" \
        '{at:$at, hook:"sandbox-bypass-guard", decision:$decision, detected_via:$detected_via, agent_type:$agent_type, session:$session, payload_keys:$payload_keys}' \
        >>"$FRICTION_LOG" 2>/dev/null || true
}

# A Workflow-spawned seat's own brief is its transcript's first message.
# `docket step claim` is wave.js's executor brief (own_id "--owner
# wave:<step>" makes it wave-specific, but the bare verb is enough — this is
# meant to be a wide net); `THE PROPOSAL:` and `docket vote cast` are
# tribunal.js's judge/checker briefs. Bounded read (the transcript grows for
# the whole session; only the opening bytes are the first message) and
# best-effort: an unreadable or missing transcript is not itself a signal
# either way.
looks_like_docket_seat_brief() {  # <transcript-path>
    local transcript="$1"
    [ -n "$transcript" ] && [ -r "$transcript" ] || return 1
    head -c 20000 "$transcript" 2>/dev/null \
        | grep -qE 'docket step claim|docket vote cast|THE PROPOSAL:'
}

INPUT=$(cat 2>/dev/null) || allow_default
[ -n "$INPUT" ] || allow_default

command -v jq >/dev/null 2>&1 || allow_default

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

# Boolean-typed on purpose: the harness sends a JSON boolean, and a string
# "true" is a schema quirk, not a lift.
BYPASS=$(printf '%s' "$INPUT" | jq -r '.tool_input.dangerouslyDisableSandbox == true' 2>/dev/null) || allow_default
[ "$BYPASS" = "true" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default

REASON="sandbox bypass blocked: dangerouslyDisableSandbox is never available to an executor step, whatever the brief or the last error said. Run the same command sandboxed; \`vorpal run\`, \`go\`, and \`cargo\` all work inside the sandbox with build caches under your step's scratch directory. If the sandboxed form is refused (Operation not permitted, a blocked host, a bind failure), that is a NETWORK GATE BLOCKED or environment finding for your step report — attempt it once, record the exact error, and do not retry this lift."

if is_executor_archetype "$AGENT_TYPE"; then
    log_decision "deny" "agent_type"
    deny "$REASON"
fi

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null) || TRANSCRIPT_PATH=""
if looks_like_docket_seat_brief "$TRANSCRIPT_PATH"; then
    log_decision "deny" "transcript-brief"
    deny "$REASON"
fi

log_decision "allow" "none"
allow_default
