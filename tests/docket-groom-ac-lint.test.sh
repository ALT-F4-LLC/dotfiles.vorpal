#!/bin/bash

# Behavior suite for docket-groom's criterion citation lint
# (skills/docket-groom/scripts/ac-lint.sh).
#
# WHY THIS EXISTS. docket-groom once wrote criteria citing
# docket-guard-prepass.awk:168 when the line it meant had moved to 178, and
# executors spent rounds re-deriving what the criterion pointed at. The lint
# is the gate that stops such a criterion before it is written, and each of
# its rules has a failure that reads as success: a lint that checks only that
# the cited file exists passes a drifted line; one that rejects every line
# number, or every expression anchor, blocks valid criteria; one that accepts
# an expression whenever the file exists passes an anchor matching nothing or
# several lines; and one that accepts a bare path:line keeps the drift class
# alive.
#
# HOW. Builds a fixture repository under $TMPDIR with a 200-line
# docket-guard-prepass.awk whose line 168 lacks the cited expression, then runs
# the lint against that commit with criterion text on stdin. Needs git, awk
# and grep; no network, no engine.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINT="${AC_LINT:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-groom/scripts/ac-lint.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$LINT" ] || fatal "ac-lint.sh not found at ${LINT}"
command -v git >/dev/null 2>&1 || fatal "git is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-groom-ac-lint.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
REPO="${WORK}/repo"
mkdir -p "${REPO}/src/user/claude_code/hooks" "${REPO}/other"
awk 'BEGIN {
    for (i = 1; i <= 200; i++) {
        if (i == 168) print "    chunk = \"\""
        else if (i == 178) print "function marked_group(content,   chunk, m, k) {"
        else if (i == 120 || i == 121) print "    GROUP++"
        else printf "# filler line %d\n", i
    }
}' > "${REPO}/src/user/claude_code/hooks/docket-guard-prepass.awk"
printf 'x\n' > "${REPO}/other/twin.sh"
mkdir -p "${REPO}/more" && printf 'x\n' > "${REPO}/more/twin.sh"
git -C "$REPO" init -q
git -C "$REPO" -c user.email=t@t -c user.name=t add -A
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q -m fixture
BASE=$(git -C "$REPO" rev-parse HEAD)
P=src/user/claude_code/hooks/docket-guard-prepass.awk

# lint <criterion text>: exit status in $RC, stdout in $OUT.
lint() {
    OUT=$(printf '%s\n' "$1" | bash "$LINT" --base "$BASE" --repo "$REPO" 2>&1)
    RC=$?
}
expect() { # <want-rc: 0 or nonzero> <label>
    if [ "$1" = 0 ] && [ "$RC" -eq 0 ]; then pass "$2 (exit 0)"
    elif [ "$1" = nonzero ] && [ "$RC" -ne 0 ]; then pass "$2 (exit ${RC})"
    else fail "$2 (want $1, got exit ${RC}: ${OUT})"
    fi
}

# A path:line whose line lacks the quoted expression is unresolved.
lint "The fix lands in ${P}:168 \`function marked_group\`."
expect nonzero "path:168 whose line lacks the expression"
case "$OUT" in
    *unresolved*"${P}:168"*) pass "the drifted citation is reported as unresolved" ;;
    *) fail "the drifted citation is not reported as unresolved: ${OUT}" ;;
esac

# The same expression at its real line resolves.
lint "The fix lands in ${P}:178 \`function marked_group\`."
expect 0 "path:178 whose line contains the expression"
lint "The fix lands in ${P}:170-180 (\`function marked_group\`)."
expect 0 "path:N-M whose range contains the expression"
lint "A bare file name: docket-guard-prepass.awk:178 \"function marked_group\"."
expect 0 "a unique bare file name with a line and a double-quoted expression"

