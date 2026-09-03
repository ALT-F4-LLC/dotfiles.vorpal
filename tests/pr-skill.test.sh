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
#   (a2) xargs    wrap the publish call in "xargs -0 -a <title-file>"
#   (b)  scan     join the two scan commands with a pipe, and drop
#                 --diff-merges=first-parent from the walk
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
#                 (DOT-1149)
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

# (a) The publish block is the gh api file-field form.
if publish=$(find_block 'gh api --method POST repos/<owner>/<repo>/pulls'); then
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
if scan=$(find_block 'git rev-list --count origin/<base>..HEAD'); then
    ok "pre-push scan block: git rev-list --count origin/<base>..HEAD"

    if grep -qF -- '|' "$scan"; then
        bad "pre-push scan block: a pipe joins the scan commands — a failed enumeration then exits 0"
    else
        ok "pre-push scan block: no pipe joins the scan commands"
    fi

    walks=$(grep -cF -- 'git log' "$scan")
    if [ "$walks" -eq 1 ]; then
        ok "pre-push scan block: exactly one git log walk"
        walk=$(grep -F -- 'git log' "$scan")
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
        bad "pre-push scan block: expected exactly one git log walk, found ${walks}"
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

if grep -qE 'gh pr comment [^\n]*--body "' "$SKILL"; then
    bad "forbidden form: gh pr comment ... --body \"<text>\" appears in ${SKILL}"
else
    ok "forbidden form: gh pr comment ... --body \"<text>\" appears nowhere"
fi

if [ "$fail" -ne 0 ]; then
    echo "pr-skill: FAIL — the pr skill's publish and scan rules are load-bearing; fix the skill, not the test." >&2
    exit 1
fi
echo "pr-skill: PASS"
