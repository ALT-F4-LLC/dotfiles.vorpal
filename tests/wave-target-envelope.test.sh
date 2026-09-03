#!/bin/bash

# Behavior suite for the target ref a judge is briefed with, and for the
# envelope the fix-round ancestry guard reads it through.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. One wave's target read was `docket step context … | grep
# -Eo '"target_(sha|worktree)"…'`, whose ONLY output on a bundle carrying no
# round record is nothing at all — and the probe brief tells its haiku seat to
# "return its output VERBATIM as your entire final reply". The seat's own
# thinking read "since there's no output and no error, I should return
# nothing", and its reply then carried a 40-hex sha that exists in no
# repository and in no transcript except that reply and the three judge briefs
# rendered from it. wave.js briefed all three security-vote seats with it as
# "TARGET SHA: … — the commit the diff under this gate stood at", and three
# opus judges spent calls hunting a phantom commit. The same probe on the same
# empty result behaved three different ways across three waves of that one run
# (silent, fabricating, and chatty): THE EMPTY VERBATIM VOID IS THE DEFECT,
# the model behaviour is weather.
#
# Measured on the machine that filed it: 22 target probes across every
# recorded wave, ZERO of which relayed a real target and ONE of which invented
# one.
#
# THE NETS, one case group each below:
#   1. The ancestry guard's probe command prints a deterministic envelope
#      either way — jq emits {"target_sha":null,"target_worktree":null} when
#      the field is absent — and the reply is read STRUCTURALLY (JSON.parse
#      of that envelope), never by regex over free text.
#   2. The gate path spends NO target probe at all: `docket gate status`
#      carries the target on the same schema-validated envelope the gate
#      already reads, and a gate without one briefs "NO target ref".
#   3. Nothing writes `TARGET SHA:` into a seat brief unless the sha is the
#      full 40-hex object id; otherwise the brief says "NO target ref" in as
#      many words.
#
# HOW. wave.js fences the ancestry helpers in TEST-BEGIN/TEST-END
# `target-envelope`, the brief renderer in `seat-brief`, and the gate driver
# in `gate-vote`. This suite extracts all three, stubs the agent per spawn
# label, and asserts on the probes spent, the log, and the literal brief text
# handed to each seat.
#
# WHAT THIS SUITE CANNOT SEE: the real haiku probe (whether jq is installed on
# the machine it runs on, and what a model does with an envelope once it HAS
# one to relay) is outside wave.js. What wave.js controls, and what this pins,
# is the command it asks for, what it will accept back, and what reaches a
# judge.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-target-envelope.XXXXXX") || fatal "mktemp failed"
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
extract seat-brief       > "${WORK}/brief.js"      || fatal "bad or missing TEST markers for seat-brief"
extract gate-vote        > "${WORK}/gate.js"       || fatal "bad or missing TEST markers for gate-vote"
extract target-envelope  > "${WORK}/envelope.js"   || fatal "bad or missing TEST markers for target-envelope"
[ -s "${WORK}/brief.js" ] || fatal "extracted seat-brief region is empty"
grep -q 'seatBrief'          "${WORK}/brief.js"    || fatal "seat-brief region does not contain seatBrief"
grep -q 'readTargetEnvelope' "${WORK}/envelope.js" || fatal "target-envelope region does not carry readTargetEnvelope"
grep -q 'gateTarget'         "${WORK}/gate.js"     || fatal "gate-vote region does not contain gateTarget"

