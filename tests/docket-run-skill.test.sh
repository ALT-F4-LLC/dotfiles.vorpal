#!/bin/bash

# Guard suite for the docket-run skill's sandbox-lift rulings.
#
# Defect class: an edit to src/user/claude_code/skills/docket-run/SKILL.md that
# drops the precondition on a sandbox lift, inverts the one paragraph that
# FORBIDS a lift, or adds a brand-new unconditioned lift grant elsewhere in the
# file. No other gate in this repository reads the skill corpus (doc-validate
# scopes to docs/*.md; build, tests and self-hygiene are cargo recipes), so such
# an edit ships green and the next conductor lifts the sandbox on an unverified
# sha, or around a signing failure whose real fix is `just activate`.
#
# Each ruling is anchored to ITS OWN paragraph, never to whole-file text: the
# refusal strings and the word "lifted" occur in several paragraphs, so a
# whole-file grep stays green while the ruling being asserted is gone. A
# paragraph is taken by a literal anchor and refuses unless exactly one
# paragraph carries it, so an anchor that has drifted fails rather than
# silently matching nothing. Paragraphs are flattened to one line before
# matching, so rewrapping the prose is not a failure.
#
# Two properties the assertions below are written for:
#
#   * Each ruling literal carries enough of its own sentence that INVERTING
#     the ruling falsifies it. A bare fragment ("with the sandbox lifted")
#     survives a rewrite that keeps the words and reverses the meaning, so the
#     literals are sentence-sized where the sentence is what rules.
#   * The worktree-cleanup paragraph is section-sized (~400 words, four
#     distinct rulings), so its three lift literals are asserted against the
#     ONE SENTENCE that rules on the hard refusal, not against the paragraph.
#     The `git branch -D` bound is a separate sentence and stays on the
#     paragraph.
#
# (e) is an absence claim and is whole-file by nature: every SENTENCE that
# names a sandbox lift must be one of the three pinned ruling sentences, so a
# newly added grant is red until it is deliberately admitted here — including
# a grant inserted INSIDE one of the three anchored paragraphs, where a
# paragraph-level census would have exempted every sentence in it.
#
# DOCKET_RUN_SKILL_FILE overrides the file under test, so a mutation probe can
# point the suite at a deliberately broken COPY under $TMPDIR without touching
# the checkout. The self-checks always read the repository's own copy, so a
# mutant run does not disturb them. Each assertion's mutant, proven red:
#
#   (s) self-check, proven with copies of THIS SUITE under $TMPDIR
#       s1 states() stubbed to report ok unconditionally, so the built-in
#          broken fixture passes and the self-check must catch it
#       s2 the clean control pointed at the broken fixture
#       s3 paragraph() degraded to whole-file matching (any anchor hit count
#          accepted, extract becomes the whole flat file) against a fixture
#          where a cherry-pick literal is moved into another paragraph —
#          proven caught by the real paragraph(), proven missed by s3's copy
#       s4 sentences() degraded to identity (no splitting) against a fixture
#          where the worktree ruling is inverted and its literal reintroduced
#          as a later sentence of the SAME paragraph — proven caught by the
#          real sentences(), proven missed by s4's copy
#       s5 the census key matched against a string absent from the corpus,
#          against a fixture with a brand-new unanchored lift paragraph —
#          proven caught by the real census, proven missed by s5's copy
#   (a) cherry-pick lift
#       p-a reword the paragraph's anchor sentence, so no paragraph carries
#          it — the census is pinned to the ruling SENTENCE, not the anchor,
#          so p-a/p-b/p-c leave it green; only the paragraph() check reds
#       a1 delete the "Operation not permitted" refusal from the paragraph
#       a2 drop .claude/skills/** from the sentence naming the failing diff
#       a3 delete "Verify the sha as always"
#       a4 replace "this run's steps produced" with "look plausible"
#       a5 delete "retry that pick with the sandbox lifted", leaving the
#          paragraph with no ruling
#   (b) signing, which must NOT be lifted around
#       p-b reword the paragraph's anchor sentence
#       b1 delete the "Couldn't load public key" refusal text
#       b2 delete "need no lift for the signature"
#       b3 invert the ruling to "DO lift the sandbox around it", keeping the
#          words "do not lift the sandbox" elsewhere in the paragraph; this
#          one reds b3's and b4's assertion (b4's literal contains b3's) AND
#          the census, since the mutated sentence still names a lift but no
#          longer equals the pinned sentence
#       b4 detach the remedy: end the `just activate` sentence before the
#          ruling clause, which leaves b3's assertion green
#   (c) worktree-remove lift
#       p-c reword the paragraph's anchor sentence
#       s-c repeat the "A hard ... from the remove" opener in a second
#          sentence of the same paragraph, so no ONE sentence rules
#       c1 delete the "A hard ... from the remove" sentence opener, which
#          leaves no sentence to rule; s-c and c1 are the two directions of
#          the same guard
#       c2 widen the single-call scope: replace "with its paired common-dir
#          write" with "with its paired writes"
#       c3 invert the ruling to "WITHOUT lifting the sandbox", keeping "with
#          the sandbox lifted" elsewhere in the paragraph; also reds the
#          census, since the mutated sentence names a lift but no longer
#          equals the pinned sentence
#       c4 delete the "The lift never extends to the git branch -D" bound
#   (d) module-cache unsandboxed retry
#       p-d reword the paragraph's anchor sentence
#       d1 delete "the unsandboxed retry is the sanctioned path"
#       d2 delete the conductor-only bound ("that retry existing HERE and not
#          in executors")
#   (e) lift census
#       e1 insert a new paragraph granting an unconditioned lift
#       e2 insert the same unconditioned-lift sentence INSIDE one of the
#          three anchored paragraphs, so a paragraph-level census would
#          exempt it; the sentence-level census still reds it
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELF="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
REPO_SKILL="${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/SKILL.md"
SKILL="${DOCKET_RUN_SKILL_FILE:-$REPO_SKILL}"

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

