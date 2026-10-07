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
#   (h) harnessCap and every other launch arg come from lane_units.py's
#       generated args-<i>.json, never computed or re-typed by hand
#       h1 restore "Compute `harnessCap = min(16, that number - 2)`" in the
#          cap paragraph
#       h2 revert either Workflow example to an inline args object
#       h4 restore `rows: <launch-0 rows>` in the first example line; the
#          example paragraph's negative assertion goes red
#       h3 restore the `getconf _NPROCESSORS_ONLN` probe anywhere in step 2
#   (i) resume-prompt paths: the shipped scripts/resume-prompt-paths.sh is
#       run against fixture prompts (DOCKET_RUN_PATHS_SCRIPT overrides the
#       script under test, as DOCKET_RUN_SKILL_FILE does for SKILL.md)
#       i0 delete or rename the shipped script; case (i) fails
#       i1 delete the `test -e` refusal from `check` (or make it exit 0); the
#          prompt naming the mistyped incident checkout then exits 0
#       i2 replace the toplevel comparison in `attach` with `true` (or delete
#          the attach branch); the mismatched Checkout then exits 0
#       i3 make `print` emit every porcelain entry again (drop its prunable
#          skip); the removed ../wt worktree reaches the round-trip prompt
#          and check exits 1 on it
#       i4 make `print` emit no linked-worktree lines; the live ../live
#          worktree's Worktree line is missing from print's output
#   (n) pause.md runs the installed resume-prompt-paths script and carries
#       no copy of it
#       n1 the record step names `<scratchpad>/resume-prompt-paths.sh` again;
#          the negative assertion fails
#       n2 the attach step drops the installed invocation; the mode count is
#          2 and the positive assertion fails
#       n3 restore the fenced script block in pause.md; the inline-copy
#          assertion fails
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SELF="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
REPO_SKILL="${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/SKILL.md"
SKILL="${DOCKET_RUN_SKILL_FILE:-$REPO_SKILL}"
PAUSE="${DOCKET_RUN_PAUSE_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/references/pause.md}"
PATHS_SCRIPT="${DOCKET_RUN_PATHS_SCRIPT:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/scripts/resume-prompt-paths.sh}"

ESCALATION="${DOCKET_RUN_ESCALATION_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/references/escalation.md}"

for input in "$SKILL" "$PAUSE" "$ESCALATION"; do
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
            mkdir -p "$3/tests" "$3/src/user/claude_code/skills/docket-run/references" \
                "$3/src/user/claude_code/skills/docket-run/scripts"
            cp "$1" "$3/tests/$(basename "$SELF")"
            cp "$2" "$3/src/user/claude_code/skills/docket-run/SKILL.md"
            cp "$PAUSE" "$3/src/user/claude_code/skills/docket-run/references/pause.md"
            cp "$PATHS_SCRIPT" "$3/src/user/claude_code/skills/docket-run/scripts/resume-prompt-paths.sh"
            cp "$ESCALATION" "$3/src/user/claude_code/skills/docket-run/references/escalation.md"
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
    states "signing: the conductor pauses the run before the operator activates" \
        "${WORK}/signing" 'pause the run with `/docket-run pause`'
    states "signing: the operator runs plain just activate" \
        "${WORK}/signing" 'run plain `just activate`'
    # Read from the anchor's own flat line, so the self-checks' degraded
    # paragraph() copy (whole-file extract) stays green on a clean file.
    grep -F -- 'A cherry-pick touching `.claude/skills/**` can fail under the sandbox' \
        "${WORK}/signing" > "${WORK}/signing-line"
    if grep -qF -- 'force' "${WORK}/signing-line"; then
        bad "signing: the carve-out paragraph names force"
    else
        ok "signing: the carve-out paragraph never names force"
    fi
else
    bad "signing: no single paragraph carries 'A cherry-pick touching \`.claude/skills/**\` can fail under the sandbox'"
fi

# (p) An operator escalation never offers activation while any run is
# non-terminal; the signing carve-out above is its one exception. The region
# is the section from `### Escalating to the operator` to the next `### `
# heading, flattened.
#
#   p1 delete the never-offers sentence
#   p2 drop `paused` from its status list
#   p3 drop the `just activate force=1` form
#   p4 reword it to "may offer activation once the run is paused"
#   p5 delete the exception sentence
#   p6 restore the carve-out paragraph as at 233a3175 (no pause step, bare
#      `just activate` mid-run; checked under (b) above)
sed -n '/^### Escalating to the operator$/,/^### /p' "$SKILL" | sed '$d' | tr '\n' ' ' \
    > "${WORK}/escalating"
activate_rule='An operator escalation never offers `just activate` or `just activate force=1` as a remedy while any run is non-terminal'
if ! grep -qF -- '### Escalating to the operator' "${WORK}/escalating"; then
    bad "no activation offer: no '### Escalating to the operator' section in ${SKILL}"
elif sentence "$activate_rule" "${WORK}/escalating" "${WORK}/activate-rule"; then
    ok "no activation offer: one sentence of the escalation section carries the rule"
    for lit in '`just activate`' 'force=1' '`planning`' '`active`' '`paused`' '`waiting-human`'; do
        states "no activation offer: the rule names ${lit}" "${WORK}/activate-rule" "$lit"
    done
    states "no activation offer: the signing carve-out is the one exception" \
        "${WORK}/escalating" 'The one exception is the signing-key carve-out'
    # Every other sentence naming activation beside a paused or waiting-human
    # run is a permission the rule forbids. Matched by containment, so the
    # self-checks' degraded sentences() copy stays green on a clean file.
    sentences "${WORK}/escalating" | grep -i 'activat' | grep -E 'paused|waiting-human' |
        grep -vF -- "$activate_rule" > "${WORK}/activate-offers"
    if [ -s "${WORK}/activate-offers" ]; then
        bad "no activation offer: another sentence permits activation on a paused or waiting-human run: $(head -c 300 "${WORK}/activate-offers")"
    else
        ok "no activation offer: no other sentence permits activation on a paused or waiting-human run"
    fi
