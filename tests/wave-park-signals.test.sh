#!/bin/bash

# Behavior suite for wave.js's park and chain-dead signals (DOT-226).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a wave.
#
# WHY THIS EXISTS. A workflow script has no module resolution, so the
# predicates cannot be imported. They are fenced in wave.js with
# `// TEST-BEGIN <region>` / `// TEST-END <region>` and this suite extracts
# those regions and evaluates them — the same extraction idiom
# workflow-sync.test.sh uses for the duplicated regions, pointed at a
# different problem.
#
# FOCUS: these predicates read AGENT PROSE, and both of them used to scan the
# whole reply for a substring. RUN-28 wave 1 is the fixture below, verbatim:
# judge STEP-687 was reviewing the pause skill, quoted the engine constant
# `CondRunActive = "run is not active"` as evidence for a finding, and closed
# with `STEP-687 recorded (done)`. The old `includes('run is not active')`
# read that quote as a park, so stage 2 never launched and the engine
# re-offered synthesize a dispatch round-trip later. A corpus that reviews its
# own park handling will keep producing replies like this one.
#
# WHAT THIS SUITE CANNOT SEE: it exercises the predicates, not the stage
# ladder they drive. That a false park skips later stages, and that the engine
# re-offers them, are wave.js and engine behavior respectively and are not
# re-derived here. Nor does it check the readiness probe (DOT-226's other
# half), which needs a live engine to answer.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-park-signals.XXXXXX") || fatal "mktemp failed"
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

{
    extract park-signals || fatal "bad or missing TEST markers for park-signals"
    extract chain-dead   || fatal "bad or missing TEST markers for chain-dead"
} > "${WORK}/predicates.js" || exit 2

[ -s "${WORK}/predicates.js" ] || fatal "extracted predicate region is empty"

cat "${WORK}/predicates.js" > "${WORK}/suite.js"
cat >> "${WORK}/suite.js" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const returned = (text) => ({ status: 'returned', text })

// ---- The RUN-28 regression, verbatim from the wave's own journal ----
// wf_b506e984-45b entry 9 (STEP-687). The finding line and the closing tail
// are byte-exact, including the unbroken `run is not active` inside the
// quoted engine constant — that is the substring the old scan matched. Other
// findings in the reply are elided; nothing else in it mattered.
const COR_2 = '- **COR-2 (blocker)** same file `:29` — graceful halt asserts "nothing about it interrupts a wave already running" and tells the session to let the wave finish. Engine says otherwise: `internal/engine/ready.go:28-29` `CondRunActive = "run is not active"`, `ready_test.go:123-140` (a `waiting-human` run offers no ready step), `claim.go:185-228` (R8: claim enforces readiness itself). On a staged wave every later-stage executor\'s claim is refused after the pause.'

const STEP_687 = [
    'Reviewed the pause skill against the engine.',
    '',
    COR_2,
    '',
    'STEP-687 recorded (done)',
].join('\n')

ok(COR_2.includes('run is not active'),
    'fixture integrity: the finding really does carry the phrase unbroken')
ok(!runParked(returned(STEP_687)),
    'a judge QUOTING `run is not active` as evidence does not park the wave')
ok(!chainDead(returned(STEP_687)),
    "the same reply does not kill its issue's chain")

// ---- Real park signals still park ----
ok(runParked(returned('Did the work.\n\nSTEP-12 recorded (waiting-human)')),
    'the mandated record tail (waiting-human) parks')
ok(runParked(returned('STEP-12 recorded (paused)')),
    'the mandated record tail (paused) parks')
ok(runParked(returned('**STEP-12 recorded (waiting-human)**')),
    'the tail still parks wrapped in markdown emphasis')
ok(runParked(returned('STEP-12 recorded (waiting-human)\n\n')),
    'the tail still parks with trailing blank lines')
ok(!runParked(returned('STEP-12 recorded (done)')),
    'a done tail does not park')

// The other park signal: an agent that launched INTO a park. Obligation 1
// mandates AT MOST three lines for a CONFLICT report.
const CONFLICT_INTO_PARK = [
    'STEP-693',
    'CONFLICT',
    '{"ok":false,"error":"run is not active"}',
].join('\n')
ok(runParked(returned(CONFLICT_INTO_PARK)),
    'a three-line CONFLICT report naming a park parks')
ok(chainDead(returned(CONFLICT_INTO_PARK)),
    'and kills its own chain')

// ---- chain-dead: a real CONFLICT vs. a report ABOUT one ----
// wf_93e53958-2d5 entry 3, verbatim shape: the engine's own refusal.
const REAL_CONFLICT = [
    'STEP-693',
    'CONFLICT',
    '{"ok":false,"error":"step verify@0 is not ready to claim: an `after` predecessor is not done"}',
].join('\n')
ok(chainDead(returned(REAL_CONFLICT)),
    'a genuine claim CONFLICT kills the chain')
ok(!runParked(returned(REAL_CONFLICT)),
    'but a not-ready CONFLICT is not a PARK — only this issue is stuck')

const CONFLICT_FINDING = [
    'Reviewed the wave for claim handling.',
    '',
    '- **F-1 (high)** wave.js:1217 treats any reply containing CONFLICT as a dead',
    '  chain, so a finding that merely names CONFLICT kills the issue.',
    '- **F-2 (medium)** the same body scan drives the park signal.',
    '- **F-3 (low)** the log line does not say which predicate fired.',
    '',
    'STEP-700 recorded (done)',
].join('\n')
ok(!chainDead(returned(CONFLICT_FINDING)),
    'a long finding that merely NAMES conflicts does not kill the chain')

// ---- Statuses the ladder sets itself still count as dead ----
for (const status of ['gate-parked', 'gate-blocked', 'gate-rejected',
                      'skipped-not-claimable', 'skipped-not-ready']) {
    ok(chainDead({ status, text: null }), `status ${status} kills the chain`)
}
ok(!chainDead(null), 'a null result is not chain-dead')
ok(!runParked(null), 'a null result is not a park')
ok(!runParked({ status: 'engine-run', text: 'STEP-9 recorded (waiting-human)' }),
    'only a RETURNED agent reply is read for park signals')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js"
