#!/bin/bash

# Behavior suite for the docket-run skill's launch splitter,
# skills/docket-run/scripts/lane_units.py: how a conductor splits one
# dispatch into wave launches, one per issue lane, each holding only its
# own rows and its share of the manifest's class headroom.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs `python3`, `git` and `jq` — no
# engine, no database, no network.
#
# WHY THIS EXISTS. A launch receives only its own rows, so the partition
# and the class headroom a launch cannot see from its own rows are computed
# here, before launch. Every issue lane is its own launch, never welded or
# packed with another; lanes past LAUNCH_CAP (20) go to deferred.jsonl for
# the next dispatch. Every row lands in exactly one launch file or the
# deferred file. A split that drifts runs a lane twice, not at all, or
# over-admits a class.
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

command -v git >/dev/null 2>&1 || fatal "git is required to run this test"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

# lane_units.py writes each launch's rows module under the git toplevel it
# runs in, so every run happens inside a throwaway fixture repository, never
# this checkout. GIT_CEILING_DIRECTORIES keeps the outside-work-tree case from
# finding a repository above $WORK.
export GIT_CEILING_DIRECTORIES="$WORK"
git init -q "$WORK/repo" || fatal "git init failed"
mkdir -p "$WORK/repo/sub/deeper" "$WORK/outside"
TOP=$(git -C "$WORK/repo" rev-parse --show-toplevel) || fatal "fixture toplevel lookup failed"
lu() { (cd "$WORK/repo" && python3 "$SCRIPT" "$@"); }

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
    lu "$WORK/rows.json" "$WORK/launch" 2> "$WORK/err"
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

# ---- One issue, one launch: writer lanes are never welded ---------------------
n=$(count "[$(w 1 A 0),$(w 2 B 1),$(r 3 C 0)]")
[ "$n" = "3" ]; ok $? "two writer lanes on different stages are two launches beside a read lane (got $n)"
grep -q 'lane:A -> launch' "$WORK/err" && grep -q 'lane:B -> launch' "$WORK/err" && grep -q 'lane:C -> launch' "$WORK/err"; ok $? 'each lane and its launch is named on stderr as lane:<issue>'
[ "$(summary 'sorted(len(x["lanes"]) for x in s)')" = "[1, 1, 1]" ]; ok $? 'every launch holds exactly one lane'

# ---- Co-staged writers stay separate ----------------------------------------
n=$(count "[$(w 1 A 0),$(w 2 B 0),$(r 3 C 0)]")
[ "$n" = "3" ]; ok $? "two writer lanes certified on the same stage are separate launches (got $n)"

# ---- Certification never merges lanes -----------------------------------------
n=$(count "[$(w 1 A 0),$(w 2 B 0),$(w 3 B 1),$(w 4 C 1)]")
[ "$n" = "3" ]; ok $? "three writer lanes are three launches whatever their co-staging (got $n)"

# ---- Read and vote lanes: one launch per issue ---------------------------------
n=$(count "[$(r 1 A 0),$(r 2 B 1),$(v 3 C 2),$(r 4 A 3)]")
[ "$n" = "3" ]; ok $? "read and vote lanes are one launch per issue (got $n)"

# ---- executor field stands in for a missing class ----------------------------
n=$(count '[{"step":"STEP-1","issue":"A","kind":"executor","executor":"write","stage":0},{"step":"STEP-2","issue":"B","kind":"executor","executor":"write","stage":1}]')
[ "$n" = "2" ] && [ "$(summary '[x["classCap"] for x in s]')" = "[{'write': 1}, {'write': 1}]" ]
ok $? "executor == write keys the write class when class is absent, one launch per lane (got $n)"