# Every blank-line-delimited paragraph, flattened to one line each. Both the
# paragraph anchors and the census read this, so line wrapping is never what a
# ruling stands or falls on.
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
' "$SKILL" > "${WORK}/flat"

# The one paragraph carrying <anchor>, written to <out>. Returns non-zero
# unless exactly one paragraph carries it: zero means the anchor has drifted
# and every assertion under it would otherwise pass vacuously; more than one
# means the assertions could be met by a paragraph other than the ruling.
paragraph() { # <anchor> <out>
    local hits
    hits=$(grep -cF -- "$1" "${WORK}/flat")
    [ "$hits" -eq 1 ] || return 1
    grep -F -- "$1" "${WORK}/flat" > "$2"
}

# Prose sentences of an already-flattened region, one per line.
sentences() { # <file>
    sed -E 's/([.!?][*`")]*) +/\1\
/g' "$1"
}

# The one sentence of <region-file> carrying <anchor>, written to <out>.
sentence() { # <anchor> <region-file> <out>
    local hits
    sentences "$2" > "${WORK}/sentences"
    hits=$(grep -cF -- "$1" "${WORK}/sentences")
    [ "$hits" -eq 1 ] || return 1
    grep -F -- "$1" "${WORK}/sentences" > "$3"
}

# Assert one literal inside one already-extracted region. A literal that is
# gone from the region but still in the file is a different defect from one
# that is gone altogether, and the message says which.
states() { # <label> <region-file> <literal>
    if grep -qF -- "$3" "$2"; then
        ok "$1"
    elif grep -qF -- "$3" "${WORK}/flat"; then
        bad "$1 — moved out of the ruling's own region, still elsewhere in ${SKILL}: $3"
    else
        bad "$1 — gone from the file: $3"
    fi
}

