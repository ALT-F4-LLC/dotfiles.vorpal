#!/bin/bash

# Behavior suite for wave.js's harness-slot weighting: how a vote row's
# judge panel counts against the harness's own concurrency cap, alongside
# executor rows.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. Before this fix, admission counted ROWS in flight, capped
# at HARNESS_CAP, and only ever added EXECUTOR rows to that count
# (`if (!isExecutorRow(row)) return null` short-circuited the harness-cap
# check for every vote row, and `inFlight.set` was gated the same way) — so
# a vote row's own panel, which tribunal.js seats via `parallel(seats.map(...))`
# and therefore genuinely runs `seats` agent() calls simultaneously, was
# invisible to admission entirely. The motivating incident this admission
# rule already existed to prevent — 21 judge agents once queuing past a
# harness cap the wave believed still had room — is EXACTLY a vote-row
# shape, and the pre-fix code never weighed vote rows against the cap at
# all. concurrencyWeight(row) now returns the seat count for a vote row (1
# for an executor, which only ever has one agent() call in flight at a
# time), and admission blocks a row when harnessWeight + that row's
# (cap-clamped) weight would exceed effectiveHarnessCap.
#
# WHAT IS PINNED HERE. (1) a vote row's weight is its seat count, not 1 and
# not agentCost()'s seats+VOTE_PROBE_COST (a different, LIFETIME-total
# quantity the agent budget uses, unrelated to concurrency); (2) three
# 3-seat vote rows against a harness cap of 6 admit two (weight 6) and hold
# the third; (3) a vote row and executor rows share the same weighted pool —
# a 3-seat vote row plus 3 executor rows fills a cap-6 harness exactly; (4)
# a vote row whose seat count EXCEEDS effectiveHarnessCap still admits when
# nothing else is in flight (clamped to the cap, never deadlocked — the
# harness itself queues the excess agent() calls); (5) a vote row's wait or
# admission never trips the class-headroom or writer-coupling messages,
# which are executor-only concepts a vote row's empty class must never
# compete in.
#
# HOW. Extends tests/wave-issue-lanes.test.sh's stage-ladder harness with a
# HOLDABLE `runGate` stub (mirroring the existing holdable `spawn`), so a
# vote row can be observed occupying a harness slot before it settles.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-vote-harness-weight.XXXXXX") || fatal "mktemp failed"
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
grep -q 'concurrencyWeight' "${WORK}/ladder.js" || fatal "stage-ladder region no longer computes concurrencyWeight — has the weighted-admission fix changed shape?"
grep -q 'function concurrencyWeight' "${WORK}/ladder.js" || fatal "concurrencyWeight is referenced but not defined in the extracted region"

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
// HOLDABLE runGate: unlike wave-issue-lanes.test.sh's stub (which always
// resolves immediately), this one mirrors spawn()'s HOLD/OPEN pattern so a
// vote row can be observed occupying its harness weight before it settles —
// the exact window this suite needs to watch.
const runGate = (row) => {
    GATES.push(row.step)
    const canned = settleFor(row) === undefined
        ? { step: row.step, status: 'gate-passed', text: '{"status":"done"}' }
        : settleFor(row)
    if (!HOLD.has(row.step)) return Promise.resolve(canned)
    return new Promise((resolve) => OPEN.set(row.step, () => resolve(canned)))
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
    input = (opts && opts.harnessCap !== undefined) ? { harnessCap: opts.harnessCap } : {}
    SPAWNED = []; GATES = []; PROBED = []; LOG.length = 0
    RESULTS = new Map()
    HOLD = new Set(theRows.map((r) => r.step))   // every row holds until finish()
    OPEN = new Map()
    return ladder()
}
const logged = (frag) => LOG.some((l) => l.includes(frag))
const inFlight = (step) => SPAWNED.includes(step) || GATES.includes(step)