else
    bad "no activation offer: no single sentence of the escalation section carries '${activate_rule}'"
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

# (h) harnessCap has one source: lane_units.py writes it into each launch's
# generated args object, and the conductor passes that object unedited. A
# hand-computed figure drifted in past runs (1000 was passed as the cap), so
# step 2 must name the generated args as the source and carry no formula, CPU
# probe, or literal of its own. The launch example passes args-<i>.json whole:
# an inline object re-emits every row and hand-types cwd through model output.
if paragraph 'wave.js uses `min(HARNESS_CAP, harnessCap)` as its own' "${WORK}/harness-cap"; then
    ok "harnessCap: exactly one paragraph rules on the cap"
    states "harnessCap: each launch passes the generated args figure" \
        "${WORK}/harness-cap" "launch i's \`harnessCap\` reaches wave.js inside \`args-<i>.json\`"
    if paragraph 'Workflow({ scriptPath: "<absolute installed path to wave.js>"' "${WORK}/launch-example"; then
        states "launch example: launch 0 passes the generated args object" \
            "${WORK}/launch-example" 'args: <$LAUNCH_DIR/args-0.json, the generated args object, unedited>'
        states "launch example: launch 1 passes the generated args object" \
            "${WORK}/launch-example" 'args: <$LAUNCH_DIR/args-1.json, the generated args object, unedited>'
        if grep -qF -- 'rows: <launch-' "${WORK}/launch-example"; then
            bad "launch example: still passes rows inline: rows: <launch-"
        else
            ok "launch example: no inline rows: <launch-"
        fi
    else
        bad "launch example: no single paragraph carries the wave.js Workflow launch example"
    fi
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
# prompt is recorded and again at attach. The shipped script, the file the
# skills install puts at ~/.claude/skills/docket-run/scripts, is copied and
# run as the conductor runs it, against fixture prompts.
paths="${WORK}/paths"
mkdir -p "${paths}/checkout" "${paths}/worktree" "${paths}/other" "${paths}/repo"
if [ -f "$PATHS_SCRIPT" ] && cp "$PATHS_SCRIPT" "${paths}/resume-prompt-paths.sh"; then
    ok "resume-prompt paths: the shipped resume-prompt-paths.sh exists"

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

        # Round trip: print's output from the main checkout must pass check.
        # ../wt is added and its directory removed, so the porcelain list
        # marks it prunable (as a sandboxed `git worktree remove` leaves it);
        # ../live is added and left in place.
        fixture_parent=$(dirname "$repo_top")
        if (cd "${paths}/repo" &&
            export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 &&
            git worktree add -q ../wt &&
            git worktree add -q ../live &&
            rm -rf ../wt &&
            git worktree list --porcelain | grep -q '^prunable') >/dev/null 2>&1; then
            (cd "${paths}/repo" && bash "${paths}/resume-prompt-paths.sh" print) \
                > "${paths}/roundtrip.md" 2>/dev/null
            if ! grep -qF -- "${fixture_parent}/wt" "${paths}/roundtrip.md" &&
                bash "${paths}/resume-prompt-paths.sh" check "${paths}/roundtrip.md" \
                    >/dev/null 2>"${paths}/roundtrip.err"; then
                ok "resume-prompt paths: print skips a prunable worktree and check passes its output"
            else
                bad "resume-prompt paths: print's output named the removed worktree or failed check: $(head -c 300 "${paths}/roundtrip.err")"
            fi
            if grep -qF -- "**Worktree:** \`${fixture_parent}/live\`" "${paths}/roundtrip.md"; then
                ok "resume-prompt paths: print keeps a live linked worktree"
            else
                bad "resume-prompt paths: print's output has no Worktree line for ${fixture_parent}/live: $(head -c 300 "${paths}/roundtrip.md")"
            fi
        else
            bad "resume-prompt paths: could not build the prunable and live worktree fixture"
        fi
    else
        bad "resume-prompt paths: could not create the fixture git repository"
    fi
