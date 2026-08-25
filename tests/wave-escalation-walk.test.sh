#!/bin/bash

# Behavior suite for wave.js's retry escalation walk — what resolve() actually
# routes a step to on its Nth claim (DOT-651).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The escalation walk shipped with an off-by-one — the guard
# read `if (row.attempt > 1)` and the loop started at `hop = 1` — so a step's
# FIRST retry re-ran at its standing variant instead of its escalate_to. That
# reached production and was visible only by reading run journals; it was
# fixed in 1e97bb3 ("escalate on a step's first retry, not its second").
# Nothing in tests/ exercised resolve() under a non-zero `attempt` at all:
# wave-chain-dead-ladder covers the stage ladder, wave-park-signals the
# predicates, wave-classifier-retry the classifier redispatch, and
# workflow-sync only diffs the SYNC regions between wave.js and tribunal.js.
#
# HOW. It slices wave.js from `SYNC-BEGIN policy-parser` to the line before
# `const WRITE_HINTS` — the parser plus every helper resolve() reaches for —
# evaluates that slice in a `vm` context, parses the REAL
# src/user/docket/config/policy.toml (no fixture: the assertions are meant to
# fail loudly when a policy edit moves a cell, naming the executor and the
# attempt), and asserts resolve(row, policy).variant across a table of
# (executor, labels, attempt) cases.
#
# WHAT THIS SUITE CANNOT SEE: everything downstream of routing. resolve()'s
# answer is a {model, effort} pair; whether the harness spawns with it, whether
# the engine ever increments `attempt`, and whether the ledger records the
# model that actually ran are all asserted nowhere here.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"
POLICY="${POLICY_TOML:-${SCRIPT_DIR}/../src/user/docket/config/policy.toml}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
[ -f "$POLICY" ] || fatal "policy.toml not found at ${POLICY}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-escalation-walk.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# The routing region: the policy parser through the end of resolve(), i.e.
# everything from the SYNC fence down to the line before the first declaration
# that belongs to the harness proper.
awk '
    index($0, "const WRITE_HINTS") { open = 0; ends++ }
    open                           { print }
    index($0, "SYNC-BEGIN policy-parser") { open = 1; begins++; print }
    END {
        if (begins != 1 || ends != 1) {
            printf "expected exactly one SYNC-BEGIN policy-parser and one const WRITE_HINTS, found %d/%d\n", begins, ends > "/dev/stderr"
            exit 1
        }
    }
' "$WAVE" > "${WORK}/region.js" || fatal "could not slice the routing region out of wave.js"

[ -s "${WORK}/region.js" ] || fatal "extracted routing region is empty"
grep -q 'function resolve(' "${WORK}/region.js" || fatal "routing region does not contain resolve()"
grep -q 'function parseToml(' "${WORK}/region.js" || fatal "routing region does not contain parseToml()"

cat > "${WORK}/suite.mjs" <<'JS'
import fs from 'node:fs'
import vm from 'node:vm'

const region = fs.readFileSync(process.env.REGION_JS, 'utf8')
const policyText = fs.readFileSync(process.env.POLICY_TOML, 'utf8')

// The region is plain script text with no imports and no file access — the
// same conditions a workflow script runs under. Evaluate it in its own context
// and hand back the two entry points.
const ctx = vm.createContext({})
vm.runInContext(region + '\n;globalThis.__api = { parseToml, resolve }',
    ctx, { filename: 'wave.js:policy-parser..resolve' })
const { parseToml, resolve } = ctx.__api
const policy = parseToml(policyText)

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const eq = (got, want, label) => ok(got === want, `${label} — expected ${want}, got ${got}`)

// A manifest row as the engine hands it to resolve(). `attempt` is
// claims-so-far, so attempt:0 is the first run and attempt:1 the first RETRY.
const row = (executor, attempt, labels) => {
    const r = { kind: 'executor', executor, step: `STEP-${executor}-a${attempt}` }
    if (attempt !== undefined) r.attempt = attempt
    if (labels && labels.length) r.labels = labels
    return r
}
const variantAt = (executor, attempt, labels) =>
    resolve(row(executor, attempt, labels), policy).variant
const modelAt = (executor, attempt, labels) =>
    resolve(row(executor, attempt, labels), policy).model