# (s) The suite's own machinery is re-proven every run: a copy of the
# repository's skill file with one ruling deleted MUST fail, and an untouched
# copy MUST pass. Without this a broken states() stays green forever. Always
# the repository's file, never $SKILL, so a mutation probe does not disturb
# the control.
#
# Three further checks below re-prove paragraph(), sentences(), and the
# census specifically: each degrades ONE helper in a copy of THIS SUITE and
# confirms a fixture built to be caught only by that helper's correct
# behavior slips through the degraded copy. Without these, a broken
# paragraph()/sentences()/census can regress silently — the states()-only
# check above cannot see any of the three.
if [ -z "${DOCKET_RUN_SKILL_INNER:-}" ]; then
    if [ ! -f "$REPO_SKILL" ]; then
        bad "self-check: the repository's own skill file is missing: ${REPO_SKILL}"
    else
        cp "$REPO_SKILL" "${WORK}/self-clean.md"
        sed 's/need no lift for the signature/[ruling deleted]/' \
            "${WORK}/self-clean.md" > "${WORK}/self-broken.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/self-broken.md"; then
            bad "self-check: the built-in mutation did not apply — the control proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/self-broken.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: a copy with its signing ruling deleted still passed the suite"
        else
            ok "self-check: a broken skill copy fails the suite"
        fi

        if DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/self-clean.md" \
            bash "$SELF" >/dev/null 2>&1; then
            ok "self-check: a clean skill copy passes the suite"
        else
            bad "self-check: a clean copy of the repository's skill file does not pass"
        fi

        # A synthetic tree at <dir>/tests/<suite basename> plus
        # <dir>/src/user/claude_code/skills/docket-run/SKILL.md: SELF and
        # REPO_SKILL both resolve off SCRIPT_DIR, so proving a DEGRADED COPY
        # of this suite still (or no longer) catches a mutant needs the copy
        # and the skill file at those same relative paths.
        run_in_tree() { # <suite-script> <skill-copy> <tree-dir>
            mkdir -p "$3/tests" "$3/src/user/claude_code/skills/docket-run"
            cp "$1" "$3/tests/$(basename "$SELF")"
            cp "$2" "$3/src/user/claude_code/skills/docket-run/SKILL.md"
            (cd "$3" && DOCKET_RUN_SKILL_INNER=1 bash "tests/$(basename "$SELF")") \
                >/dev/null 2>&1
        }

        # helper 1: paragraph() degraded to whole-file matching — any anchor
        # hit count is accepted, and the "extract" becomes the whole flat
        # file instead of the one matching paragraph.
        sed '/^paragraph() { # <anchor> <out>$/,/^}$/{
                 s/\[ "\$hits" -eq 1 \] || return 1$/[ "$hits" -ge 1 ] || return 1/;
                 s/grep -F -- "\$1" "\${WORK}\/flat" > "\$2"$/cp "${WORK}\/flat" "$2"/
             }' "$SELF" > "${WORK}/degraded-paragraph.sh"

        # Fixture: delete "Verify the sha as always..." from its own
        # cherry-pick paragraph and reinsert the bare literal, unrelated, next
        # to a DIFFERENT anchored paragraph (module cache). paragraph()'s
        # exact extract no longer carries it; a whole-file "extract" still
        # does.
        sed "s/Verify the sha as always AND that the touched \`.claude\/skills\` paths are ones/Confirm the touched \`.claude\/skills\` paths are ones/;
             s/\*\*Warm the Go module cache before dispatching into a Go repo\.\*\*/Verify the sha as always, a wholly unrelated aside about repository hygiene.\n\n**Warm the Go module cache before dispatching into a Go repo.**/" \
            "${WORK}/self-clean.md" > "${WORK}/paragraph-mutant.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/paragraph-mutant.md"; then
            bad "self-check: the paragraph() fixture's mutation did not apply — proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/paragraph-mutant.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: the paragraph() fixture (moved literal) did not fail the clean suite"
        elif run_in_tree "${WORK}/degraded-paragraph.sh" "${WORK}/paragraph-mutant.md" \
                "${WORK}/tree-paragraph"; then
            ok "self-check: a paragraph() degraded to whole-file matching lets a moved literal pass"
        else
            bad "self-check: a paragraph() degraded to whole-file matching still caught a moved literal — fixture is not load-bearing"
        fi

        # helper 2: sentences() degraded to identity (no splitting), so a
        # whole flattened paragraph reads as one "sentence".
        awk '
            /^sentences\(\) \{ # <file>$/ { print; print "    cat \"$1\""; skip = 1; next }
            skip && /^}$/ { print; skip = 0; next }
            skip { next }
            { print }
        ' "$SELF" > "${WORK}/degraded-sentences.sh"

        # Fixture: invert the worktree-remove ruling sentence to "WITHOUT
        # lifting the sandbox", then reintroduce the untouched literal "and
        # nothing else, with the sandbox lifted" as a LATER sentence in the
        # SAME paragraph. sentence() finds exactly one sentence carrying the
        # anchor, which no longer states the ruling; sentences() degraded to
        # identity treats the paragraph as one sentence, so the reintroduced
        # literal still counts as "in" the anchor sentence and passes.
        awk '
            BEGIN { done = 0 }
            {
                if (!done && $0 == "paired common-dir write and nothing else, with the sandbox lifted instead of") {
                    print "paired common-dir write and nothing else, WITHOUT lifting the sandbox instead of"
                    getline nxt; print nxt
                    getline nxt; print nxt
                    print "Retry that ONE call, the `git worktree remove` with its paired common-dir"
                    print "write and nothing else, with the sandbox lifted."
                    done = 1
                    next
                }
                print
            }
        ' "${WORK}/self-clean.md" > "${WORK}/sentences-mutant.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/sentences-mutant.md"; then
            bad "self-check: the sentences() fixture's mutation did not apply — proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/sentences-mutant.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: the sentences() fixture (inverted worktree ruling) did not fail the clean suite"
        elif run_in_tree "${WORK}/degraded-sentences.sh" "${WORK}/sentences-mutant.md" \
                "${WORK}/tree-sentences"; then
            ok "self-check: a sentences() degraded to identity lets an inverted ruling pass"
        else
            bad "self-check: a sentences() degraded to identity still caught an inverted ruling — fixture is not load-bearing"
        fi

        # helper 3: the census key matched against nothing.
        sed "s/\*'lift the sandbox'\*|\*'sandbox lifted'\*) ;;/*'zzz_no_such_key_zzz'*) ;;/" \
            "$SELF" > "${WORK}/degraded-census.sh"

        # Fixture: a brand-new unconditioned-lift paragraph appended outside
        # all three anchored rulings — the (e) defect class itself. The
        # census catches it by key; a census matched against no key does not.
        cp "${WORK}/self-clean.md" "${WORK}/census-mutant.md"
        printf '\n%s\n' \
            'A future revision may also lift the sandbox for unrelated log noise.' \
            >> "${WORK}/census-mutant.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/census-mutant.md"; then
            bad "self-check: the census fixture's mutation did not apply — proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/census-mutant.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: the census fixture (unanchored grant) did not fail the clean suite"
        elif run_in_tree "${WORK}/degraded-census.sh" "${WORK}/census-mutant.md" \
                "${WORK}/tree-census"; then
            ok "self-check: a census matched against no key lets an unanchored grant pass"
        else
            bad "self-check: a census matched against no key still caught an unanchored grant — fixture is not load-bearing"
        fi
    fi
