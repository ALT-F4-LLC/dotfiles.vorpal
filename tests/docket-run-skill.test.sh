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
#   * The worktree-cleanup paragraph is section-sized (~400 words, several
#     distinct rulings), so its lift literals are asserted against the ONE
#     SENTENCE that rules on the hard refusal, not against the paragraph.
#   * The cherry-pick paragraph carries both the (a) cherry-pick-lift ruling
#     and the (b) signing-refusal ruling; both are asserted against the same
#     paragraph extract rather than two separate ones.
#
# (e) is an absence claim and is whole-file by nature: every SENTENCE that
# names a sandbox lift must be one of the two pinned ruling sentences, so a
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
#   (a) cherry-pick lift (shares its paragraph with (b), signing)
#       p-a reword the paragraph's anchor sentence, so no paragraph carries
#          it — the census is pinned to the ruling SENTENCE, not the anchor,
#          so p-a/p-b/p-c leave it green; only the paragraph() check reds
#       a1 delete the "Operation not permitted" refusal from the paragraph
#       a2 drop .claude/skills/** from the sentence naming the failing diff
#       a3 delete "verify the sha and paths"
#       a4 delete "then retry with the sandbox lifted", leaving the sentence
#          with no ruling
#   (b) signing, which must NOT be lifted around (same paragraph as (a))
#       b1 delete the "missing `agent-signing.pub` key" refusal text
#       b2 delete "tell the operator to run `just activate`"
#       b3 invert the ruling to "DO lift the sandbox around it", keeping the
#          words "lift the sandbox" elsewhere in the paragraph; this reds
#          the census, since the mutated sentence still names a lift but no
#          longer equals the pinned sentence
#   (c) worktree-remove refusal: the metadata delete is harness-denied in
#       every session, creating or later, and is answered with `git
#       update-ref -d` on the prunable entry's branch, never with a lift
#       (the lift is unavailable to a conductor seat; the stale entries are
#       named in the reports for the operator's own prune outside the
#       sandbox)
#       p-c reword the paragraph's anchor sentence
#       s-c repeat the "A hard `Operation not permitted` is the harness"
#          opener in a second sentence of the same paragraph, so no ONE
#          sentence rules
#       c1 delete the "A hard ... is the harness" sentence opener, which
#          leaves no sentence to rule; s-c and c1 are the two directions of
#          the same guard
#       c2 delete "delete the ref directly with `git update-ref -d`"
#       c3 invert the ruling to "retry that one call with the sandbox
#          lifted"; reds the states() check on the ruling sentence and the
#          census both, since the mutated sentence names a lift that no
#          pinned sentence grants
#   (d) module-cache unsandboxed retry
#       p-d reword the paragraph's anchor sentence
#       d1 delete "the unsandboxed retry is sanctioned here because it fills
#          the shared cache every executor reads"
#   (e) lift census
#       e1 insert a new paragraph granting an unconditioned lift
#       e2 insert the same unconditioned-lift sentence INSIDE one of the
#          three anchored paragraphs, so a paragraph-level census would
#          exempt it; the sentence-level census still reds it
#   (f) isolation-unavailable: held, never re-dispatched (f-A is also run
#       by the self-checks on every pass)
#       f-A cut the ruling sentence to "`isolation-unavailable` is re-offered
#          too."
#       f-B delete only the "Hold the row until worktree isolation is
#          restored; ... without isolation." sentence
#       f-C delete "but never re-dispatch on it" from the isolation sentence
#          only; the bootstrap-denied sentence keeps the phrase, which is
#          why the region is two sentences, not the paragraph
#   (g) first-duplicate run note: a machine-caused gate or pre-gate failure
#       found mid-run gets a run note on the first duplicate closed, not
#       dedupe alone, or every later verify-ac step refiles the same gap
#       (g-A is also run by the self-checks on every pass)
#       p-g reword the dedupe paragraph's anchor sentence
#       g-A delete the "On the first duplicate you close ..." sentence,
#          leaving the paragraph with dedupe only
#       g-B move the sentence into the clean-HEAD ruling paragraph above;
#          the literal survives whole-file but leaves the dedupe paragraph
#   (h) harnessCap comes from launches.json, never computed by hand
#       h1 restore "Compute `harnessCap = min(16, that number - 2)`" in the
#          cap paragraph
#       h2 revert either Workflow example to a bare `harnessCap`
#       h3 restore the `getconf _NPROCESSORS_ONLN` probe anywhere in step 2
#   (i) resume-prompt paths: the script in references/pause.md is extracted
#       and run against fixture prompts (DOCKET_RUN_PAUSE_FILE overrides the
#       pause.md under test, as DOCKET_RUN_SKILL_FILE does for SKILL.md)
#       i1 delete the `test -e` refusal from `check` (or make it exit 0); the
#          prompt naming the mistyped incident checkout then exits 0
#       i2 replace the toplevel comparison in `attach` with `true` (or delete
#          the attach branch); the mismatched Checkout then exits 0
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELF="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
REPO_SKILL="${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/SKILL.md"
SKILL="${DOCKET_RUN_SKILL_FILE:-$REPO_SKILL}"
PAUSE="${DOCKET_RUN_PAUSE_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/references/pause.md}"

