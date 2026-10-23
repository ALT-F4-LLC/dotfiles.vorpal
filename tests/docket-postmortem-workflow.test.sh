#!/bin/bash

# Behavior suite for docket-postmortem.js's pure planning functions and its fixed
# per-log digest program.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node`, `awk`, and `jq` — no
# engine, no database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The docket-postmortem skill files Docket issues from what this
# script upholds, and promises that every agent log of a run is read. Four
# pieces carry those promises in code, and each has a failure that reads as
# success:
#   - tallyRefutations: a dead refuter seat (null) counted as an uphold lets
#     one opinion file an issue; counted as a refutation it kills every
#     candidate whose panel lost a seat.
#   - planDeepReads: a log dropped between the seated batches and the
#     deferred list is never read and never reported; flagged logs deferred
#     behind clean ones leave the most suspicious work for last.
#   - planShards / planDigestBatches: a gap or overlap in a line range skips
#     or double-counts records.
#   - groupObservations: id numbers left unmasked keep one defect in
#     hundreds of one-member groups, so no pattern ever forms.
#   - DIGEST_JQ: a flag that fires on brief text instead of tool errors
#     floods the deep-read budget; one that never fires hides real friction.
#
# WHAT IS PINNED HERE. The tally cases (majority, abstention, malformed
# verdict, remedy rework); every deep-read plan's batches plus deferred list
# equal the eligible lines exactly once, main transcripts excluded, flagged
# first and one per batch, clean packed within the byte ceiling, deferred
# flagged before deferred clean; shard and digest ranges tile 1..N with no
# gap or overlap; id numbers mask into one group while prefixes stay
# distinct; designed placeholders (unknown model_resolved, seat casts without
# --usage, claim --metadata) drop from the pattern brief only when the run's
# back-fill coverage is complete; and the digest
# program flags a fixture's bwrap denial, engine refusal, and repeated
# command, while a clean structured-output fixture carries no flag.
#
# HOW. Extracts the TEST-BEGIN/TEST-END regions and calls them directly — no
# workflow globals, no agent stubs, no I/O beyond fixture files in $WORK.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
POSTMORTEM="${POSTMORTEM_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/docket-postmortem.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$POSTMORTEM" ] || fatal "docket-postmortem.js not found at ${POSTMORTEM}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-postmortem-workflow.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

extract() { # <region> — body between the TEST-BEGIN/TEST-END markers
    awk -v r="$1" '
        index($0, "TEST-END " r)   { open = 0; ends++ }
        open                       { print }
        index($0, "TEST-BEGIN " r) { open = 1; begins++ }
        END {
            if (begins != 1 || ends != 1) {
                printf "expected exactly one TEST-BEGIN/TEST-END pair for %s, found %d/%d\n", r, begins, ends > "/dev/stderr"
                exit 1
            }
        }
    ' "$POSTMORTEM"
}

extract docket-postmortem-config       > "${WORK}/config.js" || fatal "bad or missing TEST markers for docket-postmortem-config"
extract docket-postmortem-refute-tally > "${WORK}/tally.js"  || fatal "bad or missing TEST markers for docket-postmortem-refute-tally"
extract docket-postmortem-plan         > "${WORK}/plan.js"   || fatal "bad or missing TEST markers for docket-postmortem-plan"
extract docket-postmortem-digest-jq    > "${WORK}/jq.js"     || fatal "bad or missing TEST markers for docket-postmortem-digest-jq"
extract docket-postmortem-sampling     > "${WORK}/sampling.js"  || fatal "bad or missing TEST markers for docket-postmortem-sampling"
extract docket-postmortem-inventory    > "${WORK}/inventory.js" || fatal "bad or missing TEST markers for docket-postmortem-inventory"
extract docket-postmortem-condense-jq  > "${WORK}/condense.js" || fatal "bad or missing TEST markers for docket-postmortem-condense-jq"

# ---- Fixtures for the inventory read ---------------------------------------
# A 528-line inventory like RUN-125's: 2 main transcripts, 526 workflow logs.
# The expected arrays come from this suite's own jq program, never from the
# skill's text, and the read output from running the workflow's fixed command.
awk 'BEGIN {
    for (i = 1; i <= 528; i++) {
        kind = (i <= 2) ? "main" : "workflow"
        printf "%d\t/logs/agent-%d.jsonl\t%s\twf_%d\tsess\t%d\n", i, i, kind, int(i / 40), (i * 137) % 9000 + 1
    }
}' > "${WORK}/inventory.tsv"
jq -R -s -c 'split("\n") | map(select(. != "") | split("\t")) | {kinds: map(.[2]), bytes: map(.[5] | tonumber)}' \
    "${WORK}/inventory.tsv" > "${WORK}/inventory.expected.json" || fatal "could not build the expected inventory arrays"
node -e '
eval(require("fs").readFileSync(process.argv[1], "utf8"))
process.stdout.write(inventoryReadCommand(process.argv[2]))
' "${WORK}/inventory.js" "${WORK}/inventory.tsv" > "${WORK}/inventory.cmd" || fatal "could not render the inventory read command"
bash "${WORK}/inventory.cmd" > "${WORK}/inventory.out" || fatal "the inventory read command failed"
# 527 records under a count line of 528: a reply that lost one record.
{ sed -n '1,527p' "${WORK}/inventory.out"; tail -n 1 "${WORK}/inventory.out"; } > "${WORK}/inventory.short.out"