fi
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
# one: this paragraph is the refusal, not a grant. The ruling literals carry
# their own sentence, so an inversion that keeps the words is red.
if paragraph 'A signed pick or commit signs INSIDE the sandbox' "${WORK}/signing"; then
    ok "signing: exactly one paragraph rules on the signing failure"
    states "signing: states the refusal it answers" \
        "${WORK}/signing" "Couldn't load public key"
    states "signing: signing itself needs no lift" \
        "${WORK}/signing" 'need no lift for the signature'
    states "signing: lifting around the failure is forbidden" \
        "${WORK}/signing" 'do not lift the sandbox around it'
    states "signing: precondition — the operator's just activate is the fix" \
        "${WORK}/signing" 'tell the operator to run `just activate`; do not lift the sandbox around it'
else
    bad "signing: no single paragraph carries 'A signed pick or commit signs INSIDE the sandbox'"
fi

# (c) The worktree-remove lift is scoped to that one call, and stops short of
# `git branch -D`. The paragraph is the whole worktree-cleanup block and rules
# on four separate things, so the lift literals are asserted against the one
# sentence that rules on the hard refusal.
if paragraph 'Worktrees clean themselves up ONLY when UNCHANGED' "${WORK}/worktree"; then
    ok "worktree-remove lift: exactly one paragraph rules on the remove"
    if sentence 'A hard `Operation not permitted` from the remove' \
        "${WORK}/worktree" "${WORK}/worktree-ruling"; then
        ok "worktree-remove lift: exactly one sentence states the refusal it answers"
        states "worktree-remove lift: precondition — single-call scope" \
            "${WORK}/worktree-ruling" 'retry that ONE call, the `git worktree remove` with its paired common-dir write and nothing else'
        states "worktree-remove lift: the ruling is to retry that call lifted" \
            "${WORK}/worktree-ruling" 'and nothing else, with the sandbox lifted'
    else
        bad "worktree-remove lift: no single sentence carries 'A hard \`Operation not permitted\` from the remove'"
    fi
    states "worktree-remove lift: the lift stops short of git branch -D" \
        "${WORK}/worktree" 'The lift never extends to the `git branch -D`'
