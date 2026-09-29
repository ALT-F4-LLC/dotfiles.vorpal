#!/bin/bash

# Behavior suite for the docket-run skill's launch splitter,
# skills/docket-run/scripts/lane_units.py: how a conductor splits one
# dispatch into wave launches, one per lane unit, each holding only its
# own rows and its share of the manifest's class headroom.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs only `python3` — no engine, no
# database, no network.
#
# WHY THIS EXISTS. A launch receives only its own rows, so the partition
# and the class headroom a launch cannot see from its own rows are computed
# here, before launch. Writer lanes the engine never co-staged weld into one
# unit (wave.js serializes them through an in-flight set no sibling launch
# sees); every other lane is its own unit; units above LAUNCH_CAP (20) pack
# onto 20 launches. Every row lands in exactly one launch file. A split that
# drifts runs a lane twice, not at all, or over-admits a class.
#
# The suite also pins the SKILL.md side: the skill runs the installed file
# and carries no inline interpreter program. The same program once lived in
# SKILL.md as a `python3 - <<'PY'` heredoc, which the auto-mode deny rule on
# interpreter code arguments refuses before it runs.

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

# count <rows-json> -> prints N; launch files land in $WORK/launch (fresh per
# call), stderr captured to $WORK/err
count() {
    printf '%s' "$1" > "$WORK/rows.json"
    rm -rf "$WORK/launch"
    python3 "$SCRIPT" "$WORK/rows.json" "$WORK/launch" 2> "$WORK/err"
}
# steps_of <launch-index> -> the launch file's step ids, space-joined
steps_of() {
    python3 -c 'import json,sys; print(" ".join(json.loads(l)["step"] for l in open(sys.argv[1]) if l.strip()))' "$WORK/launch/launch-$1.jsonl"
}
# summary <python-expr over s, the launches.json list> -> printed value
summary() {
    python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))' "$WORK/launch/launches.json" "$1"
}

# Row builders: writers are class "write"; votes, actions and read lanes are
# not. `stage` is the manifest stage the engine certified.
w() { printf '{"step":"STEP-%s","issue":"%s","kind":"executor","class":"write","stage":%s}' "$1" "$2" "$3"; }
r() { printf '{"step":"STEP-%s","issue":"%s","kind":"executor","class":"read","stage":%s}' "$1" "$2" "$3"; }
v() { printf '{"step":"STEP-%s","issue":"%s","kind":"vote","stage":%s}' "$1" "$2" "$3"; }

# ---- Welding: writers the engine never co-staged are one unit ---------------
n=$(count "[$(w 1 A 0),$(w 2 B 1),$(r 3 C 0)]")
[ "$n" = "2" ]; ok $? "two writer lanes on different stages weld into one unit beside a read lane (got $n)"
grep -q 'unit:A -> launch' "$WORK/err" && grep -q 'lane:C -> launch' "$WORK/err"; ok $? 'the units and their launches are named on stderr, welded writers as unit:<root>, others as lane:<issue>'
[ "$(summary '[x["lanes"] for x in s if "A" in x["lanes"]][0]')" = "['A', 'B']" ]; ok $? 'welded writer lanes share one launch file'

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

# ---- One launch per unit, capped at 20 -------------------------------------------
n=$(count "[$(r 1 A 0),$(r 2 B 0),$(r 3 C 0),$(r 4 D 0),$(r 5 E 0),$(r 6 F 0)]")
[ "$n" = "6" ]; ok $? "six lanes are six launches (got $n)"
many=""
for i in $(seq 1 25); do many="${many:+$many,}$(r "$i" "I$i" 0)"; done
n=$(count "[$many]")
[ "$n" = "20" ]; ok $? "25 lanes pack onto the 20-launch cap (got $n)"
grep -q 'packed: 25 units onto 20 launches' "$WORK/err"; ok $? 'packing past the cap is named on stderr'
[ "$(summary 'sum(x["rows"] for x in s)')" = "25" ] && [ "$(summary 'sorted(len(x["lanes"]) for x in s)[-1]')" = "2" ]
ok $? 'packed launches still hold every row once, at most two lanes each'
n=$(count '[]')
[ "$n" = "0" ]; ok $? "an empty manifest is zero launches (got $n)"

# ---- Every row lands in exactly one launch, in manifest order ---------------------
n=$(count "[$(r 1 A 0),$(w 2 B 0),$(r 3 A 1),$(v 4 C 1),$(w 5 B 1)]")
all="$(for i in $(seq 0 $((n - 1))); do steps_of "$i"; done | tr '\n' ' ')"
[ "$(printf '%s' "$all" | tr ' ' '\n' | grep -c STEP)" = "5" ] && [ "$(printf '%s' "$all" | tr ' ' '\n' | grep STEP | sort | uniq -d)" = "" ]
ok $? "the launch files partition the manifest: every row once, none twice (got '$all')"
a=$(summary '[x["index"] for x in s if "A" in x["lanes"]][0]')
[ "$(steps_of "$a")" = "STEP-1 STEP-3" ]; ok $? 'a lane keeps its rows in manifest order in its own launch'
[ "$(summary 'sorted({x["of"] for x in s})')" = "[3]" ]; ok $? 'every launch carries the same of'

