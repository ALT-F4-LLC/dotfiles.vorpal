#!/bin/bash

set -uo pipefail

# Stop-event guard (DKT-328, v2 DKT-362). Blocks session end while live
# teammates or outstanding Docket work (todo/in-progress, minus issues
# labeled stop-defer) remain, so a team-lead can't stop mid-cycle and
# strand ephemerals or unclosed issues.
#
# SESSION SCOPING (DKT-362, 2026-07-16 DKT-345 incident): the Docket
# dimension runs ONLY when this session has its own team config
# (~/.claude/teams/session-<8-char session_id prefix>/config.json). A
# no-team leaf session (e.g. /brief, ad-hoc Q&A) is never Docket-blocked,
# regardless of repo-wide outstanding issues -- that session never opted
# into orchestrating a cycle, so the charter above doesn't apply to it.
# An empty/missing session_id narrows the same way: TEAM_CONFIG stays ""
# and the Docket dimension is skipped entirely.
#
# LIVE-TEAMMATE CHECK: the team config.json member list was observed to
# self-prune on clean shutdown (in-process backend, clean shutdown_request
# handshake path -- a teammate's entry was fully removed from the roster
# before any teammate_terminated confirmation was even received; observed
# 2026-07-15). The residual gap is unverified crash/kill paths, where a
# teammate process dies without completing the handshake.
#
# TEAMMATE-DIMENSION RATE LIMITING (DKT-362): previously never rate-
# limited -- every Stop event with a live roster forced a response turn,
# the root cause of the 2026-07-16 DKT-345 per-turn forced-response storm
# (40+ minutes of near-identical forced turns). Now extends the Docket-
# signature state pattern below: block immediately on roster change
# (spawn/termination stays visible); otherwise suppress until
# STOP_GUARD_TEAMMATE_REBLOCK_SECONDS (default 600, invalid/non-numeric
# falls back to 600) have elapsed since the last block. No session_id =>
# block unconditionally (fail-toward-safety; structurally unreachable via
# the member-count resolution below, which is itself gated on session_id
# -- kept as a defensive branch, see its comment). Coverage for a
# teammate that dies without completing the shutdown handshake (so the
# roster signature never changes and the interval nudge is the only
# recourse) is explicitly delegated to teammate-idle-hook.sh -- registered
# on the harness-driven TeammateIdle event, independent of this Stop-event
# hook (confirmed via code-read, DKT-362) -- and deadman-watch Monitor
# doctrine.
#
# DOCKET-DIMENSION RATE LIMITING: to avoid re-blocking on every single
# turn-end when the outstanding-issue set hasn't changed since the last
# block this session, the docket dimension persists a per-session_id
# signature of the outstanding issue ID set under
# ~/.claude/stop-guard-hook-state/ and only re-blocks when that signature
# changes.
#
# STATE ARTIFACTS under ~/.claude/stop-guard-hook-state/ (SESSION_ID_SAFE
# prefix, sanitized via tr -c 'A-Za-z0-9_-' '_'), all pruned at >7 days on
# write. .docket-sig holds a single line, sorted outstanding issue IDs.
# .teammate-sig holds two lines: sorted non-lead member names, then the
# last-block epoch seconds. .gate-log holds the team-session gate
# decision, OVERWRITTEN -- never appended -- on every team-session Stop
# event, so it stays O(1) per session instead of growing unbounded.
# .gate-log exists so a team session's most recent block/allow
# determination is diagnosable post-hoc even when the debug toggle below
# was never armed (DKT-362 acceptance-panel concern #4: the worst-case
# regression here is a silent false-allow of a real team-lead session,
# which would otherwise be
# undiagnosable after the fact).
#
# Fail-open throughout, matching this hook family's convention: any
# parse/resolution failure (missing jq, missing docket, no team config,
# unresolvable repo root) falls through to "no outstanding work" for that
# dimension rather than blocking on an unrelated infrastructure failure.

DEBUG_TOGGLE="${HOME:-}/.claude/stop-guard-hook.debug"
DEBUG_LOG="${HOME:-}/.claude/stop-guard-hook.log"
STATE_DIR="${HOME:-}/.claude/stop-guard-hook-state"

IS_TEAM_SESSION=0
SESSION_ID_SAFE=""

prune_state_dir() {
    find "$STATE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
}

emit_debug() {
    [ -e "$DEBUG_TOGGLE" ] || return 0
    local decision="${1:--}" detail="${2:-}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    { printf 'ts=%s decision=%s %s\n' "$ts" "$decision" "$detail" >> "$DEBUG_LOG"; } 2>/dev/null || true
}

