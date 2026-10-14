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
# packed with another; lanes past the free slots (LAUNCH_CAP, 20, minus the
# lanes still in flight) go to deferred.jsonl for a later refill. Every row
# of a lane not in flight lands in exactly one launch file or the deferred
# file. A split that drifts runs a lane twice, not at all, or over-admits a
# class.
#
# The suite also pins the SKILL.md side: the skill runs the installed file
# and carries no inline interpreter program, and its refill loop keeps the
# --in-flight re-split, the close condition, a settle filter that keeps a
# refused lane pending, a bounce test that holds a refused lane until a
# non-bounce return, and a pending-rows filter that drops exactly the
# settled and held steps. The same program once lived in
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

# ---- A refill re-split launches only lanes not in flight, into the free slots ----
# Three of the 25 lanes still run, so 17 slots are free: the 22 other lanes
# fill them in manifest order and the last 5 defer. The in-flight lanes' rows
# go to neither, since their launches still hold them.
printf '%s' "[$many]" > "$WORK/rows.json"
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --in-flight I2,I5,I9 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "17" ]; ok $? "with 3 of 25 lanes in flight a re-split emits 17 launches (rc=$rc, got $n: $(head -c 200 "$WORK/err"))"
[ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "5" ] && grep -q '"issue":"I21"' "$WORK/launch/deferred.jsonl" && ! grep -q '"issue":"I20"' "$WORK/launch/deferred.jsonl"
ok $? 'the 5 lanes past the free slots land in deferred.jsonl, latest in manifest order'
[ -z "$(cat "$WORK"/launch/launch-*.jsonl "$WORK/launch/deferred.jsonl" | grep -E '"issue":"I(2|5|9)"')" ] && [ "$(summary 'sorted({x["of"] for x in s})')" = "[17]" ]
ok $? 'no launch or deferral holds an in-flight lane, and every unit carries of = 17'
# Names arrive as stderr prints them (lane:<lane>) or padded by hand; either
# way they name the same running lanes, which must not launch twice.
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --in-flight ' lane:I2, I5 ,lane:I9 ' 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "17" ] && [ -z "$(cat "$WORK"/launch/launch-*.jsonl "$WORK/launch/deferred.jsonl" | grep -E '"issue":"I(2|5|9)"')" ]
ok $? "lane:-prefixed and space-padded in-flight names match their lanes (rc=$rc, got $n: $(head -c 200 "$WORK/err"))"
# A running launch holds a slot whether or not its lane still has rows here
# (every row it held may have settled), so absent names count against the cap
# and are named on stderr in case they are typos.
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --in-flight X1,X2,X3 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "17" ] && [ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "8" ]
ok $? "3 in-flight lanes absent from the rows still hold 3 slots: 17 launches, 8 deferred (rc=$rc, got $n)"
grep -q 'in flight but in no row: X1, X2, X3' "$WORK/err"; ok $? 'in-flight names matching no lane are named on stderr'
rm -rf "$WORK/launch"
lu "$WORK/rows.json" "$WORK/launch" --in-flight I2,I5,I9 > /dev/null 2> "$WORK/err"
! grep -q 'in flight but in no row' "$WORK/err"; ok $? 'in-flight names that match lanes are not named as in no row'
# A row with no issue is its own lane, keyed row:<step>; named in flight, it
# must not launch twice.
printf '%s' '[{"step":"STEP-1","kind":"executor","class":"read","stage":0},'"$(r 2 A 0)"']' > "$WORK/rows.json"
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --in-flight lane:row:STEP-1 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "1" ] && [ "$(cat "$WORK"/launch/launch-*.jsonl | jq -r .step)" = "STEP-2" ] && ! grep -q 'in flight but in no row' "$WORK/err"
ok $? "an issue-less lane named in flight as row:<step> is not launched again (rc=$rc, got $n)"
printf '%s' "[$many]" > "$WORK/rows.json"
# More names in flight than the cap leaves no free slot, never a negative one.
names=$(for i in $(seq 1 20); do printf 'I%s,' "$i"; done)X1,X2
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --in-flight "$names" 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "0" ] && [ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "5" ] && grep -q '"issue":"I21"' "$WORK/launch/deferred.jsonl"
ok $? "22 lanes in flight leave no free slot: 0 launches, the 5 other lanes deferred (rc=$rc, got $n)"

