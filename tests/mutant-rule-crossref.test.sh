#!/bin/bash

# Guard suite for the mutant-rule cross-reference between docket-groom and
# docket-plan.
#
# Defect class: docket-groom/SKILL.md defers its verification-mutant
# requirement to docket-plan/SKILL.md's own rule rather than restating it, so
# an edit that quietly drops groom's deferral, or that inverts plan's actual
# rule while leaving the surrounding prose untouched, leaves both files
# reading as before to a whole-file grep for "mutant". No other gate in this
# repository reads the skill corpus, and a semantic inversion — replacing the
# obligation with its opposite while keeping the word "mutant" in place — goes
# undetected by a check that only counts occurrences of that word.
#
# Assertions are anchored to each rule's OWN paragraph, never to whole-file
# text: the word "mutant" recurs throughout both files (examples, unrelated
# asides), so a bare `grep -ci mutant <file>` stays green under a semantic
# inversion or a swapped-in unrelated sentence that happens to keep the word.
# Paragraphs are flattened to one line before matching, so rewrapping the
# prose is not a failure.
#
# DOCKET_GROOM_SKILL_FILE and DOCKET_PLAN_SKILL_FILE override the two files
# under test, so a mutation probe can point the suite at deliberately broken
# COPIES under $TMPDIR without touching the checkout. Each assertion's
# mutant, proven red:
#
#   (g) groom's deferral to docket-plan's mutant rule
#       g1 semantic inversion: "must carry the written mutant required by" ->
#          "need not carry a mutant required by"
#       g2 the deferral clause replaced by "A stray note about a mutant
#          elsewhere.", which keeps the word "mutant" in the paragraph
#       g3 delete the read-verified alternative ("must say **read-verified**")
#   (p) plan's own mutant-writing rule
#       p1 semantic inversion: "you record with a command beside it, write
#          down the MUTANT" -> "you record with a command beside it, a
#          mutant need not carry a command"
#       p2 the write-the-mutant clause replaced by "A stray note about a
#          mutant elsewhere.", which keeps the word "mutant" in the paragraph
#       p3 delete the read-verified alternative ("mark it **read-verified**")
#
# `shadow/SKILL.md` no longer carries this rule and is out of scope.
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GROOM_SKILL="${DOCKET_GROOM_SKILL_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-groom/SKILL.md}"
PLAN_SKILL="${DOCKET_PLAN_SKILL_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-plan/SKILL.md}"

if [ ! -f "$GROOM_SKILL" ]; then
    echo "FAIL input: no such file: ${GROOM_SKILL}" >&2
    echo "mutant-rule-crossref: FAIL" >&2
    exit 1
fi
if [ ! -f "$PLAN_SKILL" ]; then
    echo "FAIL input: no such file: ${PLAN_SKILL}" >&2
    echo "mutant-rule-crossref: FAIL" >&2
    exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/mutant-rule-crossref.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

# Every blank-line-delimited paragraph, flattened to one line each, so
# rewrapping the prose is never what an assertion stands or falls on.
flatten() { # <file> <out>
    awk '
        function close_para() {
            if (para != "") { print para; para = "" }
        }
        /^[[:space:]]*$/ { close_para(); next }
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            para = (para == "" ? line : para " " line)
        }
        END { close_para() }
    ' "$1" > "$2"
}

# The one paragraph carrying <anchor>, written to <out>. Returns non-zero
# unless exactly one paragraph carries it: zero means the anchor has drifted,
# and every assertion under it would otherwise pass vacuously; more than one
# means the assertions could be met by a paragraph other than the rule.
paragraph() { # <flat-file> <anchor> <out>
    local hits
    hits=$(grep -cF -- "$2" "$1")
    [ "$hits" -eq 1 ] || return 1
    grep -F -- "$2" "$1" > "$3"
}

# Assert one literal inside one already-extracted region.
states() { # <label> <region-file> <literal>
    if grep -qF -- "$3" "$2"; then
        ok "$1"
    else
        bad "$1 — not found in the rule's own paragraph: $3"
    fi
}

flatten "$GROOM_SKILL" "${WORK}/groom-flat"
flatten "$PLAN_SKILL" "${WORK}/plan-flat"

# (g) docket-groom's deferral to docket-plan's mutant rule.
if paragraph "${WORK}/groom-flat" \
    'Every acceptance criterion, existing or drafted, must meet §2c' \
    "${WORK}/groom-rule"; then
    ok "groom: exactly one paragraph carries the deferral"
    states "groom: must carry the written mutant" \
        "${WORK}/groom-rule" 'must carry the written mutant'
    states "groom: defers to docket-plan's mutant rule by link" \
        "${WORK}/groom-rule" '[docket-plan](../docket-plan/SKILL.md)'
    states "groom: the read-verified alternative" \
        "${WORK}/groom-rule" 'say **read-verified**'
else
    bad "groom: no single paragraph carries 'Every acceptance criterion, existing or drafted, must meet §2c'"
fi

# (p) docket-plan's own mutant-writing rule, which groom defers to.
if paragraph "${WORK}/plan-flat" \
    '**A mechanized check with no written mutant is not mechanized.**' \
    "${WORK}/plan-rule"; then
    ok "plan: exactly one paragraph carries the mutant rule"
    states "plan: write down the MUTANT" \
        "${WORK}/plan-rule" 'write down the MUTANT'
    states "plan: the read-verified alternative" \
        "${WORK}/plan-rule" 'mark it **read-verified**'
else
    bad "plan: no single paragraph carries '**A mechanized check with no written mutant is not mechanized.**'"
fi

if [ "$fail" -ne 0 ]; then
    echo "mutant-rule-crossref: FAIL — groom's deferral and plan's own rule must both state the written-mutant obligation; fix the skill, not the test." >&2
    exit 1
fi
echo "mutant-rule-crossref: PASS"
