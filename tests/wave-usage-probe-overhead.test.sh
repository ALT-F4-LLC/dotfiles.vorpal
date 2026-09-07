#!/bin/bash

# Behavior suite for wave-usage.js's three-way split of a wave's agents —
# judge, claimant, overhead — and specifically for the ordering of the two
# questions it asks a bootstrap brief.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `jq`, `node` and `awk` — no
# engine, no database, no network, and it never runs a workflow.
#
# HOW IT RUNS THE SCRIPT WITHOUT THE WORKFLOW TOOL. wave-usage.js fences its
# jq program and its pure reduction in `// TEST-BEGIN <region>` /
# `// TEST-END <region>` markers. This suite extracts both, writes the jq
# program to a file exactly as the workflow's agents do, runs it with the
# same flags over fixture transcripts, and feeds the printed objects into
# `classify`/`reduceRows` under node — the same path the live workflow takes,
# minus the agents that relay the jq output.
#
# WHY THIS EXISTS. wave.js spawns read-only probes (`docket step show STEP-N
# --json`) beside its executors, and the usage join once keyed on the first
# STEP-N in a brief, so each probe back-filled its tokens onto the step it had
# merely READ — one past wave put whole ledger rows on a pending step that was
# never claimed and on a superseded one. The join now reads the `docket step
# claim/record STEP-N` obligation instead, and the read test runs BEFORE that
# join: a brief that hands its agent one read command is overhead however much
# record-shaped text its prose quotes. The fixtures below are the shapes that
# ordering exists for.
#
# WHAT THIS SUITE CANNOT SEE: it exercises classification, not measurement.
# The by-message-id dedup (last write wins) and the arithmetic over the four
# typed units are asserted only far enough to prove a claimant's row carries
# its own agent's spend and nobody else's.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
USAGE="${WAVE_USAGE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave-usage.js}"
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$USAGE" ] || fatal "wave-usage.js not found at ${USAGE}"
[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
for tool in jq node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-usage-probe.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

# ---- The briefs this script keys on must still be the briefs wave.js writes.
# Every marker is duplicated prose; if wave.js drops one, the join silently
# reclassifies a whole wave, so check the two directions that matter.
grep -qF 'WAVE PROBE: not a step execution' "$WAVE"; ok $? \
    'wave.js still declares its probe briefs with the marker wave-usage reads'
grep -qF 'Run exactly this one command:' "$WAVE"; ok $? \
    'wave.js still opens a probe brief with the fixed one-command line'
grep -qF 'You are executing one step of a Docket run' "$WAVE"; ok $? \
    'wave.js still opens an executor brief with the line the drift guard reads'

# ---- Extract the two tested regions -----------------------------------------
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
    ' "$USAGE"
}

{
    extract wave-usage-extract  || fatal "bad or missing TEST markers for wave-usage-extract"
    extract wave-usage-classify || fatal "bad or missing TEST markers for wave-usage-classify"
} > "${WORK}/regions.js" || exit 2
[ -s "${WORK}/regions.js" ] || fatal "extracted regions are empty"

# The jq program reaches disk the way the workflow's agents write it.
{ cat "${WORK}/regions.js"; echo 'process.stdout.write(EXTRACT_JQ)'; } > "${WORK}/emit.js"
node "${WORK}/emit.js" > "${WORK}/wave-usage.jq" || fatal "could not evaluate EXTRACT_JQ"
[ -s "${WORK}/wave-usage.jq" ] || fatal "EXTRACT_JQ is empty"

# ---- Fixtures ---------------------------------------------------------------
# One synthetic wave directory. Each agent is a bootstrap user message plus two
# assistant messages carrying usage, so every agent has spend to misplace.
node - "$WORK/wave" <<'JS' || fatal "fixture build failed"
const fs = require('fs')
const path = require('path')
const d = process.argv[2]
fs.mkdirSync(d, { recursive: true })

const PROBE_MARKER = 'WAVE PROBE: not a step execution'

// wave.js probeBrief(), verbatim in shape, serving the step it READS.
const probe = `Run exactly this one command:

  docket step show STEP-3146 --json

Return its output VERBATIM as your entire final reply — every line, unedited.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

${PROBE_MARKER}. Your usage is wave overhead. This
read serves STEP-3146, which is the step it READS, not a step you run — the
usage join must not attribute your tokens to it.`

