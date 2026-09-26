#!/bin/bash

# Behavior suite for the docket-run skill's lane-unit counter,
# skills/docket-run/scripts/lane_units.py: the shard count a conductor
# launches for one dispatch, reproduced from wave.js's partition.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs only `python3` — no engine, no
# database, no network.
#
# WHY THIS EXISTS. The same program used to live in SKILL.md as a
# `python3 - <<'PY'` heredoc, which the auto-mode deny rule on interpreter
# code arguments refuses before it runs (measured on one conductor session:
# the block was denied, the conductor rewrote it to a scratch file and ran
# that). The counter is now an installed file. It must keep wave.js's
# arithmetic: writer lanes the engine never co-staged weld into one unit,
# every other lane is its own unit, N is capped at four and floored at one.
# A count that drifts launches the wrong number of shards, silently.
#
# The suite also pins the SKILL.md side: the skill runs the installed file
# and carries no inline interpreter program any more.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${SCRIPT_DIR}/.."
SCRIPT="${LANE_UNITS_PY:-${ROOT}/src/user/claude_code/skills/docket-run/scripts/lane_units.py}"
SKILL="${DOCKET_RUN_SKILL:-${ROOT}/src/user/claude_code/skills/docket-run/SKILL.md}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SCRIPT" ] || fatal "lane_units.py not found at ${SCRIPT}"
[ -f "$SKILL" ] || fatal "SKILL.md not found at ${SKILL}"
command -v python3 >/dev/null 2>&1 || fatal "python3 is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/lane-units.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

# count <rows-json> -> prints N; stderr captured to $WORK/err
count() {
    printf '%s' "$1" > "$WORK/rows.json"
    python3 "$SCRIPT" "$WORK/rows.json" 2> "$WORK/err"
}

# Row builders: writers are class "write"; votes, actions and read lanes are
# not. `stage` is the manifest stage the engine certified.
w() { printf '{"step":"STEP-%s","issue":"%s","kind":"executor","class":"write","stage":%s}' "$1" "$2" "$3"; }
r() { printf '{"step":"STEP-%s","issue":"%s","kind":"executor","class":"read","stage":%s}' "$1" "$2" "$3"; }
v() { printf '{"step":"STEP-%s","issue":"%s","kind":"vote","stage":%s}' "$1" "$2" "$3"; }

# ---- Welding: writers the engine never co-staged are one unit ---------------
n=$(count "[$(w 1 A 0),$(w 2 B 1),$(r 3 C 0)]")
[ "$n" = "2" ]; ok $? "two writer lanes on different stages weld into one unit beside a read lane (got $n)"
grep -q 'unit:A' "$WORK/err" && grep -q 'lane:C' "$WORK/err"; ok $? 'the units are named on stderr, welded writers as unit:<root>, others as lane:<issue>'

# ---- Co-staged writers stay separate ----------------------------------------
n=$(count "[$(w 1 A 0),$(w 2 B 0),$(r 3 C 0)]")
[ "$n" = "3" ]; ok $? "two writer lanes certified on the same stage are separate units (got $n)"

# ---- Certification is per pair --------------------------------------------------
# A and B co-staged, B and C co-staged, A and C never: A-C weld into one unit,
# and B, certified against both, stays its own.
n=$(count "[$(w 1 A 0),$(w 2 B 0),$(w 3 B 1),$(w 4 C 1)]")
[ "$n" = "2" ]; ok $? "only the uncertified pair welds; a writer certified against every other stays its own unit (got $n)"

# ---- Non-writer rows never weld and each issue is one lane --------------------
n=$(count "[$(r 1 A 0),$(r 2 B 1),$(v 3 C 2),$(r 4 A 3)]")
[ "$n" = "3" ]; ok $? "read and vote lanes are one unit per issue, never welded (got $n)"

# ---- A vote row with class write is not a writer -----------------------------
n=$(count '[{"step":"STEP-1","issue":"A","kind":"vote","class":"write","stage":0},{"step":"STEP-2","issue":"B","kind":"executor","class":"write","stage":1}]')
[ "$n" = "2" ]; ok $? "kind vote or action is never a writer lane, whatever its class says (got $n)"

# ---- executor field stands in for a missing class ----------------------------
n=$(count '[{"step":"STEP-1","issue":"A","kind":"executor","executor":"write","stage":0},{"step":"STEP-2","issue":"B","kind":"executor","executor":"write","stage":1}]')
[ "$n" = "1" ]; ok $? "executor == write counts as a writer when class is absent (got $n)"