else
    bad "resume-prompt paths: the shipped script is missing: ${PATHS_SCRIPT}"
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
#   j3 delete the interrupted-tail check line (the fresh interrupted seat
#      prints no STALLED line and the 10 s kill fires)
#   j4 match any tool_result tail in that check (the fresh seat whose tail is
#      an ordinary tool_result prints STALLED)
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
    wait "$zpid" 2>/dev/null
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
    printf '#!/bin/sh\n[ "$1 $2" = "step show" ] && echo "  status:    claimed"\nexit 0\n' \
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

    # Two fresh transcripts, identical but for their last two records. The
    # interrupted tail copies its shape from RUN-125's seat transcript
    # agent-ac2b6ee7805a1bbe6.jsonl:171 (the user-rejected tool_result) and
    # :172 (the interrupt record Claude Code writes after it), trimmed to the
    # fields the watcher reads. The ordinary tail is a plain tool_result.
    mkdir -p "${WORK}/wdir-stalled" "${WORK}/wdir-ordinary"
    for d in stalled ordinary; do
        printf '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_f","name":"Bash","input":{"command":"docket step claim STEP-2"}}]}}\n' \
            > "${WORK}/wdir-${d}/agent-${d}2.jsonl"
        printf '{"agent":"%s2","event":"started"}\n' "$d" > "${WORK}/wdir-${d}/journal.jsonl"
    done
    printf '%s\n' \
        '{"isSidechain":true,"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"The user doesn'"'"'t want to proceed with this tool use. The tool use was rejected (eg. if it was a file edit, the new_string was NOT written to the file). STOP what you are doing and wait for the user to tell you how to proceed.","is_error":true,"tool_use_id":"toolu_f"}]},"toolUseResult":"User rejected tool use","toolDenialKind":"user-rejected"}' \
        '{"isSidechain":true,"type":"user","message":{"role":"user","content":[{"type":"text","text":"[Request interrupted by user for tool use]"}]}}' \
        >> "${WORK}/wdir-stalled/agent-stalled2.jsonl"
    printf '%s\n' \
        '{"isSidechain":true,"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"ok","is_error":false,"tool_use_id":"toolu_f"}]},"toolUseResult":{"stdout":"ok"}}' \
        '{"isSidechain":true,"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"running the next check"}]}}' \
        >> "${WORK}/wdir-ordinary/agent-ordinary2.jsonl"

    bounded_run 10 "${WORK}/watcher-stalled.out" "$watcher" "${WORK}/wdir-0" "${WORK}/wdir-stalled"
    if [ "$b_fired" -eq 1 ]; then
        bad "dispatch watcher: a fresh interrupted seat printed no STALLED line within 10 s (killed): $(head -c 300 "${WORK}/watcher-stalled.out")"
    elif grep -q '^STALLED STEP-2' "${WORK}/watcher-stalled.out"; then
        ok "dispatch watcher: a fresh seat whose tail is a user-rejected tool_result and an interrupt prints STALLED STEP-2 at once"
    else
        bad "dispatch watcher: an interrupted seat exited ${b_rc} without a STALLED STEP-2 line: $(head -c 300 "${WORK}/watcher-stalled.out")"
    fi

    # The ordinary-tail case always runs to its 10 s kill, so the self-checks'
    # nested runs skip it; the outer run, and every mutant run, does not.
    if [ -n "${DOCKET_RUN_SKILL_INNER:-}" ]; then
        :
    elif bounded_run 10 "${WORK}/watcher-ordinary.out" "$watcher" "${WORK}/wdir-0" "${WORK}/wdir-ordinary"
        grep -q '^STALLED' "${WORK}/watcher-ordinary.out"; then
        bad "dispatch watcher: a fresh seat whose tail is an ordinary tool_result printed STALLED: $(head -c 300 "${WORK}/watcher-ordinary.out")"
    elif [ "$b_fired" -eq 1 ]; then
        ok "dispatch watcher: a fresh seat whose tail is an ordinary tool_result prints no STALLED line within 10 s"
    else
        bad "dispatch watcher: the ordinary-tail run exited ${b_rc} before the 10 s window closed: $(head -c 300 "${WORK}/watcher-ordinary.out")"
    fi
fi

# (k) The loop-history line in references/escalation.md takes each field
# from a read verb that returns it whole. The round comes from step show's
# loop_rounds_run, not from loop-entered's ordinal in an events page that
# returned nothing unnoticed; budget raises come from a tailed events read
# that is complete only when the page is not truncated. Each bullet runs
# from its label to the next "- **" bullet (DOCKET_RUN_ESCALATION_FILE
# overrides the file under test).
#
#   k1 restore "round from `loop-entered`'s `ordinal=N` in `docket events
#      list --run $RUN`" (the events-list absence check reds)
#   k2 replace `docket step show` with `docket run report` in the bullet
#   k3 delete the `docket workflow show <name>@<version> --source` cap source
#   k4 delete `--tail <N>` and the truncated check from the spend bullet
bullet() { # <label> <out>
    awk -v label="$1" '
        on && /^- \*\*/ { exit }
        index($0, "- **" label) == 1 { on = 1 }
        on
    ' "$ESCALATION" > "$2"
    [ -s "$2" ]
}
contains() { # <label> <region-file> <literal>
    if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 — missing: $3"; fi
}
if bullet 'Rounds run against the cap' "${WORK}/rounds"; then
    contains "loop history: the round comes from loop_rounds_run" "${WORK}/rounds" 'loop_rounds_run'
    contains "loop history: the round is read with docket step show" "${WORK}/rounds" 'docket step show'
    contains "loop history: the cap is read with docket workflow show" "${WORK}/rounds" 'docket workflow show'
    if grep -qF -- 'events list --run' "${WORK}/rounds"; then
        bad "loop history: the round is still derived from an events list --run page"
    else
        ok "loop history: the round is not derived from events list --run"
    fi
else
    bad "loop history: no 'Rounds run against the cap' bullet in ${ESCALATION}"
fi
if bullet 'Spend against budget, including every raise' "${WORK}/spend"; then
    contains "loop history: budget raises are read with --tail" "${WORK}/spend" '--tail'
    contains "loop history: the raise list requires an untruncated page" "${WORK}/spend" 'truncated == false'
else
    bad "loop history: no 'Spend against budget, including every raise' bullet in ${ESCALATION}"
fi

