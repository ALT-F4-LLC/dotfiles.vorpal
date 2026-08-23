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
# ALSO NOT COVERED, and load-bearing: in the harness measured while this was
# written (claude 2.1.241) a pre-spawn classifier block resolves agent() to a
# BARE null — `if (await <preflight>(...)) return null` — and the reason text
# is emitted only onto the progress stream as workflowProgress[].error. A
# workflow script cannot read that. So the predicate below can only fire on a
# REJECTED spawn (one whose error object carries the text), and the exact
# RUN-43 shape stays unretried until the harness surfaces the reason in-band.
# See the DOT-558 note on handle()'s null branch for why retrying a bare null
# anyway would be worse: it would relaunch operator-skipped agents.

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

cat "${WORK}/predicates.js" > "${WORK}/suite.js"
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

shape 1 'the retry is gated by transientClassifierBlock at exactly one call site' \
    'if (transientClassifierBlock(err)) return retryTransient'
shape 1 'the retry helper is defined exactly once' \
    'const retryTransient = (err, iso) =>'
shape 1 'the retry resubmits through the same launch() path — same brief, same opts' \
    'return launch(iso).catch((err2) =>'
shape 1 "a second failure returns today's spawn-failed" \
    'spawn error on transient-classifier retry'

if grep -q 'transientClassifierBlock(text)' "$WAVE"; then
    printf 'FAIL: the null (SPAWN PRODUCED NOTHING) branch must not gate a retry — a bare null cannot be told from an operator skip\n' >&2
    shape_fail=1
else
    printf 'PASS: the null branch retries nothing\n'
fi

exit $shape_fail