else
    bad "worktree-remove lift: no single paragraph carries 'Worktrees clean themselves up ONLY when UNCHANGED'"
fi

# (d) The module-cache retry is the fourth relaxation ruling in the file, and
# the only one granted to the conductor alone.
if paragraph 'Warm the Go module cache before dispatching into a Go repo' "${WORK}/modcache"; then
    ok "module cache: exactly one paragraph rules on warming the cache"
    states "module cache: the unsandboxed retry is the sanctioned path" \
        "${WORK}/modcache" 'the unsandboxed retry is the sanctioned path when the sandboxed attempt hits the wall'
    states "module cache: the retry is the conductor's, not an executor's" \
        "${WORK}/modcache" 'that retry existing HERE and not in executors'
else
    bad "module cache: no single paragraph carries 'Warm the Go module cache before dispatching into a Go repo'"
fi

# (e) Absence claim, run over SENTENCES rather than paragraphs: every
# sentence anywhere in the file that names a sandbox lift must be one of the
# three pinned ruling sentences below. A paragraph-level census would exempt
# every sentence in an anchored paragraph, so a new unconditioned grant
# inserted inside one of the three rulings' own paragraphs would stay
# invisible to it; pinning to the sentence catches it wherever it lands.
# The pins are the same literals already asserted by states() above, so the
# census and those assertions cannot drift apart.
sentences "${WORK}/flat" > "${WORK}/all-sentences"
census=0
while IFS= read -r sent; do
    case "$sent" in
        *'lift the sandbox'*|*'sandbox lifted'*) ;;
        *) continue ;;
    esac
    case "$sent" in
        *'retry that pick with the sandbox lifted'*) ;;
        *'do not lift the sandbox around it'*) ;;
        *'and nothing else, with the sandbox lifted'*) ;;
        *)
            bad "lift census: an unpinned sentence rules on a sandbox lift: ${sent:0:140}"
            census=1
            ;;
    esac
done < "${WORK}/all-sentences"
[ "$census" -eq 0 ] && ok "lift census: every sentence naming a sandbox lift is one of the pinned rulings"

if [ "$fail" -ne 0 ]; then
    echo "docket-run-skill: FAIL — a sandbox lift without its precondition is the failure this pins; fix the skill, not the test." >&2
    exit 1
fi
echo "docket-run-skill: PASS"
