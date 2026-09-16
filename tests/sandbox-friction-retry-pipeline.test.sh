#!/bin/bash

# Behavior suite for sandbox-friction.js's File-then-retry orchestration:
# one continuous pipeline() with a conditional retry stage, instead of two
# separate pipeline() calls with a plain-JS null-filter between them.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never spawns a real agent or files an issue.
#
# WHY THIS EXISTS. Two pipeline() calls is a barrier in disguise: a fast
# group's retry could not start until every group in the whole batch —
# including the slowest filing agent — had resolved, even though a null
# result is known the instant that group's own attempt returns. Folding the
# retry into a conditional stage of the SAME pipeline lets it begin the
# instant this item's own attempt is known to need one.
#
# WHY RETRYING A SIDE-EFFECTING AGENT IS SAFE HERE. filePrompt's own
# idempotency check — `docket issue list --label sandbox ... | grep -qF --
# <subject>` — runs fresh INSIDE the agent's own shell command on every
# attempt, first or retry. A retry whose first attempt actually filed the
# issue but whose reply was merely lost re-runs the SAME check, finds the
# issue already filed, and reports "already-filed" — the safety lives in
# the command's own idempotency check, not in script-side bookkeeping, so
# folding two pipeline() calls into one changes nothing about double-filing
# risk. This suite pins that the fold preserves the null-then-retry shape
# and that a rejected agent() call is caught into the same null path a
# resolved-to-null call takes (the same regression class the census and
# wave-usage folds guarded against).
#
# WHAT IS PINNED HERE. (1) a fast group's retry fires while a slow sibling's
# own first attempt is still held open — the one thing impossible under the
# old two-pipeline shape; (2) a group whose first attempt succeeds (any
# non-null outcome) is never retried; (3) a group whose first attempt
# returns null is retried exactly once, and the retry's outcome (not the
# null) is what determines filed/skipped; (4) a group still null after its
# one retry is reported DROPPED, not filed and not silently absent; (5) an
# agent() REJECTION on the first attempt is caught into the same null path
# a resolved-to-null call takes, and is retried exactly like one.
#
# HOW. Wraps sandbox-friction.js's sandbox-friction-file region (the
# CLASSIFIER_REMEDY/SANDBOX_REMEDY strings through fileGroups) in an async
# IIFE, calling fileGroups(groups) directly with a no-barrier `pipeline`
# stub matching the real one's throw-to-null rule, `agent` scripted per
# label, `phase`/`log` recording calls, and `shq`/`ERROR_DETAIL_LENGTH`/
# `EXAMPLE_LENGTH`/`checkout`/`SANDBOX_RULE` stubbed to match the real
# values (SANDBOX_RULE is declared outside the fenced region in the real
# file, used by filePrompt).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SANDBOX_FRICTION="${SANDBOX_FRICTION_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/sandbox-friction.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SANDBOX_FRICTION" ] || fatal "sandbox-friction.js not found at ${SANDBOX_FRICTION}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/sandbox-friction-retry-pipeline.XXXXXX") || fatal "mktemp failed"
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
    ' "$SANDBOX_FRICTION"
}

extract sandbox-friction-file > "${WORK}/region.js" || fatal "bad or missing TEST markers for sandbox-friction-file"
grep -q 'async function fileGroups' "${WORK}/region.js" || fatal "region does not contain fileGroups"
grep -q '\.catch(' "${WORK}/region.js" || fatal "region no longer catches agent() rejections — has the retry-fold changed shape?"