# (l) The install-drift diff stops the run on any line it prints, so it must
# print nothing for the empty .claude/.cc-writes directories the harness
# recreates in the source trees, yet still name an added hook and a
# byte-changed workflow. The command is the one `diff -rq` line of the
# fenced probe block carrying `docket doctor --run`, run with CC_SRC and
# HOME pointed at fixture source and installed trees.
#
#   l1 drop `-x .claude`; the clean fixture prints 'Only in <src>: .claude'
#   l2 widen the exclude to `-x '*'` or `-x '*.sh'`; new-hook.sh goes unnamed
#   l3 add `-x '*.js'`; the changed workflow goes unnamed
drift="${WORK}/drift"
mkdir -p "$drift"
awk '
    /^```/ {
        if (open) { if (found) printf "%s", block; open = 0; found = 0; block = "" }
        else open = 1
        next
    }
    open { block = block $0 "\n"; if (index($0, "docket doctor --run")) found = 1 }
' "$SKILL" | grep '^diff -rq' > "${drift}/cmd.sh"
if [ "$(wc -l < "${drift}/cmd.sh")" -ne 1 ]; then
    bad "install drift: the probe block does not carry exactly one diff -rq line"
else
    ok "install drift: the diff command is extracted from the probe block"
    drift_fixture() { # <name>: source and installed trees, identical, with harness dirs in source
        mkdir -p "${drift}/$1/src/workflows/.claude/.cc-writes" "${drift}/$1/src/hooks/.claude/.cc-writes" \
            "${drift}/$1/home/.claude/workflows" "${drift}/$1/home/.claude/hooks"
        echo 'export default 1' > "${drift}/$1/src/workflows/wave.js"
        echo 'export default 1' > "${drift}/$1/home/.claude/workflows/wave.js"
        echo 'exit 0' > "${drift}/$1/src/hooks/guard.sh"
        echo 'exit 0' > "${drift}/$1/home/.claude/hooks/guard.sh"
    }
    drift_run() { # <name> <out>; sets d_rc
        (cd "${drift}/$1" && CC_SRC="${drift}/$1/src" HOME="${drift}/$1/home" bash "${drift}/cmd.sh") > "$2" 2>&1
        d_rc=$?
    }
    drift_fixture clean
    drift_run clean "${drift}/clean.out"
    if [ "$d_rc" -eq 0 ] && [ ! -s "${drift}/clean.out" ]; then
        ok "install drift: an empty .claude/.cc-writes in both source trees prints nothing and exits 0"
    else
        bad "install drift: the harness directory alone exited ${d_rc}: $(head -c 300 "${drift}/clean.out")"
    fi
    drift_fixture hook
    echo 'exit 0' > "${drift}/hook/src/hooks/new-hook.sh"
    drift_run hook "${drift}/hook.out"
    if grep -q '^Only in .*: new-hook\.sh$' "${drift}/hook.out"; then
        ok "install drift: a hook added in source is named in an Only in line"
    else
        bad "install drift: an added new-hook.sh was not reported: $(head -c 300 "${drift}/hook.out")"
    fi
    drift_fixture workflow
    echo 'export default 2' > "${drift}/workflow/src/workflows/wave.js"
    drift_run workflow "${drift}/workflow.out"
    if grep -q '^Files .*wave\.js and .*wave\.js differ$' "${drift}/workflow.out"; then
        ok "install drift: a byte-changed workflow is named in a Files differ line"
    else
        bad "install drift: a changed wave.js was not reported: $(head -c 300 "${drift}/workflow.out")"
    fi
fi

# (m) The run-close sweep deletes only this session's prunable wave branch
# refs; several sessions share the bare repo. The snippet is the one fenced
# block carrying its header comment, run with session wfId wf_mine against
# a fixture bare repo whose porcelain list holds, in order: a prunable
# foreign entry, a live entry of this session, a detached prunable entry,
# and a prunable entry of this session. Only worktree-wf_mine-2 may go, and
# stdout is exactly that ref with the sha it held.
#
#   m1 drop the wfId filter (worktree-wf_other-1 is deleted)
#   m2 drop the per-blank-line reset (worktree-wf_mine-1 is deleted via the
#      detached entry)
#   m3 remove the print, or print the path instead of the ref
sweep_header='# run-close sweep: delete this session'"'"'s prunable wave branch refs'
sweep="${WORK}/sweep"
mkdir -p "$sweep"
if awk -v header="$sweep_header" '
        /^```/ {
            if (open) { if (found) { printf "%s", block; n++ }; open = 0; found = 0; block = "" }
            else open = 1
            next
        }
        open { block = block $0 "\n"; if ($0 == header) found = 1 }
        END { exit n == 1 ? 0 : 1 }
    ' "$SKILL" | sed 's/^set -- .*/set -- wf_mine/' > "${sweep}/sweep.sh" &&
    [ "$(grep -c '^set -- wf_mine$' "${sweep}/sweep.sh")" -eq 1 ]; then
    ok "run-close sweep: exactly one fenced block carries the sweep"
    if (
        export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
        g() { git -c user.name=fixture -c user.email=fixture@example.invalid "$@"; }
        g init -q "${sweep}/seed" &&
            g -C "${sweep}/seed" commit -q --allow-empty -m fixture &&
            g clone -q --bare "${sweep}/seed" "${sweep}/repo.git" &&
            g -C "${sweep}/repo.git" worktree add -q -b worktree-wf_other-1 "${sweep}/wt/a-other1" &&
            g -C "${sweep}/repo.git" worktree add -q -b worktree-wf_mine-1 "${sweep}/wt/b-mine1" &&
            g -C "${sweep}/repo.git" worktree add -q --detach "${sweep}/wt/c-detached" &&
            g -C "${sweep}/repo.git" worktree add -q -b worktree-wf_mine-2 "${sweep}/wt/d-mine2" &&
            rm -rf "${sweep}/wt/a-other1" "${sweep}/wt/c-detached" "${sweep}/wt/d-mine2"
    ) >/dev/null 2>&1; then
        fixture_git() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C "${sweep}/repo.git" "$@"; }
        order=$(fixture_git worktree list --porcelain |
            awk '/^worktree /{w=$2} /^branch /{b=$2} /^detached/{b="detached"} /^prunable/{p="prunable"} /^$/{if (w ~ /\/wt\//) print b, (p ? p : "live"); b=""; p=""}' |
            tr '\n' ',')
        if [ "$order" != "refs/heads/worktree-wf_other-1 prunable,refs/heads/worktree-wf_mine-1 live,detached prunable,refs/heads/worktree-wf_mine-2 prunable," ]; then
            bad "run-close sweep: the fixture porcelain list is not in the planned order: ${order}"
        else
            mine2=$(fixture_git rev-parse refs/heads/worktree-wf_mine-2)
            (cd "${sweep}/repo.git" && GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 bash "${sweep}/sweep.sh") \
                > "${sweep}/out" 2>"${sweep}/err"
            if fixture_git rev-parse -q --verify refs/heads/worktree-wf_mine-2 >/dev/null; then
                bad "run-close sweep: this session's prunable worktree-wf_mine-2 was not deleted: $(head -c 300 "${sweep}/err")"
            else
                ok "run-close sweep: this session's prunable ref is deleted"
            fi
            if fixture_git rev-parse -q --verify refs/heads/worktree-wf_other-1 >/dev/null; then
                ok "run-close sweep: another session's prunable ref survives"
            else
                bad "run-close sweep: another session's worktree-wf_other-1 was deleted"
            fi
            if fixture_git rev-parse -q --verify refs/heads/worktree-wf_mine-1 >/dev/null; then
                ok "run-close sweep: a live ref survives a detached prunable entry after it"
            else
                bad "run-close sweep: the live worktree-wf_mine-1 was deleted"
            fi
            if [ "$(cat "${sweep}/out")" = "refs/heads/worktree-wf_mine-2 ${mine2}" ]; then
                ok "run-close sweep: stdout is exactly the deleted ref and the sha it held"
            else
                bad "run-close sweep: stdout is not one line naming the deleted ref and its sha: $(head -c 300 "${sweep}/out")"
            fi
        fi
    else
        bad "run-close sweep: could not build the fixture bare repository"
    fi