for input in "$SKILL" "$PAUSE"; do
    if [ ! -f "$input" ]; then
        echo "FAIL input: no such file: ${input}" >&2
        echo "docket-run-skill: FAIL" >&2
        exit 1
    fi
done

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
        sed 's/Never lift the sandbox around this or inspect/[ruling deleted] or inspect/' \
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
            mkdir -p "$3/tests" "$3/src/user/claude_code/skills/docket-run/references"
            cp "$1" "$3/tests/$(basename "$SELF")"
            cp "$2" "$3/src/user/claude_code/skills/docket-run/SKILL.md"
            cp "$PAUSE" "$3/src/user/claude_code/skills/docket-run/references/pause.md"
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

        # Fixture: delete "verify the sha and paths..." from its own
        # cherry-pick/signing paragraph and reinsert the bare literal,
        # unrelated, next to a DIFFERENT anchored paragraph (module cache).
        # paragraph()'s exact extract no longer carries it; a whole-file
        # "extract" still does. The reinserted text is the verbatim admitted
        # census sentence (not a paraphrase), so this fixture isolates the
        # paragraph() defect alone without also tripping the census.
        sed "s/the unlink; verify the sha and paths, then retry with the sandbox lifted\\./the unlink./;
             s/\*\*Warm the Go module cache before dispatching into a Go repo\.\*\*/A wholly unrelated aside about repository hygiene: verify the sha and paths, then retry with the sandbox lifted.\n\n**Warm the Go module cache before dispatching into a Go repo.**/" \
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

        # Fixture: invert the worktree-remove ruling sentence to "retry that
        # one call unsandboxed" (no census key in it, so only sentence-level
        # matching can catch it), then reintroduce the untouched literal "no
        # sandbox lift, no retry, no escalation" as a LATER sentence
        # in the SAME paragraph. sentence() finds exactly one sentence
        # carrying the anchor ("A hard `Operation not permitted` is the
        # harness"), which after inversion no longer states the ruling;
        # sentences() degraded to identity treats the whole paragraph as one
        # "sentence", so the reintroduced literal still counts as "in" the
        # anchor sentence and the pinned states() check passes regardless of
        # the inversion. The prose wraps mid-clause in the source, so the
        # pattern tolerates `\s+` wherever the file may break a line.
        perl -0pe 's/(A hard `Operation not permitted` is the\s+harness, not a lift case: )no sandbox lift, no retry, no escalation,(\s+since)/$1retry that one call unsandboxed, contradicting the real ruling,$2/s; s/(neither\s+unlinkable nor renamable\.)(\s+The\s+working directory)/$1 The old wording was: no sandbox lift, no retry, no escalation.$2/s' \
            "${WORK}/self-clean.md" > "${WORK}/sentences-mutant.md"

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

        # The isolation-unavailable ruling cut to its bare status name
        # (mutant A) must fail the suite.
        perl -0pe 's/(`isolation-unavailable` is re-offered too), but never re-dispatch on it:.*?unguarded in the shared checkout\./$1./s' \
            "${WORK}/self-clean.md" > "${WORK}/isolation-mutant.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/isolation-mutant.md"; then
            bad "self-check: the isolation-unavailable mutation did not apply — proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/isolation-mutant.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: an isolation-unavailable ruling cut to its status name still passed the suite"
        else
            ok "self-check: an isolation-unavailable ruling cut to its status name fails the suite"
        fi

        # The first-duplicate run-note sentence deleted from the dedupe
        # paragraph (mutant g-A) must fail the suite.
        perl -0pe 's/ On the first duplicate you close for a\s+machine-caused gate or pre-gate failure discovered mid-run,.*?refiles the same gap\.//s' \
            "${WORK}/self-clean.md" > "${WORK}/first-dup-mutant.md"

        if cmp -s "${WORK}/self-clean.md" "${WORK}/first-dup-mutant.md"; then
            bad "self-check: the first-duplicate note mutation did not apply — proves nothing"
        elif DOCKET_RUN_SKILL_INNER=1 DOCKET_RUN_SKILL_FILE="${WORK}/first-dup-mutant.md" \
            bash "$SELF" >/dev/null 2>&1; then
            bad "self-check: a dedupe paragraph without the first-duplicate note sentence still passed the suite"
        else
            ok "self-check: a dedupe paragraph without the first-duplicate note sentence fails the suite"
        fi
    fi
