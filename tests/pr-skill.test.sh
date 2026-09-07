#!/bin/bash

# Guard suite for the pr skill's publish and pre-push-scan rules.
#
# Defect class: an edit to src/user/claude_code/skills/pr/SKILL.md that
# quietly relaxes one of the four rules the skill's security case rests on.
# No other gate in this repository reads the skill corpus, so an edit that
# routes publishing around the permission ask, or that turns the pre-push
# scan into a fail-open pipeline, ships green.
#
# Assertions are anchored to the fenced command blocks and to the review
# mode's refusal-list region, never to whole-file text: each of these strings
# also occurs in the prose that explains the rule, so a whole-file grep stays
# green while the command itself is wrong. The one exception is (d), an
# absence claim, which is whole-file by nature.
#
# PR_SKILL_FILE overrides the file under test, so a mutation probe can point
# the suite at a deliberately broken COPY under $TMPDIR without touching the
# checkout. Each assertion's mutant, proven red:
#
#   (a)  publish  replace the fenced publish block with the
#                 "gh pr create --title ... --body-file ..." shape
#                 M-1454: delete the publish fence outright (the anchor must
#                 not fall through to a false match on the review-reply block,
#                 which carries "pulls" as a literal prefix)
#   (a3) universal M6: append a SECOND fenced publish block —
#                 "gh pr create -R <owner>/<repo> --title ... --body-file ..."
#                 — after the real one; (a) alone finds only the first
#                 matching block and never looks at the second
#   (a2) xargs    wrap the publish call in "xargs -0 -a <title-file>"
#   (b)  scan     M2: join the two scan commands onto one line with a
#                 semicolon, and drop --diff-merges=first-parent from the walk
#                 M1: fold two "git log" invocations onto one physical line
#                 with a semicolon, so a line count sees one command where two
#                 processes ran
#   (b2) prefix   MG: drop the origin/ prefix at both scan command sites,
#                 leaving a bare "<base>..HEAD" in the rev-list count and in
#                 the log walk
#                 MH: drop it at the walk alone, which keeps the count
#                 command — and so the block anchor — intact
#   (c)  refusal  delete src/user/claude_code/skills/** from the review-mode
#                 refusal list (it still occurs elsewhere in the file)
#   (d)  title    reintroduce the forbidden literal --title "<title>"
#   (e)  status   reintroduce a standalone "echo $?" line in the checks
#                 step 4 log-fetch block (DOT-1130)
#   (f)  tail     rejoin the checks step 4 capture and tail commands into
#                 one fenced block with no conditional between them
#                 (DOT-1131)
#   (g)  reply    rewrite the review-thread-reply or close-comment
#                 instruction to "gh pr comment <n> ... --body \"$text\""
#                 (DOT-1149); the same rewrite also leaves a
#                 gh pr comment ... --body "<text>" line in the file, which
#                 the forbidden-form check rejects on its own
#   (h)  auto     MA: inside merge step 2's mergeStateStatus bullet, rewrite
#                 "accept the PR here — handed to step 3" to "refuse here as
#                 well, which keeps step 3 unreachable"
#                 MB: delete the exception clause (the whole "So when the
#                 invocation said auto ..." sentence)
#                 MF (must stay GREEN): insert an unrelated earlier line
#                 containing "mergeStateStatus == CLEAN" above merge step 2
#   (i)  headref  MC: replace "and assert it equals <head-branch>; a mismatch
#                 refuses, naming both branches" with "and note it in the
#                 report"
#                 MD: drop only the refusal verb from that sentence
#   (j)  eol      MI: revert the title-validation paragraph to "exactly one
#                 line, no embedded newline", dropping the trailing-newline
#                 item and its tail -c1 mechanism
#                 MJ (must stay GREEN): delete the writer paragraph's
#                 "trailing newline" prose, which the region excludes
#                 MN: revert the NUL item to "contains no NUL byte" with no
#                 detection command
#   (k)  determ   MK: delete the fenced /usr/bin/perl -0777 -pe 's/\n\z//'
#                 de-terminate command, leaving the check with no producer
#
# (h) and (i) assert the ruling, not a token count: a count of "auto" over
# the bullet, or of "headRefName" over the file, survives MA, MC and MD
# unchanged, and a first-match extraction turns MF into a false red.
#
# A missing input file fails; it never skips green.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL="${PR_SKILL_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/pr/SKILL.md}"

