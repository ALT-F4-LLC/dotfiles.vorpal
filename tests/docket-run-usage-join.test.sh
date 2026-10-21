#!/bin/bash

# Golden suite for the docket-run skill's deterministic usage reader,
# skills/docket-run/scripts/usage_join.sh (usage_extract.jq and
# usage_reduce.jq beside it): the back-fill rows it prints must equal, byte for
# byte, the rows docket-workflow-usage.js returns for the same transcripts,
# with no agent spawned.
#
# Needs bash, jq, node and git-free fixtures only; no engine, no network.
#
# WHY THIS EXISTS. The workflow measured a wave with one scout and one haiku
# agent per transcript, each running a fixed jq program, and RUN-158 paid for
# 544 joins and 3007 such agents. The program and the reduction are
# deterministic, so a script runs them directly. A script that drifts from the
# workflow either double-counts a streamed message (summing instead of
# last-wins), files a claim agent's spend under a step, or loses a step's
# metadata, and a back-fill is not easy to take back. The golden diff is the
# guard, and its mutants (below) prove the diff would notice.
#
# The reference side is the workflow's own text: this suite extracts
# EXTRACT_JQ, SELECT_JQ and the classify region from the workflow file between
# its TEST-BEGIN/TEST-END markers and runs them under node, so editing the
# workflow without the script fails here.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="${SCRIPT_DIR}/.."
SCRIPTS_DIR="${USAGE_JOIN_DIR:-${ROOT}/src/user/claude_code/skills/docket-run/scripts}"
WORKFLOW="${USAGE_WORKFLOW_JS:-${ROOT}/src/user/claude_code/workflows/docket-workflow-usage.js}"
SKILL="${DOCKET_RUN_SKILL:-${ROOT}/src/user/claude_code/skills/docket-run/SKILL.md}"

fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$SCRIPTS_DIR/usage_join.sh" ] || fatal "usage_join.sh not found in ${SCRIPTS_DIR}"
[ -f "$WORKFLOW" ] || fatal "docket-workflow-usage.js not found at ${WORKFLOW}"
for tool in jq node; do command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"; done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/usage-join.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <0|1> <label>
    if [ "$1" -eq 0 ]; then pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2; fi
}

# ---- the reference: the workflow's own jq and reduction, run under node ----
cat > "$WORK/reference.js" <<'EOF'
const fs = require('fs')
const cp = require('child_process')
const path = require('path')
const [, , jsPath, mode, excludeJson, what, ...files] = process.argv
const text = fs.readFileSync(jsPath, 'utf8')
const region = (name) => {
    const b = text.indexOf(`TEST-BEGIN ${name}`)
    const e = text.indexOf(`TEST-END ${name}`)
    if (b < 0 || e < 0) throw new Error(`no region ${name}`)
    return text.slice(text.indexOf('\n', b) + 1, text.lastIndexOf('\n', e))
}
const mod = new Function(region('docket-workflow-usage-extract') + '\n' + region('docket-workflow-usage-select') + '\n' +
    region('docket-workflow-usage-classify') + '\nreturn {EXTRACT_JQ, SELECT_JQ, reduceRows}')()
if (what === 'extract-jq') { process.stdout.write(mod.EXTRACT_JQ); process.exit(0) }
const jq = (prog, flags, file) => {
    const r = cp.spawnSync('jq', [...flags, prog, file], { encoding: 'utf8' })
    if (r.status !== 0) throw new Error(`jq failed on ${file}: ${r.stderr}`)
    return r.stdout
}
const results = []
for (const file of files) {
    if (mode === 'seats' && jq(mod.SELECT_JQ, ['-r', '-n', '-R'], file).trim() === '') continue
    const extract = JSON.parse(jq(mod.EXTRACT_JQ, ['-c', '-n', '-R'], file))
    // NOT TESTABLE BY DIFF: this stands in for the workflow's recheck, so the diff cannot disagree on it.
    // The workflow's recheck confirms a repeated bootstrap:false as a misreport
    // and files the agent as overhead; the reader has no relay to misreport it.
    if (extract.bootstrap === false) extract.bootstrapFallback = true
    results.push({ file: path.basename(file), extract })
}
const out = mod.reduceRows(results, mode, JSON.parse(excludeJson))
process.stdout.write(JSON.stringify({
    rows: out.rows,
    osums: out.overhead.sums,
    oagents: out.overhead.agents.map((a) => a.file),
    skipped: out.skipped.map((s) => ({ file: s.file, reason: s.reason, key: s.key })),
    nerr: out.errors.length,
    obs: out.model_observations,
}))
EOF
ref() { node "$WORK/reference.js" "$WORKFLOW" "$@"; }

