#!/bin/bash
# Chains close -> verify status==done -> comment, replacing the manual
# 3-command sequence agents previously typed by hand. Never posts the
# "Completed:" comment unless the status transition is confirmed.
set -euo pipefail

usage() {
    echo "Usage: docket_close.sh <id> <msg>" >&2
    echo "  Closes <id>, verifies .data.status == \"done\" via a re-show," >&2
    echo "  then posts: docket issue comment add <id> -m \"Completed: <msg>\"" >&2
    echo "  Guards cwd to repo root. Exits non-zero without commenting if" >&2
    echo "  the status check fails." >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

ID="$1"
MSG="$2"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_close.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

docket issue close "$ID"

SHOW_OUTPUT=$(docket issue show "$ID" --json) || {
    echo "docket_close.sh: failed to show ${ID}: ${SHOW_OUTPUT}" >&2
    exit 1
}
STATUS=$(printf '%s' "$SHOW_OUTPUT" | jq -r '.data.status')

if [ "$STATUS" != "done" ]; then
    echo "docket_close.sh: ${ID} status is \"${STATUS}\", not \"done\" — not posting comment." >&2
    echo "$SHOW_OUTPUT" >&2
    exit 1
fi

docket issue comment add "$ID" -m "Completed: ${MSG}"

echo "Closed ${ID} (status: done) and posted completion comment."
