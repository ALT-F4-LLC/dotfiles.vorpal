#!/bin/bash
# Lock-guarded background-wait helper: makes "spawn a fresh wait per nudge"
# idempotent instead of cumulative when armed through this helper — the
# mechanical guard against the orphaned-poller leak class from the
# 2026-07-16 DKT-345 incident. NOT a guarantee across all invocation paths:
# a hand-rolled Bash(run_in_background=true) loop still bypasses the lock
# entirely; this is a doctrine convention + opt-in helper.
#
# Usage: singleton_wait.sh <key> <interval-seconds> <condition-command> [args...]
#   Polls <condition-command> every <interval-seconds>s until it exits 0,
#   then prints "condition-met key=<key>" and exits 0. Exactly one poller
#   may be armed per <key> at a time; a second invocation for an
#   already-armed key prints "already-armed key=<key> pid=<pid>" and exits
#   3 without polling.
#
#   SINGLETON_WAIT_LOCK_ROOT (default /tmp/claude/wait-locks) overrides the
#   lock root. Deliberately not $TMPDIR (session-scoped, sandbox-mode-
#   dependent) and not ~/.claude (not sandbox-writable for background Bash
#   in default profiles).
#
# Lock contract: claim = atomic `mkdir "$LOCK_ROOT/<sanitized-key>"`. The
# owning process publishes its pid by writing to a temp file inside the
# lock dir and mv-ing it into place as `pid` — the pid file's *appearance*
# is atomic relative to the mkdir claim, so a losing invocation never
# observes a partially-written pid file; it sees either no `pid` file yet
# or a fully-formed one. A losing invocation that observes no `pid` file
# yet treats this as "just claimed" (bounded backoff + re-read), never as
# "dead" — deleting a lock on an ambiguous read would break the winner's
# exclusivity guarantee. If the pid still cannot be read after the backoff
# budget, the lock is treated conservatively as live (exit 3, pid=unknown)
# rather than reclaimed.
#
# Stale-lock reclaim: once a pid is read, `kill -0 <pid>` decides liveness
# — NOT lock-dir age (macOS does not reliably clear /tmp across boots, so
# pid liveness, not "the lock predates this boot", is the actual soundness
# guard). A dead pid alone is not enough to reclaim safely: two concurrent
# reclaimers could both observe the same dead pid, and a plain `rm -rf`
# from each would let a fast reclaimer's fresh, live lock be deleted by a
# slower reclaimer still acting on its own stale read. Reclaim therefore
# transfers ownership atomically first: `mv` the lock dir to a private,
# uniquely-named quarantine path (rename(2) is atomic — of any number of
# concurrent movers racing the same source path, exactly one succeeds),
# THEN `rm -rf` the quarantined copy, THEN retry the mkdir claim exactly
# once. If the `mv` fails (ENOENT — another reclaimer already won), this
# invocation did not reclaim anything and re-enters the ordinary claim
# path rather than assuming ownership. If the retried claim also loses —
# to a live claimant, or another dead pid — fall through to exit 3 rather
# than retrying indefinitely.
#
# Known risks (untested/probabilistic, documented not mitigated):
#   - R-5: a recycled pid can make a stale lock look live, producing a
#     false "already-armed" and blocking re-arm.
#   - A winner that crashes between mkdir and pid publish leaves a
#     permanently pid-less lock wedging the key (this helper always backs
#     off conservatively rather than deleting an unresolved lock, by
#     design — see above).
#   - A reclaimer SIGKILL'd between the quarantine `mv` and the `rm -rf`
#     of the quarantined copy leaves an orphaned, empty `.reclaim.*` dir
#     under LOCK_ROOT. Harmless (never read back by any code path; does
#     not wedge the key) but not self-cleaning -- an operator sweep of
#     LOCK_ROOT may accumulate these over a long-lived boot.
#   Operator remedy for either: `rm -rf` the lock dir named in the
#   already-armed message. Manual recovery heuristic: a lock with a dead
#   pid, OR a pid-less lock older than roughly a minute, is safe to
#   `rm -rf` by hand.
#
# Cleanup: trap on EXIT/INT/TERM removes the lock dir. Registered only
# after this process wins the claim, so a losing invocation never removes
# a lock it doesn't own.
#
# Exit codes: 0 condition met; 2 usage error or unwritable lock root (never
# polls unguarded); 3 already armed by a live (or unresolvable) poller.
set -uo pipefail

usage() {
    echo "Usage: singleton_wait.sh <key> <interval-seconds> <condition-command> [args...]" >&2
    echo "  Polls <condition-command> every <interval-seconds>s until it exits 0." >&2
    echo "  Exactly one poller may be armed per <key>; a second invocation for an" >&2
    echo "  already-armed key exits 3 without polling." >&2
    echo "  SINGLETON_WAIT_LOCK_ROOT (default /tmp/claude/wait-locks) overrides the" >&2
    echo "  lock root; an unwritable lock root also exits 2." >&2
    exit 2
}

