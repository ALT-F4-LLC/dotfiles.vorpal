#!/bin/bash

# Behavior suite for wave.js's vote-gate retry reporting (DOT-744).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. RUN-52 (wave wf_3461bca8-48c, DISPATCH-302): STEP-2493's
# vote gate tallied APPROVED 3/3, yet the completion notification carried a
# failures entry — "[STEP-2493 · gate:tally] failed: API Error: Connection
# lost mid-response" — beside the same step's gate-passed verdict, and the
# 8-spawns-for-3-seats cost was visible nowhere. The failure was retry noise
# the script had already absorbed; a failure entry beside a success verdict
# for the same step is exactly the shape a conductor misreads as a failed
# gate. The fix: when a vote row's tally SUCCEEDS, absorbed agent-level
# errors ride the success result as `notes` (each naming the tally's
# success), spawn/seat/retry accounting is reported explicitly
# (`spawn_accounting`), and nothing failure-shaped is attached; a tally that
# FAILS keeps its errors as real failures, un-softened.
#
# HOW. wave.js fences the gate machinery (probeBrief, probe, parseHeldCluster,
# parseTargetRef, parseVoteShow, gateSuccess, runGate) in TEST-BEGIN/TEST-END
# `gate-vote` markers. This suite extracts that region, prepends the
# classifier-retry region (reasonText and the block regexes the probe retry
# reads) and stub `agent`/`parallel`/`log`/`seatBrief`/`resolveSeat`/
# `labelsOf`/`policy` globals, scripts the agent per spawn label, and asserts
# on the result runGate returns. park-signals and chain-dead are extracted too
# so the suite can prove the success result does not trip either predicate.
#
# WHAT THIS SUITE CANNOT SEE: the harness's own per-agent failure accounting
# in the completion notification (agents_error and the "[label] failed: ..."
# lines) is harness behavior, out of wave.js's hands — what wave.js controls,
# and what this suite pins, is the wave's returned result for the step: the
# surface the conductor reads the gate's outcome from.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-vote-retry-report.XXXXXX") || fatal "mktemp failed"
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
    ' "$WAVE"
}

extract classifier-retry > "${WORK}/classifier.js" || fatal "bad or missing TEST markers for classifier-retry"
extract park-signals     > "${WORK}/park.js"       || fatal "bad or missing TEST markers for park-signals"
extract gate-vote        > "${WORK}/gate.js"       || fatal "bad or missing TEST markers for gate-vote"
# chain-dead nests inside stage-ladder; extract it on its own.
extract chain-dead       > "${WORK}/chain.js"      || fatal "bad or missing TEST markers for chain-dead"
[ -s "${WORK}/gate.js" ] || fatal "extracted gate-vote region is empty"
grep -q 'runGate'     "${WORK}/gate.js" || fatal "gate-vote region does not contain runGate"
grep -q 'gateSuccess' "${WORK}/gate.js" || fatal "gate-vote region does not contain gateSuccess"

{
    # --- stub workflow globals the gate region reaches for ---
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
const policy = {}
const labelsOf = () => []
const resolveSeat = (seat) => ({ seat, variant: 'std', model: 'stub-model', effort: 'low' })
const seatBrief = () => 'seat brief (stub)'
// The scripted agent: SCRIPT maps a spawn label to one response or an array
// of responses consumed in order — {text: ...} resolves, {reject: ...}
// rejects with an Error carrying that message. An unlisted label resolves ''.
let SCRIPT = {}
let CALLS = []
const agent = (brief, opts) => {
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    const item = Array.isArray(entry) ? entry.shift() : entry
    if (item === undefined) return Promise.resolve('')
    if (item.reject !== undefined) return Promise.reject(new Error(item.reject))
    return Promise.resolve(item.text)
}
JS
    cat "${WORK}/classifier.js"
    cat "${WORK}/park.js"
    cat "${WORK}/chain.js"
    cat "${WORK}/gate.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const ROW = {
    step: 'STEP-2493', kind: 'vote', issue: 'DOT-1', run: 'RUN-52',
    instance: 'gate@1', stage: 1,
    voters: ['judge-architecture', 'judge-security', 'judge-correctness'],
}
const APPROVED =
    '{"ok":true,"data":{"id":"DKT-V260","status":"approved","final_outcome":"approved",' +
    '"weighted_score":1.0,"votes":[{"voter_name":"judge-architecture","verdict":"approve"},' +
    '{"voter_name":"judge-security","verdict":"approve"},' +
    '{"voter_name":"judge-correctness","verdict":"approve"}]}}'
const REJECTED =
    '{"ok":true,"data":{"id":"DKT-V260","status":"rejected","final_outcome":"rejected",' +
    '"weighted_score":0.0,"votes":[{"voter_name":"judge-architecture","verdict":"reject"}]}}'
const RECORD_TWO =
    '{"ok":true,"data":{"id":"DKT-V260","status":"open","votes":[' +
    '{"voter_name":"judge-architecture"},{"voter_name":"judge-correctness"}]}}'
const RECORD_ALL =
    '{"ok":true,"data":{"id":"DKT-V260","status":"open","votes":[' +
    '{"voter_name":"judge-architecture"},{"voter_name":"judge-security"},' +
    '{"voter_name":"judge-correctness"}]}}'
