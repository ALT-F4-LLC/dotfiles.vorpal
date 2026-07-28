#!/bin/bash
# Chains the claim ritual (assignee-first, then in-progress) with a cwd-guard
# and status/assignee verification, replacing the manual 2-command chain
# agents previously typed by hand.
set -euo pipefail

usage() {
    echo "Usage: docket_claim.sh <id> <role>" >&2
    echo "  Claims <id> for @<role>: docket issue edit -a @<role> && docket issue move in-progress" >&2
    echo "  Guards cwd to repo root and verifies status/assignee landed." >&2
    echo "  Rejects the claim (no state change) if the issue's status is still 'backlog'." >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

ID="$1"
ROLE="${2#@}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_claim.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

show_json() {
    local out
    out=$(docket issue show "$ID" --json) || {
        echo "docket_claim.sh: failed to show ${ID}: ${out}" >&2
        exit 1
    }
    printf '%s' "$out"
}

BEFORE_JSON=$(show_json)
BEFORE_UPDATED_AT=$(printf '%s' "$BEFORE_JSON" | jq -r '.data.updated_at')
BEFORE_STATUS=$(printf '%s' "$BEFORE_JSON" | jq -r '.data.status')

if [ "$BEFORE_STATUS" = "backlog" ]; then
    echo "docket_claim.sh: refusing to claim ${ID} — status is still 'backlog' (must be promoted to todo before claiming)" >&2
    exit 1
fi

docket issue edit "$ID" -a "@${ROLE}"
docket issue move "$ID" in-progress

AFTER_JSON=$(show_json)
AFTER_UPDATED_AT=$(printf '%s' "$AFTER_JSON" | jq -r '.data.updated_at')
AFTER_STATUS=$(printf '%s' "$AFTER_JSON" | jq -r '.data.status')
AFTER_ASSIGNEE=$(printf '%s' "$AFTER_JSON" | jq -r '.data.assignee')

# Verify against status/assignee rather than updated_at equality: updated_at
# is second-granularity, so a claim completing within one wall-clock second
# leaves BEFORE/AFTER equal even though the claim fully succeeded.
if [ "$AFTER_STATUS" != "in-progress" ] || [ "$AFTER_ASSIGNEE" != "@${ROLE}" ]; then
    echo "docket_claim.sh: claim did not take effect — status=${AFTER_STATUS} assignee=${AFTER_ASSIGNEE} (expected in-progress/@${ROLE}). Check cwd/docket state." >&2
    exit 1
fi

echo "Claimed ${ID} for @${ROLE} (updated_at: ${BEFORE_UPDATED_AT} -> ${AFTER_UPDATED_AT})"
