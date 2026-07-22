#!/bin/bash
# Collapses the backlog->todo Docket-issue promotion doctrine (previously
# hand-restated at 4 separate call sites in team-lead.md) into one
# idempotent script: promote if backlog, no-op otherwise.
set -euo pipefail

usage() {
    echo "Usage: docket_promote.sh <id>" >&2
    echo "  If <id>'s status is 'backlog', promotes it to 'todo' via" >&2
    echo "  ~/.claude/scripts/docket_write.sh <id> move <id> todo." >&2
    echo "  No-op (exit 0) if the issue is already 'todo' or beyond." >&2
    echo "  Guards cwd to repo root. Exits nonzero only on a genuine" >&2
    echo "  failure (issue not found, or docket_write.sh failure)." >&2
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

ID="$1"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_promote.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

SHOW_OUTPUT=$(docket issue show "$ID" --json) || {
    echo "docket_promote.sh: failed to show ${ID}" >&2
    exit 1
}
STATUS=$(printf '%s' "$SHOW_OUTPUT" | jq -r '.data.status')

if [ "$STATUS" != "backlog" ]; then
    echo "docket_promote.sh: ${ID} status is \"${STATUS}\" — no promotion needed."
    exit 0
fi

~/.claude/scripts/docket_write.sh "$ID" move "$ID" todo

echo "docket_promote.sh: promoted ${ID} backlog -> todo."
