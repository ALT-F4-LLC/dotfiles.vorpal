#!/bin/bash

# Behavior suite for wave.js's transient-safety-classifier retry (DOT-558).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a wave.
#
# WHY THIS EXISTS. RUN-43 (wave wf_b8679e05-2dc, 2026-08-22) lost 3 of 24
# executor spawns to ONE pre-spawn block whose reason was byte-identical
# across all three — STEP-1547 (judge-simplicity), STEP-1548 (judge-testing,
# opus), STEP-1561 (synthesize-findings, sonnet): different issues, different
# classes, different models, so the block was infra, not content. All three
# recorded `done` on redispatch from the SAME brief bytes. wave.js now retries
# such a spawn ONCE with identical bytes; this suite pins the signature match
# that decides which blocks qualify, because that predicate is the whole
# safety argument — a content-based refusal must never be resubmitted, and a
# resubmission must never be reworded.
#
# WHAT THIS SUITE CANNOT SEE: it exercises the predicate, not the spawn
# ladder it gates. That the ladder retries EXACTLY once and returns
# 'spawn-failed' on a second failure is asserted here only as a source shape
# (grep, below), because spawn() closes over workflow globals (agent, log)
# that do not exist outside a live Workflow run.
#
# THE PRE-SPAWN (BARE NULL) PATH (DOT-565): in the harness measured while
# this was written (claude 2.1.241) a pre-spawn classifier block resolves
# agent() to a BARE null — `if (await <preflight>(...)) return null` — and
# the reason text is emitted only onto the progress stream as
# workflowProgress[].error, which a workflow script cannot read. wave.js now
# covers that shape out-of-band: the null branch spawns a read-only probe
# agent that recovers the harness's own persisted progress record for the
# step's label from the wave state file, and probeRecovered() (second region
# below) gates what the probe hands back — only a found, label-matched,
# blocked === true entry with a non-empty error string yields a reason, and
# that reason must still pass transientClassifierBlock() before the
# identical-bytes resubmission fires. A bare null is still never retried
# BLIND — that would relaunch operator-skipped agents (DOT-558).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-classifier-retry.XXXXXX") || fatal "mktemp failed"
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

extract classifier-retry > "${WORK}/predicates.js" \
    || fatal "bad or missing TEST markers for classifier-retry"
[ -s "${WORK}/predicates.js" ] || fatal "extracted predicate region is empty"

extract null-probe > "${WORK}/null-probe.js" \
    || fatal "bad or missing TEST markers for null-probe"
[ -s "${WORK}/null-probe.js" ] || fatal "extracted null-probe region is empty"

cat "${WORK}/predicates.js" "${WORK}/null-probe.js" > "${WORK}/suite.js"
cat >> "${WORK}/suite.js" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// ---- The RUN-43 fixture, verbatim from workflowProgress[].error ----
// Byte-exact, em dash included. This is the harness's own wrapper around the
// classifier's reason: `[${label}] blocked by safety classifier: ${reason}`.
const RUN_43 = '[STEP-1547 · judge-simplicity] blocked by safety classifier: Stage 2 classifier error - blocking based on stage 1 assessment (usually transient — retrying often succeeds)'

ok(transientClassifierBlock(RUN_43),
    'the verbatim RUN-43 block reason is recognized as transient')
ok(transientClassifierBlock({ message: RUN_43 }),
    'the same reason wrapped in an Error-shaped object is recognized')
ok(transientClassifierBlock(new Error(RUN_43)),
    'a real Error carrying the reason is recognized')
ok(transientClassifierBlock({ error: RUN_43 }),
    'a progress-shaped {error} record is recognized')

// The two sibling steps, same wave, same sentence, different labels.
for (const label of ['STEP-1548 · judge-testing', 'STEP-1561 · synthesize-findings']) {
    ok(transientClassifierBlock(RUN_43.replace('STEP-1547 · judge-simplicity', label)),
        `the same reason under label ${label} is recognized`)
}

// Either half of the signature is enough — the classifier has worded this
// admission both ways — but only inside a real classifier block.
ok(transientClassifierBlock('[STEP-9 · implement] blocked by safety classifier: Stage 2 classifier error'),
    'the stage-2 half alone qualifies inside a classifier block')
ok(transientClassifierBlock('[STEP-9 · implement] blocked by safety classifier: transient upstream fault (usually transient)'),
    'the transience half alone qualifies inside a classifier block')

// ---- Content-based blocks are NEVER retried ----
const CONTENT_BLOCKS = [
    '[STEP-197 · implement] blocked by safety classifier: prompt requests credential exfiltration',
    '[STEP-42 · judge-security] blocked by safety classifier: request appears to seek malware development assistance',
    '[STEP-42 · implement] blocked by safety classifier: refused',
]
for (const b of CONTENT_BLOCKS) {
    ok(!transientClassifierBlock(b),
        `a content-based block stays operator-escalated: ${b.slice(0, 60)}…`)
}

// ---- Everything that is not a classifier block is out of domain ----
ok(!transientClassifierBlock('spawn error: Error: base branch is not a valid worktree source'),
    'a worktree/isolation failure is not a classifier block')
ok(!transientClassifierBlock('Error: model opus is unavailable — usually transient, retry later'),
    'an unrelated error that merely says "usually transient" is not retried')
