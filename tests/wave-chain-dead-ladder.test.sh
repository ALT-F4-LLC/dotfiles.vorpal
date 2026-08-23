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
extract stage-ladder > "${WORK}/ladder.js" || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ladder.js" ] || fatal "extracted stage-ladder region is empty"
grep -q 'chainDead' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain chainDead"

{
    # --- stub workflow globals the ladder reaches for ---
    cat <<'JS'
let rows = []
let input = { policyText: '' }
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
const probe = () => Promise.resolve('')

const ladder = async () => {
JS
    cat "${WORK}/park.js"
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

const run = async (theRows, results) => {
    rows = theRows
    SPAWNED = []
    LOG.length = 0
    RESULTS = new Map(Object.entries(results || {}))
    return ladder()
}

// ---- AC1/AC2/AC3: a stage-0 'spawn-failed' kills only its own chain ----
let out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'spawn-failed', text: null },
})
ok(statusOf(out, 'STEP-1550') === 'skipped-dead-issue' &&
   statusOf(out, 'STEP-1563') === 'skipped-dead-issue',
    'AC1: later-stage rows of the spawn-failed issue settle skipped-dead-issue')
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
ok(statusOf(out, 'STEP-1550') === 'skipped-dead-issue' && !SPAWNED.includes('STEP-1550'),
    'and it kills the chain exactly like an explicit spawn-failed')

// ---- The guard against over-killing: a healthy stage still ladders ----
out = await run(RUN43(), {})
ok(SPAWNED.length === 5 && out.every((r) => r.status === 'returned'),
    'with nothing dead, every row of both issues spawns and returns')

// ---- Neighbouring dead statuses still behave (regression fence) ----
out = await run(RUN43(), {
    'STEP-1547': { step: 'STEP-1547', status: 'gate-rejected', text: null },
})
ok(statusOf(out, 'STEP-1550') === 'skipped-dead-issue' &&
   statusOf(out, 'STEP-2002') === 'returned',
    'gate-rejected still kills its own chain and only its own')

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

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