// N issue-less executor singleton rows.
const exRows = (n, prefix) => Array.from({ length: n }, (_, i) => ({
    step: `${prefix}${i}`, stage: 0, kind: 'executor', executor: 'research', class: 'research',
}))
// A vote row with `seats` voter_assignments — the exact field tribunal.js
// reads its panel size from, and concurrencyWeight's vote branch reads too.
const voteRow = (step, seats) => ({
    step, stage: 0, kind: 'vote',
    voter_assignments: Array.from({ length: seats }, (_, i) => ({ voter: `seat-${i}` })),
})

// ---- (1) a vote row's weight is its seat count, not 1 -------------------
{
    const run = start([voteRow('V-0', 3)], { harnessCap: 6 })
    await settle()
    ok(inFlight('V-0'), 'case 1: the single 3-seat vote row admits (3 <= cap 6)')
    await finish('V-0')
    await run
}
// The weight arithmetic itself — that a vote row's occupancy is its seat
// count, not 1 — is what case 2 below actually pins: three 3-seat panels
// against a cap of 6 admit exactly two (weight 3+3=6), which could only
// happen if each panel occupies 3 slots, not 1.

// ---- (2) three 3-seat vote rows against cap 6 admit two, hold the third -
{
    const run = start([voteRow('V-0', 3), voteRow('V-1', 3), voteRow('V-2', 3)], { harnessCap: 6 })
    await settle()
    ok(inFlight('V-0') && inFlight('V-1'), 'case 2: the first two 3-seat panels admit (weight 3+3=6, fills the cap)')
    ok(!inFlight('V-2'),
        'case 2: the third 3-seat panel is held — 6+3=9 would exceed the cap of 6')
    ok(logged('waiting — 6 of 6 harness slot(s) in flight (this row needs 3)'),
        `case 2: the wait names the weighted occupancy, not a bare row count (got ${JSON.stringify(LOG.filter((l) => l.includes('waiting')))})`)
    await finish('V-0')
    await settle()
    ok(inFlight('V-2'), 'case 2: releasing one 3-seat panel frees exactly enough weight for the third')
    await finish('V-1')
    await finish('V-2')
    await run
}

// ---- (3) a vote row and executor rows share one weighted pool -----------
{
    const run = start([voteRow('V-0', 3), ...exRows(4, 'E')], { harnessCap: 6 })
    await settle()
    ok(inFlight('V-0'), 'case 3: the 3-seat vote row admits')
    ok(inFlight('E0') && inFlight('E1') && inFlight('E2'),
        'case 3: three executor rows (weight 1 each) admit alongside it (3+1+1+1=6, fills the cap)')
    ok(!inFlight('E3'),
        'case 3: the fourth executor row is held — 6+1=7 would exceed the cap of 6')
    await finish('V-0')
    await settle()
    ok(inFlight('E3'), 'case 3: releasing the vote row frees exactly 3, enough for the held executor')
    for (const s of ['E0', 'E1', 'E2', 'E3']) await finish(s)
    await run
}

// ---- (4) an over-weight vote row still admits alone, never deadlocks ----
{
    const run = start([voteRow('V-0', 9)], { harnessCap: 6 })
    await settle()
    ok(inFlight('V-0'),
        'case 4: a 9-seat panel against a cap of 6 still admits when nothing else is in flight — clamped, not deadlocked')
    await finish('V-0')
    await run
}

// ---- (5) a vote row never trips the class-headroom or writer-coupling
// messages, which are executor-only concepts --------------------------
{
    const run = start([voteRow('V-0', 3), voteRow('V-1', 3)], { harnessCap: 10 })
    await settle()
    ok(inFlight('V-0') && inFlight('V-1'), 'case 5: both vote rows admit under a generous cap')
    ok(!logged('row(s) of class'), 'case 5: no class-headroom message names a vote row')
    ok(!logged('scopes unproven disjoint'), 'case 5: no writer-coupling message names a vote row')
    await finish('V-0')
    await finish('V-1')
    await run
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
