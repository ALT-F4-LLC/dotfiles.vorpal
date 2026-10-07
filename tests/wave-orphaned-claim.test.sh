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
# survives verbatim inside it, and the chain-kill holds for every unsettled
# row — the diagnosed result is still chainDead and still not a park — while
# a row that already reads done or skipped settles the stage instead.
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
    # packet defines shellQuote, which the blocked-settle brief reads.
    extract packet         || fatal "bad or missing TEST markers for packet"
    # park-signals first: it defines isConflictReport, which the orphaned-claim
    # predicate reads. chain-dead nests inside stage-ladder; extract it alone.
    extract park-signals   || fatal "bad or missing TEST markers for park-signals"
    extract orphaned-claim || fatal "bad or missing TEST markers for orphaned-claim"
    extract blocked-settle || fatal "bad or missing TEST markers for blocked-settle"
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
// executor's claim still on the row, one claim spent, nothing recorded. The
// shape is the installed engine's: a step row names no lease holder, so there
// is no lease object to read.
const SHOW_CLAIMED = '{"ok":true,"data":{"step":"STEP-2760","instance":"fix@1",' +
    '"issue":"DOT-800","run":"RUN-61","kind":"executor","attempt":1,' +
    '"expected_cost":0,"lease_ttl_s":900,"status":"claimed"}}'
// The expired-but-unreaped window: the row still holds the claim, the lease
// lapsed, and `status` already renders the reap's answer.
const SHOW_EXPIRED = '{"ok":true,"data":{"step":"STEP-2760","attempt":1,' +
    '"status":"ready","lease_expired":true}}'
const SHOW_DONE = '{"ok":true,"data":{"step":"STEP-2760","status":"done","attempt":1}}'
const SHOW_PENDING = '{"ok":true,"data":{"step":"STEP-2760","status":"pending","attempt":0}}'
const SHOW_SKIPPED = '{"ok":true,"data":{"step":"STEP-2760","status":"skipped","attempt":0}}'
const SHOW_FAILED = '{"ok":true,"data":{"step":"STEP-2760","status":"failed","attempt":1}}'
const SHOW_SUPERSEDED = '{"ok":true,"data":{"step":"STEP-2760","status":"superseded","attempt":1}}'

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
ok(!diag.text.includes('owner=') && !diag.text.includes('lease_expired='),
    'AC2: the report invents no holder or lease fact the row did not carry')
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
const expired = orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_EXPIRED)
ok(expired.text.includes('lease_expired=true') && expired.text.includes('disagree'),
    'an expired-but-unreaped lease is named in the facts line')

// ---- A conflict on a step that already settled is a settled stage ----
// The RUN-114 shape: a harness stall retry relaunched a seat whose first
// agent had already recorded, the relaunch was refused "not pending", and
// the probe read `done`. The lane is alive; only an unsettled row kills it.
ok(!chainDead(done),
    'a diagnosed conflict whose step reads done does NOT kill the chain')
const skipped = orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_SKIPPED)
ok(skipped.status === 'claim-conflict' && !chainDead(skipped),
    'a diagnosed conflict whose step reads skipped does NOT kill the chain')
ok(chainDead(pending),
    'a diagnosed conflict whose step reads pending still kills the chain')
ok(chainDead(orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_FAILED)),
    'a diagnosed conflict whose step reads failed still kills the chain')
ok(chainDead(orphanedClaimReport('STEP-2760', NOT_PENDING, SHOW_SUPERSEDED)),
    'a diagnosed conflict whose step reads superseded still kills the chain')
ok(chainDead(expired),
    'a diagnosed conflict whose row and refusal disagree still kills the chain')

// ---- Degradation: an empty or unusable probe relays the refusal ----
ok(orphanedClaimReport('STEP-2760', NOT_PENDING, '') === null,
    'an EMPTY probe yields null — the caller relays the refusal exactly as before')
ok(orphanedClaimReport('STEP-2760', NOT_PENDING,
    'docket: could not reach the database') === null,
    'and so does engine prose carrying no status field')

// ---- parseStepShow: absence is normal, and nothing is invented ----
const bare = parseStepShow('{"data":{"status":"claimed"}}')
ok(bare.status === 'claimed' && bare.attempt === '' && bare.leaseExpired === '' &&
   bare.failed === '' && bare.reaped === '',
    'omitted fields parse as absent rather than as zeros')
ok(!orphanedClaimReport('STEP-9', NOT_PENDING, '{"data":{"status":"claimed"}}')
    .text.includes('attempt='),
    'and an absent attempt is simply not claimed in the report')

