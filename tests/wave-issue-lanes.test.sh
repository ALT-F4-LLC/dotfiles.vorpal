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
# while the certified count is in flight, and releases them in admission
# order (writers lowest stage first, every other row deepest stage first,
# then submission order — (8) pins the deepest-first half); (4) a park is
# still run-wide: nothing launches after it, and a row
# waiting for admission settles not-launched-run-parked without a spawn; (5)
# chain death stays per issue, an issue-less row rides its own lane, vote and
# action rows neither reserve nor wait; (6) the return still carries one entry
# per manifest row, in manifest order; (9) the writer ladder budget: a
# writer queued behind three or more uncertified other-lane writer cohorts
# settles not-launched-writer-budget, its lane's later rows read as deferred,
# and a lane's own writer chain never counts against it.
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

extract configuration > "${WORK}/configuration.js" || fatal "bad or missing TEST markers for configuration"
extract park-signals       > "${WORK}/park.js"     || fatal "bad or missing TEST markers for park-signals"
extract target-envelope    > "${WORK}/envelope.js" || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js" || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder       > "${WORK}/ladder.js"   || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ladder.js" ] || fatal "extracted stage-ladder region is empty"
grep -q 'runLane' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain runLane"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
let rows = []
let input = {}
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
// Matches probe()'s unconditional fail-open here: no fixture in this suite
// exercises a terminal pre-claim status, only that the row still spawns.
const stepShow = (step) => {
    PROBED.push(step)
    return Promise.resolve(null)
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
    input = {}
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

// ---- (4) a park is LANE-wide; only R1's refusal is run-wide ------------
// A's writer parks ITS ISSUE on settle (the mandated tail): A's later stage
// never launches, but B's writer, waiting behind it as an uncertified pair,
// launches the moment A's settles, and C's lane runs to the end. The engine
// parks the issue (R2b) and keeps the run active for everyone else.
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
ok(!logged('run parked mid-wave') && logged('A-0: parked waiting-human'),
    'park: a lane park is logged as the issue waiting, never as a run park')
ok(!SPAWNED.includes('A-1'), "park: the parking issue's own next stage never launches")
ok(!SPAWNED.includes('B-1') && logged('B-1: waiting — writer A-0'),
    "park: B's writer still waits — behind C's in-flight uncertified writer, not behind the park")
await finish('C-0')
out = await run
ok(SPAWNED.includes('B-1') && logged('B-1: released — launching'),
    "park: B's writer launches once the last uncertified writer settles — the park holds only A")
ok(statusOf(out, 'C-0') === 'returned' && statusOf(out, 'C-1') === 'returned',
    "park: C's lane runs to the end")
ok(statusOf(out, 'A-1') === 'skipped-chain-dead',
    "park: A's later row settles skipped-chain-dead, a deferral")
ok(statusOf(out, 'B-1') === 'returned' && statusOf(out, 'B-2') === 'returned',
    "park: B's chain completes behind the released waiter")
ok(!out.some((r) => r.status === 'not-launched-run-parked'),
    'park: nothing settles not-launched-run-parked on a lane park')

// The run-wide park is R1's refusal: an agent that launched INTO a parked run
// reports a CONFLICT naming it, and after that nothing launches — not the
// waiter, not any lane's next stage.
const INTO_PARK = ['A-0', 'CONFLICT', '{"ok":false,"error":"run is not active"}'].join('\n')
run = start(PARK(), {
    hold: ['A-0', 'C-0'],
    results: { 'A-0': { step: 'A-0', status: 'returned', text: INTO_PARK } },
})
await settle()
await finish('A-0')
ok(logged('run parked mid-wave'), 'run park: the park is observed the moment the refusal settles')
ok(!SPAWNED.includes('B-1') && !SPAWNED.includes('A-1'),
    'run park: nothing launches after it — not the waiter, not the next stage')
await finish('C-0')
out = await run
ok(statusOf(out, 'C-0') === 'returned', "run park: C's in-flight row still finishes")
ok(statusOf(out, 'B-1') === 'not-launched-run-parked' &&
   statusOf(out, 'B-2') === 'not-launched-run-parked' &&
   statusOf(out, 'A-1') === 'not-launched-run-parked' &&
   statusOf(out, 'C-1') === 'not-launched-run-parked',
    'run park: every unlaunched row settles not-launched-run-parked, including the flushed waiter')
ok(SPAWNED.length === 2, 'run park: exactly the two pre-park spawns happened')

// A lane park while ANOTHER lane's stage-0 row is still running: that lane
// starts its stage 1 as usual once its own row returns.
run = start(RUN67(), {
    hold: ['C-0'],
    results: { 'A-0': { step: 'A-0', status: 'returned', text: 'A-0 recorded (waiting-human)' } },
})
await settle()
ok(!SPAWNED.includes('A-1a') && SPAWNED.includes('B-0'),
    "park: the parking issue's own later stage never launches; stage-mates still ran")
await finish('C-0')
out = await run
ok(statusOf(out, 'C-1a') === 'returned' && SPAWNED.includes('C-1a'),
    "park: a lane whose stage-0 row was still running starts stage 1 after another lane's park")

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

// ---- (7) DOT-1603: a row already queued for a harness execution slot when
// the wave observes a park does not launch into it. Seventeen independent
// read-class issues, one stage-0 row each — no class-headroom or writer-
// coupling rule ever fires here, so the ONLY thing that can hold the
// seventeenth back is the harness's own concurrency cap this admission rule
// now bounds. All seventeen are HELD (the stub spawn stands in for a row
// admitted but still queued for a harness slot — the exact state RUN-88's
// judges were in when the park landed), so the suite can watch the cap hold
// the last one back, then watch a park settle it without ever spawning.
const CAPPED = () => Array.from({ length: 17 }, (_, i) =>
    ex(`R${i}-0`, `CAP-${i}`, 0, 'research'))
const capRows = CAPPED()
const capHeld = capRows.map((r) => r.step)
const CAP_INTO_PARK = [capHeld[0], 'CONFLICT', '{"ok":false,"error":"run is not active"}'].join('\n')
run = start(capRows, {
    hold: capHeld,
    results: { [capHeld[0]]: { step: capHeld[0], status: 'returned', text: CAP_INTO_PARK } },
})
await settle()
ok(capHeld.slice(0, 16).every((s) => SPAWNED.includes(s)),
    'DOT-1603: sixteen rows reach the harness (the documented min(16, CPUs-2) ceiling)')
ok(!SPAWNED.includes(capHeld[16]),
    'DOT-1603: the seventeenth row does not launch — it queues behind the cap')
ok(logged('waiting — 16 row(s) in flight — the harness runs at most 16 agents concurrently'),
    'DOT-1603: the wait names the harness cap, not a class or writer rule')
// The held row that returns is one of the sixteen already in the harness;
// its refusal is the run-wide park signal, observed while the seventeenth is
// still queued behind the cap — the exact RUN-88 shape.
await finish(capHeld[0])
ok(logged('run parked mid-wave'), 'DOT-1603: the park is observed the moment the refusal settles')
ok(!SPAWNED.includes(capHeld[16]),
    'DOT-1603: the queued row still has not spawned once the park lands')
// Drain the rest of the in-flight sixteen so the ladder can settle.
for (const s of capHeld.slice(1, 16)) await finish(s)
const capOut = await run
ok(statusOf(capOut, capHeld[16]) === 'not-launched-run-parked',
    'DOT-1603: the queued row settles not-launched-run-parked — it never spawned into the park')
ok(!SPAWNED.includes(capHeld[16]),
    'DOT-1603: and it is confirmed absent from SPAWNED, not merely reported that way')
ok(SPAWNED.length === 16, 'DOT-1603: exactly the sixteen pre-park spawns happened, never a seventeenth')

// ---- (8) deepest-stage-first admission for rows that hold no tree --------
// Two judges at stage 0 hold the certified judge count (2). Lane D's judge
// at stage 1 and lane C's judge at stage 2 both queue behind them, C's
// submitted later. When one slot frees, the DEEPER row launches first: a
// chain finishes instead of every chain advancing one rung.
const DEEP = () => [
    ex('A-0', 'HRN-1', 0, 'judge'),
    ex('B-0', 'HRN-2', 0, 'judge'),
    ex('D-0', 'HRN-4', 0, 'synthesize-findings'),
    ex('D-1', 'HRN-4', 1, 'judge'),
    ex('C-0', 'HRN-3', 0, 'synthesize-findings'),
    ex('C-1', 'HRN-3', 1, 'synthesize-findings'),
    ex('C-2', 'HRN-3', 2, 'judge'),
]
run = start(DEEP(), { hold: ['A-0', 'B-0', 'C-2'] })
await settle()
ok(SPAWNED.includes('D-0') && SPAWNED.includes('C-0') && SPAWNED.includes('C-1') &&
   !SPAWNED.includes('D-1') && !SPAWNED.includes('C-2'),
    'deepest-first: both waiting judges hold behind the certified judge count')
await finish('A-0')
ok(SPAWNED.includes('C-2') && !SPAWNED.includes('D-1'),
    'deepest-first: one freed slot admits the stage-2 row ahead of the earlier-submitted stage-1 row')
await finish('B-0')
ok(SPAWNED.includes('D-1'), 'deepest-first: the next freed slot admits the stage-1 row')
await finish('C-2')
const deepOut = await run
ok(statusOf(deepOut, 'D-1') === 'returned' && statusOf(deepOut, 'C-2') === 'returned',
    'deepest-first: both rows settle returned')

// ---- (9) writer ladder budget: the fourth uncertified writer cohort waits
// for the next dispatch. Four lanes hold one writer each at stages 0..3 and
// none are co-staged, so they serialize; lane HRN-14's judge at stage 4
// rides behind its writer. Lane HRN-15 has writers at stages 0 and 3 of its
// OWN: its stage-0 writer is co-staged with HRN-11's (certified), so the
// uncertified other-lane writers below its stage-3 writer sit at stages 1
// and 2 only — depth 2 — and it launches.
const LADDER = () => [
    ex('W1-0', 'HRN-11', 0, 'write'),
    ex('W2-1', 'HRN-12', 1, 'write'),
    ex('W3-2', 'HRN-13', 2, 'write'),
    ex('W4-3', 'HRN-14', 3, 'write'),
    ex('W4-4', 'HRN-14', 4, 'judge'),
    ex('S-0', 'HRN-15', 0, 'write'),
    ex('S-3', 'HRN-15', 3, 'write'),
]
run = start(LADDER())
const ladderOut = await run
ok(SPAWNED.includes('W1-0') && SPAWNED.includes('W2-1') && SPAWNED.includes('W3-2'),
    'writer budget: the first three uncertified writer cohorts launch')
ok(!SPAWNED.includes('W4-3') && statusOf(ladderOut, 'W4-3') === 'not-launched-writer-budget',
    'writer budget: the fourth cohort is not launched and settles not-launched-writer-budget')
ok(!SPAWNED.includes('W4-4') && statusOf(ladderOut, 'W4-4') === 'skipped-chain-dead',
    "writer budget: the deferred lane's later row is skipped, not launched")
ok(logged('W4-4: later stages deferred') && !logged('chain died'),
    'writer budget: the skip reads as deferred, never as died')
ok(logged('writer ladder budget'), 'writer budget: the log names the rule')
ok(SPAWNED.includes('S-3') && statusOf(ladderOut, 'S-3') === 'returned',
    "writer budget: a lane's own writer chain does not count against it")
ok(ladderOut.length === 7, 'writer budget: one entry per manifest row')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
