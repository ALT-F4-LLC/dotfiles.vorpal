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
# its own agent's spend and nobody else's. The tool-call count is asserted
# the same way: distinct tool_use block ids across lines, since the
# transcript writes one content block per line under a shared message id.
# The coordination section is exercised over a synthetic manifest and wave
# return, the two inputs the live conductor passes in.
#
# Seats-mode selection is exercised three ways: SELECT_JQ over the fixtures,
# the scout's own fenced command block (rendered from scoutBrief and run under
# bash over fixture transcripts behind a ~/.claude/projects slug glob, with
# its `--- seats ---` split and `seats_exit` line checked), and
# filesToExtract over the reply shape the scout returns. That structured
# reply is a fixture here: no agent copies the block's output into it.

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
grep -qF 'WAVE CLAIM: not a step execution' "$WAVE"; ok $? \
    'wave.js still declares its claim agent with the marker wave-usage reads'

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
    extract wave-usage-select   || fatal "bad or missing TEST markers for wave-usage-select"
    extract wave-usage-classify || fatal "bad or missing TEST markers for wave-usage-classify"
    extract wave-usage-paths    || fatal "bad or missing TEST markers for wave-usage-paths"
} > "${WORK}/regions.js" || exit 2
[ -s "${WORK}/regions.js" ] || fatal "extracted regions are empty"

# The jq program reaches disk the way the workflow's agents write it.
{ cat "${WORK}/regions.js"; echo 'process.stdout.write(EXTRACT_JQ)'; } > "${WORK}/emit.js"
node "${WORK}/emit.js" > "${WORK}/wave-usage.jq" || fatal "could not evaluate EXTRACT_JQ"
[ -s "${WORK}/wave-usage.jq" ] || fatal "EXTRACT_JQ is empty"
# The seats-mode selection program, written to disk the way the scout writes it.
{ cat "${WORK}/regions.js"; echo 'process.stdout.write(SELECT_JQ)'; } > "${WORK}/emit-select.js"
node "${WORK}/emit-select.js" > "${WORK}/wave-usage-select.jq" || fatal "could not evaluate SELECT_JQ"
[ -s "${WORK}/wave-usage-select.jq" ] || fatal "SELECT_JQ is empty"

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

Return its output VERBATIM as \`output\` in the structured output: no summary,
no commentary, no code fence.

Run nothing else: no vote, no investigation. You are a
read-only probe reporting what the record currently says.

${PROBE_MARKER}; it READS STEP-3146.`

// THE REGRESSION FIXTURE: the same probe, whose prose also QUOTES the
// obligation it is reading about. Record-shaped text in a read-only brief is
// exactly what the old ordering (join first, label second) could not survive.
const quotingProbe = probe.replace(
    'it READS STEP-3146',
    'it READS STEP-3146 (whose executor will run `docket step record STEP-3146` once it claims)')

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

// The harness may open a transcript with a relay of the operator's request,
// ahead of the brief. Its text is shaped after a live transcript's.
const RELAY = `[Workflow harness — user request] The harness relays, verbatim and indented below, the user request that triggered this workflow run. Where the computed task conflicts with this request, this request wins:
  The harness has been patched.`

// A tool result, read back after the brief, that quotes a judge's cast
// command. Only the bootstrap says what an agent was briefed to do, so this
// must neither seat the agent nor select its transcript in seats mode.
const QUOTED_CAST = {
    type: 'user',
    message: { content: [{ type: 'tool_result', tool_use_id: 'toolu-a',
        content: 'artifact: the judge ran `docket vote cast PROP-77 --voter reviewer --decision approve`' }] },
}

