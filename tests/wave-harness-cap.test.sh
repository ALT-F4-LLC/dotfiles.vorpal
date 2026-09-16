#!/bin/bash

# Behavior suite for wave.js's effective harness concurrency cap:
# `args.harnessCap`, and how it interacts with the loose HARNESS_CAP=16
# ceiling admission was previously bound to unconditionally.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The Workflow tool's real agent() concurrency cap is
# min(16, CPUs-2) per invocation — this script cannot read the machine's own
# CPU count, so it used HARNESS_CAP=16 unconditionally as the loosest bound
# it could assert. On any machine under 18 cores the real cap is tighter,
# and admission()'s own header comment names the failure this causes: judge
# agents queuing behind a harness slot the wave believed was still open. The
# fix lets the conductor (which CAN run `nproc`) pass the real figure as
# `args.harnessCap`; wave.js takes min(HARNESS_CAP, that value) as the
# effective admission bound, and falls back to the loose 16-agent ceiling
# when the field is absent — a caller that omits it (an older SKILL.md, a
# direct scriptPath launch, a resumed run whose original args predate this
# field) is not refused, since a tighter bound this script cannot verify is
# advisory, not a contract.
#
# WHAT IS PINNED HERE. (1) a harnessCap tighter than 16 is honored — the
# concurrency-gate log line names the tighter figure, and a row queues
# behind it before 16 rows are in flight; (2) a harnessCap of exactly 16 (or
# missing entirely) behaves identically to the pre-fix unconditional 16; (3)
# a harnessCap ABOVE 16 is clamped to 16, never used to admit past the
# script's own hard ceiling; (4) a non-integer, zero, or negative harnessCap
# is ignored (falls back to 16), never crashes or admits zero rows.
#
# HOW. Like tests/wave-shard-partition.test.sh, it wraps the extracted
# stage-ladder region in an async function with stub spawn/runGate/probe/
# parallel/log globals and sets `input.harnessCap` per scenario. Rows are
# issue-less singletons (their own lane each) so nothing but the harness cap
# gates their admission.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-harness-cap.XXXXXX") || fatal "mktemp failed"
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
grep -q 'effectiveHarnessCap' "${WORK}/ladder.js" || fatal "stage-ladder region no longer computes effectiveHarnessCap — has the harness-cap fix changed shape?"

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
const start = (theRows, harnessCap) => {
    rows = theRows
    input = harnessCap === undefined ? {} : { harnessCap }
    SPAWNED = []; GATES = []; PROBED = []; LOG.length = 0
    RESULTS = new Map()
    HOLD = new Set(theRows.map((r) => r.step))   // every row holds until finish()
    OPEN = new Map()
    return ladder()
}
// N issue-less singleton rows, each its own lane, no class/writer coupling —
// nothing but the harness cap gates their admission.
const rowsOf = (n) => Array.from({ length: n }, (_, i) => ({
    step: `STEP-${i}`, stage: 0, kind: 'executor', executor: 'research', class: 'research',
}))
const logged = (frag) => LOG.some((l) => l.includes(frag))

// ---- (1) a tighter harnessCap is honored ---------------------------------
{
    const run = start(rowsOf(20), 6)
    await settle()
    ok(SPAWNED.length === 6,
        `case 1: only 6 of 20 rows admit — the tighter harnessCap gates them (got ${SPAWNED.length})`)
    ok(logged('conductor reported 6, using 6') || logged('using 6 (min of that and the 16-agent ceiling)'),
        `case 1: the log names the tighter effective cap (got ${JSON.stringify(LOG.filter((l) => l.includes('harness concurrency cap')))})`)
    ok(logged('6 of 6 harness slot(s) in flight (this row needs 1) — the harness runs at most 6 agents concurrently'),
        'case 1: a queued row is held on the tighter bound, not the loose 16')
    for (const r of rowsOf(20)) await finish(r.step)
    await run
}

// ---- (2) harnessCap of exactly 16, or absent, behaves like the pre-fix
// unconditional 16 ---------------------------------------------------------
{
    const run = start(rowsOf(20), 16)
    await settle()
    ok(SPAWNED.length === 16, `case 2a: harnessCap=16 admits exactly 16 of 20 (got ${SPAWNED.length})`)
    ok(!logged('harness concurrency cap — conductor reported'),
        'case 2a: no cap-override line when harnessCap equals the ceiling (nothing to narrow)')
    for (const r of rowsOf(20)) await finish(r.step)
    await run
}
{
    const run = start(rowsOf(20), undefined)
    await settle()
    ok(SPAWNED.length === 16, `case 2b: no harnessCap in args admits exactly 16 of 20, same as before this fix (got ${SPAWNED.length})`)
    ok(logged('no harnessCap in args, using the 16-agent ceiling'),
        'case 2b: the log says the loose bound is in force, advisory rather than a silent default')
    for (const r of rowsOf(20)) await finish(r.step)
    await run
}

// ---- (3) a harnessCap ABOVE 16 is clamped to 16, never used to admit past
// this script's own hard ceiling -------------------------------------------
{
    const run = start(rowsOf(20), 64)
    await settle()
    ok(SPAWNED.length === 16,
        `case 3: harnessCap=64 still admits only 16 — clamped to the HARNESS_CAP ceiling (got ${SPAWNED.length})`)
    ok(logged('conductor reported 64') && logged('clamped to the 16-agent ceiling'),
        `case 3: the log names both the reported and the clamped figure (got ${JSON.stringify(LOG.filter((l) => l.includes('harness concurrency cap')))})`)
    for (const r of rowsOf(20)) await finish(r.step)
    await run
}

// ---- (4) malformed harnessCap values fall back to 16, never crash or
// admit zero -----------------------------------------------------------
for (const [label, value] of [['zero', 0], ['negative', -3], ['non-integer', 2.5], ['string', '8']]) {
    const run = start(rowsOf(20), value)
    await settle()
    ok(SPAWNED.length === 16,
        `case 4 (${label}): a malformed harnessCap (${JSON.stringify(value)}) falls back to 16, never 0 or a crash (got ${SPAWNED.length})`)
    ok(logged('not a positive integer') && logged('ignoring it'),
        `case 4 (${label}): the log says the value was rejected, not silently accepted (got ${JSON.stringify(LOG.filter((l) => l.includes('harness concurrency cap')))})`)
    for (const r of rowsOf(20)) await finish(r.step)
    await run
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
