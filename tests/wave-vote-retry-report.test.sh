#!/bin/bash

# Behavior suite for wave.js's vote-gate path: what a vote row costs in
# read-only probes, and how the wave reports the noise it absorbed.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. One run's vote gate tallied APPROVED 3/3, yet the
# completion notification carried a failures entry — "[STEP-N · gate:tally]
# failed: API Error: Connection lost mid-response" — beside the same step's
# gate-passed verdict, and the 8-spawns-for-3-seats cost was visible nowhere.
# The failure was retry noise the script had already absorbed; a failure
# entry beside a success verdict for the same step is exactly the shape a
# conductor misreads as a failed gate. So when a vote row's tally SUCCEEDS,
# absorbed agent-level errors ride the success result as `notes` (each
# naming the tally's success), seat/probe/retry accounting is reported
# explicitly (`spawn_accounting`) with seats and probes in SEPARATE buckets,
# and nothing failure-shaped is attached; a tally that FAILS keeps its errors
# as real failures, un-softened.
#
# THE ONE-VERB READ. A vote row used to cost three to five relayed probes —
# step show, a vote-show projection, a second step show for the outcome, a
# tally re-read, a target read — each retyped by a haiku seat and rescued by
# regex when the retype was corrupt (one relay lost its closing brace,
# another 81 chars mid-body). `docket gate status STEP-N --json` answers all
# of it in one envelope under 1 KB, returned through a StructuredOutput
# schema the harness validates, so the gate path holds NO regex over relayed
# engine JSON at all. The counts this suite measures are the authority, and
# `meta.description` in wave.js must state them; the postscript below
# cross-checks the prose against the cases so the two cannot drift:
#   1 probe on a gate already decided when the wave reaches it (case C),
#   2 on the normal path — one before the panel seats, one after (case E),
#   3 when a re-seat forces a re-read (case A's healthy re-seat).
#
# HOW. wave.js fences the gate machinery (probeBrief, probe, gateStatus,
# gateTarget, heldCluster, gateSuccess, runGate) in TEST-BEGIN/TEST-END
# `gate-vote` markers. This suite extracts that region, prepends the
# classifier-retry region (reasonText and the block regexes the probe retry
# reads) and stub `agent`/`parallel`/`log`/`workflow`/`voterToSeat` globals,
# scripts the agent per spawn label and the workflow stub per voter list,
# and asserts on the result runGate returns. park-signals and chain-dead are
# extracted too so the suite can prove the success result does not trip
# either predicate, and that the blocked path still hands the ladder the
# engine's blocked_reason.
#
# THE PANEL ITSELF IS TRIBUNAL.JS'S: runGate calls `workflow(args.tribunal,
# {...})` one level deep rather than rendering and spawning a seat brief
# in-process (DOT-1300 folded the seat contract into tribunal.js, reached
# from wave.js exactly this way). This suite stubs `workflow` to return
# {absorbed: [...]} shaped like tribunal.js's mid-wave reply, so it pins
# what wave.js does with that reply — the probe/seat/retry accounting, the
# log lines, the folded absorbed-error notes — without re-deriving
# tribunal.js's own seat-spawn logic, which tests/tribunal-seat-brief.test.sh
# and tests/wave-target-envelope.test.sh pin directly against tribunal.js.
#
# WHAT THIS SUITE CANNOT SEE: the harness's own per-agent failure accounting
# in the completion notification (agents_error and the "[label] failed: ..."
# lines) is harness behavior, out of wave.js's hands — what wave.js controls,
# and what this suite pins, is the wave's returned result for the step: the
# surface the conductor reads the gate's outcome from.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-vote-retry-report.XXXXXX") || fatal "mktemp failed"
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

extract classifier-retry > "${WORK}/classifier.js" || fatal "bad or missing TEST markers for classifier-retry"
extract park-signals     > "${WORK}/park.js"       || fatal "bad or missing TEST markers for park-signals"
extract gate-vote        > "${WORK}/gate.js"       || fatal "bad or missing TEST markers for gate-vote"
# chain-dead nests inside stage-ladder; extract it on its own.
extract chain-dead       > "${WORK}/chain.js"      || fatal "bad or missing TEST markers for chain-dead"
[ -s "${WORK}/gate.js" ] || fatal "extracted gate-vote region is empty"
grep -q 'runGate'     "${WORK}/gate.js" || fatal "gate-vote region does not contain runGate"
grep -q 'gateSuccess' "${WORK}/gate.js" || fatal "gate-vote region does not contain gateSuccess"

