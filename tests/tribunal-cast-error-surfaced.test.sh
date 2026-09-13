#!/bin/bash

# Behavior suite for tribunal.js's return path: a seat's final text reaches
# the caller as `replies`, in both modes.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `sed` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The seat brief tells every judge its final chat text is
# discarded EXCEPT a verbatim cast error, which a seat whose `docket vote
# cast` failed twice must end with. Neither mode relayed that text: the
# conversational path returned only what its verify probe read off the vote
# record, and the mid-wave path filtered the seats' replies down to the
# `{seat, error}` objects of caught spawn exceptions. A judge that ended with
# a valid cast error was dropped exactly like a judge that ended with
# nothing, so the one case where its text mattered reached nobody. Now every
# spawn attempt that ends with non-empty text is logged under its seat and
# relayed on the result as `replies: [{seat, text}]`, beside — never folded
# into — the mid-wave `absorbed` list.
#
# HOW. The return path sits outside tribunal.js's `seat-brief` TEST fence, so
# this suite runs the WHOLE script: it wraps the file in an async function
# (stripping the single `export` keyword, which a function body rejects; the
# script's top-level `return` then returns from the wrapper), stubs the four
# harness globals the script reaches for (`agent`, `parallel`, `log`,
# `phase`), scripts the agent per spawn label, and asserts on the returned
# result and the log for a conversational and a mid-wave invocation.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TRIBUNAL="${TRIBUNAL_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/tribunal.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$TRIBUNAL" ] || fatal "tribunal.js not found at ${TRIBUNAL}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/tribunal-cast-error-surfaced.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# The wrap edits exactly one line. A second top-level export would either
# break the wrap or slip past it silently, so both directions fail loudly.
[ "$(grep -c '^export ' "$TRIBUNAL")" -eq 1 ] || fatal "expected exactly one top-level export in tribunal.js"
grep -q '^export const meta' "$TRIBUNAL" || fatal "the one top-level export is not \`export const meta\`"
sed 's/^export const meta/const meta/' "$TRIBUNAL" > "${WORK}/body.js"
grep -q '^export ' "${WORK}/body.js" && fatal "wrapped body still carries a top-level export"
grep -q '^return ' "${WORK}/body.js" || fatal "tribunal.js has no top-level return to wrap"

{
    cat <<'JS'
// --- stub harness globals the script reaches for ---
const LOG = []
const log = (m) => LOG.push(String(m))
const phase = () => {}
const parallel = (fns) => Promise.all(fns.map((f) => f()))
// The scripted agent: SCRIPT maps a spawn label to one response or an array
// of responses consumed in order — {text: ...} resolves with that value (a
// string for a seat, an object for the schema probe), {reject: ...} rejects
// with an Error carrying that message. An unlisted label resolves '' for a
// seat and null for a schema probe — a silent spawn either way.
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

async function tribunal(args) {
JS
    cat "${WORK}/body.js"
    cat <<'JS'
}

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b)

const VOTE = 'DKT-V304'
const routed = (seat) => ({ seat, model: 'opus', effort: 'high', variant: 'opus-high' })
const VOTERS = ['tribunal-architecture', 'tribunal-security', 'tribunal-correctness'].map(routed)
const STEP = { step: 'STEP-3187', instance: 'security-vote@1', issue: 'VPL-711', run: 'RUN-63' }
const CAST_ERR = 'Error: docket vote cast: voter tribunal-security is not on the roster of DKT-V304'
const CAST_ERR_2 = 'Error: docket vote cast: proposal DKT-V304 is closed'
const API_ERR = 'API Error: Connection lost mid-response'
// `docket vote show` projections, as the schema probe hands them back.
const record = (cast) => ({
    status: 'open', final_outcome: 'open',
    votes: cast.map((voter_name) => ({ voter_name, verdict: 'approve' })),
})

const run = async (script, extraArgs) => {
    SCRIPT = script
    CALLS = []
    LOG.length = 0
    return tribunal({ voteId: VOTE, voters: VOTERS, gateKind: 'activation', cwd: '/repo', ...extraArgs })
}
const seatLog = (seat, text) => LOG.some((l) => l.startsWith(`${seat}:`) && l.includes(text))

// ---- conversational: one seat ends with a verbatim cast error, one ends
// silent (''), one produces nothing (null). The record lists the erroring
// seat as missing, its one re-seat casts clean, and the second read is whole.
const C = await run({
    'seat:tribunal-architecture': { text: '' },
    'seat:tribunal-security':     [{ text: CAST_ERR }, { text: '' }],
    'seat:tribunal-correctness':  { text: null },
    [`verify:${VOTE}`]: [
        { text: record(['tribunal-architecture', 'tribunal-correctness']) },
        { text: record(['tribunal-architecture', 'tribunal-security', 'tribunal-correctness']) },
    ],
}, { context: 'the case text' })
ok(seatLog('tribunal-security', CAST_ERR),
    `AC1: the log names the seat and shows its text (got ${JSON.stringify(LOG)})`)
