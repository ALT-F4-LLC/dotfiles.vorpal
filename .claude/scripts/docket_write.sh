#!/bin/bash
# Generalizes docket_claim.sh's cwd-guard + write-verification pattern to
# arbitrary Docket issue write subcommands (edit, move, comment add, ...).
#
# Verifies via the issue's activity-log max id, not updated_at: updated_at
# has only second-level resolution, so back-to-back writes within the same
# wall-clock second land with an unchanged updated_at despite succeeding
# (confirmed empirically — see DKT-194). The activity log's id is a
# monotonically increasing counter appended on every write, so comparing
# max id before/after does not have that false-negative window.
set -euo pipefail

usage() {
    echo "Usage: docket_write.sh <id> <docket issue subcommand...>" >&2
    echo "  Runs 'docket issue <subcommand...>', then verifies <id>'s" >&2
    echo "  activity log advanced via a re-show." >&2
    echo "  Examples:" >&2
    echo "    docket_write.sh DKT-1 edit DKT-1 -a @senior-engineer" >&2
    echo "    docket_write.sh DKT-1 move DKT-1 in-progress" >&2
    echo "    docket_write.sh DKT-1 comment add DKT-1 -m \"note\"" >&2
    echo "  Guards cwd to repo root and verifies the write took effect." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

ID="$1"
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_write.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

show_issue() {
    docket issue show "$ID" --json || {
        echo "docket_write.sh: failed to show ${ID}" >&2
        exit 1
    }
}

last_activity_id() {
    printf '%s' "$1" | jq -r '(.data.activity // []) | map(.id) | max // 0'
}

BEFORE_OUTPUT=$(show_issue)
BEFORE_ACTIVITY_ID=$(last_activity_id "$BEFORE_OUTPUT")

docket issue "$@"

AFTER_OUTPUT=$(show_issue)
AFTER_ACTIVITY_ID=$(last_activity_id "$AFTER_OUTPUT")

if [ "$AFTER_ACTIVITY_ID" -le "$BEFORE_ACTIVITY_ID" ]; then
    echo "docket_write.sh: write did not take effect on ${ID} — activity log unchanged (last id ${AFTER_ACTIVITY_ID}). Check cwd/docket state." >&2
    exit 1
fi

echo "Wrote ${ID} via 'docket issue $*' (activity id: ${BEFORE_ACTIVITY_ID} -> ${AFTER_ACTIVITY_ID})"