# ---- One launch per lane, capped at 20; the rest defer ------------------------------
n=$(count "[$(r 1 A 0),$(r 2 B 0),$(r 3 C 0),$(r 4 D 0),$(r 5 E 0),$(r 6 F 0)]")
[ "$n" = "6" ]; ok $? "six issues are six launches (got $n)"
[ -f "$WORK/launch/deferred.jsonl" ] && [ ! -s "$WORK/launch/deferred.jsonl" ]; ok $? 'deferred.jsonl exists and is empty under the cap'
many=""
for i in $(seq 1 25); do many="${many:+$many,}$(r "$i" "I$i" 0)"; done
n=$(count "[$many]")
[ "$n" = "20" ]; ok $? "25 lanes launch the first 20 (got $n)"
[ "$(summary 'sum(x["rows"] for x in s)')" = "20" ] && [ "$(summary 'sorted({len(x["lanes"]) for x in s})')" = "[1]" ]
ok $? 'capped launches still hold one lane each, never packed'
[ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "5" ] && grep -q '"issue":"I21"' "$WORK/launch/deferred.jsonl" && ! grep -q '"issue":"I20"' "$WORK/launch/deferred.jsonl"
ok $? 'lanes past the cap land in deferred.jsonl, latest in manifest order'
grep -q 'deferred: 5 lane(s) past the 20-launch cap' "$WORK/err" && grep -q 'I25' "$WORK/err"; ok $? 'the deferral is named on stderr with its lanes'
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
n=$(lu "$WORK/rows.jsonl" "$WORK/out-jsonl" 2>/dev/null)
[ "$n" = "2" ]; ok $? "JSON lines input (the paged rows file) is read the same as an array (got $n)"
n=$(count "{\"rows\":[$(w 1 A 0),$(w 2 B 1)]}")
[ "$n" = "2" ]; ok $? "a {rows: [...]} envelope is unwrapped, one launch per lane (got $n)"
n=$(count "{\"rows\":[$(r 1 A 0),$(r 2 B 0)]}"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "2" ] && [ "$(summary 'sum(x["rows"] for x in s)')" = "2" ]
ok $? "an envelope of two reader lanes is two rows, not one row object (rc=$rc, got $n)"
# jq -c '.data.rows[] | select(.kind != "human")' over a one-row dispatch
# emits one bare object on one line.
row=$(r 1 A 0)
printf '%s\n' "$row" > "$WORK/one.jsonl"
rm -rf "$WORK/launch"
n=$(lu "$WORK/one.jsonl" "$WORK/launch" 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "1" ] && [ "$(cat "$WORK/launch/launch-0.jsonl")" = "$row" ]
ok $? "a rows file holding one row object is one launch holding that row (rc=$rc, got '$n': $(head -c 200 "$WORK/err"))"
printf '42\n' > "$WORK/scalar.json"
lu "$WORK/scalar.json" "$WORK/out-scalar" > /dev/null 2> "$WORK/err"; rc=$?
[ "$rc" -eq 1 ] && grep -q 'holds neither a rows array nor JSON lines' "$WORK/err"
ok $? "a top-level scalar is still exit 1 naming the accepted shapes (rc=$rc)"

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
# Without the override the cap follows the host's online CPUs, checked against
# getconf rather than lane_units.py. PYTHON_CPU_COUNT (Python 3.13+) would
# steer os.cpu_count() away from getconf, so it is unset too.
online=$(getconf _NPROCESSORS_ONLN)
want=$((online - 2)); [ "$want" -lt 1 ] && want=1; [ "$want" -gt 16 ] && want=16
printf '%s' "[$(w 1 A 0),$(r 2 B 0),$(r 3 C 0)]" > "$WORK/rows.json"
rm -rf "$WORK/launch"
out=$(cd "$WORK/repo" && env -u LANE_UNITS_CPUS -u PYTHON_CPU_COUNT python3 "$SCRIPT" "$WORK/rows.json" "$WORK/launch" 2> "$WORK/err")
got=$(summary 'sorted({x["harnessCap"] for x in s})')
[ "$out" = "3" ] && [ "$got" = "[$want]" ] && [ "$(summary 'len(s)')" = "3" ]
ok $? "with LANE_UNITS_CPUS unset every launch has harnessCap min(16, max(1, $online - 2)) = $want (got '$out', caps $got)"

