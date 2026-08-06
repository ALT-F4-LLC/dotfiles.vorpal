#!/bin/bash
# Creates a docket vote with the doctrine-correct --threshold mapped from
# criticality (fixes a live bug: docket CLI's silent 0.67 default diverges
# from ~/.claude/skills/vote/SKILL.md's Criticality Classification table for
# every level except a coincidental overlap near medium), then prints the
# exact text-prefixed delegation payload ready to paste into a SendMessage
# to team-lead, per the vote skill's Delegation Protocol.
set -euo pipefail

usage() {
    echo "Usage: vote_delegate.sh <role> <criticality> <desc> <voters> [artifact]" >&2
    echo "  role:        e.g. @senior-engineer (leading @ optional)" >&2
    echo "  criticality: low|medium|high|critical" >&2
    echo "  desc:        proposal description" >&2
    echo "  voters:      required number of voters (integer)" >&2
    echo "  artifact:    optional artifact path included in the payload" >&2
    exit 1
}

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage
fi

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    usage
fi

ROLE="@${1#@}"
CRITICALITY="$2"
DESC="$3"
VOTERS="$4"
ARTIFACT="${5:-}"

case "$CRITICALITY" in
    low) THRESHOLD=0.50 ;;
    medium) THRESHOLD=0.60 ;;
    high) THRESHOLD=0.75 ;;
    critical) THRESHOLD=0.90 ;;
    *)
        echo "vote_delegate.sh: unknown criticality '${CRITICALITY}' (want low|medium|high|critical)" >&2
        exit 1
        ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "vote_delegate.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

VOTE_OUTPUT=$(docket vote create -c "$CRITICALITY" -d "$DESC" -n "$VOTERS" --threshold "$THRESHOLD" --created-by "$ROLE" --json) || {
    echo "vote_delegate.sh: docket vote create failed" >&2
    echo "$VOTE_OUTPUT" >&2
    exit 1
}

VOTE_ID=$(printf '%s' "$VOTE_OUTPUT" | jq -r '.data.id')

if [ -z "$VOTE_ID" ] || [ "$VOTE_ID" = "null" ]; then
    echo "vote_delegate.sh: could not extract vote id from docket output" >&2
    echo "$VOTE_OUTPUT" >&2
    exit 1
fi

if command -v uuidgen >/dev/null 2>&1; then
    REQUEST_ID=$(uuidgen)
elif command -v python3 >/dev/null 2>&1; then
    REQUEST_ID=$(python3 -c "import uuid; print(uuid.uuid4())")
else
    echo "vote_delegate.sh: neither uuidgen nor python3 available to generate request_id" >&2
    exit 1
fi
REQUEST_ID=$(printf '%s' "$REQUEST_ID" | tr '[:upper:]' '[:lower:]')

PAYLOAD_JSON=$(jq -nc \
    --arg vote_id "$VOTE_ID" \
    --arg from "$ROLE" \
    --arg summary "$DESC" \
    --arg request_id "$REQUEST_ID" \
    --arg artifact "$ARTIFACT" \
    '{type: "delegation_request", protocol_version: "1", skill: "vote", request_id: $request_id, vote_id: $vote_id, from: $from, summary: $summary}
     + (if $artifact != "" then {artifact: $artifact} else {} end)')

echo "Threshold: ${THRESHOLD}"
echo "Vote ID: ${VOTE_ID}"
echo "delegation_request (vote) JSON: ${PAYLOAD_JSON}"