function write(name, bootstrap, outDir = d, listed = false, relayed = false, quotesCast = false) {
    const content = listed ? [{ type: 'text', text: bootstrap }] : bootstrap
    const lines = [{ type: 'user', message: { content } }]
    if (relayed) lines.unshift({ type: 'user', message: { content: RELAY } })
    if (quotesCast) lines.push(QUOTED_CAST)
    // msg-a is written twice with a GROWING output count: the dedup keeps the
    // last, so this agent's output total is 100 + 250, not 40 + 250.
    const model = name === 'agent-aexec2.jsonl' ? undefined : 'claude-opus-5'
    const firstModel = name === 'agent-aexec.jsonl' ? 'stale-stream-model' : model
    const finalModel = name === 'agent-aexec.jsonl' ? 'claude-fable-5-1' : model
    // Content blocks arrive one per line under a shared message id, so a
    // tool_use count keyed by message id (last wins, like usage) would keep
    // only the last block's calls. Four tool_use lines, three distinct block
    // ids: the rewritten msg-b line repeats toolu-b2, which must count once.
    const call = (id) => ({ type: 'tool_use', id, name: 'Bash', input: {} })
    lines.push({ type: 'assistant', message: { id: 'msg-a', model: firstModel, usage: usage(40), content: [{ type: 'text', text: 'reading' }] } })
    lines.push({ type: 'assistant', message: { id: 'msg-a', model: finalModel, usage: usage(100), content: [call('toolu-a')] } })
    lines.push({ type: 'assistant', message: { id: 'msg-b', model, usage: usage(250), content: [call('toolu-b1'), call('toolu-b2')] } })
    lines.push({ type: 'assistant', message: { id: 'msg-b', model, usage: usage(250), content: [call('toolu-b2')] } })
    // A schema'd agent ends with the StructuredOutput call its schema forces:
    // its return, not investigation, so it never counts as a tool use.
    lines.push({ type: 'assistant', message: { id: 'msg-b', model, usage: usage(250),
        content: [{ type: 'tool_use', id: 'toolu-return', name: 'StructuredOutput', input: {} }] } })
    fs.writeFileSync(path.join(outDir, name), lines.map((o) => JSON.stringify(o)).join('\n') + '\n')
}

for (const [name, brief] of Object.entries(AGENTS)) {
    write(name, brief, d, name in LIST_SHAPED, false, name === 'agent-aexec.jsonl' || name === 'agent-aprobe.jsonl')
}

// The drift fixture lives in its own directory: it is a whole-run failure, and
// one verdict cannot say two things at once.
const driftDir = path.join(path.dirname(d), 'drift')
fs.mkdirSync(driftDir, { recursive: true })
write('agent-adrift.jsonl', drifted, driftDir)

// A panel with one re-seated seat, in its own directory so the wave
// fixture's counts stay what the assertions above say. The sentence is the
// one tribunal.js opens a re-seated judge's brief with.
const panelDir = path.join(path.dirname(d), 'panel')
fs.mkdirSync(panelDir, { recursive: true })
write('agent-pjudge.jsonl', judge, panelDir)
write('agent-preseat.jsonl', judge.replace('--voter reviewer', '--voter security') + `

THIS IS A SECOND ATTEMPT AT YOUR SEAT. A prior agent held it and returned
without a recorded cast.`, panelDir)
// A judge whose brief sits behind the harness relay: the seats-mode selector
// must read past the relay to the brief, as the extract does.
write('agent-prelayjudge.jsonl', judge.replace('PROP-77 --voter reviewer', 'PROP-78 --voter architect'),
    panelDir, false, true)

// Relayed transcripts, in their own directory: the relay comes first and the
// brief second, so a selector that reads the first user message sees no
// obligation and no probe marker.
const relayDir = path.join(path.dirname(d), 'relay')
fs.mkdirSync(relayDir, { recursive: true })
write('agent-arelayexec.jsonl', executor.replace(/STEP-3156/g, 'STEP-3175'), relayDir, false, true)
write('agent-arelayprobe.jsonl', probe.replace(/STEP-3146/g, 'STEP-3176'), relayDir, false, true)