// THE REGRESSION FIXTURE: the same probe, whose prose also QUOTES the
// obligation it is reading about. Record-shaped text in a read-only brief is
// exactly what the old ordering (join first, label second) could not survive.
const quotingProbe = probe.replace(
    'read serves STEP-3146',
    'read serves STEP-3146 (whose executor will run `docket step record STEP-3146` once it claims)')

// A probe from before the marker existed: no declaration at all, just the one
// read command. "Only tells an agent to read/show a step" is the whole shape.
const legacyProbe = `Run exactly this one command:

  docket step show STEP-3158 --json

Return its output verbatim as your entire final reply.`

// A real claimant. The join reads the obligation, never the prose around it.
const executor = `You are executing one step of a Docket run (dispatch DISPATCH-9).

Obligations:
1. Claim it: \`docket step claim STEP-3156 --owner wave:STEP-3156 --render --json\`
3. Record it yourself with \`docket step record STEP-3156 --artifact-file ...\`

Context: your work follows STEP-3146 and must not touch STEP-3158.`

// A second claimant on a lower-numbered step, so the row order is provably
// numeric and the exclude scenario has a step left over to keep.
const executor2 = executor.replace(/STEP-3156/g, 'STEP-3150')

// A judge. Steps mode leaves it to seats mode; seats mode keys it by
// (proposal, seat).
const judge = `You are seated on a Docket gate panel.

Cast with: docket vote cast PROP-77 --voter reviewer --decision approve`

// An executor brief whose obligation was reworded out from under the join. It
// also carries a read command, to prove the probe test cannot swallow a
// claimant: this must still be a hard error, never overhead.
const drifted = `You are executing one step of a Docket run (dispatch DISPATCH-9).

First read the row: \`docket step show STEP-3160 --json\`, then do the work and
mark it finished when you are done.`

// A wave agent whose bootstrap arrives list-shaped, so the brief's newlines are
// JSON-encoded as literal backslash-n. Classification must survive the encoding.
const LIST_SHAPED = { 'agent-alist.jsonl': legacyProbe.replace('STEP-3158', 'STEP-3166') }

const AGENTS = {
    'agent-aprobe.jsonl': probe,
    'agent-aquoting.jsonl': quotingProbe,
    'agent-alegacy.jsonl': legacyProbe,
    'agent-aexec.jsonl': executor,
    'agent-aexec2.jsonl': executor2,
    'agent-ajudge.jsonl': judge,
    ...LIST_SHAPED,
}

const usage = (out) => ({
    input_tokens: 5, output_tokens: out,
    cache_creation_input_tokens: 1000, cache_read_input_tokens: 2000,
})

function write(name, bootstrap, outDir = d, listed = false) {
    const content = listed ? [{ type: 'text', text: bootstrap }] : bootstrap
    const lines = [{ type: 'user', message: { content } }]
    // msg-a is written twice with a GROWING output count: the dedup keeps the
    // last, so this agent's output total is 100 + 250, not 40 + 250.
    const model = name === 'agent-aexec2.jsonl' ? undefined : 'claude-opus-5'
    const firstModel = name === 'agent-aexec.jsonl' ? 'stale-stream-model' : model
    const finalModel = name === 'agent-aexec.jsonl' ? 'claude-fable-5-1' : model
    lines.push({ type: 'assistant', message: { id: 'msg-a', model: firstModel, usage: usage(40) } })
    lines.push({ type: 'assistant', message: { id: 'msg-a', model: finalModel, usage: usage(100) } })
    lines.push({ type: 'assistant', message: { id: 'msg-b', model, usage: usage(250) } })
    fs.writeFileSync(path.join(outDir, name), lines.map((o) => JSON.stringify(o)).join('\n') + '\n')
}

for (const [name, brief] of Object.entries(AGENTS)) write(name, brief, d, name in LIST_SHAPED)

// The drift fixture lives in its own directory: it is a whole-run failure, and
// one verdict cannot say two things at once.
const driftDir = path.join(path.dirname(d), 'drift')
fs.mkdirSync(driftDir, { recursive: true })
write('agent-adrift.jsonl', drifted, driftDir)
JS

# ---- Run the jq program over every fixture, exactly as an agent would ----------
# One extract per transcript, collected into {dir: {file: extract}}.
extracts_ok=0
for sub in wave drift; do
    mkdir -p "${WORK}/extracts/${sub}"
    for f in "${WORK}/${sub}"/agent-*.jsonl; do
        name=$(basename "$f")
        if ! jq -c -n -R -f "${WORK}/wave-usage.jq" "$f" > "${WORK}/extracts/${sub}/${name}.json"; then
            printf 'jq failed on %s/%s\n' "$sub" "$name" >&2
            extracts_ok=1
        fi
    done
