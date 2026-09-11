#!/bin/bash

# Behavior suite for wave.js's AGENT BUDGET — the self-bound that keeps one
# wave launch under the Workflow tool's 1000-agent lifetime cap.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. RUN-95's first `dispatch open` (no --limit) offered a
# staged-closure manifest of 947 executor rows and 200 vote rows — roughly
# 1750-2150 agents once seats and probes are counted — against a harness that
# kills the whole invocation at its 1000th agent, with claims and worktrees
# stranded across every lane still in flight. The cap counts every agent()
# the invocation ever made, so no chunking inside the script gets past it; the
# wave has to stop launching in time, and it has to do so without holding any
# lane: a row the budget cannot cover is DEFERRED on the spot (the engine
# re-offers it next dispatch), never parked in the admission queue where it
# would idle its lane and, through the stage await, every row behind it.
#
# This suite wraps the ladder region in an async function with stubbed
# spawn/runGate/probe/parallel/log globals — the wave-chain-dead-ladder.test.sh
# scaffolding — and asserts on what launched, what deferred, and how the wave
# said so.
#
# WHAT THIS SUITE CANNOT SEE: the real agent() counter (the stubs spawn
# nothing), so the per-kind cost constants are asserted as the projection they
# are, not measured against a harness.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-agent-budget.XXXXXX") || fatal "mktemp failed"
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
extract park-signals > "${WORK}/park.js" || fatal "bad or missing TEST markers for park-signals"
extract target-envelope > "${WORK}/envelope.js" || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js" || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder > "${WORK}/ladder.js" || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ladder.js" ] || fatal "extracted stage-ladder region is empty"
grep -q 'AGENT_BUDGET' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain the agent budget"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
let rows = []
let input = {}
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
let SPAWNED = []
const spawn = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve({ step: row.step, status: 'returned', text: `${row.step} recorded (done)` })
}
const runGate = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve({ step: row.step, status: 'gate-passed', text: '{"status":"done"}' })
}
const probe = () => Promise.resolve('')

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
const ex = (step, issue, stage) => ({ step, issue, stage, kind: 'executor', executor: 'x', class: 'read' })
const act = (step, issue, stage) => ({ step, issue, stage, kind: 'action' })
const vote =(step, issue, stage, seats) => ({
    step, issue, stage, kind: 'vote',
    voter_assignments: Array.from({ length: seats }, (_, i) => ({ voter: `judge-${i}`, model: 'm', effort: 'e', variant: 'v' })),
})
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status
const run = async (theRows) => {
    rows = theRows
    SPAWNED = []
    LOG.length = 0
    return ladder()
}
// Read the production configuration rather than duplicating its values.
const BUDGET = AGENT_BUDGET
const EXEC = EXECUTOR_AGENT_COST
const VOTE_PROBES = VOTE_PROBE_COST

// ---- A manifest that fits launches everything and reports the budget ----
let out = await run([ex('STEP-1', 'A', 0), ex('STEP-2', 'A', 1), vote('STEP-3', 'A', 2, 3), ex('STEP-4', 'B', 0)])
ok(SPAWNED.length === 4 && out.every((r) => r.status === 'returned' || r.status === 'gate-passed'),
    'small manifest: every row launches, nothing deferred')
ok(!LOG.some((l) => /projects ~\d+ agents against a budget/.test(l)),
    'small manifest: no over-budget warning')
ok(LOG.some((l) => l === `wave: agent budget — ${3 * EXEC + 3 + VOTE_PROBES} of ${BUDGET} projected agents reserved this launch`),
    'small manifest: the closing line reports the reservation exactly (3 executors, one 3-seat vote)')

// ---- RUN-95's shape, scaled: far more rows than the budget covers ----
// 300 issues × (implement, review) = 600 executor rows = 1200 projected
// agents against 900. Exactly 450 executors may launch.
const big = []
for (let i = 0; i < 300; i++) {
    big.push(ex(`STEP-${1000 + i}`, `ISS-${i}`, 0))
    big.push(ex(`STEP-${2000 + i}`, `ISS-${i}`, 1))
}
out = await run(big)
ok(LOG.some((l) => l.startsWith(`wave: the manifest projects ~1200 agents against a budget of ${BUDGET}`)),
    'over budget: the wave says up front what the manifest projects and what it will do')
ok(SPAWNED.length === BUDGET / EXEC,
    `over budget: exactly ${BUDGET / EXEC} executors launch (got ${SPAWNED.length})`)