# ---- Cap and floor -------------------------------------------------------------
n=$(count "[$(r 1 A 0),$(r 2 B 0),$(r 3 C 0),$(r 4 D 0),$(r 5 E 0),$(r 6 F 0)]")
[ "$n" = "4" ]; ok $? "six lanes cap at four shards (got $n)"
n=$(count '[]')
[ "$n" = "1" ]; ok $? "an empty manifest floors at one shard (got $n)"

# ---- A row without an issue is its own lane -----------------------------------
n=$(count '[{"step":"STEP-9","kind":"action","stage":0},{"step":"STEP-8","kind":"action","stage":0}]')
[ "$n" = "2" ]; ok $? "rows without an issue are one lane each, keyed by step (got $n)"

# ---- Input shapes: a JSON array, JSON lines, and a {rows: [...]} envelope --------
printf '%s\n%s\n' "$(w 1 A 0)" "$(r 2 B 0)" > "$WORK/rows.jsonl"
n=$(python3 "$SCRIPT" "$WORK/rows.jsonl" 2>/dev/null)
[ "$n" = "2" ]; ok $? "JSON lines input (the paged rows file) is read the same as an array (got $n)"
n=$(count "{\"rows\":[$(w 1 A 0),$(w 2 B 1)]}")
[ "$n" = "1" ]; ok $? "a {rows: [...]} envelope is unwrapped (got $n)"

# ---- Only N reaches stdout ------------------------------------------------------
out=$(count "[$(w 1 A 0),$(r 2 B 0)]")
[ "$(printf '%s' "$out" | wc -l | tr -d ' ')" = "0" ] && [ "$out" = "2" ]; ok $? "stdout carries the number alone, so \$(…) capture is clean (got '$out')"

# ---- Bad usage fails loudly -------------------------------------------------------
python3 "$SCRIPT" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'no argument is a non-zero exit'
printf 'not json' > "$WORK/bad.json"
python3 "$SCRIPT" "$WORK/bad.json" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'unparseable input is a non-zero exit, never a count'

# ---- seat_roster.py: the conversational gate's voters from the policy ------------
ROSTER="${SEAT_ROSTER_PY:-${ROOT}/src/user/claude_code/skills/docket-run/scripts/seat_roster.py}"
[ -f "$ROSTER" ] || fatal "seat_roster.py not found at ${ROSTER}"
cat > "$WORK/policy.toml" <<'TOML'
# fixture policy
[executors]   # seats and executors
tribunal-architecture = { variant = "judge-a" }
tribunal-security = { variant = "judge-s", note = "x" }
implement = { variant = "writer" }

[variants]
judge-a = { model = "opus", effort = "high", tier = "review" }
judge-s = { model = "fable", effort = "max" }
writer = { model = "sonnet", effort = "medium" }

[other]
tribunal-correctness = { variant = "judge-a" }
TOML
out=$(python3 "$ROSTER" tribunal-architecture,tribunal-security "$WORK/policy.toml" 2>"$WORK/err")
[ "$out" = '[{"seat": "tribunal-architecture", "model": "opus", "effort": "high", "variant": "judge-a"}, {"seat": "tribunal-security", "model": "fable", "effort": "max", "variant": "judge-s"}]' ]
ok $? "seat_roster resolves each seat's variant, model and effort from the two inline tables (got $out)"
python3 "$ROSTER" tribunal-architecture,tribunal-correctness "$WORK/policy.toml" > "$WORK/out" 2>"$WORK/err"; rc=$?
[ "$rc" -ne 0 ] && [ ! -s "$WORK/out" ] && grep -q 'tribunal-correctness' "$WORK/err"
ok $? "a seat outside [executors] is a non-zero exit naming it, never a voter with a null field (rc=$rc)"
python3 "$ROSTER" "" "$WORK/policy.toml" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'an empty seat list is a non-zero exit'

# ---- SKILL.md runs the installed files and carries no inline program -----------
grep -qF 'python3 ~/.claude/skills/docket-run/scripts/lane_units.py' "$SKILL"; ok $? \
    'SKILL.md runs lane_units.py by its installed path'
grep -qF 'python3 ~/.claude/skills/docket-run/scripts/seat_roster.py' "$SKILL"; ok $? \
    'SKILL.md runs seat_roster.py by its installed path'
! grep -qE "^(python[0-9]*|node) +-( |e |-eval|p )" "$SKILL"; ok $? \
    'SKILL.md carries no inline interpreter program (stdin heredoc or code argument) the deny rule refuses'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
