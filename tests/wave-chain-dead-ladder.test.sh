#!/bin/bash

# Behavior suite for wave.js's stage ladder — what a dead chain actually does
# to the LATER rows of the same issue (DOT-559).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. tests/wave-park-signals.test.sh exercises the PREDICATES
# (runParked, chainDead) and says so in its own header: "it exercises the
# predicates, not the stage ladder they drive." DOT-559 was a defect in the
# ladder's reach, not in a predicate's judgement — 'spawn-failed' simply was
# not in chainDead()'s set, so RUN-43 booted three executors (STEP-1550,
# STEP-1563, STEP-1572; ~52K tokens) whose claims were guaranteed to be
# refused with "an `after` predecessor is not done". A predicate-only suite
# cannot see that. This one wraps the ladder region itself in an async
# function, feeds it stub spawn/runGate/probe/parallel/log globals, and asserts
# on what got spawned and what came back.
#
# It also covers the ladder's OTHER corpse guard, the pre-claim probe
# (DOT-560): the probe stub is scripted per step, so the suite can assert both
# halves of the contract — a recognized unreachable status skips the spawn, and
# anything unrecognized (empty, prose, engine error) still spawns.
#
# WHAT THIS SUITE CANNOT SEE: the real spawn() (agent launch, worktree
# isolation, the DOT-558 classifier retry) is stubbed out wholesale, and the
# engine's re-offer of the skipped steps at the next dispatch is engine
# behavior, asserted nowhere here.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-chain-dead-ladder.XXXXXX") || fatal "mktemp failed"
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

extract park-signals > "${WORK}/park.js" || fatal "bad or missing TEST markers for park-signals"
# The ladder calls the fix-round base-ancestry helpers (DOT-871), which live
# in their own region so tests/wave-fix-round-ancestry.test.sh can exercise
# them alone — concatenate that region ahead of the ladder, same as the
# orphaned-claim suite does for its neighbours.
# …which in turn read the target-ref envelope helpers (DOT-1040), shared with
# the gate path and fenced in their own nested region.
extract target-envelope > "${WORK}/envelope.js" || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js" || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder > "${WORK}/ladder.js" || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ladder.js" ] || fatal "extracted stage-ladder region is empty"
grep -q 'chainDead' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain chainDead"

{
    # --- stub workflow globals the ladder reaches for ---
    cat <<'JS'
let rows = []
let input = {}
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
// Every row the ladder decided to launch, in launch order, plus the canned
// result the scenario wants back for it.
let SPAWNED = []
let RESULTS = new Map()
const settleFor = (row) => {
    const r = RESULTS.get(row.step)
    return typeof r === 'function' ? r(row) : r
}
const spawn = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve(settleFor(row) === undefined
        ? { step: row.step, status: 'returned', text: `${row.step} recorded (done)` }
        : settleFor(row))
}
const runGate = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve(settleFor(row) === undefined
        ? { step: row.step, status: 'gate-passed', text: '{"status":"done"}' }
        : settleFor(row))
}
// The pre-claim probe. PROBES maps a step to the raw text `docket step show`
// would have returned for it; an unlisted step probes empty (fail-open).
let PROBES = new Map()
let PROBED = []
const probe = (_cmd, _label, _phase, step) => {
    PROBED.push(step)
    return Promise.resolve(PROBES.get(step) || '')
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
const ex = (step, issue, stage) => ({ step, issue, stage, kind: 'executor', executor: 'x' })
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status

// One wave, two issues, three stages — the RUN-43 shape. HRN-30's stage-0
// judge dies pre-spawn; its synthesize (stage 1) and verify-ac (stage 2) are
// the corpses DOT-559 stopped booting. HRN-99 runs the same ladder untouched.
const RUN43 = () => [
    ex('STEP-1547', 'HRN-30', 0),
    ex('STEP-1550', 'HRN-30', 1),
    ex('STEP-1563', 'HRN-30', 2),
    ex('STEP-2001', 'HRN-99', 0),
    ex('STEP-2002', 'HRN-99', 1),
]

const run = async (theRows, results, probes) => {
    rows = theRows
    SPAWNED = []
    PROBED = []
    LOG.length = 0
    RESULTS = new Map(Object.entries(results || {}))
    PROBES = new Map(Object.entries(probes || {}))
    return ladder()
}

// ---- AC1/AC2/AC3: a stage-0 'spawn-failed' kills only its own chain ----
let out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'spawn-failed', text: null },
})
ok(statusOf(out, 'STEP-1550') === 'skipped-chain-dead' &&
   statusOf(out, 'STEP-1563') === 'skipped-chain-dead',
    'AC1: later-stage rows of the spawn-failed issue settle skipped-chain-dead')