{
    # --- stub workflow globals the gate region reaches for ---
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
const voterToSeat = (seat) => ({ seat, variant: 'std', model: 'stub-model', effort: 'low' })
// The real wave.js reads `args.tribunal` (the installed tribunal.js path) and
// `args.cwd` off its own top-level `args` global — the workflow's own input.
const args = { tribunal: '/stub/tribunal.js', cwd: '/repo' }
// The scripted agent: SCRIPT maps a spawn label to one response or an array
// of responses consumed in order — {text: ...} resolves with that value (a
// string for a text probe, an object for a schema probe), {reject: ...}
// rejects with an Error carrying that message. An unlisted label resolves
// '' for a text probe and null for a schema probe — a dead spawn either way.
let SCRIPT = {}
let CALLS = []
let SCHEMAS = {}
const agent = (brief, opts) => {
    CALLS.push(opts.label)
    if (opts.schema) SCHEMAS[opts.label] = opts.schema
    const entry = SCRIPT[opts.label]
    const item = Array.isArray(entry) ? entry.shift() : entry
    if (item === undefined) return Promise.resolve(opts.schema ? null : '')
    if (item.reject !== undefined) return Promise.reject(new Error(item.reject))
    return Promise.resolve(item.text)
}
// The panel is one workflow-nesting level into tribunal.js. WORKFLOW_SCRIPT
// maps each seat name to one outcome or an array of outcomes consumed in call
// order (a seat can die on its first panel call and cast clean on its
// retry) — {error: ...} models an agent-level death the same shape
// spawnJudge's own catch would have produced; an unlisted or exhausted entry
// "cast" cleanly (absorbed nothing). {throwErr: ...} at the top level of
// WORKFLOW_SCRIPT makes the whole workflow() call reject, modeling an
// unreadable tribunal.js path or one of its own arg refusals. Every call is
// recorded in WORKFLOW_CALLS as {voters, isRespawn} so the suite can assert
// on what wave.js asked tribunal.js to seat.
let WORKFLOW_SCRIPT = {}
let WORKFLOW_CALLS = []
const workflow = (path, a) => {
    WORKFLOW_CALLS.push({ voters: a.voters.map((v) => v.seat), isRespawn: Boolean(a.isRespawn) })
    for (const v of a.voters) {
        CALLS.push(`${a.step ? a.step.step + ' · ' : ''}seat:${v.seat}${a.isRespawn ? ' (retry)' : ''}`)
    }
    if (WORKFLOW_SCRIPT.throwErr !== undefined) return Promise.reject(new Error(WORKFLOW_SCRIPT.throwErr))
    const absorbed = []
    for (const v of a.voters) {
        const entry = WORKFLOW_SCRIPT[v.seat]
        const item = Array.isArray(entry) ? entry.shift() : entry
        if (item && item.error) absorbed.push({ seat: v.seat, error: item.error })
    }
    return Promise.resolve({ voteId: a.voteId, seatsSpawned: a.voters.length, absorbed })
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
    step: 'STEP-2493', kind: 'vote', issue: 'DOT-1', run: 'RUN-52',
    instance: 'gate@1', stage: 1,
    voters: VOTERS,
    voter_assignments: VOTERS.map(routed),
}
// `docket gate status` envelopes, as the schema probe hands them back.
const envelope = (step_status, outcome, missing, extra) => ({
    step_status, outcome,
    proposal: 'DKT-V260',
    tally: { weighted_score: outcome === 'open' ? null : 1.0, threshold: 0.67 },
    seats: VOTERS.map((v) => ({ voter: v, cast: !missing.includes(v), verdict: missing.includes(v) ? undefined : 'approve' })),
    missing_seats: missing,
    ...(extra || {}),
})
const OPEN_NOBODY   = envelope('ready', 'open', VOTERS)
const OPEN_ONE_MISSING = envelope('ready', 'open', ['judge-security'])
const APPROVED = envelope('done', 'approved', [])
const REJECTED = envelope('done', 'rejected', [])
const NO_PROPOSAL = { step_status: 'pending', outcome: 'open', missing_seats: [] }
const SHOW_BLOCKED = '{"ok":true,"data":{"id":"STEP-2493","status":"pending",' +
    '"blocked_reason":"an `after` predecessor is not done"}}'
const API_ERR = 'API Error: Connection lost mid-response'

const run = async (script, wfScript, row) => {
    SCRIPT = script
    WORKFLOW_SCRIPT = wfScript || {}
    CALLS = []
    WORKFLOW_CALLS = []
    SCHEMAS = {}
    LOG.length = 0
    return runGate(row || ROW, 'stage 1 (1 row)')
}
const calls = (label) => CALLS.filter((c) => c === label).length
const probes = () => CALLS.filter((c) => !c.includes('seat:')).length

// ---- A: one seat's first spawn dies at the agent level and its re-spawn
// casts; the outcome probe dies once and its identical resubmission reads
// the record. The gate SUCCEEDS: the result must carry the accounting and
// the absorbed errors as notes — and nothing failure-shaped.
const A = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · gate:outcome': [{ reject: API_ERR }, { text: OPEN_ONE_MISSING }, { text: APPROVED }],
}, {
    'judge-security': [{ error: API_ERR }, {}],
})
ok(A.status === 'gate-passed', 'A: tally succeeded -> status is gate-passed')
// 3 judges + 4 read-only probes (status, outcome x2 — one died — and the
// re-read after the re-seat); the two retries are the re-seated judge and
// the probe resubmission.
ok(A.spawn_accounting === '3 seats, 4 probes, 2 retries',
    `A: seat/probe/retry accounting is explicit and separated (got ${JSON.stringify(A.spawn_accounting)})`)
