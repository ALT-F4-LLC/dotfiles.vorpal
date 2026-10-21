#!/bin/bash

# Behavior suite for the docket-run skill's refill script,
# skills/docket-run/scripts/refill.sh: one refill of freed launch slots at a
# launch return.
#
# CI wiring: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs `python3`, `git` and `jq`, and
# stubs `docket` on PATH — no engine, no database, no network.
#
# WHY THIS EXISTS. A conductor once piped two `docket dispatch extend` calls
# into a row count: 216 rows and then 308 never reached the kept rows file,
# so they waited for the next dispatch, and a later dispatch ran no extend at
# all and waited for every lane. The refill was prose, and what failed was
# the bookkeeping. The script runs extend itself and keeps its answer, so the
# failures to catch are the ones that read as success: a pending set that
# omits rows the extend appended, a settled step relaunched, a refused lane
# relaunched at a bounce, a lane whose launch is in flight launched twice,
# and an extend that failed but left the rows file half-written.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REFILL="${REFILL_SH:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/scripts/refill.sh}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$REFILL" ] || fatal "refill.sh not found at ${REFILL}"
for tool in python3 git jq; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/refill.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
export GIT_CEILING_DIRECTORIES="$WORK"
git init -q "$WORK/repo" || fatal "git init failed"

# A stub `docket`: `dispatch extend` prints
# $STUB_EXTEND_DIR/answer-<n>.json for the n-th call, or exits 1 when none is queued.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/docket" <<'STUB'
#!/bin/bash
[ "$1 $2" = "dispatch extend" ] || { echo "stub docket: unexpected $*" >&2; exit 2; }
echo "$*" >> "$STUB_EXTEND_DIR/calls"
n=$(cat "$STUB_EXTEND_DIR/n" 2>/dev/null || echo 0)
n=$((n + 1))
echo "$n" > "$STUB_EXTEND_DIR/n"
f="$STUB_EXTEND_DIR/answer-$n.json"
[ -f "$f" ] || { echo "stub docket: no answer queued for call $n" >&2; exit 1; }
cat "$f"
echo "warning: reaped an expired lease on STEP-9" >&2
STUB
chmod 755 "$WORK/bin/docket"
export PATH="$WORK/bin:$PATH"
export STUB_EXTEND_DIR="$WORK/stub"

pass=0
fail=0
ok() { # <0|1> <label>
    if [ "$1" -eq 0 ]; then pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2; fi
}

row() { # <step> <issue> <kind> <stage> [class]
    jq -c -n --arg step "$1" --arg issue "$2" --arg kind "$3" --argjson stage "$4" --arg class "${5:-write}" \
        '{step: $step, issue: $issue, kind: $kind, stage: $stage, class: $class}'
}
answer() { # <n> <rows-jsonl-file or empty>: queue the n-th extend answer
    mkdir -p "$STUB_EXTEND_DIR"
    if [ -n "${2:-}" ] && [ -s "$2" ]; then jq -c -s '{ok: true, data: {dispatch: "DISPATCH-1", run: "RUN-1", rows: .}}' "$2" > "$STUB_EXTEND_DIR/answer-$1.json"
    else printf '{"ok":true,"data":{"dispatch":"DISPATCH-1","run":"RUN-1","rows":[]}}\n' > "$STUB_EXTEND_DIR/answer-$1.json"; fi
}
reset() { # fresh state files and stub queue
    rm -rf "$STUB_EXTEND_DIR" "$WORK/state" "$WORK/launch"
    mkdir -p "$STUB_EXTEND_DIR" "$WORK/state"
    ROWS="$WORK/state/rows.jsonl"; SETTLED="$WORK/state/settled"; HELD="$WORK/state/held"; PENDING="$WORK/state/pending.jsonl"
    : > "$SETTLED"; : > "$HELD"
}
refill() { # extra args; stdout in $OUT, stderr in $ERR, status in $RC; launches in $WORK/launch
    rm -rf "$WORK/launch"
    OUT=$(cd "$WORK/repo" && bash "$REFILL" --run RUN-1 --rows "$ROWS" --settled "$SETTLED" --held "$HELD" --pending "$PENDING" --launch-dir "$WORK/launch" "$@" 2> "$WORK/err")
    RC=$?
    ERR=$(cat "$WORK/err")
}
steps_of() { jq -r '.step' "$1" | sort | tr '\n' ' '; }
launched_lanes() { jq -r '.[].lanes[]' "$WORK/launch/launches.json" 2>/dev/null | sort | tr '\n' ' '; }

