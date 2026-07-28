#!/bin/bash
# Shared "stage + validate" step for the doc-authoring skills' "Validation
# Before Save" sequence (tdd, adr; eventually prd/ux-spec) -- mirrors
# report_stage_lint.sh's pattern for the report-emission family. Previously
# each doc-authoring skill hand-rolled its own ~15-line mktemp-staging +
# doc_validate.py invocation, duplicated verbatim across SKILL.md files.
#
# Stages the drafted content (a content-file argument, or stdin when
# omitted / passed as "-") to a fresh mktemp path under $TMPDIR -- never a
# fixed name: a fixed name races when multiple drafts are staged
# concurrently -- then chains, in order:
#   1. doc_validate.py --type <type>              (always)
#   2. tdd_preflight.sh                            (type=tdd only)
#   3. g5_check.sh --content                       (type=tdd only)
#
# Exit-code semantics mirror report_stage_lint.sh's pass-through convention:
#   0  pass             -- all applicable checks passed
#   1  fail-with-detail  -- a check failed; its own stderr is surfaced, not
#                          swallowed
#   2  infra-failure     -- usage / missing tool / staging error
#
# g5_check.sh --content exiting 2 ("no candidate regex commands found") is
# NOT treated as a failure here: most tdd drafts embed no backtick-quoted
# grep command at all (many phase ACs use measured/rendered values instead
# of a regex), so "nothing to check" is a benign, expected outcome -- only
# exit 1 (a candidate that failed, was rejected, timed out, or warned) is
# a real failure.
set -euo pipefail

usage() {
    echo "Usage: doc_stage_validate.sh <type> [<content-file>|-]" >&2
    echo "  <type>          tdd | adr" >&2
    echo "  <content-file>  path to the drafted document; omit or pass - to read stdin" >&2
    exit 2
}

[ "$#" -ge 1 ] || usage

TYPE="$1"
shift

case "$TYPE" in
    tdd|adr) ;;
    *)
        echo "doc_stage_validate.sh: unsupported type '${TYPE}' (must be tdd or adr)" >&2
        exit 2
        ;;
esac

CONTENT_FILE="${1:--}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_tool() {
    local name="$1"
    local candidate="${SCRIPT_DIR}/${name}"
    if [ -f "$candidate" ]; then
        echo "$candidate"
        return 0
    fi
    candidate="$HOME/.claude/scripts/${name}"
    if [ -f "$candidate" ]; then
        echo "$candidate"
        return 0
    fi
    return 1
}

DOC_VALIDATE=$(resolve_tool doc_validate.py) || {
    echo "doc_stage_validate.sh: doc_validate.py not found (checked ${SCRIPT_DIR} and ~/.claude/scripts)" >&2
    exit 2
}

if [ "$TYPE" = "tdd" ]; then
    TDD_PREFLIGHT=$(resolve_tool tdd_preflight.sh) || {
        echo "doc_stage_validate.sh: tdd_preflight.sh not found (checked ${SCRIPT_DIR} and ~/.claude/scripts)" >&2
        exit 2
    }
    G5_CHECK=$(resolve_tool g5_check.sh) || {
        echo "doc_stage_validate.sh: g5_check.sh not found (checked ${SCRIPT_DIR} and ~/.claude/scripts)" >&2
        exit 2
    }
fi

STAGE=$(mktemp "${TMPDIR:-/tmp}/doc_stage-XXXXXX") || {
    echo "doc_stage_validate.sh: mktemp failed under \${TMPDIR:-/tmp}" >&2
    exit 2
}
trap 'rm -f "$STAGE"' EXIT

if [ "$CONTENT_FILE" = "-" ]; then
    cat >"$STAGE"
else
    [ -r "$CONTENT_FILE" ] || {
        echo "doc_stage_validate.sh: cannot read content file: ${CONTENT_FILE}" >&2
        exit 2
    }
    cp "$CONTENT_FILE" "$STAGE"
fi

set +e

python3 "$DOC_VALIDATE" --type "$TYPE" "$STAGE"
RC=$?
if [ "$RC" -eq 2 ]; then
    exit 2
elif [ "$RC" -ne 0 ]; then
    exit 1
fi

if [ "$TYPE" = "tdd" ]; then
    bash "$TDD_PREFLIGHT" "$STAGE"
    RC=$?
    if [ "$RC" -ne 0 ]; then
        exit 1
    fi

    bash "$G5_CHECK" --content "$STAGE"
    RC=$?
    if [ "$RC" -eq 1 ]; then
        exit 1
    fi
    # RC == 2 (no candidate regex commands found) and RC == 0 both pass
    # through as an overall pass -- see header comment.
fi

exit 0