ok(!/spawn/.test(A.spawn_accounting),
    'A: probes are never reported as spawns of the panel')
ok(Array.isArray(A.notes) && A.notes.length === 2,
    `A: both absorbed errors ride the success result as notes (got ${JSON.stringify(A.notes)})`)
ok((A.notes || []).every((n) => n.includes('NOT a failure') && n.includes('SUCCEEDED')),
    'A: every note names the tally success and disclaims failure')
ok((A.notes || []).some((n) => n.includes('[STEP-2493 · gate:outcome]') && n.includes(API_ERR)),
    'A: the dead outcome probe is a note, attributed to its spawn label')
ok((A.notes || []).some((n) => n.includes('[STEP-2493 · seat:judge-security]')),
    'A: the dead seat spawn is a note, attributed to its seat label')
ok(A.failures === undefined, 'A: no failures field on the success result')
ok(!/fail/.test(A.status), 'A: nothing failure-shaped in the status')
ok(calls('STEP-2493 · gate:outcome') === 3,
    `A: the outcome probe was resubmitted once and re-read once after the re-seat (got ${calls('STEP-2493 · gate:outcome')})`)
ok(calls('STEP-2493 · seat:judge-security (retry)') === 1, 'A: the missing seat was re-spawned once')
ok(calls('STEP-2493 · seat:judge-architecture (retry)') === 0 &&
   calls('STEP-2493 · seat:judge-correctness (retry)') === 0,
    'A: seats the engine lists as cast are never re-spawned')
ok(chainDead(A) === false, 'A: the success result does not kill the issue chain')
ok(runParked(A) === false, 'A: the success result does not park the run')

// ---- A2: the healthy re-seat — no probe noise — is exactly THREE probes.
const A2 = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'returned without casting' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': [{ text: OPEN_ONE_MISSING }, { text: APPROVED }],
    'STEP-2493 · seat:judge-security (retry)': { text: 'cast recorded' },
})
ok(A2.status === 'gate-passed' && A2.spawn_accounting === '3 seats, 3 probes, 1 retry',
    `AC: a re-seat adds exactly one probe (got ${JSON.stringify(A2.spawn_accounting)})`)
ok(LOG.some((l) => l.includes('1 seat(s) returned without a recorded cast (judge-security)')),
    `A2: the log names the seat the engine listed as missing (got ${JSON.stringify(LOG)})`)

// ---- A3: a seat STILL silent after its retry is named, and the gate is
// decided on the engine's record as it stands.
await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'nothing' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': [{ text: OPEN_ONE_MISSING }, { text: envelope('done', 'approved', ['judge-security']) }],
    'STEP-2493 · seat:judge-security (retry)': { text: 'nothing again' },
})
ok(LOG.some((l) => l.includes('STILL NO CAST from judge-security')),
    `A3: a seat silent after its one re-spawn is named (got ${JSON.stringify(LOG)})`)

