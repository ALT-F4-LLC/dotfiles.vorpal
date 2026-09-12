#!/bin/bash

# Guard suite for the finish skill's standing prohibitions.
#
# Defect class: finish is the sweep a session runs before walking away, and
# four of its rulings are load-bearing because what each forbids cannot be
# undone from the far side of the session — a push publishes commits nobody
# reviewed, a removed worktree takes an un-integrated sha with it, a
# `dispatch abandon` discards a live run's work unconditionally, and an agent
# stopped on the strength of a list surface rather than this session's own
# record may belong to a session still using it. Nothing else in this
# repository pins any of the four, so an edit that carves out an exception
# ("push when the operator asked for it"), conditions a ruling ("remove it
# when its branch is merged"), drops one verb from the halt ruling, or
# demotes the session's record from proof to "one input among others" ships
# green.
#
# Assertions are anchored to each ruling's OWN paragraph, never to whole-file
# text: "push" and "abandon" each appear only in the sentences the census
# below admits today, but a whole-file grep would stay green if a rewrite
# moved a ruling to different words while leaving an unrelated mention in
# place ("Nothing was pushed." would keep such a grep satisfied). Paragraphs
# are flattened to one line before matching, so rewrapping the prose is not
# a failure. The halt ruling is pinned to one SENTENCE rather than the whole
# paragraph, so that dropping a verb from the ruling sentence and restating
# it a sentence later in the same paragraph falsifies the pin instead of
# surviving inside a paragraph-sized match. Each paragraph-level literal
# runs to the boundary of its ruling — the period after "invokes", the
# semicolon after "un-integrated sha", the closing ** after "ownership" — so
# an exception spliced in before that boundary breaks the literal.
#
# The pins catch a ruling that is weakened or removed; the census at the end
# catches one contradicted elsewhere. Every sentence anywhere in the file
# that names a push or one of the three halting verbs (`run pause`,
# `dispatch close`, `dispatch abandon`) must be, in full, one of three
# admitted sentences: the push ruling, the halt ruling, and the closing
# report's "Nothing was pushed." — a report line rather than a ruling,
# admitted because it names a push. Admission is by exact whole-sentence
# match, not substring: a ruling sentence with an exception clause spliced
# onto its end still contains its own pinned literal, and only an exact
# match reds it.
#
# FINISH_SKILL_FILE overrides the file under test, so a mutation probe can
# point the suite at a deliberately broken COPY under $TMPDIR without
# touching the checkout. The self-checks always read the repository's own
# copy, so a mutant run does not disturb them. Each assertion's mutant,
# proven red:
#
#   (s) self-check, run against copies of the repository's own file
#       s1 "and never `dispatch abandon`" deleted: the suite fails
#       s2 the "**Uncommitted changes.**" paragraph duplicated: the suite
#          fails
#       s3 one unadmitted sentence appended per census key: the suite fails
#          for each
#       s4 an untouched copy: the suite passes
#   (o) ownership — this session's own record is the proof
#       o1 replace "is the proof of ownership" with "is one input among
#          others": the literal is gone from the file
#   (h) halt — finish never halts a run itself
#       h1 delete "and never `dispatch abandon`" from the ruling sentence:
#          the three-verb literal is gone from the file, and the census reds
#          the truncated sentence too, since it still names `dispatch close`
#          but no longer equals the admitted one
#   (w) worktree — never remove one carrying an un-integrated sha
#       w1 replace "**Never remove a worktree carrying an un-integrated sha**"
#          with "Remove a worktree carrying an un-integrated sha when its
#          branch is merged": the literal is gone from the file
#   (p) push — never, here or through anything this skill invokes
#       p1 replace "**Never push**, here or through anything this skill
#          invokes" with "Push when the operator asked for it": the literal
#          is gone from the file, and the census reds the new sentence too
#       p2 the "**Uncommitted changes.**" paragraph appears twice: no single
#          paragraph carries the anchor, so the pin is refused rather than
#          read off either copy
#       p3 splice ", unless the operator asks" into the ruling sentence before
#          its period: the literal is gone from the file, and the census reds
#          the sentence because it no longer equals the admitted one
#   (c) census, each appended to an otherwise clean copy so every pin stays
#       green and only the census can red it
#       c1 "Push the branch once the commit lands."
#       c2 "Run `docket dispatch abandon` if the run is stuck."
#       c3 "Issue `docket run pause` yourself if pause is unavailable."
#       c4 "Run `docket dispatch close` before the sweep."
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_SKILL="${SCRIPT_DIR}/../src/user/claude_code/skills/finish/SKILL.md"
SKILL="${FINISH_SKILL_FILE:-$REPO_SKILL}"

