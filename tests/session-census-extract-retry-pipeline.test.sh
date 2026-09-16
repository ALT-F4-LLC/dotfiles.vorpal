#!/bin/bash

# Behavior suite for session-census.js's Extract-then-retry orchestration:
# one continuous pipeline() with a conditional retry stage, instead of two
# separate pipeline() calls with a plain-JS filter between them.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never spawns a real agent.
#
# WHY THIS EXISTS. Two pipeline() calls is a barrier in disguise: nothing in
# the second (retry) pipeline could start for a FAST item until every item
# in the first pipeline — including the slowest transcript in the whole
# batch — had resolved, even though a fast item's own retry need is known
# the moment its own extract returns. Folding the retry into a conditional
# stage of the SAME pipeline lets each item's retry begin the instant its
# own first attempt is classified, independent of its siblings — this is
# the shape the workflow-authoring reference's own barrier rule argues for.
#
# THE REGRESSION THIS ALSO GUARDS. Folding two independently-awaited
# pipeline() calls into stages of ONE pipeline() changes how an agent()
# REJECTION behaves: the authoring reference's own rule is "a stage that
# throws drops that item to null and skips its remaining stages" — so an
# uncaught rejection in the extract stage would skip the classify AND retry
# stages entirely, silently dropping the item with no retry and no DROPPED
# line, a real behavior loss the two-pipeline shape never had (a rejection
# there stayed inside pipeline #1, which classifyExtract(null) still read as
# retryable). Both agent() calls now explicit-catch into null so a rejection
# takes the exact same classify/retry path a resolved-to-null call would.
#
# WHAT IS PINNED HERE. (1) a fast item's retry starts without waiting for a
# slow sibling's first attempt — the one thing impossible under the old
# two-pipeline shape, and the direct proof the fold is real; (2) an agent()
# REJECTION on the first attempt is still retried, not silently dropped;
# (3) a rejection on the retry attempt itself still produces a DROPPED log
# line; (4) a jq `error` result is never retried (deterministic on identical
# bytes).
#
# HOW. Wraps session-census.js's census-retry-pipeline region
# (classifyExtract through `usable`) in an async IIFE, with `files`/`cutoff`
# set per case and a no-barrier `pipeline` stub matching the real one's
# throw-to-null semantics, `agent` scripted per label, and `phase`/`log`
# stubbed to record calls.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CENSUS="${SESSION_CENSUS_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/session-census.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$CENSUS" ] || fatal "session-census.js not found at ${CENSUS}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/session-census-extract-retry-pipeline.XXXXXX") || fatal "mktemp failed"
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
    ' "$CENSUS"
}

extract session-census-config            > "${WORK}/config.js" || fatal "bad or missing TEST markers for session-census-config"
extract census-retry-pipeline            > "${WORK}/region.js" || fatal "bad or missing TEST markers for census-retry-pipeline"
grep -q 'function classifyExtract' "${WORK}/region.js" || fatal "region does not contain classifyExtract"
grep -q 'const usable' "${WORK}/region.js" || fatal "region does not contain the final usable computation"
grep -q '\.catch(' "${WORK}/region.js" || fatal "region no longer catches agent() rejections — has the retry-fold changed shape?"

