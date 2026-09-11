#!/bin/bash

# Behavior suite for wave.js's orphaned-claim diagnosis (DOT-864).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. RUN-61 DISPATCH-332 (wave wf_289fc41a-863, 2026-08-25): the
# operator interrupted the fix@1 executor mid-step, the harness relaunched the
# IDENTICAL agent spec on workflow resume (same idempotency key, new agentId,
# same worktreePath — none of wave.js's own retry paths fired, and none could
# see a harness resume), and the relaunched agent's claim was refused with
# `step fix@1 is not ready to claim: the step is not pending`. The wave
# reported that sentence as STEP-2760's outcome. Read at face value it says the
# step never started; the truth was the opposite — claimed, holder dead, reap
# needed — and the conductor had to reconstruct that from the journal.
#
# WHAT IS PINNED HERE: the refusal is recognized only in its mandated
# three-line CONFLICT-report form, the report that replaces it carries the
# step's real status, its attempt, and holder-gone evidence, the RAW refusal
# survives verbatim inside it, and the chain-kill is unchanged — the diagnosed
# result is still chainDead, and it is still not a park.
#
# WHAT THIS SUITE CANNOT SEE: the probe itself (a real `docket step show`
# against a live engine) is out of scope — the report builder is fed probe TEXT
# here. And the caveat the fix carries in its comments is not testable at all
# from this side: an interrupted READ-class brief re-runs invisibly on harness
# resume, because only a claim refuses a duplicate, so there is no conflict for
# any predicate to catch.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-orphaned-claim.XXXXXX") || fatal "mktemp failed"
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
    extract configuration || fatal "bad or missing TEST markers for configuration"
    # park-signals first: it defines isConflictReport, which the orphaned-claim
    # predicate reads. chain-dead nests inside stage-ladder; extract it alone.
    extract park-signals   || fatal "bad or missing TEST markers for park-signals"
    extract orphaned-claim || fatal "bad or missing TEST markers for orphaned-claim"
    extract chain-dead     || fatal "bad or missing TEST markers for chain-dead"
} > "${WORK}/regions.js" || exit 2

[ -s "${WORK}/regions.js" ] || fatal "extracted regions are empty"
grep -q 'orphanedClaimReport' "${WORK}/regions.js" ||
    fatal "orphaned-claim region does not contain orphanedClaimReport"

cat "${WORK}/regions.js" > "${WORK}/suite.js"
cat >> "${WORK}/suite.js" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// ---- Fixtures ----
// The refusal, in the exact shape obligation 1 mandates: step id, the word
// CONFLICT, the engine's error line verbatim.
const NOT_PENDING = [
    'STEP-2760',
    'CONFLICT',
    '{"ok":false,"error":"step fix@1 is not ready to claim: the step is not pending"}',
].join('\n')

// The OTHER two conflicts a wave sees, neither of which this branch may touch.
const AFTER_PREDECESSOR = [
    'STEP-693',
    'CONFLICT',
    '{"ok":false,"error":"step verify@0 is not ready to claim: an `after` predecessor is not done"}',
].join('\n')
const INTO_PARK = [
    'STEP-693',
    'CONFLICT',
    '{"ok":false,"error":"run is not active"}',
].join('\n')

// `docket step show STEP-2760 --json` for the RUN-61 state: the interrupted
// executor's claim still on the row, one claim spent, nothing recorded.
const SHOW_CLAIMED = '{"ok":true,"data":{"step":"STEP-2760","instance":"fix@1",' +
    '"issue":"DOT-800","run":"RUN-61","kind":"executor","status":"claimed",' +
    '"attempt":1,"lease":{"owner":"wave:STEP-2760","expires_ms":1756150000000,' +
    '"live":true}}}'
const SHOW_DONE = '{"ok":true,"data":{"step":"STEP-2760","status":"done","attempt":1}}'
const SHOW_PENDING = '{"ok":true,"data":{"step":"STEP-2760","status":"pending","attempt":0}}'

// ---- AC1: the refusal is recognized, and only in its own shape ----
ok(isOrphanedClaimConflict(NOT_PENDING),
    'AC1: the mandated three-line "not pending" CONFLICT report is recognized')
ok(!isOrphanedClaimConflict(AFTER_PREDECESSOR),
    'a not-done-predecessor CONFLICT is NOT diagnosed as an orphaned claim')
ok(!isOrphanedClaimConflict(INTO_PARK),
    'a launched-into-a-park CONFLICT is left alone (runParked must still see it)')
ok(runParked({ status: 'returned', text: INTO_PARK }),
    'and that park signal still parks the wave')

// PRECEDENCE, the case that decides which predicate owns a text carrying BOTH
// phrases: a park is run-wide and must reach runParked() on a `returned`
// result, so the park signal wins and nothing is diagnosed here.
const BOTH = [
    'STEP-693',
    'CONFLICT',
    '{"ok":false,"error":"step fix@1 is not ready to claim: the step is not pending; run is not active"}',
].join('\n')
ok(!isOrphanedClaimConflict(BOTH),
    'a refusal carrying BOTH phrases is not diagnosed — the park signal wins')