if [ ! -f "$SKILL" ]; then
    echo "FAIL input: no such file: ${SKILL}" >&2
    echo "finish-skill: FAIL" >&2
    exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/finish-skill.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

fail=0

ok() {
    echo "ok   $1"
}

bad() {
    echo "FAIL $1"
    fail=1
}

# Every blank-line-delimited paragraph of <in>, flattened to one line each,
# written to <out>. Both the paragraph anchors and the census read this, so
# line wrapping is never what a ruling stands or falls on.
flatten() { # <in> <out>
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

flatten "$SKILL" "${WORK}/flat"

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
        bad "$1 — moved out of the ruling's own region, still elsewhere in the file: $3"
    else
        bad "$1 — gone from the file: $3"
    fi
}

# (s) The suite's own machinery is re-proven every run: a copy of the
# repository's skill file with one ruling clause deleted MUST fail, a copy
# with a ruling paragraph duplicated MUST fail, a copy with one unadmitted
# sentence appended per census key MUST fail, and an untouched copy MUST
# pass. Without this a broken states(), a paragraph() that accepts any hit
# count, or a census matched against no key stays green forever. Always the
# repository's own file, never $SKILL, so a mutation probe does not disturb
# the control; FINISH_SKILL_FILE is set explicitly on every inner run, so an
# outer probe's mutant cannot leak into the control via inheritance.
inner() { # <skill-copy>
    FINISH_SKILL_INNER=1 FINISH_SKILL_FILE="$1" bash "$0" >/dev/null 2>&1
}

if [ -z "${FINISH_SKILL_INNER:-}" ]; then
    if [ ! -f "$REPO_SKILL" ]; then
        bad "self-check: the repository's own skill file is missing: ${REPO_SKILL}"
    else
        cp "$REPO_SKILL" "${WORK}/self-clean.md"

        # s1: the halt ruling loses its `dispatch abandon` clause. The clause
        # wraps across source lines, so the mutation matches across embedded
        # newlines (perl slurp mode with \s+ standing in for "space or
        # line-wrap") rather than anchoring to a single physical line.
        perl -0pe 's/and\s+never\s+`dispatch\s+abandon`/[ruling deleted]/s' \
            "${WORK}/self-clean.md" > "${WORK}/self-broken.md"
        if cmp -s "${WORK}/self-clean.md" "${WORK}/self-broken.md"; then
            bad "self-check: the deletion did not apply — the control proves nothing"
        elif inner "${WORK}/self-broken.md"; then
            bad "self-check: a copy with its dispatch-abandon clause deleted still passed the suite"
        else
            ok "self-check: a broken skill copy fails the suite"
        fi

        # s2: the push ruling's paragraph appears twice, so no single
        # paragraph carries its anchor and the pin must be refused.
        perl -0pe 's/(\*\*Uncommitted changes\.\*\*.*?owns them\.\n)/$1\n$1/s' \
            "${WORK}/self-clean.md" > "${WORK}/self-duplicated.md"
        if cmp -s "${WORK}/self-clean.md" "${WORK}/self-duplicated.md"; then
            bad "self-check: the duplication did not apply — the control proves nothing"
        elif inner "${WORK}/self-duplicated.md"; then
            bad "self-check: a copy with its push paragraph duplicated still passed the suite"
        else
            ok "self-check: a duplicated ruling paragraph fails the suite"
        fi

        # s3: one unadmitted sentence per census key, appended outside every
        # anchored paragraph, so every pin stays green and only the census
        # can red it.
        while IFS= read -r line; do
            cp "${WORK}/self-clean.md" "${WORK}/self-census.md"
            printf '\n%s\n' "$line" >> "${WORK}/self-census.md"
            if inner "${WORK}/self-census.md"; then
                bad "self-check: a copy with an unadmitted sentence appended still passed the suite: ${line}"
            else
                ok "self-check: an appended unadmitted sentence fails the suite: ${line}"
            fi
        done <<'FIXTURES'
Push the branch once the commit lands.
Run `docket dispatch abandon` if the run is stuck.
Issue `docket run pause` yourself if pause is unavailable.
Run `docket dispatch close` before the sweep.
FIXTURES

        # s4: the control.
        if inner "${WORK}/self-clean.md"; then
            ok "self-check: a clean skill copy passes the suite"
        else
            bad "self-check: a clean copy of the repository's skill file does not pass"
        fi
    fi