# An expression anchor with no line number resolves when it occurs once.
lint "Edit ${P} \`function marked_group\` to join fragments."
expect 0 "path plus an expression found exactly once"
lint "Edit \`${P}\` \`function marked_group\` to join fragments."
expect 0 "a backtick-quoted path plus an expression found exactly once"

# A path that is not its span's first token: the span's closing backtick
# does not open an expression, and a span right after it still anchors.
lint "Check: \`bash ${P}\` exits 0 (run by \`function marked_group\`)."
expect 0 "a path after a command inside its span, followed by prose"
lint "Check: \`bash ${P}\` \`function never_written\` is gone."
expect nonzero "a path after a command inside its span, then an unresolved expression"

# Zero or several occurrences are refused.
lint "Edit ${P} \`function never_written\` to join fragments."
expect nonzero "path plus an expression found zero times"
lint "Edit ${P} \`GROUP++\` to count groups."
expect nonzero "path plus an expression found on two lines"

# A path:line with no quoted expression is refused even when the line exists.
lint "See ${P}:168 for the split."
expect nonzero "bare path:168 with no expression"

# Prose and non-repository tokens are not citations.
lint "Run make test against 127.0.0.1:8080, e.g. on the docket-guard-prepass.awk file."
expect 0 "a host:port and a bare file name with no line or expression"

# A citation that cannot name one file is refused.
lint "See twin.sh:1 \`x\`."
expect nonzero "a bare file name shared by two files"
lint "See src/missing/file.sh:3 \`x\`."
expect nonzero "a path that does not exist at the base"

# A moving base. A criterion once measured assertions from
# `git merge-base HEAD main`, where a sibling's earlier commit had already
# removed four assertion lines, so it read unmet whatever the fix did; the
# amended text names the literal sha.
lintShared() { # <criterion text>: --shared-base, exit status in $RC, stdout in $OUT.
    OUT=$(printf '%s\n' "$1" | bash "$LINT" --base "$BASE" --repo "$REPO" --shared-base 2>&1)
    RC=$?
}
ORIG_AC3='- No assertion is dropped: Verify: `test "$(git diff -U0 $(git merge-base HEAD main) -- internal/engine/report_test.go | grep -cE '"'"'^-[^-].*(assert|require)'"'"')" -le 0` exits 0. Mutant: deleting one assertion line.'
AMENDED_AC3='- No assertion is dropped: Verify: `test "$(git diff -U0 563519c -- internal/engine/report_test.go | grep -cE '"'"'^-[^-].*(assert|require)'"'"')" -le 0` exits 0. Mutant: deleting one assertion line.'
lintShared "$ORIG_AC3"
expect nonzero "a merge-base Verify on an issue with siblings (shared base)"
case "$OUT" in *moving-base*merge-base*) pass "the merge-base criterion is reported as moving-base" ;; *) fail "the merge-base criterion is not reported as moving-base: ${OUT}" ;; esac
lintShared "$AMENDED_AC3"
expect 0 "the amended criterion with a literal base sha (shared base)"
lint "$ORIG_AC3"
expect 0 "a merge-base Verify on an issue with no siblings or dependencies"
lintShared '- Done: Verify: `git diff --stat main..HEAD -- src/a.sh` prints one line.'
expect nonzero "a Verify range from bare main (shared base)"
case "$OUT" in *moving-base*"measures from main"*) pass "the bare-main range is reported as measuring from main" ;; *) fail "the bare-main range is not reported as measuring from main: ${OUT}" ;; esac
lintShared '- Done: Verify: `git log --oneline origin/main -- src/a.sh` prints nothing.'
expect nonzero "a Verify log from origin/main (shared base)"
lintShared '- Done: Verify: `git diff -U0 563519c -- cmd/main.go internal/main_test.go` prints nothing.'
expect 0 "file names containing main are not a moving base (shared base)"
lintShared '- Done: Verify: `git grep -n main -- src/a.sh` prints nothing.'
expect 0 "git grep for the word main is not a base (shared base)"
lintShared 'Prose only: the branch main moves, and `git merge-base HEAD main` is how it was once measured.'
expect 0 "a merge-base mentioned outside a Verify command (shared base)"

