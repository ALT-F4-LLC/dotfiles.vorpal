#!/bin/bash
# Poll-loop stall detector. Combines roster_sweep.sh's {role: [in-progress
# issue ids]} with `docket plan --json`'s per-issue `updated_at` to detect
# issues that have simply stopped moving, and emits one
# `STALL-CANDIDATE: <role> <issue> unchanged <N>min` line per stall to
# stdout — one line = one Monitor tool event.
#
# `docket ... --watch` cannot do this job: it only emits when a row's fields
# CHANGE, so an issue that silently stalls (no status/updated_at delta at
# all) produces zero --watch events — the exact case this script exists to
# catch. This script instead polls on a fixed interval and diffs
# `updated_at` itself, so silence past the threshold is precisely what it
# detects.
#
# Designed to run under the Monitor tool, not as a standalone daemon: it is
# a long-lived foreground loop whose stdout lines are the event stream:
#   Monitor("deadman_watch.sh 10", description: "stall sweep")
# Monitor owns the process lifecycle (start, stream, stop) — this script
# does not fork, detach, or persist beyond the invocation that runs it.
set -euo pipefail

usage() {
    echo "Usage: deadman_watch.sh <stall-threshold-minutes> [poll-interval-seconds]" >&2
    echo "  Polls roster_sweep.sh + 'docket plan --json' every <poll-interval-seconds>" >&2
    echo "  (default 30) and emits 'STALL-CANDIDATE: <role> <issue> unchanged <N>min'" >&2
    echo "  to stdout for each in-progress issue whose updated_at has not advanced" >&2
    echo "  for at least <stall-threshold-minutes>. Run under Monitor; each stdout" >&2
    echo "  line is one event. Re-alerts only after the issue progresses and stalls" >&2
    echo "  again, so a single stall does not flood the event stream." >&2
    exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

THRESHOLD_MIN="$1"
POLL_INTERVAL="${2:-30}"

case "$THRESHOLD_MIN" in
    ''|*[!0-9]*) usage ;;
esac
case "$POLL_INTERVAL" in
    ''|*[!0-9]*) usage ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "deadman_watch.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROSTER_SWEEP="${SCRIPT_DIR}/roster_sweep.sh"

if [ ! -x "$ROSTER_SWEEP" ]; then
    echo "deadman_watch.sh: roster_sweep.sh not found or not executable at ${ROSTER_SWEEP}" >&2
    exit 1
fi

THRESHOLD_SEC=$((THRESHOLD_MIN * 60))

# State is kept in a plain-text file rather than a bash associative array:
# the repo's baseline /bin/bash is 3.2 (macOS default), which has no
# `declare -A`. One line per tracked issue: "<id> <updated_at>
# <first_seen_epoch> <alerted_updated_at|->". Rewritten in full each poll,
# which also prunes ids no longer in-progress.
STATE_FILE=$(mktemp)
trap 'rm -f "$STATE_FILE" "${STATE_FILE}.new" "${STATE_FILE}.plan"' EXIT

while true; do
    ROSTER_JSON=$("$ROSTER_SWEEP" 2>/dev/null) || {
        echo "deadman_watch.sh: roster_sweep.sh failed, skipping this poll" >&2
        sleep "$POLL_INTERVAL"
        continue
    }
    PLAN_JSON=$(docket plan --json 2>/dev/null) || {
        echo "deadman_watch.sh: docket plan --json failed, skipping this poll" >&2
        sleep "$POLL_INTERVAL"
        continue
    }

    NOW=$(date -u '+%s')

    # "<id>\t<updated_at>" per issue currently known to the plan.
    printf '%s' "$PLAN_JSON" | jq -r '.data.phases[].issues[] | [.id, .updated_at] | @tsv' \
        > "${STATE_FILE}.plan"

    : > "${STATE_FILE}.new"

    for ROLE in $(printf '%s' "$ROSTER_JSON" | jq -r 'keys[]'); do
        for ID in $(printf '%s' "$ROSTER_JSON" | jq -r --arg r "$ROLE" '.[$r][]'); do
            UPDATED_AT=$(awk -F'\t' -v id="$ID" '$1 == id { print $2; exit }' "${STATE_FILE}.plan")
            if [ -z "$UPDATED_AT" ]; then
                continue
            fi

            OLD_LINE=$(awk -v id="$ID" '$1 == id { print; exit }' "$STATE_FILE" 2>/dev/null || true)

            if [ -z "$OLD_LINE" ]; then
                echo "${ID} ${UPDATED_AT} ${NOW} -" >> "${STATE_FILE}.new"
                continue
            fi

            OLD_UPDATED_AT=$(printf '%s' "$OLD_LINE" | awk '{print $2}')
            OLD_FIRST_SEEN=$(printf '%s' "$OLD_LINE" | awk '{print $3}')
            OLD_ALERTED=$(printf '%s' "$OLD_LINE" | awk '{print $4}')

            if [ "$OLD_UPDATED_AT" != "$UPDATED_AT" ]; then
                # Issue progressed since the last poll; reset the stall timer.
                echo "${ID} ${UPDATED_AT} ${NOW} -" >> "${STATE_FILE}.new"
                continue
            fi

            # OLD_FIRST_SEEN is already an epoch — this script only ever writes epochs.
            ELAPSED=$((NOW - OLD_FIRST_SEEN))

            if [ "$ELAPSED" -ge "$THRESHOLD_SEC" ] && [ "$OLD_ALERTED" != "$UPDATED_AT" ]; then
                MINUTES=$((ELAPSED / 60))
                echo "STALL-CANDIDATE: ${ROLE} ${ID} unchanged ${MINUTES}min"
                echo "${ID} ${UPDATED_AT} ${OLD_FIRST_SEEN} ${UPDATED_AT}" >> "${STATE_FILE}.new"
            else
                echo "${ID} ${UPDATED_AT} ${OLD_FIRST_SEEN} ${OLD_ALERTED}" >> "${STATE_FILE}.new"
            fi
        done
    done

    mv "${STATE_FILE}.new" "$STATE_FILE"
    sleep "$POLL_INTERVAL"
done