if [ "$#" -lt 3 ]; then
    usage
fi

KEY="$1"
INTERVAL="$2"
shift 2
CONDITION_CMD=("$@")

case "$INTERVAL" in
    ''|*[!0-9]*)
        echo "singleton_wait.sh: interval-seconds must be a positive integer, got '${INTERVAL}'" >&2
        exit 2
        ;;
esac
if [ "$INTERVAL" -lt 1 ]; then
    echo "singleton_wait.sh: interval-seconds must be >= 1, got '${INTERVAL}'" >&2
    exit 2
fi

LOCK_ROOT="${SINGLETON_WAIT_LOCK_ROOT:-/tmp/claude/wait-locks}"
SANITIZED_KEY=$(printf '%s' "$KEY" | tr -c 'A-Za-z0-9_-' '_')
LOCK_DIR="${LOCK_ROOT}/${SANITIZED_KEY}"

mkdir -p "$LOCK_ROOT" 2>/dev/null
if [ ! -d "$LOCK_ROOT" ] || [ ! -w "$LOCK_ROOT" ]; then
    echo "singleton_wait.sh: lock root '${LOCK_ROOT}' is not writable (override via SINGLETON_WAIT_LOCK_ROOT)" >&2
    exit 2
fi

# --- claim -----------------------------------------------------------------
RECLAIMED=0
while true; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
        # Won the claim. Publish the pid atomically: write-to-temp then mv,
        # so a concurrent loser never observes a partially-written pid file.
        TMP_PID_FILE="${LOCK_DIR}/.pid.tmp.$$"
        printf '%s\n' "$$" > "$TMP_PID_FILE"
        mv -f "$TMP_PID_FILE" "${LOCK_DIR}/pid"
        break
    fi

    # Lost the mkdir race (or the dir already existed). Determine whether
    # the holder is alive, dead, or still in the act of publishing its pid.
    OWNER_PID=""
    BACKOFF_TRIES=0
    while [ "$BACKOFF_TRIES" -lt 20 ]; do
        if [ ! -d "$LOCK_DIR" ]; then
            break  # owner released between our failed mkdir and now
        fi
        if [ -s "${LOCK_DIR}/pid" ]; then
            OWNER_PID=$(cat "${LOCK_DIR}/pid" 2>/dev/null || true)
            [ -n "$OWNER_PID" ] && break
        fi
        BACKOFF_TRIES=$((BACKOFF_TRIES + 1))
        sleep 0.1
    done

    if [ ! -d "$LOCK_DIR" ]; then
        continue  # lock vanished; retry the claim from the top
    fi

    if [ -z "$OWNER_PID" ]; then
        # Never resolved a pid within the backoff budget. Do not delete an
        # ambiguous lock (see header) -- treat conservatively as live.
        echo "already-armed key=${KEY} pid=unknown"
        exit 3
    fi

    if kill -0 "$OWNER_PID" 2>/dev/null; then
        echo "already-armed key=${KEY} pid=${OWNER_PID}"
        exit 3
    fi

    # Dead pid: stale lock. Do not rm -rf directly -- transfer ownership of
    # the stale lock atomically via mv first, so a slower reclaimer here
    # can never delete a faster reclaimer's fresh, live lock that has since
    # replaced the path we originally inspected.
    if [ "$RECLAIMED" -eq 1 ]; then
        # Already used our one reclaim retry; fall through rather than
        # retry indefinitely.
        echo "already-armed key=${KEY} pid=${OWNER_PID}"
        exit 3
    fi

    QUARANTINE="${LOCK_ROOT}/.reclaim.$$.${SANITIZED_KEY}"
    if mv "$LOCK_DIR" "$QUARANTINE" 2>/dev/null; then
        rm -rf "$QUARANTINE"
        RECLAIMED=1
        continue  # retry the claim exactly once
    fi

    # Lost the reclaim race (another reclaimer's mv won first) -- we did
    # not reclaim anything, so do not consume the once-only retry. Loop
    # back and re-enter the ordinary claim path against whatever now
    # occupies LOCK_DIR (likely the other reclaimer's fresh, live lock).
done

# Split, not combined: bash RESUMES script execution after a signal trap
# fires, so a combined `EXIT INT TERM` handler here would let a TERM'd
# poller fall through to the poll loop below with its lock already removed
# -- an immortal, SIGKILL-only poller with a duplicate-arm window against
# the very key it was supposed to hold exclusively. INT/TERM must exit
# explicitly; the EXIT trap then fires exactly once (on that exit, or on
# condition-met) and performs the one rm -rf.
trap 'rm -rf "$LOCK_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- poll --------------------------------------------------------------
while true; do
    if "${CONDITION_CMD[@]}"; then
        echo "condition-met key=${KEY}"
        exit 0
    fi
    sleep "$INTERVAL"
done