// The claim path, in its own directory: wave.js's claim agent (claimBrief()
// in shape) and the executor it claims for, whose brief closes with a packet
// that quotes another step's obligations.
const claimDir = path.join(path.dirname(d), 'claim')
fs.mkdirSync(claimDir, { recursive: true })
write('agent-cclaim.jsonl', `Run exactly this one command:

  ~/.docket/bin/wave-claim --step STEP-3180 --owner wave:STEP-3180:1 --attempt 1 --module '/repo/.claude/docket-packets/STEP-3180.a1.js' --metadata '{}'

It claims STEP-3180 under that owner, parks the lease token in the step's
private scratch dir, and writes the rendered packet for the executor the wave
launches next.

Return its output VERBATIM as \`output\` in the structured output.

Run nothing else.

WAVE CLAIM: not a step execution; it claims STEP-3180 for its executor.`, claimDir, false, false, true)
write('agent-cexec.jsonl', `You are executing one step of a Docket run. Follow these obligations exactly.

YOUR ASSIGNMENT: step STEP-3180 (issue DOT-1, run RUN-1). The wave claimed
it for you with \`docket step claim STEP-3180 --owner wave:STEP-3180:1 --render\`
(attempt 1): the lease is live.

3. Record it yourself: \`docket step record STEP-3180 --artifact-file x < y\`

----- BEGIN WORK PACKET STEP-3180 -----
== REQUEST
An old run's note: \`docket step record STEP-999 --artifact-file x\`.
----- END WORK PACKET STEP-3180 -----`, claimDir)
JS

# ---- Run the jq program over every fixture, exactly as an agent would ----------
# One extract per transcript, collected into {dir: {file: extract}}.
extracts_ok=0
for sub in wave drift panel relay claim; do
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

# ---- Seats-mode selection, run once over a mixed corpus as the scout runs it ----
# The wave's claimants, probes and judge, the panel's judges (one re-seated,
# one behind the harness relay), the relay-first claimant and probe, and the
# claim path. One jq invocation over many files, as the scout's glob hands
# them over.
jq -r -n -R -f "${WORK}/wave-usage-select.jq" \
    "${WORK}"/wave/agent-*.jsonl "${WORK}"/panel/agent-*.jsonl \
    "${WORK}"/relay/agent-*.jsonl "${WORK}"/claim/agent-*.jsonl \
    > "${WORK}/selected.txt"
ok $? 'the selection program runs clean over the mixed corpus'

# One malformed transcript in the batch aborts the whole selection. The
# status is the only signal: seats_exit carries it, and filesToExtract
# refuses a non-zero one rather than reading a short seat list as complete.
mkdir -p "${WORK}/malformed"
printf '%s\n' '{"type":"user","message":"not an object"}' > "${WORK}/malformed/agent-bad.jsonl"
jq -r -n -R -f "${WORK}/wave-usage-select.jq" \
    "${WORK}/malformed/agent-bad.jsonl" "${WORK}"/panel/agent-pjudge.jsonl \
    > "${WORK}/selected-malformed.txt" 2>/dev/null
[ $? -ne 0 ]; ok $? 'a malformed transcript fails the selection batch with a non-zero status'

# ---- The scout's seats-mode command block, rendered and run as the scout runs it ----
# The wave fixtures sit behind a ~/.claude/projects slug, so the block's path
# carries the `*` glob shellPath writes. The block runs under bash with stdin
# closed: a jq call that lost its transcript operand reads stdin instead.
SCOUT_DIR="${WORK}/home/.claude/projects/-Users-x-Development-repository-github-com-ORG-repo-git-main/5575d475/subagents/workflows/wf_1"
mkdir -p "$SCOUT_DIR" && cp "${WORK}"/wave/agent-*.jsonl "$SCOUT_DIR"/ || fatal "scout fixture copy failed"
{
    cat "${WORK}/regions.js"
    echo 'const dir = process.argv[2]; const mode = "seats"'
    extract wave-usage-scout || fatal "bad or missing TEST markers for wave-usage-scout"
    echo 'process.stdout.write(scoutBrief)'
} > "${WORK}/emit-scout.js" || exit 2
node "${WORK}/emit-scout.js" "$SCOUT_DIR" > "${WORK}/scout-brief.txt" || fatal "could not render scoutBrief"
awk '/^```$/ { n++; next } n == 1' "${WORK}/scout-brief.txt" > "${WORK}/seats-block.sh"
[ -s "${WORK}/seats-block.sh" ]; ok $? 'the seats-mode scout brief carries a fenced command block'
bash "${WORK}/seats-block.sh" < /dev/null > "${WORK}/scout-out.txt" 2> "${WORK}/scout-err.txt"
grep -qx 'seats_exit=0' "${WORK}/scout-out.txt"; ok $? \
    "the seats block's selection exits 0 over the fixture transcripts (stderr: $(head -c 300 "${WORK}/scout-err.txt"))"