# ---- --write-cap: the write class's effective cap bounds the launches ----------
# The launch cap is min(LAUNCH_CAP, N): a smaller write cap narrows it, a
# larger one never lifts it past LAUNCH_CAP, and no flag keeps LAUNCH_CAP.
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --write-cap 5 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "5" ] && [ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "20" ] &&
    grep -q '"issue":"I6"' "$WORK/launch/deferred.jsonl" && ! grep -q '"issue":"I5"' "$WORK/launch/deferred.jsonl"
ok $? "--write-cap 5 over 25 lanes launches the first 5 and defers 20 (rc=$rc, got $n: $(head -c 200 "$WORK/err"))"
grep -q 'deferred: 20 lane(s) past the 5-launch cap' "$WORK/err"; ok $? 'the deferral names the write cap as the launch cap'
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --write-cap 5 --in-flight I1,I2 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "3" ]; ok $? "--write-cap 5 with 2 lanes in flight leaves 3 free slots (rc=$rc, got $n)"
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" --write-cap 50 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "20" ] && [ "$(wc -l < "$WORK/launch/deferred.jsonl" | tr -d ' ')" = "5" ] &&
    grep -q 'deferred: 5 lane(s) past the 20-launch cap' "$WORK/err"
ok $? "--write-cap 50 over 25 lanes still launches at most 20 (rc=$rc, got $n: $(head -c 200 "$WORK/err"))"
rm -rf "$WORK/launch"
n=$(lu "$WORK/rows.json" "$WORK/launch" 2> "$WORK/err"); rc=$?
[ "$rc" -eq 0 ] && [ "$n" = "20" ] && grep -q 'deferred: 5 lane(s) past the 20-launch cap' "$WORK/err"
ok $? "without --write-cap 25 lanes launch the first 20, as before (rc=$rc, got $n)"
for bad in 0 -1 1.5 ''; do
    rm -rf "$WORK/out-cap"
    flag=(--write-cap); [ -n "$bad" ] && flag+=("$bad")
    lu "$WORK/rows.json" "$WORK/out-cap" "${flag[@]}" > "$WORK/out" 2> "$WORK/err"; rc=$?
    [ "$rc" -ne 0 ] && grep -q -- '--write-cap' "$WORK/err" && [ ! -e "$WORK/out-cap" ] && [ ! -s "$WORK/out" ]
    ok $? "--write-cap ${bad:-with no value} exits non-zero naming --write-cap and writes nothing (rc=$rc: $(head -c 200 "$WORK/err"))"
done

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

# ---- SKILL.md's refill loop: the re-split form, the close, the pending filter ---
grep -qF -- '"$PENDING_FILE" "$LAUNCH_DIR" --tribunal "<absolute installed path to tribunal.js>" --in-flight "<lane>,<lane>"' "$SKILL"; ok $? \
    'SKILL.md re-splits the pending rows with --in-flight at a launch return'
# Prose pins match across line wraps.
skill_text=$(tr -s ' \n' '  ' < "$SKILL")
printf '%s' "$skill_text" | grep -qF 'Never hold a deferred lane while fewer than 20 launches run'; ok $? \
    'SKILL.md never holds a deferred lane while a slot is free'
