#!/bin/bash
# Parses a reviewer report's structured sections (Verdict/Confidence/Domain
# Relevance/Findings/Summary, per vote/SKILL.md's Reviewer Prompt Template)
# and casts the vote via `docket vote cast`, streaming findings from a temp
# file through stdin redirection rather than interpolating reviewer prose
# into a command-line argument or heredoc body — the source of the
# bare-`!`/stray-backslash corruption documented in vote/SKILL.md's
# Recording Votes section. Falls back from --findings-json to plaintext
# --findings when the parsed JSON is missing or malformed.
#
# --non-vote mode records a documented decision made without a formal quorum
# vote (see vote/SKILL.md's Non-Vote Decisions section for when to use it).
# It parses Decision/Rationale/Summary instead, and streams the assembled
# body through `docket doc create -d @<tmpfile>` — the file-based equivalent
# of the vote-cast path's stdin redirection — for the same reason: freeform
# prose (decision/rationale text) never touches argv or a heredoc.
set -euo pipefail

usage() {
    echo "Usage: vote_record.sh <vote-id> <voter> <role> <report-file>" >&2
    echo "       vote_record.sh --non-vote <decision-id> <recorder> <role> <report-file> [issue-id]" >&2
    echo "  vote-id:     e.g. DKT-V1" >&2
    echo "  voter:       voter identity, e.g. DKT-V1-reviewer-1" >&2
    echo "  decision-id: short label for the decision, e.g. DKT-95-caching-approach" >&2
    echo "  recorder:    identity recording the decision, e.g. team-lead" >&2
    echo "  role:        reviewer or recorder agent type, e.g. staff-engineer" >&2
    echo "  report-file: path to the structured report (vote: Verdict/Confidence/" >&2
    echo "               Domain Relevance/Findings/Summary; non-vote: Decision/" >&2
    echo "               Rationale/Summary)" >&2
    echo "  issue-id:    optional Docket issue to link the decision doc to (non-vote only)" >&2
    exit 1
}

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage
fi

NON_VOTE=0
if [ "$#" -ge 1 ] && [ "$1" = "--non-vote" ]; then
    NON_VOTE=1
    shift
fi

if [ "$NON_VOTE" -eq 1 ]; then
    if [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
        usage
    fi
    DECISION_ID="$1"
    RECORDER="$2"
    ROLE="$3"
    REPORT_FILE="$4"
    ISSUE_ID="${5:-}"
else
    if [ "$#" -ne 4 ]; then
        usage
    fi
    VOTE_ID="$1"
    VOTER="$2"
    ROLE="$3"
    REPORT_FILE="$4"
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo "vote_record.sh: report file not found: $REPORT_FILE" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "vote_record.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Prints the body between a "### <heading>" line matching exactly $1 and the
# next "### " heading (or EOF), excluding both heading lines.
extract_section() {
    local want="$1"
    local file="$2"
    awk -v want="$want" '
        /^### / {
            line = $0
            sub(/\r$/, "", line)
            if (active) { exit }
            if (line == want) { active = 1 }
            next
        }
        active { print }
    ' "$file"
}

# Prints the body of a ```json fenced block from stdin.
extract_json_fence() {
    awk '
        /^```json/ { active = 1; next }
        /^```/ { if (active) exit }
        active { print }
    '
}