# ---- two extends whose stdout nobody reads ---------------------------------
# The first refill appends 3 rows, the second 2: every appended row reaches
# the rows file and the pending set, and the lanes they belong to launch.
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; } > "$ROWS"
{ row STEP-3 ISS-3 executor 1; row STEP-4 ISS-3 executor 2; row STEP-5 ISS-4 executor 1; } > "$WORK/ext1.jsonl"
{ row STEP-6 ISS-5 executor 1; row STEP-7 ISS-5 vote 2; } > "$WORK/ext2.jsonl"
answer 1 "$WORK/ext1.jsonl"; answer 2 "$WORK/ext2.jsonl"
refill --in-flight "ISS-1,ISS-2"
ok $([ "$RC" -eq 0 ] && [ "$OUT" = 2 ] && echo 0 || echo 1) "first refill: exit 0 and 2 launches (got rc ${RC}, out '${OUT}', err ${ERR})"
ok $([ "$(steps_of "$ROWS")" = "STEP-1 STEP-2 STEP-3 STEP-4 STEP-5 " ] && echo 0 || echo 1) "first refill: the 3 appended rows are in the rows file (got $(steps_of "$ROWS"))"
ok $([ "$(launched_lanes)" = "ISS-3 ISS-4 " ] && echo 0 || echo 1) "first refill: the in-flight lanes are not launched, the appended lanes are (got $(launched_lanes))"
ok $([ "$OUT" = 2 ] && echo 0 || echo 1) "first refill: the launch count N is the only stdout"
refill --in-flight "ISS-1,ISS-2,ISS-3,ISS-4"
ok $([ "$RC" -eq 0 ] && [ "$(steps_of "$ROWS")" = "STEP-1 STEP-2 STEP-3 STEP-4 STEP-5 STEP-6 STEP-7 " ] && echo 0 || echo 1) "second refill: the 2 further rows are appended (got $(steps_of "$ROWS"))"
ok $([ "$(launched_lanes)" = "ISS-5 " ] && echo 0 || echo 1) "second refill: the new lane launches (got $(launched_lanes))"
ok $([ "$(steps_of "$PENDING")" = "$(steps_of "$ROWS")" ] && echo 0 || echo 1) "pending holds every row of the rows file when nothing is settled or held"
ok $([ "$(wc -l < "$STUB_EXTEND_DIR/calls" | tr -d ' ')" = 2 ] && grep -q -- '--run RUN-1' "$STUB_EXTEND_DIR/calls" && echo 0 || echo 1) "each refill ran exactly one extend for the run"

# ---- idempotence: an extend that repeats rows appends nothing ---------------
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
answer 1 "$ROWS"
refill
ok $([ "$RC" -eq 0 ] && [ "$(wc -l < "$ROWS" | tr -d ' ')" = 1 ] && echo 0 || echo 1) "an extend repeating a known step appends nothing"

# ---- human rows never reach the rows file -----------------------------------
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
{ row STEP-2 ISS-2 human 1; row STEP-3 ISS-2 executor 2; } > "$WORK/ext.jsonl"
answer 1 "$WORK/ext.jsonl"
refill
ok $([ "$RC" -eq 0 ] && [ "$(steps_of "$ROWS")" = "STEP-1 STEP-3 " ] && echo 0 || echo 1) "a human row is filtered from the appended rows (got $(steps_of "$ROWS"))"

# ---- a writer's return relaunches its review chain --------------------------
# Lane ISS-9 holds a writer and its staged review rows; the writer's launch
# returned, so the lane is no longer in flight. The writer settles, the review
# rows stay pending, and the lane relaunches with the reviews alone.
reset
{ row STEP-10 ISS-9 executor 1; row STEP-11 ISS-9 vote 2; row STEP-12 ISS-9 vote 2; row STEP-20 ISS-8 executor 1; } > "$ROWS"
answer 1 ""
printf '[{"step":"STEP-10","status":"recorded"}]\n' > "$WORK/statuses.json"
refill --statuses "$WORK/statuses.json" --in-flight "ISS-8"
ok $([ "$RC" -eq 0 ] && grep -qx 'STEP-10' "$SETTLED" && echo 0 || echo 1) "the returned writer's step is settled"
ok $([ "$(launched_lanes)" = "ISS-9 " ] && [ "$(steps_of "$WORK/launch/launch-0.jsonl")" = "STEP-11 STEP-12 " ] && echo 0 || echo 1) "the review chain relaunches at the writer's return without the writer (got $(launched_lanes): $(steps_of "$WORK/launch/launch-0.jsonl" 2>/dev/null))"