scout_seats=$(sed -n '/^--- seats ---$/,$p' "${WORK}/scout-out.txt" | sed '1d' | grep -v '^seats_exit=')
[ "$scout_seats" = "${SCOUT_DIR}/agent-ajudge.jsonl" ]; ok $? \
    "the paths after --- seats --- are exactly the fixture seat transcripts (got: ${scout_seats:-none})"
scout_files=$(sed -n '/^--- seats ---$/q;p' "${WORK}/scout-out.txt" | grep -v '^exit=')
want_files=$(for f in "${SCOUT_DIR}"/agent-*.jsonl; do printf '%s\n' "$f"; done | LC_ALL=C sort)
[ -n "$scout_files" ] && [ "$scout_files" = "$want_files" ]; ok $? \
    'the paths before --- seats --- are every fixture transcript, sorted'

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
const panel = load('panel')
const relay = load('relay')
const claimPath = load('claim')

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
ok(by(wave, 'agent-aexec.jsonl').extract.tool_uses === 3,
    `tool_uses counts distinct tool_use block ids across lines (4 lines, 3 ids), not the last block per message, and not the StructuredOutput return (got ${by(wave, 'agent-aexec.jsonl').extract.tool_uses})`)
ok(by(wave, 'agent-ajudge.jsonl').extract.reseat === false && by(panel, 'agent-preseat.jsonl').extract.reseat === true,
    'a re-seated judge is read from the respawn sentence in its bootstrap, a first seating is not')

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
ok(!steps.rows.some((r) => r.unit === 'tool_uses'),
    'steps mode keeps the four-row ledger contract: no tool_uses row reaches dispatch backfill-usage')

// ---- The claim path: the claim agent is overhead, its executor the claimant ----
ok(by(claimPath, 'agent-cclaim.jsonl').extract.claim_agent === true &&
    by(claimPath, 'agent-cclaim.jsonl').extract.record === null,
    'the claim agent is read as one, and its brief joins no step')
ok(by(claimPath, 'agent-cexec.jsonl').extract.record === 'STEP-3180' &&
    by(claimPath, 'agent-cexec.jsonl').extract.claim_agent === false,
    "the executor joins its own step, ahead of anything its packet quotes")
const claimSteps = reduceRows(claimPath, 'steps', [])
ok(claimSteps.errors.length === 0 && [...new Set(claimSteps.rows.map((r) => r.step))].join(',') === 'STEP-3180',
    "only the executor's spend reaches STEP-3180's ledger rows")
ok(overheadLabel(claimSteps, 'agent-cclaim.jsonl') === 'claim agent, mentions STEP-3180',
    'the claim agent lands in overhead under its own label')
ok(JSON.stringify(unitsOf(claimSteps.rows, 'STEP-3180')) === JSON.stringify(want),
    "the claim agent's spend is never folded into the step it claimed")

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
ok(seats.rows.length === 5 && seats.rows.every((r) => r.proposal === 'PROP-77' && r.voter === 'reviewer'),
    'and the judge gets four token unit rows plus tool_uses, all carrying its proposal and seat')
ok(seats.rows.map((r) => r.unit).join(',') === 'input_tokens,output_tokens,cache_creation_tokens,cache_read_tokens,tool_uses',
    'the seat rows keep the ledger order with tool_uses last')
ok(seats.rows.find((r) => r.unit === 'tool_uses').quantity === 3,
    'the seat\'s tool_uses row carries its own distinct tool calls')
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