if [ ! -f "$SKILL" ]; then
    echo "FAIL input: no such file: ${SKILL}" >&2
    echo "pr-skill: FAIL" >&2
    exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/pr-skill.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

# Every fenced block body, one file per block, continuation lines joined so a
# command that wraps across physical lines is asserted on as one command.
awk -v out="$WORK" '
    /^[[:space:]]*```/ { inside = !inside; if (inside) { n++ }; next }
    inside { print > (out "/block." n) }
' "$SKILL"

shopt -s nullglob
BLOCKS=("$WORK"/block.*)
shopt -u nullglob

if [ "${#BLOCKS[@]}" -eq 0 ]; then
    bad "fences: no fenced block found in ${SKILL}"
    echo "pr-skill: FAIL" >&2
    exit 1
fi

join_continuations() { # <file> — trailing-backslash lines folded onto one line
    awk '{
        line = $0
        while (sub(/\\$/, "", line) && (getline next_line) > 0) { line = line next_line }
        print line
    }' "$1"
}

for b in "${BLOCKS[@]}"; do
    join_continuations "$b" > "${b}.joined"
done

sentences() { # <file> — prose sentences, one per line, fenced blocks dropped
    awk '
        /^[[:space:]]*```/     { fenced = !fenced; next }
        fenced                 { next }
        /^[[:space:]]*$/       { if (para != "") print para; para = ""; next }
        { sub(/^[[:space:]]+/, ""); para = (para == "" ? $0 : para " " $0) }
        END { if (para != "") print para }
    ' "$1" | sed -E 's/([.!?][*`")]*) +/\1\
/g'
}

find_block() { # <literal> — path of the joined block containing it
    local b
    for b in "$WORK"/block.*.joined; do
        if grep -qF -- "$1" "$b"; then
            printf '%s\n' "$b"
            return 0
        fi
    done
    return 1
}

find_block_re() { # <ERE> — path of the joined block matching it
    local b
    for b in "$WORK"/block.*.joined; do
        if grep -qE -- "$1" "$b"; then
            printf '%s\n' "$b"
            return 0
        fi
    done
    return 1
}

# (a) The publish block is the gh api file-field form. Anchored so the
# literal cannot prefix-match the review-reply endpoint
# (.../pulls/<pr-number>/comments/<comment-id>/replies carries "pulls" as a
# prefix too): the anchor requires "pulls" end the line or be followed only
# by whitespace, never a "/".
if publish=$(find_block_re 'gh api --method POST repos/<owner>/<repo>/pulls([[:space:]]|$)'); then
    ok "publish block: gh api --method POST repos/<owner>/<repo>/pulls"
    for field in "-F 'title=@" "-F 'body=@"; do
        if grep -qF -- "$field" "$publish"; then
            ok "publish block: carries ${field}"
        else
            bad "publish block: missing ${field} — generated text must reach gh as a file"
        fi
    done
else
    bad "publish block: no fenced block runs gh api --method POST repos/<owner>/<repo>/pulls"
    publish=""
fi

# (a3) Universal, not existential: find_block above stops at the FIRST
# matching block, so a second fenced block that also creates the PR — via
# "gh pr create" or another "gh api ... pulls" call — would never be looked
# at. Sweep every fenced block for one, and require each to be the gh api
# file-field form, mirroring the xargs loop's universal quantifier below.
for b in "$WORK"/block.*.joined; do
    if grep -qE -- 'gh (api .*/pulls([[:space:]]|$)|pr create)' "$b"; then
        if grep -qE -- '^[[:space:]]*gh api ' "$b" \
            && grep -qF -- "-F 'title=@" "$b" \
            && grep -qF -- "-F 'body=@" "$b"; then
            ok "publish shape: $(grep -oE -- 'gh (api .*/pulls|pr create)' "$b" | head -n 1) is the gh api file-field form"
        else
            bad "publish shape: a fenced block creates the PR without the gh api file-field form: $(grep -E -- 'gh (api .*/pulls|pr create)' "$b" | head -n 1)"
        fi
    fi
done

# (a2) No publish path wraps gh in a launcher: an ask rule is a prefix match
# on the command as written, so a wrapper removes the ask it appears to keep.
xargs_hits=0
for b in "$WORK"/block.*.joined; do
    if grep -qF -- 'xargs' "$b"; then
        bad "publish path: xargs appears in a fenced command block: $(grep -F -- 'xargs' "$b" | head -n 1)"
        xargs_hits=1
    fi
done
[ "$xargs_hits" -eq 0 ] && ok "publish path: no fenced command block wraps a command in xargs"

# (b) The pre-push scan is two separate commands, and the walk is one process.
# Structural, not a pipe-byte scan: the block's non-comment, non-blank lines
# must be exactly two, the rev-list anchor then the log walk, so any
# single-line join (pipe, semicolon, &&, command substitution) fails, and two
# git log invocations folded onto one physical line by join_continuations
# still count as one command line for occurrence purposes.
if scan=$(find_block 'git rev-list --count origin/<base>..HEAD'); then
    ok "pre-push scan block: git rev-list --count origin/<base>..HEAD"

    grep -vE '^[[:space:]]*(#|$)' "$scan" > "${WORK}/scan-lines"
    scan_lines=$(grep -c '' "${WORK}/scan-lines")
    if [ "$scan_lines" -eq 2 ] \
        && sed -n '1p' "${WORK}/scan-lines" | grep -qE '^git rev-list' \
        && sed -n '2p' "${WORK}/scan-lines" | grep -qE '^git log'; then
        ok "pre-push scan block: exactly two command lines, rev-list then log walk"
    else
        bad "pre-push scan block: expected exactly two command lines (git rev-list, then git log), found ${scan_lines} — the two commands must run separately"
    fi

    walk_occurrences=$(grep -oF -- 'git log' "$scan" | wc -l)
    if [ "$walk_occurrences" -eq 1 ]; then
        ok "pre-push scan block: exactly one git log walk"
        walk=$(grep -F -- 'git log' "${WORK}/scan-lines")
        for flag in '--diff-merges=first-parent' '--diff-filter=AM' 'origin/<base>..HEAD'; do
            case "$walk" in
                *"$flag"*) ok "pre-push scan walk: carries ${flag}" ;;
                *) bad "pre-push scan walk: missing ${flag}" ;;
            esac
        done
        case "$walk" in
            *'origin/<base>...HEAD'*)
                bad "pre-push scan walk: three-dot range — that is a different question than what the push publishes" ;;
        esac
    else
        bad "pre-push scan block: expected exactly one git log walk, found ${walk_occurrences}"
    fi
else
    bad "pre-push scan block: no fenced block runs git rev-list --count origin/<base>..HEAD"
fi

# (c) The review-mode refusal list names the skill corpus. Membership in the
# list, not presence in the file: the same path is written twice more in the
# worked example, so the region is extracted before it is searched.
awk '
    index($0, "**Refuse** to apply any comment-derived edit") { open = 1; begins++ }
    index($0, "**For anything on neither list**")             { open = 0; ends++ }
    open { print }
    END {
        if (begins != 1 || ends != 1) {
            printf "found %d refusal-list starts and %d ends\n", begins, ends > "/dev/stderr"
            exit 1
        }
    }
' "$SKILL" > "${WORK}/refusal-list"
refusal_markers=$?

if [ "$refusal_markers" -ne 0 ] || [ ! -s "${WORK}/refusal-list" ]; then
    bad "refusal list: could not delimit the review-mode refusal list"
elif grep -qF -- 'src/user/claude_code/skills/**' "${WORK}/refusal-list"; then
    ok "refusal list: names src/user/claude_code/skills/**"
else
    bad "refusal list: src/user/claude_code/skills/** is not in the review-mode refusal list"
fi

# (d) The forbidden shell-string title form appears nowhere.
if grep -qF -- '--title "<title>"' "$SKILL"; then
    bad "forbidden form: --title \"<title>\" appears in ${SKILL}"
else
    ok "forbidden form: --title \"<title>\" appears nowhere"
fi

# (e) checks step 4 never reads $? in a separate shell from the one that
# ran gh: no fenced block contains a standalone "echo $?" line.
status_hits=0
for b in "$WORK"/block.*.joined; do
    if grep -qxE '[[:space:]]*echo[[:space:]]+\$\?[[:space:]]*' "$b"; then
        bad "checks step 4: a fenced block contains a standalone 'echo \$?' line: $b"
        status_hits=1
    fi
done
[ "$status_hits" -eq 0 ] && ok "checks step 4: no fenced block reads \$? on its own line"

# (f) checks step 4's log capture and its tail are never the same fenced
# block: a reader copying one fence must not be able to tail an unfetched
# log past a failed capture with no conditional in between.
if capture=$(find_block 'gh run view <run-id>'); then
    ok "checks step 4: gh run view <run-id> capture block found"
    if grep -qF -- 'tail -n 50' "$capture"; then
        bad "checks step 4: the gh run view capture and 'tail -n 50' share one fenced block with no conditional between them"
    else
        ok "checks step 4: gh run view capture and tail are separate fenced blocks"
    fi
else
    bad "checks step 4: no fenced block runs gh run view <run-id>"
fi
if ! find_block 'tail -n 50 <log-file>' >/dev/null; then
    bad "checks step 4: no fenced block runs tail -n 50 <log-file>"
else
    ok "checks step 4: tail -n 50 <log-file> is its own fenced block"
fi

# (g) review-thread replies and close comments publish through the same
# file-field gh api mechanism as the title/body, never gh pr comment.
if reply=$(find_block 'pulls/<pr-number>/comments/<comment-id>/replies'); then
    ok "review reply block: gh api ... pulls/<pr-number>/comments/<comment-id>/replies"
    if grep -qF -- "-F 'body=@" "$reply"; then
        ok "review reply block: carries -F 'body=@"
    else
        bad "review reply block: missing -F 'body=@ — reply text must reach gh as a file"
    fi
else
    bad "review reply block: no fenced block runs gh api ... pulls/<pr-number>/comments/<comment-id>/replies"
fi

if close_comment=$(find_block 'issues/<pr-number>/comments'); then
    ok "close comment block: gh api ... issues/<pr-number>/comments"
    if grep -qF -- "-F 'body=@" "$close_comment"; then
        ok "close comment block: carries -F 'body=@"
    else
        bad "close comment block: missing -F 'body=@ — comment text must reach gh as a file"
    fi
else
    bad "close comment block: no fenced block runs gh api ... issues/<pr-number>/comments"
fi

# `[^\n]` here would be a bracket expression excluding the letter n, not a
# "not a newline" class, and every real call names <pr-number>.
if grep -qE 'gh pr comment .*--body "' "$SKILL"; then
    bad "forbidden form: gh pr comment ... --body \"<text>\" appears in ${SKILL}"
else
    ok "forbidden form: gh pr comment ... --body \"<text>\" appears nowhere"
fi

# (h) merge step 2's mergeStateStatus bullet keeps step 3's `auto` path
# reachable: the pending-required-check case is ACCEPTED here and handed on,
# never refused. The bullet is taken by its position inside merge step 2, and
# a second matching region — or a second step 2 — refuses rather than
# guessing, so a `mergeStateStatus == CLEAN` line elsewhere in the file
# cannot be extracted in its place.
awk '
    /^## merge /  { in_merge = 1; next }
    /^## /        { in_merge = 0 }
    !in_merge     { next }
    /^2\. /       { in_step = 1; steps++ }
    /^3\. /       { in_step = 0; in_bullet = 0 }
    in_step && /^   - .*mergeStateStatus == CLEAN/ { in_bullet = 1; regions++; print; next }
    in_bullet && /^   - / { in_bullet = 0 }
    in_bullet     { print }
    END { exit (regions == 1 && steps == 1) ? 0 : 1 }
' "$SKILL" > "${WORK}/auto-bullet"
auto_region=$?

if [ "$auto_region" -ne 0 ] || [ ! -s "${WORK}/auto-bullet" ]; then
    bad "auto carve-out: merge step 2 does not hold exactly one mergeStateStatus bullet"
else
    ok "auto carve-out: exactly one mergeStateStatus bullet inside merge step 2"
    sentences "${WORK}/auto-bullet" > "${WORK}/auto-sentences"

    if grep -qF -- 'auto' "${WORK}/auto-bullet"; then
        ok "auto carve-out: the bullet names the auto invocation"
    else
        bad "auto carve-out: the bullet never names auto — step 3's auto path is dead"
    fi

    if grep -F -- 'step 3' "${WORK}/auto-sentences" | grep -Ei 'accept' | grep -qEiv 'refus'; then
        ok "auto carve-out: the pending case is accepted here and handed to step 3"
    else
        bad "auto carve-out: no sentence hands the pending case to step 3 with an acceptance verb free of a refusal verb"
    fi
fi

# (i) An explicitly given PR number is checked against the checked-out
# branch, and a mismatch refuses. Anchored on the sentence that carries the
# assertion, not on how often headRefName is written.
sentences "$SKILL" > "${WORK}/skill-sentences"
head_hits=$(grep -cF -- 'assert it equals' "${WORK}/skill-sentences")

if [ "$head_hits" -ne 1 ]; then
    bad "head-branch assertion: expected exactly one sentence carrying 'assert it equals', found ${head_hits}"
else
    ok "head-branch assertion: one sentence asserts the PR's head branch equals the checkout's"
    head_sentence=$(grep -F -- 'assert it equals' "${WORK}/skill-sentences")

    case "$head_sentence" in
        *refus*) ok "head-branch assertion: a mismatch refuses" ;;
        *) bad "head-branch assertion: no refusal governs the mismatch — it is then merely reported" ;;
    esac

    case "$head_sentence" in
        *'<head-branch>'*) ok "head-branch assertion: the sentence names <head-branch>" ;;
        *) bad "head-branch assertion: the sentence does not name <head-branch>" ;;
    esac
fi

# (j) The title-validation paragraph carries the trailing-newline item and a
# mechanism that can see a terminator. "trailing newline" also occurs in the
# writer prose above, so the paragraph is extracted before it is searched.
awk '
    index($0, "**The title file is validated before it is used**") { open = 1; begins++ }
    open && /^[[:space:]]*$/ { open = 0 }
    open { print }
    END { exit (begins == 1) ? 0 : 1 }
' "$SKILL" > "${WORK}/title-validation"
validation_region=$?

if [ "$validation_region" -ne 0 ] || [ ! -s "${WORK}/title-validation" ]; then
    bad "title validation: expected exactly one paragraph opening 'The title file is validated before it is used'"
else
    ok "title validation: exactly one validation paragraph"
    if grep -qF -- 'trailing newline' "${WORK}/title-validation"; then
        ok "title validation: the list refuses a trailing newline"
    else
        bad "title validation: no trailing-newline item — gh publishes the terminator inside the title"
    fi
    if grep -qF -- 'tail -c1' "${WORK}/title-validation"; then
        ok "title validation: the item names a mechanism that can see a terminator"
    else
        bad "title validation: no tail -c1 mechanism — a wc -l count cannot see a terminator"
    fi
    if grep -qF -- "tr -d '\\000'" "${WORK}/title-validation"; then
        ok "title validation: the NUL-byte item names a detection command"
    else
        bad "title validation: no tr -d '\\000' detection — neither an agent nor the denylist's grep pass can see a NUL directly"
    fi
fi

# (k) The de-terminate step exists to PRODUCE that property: BSD grep's strip
# pass always terminates its output, so without this the check refuses every
# title. Anchored on perl, not head -c: the perl form depends on no
# hand-computed byte count, which a head -c form would let an off-by-one
# silently truncate the title past every item in the validation list.
if determinate=$(find_block "/usr/bin/perl -0777 -pe 's/\\n\\z//'"); then
    ok "de-terminate: a fenced block cuts the terminator with perl -0777 -pe s/\\n\\z//"
    if grep -qF -- '> <final-title-file>' "$determinate"; then
        ok "de-terminate: it redirects into the file that gets scanned and sent"
    else
        bad "de-terminate: the perl command does not redirect into <final-title-file>"
    fi
else
    bad "de-terminate: no fenced block runs /usr/bin/head -c — the strip pass's terminator has no remover"
fi

if [ "$fail" -ne 0 ]; then
    echo "pr-skill: FAIL — the pr skill's publish and scan rules are load-bearing; fix the skill, not the test." >&2
    exit 1
fi
echo "pr-skill: PASS"