# ---- Generated launch args: a rows module by reference, never inline rows ------
# The conductor passes args-<i>.json to wave.js unedited, so the object is
# complete and small: the rows ride in a module under
# <toplevel>/.claude/docket-packets/ that wave.js loads, and the module
# exports rows_sha256, the sha256 of launch-<i>.jsonl's bytes, which wave.js
# compares with the args' rows_sha256.
fat() { # <n> <issue> <stage> — a kept row with the fields the engine renders
    printf '{"step":"STEP-%s","issue":"%s","run":"RUN-125","kind":"executor","class":"read","executor":"review-correctness","instance":"review@0#%s","stage":%s,"attempt":0,"model":"sonnet","effort":"medium","variant":"judge-sonnet","scope":["src/user/claude_code/workflows/wave.js"]}' "$1" "$2" "$1" "$3"
}
big=""
for lane in 1 2 3 4 5 6; do
    for k in $(seq 1 20); do big="${big:+$big,}$(fat "$lane$k" "DOT-$lane" "$((k % 4))")"; done
done
printf '[%s]' "$big" > "$WORK/big.json"
[ "$(jq length "$WORK/big.json")" = "120" ] || fatal "the 120-row fixture holds $(jq length "$WORK/big.json") rows"
TRIBUNAL=/home/op/.claude/workflows/tribunal.js
printf '{"DOT-2":"%s","DOT-5":"%s"}' "$(printf 'a%.0s' $(seq 1 40))" "$(printf 'b%.0s' $(seq 1 40))" > "$WORK/integrated.json"
rm -rf "$WORK/gen"
n=$(cd "$WORK/repo/sub/deeper" && LANE_UNITS_CPUS=10 python3 "$SCRIPT" "$WORK/big.json" "$WORK/gen" \
    --tribunal "$TRIBUNAL" --integrated "$WORK/integrated.json" 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "6" ]; ok $? "the 120-row fixture splits into six launches from a subdirectory (rc=$rc, got '$n': $(head -c 300 "$WORK/err"))"
