#!/bin/bash

# Behavior suite for wave.js's token-budget check: the session's own
# output-token target ("+500k"-style directive), read from the `budget`
# global, gates admission the same way the agent-count budget does.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. wave.js never read the `budget` global at all before this
# fix. Under a token target, an agent() call made after the target is
# exhausted throws (documented: "once spent() reaches total, further
# agent() calls throw"), and that throw was landing in spawn's catch as a
# bare spawn error — read by the conductor as a dead executor to reap,
# never as a budget deferral it should wait out or the operator should
# raise. This is a DIFFERENT budget from AGENT_BUDGET (which counts agent()
# CALLS against the Workflow tool's 1000-agent lifetime cap): this one
# counts TOKENS spent across the whole turn, pooled across the main loop
# and every workflow, and is checked once the target is already exhausted
# (<= 0), not projected forward the way agentCost() projects AGENT_BUDGET,
# since a script cannot know a call's token cost before it runs.
#
# WHAT IS PINNED HERE. (1) no budget.total set (the ordinary case) never
# gates anything — remaining() is Infinity; (2) a set budget.total with
# remaining() > 0 admits normally; (3) a set budget.total with
# remaining() <= 0 defers a row to 'not-launched-token-budget', logging the
# spend, and never admits it; (4) the summary log line at wave end reports
# spend only when a target was set at all; (5) a token-budget deferral
# marks the row's issue dead the same way an agent-budget deferral does, so
# later same-issue rows are skipped-chain-dead this wave, not spawned into
# a refusal.
#
# HOW. Like tests/wave-harness-cap.test.sh, wraps the extracted stage-ladder
# region in an async function with stub spawn/runGate/probe/parallel/log/
# budget globals; `budget` is reassigned per case (the region reads it as a
# plain identifier, not through `input`, so the test harness must expose a
# mutable one).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-token-budget.XXXXXX") || fatal "mktemp failed"
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
grep -q "'token-budget'" "${WORK}/ladder.js" || fatal "stage-ladder region no longer resolves 'token-budget' — has the token-budget check changed shape?"
grep -q "not-launched-token-budget" "${WORK}/ladder.js" || fatal "stage-ladder region does not settle not-launched-token-budget"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
let rows = []
let input = {}
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
// budget is REASSIGNED per case below (unlike the sibling ladder tests,
// which stub it once with no target and never touch it again) — this
// suite is specifically about what wave.js does when budget.total varies.
let budget = { total: null, spent: () => 0, remaining: () => Infinity }
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
const start = (theRows, budgetOverride) => {
    rows = theRows
    input = {}
    budget = budgetOverride || { total: null, spent: () => 0, remaining: () => Infinity }
    SPAWNED = []; GATES = []; PROBED = []; LOG.length = 0
    RESULTS = new Map()
    HOLD = new Set()   // nothing held in this suite — every row settles immediately
    OPEN = new Map()
    return ladder()
}
const logged = (frag) => LOG.some((l) => l.includes(frag))
const ex = (step, issue, stage) => ({
    step, issue, stage, kind: 'executor', executor: 'research', class: 'research',
})

// ---- (1) no budget.total set: never gates anything -----------------------
{
    const out = await start([ex('A-0', 'ISS-1', 0)])
    ok(SPAWNED.includes('A-0'), 'case 1: with no target set, the row admits normally')
    ok(out[0].status === 'returned', `case 1: the row settles returned (got ${out[0].status})`)
    ok(!logged('token budget'), 'case 1: no token-budget line is logged when no target was ever set')
}

// ---- (2) budget.total set, remaining() > 0: admits normally --------------
{
    const out = await start([ex('B-0', 'ISS-2', 0)],
        { total: 500000, spent: () => 100000, remaining: () => 400000 })
    ok(SPAWNED.includes('B-0'), 'case 2: with headroom remaining, the row admits normally')
    ok(out[0].status === 'returned', `case 2: the row settles returned (got ${out[0].status})`)
    ok(logged('token budget — 100000 of 500000 spent'),
        `case 2: the summary line reports spend when a target was set (got ${JSON.stringify(LOG.filter((l) => l.includes('token budget')))})`)
}

// ---- (3) budget.total set, remaining() <= 0: defers, never admits --------
{
    const out = await start([ex('C-0', 'ISS-3', 0)],
        { total: 500000, spent: () => 500000, remaining: () => 0 })
    ok(!SPAWNED.includes('C-0'), 'case 3: with the target exhausted, the row is never spawned')
    ok(out[0].status === 'not-launched-token-budget',
        `case 3: the row settles not-launched-token-budget (got ${out[0].status})`)
    ok(logged('not launched — token budget: the session\'s target is exhausted (500000 of 500000 spent)'),
        `case 3: the log names the exhausted target with the exact spend (got ${JSON.stringify(LOG.filter((l) => l.includes('token budget')))})`)
}

// ---- (4) summary line reports the deferred count -------------------------
{
    await start([ex('D-0', 'ISS-4', 0), ex('D-1', 'ISS-5', 0)],
        { total: 100, spent: () => 100, remaining: () => 0 })
    ok(logged('token budget — 100 of 100 spent this turn; 2 row(s) deferred to the next dispatch for want of budget'),
        `case 4: the wave-end summary names the deferred count (got ${JSON.stringify(LOG.filter((l) => l.includes('token budget —')))})`)
}

// ---- (5) a token-budget deferral kills the issue's later rows this wave --
{
    const out = await start(
        [ex('E-0', 'ISS-6', 0), ex('E-1', 'ISS-6', 1)],
        { total: 10, spent: () => 10, remaining: () => 0 })
    ok(out[0].status === 'not-launched-token-budget', `case 5: the stage-0 row defers (got ${out[0].status})`)
    ok(out[1].status === 'skipped-chain-dead',
        `case 5: the same issue's later stage is skipped-chain-dead this wave, never spawned into a refusal (got ${out[1].status})`)
    ok(!SPAWNED.includes('E-1'), 'case 5: E-1 was never actually spawned')
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