fi
# (a) The cherry-pick lift is conditioned on verifying the sha and paths, and
# a signing failure in the same paragraph must never be answered with a lift.
if paragraph 'A cherry-pick touching `.claude/skills/**` can fail under the sandbox' "${WORK}/pick"; then
    ok "cherry-pick lift: exactly one paragraph rules on the skills-path pick and signing"
    states "cherry-pick lift: states the refusal it answers" \
        "${WORK}/pick" 'fail under the sandbox on the unlink'
    states "cherry-pick lift: names the diff that provokes it" \
        "${WORK}/pick" '.claude/skills/**'
    states "cherry-pick lift: precondition — the sha and paths are verified" \
        "${WORK}/pick" 'verify the sha and paths'
    states "cherry-pick lift: the ruling is to retry the pick lifted" \
        "${WORK}/pick" 'then retry with the sandbox lifted'
else
    bad "cherry-pick lift: no single paragraph carries 'A cherry-pick touching \`.claude/skills/**\` can fail under the sandbox'"
fi

# (b) Signing needs no lift, and a signing failure must never be answered with
# one: this is a refusal, not a grant. The ruling literal carries its own
# sentence, so an inversion that keeps the words is red.
if paragraph 'A cherry-pick touching `.claude/skills/**` can fail under the sandbox' "${WORK}/signing"; then
    ok "signing: exactly one paragraph rules on the signing failure"
    states "signing: states the refusal it answers" \
        "${WORK}/signing" "missing \`agent-signing.pub\` key"
    states "signing: precondition — the operator's just activate is the fix" \
        "${WORK}/signing" 'tell the operator to'
    states "signing: lifting around the failure is forbidden" \
        "${WORK}/signing" 'Never lift the sandbox around this'
else
    bad "signing: no single paragraph carries 'A cherry-pick touching \`.claude/skills/**\` can fail under the sandbox'"
fi

# (c) The worktree-remove refusal is never answered with a lift: the harness
# denies that metadata directory in every session, the lift is unavailable
# to a conductor seat, the branch is deleted by ref on the prunable entry
# instead, and the stale entry is named for the operator's prune outside the
# sandbox. The paragraph is the whole
# worktree-cleanup block and rules on several separate things, so the ruling
# is asserted against the one sentence that rules on the hard refusal, and
# the mechanism against the paragraph.
if paragraph 'Worktrees clean themselves up only when unchanged' "${WORK}/worktree"; then
    ok "worktree-remove refusal: exactly one paragraph rules on the remove"
    if sentence 'A hard `Operation not permitted` is the harness' \
        "${WORK}/worktree" "${WORK}/worktree-ruling"; then
        ok "worktree-remove refusal: exactly one sentence states the refusal it answers"
        states "worktree-remove refusal: no lift, no retry, no escalation" \
            "${WORK}/worktree-ruling" 'no sandbox lift, no retry, no escalation'
        states "worktree-remove refusal: the deny holds for later sessions too" \
            "${WORK}/worktree-ruling" 'in later ones that never created it'
        states "worktree-remove refusal: the branch is deleted by ref instead" \
            "${WORK}/worktree" 'delete the ref directly with `git update-ref -d`'
        states "worktree-remove refusal: precondition — the entry reads prunable" \
            "${WORK}/worktree" 'only once the entry reads `prunable`'
    else
        bad "worktree-remove refusal: no single sentence carries 'A hard \`Operation not permitted\` is the harness'"
    fi
