#!/bin/bash

# Behavior suite for wave.js's per-unit LAUNCHES — one dispatch split into
# one wave launch per lane unit, each launch holding only its own rows.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The Workflow tool caps one invocation at 16 concurrent
# agents and 1000 over its lifetime, and a nested workflow() shares both with
# its parent; separate top-level launches share neither, and 20 of them ran
# concurrently with none refused. So the conductor launches one wave per lane
# unit and hands each only its own rows plus `unit: {index, of, classCap}`
# from lane_units.py (whose own suite, docket-run-lane-units, pins the
# partition). What has to hold here: a launch runs every row it holds and
# returns one entry per row, never another launch's status; writer lanes the
# engine never co-staged, welded into one launch, still serialize inside it;
# classCap, the launch's share of the manifest-wide class headroom, overrides
# the narrower count its own rows show; and the retired `shard` arg and a
# malformed `unit` refuse to route.
#
# HOW. Like tests/wave-issue-lanes.test.sh it wraps the extracted ladder
# region in an async function with stub spawn/runGate/probe/parallel/log
# globals; `input.unit` is set per scenario.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-launch-unit.XXXXXX") || fatal "mktemp failed"
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

extract configuration      > "${WORK}/configuration.js" || fatal "bad or missing TEST markers for configuration"
extract park-signals       > "${WORK}/park.js"          || fatal "bad or missing TEST markers for park-signals"
extract target-envelope    > "${WORK}/envelope.js"      || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js"      || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder       > "${WORK}/ladder.js"        || fatal "bad or missing TEST markers for stage-ladder"
grep -q 'launchUnit' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain launchUnit"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
let rows = []
let input = {}
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
// budget: no target set by default (matches an ordinary turn with no
// "+500k"-style directive) — budget.remaining() is Infinity, so wave.js's
// token-budget check never fires unless a case below overrides it.
const budget = { total: null, spent: () => 0, remaining: () => Infinity }
let SPAWNED = []
let GATES = []
let RESULTS = new Map()
const settleFor = (row) => {
    const r = RESULTS.get(row.step)
    return typeof r === 'function' ? r(row) : r
}
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
    input = Object.assign({}, opts && opts.unit !== undefined ? { unit: opts.unit } : {}, opts && opts.shard !== undefined ? { shard: opts.shard } : {})
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
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status
const logged = (frag) => LOG.some((l) => l.includes(frag))

// Three certified-disjoint issues (every implement co-staged at stage 0),
// each implement -> judges -> gate -> synthesize -> verify.
const chain = (p, issue) => [
    ex(`${p}-0`, issue, 0, 'write'),
    ex(`${p}-1a`, issue, 1, 'judge-correctness'),
    ex(`${p}-1b`, issue, 1, 'judge-testing'),
    vote(`${p}-2`, issue, 2),
    ex(`${p}-3`, issue, 3, 'synthesize-findings'),
    ex(`${p}-4`, issue, 4, 'verify-ac'),
]
const THREE = () => [...chain('A', 'AGT-602'), ...chain('B', 'AGT-840'), ...chain('C', 'AGT-890')]

// ---- (1) no unit: one wave over the rows it is given -------------------
let out = await start(THREE())
ok(out.length === 18 && out.every((r, i) => r.step === THREE()[i].step),
    'no unit: one entry per row, in manifest order')
ok(!logged('wave: launch'), 'no unit: nothing about launches is logged')
ok(['A-0', 'B-0', 'C-0', 'A-4', 'B-4', 'C-4'].every((s) => SPAWNED.includes(s)),
    'no unit: every lane launches here')

// ---- (2) a unit launch runs every row it holds and nothing else ---------
out = await start(chain('B', 'AGT-840'), { unit: { index: 1, of: 3, classCap: { write: 1 } } })
ok(out.length === 6 && out.every((r) => r.status !== 'not-launched-other-shard'),
    'unit: the return carries exactly the launch\'s own rows, none as another launch\'s')
ok(['B-0', 'B-1a', 'B-1b', 'B-3', 'B-4'].every((s) => SPAWNED.includes(s)) && GATES.includes('B-2'),
    'unit: the lane runs its whole ladder in its own launch')
ok(logged('wave: launch 2 of 3') && logged('holds 6 row(s)') && logged('write≤1'),
    'unit: the log names the launch, its row count, and the class headroom it was handed')

// ---- (3) welded writer lanes still serialize inside their launch --------
// A and B: writers never co-staged (B rationed to stage 1), so lane_units.py
// puts them in one launch; the coupling rule must hold them in stage order.
const WELDED = () => [
    ex('A-0', 'AGT-602', 0, 'write'),
    ex('A-1', 'AGT-602', 1, 'judge-correctness'),
    ex('A-2', 'AGT-602', 2, 'write', { executor: 'fix' }),
    ex('B-1', 'AGT-840', 1, 'write', { status: 'staged' }),
    ex('B-2', 'AGT-840', 2, 'judge-correctness'),
]
let run = start(WELDED(), { unit: { index: 0, of: 2, classCap: { write: 1, 'judge-correctness': 2 } }, hold: ['A-0'] })
await settle()
ok(SPAWNED.includes('A-0') && !SPAWNED.includes('B-1'),
    "weld: B's writer waits while A's is in flight")