# ---- fixtures -----------------------------------------------------------------
WAVE="$WORK/wave"
mkdir -p "$WAVE"
user() { jq -c -n --arg t "$2" '{type: "user", message: {content: $t}}' >> "$WAVE/$1"; }
asst() { # <file> <msg id> <model> <effort> <in> <out> <cc> <cr> [tool_use ids...]
    local f="$1" id="$2" model="$3" effort="$4" i="$5" o="$6" cc="$7" cr="$8"; shift 8
    local tools; tools=$(printf '%s\n' ${1+"$@"} | jq -R -c -s 'split("\n") | map(select(. != "")) | map({type: "tool_use", id: ., name: (if . == "so" then "StructuredOutput" else "Bash" end), input: {}})')
    jq -c -n --arg id "$id" --arg model "$model" --arg effort "$effort" --argjson i "$i" --argjson o "$o" --argjson cc "$cc" --argjson cr "$cr" --argjson tools "$tools" \
        '{type: "assistant", message: ({id: $id, content: $tools, usage: {input_tokens: $i, output_tokens: $o, cache_creation_input_tokens: $cc, cache_read_input_tokens: $cr}}
            + (if $model != "-" then {model: $model} else {} end))}
         + (if $effort != "-" then {effort: $effort} else {} end)' >> "$WAVE/$f"
}
EXEC_HEAD='You are executing one step of a Docket run.'

# STEP-12: a harness preamble, then the executor brief; one message streamed
# over three lines (output grows 10 -> 90 -> 250), a second message, two tools.
user agent-01.jsonl $'[Workflow harness — user request]\nthe operator asked for a fix'
user agent-01.jsonl "$EXEC_HEAD
Run: docket step claim STEP-12 then do the work and docket step record STEP-12"
asst agent-01.jsonl m1 claude-opus-5-5 high 100 10 1000 5000 t1
asst agent-01.jsonl m1 claude-opus-5-5 high 100 90 1000 5000 t1 t2
asst agent-01.jsonl m1 claude-opus-5-5 high 100 250 1000 5000 t1 t2
asst agent-01.jsonl m2 claude-opus-5-5 high 7 40 0 6000 t3
# STEP-5: two models, two efforts, served by two transcripts (no metadata).
user agent-02.jsonl "$EXEC_HEAD
docket step claim STEP-5"
asst agent-02.jsonl a1 claude-haiku-5-5 low 5 50 500 100
asst agent-02.jsonl a2 claude-opus-5-5 high 6 60 600 200
user agent-07.jsonl "$EXEC_HEAD
docket step record STEP-5"
asst agent-07.jsonl b1 claude-opus-5-5 high 1 2 3 4
# A claim agent and a probe that mention steps are wave overhead, never a step's.
user agent-03.jsonl 'Run exactly this one command:

  ~/.docket/bin/docket-workflow-claim --step STEP-12 --owner wave

It claims STEP-12 under that owner and writes the rendered packet for the executor.

Run nothing else.