// ---- B: the SAME noise as A, but the tally REJECTS. Nothing softens a real
// failure: no notes, no accounting cushion.
const B = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { reject: API_ERR },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': [{ reject: API_ERR }, { text: OPEN_ONE_MISSING }, { text: REJECTED }],
    'STEP-2493 · seat:judge-security (retry)': { text: 'cast recorded' },
})
ok(B.status === 'gate-rejected', 'B: rejected tally -> status is gate-rejected')
ok(B.notes === undefined, 'B: a failing gate gets NO absorbed-error notes')
ok(B.spawn_accounting === undefined, 'B: a failing gate gets NO accounting attachment')
ok(chainDead(B) === true, 'B: the rejection still kills the issue chain')

// ---- C: gate already decided when the wave arrives (early path). ONE
// probe, no panel, so the accounting reports probes and retries ONLY — the
// seats clause is suppressed rather than logging "0 seats".
const C = await run({
    'STEP-2493 · gate:status': { text: APPROVED },
})
ok(C.status === 'gate-passed', 'C: already-decided approved gate is gate-passed')
ok(C.spawn_accounting === '1 probe, 0 retries',
    `AC: a vote row that decides on the first read spawns exactly one probe (got ${JSON.stringify(C.spawn_accounting)})`)
ok(CALLS.length === 1, `C: nothing but that one probe was spawned (got ${JSON.stringify(CALLS)})`)
ok(!/seat/.test(C.spawn_accounting),
    'C: no seats clause at all when no panel was seated')
ok(LOG.some((l) => l.includes('no panel seated — 1 probe, 0 retries')),
    `C: the log line names the empty panel instead of "0 seats" (got ${JSON.stringify(LOG)})`)
ok(C.notes === undefined, 'C: no noise, no notes')

const C2 = await run({
    'STEP-2493 · gate:status': { text: REJECTED },
})
ok(C2.status === 'gate-rejected' && CALLS.length === 1,
    'C2: an already-REJECTED gate is read off the same single probe — a done step is not a pass')

// A step the engine skipped with no tally ever run reports gate-skipped, not
// gate-passed — the exact misread a conductor once made on a security
// tribunal that never sat.
const C3 = await run({
    'STEP-2493 · gate:status': { text: envelope('skipped', 'open', VOTERS) },
})
ok(C3.status === 'gate-skipped' && CALLS.length === 1,
    'C3: a skipped step with an untallied ballot reports gate-skipped, not gate-passed')

// ---- D: a NON-transient classifier block on the outcome probe is
// deterministic on identical bytes — never resubmitted. The tally is then
// UNKNOWN, which is a park for the conductor, not a pass on the step's
// status alone.
const D = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { reject: '[STEP-2493 · gate:outcome] blocked by safety classifier: the brief was refused on content' },
})
ok(calls('STEP-2493 · gate:outcome') === 1, 'D: a content classifier block is NOT resubmitted')
ok(D.status === 'gate-parked' && D.notes === undefined,
    `D: an unreadable tally parks the gate for the conductor, un-softened (got ${D.status})`)
ok(calls('STEP-2493 · seat:judge-security (retry)') === 0 &&
   calls('STEP-2493 · seat:judge-architecture (retry)') === 0,
    'D: an unreadable record re-spawns NOBODY — silence is not "every seat missing"')
ok(LOG.some((l) => l.includes('probe blocked on content')),
    `D: the block is logged as deterministic (got ${JSON.stringify(LOG)})`)

// ---- E: the healthy gate. One read before the panel, one after: TWO probes,
// no re-seat, no fallback line anywhere in the log.
const E = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: APPROVED },
})
ok(E.status === 'gate-passed', 'E: the healthy gate passes')
ok(E.spawn_accounting === '3 seats, 2 probes, 0 retries',
    `E: status + outcome (got ${JSON.stringify(E.spawn_accounting)})`)
ok(probes() === 2, `AC: exactly TWO gate status probes on the normal path (got ${JSON.stringify(CALLS)})`)
ok(!LOG.some((l) => l.includes('did not parse') || l.includes('falling back')),
    `AC: no parse-fallback line on a healthy tally (got ${JSON.stringify(LOG)})`)
ok(SCHEMAS['STEP-2493 · gate:status'] && SCHEMAS['STEP-2493 · gate:status'] === SCHEMAS['STEP-2493 · gate:outcome'],
    'AC: both reads go through the same StructuredOutput schema')