# ---- a bounce holds its lanes; the next return releases them ----------------
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; } > "$ROWS"
answer 1 ""; answer 2 ""; answer 3 ""
printf '[{"step":"STEP-2","status":"skipped-not-ready"}]\n' > "$WORK/bounce.json"
refill --statuses "$WORK/bounce.json" --in-flight "ISS-1"
ok $([ "$RC" -eq 0 ] && [ "$(cat "$HELD")" = "STEP-2" ] && [ ! -s "$SETTLED" ] && [ "$OUT" = 0 ] && echo 0 || echo 1) "a bounce holds the refused lane, settles nothing and relaunches nothing (held '$(cat "$HELD")', out '${OUT}')"
ok $([ "$(steps_of "$PENDING")" = "STEP-1 " ] && echo 0 || echo 1) "the held step leaves the pending rows (got $(steps_of "$PENDING"))"
printf '[{"step":"STEP-1","status":"recorded"}]\n' > "$WORK/done.json"
refill --statuses "$WORK/done.json"
ok $([ "$RC" -eq 0 ] && [ ! -s "$HELD" ] && grep -qx 'STEP-1' "$SETTLED" && [ "$(launched_lanes)" = "ISS-2 " ] && echo 0 || echo 1) "a non-bounce return empties the hold and relaunches the refused lane (got lanes $(launched_lanes))"
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; } > "$ROWS"
answer 1 ""
refill --statuses "$WORK/bounce.json" --reaped --in-flight "ISS-1"
ok $([ "$RC" -eq 0 ] && [ ! -s "$HELD" ] && [ "$(launched_lanes)" = "ISS-2 " ] && echo 0 || echo 1) "--reaped makes a refusal-only return a non-bounce: nothing is held (got lanes $(launched_lanes))"

# ---- a refused row's chain-dead rows stay pending with it -------------------
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-1 executor 2; row STEP-3 ISS-1 executor 3; } > "$ROWS"
answer 1 ""
printf '[{"step":"STEP-1","status":"recorded"},{"step":"STEP-2","status":"skipped-not-ready"},{"step":"STEP-3","status":"skipped-chain-dead"}]\n' > "$WORK/mixed.json"
refill --statuses "$WORK/mixed.json"
ok $([ "$(cat "$SETTLED")" = "STEP-1" ] && [ ! -s "$HELD" ] && [ "$(steps_of "$PENDING")" = "STEP-2 STEP-3 " ] && echo 0 || echo 1) "a refused row and its chain-dead rows stay pending; the recorded row settles (settled '$(cat "$SETTLED")')"

# ---- failures leave the rows file alone --------------------------------------
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
cp "$ROWS" "$WORK/rows.before"
refill
ok $([ "$RC" -eq 1 ] && cmp -s "$ROWS" "$WORK/rows.before" && echo 0 || echo 1) "a failing extend exits 1 and leaves the rows file unchanged (rc ${RC})"
printf '{"ok":false,"error":"no open dispatch"}\n' > "$STUB_EXTEND_DIR/answer-2.json"
refill
ok $([ "$RC" -eq 1 ] && cmp -s "$ROWS" "$WORK/rows.before" && echo 0 || echo 1) "an extend answering ok:false exits 1 and leaves the rows file unchanged (rc ${RC})"
printf '{"ok":true,"data":{"rows":"not-an-array"}}\n' > "$STUB_EXTEND_DIR/answer-3.json"
refill
ok $([ "$RC" -eq 1 ] && cmp -s "$ROWS" "$WORK/rows.before" && echo 0 || echo 1) "an extend answering a non-array rows exits 1 and leaves the rows file unchanged (rc ${RC})"

# ---- the engine's rows survive a failure after extend --------------------------
# Extend commits its rows to the manifest and never returns them again: when
# the script fails after extend, the answer stays beside the rows file.
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
printf '{"ok":true,"data":{"rows":"oops"}}\n' > "$STUB_EXTEND_DIR/answer-1.json"
refill
ok $([ "$RC" -eq 1 ] && [ -f "$ROWS.extend.json" ] && grep -q "$ROWS.extend.json" "$WORK/err" && echo 0 || echo 1) "an unusable extend answer exits 1, is kept beside the rows file and is named on stderr (rc ${RC})"
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
printf '{"step":"STEP-2"' >> "$ROWS"
{ row STEP-9 ISS-9 executor 1; } > "$WORK/ext.jsonl"
answer 1 "$WORK/ext.jsonl"
refill
ok $([ "$RC" -eq 1 ] && [ ! -e "$STUB_EXTEND_DIR/calls" ] && echo 0 || echo 1) "a rows file with a truncated line exits 1 before extend is called (rc ${RC})"
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
{ row STEP-9 ISS-9 executor 1; } > "$WORK/ext.jsonl"
answer 1 "$WORK/ext.jsonl"
refill
ok $([ "$RC" -eq 0 ] && [ ! -e "$ROWS.extend.json" ] && echo 0 || echo 1) "the saved extend answer is removed once its rows are kept"

reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
printf '{"ok":true,"data":{"rows":"oops"}}\n' > "$STUB_EXTEND_DIR/answer-1.json"
answer 2 ""
refill
refill
ok $([ "$RC" -eq 1 ] && [ "$(cat "$STUB_EXTEND_DIR/n")" = 1 ] && grep -q 'saved extend answer' "$WORK/err" && echo 0 || echo 1) "a second run refuses while a saved extend answer is unresolved, without extending again"