done
ok $extracts_ok 'the jq program runs clean over every fixture transcript'

# ---- Classification and reduction under node ----------------------------------
cat "${WORK}/regions.js" > "${WORK}/suite.js"
cat >> "${WORK}/suite.js" <<'JS'

const fs = require('fs')
const path = require('path')
const root = process.argv[2]

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// Directory order, as the workflow sorts its scout's listing.
function load(sub) {
    const dir = path.join(root, 'extracts', sub)
    return fs.readdirSync(dir).sort().map((n) => ({
        file: n.replace(/\.json$/, ''),
        extract: JSON.parse(fs.readFileSync(path.join(dir, n), 'utf8')),
    }))
}
const wave = load('wave')
const drift = load('drift')

// Exercise missing and synthetic model fields through the actual jq extractor,
// not only the reducer. Bootstrap prose cannot supply runtime observations.
const { spawnSync } = require('child_process')
const partialTranscript = [
    { type:'user', message:{content:'You are executing one step of a Docket run. docket step claim STEP-99 --owner wave. Requested model: claude-fable-5-1, effort: max.'} },
    { type:'assistant', message:{id:'known', model:'claude-opus-5', usage:{output_tokens:1}} },
    { type:'assistant', message:{id:'missing', usage:{output_tokens:1}} },
    { type:'assistant', message:{id:'synthetic', model:'<synthetic>', usage:{output_tokens:0}} },
].map(JSON.stringify).join('\n')
const partialRun = spawnSync('jq', ['-c', '-n', '-R', EXTRACT_JQ], {
    input:partialTranscript, encoding:'utf8',
})
ok(partialRun.status === 0, 'partial model observations parse without changing usage extraction')
const partialExtract = JSON.parse(partialRun.stdout)
ok(partialExtract.models_observed.join(',') === 'claude-opus-5'
    && partialExtract.model_observation_complete === false,
    'only actual model fields are observed; missing fields and synthetic messages keep coverage incomplete')

const by = (list, file) => list.find((r) => r.file === file)
const overheadLabel = (out, file) => (out.overhead.agents.find((a) => a.file === file) || {}).label || ''

// ---- The extractor's own reads, before any precedence is applied ----
ok(by(wave, 'agent-aexec.jsonl').extract.record === 'STEP-3156',
    'the record join reads the step from the claim/record obligation')
ok(by(wave, 'agent-aquoting.jsonl').extract.record === 'STEP-3146',
    'fixture integrity: the quoting probe really does match the record join on its own')
ok(by(wave, 'agent-aquoting.jsonl').extract.probe === true,
    'and the read test sees it as a probe, so precedence is what keeps it out of the ledger')
ok(by(wave, 'agent-alist.jsonl').extract.probe === true,
    'the read-job regex accepts the literal backslash-n of a JSON-encoded bootstrap')
ok(by(wave, 'agent-adrift.jsonl') === undefined && by(drift, 'agent-adrift.jsonl').extract.exec === true,
    'the executor opening line is read even when no obligation follows it')
const cast = by(wave, 'agent-ajudge.jsonl').extract.cast
ok(cast && cast.proposal === 'PROP-77' && cast.voter === 'reviewer',
    'the cast join reads proposal and seat from one match on the cast command')

// ---- Steps mode: only the claimants reach the ledger ----
const steps = reduceRows(wave, 'steps', [])
ok(steps.errors.length === 0,
    'steps mode reports no error on a wave of two executors, four probes and a judge')

const keyed = [...new Set(steps.rows.map((r) => r.step))]
ok(keyed.join(',') === 'STEP-3150,STEP-3156',
    `the only steps keyed are the ones an agent was obliged to record, in numeric order (got: ${keyed.join(',') || 'none'})`)
for (const probed of ['STEP-3146', 'STEP-3158', 'STEP-3166']) {
    ok(!steps.rows.some((r) => r.step === probed),
        `no ledger row is emitted for ${probed}, which was only READ`)
}

// The regression itself: a read-only brief that quotes a record obligation.
ok(overheadLabel(steps, 'agent-aquoting.jsonl').startsWith('read-only probe'),
    'a probe brief QUOTING `docket step record STEP-N` is still overhead, not a claimant')
