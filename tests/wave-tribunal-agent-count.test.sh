#!/bin/bash

# Behavior suite for wave.js's agentsLaunched accounting across the nested
# tribunal.js workflow() boundary.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. wave.js seats a vote row's judge panel by calling
# `workflow({scriptPath: args.tribunal}, ...)`, one level of nesting deep. The
# Workflow tool documents that a nested workflow() shares its parent's agent
# counter and concurrency cap, so every seat tribunal.js spawns is a real
# agent() call against THIS wave invocation's 1000-call lifetime cap — but
# wave.js's own `countedAgent()` never runs for those calls, since they
# happen inside the child. Before this fix, wave.js's `agentsLaunched` total
# (the number the invocation logs at close, and the number AgentCapError
# compares against) counted only its OWN probe/executor agent() calls and
# silently undercounted by every seat and seat re-spawn any vote row seated.
# tribunal.js's mid-wave reply already carries `seatsSpawned` — exactly the
# number of Judge-phase agent() calls it made — so folding that into
# agentsLaunched after each seatPanel() call is the fix; this suite pins
# that it actually happens, for both the initial seating and a re-seat, and
# that a `workflow()` throw (tribunal.js never ran) adds nothing.
#
# HOW. Same extraction and stub pattern as tests/wave-vote-retry-report.test.sh
# (configuration, classifier-retry, park-signals, chain-dead, gate-vote
# regions; a scripted `agent`/`workflow` pair), but each case resets
# `agentsLaunched` to a known baseline before calling runGate(), and isolates
# the SEAT-ONLY contribution by also tracking every real countedAgent() probe
# call (via the same CALLS log the spawn_accounting suite uses) and
# subtracting that count from the total rise: (agentsLaunched rise) minus
# (probe calls) is exactly what seatPanel()'s fold-in added, independent of
# how many probes a given gate path happens to spend. Sharing accumulated
# `agentsLaunched` state across cases the way the spawn_accounting suite does
# would make this suite's assertions order-dependent (that suite never reads
# agentsLaunched, so accumulation is harmless there); resetting the baseline
# per case avoids that.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-tribunal-agent-count.XXXXXX") || fatal "mktemp failed"
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

extract configuration    > "${WORK}/configuration.js" || fatal "bad or missing TEST markers for configuration"
extract classifier-retry > "${WORK}/classifier.js"     || fatal "bad or missing TEST markers for classifier-retry"
extract park-signals     > "${WORK}/park.js"           || fatal "bad or missing TEST markers for park-signals"
extract chain-dead       > "${WORK}/chain.js"          || fatal "bad or missing TEST markers for chain-dead"
extract gate-vote        > "${WORK}/gate.js"           || fatal "bad or missing TEST markers for gate-vote"
[ -s "${WORK}/gate.js" ] || fatal "extracted gate-vote region is empty"
grep -q 'runGate' "${WORK}/gate.js" || fatal "gate-vote region does not contain runGate"
grep -q 'agentsLaunched +=' "${WORK}/gate.js" || fatal "gate-vote region no longer folds tribunal's seatsSpawned into agentsLaunched — has seatPanel() changed shape?"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
const voterToSeat = (seat) => ({ seat, variant: 'std', model: 'stub-model', effort: 'low' })
const args = { tribunal: '/stub/tribunal.js', cwd: '/repo' }
let SCRIPT = {}
let CALLS = []
const agent = (brief, opts) => {
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    const item = Array.isArray(entry) ? entry.shift() : entry
    if (item === undefined) return Promise.resolve(opts.schema ? null : '')
    if (item.reject !== undefined) return Promise.reject(new Error(item.reject))
    return Promise.resolve(item.text)
}
// WORKFLOW_SCRIPT: {seatsSpawned, absorbed} for a clean reply, or
// {throwErr} to make the whole workflow() call reject (tribunal.js never
// ran, so it must add nothing to agentsLaunched).
let WORKFLOW_SCRIPT = {}
let WORKFLOW_CALLS = []
const workflow = (path, a) => {
    WORKFLOW_CALLS.push({ voters: a.voters.map((v) => v.seat), isRespawn: Boolean(a.isRespawn) })
    if (WORKFLOW_SCRIPT.throwErr !== undefined) return Promise.reject(new Error(WORKFLOW_SCRIPT.throwErr))
    const reply = Array.isArray(WORKFLOW_SCRIPT.replies) ? WORKFLOW_SCRIPT.replies.shift() : WORKFLOW_SCRIPT.replies
    return Promise.resolve(reply !== undefined ? reply : { voteId: a.voteId, seatsSpawned: a.voters.length, absorbed: [] })
}
JS
    cat "${WORK}/classifier.js"
    cat "${WORK}/park.js"
    cat "${WORK}/chain.js"
    cat "${WORK}/gate.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const VOTERS = ['judge-architecture', 'judge-security', 'judge-correctness']