// ---- Relay-mangled keys: unquoted before they reach a row, or refused ----
// One measured join returned two step ids wrapped in literal quotes and the
// engine refused the whole batch; the join now strips one layer of quotes
// from every key and errors on a step key that still is not STEP-N.
const execExtract = by(wave, 'agent-aexec.jsonl').extract
const quotedStep = reduceRows([{ file: 'agent-q.jsonl', extract: { ...execExtract, record: '"STEP-3170"' } }], 'steps', [])
ok(quotedStep.errors.length === 0 && [...new Set(quotedStep.rows.map((r) => r.step))].join(',') === 'STEP-3170',
    `a record key wrapped in literal quotes is unquoted before it becomes a row (got ${JSON.stringify([...new Set(quotedStep.rows.map((r) => r.step))])})`)
const spacedStep = reduceRows([{ file: 'agent-s.jsonl', extract: { ...execExtract, record: ' \'STEP-3171\' ' } }], 'steps', [])
ok(spacedStep.errors.length === 0 && [...new Set(spacedStep.rows.map((r) => r.step))].join(',') === 'STEP-3171',
    'surrounding whitespace and single quotes are stripped the same way')
const mangledStep = reduceRows([{ file: 'agent-m.jsonl', extract: { ...execExtract, record: 'STEP 3172' } }], 'steps', [])
ok(mangledStep.rows.length === 0 && mangledStep.errors.length === 1 && /agent-m\.jsonl.*not a STEP-N id/.test(mangledStep.errors[0]),
    `a record key that is not STEP-N after unquoting is an error naming the file, never a row (got ${JSON.stringify(mangledStep.errors)})`)
const judgeExtract = by(wave, 'agent-ajudge.jsonl').extract
const quotedSeat = reduceRows([{ file: 'agent-j.jsonl', extract: { ...judgeExtract, cast: { proposal: '"PROP-78"', voter: '"reviewer"' } } }], 'seats', [])
ok(quotedSeat.errors.length === 0 && quotedSeat.rows.every((r) => r.proposal === 'PROP-78' && r.voter === 'reviewer'),
    'a quoted proposal and seat are unquoted in seats mode too')

// ---- Paths the agents type: the project slug is a glob, the directory is args.dir ----
// Two measured joins failed on the flattened project directory retyped
// (`github-com` → `github.com`): once by extract agents, once by the scout's
// whole listing. The shell command carries that component as `*`, and the
// listing is rebuilt from the literal directory plus the scout's basename.
const slugDir = '/Users/x/.claude/projects/-Users-x-Development-repository-github-com-ORG-repo-git-main/5575d475/subagents/workflows/wf_1'
ok(shellPath(`${slugDir}/agent-A.jsonl`) ===
    "'/Users/x/.claude/projects/'*'/5575d475/subagents/workflows/wf_1/agent-A.jsonl'",
    `the flattened project directory is left as a bare * between quoted halves (got ${shellPath(`${slugDir}/agent-A.jsonl`)})`)
ok(shellPath('/tmp/plain/agent-B.jsonl') === "'/tmp/plain/agent-B.jsonl'",
    'a path outside ~/.claude/projects is quoted whole')
ok(shellPath("/tmp/it's/agent-C.jsonl") === "'/tmp/it'\\''s/agent-C.jsonl'",
    'a single quote in the path is still escaped')
const retypedListing = rebuildListing(slugDir + '/', [
    `${slugDir.replace('github-com', 'github.com')}/agent-B.jsonl`,
    `${slugDir}/agent-A.jsonl`,
    `${slugDir.replace('github-com', 'github_com')}/agent-A.jsonl`,
])
ok(retypedListing.files.join(',') === `${slugDir}/agent-A.jsonl,${slugDir}/agent-B.jsonl` && retypedListing.retyped === 2,
    `a listing with the directory retyped is rebuilt on args.dir, deduplicated and sorted, and the retypes are counted (got ${JSON.stringify(retypedListing)})`)

