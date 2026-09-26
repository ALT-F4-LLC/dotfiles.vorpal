#!/bin/bash

# Behavior suite for shadow.js's pure planning functions and its fixed
# per-log digest program.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node`, `awk`, and `jq` — no
# engine, no database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The shadow skill files Docket issues from what this
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
# distinct; and the digest
# program flags a fixture's bwrap denial, engine refusal, and repeated
# command, while a clean structured-output fixture carries no flag.
#
# HOW. Extracts the TEST-BEGIN/TEST-END regions and calls them directly — no
# workflow globals, no agent stubs, no I/O beyond fixture files in $WORK.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SHADOW="${SHADOW_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/shadow.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SHADOW" ] || fatal "shadow.js not found at ${SHADOW}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/shadow-workflow.XXXXXX") || fatal "mktemp failed"
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
    ' "$SHADOW"
}

extract shadow-config       > "${WORK}/config.js" || fatal "bad or missing TEST markers for shadow-config"
extract shadow-refute-tally > "${WORK}/tally.js"  || fatal "bad or missing TEST markers for shadow-refute-tally"
extract shadow-plan         > "${WORK}/plan.js"   || fatal "bad or missing TEST markers for shadow-plan"
extract shadow-digest-jq    > "${WORK}/jq.js"     || fatal "bad or missing TEST markers for shadow-digest-jq"

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

{
    cat "${WORK}/config.js"
    cat "${WORK}/tally.js"
    cat "${WORK}/plan.js"
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

node "${WORK}/suite.mjs"
exit $?