packets="$TOP/.claude/docket-packets"
for i in 0 1 2 3 4 5; do  # the fixture's six lanes, whatever the script printed
    args="$WORK/gen/args-$i.json"
    [ -f "$args" ] || { ok 1 "launch $i: args-$i.json is written"; continue; }
    size=$(jq -c . "$args" | wc -c | tr -d ' ')
    jq -e 'has("rows") | not' "$args" > /dev/null && [ "$size" -lt 2048 ]
    ok $? "launch $i: the args carry no inline rows and serialize under 2048 bytes (got $size bytes, rows type $(jq -r '.rows | type' "$args"))"
    mod=$(jq -r '.rowsModule // ""' "$args")
    want=$(shasum -a 256 "$WORK/gen/launch-$i.jsonl" | cut -d' ' -f1)
    case "$mod" in "$packets"/*.js) under=0 ;; *) under=1 ;; esac
    [ "$under" -eq 0 ] && [ -f "$mod" ]
    ok $? "launch $i: rowsModule names an existing module under <toplevel>/.claude/docket-packets/ (got $mod)"
    body=$(sed -n 's/^return //p' "$mod" 2>/dev/null)
    [ "$(jq -r '.rows_sha256' "$args")" = "$want" ] && [ "$(printf '%s' "$body" | jq -r '.rows_sha256')" = "$want" ]
    ok $? "launch $i: args and module both carry rows_sha256 = sha256(launch-$i.jsonl) (args $(jq -r '.rows_sha256' "$args"), want $want)"
    [ "$(printf '%s' "$body" | jq -c '.rows[]')" = "$(jq -c . "$WORK/gen/launch-$i.jsonl")" ] && [ "$(printf '%s' "$body" | jq '.v')" = "1" ]
    ok $? "launch $i: the module's rows equal launch-$i.jsonl's rows in manifest order"
    [ "$(jq -r '.cwd' "$args")" = "$TOP" ]
    ok $? "launch $i: cwd is the git toplevel, not the subdirectory it ran in (got $(jq -r '.cwd' "$args"), want $TOP)"
    [ "$(jq -c '.unit' "$args")" = "$(jq -c --argjson i "$i" '.[$i] | {index, of, classCap}' "$WORK/gen/launches.json")" ] &&
        [ "$(jq '.unit.of' "$args")" = "$n" ] && [ "$(jq '.unit.index' "$args")" = "$i" ] &&
        [ "$(jq '.harnessCap' "$args")" = "8" ] &&
        [ "$(jq '.harnessCap' "$args")" = "$(jq --argjson i "$i" '.[$i].harnessCap' "$WORK/gen/launches.json")" ]
    ok $? "launch $i: unit {index, of, classCap} and harnessCap match launches.json (got unit $(jq -c '.unit' "$args"), harnessCap $(jq '.harnessCap' "$args"))"
    [ "$(jq -r '.tribunal' "$args")" = "$TRIBUNAL" ] && [ "$(jq -cS '.integrated' "$args")" = "$(jq -cS . "$WORK/integrated.json")" ]
    ok $? "launch $i: tribunal and integrated equal the inputs"
done
[ -f "$packets/.gitignore" ] && [ "$(cat "$packets/.gitignore")" = "*" ]
ok $? 'the packet directory carries a .gitignore of *, so rows modules never show in git status'
rm -rf "$WORK/gen"
n=$(lu "$WORK/big.json" "$WORK/gen" --tribunal "$TRIBUNAL" 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "6" ] && [ -z "$(for i in $(seq 0 5); do jq -r 'select(has("integrated")) | "x"' "$WORK/gen/args-$i.json"; done)" ] &&
    [ "$(jq -r '.tribunal' "$WORK/gen/args-0.json")" = "$TRIBUNAL" ]
ok $? "with no integrated-map file no args object carries an integrated key (rc=$rc)"
rm -rf "$WORK/gen"
(cd "$WORK/outside" && python3 "$SCRIPT" "$WORK/big.json" "$WORK/gen" --tribunal "$TRIBUNAL" > "$WORK/out" 2> "$WORK/err"); rc=$?
[ "$rc" -ne 0 ] && grep -qi 'git work tree' "$WORK/err" && [ -z "$(ls "$WORK/gen"/args-*.json 2>/dev/null)" ] && [ ! -s "$WORK/out" ]
ok $? "outside a git work tree it exits non-zero, names the problem, and writes no args object (rc=$rc: $(head -c 200 "$WORK/err"))"

# ---- Bad usage fails loudly -------------------------------------------------------
python3 "$SCRIPT" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'no argument is a non-zero exit'
python3 "$SCRIPT" "$WORK/rows.json" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'a missing out-dir is a non-zero exit'
printf 'not json' > "$WORK/bad.json"
lu "$WORK/bad.json" "$WORK/out-bad" > /dev/null 2>&1; [ $? -ne 0 ]; ok $? 'unparseable input is a non-zero exit, never a count'

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

# ---- the mirrored caps match wave.js --------------------------------------------
# lane_units.py caps launches and reports harnessCap; a cap that drifts from
# wave.js splits launches the wave then refuses or narrows.
WAVE_JS="${WAVE_JS:-${ROOT}/src/user/claude_code/workflows/wave.js}"
for name in LAUNCH_CAP HARNESS_CAP; do
    js=$(sed -n "s/^const ${name} = \([0-9][0-9]*\).*/\1/p" "$WAVE_JS")
    py=$(sed -n "s/^${name} = \([0-9][0-9]*\).*/\1/p" "$SCRIPT")
    [ -n "$js" ] && [ "$js" = "$py" ]; ok $? "lane_units.py's ${name} (${py:-missing}) mirrors wave.js (${js:-missing})"
done
# The rows module's field names are the ones wave.js reads; a rename on
# either side strands every launch.
grep -q 'input\.rowsModule' "$WAVE_JS" && grep -q 'input\.rows_sha256' "$WAVE_JS" && grep -q 'mod\.rows_sha256' "$WAVE_JS" &&
    grep -q 'mod\.v !== 1' "$WAVE_JS" && grep -q "const PACKET_DIR = '.claude/docket-packets'" "$WAVE_JS"
ok $? 'wave.js reads rowsModule, rows_sha256 and v under the names lane_units.py writes, from the same packet directory'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