else
    bad "worktree-remove refusal: no single paragraph carries 'Worktrees clean themselves up only when unchanged'"
fi
# The stale entry left behind is the operator's to prune outside the
# sandbox; no session, this one or a later one, is told it clears it.
if paragraph 'The stale metadata directory is inert' "${WORK}/stale-entry"; then
    ok "stale entry: exactly one paragraph rules on the leftover metadata directory"
    states "stale entry: the operator prunes it outside the sandbox" \
        "${WORK}/stale-entry" 'stays until the operator prunes it outside the sandbox'
    states "stale entry: no later session clears it" \
        "${WORK}/stale-entry" 'no later session clears it'
    states "stale entry: named in the close report" \
        "${WORK}/stale-entry" 'in the close report'
else
    bad "stale entry: no single paragraph carries 'The stale metadata directory is inert'"
fi

# (d) The module-cache retry is the fourth relaxation ruling in the file, and
# the only one granted to the conductor alone (dispatched before any executor
# exists, so no executor-side equivalent could apply).
if paragraph 'Warm the Go module cache before dispatching into a Go repo' "${WORK}/modcache"; then
    ok "module cache: exactly one paragraph rules on warming the cache"
    states "module cache: the unsandboxed retry is sanctioned here" \
        "${WORK}/modcache" 'the unsandboxed retry is sanctioned here because it fills the shared cache every executor reads'
else
    bad "module cache: no single paragraph carries 'Warm the Go module cache before dispatching into a Go repo'"
fi

# (f) An isolation-unavailable row is held, never re-dispatched into broken
# isolation. The region is the anchor sentence plus the one after it, not the
# paragraph: the bootstrap-denied sentence in the same paragraph also says
# "never re-dispatch on it", so a paragraph region stays green when this
# sentence loses it.
isolation_anchor='`isolation-unavailable` is re-offered too'
sentences "${WORK}/flat" > "${WORK}/isolation-sentences"
if [ "$(grep -cF -- "$isolation_anchor" "${WORK}/isolation-sentences")" -eq 1 ]; then
    grep -A1 -F -- "$isolation_anchor" "${WORK}/isolation-sentences" > "${WORK}/isolation"
    ok "isolation-unavailable: exactly one sentence rules on the status"
    states "isolation-unavailable: never re-dispatched" \
        "${WORK}/isolation" 'never re-dispatch on it'
    states "isolation-unavailable: held until isolation is restored" \
        "${WORK}/isolation" 'Hold the row until worktree isolation is restored'
    states "isolation-unavailable: the writer never relaunches unguarded" \
        "${WORK}/isolation" 'never relaunching the writer without isolation'
else
    bad "isolation-unavailable: no single sentence carries '${isolation_anchor}'"
fi

# (g) A machine-caused gate or pre-gate failure discovered mid-run gets a run
# note on the first duplicate closed, so later packets carry the tracking
# issue instead of refiling the gap. The sentence is asserted against the
# dedupe paragraph, not the clean-HEAD ruling paragraph above it: the
# clean-HEAD paragraph already prescribes a note, so a whole-file grep would
# stay green with the mid-run rule gone.
if paragraph 'A note reaches only packets rendered after it lands' "${WORK}/dedupe"; then
    ok "first-duplicate note: exactly one paragraph rules on dedupe after a note"
    states "first-duplicate note: the first duplicate closed lands a run note" \
        "${WORK}/dedupe" 'On the first duplicate you close for a machine-caused gate or pre-gate failure discovered mid-run, land a run note naming the tracking issue and the disposition before the next `dispatch open`'
    states "first-duplicate note: the note takes the clean-HEAD ruling form" \
        "${WORK}/dedupe" 'in the same form as the clean-HEAD ruling above'