ok(!SPAWNED.includes('STEP-1550') && !SPAWNED.includes('STEP-1563'),
    'AC1: and neither of them is spawned')
ok(SPAWNED.includes('STEP-2001') && SPAWNED.includes('STEP-2002') &&
   statusOf(out, 'STEP-2002') === 'returned',
    'AC2: the other issue\'s rows run both stages, unaffected')
ok(statusOf(out, 'STEP-1547') === 'spawn-failed',
    'AC3: the return still names the spawn-failed step, with its own status')
ok(out.length === 5 && out.every((r) => r && typeof r.step === 'string'),
    'AC3: the return still carries one entry per manifest row')

// A spawn that resolves to nothing at all is RECORDED as spawn-failed, so it
// has to be READ as one too — otherwise the corpse-boot returns by the back
// door.
out = await run(RUN43(), { 'STEP-1547': null })
ok(statusOf(out, 'STEP-1547') === 'spawn-failed',
    'a null settle is still recorded as spawn-failed')
ok(statusOf(out, 'STEP-1550') === 'skipped-chain-dead' && !SPAWNED.includes('STEP-1550'),
    'and it kills the chain exactly like an explicit spawn-failed')

// ---- The guard against over-killing: a healthy stage still ladders ----
out = await run(RUN43(), {})
ok(SPAWNED.length === 5 && out.every((r) => r.status === 'returned'),
    'with nothing dead, every row of both issues spawns and returns')

// ---- Neighbouring dead statuses still behave (regression fence) ----
out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'gate-rejected', text: null },
})
ok(statusOf(out, 'STEP-1550') === 'skipped-chain-dead' &&
   statusOf(out, 'STEP-2002') === 'returned',
    'gate-rejected still kills its own chain and only its own')

// ---- DOT-1050: "died" is reserved for a predecessor that actually failed ----
// RUN-63's shape, four waves running: the engine minted a held-cluster panel
// step between a gate and its `after` predecessor, so the gate had no proposal
// to seat on and settled gate-blocked — while that predecessor was recording,
// holding its step and opening its vote, exactly as designed. The ladder's
// DECISION is unchanged (the later rows still do not launch, still settle
// skipped-chain-dead); only the wording moves, because "chain died" sends an
// operator hunting a failure that does not exist. The engine's own
// `blocked_reason` on the gate's `step show --json` payload is the evidence.
const blockedPayload = (reason) =>
    `{"data":{"step":"STEP-1547","status":"pending","blocked_reason":"${reason}"}}`
// The engine's CondPredecessors, verbatim (docket internal/engine/ready.go),
// backticks and all.
const AFTER_PRED = 'an `after` predecessor is not done'

out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'gate-blocked',
                   text: blockedPayload(AFTER_PRED) },
})
ok(statusOf(out, 'STEP-1550') === 'skipped-chain-dead' &&
   statusOf(out, 'STEP-1563') === 'skipped-chain-dead' &&
   !SPAWNED.includes('STEP-1550') && !SPAWNED.includes('STEP-1563'),
    'DOT-1050: a progressing predecessor still stops the lane — the decision is unchanged')
ok(LOG.some((l) => l.startsWith('STEP-1550: later stages deferred — predecessor ' +
                               'STEP-1547 is gate-blocked') && l.includes('ask next after close')),
    `DOT-1050: the skipped row logs the DEFERRED wording naming the predecessor and its status (got ${JSON.stringify(LOG)})`)