ok(logged('cross-issue coupling') && LOG.some((l) => l.startsWith('B-1: waiting — writer A-0')),
    "weld: the wait names the uncertified writer pair")
await finish('A-0')
out = await run
ok(SPAWNED.includes('B-1') && SPAWNED.includes('A-2') && SPAWNED.includes('B-2'),
    'weld: the welded lanes run to the end in their launch')

// ---- (4) classCap overrides the launch-local count -----------------------
// HRN-1 alone co-stages two judges, so its own rows certify judge at 2. A
// classCap of 1 (its share of the manifest-wide headroom) must narrow that.
const HEADROOM = () => [
    ex('A-0', 'HRN-1', 0, 'write'),
    ex('A-1a', 'HRN-1', 1, 'judge'),
    ex('A-1b', 'HRN-1', 1, 'judge'),
]
run = start(HEADROOM(), { unit: { index: 1, of: 2, classCap: { write: 1, judge: 1 } }, hold: ['A-1a'] })
await settle()
ok(SPAWNED.includes('A-1a') && !SPAWNED.includes('A-1b'),
    'classCap: the second judge waits under the share of one')
ok(logged('1 row(s) of class judge in flight — the manifest certifies at most 1 concurrent'),
    'classCap: the wait names the handed-down bound')
await finish('A-1a')
out = await run
ok(SPAWNED.includes('A-1b') && statusOf(out, 'A-1b') === 'returned',
    'classCap: the second judge launches once the first returns')
// Widening: two lanes whose judges sit on different stages certify judge at
// one locally, yet the manifest-wide share of two lets both run together.
run = start([ex('J-1', 'HRN-3', 0, 'judge'), ex('K-1', 'HRN-4', 1, 'judge')], { unit: { index: 0, of: 2, classCap: { judge: 2 } }, hold: ['J-1'] })
await settle()
ok(SPAWNED.includes('J-1') && SPAWNED.includes('K-1'),
    'classCap: a share above the launch-local count admits both judges at once')
await finish('J-1')
await run
run = start([ex('J-1', 'HRN-3', 0, 'judge'), ex('K-1', 'HRN-4', 1, 'judge')], { hold: ['J-1'] })
await settle()
ok(SPAWNED.includes('J-1') && !SPAWNED.includes('K-1'),
    'classCap: without it, the local count of one holds the second judge')
await finish('J-1')
await run
run = start(HEADROOM(), { hold: ['A-1a'] })
await settle()
ok(SPAWNED.includes('A-1a') && SPAWNED.includes('A-1b'),
    'classCap: without it, the launch-local certification of two admits both judges')
await finish('A-1a')
await run

// ---- (5) determinism: the same launch twice picks the same order ------
const first = [...(await start(THREE(), { unit: { index: 0, of: 1 } }), SPAWNED)]
const second = [...(await start(THREE(), { unit: { index: 0, of: 1 } }), SPAWNED)]
ok(first.join(',') === second.join(','), 'determinism: a repeated launch spawns the identical set in the identical order')

// ---- (6) the retired shard arg and malformed units refuse to route -----
const refuses = async (opts, frag, label) => {
    try {
        await start(THREE(), opts)
        ok(false, label)
    } catch (e) {
        ok(String(e.message).includes(frag) && String(e.message).includes('Refusing to route'), label)
    }
}
await refuses({ shard: { index: 0, of: 2 } }, 'args.shard is retired', 'refuse: the retired shard arg')
await refuses({ unit: { index: 2, of: 2 } }, 'out of range', 'refuse: index past `of`')
await refuses({ unit: { index: 0, of: LAUNCH_CAP + 1 } }, `exceeds LAUNCH_CAP ${LAUNCH_CAP}`, 'refuse: `of` past LAUNCH_CAP')
await refuses({ unit: { index: '0', of: 2 } }, 'non-integer', 'refuse: a non-integer index')
await refuses({ unit: '1/2' }, 'not an object', 'refuse: a string spec')
await refuses({ unit: { index: 0, of: 2, classCap: { judge: 0 } } }, 'positive integers', 'refuse: a classCap below one')
await refuses({ unit: { index: 0, of: 2, classCap: [1] } }, 'classCap is not an object', 'refuse: a classCap array')
ok(SPAWNED.length === 0, 'refuse: nothing launched on a refused spec')
ok(LAUNCH_CAP === 20, 'LAUNCH_CAP is the measured 20 (keep lane_units.py in step)')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