ok(SCHEMAS['STEP-2493 · gate:status'].properties.outcome.enum.join() === 'approved,rejected,open',
    'the schema pins the three-state outcome the engine documents')
ok(LOG.some((l) => l.includes('seating judge-architecture, judge-security, judge-correctness')),
    `E: the panel is seated from the row's routed roster (got ${JSON.stringify(LOG)})`)
ok(calls('STEP-2493 · gate:held-cluster') === 0,
    'E: an ordinary gate never spends the held-cluster read')

// A REJECTED proposal is equally conclusive — one read after the panel.
const E2 = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: REJECTED },
})
ok(E2.status === 'gate-rejected' && probes() === 2,
    'E2: a rejection is read off the same single post-panel probe')

// A gate that did not clear — every seat cast, the ballot still open.
const E3 = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: envelope('ready', 'open', []) },
})
ok(E3.status === 'gate-parked' && LOG.some((l) => l.includes('gate did NOT clear (ready, tally open)')),
    `E3: an undecided ballot parks the gate and the log names the engine's state (got ${JSON.stringify(LOG)})`)

// ---- F: a reply that is not the envelope. The old relays lost a brace or
// 81 chars mid-body and were rescued by regex; a schema reply carries no
// text to regex, so a non-envelope object is UNKNOWN and nothing is
// re-seated off it.
const F = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: {} },
})
ok(F.status === 'gate-parked' && !CALLS.some((c) => c.includes('(retry)')),
    'F: a non-envelope reply parks the gate and re-spawns nobody')
const F2 = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-2493 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-2493 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-2493 · gate:outcome': { text: { error: 'Error: STEP-2493 is a "executor" step, not a gate' } },
})
ok(F2.status === 'gate-parked' && LOG.some((l) => l.includes('engine error — Error: STEP-2493 is a')),
    `F2: an engine error relayed through the schema is logged verbatim (got ${JSON.stringify(LOG)})`)
const F3 = await run({
    'STEP-2493 · gate:status': { text: null },
})
ok(F3.status === 'gate-blocked' && CALLS.length === 1 &&
   LOG.some((l) => l.includes('gate:status probe returned nothing')),
    'F3: a dead first read seats nobody and blocks the lane with the state UNKNOWN')

// ---- G: no proposal yet — the predecessors have not all recorded. The one
// read that carries the engine's blocked_reason is `step show`, spent here
// alone so the ladder can say "deferred" instead of "died".
const G = await run({
    'STEP-2493 · gate:status':  { text: NO_PROPOSAL },
    'STEP-2493 · gate:blocked': { text: SHOW_BLOCKED },
})
ok(G.status === 'gate-blocked' && probes() === 2 && !CALLS.some((c) => c.includes('seat:')),
    `G: a gate with no proposal spends status + step show and seats nobody (got ${JSON.stringify(CALLS)})`)
ok(blockedReason(G) === 'an `after` predecessor is not done',
    `G: the ladder still reads the engine's blocked_reason off the result (got ${JSON.stringify(blockedReason(G))})`)
ok(chainDead(G) === true, 'G: and the lane still stops this wave')

// ---- H: a vote row whose roster carries no routing — the run pins no
// policy.toml, or the row was re-typed — is escalated, never guessed.
const H = await run({
    'STEP-2493 · gate:status': { text: OPEN_NOBODY },
}, {}, { ...ROW, voter_assignments: undefined })
ok(H.status === 'gate-blocked' && CALLS.length === 1 &&
   LOG.some((l) => l.includes('carries no voter_assignments')),
    'H: no voter_assignments -> gate-blocked after the one read, no panel')

// ---- I: an engine-minted held-cluster gate (`<name>-held@N#k`) spends one
// more read to name its cluster; an ordinary gate never does.
const HELD = {
    ...ROW, instance: 'review-held@2#0',
}
const I = await run({
    'STEP-2493 · gate:status':  { text: OPEN_NOBODY },
    'STEP-2493 · gate:held-cluster': { text: { cluster_index: 0, cluster_count: 10, artifact: 'ARTIFACT-1251', producer_step: 'reconcile@2' } },
    'STEP-2493 · gate:outcome': { text: APPROVED },
}, {}, HELD)
ok(I.status === 'gate-passed' && calls('STEP-2493 · gate:held-cluster') === 1 &&
   I.spawn_accounting === '3 seats, 3 probes, 0 retries',
    `I: a held-cluster gate spends exactly one extra read (got ${JSON.stringify(I.spawn_accounting)})`)
