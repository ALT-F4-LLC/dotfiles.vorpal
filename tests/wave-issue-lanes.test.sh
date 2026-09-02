#!/bin/bash

# Behavior suite for wave.js's per-issue stage lanes (DOT-1031).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The stage ladder used to be ONE global barrier: stage k+1
# of every issue waited for stage k of every issue, so an issue's judges idled
# behind another issue's slower implement — measured on one run as 11m47s
# between an implement recording and its own judges being claimed, most of it
# waiting on two unrelated implements and a park. The engine's `stage` labels
# order SAME-ISSUE work (after/loop/gate edges; a cross-issue `depends_on`
# never enters a manifest) and ALSO pack cross-issue cohorts (class headroom,
# scope disjointness) into the same numbers. The ladder now runs one lane per
# issue and honors the cohort packing from what the manifest itself certifies:
# the largest same-stage count of a class bounds that class in flight, and
# two writers co-staged by the engine prove their issues' scopes disjoint.
#
# WHAT IS PINNED HERE. (1) three independent chains: issue B's stage-1 rows
# spawn the moment B's stage-0 row returns, while issue A's stage-0 row is
# still running; (2) cross-issue coupling — writers the engine never
# co-staged keep the global stage order between them, logged as such, while a
# reader-only issue never waits; (3) the class bound holds rows back only
# while the certified count is in flight, and releases them lowest-stage
# first; (4) a park is still run-wide: nothing launches after it, and a row
# waiting for admission settles not-launched-run-parked without a spawn; (5)
# chain death stays per issue, an issue-less row rides its own lane, vote and
# action rows neither reserve nor wait; (6) the return still carries one entry
# per manifest row, in manifest order.
#
# HOW. Like tests/wave-chain-dead-ladder.test.sh it wraps the extracted ladder
# region in an async function with stub spawn/runGate/probe/parallel/log
# globals. The spawn stub can HOLD a step open until the scenario calls
# finish(step), which is how the suite observes what launched while another
# lane's row was still in flight.
#
# WHAT THIS SUITE CANNOT SEE: the real spawn(), the engine's own claim-time
# R4/R5 checks (the authority the admission rule defers to), and the corpus
# convention the scope rule rests on — that `class = "write"` steps hold the
# tree and every other executor step declares `holds_tree = false` — which is
# asserted nowhere here.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-issue-lanes.XXXXXX") || fatal "mktemp failed"
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

extract park-signals       > "${WORK}/park.js"     || fatal "bad or missing TEST markers for park-signals"
extract target-envelope    > "${WORK}/envelope.js" || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js" || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder       > "${WORK}/ladder.js"   || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ladder.js" ] || fatal "extracted stage-ladder region is empty"
grep -q 'runLane' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain runLane"

