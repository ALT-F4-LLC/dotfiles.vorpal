#!/bin/bash

# Behavior suite for wave.js's gate:target probe and the seat brief it feeds
# (DOT-1040).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. RUN-63 (vorpal.git, DISPATCH-363, wave wf_48ebd80d-906,
# STEP-3187). The gate path's target read was `docket step context … | grep
# -Eo '"target_(sha|worktree)"…'`, whose ONLY output on a bundle carrying no
# round record is nothing at all — and the probe brief tells its haiku seat to
# "return its output VERBATIM as your entire final reply". The seat's own
# thinking read "since there's no output and no error, I should return
# nothing", and its reply then carried
# `"target_sha": "3ee9ca3cc3f5ada37eb46768efaebe0bea6a02ca"` /
# `"target_worktree": "feature/parallelism"` — a 40-hex sha that exists in no
# repository and in no transcript except that reply and the three judge briefs
# rendered from it. wave.js briefed all three security-vote seats with it as
# "TARGET SHA: … — the commit the diff under this gate stood at", and three
# opus judges spent calls hunting a phantom commit. The same probe on the same
# empty result behaved three different ways across three waves of that one run
# (silent, fabricating, and chatty): THE EMPTY VERBATIM VOID IS THE DEFECT,
# the model behaviour is weather.
#
# Measured on the machine that filed it: 22 gate:target probes across every
# recorded wave, ZERO of which relayed a real target and ONE of which invented
# one.
#
# THE THREE NETS, one case group each below:
#   1. The probe command prints a deterministic envelope either way — jq emits
#      {"target_sha":null,"target_worktree":null} when the field is absent —
#      and the reply is read STRUCTURALLY (JSON.parse of that envelope), never
#      by regex over free text.
#   2. The spawn is skipped outright when the gate's own `step show` payload,
#      already in hand, carries no target field at all.
#   3. Nothing writes `TARGET SHA:` into a seat brief unless the sha is 40-hex
#      AND occurs in text the wave read for itself; otherwise the brief says
#      "NO target ref" in as many words.
#
# HOW. wave.js fences the shared helpers in TEST-BEGIN/TEST-END
# `target-envelope` (nested inside `gate-vote`, and prepended by the
# fix-round-ancestry suites, which share the same command), the brief renderer
# in `seat-brief`, and the gate driver in `gate-vote`. This suite extracts all
# three, stubs the agent per spawn label, and asserts on the probes spent, the
# log, and the literal brief text handed to each seat.
#
# WHAT THIS SUITE CANNOT SEE: the real haiku probe (whether jq is installed on
# the machine it runs on, and what a model does with the envelope once it HAS
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
[ -s "${WORK}/brief.js" ] || fatal "extracted seat-brief region is empty"
grep -q 'seatBrief'          "${WORK}/brief.js" || fatal "seat-brief region does not contain seatBrief"
grep -q 'readTargetEnvelope' "${WORK}/gate.js"  || fatal "gate-vote region does not carry the target-envelope helpers"