if [ "$NON_VOTE" -eq 1 ]; then
    DECISION=$(extract_section "### Decision" "$REPORT_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ' ' | sed -e 's/[[:space:]]\{2,\}/ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') || true
    if [ -z "$DECISION" ]; then
        echo "vote_record.sh: could not parse a Decision from $REPORT_FILE" >&2
        exit 1
    fi

    RATIONALE=$(extract_section "### Rationale" "$REPORT_FILE")
    if [ -z "$RATIONALE" ]; then
        echo "vote_record.sh: could not parse a Rationale from $REPORT_FILE" >&2
        exit 1
    fi

    SUMMARY=$(extract_section "### Summary" "$REPORT_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ' ' | sed -e 's/[[:space:]]\{2,\}/ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') || true
    if [ -z "$SUMMARY" ]; then
        SUMMARY="(no summary section found in report)"
    fi

    TMP_BODY=$(mktemp "${TMPDIR:-/tmp}/vote_record.XXXXXX")
    trap 'rm -f "$TMP_BODY"' EXIT

    {
        printf 'Decision: %s\n\n' "$DECISION"
        printf 'Recorded by: %s (%s)\n\n' "$RECORDER" "$ROLE"
        printf 'Rationale:\n%s\n\n' "$RATIONALE"
        printf 'Summary: %s\n' "$SUMMARY"
    } >"$TMP_BODY"

    DOC_JSON=$(docket doc create \
        -T decision \
        -t "Non-vote decision: $DECISION_ID" \
        -d "@$TMP_BODY" \
        --json) || {
        echo "vote_record.sh: docket doc create failed" >&2
        exit 1
    }
    echo "$DOC_JSON"

    if [ -n "$ISSUE_ID" ]; then
        DOC_ID=$(printf '%s' "$DOC_JSON" | jq -r '.data.id')
        if [ -z "$DOC_ID" ] || [ "$DOC_ID" = "null" ]; then
            echo "vote_record.sh: could not parse doc id from docket doc create output; skipping issue link" >&2
            exit 1
        fi
        docket doc link add "$DOC_ID" --issue "$ISSUE_ID" || {
            echo "vote_record.sh: docket doc link add failed for $DOC_ID -> $ISSUE_ID" >&2
            exit 1
        }
    fi

    exit 0
fi

VERDICT=$(extract_section "### Verdict" "$REPORT_FILE" | tr '[:upper:]' '[:lower:]' | grep -oE 'approve-with-concerns|approve|reject' | head -1)
if [ -z "$VERDICT" ]; then
    echo "vote_record.sh: could not parse a Verdict (approve|approve-with-concerns|reject) from $REPORT_FILE" >&2
    exit 1
fi

CONFIDENCE=$(extract_section "### Confidence" "$REPORT_FILE" | grep -oE '[0-9]+\.[0-9]+|[0-9]+' | head -1)
if [ -z "$CONFIDENCE" ]; then
    echo "vote_record.sh: could not parse a Confidence value from $REPORT_FILE" >&2
    exit 1
fi

DOMAIN_RELEVANCE=$(extract_section "### Domain Relevance" "$REPORT_FILE" | grep -oE '[0-9]+\.[0-9]+|[0-9]+' | head -1)
if [ -z "$DOMAIN_RELEVANCE" ]; then
    echo "vote_record.sh: could not parse a Domain Relevance value from $REPORT_FILE" >&2
    exit 1
fi

SUMMARY=$(extract_section "### Summary" "$REPORT_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ' ' | sed -e 's/[[:space:]]\{2,\}/ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//') || true
if [ -z "$SUMMARY" ]; then
    SUMMARY="(no summary section found in report)"
fi

FINDINGS_JSON=$(extract_section "### Findings JSON" "$REPORT_FILE" | extract_json_fence)
FINDINGS_PLAIN=$(extract_section "### Findings" "$REPORT_FILE")
if [ -z "$FINDINGS_PLAIN" ]; then
    FINDINGS_PLAIN="(no Findings section found in report)"
fi

do_cast() {
    local findings_flag="$1"
    local findings_file="$2"
    docket vote cast "$VOTE_ID" \
        --voter "$VOTER" \
        --role "$ROLE" \
        -v "$VERDICT" \
        --confidence "$CONFIDENCE" \
        --domain-relevance "$DOMAIN_RELEVANCE" \
        --summary "$SUMMARY" \
        --json \
        "$findings_flag" - <"$findings_file"
}

TMP_FINDINGS=$(mktemp "${TMPDIR:-/tmp}/vote_record.XXXXXX")
trap 'rm -f "$TMP_FINDINGS"' EXIT

if [ -n "$FINDINGS_JSON" ] && printf '%s' "$FINDINGS_JSON" | jq empty >/dev/null 2>&1; then
    printf '%s\n' "$FINDINGS_JSON" >"$TMP_FINDINGS"
    if do_cast --findings-json "$TMP_FINDINGS"; then
        exit 0
    fi
    echo "vote_record.sh: --findings-json cast rejected by docket; falling back to plaintext --findings" >&2
else
    echo "vote_record.sh: Findings JSON missing or malformed; using plaintext --findings" >&2
fi

printf '%s\n' "$FINDINGS_PLAIN" >"$TMP_FINDINGS"
if do_cast --findings "$TMP_FINDINGS"; then
    exit 0
fi

echo "vote_record.sh: docket vote cast failed in both JSON and plaintext modes" >&2
exit 1
