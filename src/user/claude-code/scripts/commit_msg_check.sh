#!/bin/bash
# Runs commit/SKILL.md Step 3's 4 forbidden-content checks against a drafted
# commit message file in one deterministic call. Single source of truth for
# the regex patterns — commit/SKILL.md invokes this instead of inlining
# hand-retyped `grep -niE` commands, removing the drift risk between the
# documented pattern and what's actually run.
set -uo pipefail

usage() {
    echo "Usage: commit_msg_check.sh <draft-file>" >&2
    echo "" >&2
    echo "  Runs the 4 forbidden-content checks against <draft-file>:" >&2
    echo "    1. agent/subagent references" >&2
    echo "    2. Docket issue IDs / issue-tracker references" >&2
    echo "    3. harness/orchestration metadata" >&2
    echo "    4. Claude/Claude Code/Anthropic references or AI-attribution trailers" >&2
    echo "" >&2
    echo "  Exits 0 if clean, 1 with the offending line(s) if any check" >&2
    echo "  fails, 2 on usage error." >&2
    exit 2
}

[ "$#" -eq 1 ] || usage
FILE="$1"
[ -f "$FILE" ] || {
    echo "commit_msg_check.sh: file not found: $FILE" >&2
    exit 2
}

FAILED=0

# check <label> <pattern> [exclude-pattern]
check() {
    local label="$1" pattern="$2" exclude="${3:-}" hits
    if [ -n "$exclude" ]; then
        hits=$(grep -niE "$pattern" "$FILE" | grep -viE "$exclude")
    else
        hits=$(grep -niE "$pattern" "$FILE")
    fi
    if [ -n "$hits" ]; then
        echo "FAIL: $label" >&2
        echo "$hits" | sed 's/^/  /' >&2
        FAILED=1
    fi
}

check "agent/subagent reference" \
    '@(senior-engineer|staff-engineer|distinguished-engineer|security-engineer|sdet|ux-designer|project-manager|team-lead|advisor)\b'

check "Docket issue ID / issue-tracker reference" \
    '\b[A-Z]{2,10}-[0-9]+\b' \
    '\b(UTF|SHA|RFC|ISO|TLS|SSL|AES|CVE)-[0-9]+\b'

check "harness/orchestration metadata" \
    '\b(session[_ -]?id|task[_ -]?id|vote[_ -]?id|teammate|docket)\b'

check "Claude/Claude Code/Anthropic reference or AI-attribution trailer" \
    '\b(claude|anthropic)\b|generated (with|by)|co-authored-by'

if [ "$FAILED" -eq 0 ]; then
    echo "commit_msg_check: clean (no forbidden-content matches)"
    exit 0
fi
echo "commit_msg_check: forbidden content present — rewrite and re-run" >&2
exit 1