# A refused lane relaunches only at a return that can have freed its holder,
# never at a bounce: relaunching at every return spun refused lanes against a
# live holder. Both the refill step and the paragraph after it must say so.
printf '%s' "$skill_text" | grep -qF 'Relaunch a `skipped-not-ready` lane only at a return where a holder released its scope (an in-dispatch launch returned having claimed or settled steps, or a dead holder was reaped at that return) or at a non-bounce launch return, never at a bounce return' &&
    printf '%s' "$skill_text" | grep -qF 'A held lane relaunches only at a return where a holder released its scope or at a non-bounce launch return, and never at a bounce return, a return whose launch claimed nothing because every claim was refused.' &&
    ! printf '%s' "$skill_text" | grep -qF 'relaunches at every return that settles it' &&
    ! printf '%s' "$skill_text" | grep -qF 'even when no other launch is in flight' &&
    ! printf '%s' "$skill_text" | grep -qF 'relaunches at the return that settled it'; ok $? \
    'SKILL.md holds a skipped-not-ready lane through bounce returns and relaunches it at a release or non-bounce return'
# The hold spares launches, never usage joins: a bounce return still joins.
printf '%s' "$skill_text" | grep -qF 'Every launch return, a bounce included, still gets its usage join'; ok $? \
    'SKILL.md runs the usage join for every launch return, a bounce included'