# ---- Class headroom from the whole manifest, shared among holders ----------------
# read is co-staged 3 wide at stage 0 across three lanes, so each of the three
# launches holding read gets 1; write is 2 wide at stage 1 across B and D.
n=$(count "[$(r 1 A 0),$(r 2 B 0),$(r 3 C 0),$(w 4 B 1),$(w 5 D 1)]")
[ "$(summary '[x["classCap"].get("read") for x in s if "A" in x["lanes"]][0]')" = "1" ]
ok $? 'a class spread over three launches gives each its third of the certified 3'
[ "$(summary '[x["classCap"].get("write") for x in s if "D" in x["lanes"]][0]')" = "1" ] && [ "$(summary '[x["classCap"].get("write") for x in s if "A" in x["lanes"]][0]')" = "None" ]
ok $? 'classCap names only the classes a launch holds'
# one lane with five same-stage reads: its launch alone holds read, keeps all 5
n=$(count "[$(r 1 A 0),$(r 2 A 0),$(r 3 A 0),$(r 4 A 0),$(r 5 A 0),$(w 6 B 0)]")
[ "$(summary '[x["classCap"]["read"] for x in s if "A" in x["lanes"]][0]')" = "5" ]
ok $? 'a class held by one launch keeps the full certified count'
# certified 5 over 3 holders: 2, 2, 1 by rank
rows5="$(r 1 A 0),$(r 2 A 0),$(r 3 B 0),$(r 4 B 0),$(r 5 C 0),$(w 6 A 1),$(w 7 A 2),$(w 8 A 3)"
n=$(count "[$rows5]")
[ "$(summary 'sorted((x["index"], x["classCap"]["read"]) for x in s)')" = "[(0, 2), (1, 2), (2, 1)]" ]
ok $? 'a remainder goes to the lowest-ranked holders, so the shares sum to the certified count'

# ---- A row without an issue is its own lane -----------------------------------
n=$(count '[{"step":"STEP-9","kind":"action","stage":0},{"step":"STEP-8","kind":"action","stage":0}]')
[ "$n" = "2" ]; ok $? "rows without an issue are one lane each, keyed by step (got $n)"

# ---- Input shapes: a JSON array, JSON lines, and a {rows: [...]} envelope --------
printf '%s\n%s\n' "$(w 1 A 0)" "$(r 2 B 0)" > "$WORK/rows.jsonl"
n=$(python3 "$SCRIPT" "$WORK/rows.jsonl" "$WORK/out-jsonl" 2>/dev/null)
[ "$n" = "2" ]; ok $? "JSON lines input (the paged rows file) is read the same as an array (got $n)"
n=$(count "{\"rows\":[$(w 1 A 0),$(w 2 B 1)]}")
[ "$n" = "1" ]; ok $? "a {rows: [...]} envelope is unwrapped (got $n)"

# ---- Only N reaches stdout ------------------------------------------------------
out=$(count "[$(w 1 A 0),$(r 2 B 0)]")
[ "$(printf '%s' "$out" | wc -l | tr -d ' ')" = "0" ] && [ "$out" = "2" ]; ok $? "stdout carries the number alone, so \$(…) capture is clean (got '$out')"

# ---- harnessCap: min(16, max(1, cpus - 2)) on every launches.json entry -------
# LANE_UNITS_CPUS stands in for os.cpu_count() so the host does not decide.
for pair in 1:1 2:1 10:8 18:16 64:16; do
    cpus=${pair%%:*} want=${pair##*:}
    out=$(LANE_UNITS_CPUS=$cpus count "[$(w 1 A 0),$(r 2 B 0),$(r 3 C 0)]")
    got=$(summary 'sorted({x["harnessCap"] for x in s})')
    [ "$out" = "3" ] && [ "$got" = "[$want]" ] && [ "$(summary 'len(s)')" = "3" ]
    ok $? "LANE_UNITS_CPUS=$cpus gives every launch harnessCap $want, stdout still N alone (got '$out', caps $got)"
done

# ---- Bad usage fails loudly -------------------------------------------------------
python3 "$SCRIPT" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'no argument is a non-zero exit'
python3 "$SCRIPT" "$WORK/rows.json" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'a missing out-dir is a non-zero exit'
printf 'not json' > "$WORK/bad.json"
python3 "$SCRIPT" "$WORK/bad.json" "$WORK/out-bad" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'unparseable input is a non-zero exit, never a count'

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