# ---- reaps in the extend answer are not swallowed ------------------------------
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
printf '{"ok":true,"data":{"rows":[],"reaped":["STEP-4#1"],"reap_hold":"write class held until ack"}}\n' > "$STUB_EXTEND_DIR/answer-1.json"
refill
ok $([ "$RC" -eq 0 ] && grep -q 'reaped an expired lease on STEP-4#1' "$WORK/err" && grep -q 'reap hold: write class held until ack' "$WORK/err" && echo 0 || echo 1) "extend's reaped list and reap_hold are printed on stderr"

# ---- state accumulates across returns -------------------------------------------
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; row STEP-3 ISS-3 executor 1; } > "$ROWS"
answer 1 ""; answer 2 ""
printf '[{"step":"STEP-1","status":"recorded"}]\n' > "$WORK/s1.json"; printf '[{"step":"STEP-2","status":"recorded"}]\n' > "$WORK/s2.json"
refill --statuses "$WORK/s1.json" --in-flight "ISS-3"; refill --statuses "$WORK/s2.json" --in-flight "ISS-3"
ok $([ "$(sort "$SETTLED" | tr '\n' ' ')" = "STEP-1 STEP-2 " ] && echo 0 || echo 1) "settled accumulates across returns (got $(tr '\n' ' ' < "$SETTLED"))"
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; row STEP-3 ISS-3 executor 1; } > "$ROWS"
answer 1 ""; answer 2 ""
printf '[{"step":"STEP-1","status":"skipped-not-ready"}]\n' > "$WORK/b1.json"; printf '[{"step":"STEP-2","status":"skipped-not-ready"}]\n' > "$WORK/b2.json"
refill --statuses "$WORK/b1.json" --in-flight "ISS-3"; refill --statuses "$WORK/b2.json" --in-flight "ISS-3"
ok $([ "$(sort "$HELD" | tr '\n' ' ')" = "STEP-1 STEP-2 " ] && echo 0 || echo 1) "two bounces in a row hold both lanes (got $(tr '\n' ' ' < "$HELD"))"

# ---- caps and the tribunal path reach lane_units.py -------------------------------
reset
{ row STEP-1 ISS-1 executor 1; row STEP-2 ISS-2 executor 1; } > "$ROWS"
answer 1 ""; answer 2 ""
refill --write-cap 1
ok $([ "$RC" -eq 0 ] && [ "$OUT" = 1 ] && echo 0 || echo 1) "--write-cap 1 over two free lanes launches one (got '${OUT}')"
refill --tribunal /opt/tribunal.js
ok $([ "$RC" -eq 0 ] && [ "$(jq -r '.tribunal' "$WORK/launch/args-0.json")" = /opt/tribunal.js ] && echo 0 || echo 1) "--tribunal reaches each launch's args"
{ echo '{"ISS-1":"abc123"}'; } > "$WORK/integrated.json"; answer 3 ""
refill --integrated "$WORK/integrated.json"
ok $([ "$RC" -eq 0 ] && [ "$(jq -r '.integrated' "$WORK/launch/args-0.json")" != null ] && echo 0 || echo 1) "--integrated reaches each launch's args"

# ---- the skill runs the installed script, never a hand pipe -------------------
SKILL="${DOCKET_RUN_SKILL:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/SKILL.md}"
ok $(grep -q 'bash ~/.claude/skills/docket-run/scripts/refill.sh --run "\$RUN" --rows "\$ROWS_FILE" --settled "\$SETTLED_FILE" --held "\$HELD_FILE" --pending "\$PENDING_FILE" --launch-dir "\$LAUNCH_DIR" --statuses "\$STATUSES_FILE"' "$SKILL" && echo 0 || echo 1) "SKILL.md carries the refill.sh command with every state file"
ok $(grep -q -- '--reaped' "$SKILL" && grep -q 'Never pipe `docket dispatch' "$SKILL" && echo 0 || echo 1) "SKILL.md names --reaped and forbids a hand-piped extend"

# ---- usage -------------------------------------------------------------------
OUT=$(cd "$WORK/repo" && bash "$REFILL" --run RUN-1 2>&1); RC=$?
ok $([ "$RC" -eq 2 ] && echo 0 || echo 1) "missing arguments exit 2 (rc ${RC})"
reset
{ row STEP-1 ISS-1 executor 1; } > "$ROWS"
answer 1 ""
printf 'not json\n' > "$WORK/bad-statuses.json"
refill --statuses "$WORK/bad-statuses.json"
ok $([ "$RC" -eq 1 ] && [ ! -e "$STUB_EXTEND_DIR/calls" ] && echo 0 || echo 1) "a statuses file that is not a JSON array exits 1 before extending (rc ${RC})"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
