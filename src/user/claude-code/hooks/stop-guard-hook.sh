#!/bin/bash

set -uo pipefail

# Stop-event guard (DKT-328). Blocks session end while live teammates or
# outstanding Docket work (todo/in-progress, minus issues labeled
# stop-defer) remain, so a team-lead can't stop mid-cycle and strand
# ephemerals or unclosed issues.
#
# LIVE-TEAMMATE CHECK: the team config.json member list was observed to
# self-prune on clean shutdown (in-process backend, clean shutdown_request
# handshake path -- a teammate's entry was fully removed from the roster
# before any teammate_terminated confirmation was even received; observed
# 2026-07-15). The residual gap is unverified crash/kill paths, where a
# teammate process dies without completing the handshake. Treat this check
# as generally accurate, not as a known-broken heuristic -- it is never
# rate-limited (see below) because it is the more reliable of the two
# signals.
#
# DOCKET-DIMENSION RATE LIMITING: to avoid re-blocking on every single
# turn-end when the outstanding-issue set hasn't changed since the last
# block this session, the docket dimension persists a per-session_id
# signature of the outstanding issue ID set under
# ~/.claude/stop-guard-hook-state/ and only re-blocks when that signature
# changes. This memory applies ONLY to the docket dimension.
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
# Issues labeled "stop-defer" are excluded regardless of status -- this is
# how an operator marks "I've explicitly reviewed and accepted leaving this
# open" so the hook stops re-blocking on it.
DOCKET_FILTER='select(.status == "todo" or .status == "in-progress") | select(((.labels // []) | index("stop-defer")) == null)'
DOCKET_OUTSTANDING_COUNT=0
DOCKET_OUTSTANDING_IDS=""
DOCKET_OUTSTANDING_SIGNATURE=""
if command -v docket >/dev/null 2>&1 && [ -n "$CWD" ] && [ -d "$CWD" ]; then
    REPO_ROOT=$(cd "$CWD" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=""
    if [ -n "$REPO_ROOT" ]; then
        PLAN_JSON=$(cd "$REPO_ROOT" 2>/dev/null && docket plan --json 2>/dev/null) || PLAN_JSON=""
        if [ -n "$PLAN_JSON" ]; then
            DOCKET_OUTSTANDING_COUNT=$(printf '%s' "$PLAN_JSON" | jq -r "[.data.phases[]?.issues[]? | ${DOCKET_FILTER}] | length" 2>/dev/null) || DOCKET_OUTSTANDING_COUNT=0
            DOCKET_OUTSTANDING_IDS=$(printf '%s' "$PLAN_JSON" | jq -r "[.data.phases[]?.issues[]? | ${DOCKET_FILTER} | .id] | join(\", \")" 2>/dev/null) || DOCKET_OUTSTANDING_IDS=""
            DOCKET_OUTSTANDING_SIGNATURE=$(printf '%s' "$PLAN_JSON" | jq -r "[.data.phases[]?.issues[]? | ${DOCKET_FILTER} | .id] | sort | join(\",\")" 2>/dev/null) || DOCKET_OUTSTANDING_SIGNATURE=""
        fi
    fi
fi
[ -n "$DOCKET_OUTSTANDING_COUNT" ] || DOCKET_OUTSTANDING_COUNT=0

# --- Docket-dimension rate limiting (once per state signature) ------------
# Never applied to the live-teammate dimension -- see comment header.
DOCKET_RATE_LIMITED=0
if [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ] && [ -n "$SESSION_ID" ]; then
    STATE_DIR="${HOME:-}/.claude/stop-guard-hook-state"
    SESSION_ID_SAFE=$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_-' '_')
    STATE_FILE="${STATE_DIR}/${SESSION_ID_SAFE}.docket-sig"
    PREV_SIGNATURE=""
    if [ -f "$STATE_FILE" ]; then
        PREV_SIGNATURE=$(cat "$STATE_FILE" 2>/dev/null) || PREV_SIGNATURE=""
    fi
    if [ "$PREV_SIGNATURE" = "$DOCKET_OUTSTANDING_SIGNATURE" ]; then
        DOCKET_RATE_LIMITED=1
    else
        mkdir -p "$STATE_DIR" 2>/dev/null && printf '%s' "$DOCKET_OUTSTANDING_SIGNATURE" > "$STATE_FILE" 2>/dev/null || true
    fi
fi

DOCKET_BLOCK=0
if [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ] && [ "$DOCKET_RATE_LIMITED" -eq 0 ]; then
    DOCKET_BLOCK=1
fi

if [ "$TEAM_MEMBER_COUNT" -gt 0 ] || [ "$DOCKET_BLOCK" -eq 1 ]; then
    REASON="Session stop blocked:"
    if [ "$TEAM_MEMBER_COUNT" -gt 0 ]; then
        REASON="${REASON} ${TEAM_MEMBER_COUNT} teammate(s) recorded in this session (${TEAM_MEMBER_NAMES});"
    fi
    if [ "$DOCKET_BLOCK" -eq 1 ]; then
        REASON="${REASON} ${DOCKET_OUTSTANDING_COUNT} outstanding Docket issue(s) (${DOCKET_OUTSTANDING_IDS});"
    fi
    REASON="${REASON} resolve or shut down teammates and close/defer issues before stopping."
    emit_block "$REASON" "teammates=${TEAM_MEMBER_COUNT} docket=${DOCKET_OUTSTANDING_COUNT} docket_rate_limited=${DOCKET_RATE_LIMITED}"
fi

emit_allow "clear"
