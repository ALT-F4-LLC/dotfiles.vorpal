#!/bin/bash
# Shared "stage + lint" step for the report-emission skills' "Validation
# Before Emit" sequence (code-review-verdict, verify-ac, design-review,
# design-qa) -- previously ~15 lines of hand-described mktemp-staging +
# report_lint.py invocation + exit-code-triple handling, duplicated
# verbatim across all four SKILL.md files.
#
# Stages the drafted report content (a content-file argument, or stdin
# when omitted / passed as "-") to a fresh mktemp path under $TMPDIR --
# never a fixed name: parallel panel reviewers (advisor + reviewer-2, or
# the 3-way security panel) can share one $TMPDIR, and a fixed name races
# -- then runs report_lint.py against the staged copy. Exit-code
# semantics are report_lint.py's, passed through unchanged:
#   0  pass             -- stdout: OK: <skill> report (<mode>)
#   1  fail-with-detail -- stderr: validation failed: <check> -- <detail>
#   2  infra-failure    -- stderr: usage / missing linter / staging error
set -euo pipefail

usage() {
    echo "Usage: report_stage_lint.sh <skill-name> [--mode full|round-n|light] [<content-file>|-]" >&2
    echo "  <skill-name>    code-review-verdict | verify-ac | design-review | design-qa" >&2
    echo "  <content-file>  path to the drafted report; omit or pass - to read stdin" >&2
    exit 2
}

[ "$#" -ge 1 ] || usage

SKILL="$1"
shift

MODE_ARGS=()
if [ "${1:-}" = "--mode" ]; then
    [ "$#" -ge 2 ] || usage
    MODE_ARGS=(--mode "$2")
    shift 2
fi

CONTENT_FILE="${1:--}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINTER="${SCRIPT_DIR}/report_lint.py"
[ -f "$LINTER" ] || LINTER="$HOME/.claude/scripts/report_lint.py"
if [ ! -f "$LINTER" ]; then
    echo "report_stage_lint.sh: report_lint.py not found (checked ${SCRIPT_DIR} and ~/.claude/scripts)" >&2
    exit 2
fi

STAGE=$(mktemp "${TMPDIR:-/tmp}/report_stage-XXXXXX") || {
    echo "report_stage_lint.sh: mktemp failed under \${TMPDIR:-/tmp}" >&2
    exit 2
}
trap 'rm -f "$STAGE"' EXIT

if [ "$CONTENT_FILE" = "-" ]; then
    cat >"$STAGE"
else
    [ -r "$CONTENT_FILE" ] || {
        echo "report_stage_lint.sh: cannot read content file: ${CONTENT_FILE}" >&2
        exit 2
    }
    cp "$CONTENT_FILE" "$STAGE"
fi

python3 "$LINTER" --skill "$SKILL" "${MODE_ARGS[@]+"${MODE_ARGS[@]}"}" "$STAGE"