ok(same(C.replies, [{ seat: 'tribunal-security', text: CAST_ERR }]),
    `AC1: conversational result carries replies: [{seat, text}] for the one seat that ended with text (got ${JSON.stringify(C.replies)})`)
ok(seatLog('tribunal-correctness', 'SPAWN PRODUCED NOTHING'),
    `AC2: a null seat is still logged as unknown (got ${JSON.stringify(LOG)})`)
ok(C.outcome && Array.isArray(C.outcome.votes) && C.outcome.votes.length === 3 && C.respawns === 1 && C.seatsSpawned === 3,
    `conversational verification is untouched: outcome read off the record, one re-seat (got ${JSON.stringify(C)})`)
ok(CALLS.filter((c) => c === `verify:${VOTE}`).length === 2 && CALLS.filter((c) => c === 'seat:tribunal-security').length === 2,
    `the re-seat and both probes still happen (got ${JSON.stringify(CALLS)})`)
ok(C.absorbed === undefined, 'a conversational result grows no absorbed field')

// ---- conversational, the re-seat ALSO ends with a cast error: the retry's
// text is relayed too, since that attempt is the one the brief tells to end
// with the verbatim error. Two entries, one per attempt, in completion order.
const R = await run({
    'seat:tribunal-architecture': { text: '' },
    'seat:tribunal-security':     [{ text: CAST_ERR }, { text: CAST_ERR_2 }],
    'seat:tribunal-correctness':  { text: '' },
    [`verify:${VOTE}`]: [
        { text: record(['tribunal-architecture', 'tribunal-correctness']) },
        { text: record(['tribunal-architecture', 'tribunal-correctness']) },
    ],
}, { context: 'the case text' })
ok(same(R.replies, [{ seat: 'tribunal-security', text: CAST_ERR }, { seat: 'tribunal-security', text: CAST_ERR_2 }]),
    `a re-seat that ends with text is relayed as its own entry (got ${JSON.stringify(R.replies)})`)
ok(seatLog('tribunal-security', CAST_ERR_2) && LOG.some((l) => l.includes('STILL NO CAST from tribunal-security')),
    `the retry's text is logged and the seat is still named as missing (got ${JSON.stringify(LOG)})`)

// ---- mid-wave: same seats, no probe. The spawn exception stays in
// `absorbed` alone; the cast error rides `replies` alone.
const M = await run({
    'seat:tribunal-architecture': { reject: API_ERR },
    'seat:tribunal-security':     { text: CAST_ERR },
    'seat:tribunal-correctness':  { text: null },
}, { step: STEP })
ok(same(M.replies, [{ seat: 'tribunal-security', text: CAST_ERR }]),
    `AC1: mid-wave result carries the same replies entry (got ${JSON.stringify(M.replies)})`)
ok(seatLog('tribunal-security', CAST_ERR),
    `AC1: mid-wave logs the seat and its text (got ${JSON.stringify(LOG)})`)
ok(same(M.absorbed, [{ seat: 'tribunal-architecture', error: `Error: ${API_ERR}` }]),
    `AC2: absorbed carries only the spawn error, never a seat's text (got ${JSON.stringify(M.absorbed)})`)
ok(seatLog('tribunal-correctness', 'SPAWN PRODUCED NOTHING'),
    `AC2: mid-wave still logs a null seat as unknown (got ${JSON.stringify(LOG)})`)
ok(M.seatsSpawned === 3 && M.voteId === VOTE && M.outcome === undefined,
    `mid-wave result keeps its shape (got ${JSON.stringify(M)})`)
ok(!CALLS.some((c) => c.startsWith('verify:')),
    `mid-wave never probes the record (got ${JSON.stringify(CALLS)})`)

// ---- nothing to relay: every seat silent or dead -> replies is present and empty.
const N = await run({
    'seat:tribunal-architecture': { text: '' },
    'seat:tribunal-security':     { text: '   ' },
    'seat:tribunal-correctness':  { text: null },
}, { step: STEP })
ok(same(N.replies, []) && same(N.absorbed, []),
    `blank and null replies never land in replies, and the field is still present (got ${JSON.stringify(N)})`)

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS
} > "${WORK}/suite.mjs"

node "${WORK}/suite.mjs"