else
    bad "run-close sweep: no single fenced block carries '${sweep_header}' with a set -- line"
fi

# (n) A step parked after its second classifier-stopped attempt is answered
# by a standing ruling, never a question: abandon the issue's remaining steps
# in the run under a named standing grant, file one re-plan issue carrying
# both refusals, and never retry. A retry past a safety-classifier refusal
# stays human, so no sentence of the ruling may offer or recommend one.
#
#   n1 replace the never-retry sentence with "Re-dispatch once as is, then
#      abandon." (the never-retry and no-retry-offer checks red)
#   n2 drop `--issue` from the abandon command
#   n3 delete the re-plan clause
#   n4 drop `--authority-ref` and its value from the abandon command
#   n5 change "second classifier-stopped attempt" in the trigger sentence to
#      "first classifier-stopped attempt"
twice_anchor='A twice-classifier-stopped step is abandoned and re-planned'
if paragraph "$twice_anchor" "${WORK}/twice"; then
    ok "twice classifier-stopped: exactly one paragraph carries the ruling"
    if sentence 'classifier-stopped attempt' "${WORK}/twice" "${WORK}/twice-trigger"; then
        states "twice classifier-stopped: the trigger is a step parked waiting-human after its second classifier-stopped attempt" \
            "${WORK}/twice-trigger" 'A step parked `waiting-human` after its second classifier-stopped attempt'
    else
        bad "twice classifier-stopped: no single sentence of the ruling names the classifier-stopped attempt"
    fi
    grep -oE '`docket run abandon [^`]*`' "${WORK}/twice" > "${WORK}/twice-abandon"
    if [ "$(wc -l < "${WORK}/twice-abandon")" -ne 1 ]; then
        bad "twice classifier-stopped: the ruling does not carry exactly one \`docket run abandon\` command"
    else
        if grep -qE -- '--issue [^ ]' "${WORK}/twice-abandon"; then
            ok "twice classifier-stopped: the abandon command narrows to the issue with --issue"
        else
            bad "twice classifier-stopped: the abandon command lacks --issue: $(cat "${WORK}/twice-abandon")"
        fi
        if grep -qE -- '--authority standing-grant --authority-ref [a-z][a-z0-9-]*' "${WORK}/twice-abandon"; then
            ok "twice classifier-stopped: the abandon command cites a named standing grant"
        else
            bad "twice classifier-stopped: the abandon command lacks --authority standing-grant --authority-ref <ruling>: $(cat "${WORK}/twice-abandon")"
        fi
    fi
    states "twice classifier-stopped: one re-plan issue carries both refusals" \
        "${WORK}/twice" 'plus one re-plan issue carrying both refusals'
    twice_never='Never retry the step and never reword its brief; no ruling applies a retry past a safety-classifier refusal.'
    states "twice classifier-stopped: the never-retry sentence stands" "${WORK}/twice" "$twice_never"
    # Every sentence of the ruling that names a retry or re-dispatch must be
    # the never-retry sentence. Matched by containment, as the census is, and
    # read from the anchor's own flat line, so the self-checks' degraded
    # paragraph() and sentences() copies stay green on a clean file.
    grep -F -- "$twice_anchor" "${WORK}/twice" > "${WORK}/twice-line"
    sentences "${WORK}/twice-line" | grep -iE 'retry|re-?dispatch' | grep -vF -- "$twice_never" > "${WORK}/twice-offers"
    if [ -s "${WORK}/twice-offers" ]; then
        bad "twice classifier-stopped: a sentence of the ruling offers or recommends a retry or re-dispatch: $(head -c 300 "${WORK}/twice-offers")"
    else
        ok "twice classifier-stopped: no sentence of the ruling offers a retry or re-dispatch"
    fi
else
    bad "twice classifier-stopped: no single paragraph carries '${twice_anchor}'"
fi