# Unconditional (bypasses DEBUG_TOGGLE) team-session gate log -- DKT-362
# panel concern #4. Overwrites SESSION_ID_SAFE.gate-log rather than
# appending, so this stays bounded (O(1) per session) instead of growing
# on every Stop event; see the STATE ARTIFACTS header paragraph.
log_team_session_gate() {
    [ "$IS_TEAM_SESSION" -eq 1 ] && [ -n "$SESSION_ID_SAFE" ] || return 0
    local outcome="${1:-}" ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || ts="-"
    mkdir -p "$STATE_DIR" 2>/dev/null || return 0
    prune_state_dir
    { printf 'ts=%s team_session=1 outcome=%s\n' "$ts" "$outcome" > "${STATE_DIR}/${SESSION_ID_SAFE}.gate-log"; } 2>/dev/null || true
}

emit_allow() {
    emit_debug "allow" "${1:-}"
    log_team_session_gate "allow"
    printf '{}\n'
    exit 0
}

emit_block() {
    emit_debug "block" "${2:-}"
    log_team_session_gate "block"
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

if [ -n "$SESSION_ID" ]; then
    SESSION_ID_SAFE=$(printf '%s' "$SESSION_ID" | tr -c 'A-Za-z0-9_-' '_')
fi

# --- Live-teammate check --------------------------------------------------
# Team directories are named session-<first 8 chars of leadSessionId>
# (verified against live ~/.claude/teams/session-*/config.json instances).
TEAM_CONFIG=""
TEAM_MEMBER_COUNT=0
TEAM_MEMBER_NAMES=""
TEAM_ROSTER_SIGNATURE=""
if [ -n "$SESSION_ID" ]; then
    SESSION_PREFIX="${SESSION_ID:0:8}"
    TEAM_CONFIG="${HOME:-}/.claude/teams/session-${SESSION_PREFIX}/config.json"
    if [ -f "$TEAM_CONFIG" ] && [ -r "$TEAM_CONFIG" ]; then
        TEAM_MEMBER_COUNT=$(jq -r '[.members[]? | select(.agentType != "team-lead")] | length' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_COUNT=0
        TEAM_MEMBER_NAMES=$(jq -r '[.members[]? | select(.agentType != "team-lead") | .name] | join(", ")' "$TEAM_CONFIG" 2>/dev/null) || TEAM_MEMBER_NAMES=""
        TEAM_ROSTER_SIGNATURE=$(jq -r '[.members[]? | select(.agentType != "team-lead") | .name] | sort | join(",")' "$TEAM_CONFIG" 2>/dev/null) || TEAM_ROSTER_SIGNATURE=""
    fi
fi
[ -n "$TEAM_MEMBER_COUNT" ] || TEAM_MEMBER_COUNT=0

IS_TEAM_SESSION=0
if [ -n "$TEAM_CONFIG" ] && [ -f "$TEAM_CONFIG" ] && [ -r "$TEAM_CONFIG" ]; then
    IS_TEAM_SESSION=1
fi

# --- Outstanding Docket work check (session-scoped: only for this
# session's own team config -- DKT-362 root cause #3) ----------------------
# Issues labeled "stop-defer" are excluded regardless of status -- this is
# how an operator marks "I've explicitly reviewed and accepted leaving this
# open" so the hook stops re-blocking on it.
DOCKET_FILTER='select(.status == "todo" or .status == "in-progress") | select(((.labels // []) | index("stop-defer")) == null)'
DOCKET_OUTSTANDING_COUNT=0
DOCKET_OUTSTANDING_IDS=""
DOCKET_OUTSTANDING_SIGNATURE=""
if [ "$IS_TEAM_SESSION" -eq 1 ] && command -v docket >/dev/null 2>&1 && [ -n "$CWD" ] && [ -d "$CWD" ]; then
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
DOCKET_RATE_LIMITED=0
if [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ] && [ -n "$SESSION_ID_SAFE" ]; then
    STATE_FILE="${STATE_DIR}/${SESSION_ID_SAFE}.docket-sig"
    PREV_SIGNATURE=""
    if [ -f "$STATE_FILE" ]; then
        PREV_SIGNATURE=$(cat "$STATE_FILE" 2>/dev/null) || PREV_SIGNATURE=""
    fi
    if [ "$PREV_SIGNATURE" = "$DOCKET_OUTSTANDING_SIGNATURE" ]; then
        DOCKET_RATE_LIMITED=1
    else
        mkdir -p "$STATE_DIR" 2>/dev/null && prune_state_dir && printf '%s' "$DOCKET_OUTSTANDING_SIGNATURE" > "$STATE_FILE" 2>/dev/null || true
    fi
fi

DOCKET_BLOCK=0
if [ "$DOCKET_OUTSTANDING_COUNT" -gt 0 ] && [ "$DOCKET_RATE_LIMITED" -eq 0 ]; then
    DOCKET_BLOCK=1
fi

# --- Teammate-dimension rate limiting (DKT-362) ---------------------------
# Extends the Docket-signature state pattern above to the teammate
# dimension. Block immediately on roster change (keeps spawn/termination
# visible); otherwise suppress until STOP_GUARD_TEAMMATE_REBLOCK_SECONDS
# have elapsed since the last block.
TEAMMATE_BLOCK=0
TEAMMATE_RATE_LIMITED=0
if [ "$TEAM_MEMBER_COUNT" -gt 0 ]; then
    if [ -n "$SESSION_ID_SAFE" ]; then
        TEAMMATE_STATE_FILE="${STATE_DIR}/${SESSION_ID_SAFE}.teammate-sig"
        PREV_ROSTER_SIGNATURE=""
        PREV_BLOCK_EPOCH=""
        if [ -f "$TEAMMATE_STATE_FILE" ]; then
            PREV_ROSTER_SIGNATURE=$(sed -n '1p' "$TEAMMATE_STATE_FILE" 2>/dev/null) || PREV_ROSTER_SIGNATURE=""
            PREV_BLOCK_EPOCH=$(sed -n '2p' "$TEAMMATE_STATE_FILE" 2>/dev/null) || PREV_BLOCK_EPOCH=""
        fi

        # Panel concern #3: a corrupt/empty/non-numeric epoch line must
        # never reach bash arithmetic -- treat it the same as a
        # missing/corrupt whole file (changed => block, rewrite).
        EPOCH_VALID=1
        case "$PREV_BLOCK_EPOCH" in
            ''|*[!0-9]*) EPOCH_VALID=0 ;;
        esac

        REBLOCK_INTERVAL="${STOP_GUARD_TEAMMATE_REBLOCK_SECONDS:-600}"
        case "$REBLOCK_INTERVAL" in
            ''|*[!0-9]*) REBLOCK_INTERVAL=600 ;;
        esac

        NOW_EPOCH=$(date +%s 2>/dev/null) || NOW_EPOCH=0

        if [ ! -f "$TEAMMATE_STATE_FILE" ] || [ "$EPOCH_VALID" -eq 0 ] || [ "$PREV_ROSTER_SIGNATURE" != "$TEAM_ROSTER_SIGNATURE" ]; then
            TEAMMATE_BLOCK=1
        elif [ $(( NOW_EPOCH - PREV_BLOCK_EPOCH )) -ge "$REBLOCK_INTERVAL" ]; then
            TEAMMATE_BLOCK=1
        else
            TEAMMATE_RATE_LIMITED=1
        fi

        if [ "$TEAMMATE_BLOCK" -eq 1 ]; then
            mkdir -p "$STATE_DIR" 2>/dev/null && prune_state_dir && printf '%s\n%s\n' "$TEAM_ROSTER_SIGNATURE" "$NOW_EPOCH" > "$TEAMMATE_STATE_FILE" 2>/dev/null || true
        fi
    else
        # Structurally unreachable via this hook's stdin interface today:
        # TEAM_MEMBER_COUNT can only be >0 when SESSION_ID (and therefore
        # SESSION_ID_SAFE) is non-empty, since member-count resolution
        # above is itself gated on session_id. Kept as fail-toward-safety
        # in case that coupling ever changes (DKT-362 open question,
        # advisor-confirmed: deliberately untested, see
        # test_stop_guard_hook.py's module docstring).
        TEAMMATE_BLOCK=1
    fi