ok(!LOG.some((l) => l.includes('chain died')),
    'DOT-1050: and nothing in the wave log says the chain died')
ok(LOG.some((l) => l.includes('STEP-1547: settled gate-blocked') &&
                   l.includes('progressing, NOT failed')),
    'DOT-1050: the settling row itself reports a deferral, not a kill')
ok(statusOf(out, 'STEP-2002') === 'returned',
    'DOT-1050: the other issue is untouched, as always')

// Every OTHER progressing readiness clause the engine can report reads the
// same way — this is the set in PROGRESSING_BLOCKS, kept honest against
// docket's internal/engine/ready.go.
for (const reason of [
    'no threshold has routed to this interposed step',
    'an interposed gate on a predecessor has not resolved',
    'the issue\'s dependencies are not satisfied',
    'its scope conflicts with a claimed or running step',
    'no concurrency headroom in its class',
    'no budget headroom',
]) {
    out = await run(RUN43(), {
        'STEP-1547': { step: 'STEP-1547', status: 'gate-blocked', text: blockedPayload(reason) },
    })
    ok(LOG.some((l) => l.includes('later stages deferred')) &&
       !LOG.some((l) => l.includes('chain died')),
        `DOT-1050: "${reason}" is a deferral, not a death`)
}

// THE FENCE. A genuine failure keeps "died" whatever the payload says — the
// status decides eligibility first, the reason only confirms it.
for (const status of ['gate-rejected', 'spawn-failed', 'claim-conflict',
                      'parked-base-ancestry', 'gate-parked']) {
    out = await run(RUN43(), {
        'STEP-1547': { step: 'STEP-1547', status, text: blockedPayload(AFTER_PRED) },
    })
    ok(LOG.some((l) => l.includes('chain died')) &&
       !LOG.some((l) => l.includes('later stages deferred')),
        `DOT-1050 fence: ${status} still says the chain died, even carrying a progressing blocked_reason`)
}

// And a blocked_reason the list does NOT name — a failure-adjacent clause, or
// one the engine adds later — falls back to the old wording. Under-claiming a
// deferral costs one imprecise line; over-claiming one tells the operator to
// wait for a close that is never coming.
for (const reason of ['run is not active', 'the step is not pending',
                      'some clause invented after this list was written']) {
    out = await run(RUN43(), {
        'STEP-1547': { step: 'STEP-1547', status: 'gate-blocked', text: blockedPayload(reason) },
    })
    ok(LOG.some((l) => l.includes('chain died')) &&
       !LOG.some((l) => l.includes('later stages deferred')),
        `DOT-1050 fence: an unlisted blocked_reason ("${reason}") keeps the died wording`)
}

// A gate-blocked with NO blocked_reason at all (an absent field, a dead probe,
// prose) is the same fail-safe.
for (const text of ['{"data":{"step":"STEP-1547","status":"pending"}}', '', null,
                    'docket: could not reach the database']) {
    out = await run(RUN43(), {
        'STEP-1547': { step: 'STEP-1547', status: 'gate-blocked', text },
    })
    ok(LOG.some((l) => l.includes('chain died')) &&
       !LOG.some((l) => l.includes('later stages deferred')),
        `DOT-1050 fence: gate-blocked with no readable blocked_reason (${JSON.stringify(text)}) keeps the died wording`)
}

// The pre-claim probe's own skip reaches the same wording, since it settles
// skipped-not-claimable carrying the payload it read. (Same shape the DOT-560
// block below uses: an ACTION at stage 0 so the chain is not dead, executors
// behind it at stages 1 and 2.)
const DEFER43 = () => [
    { step: 'STEP-1540', issue: 'HRN-30', stage: 0, kind: 'action' },
    ex('STEP-1563', 'HRN-30', 1),
    ex('STEP-1572', 'HRN-30', 2),
]
out = await run(DEFER43(), {}, {
    'STEP-1563': `{"data":{"step":"STEP-1563","status":"pending","blocked_reason":"${AFTER_PRED}"}}`,
})
ok(statusOf(out, 'STEP-1563') === 'skipped-not-claimable' &&
   statusOf(out, 'STEP-1572') === 'skipped-chain-dead',
    'DOT-1050: a pending pre-claim probe still skips and still stops the lane')