# (o) The classifier paragraph covers a stop of a running agent's output
# mid-write as well as pre-spawn brief screening, and sends a second stop to
# the standing ruling above rather than to a question.
#
#   o1 delete the mid-write sentence
#   o2 delete the sentence pointing a second stop to the standing ruling
classifier_anchor='A safety-classifier block is not a flake'
if paragraph "$classifier_anchor" "${WORK}/classifier"; then
    ok "classifier: exactly one paragraph carries the classifier ruling"
    states "classifier: pre-spawn brief screening is named" \
        "${WORK}/classifier" 'The classifier screens a rendered brief before any agent exists'
    states "classifier: a stop of a running agent's output mid-write is named" \
        "${WORK}/classifier" "It also stops a running agent's output mid-write"
    states "classifier: a step stopped a second time goes to the standing ruling" \
        "${WORK}/classifier" 'A step stopped a second time goes to **Standing ruling: a step stopped twice by the safety classifier**'
else
    bad "classifier: no single paragraph carries '${classifier_anchor}'"
fi

# (r) pause.md runs the installed script by its install path in all three
# places (print while building the snapshot, check before recording, attach
# in a new session) and never tells the conductor to write a copy. Lines are
# joined first, so an invocation wrapped across lines still counts.
tr '\n' ' ' < "$PAUSE" > "${WORK}/pause-joined"
installed_modes=$(grep -oE 'bash +~/\.claude/skills/docket-run/scripts/resume-prompt-paths\.sh +(print|check|attach)' \
    "${WORK}/pause-joined" | awk '{print $NF}' | sort -u | wc -l | tr -d ' ')
if [ "$installed_modes" -eq 3 ]; then
    ok "installed paths script: pause.md runs print, check and attach from ~/.claude/skills/docket-run/scripts"
else
    bad "installed paths script: pause.md runs ${installed_modes} of print, check and attach by the installed path, not 3"
fi
if grep -qE '<scratchpad>/resume-prompt-paths|script to your scratchpad|with the Write tool' "${WORK}/pause-joined"; then
    bad "installed paths script: pause.md still tells the conductor to write the script: $(grep -oE '<scratchpad>/resume-prompt-paths|script to your scratchpad|with the Write tool' "${WORK}/pause-joined" | head -1)"
else
    ok "installed paths script: pause.md never tells the conductor to write the script"
fi

