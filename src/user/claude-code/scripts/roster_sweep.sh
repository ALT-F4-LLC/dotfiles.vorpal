#!/bin/bash
# Emits {role: [in-progress issue ids]} for every role team-lead tracks, in a
# single invocation, replacing the hand-enumerated per-role
# `docket issue list -a @<role> -s in-progress --json` calls in team-lead.md's
# shutdown sweep and Liveness-Confirmation Gate pre-respawn check.
set -euo pipefail

usage() {
    echo "Usage: roster_sweep.sh" >&2
    echo "  Emits {role: [in-progress issue ids]} across all roles team-lead" >&2
    echo "  tracks (senior-engineer, sdet, staff-engineer, distinguished-engineer," >&2
    echo "  project-manager, security-engineer, ux-designer)." >&2
    exit 1
}

if [ "$#" -ne 0 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "roster_sweep.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Roles sourced from team-lead.md's Per-Role Dispatch Table (all @-roles that
# hold Docket-assigned issues; team-lead itself is not assignable).
ROLES=(
    senior-engineer
    sdet
    staff-engineer
    distinguished-engineer
    project-manager
    security-engineer
    ux-designer
)

RESULT="{}"
for ROLE in "${ROLES[@]}"; do
    OUT=$(docket issue list -a "@${ROLE}" -s in-progress --json) || {
        echo "roster_sweep.sh: failed to list issues for @${ROLE}: ${OUT}" >&2
        exit 1
    }
    IDS=$(printf '%s' "$OUT" | jq '[.data.issues[].id]')
    RESULT=$(printf '%s' "$RESULT" | jq --arg role "$ROLE" --argjson ids "$IDS" '. + {($role): $ids}')
done

printf '%s\n' "$RESULT" | jq -c .