ok(overheadLabel(steps, 'agent-aprobe.jsonl') === 'read-only probe, mentions STEP-3146',
    'a marked probe is named a probe and labeled with the step it read')
ok(overheadLabel(steps, 'agent-alegacy.jsonl').startsWith('read-only probe'),
    'a marker-less brief whose whole job is one read command is named a probe')
ok(overheadLabel(steps, 'agent-alist.jsonl').startsWith('read-only probe'),
    'and so is one whose bootstrap arrived JSON-encoded (list-shaped content)')
ok(!steps.overhead.agents.some((a) => a.label.startsWith('not a wave agent')),
    'no wave probe is left in the unrecognized bucket')

const seated = steps.skipped.find((s) => s.reason === 'seated')
ok(seated && seated.label === 'agent-ajudge.jsonl (PROP-77/reviewer)',
    'the judge is skipped here and named for seats mode, never keyed to a step')
ok(steps.skipped.length === 1, 'nothing else is skipped in steps mode')

ok(steps.overhead.agents.length === 4,
    `all four probes are counted into one reported overhead total (got ${steps.overhead.agents.length})`)
ok(steps.overhead.sums.output_tokens === 4 * 350 && steps.overhead.sums.cache_read_tokens === 4 * 4000,
    'the overhead sums carry the probes\' own deduped spend')

// The claimant's rows carry its own agent's spend only — 2 messages after the
// dedup, output 100+250, cache_read 2000+2000 — with no probe folded in.
const want = { input_tokens: 10, output_tokens: 350, cache_creation_tokens: 2000, cache_read_tokens: 4000 }
const unitsOf = (rows, step) => Object.fromEntries(rows.filter((r) => r.step === step).map((r) => [r.unit, r.quantity]))
ok(JSON.stringify(unitsOf(steps.rows, 'STEP-3156')) === JSON.stringify(want),
    "the claimant's four units are its own agent's, deduped by message id (last write wins)")
ok(steps.rows.filter((r) => r.step === 'STEP-3156').map((r) => r.unit).join(',') ===
    'input_tokens,output_tokens,cache_creation_tokens,cache_read_tokens',
    'the four unit rows come out in the ledger\'s order, named exactly as the engine wants them')

// Serving models are observed message fields, separate from requested routing.
const observed = steps.model_observations.find((o) => o.key === 'STEP-3156')
ok(observed.models.join(',') === 'claude-fable-5-1,claude-opus-5' && observed.complete,
    'a fallback run reports both serving models from deduplicated messages')
ok(!observed.models.includes('stale-stream-model'),
    'a superseded stream record cannot add a serving model')
ok(observed.source === 'assistant.message.model' && observed.effort_resolved === 'unknown',
    'attribution names its source and does not infer an unobserved effort')
const absent = steps.model_observations.find((o) => o.key === 'STEP-3150')
ok(absent.models.length === 0 && absent.complete === false,
    'a transcript without model fields keeps attribution unknown')
ok(steps.model_observations.filter((o) => o.kind === 'overhead').length === 4,
    'probe observations remain overhead rather than being credited to a step')
ok(!steps.rows.some((r) => 'model' in r || 'effort' in r),
    'model observations do not change the engine token back-fill row contract')

// ---- exclude: a key a prior back-fill already carries ----
const excluded = reduceRows(wave, 'steps', ['STEP-3156'])
ok(!excluded.rows.some((r) => r.step === 'STEP-3156') && excluded.rows.some((r) => r.step === 'STEP-3150'),
    'exclude drops the named step and keeps the other')
const ex = excluded.skipped.find((s) => s.reason === 'excluded')
ok(ex && ex.file === 'agent-aexec.jsonl' && ex.key === 'STEP-3156',
    'and the dropped key is reported by file and step, never silently')
ok(excluded.overhead.agents.length === 4 && excluded.errors.length === 0,
    'exclude touches nothing else')

// ---- Seats mode: the mirror image ----
const seats = reduceRows(wave, 'seats', [])
ok(seats.errors.length === 0, 'seats mode reports no error over the same directory')
const seatKeys = [...new Set(seats.rows.map((r) => `${r.proposal}/${r.voter}`))]
ok(seatKeys.join(',') === 'PROP-77/reviewer',
    'seats mode emits exactly the judge, keyed by (proposal, seat)')
ok(seats.rows.length === 4 && seats.rows.every((r) => r.proposal === 'PROP-77' && r.voter === 'reviewer'),
    'and the judge gets four unit rows carrying its proposal and seat')