# Dispatch-close item 1 owns the obligation: it launches the join first and
# must not exempt a bounce, in any wording.
join_item=${skill_text#*'**1. Launch the usage join first'}
join_item=${join_item%%'End the turn on the join'*}
[ "$join_item" != "$skill_text" ] && [ -n "$join_item" ] &&
    printf '%s' "$join_item" | grep -qF 'before reading or diagnosing the wave'; ok $? \
    "SKILL.md's dispatch-close item 1 launches the usage join first"
printf '%s' "$join_item" | grep -qiE 'bounce'; rc=$?
[ "$rc" -eq 1 ]; ok $? \
    "SKILL.md's dispatch-close item 1 names no bounce exemption from the usage join"
# A bounce is a launch that claimed nothing because every claim was refused.
# The test runs as SKILL.md spells it.
bounce=$(sed -n 's/.*`jq -e '"'"'\([^'"'"']*\)'"'"' "$STATUSES_FILE"`.*/\1/p' "$SKILL")
printf '%s' '[{"step":"STEP-1","status":"skipped-not-ready"},{"step":"STEP-2","status":"skipped-chain-dead"}]' > "$WORK/statuses.json"
jq -e "$bounce" "$WORK/statuses.json" > /dev/null 2>&1; rc=$?
[ -n "$bounce" ] && [ "$rc" -eq 0 ]; ok $? \
    "SKILL.md's bounce test matches a launch whose every claim was refused (test '$bounce', rc=$rc)"
printf '%s' '[{"step":"STEP-1","status":"returned"},{"step":"STEP-2","status":"skipped-not-ready"},{"step":"STEP-3","status":"skipped-chain-dead"}]' > "$WORK/statuses.json"
jq -e "$bounce" "$WORK/statuses.json" > /dev/null 2>&1; rc=$?
[ -n "$bounce" ] && [ "$rc" -eq 1 ]; ok $? \
    "SKILL.md's bounce test rejects a launch that claimed a step before a refusal (rc=$rc)"
printf '%s' '[{"step":"STEP-1","status":"not-launched-run-parked"}]' > "$WORK/statuses.json"
jq -e "$bounce" "$WORK/statuses.json" > /dev/null 2>&1; rc=$?
[ -n "$bounce" ] && [ "$rc" -eq 1 ]; ok $? \
    "SKILL.md's bounce test rejects a launch with no refused claim (rc=$rc)"
printf '%s' "$skill_text" | grep -qF "The dispatch closes only when no launch is in flight and the last return's re-split had nothing to launch: extend appended nothing launchable, and every row of the manifest of record is in \`\$SETTLED_FILE\` or \`\$HELD_FILE\`. The loop ends only when no work remains in this dispatch."; ok $? \
    'SKILL.md closes the dispatch only when no launch is in flight and every row of the manifest is settled or held'
# A dead in-dispatch holder is reaped and acked at the return that reports
# it, inside the refill steps and ahead of the relaunch, so a lane it refused
# stops retrying before the close instead of waiting on it.
refill_steps=${skill_text#*Each time one launch returns while the dispatch is open}
refill_steps=${refill_steps%%Launch every unit it wrote*}
printf '%s' "$refill_steps" | grep -qF 'For each row this return settled as `unrecorded` or `unsettled` whose step still reads claimed by that spawn, run `docket step reap STEP-N --reason R` at this return, then pass the `lease-reaped` seq of that reap to `docket guard spawn --run $RUN --ack-reap <seq>` on your own dead-holder evidence and without the ack panel, before the refill relaunches any `skipped-not-ready` lane.'; ok $? \
    'SKILL.md reaps a dead in-dispatch holder and passes its --ack-reap at the return, before the refill relaunch'
# A returned launch's statuses settle every row except a refused row and, in
# the refused row's lane, the chain-dead rows waiting on it. The filter runs
# as SKILL.md spells it.
settle=$(sed -n 's/.*`jq -r '"'"'\([^'"'"']*\)'"'"' "$STATUSES_FILE" >> "$SETTLED_FILE"`.*/\1/p' "$SKILL")
printf '%s' '[{"step":"STEP-1","status":"returned"},{"step":"STEP-2","status":"skipped-not-ready"},{"step":"STEP-3","status":"skipped-chain-dead"}]' > "$WORK/statuses.json"
got=$(jq -r "$settle" "$WORK/statuses.json" | tr '\n' ' ')
[ -n "$settle" ] && [ "$got" = "STEP-1 " ]; ok $? \
    "SKILL.md's settle filter keeps a refused row and its chain-dead rows pending (filter '$settle', got '$got')"
printf '%s' '[{"step":"STEP-4","status":"spawn-failed"},{"step":"STEP-5","status":"skipped-chain-dead"},{"step":"STEP-6","status":"returned"}]' > "$WORK/statuses.json"
got=$(jq -r "$settle" "$WORK/statuses.json" | tr '\n' ' ')
[ -n "$settle" ] && [ "$got" = "STEP-4 STEP-5 STEP-6 " ]; ok $? \
    "SKILL.md's settle filter settles every row of a launch with no refused row, chain-dead included (got '$got')"
# The pending rows are the manifest of record minus the settled and held
# step ids, matched whole: STEP-12 settled must not drop STEP-123.
filter=$(sed -n 's/.*--rawfile held "$HELD_FILE" '"'"'\([^'"'"']*\)'"'"' "$ROWS_FILE" > "$PENDING_FILE".*/\1/p' "$SKILL")
printf '%s\n%s\n%s\n%s\n' "$(r 5 A 0)" "$(r 12 B 0)" "$(r 123 C 0)" "$(r 7 D 0)" > "$WORK/kept.jsonl"
cat /dev/null > "$WORK/settled"
cat /dev/null > "$WORK/held"
got=$(jq -c --rawfile settled "$WORK/settled" --rawfile held "$WORK/held" "$filter" "$WORK/kept.jsonl" | jq -r .step | tr '\n' ' ')
[ -n "$filter" ] && [ "$got" = "STEP-5 STEP-12 STEP-123 STEP-7 " ]; ok $? \
    "SKILL.md's pending filter keeps every row while nothing is settled or held (filter '$filter', got '$got')"
printf 'STEP-12\n' > "$WORK/settled"
printf 'STEP-7\n' > "$WORK/held"
got=$(jq -c --rawfile settled "$WORK/settled" --rawfile held "$WORK/held" "$filter" "$WORK/kept.jsonl" | jq -r .step | tr '\n' ' ')
[ -n "$filter" ] && [ "$got" = "STEP-5 STEP-123 " ]; ok $? \
    "SKILL.md's pending filter drops exactly the settled and held steps (got '$got')"

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