fi

# (o) The proof of ownership is this session's own record, not a list
# surface. The literal is the whole ruling, closing ** included, so a hedge
# spliced in before "proof" breaks it.
if paragraph 'Every stop below is bounded by one rule' "${WORK}/ownership"; then
    ok "ownership: exactly one paragraph carries the ownership rule"
    states "ownership: this session's own record is the proof of ownership" \
        "${WORK}/ownership" "**This session's own record of what it created is the proof of ownership**"
else
    bad "ownership: no single paragraph carries 'Every stop below is bounded by one rule'"
fi

# (h) Finish never halts a run itself. The paragraph also carries the
# hand-off to pause, so the halt literals are asserted against the one
# sentence that rules on halting: a verb dropped there and restated a
# sentence later would otherwise still read as pinned.
if paragraph 'Invoke `/pause` for the run' "${WORK}/handoff"; then
    ok "halt: exactly one paragraph carries the hand-off to pause"
    if sentence '**Finish never halts a run itself**' \
        "${WORK}/handoff" "${WORK}/halt-sentence"; then
        ok "halt: exactly one sentence rules on halting a run"
        states "halt: finish issues none of the three halting verbs" \
            "${WORK}/halt-sentence" 'it issues no `run pause`, no `dispatch close`, and never `dispatch abandon`'
        states "halt: dispatch abandon belongs to pause's hard halt alone" \
            "${WORK}/halt-sentence" "that verb discards live work unconditionally and belongs to pause's hard halt alone"
    else
        bad "halt: no single sentence carries '**Finish never halts a run itself**'"
    fi
else
    bad "halt: no single paragraph carries 'Invoke \`/pause\` for the run'"
fi

# (w) A worktree carrying an un-integrated sha is never removed. The literal
# ends at the semicolon, so a condition spliced in before it breaks the pin.
if paragraph '**Git worktrees this session created.**' "${WORK}/worktrees"; then
    ok "worktree: exactly one paragraph carries the worktree row"
    states "worktree: never remove one carrying an un-integrated sha" \
        "${WORK}/worktrees" '**Never remove a worktree carrying an un-integrated sha**;'
else
    bad "worktree: no single paragraph carries '**Git worktrees this session created.**'"
fi

# (p) Never push, here or through anything this skill invokes. The literal
# ends at the period, so an exception spliced in before it breaks the pin;
# the census below reds the resulting sentence a second time.
if paragraph '**Uncommitted changes.**' "${WORK}/uncommitted"; then
    ok "push: exactly one paragraph carries the uncommitted-changes row"
    states "push: never, here or through anything this skill invokes" \
        "${WORK}/uncommitted" '**Never push**, here or through anything this skill invokes.'
else
    bad "push: no single paragraph carries '**Uncommitted changes.**'"
fi

# (c) Absence claim, run over SENTENCES rather than paragraphs: every
# sentence anywhere in the file that names a push or a halting verb must be,
# in full, one of the admitted sentences. A paragraph-level census would
# exempt every sentence in an anchored paragraph, so a new push instruction
# inserted inside a ruling's own paragraph would stay invisible to it;
# pinning to the sentence catches it wherever it lands. The two ruling
# sentences here are the same ones the pins above assert into, so the census
# and those assertions cannot drift apart.
cat > "${WORK}/admitted" <<'ADMITTED'
**Never push**, here or through anything this skill invokes.
Nothing was pushed.
**Finish never halts a run itself** — it issues no `run pause`, no `dispatch close`, and never `dispatch abandon`; that verb discards live work unconditionally and belongs to pause's hard halt alone.
ADMITTED

sentences "${WORK}/flat" > "${WORK}/all-sentences"
census=0
while IFS= read -r sent; do
    case "$sent" in
        *[Pp]ush*|*[Aa]bandon*|*'run pause'*|*'dispatch close'*) ;;
        *) continue ;;
    esac
    if ! grep -qxF -- "$sent" "${WORK}/admitted"; then
        bad "census: an unadmitted sentence names a push or a halting verb: ${sent:0:140}"
        census=1
    fi
done < "${WORK}/all-sentences"
[ "$census" -eq 0 ] && ok "census: every sentence naming a push or a halting verb is one of the admitted sentences"

if [ "$fail" -ne 0 ]; then
    echo "finish-skill: FAIL — a finish prohibition without its full pin is the failure this catches; fix the skill, not the test." >&2
    exit 1
fi
echo "finish-skill: PASS"