const SHOW_READY = '{"ok":true,"data":{"id":"STEP-2493","status":"ready","proposal":"DKT-V260"}}'
const SHOW_DONE  = '{"ok":true,"data":{"id":"STEP-2493","status":"done","proposal":"DKT-V260"}}'
const API_ERR = 'API Error: Connection lost mid-response'

const run = async (script) => {
    SCRIPT = script
    CALLS = []
    LOG.length = 0
    return runGate(ROW, 'stage 1 (1 row)')
}
const calls = (label) => CALLS.filter((c) => c === label).length

// ---- A: the DOT-744 case. One seat's first spawn dies at the agent level
// and its re-spawn casts; the tally probe dies once and its identical
// resubmission reads APPROVED. The gate SUCCEEDS: the result must carry the
// accounting and the absorbed errors as notes — and nothing failure-shaped.
const A = await run({
    'STEP-2493 · gate:show':    { text: SHOW_READY },
    'STEP-2493 · gate:target':  { text: '' },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { reject: API_ERR },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:record':  { text: RECORD_TWO },
    'STEP-2493 · seat:judge-security (retry)': { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: SHOW_DONE },
    'STEP-2493 · gate:tally':   [{ reject: API_ERR }, { text: APPROVED }],
})
ok(A.status === 'gate-passed', 'A: tally succeeded -> status is gate-passed')
ok(A.spawn_accounting === '10 spawns for 3 seats, 2 retries',
    `A: spawn/seat/retry accounting is explicit (got ${JSON.stringify(A.spawn_accounting)})`)
ok(Array.isArray(A.notes) && A.notes.length === 2,
    `A: both absorbed errors ride the success result as notes (got ${JSON.stringify(A.notes)})`)
ok((A.notes || []).every((n) => n.includes('NOT a failure') && n.includes('SUCCEEDED')),
    'A: every note names the tally success and disclaims failure')
ok((A.notes || []).some((n) => n.includes('[STEP-2493 · gate:tally]') && n.includes(API_ERR)),
    'A: the RUN-52 tally-probe error is a note, attributed to its spawn label')
ok((A.notes || []).some((n) => n.includes('[STEP-2493 · seat:judge-security]')),
    'A: the dead seat spawn is a note, attributed to its seat label')
ok(A.failures === undefined, 'A: no failures field on the success result')
ok(!/fail/.test(A.status), 'A: nothing failure-shaped in the status')
ok(calls('STEP-2493 · gate:tally') === 2, 'A: the tally probe was resubmitted exactly once')
ok(calls('STEP-2493 · seat:judge-security (retry)') === 1, 'A: the missing seat was re-spawned once')
ok(chainDead(A) === false, 'A: the success result does not kill the issue chain')
ok(runParked(A) === false, 'A: the success result does not park the run')

// ---- B: the SAME noise, but the tally REJECTS. The fix must not soften a
// real failure: no notes, no accounting cushion — the rejected result is
// exactly what it was before DOT-744.
const B = await run({
    'STEP-2493 · gate:show':    { text: SHOW_READY },
    'STEP-2493 · gate:target':  { text: '' },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { reject: API_ERR },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:record':  { text: RECORD_TWO },
    'STEP-2493 · seat:judge-security (retry)': { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: SHOW_DONE },
    'STEP-2493 · gate:tally':   { text: REJECTED },
})
ok(B.status === 'gate-rejected', 'B: rejected tally -> status is gate-rejected')
ok(B.notes === undefined, 'B: a failing gate gets NO absorbed-error notes')
ok(B.spawn_accounting === undefined, 'B: a failing gate gets NO accounting attachment')
ok(chainDead(B) === true, 'B: the rejection still kills the issue chain')

// ---- C: gate already decided when the wave arrives (early path). Success
// still reports accounting — probes only, zero seats.
const C = await run({
    'STEP-2493 · gate:show':  { text: SHOW_DONE },
    'STEP-2493 · gate:tally': { text: APPROVED },
})
ok(C.status === 'gate-passed', 'C: already-decided approved gate is gate-passed')
ok(C.spawn_accounting === '2 spawns for 0 seats, 0 retries',
    `C: early path reports its probe spawns (got ${JSON.stringify(C.spawn_accounting)})`)
ok(C.notes === undefined, 'C: no noise, no notes')

// ---- D: a NON-transient classifier block on the tally probe is
// deterministic on identical bytes — never resubmitted (DOT-558 doctrine),
// but still noted on the success result.
const D = await run({
    'STEP-2493 · gate:show':    { text: SHOW_READY },
    'STEP-2493 · gate:target':  { text: '' },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:record':  { text: RECORD_ALL },
    'STEP-2493 · gate:outcome': { text: SHOW_DONE },
    'STEP-2493 · gate:tally':   { reject: '[STEP-2493 · gate:tally] blocked by safety classifier: the brief was refused on content' },
})
ok(calls('STEP-2493 · gate:tally') === 1, 'D: a content classifier block is NOT resubmitted')
ok(D.status === 'gate-passed', 'D: unknown tally on a done step still falls through as before')
ok(D.spawn_accounting === '8 spawns for 3 seats, 0 retries',
    `D: no retry counted for the unretried block (got ${JSON.stringify(D.spawn_accounting)})`)
ok(Array.isArray(D.notes) && D.notes.length === 1 && D.notes[0].includes('blocked by safety classifier'),
    'D: the block is still noted on the success result')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