ok(!transientClassifierBlock(null), 'null is not a transient block')
ok(!transientClassifierBlock(undefined), 'undefined is not a transient block')
ok(!transientClassifierBlock(''), 'the empty string is not a transient block')
ok(!transientClassifierBlock(42), 'a non-string, non-object is not a transient block')
ok(!transientClassifierBlock({}), 'an object with no reason field is not a transient block')

// The predicate is applied ONLY to block reasons and spawn errors, never to
// agent prose — but a judge reviewing this retry will quote the signature, so
// pin what the domain rule buys: the quote alone, absent the harness wrapper,
// does not qualify. (RUN-28, one field over, is the standing lesson.)
ok(!transientClassifierBlock([
    'Reviewed the DOT-558 retry.',
    '',
    '- **F-1 (low)** wave.js gates the retry on "Stage 2 classifier error" and',
    '  "usually transient"; a reworded resubmission is never attempted.',
    '',
    'STEP-1600 recorded (done)',
].join('\n')),
    'a judge REVIEWING the retry, quoting both signature phrases, is not a block')

// ---- probeRecovered: the provenance gate on the pre-spawn (bare null) path ----
// The probe's structured claim is trusted for nothing: found, blocked, an
// exact label echo, and a non-empty error string are ALL required, and the
// recovered reason still has to pass transientClassifierBlock() after.
const LABEL = 'STEP-1547 · judge-simplicity'
const GOOD = { found: true, label: LABEL, blocked: true, state: 'error', error: RUN_43, file: 'wf_b8679e05-2dc.json' }

ok(probeRecovered(GOOD, LABEL) === RUN_43,
    'a found, label-matched, blocked entry yields its error verbatim')
ok(transientClassifierBlock(probeRecovered(GOOD, LABEL)),
    'the recovered RUN-43 reason then passes the transience predicate — the retry fires')

const CONTENT = { ...GOOD, error: '[STEP-1547 · judge-simplicity] blocked by safety classifier: prompt requests credential exfiltration' }
ok(probeRecovered(CONTENT, LABEL) !== null && !transientClassifierBlock(probeRecovered(CONTENT, LABEL)),
    'a recovered CONTENT block is provenance-valid but fails transience — no retry')

ok(probeRecovered({ ...GOOD, label: 'STEP-1548 · judge-testing' }, LABEL) === null,
    'a label mismatch is rejected — another step\'s block never fires this retry')
ok(probeRecovered({ ...GOOD, blocked: false }, LABEL) === null,
    'blocked !== true is rejected — a skip or mid-flight death is never a block')
ok(probeRecovered({ ...GOOD, blocked: 'true' }, LABEL) === null,
    'a stringly-typed blocked field is rejected — strict === true only')
ok(probeRecovered({ ...GOOD, found: false }, LABEL) === null,
    'found: false recovers nothing, whatever else the probe claims')
ok(probeRecovered({ ...GOOD, error: '' }, LABEL) === null,
    'an empty error string recovers nothing')
ok(probeRecovered({ ...GOOD, error: undefined }, LABEL) === null,
    'a missing error field recovers nothing')
ok(probeRecovered(null, LABEL) === null, 'a null probe result (probe skipped/blocked/dead) recovers nothing')
ok(probeRecovered(undefined, LABEL) === null, 'an undefined probe result recovers nothing')
ok(probeRecovered({}, LABEL) === null, 'an empty probe object recovers nothing')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js" || exit 1

# ---- Source-shape guards on the ladder the predicate gates ----
# spawn() closes over workflow globals, so these are greps, not executions.
shape_fail=0
shape() { # <count> <label> <pattern>
    local want=$1 label=$2 pattern=$3 got
    got=$(grep -c "$pattern" "$WAVE")
    if [ "$got" = "$want" ]; then
        printf 'PASS: %s\n' "$label"
    else
        printf 'FAIL: %s (expected %s match(es), found %s)\n' "$label" "$want" "$got" >&2
        shape_fail=1
    fi
}

shape 1 'the rejected-spawn retry is gated by transientClassifierBlock at exactly one call site' \
    'if (transientClassifierBlock(err)) return retryTransient'
shape 1 'the retry helper is defined exactly once' \
    'const retryTransient = (err, iso) =>'
shape 1 'the rejected-spawn retry resubmits through launch() marked retried — same brief, same opts, never again' \
    'return launch(iso, true).catch((err2) =>'
shape 2 "a second failure returns today's spawn-failed, on both retry paths" \
    'spawn error on transient-classifier retry'

# ---- The pre-spawn (bare null) path: probe-gated, exactly once ----
shape 1 'the null-path retry is gated on a probe-RECOVERED reason passing the transience predicate' \
    'if (reason && transientClassifierBlock(reason))'
shape 1 'the probe claim passes through the provenance gate at exactly one call site' \
    'probeRecovered(p, stepLabel)'
shape 1 'the null-path resubmission goes through launch() marked retried — a second null never re-probes' \
    'return launch(isolated, true).catch((err2) =>'
shape 1 'a retried launch that nulls again escalates instead of probing' \
    'if (retried) return escalate()'

if grep -q 'transientClassifierBlock(text)' "$WAVE"; then
    printf 'FAIL: the null branch must never gate a retry on the bare null itself — only on a probe-recovered reason; a bare null cannot be told from an operator skip\n' >&2
    shape_fail=1
else
    printf 'PASS: the bare null itself gates no retry\n'
fi

exit $shape_fail
