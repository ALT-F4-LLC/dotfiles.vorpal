#!/bin/bash

# Behavior suite for wave.js's per-unit LAUNCHES — one dispatch split into
# one wave launch per issue, each launch holding only its own rows.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The Workflow tool caps one invocation at 16 concurrent
# agents and 1000 over its lifetime, and a nested workflow() shares both with
# its parent; separate top-level launches share neither, and 20 of them ran
# concurrently with none refused. So the conductor launches one wave per
# issue and hands each only its own rows plus `unit: {index, of, classCap}`
# from lane_units.py (whose own suite, docket-run-lane-units, pins the
# partition). What has to hold here: a launch runs every row it holds and
# returns one entry per row, never another launch's status; a launch with
# `unit` and more than one issue lane refuses to route, while a launch with no
# `unit` still serializes writer lanes the engine never co-staged;
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
// wave.js returns {statuses, coordination}; `out` below is that object.
const statusOf = (out, step) => (out.statuses.find((r) => r.step === step) || {}).status
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
ok(out.statuses.length === 18 && out.statuses.every((r, i) => r.step === THREE()[i].step),
    'no unit: one entry per row, in manifest order')
ok(!logged('wave: launch'), 'no unit: nothing about launches is logged')
ok(['A-0', 'B-0', 'C-0', 'A-4', 'B-4', 'C-4'].every((s) => SPAWNED.includes(s)),
    'no unit: every lane launches here')

// ---- (2) a unit launch runs every row it holds and nothing else ---------
out = await start(chain('B', 'AGT-840'), { unit: { index: 1, of: 3, classCap: { write: 1 } } })
ok(out.statuses.length === 6 && out.statuses.every((r) => r.status !== 'not-launched-other-shard'),
    'unit: the return carries exactly the launch\'s own rows, none as another launch\'s')
ok(['B-0', 'B-1a', 'B-1b', 'B-3', 'B-4'].every((s) => SPAWNED.includes(s)) && GATES.includes('B-2'),
    'unit: the lane runs its whole ladder in its own launch')
ok(logged('wave: launch 2 of 3') && logged('holds 6 row(s)') && logged('write≤1'),
    'unit: the log names the launch, its row count, and the class headroom it was handed')

// ---- (3) one issue per launch: a unit launch with two lanes refuses ------
// A and B: writers never co-staged (B rationed to stage 1). The conductor
// launches each alone; a launch carrying both is refused before any spawn.
const UNCERTIFIED = () => [
    ex('A-0', 'AGT-602', 0, 'write'),
    ex('A-1', 'AGT-602', 1, 'judge-correctness'),
    ex('A-2', 'AGT-602', 2, 'write', { executor: 'fix' }),
    ex('B-1', 'AGT-840', 1, 'write', { status: 'staged' }),
    ex('B-2', 'AGT-840', 2, 'judge-correctness'),
]
try {
    await start(UNCERTIFIED(), { unit: { index: 0, of: 2, classCap: { write: 1, 'judge-correctness': 2 } } })
    ok(false, 'one issue per launch: a unit launch holding two lanes refuses')
} catch (e) {
    ok(String(e.message).includes('exactly one issue lane') && String(e.message).includes('AGT-602, AGT-840') &&
        String(e.message).includes('Refusing to route') && SPAWNED.length === 0,
        'one issue per launch: a unit launch holding two lanes refuses before any spawn')
}
// Without `unit`, the in-wave coupling rule still holds them in stage order.
let run = start(UNCERTIFIED(), { hold: ['A-0'] })
await settle()
ok(SPAWNED.includes('A-0') && !SPAWNED.includes('B-1'),
    "no unit: B's writer waits while A's is in flight")
ok(logged('cross-issue coupling') && LOG.some((l) => l.startsWith('B-1: waiting — writer A-0')),
    "no unit: the wait names the uncertified writer pair")
await finish('A-0')
out = await run
ok(SPAWNED.includes('B-1') && SPAWNED.includes('A-2') && SPAWNED.includes('B-2'),
    'no unit: both lanes run to the end')

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
// Two lanes whose judges sit on different stages certify judge at one
// locally; a launch with no unit has no wider share to apply.
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
const first = [...(await start(chain('A', 'AGT-602'), { unit: { index: 0, of: 1 } }), SPAWNED)]
const second = [...(await start(chain('A', 'AGT-602'), { unit: { index: 0, of: 1 } }), SPAWNED)]
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

// ---- (7) the launch measures its own coordination section --------------
// One lane's writer settles claim-conflict (its judge is then chain-dead);
// another lane's gate passes on its first round after re-seating one judge.
// The section comes from the launch's own rows and settled statuses, with no
// conductor input, and rides beside the per-row statuses in one plain object.
const COORDINATED = () => [
    ex('X-0', 'CRD-1', 0, 'write', { instance: 'implement@0' }),
    ex('X-1', 'CRD-1', 1, 'judge-correctness', { instance: 'review@0#1' }),
    Object.assign(vote('Y-2', 'CRD-2', 0), { instance: 'verify-tribunal@0' }),
]
out = await start(COORDINATED(), { results: {
    'X-0': { step: 'X-0', status: 'claim-conflict', text: 'not ready to claim' },
    'Y-2': { step: 'Y-2', status: 'gate-passed', text: '{"status":"done"}', reseats: 1 },
} })
const c = out.coordination
ok(JSON.stringify(Object.keys(out)) === JSON.stringify(['statuses', 'coordination']) &&
    Array.isArray(out.statuses) && out.statuses.length === 3 &&
    out.statuses.map((r) => `${r.step}:${r.status}`).join(',') === 'X-0:claim-conflict,X-1:skipped-chain-dead,Y-2:gate-passed',
    'coordination: the return is {statuses, coordination}, the per-row statuses unchanged')