const un = seats.skipped.filter((s) => s.reason === 'unattributed').map((s) => s.file)
ok(un.includes('agent-aexec.jsonl') && un.includes('agent-aprobe.jsonl'),
    'and drops the claimants and probes with a named reason, so the modes partition the wave')
ok(seats.overhead.agents.length === 0, 'seats mode reports no overhead of its own')
const seatEx = reduceRows(wave, 'seats', ['reviewer'])
ok(seatEx.rows.length === 0 && seatEx.skipped.some((s) => s.reason === 'excluded' && s.key[1] === 'reviewer'),
    'a bare seat name in exclude drops that seat and reports it')

ok(seats.model_observations.length === 1 && seats.model_observations[0].kind === 'seat'
    && seats.model_observations[0].key.join('/') === 'PROP-77/reviewer',
    'seat mode carries judge observations separately from step mode')
const partialObservation = reduceRows([{ file:'partial', extract: {
    ...by(wave, 'agent-aexec.jsonl').extract,
    models_observed:['claude-opus-5'], model_observation_complete:false,
}}], 'steps', []).model_observations[0]
ok(partialObservation.models[0] === 'claude-opus-5' && !partialObservation.complete,
    'a known model does not establish complete attribution when other messages lack it')

// ---- Seats mode sort order: grouped by proposal, then seat ----
const twoPanels = [
    { file: 'a', extract: { bootstrap: true, cast: { proposal: 'PROP-9', voter: 'zed' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
    { file: 'b', extract: { bootstrap: true, cast: { proposal: 'PROP-10', voter: 'amy' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
    { file: 'c', extract: { bootstrap: true, cast: { proposal: 'PROP-10', voter: 'bob' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
]
const order = [...new Set(reduceRows(twoPanels, 'seats', []).rows.map((r) => `${r.proposal}/${r.voter}`))]
ok(order.join(',') === 'PROP-10/amy,PROP-10/bob,PROP-9/zed',
    'seats rows sort lexicographically by (proposal, voter), grouped per proposal')

// ---- The drift guard survives the new ordering ----
const drifted = reduceRows(drift, 'steps', [])
ok(drifted.errors.length === 1 && drifted.rows.length === 0 && drifted.overhead.agents.length === 0,
    'an executor brief with no claim/record obligation is a hard error, not overhead')
ok(drifted.errors[0].includes('have drifted'),
    'and the failure names the drift rather than emptying the ledger silently')

// ---- Silence must not look like success ----
const silent = [{ file: 'agent-quiet.jsonl', extract: {
    ...by(wave, 'agent-aexec.jsonl').extract,
    usage: { input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0 },
} }]
const quiet = reduceRows(silent, 'steps', [])
ok(quiet.errors.length === 1 && quiet.errors[0].includes('carries no usage'),
    'a claimant whose transcript carries no usage is an error, not a zero row')
const unread = [{ file: 'agent-blank.jsonl', extract: {
    bootstrap: false, cast: null, record: null, probe: false, exec: false, step_mention: null, usage: want,
} }]
const unreadResult = reduceRows(unread, 'steps', [])
ok(unreadResult.errors[0].includes('no user message'),
    'an agent with no bootstrap at all cannot be classified and is an error')
ok(unreadResult.errors[0].includes('"bootstrap":false') && unreadResult.errors[0].includes('"step_mention":null'),
    'the thrown error names the agent\'s raw structured answer beside the jq verdict, not just the file name')

// ---- A relayed bootstrap:false, checked twice, is a misreport, not an error ----
// wave.js never dispatches an agent without a bootstrap brief, so this is a
// case a script cannot rule out on its own — a second independent read
// repeating the same answer is treated as a relay misreport and folded into
// overhead (with its usage) rather than thrown, so it cannot sink the join.
const misreport = [{ file: 'agent-misreport.jsonl', extract: {
    bootstrap: false, bootstrapFallback: true, cast: null, record: null, probe: true, exec: false,
    step_mention: 'STEP-4541', usage: want,
} }]
const misreportResult = reduceRows(misreport, 'steps', [])
ok(misreportResult.errors.length === 0 && misreportResult.overhead.agents.length === 1,
    'a bootstrap:false confirmed on retry is folded into overhead, not thrown as an error')
ok(UNITS.every((u) => misreportResult.overhead.sums[u] === want[u]),
    'and its usage is still counted into the overhead total, not dropped')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js" "$WORK"
ok $? 'the classification suite under node passes'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