// ---- Seats-mode selection: only judges are extracted, and nothing is lost ----
// The scout runs SELECT_JQ so seats mode spawns an extract agent only for a
// transcript whose brief casts a vote. The full reduction over every
// transcript is the oracle the selected reduction must reproduce.
const corpus = [...wave, ...panel, ...relay, ...claimPath]
// The scout's reply as filesToExtract receives it: the listing rebuilt on one
// directory, the paths SELECT_JQ printed, and the selection's exit status.
const scoutDir = '/wave'
const listedPaths = corpus.map((r) => `${scoutDir}/${r.file}`).sort()
const printedSeats = fs.readFileSync(path.join(root, 'selected.txt'), 'utf8').split('\n').filter(Boolean)
const seatsReply = { files: listedPaths, seats: printedSeats, seats_exit: 0 }
const selectedNames = filesToExtract('seats', scoutDir, listedPaths, seatsReply).files
    .map((p) => path.basename(p)).sort()
const judges = ['agent-ajudge.jsonl', 'agent-pjudge.jsonl', 'agent-preseat.jsonl', 'agent-prelayjudge.jsonl'].sort()
ok(JSON.stringify(selectedNames) === JSON.stringify(judges),
    `the selection is exactly the judge transcripts, re-seated and relay-prefixed included (got ${JSON.stringify(selectedNames)})`)
ok(!selectedNames.includes('agent-aexec.jsonl') && !selectedNames.includes('agent-aprobe.jsonl')
    && !selectedNames.includes('agent-cclaim.jsonl'),
    'a step, probe or claim transcript whose tool result quotes the cast command is not selected')
const selectedCorpus = corpus.filter((r) => selectedNames.includes(r.file))
const seatsAll = reduceRows(corpus, 'seats', [])
const seatsSelected = reduceRows(selectedCorpus, 'seats', [])
ok(seatsAll.errors.length === 0 && seatsAll.rows.length > 0,
    'oracle: seats mode over every transcript reduces cleanly to rows')
ok(JSON.stringify(seatsSelected.rows) === JSON.stringify(seatsAll.rows),
    `the selected transcripts reduce to the same seat rows as every transcript (got ${JSON.stringify(seatsSelected.rows.map((r) => `${r.proposal}/${r.voter}/${r.unit}=${r.quantity}`))})`)

// ---- The mode gate and the selection's failure channel ----
ok(JSON.stringify(filesToExtract('steps', scoutDir, listedPaths, seatsReply).files) === JSON.stringify(listedPaths),
    'steps mode extracts every listed transcript, even when the reply carries a seat selection')
const refusal = (listing) => {
    try { filesToExtract('seats', scoutDir, listedPaths, listing); return '' } catch (e) { return String(e.message) }
}
ok(refusal({ ...seatsReply, seats_exit: 5 }).includes('exited 5'),
    'a seats selection that exited non-zero is refused, not read as a short seat list')
ok(refusal({ ...seatsReply, seats: [], seats_exit: 1 }).includes('exited 1'),
    'a failed selection that printed nothing is refused, not read as a wave with no judges')
ok(refusal({ files: listedPaths, seats: printedSeats }).includes('exited undefined'),
    'a reply that does not carry the selection status is refused')
ok(refusal({ files: listedPaths }).includes('no seats listing'),
    'a reply with no seats listing is refused')
const judgeless = [...relay, ...claimPath]
const judgelessPaths = judgeless.map((r) => `${scoutDir}/${r.file}`).sort()
const cleanEmpty = filesToExtract('seats', scoutDir, judgelessPaths, { files: judgelessPaths, seats: [], seats_exit: 0 }).files
ok(cleanEmpty.length === 0
    && JSON.stringify(reduceRows([], 'seats', []).rows) === JSON.stringify(reduceRows(judgeless, 'seats', []).rows),
    'a clean selection naming no transcript extracts nothing and matches the rows of every transcript in a judge-less directory')