WAVE CLAIM: not a step execution; it claims STEP-12 for its executor.'
asst agent-03.jsonl c1 claude-haiku-5-5 low 11 22 33 44
user agent-04.jsonl 'WAVE PROBE: not a step execution. docket step show STEP-5, which quotes docket step record STEP-5'
asst agent-04.jsonl d1 claude-haiku-5-5 low 55 66 77 88
# Seats: a ballot is a seat in seats mode and skipped in steps mode.
user agent-05.jsonl 'You are a judge.
docket vote cast PROP-7 --voter alice'
asst agent-05.jsonl e1 claude-opus-5-5 high 9 8 7 6 t1 t2 so
user agent-11.jsonl 'You are a judge.
Cast with: docket vote cast PROP-7 --voter bob'
asst agent-11.jsonl f1 claude-opus-5-5 high 1 1 1 1
user agent-12.jsonl 'You are a judge.
docket vote cast PROP-2 --voter carol'
asst agent-12.jsonl g1 claude-opus-5-5 high 3 3 3 3 t9
# This workflow's own relay is overhead.
user agent-06.jsonl 'You are a read-only scout. List the agent transcripts.'
asst agent-06.jsonl h1 claude-haiku-5-5 low 2 2 2 2
# A dead spawn beside a live transcript for the same step: skipped.
user agent-08.jsonl "$EXEC_HEAD
docket step claim STEP-5"
# No user message at all: overhead.
asst agent-09.jsonl i1 claude-haiku-5-5 low 4 4 4 4
# STEP-100: a synthetic message and a message without a model: incomplete
# model coverage, so no metadata. Sorts after STEP-12 numerically.
user agent-10.jsonl "$EXEC_HEAD
docket step claim STEP-100"
asst agent-10.jsonl j1 claude-opus-5-5 high 10 10 10 10
asst agent-10.jsonl j2 '<synthetic>' - 0 5 0 0
asst agent-10.jsonl j3 - - 1 1 1 1
# STEP-9: a line that is not JSON in the middle of the transcript.
user agent-13.jsonl "$EXEC_HEAD
docket step claim STEP-9"
printf 'this line is not json\n' >> "$WAVE/agent-13.jsonl"
asst agent-13.jsonl k1 claude-sonnet-5-5 medium 20 30 40 50
# A step with metadata from one transcript but a streamed model switch.
user agent-14.jsonl "$EXEC_HEAD
docket step claim STEP-3"
asst agent-14.jsonl l1 claude-haiku-5-5 medium 1 2 3 4
asst agent-14.jsonl l2 claude-opus-5-5 medium 5 6 7 8
# Keys the ledger joins on lose one layer of surrounding quotes, as the
# workflow's unquote() does: a quoted cast, an empty quoted cast (no seat), and
# a quoted model name.
user agent-15.jsonl 'You are a judge.
docket vote cast "PROP-8" --voter '"'dave'"
asst agent-15.jsonl n1 claude-opus-5-5 high 2 2 2 2
user agent-16.jsonl 'You are a judge.
docket vote cast "" --voter erin'
asst agent-16.jsonl o1 claude-opus-5-5 high 2 2 2 2
user agent-17.jsonl "$EXEC_HEAD
docket step claim STEP-77"
asst agent-17.jsonl p1 '"claude-opus-5-5"' high 3 3 3 3
: > "$WAVE/notes.txt"

FILES=($(printf "%s\n" "$WAVE"/agent-*.jsonl | LC_ALL=C sort))
USAGE_JOIN="$SCRIPTS_DIR/usage_join.sh"
uj() { bash "$USAGE_JOIN" "$@" 2> "$WORK/uj.err"; }
project() { jq -c '{rows, osums: .overhead.sums, oagents: (.overhead.agents | map(.file)), skipped: (.skipped | map({file, reason, key})), nerr: (.errors | length), obs: .model_observations}'; }

# golden <mode> <exclude-csv> <exclude-json>: 0 when the script matches the workflow
golden() {
    local m="$1" csv="$2" js="$3" want got
    want=$(ref "$m" "$js" run "${FILES[@]}") || return 2
    got=$(uj "$WAVE" --mode "$m" ${csv:+--exclude "$csv"} --full) || return 3
    [ "$(printf '%s' "$want" | jq -c .rows)" = "$(printf '%s' "$got" | jq -c .rows)" ] || return 4
    [ "$(printf '%s' "$want" | jq -c .)" = "$(printf '%s' "$got" | project)" ] || return 5
    return 0
}