# No fenced block carries the script's usage line, and the Resume-prompt
# paths section has no bash fence.
paths_usage='# resume-prompt-paths: print | check <prompt-file> | attach <prompt-file>'
inline_copies=$(awk -v usage="$paths_usage" '
        /^[[:space:]]*```/ { open = !open; next }
        open && $0 == usage { n++ }
        END { print n + 0 }
    ' "$PAUSE")
section_fences=$(awk '
        /^## / { on = ($0 == "## Resume-prompt paths"); next }
        on && /^[[:space:]]*```bash/ { n++ }
        END { print n + 0 }
    ' "$PAUSE")
if [ "$inline_copies" -eq 0 ] && [ "$section_fences" -eq 0 ]; then
    ok "installed paths script: pause.md carries no inline copy of the script"
else
    bad "installed paths script: pause.md carries an inline copy (${inline_copies} fenced usage lines, ${section_fences} bash fences under Resume-prompt paths)"
fi

# (q) A regressing round whose write sha is recorded but unintegrated, so
# close refuses CONFLICT on it, goes to the loop-extension panel without an
# operator question: the ruling's own path is applied, not offered. An
# approved tally integrates, resolves and closes; a rejected or stalled one
# reaches the operator, since discarding unintegrated commits is
# irreversible.
#
#   q1 rewrite (a) to ask the operator whether to integrate before
#      convening the panel
#   q2 delete (c), the rejected-or-stalled sentence
#   q3 change (b) to resolve without integrating the sha
#   q4 move (a) out of the anchored paragraph to another paragraph
loopext_anchor="A loop-extension gate is the panel's once, then the operator's"
if paragraph "$loopext_anchor" "${WORK}/loopext"; then
    ok "loop-extension CONFLICT: exactly one paragraph carries the ruling"
    states "loop-extension CONFLICT: (a) an unintegrated regressing sha refused CONFLICT leaves the dispatch open for the panel, unasked" \
        "${WORK}/loopext" 'and `docket dispatch close` refuses CONFLICT on it, leave the dispatch open and convene the panel without asking the operator.'
    states "loop-extension CONFLICT: (b) an approved tally integrates the sha, resolves --as fix-round, and closes" \
        "${WORK}/loopext" 'An approved tally integrates the sha, resolves the step `--as fix-round`, and closes the dispatch'
    states "loop-extension CONFLICT: (c) a rejected or stalled tally goes to the operator with the integrate-or-discard choice" \
        "${WORK}/loopext" 'A rejected or stalled tally goes to the operator with the integrate-or-discard choice'
else
    bad "loop-extension CONFLICT: no single paragraph carries '${loopext_anchor}'"
fi

# (t) Event-log predicate lookups filter by kind. An unfiltered `docket events
# list --run` returns only the run's oldest 100 events, so on a long run a
# lookup for a late event comes back empty without saying so. The verbs
# checkpoint carries the lease-reaped seq lookup in the form the --ack-reap
# paragraph teaches, and every events-list invocation in the file carries
# --tail, --kind or --step.
#
#   t1 delete the lease-reaped line from the verbs heredoc
#   t2 drop `--kind lease-reaped` from the heredoc line only
#   t3 revert the conductor-seated read to `docket events list --run $RUN
#      --json=v2`
#   t4 drop `--kind issue-promoted` from the post-activation check
#   t5 drop `--kind gate-override-granted` from the grant report
reaped_lookup='docket events list --run $RUN --kind lease-reaped --json=v2'
awk '
    index($0, "cat > <scratchpad>/conductor.d/$RUN.verbs <<'"'"'EOF'"'"'") { on = 1; next }
    on && $0 == "EOF" { on = 0; next }
    on { print }
' "$SKILL" > "${WORK}/verbs-heredoc"
grep -F -- "$reaped_lookup" "${WORK}/verbs-heredoc" > "${WORK}/verbs-reaped"
if [ "$(wc -l < "${WORK}/verbs-reaped")" -eq 1 ]; then
    ok "events by kind: the verbs checkpoint carries the lease-reaped seq lookup"
    reaped_line=$(cat "${WORK}/verbs-reaped")
    taught=$(awk '
        index($0, "cat > <scratchpad>/conductor.d/$RUN.verbs <<'"'"'EOF'"'"'") { on = 1; next }
        on && $0 == "EOF" { on = 0; next }
        !on { print }
    ' "$SKILL" | grep -cxF -- "$reaped_line")
    if [ "$taught" -ge 1 ]; then
        ok "events by kind: the checkpoint's lease-reaped line matches the form the body teaches"
    else
        bad "events by kind: the checkpoint's lease-reaped line is taught nowhere outside the heredoc: ${reaped_line}"
    fi
else
    bad "events by kind: the verbs checkpoint does not carry exactly one '${reaped_lookup}' line"
fi
seated_anchor='**Two refusals, and what each means.**'
if paragraph "$seated_anchor" "${WORK}/seated"; then
    states "events by kind: the conductor-seated read filters by kind" \
        "${WORK}/seated" 'docket events list --run $RUN --kind conductor-seated --json=v2'
else
    bad "events by kind: no single paragraph carries '${seated_anchor}'"
fi
roster_anchor='**Read the roster straight out of the dry-run JSON.**'
if paragraph "$roster_anchor" "${WORK}/roster"; then
    states "events by kind: the post-activation issue-promoted check filters by kind" \
        "${WORK}/roster" 'events list --run $RUN --kind issue-promoted'
else
    bad "events by kind: no single paragraph carries '${roster_anchor}'"
fi
grant_anchor='the engine offers no verb to list or revoke a grant'
if paragraph "$grant_anchor" "${WORK}/grant"; then
    states "events by kind: the grant report reads gate-override-granted by kind" \
        "${WORK}/grant" 'docket events list --run RUN-N --kind gate-override-granted --json --all-projects'
else
    bad "events by kind: no single paragraph carries '${grant_anchor}'"
fi
grep -oE '(docket events list|events list --run)[^`|]*' "${WORK}/flat" \
    | grep -vE -- '--(tail|kind|step) ' > "${WORK}/events-unfiltered"
if [ -s "${WORK}/events-unfiltered" ]; then
    bad "events by kind: an events-list invocation carries none of --tail, --kind, --step: $(head -1 "${WORK}/events-unfiltered")"
else
    ok "events by kind: every events-list invocation carries --tail, --kind or --step"
fi

# (u) The close report's landed-commit list ranges from the activation head
# the engine recorded, read in the same paragraph, and an absent head is
# reported as absent rather than reconstructed.
#
#   u1 restore the `<shared-branch tip when this run activated>` placeholder
#      and move the run-status source to a new paragraph elsewhere
#   u2 delete the absent-head sentence
landed_anchor='**Two more pieces of the close report are pasted literal output'
if paragraph "$landed_anchor" "${WORK}/landed"; then
    states "close report: the landed-commit list ranges from the recorded head" \
        "${WORK}/landed" "git log --format='%h %s' <head>..HEAD"
    states "close report: the head is read from run status's activation_head" \
        "${WORK}/landed" '`.data.activation_head.commit` in `docket run status $RUN --json=v2`'
    states "close report: an absent head is reported, not reconstructed" \
        "${WORK}/landed" 'report that no activation head was recorded and paste no list; never reconstruct the range'
    if grep -qF -- '<shared-branch tip when this run activated>' "${WORK}/landed"; then
        bad "close report: the paragraph still asks the conductor to remember the activation tip"
    else
        ok "close report: no remembered-tip placeholder in the paragraph"
    fi
else
    bad "close report: no single paragraph carries '${landed_anchor}'"
fi

# (v) A reconciled dispatch close acknowledges its own dispatch's non-forced
# reaps, so the ack-reap panel convenes only for a hold the reap check still
# names after that close, never beside the usage join before it.
#
#   v1 restore the pre-close reap check that convenes the panel beside the
#      join in the step-1 paragraph
#   v2 delete the "Exit 0 means no hold stands" sentence
#   v3 widen "only that hold gets the ack-reap panel" to every reap
reapcheck_anchor='**After a reconciled close, run the reap check before `next`:**'
if paragraph "$reapcheck_anchor" "${WORK}/reapcheck"; then
    states "reap check: the close acknowledges its own dispatch's non-forced reaps" \
        "${WORK}/reapcheck" 'already acknowledged, as `acked_by: dispatch-close`, every non-forced reap of a claim admitted under that dispatch'
    states "reap check: a clean check convenes no panel" \
        "${WORK}/reapcheck" 'Exit 0 means no hold stands, so no ack-reap panel convenes.'
    states "reap check: only a hold left standing gets the panel" \
        "${WORK}/reapcheck" 'and only that hold gets the ack-reap panel'
else
    bad "reap check: no single paragraph carries '${reapcheck_anchor}'"
fi
join_anchor='**1. Launch the usage join first, before reading or diagnosing the wave'
if paragraph "$join_anchor" "${WORK}/join"; then
    # Read from the anchor's own flat line, as (n) does, so the self-checks'
    # degraded paragraph() copy stays green on a clean file.
    grep -F -- "$join_anchor" "${WORK}/join" > "${WORK}/join-line"
    if grep -qiE 'convene the ack-reap panel' "${WORK}/join-line"; then
        bad "reap check: the usage-join step still convenes the ack-reap panel before the close"
    else
        ok "reap check: the usage-join step convenes no ack-reap panel before the close"
    fi
else
    bad "reap check: no single paragraph carries '${join_anchor}'"
fi
if grep -qE '^docket guard spawn --run \$RUN +# after a reconciled close' "${WORK}/verbs-heredoc"; then
    ok "reap check: the verbs checkpoint carries the post-close reap check"
else
    bad "reap check: the verbs checkpoint lacks the bare post-close 'docket guard spawn --run \$RUN' line"
fi

# (w) The engine sets a gap issue's files and scope from the gap's own
# `Files:` and `Scope:` header lines, so the close promotes nothing by hand.
#
#   w1 restore the "Promote the header at the same close" sentence
#   w2 delete the sentence saying the header lines already set files and
#      scope
gapdup_anchor='**A gap that duplicates a tracker you already hold gets the run note'
if paragraph "$gapdup_anchor" "${WORK}/gapdup"; then
    states "gap header: the header lines set the filed issue's files and scope" \
        "${WORK}/gapdup" "A gap's own \`Files:\` and \`Scope:\` header lines already set the filed issue's files and scope"
else
    bad "gap header: no single paragraph carries '${gapdup_anchor}'"
fi
if grep -qE "Promote the header|from the gap's \`Files:\` line" "${WORK}/flat"; then
    bad "gap header: the skill still promotes a gap's Files: header by hand"
else
    ok "gap header: no hand promotion of a gap's Files: header"
fi

# (x) A step with no max_attempts that keeps failing is offered `docket step
# hold`, which parks that one step, never `run abandon --issue`, which fails
# every step of its issue. The hold form in escalation.md's answer block is
# the one the verbs checkpoint carries.
#
#   x1 swap the hold offer for `docket run abandon $RUN --issue`
#   x2 delete the never-abandon sentence
#   x3 delete the hold line from the verbs heredoc
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
' "$ESCALATION" > "${WORK}/esc-flat"
hold_anchor='**A step that keeps failing is held; its issue is not abandoned.**'
if [ "$(grep -cF -- "$hold_anchor" "${WORK}/esc-flat")" -eq 1 ]; then
    grep -F -- "$hold_anchor" "${WORK}/esc-flat" > "${WORK}/hold"
    contains "step hold: a repeatedly failing step is offered docket step hold" \
        "${WORK}/hold" 'offer the operator `docket step hold` (above) for that step'
    contains "step hold: the hold parks one step and the issue runs on" \
        "${WORK}/hold" 'and the rest of its issue runs on'
    contains "step hold: run abandon --issue is never offered to stop one step" \
        "${WORK}/hold" 'Never offer `docket run abandon $RUN --issue` to stop one step'
else
    bad "step hold: escalation.md does not carry exactly one '${hold_anchor}' paragraph"
fi
hold_line=$(grep -E '^docket step hold STEP-N --reason ' "$ESCALATION")
if [ -n "$hold_line" ] && [ "$(printf '%s\n' "$hold_line" | wc -l)" -eq 1 ]; then
    if grep -qxF -- "$hold_line" "${WORK}/verbs-heredoc"; then
        ok "step hold: the verbs checkpoint carries escalation.md's hold form"
    else
        bad "step hold: the verbs checkpoint lacks escalation.md's hold form: ${hold_line}"
    fi
else
    bad "step hold: escalation.md's answer block does not carry exactly one 'docket step hold STEP-N --reason' line"
fi

# (y) Each budget or chain deferral and each vote re-seat is recorded with
# `docket run fact add`, in the form the verbs checkpoint carries, so a retro
# reading only the store can count them.
#
#   y1 delete the step-deferred line from the verbs heredoc
#   y2 map `skipped-chain-dead` to cause `budget`
#   y3 delete the taught vote-reseated line outside the heredoc, leaving the
#      checkpoint's copy
facts_anchor='**Record each deferral and re-seat as a run fact once the close lands.**'
if paragraph "$facts_anchor" "${WORK}/facts"; then
    states "run facts: budget statuses map to cause budget" \
        "${WORK}/facts" '`not-launched-writer-budget` or `not-launched-token-budget` (cause `budget`)'
    states "run facts: a chain-dead row maps to cause chain" \
        "${WORK}/facts" '`skipped-chain-dead` (cause `chain`)'
    states "run facts: every seat a reseated row names gets a fact" \
        "${WORK}/facts" "for every seat a row's \`reseated: {proposal, seats}\` names"
else
    bad "run facts: no single paragraph carries '${facts_anchor}'"
fi
for kind in step-deferred vote-reseated; do
    fact_line=$(grep -E "^docket run fact add \\\$RUN --kind ${kind} " "${WORK}/verbs-heredoc")
    if [ -z "$fact_line" ] || [ "$(printf '%s\n' "$fact_line" | wc -l)" -ne 1 ]; then
        bad "run facts: the verbs checkpoint does not carry exactly one ${kind} fact line"
        continue
    fi
    taught=$(awk '
        index($0, "cat > <scratchpad>/conductor.d/$RUN.verbs <<'"'"'EOF'"'"'") { on = 1; next }
        on && $0 == "EOF" { on = 0; next }
        !on { print }
    ' "$SKILL" | grep -cxF -- "$fact_line")
    if [ "$taught" -ge 1 ]; then
        ok "run facts: the checkpoint's ${kind} line matches the form the body teaches"
    else
        bad "run facts: the checkpoint's ${kind} line is taught nowhere outside the heredoc: ${fact_line}"
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "docket-run-skill: FAIL — a sandbox lift without its precondition is the failure this pins; fix the skill, not the test." >&2
    exit 1
fi
echo "docket-run-skill: PASS"
