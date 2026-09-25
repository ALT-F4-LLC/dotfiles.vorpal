#!/bin/bash

# Behavior suite for wave-usage.js's Extract-then-bootstrap-recheck
# orchestration: one continuous pipeline() with a conditional recheck stage,
# instead of two separate pipeline() calls with a plain-JS filter between
# them.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never spawns a real agent.
#
# WHY THIS EXISTS. Two pipeline() calls is a barrier in disguise: nothing in
# the recheck stage could start for a transcript reporting bootstrap:false
# until every OTHER transcript in the whole batch had finished its own first
# extract, even though this transcript's own recheck need is known the
# moment its own extract classifies. Folding the recheck into a conditional
# stage of the SAME pipeline lets it begin the instant this item's own
# classification decides it is needed, independent of its siblings.
#
# THE REGRESSION THIS ALSO GUARDS. Folding two independently-awaited
# pipeline() calls into stages of ONE pipeline() changes how an agent()
# REJECTION behaves: a stage that throws drops that item to null and skips
# its remaining stages, so an uncaught rejection in the extract stage would
# skip classification and recheck entirely, silently dropping the item with
# no error pushed and no recheck attempted. Both agent() calls now
# explicit-catch into null so a rejection takes the same path a
# resolved-to-null call would.
#
# WHAT IS PINNED HERE, matching the four-branch precedence in
# recheckBootstrap exactly (NOT simplified to "retry if bootstrap:false"):
# (a) a transcript reporting bootstrap:false gets its recheck agent() call
#     made while a SLOW sibling's own first extract is still in flight — the
#     one thing impossible under the old two-pipeline shape, and the direct
#     proof the fold is real;
# (b) the recheck confirms bootstrap:false again -> bootstrapFallback:true,
#     folded into results (overhead), NOT pushed to errors;
# (c) the recheck disagrees (bootstrap true, WITH usage) -> the recheck's
#     extract replaces the original;
# (d) the recheck is ok but carries NO usage -> the ORIGINAL extract is kept
#     unchanged (not the recheck's, not dropped);
# (e) a FAILED first attempt (ok:false) is pushed to errors and returned as
#     null — and is NEVER retried, since wave-usage only rechecks a
#     confirmed-good extract that merely reported no bootstrap, never an
#     outright extraction failure.
#
# HOW. Wraps wave-usage.js's wave-usage-recheck-pipeline region (hasUsage
# through `results`) in an async IIFE, with `files` set per case and a
# no-barrier `pipeline` stub matching the real one's throw-to-null
# semantics, `agent` scripted per label, `phase`/`log` recording calls.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE_USAGE="${WAVE_USAGE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave-usage.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE_USAGE" ] || fatal "wave-usage.js not found at ${WAVE_USAGE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-usage-recheck-pipeline.XXXXXX") || fatal "mktemp failed"
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
    ' "$WAVE_USAGE"
}

extract wave-usage-recheck-pipeline > "${WORK}/region.js" || fatal "bad or missing TEST markers for wave-usage-recheck-pipeline"
grep -q 'function recheckBootstrap' "${WORK}/region.js" || fatal "region does not contain recheckBootstrap"
grep -q 'function classifyFirstAttempt' "${WORK}/region.js" || fatal "region does not contain classifyFirstAttempt"
grep -q '\.catch(' "${WORK}/region.js" || fatal "region no longer catches agent() rejections — has the recheck-fold changed shape?"