// ---- A WRITE BLOCKED executor's claim is settled, not left to a reap ----
// The RUN-125 STEP-11282 reply: the signal opens the last line, the refusal
// sentence follows it, and no record tail closes the reply.
const STEP = 'STEP-11282'
const ROW = { step: STEP, issue: 'DOT-1', run: 'RUN-125', attempt: 0 }
const CLAIM = {
    dir: `/tmp/claude-501/${STEP}.d`,
    token: `/tmp/claude-501/${STEP}.d/${STEP}.token`,
    attempt: 1,
}
const OWNER = `wave:${STEP}:1`
const HELD = `${STEP} is CLAIMED by ${OWNER}`
const WRITE_BLOCKED_REPLY = [
    'I could not write the artifact.',
    '',
    `WRITE BLOCKED: The live token is still in /tmp/claude-501/${STEP}.d/${STEP}.token, ` +
        'and the step has no record and no fail.',
].join('\n')
const RECORD_BLOCKED_REPLY = [
    'The record was refused.',
    '',
    'RECORD BLOCKED',
    `${STEP}: permission denied`,
].join('\n')
const NETWORK_BLOCKED_REPLY = [
    'The tests gate needs the network.',
    '',
    'NETWORK GATE BLOCKED: tests, proxy.golang.org, dial tcp: lookup proxy.golang.org: no such host',
].join('\n')

ok(lastLine(WRITE_BLOCKED_REPLY).startsWith('WRITE BLOCKED:') && recordTail(WRITE_BLOCKED_REPLY) === null,
    'fixture integrity: the WRITE BLOCKED reply ends on the signal with no record tail')

// A spy agent() and a stub `docket step show` reading `showStatus`.
function harness(showStatus) {
    const h = { prompts: [], shows: [] }
    h.deps = {
        row: ROW, owner: OWNER, claim: CLAIM, held: HELD, log: () => {},
        agent: (brief) => { h.prompts.push(brief); return Promise.resolve({ output: 'ok' }) },
        stepShow: (step) => {
            h.shows.push(step)
            return Promise.resolve(showStatus === null ? null : { status: showStatus, attempt: '1' })
        },
    }
    return h
}

async function settleCases() {
    // (1) WRITE BLOCKED: one settle agent, the fail and show commands, failed-blocked.
    const w = harness('ready')
    const wr = await settleStoppedReply({ ...w.deps, text: WRITE_BLOCKED_REPLY })
    ok(w.prompts.length === 1, 'WRITE BLOCKED launches exactly one settle agent')
    const p = w.prompts[0] || ''
    ok(p.includes(`docket step fail ${STEP} --note`),
        'the settle prompt runs docket step fail with a note')
    ok(new RegExp(`docket step fail ${STEP} --note '[^\\n]*' < ${CLAIM.token.replace(/\./g, '\\.')}`).test(p),
        'the settle prompt feeds the token through a < stdin redirect')
    ok(p.includes(`docket step show ${STEP}`), 'the settle prompt runs docket step show')
    ok(p.includes('WRITE BLOCKED: The live token is still in'),
        'the note carries the signal and the first refusal line')
    ok(p.includes(`docket step claim ${STEP} --owner ${OWNER}`),
        'the settle prompt names its step in the sibling guard spelling')
    ok(wr.status === 'failed-blocked' && wr.signal === 'WRITE BLOCKED',
        'a settle whose step show reads ready reports failed-blocked')

    // (3) RECORD BLOCKED keeps its token: no settle agent, status blocked.
    const r = harness('ready')
    const rr = await settleStoppedReply({ ...r.deps, text: RECORD_BLOCKED_REPLY })
    ok(r.prompts.length === 0, 'RECORD BLOCKED launches no settle agent')
    ok(rr.status === 'blocked' && rr.signal === 'RECORD BLOCKED',
        'RECORD BLOCKED settles blocked with its signal')

    // (4) NETWORK GATE BLOCKED keeps its token too.
    const n = harness('ready')
    const nr = await settleStoppedReply({ ...n.deps, text: NETWORK_BLOCKED_REPLY })
    ok(n.prompts.length === 0, 'NETWORK GATE BLOCKED launches no settle agent')
    ok(nr.status === 'blocked' && nr.signal === 'NETWORK GATE BLOCKED',
        'NETWORK GATE BLOCKED settles blocked with its signal')

    // (5) The settle ran but step show does not read ready: unsettled.
    for (const status of ['claimed', null]) {
        const u = harness(status)
        const ur = await settleStoppedReply({ ...u.deps, text: WRITE_BLOCKED_REPLY })
        ok(u.prompts.length === 1 && ur.status === 'unsettled',
            `a settle whose step show reads ${status === null ? 'nothing' : status} reports unsettled`)
        ok(ur.text.includes(HELD), 'an unsettled row names the claim still held')
    }

    // No signal and no tail keeps the unrecorded path, with no settle agent.
    const x = harness('ready')
    const xr = await settleStoppedReply({ ...x.deps, text: 'I did some things and stopped.' })
    ok(x.prompts.length === 0 && xr.status === 'unrecorded',
        'a reply with neither a tail nor a signal settles unrecorded')

    // (6) Each new status leaves later same-issue steps unclaimable this wave.
    ok(chainDead({ step: STEP, status: 'failed-blocked', text: '' }),
        'failed-blocked kills its issue\'s chain for this wave')
    ok(chainDead({ step: STEP, status: 'unsettled', text: '' }),
        'unsettled kills its issue\'s chain for this wave')
}

settleCases().then(() => {
    console.log(`\n${pass} passed, ${fail} failed`)
    process.exit(fail === 0 ? 0 : 1)
}, (err) => {
    console.error(`FAIL: settle cases threw: ${err && err.stack || err}`)
    process.exit(1)
})
JS

node "${WORK}/suite.js"