ok(calls('STEP-2493 · gate:held-cluster') === 1 && !CALLS.some((c) => c.includes('held') && c !== 'STEP-2493 · gate:held-cluster'),
    'I: the cluster read goes through its own schema probe')
ok(SCHEMAS['STEP-2493 · gate:held-cluster'].properties.cluster_index.type === 'number',
    'I: the held-cluster reply is schema-validated, never regexed out of step show')
ok(parseHeldCluster({ cluster_index: 0, cluster_count: 10, artifact: 'A', producer_step: 'p' }).clusterCount === 10 &&
   parseHeldCluster({ cluster_index: 0 }) === null && parseHeldCluster(null) === null && parseHeldCluster({}) === null,
    'parseHeldCluster accepts the four-field object and nothing less')

// ---- J: the workflow() call into tribunal.js itself throws — an unreadable
// scriptPath, a child syntax error, or tribunal.js refusing its own args.
// That must not crash the wave: no seat can have cast, so the tally reads
// UNKNOWN and the row parks for the conductor, the same as any other
// silent-panel gate, and no other issue's lane is disturbed.
const J = await run({
    'STEP-2493 · gate:status': { text: OPEN_NOBODY },
}, { throwErr: 'tribunal.js: args.cwd is required and must be a non-empty string (got ""). Refusing to seat the panel.' })
ok(J.status === 'gate-parked',
    `J: a workflow() throw never crashes the wave — the tally reads UNKNOWN and the row parks (got ${JSON.stringify(J)})`)
ok(LOG.some((l) => l.includes('tribunal panel spawn error') && l.includes('Refusing to seat the panel')),
    `J: the panel spawn error is logged verbatim (got ${JSON.stringify(LOG)})`)

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
rc=$?

# ---- AC: no regex over relayed engine JSON remains in the gate path ----
# Every field-level regex this path ever carried had the shape `"key"\s*:\s*`;
# the schema reads leave no text to match.
if grep -q '\\s\*:\\s\*' "${WORK}/gate.js"; then
    printf 'FAIL: the gate-vote region still carries a regex over relayed engine JSON:\n' >&2
    grep -n '\\s\*:\\s\*' "${WORK}/gate.js" >&2
    rc=1
else
    printf 'PASS: AC: no regex over relayed engine JSON in the gate-vote region\n'
fi

# ---- the per-vote-row probe cost is DOCUMENTED ----
# The counts above are measured; this asserts wave.js's own meta.description
# states them, so a conductor sizing a dispatch sees the gate overhead without
# reading the gate path. Numbers are matched literally against the cases:
#   C = 1 probe (already-decided), E = 2 (normal), A2 = 3 (re-seat).
DESC=$(awk '/^    description: /{print; exit}' "$WAVE")
dpass=0
dfail=0
dok() { # <cond-exit> <label>
    if [ "$1" -eq 0 ]; then dpass=$((dpass + 1)); printf 'PASS: %s\n' "$2"
    else dfail=$((dfail + 1)); printf 'FAIL: %s\n' "$2" >&2; fi
}
[ -n "$DESC" ]; dok $? 'wave.js meta.description line is readable'
printf '%s' "$DESC" | grep -qi 'probe'; dok $? \
    'meta.description mentions the probe cost per vote row at all'
printf '%s' "$DESC" | grep -q '2 read-only haiku probes'; dok $? \
    'it names the 2-probe normal path (case E measured 2 probes)'
printf '%s' "$DESC" | grep -q '1 on a gate that was already decided'; dok $? \
    'it names the 1-probe already-decided path (case C measured 1 probe)'
printf '%s' "$DESC" | grep -q '3 when a re-seat'; dok $? \
    'it names the 3-probe re-seat path (case A2 measured 3 probes)'
printf '%s' "$DESC" | grep -q 'gate status'; dok $? \
    'it names the verb so the count can be audited'
# The pre-collapse numbers must not be restated as current.
printf '%s' "$DESC" | grep -qE 'five to eight|5-8 probes|3 read-only haiku|up to 5|gate:show'; [ $? -ne 0 ]; dok $? \
    'and it does NOT restate the pre-collapse figures'

printf '\n%s passed, %s failed (meta.description probe accounting)\n' "$dpass" "$dfail"
[ "$dfail" -eq 0 ] || rc=1
exit "$rc"