ok(LOG.some((l) => l.startsWith('STEP-1572: later stages deferred — predecessor ' +
                               'STEP-1563 is skipped-not-claimable')),
    `DOT-1050: and it too reads as deferred, not dead (got ${JSON.stringify(LOG)})`)

// ---- A park stops LATER stages of every issue, not just one ----
out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'returned',
                   text: 'Did it.\n\nSTEP-1547 recorded (waiting-human)' },
})
ok(statusOf(out, 'STEP-1550') === 'not-launched-run-parked' &&
   statusOf(out, 'STEP-2002') === 'not-launched-run-parked',
    'a mid-wave park leaves every later row not-launched-run-parked')
ok(SPAWNED.includes('STEP-2001'),
    'while the parking row\'s own stage-mates still ran')

// ---- DOT-560: the pre-claim probe's fail-open must not cover 'pending' ----
// Shape: one issue whose stage-0 row is an ACTION (engine-run, so the chain is
// NOT dead), with executors behind it at stages 1 and 2. needsClaimProbe fires
// on exactly those two, and their probes run AFTER stage 0 was awaited — the
// stage barrier has passed, so a 'pending' step can no longer become 'ready'
// within this wave.
const act = (step, issue, stage) => ({ step, issue, stage, kind: 'action' })
const PROBE43 = () => [
    act('STEP-1540', 'HRN-30', 0),
    ex('STEP-1563', 'HRN-30', 1),
    ex('STEP-1572', 'HRN-30', 2),
]
const st = (s) => `{"data":{"step":"STEP-x","status":"${s}"}}`

out = await run(PROBE43(), {}, { 'STEP-1563': st('pending'), 'STEP-1572': st('pending') })
ok(PROBED.includes('STEP-1563'),
    'DOT-560: the row behind an action row is pre-claim probed')
ok(statusOf(out, 'STEP-1563') === 'skipped-not-claimable',
    'DOT-560: a post-barrier probe reading "pending" settles skipped-not-claimable')
ok(!SPAWNED.includes('STEP-1563'),
    'DOT-560: and no executor is spawned for it')
ok(statusOf(out, 'STEP-1572') === 'skipped-chain-dead' && !SPAWNED.includes('STEP-1572'),
    'DOT-560: skipped-not-claimable still kills the rest of the issue\'s chain')

// Fail-open is the whole reason the probe is safe to run: anything the regex
// does not positively recognize still spawns.
out = await run(PROBE43(), {}, {})
ok(SPAWNED.includes('STEP-1563') && statusOf(out, 'STEP-1563') === 'returned',
    'DOT-560: an EMPTY probe still spawns (fail-open preserved)')

out = await run(PROBE43(), {}, {
    'STEP-1563': 'docket: could not reach the database\n',
    'STEP-1572': 'Step STEP-1572 is pending.\n',
})
ok(SPAWNED.includes('STEP-1563') && SPAWNED.includes('STEP-1572'),
    'DOT-560: unparseable probe prose still spawns, even prose containing "pending"')

// And a 'ready' step — the case the probe exists to let through — is untouched.
out = await run(PROBE43(), {}, { 'STEP-1563': st('ready'), 'STEP-1572': st('ready') })
ok(SPAWNED.includes('STEP-1563') && SPAWNED.includes('STEP-1572') &&
   statusOf(out, 'STEP-1572') === 'returned',
    'DOT-560: a probe reading "ready" spawns as before')

// The terminal statuses the probe already skipped on must keep skipping.
for (const s of ['done', 'superseded', 'skipped', 'failed']) {
    out = await run(PROBE43(), {}, { 'STEP-1563': st(s) })
    ok(statusOf(out, 'STEP-1563') === 'skipped-not-claimable' && !SPAWNED.includes('STEP-1563'),
        `DOT-560 fence: "${s}" still settles skipped-not-claimable without a spawn`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