const routed = (voter) => ({ voter, model: 'opus', effort: 'high', variant: 'opus-high' })
const ROW = {
    step: 'STEP-9001', kind: 'vote', issue: 'DOT-1', run: 'RUN-1',
    instance: 'gate@1', stage: 1,
    voters: VOTERS,
    voter_assignments: VOTERS.map(routed),
}
const envelope = (step_status, outcome, missing, extra) => ({
    step_status, outcome,
    proposal: 'DKT-V1',
    tally: { weighted_score: outcome === 'open' ? null : 1.0, threshold: 0.67 },
    seats: VOTERS.map((v) => ({ voter: v, cast: !missing.includes(v), verdict: missing.includes(v) ? undefined : 'approve' })),
    missing_seats: missing,
    ...(extra || {}),
})
const OPEN_NOBODY = envelope('ready', 'open', VOTERS)
const OPEN_ONE_MISSING = envelope('ready', 'open', ['judge-security'])
const APPROVED = envelope('done', 'approved', [])

// Runs one case and returns the SEAT-ONLY contribution to agentsLaunched:
// (total rise) minus (real countedAgent probe calls this case made, read off
// CALLS — the same stub `agent()` every countedAgent() call in wave.js goes
// through). Isolating it this way makes each assertion independent of how
// many probes a given gate path happens to spend, which is pinned
// separately by tests/wave-vote-retry-report.test.sh and is not this
// suite's concern.
const run = async (script, wfScript, baseline) => {
    SCRIPT = script
    WORKFLOW_SCRIPT = wfScript || {}
    WORKFLOW_CALLS = []
    CALLS = []
    LOG.length = 0
    agentsLaunched = baseline
    const res = await runGate(ROW, 'stage 1 (1 row)')
    return { res, seatContribution: agentsLaunched - baseline - CALLS.length }
}

// ---- 1: a clean 3-seat panel, no re-seat — tribunal reports seatsSpawned:3
// and that whole 3 folds into agentsLaunched, on top of whatever the gate's
// own probes separately counted.
{
    const { res, seatContribution } = await run({
        'STEP-9001 · gate:status':  { text: OPEN_NOBODY },
        'STEP-9001 · gate:outcome': { text: APPROVED },
    }, {
        replies: { voteId: 'DKT-V1', seatsSpawned: 3, absorbed: [] },
    }, 100)
    ok(res.status === 'gate-passed', 'case 1: gate passes')
    ok(seatContribution === 3,
        `case 1: the panel's reported seatsSpawned (3) folds into agentsLaunched, beyond the probe count (got ${seatContribution})`)
}

// ---- 2: a re-seat — TWO seatPanel() calls, the initial 3 and a 1-seat
// retry — both contribute, so the seat-only total is 3 (initial) + 1
// (retry) = 4, never just the initial panel and never double-counting the
// retry as a fresh 3.
{
    const { res, seatContribution } = await run({
        'STEP-9001 · gate:status':  { text: OPEN_NOBODY },
        'STEP-9001 · gate:outcome': [{ text: OPEN_ONE_MISSING }, { text: APPROVED }],
    }, {
        replies: [
            { voteId: 'DKT-V1', seatsSpawned: 3, absorbed: [] },
            { voteId: 'DKT-V1', seatsSpawned: 1, absorbed: [] },
        ],
    }, 200)
    ok(res.status === 'gate-passed', 'case 2: gate passes after the re-seat')
    ok(seatContribution === 4,
        `case 2: the seat-only total is 3 (initial) + 1 (re-seat) = 4, never just 3 (got ${seatContribution})`)
}

// ---- 3: workflow() throws — tribunal.js never ran, so nothing was
// actually spawned; the seat-only contribution must be ZERO, not
// incremented by the panel size the caller asked for.
{
    const { res, seatContribution } = await run({
        'STEP-9001 · gate:status': { text: OPEN_NOBODY },
    }, {
        throwErr: 'tribunal.js: args.cwd is required and must be a non-empty string. Refusing to seat the panel.',
    }, 300)
    ok(res.status === 'gate-parked', 'case 3: a workflow() throw settles the row, never crashes the wave')
    ok(seatContribution === 0,
        `case 3: a workflow() throw adds nothing — tribunal.js never ran, so no agent was actually spawned (got ${seatContribution})`)
}

// ---- 4: a reply missing seatsSpawned (a malformed or pre-contract mid-wave
// reply) falls back to the panel size wave.js asked tribunal to seat, never
// to zero — the same fail-open assumption the pre-fix code made implicitly
// for every call.
{
    const { res, seatContribution } = await run({
        'STEP-9001 · gate:status':  { text: OPEN_NOBODY },
        'STEP-9001 · gate:outcome': { text: APPROVED },
    }, {
        replies: { voteId: 'DKT-V1', absorbed: [] },
    }, 400)
    ok(res.status === 'gate-passed', 'case 4: gate passes on a reply with no seatsSpawned field')
    ok(seatContribution === 3,
        `case 4: a missing seatsSpawned falls back to the 3-seat panel size, not 0 (got ${seatContribution})`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