else
    bad "first-duplicate note: no single paragraph carries 'A note reaches only packets rendered after it lands'"
fi

# (h) harnessCap has one source: lane_units.py writes it into launches.json
# and the conductor passes it through. A hand-computed figure drifted in past
# runs (1000 was passed as the cap), so step 2 must name launches.json as the
# source and carry no formula, CPU probe, or literal of its own.
if paragraph 'wave.js uses `min(HARNESS_CAP, harnessCap)` as its own' "${WORK}/harness-cap"; then
    ok "harnessCap: exactly one paragraph rules on the cap"
    states "harnessCap: each launch passes the launches.json figure" \
        "${WORK}/harness-cap" "pass entry i's \`harnessCap\` from launches.json"
    states "harnessCap: launch 0 example reads launches.json" \
        "${WORK}/flat" 'harnessCap: <launches.json[0].harnessCap>'
    states "harnessCap: launch 1 example reads launches.json" \
        "${WORK}/flat" 'harnessCap: <launches.json[1].harnessCap>'
    awk '/^### 2\. /{on=1; next} /^### 3\. /{on=0} on' "$SKILL" > "${WORK}/step-2"
    if [ ! -s "${WORK}/step-2" ]; then
        bad "harnessCap: the step-2 section heading has drifted; nothing extracted"
    elif grep -qE -- 'Compute `harnessCap`|that number - 2|getconf|harnessCap: 1000' "${WORK}/step-2"; then
        bad "harnessCap: step 2 still computes the cap or passes a literal: $(grep -E -- 'Compute `harnessCap`|that number - 2|getconf|harnessCap: 1000' "${WORK}/step-2" | head -1)"
    else
        ok "harnessCap: step 2 carries no formula, CPU probe, or literal cap"
    fi
else
    bad "harnessCap: no single paragraph carries 'wave.js uses \`min(HARNESS_CAP, harnessCap)\` as its own'"
fi

# (e) Absence claim, run over SENTENCES rather than paragraphs: every
# sentence anywhere in the file that names a sandbox lift must be one of the
# two pinned ruling sentences below. A paragraph-level census would exempt
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
        *'then retry with the sandbox lifted.'*) ;;
        *'Never lift the sandbox around this or inspect'*) ;;
        *)
            bad "lift census: an unpinned sentence rules on a sandbox lift: ${sent:0:140}"
            census=1
            ;;
    esac
done < "${WORK}/all-sentences"
[ "$census" -eq 0 ] && ok "lift census: every sentence naming a sandbox lift is one of the pinned rulings"