# ---- the golden diff ------------------------------------------------------------
golden steps "" '[]'; rc=$?
ok $([ "$rc" -eq 0 ] && echo 0 || echo 1) "steps mode: rows, overhead, skips and model observations equal the workflow's (rc ${rc})"
golden seats "" '[]'; rc=$?
ok $([ "$rc" -eq 0 ] && echo 0 || echo 1) "seats mode: rows, skips and model observations equal the workflow's (rc ${rc})"
golden steps "STEP-9" '["STEP-9"]'; rc=$?
ok $([ "$rc" -eq 0 ] && echo 0 || echo 1) "steps mode with an excluded step equals the workflow's (rc ${rc})"
golden seats "alice" '["alice"]'; rc=$?
ok $([ "$rc" -eq 0 ] && echo 0 || echo 1) "seats mode with an excluded seat equals the workflow's (rc ${rc})"

# ---- values that must not be wrong in both at once -------------------------------
ROWS=$(uj "$WAVE" --mode steps)
q() { printf '%s' "$ROWS" | jq -r "$1"; }
ok $([ "$(q '[.[] | select(.step == "STEP-12" and .unit == "output_tokens") | .quantity] | .[0]')" = 290 ] && echo 0 || echo 1) "a streamed message id counts once, last occurrence: 250 + 40 output tokens, not 10 + 90 + 250 + 40"
ok $([ "$(q '[.[] | select(.step == "STEP-12" and .unit == "cache_read_tokens") | .quantity] | .[0]')" = 11000 ] && echo 0 || echo 1) "cache reads are not repeated per streamed line"
ok $([ "$(q 'map(.step) | unique | join(" ")')" = "STEP-100 STEP-12 STEP-3 STEP-5 STEP-77 STEP-9" ] && echo 0 || echo 1) "the claim agent, probe, seats, relay, dead spawn and no-bootstrap agents own no step"
ok $([ "$(q '[.[] | select(.unit == "input_tokens") | .step] | join(" ")')" = "STEP-3 STEP-5 STEP-9 STEP-12 STEP-77 STEP-100" ] && echo 0 || echo 1) "steps sort numerically, not as text"
ok $([ "$(q '[.[] | select(.step == "STEP-5" and .unit == "input_tokens") | .quantity] | .[0]')" = 12 ] && echo 0 || echo 1) "the dead spawn adds nothing and the two live transcripts of a step are summed"
ok $([ "$(q '[.[] | select(.metadata != null) | .step] | join(" ")')" = "STEP-3 STEP-9 STEP-12 STEP-77" ] && echo 0 || echo 1) "metadata only where one transcript served the step with complete model coverage"
ok $([ "$(q '[.[] | select(.step == "STEP-3" and .metadata != null) | .metadata][0] | tojson')" = '{"model_resolved":"claude-opus-5-5","effort_resolved":"medium","models_observed":["claude-haiku-5-5","claude-opus-5-5"]}' ] && echo 0 || echo 1) "metadata names the last model, the one effort and, for several models, the sorted list"
SEATS=$(uj "$WAVE" --mode seats)
ok $([ "$(printf '%s' "$SEATS" | jq -r '[.[] | select(.unit == "tool_uses") | "\(.proposal)/\(.voter)=\(.quantity)"] | join(" ")')" = "PROP-2/carol=1 PROP-7/alice=2 PROP-7/bob=0 PROP-8/dave=0" ] && echo 0 || echo 1) "seats sort by proposal then voter and count tool_use blocks, not StructuredOutput"
ok $([ "$(printf '%s' "$SEATS" | jq -r '[.[] | select(.unit == "input_tokens") | "\(.proposal)/\(.voter)"] | join(" ")')" = "PROP-2/carol PROP-7/alice PROP-7/bob PROP-8/dave" ] && echo 0 || echo 1) "a quoted cast is unquoted and an empty quoted cast is no seat"
ok $([ "$(q '[.[] | select(.step == "STEP-77") | .metadata][0].model_resolved')" = claude-opus-5-5 ] && echo 0 || echo 1) "a quoted model name is unquoted in the metadata"
ok $([ "$(q '[.[] | select(.step == "STEP-12" and .unit == "input_tokens") | .quantity] | .[0]')" = 107 ] && echo 0 || echo 1) "a claim agent's spend (real brief shape) stays out of the step it mentions"
ok $([ "$(uj "$WAVE" | jq 'length')" = 24 ] && [ "$(printf '%s' "$SEATS" | jq 'length')" = 20 ] && echo 0 || echo 1) "steps mode emits four rows a step and seats mode five a seat"