// ---- Seats mode sort order: grouped by proposal, then seat ----
const twoPanels = [
    { file: 'a', extract: { bootstrap: true, cast: { proposal: 'PROP-9', voter: 'zed' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
    { file: 'b', extract: { bootstrap: true, cast: { proposal: 'PROP-10', voter: 'amy' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
    { file: 'c', extract: { bootstrap: true, cast: { proposal: 'PROP-10', voter: 'bob' }, record: null, probe: false, exec: false, step_mention: null, usage: want } },
]
const order = [...new Set(reduceRows(twoPanels, 'seats', []).rows.map((r) => `${r.proposal}/${r.voter}`))]
ok(order.join(',') === 'PROP-10/amy,PROP-10/bob,PROP-9/zed',
    'seats rows sort lexicographically by (proposal, voter), grouped per proposal')
ok(reduceRows(twoPanels, 'seats', []).rows.filter((r) => r.unit === 'tool_uses').every((r) => r.quantity === 0),
    'an extract without a tool_uses field counts zero calls rather than NaN')

// ---- Coordination: the wave's statuses joined to the manifest rows ----
// Instance ordinals are the engine's: @0 is a step's first minting, a fix
// round's rows carry the round number. One sibling-shard row and one status
// no manifest row explains, so both edges are exercised.
const manifest = [
    { step: 'STEP-3150', instance: 'implement@0', issue: 'DOT-1', kind: 'executor' },
    { step: 'STEP-3146', instance: 'verify-tribunal@0', issue: 'DOT-1', kind: 'vote' },
    { step: 'STEP-3156', instance: 'fix@2', issue: 'DOT-2', kind: 'executor' },
    { step: 'STEP-3166', instance: 'review@2#0', issue: 'DOT-2', kind: 'executor' },
    { step: 'STEP-3158', instance: 'verify-tribunal@2', issue: 'DOT-2', kind: 'vote' },
    { step: 'STEP-3170', instance: 'synthesize-findings@2', issue: 'DOT-2', kind: 'executor' },
    { step: 'STEP-3180', instance: 'implement@0', issue: 'DOT-3', kind: 'executor' },
    { step: 'STEP-3190', instance: 'verify-tribunal@0', issue: 'DOT-3', kind: 'vote' },
]
const settled = [
    { step: 'STEP-3150', status: 'returned', text: 'ok' },
    { step: 'STEP-3146', status: 'gate-passed', text: '', spawn_accounting: '3 seats, 3 probes, 0 retries' },
    { step: 'STEP-3156', status: 'claim-conflict', text: 'STEP-3156 CLAIM CONFLICT' },
    { step: 'STEP-3166', status: 'parked-base-ancestry', text: '' },
    { step: 'STEP-3158', status: 'gate-rejected', text: '' },
    { step: 'STEP-3170', status: 'skipped-chain-dead', text: null },
    { step: 'STEP-3180', status: 'not-launched-agent-budget', text: null },
    { step: 'STEP-3190', status: 'not-launched-other-shard', text: null },
    { step: 'STEP-9999', status: 'spawn-failed', text: null },
]
const coord = coordinationOf(panel, manifest, settled)
ok(coord.rows === 8, `a sibling shard's row counts nowhere (got rows ${coord.rows})`)
ok(JSON.stringify(coord.rounds_per_issue) === JSON.stringify({ 'DOT-1': 0, 'DOT-2': 2, 'DOT-3': 0 }),
    `rounds per issue is the highest instance ordinal the wave carried per issue (got ${JSON.stringify(coord.rounds_per_issue)})`)
ok(coord.gates.decided === 2 && coord.gates.passed === 1 && coord.gates.rejected === 1 && coord.gates.parked === 0,
    'gate outcomes are bucketed from the wave statuses')
ok(coord.gates.first_pass.decided === 1 && coord.gates.first_pass.passed === 1 && coord.gates.first_pass.rate === 1,
    'first pass counts only gates at ordinal 0; a fix round\'s gate is not a first pass')
ok(coord.reseats === 1, 'a re-seated judge is counted from its own brief')
ok(coord.claim_conflicts === 1 && coord.ancestry_parks === 1 && coord.spawn_failed === 1,
    'claim conflicts, ancestry parks and spawn failures each count once')
ok(coord.deferred.agent_budget === 1 && coord.deferred.chain_dead === 1 && coord.deferred.total === 2
    && coord.deferred.writer_budget === 0 && coord.deferred.run_parked === 0,
    'deferrals are bucketed by cause, sibling-shard rows excluded')
ok(coord.unmatched_steps.join(',') === 'STEP-9999',
    'a status no manifest row explains is named, never silently dropped')
ok(coordinationOf(panel, undefined, undefined) === null,
    'without the wave statuses and rows the section is null, so an unmeasured wave never reads as clean')
ok(coordinationOf(wave, manifest, settled).reseats === 0,
    'a panel with no respawn sentence counts no re-seats')

// ---- The drift guard survives the new ordering ----
const drifted = reduceRows(drift, 'steps', [])
ok(drifted.errors.length === 1 && drifted.rows.length === 0 && drifted.overhead.agents.length === 0,
    'an executor brief with no claim/record obligation is a hard error, not overhead')
ok(drifted.errors[0].includes('have drifted'),
    'and the failure names the drift rather than emptying the ledger silently')

// ---- A harness relay ahead of the brief is skipped, not read as the brief ----
ok(by(relay, 'agent-arelayexec.jsonl').extract.record === 'STEP-3175',
    `a relay-first transcript reads the obligation from the brief behind the relay (got ${by(relay, 'agent-arelayexec.jsonl').extract.record})`)
const relayed = reduceRows(relay, 'steps', [])
ok(relayed.errors.length === 0 && [...new Set(relayed.rows.map((r) => r.step))].join(',') === 'STEP-3175'
    && JSON.stringify(unitsOf(relayed.rows, 'STEP-3175')) === JSON.stringify(want),
    'and steps mode attributes that agent\'s own spend to its claimed step')
ok(by(relay, 'agent-arelayprobe.jsonl').extract.probe === true
    && overheadLabel(relayed, 'agent-arelayprobe.jsonl') === 'read-only probe, mentions STEP-3176',
    'a relay followed by a probe brief is still classified as a probe')

// ---- Silence must not look like success ----
const silent = [{ file: 'agent-quiet.jsonl', extract: {
    ...by(wave, 'agent-aexec.jsonl').extract,
    usage: { input_tokens: 0, output_tokens: 0, cache_creation_tokens: 0, cache_read_tokens: 0 },
} }]
const quiet = reduceRows(silent, 'steps', [])
ok(quiet.errors.length === 1 && quiet.errors[0].includes('carries no usage'),
    'a claimant whose transcript carries no usage is an error, not a zero row')
// ---- ...unless a live transcript carries the same step: then it is a dead spawn ----
// wave.js re-spawns a claimant whose first spawn died before its first
// assistant turn; the dead transcript still opens with the step's brief and
// carries no usage. One wave lost a whole shard's rows to that error.
const live = by(wave, 'agent-aexec.jsonl')
const deadFirst = [silent[0], live]
const deadResult = reduceRows(deadFirst, 'steps', [])
ok(deadResult.errors.length === 0,
    'a no-usage claimant beside a live transcript for the same step is not an error')
ok(deadResult.skipped.length === 1 && deadResult.skipped[0].reason === 'dead-spawn' && deadResult.skipped[0].file === 'agent-quiet.jsonl',
    'and lands in skipped with reason dead-spawn')
ok(JSON.stringify(unitsOf(deadResult.rows, live.extract.record)) === JSON.stringify(unitsOf(reduceRows([live], 'steps', []).rows, live.extract.record)),
    'and the live transcript\'s row is exactly what it would be alone')
const deadLast = reduceRows([live, silent[0]], 'steps', [])
ok(deadLast.errors.length === 0 && deadLast.skipped.length === 1 && deadLast.skipped[0].reason === 'dead-spawn',
    'directory order does not matter: the dead transcript listed after the live one is skipped too')
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