{
    cat <<'JS'
let rows = []
let input = { policyText: '' }
const policyVersion = 16
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
// Every row the ladder launched, in launch order; gate rows land in GATES.
let SPAWNED = []
let GATES = []
let RESULTS = new Map()
const settleFor = (row) => {
    const r = RESULTS.get(row.step)
    return typeof r === 'function' ? r(row) : r
}
// Steps in HOLD stay open after spawning until finish(step) is called, so a
// scenario can look at what ELSE launched while they were in flight.
let HOLD = new Set()
let OPEN = new Map()
const spawn = (row) => {
    SPAWNED.push(row.step)
    const canned = settleFor(row) === undefined
        ? { step: row.step, status: 'returned', text: `${row.step} recorded (done)` }
        : settleFor(row)
    if (!HOLD.has(row.step)) return Promise.resolve(canned)
    return new Promise((resolve) => OPEN.set(row.step, () => resolve(canned)))
}
const runGate = (row) => {
    GATES.push(row.step)
    return Promise.resolve(settleFor(row) === undefined
        ? { step: row.step, status: 'gate-passed', text: '{"status":"done"}' }
        : settleFor(row))
}
let PROBED = []
const probe = (_cmd, _label, _phase, step) => {
    PROBED.push(step)
    return Promise.resolve('')
}

const ladder = async () => {
JS
    cat "${WORK}/park.js"
    cat "${WORK}/envelope.js"
    cat "${WORK}/ancestry.js"
    cat "${WORK}/ladder.js"
    printf '}\n'
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
// Let every pending microtask chain run to rest before looking.
const settle = () => new Promise((r) => setTimeout(r, 0))
const finish = async (step) => {
    const r = OPEN.get(step)
    if (!r) throw new Error(`finish(${step}): not spawned yet, or not held`)
    OPEN.delete(step)
    r()
    await settle()
}
const start = (theRows, opts) => {
    rows = theRows
    input = { policyText: '' }
    SPAWNED = []; GATES = []; PROBED = []; LOG.length = 0
    RESULTS = new Map(Object.entries((opts && opts.results) || {}))
    HOLD = new Set((opts && opts.hold) || [])
    OPEN = new Map()
    return ladder()
}
const ex = (step, issue, stage, cls, extra) => Object.assign(
    { step, issue, stage, kind: 'executor', executor: cls === 'write' ? 'implement' : cls, class: cls },
    extra || {})
const vote = (step, issue, stage) => ({ step, issue, stage, kind: 'vote', voters: ['judge-correctness'] })
const act = (step, issue, stage) => ({ step, issue, stage, kind: 'action' })
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status
const before = (a, b) => SPAWNED.includes(a) && SPAWNED.includes(b) && SPAWNED.indexOf(a) < SPAWNED.indexOf(b)
const logged = (frag) => LOG.some((l) => l.includes(frag))

// ---- (1) AC: three independent chains — the RUN-67 shape ----------------
// Three issues, each implement -> judges -> gate -> synthesize -> verify,
// stages 0..4, every pair of implements co-staged at stage 0 (so the engine
// proved every issue pair's scopes disjoint). A's and C's implements are
// HELD; B's returns at once.
const chain = (p, issue) => [
    ex(`${p}-0`, issue, 0, 'write'),
    ex(`${p}-1a`, issue, 1, 'judge-correctness'),
    ex(`${p}-1b`, issue, 1, 'judge-testing'),
    vote(`${p}-2`, issue, 2),
    ex(`${p}-3`, issue, 3, 'synthesize-findings'),
    ex(`${p}-4`, issue, 4, 'verify-ac'),
]
const RUN67 = () => [...chain('A', 'AGT-602'), ...chain('B', 'AGT-840'), ...chain('C', 'AGT-890')]

let run = start(RUN67(), { hold: ['A-0', 'C-0'] })
await settle()
ok(SPAWNED.includes('A-0') && SPAWNED.includes('B-0') && SPAWNED.includes('C-0'),
    'AC1: every stage-0 implement spawns at once')
ok(SPAWNED.includes('B-1a') && SPAWNED.includes('B-1b'),
    "AC1: issue B's judges spawn while A's and C's implements are still in flight")
ok(GATES.includes('B-2') && SPAWNED.includes('B-3') && SPAWNED.includes('B-4'),
    "AC1: and B's whole chain (gate, synthesize, verify) runs to the end on its own")
ok(!SPAWNED.includes('A-1a') && !SPAWNED.includes('C-1a'),
    "AC1: A's and C's judges wait for THEIR OWN implements, nothing else")
ok(logged('lanes run concurrently'), 'AC1: the wave logs that lanes run concurrently')
ok(!logged('cross-issue coupling'), 'AC1: no coupling is logged — every implement pair was co-staged')
await finish('A-0')
ok(SPAWNED.includes('A-1a') && SPAWNED.includes('A-4') && !SPAWNED.includes('C-1a'),
    "AC1: A's chain runs to the end once A's implement returns; C still waits on its own")
await finish('C-0')
let out = await run
ok(out.length === 18 && out.every((r, i) => r.step === RUN67()[i].step),
    'AC1: the return carries one entry per manifest row, in manifest order')
ok(out.every((r) => r.status === 'returned' || r.status === 'gate-passed'),
    'AC1: every row settled returned/gate-passed')

// ---- (2) AC: cross-issue coupling -> the engine's stage order, logged --
// Issue B's implement was rationed to stage 1 behind A's (the engine never
// co-staged writers of A and B: their scopes are unproven disjoint). A's own
// fix at stage 2 is a writer too. Issue C is reader-only (research/report)
// and shares a stage with nobody's writers.
const COUPLED = () => [
    ex('A-0', 'AGT-602', 0, 'write'),
    ex('A-1', 'AGT-602', 1, 'judge-correctness'),
    ex('A-2', 'AGT-602', 2, 'write', { executor: 'fix' }),
    ex('B-1', 'AGT-840', 1, 'write', { status: 'staged' }),
    ex('B-2', 'AGT-840', 2, 'judge-correctness'),
    ex('C-0', 'AGT-890', 0, 'research'),
    ex('C-1', 'AGT-890', 1, 'investigate'),
]
run = start(COUPLED(), { hold: ['A-0', 'B-1'] })
await settle()
ok(logged('cross-issue coupling') && logged('AGT-602/AGT-840'),
    'AC2: the wave logs the uncertified writer pair up front')
ok(SPAWNED.includes('A-0') && !SPAWNED.includes('B-1'),
    "AC2: B's writer does not launch while A's uncertified writer is in flight")
ok(LOG.some((l) => l.startsWith('B-1: waiting — writer A-0')),
    "AC2: and the log names the writer it is holding behind")
ok(SPAWNED.includes('C-0') && SPAWNED.includes('C-1'),
    'AC2: the reader-only issue runs its whole chain regardless')
await finish('A-0')
ok(SPAWNED.includes('B-1') && logged('B-1: released — launching'),
    "AC2: B's writer launches once A's writer returns, and says so")
ok(SPAWNED.includes('A-1') && !SPAWNED.includes('A-2'),
    "AC2: A's judge runs, but A's fix (a writer) now waits behind B's in-flight writer — symmetric")
await finish('B-1')
out = await run
ok(SPAWNED.includes('A-2') && SPAWNED.includes('B-2'),
    "AC2: both remaining rows launch once the writer settles")
ok(out.length === 7 && out.every((r) => r.status === 'returned'),
    'AC2: every row still settles returned — coupling delays, never kills')

// ---- (3) class headroom: the certified count bounds rows in flight ------
// Two judges per stage is the most the manifest ever shows for class
// `judge`, so two is the bound. A's judges are HELD at stage 1; B reaches
// its stage-2 judges first and must wait for A's to drain, lowest-seq first.
const HEADROOM = () => [
    ex('A-0', 'HRN-1', 0, 'write'),
    ex('A-1a', 'HRN-1', 1, 'judge'),
    ex('A-1b', 'HRN-1', 1, 'judge'),
    ex('B-0', 'HRN-2', 0, 'write'),
    ex('B-1', 'HRN-2', 1, 'synthesize-findings'),
    ex('B-2a', 'HRN-2', 2, 'judge'),
    ex('B-2b', 'HRN-2', 2, 'judge'),
]
// B-2a is held too, so that freeing ONE slot can be seen to admit ONE row.
run = start(HEADROOM(), { hold: ['A-1a', 'A-1b', 'B-2a'] })
await settle()
ok(logged('judge≤2'), 'headroom: the manifest certifies two concurrent judge rows')
ok(SPAWNED.includes('A-1a') && SPAWNED.includes('A-1b') && SPAWNED.includes('B-1') &&
   !SPAWNED.includes('B-2a') && !SPAWNED.includes('B-2b'),
    "headroom: B's judges wait while A's two judges hold the certified count")
ok(logged('2 row(s) of class judge in flight — the manifest certifies at most 2 concurrent'),
    'headroom: the wait names the class and the bound')
await finish('A-1a')
ok(SPAWNED.includes('B-2a') && !SPAWNED.includes('B-2b'),
    'headroom: one slot frees one row — B-2a first, B-2b still waits')
await finish('A-1b')
ok(SPAWNED.includes('B-2b'), 'headroom: the second slot frees the second row')
await finish('B-2a')
out = await run
ok(out.every((r) => r.status === 'returned'), 'headroom: everything settles returned')

// ---- (4) a park is still run-wide -------------------------------------
// A's writer parks the run on settle; B's writer is waiting behind it
// (uncertified pair); C's writer is in flight in its own lane. Nothing may
// launch after the park: the waiter settles without a spawn, C's in-flight
// row finishes, and every later row is not-launched-run-parked.
const PARK = () => [
    ex('A-0', 'AGT-602', 0, 'write'),
    ex('A-1', 'AGT-602', 1, 'judge-correctness'),
    ex('B-1', 'AGT-840', 1, 'write', { status: 'staged' }),
    ex('B-2', 'AGT-840', 2, 'judge-correctness'),
    ex('C-0', 'AGT-890', 0, 'write'),
    ex('C-1', 'AGT-890', 1, 'judge-correctness'),
]
run = start(PARK(), {
    hold: ['A-0', 'C-0'],
    results: { 'A-0': { step: 'A-0', status: 'returned', text: 'Did it.\n\nA-0 recorded (waiting-human)' } },
})
await settle()
ok(SPAWNED.includes('A-0') && SPAWNED.includes('C-0') && !SPAWNED.includes('B-1'),
    "park: before the park, B's writer waits behind A's")
await finish('A-0')
ok(logged('run parked mid-wave'), 'park: the park is observed the moment the parking row settles')
ok(!SPAWNED.includes('B-1') && !SPAWNED.includes('A-1'),
    'park: nothing launches after it — not the waiter, not the next stage')
await finish('C-0')
out = await run
ok(statusOf(out, 'C-0') === 'returned', "park: C's in-flight row still finishes")
ok(statusOf(out, 'B-1') === 'not-launched-run-parked' &&
   statusOf(out, 'B-2') === 'not-launched-run-parked' &&
   statusOf(out, 'A-1') === 'not-launched-run-parked' &&
   statusOf(out, 'C-1') === 'not-launched-run-parked',
    'park: every unlaunched row settles not-launched-run-parked, including the flushed waiter')
ok(SPAWNED.length === 2, 'park: exactly the two pre-park spawns happened')

// The same shape when the park lands while ANOTHER lane's stage-0 row is
// still running: that lane's next stage sees the flag and never launches.
run = start(RUN67(), {
    hold: ['C-0'],
    results: { 'A-0': { step: 'A-0', status: 'returned', text: 'A-0 recorded (waiting-human)' } },
})
await settle()
ok(!SPAWNED.includes('A-1a') && SPAWNED.includes('B-0'),
    "park: the parking issue's own later stage never launches; stage-mates still ran")
await finish('C-0')
out = await run
ok(statusOf(out, 'C-1a') === 'not-launched-run-parked' && !SPAWNED.includes('C-1a'),
    "park: a lane whose stage-0 row was still running does not start stage 1 after the park")

// ---- (5) per-lane chain death, issue-less rows, vote/action rows --------
const MIXED = () => [
    ex('A-0', 'HRN-30', 0, 'write'),
    ex('A-1', 'HRN-30', 1, 'judge-correctness'),
    ex('B-0', 'HRN-99', 0, 'write'),
    act('B-1', 'HRN-99', 1),
    vote('B-2', 'HRN-99', 2),
    ex('B-3', 'HRN-99', 3, 'verify-ac'),
    { step: 'X-0', stage: 0, kind: 'executor', executor: 'research', class: 'research' },
]
run = start(MIXED(), {
    hold: ['B-0'],
    results: { 'A-0': { step: 'A-0', status: 'spawn-failed', text: null } },
})
await settle()
ok(!SPAWNED.includes('A-1'), "mixed: a spawn-failed stage-0 row kills only its own lane's later rows")
ok(SPAWNED.includes('X-0'), 'mixed: an issue-less row rides a lane of its own and launches')
await finish('B-0')
out = await run
ok(statusOf(out, 'A-1') === 'skipped-chain-dead', 'mixed: the dead lane\'s row reads skipped-chain-dead')
ok(statusOf(out, 'B-1') === 'engine-run' && GATES.includes('B-2') && statusOf(out, 'B-3') === 'returned',
    "mixed: the other lane's action, vote and verify rows all settle in order")
ok(before('X-0', 'B-3'), 'mixed: launch order still ascends the stages')
ok(out.length === 7 && out.every((r, i) => r.step === MIXED()[i].step),
    'mixed: the return carries one entry per manifest row, in manifest order')

// ---- (6) a one-lane manifest is the old ladder, byte for byte in effect --
run = start(chain('A', 'AGT-602'), { hold: ['A-0'] })
await settle()
ok(SPAWNED.length === 1 && !logged('lanes run concurrently'),
    'single lane: stage 1 waits on stage 0, and no concurrency line is logged')
await finish('A-0')
out = await run
ok(out.every((r) => r.status === 'returned' || r.status === 'gate-passed') &&
   before('A-1a', 'A-3') && before('A-3', 'A-4'),
    'single lane: the chain ladders in stage order to the end')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