ok(runParked({ status: 'returned', text: BOTH }),
    'and that text still parks the wave')

// The same body-scan trap every predicate in this file guards: a reviewer
// WRITING about this conflict is prose, not a conflict.
const FINDING = [
    'Reviewed wave.js\'s claim handling.',
    '',
    '- **F-1 (high)** a CONFLICT reading "not ready to claim: the step is not pending"',
    '  is relayed as the step outcome, which reads as "the step never started".',
    '- **F-2 (medium)** the orphaned claim is only visible in the journal.',
    '',
    'STEP-700 recorded (done)',
].join('\n')
ok(NOT_PENDING_CONFLICT.test(FINDING),
    'fixture integrity: the finding really does carry the phrase unbroken')
ok(!isOrphanedClaimConflict(FINDING),
    'a long finding that merely QUOTES the refusal is not diagnosed')
ok(!chainDead({ status: 'returned', text: FINDING }),
    "and it still does not kill its issue's chain")

// ---- AC2: the report carries status + attempt + holder-gone evidence ----
const diag = orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_CLAIMED)
ok(diag !== null && diag.status === 'claim-conflict',
    'AC2: a claimed step yields a diagnosed result, not a bare relay')
ok(diag.text.includes('status=claimed'), 'AC2: the report names the step STATUS')
ok(diag.text.includes('attempt=1'), 'AC2: the report names the ATTEMPT')
ok(diag.text.includes('owner="wave:STEP-2760"'),
    'AC2: the report names the HOLDER the row still carries')
ok(/claimed at attempt 1, holder returned nothing/.test(diag.text) &&
   /likely orphaned claim, reap needed/.test(diag.text),
    'AC2: it reads as an orphaned claim needing a reap, not as a claim refusal')
ok(diag.text.includes('docket step reap STEP-2760'),
    'AC2: it names the remedy verb for the step')
ok(diag.text.includes('ESTABLISH the holder is gone'),
    'AC2: and keeps the conductor\'s evidence bar ahead of the reap')
ok(diag.text.includes('{"ok":false,"error":"step fix@1 is not ready to claim: ' +
    'the step is not pending"}'),
    'AC2: the engine\'s refusal survives VERBATIM inside the report')
ok(/never started/.test(diag.text) && /Do NOT read this outcome as "the step never started"/.test(diag.text),
    'AC2: the inverted reading is named and refused explicitly')

// ---- AC3: the chain-kill is unchanged ----
ok(chainDead(diag), 'AC3: the diagnosed result still kills its issue\'s chain')
ok(!runParked(diag), 'AC3: and it is still not a run park')
ok(chainDead({ status: 'returned', text: NOT_PENDING }),
    'AC3 fence: the undiagnosed relay (empty probe) kills the chain as it always did')
ok(chainDead({ status: 'returned', text: AFTER_PREDECESSOR }),
    'AC3 fence: every other genuine claim CONFLICT still kills the chain')

// The kill must not ride on the report's LENGTH — the diagnosis deliberately
// exceeds isConflictReport()'s three-line budget, which is why it carries a
// status of its own.
ok(diag.text.trim().split('\n').filter((l) => l.trim()).length > CONFLICT_REPORT_MAX_LINES,
    'the diagnosis is longer than a CONFLICT report, so the status is what kills')
ok(chainDead({ status: 'claim-conflict', text: null }),
    'status claim-conflict alone kills the chain')

// ---- The other two states the probe can come back with ----
const done = orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_DONE)
ok(done.text.includes('already RECORDED (done)') && !done.text.includes('reap STEP-2760'),
    'a step that already recorded is reported as such, with no reap prescribed')
const pending = orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_PENDING)
ok(pending.text.includes('disagree') && pending.text.includes('pending'),
    'a status that contradicts the refusal is reported as a disagreement to reconcile')

// ---- Degradation: an empty or unusable probe relays the refusal ----
ok(orphanedClaimReport('STEP-2760', NOT_PENDING, '') === null,
    'an EMPTY probe yields null — the caller relays the refusal exactly as before')
ok(orphanedClaimReport('STEP-2760', NOT_PENDING,
    'docket: could not reach the database') === null,
    'and so does engine prose carrying no status field')

// ---- parseStepShow: absence is normal, and nothing is invented ----
const bare = parseStepShow('{"data":{"status":"claimed"}}')
ok(bare.status === 'claimed' && bare.attempt === '' && bare.owner === '' &&
   bare.failed === '' && bare.reaped === '',
    'omitted fields parse as absent rather than as zeros')
ok(!orphanedClaimReport('STEP-9', NOT_PENDING, '{"data":{"status":"claimed"}}')
    .text.includes('attempt='),
    'and an absent attempt is simply not claimed in the report')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js"