# (i) The resume prompt's paths come from git and are checked before the
# prompt is recorded and again at attach. The script is taken from the one
# fenced block in pause.md carrying its usage line and run as the conductor
# runs it, against fixture prompts.
paths_usage='# resume-prompt-paths: print | check <prompt-file> | attach <prompt-file>'
paths="${WORK}/paths"
mkdir -p "${paths}/checkout" "${paths}/worktree" "${paths}/other" "${paths}/repo"
if awk -v usage="$paths_usage" '
        /^```/ {
            if (open) { if (found) { printf "%s", block; n++ }; open = 0; found = 0; block = "" }
            else open = 1
            next
        }
        open { block = block $0 "\n"; if ($0 == usage) found = 1 }
        END { exit n == 1 ? 0 : 1 }
    ' "$PAUSE" > "${paths}/resume-prompt-paths.sh"; then
    ok "resume-prompt paths: exactly one fenced block in pause.md carries the script"

    incident='/Users/erikreinert/Development/repository/github.com/ALT-F-LLC/dotfiles.vorpal.git/main'
    printf '# Resume RUN-1\n\n**Checkout:** `%s`\n**Branch:** `main`\n' "$incident" \
        > "${paths}/typo.md"
    bash "${paths}/resume-prompt-paths.sh" check "${paths}/typo.md" \
        >/dev/null 2>"${paths}/typo.err"
    rc=$?
    if [ "$rc" -eq 1 ] && grep -qF -- "**Checkout:** \`${incident}\`" "${paths}/typo.err"; then
        ok "resume-prompt paths: check refuses a Checkout that does not exist, quoting the line"
    else
        bad "resume-prompt paths: check on the mistyped incident Checkout exited ${rc} without quoting the line: $(head -c 300 "${paths}/typo.err")"
    fi

    printf '**Checkout:** `%s`\n**Branch:** `main`\n**Worktree:** `%s`\n' \
        "${paths}/checkout" "${paths}/worktree" > "${paths}/good.md"
    if bash "${paths}/resume-prompt-paths.sh" check "${paths}/good.md" >/dev/null 2>&1; then
        ok "resume-prompt paths: check passes a prompt whose paths exist"
    else
        bad "resume-prompt paths: check refused a prompt whose Checkout and worktree exist"
    fi

    # A throwaway repo with one commit, isolated from the host's git config so
    # nothing outside the fixture shapes HEAD or the commit.
    if (cd "${paths}/repo" &&
        export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 &&
        git init -q &&
        git -c user.name=fixture -c user.email=fixture@example.invalid \
            commit -q --allow-empty -m fixture) >/dev/null 2>&1; then
        if (cd "${paths}/repo" && bash "${paths}/resume-prompt-paths.sh" print) \
                > "${paths}/printed.md" 2>/dev/null &&
            (cd "${paths}/repo" &&
                bash "${paths}/resume-prompt-paths.sh" attach "${paths}/printed.md") \
                >/dev/null 2>&1; then
            ok "resume-prompt paths: attach accepts the Checkout print wrote from the same checkout"
        else
            bad "resume-prompt paths: print's own Checkout line failed attach in the checkout it came from"
        fi

        printf '**Checkout:** `%s`\n**Branch:** `main`\n' "${paths}/other" > "${paths}/elsewhere.md"
        (cd "${paths}/repo" &&
            bash "${paths}/resume-prompt-paths.sh" attach "${paths}/elsewhere.md") \
            >/dev/null 2>"${paths}/elsewhere.err"
        rc=$?
        repo_top=$(cd "${paths}/repo" && git rev-parse --show-toplevel)
        if [ "$rc" -eq 1 ] && grep -qF -- "${paths}/other" "${paths}/elsewhere.err" &&
            grep -qF -- "$repo_top" "${paths}/elsewhere.err"; then
            ok "resume-prompt paths: attach refuses a Checkout other than this toplevel, naming both"
        else
            bad "resume-prompt paths: attach on a mismatched Checkout exited ${rc}: $(head -c 300 "${paths}/elsewhere.err")"
        fi
    else
        bad "resume-prompt paths: could not create the fixture git repository"
    fi
else
    bad "resume-prompt paths: no single fenced block in ${PAUSE} carries '${paths_usage}'"
fi

# (j) The dispatch idle watcher runs under zsh, which is what the Bash tool
# runs. zsh does not word-split an unquoted parameter, so a space-joined
# directory list reached find as one missing path and the watcher never
# fired. The block between its begin and end anchors is extracted from
# SKILL.md, its two directory placeholders are substituted, and it is run
# under zsh against fixture transcripts with a stub docket on PATH. Each run
# is bounded by a portable wall-clock kill (no timeout binary): a watchdog
# sleeps the bound, then kills the run; the case fails when it fires. A
# missing zsh fails, never skips: CI must exercise the zsh defect.
#
#   j1 restore DIRS="<transcript-dir-0> <transcript-dir-1>"; for DIR in $DIRS
#      (find gets one joined path, no IDLE prints, the 120 s kill fires)
#   j2 delete the directory-existence check (find errors on the missing dir,
#      the loop keeps sleeping, the 90 s kill fires)
bounded_run() { # <seconds> <out> <script> <dir-0> <dir-1>; sets b_rc, b_secs, b_fired
    local secs=$1 out=$2 script=$3 zpid wpid start=$SECONDS
    rm -f "${WORK}/watchdog-fired"
    sed -e "s|<transcript-dir-0>|$4|g" -e "s|<transcript-dir-1>|$5|g" \
        "$script" > "${script}.run"
    PATH="${WORK}/watcher-bin:$PATH" zsh "${script}.run" > "$out" 2>&1 &
    zpid=$!
    (
        trap 'kill "$sp" 2>/dev/null; exit 0' TERM
        sleep "$secs" & sp=$!
        wait "$sp"
        kill "$zpid" 2>/dev/null && touch "${WORK}/watchdog-fired"
    ) >/dev/null 2>&1 &
    wpid=$!
    wait "$zpid"
    b_rc=$?
    b_secs=$((SECONDS - start))
    kill "$wpid" 2>/dev/null
    wait "$wpid" 2>/dev/null
    b_fired=0
    [ -e "${WORK}/watchdog-fired" ] && b_fired=1
}

watcher="${WORK}/watcher.zsh"
sed -n '/^# dispatch-watcher: begin$/,/^# dispatch-watcher: end$/p' "$SKILL" > "$watcher"
if [ "$(grep -cE '^# dispatch-watcher: (begin|end)$' "$watcher")" -ne 2 ]; then
    bad "dispatch watcher: no block between '# dispatch-watcher: begin' and '# dispatch-watcher: end' in ${SKILL}"
elif ! command -v zsh >/dev/null 2>&1; then
    bad "dispatch watcher: zsh is not on PATH; the zsh cases cannot run and do not skip"
else
    ok "dispatch watcher: the block is extracted between its anchors"
    mkdir -p "${WORK}/watcher-bin" "${WORK}/wdir-0" "${WORK}/wdir-1"
    printf '#!/bin/sh\n[ "$1 $2 $3" = "step show STEP-1" ] && echo "  status:    claimed"\nexit 0\n' \
        > "${WORK}/watcher-bin/docket"
    chmod +x "${WORK}/watcher-bin/docket"
    printf '{"type":"assistant","text":"docket step claim STEP-1"}\n' \
        > "${WORK}/wdir-1/agent-idle1.jsonl"
    printf '{"agent":"idle1","event":"started"}\n' > "${WORK}/wdir-1/journal.jsonl"
    touch -t "$(date -r "$(( $(date +%s) - 960 ))" +%Y%m%d%H%M.%S 2>/dev/null ||
        date -d "@$(( $(date +%s) - 960 ))" +%Y%m%d%H%M.%S)" "${WORK}/wdir-1/agent-idle1.jsonl"

    bounded_run 120 "${WORK}/watcher-idle.out" "$watcher" "${WORK}/wdir-0" "${WORK}/wdir-1"
    if [ "$b_fired" -eq 1 ]; then
        bad "dispatch watcher: no IDLE line within 120 s under zsh with two dirs (killed): $(head -c 300 "${WORK}/watcher-idle.out")"
    elif grep -q '^IDLE STEP-1' "${WORK}/watcher-idle.out"; then
        ok "dispatch watcher: under zsh with two dirs, a 16-minute-idle claimed agent prints IDLE STEP-1"
    else
        bad "dispatch watcher: exited ${b_rc} without an IDLE STEP-1 line: $(head -c 300 "${WORK}/watcher-idle.out")"
    fi

    bounded_run 90 "${WORK}/watcher-missing.out" "$watcher" "${WORK}/wdir-0" "${WORK}/wdir-missing"
    if [ "$b_fired" -eq 1 ]; then
        bad "dispatch watcher: a missing dir did not stop the watcher within 90 s (killed): $(head -c 300 "${WORK}/watcher-missing.out")"
    elif [ "$b_rc" -eq 2 ] && [ "$b_secs" -lt 60 ] &&
        [ "$(grep '^WATCHER-ERROR ' "${WORK}/watcher-missing.out")" = "WATCHER-ERROR ${WORK}/wdir-missing" ]; then
        ok "dispatch watcher: a missing dir prints WATCHER-ERROR naming it and exits 2 before the first sleep"
    else
        bad "dispatch watcher: a missing dir exited ${b_rc} after ${b_secs} s:$(head -c 300 "${WORK}/watcher-missing.out")"
    fi
fi

if [ "$fail" -ne 0 ]; then
    echo "docket-run-skill: FAIL — a sandbox lift without its precondition is the failure this pins; fix the skill, not the test." >&2
    exit 1
fi
echo "docket-run-skill: PASS"
