#!/bin/bash

# Guard suite for the docket-run skill's three sandbox-lift rulings.
#
# Defect class: an edit to src/user/claude_code/skills/docket-run/SKILL.md that
# drops the precondition on a sandbox lift, or turns the one paragraph that
# FORBIDS a lift into one that allows it. No other gate in this repository
# reads the skill corpus (doc-validate scopes to docs/*.md; build, tests and
# self-hygiene are cargo recipes), so such an edit ships green and the next
# conductor lifts the sandbox on an unverified sha, or around a signing
# failure whose real fix is `just activate`.
#
# Each ruling is anchored to ITS OWN paragraph, never to whole-file text: the
# refusal strings and the word "lifted" occur in several paragraphs, so a
# whole-file grep stays green while the ruling being asserted is gone. A
# paragraph is taken by a literal anchor and refuses unless exactly one
# paragraph carries it, so an anchor that has drifted fails rather than
# silently matching nothing. Paragraphs are flattened to one line before
# matching, so rewrapping the prose is not a failure.
#
# DOCKET_RUN_SKILL_FILE overrides the file under test, so a mutation probe can
# point the suite at a deliberately broken COPY under $TMPDIR without touching
# the checkout. Each assertion's mutant, proven red:
#
#   (a) cherry-pick lift
#       a1 delete the "Operation not permitted" refusal from the paragraph
#       a2 drop .claude/skills/** from the sentence naming the failing diff
#       a3 delete "Verify the sha as always"
#       a4 replace "this run's steps produced" with "look plausible"
#       a5 delete "retry that pick with the sandbox lifted", leaving the
#          paragraph with no ruling
#   (b) signing, which must NOT be lifted around
#       b1 delete the "Couldn't load public key" refusal text
#       b2 delete "need no lift for the signature"
#       b3 turn "do not lift the sandbox" into "lift the sandbox"
#       b4 delete the "just activate" remedy
#   (c) worktree-remove lift
#       c1 delete the "A hard ... from the remove" sentence opener
#       c2 widen the single-call scope: drop "with its paired common-dir
#          write and nothing else"
#       c3 delete "with the sandbox lifted" from the ruling
#       c4 delete the "The lift never extends to the git branch -D" bound
#
# A missing input file fails; it never skips green.

set -uo pipefail

TESTS_DIR_SELF=$(dirname "${BASH_SOURCE[0]}")
SKILL="${DOCKET_RUN_SKILL_FILE:-${TESTS_DIR_SELF}/../src/user/claude_code/skills/docket-run/SKILL.md}"

if [ ! -f "$SKILL" ]; then
    echo "FAIL input: no such file: ${SKILL}" >&2
    echo "docket-run-skill: FAIL" >&2
    exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-run-skill.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

fail=0

ok() {
    echo "ok   $1"
}

bad() {
    echo "FAIL $1"
    fail=1
}

# The one blank-line-delimited paragraph carrying <anchor>, flattened to a
# single line, written to <out>. Exits non-zero unless exactly one paragraph
# carries the anchor: zero means the anchor has drifted and every assertion
# under it would otherwise pass vacuously; more than one means the assertions
# could be met by a paragraph other than the ruling.
paragraph() { # <anchor> <out>
    awk -v anchor="$1" '
        function close_para() {
            if (para != "") {
                if (index(para, anchor)) { hits++; print para }
                para = ""
            }
        }
        /^[[:space:]]*$/ { close_para(); next }
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            para = (para == "" ? line : para " " line)
        }
        END { close_para(); exit (hits == 1) ? 0 : 1 }
    ' "$SKILL" > "$2"
}

# Assert one literal inside one already-extracted paragraph.
states() { # <label> <paragraph-file> <literal>
    if grep -qF -- "$3" "$2"; then
        ok "$1"
    else
        bad "$1 — the paragraph no longer states: $3"
    fi
}

# (a) The cherry-pick lift is conditioned on verifying the sha and on the
# touched skill paths being this run's own output.
if paragraph 'A cherry-pick whose diff touches' "${WORK}/pick"; then
    ok "cherry-pick lift: exactly one paragraph rules on the skills-path pick"
    states "cherry-pick lift: states the refusal it answers" \
        "${WORK}/pick" 'Operation not permitted'
    states "cherry-pick lift: names the diff that provokes it" \
        "${WORK}/pick" '.claude/skills/**'
    states "cherry-pick lift: precondition — the sha is verified" \
        "${WORK}/pick" 'Verify the sha as always'
    states "cherry-pick lift: precondition — the paths are this run's output" \
        "${WORK}/pick" "this run's steps produced"
    states "cherry-pick lift: the ruling is to retry the pick lifted" \
        "${WORK}/pick" 'retry that pick with the sandbox lifted'
else
    bad "cherry-pick lift: no single paragraph carries 'A cherry-pick whose diff touches'"
fi

# (b) Signing needs no lift, and a signing failure must never be answered with
# one: this paragraph is the refusal, not a grant.
if paragraph 'A signed pick or commit signs INSIDE the sandbox' "${WORK}/signing"; then
    ok "signing: exactly one paragraph rules on the signing failure"
    states "signing: states the refusal it answers" \
        "${WORK}/signing" "Couldn't load public key"
    states "signing: signing itself needs no lift" \
        "${WORK}/signing" 'need no lift for the signature'
    states "signing: lifting around the failure is forbidden" \
        "${WORK}/signing" 'do not lift the sandbox'
    states "signing: precondition — the operator's just activate is the fix" \
        "${WORK}/signing" 'just activate'
else
    bad "signing: no single paragraph carries 'A signed pick or commit signs INSIDE the sandbox'"
fi

# (c) The worktree-remove lift is scoped to that one call, and stops short of
# `git branch -D`.
if paragraph 'Worktrees clean themselves up ONLY when UNCHANGED' "${WORK}/worktree"; then
    ok "worktree-remove lift: exactly one paragraph rules on the remove"
    states "worktree-remove lift: states the refusal it answers" \
        "${WORK}/worktree" 'A hard `Operation not permitted` from the remove'
    states "worktree-remove lift: precondition — single-call scope" \
        "${WORK}/worktree" 'retry that ONE call, the `git worktree remove` with its paired common-dir write and nothing else'
    states "worktree-remove lift: the ruling is to retry that call lifted" \
        "${WORK}/worktree" 'with the sandbox lifted'
    states "worktree-remove lift: the lift stops short of git branch -D" \
        "${WORK}/worktree" 'The lift never extends to the `git branch -D`'
else
    bad "worktree-remove lift: no single paragraph carries 'Worktrees clean themselves up ONLY when UNCHANGED'"
fi

if [ "$fail" -ne 0 ]; then
    echo "docket-run-skill: FAIL — a sandbox lift without its precondition is the failure this pins; fix the skill, not the test." >&2
    exit 1
fi
echo "docket-run-skill: PASS"