# ---- failures: an error is named, nothing prints, exit 1 --------------------------
SILENT="$WORK/silent"; mkdir -p "$SILENT"
printf '%s\n' '{"type":"user","message":{"content":"You are executing one step of a Docket run.\ndocket step claim STEP-1"}}' > "$SILENT/agent-a.jsonl"
OUT=$(bash "$USAGE_JOIN" "$SILENT" 2> "$WORK/err"); rc=$?
ok $([ "$rc" -eq 1 ] && [ -z "$OUT" ] && grep -q 'transcript carries no usage' "$WORK/err" && echo 0 || echo 1) "a lone transcript with no usage exits 1 naming it and prints no rows (rc ${rc})"
DRIFT="$WORK/drift"; mkdir -p "$DRIFT"
printf '%s\n' '{"type":"user","message":{"content":"You are executing one step of a Docket run.\nno record command here"}}' '{"type":"assistant","message":{"id":"x","model":"claude-opus-5-5","usage":{"input_tokens":1,"output_tokens":1}}}' > "$DRIFT/agent-a.jsonl"
OUT=$(bash "$USAGE_JOIN" "$DRIFT" 2> "$WORK/err"); rc=$?
ok $([ "$rc" -eq 1 ] && [ -z "$OUT" ] && grep -q 'names no `docket step claim/record STEP-N`' "$WORK/err" && echo 0 || echo 1) "an executor brief that names no step is an error, never silent overhead (rc ${rc})"
LANE="$WORK/lane"; mkdir -p "$LANE"
printf '%s\n' '{"type":"user","message":{"content":"You are a read-only scout. List."}}' '{"type":"assistant","message":{"id":"x","model":"claude-haiku-5-5","usage":{"input_tokens":1,"output_tokens":1}}}' > "$LANE/agent-a.jsonl"
OUT=$(bash "$USAGE_JOIN" "$LANE" 2> "$WORK/err"); rc=$?
ok $([ "$rc" -eq 1 ] && grep -q 'lane mismatch' "$WORK/err" && echo 0 || echo 1) "a directory of only usage-join agents is a lane mismatch (rc ${rc})"
EMPTY="$WORK/empty"; mkdir -p "$EMPTY"
OUT=$(bash "$USAGE_JOIN" "$EMPTY" 2> "$WORK/err"); rc=$?
ok $([ "$rc" -eq 1 ] && grep -q 'no agent-\*.jsonl' "$WORK/err" && echo 0 || echo 1) "a directory with no transcripts exits 1 (rc ${rc})"
bash "$USAGE_JOIN" "$WORK/missing" >/dev/null 2>&1; rc=$?
ok $([ "$rc" -eq 1 ] && echo 0 || echo 1) "a missing directory exits 1 (rc ${rc})"
bash "$USAGE_JOIN" "$WAVE" --mode nope >/dev/null 2>&1; rc=$?
ok $([ "$rc" -eq 2 ] && echo 0 || echo 1) "a bad --mode exits 2 (rc ${rc})"