ok(c != null && c.claim_conflicts === 1, `coordination: one claim conflict counted (got ${JSON.stringify(c)})`)
ok(c != null && c.reseats === 1, `coordination: one re-seated judge counted (got ${c && c.reseats})`)
ok(c != null && c.rows === 3 && c.deferred.chain_dead === 1 && c.deferred.total === 1 &&
    c.gates.passed === 1 && c.gates.decided === 1 &&
    c.gates.first_pass.decided === 1 && c.gates.first_pass.rate === 1 &&
    c.rounds_per_issue['CRD-1'] === 0 && c.rounds_per_issue['CRD-2'] === 0 &&
    c.ancestry_parks === 0 && c.spawn_failed === 0 && c.unmatched_steps.length === 0,
    'coordination: rows, gates, deferrals and rounds are counted from the settled statuses')
ok(c != null && JSON.stringify(Object.keys(c)) === JSON.stringify(['rows', 'rounds_per_issue', 'gates',
    'reseats', 'claim_conflicts', 'ancestry_parks', 'spawn_failed', 'deferred', 'unmatched_steps']),
    'coordination: the field set matches the wave-usage join\'s section')
// The harness hands the conductor the return as JSON text, so the whole
// return, section included, must survive a JSON round trip.
const crossed = JSON.parse(JSON.stringify(out))
ok(JSON.stringify(crossed.coordination) === JSON.stringify(c) &&
    JSON.stringify(crossed.statuses) === JSON.stringify(out.statuses),
    `coordination: the section and the statuses survive the JSON transport (got ${JSON.stringify(crossed)})`)

// ---- (8) every coordination bucket, one lane per settled status ---------
// Each row is its own issue, so no status cascades into another row. The
// expected section is derived by hand from the fixture: a gate is decided
// when it passed, was rejected or parked, and counts toward first pass only
// at instance ordinal 0.
const BUCKETS = () => [
    Object.assign(vote('R-0', 'CRD-3', 0), { instance: 'verify-tribunal@2' }),
    Object.assign(vote('B-0', 'CRD-4', 0), { instance: 'verify-tribunal@0' }),
    Object.assign(vote('P-0', 'CRD-5', 0), { instance: 'verify-tribunal@0' }),
    Object.assign(vote('K-0', 'CRD-6', 0), { instance: 'gate@0' }),
    ex('N-0', 'CRD-7', 0, 'write', { executor: 'fix', instance: 'fix@1' }),
    ex('S-0', 'CRD-8', 0, 'judge-correctness', { instance: 'review@0#2' }),
    ex('G-0', 'CRD-9', 0, 'judge-testing', { instance: 'review@0#1' }),
    ex('W-0', 'CRD-10', 0, 'judge-security', { instance: 'review@0#3' }),
    ex('U-0', 'CRD-11', 0, 'verify-ac', { instance: 'verify-ac@0' }),
]
const settledAs = (step, status) => ({ step, status, text: null })
out = await start(BUCKETS(), { results: {
    'R-0': settledAs('R-0', 'gate-rejected'),
    'B-0': settledAs('B-0', 'gate-blocked'),
    'P-0': settledAs('P-0', 'gate-parked'),
    'K-0': settledAs('K-0', 'gate-skipped'),
    'N-0': settledAs('N-0', 'parked-base-ancestry'),
    'S-0': settledAs('S-0', 'spawn-failed'),
    'G-0': settledAs('G-0', 'not-launched-agent-budget'),
    'W-0': settledAs('W-0', 'not-launched-writer-budget'),
    'U-0': settledAs('U-0', 'not-launched-run-parked'),
} })
ok(JSON.stringify(out.coordination) === JSON.stringify({
    rows: 9,
    rounds_per_issue: { 'CRD-3': 2, 'CRD-4': 0, 'CRD-5': 0, 'CRD-6': 0, 'CRD-7': 1,
                        'CRD-8': 0, 'CRD-9': 0, 'CRD-10': 0, 'CRD-11': 0 },
    gates: { decided: 2, passed: 0, rejected: 1, parked: 1, blocked: 1, skipped: 1,
             first_pass: { decided: 1, passed: 0, rate: 0 } },
    reseats: 0,
    claim_conflicts: 0,
    ancestry_parks: 1,
    spawn_failed: 1,
    deferred: { agent_budget: 1, writer_budget: 1, chain_dead: 0, run_parked: 1, token_budget: 0, total: 3 },
    unmatched_steps: [],
}), `coordination: every bucket counts its own settled status (got ${JSON.stringify(out.coordination)})`)

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
