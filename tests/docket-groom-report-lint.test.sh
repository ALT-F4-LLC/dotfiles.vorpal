#!/bin/bash

# Behavior suite for the hand-back lint
# (skills/docket-groom/scripts/report-lint.sh).
#
# WHY THIS EXISTS. A docket-groom pass over one epic ended four turns on a
# progress report ("Still open for this pass", "Still to do") and closed on
# a final report that handed back decisions ("Whether to retarget the edge
# is your call") and skipped checks ("I did not re-judge routing"). Each
# stop made the operator type the next step. The lint reads the draft before
# the turn ends. Each rule has a failure that reads as success: a lint that
# matches case-sensitively passes "Still Open"; one that reads only the
# first line passes a late hand-back; one that exits 0 on unreadable input
# passes a draft it never saw. The clean case keeps the lint from refusing a
# report whose gaps use the gate-state wording.
#
# HOW. Feeds drafts through a file and stdin. Needs bash and grep.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINT="${REPORT_LINT:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-groom/scripts/report-lint.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1"; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$LINT" ] || fatal "report-lint.sh not found at ${LINT}"
[ -x "$LINT" ] && pass "report-lint.sh is executable" || fail "report-lint.sh is not executable"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-groom-report-lint.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# expect <name> <exit> <draft text> [stdout substring]
expect() {
    local name="$1" want="$2" text="$3" sub="${4:-}" out rc
    printf '%s\n' "$text" > "${WORK}/draft.txt"
    out=$("$LINT" "${WORK}/draft.txt" 2>&1); rc=$?
    if [ "$rc" -ne "$want" ]; then fail "${name}: exit ${rc}, want ${want}"; return; fi
    if [ -n "$sub" ] && ! printf '%s' "$out" | grep -qF -- "$sub"; then fail "${name}: output lacks '${sub}'"; return; fi
    pass "$name"
}

expect "clean report passes" 0 $'All 13 repairs applied.\nBlocked on the operator: 4072 waits on the store path 4037 decides.'
expect "still-open list fails" 1 $'Round 2 applied.\nStill open for this pass: splits.' "line 2:"
expect "case-insensitive match" 1 'STILL TO DO: relation corrections.'
expect "late hand-back is found" 1 $'a\nb\nc\nWhether to retarget the edge is your call.' "line 4:"
expect "skipped re-judge fails" 1 'I did not re-judge routing on the 63 new pieces.'
expect "loose note fails" 1 'That check belongs with the stream issue.'
expect "engine-coverage wording passes" 0 "engine judging waits for the next pass from the engine checkout"
expect "gate-state wording passes" 0 "Blocked on the operator: 4072 still needs the store path decision."
expect "re-parent defense passes" 0 "Re-parent 4071: it belongs with the auth epic."
expect "reopen is not open items" 0 "Reopen items after the split."
expect "matches-siblings hand-back fails" 1 "Kept because it matches its siblings."
expect "check-belongs hand-back fails" 1 "That check belongs with the stream issue."
expect "closing offer fails" 1 'Want me to continue with the criteria?'
expect "bare waiting-on id fails" 1 'HRN-1818: waiting on HRN-2691.' "line 1:"
expect "bare waiting-on id at line end fails" 1 'waiting on HRN-2691'
expect "waiting-on id with route passes" 0 'HRN-1818: waiting on HRN-2691 (route-run).'
expect "direct-work form passes" 0 'HRN-1818: waiting on direct work: HRN-2691 (route-direct), do it through /goal.'
expect "waiting on a named condition passes" 0 'HRN-1818: waiting on the measurement window the body names.'
expect "two-digit id with route passes" 0 'waiting on HRN-12 (route-run)'

out=$(printf 'Still open: x\n' | "$LINT" 2>&1); rc=$?
[ "$rc" -eq 1 ] && pass "reads stdin without a file" || fail "stdin: exit ${rc}, want 1"

"$LINT" "${WORK}/missing.txt" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "unreadable file exits 2" || fail "unreadable file: exit ${rc}, want 2"

"$LINT" a b >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "two arguments exit 2" || fail "two arguments: exit ${rc}, want 2"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
