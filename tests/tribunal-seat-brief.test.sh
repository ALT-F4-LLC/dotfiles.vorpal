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
# markers, stubs `lensOf`, and asserts the rendered brief — conversational AND
# mid-wave — names both safe-read verbs.

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
const mid = judgeBrief(SEAT, 'DKT-V304', undefined, undefined, '/repo', false, STEP, null, null)
ok(mid.includes(`docket run status ${STEP.run} --json`),
    `mid-wave brief names docket run status for its own run (got a brief lacking it: ${JSON.stringify(mid.slice(0, 300))})`)
ok(mid.includes(`docket run activate ${STEP.run} --dry-run --json`),
    'mid-wave brief names docket run activate --dry-run for its own run')
ok(mid.includes('--dry-run is load-bearing'),
    'mid-wave brief explains why --dry-run matters')

// Neither verb is gated behind a target ref or held cluster — every seat sees
// them regardless of what else the gate carries.
const midWithTarget = judgeBrief(SEAT, 'DKT-V304', undefined, undefined, '/repo', false, STEP,
    { sha: 'a6533be112700bd1c5e0e7c5f0d4a53a4b2c7f19', worktree: '/w' }, null)
ok(midWithTarget.includes('docket run status') && midWithTarget.includes('docket run activate') && midWithTarget.includes('--dry-run'),
    'the safe-read verbs survive alongside a target ref')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