{
    cat "${WORK}/config.js"
    cat <<'JS'
let files = []
let cutoff = '2026-01-01T00:00:00Z'
const LOG = []
const log = (m) => LOG.push(String(m))
const phase = (t) => LOG.push(`__phase:${t}`)
const CALLS = []          // every agent() label invoked, in call order
const RESOLVE_ORDER = []  // labels in the order their promise SETTLED (not called) — proves overlap
let SCRIPT = {}            // label -> {text} | {reject} | {hold: true}
const HOLD_RESOLVERS = new Map()
const agent = (brief, opts) => {
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    if (entry && entry.hold) {
        return new Promise((resolve, reject) => {
            HOLD_RESOLVERS.set(opts.label, { resolve, reject })
        }).then((v) => { RESOLVE_ORDER.push(opts.label); return v })
    }
    if (entry && entry.reject !== undefined) {
        return Promise.reject(new Error(entry.reject)).catch((e) => { RESOLVE_ORDER.push(opts.label); throw e })
    }
    const value = entry ? entry.text : null
    return Promise.resolve(value).then((v) => { RESOLVE_ORDER.push(opts.label); return v })
}
function extractPrompt(f) { return `extract ${f.path}` }
const EXTRACT_SCHEMA = {}
// AGENT_CONFIG and ERROR_TEXT_CHARS come from the real session-census-config
// region (included above) — not restated here, to avoid a duplicate-
// declaration clash with the real source. COUNT_FIELDS is declared OUTSIDE
// that region in the real file, so it is restated here, matching the real
// list exactly (session-census.js's own COUNT_FIELDS, line ~662).
const COUNT_FIELDS = ['msgs', 'out', 'think', 'think_msgs', 'think_chars', 'text_chars', 'tool_uses',
    'operator', 'interrupts', 'kills', 'kill_events', 'idle_notifs', 'idle_textonly', 'idle_worked']
// Real no-barrier pipeline(): every item runs through every stage
// independently and concurrently; a stage that throws drops that item to
// null and skips its remaining stages — the authoring reference's own rule,
// which the region under test depends on for agent() rejections.
const pipeline = (items, ...stages) => Promise.all(items.map(async (item, i) => {
    let r = item
    try {
        for (const stage of stages) r = await stage(r, item, i)
    } catch (e) {
        return null
    }
    return r
}))

const run = async () => {
JS
    cat "${WORK}/region.js"
    printf 'return usable\n}\n'
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const reset = () => { LOG.length = 0; CALLS.length = 0; RESOLVE_ORDER.length = 0; HOLD_RESOLVERS.clear() }
const settle = () => new Promise((r) => setTimeout(r, 0))
const resolveHeld = (label, value) => {
    const h = HOLD_RESOLVERS.get(label)
    if (!h) throw new Error(`resolveHeld(${label}): not held`)
    HOLD_RESOLVERS.delete(label)
    h.resolve(value)
}
const f = (i, kind) => ({ path: `/t/session-${i}.jsonl`, kind: kind || 'main' })
const COUNTS = { msgs: 1, out: 1, think: 0, think_msgs: 0, think_chars: 0, text_chars: 0, tool_uses: 0,
    sidechain_dropped: 0, efforts: {}, cells: [], operator: 0, interrupts: 0, kills: 0, kill_events: 0,
    idle_notifs: 0, idle_textonly: 0, idle_worked: 0, versions: {}, excluded: {}, rows: {}, last_ts: null }

// ---- (1) a fast item's retry starts without waiting for a slow sibling --
// A: extract HELD (never resolves in this scenario's window). B: extract
// resolves null immediately (retryable). Under the OLD two-pipeline shape,
// B's retry agent() call could not be MADE until pipeline #1 fully resolved
// for every item — which never happens here, since A is held. Under the
// fold, B's retry call fires as soon as B's own classify runs, with A still
// in flight. This is the one scenario impossible to pass under the pre-fix
// two-pipeline shape.
{
    reset()
    files = [f(0), f(1)]
    SCRIPT = {
        'extract:main:1/2': { hold: true },
        'extract:main:2/2': { text: null },   // B's first attempt: null, retryable
        'extract:main:retry:2/2': { text: { ...COUNTS } },   // B's retry: succeeds
    }
    const p = run()
    await settle()
    ok(CALLS.includes('extract:main:retry:2/2'),
        `case 1: B's retry call fires while A's own extract is still held (got calls: ${JSON.stringify(CALLS)})`)
    resolveHeld('extract:main:1/2', { ...COUNTS })
    const usable = await p
    ok(usable.length === 2, `case 1: both A and B end up usable once A's hold releases (got ${usable.length})`)
}

// ---- (2) an agent() REJECTION on the first attempt is still retried -----
{
    reset()
    files = [f(0)]
    SCRIPT = {
        'extract:main:1/1': { reject: 'API Error: rate limited' },
        'extract:main:retry:1/1': { text: { ...COUNTS } },
    }
    const usable = await run()
    ok(CALLS.includes('extract:main:retry:1/1'),
        `case 2: a REJECTED first attempt is still retried, not silently dropped (got calls: ${JSON.stringify(CALLS)})`)
    ok(usable.length === 1, `case 2: the retry recovers it (got ${usable.length})`)
    ok(LOG.some((l) => l.includes('extract agent error') && l.includes('rate limited')),
        'case 2: the rejection reason is logged')
}

// ---- (3) a rejection on the RETRY attempt produces a DROPPED line -------
{
    reset()
    files = [f(0)]
    SCRIPT = {
        'extract:main:1/1': { text: null },
        'extract:main:retry:1/1': { reject: 'API Error: still rate limited' },
    }
    const usable = await run()
    ok(usable.length === 0, `case 3: a rejected retry is dropped, not silently counted usable (got ${usable.length})`)
    ok(LOG.some((l) => l.includes('DROPPED') && l.includes('retry did not recover it')),
        `case 3: the DROPPED line fires for a rejected retry (got ${JSON.stringify(LOG)})`)
}

// ---- (4) a jq error result is never retried ------------------------------
{
    reset()
    files = [f(0)]
    SCRIPT = {
        'extract:main:1/1': { text: { error: 'jq: syntax error' } },
    }
    const usable = await run()
    ok(!CALLS.includes('extract:main:retry:1/1'), 'case 4: a jq error result is never retried')
    ok(usable.length === 0, 'case 4: it is dropped, not usable')
    ok(LOG.some((l) => l.includes('DROPPED') && l.includes('jq:')), 'case 4: the DROPPED line names the jq error')
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