bash "$USAGE_JOIN" "$WAVE" --exclude "STEP-9, nope" >/dev/null 2>&1; rc=$?
ok $([ "$rc" -eq 2 ] && echo 0 || echo 1) "a steps-mode --exclude entry that is not STEP-N exits 2 (rc ${rc})"
[ "$(bash "$USAGE_JOIN" "$WAVE" --exclude " STEP-9 , STEP-12 " 2>/dev/null | jq -r 'map(.step) | unique | join(" ")')" = "STEP-100 STEP-3 STEP-5 STEP-77" ]; rc=$?
ok $rc "a padded --exclude list is trimmed and excludes each step"
# ---- the script carries the workflow's jq, and spawns no agent -----------------------
ref x '[]' extract-jq > "$WORK/js-extract.jq" 2>/dev/null
ok $(cmp -s "$WORK/js-extract.jq" "$SCRIPTS_DIR/usage_extract.jq" && echo 0 || echo 1) "usage_extract.jq is the workflow's EXTRACT_JQ verbatim"
ok $(! grep -q -e 'claude -' -e 'Workflow(' -e 'scriptPath' "$SCRIPTS_DIR/usage_join.sh" "$SCRIPTS_DIR/usage_extract.jq" "$SCRIPTS_DIR/usage_reduce.jq" && echo 0 || echo 1) "the reader names no agent launch"

# ---- mutants: the golden diff must notice each ---------------------------------------
mutant() { # <label> <file> <sed-expr>
    local d="$WORK/mut-$1"
    rm -rf "$d"; mkdir -p "$d"; cp "$SCRIPTS_DIR"/usage_* "$d/"
    sed -i.b "$3" "$d/$2"
    if cmp -s "$d/$2" "$SCRIPTS_DIR/$2"; then ok 1 "mutant $1 changed nothing (the suite's own sed is stale)"; return; fi
    USAGE_JOIN="$d/usage_join.sh"
    golden steps "" '[]'; local a=$?
    golden seats "" '[]'; local b=$?
    golden steps "STEP-9" '["STEP-9"]'; local c=$?
    golden seats "alice" '["alice"]'; local e=$?
    USAGE_JOIN="$SCRIPTS_DIR/usage_join.sh"
    ok $([ "$a" -ne 0 ] || [ "$b" -ne 0 ] || [ "$c" -ne 0 ] || [ "$e" -ne 0 ] && echo 0 || echo 1) "the golden diff fails when $1"
}
mutant "a streamed message id is summed rather than last-wins" usage_extract.jq 's/({}; \.\[\$m\.id\] = \$m)/({}; .[$m.id + (.|length|tostring)] = $m)/'
mutant "the first occurrence of a streamed message wins" usage_extract.jq 's/({}; \.\[\$m\.id\] = \$m)/({}; if has($m.id) then . else .[$m.id] = $m end)/'
mutant "a claim agent is attributed to the step its brief mentions" usage_reduce.jq 's|(if $probe then null else $x.record end) as $record|(if $probe then null else ($x.record // $x.step_mention) end) as $record|'
mutant "a probe is attributed to a step by the reducer" usage_reduce.jq 's/(\$x\.probe and (\$x\.exec | not)) as \$probe/false as $probe/'
mutant "a probe is attributed to a step" usage_extract.jq 's/or contains("You are a DIAGNOSTIC PROBE inside a running Docket wave")/or false/; s/contains("WAVE PROBE: not a step execution")/false/; s/test("Run exactly this one command:[^)]*)))/false))/'
mutant "steps sort as text" usage_reduce.jq 's/sort_by(\.key | split("-")\[1\] | tonumber)/sort_by(.key)/'
mutant "metadata is dropped" usage_reduce.jq 's/served_metadata(\$t\.observation) != null/false/'
mutant "a seat is attributed to a step" usage_reduce.jq 's/elif \$seat != null then/elif false then/'
mutant "the dead spawn is counted as an error" usage_reduce.jq 's/if \.totals | has(\$q\.id) then \.skipped/if false then .skipped/'
mutant "an excluded key is measured" usage_reduce.jq 's/if (\$exclude | index(\$name)) != null then/if false then/'

# ---- the skill points the back-fill at the script -------------------------------------
ok $(grep -q 'scripts/usage_join.sh' "$SKILL" && echo 0 || echo 1) "SKILL.md names usage_join.sh"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