# Wrapped and fenced criteria are joined before they are read.
lintShared '- No assertion is dropped: Verify: `test "$(git diff -U0
  $(git merge-base HEAD main) -- internal/engine/report_test.go | grep -c assert)" -le 0`
  exits 0. Mutant: deleting one assertion line.'
expect nonzero "a merge-base Verify wrapped inside its command (shared base)"
lintShared '- No assertion is dropped. Verify:
  `git diff -U0 main...HEAD -- internal/engine/report_test.go` prints nothing.'
expect nonzero "a Verify whose command starts on the next line (shared base)"
lintShared '- No assertion is dropped. Verify:
  ```
  git diff -U0 $(git merge-base HEAD main) -- a.go
  ```
  Mutant: delete one assertion.'
expect nonzero "a fenced Verify command (shared base)"
lintShared '- Done. verify: `git log --oneline main..HEAD -- a.go` prints nothing.'
expect nonzero "a lower-case verify label (shared base)"
# Global git options do not hide the subcommand.
lintShared '- Done. Verify: `git -C repo diff main -- a.go` prints nothing.'
expect nonzero "git -C before the subcommand (shared base)"
lintShared '- Done. Verify: `git --no-pager diff main` prints nothing.'
expect nonzero "a global option before the subcommand (shared base)"
lintShared '- Done. Verify: `git -C repo merge-base HEAD main` prints a sha.'
expect nonzero "git -C before merge-base (shared base)"
# The report names the offending command.
lintShared '- Done. Verify: `git diff main...HEAD -- a.go` prints nothing.'
case "$OUT" in *moving-base*"git diff main...HEAD"*"measures from main"*) pass "the report quotes the command and says it measures from main" ;; *) fail "the report does not quote the command: ${OUT}" ;; esac
lintShared '- Done. Verify: `git show main:src/a.sh` prints the file.'
expect nonzero "git show of a main path (shared base)"
lintShared '- Done. Verify: `git diff 563519c..main -- a.go` prints nothing.'
expect nonzero "a range ending at main (shared base)"
# Stable forms and prose pass.
lintShared '- Done. Verify: `git log --oneline 563519c..HEAD` lists one commit on the main branch.'
expect 0 "prose after the command that mentions main (shared base)"
lintShared '- Done. Verify: `git diff 563519c -- main` prints nothing.'
expect 0 "a pathspec named main (shared base)"
lintShared '- Done. Verify: `git diff 563519c | grep main` prints nothing.'
expect 0 "main after a pipe (shared base)"
lintShared '- Done. Verify: `git merge-base --is-ancestor 563519c HEAD` exits 0.'
expect 0 "merge-base --is-ancestor with a literal sha (shared base)"
lintShared '- Done. Verify: `git merge-base --is-ancestor 563519c main` exits 0.'
expect nonzero "merge-base --is-ancestor against main (shared base)"
lintShared '- Done. Verify: `git diff 563519c -- src/main.sh` prints nothing.'
expect 0 "a path containing main.sh (shared base)"
lintShared '- First. Verify: `git diff 563519c -- a.go` prints nothing.
- Second. Verify: `git diff main -- b.go` prints nothing.'
expect nonzero "one moving-base criterion among several (shared base)"
case "$OUT" in *"git diff main -- b.go"*) pass "only the offending criterion is quoted" ;; *) fail "the offending criterion is not quoted: ${OUT}" ;; esac

# A base that is not a commit is a usage error, not a pass.
OUT=$(printf 'x\n' | bash "$LINT" --base 0000000000000000000000000000000000000000 --repo "$REPO" 2>&1)
RC=$?
[ "$RC" -eq 2 ] && pass "an unknown base exits 2" || fail "an unknown base exits ${RC}: ${OUT}"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