# ---- Fixtures for the digest program --------------------------------------
# A flagged log: one bwrap denial, one engine refusal, one command run twice.
cat > "${WORK}/flagged.jsonl" <<'JSONL'
{"type":"assistant","timestamp":"2026-09-20T00:00:00Z","message":{"id":"m1","model":"claude-opus-5-5","usage":{"input_tokens":5,"output_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100},"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"git rev-parse HEAD"}}]}}
{"type":"user","timestamp":"2026-09-20T00:00:01Z","message":{"content":[{"type":"tool_result","tool_use_id":"t1","is_error":true,"content":"Exit code 1\nbwrap: Can't get type of source /x/.claude/launch.json: No such file"}]}}
{"type":"assistant","timestamp":"2026-09-20T00:00:02Z","message":{"id":"m2","model":"claude-opus-5-5","usage":{"input_tokens":5,"output_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100},"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"git rev-parse HEAD"}}]}}
{"type":"user","timestamp":"2026-09-20T00:00:03Z","message":{"content":[{"type":"tool_result","tool_use_id":"t2","content":"{\"ok\":false,\"error\":\"run has no show subcommand\"}"}]}}
{"type":"assistant","timestamp":"2026-09-20T00:00:04Z","message":{"id":"m3","model":"claude-opus-5-5","usage":{"input_tokens":5,"output_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100},"content":[{"type":"text","text":"done"}]}}
JSONL
# A clean log: its brief mentions the sandbox and a refusal, it returns
# through StructuredOutput with no final text, and no tool errored.
cat > "${WORK}/clean.jsonl" <<'JSONL'
{"type":"user","timestamp":"2026-09-20T00:00:00Z","message":{"content":"Brief: the sandbox denied a write last run; a refusal is evidence."}}
{"type":"assistant","timestamp":"2026-09-20T00:00:01Z","message":{"id":"m1","model":"claude-haiku-4-5-20251001","usage":{"input_tokens":5,"output_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100},"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"jq . x"}}]}}
{"type":"user","timestamp":"2026-09-20T00:00:02Z","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"sandbox ok; nothing refused"}]}}
{"type":"assistant","timestamp":"2026-09-20T00:00:03Z","message":{"id":"m2","model":"claude-haiku-4-5-20251001","usage":{"input_tokens":5,"output_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":100},"content":[{"type":"tool_use","id":"t2","name":"StructuredOutput","input":{"ok":true}}]}}
JSONL

node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8")
const m = src.match(/const DIGEST_JQ = String\.raw`([\s\S]*?)`/)
if (!m) { console.error("DIGEST_JQ not found in its region"); process.exit(1) }
require("fs").writeFileSync(process.argv[2], m[1])
' "${WORK}/jq.js" "${WORK}/digest.jq" || fatal "could not extract DIGEST_JQ"

digest() { # <fixture> <line>
    jq -c -n -R --arg path "$1" --arg kind workflow --argjson line "$2" -f "${WORK}/digest.jq" "$1"
}
digest "${WORK}/flagged.jsonl" 7 > "${WORK}/flagged.digest.json" || fatal "digest program failed on the flagged fixture"
digest "${WORK}/clean.jsonl" 8   > "${WORK}/clean.digest.json"   || fatal "digest program failed on the clean fixture"

# ---- Fixtures for the transcript condensation ------------------------------
# 100 turns, each an assistant text beside a 5000-character tool call, then a
# 30000-character tool result; then lines the program must not lose: invalid
# JSON, a blank line, a system record, and a thinking block.
jq -c -n 'def big($k): [range(0; $k) | "x"] | join("");
    {type: "user", uuid: "u0", timestamp: "2026-09-20T00:00:00Z", message: {role: "user", content: "Operator: drive the run."}},
    (range(1; 101) as $i |
        {type: "assistant", uuid: "a\($i)", timestamp: "2026-09-20T00:01:00Z", message: {role: "assistant", model: "claude-opus-5-5", content: [{type: "text", text: "Step \($i) text kept whole."}, {type: "tool_use", id: "t\($i)", name: "Bash", input: {command: big(5000)}}]}},
        {type: "user", uuid: "r\($i)", timestamp: "2026-09-20T00:02:00Z", message: {role: "user", content: [{type: "tool_result", tool_use_id: "t\($i)", content: big(30000)}]}})' > "${WORK}/transcript.jsonl" || fatal "could not build the transcript fixture"
printf '%s\n' 'not json at all' '' '{"type":"system","subtype":"compact","uuid":"s1","timestamp":"2026-09-20T00:03:00Z","content":"Conversation compacted"}' '{"type":"assistant","uuid":"th1","timestamp":"2026-09-20T00:04:00Z","message":{"role":"assistant","content":[{"type":"thinking","thinking":"short thought"},{"type":"text","text":"Final answer."}]}}' >> "${WORK}/transcript.jsonl"
cat >> "${WORK}/transcript.jsonl" <<'JSONL'
{"type":"user","uuid":"m1","timestamp":"2026-09-20T00:05:00Z","isMeta":true,"message":{"role":"user","content":[{"type":"text","text":"Stop hook feedback: keep going"}]}}
{"type":"user","uuid":"m2","timestamp":"2026-09-20T00:05:01Z","origin":{"kind":"task-notification"},"message":{"role":"user","content":"<task-notification>done</task-notification>"}}
{"type":"user","uuid":"m3","timestamp":"2026-09-20T00:05:02Z","isCompactSummary":true,"isSidechain":true,"message":{"role":"user","content":"This session is being continued"}}
{"type":"attachment","uuid":"at1","timestamp":"2026-09-20T00:05:03Z","attachment":{"type":"queued_command","prompt":"operator says stop"}}
{"type":"attachment","uuid":"at2","timestamp":"2026-09-20T00:05:04Z","attachment":{"type":"hook_success","content":"ok"}}
{"type":"queue-operation","timestamp":"2026-09-20T00:05:05Z","operation":"enqueue","content":"queued operator prompt"}
{"type":"summary","summary":"A compacted summary","leafUuid":"x"}
{"type":"assistant","uuid":"sv1","timestamp":"2026-09-20T00:05:06Z","message":{"role":"assistant","content":[{"type":"server_tool_use","id":"s1","name":"web_search","input":{"query":"q"}}]}}
{"type":"user","uuid":"ar1","timestamp":"2026-09-20T00:05:07Z","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"s1","content":[{"type":"text","text":"part one"},{"type":"image"}]}]}}
{"type":"user","uuid":"nm1","timestamp":"2026-09-20T00:05:08Z","message":null}
JSONL
node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8")
const m = src.match(/const CONDENSE_JQ = String\.raw`([\s\S]*?)`/)
if (!m) { console.error("CONDENSE_JQ not found in its region"); process.exit(1) }
require("fs").writeFileSync(process.argv[2], m[1])
' "${WORK}/condense.js" "${WORK}/condense.jq" || fatal "could not extract CONDENSE_JQ"
jq -c -n -R -f "${WORK}/condense.jq" "${WORK}/transcript.jsonl" > "${WORK}/condensed.jsonl" || fatal "the condensation program failed on the transcript fixture"
jq -c -n -R '[foreach inputs as $r (0; . + 1; . as $n | (try ($r | fromjson) catch null) | select(type == "object" and .type == "assistant") | .message.content[]? | select(.type == "text") | {line: $n, text: .text})]' "${WORK}/transcript.jsonl" > "${WORK}/source.texts.json" || fatal "could not list the source assistant texts"

{
    cat "${WORK}/config.js"
    cat "${WORK}/tally.js"
    cat "${WORK}/plan.js"
    cat "${WORK}/sampling.js"
    cat "${WORK}/inventory.js"
    cat "${WORK}/condense.js"
    printf 'const CONDENSED = %s\n' "$(jq -s -c . "${WORK}/condensed.jsonl")"
    printf 'const SOURCE_TEXTS = %s\n' "$(cat "${WORK}/source.texts.json")"
    printf 'const SOURCE_LINES = %s\n' "$(awk 'END { print NR }' "${WORK}/transcript.jsonl")"
    printf 'const SOURCE_BYTES = %s\n' "$(wc -c < "${WORK}/transcript.jsonl" | tr -d ' ')"
    printf 'const CONDENSED_BYTES = %s\n' "$(wc -c < "${WORK}/condensed.jsonl" | tr -d ' ')"
    printf 'const CONDENSE_PROGRAM = %s\n' "$(jq -R -s . "${WORK}/condense.jq")"
    printf 'const INVENTORY_OUT = %s\n' "$(jq -R -s . "${WORK}/inventory.out")"
    printf 'const INVENTORY_SHORT_OUT = %s\n' "$(jq -R -s . "${WORK}/inventory.short.out")"
    printf 'const INVENTORY_EXPECTED = %s\n' "$(cat "${WORK}/inventory.expected.json")"
    printf 'const FLAGGED_DIGEST = %s\n' "$(cat "${WORK}/flagged.digest.json")"
    printf 'const CLEAN_DIGEST = %s\n' "$(cat "${WORK}/clean.digest.json")"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// ---- tally ---------------------------------------------------------------
const U = { refuted: false, reason: 'holds', severityAgrees: true, remedyAutomationOk: true }
const R = { refuted: true, reason: 'does not hold', severityAgrees: true, remedyAutomationOk: true }
const W = { refuted: false, reason: 'holds, remedy under-automated', severityAgrees: true, remedyAutomationOk: false }

ok(REFUTERS_PER_FINDING === 3 && UPHOLD_QUORUM === 2, 'config: three refuters, quorum two')
ok(tallyRefutations([U, U, U]).disposition === 'upheld', 'tally: three upholds is upheld')
ok(tallyRefutations([U, R, U]).disposition === 'upheld', 'tally: two of three upholds is upheld')
ok(tallyRefutations([R, U, R]).disposition === 'refuted', 'tally: one of three upholds is refuted')
ok(tallyRefutations([null, U, U]).disposition === 'upheld', 'tally: a dead seat abstains; two upholds still uphold')
ok(tallyRefutations([null, null, U]).disposition === 'unverified', 'tally: one seated verdict is unverified, never upheld')
ok(tallyRefutations([null, R, U]).disposition === 'refuted', 'tally: one uphold of two seated is below quorum')
ok(tallyRefutations([{ reason: 'x' }, { refuted: 'no' }, U]).seated === 1, 'tally: malformed verdicts are abstentions')
ok(tallyRefutations([W, W, U]).remedyNeedsRework === true, 'tally: a majority rejecting the remedy marks it for rework')
ok(tallyRefutations([W, U, U]).remedyNeedsRework === false, 'tally: a minority rejecting the remedy does not')
ok(tallyRefutations([W, W, U]).disposition === 'upheld', 'tally: a weak remedy never refutes a true observation')

// ---- sampling ------------------------------------------------------------
// Opt-in stratified mode: sizes follow n = ceil(59 / (1 + 58 / N)), and one seed
// with one set of strata always chooses the same logs.
for (const [n, want] of [[31, 21], [100, 38], [3007, 58]]) {
    ok(sampleSize(n) === want && want === Math.ceil(59 / (1 + 58 / n)), `sampling: a stratum of ${n} is sampled at ${want}`)
}
ok(sampleSize(1) === 1 && sampleSize(5) === 5 && sampleSize(0) === 0 && sampleSize(-3) === 0 && sampleSize(2.5) === 0, 'sampling: a small stratum is read whole, and a bad size samples nothing')
const lineRange = (from, to) => Array.from({ length: to - from + 1 }, (_, i) => from + i)
const big = [{ name: 'extract/haiku', lines: lineRange(1, 3007) }, { name: 'verify/opus', lines: lineRange(4000, 4099) }, { name: 'rare', lines: lineRange(5000, 5029) }, { name: 'small', lines: lineRange(6000, 6030) }]
const pickA = selectSample(big, 'seed-1', 30)
const pickB = selectSample(big, 'seed-1', 30)
ok(JSON.stringify(pickA) === JSON.stringify(pickB), 'sampling: one seed and one set of strata choose the same logs twice')
const shuffled = big.map((s) => ({ ...s, lines: [...s.lines].reverse() }))
ok(JSON.stringify(selectSample(shuffled, 'seed-1', 30)) === JSON.stringify(pickA), 'sampling: the order the lines arrive in does not change the choice')
ok(JSON.stringify(selectSample(big, 'seed-2', 30)) !== JSON.stringify(pickA), 'sampling: another seed chooses other logs')
ok(JSON.stringify(selectSample([big[1]], 'seed-1', 30)[0]) === JSON.stringify(pickA[1]), 'sampling: a stratum is chosen alone the same as beside others')
ok(pickA.map((s) => s.n).join() === '58,38,30,21' && pickA.map((s) => s.census).join() === 'false,false,true,false', 'sampling: sizes 58, 38, a 30-log census, and 21 for 31 logs')
ok(pickA.every((s) => s.selected.length === s.n && s.selected.length + s.unsampled.length === s.N && !s.selected.some((l) => s.unsampled.includes(l))), 'sampling: selected and unsampled partition each stratum')
ok(pickA[0].selected.every((l, i, a) => i === 0 || a[i - 1] < l), 'sampling: selected lines are ascending')
ok(pickA[0].selected.slice(0, 5).join() === '129,181,220,232,281' && pickA[0].selected.at(-1) === 2971, 'sampling: seed-1 chooses the pinned logs (a drifting hash fails here)')
const spread = pickA[0].selected.reduce((a, l) => a + l, 0) / pickA[0].n
ok(spread > 1100 && spread < 1900, `sampling: the 58 chosen lines spread over 1-3007 (mean ${Math.round(spread)})`)
ok(checkStrata(big, Array(6100).fill('subagent')).length === 0, 'sampling: valid strata have no problems')
ok(checkStrata([], ['subagent']).length === 1 && checkStrata(undefined, ['subagent']).length === 1, 'sampling: missing or empty strata are refused')
ok(checkStrata([{ name: 'a', lines: [1] }, { name: 'a', lines: [2] }], ['subagent', 'subagent']).some((p) => p.includes('named twice')), 'sampling: a repeated stratum name is refused')
ok(checkStrata([{ name: 'a', lines: [1, 2] }, { name: 'b', lines: [2] }], ['subagent', 'subagent']).some((p) => p.includes('line 2 is in strata')), 'sampling: a line in two strata is refused')
ok(checkStrata([{ name: 'a', lines: [1, 3] }], ['subagent', 'subagent']).some((p) => p.includes('not an inventory line')), 'sampling: a line past the inventory is refused')
ok(checkStrata([{ name: 'a', lines: [1.5] }], ['subagent', 'subagent']).length === 1, 'sampling: a non-integer line is refused')
ok(checkStrata([{ name: 'a', lines: [1] }], ['main']).some((p) => p.includes('main transcript')), 'sampling: a main transcript is refused')
ok(checkStrata([{ name: '', lines: [1] }, { name: 'b', lines: [] }], ['subagent']).length === 2, 'sampling: an unnamed or empty stratum is refused')
const w = (h, n) => wilson95(h, n)
ok(w(44, 54).lower === 0.6916 && w(44, 54).upper === 0.8962, 'sampling: 44 of 54 reads as a Wilson interval of about 69-90%')
ok(Math.round(w(12, 38).lower * 100) === 19 && Math.round(w(12, 38).upper * 100) === 47, 'sampling: 12 of 38 reads as about 19-47%')
ok(w(0, 58).lower === 0 && w(0, 58).upper === 0.0621 && wilson95(0, 0) === null, 'sampling: no hits in 58 bound the rate near 6%, and nothing read has no interval')
const allRead = [...pickA[0].selected]
const none = sampleReport([pickA[0]], allRead, [])[0]
ok(none.hits === 0 && none.complete === true && none.rate === 0 && none.upperExact === 0.0503 && none.unseenMax === 151 && none.unsampled === 2949, 'sampling: no hits in 58 of 3007 leaves a 5.0% bound and up to 151 unseen logs')
const hit = sampleReport([pickA[1]], pickA[1].selected, [pickA[1].selected[0], pickA[1].selected[0], 99999])[0]
ok(hit.hits === 1 && hit.hitLines.length === 1 && hit.n === 38 && hit.N === 100 && hit.upperExact === null, 'sampling: a log citing two observations is one hit, and a cited line outside the sample is none')
const part = sampleReport([pickA[0]], allRead.slice(0, 10), [allRead[0]])[0]
ok(part.complete === false && part.rate === null && part.interval === null && part.read === 10 && part.hits === 1, 'sampling: an unfinished stratum reports no rate or interval')
const resc = sampleReport([pickA[0]], allRead, [], new Set([pickA[0].unsampled[0], 99999]))[0]
ok(resc.unsampled === 2948, 'sampling: a flagged log read anyway is not counted as unsampled')
const cen = sampleReport([pickA[2]], pickA[2].selected, pickA[2].selected.slice(0, 3))[0]
ok(cen.census && cen.rate === 0.1 && cen.interval.lower === 0.1 && cen.interval.upper === 0.1 && cen.upperExact === null, 'sampling: a census has no sampling error')

// ---- ranges --------------------------------------------------------------
function tiles(ranges, n) {
    let next = 1
    for (const r of ranges) { if (r.from !== next || r.to < r.from) return false; next = r.to + 1 }
    return next === n + 1
}
for (const [n, size] of [[1, 40], [40, 40], [41, 40], [1039, 40]]) {
    ok(tiles(planDigestBatches(n, size), n), `digest batches tile 1..${n} at size ${size}`)
}
ok(planDigestBatches(0, 40).length === 0, 'digest batches: empty inventory plans nothing')
for (const [lines, bytes] of [[2422, 6_700_000], [10, 100], [1, 5_000_000], [7, 0]]) {
    ok(tiles(planShards(lines, bytes, SHARD_BYTES), lines), `shards tile 1..${lines} for ${bytes} bytes`)
}
ok(planShards(2422, 6_700_000, SHARD_BYTES).length >= Math.ceil(6_700_000 / SHARD_BYTES) - 1, 'shards: a large transcript splits into several shards')
ok(planShards(0, 0, SHARD_BYTES).length === 0, 'shards: an empty transcript plans nothing')

// ---- deep-read plan ------------------------------------------------------
{
    const kinds = ['main', 'workflow', 'workflow', 'subagent', 'workflow', 'workflow', 'workflow']
    const bytes = [9_000_000, 900_000, 200_000, 200_000, 100_000, 300_000, 50_000]
    const flagged = new Set([1, 3, 6])
    const lines = [1, 2, 3, 4, 5, 6, 7]
    const full = planDeepReads(lines, kinds, bytes, flagged, 100, DEEP_BATCH_BYTES)
    const seated = full.batches.flatMap((b) => b.lines)
    const every = [...seated, ...full.deferred].sort((a, b) => a - b)
    ok(JSON.stringify(every) === JSON.stringify([2, 3, 4, 5, 6, 7]), `deep: every non-main line planned exactly once (got ${JSON.stringify(every)})`)
    ok(!seated.includes(1) && !full.deferred.includes(1), 'deep: main transcripts are never deep-read')
    ok(full.deferred.length === 0, 'deep: an ample budget defers nothing')
    ok(full.batches[0].flagged && full.batches[1].flagged && full.batches[0].lines.length === 1, 'deep: flagged logs come first, one per reader')
    ok(full.batches.filter((b) => !b.flagged).every((b) => b.lines.length === 1 || b.lines.reduce((s, l) => s + bytes[l - 1], 0) <= DEEP_BATCH_BYTES), 'deep: clean readers stay within the byte ceiling unless alone')
    ok(full.batches.some((b) => !b.flagged && b.lines.includes(2) && b.lines.length === 1), 'deep: a clean log over the ceiling is read alone')

    const tight = planDeepReads(lines, kinds, bytes, flagged, 1, DEEP_BATCH_BYTES)
    ok(tight.batches.length === 1 && tight.batches[0].flagged, 'deep: a budget of one seats the first flagged log')
    ok(tight.deferred[0] === 6, `deep: deferred flagged logs come before deferred clean ones (got ${JSON.stringify(tight.deferred)})`)
    const tightAll = [...tight.batches.flatMap((b) => b.lines), ...tight.deferred].sort((a, b) => a - b)
    ok(JSON.stringify(tightAll) === JSON.stringify([2, 3, 4, 5, 6, 7]), 'deep: a tight budget loses no line')
    ok(planDeepReads(lines, kinds, bytes, flagged, -5, DEEP_BATCH_BYTES).batches.length === 0, 'deep: a negative budget seats nothing and defers everything')
}

// ---- agent-budget preflight ----------------------------------------------
{
    const fixture = (logs, lines, bytes) => {
        const kinds = ['main', ...Array.from({ length: logs - 1 }, () => 'workflow')]
        const sizes = [bytes, ...Array.from({ length: logs - 1 }, () => 40_000)]
        const shards = planShards(lines, bytes, SHARD_BYTES).length
        const batches = planDigestBatches(logs, DIGEST_BATCH).length
        const plan = { spent: 1, digestBatches: batches, shards, layers: 6, reserved: RESERVED_AGENTS, cap: AGENT_CAP, margin: AGENT_CAP_MARGIN }
        return { plan, kinds, sizes, shards, batches }
    }
    // The measured run: 6700 logs and a 296 MB, 44000-line driver transcript.
    const big = fixture(6700, 44_000, 296_000_000)
    const bigBudget = planBudget(big.plan, big.kinds, big.sizes)
    ok(RESERVED_AGENTS === 242, `budget: the reserve is the pattern analyst, ${REFUTE_CAP} x ${REFUTERS_PER_FINDING} refuters, and the reconciler (got ${RESERVED_AGENTS})`)
    ok(bigBudget.ok === false && bigBudget.fixed + bigBudget.reserved > AGENT_CAP, `budget: 6700 logs and a 296 MB transcript do not fit (got fixed ${bigBudget.fixed} + reserved ${bigBudget.reserved})`)
    ok(big.shards >= 580 && big.batches === 168, `budget: the fixture shards to about 590 readers (got ${big.shards} shards, ${big.batches} digest batches)`)
    ok(/spent\+planned \d+ .* \+ reserved 242 .* = \d+ > cap 1000 - margin 10 = 990/.test(bigBudget.message || ''), `budget: the refusal names spent + reserved > cap (got ${bigBudget.message})`)
    ok(bigBudget.message.includes(`${big.shards} conductor shards`) && bigBudget.message.includes('168 digest batches') && bigBudget.message.includes('6 layer analysts'), 'budget: the refusal names every stage-1 count')
    ok(bigBudget.deepReaders > 0, 'budget: the refusal names the deep readers a full pass needs')
    // A modest run: 1000 logs and a 20 MB transcript.
    const small = fixture(1000, 3000, 20_000_000)
    const smallBudget = planBudget(small.plan, small.kinds, small.sizes)
    ok(smallBudget.ok === true && smallBudget.message === null, `budget: 1000 logs and a 20 MB transcript fit (got ${smallBudget.message})`)
    ok(smallBudget.total <= AGENT_CAP - AGENT_CAP_MARGIN, 'budget: a fitting plan stays under cap less margin')
    // The boundary: exactly at cap less margin fits, one more does not.
    const edge = { spent: 0, digestBatches: AGENT_CAP - AGENT_CAP_MARGIN - RESERVED_AGENTS, shards: 0, layers: 0, reserved: RESERVED_AGENTS, cap: AGENT_CAP, margin: AGENT_CAP_MARGIN }
    ok(planBudget(edge, [], []).ok === true, 'budget: a plan exactly at cap less margin fits')
    ok(planBudget({ ...edge, shards: 1 }, [], []).ok === false, 'budget: one agent over cap less margin is refused')
    ok(planBudget({ ...edge, digestBatches: 0, shards: 0, layers: 0 }, [], []).ok === true, 'budget: a plan of nothing but the reserve fits')
    ok(bigBudget.launches === Math.ceil(bigBudget.deepReaders / (AGENT_CAP - AGENT_CAP_MARGIN - 1 - RESERVED_AGENTS)) && /launch\(es\) of 747/.test(bigBudget.message), `budget: the refusal names the deep-read launches needed (got ${bigBudget.launches})`)
    // The refute stage seats only what the cap leaves room for.
    ok(refuteSeatCap(0, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP) === REFUTE_CAP, 'refute cap: an unspent budget seats the full REFUTE_CAP')
    ok(refuteSeatCap(990 - 1 - 3 * 10, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP) === 10, 'refute cap: room for 30 seats and the reconciler judges 10 candidates')
    ok(refuteSeatCap(990, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP) === 0 && refuteSeatCap(1500, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP) === 0, 'refute cap: an exhausted or overspent budget seats nothing, never a negative count')
    ok(refuteSeatCap(989 - 3 * REFUTE_CAP, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP) === REFUTE_CAP, 'refute cap: exactly enough room for REFUTE_CAP candidates seats all of them')
}

// ---- grouping ------------------------------------------------------------
{
    const obs = [
        { line: 3, surface: 'engine', symptom: 'refusal', target: 'docket step show STEP-10471', severity: 'friction', claim: 'a', locator: 'x', automatable: true },
        { line: 9, surface: 'engine', symptom: 'refusal', target: 'Docket step show  STEP-20002', severity: 'friction', claim: 'b', locator: 'y', automatable: true },
        { line: 9, surface: 'engine', symptom: 'refusal', target: 'docket step show step-7', severity: 'paper-cut', claim: 'c', locator: 'z', automatable: false },
        { line: 4, surface: 'sandbox', symptom: 'denial', target: 'write /tmp/claude-1000/STEP-1.d', severity: 'friction', claim: 'd', locator: 'w', automatable: true },
    ]
    const g = groupObservations(obs)
    ok(g.length === 2, `group: id numbers, case, spacing, and scratch paths mask into one group per defect (got ${g.length})`)
    const other = groupObservations([
        { line: 1, surface: 'engine', symptom: 'refusal', target: 'issue ABC-7', severity: 'friction', claim: 'a', locator: 'x', automatable: true },
        { line: 2, surface: 'engine', symptom: 'refusal', target: 'issue XYZ-7', severity: 'friction', claim: 'b', locator: 'y', automatable: true },
    ])
    ok(other.length === 2, 'group: the id prefix is kept, so two projects stay apart')
    ok(g[0].count === 3 && JSON.stringify(g[0].lines) === '[3,9]', 'group: counts every observation and each line once')
    ok(g[0].automatable === 2 && g[0].examples.length === 3, 'group: counts automatable touches and keeps up to three examples')
}

// ---- inventory read ------------------------------------------------------
{
    const throwsWith = (fn, ...parts) => {
        try { fn() } catch (e) { return parts.every((p) => String(e.message).includes(p)) }
        return false
    }
    const E = INVENTORY_EXPECTED
    const r = resolveInventory(INVENTORY_OUT, { file: '/x/inventory.tsv' }, null)
    ok(r.total === 528, `inventory: the derived line count is 528 (got ${r.total})`)
    ok(r.kinds.length === E.kinds.length && r.kinds.every((k, i) => k === E.kinds[i]), 'inventory: derived kinds equal the jq-built array line for line')
    ok(r.bytes.length === E.bytes.length && r.bytes.every((b, i) => b === E.bytes[i]), 'inventory: derived bytes equal the jq-built array line for line')
    ok(JSON.stringify(planDigestBatches(r.total, DIGEST_BATCH)) === JSON.stringify(planDigestBatches(E.kinds.length, DIGEST_BATCH)), 'inventory: derived arrays plan the same digest batches')
    const every = Array.from({ length: 528 }, (_, i) => i + 1)
    const flagged = new Set([3, 40, 527])
    ok(JSON.stringify(planDeepReads(every, r.kinds, r.bytes, flagged, 100, DEEP_BATCH_BYTES)) === JSON.stringify(planDeepReads(every, E.kinds, E.bytes, flagged, 100, DEEP_BATCH_BYTES)), 'inventory: derived arrays plan the same deep reads')
    ok(throwsWith(() => resolveInventory(INVENTORY_SHORT_OUT, { file: '/x' }, null), '527', '528'), 'inventory: 527 records under a count of 528 throws naming both counts')

    const k508 = E.kinds.slice(0, 508)
    const b508 = E.bytes.slice(0, 508)
    ok(throwsWith(() => resolveInventory(INVENTORY_OUT, { file: '/x', kinds: k508, bytes: E.bytes }, null), 'kinds has 508 entries', '528'), 'inventory: a 508-entry kinds override is refused naming 508 and 528')
    ok(throwsWith(() => resolveInventory(INVENTORY_OUT, { file: '/x', kinds: E.kinds, bytes: b508 }, null), 'bytes has 508 entries', '528'), 'inventory: a 508-entry bytes override is refused naming 508 and 528')
    const o = resolveInventory(INVENTORY_OUT, { file: '/x', kinds: E.kinds, bytes: E.bytes }, null)
    ok(o.kinds === E.kinds && o.bytes === E.bytes, 'inventory: a full-length override is used as passed')

    const c = resolveInventory(INVENTORY_OUT, { file: '/x' }, [3, 528])
    ok(c.total === 528 && JSON.stringify(planDeepReads([3, 528], c.kinds, c.bytes, new Set([528]), 10, DEEP_BATCH_BYTES)) === JSON.stringify(planDeepReads([3, 528], E.kinds, E.bytes, new Set([528]), 10, DEEP_BATCH_BYTES)), 'inventory: a continuation with no arrays plans its deep reads from the derived arrays')
    ok(throwsWith(() => resolveInventory(INVENTORY_OUT, { file: '/x' }, [529]), '529', '528'), 'inventory: a continuation line past the derived count is refused')
}

// ---- designed placeholders -----------------------------------------------
{
    const obs = (target, n = 1) => Array.from({ length: n }, (_, i) => ({ surface: 'executor', symptom: 'missing-evidence', target, severity: 'paper-cut', line: i + 1, claim: 'gap', locator: 'x', automatable: false }))
    const real = obs('docket step record --artifact', 2)
    const all = groupObservations([...obs('docket vote cast --usage', 5), ...obs('model_resolved', 4), ...obs('effort_resolved', 1), ...obs('docket claim --metadata', 2), ...real])
    const keys = (gs) => gs.map((g) => g.target).sort().join('|')

    const full = { casts: 64, reported: 64, modelTotal: 948, modelUnknown: 9 }
    const a = splitDesignedSentinels(all, full)
    ok(keys(a.kept) === 'docket step record --artifact', `sentinels: complete coverage keeps only the real group (kept: ${keys(a.kept)})`)
    ok(a.suppressed.length === 4 && a.suppressed.every((s) => s.count > 0 && s.sentinel && s.key), 'sentinels: every dropped group is listed with its count and sentinel')
    ok(a.suppressed.find((s) => s.key.includes('vote cast')).sentinel === 'vote-usage' && a.suppressed.find((s) => s.key.includes('claim')).sentinel === 'claim-metadata', 'sentinels: dropped groups name their placeholder')

    const short = splitDesignedSentinels(all, { ...full, reported: 60 })
    ok(short.kept.some((g) => g.target === 'docket vote cast --usage') && !short.kept.some((g) => g.target === 'model_resolved'), 'sentinels: reported<casts keeps the vote-usage group and still drops the complete model groups')
    ok(short.suppressed.every((s) => s.sentinel !== 'vote-usage'), 'sentinels: reported<casts suppresses no vote-usage group')

    const unfilled = splitDesignedSentinels(all, { ...full, modelUnknown: 400 })
    ok(unfilled.kept.some((g) => g.target === 'model_resolved') && unfilled.kept.some((g) => g.target === 'docket claim --metadata') && !unfilled.kept.some((g) => g.target.includes('vote cast')), 'sentinels: a mostly-unknown model_resolved keeps the model and claim groups')
    ok(keys(splitDesignedSentinels(all, { ...full, modelTotal: 0, modelUnknown: 0 }).kept).includes('model_resolved'), 'sentinels: no known model_resolved at all is not complete')
    const none = splitDesignedSentinels(all, null)
    ok(none.kept.length === all.length && none.suppressed.length === 0, 'sentinels: without coverage nothing is dropped')
    ok(a.kept.every((g, i, arr) => i === 0 || arr[i - 1].count >= g.count), 'sentinels: kept groups stay in count order')

    const defects = groupObservations([
        ...obs('model_resolved', 2).map((o) => ({ ...o, symptom: 'wrong-model' })),
        ...obs('docket vote cast --usage', 2).map((o) => ({ ...o, symptom: 'tool-error' })),
    ])
    const d = splitDesignedSentinels(defects, full)
    ok(d.kept.length === 2 && d.suppressed.length === 0, 'sentinels: a wrong-model or tool-error group on a placeholder target survives complete coverage')
    ok(a.suppressed.every((s) => Array.isArray(s.lines) && s.lines.length > 0 && Array.isArray(s.examples) && s.examples.length > 0), 'sentinels: a dropped group keeps its lines and examples for audit')
    ok(validUsageCoverage(full) && !validUsageCoverage(null) && !validUsageCoverage({ ...full, casts: null }) && !validUsageCoverage({ ...full, modelUnknown: 949 }) && !validUsageCoverage({ ...full, reported: -1 }), 'sentinels: a partial, negative or inconsistent coverage object is not usable')
    ok(/except model-resolved, claim-metadata: their coverage/.test(sentinelNote({ ...full, modelUnknown: 400 })) && /except vote-usage: its coverage/.test(sentinelNote({ ...full, reported: 60 })), 'brief note: its/their agrees with the number of open placeholders')
    ok(/64\/64/.test(sentinelNote(full)) && /939\/948/.test(sentinelNote(full)) && !/except/.test(sentinelNote(full)), 'brief note: complete coverage states the numbers and no exception')
    ok(/except vote-usage/.test(sentinelNote({ ...full, reported: 60 })), 'brief note: short vote coverage names vote-usage as still reportable')
    ok(/was not passed/.test(sentinelNote(null)), 'brief note: no coverage says so')
    ok(MODEL_UNKNOWN_TOLERANCE === 0.05, 'config: model-unknown tolerance is 5%')
}

// ---- transcript condensation ---------------------------------------------
{
    ok(CONDENSED.length === SOURCE_LINES, `condense: one record per source line (${CONDENSED.length} of ${SOURCE_LINES})`)
    ok(CONDENSED.every((r, i) => Number.isInteger(r.src_line) && r.src_line === i + 1), 'condense: every record carries src_line equal to its source line number')
    const kept = CONDENSED.filter((r) => r.type === 'assistant').flatMap((r) => r.blocks.filter((b) => b.t === 'text').map((b) => ({ line: r.src_line, text: b.text })))
    ok(kept.length === SOURCE_TEXTS.length && SOURCE_TEXTS.every((s, i) => kept[i].line === s.line && kept[i].text === s.text), `condense: every assistant text is kept whole, at its source line (${kept.length} of ${SOURCE_TEXTS.length})`)
    ok(CONDENSED.filter((r) => r.blocks).every((r) => 'uuid' in r && 'timestamp' in r && typeof r.role === 'string'), 'condense: uuid, timestamp and role stay on every conversation record')
    ok(CONDENSED[1].model === 'claude-opus-5-5', 'condense: the assistant model is kept')
    const call = CONDENSED[1].blocks.find((b) => b.t === 'tool_use')
    ok(call.input.length === CONDENSE_CALL_CHARS && call.cut > 0 && call.name === 'Bash', `condense: a tool call is cut to ${CONDENSE_CALL_CHARS} characters and says how many were lost (cut ${call.cut})`)
    const result = CONDENSED[2].blocks.find((b) => b.t === 'tool_result')
    ok(result.text.length === CONDENSE_RESULT_CHARS && result.cut === 30000 - CONDENSE_RESULT_CHARS && result.is_error === false, `condense: a tool result is cut to ${CONDENSE_RESULT_CHARS} characters (cut ${result.cut})`)
    ok(CONDENSED[0].blocks[0].text === 'Operator: drive the run.', 'condense: operator text is kept whole')
    const by = (uuid) => CONDENSED.find((r) => r.uuid === uuid)
    ok(JSON.stringify(CONDENSED.filter((r) => r.unparsed).map((r) => r.src_line)) === '[202,203]', 'condense: a non-JSON and a blank line become unparsed markers at their own line')
    ok(by('s1').type === 'system' && by('s1').text === 'Conversation compacted' && by('s1').subtype === 'compact', 'condense: a system record keeps its subtype and text')
    ok(by('th1').blocks[0].t === 'thinking' && by('th1').blocks[1].text === 'Final answer.', 'condense: thinking is marked and the text beside it kept')
    ok(by('m1').meta === true && by('m2').origin === 'task-notification' && by('m3').compact === true && by('m3').sidechain === true, 'condense: meta, origin, compact and sidechain are carried when set')
    ok(!('meta' in by('u0')) && !('origin' in by('u0')) && !('compact' in by('u0')), 'condense: an operator message carries none of the injected-text flags')
    ok(by('m2').blocks[0].text === '<task-notification>done</task-notification>' && by('m1').blocks[0].text === 'Stop hook feedback: keep going', 'condense: injected text is kept whole beside its flag')
    ok(by('at1').subtype === 'queued_command' && by('at1').text === 'operator says stop', 'condense: a queued command attachment keeps its prompt whole')
    ok(by('at2').subtype === 'hook_success' && by('at2').text.includes('"content":"ok"'), 'condense: another attachment keeps its type and body')
    ok(CONDENSED.some((r) => r.type === 'queue-operation' && r.text === 'queued operator prompt'), 'condense: a queue-operation record keeps its content')
    ok(CONDENSED.some((r) => r.type === 'summary' && r.text === 'A compacted summary'), 'condense: a summary record keeps its summary')
    ok(by('sv1').blocks[0].t === 'server_tool_use' && by('sv1').blocks[0].input.includes('"query":"q"'), 'condense: a server tool call keeps its input')
    ok(by('ar1').blocks[0].text === 'part one\n[image]', 'condense: an array-shaped tool result is joined and cut')
    ok(CONDENSED.some((r) => r.uuid === 'nm1' && r.text === ''), 'condense: a record with a null message still yields a record')
    ok(CONDENSE_PROGRAM.includes('clipped(1500)') && CONDENSE_PROGRAM.includes('clipped(400)') && CONDENSE_CALL_CHARS === 1500 && CONDENSE_RESULT_CHARS === 400, 'condense: the jq limits match the stated constants')
    // Shards drop by the byte ratio. A small shard size makes the fixture split.
    const shardBytes = 100_000
    const raw = planShards(SOURCE_LINES, SOURCE_BYTES, shardBytes).length
    const small = planShards(CONDENSED.length, CONDENSED_BYTES, shardBytes).length
    ok(CONDENSED_BYTES * 8 < SOURCE_BYTES, `condense: the condensed file is under an eighth of the source (${CONDENSED_BYTES} of ${SOURCE_BYTES} bytes)`)
    ok(raw >= 30 && small * 8 <= raw, `condense: the shard count drops by the byte ratio (${raw} to ${small})`)
    // The relay's reply is checked against the session.
    const session = { lines: 100, bytes: 5_000_000 }
    const good = { sourceLines: 100, lines: 100, bytes: 400_000, unparsed: 0, error: '' }
    ok(resolveCondensed(good, session).ok === true, 'condense reply: matching counts are accepted')
    ok(resolveCondensed(null, session).ok === false, 'condense reply: no reply is refused')
    ok(resolveCondensed({ ...good, error: 'jq: error' }, session).ok === false, 'condense reply: an error is refused')
    ok(resolveCondensed({ ...good, lines: 99 }, session).ok === false, 'condense reply: a record missing from the condensed file is refused')
    ok(resolveCondensed({ ...good, sourceLines: 101 }, session).ok === false, 'condense reply: a source count that differs from args.sessions is refused')
    ok(resolveCondensed({ ...good, bytes: 0 }, session).ok === false, 'condense reply: an empty condensed file is refused')
    ok(resolveCondensed({ ...good, bytes: '400000' }, session).ok === false, 'condense reply: a non-integer count is refused')
    ok(resolveCondensed({ ...good, unparsed: 100 }, session).ok === false, 'condense reply: a file that is all unparsed markers (the program run without -R) is refused')
    ok(resolveCondensed({ ...good, unparsed: 10 }, session).ok === true && resolveCondensed({ ...good, unparsed: 11 }, session).ok === false, 'condense reply: more than a tenth unparsed is refused')
    ok(resolveCondensed({ sourceLines: 100, lines: 100, bytes: 400_000, error: '' }, session).ok === false, 'condense reply: a missing unparsed count is refused')
}

// ---- digest program ------------------------------------------------------
{
    const f = FLAGGED_DIGEST
    ok(f.line === 7 && f.tool_errors === 1, `digest: flagged fixture has one tool error (got ${f.tool_errors})`)
    ok(f.flags.includes('denial'), 'digest: a bwrap tool error is a denial')
    ok(f.flags.includes('refusal'), 'digest: an ok:false tool result is a refusal')
    ok(f.flags.includes('repeated-command'), 'digest: a command run twice is repeated')
    ok(f.usage.output === 30 && f.tool_uses === 2, 'digest: usage and tool uses count each message and tool call once')
    const c = CLEAN_DIGEST
    ok(c.flags.length === 0, `digest: brief text about sandboxes and refusals raises no flag (got ${JSON.stringify(c.flags)})`)
    ok(c.tools.StructuredOutput === 1, 'digest: a structured-output return counts as a final result')
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS


# Wiring: the budget preflight must throw before the first digest agent is seated.
wiring=0
pre=$(grep -n 'need(budget.ok, budget.message)' "$POSTMORTEM" | head -1 | cut -d: -f1)
call=$(grep -n 'const budget = planBudget(' "$POSTMORTEM" | head -1 | cut -d: -f1)
args=$(sed -n "${call}p" "$POSTMORTEM")
for want in 'spent,' 'digestBatches: digestBatches.length' 'shards: shardPlan.length' 'layers: LAYERS.length' 'reserved: RESERVED_AGENTS' 'cap: AGENT_CAP' 'margin: AGENT_CAP_MARGIN' 'inventory.kinds, inventory.bytes'; do
    case "$args" in *"$want"*) ;; *) echo "FAIL: the budget preflight call passes '$want'"; wiring=1 ;; esac
done
refute=$(grep -c 'refuteSeatCap(spent, AGENT_CAP, AGENT_CAP_MARGIN, REFUTERS_PER_FINDING, REFUTE_CAP)' "$POSTMORTEM")
[ "$refute" -eq 1 ] || { echo "FAIL: the refute stage is bounded by refuteSeatCap(spent, ...)"; wiring=1; }
cstage=$(grep -n 'resolveCondensed(await seat(condenseBrief' "$POSTMORTEM" | head -1 | cut -d: -f1)
cshard=$(grep -n 'const shardPlan = sessions.flatMap' "$POSTMORTEM" | head -1 | cut -d: -f1)
if [ -n "$cstage" ] && [ -n "$cshard" ] && [ "$cstage" -lt "$cshard" ] && [ -n "$pre" ] && [ "$cshard" -lt "$pre" ] && grep -q 'condensed.get(s.sessionId)' "$POSTMORTEM" && grep -q 'condensed: source.condensed' "$POSTMORTEM" && grep -q 'planShards(source.lines, source.bytes, SHARD_BYTES)' "$POSTMORTEM" && ! grep -q 'planShards(s.lines' "$POSTMORTEM"; then
    echo "PASS: the conductor shards are cut from the condensed copy, after condensation and before the budget preflight"
else
    echo "FAIL: the conductor shards are cut from the condensed copy, after condensation and before the budget preflight (condense line '${cstage}', shard line '${cshard}', preflight line '${pre}')"
    wiring=1
fi
if grep -qF "jq -c -n -R -f '\${jqFile}' '\${session.transcript}' > '\${outFile}' &&" "$POSTMORTEM"; then
    echo "PASS: the condensation relay runs the program with -R over the transcript and writes the out file"
else
    echo "FAIL: the condensation relay runs the program with -R over the transcript and writes the out file"
    wiring=1
fi
dig=$(grep -n 'parallel(digestBatches.map' "$POSTMORTEM" | head -1 | cut -d: -f1)

if [ -n "$pre" ] && [ -n "$dig" ] && [ "$pre" -lt "$dig" ]; then
    echo "PASS: the budget preflight throws before the first digest agent is seated"
else
    echo "FAIL: the budget preflight throws before the first digest agent is seated (preflight line '${pre}', first digest line '${dig}')"
    wiring=1
fi

# Seats return their notes; none is told to write a notes file. The sensitive-path
# guard refuses a write into the audit directory from a seat, so a brief that
# asks for one burns a refusal per seat and loses the notes.
POSTMORTEM_SKILL="${POSTMORTEM_SKILL_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-postmortem/SKILL.md}"
# Every line that interpolates the audit directory is a digest or condense path:
# the two directory constants and the two jq program files those seats write.
stray=$(grep -F '${auditDir}' "$POSTMORTEM" | grep -vE '^const (digestDir|condenseDir) = |^    const jqFile = `\$\{auditDir\}/(digest|condense)\.jq\.\$\{index\}`$' | grep -vE '^//' | head -3)
if [ -z "$stray" ]; then
    echo "PASS: only the digest and condense paths interpolate the audit directory"
else
    echo "FAIL: only the digest and condense paths interpolate the audit directory (stray: ${stray})"
    wiring=1
fi
boundary=$(awk 'index($0, "const BOUNDARY = `") { open = 1 } open { print } open && /`$/ { exit }' "$POSTMORTEM")
if [ -n "$boundary" ] && ! printf '%s\n' "$boundary" | grep -qF '${auditDir}' && printf '%s\n' "$boundary" | grep -qF 'Write no file'; then
    echo "PASS: the shared boundary text grants no write under the audit directory"
else
    echo "FAIL: the shared boundary text grants no write under the audit directory"
    wiring=1
fi
for fn in conductorBrief layerBrief deepBrief patternsBrief refuteBrief reconcileBrief; do
    if awk -v s="function ${fn}(" 'index($0, s) { open = 1 } open { print } open && /^}/ { exit }' "$POSTMORTEM" | grep -qF 'Write no file'; then
        echo "PASS: ${fn} tells the seat to write no file"
    else
        echo "FAIL: ${fn} tells the seat to write no file"
        wiring=1
    fi
done
for schema in CANDIDATES_SCHEMA DEEP_SCHEMA VERDICT_SCHEMA RECONCILE_SCHEMA; do
    if awk -v s="const ${schema} = {" 'index($0, s) { open = 1 } open { print } open && /^}/ { exit }' "$POSTMORTEM" | grep -q '^        notes: { type'; then
        echo "PASS: ${schema} carries a notes field"
    else
        echo "FAIL: ${schema} carries a notes field"
        wiring=1
    fi
done
if awk 'index($0, "const VERDICT_SCHEMA = {") { open = 1 } open { print } open && /^}/ { exit }' "$POSTMORTEM" | grep -E "^    required: " | grep -q notes; then
    echo "FAIL: VERDICT_SCHEMA does not require notes (a refuter that omits them must still vote)"
    wiring=1
else
    echo "PASS: VERDICT_SCHEMA does not require notes (a refuter that omits them must still vote)"
fi
missing=""
for site in "keepNotes(name," 'keepNotes(`layer ' 'keepNotes(`deep ' "keepNotes('patterns'," 'keepNotes(`refute ' "keepNotes('reconcile',"; do
    grep -qF -- "$site" "$POSTMORTEM" || missing="${missing} ${site}"
done
if [ -z "$missing" ] && grep -q '^    seatNotes,$' "$POSTMORTEM"; then
    echo "PASS: every note-returning seat feeds seatNotes and the return carries it"
else
    echo "FAIL: every note-returning seat feeds seatNotes and the return carries it (missing:${missing})"
    wiring=1
fi
if grep -qF 'verdicts: votes.map((v) => (v == null ? v : (({ notes, ...rest }) => rest)(v)))' "$POSTMORTEM"; then
    echo "PASS: refuter notes do not ride into the reconciler brief or a continuation"
else
    echo "FAIL: refuter notes do not ride into the reconciler brief or a continuation"
    wiring=1
fi
if grep -qF 'const NOTES_MAX = 1200' "$POSTMORTEM" && grep -qF 'notes.slice(0, NOTES_MAX)' "$POSTMORTEM"; then
    echo "PASS: a seat's notes are bounded before they reach the return"
else
    echo "FAIL: a seat's notes are bounded before they reach the return"
    wiring=1
fi
if [ -f "$POSTMORTEM_SKILL" ] && grep -q 'seatNotes' "$POSTMORTEM_SKILL" && grep -qF 'notes-<launch ordinal>.md' "$POSTMORTEM_SKILL" && grep -qF 'with the Write tool, never a shell heredoc' "$POSTMORTEM_SKILL"; then
    echo "PASS: the skill persists the returned notes with the Write tool, as data"
else
    echo "FAIL: the skill persists the returned notes with the Write tool, as data"
    wiring=1
fi

# The opt-in is wired through the workflow body and the return, and the skill states
# when it is allowed. Default full coverage must not change: without args.sampling
# no log is dropped from the deep-read candidates.
if grep -qF '.filter((line) => !unsampledSet.has(line))' "$POSTMORTEM" && grep -qF 'const unsampledSet = new Set(sampleSelection ? sampleSelection.flatMap((s) => s.unsampled) : [])' "$POSTMORTEM"; then
    echo "PASS: only the sample's unsampled lines leave the deep-read candidates"
else
    echo "FAIL: only the sample's unsampled lines leave the deep-read candidates"
    wiring=1
fi
if grep -qF 'for (const line of rescuedFlagged) unsampledSet.delete(line)' "$POSTMORTEM" && grep -qF 'flaggedRead: rescuedFlagged.size,' "$POSTMORTEM" && [ -f "$POSTMORTEM_SKILL" ] && grep -qF 'Every digest-flagged log is read whatever' "$POSTMORTEM_SKILL"; then
    echo "PASS: a flagged log is read even when a stratum would sample it away"
else
    echo "FAIL: a flagged log is read even when a stratum would sample it away"
    wiring=1
fi
if grep -q '^    sampling: sampled,$' "$POSTMORTEM" && grep -qF 'input.sampling || null' "$POSTMORTEM"; then
    echo "PASS: args.sampling is read and the return carries sampling"
else
    echo "FAIL: args.sampling is read and the return carries sampling"
    wiring=1
fi
if [ -f "$POSTMORTEM_SKILL" ] && grep -qF 'args.sampling' "$POSTMORTEM_SKILL" && grep -qF 'AskUserQuestion' "$POSTMORTEM_SKILL"; then
    echo "PASS: the skill names args.sampling and leaves the choice to the operator"
else
    echo "FAIL: the skill names args.sampling and leaves the choice to the operator"
    wiring=1
fi

node "${WORK}/suite.mjs"
suite=$?
[ "$suite" -eq 0 ] && [ "$wiring" -eq 0 ]
exit $?
