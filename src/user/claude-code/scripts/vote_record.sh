#!/bin/bash
# Parses a reviewer report's structured sections (Verdict/Confidence/Domain
# Relevance/Findings/Summary, per vote/SKILL.md's Reviewer Prompt Template)
# and casts the vote via `docket vote cast`, streaming findings from a temp
# file through stdin redirection rather than interpolating reviewer prose
# into a command-line argument or heredoc body — the source of the
# bare-`!`/stray-backslash corruption documented in vote/SKILL.md's
# Recording Votes section. Falls back from --findings-json to plaintext
# --findings when the parsed JSON is missing or malformed.
set -euo pipefail

usage() {
    echo "Usage: vote_record.sh <vote-id> <voter> <role> <report-file>" >&2
    echo "  vote-id:     e.g. DKT-V1" >&2
    echo "  voter:       voter identity, e.g. DKT-V1-reviewer-1" >&2
    echo "  role:        reviewer agent type, e.g. staff-engineer" >&2
    echo "  report-file: path to the reviewer's structured report" >&2
    exit 1
}

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage
fi

if [ "$#" -ne 4 ]; then
    usage
fi

VOTE_ID="$1"
VOTER="$2"
ROLE="$3"
REPORT_FILE="$4"

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

SUMMARY=$(extract_section "### Summary" "$REPORT_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ' ' | sed -e 's/[[:space:]]\{2,\}/ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
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