const deferred = out.filter((r) => r.status === 'not-launched-agent-budget')
const chainDeferred = out.filter((r) => r.status === 'skipped-chain-dead')
ok(deferred.length > 0 && deferred.length + chainDeferred.length + SPAWNED.length === big.length,
    `over budget: every unlaunched row is a deferral (${deferred.length} budget, ${chainDeferred.length} behind one), never spawn-failed`)
ok(!out.some((r) => r.status === 'spawn-failed' || r.status === 'not-launched-run-parked'),
    'over budget: no row reads as failed or parked — nothing failed')
ok(out.length === big.length && out.every((r) => r && typeof r.step === 'string'),
    'over budget: the return carries one entry per manifest row (the wave did not hang or drop rows)')
// Non-blocking: lanes finish. With deepest-stage-first admission, a lane
// whose stage 0 launched gets its stage 1 ahead of another lane's stage 0,
// so the budget buys COMPLETE chains — many lanes have both rows launched,
// and no lane launched stage 1 without stage 0.
const launched = new Set(SPAWNED)
const complete = Array.from({ length: 300 }, (_, i) => i)
    .filter((i) => launched.has(`STEP-${1000 + i}`) && launched.has(`STEP-${2000 + i}`)).length
ok(complete >= 200,
    `over budget: the budget is spent finishing chains — ${complete} of 300 lanes ran both stages`)
ok(!Array.from({ length: 300 }, (_, i) => i).some((i) => launched.has(`STEP-${2000 + i}`) && !launched.has(`STEP-${1000 + i}`)),
    'over budget: no lane ran its stage 1 without its stage 0')
// A deferred stage-0 row marks its lane deferred (not dead), and the lane's
// stage-1 row is neither launched nor called a corpse.
const firstDeferred = deferred.find((r) => /^STEP-1\d\d\d$/.test(r.step))
if (firstDeferred) {
    const i = Number(firstDeferred.step.slice(5)) - 1000
    ok(statusOf(out, `STEP-${2000 + i}`) === 'skipped-chain-dead' && !launched.has(`STEP-${2000 + i}`),
        'over budget: a lane whose stage 0 was deferred settles its stage 1 without launching it')
    ok(LOG.some((l) => l.startsWith(`STEP-${2000 + i}: later stages deferred`) && l.includes('agent budget')),
        'over budget: the lane\'s later row is logged as DEFERRED for the budget, not as a dead chain')
    ok(LOG.some((l) => l.startsWith(`${firstDeferred.step}: not launched — agent budget:`)),
        'over budget: the deferred row itself names the budget as the reason')
} else {
    ok(false, 'over budget: at least one stage-0 row was deferred')
}
ok(LOG.some((l) => l.startsWith(`wave: agent budget — ${BUDGET} of ${BUDGET} projected agents reserved this launch; `) &&
    l.includes(`${deferred.length} row(s) deferred`)),
    'over budget: the closing line reports the full reservation and the deferral count')

// ---- Vote rows cost their seats plus the gate reads ----
// 100 three-seat vote rows (6 each = 600) after 200 executors (400) is 1000
// projected against 900: the executors all fit, and the votes stop once the
// remainder cannot seat one more panel.
const mixed = []
for (let i = 0; i < 200; i++) mixed.push(ex(`STEP-${5000 + i}`, `MX-${i}`, 0))
for (let i = 0; i < 100; i++) mixed.push(vote(`STEP-${6000 + i}`, `VX-${i}`, 0, 3))
out = await run(mixed)
const votesLaunched = SPAWNED.filter((s) => s.startsWith('STEP-6')).length
const execsLaunched = SPAWNED.filter((s) => s.startsWith('STEP-5')).length
ok(execsLaunched + votesLaunched === SPAWNED.length && execsLaunched * EXEC + votesLaunched * (3 + VOTE_PROBES) <= BUDGET,
    `mixed: the reservation never exceeds the budget (${execsLaunched} executors, ${votesLaunched} votes)`)
ok(execsLaunched * EXEC + (votesLaunched + 1) * (3 + VOTE_PROBES) > BUDGET,
    'mixed: one more panel would not have fit — the budget is spent, not under-used')
ok(out.filter((r) => r.status === 'not-launched-agent-budget').length === mixed.length - SPAWNED.length,
    'mixed: every unlaunched row is a budget deferral')

// ---- Action rows cost nothing ----
out = await run([act('STEP-7000', 'AX', 0), ex('STEP-7001', 'AX', 1)])
ok(LOG.some((l) => l === `wave: agent budget — ${EXEC} of ${BUDGET} projected agents reserved this launch`),
    'an engine-run action row reserves no agents')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