// ---------------------------------------------------------------------------
// THE TABLE. One row per (executor, labels); one cell per attempt 0..5.
//
// These names are read off the REAL policy.toml, not a fixture, so a policy
// edit that moves any cell fails here naming the executor and the attempt —
// which is the point: the walk is the thing under test, and a silent variant
// swap is exactly the class of change that should have to be acknowledged.
// ---------------------------------------------------------------------------
const TABLE = [
    // The regression fence. `implement`/`fix` stand on sonnet-medium; the
    // FIRST retry must already be one hop up (opus-medium). Under the shipped
    // off-by-one (`row.attempt > 1`, `hop = 1`) a1 came back sonnet-medium.
    ['fix', [], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-high', 'opus-high', 'opus-high']],
    ['implement', [], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-high', 'opus-high', 'opus-high']],

    // DOT-650 fallback redirect. These rows are security-pinned (never =
    // ["fable"] via [security].labels), so every fable hop on their chain is a
    // never-listed hop. The walk REDIRECTS such a hop through
    // [escalation.fallback] instead of ending there, and the redirect is
    // itself ceiling-clamped — so they climb sonnet-medium -> opus-medium ->
    // opus-high -> opus-xhigh -> opus-max and hold at the [security].ceiling.
    // Revert that branch to a plain `break` and they strand at opus-medium.
    ['fix', ['security'], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-xhigh', 'opus-max', 'opus-max']],
    ['implement', ['security-change'], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-xhigh', 'opus-max', 'opus-max']],

    // DOT-650, the [security].nodes half: pinned by executor name rather than
    // by label. Standing at opus-xhigh, the first retry redirects fable-xhigh
    // -> opus-max (the ceiling) and stops there.
    ['threat-model', [], ['opus-xhigh', 'opus-max', 'opus-max', 'opus-max', 'opus-max', 'opus-max']],
    ['tdd-author-security', [], ['opus-xhigh', 'opus-max', 'opus-max', 'opus-max', 'opus-max', 'opus-max']],
    ['tribunal-security', [], ['opus-xhigh', 'opus-max', 'opus-max', 'opus-max', 'opus-max', 'opus-max']],

    // DOT-650, and the never-listed-executor case the ACs call out: a pinned
    // node standing LOWER than the others walks two redirects (fable-high ->
    // opus-xhigh, fable-xhigh -> opus-max) and caps, never touching fable.
    ['judge-security', [], ['opus-high', 'opus-xhigh', 'opus-max', 'opus-max', 'opus-max', 'opus-max']],

    // Fable-STANDING rows do not move: resolve() only consults the fable gates
    // when the walk actually changed the variant, and fable-xhigh has no
    // escalate_to, so every attempt resolves to the standing home.
    ['investigate', [], ['fable-xhigh', 'fable-xhigh', 'fable-xhigh', 'fable-xhigh', 'fable-xhigh', 'fable-xhigh']],

    // Fable ENTRY by chain-walk is gated. Unpinned, ungated rows walk one hop
    // into a fable variant, fail fableEligible(), and land on
    // [escalation.fallback] — where they stay, because the fallback target's
    // own chain re-enters the same gated fable variant.
    ['design-qa', [], ['opus-high', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh']],
    ['judge-simplicity', [], ['opus-medium', 'opus-high', 'opus-high', 'opus-high', 'opus-high', 'opus-high']],

    // ...unless a gate is met. `novel-architecture` opens fable entry, so this
    // row reaches fable-medium at a2 where the ungated `implement` row above
    // is bounced to opus-high at the same attempt.
    ['synthesize-findings', ['novel-architecture'],
        ['sonnet-medium', 'opus-medium', 'fable-medium', 'fable-medium', 'fable-medium', 'fable-medium']],
]

for (const [executor, labels, want] of TABLE) {
    const who = executor + (labels.length ? ` (${labels.join(',')})` : '')
    for (let a = 0; a < want.length; a++) {
        let got
        try { got = variantAt(executor, a, labels) }
        catch (e) { got = `THREW: ${e.message}` }
        eq(got, want[a], `${who} attempt:${a}`)
    }
}

// ---------------------------------------------------------------------------
// Structural assertions — derived from policy.toml rather than transcribed, so
// they keep holding as the policy moves and pin the SHAPE of the walk.
// ---------------------------------------------------------------------------
const variants = policy.variants || {}
const executors = policy.executors || {}
const fallback = (policy.escalation || {}).fallback || {}
const ceiling = (policy.security || {}).ceiling

// AC: first retry moves exactly one hop.
for (const hint of ['implement', 'fix', 'judge-simplicity']) {
    const standing = executors[hint].variant
    const oneHop = variants[standing].escalate_to
    const landed = variantAt(hint, 1, [])
    ok(landed === oneHop || landed === fallback[oneHop],
        `${hint} attempt:1 is one hop off ${standing} — expected ${oneHop} ` +
        `(or its fallback ${fallback[oneHop]}), got ${landed}`)
    ok(landed !== standing,
        `${hint} attempt:1 does NOT re-run at its standing variant ${standing} ` +
        `(the shipped off-by-one) — got ${landed}`)
}

// AC: a missing `attempt` field resolves as attempt:0.
for (const hint of ['implement', 'judge-security', 'investigate', 'design-qa']) {
    eq(variantAt(hint, undefined, []), executors[hint].variant,
        `${hint} with NO attempt field resolves at its standing variant`)
}
eq(variantAt('fix', undefined, ['security']), executors.fix.variant,
    'fix (security) with NO attempt field resolves at its standing variant')

// AC: never-listed executors climb through the fallback and cap at the
// ceiling without ever resolving to fable — checked well past the point the
// walk runs out of hops.
for (let a = 0; a <= 12; a++) {
    ok(modelAt('judge-security', a, []) !== 'fable',
        `judge-security attempt:${a} never resolves to a fable model`)
}
for (const hint of ['judge-security', 'threat-model', 'tdd-author-security',
                    'spec-author-security', 'tribunal-security']) {
    eq(variantAt(hint, 12, []), ceiling,
        `${hint} at a high attempt holds at the [security].ceiling`)
}
eq(variantAt('fix', 12, ['security']), ceiling,
    'security-labelled fix holds at the [security].ceiling')
eq(variantAt('implement', 12, ['security-change']), ceiling,
    'security-labelled implement holds at the [security].ceiling')

// AC: fable-standing executors do not move, at any attempt.
for (const hint of Object.keys(executors)) {
    const standing = executors[hint].variant
    if ((variants[standing] || {}).model !== 'fable') continue
    for (const a of [0, 1, 2, 7]) {
        eq(variantAt(hint, a, []), standing,
            `fable-standing ${hint} attempt:${a} stays put`)
    }
}

// ---------------------------------------------------------------------------
// Round-based escalation (DOT-724). A fix-loop round is a FRESH step id
// (`docket step resolve --as fix-round` mints fix@N+1 at attempt 0), so the
// attempt walk alone never fires across rounds — RUN-51's AGT-643 ran nine
// fix rounds all at sonnet-medium. [escalation] on_round/round_executors
// counts each round after an opted-in executor's first (instance `name@N`,
// first entry minted at @1) as one escalate_to hop.
// ---------------------------------------------------------------------------
const loopRow = (executor, instance, attempt, labels) => {
    const r = { kind: 'executor', executor, instance, attempt,
        step: `STEP-${executor}-${instance}` }
    if (labels && labels.length) r.labels = labels
    return r
}
const variantAtRound = (executor, instance, attempt, labels) =>
    resolve(loopRow(executor, instance, attempt, labels), policy).variant

// The regression fence for the defect itself: consecutive fix rounds, each a
// fresh step at attempt 0, climb the escalate_to chain instead of re-running
// at standing forever.
const ROUNDS = [
    // Unpinned fix loop: one hop per round after the first; the fable hop is
    // gated, so the climb settles on [escalation.fallback]'s opus-high.
    [[], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-high', 'opus-high', 'opus-high']],
    // AGT-643's actual shape: security-pinned (label in [security].labels),
    // so fable hops redirect through the fallback and the climb holds at the
    // [security].ceiling.
    [['security-load-bearing'], ['sonnet-medium', 'opus-medium', 'opus-high', 'opus-xhigh', 'opus-max', 'opus-max']],
]
for (const [labels, want] of ROUNDS) {
    const who = `fix (rounds${labels.length ? `, ${labels.join(',')}` : ''})`
    for (let n = 1; n <= want.length; n++) {
        let got
        try { got = variantAtRound('fix', `fix@${n}`, 0, labels) }
        catch (e) { got = `THREW: ${e.message}` }
        eq(got, want[n - 1], `${who} fix@${n} attempt:0`)
    }
}

// Round hops COMPOSE with attempt hops: a round-2 fix that also burned one
// claim of its own stands two hops up.
eq(variantAtRound('fix', 'fix@2', 1, []), 'opus-high',
    'fix@2 attempt:1 composes round and attempt hops')

// DOT-745: dispose is the second round_executors member. Its disposition-loop
// `revise` step (workflows/disposition.toml) shares the SAME engine-level
// defect fix had — a fresh step id per round, invisible to the attempt-keyed
// walk — but dispose stands on opus-high rather than fix's sonnet-medium, so
// its climb is shorter: one hop lands it on the fable-high gate, which is
// gated the same way design-qa's is, so it settles on the fallback
// opus-xhigh instead of ever reaching fable.
const DISPOSE_ROUNDS = [
    // Unpinned dispose loop: round 2 hops opus-high -> opus-xhigh (the fable
    // hop is gated) and holds there for every later round.
    [[], ['opus-high', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh', 'opus-xhigh']],
    // Security-pinned: the same redirect-through-fallback DOT-650 gives fix
    // continues one hop further for dispose, opus-xhigh -> opus-max, and
    // holds at the [security].ceiling.
    [['security-load-bearing'], ['opus-high', 'opus-xhigh', 'opus-max', 'opus-max', 'opus-max', 'opus-max']],
]
for (const [labels, want] of DISPOSE_ROUNDS) {
    const who = `dispose (rounds${labels.length ? `, ${labels.join(',')}` : ''})`
    for (let n = 1; n <= want.length; n++) {
        let got
        try { got = variantAtRound('dispose', `dispose@${n}`, 0, labels) }
        catch (e) { got = `THREW: ${e.message}` }
        eq(got, want[n - 1], `${who} dispose@${n} attempt:0`)
    }
}

// Round hops COMPOSE with attempt hops for dispose too.
eq(variantAtRound('dispose', 'dispose@2', 1, []), 'opus-xhigh',
    'dispose@2 attempt:1 composes round and attempt hops')

// A listed executor whose row carries no instance at all is attempt-keyed
// only, same invariant as fix below.
eq(variantAtRound('dispose', undefined, 0, []), 'opus-high',
    'dispose with NO instance field resolves at its standing variant')

// Scope fence: every per-round step shares the instance ordinal, and NONE of
// the unlisted ones may move — the judges reviewing round 9 stand exactly
// where they stood at round 0, and the walk stays attempt-keyed for them.
eq(variantAtRound('judge-correctness', 'review@9#2', 0, []), 'opus-high',
    'judge-correctness review@9#2 attempt:0 keeps its standing variant')
eq(variantAtRound('judge-security', 'review@9#3', 0, []), 'opus-high',
    'judge-security review@9#3 attempt:0 keeps its standing variant')
eq(variantAtRound('synthesize-findings', 'synthesize@9', 0, []), 'sonnet-medium',
    'synthesize-findings synthesize@9 attempt:0 keeps its standing variant')
eq(variantAtRound('verify-ac', 'verify@9', 0, []), 'opus-high',
    'verify-ac verify@9 attempt:0 keeps its standing variant')
eq(variantAtRound('implement', 'implement@0', 0, []), 'sonnet-medium',
    'implement implement@0 attempt:0 keeps its standing variant')
eq(variantAtRound('implement', 'implement@0', 1, []), 'opus-medium',
    'implement implement@0 attempt:1 still escalates by attempt alone')

// A listed executor whose row carries no instance at all is attempt-keyed
// only — the whole TABLE above already runs `fix` instanceless, so this just
// names the invariant.
eq(variantAtRound('fix', undefined, 0, []), 'sonnet-medium',
    'fix with NO instance field resolves at its standing variant')

// The walk is monotone in `attempt` for a couple of representative rows: it
// may hold, but it must never walk BACK down to a variant it already left.
for (const [hint, labels] of [['implement', []], ['fix', ['security']], ['judge-security', []]]) {
    const seen = []
    let broke = false
    for (let a = 0; a <= 8; a++) {
        const v = variantAt(hint, a, labels)
        if (seen.includes(v) && seen[seen.length - 1] !== v) broke = true
        seen.push(v)
    }
    ok(!broke, `${hint}${labels.length ? ` (${labels.join(',')})` : ''} never ` +
        `revisits an abandoned variant: ${seen.join(' -> ')}`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

REGION_JS="${WORK}/region.js" POLICY_TOML="$POLICY" node "${WORK}/suite.mjs"