{
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
const policy = {}
const labelsOf = () => []
const resolveSeat = (seat) => ({ seat, variant: 'std', model: 'stub-model', effort: 'low' })
// The only global the brief renderer reaches for.
const lensOf = (seat) => ({ role: 'stub', text: 'STUB LENS.' })
// Every brief handed to a seat, by spawn label — this is the surface a judge
// actually reads, and the one DOT-1040 is about.
let BRIEFS = {}
let SCRIPT = {}
let CALLS = []
const agent = (brief, opts) => {
    BRIEFS[opts.label] = brief
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    const item = Array.isArray(entry) ? entry.shift() : entry
    if (item === undefined) return Promise.resolve('')
    if (item.reject !== undefined) return Promise.reject(new Error(item.reject))
    return Promise.resolve(item.text)
}
JS
    cat "${WORK}/classifier.js"
    cat "${WORK}/brief.js"
    cat "${WORK}/gate.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// RUN-63's own numbers, so a reader can chase them.
const PHANTOM = '3ee9ca3cc3f5ada37eb46768efaebe0bea6a02ca'
const REAL    = 'a6533be112700bd1c5e0e7c5f0d4a53a4b2c7f19'
const ROW = {
    step: 'STEP-3187', kind: 'vote', issue: 'VPL-711', run: 'RUN-63',
    instance: 'security-vote@1', stage: 1,
    voters: ['judge-security', 'judge-architecture', 'judge-correctness'],
}
const SEAT = { seat: 'judge-security', variant: 'std', model: 'm', effort: 'low' }
const envelope = (sha, worktree) => JSON.stringify({
    target_sha: sha === undefined ? null : sha,
    target_worktree: worktree === undefined ? null : worktree,
})
const showWith = (extra) =>
    `{"ok":true,"data":{"step":"STEP-3187","status":"ready",` +
    `"proposal":"DKT-V304"${extra ? ',' + extra : ''}}}`
const SHOW_NO_TARGET = showWith('')
const SHOW_WITH_TARGET =
    showWith(`"target_sha":"${REAL}","target_worktree":"/w/vpl-711"`)
const APPROVED =
    '{"ok":true,"data":{"id":"DKT-V304","status":"approved","final_outcome":"approved",' +
    '"votes":[{"voter_name":"judge-security"},{"voter_name":"judge-architecture"},' +
    '{"voter_name":"judge-correctness"}]}}'
const SHOW_DONE = '{"ok":true,"data":{"step":"STEP-3187","status":"done","proposal":"DKT-V304"}}'

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

// ================= NET 1: the envelope, read structurally =================

// The three inputs the acceptance names, on the gate path's own parser.
ok(parseTargetRef('') === null, 'parseTargetRef("") is no target')
ok(parseTargetRef(envelope()) === null,
    'parseTargetRef({"target_sha":null,"target_worktree":null}) is no target')
ok(parseTargetRef(
       'Since there was no output and no error, the target sha is ' +
       `${PHANTOM} on worktree feature/parallelism.`) === null,
    'parseTargetRef(free prose naming a 40-hex sha) is no target')
// The RUN-63 reply verbatim: a bare pair of JSON-ish lines, no object at all.
ok(parseTargetRef(
       `"target_sha": "${PHANTOM}"\n"target_worktree": "feature/parallelism"`) === null,
    "parseTargetRef refuses RUN-63's actual fabricated reply — no object, no parse")
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

// ================= NET 2: don't spend the probe at all =================

// AC: a vote row whose bundle carries no target_sha. `show` carries no target
// field, so the probe is never spawned, the log says so, and the seats are
// briefed with the NO-target wording.
const A = await run({
    'STEP-3187 · gate:show':    { text: SHOW_NO_TARGET },
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:record':  { text: APPROVED },
    'STEP-3187 · gate:outcome': { text: SHOW_DONE },
    'STEP-3187 · gate:tally':   { text: APPROVED },
})
ok(calls('STEP-3187 · gate:target') === 0,
    'AC: no target field on the gate payload -> the gate:target probe is never spawned')
ok(LOG.some((l) => l.includes('skipping the gate:target probe entirely')),
    `AC: the wave log says the probe was skipped (got ${JSON.stringify(LOG)})`)
ok(seatBriefs().length === 3 &&
   seatBriefs().every((b) => b.includes('NO target ref')),
    'AC: every seat brief carries the NO target ref wording')
ok(seatBriefs().every((b) => !/TARGET SHA:/.test(b)),
    'AC: and not one brief carries a TARGET SHA: line')
ok(seatBriefs().every((b) => !/[0-9a-f]{40}/.test(b)),
    'AC: no 40-hex sha appears anywhere in any brief')
// 3 probes: gate:show, ONE vote-show (labelled gate:record, reused by the
// tally under DOT-1041), gate:outcome. gate:target is skipped by DOT-1040 and
// gate:tally spawns nothing because the record read was already conclusive.
ok(A.status === 'gate-passed' && A.spawn_accounting === '3 seats, 3 probes, 0 retries',
    `AC: the gate still passes, two probes cheaper than before (got ${JSON.stringify(A.spawn_accounting)})`)
ok(calls('STEP-3187 · gate:tally') === 0,
    'AC: a conclusive gate:record read serves the tally too — one vote-show probe per gate')

// ================= NET 3: nothing unvouched reaches a judge ================

// The RUN-63 fabrication, replayed end to end against a gate whose payload
// DOES carry a target: the probe relays a different 40-hex sha, and the brief
// refuses it because `show` does not carry it.
const B = await run({
    'STEP-3187 · gate:show':   { text: SHOW_WITH_TARGET },
    'STEP-3187 · gate:target': { text: envelope(PHANTOM, 'feature/parallelism') },
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:record':  { text: APPROVED },
    'STEP-3187 · gate:outcome': { text: SHOW_DONE },
    'STEP-3187 · gate:tally':   { text: APPROVED },
})
ok(calls('STEP-3187 · gate:target') === 1,
    'a payload that DOES carry a target still spends the probe')
ok(seatBriefs().every((b) => !b.includes(PHANTOM)),
    'the fabricated sha never reaches a seat: it is absent from the text the wave holds')
ok(LOG.some((l) => l.includes("step payload does not carry")),
    `the wave logs the refusal (got ${JSON.stringify(LOG)})`)
ok(seatBriefs().every((b) => b.includes('NO target ref')),
    'and the seats are briefed to read their own HEAD instead')
ok(B.status === 'gate-passed', 'the refusal does not disturb the gate outcome')

// A CORROBORATED target still reaches the seats exactly as before.
const C = await run({
    'STEP-3187 · gate:show':   { text: SHOW_WITH_TARGET },
    'STEP-3187 · gate:target': { text: envelope(REAL, '/w/vpl-711') },
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:record':  { text: APPROVED },
    'STEP-3187 · gate:outcome': { text: SHOW_DONE },
    'STEP-3187 · gate:tally':   { text: APPROVED },
})
ok(seatBriefs().length === 3 &&
   seatBriefs().every((b) => b.includes(`TARGET SHA:     ${REAL}`)),
    'a sha the wave can vouch for is still named in every brief')
ok(seatBriefs().every((b) => b.includes('/w/vpl-711') && !b.includes('NO target ref')),
    'the worktree rides with it, and the NO-target wording is suppressed')
ok(LOG.some((l) => l.includes(`seating`) && l.includes(REAL)),
    'the wave log names the target it seated on')
ok(C.status === 'gate-passed', 'the corroborated path is unchanged')

// A non-envelope reply is logged as such and treated as no target — never
// regex-scraped for a sha.
const D = await run({
    'STEP-3187 · gate:show':   { text: SHOW_WITH_TARGET },
    'STEP-3187 · gate:target': { text:
        `"target_sha": "${PHANTOM}"\n"target_worktree": "feature/parallelism"` },
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:record':  { text: APPROVED },
    'STEP-3187 · gate:outcome': { text: SHOW_DONE },
    'STEP-3187 · gate:tally':   { text: APPROVED },
})
ok(LOG.some((l) => l.includes('gate:target probe reply did not parse — treating as no target')),
    `a non-envelope reply is logged verbatim as unparseable (got ${JSON.stringify(LOG)})`)
ok(seatBriefs().every((b) => !b.includes(PHANTOM) && b.includes('NO target ref')),
    'and nothing from it reaches a seat')
ok(D.status === 'gate-passed', 'the unparseable reply does not disturb the gate outcome')

// A DEAD gate:target probe (empty reply) is the same story.
const E = await run({
    'STEP-3187 · gate:show':   { text: SHOW_WITH_TARGET },
    'STEP-3187 · gate:target': { text: '' },
    'STEP-3187 · seat:judge-security':     { text: 'cast recorded' },
    'STEP-3187 · seat:judge-architecture': { text: 'cast recorded' },
    'STEP-3187 · seat:judge-correctness':  { text: 'cast recorded' },
    'STEP-3187 · gate:record':  { text: APPROVED },
    'STEP-3187 · gate:outcome': { text: SHOW_DONE },
    'STEP-3187 · gate:tally':   { text: APPROVED },
})
ok(seatBriefs().every((b) => b.includes('NO target ref')) && E.status === 'gate-passed',
    'an empty gate:target reply briefs NO target ref and passes the gate')

// ---- corroboratedTarget, on its own ----
const held = `…"target_sha":"${REAL}","target_worktree":"/w/vpl-711"…`
ok(corroboratedTarget(null, held) === null, 'corroboratedTarget(null) is no target')
ok(corroboratedTarget({ sha: REAL, worktree: '/w/vpl-711' }, held).sha === REAL,
    'a 40-hex sha present in the held text survives')
ok(corroboratedTarget({ sha: PHANTOM, worktree: '' }, held) === null,
    'a 40-hex sha ABSENT from the held text is refused')
ok(corroboratedTarget({ sha: REAL.slice(0, 12), worktree: '' }, held) === null,
    'an abbreviated sha is refused even when the held text contains it')
ok(corroboratedTarget({ sha: REAL.toUpperCase(), worktree: '' },
       held + REAL.toUpperCase()) === null,
    'an uppercase sha is refused — the engine records lowercase hex')
ok(corroboratedTarget({ sha: '', worktree: '/w/vpl-711' }, held).worktree === '/w/vpl-711' &&
   corroboratedTarget({ sha: '', worktree: '/w/vpl-711' }, held).sha === '',
    'the worktree half stands alone when only it is corroborated')
ok(corroboratedTarget({ sha: REAL, worktree: '/gone' }, held).worktree === '',
    'an uncorroborated worktree is dropped while the vouched sha stays')

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