{
    cat <<'JS'
const LOG = []
const log = (m) => LOG.push(String(m))
const phase = (t) => LOG.push(`__phase:${t}`)
const CALLS = []          // every agent() label invoked, in call order
let SCRIPT = {}            // label -> {action, detail} | {reject} | {hold: true}
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
function shq(s) { return `'${String(s).replace(/'/g, `'\\''`)}'` }
const ERROR_DETAIL_LENGTH = 300
const EXAMPLE_LENGTH = 100
const checkout = '/repo'
const SANDBOX_RULE = `Run it SANDBOXED — do NOT pass dangerouslyDisableSandbox. If the sandbox denies it, report the denial text instead of retrying with the sandbox disabled.`
const AGENT_CONFIG = { file: { effort: 'low' } }
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
JS
    cat "${WORK}/region.js"
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
const g = (subject, count) => ({ subject, kind: 'sandbox-denial', count: count || 1, bypasses: 0, repos: 1, example: 'echo hi' })

// ---- (1) a fast group's retry fires while a slow sibling is still held --
{
    reset()
    const groups = [g('/A/path'), g('/B/path')]
    SCRIPT = {
        'file:1/2': { hold: true },
        'file:2/2': null,                                          // B's first attempt: null
        'file:2/2 (retry)': { action: 'filed', detail: 'ISSUE-1' },  // B's retry: succeeds
    }
    const p = fileGroups(groups)
    await settle()
    ok(CALLS.includes('file:2/2 (retry)'),
        `case 1: B's retry fires while A's own first attempt is still held (got calls: ${JSON.stringify(CALLS)})`)
    resolveHeld('file:1/2', { action: 'filed', detail: 'ISSUE-0' })
    const { filed } = await p
    ok(filed.length === 2, `case 1: both A and B end up filed once A's hold releases (got ${JSON.stringify(filed)})`)
}

// ---- (2) a group whose first attempt succeeds is never retried ----------
{
    reset()
    const groups = [g('/C/path')]
    SCRIPT = { 'file:1/1': { action: 'already-filed', detail: 'ALREADY-FILED' } }
    const { filed, skipped } = await fileGroups(groups)
    ok(!CALLS.includes('file:1/1 (retry)'), 'case 2: a non-null first outcome is never retried')
    ok(filed.length === 0 && skipped.some((s) => s.subject === '/C/path' && s.why === 'already filed'),
        `case 2: already-filed lands in skipped, not filed (got filed=${JSON.stringify(filed)}, skipped=${JSON.stringify(skipped)})`)
}

// ---- (3) a null first attempt is retried once; the RETRY's outcome wins -
{
    reset()
    const groups = [g('/D/path')]
    SCRIPT = {
        'file:1/1': null,
        'file:1/1 (retry)': { action: 'filed', detail: 'ISSUE-2' },
    }
    const { filed } = await fileGroups(groups)
    ok(CALLS.filter((c) => c === 'file:1/1').length === 1 && CALLS.includes('file:1/1 (retry)'),
        `case 3: exactly one retry call is made (got calls: ${JSON.stringify(CALLS)})`)
    ok(filed.includes('/D/path'), `case 3: the retry's "filed" outcome wins over the first null (got ${JSON.stringify(filed)})`)
}

// ---- (4) still null after the one retry is DROPPED, not filed or absent -
{
    reset()
    const groups = [g('/E/path')]
    SCRIPT = { 'file:1/1': null, 'file:1/1 (retry)': null }
    const { filed, skipped } = await fileGroups(groups)
    ok(filed.length === 0, `case 4: a group still null after retry is never filed (got ${JSON.stringify(filed)})`)
    ok(skipped.some((s) => s.subject === '/E/path' && s.why.includes('returned nothing')),
        `case 4: it is reported DROPPED in skipped with a reason naming the retry (got ${JSON.stringify(skipped)})`)
    ok(LOG.some((l) => l.includes('DROPPED') && l.includes('/E/path')), 'case 4: a DROPPED log line names the subject')
}

// ---- (5) an agent() REJECTION on the first attempt is caught into null
// and retried exactly like a resolved-to-null call -------------------------
{
    reset()
    const groups = [g('/F/path')]
    SCRIPT = {
        'file:1/1': { reject: 'API Error: rate limited' },
        'file:1/1 (retry)': { action: 'filed', detail: 'ISSUE-3' },
    }
    const { filed } = await fileGroups(groups)
    ok(CALLS.includes('file:1/1 (retry)'), `case 5: a REJECTED first attempt is still retried (got calls: ${JSON.stringify(CALLS)})`)
    ok(filed.includes('/F/path'), `case 5: the retry recovers it (got ${JSON.stringify(filed)})`)
    ok(LOG.some((l) => l.includes('agent error') && l.includes('rate limited')), 'case 5: the rejection reason is logged')
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
