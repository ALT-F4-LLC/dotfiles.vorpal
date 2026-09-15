#!/bin/bash

# Behavior suite for tribunal.js's seat-brief renderer: the safe-read verbs a
# judge is told it may run before casting.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. wave.js fences its own seat-brief safe-read list and pins
# it (tests/wave-target-envelope.test.sh, tests/wave-vote-retry-report.test.sh
# extract wave.js's `gate-vote` region and exercise the brief tribunal.js
# renders through a stubbed `workflow`). Before this suite, tribunal.js's OWN
# copy — now the only copy, since DOT-1300 folded the seat contract into this
# file — carried no such pin: nothing in the repo asserted that a judge is
# actually told it may run `docket run status` and
# `docket run activate --dry-run` before voting. A scratch mutant that deletes
# both lines passed every suite in the repo unchanged.
#
# HOW. tribunal.js fences its brief renderer (judgeBrief and its helpers) in
# TEST-BEGIN/TEST-END `seat-brief` markers. This suite extracts that region
# plus the `lensOf`/`TARGET_SHA_RE` globals it reaches for outside the
# markers, stubs `lensOf`, and asserts the rendered brief names the safe-read
# verbs: `docket run status` in both modes, `docket run activate --dry-run`
# ONLY in conversational mode (an activation gate previews the bind it would
# make). A mid-wave step vote previews nothing, so its brief must not carry
# the activation verb at all — a read-only seat holding a verb one dropped
# flag away from activating the run is an incident waiting for a typo.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TRIBUNAL="${TRIBUNAL_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/tribunal.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$TRIBUNAL" ] || fatal "tribunal.js not found at ${TRIBUNAL}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/tribunal-seat-brief.XXXXXX") || fatal "mktemp failed"
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
    ' "$TRIBUNAL"
}

extract seat-brief > "${WORK}/brief.js" || fatal "bad or missing TEST markers for seat-brief"
[ -s "${WORK}/brief.js" ] || fatal "extracted seat-brief region is empty"
grep -q 'judgeBrief' "${WORK}/brief.js" || fatal "seat-brief region does not contain judgeBrief"

{
    cat <<'JS'
// The only globals judgeBrief reaches for outside its own TEST fence.
const lensOf = (seat) => ({ role: 'stub-role', text: 'STUB LENS.' })
const TARGET_SHA_RE = /^[0-9a-f]{40}$/
JS
    cat "${WORK}/brief.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const SEAT = { seat: 'tribunal-security', variant: 'opus-high', model: 'opus', effort: 'high' }
const STEP = { step: 'STEP-3187', instance: 'security-vote@1', issue: 'VPL-711', run: 'RUN-63' }

// ---- conversational mode: no `step` argument ----
const conv = judgeBrief(SEAT, 'DKT-V304', 'activation', 'the case text', '/repo', false)
ok(conv.includes('docket run status RUN-N --json'),
    `conversational brief names docket run status (got a brief lacking it: ${JSON.stringify(conv.slice(0, 200))})`)
ok(conv.includes('docket run activate RUN-N --dry-run --json'),
    'conversational brief names docket run activate --dry-run')
ok(conv.includes('--dry-run is load-bearing'),
    'conversational brief explains why --dry-run matters')

// ---- mid-wave mode: `step` present ----
// A step vote previews no activation, so the mid-wave brief must NOT hand a
// read-only seat `docket run activate --dry-run`: the verb is one dropped flag
// from activating the run, and nothing a step vote reads comes from it.
const mid = judgeBrief(SEAT, 'DKT-V304', undefined, undefined, '/repo', false, STEP, null, null)
ok(mid.includes(`docket run status ${STEP.run} --json`),
    `mid-wave brief names docket run status for its own run (got a brief lacking it: ${JSON.stringify(mid.slice(0, 300))})`)
ok(!mid.includes('docket run activate'),
    'mid-wave brief never names docket run activate, even with --dry-run')
ok(mid.includes(`docket step show ${STEP.step}`),
    'mid-wave brief names docket step show for its own step')

// The status read is not gated behind a target ref or held cluster — every
// seat sees it regardless of what else the gate carries — and the activation
// verb stays absent there too.
const midWithTarget = judgeBrief(SEAT, 'DKT-V304', undefined, undefined, '/repo', false, STEP,
    { sha: 'a6533be112700bd1c5e0e7c5f0d4a53a4b2c7f19', worktree: '/w' }, null)
ok(midWithTarget.includes('docket run status') && !midWithTarget.includes('docket run activate'),
    'the status read survives alongside a target ref and the activation verb stays absent')

// ---- the case is rendered VERBATIM in both modes, and no mode sends a seat
// to the vote record — it prints every sibling cast already landed, and
// seats run in parallel.
ok(conv.includes('the case text'),
    'conversational brief renders the caller\'s context verbatim')
const BODY = 'DESCRIPTION: security-vote@1 (security-vote)\nRATIONALE: workflow vote step security-vote@1'
const midCase = judgeBrief(SEAT, 'DKT-V304', undefined, BODY, '/repo', false, STEP, null, null)
ok(midCase.includes(BODY) && !midCase.includes('COULD NOT BE READ'),
    'mid-wave brief renders the projected proposal body verbatim')
ok(mid.includes('THE PROPOSAL BODY COULD NOT BE READ') && mid.includes(`${STEP.instance} on`),
    'a mid-wave brief with no context says so and names the gate it decides')
const respawn = judgeBrief(SEAT, 'DKT-V304', 'activation', 'the case text', '/repo', true)
for (const [label, b] of [['conversational', conv], ['conversational re-seat', respawn],
                          ['mid-wave', midCase], ['mid-wave without a body', mid]]) {
    ok(!/vote show/.test(b) && !/vote result/.test(b),
        `${label} brief never tells a seat to read the vote record`)
    ok(b.includes('DO NOT READ SIBLING CASTS') && b.includes('The only `docket vote` verb'),
        `${label} brief carries the sibling-cast rule`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
