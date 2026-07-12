#!/bin/bash
# Chains the claim ritual (assignee-first, then in-progress) with a cwd-guard
# and updated_at verification, replacing the manual 2-command chain agents
# previously typed by hand.
set -euo pipefail

usage() {
    echo "Usage: docket_claim.sh <id> <role>" >&2
    echo "  Claims <id> for @<role>: docket issue edit -a @<role> && docket issue move in-progress" >&2
    echo "  Guards cwd to repo root and verifies updated_at advanced." >&2
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

show_updated_at() {
    local out
    out=$(docket issue show "$ID" --json) || {
        echo "docket_claim.sh: failed to show ${ID}: ${out}" >&2
        exit 1
    }
    printf '%s' "$out" | jq -r '.data.updated_at'
}

BEFORE_UPDATED_AT=$(show_updated_at)

docket issue edit "$ID" -a "@${ROLE}"
docket issue move "$ID" in-progress

AFTER_UPDATED_AT=$(show_updated_at)

if [ "$AFTER_UPDATED_AT" = "$BEFORE_UPDATED_AT" ]; then
    echo "docket_claim.sh: claim did not take effect — updated_at unchanged (${AFTER_UPDATED_AT}). Check cwd/docket state." >&2
    exit 1
fi

echo "Claimed ${ID} for @${ROLE} (updated_at: ${BEFORE_UPDATED_AT} -> ${AFTER_UPDATED_AT})"
