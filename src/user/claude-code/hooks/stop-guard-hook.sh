#!/bin/bash

set -uo pipefail

# Stop-event guard (DKT-328). Blocks session end while live teammates or
# outstanding Docket work (todo/in-progress) remain, so a team-lead can't
# stop mid-cycle and strand ephemerals or unclosed issues.
#
# KNOWN LIMITATION -- LIVE-PROBE before trusting in prod (design is INFERRED
# from Claude Code hook docs per DKT-328, not yet verified against live hook
# behavior): the team config.json member list is an append-only join log --
# entries are never removed when a teammate shuts down, so "member count > 0
# excluding team-lead" only proves a teammate joined THIS session at some
# point, not that one is still running. This will over-block (false
# "outstanding work") once any teammate has ever joined the session, even
# after every teammate has cleanly shut down. No process-liveness signal is
# available in ~/.claude/teams/*/ to distinguish the two cases. Acceptable as
# a v1 per DKT-328's own scope (smoke-test + document, not solve); a future
# evolve-config/evolve-agents cycle should revisit once a liveness signal
# exists (e.g. a shutdown marker written by team-lead's own shutdown sweep).
#
# Fail-open throughout, matching this hook family's convention: any
# parse/resolution failure (missing jq, missing docket, no team config,
# unresolvable repo root) falls through to "no outstanding work" for that
# dimension rather than blocking on an unrelated infrastructure failure.

DEBUG_TOGGLE="${HOME:-}/.claude/stop-guard-hook.debug"
DEBUG_LOG="${HOME:-}/.claude/stop-guard-hook.log"

emit_debug() {
    [ -e "$DEBUG_TOGGLE" ] || return 0
    local decision="${1:--}" detail="${2:-}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    { printf 'ts=%s decision=%s %s\n' "$ts" "$decision" "$detail" >> "$DEBUG_LOG"; } 2>/dev/null || true
}

emit_allow() {
    emit_debug "allow" "${1:-}"
    printf '{}\n'
    exit 0
}

emit_block() {
    emit_debug "block" "${2:-}"
    jq -n --arg reason "$1" '{decision: "block", reason: $reason}' 2>/dev/null || printf '{}\n'
    exit 0
}

DATA=$(cat 2>/dev/null) || emit_allow "no-stdin"

if ! command -v jq >/dev/null 2>&1; then
    emit_allow "no-jq"
fi

# Row 1: stop_hook_active guards against infinite block loops -- when true,
# Claude Code is already continuing as a result of a prior Stop-hook block
# for this same stop attempt, so never re-block.
STOP_HOOK_ACTIVE=$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null) || emit_allow "unparsable-payload"
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    emit_allow "stop-hook-active"
fi

SESSION_ID=$(printf '%s' "$DATA" | jq -r '.session_id // empty' 2>/dev/null) || SESSION_ID=""
CWD=$(printf '%s' "$DATA" | jq -r '.cwd // empty' 2>/dev/null) || CWD=""

# --- Live-teammate check --------------------------------------------------
# Team directories are named session-<first 8 chars of leadSessionId>
# (verified against live ~/.claude/teams/session-*/config.json instances).
TEAM_MEMBER_COUNT=0
TEAM_MEMBER_NAMES=""
if [ -n "$SESSION_ID" ]; then
    SESSION_PREFIX="${SESSION_ID:0:8}"
    TEAM_CONFIG="${HOME:-}/.claude/teams/session-${SESSION_PREFIX}/config.json"
    if [ -f "$TEAM_CONFIG" ] && [ -r "$TEAM_CONFIG" ]; then
        TEAM_MEMBER_COUNT=$(jq -r '[.members[]? | select(.agentType != "team-lead")] | length' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_COUNT=0
        TEAM_MEMBER_NAMES=$(jq -r '[.members[]? | select(.agentType != "team-lead") | .name] | join(", ")' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_NAMES=""
    fi
fi
[ -n "$TEAM_MEMBER_COUNT" ] || TEAM_MEMBER_COUNT=0

# --- Outstanding Docket work check ----------------------------------------
DOCKET_OUTSTANDING_COUNT=0
DOCKET_OUTSTANDING_IDS=""
if command -v docket >/dev/null 2>&1 && [ -n "$CWD" ] && [ -d "$CWD" ]; then
    REPO_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=""
    if [ -n "$REPO_ROOT" ]; then
        PLAN_JSON=$(cd "$REPO_ROOT" 2>/dev/null && docket plan --json 2>/dev/null) || PLAN_JSON=""
        if [ -n "$PLAN_JSON" ]; then
            DOCKET_OUTSTANDING_COUNT=$(printf '%s' "$PLAN_JSON" | jq -r '[.data.phases[]?.issues[]? | select(.status == "todo" or .status == "in-progress")] | length' 2>/dev/null) || DOCKET_OUTSTANDING_COUNT=0
            DOCKET_OUTSTANDING_IDS=$(printf '%s' "$PLAN_JSON" | jq -r '[.data.phases[]?.issues[]? | select(.status == "todo" or .status == "in-progress") | .id] | join(", ")' 2>/dev/null) || DOCKET_OUTSTANDING_IDS=""
        fi
    fi
fi
[ -n "$DOCKET_OUTSTANDING_COUNT" ] || DOCKET_OUTSTANDING_COUNT=0

if [ "$TEAM_MEMBER_COUNT" -gt 0 ] || [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ]; then
    REASON="Session stop blocked:"
    if [ "$TEAM_MEMBER_COUNT" -gt 0 ]; then
        REASON="${REASON} ${TEAM_MEMBER_COUNT} teammate(s) recorded in this session (${TEAM_MEMBER_NAMES});"
    fi
    if [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ]; then
        REASON="${REASON} ${DOCKET_OUTSTANDING_COUNT} outstanding Docket issue(s) (${DOCKET_OUTSTANDING_IDS});"
    fi
    REASON="${REASON} resolve or shut down teammates and close/defer issues before stopping."
    emit_block "$REASON" "teammates=${TEAM_MEMBER_COUNT} docket=${DOCKET_OUTSTANDING_COUNT}"
fi

emit_allow "clear"