{
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
const resolveSeat = (seat) => ({ seat, variant: 'std', model: 'stub-model', effort: 'low' })
// The only global the brief renderer reaches for.
const lensOf = (seat) => ({ role: 'stub', text: 'STUB LENS.' })
// Every brief handed to a seat, by spawn label — this is the surface a judge
// actually reads.
let BRIEFS = {}
let SCRIPT = {}
let CALLS = []
const agent = (brief, opts) => {
    BRIEFS[opts.label] = brief
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    const item = Array.isArray(entry) ? entry.shift() : entry
    if (item === undefined) return Promise.resolve(opts.schema ? null : '')
    if (item.reject !== undefined) return Promise.reject(new Error(item.reject))
    return Promise.resolve(item.text)
}
JS
    cat "${WORK}/classifier.js"
    cat "${WORK}/brief.js"
    cat "${WORK}/gate.js"
    cat "${WORK}/envelope.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// The run's own numbers, so a reader can chase them.
const PHANTOM = '3ee9ca3cc3f5ada37eb46768efaebe0bea6a02ca'
const REAL    = 'a6533be112700bd1c5e0e7c5f0d4a53a4b2c7f19'
const VOTERS = ['judge-security', 'judge-architecture', 'judge-correctness']
const ROW = {
    step: 'STEP-3187', kind: 'vote', issue: 'VPL-711', run: 'RUN-63',
    instance: 'security-vote@1', stage: 1,
    voters: VOTERS,
    voter_assignments: VOTERS.map((voter) => ({ voter, model: 'opus', effort: 'high', variant: 'opus-high' })),
}
const SEAT = { seat: 'judge-security', variant: 'std', model: 'm', effort: 'low' }
const envelope = (sha, worktree) => JSON.stringify({
    target_sha: sha === undefined ? null : sha,
    target_worktree: worktree === undefined ? null : worktree,
})
// `docket gate status` envelopes, before and after the panel.
const open = (target) => ({
    step_status: 'ready', proposal: 'DKT-V304', outcome: 'open',
    missing_seats: VOTERS, ...(target ? { target } : {}),
})
const APPROVED = { step_status: 'done', proposal: 'DKT-V304', outcome: 'approved', missing_seats: [] }
const CAST = {
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:outcome': { text: APPROVED },
}

const run = async (script) => {
    SCRIPT = script
    CALLS = []
    BRIEFS = {}
    LOG.length = 0
    return runGate(ROW, 'stage 1 (1 row)')
}
const calls = (label) => CALLS.filter((c) => c === label).length
const seatBriefs = () => Object.keys(BRIEFS)
    .filter((k) => k.includes('seat:'))
    .map((k) => BRIEFS[k])

// ======= NET 1: the ancestry guard's envelope, read structurally =======

ok(parseTargetRef('') === null, 'parseTargetRef("") is no target')
ok(parseTargetRef(envelope()) === null,
    'parseTargetRef({"target_sha":null,"target_worktree":null}) is no target')
ok(parseTargetRef(
       'Since there was no output and no error, the target sha is ' +
       `${PHANTOM} on worktree feature/parallelism.`) === null,
    'parseTargetRef(free prose naming a 40-hex sha) is no target')
// The fabricated reply verbatim: a bare pair of JSON-ish lines, no object at all.
ok(parseTargetRef(
       `"target_sha": "${PHANTOM}"\n"target_worktree": "feature/parallelism"`) === null,
    'parseTargetRef refuses the actual fabricated reply — no object, no parse')
ok(parseTargetRef(null) === null && parseTargetRef(undefined) === null,
    'parseTargetRef survives a dead probe (null/undefined)')

// `parsed` separates "the probe answered, there is no target" from "the probe
// did not answer the question" — the two get DIFFERENT log lines.
ok(readTargetEnvelope(envelope()).parsed === true &&
   readTargetEnvelope(envelope()).target === null,
    'readTargetEnvelope: the null envelope parsed, and named no target')
ok(readTargetEnvelope('').parsed === false &&
   readTargetEnvelope('not json').parsed === false &&
   readTargetEnvelope('[1,2]').parsed === false &&
   readTargetEnvelope('{"target_sha":"x"}').parsed === false,
    'readTargetEnvelope: empty, prose, an array, and a half-envelope all fail to parse')
ok(readTargetEnvelope(`banner text\n${envelope(REAL, '/w')}`).parsed === true &&
   readTargetEnvelope(`banner text\n${envelope(REAL, '/w')}`).target.sha === REAL,
    'readTargetEnvelope still reads an envelope behind a harness banner')

// The command prints an envelope whether or not a target exists.
ok(targetRefCommand('STEP-3187').startsWith('docket step context STEP-3187 --json |'),
    'targetRefCommand reads the step context bundle')
ok(/jq -c/.test(targetRefCommand('STEP-3187')) &&
   targetRefCommand('STEP-3187').includes('// null') &&
   !/grep/.test(targetRefCommand('STEP-3187')),
    'targetRefCommand is the jq envelope with null defaults — no grep, no empty output')

// ======= NET 2: the gate path spends no target probe at all =======

// AC: a vote row whose gate envelope carries no target. Nothing else is
// probed for one, the log says so, and the seats are briefed with the
// NO-target wording.
const A = await run({
    'STEP-3187 · gate:status': { text: open(null) },
    ...CAST,
})
ok(!CALLS.some((c) => /target/.test(c)),
    `AC: no target probe of any kind is spawned on the gate path (got ${JSON.stringify(CALLS)})`)
ok(LOG.some((l) => l.includes('NO target ref on the gate')),
    `AC: the wave log says the gate carried no target (got ${JSON.stringify(LOG)})`)
ok(seatBriefs().length === 3 &&
   seatBriefs().every((b) => b.includes('NO target ref')),
    'AC: every seat brief carries the NO target ref wording')
ok(seatBriefs().every((b) => !/TARGET SHA:/.test(b)),
    'AC: and not one brief carries a TARGET SHA: line')
ok(seatBriefs().every((b) => !/[0-9a-f]{40}/.test(b)),
    'AC: no 40-hex sha appears anywhere in any brief')
ok(A.status === 'gate-passed' && A.spawn_accounting === '3 seats, 2 probes, 0 retries',
    `AC: the gate passes on two reads — status and outcome (got ${JSON.stringify(A.spawn_accounting)})`)

// ======= NET 3: nothing unvouched reaches a judge =======

// A target the engine carries on the envelope reaches the seats.
const B = await run({
    'STEP-3187 · gate:status': { text: open({ sha: REAL, worktree: '/w/vpl-711' }) },
    ...CAST,
})
ok(seatBriefs().length === 3 &&
   seatBriefs().every((b) => b.includes(`TARGET SHA:     ${REAL}`)),
    'a sha the engine carries is named in every brief')
ok(seatBriefs().every((b) => b.includes('/w/vpl-711') && !b.includes('NO target ref')),
    'the worktree rides with it, and the NO-target wording is suppressed')
ok(LOG.some((l) => l.includes('seating') && l.includes(REAL)),
    'the wave log names the target it seated on')
ok(B.status === 'gate-passed' && B.spawn_accounting === '3 seats, 2 probes, 0 retries',
    'the target costs no extra probe')

// A sha that is not the full object id is refused, whatever the envelope
// says — an abbreviation, uppercase hex, prose.
for (const [label, sha] of [
    ['abbreviated', REAL.slice(0, 12)],
    ['uppercase', REAL.toUpperCase()],
    ['prose', `the commit is ${REAL}`],
]) {
    const R = await run({
        'STEP-3187 · gate:status': { text: open({ sha, worktree: '' }) },
        ...CAST,
    })
    ok(seatBriefs().every((b) => !b.includes(sha) && b.includes('NO target ref')) && R.status === 'gate-passed',
        `a ${label} sha on the envelope never reaches a seat, and the gate still passes`)
}

// The worktree half stands alone when only it is carried.
const D = await run({
    'STEP-3187 · gate:status': { text: open({ sha: '', worktree: '/w/vpl-711' }) },
    ...CAST,
})
ok(seatBriefs().every((b) => b.includes('TARGET WORKTREE:/w/vpl-711') && !/TARGET SHA:/.test(b)),
    'a worktree-only target names the worktree and no sha')
ok(D.status === 'gate-passed', 'and does not disturb the gate outcome')

// ---- gateTarget, on its own ----
ok(gateTarget({}) === null && gateTarget({ target: null }) === null &&
   gateTarget({ target: 'x' }) === null,
    'gateTarget: no target field, a null one, and a non-object are no target')
ok(gateTarget({ target: { sha: '', worktree: '' } }) === null,
    'gateTarget: an envelope naming neither half is no target')
ok(gateTarget({ target: { sha: REAL, worktree: '/w' } }).sha === REAL,
    'gateTarget: a 40-hex sha survives')
ok(gateTarget({ target: { sha: PHANTOM.slice(0, 12), worktree: '/w' } }).sha === '' &&
   gateTarget({ target: { sha: PHANTOM.slice(0, 12), worktree: '/w' } }).worktree === '/w',
    'gateTarget: an abbreviated sha is dropped while the worktree stays')
ok(gateTarget({ target: { sha: REAL.toUpperCase(), worktree: '' } }) === null,
    'gateTarget: an uppercase sha is refused — the engine records lowercase hex')

// ---- seatBrief's own shape check, behind the call site ----
const briefWith = (t) => seatBrief(SEAT, 'DKT-V304', ROW, false, null, t)
ok(!briefWith({ sha: PHANTOM.slice(0, 12), worktree: '' }).includes('TARGET SHA:'),
    'seatBrief refuses a non-40-hex sha even if a caller routes around the gate path')
ok(briefWith({ sha: PHANTOM.slice(0, 12), worktree: '' }).includes('NO target ref'),
    'and says NO target ref instead')
ok(briefWith(null).includes('NO target ref') &&
   briefWith(null).includes('read your own HEAD'),
    'seatBrief(no target) tells the seat to read its own HEAD')
ok(!/[0-9a-f]{40}/.test(briefWith(null)),
    'a no-target brief contains no 40-hex string at all')
ok(briefWith({ sha: REAL, worktree: '' }).includes(`TARGET SHA:     ${REAL}`) &&
   !briefWith({ sha: REAL, worktree: '' }).includes('NO target ref'),
    'a 40-hex sha renders the target block, and suppresses the NO-target wording')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