{
    cat <<'JS'
let files = []
const LOG = []
const log = (m) => LOG.push(String(m))
const phase = (t) => LOG.push(`__phase:${t}`)
const CALLS = []          // every agent() label invoked, in call order
let SCRIPT = {}            // label -> {ok: false, error}|{ok: true, bootstrap, usage}|{reject}|{hold: true}
const HOLD_RESOLVERS = new Map()
const agent = (brief, opts) => {
    CALLS.push(opts.label)
    const entry = SCRIPT[opts.label]
    if (entry && entry.hold) {
        return new Promise((resolve) => HOLD_RESOLVERS.set(opts.label, resolve))
    }
    if (entry && entry.reject !== undefined) {
        return Promise.reject(new Error(entry.reject))
    }
    return Promise.resolve(entry === undefined ? null : entry)
}
function extractBrief(path, retry) { return `extract ${path}${retry ? ' (retry)' : ''}` }
const EXTRACT_SCHEMA = {}
const AGENT_CONFIG = { extract: { model: 'haiku', effort: 'low' }, recheck: { model: 'haiku', effort: 'low' } }
// Real no-barrier pipeline(): every item runs through every stage
// independently and concurrently; a stage that throws drops that item to
// null and skips its remaining stages.
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
    printf 'return { results, errors }\n}\n'
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const reset = () => { LOG.length = 0; CALLS.length = 0; HOLD_RESOLVERS.clear() }
const settle = () => new Promise((r) => setTimeout(r, 0))
const resolveHeld = (label, value) => {
    const h = HOLD_RESOLVERS.get(label)
    if (!h) throw new Error(`resolveHeld(${label}): not held`)
    HOLD_RESOLVERS.delete(label)
    h(value)
}
const USAGE = { input_tokens: 10, output_tokens: 5, cache_creation_tokens: 0, cache_read_tokens: 0 }
const GOOD = (bootstrap) => ({ ok: true, bootstrap, usage: USAGE, tool_uses: 0 })

// ---- (a) a bootstrap:false transcript's recheck fires while a slow
// sibling's own extract is still held ------------------------------------
{
    reset()
    files = ['/dir/agent-A.jsonl', '/dir/agent-B.jsonl']
    SCRIPT = {
        'agent-A.jsonl · extract': { hold: true },
        'agent-B.jsonl · extract': GOOD(false),
        'agent-B.jsonl · extract (retry)': GOOD(true),
    }
    const p = run()
    await settle()
    ok(CALLS.includes('agent-B.jsonl · extract (retry)'),
        `case a: B's recheck fires while A's own extract is still held (got calls: ${JSON.stringify(CALLS)})`)
    resolveHeld('agent-A.jsonl · extract', GOOD(true))
    const { results } = await p
    ok(results.length === 2, `case a: both A and B end up in results once A's hold releases (got ${results.length})`)
}

// ---- (b) recheck CONFIRMS bootstrap:false -> bootstrapFallback, folded
// into results as overhead, NOT pushed to errors --------------------------
{
    reset()
    files = ['/dir/agent-C.jsonl']
    SCRIPT = {
        'agent-C.jsonl · extract': GOOD(false),
        'agent-C.jsonl · extract (retry)': { ok: true, bootstrap: false, usage: USAGE },
    }
    const { results, errors } = await run()
    ok(results.length === 1 && results[0].extract.bootstrapFallback === true,
        `case b: a confirmed bootstrap:false is folded into results with bootstrapFallback:true (got ${JSON.stringify(results)})`)
    ok(errors.length === 0, `case b: a confirmed bootstrap:false is NOT pushed to errors (got ${JSON.stringify(errors)})`)
}

// ---- (c) recheck DISAGREES (bootstrap:true, with usage) -> the recheck's
// extract replaces the original -------------------------------------------
{
    reset()
    files = ['/dir/agent-D.jsonl']
    SCRIPT = {
        'agent-D.jsonl · extract': GOOD(false),
        'agent-D.jsonl · extract (retry)': { ok: true, bootstrap: true, usage: { ...USAGE, output_tokens: 999 } },
    }
    const { results } = await run()
    ok(results.length === 1 && results[0].extract.bootstrap === true && results[0].extract.usage.output_tokens === 999,
        `case c: the recheck's extract (bootstrap:true, usage 999) replaces the original (got ${JSON.stringify(results[0] && results[0].extract)})`)
}

// ---- (d) recheck is ok but carries NO usage -> the ORIGINAL extract is
// kept unchanged, not the recheck's, not dropped ---------------------------
{
    reset()
    files = ['/dir/agent-E.jsonl']
    SCRIPT = {
        'agent-E.jsonl · extract': GOOD(false),
        'agent-E.jsonl · extract (retry)': { ok: true, bootstrap: true },   // no usage field
    }
    const { results, errors } = await run()
    ok(results.length === 1 && results[0].extract.bootstrap === false && !results[0].extract.bootstrapFallback,
        `case d: the ORIGINAL extract (bootstrap:false, no fallback flag) is kept, not the recheck's (got ${JSON.stringify(results[0] && results[0].extract)})`)
    ok(errors.length === 0, 'case d: kept-original is not itself pushed to errors here (the ORIGINAL already passed hasUsage in stage 2, since it was GOOD(false))')
}

// ---- (e) a FAILED first attempt is pushed to errors and NEVER retried ---
{
    reset()
    files = ['/dir/agent-F.jsonl']
    SCRIPT = {
        'agent-F.jsonl · extract': { ok: false, error: 'jq: parse error' },
    }
    const { results, errors } = await run()
    ok(results.length === 0, `case e: a failed first attempt is excluded from results (got ${results.length})`)
    ok(errors.length === 1 && errors[0].includes('jq failed') && errors[0].includes('jq: parse error'),
        `case e: the failure is pushed to errors with the jq error text (got ${JSON.stringify(errors)})`)
    ok(!CALLS.includes('agent-F.jsonl · extract (retry)'),
        'case e: a failed first attempt is NEVER retried — only bootstrap:false triggers a recheck')
    ok(!CALLS.includes('agent-F.jsonl · extract (path retry)'),
        'case e: a jq parse failure is not a path miss and gets no path retry either')
}

// ---- (f) a jq "could not open file" failure is a relay path miss: retried
// ONCE with a fresh agent, and the retry's good extract is used -----------
{
    reset()
    files = ['/dir/github-com/agent-G.jsonl']
    SCRIPT = {
        'agent-G.jsonl · extract': { ok: false, error: 'jq: error: Could not open /dir/github.com/agent-G.jsonl: No such file or directory' },
        'agent-G.jsonl · extract (path retry)': GOOD(true),
    }
    const { results, errors } = await run()
    ok(CALLS.includes('agent-G.jsonl · extract (path retry)'),
        `case f: a could-not-open failure triggers one path retry (got calls: ${JSON.stringify(CALLS)})`)
    ok(results.length === 1 && results[0].extract.bootstrap === true && results[0].path === '/dir/github-com/agent-G.jsonl',
        `case f: the retry's extract is used, with the original path kept (got ${JSON.stringify(results)})`)
    ok(errors.length === 0, `case f: a recovered path miss is not an error (got ${JSON.stringify(errors)})`)
}

// ---- (g) a path miss that misses AGAIN is the error, and is not retried a
// second time ---------------------------------------------------------------
{
    reset()
    files = ['/dir/github-com/agent-H.jsonl']
    SCRIPT = {
        'agent-H.jsonl · extract': { ok: false, error: 'Could not open file: No such file or directory' },
        'agent-H.jsonl · extract (path retry)': { ok: false, error: 'Could not open file: No such file or directory' },
    }
    const { results, errors } = await run()
    ok(results.length === 0, `case g: a twice-missed path is excluded from results (got ${results.length})`)
    ok(errors.length === 1 && errors[0].includes('jq failed') && errors[0].includes('path retry'),
        `case g: the error names both misses (got ${JSON.stringify(errors)})`)
    ok(CALLS.filter((c) => c.includes('path retry')).length === 1,
        `case g: exactly one path retry, never two (got calls: ${JSON.stringify(CALLS)})`)
}

// ---- (h) a path retry whose extract reports bootstrap:false still gets the
// bootstrap recheck: the stages chain ------------------------------------
{
    reset()
    files = ['/dir/agent-I.jsonl']
    SCRIPT = {
        'agent-I.jsonl · extract': { ok: false, error: 'No such file or directory' },
        'agent-I.jsonl · extract (path retry)': GOOD(false),
        'agent-I.jsonl · extract (retry)': GOOD(true),
    }
    const { results } = await run()
    ok(CALLS.includes('agent-I.jsonl · extract (retry)') && results.length === 1 && results[0].extract.bootstrap === true,
        `case h: path retry then bootstrap recheck both fire and the final extract is the recheck's (got calls ${JSON.stringify(CALLS)}, results ${JSON.stringify(results)})`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
