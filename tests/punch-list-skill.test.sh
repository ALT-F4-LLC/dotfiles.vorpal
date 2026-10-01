#!/bin/bash

# Guard suite for the punch-list skill's no-unverified-close prohibition.
#
# Defect class: punch-list closes items in its final walkthrough, and a close
# on an item this session never verified cannot be seen from outside the
# session once the run ends; the closed issue reads the same as a verified
# one. An edit that drops the ruling, carves out an exception ("unless the
# operator asks"), or loosens where closure may happen ships green without
# this pin. The skill's other standing prohibition (no routing or size label
# on filed issues) stays unguarded on purpose: a mislabeled issue is visible
# to docket-tend and bare docket-plan, and groom's checks already catch it.
#
# The ruling is a bullet in a list, so paragraphs here are split at blank
# lines AND at each bullet start, then flattened to one line: rewrapping the
# prose is not a failure, and the assertion reads the ruling's own item, not
# the whole file. The literal runs to the item's closing period, so an
# exception spliced in before it breaks the pin.
#
# PUNCH_LIST_SKILL_FILE overrides the file under test, so a mutation probe can
# point the suite at a deliberately broken COPY under $TMPDIR without
# touching the checkout. The self-checks always read the repository's own
# copy. Each mutant, proven red by the self-checks on every run:
#
#   s1 the ruling sentence deleted: the suite fails
#   s2 ", unless the operator asks" spliced before the item's period: the
#      suite fails
#   s3 the ruling item duplicated: no single item carries the anchor, the
#      pin is refused, and the suite fails
#   s4 an untouched copy: the suite passes
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_SKILL="${SCRIPT_DIR}/../src/user/claude_code/skills/punch-list/SKILL.md"
SKILL="${PUNCH_LIST_SKILL_FILE:-$REPO_SKILL}"

if [ ! -f "$SKILL" ]; then
    echo "FAIL input: no such file: ${SKILL}" >&2
    echo "punch-list-skill: FAIL" >&2
    exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/punch-list-skill.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

fail=0

ok() {
    echo "ok   $1"
}

bad() {
    echo "FAIL $1"
    fail=1
}

# Every paragraph or list item of <in>, flattened to one line each.
flatten() { # <in> <out>
    awk '
        function close_para() {
            if (para != "") { print para; para = "" }
        }
        /^[[:space:]]*$/ { close_para(); next }
        /^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]/ { close_para() }
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            para = (para == "" ? line : para " " line)
        }
        END { close_para() }
    ' "$1" > "$2"
}

flatten "$SKILL" "${WORK}/flat"

inner() { # <skill-copy>
    PUNCH_LIST_SKILL_INNER=1 PUNCH_LIST_SKILL_FILE="$1" bash "$0" >/dev/null 2>&1
}

# expect_red <label> <perl-substitution>: a mutated copy of the repository's
# skill file must fail the suite, and the mutation must have applied.
expect_red() {
    perl -0pe "$2" "${WORK}/self-clean.md" > "${WORK}/self-mutant.md"
    if cmp -s "${WORK}/self-clean.md" "${WORK}/self-mutant.md"; then
        bad "self-check: the ${1} mutation did not apply — the control proves nothing"
    elif inner "${WORK}/self-mutant.md"; then
        bad "self-check: a copy with the ruling ${1} still passed the suite"
    else
        ok "self-check: a copy with the ruling ${1} fails the suite"
    fi
}

if [ -z "${PUNCH_LIST_SKILL_INNER:-}" ]; then
    if [ ! -f "$REPO_SKILL" ]; then
        bad "self-check: the repository's own skill file is missing: ${REPO_SKILL}"
    else
        cp "$REPO_SKILL" "${WORK}/self-clean.md"
        expect_red "deleted" 's/Never\s+close\s+an\s+item\s+this\s+skill\s+has\s+not\s+verified\.\s*//s'
        expect_red "weakened" 's/(section\s+and\s+nowhere\s+else)\./$1, unless the operator asks./s'
        expect_red "duplicated" 's/(- Never close an item.*?nowhere else\.\n)/$1$1/s'
        if inner "${WORK}/self-clean.md"; then
            ok "self-check: a clean skill copy passes the suite"
        else
            bad "self-check: a clean copy of the repository's skill file does not pass"
        fi
    fi
fi

anchor='Never close an item this skill has not verified'
ruling='- Never close an item this skill has not verified. Closure in the final walkthrough follows the rule in that section and nowhere else.'

hits=$(grep -cF -- "$anchor" "${WORK}/flat")
if [ "$hits" -ne 1 ]; then
    bad "close: expected exactly one item carrying '${anchor}', found ${hits}"
elif grep -qxF -- "$ruling" "${WORK}/flat"; then
    ok "close: never close an item this skill has not verified"
else
    bad "close: the ruling item no longer reads, in full: ${ruling}"
fi

if [ "$fail" -ne 0 ]; then
    echo "punch-list-skill: FAIL — the no-unverified-close ruling without its full pin is the failure this catches; fix the skill, not the test." >&2
    exit 1
fi
echo "punch-list-skill: PASS"