fi

if [ "$TEAMMATE_BLOCK" -eq 1 ] || [ "$DOCKET_BLOCK" -eq 1 ]; then
    REASON="Session stop blocked:"
    if [ "$TEAMMATE_BLOCK" -eq 1 ]; then
        REASON="${REASON} ${TEAM_MEMBER_COUNT} teammate(s) recorded in this session (${TEAM_MEMBER_NAMES}); periodic nudge (at most one per interval): re-check state once, reuse the existing armed wait (Monitor or singleton_wait.sh) — do NOT spawn a new background wait for this nudge."
    fi
    if [ "$DOCKET_BLOCK" -eq 1 ]; then
        REASON="${REASON} ${DOCKET_OUTSTANDING_COUNT} outstanding Docket issue(s) (${DOCKET_OUTSTANDING_IDS});"
    fi
    REASON="${REASON} resolve or shut down teammates and close/defer issues before stopping."
    emit_block "$REASON" "team_session=${IS_TEAM_SESSION} teammates=${TEAM_MEMBER_COUNT} teammate_rate_limited=${TEAMMATE_RATE_LIMITED} docket=${DOCKET_OUTSTANDING_COUNT} docket_rate_limited=${DOCKET_RATE_LIMITED}"
fi

emit_allow "clear team_session=${IS_TEAM_SESSION} teammates=${TEAM_MEMBER_COUNT} teammate_rate_limited=${TEAMMATE_RATE_LIMITED} docket=${DOCKET_OUTSTANDING_COUNT} docket_rate_limited=${DOCKET_RATE_LIMITED}"
