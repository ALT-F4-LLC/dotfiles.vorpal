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

# check <label> <pattern> [exclude-pattern] [icase]
#
# icase defaults to "yes" — the right behaviour for the prose checks, which must
# catch any capitalisation. Pass "no" when the pattern itself encodes case, as
# the issue-ID check does: matching an upper-case-only pattern case-INSENSITIVELY
# silently widens it to every lower-case `word-number`, so `sonnet-5` and
# `top-10` were being rejected as issue references.
check() {
    local label="$1" pattern="$2" exclude="${3:-}" icase="${4:-yes}" src="${5:-$FILE}" hits
    local mflags="-niE" xflags="-viE"
    if [ "$icase" = "no" ]; then
        mflags="-nE"
        xflags="-vE"
    fi
    if [ -n "$exclude" ]; then
        hits=$(grep $mflags "$pattern" "$src" | grep $xflags "$exclude")
    else
        hits=$(grep $mflags "$pattern" "$src")
    fi
    if [ -n "$hits" ]; then
        echo "FAIL: $label" >&2
        echo "$hits" | sed 's/^/  /' >&2
        FAILED=1
    fi
}

check "agent/subagent reference" \
    '@(senior-engineer|staff-engineer|distinguished-engineer|security-engineer|sdet|ux-designer|project-manager|team-lead|advisor)\b'

# Case-SENSITIVE by design (see check()). The generic arm is upper-case only,
# which is what a real tracker ID looks like; the second arm keeps the local
# tracker's prefix matching in any capitalisation, so dropping `-i` does not
# lose coverage of a lower-cased `dkt-12`.
check "Docket issue ID / issue-tracker reference" \
    '\b([A-Z]{2,10}-[0-9]+|[Dd][Kk][Tt]-[0-9]+)\b' \
    '\b(UTF|SHA|RFC|ISO|TLS|SSL|AES|CVE)-[0-9]+\b' \
    no

check "harness/orchestration metadata" \
    '\b(session[_ -]?id|task[_ -]?id|vote[_ -]?id|teammate|docket|team-lead|staff-engineer|senior-engineer|security-engineer|distinguished-engineer|project-manager|ux-designer|sdet|historical-auditor|bug-auditor|repetition-auditor|model-routing-auditor|docs-researcher|simplify-scout|innovation-scanner|coherence-reviewer|single-reviewer|tdd-author|docs-author)\b|\b(reviewer|design-review|design-qa)-[0-9]+\b|\bverifier-(criteria|integration)\b'

# The Conventional-Commits SCOPE on the subject line is a component name, not
# prose, and this project's component genuinely is named for the product. The
# scope token is therefore masked before this check runs -- ONLY the token
# inside the parentheses, never the rest of the line, so a prose mention
# sharing the subject line is still caught. Masking preserves the line count so
# reported line numbers stay accurate.
SCOPE_MASKED="$(mktemp "${TMPDIR:-/tmp}/commit-msg-scope-masked.XXXXXX")"
trap 'rm -f "$SCOPE_MASKED"' EXIT
sed '1s/^\([a-zA-Z]\{1,12\}\)(\([^)]*\))\(!\{0,1\}\):/\1(scope)\3:/' "$FILE" > "$SCOPE_MASKED"

check "Claude/Claude Code/Anthropic reference or AI-attribution trailer" \
    '\b(claude|anthropic)\b|generated (with|by)|co-authored-by:.*(claude|anthropic)' \
    '' yes "$SCOPE_MASKED"

if [ "$FAILED" -eq 0 ]; then
    echo "commit_msg_check: clean (no forbidden-content matches)"
    exit 0
fi
echo "commit_msg_check: forbidden content present — rewrite and re-run" >&2
exit 1
