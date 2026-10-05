export const meta = {
    name: 'wave-usage',
    description: 'Internal: launched through scriptPath by docket-run when a wave returns; measures a completed wave\'s token spend from its agent transcripts and emits the back-fill rows for `docket dispatch backfill-usage` or `docket vote backfill-usage`. Args and probe cost in the header comment.',
    whenToUse: 'Never by name. Launched beside the dispatch close, and by the pause and resume paths for a wave never back-filled.',
    phases: [
        { title: 'Scout', detail: 'one agent lists the agent transcripts and, in seats mode, selects the seat transcripts' },
        { title: 'Extract', detail: 'one low-effort agent per listed transcript (seats mode: per seat transcript) runs the fixed jq' },
    ],
}

// ---------------------------------------------------------------------------
// CONTRACT FOR CALLERS (the listing's description is deliberately one line;
// this block is the single copy of what it used to carry).
//
// What it does:
// Measure a completed wave's token spend from its agent transcripts and emit
// the back-fill rows: one row per (step, unit) for `docket dispatch backfill-
// usage --from-json -`, or per (proposal, voter, unit) for `docket vote
// backfill-usage --from-json -`. Every agent is partitioned exactly once into
// judge, claimant, or wave overhead by what its bootstrap brief told it to do.
// Seats mode also emits a fifth `tool_uses` unit per seat (distinct tool_use
// blocks in the seat's transcript), the investigation-depth signal docket-
// retro's seat-calibration row reads beside the cast's self-reported
// confidence. Steps mode returns a `coordination` section beside the rows
// (counts under return below) when the caller also passes the wave's returned
// statuses and the manifest rows. PROBE COST: one scout, plus one low-effort
// read-only extract agent per transcript to measure: in steps mode every
// agent-*.jsonl in the directory, in seats mode only each seat transcript
// (one whose bootstrap brief carries `docket vote cast`, selected by the
// scout without an agent per file), plus one re-check for any transcript
// relayed as bootstrap:false. Invoke by scriptPath
// ONLY, with args {dir, mode?, exclude?, rows?, statuses?}.
//
// When and how it is invoked:
// Invoked by the docket-run skill the moment a wave returns. On the normal
// path, launched in docket-run's back-fill step, ahead of the close call in
// that step's own call order, but the join's usage record can still land
// after the close call returns (the engine measures `dispatch.grace` from
// the run's newest terminal step record — the wave's last one — so every step
// recorded before it is usage PENDING while that record is inside the window,
// and the join may land after the close; a step still unbilled once the wave's
// last record is past the window is the `usage-rows-missing` refusal it always
// was), and by the pause and resume paths for a wave whose usage was never
// back-filled. args is {dir: absolute transcript directory, mode: "steps"
// (default) | "seats", exclude: [STEP-N...] in steps mode or [seat...] in
// seats mode, rows: the manifest rows handed to wave.js, statuses: the wave's
// returned array}; rows and statuses are optional, given together, and read in
// steps mode only, where they feed the `coordination` section (null without
// them, and the log says so). The script cannot read files itself; its agents
// run one fixed jq program per transcript and the reduction happens here.
// ---------------------------------------------------------------------------

// scout/extract/recheck only relay a fixed command's output through a schema
// (no judgment involved), so a cheap model is pinned rather than inherited —
// the same reasoning wave.js:probe and tribunal.js:verify already apply to
// read-only relay agents of this shape.
const AGENT_CONFIG = {
    scout: { model: 'haiku', effort: 'low' },
    extract: { model: 'haiku', effort: 'low' },
    recheck: { model: 'haiku', effort: 'low' },
}

const DEFAULT_MODE = 'steps'

// ---------------------------------------------------------------------------
// THE TRANSCRIPT-DERIVED TOKEN PATH, designed rather than a workaround: a
// claimant cannot observe its own token consumption, so the conductor that
// spawned it measures the transcripts here and pipes the rows to
// `backfill-usage`. `docket step record --usage` is the engine's channel for
// units a claimant CAN measure at source.
//
// Each agent-<id>.jsonl (in seats mode, each one the scout's SELECT_JQ
// selects as a seat) is read by one agent running EXTRACT_JQ below, which
// reports what the bootstrap brief (the first user message after any harness
// relay) told the agent to do, the agent's four typed token units, its
// tool-call count, and whether it was a re-seated judge. This script joins,
// partitions, sums and sorts; agents read, the script decides.
//
// Rules carried over from the measured history of this join:
//
//  * USAGE IS DEDUPLICATED BY MESSAGE ID, LAST OCCURRENCE WINS. Streamed
//    assistant messages repeat across transcript lines, so a per-line sum
//    double-counts (measured 1.65-2.36x on a past wave). The direction is
//    load-bearing: `output_tokens` GROWS across the rewrites of one id, so the
//    first occurrence is a partial count (~3x under on one step), while input
//    and both cache units never change. Last-wins satisfies both failure
//    modes; a seen-set does not.
//
//  * THE JOIN IS THE OBLIGATION, NOT THE FIRST STEP-N. Every executor brief
//    names its assignment in a `docket step claim/record STEP-N` command, the
//    same string the claimant must pass, so the join cannot disagree with the
//    record. A bare STEP-N search cannot tell "execute this step" from "read
//    this step": wave.js probes a row before claiming it, and a first-match
//    join back-filled ~17K tokens per probe onto pending and superseded steps
//    no agent ever ran on a past wave.
//
//  * ASK WHAT THE BRIEF IS FOR BEFORE ASKING WHAT STEP IT NAMES: briefed to
//    cast? briefed only to read? briefed to record? The first yes wins. The
//    read test sits ABOVE the step join on purpose: a probe can quote the
//    obligation it is reading about, and with the join first the ledger was
//    safe only while probe briefs happened to carry no record-shaped text.
//
//  * ALL THREE JOINS READ THE BOOTSTRAP ONLY, never a later user message.
//    Later messages carry tool results, and a probe's own `docket step show`
//    output can quote a step artifact naming the record command. What briefs
//    the agent decides; what the agent read back cannot.
//
//  * EXEC_MARK IS THE DRIFT SAFETY NET. An agent whose brief opens as an
//    executor yet names no claim/record command means the brief was reworded
//    out from under the join; without this error every claimant would fall
//    silently into overhead and the wave would back-fill nothing. The same
//    mark breaks a probe/executor tie toward the claimant path.
//
//  * THE MODES PARTITION THE WAVE. Steps mode emits agents briefed to record
//    and names (skips) those briefed to cast; seats mode is the mirror. An
//    agent briefed to do neither is WAVE OVERHEAD: every pre-claim probe,
//    gate read, block probe and ancestry read. Its spend is real but no step
//    owns it, so it is summed and reported, never keyed to the step it read
//    and never dropped silently. A conductor runs both modes over a wave and
//    counts every agent at most once; where a vote-kind step would otherwise
//    double-count against both the steps-mode and seats-mode back-fill, the
//    caller passes it in `exclude` (docket-run's own rule: vote-kind steps
//    are always refused a steps-mode claim, so they are filtered out there
//    and left to seats mode) — this script never infers the exclusion
//    itself.
//
//  * EVERY AGENT ANSWER IS A RELAY, AND RELAYS RETYPE. The scout's listing
//    and the extract's fields are structured output a low-effort model
//    copied, and two copies have failed the join: the flattened project
//    directory under ~/.claude/projects came back with `github-com` read as
//    `github.com` (in extracts, and once in the whole scout listing), and
//    two step ids came back wrapped in literal quotes. So the directory is
//    always args.dir with only the scout's basename appended, the paths the
//    agents type carry that component as a `*` glob the shell resolves, and
//    every ledger key is unquoted and validated before it reaches a row.
//
//  * `exclude` drops a key a PRIOR dispatch's back-fill already carries (a
//    gate probed in one wave and seated in the next emits usage in both
//    journals). In seats mode it names a bare seat and drops it under every
//    proposal. Excluded keys are logged, never silently dropped.
//
//  * TOOL USE IS COUNTED BY BLOCK ID, NOT BY MESSAGE ID. The transcript
//    writes one content block per line under a shared message id (usage
//    repeated on each line), so the last-wins rule that is right for usage
//    would keep only the last block's calls: measured 4 of 8, 6 of 9 and 8 of
//    11 tool_use blocks on three transcripts. A tool_use block carries its
//    own id, which a rewritten line repeats and `unique` absorbs.
//    server_tool_use blocks are not counted, matching session-census.js. The
//    count is an audit signal for docket-retro's seat-calibration row (reads
//    can be spammed, so it is never a tally input) and reaches the ledger
//    only in seats mode, as a fifth unit beside the four token units; steps
//    mode keeps its four-row contract.
//
//  * COORDINATION IS A REPORT, NOT A LEDGER ROW. Steps mode returns a
//    `coordination` section (see return) when the caller hands over the
//    wave's returned statuses and the manifest rows. Re-seats come from the
//    transcripts (a re-seated judge's brief says so); every other count comes
//    from the statuses joined to the rows by step. A `not-launched-other-shard`
//    row, which only a wave launched before the per-unit split returns, is
//    another launch's and counts nowhere. Instance ordinals are the engine's:
//    `@0` is a step's first minting (`review@0#k`, `verify-tribunal@0`) and a
//    fix round's rows carry the round (`fix@2`, `review@2#k`), so first-pass
//    means ordinal 0.
//
// args:   {dir, mode?, exclude?, rows?, statuses?}
//         dir       absolute path of the wave's transcript directory
//         mode      'steps' (default) or 'seats'
//         exclude   [STEP-N...] in steps mode, [seat...] in seats mode; [] default
//         rows      the manifest rows handed to wave.js; {step, instance, issue}
//                   are read here. Steps mode, optional, given with statuses
//         statuses  the wave's returned array; {step, status} are read here.
//                   Steps mode, optional, given with rows
// return: {rows, overhead: {agents: [{file, label}], sums}, skipped, errors,
//          model_observations, coordination}
//         rows     [{step, unit, quantity}] or [{proposal, voter, unit, quantity}],
//                  four token unit rows per step, or those four plus one
//                  `tool_uses` row per (proposal, voter), sorted numerically
//                  by step or lexicographically by (proposal, voter)
//         overhead the agents that recorded no step and cast no ballot, with
//                  their summed units (steps mode; empty in seats mode)
//         skipped  [{file, reason: 'seated'|'unattributed'|'excluded'|'dead-spawn', key, label}]
//         errors   [string]; when non-empty the script throws after logging
//                  each one, because silence must not look like success
//         model_observations [{file, kind, key, models, complete, source,
//                              effort_resolved}]
//                  serving models from assistant.message.model, separately
//                  from routing requests and token rows. Multiple models can
//                  serve one agent after fallback. Missing fields stay unknown;
//                  neither routing settings nor model self-reports fill them.
//                  Effective effort is not exposed by this transcript shape.
//                  complete covers parsed, deduplicated usage-bearing messages;
//                  it does not certify that the transcript or task finished.
//         coordination steps mode with rows and statuses given: {rows,
//                  rounds_per_issue, gates: {decided, passed, rejected, parked,
//                  blocked, skipped, first_pass: {decided, passed, rate}},
//                  reseats, claim_conflicts, ancestry_parks, spawn_failed,
//                  deferred: {agent_budget, writer_budget, chain_dead,
//                  run_parked, total}, unmatched_steps}. `rows` counts the
//                  statuses this launch owned; `decided` is passed + rejected
//                  + parked (a parked gate is one whose tally did not clear or
//                  could not be read); `rate` is passed over decided, null at
//                  zero; `unmatched_steps` names statuses no manifest row
//                  explains. null in seats mode or when the args are absent.
// Throws when the directory holds no agent transcripts, when the fresh
// re-check of a relayed bootstrap:false fails to return a usable answer,
// when an executor brief names no step to record, or when a dispatched agent
// carries no usage. A bootstrap:false confirmed on that re-check is not an
// error: it is folded into wave overhead instead, since wave.js never
// dispatches an agent without a bootstrap brief.
// ---------------------------------------------------------------------------

const input = (typeof args === 'string' ? JSON.parse(args) : args) || {}
if (typeof args === 'string') log('wave-usage: decoded args from the harness JSON-encoded transport (normal)')
const dir = input.dir
if (typeof dir !== 'string' || !dir.startsWith('/')) {
    throw new Error(`wave-usage: args.dir must be an absolute transcript directory, got ${JSON.stringify(dir)}`)
}
const mode = input.mode ?? DEFAULT_MODE
if (mode !== 'steps' && mode !== 'seats') {
    throw new Error(`wave-usage: args.mode must be "steps" or "seats", got ${JSON.stringify(mode)}`)
}
const exclude = Array.isArray(input.exclude) ? input.exclude.map(String) : []
const manifestRows = input.rows ?? null
const waveStatuses = input.statuses ?? null
if ((manifestRows == null) !== (waveStatuses == null)) {
    throw new Error('wave-usage: args.rows and args.statuses are given together or not at all — ' +
        'the coordination counts join the wave\'s returned statuses to the manifest rows by step')
}
if (manifestRows != null && (!Array.isArray(manifestRows) || !Array.isArray(waveStatuses))) {
    throw new Error(`wave-usage: args.rows and args.statuses must be arrays, got ` +
        `${JSON.stringify(manifestRows).slice(0, 80)} and ${JSON.stringify(waveStatuses).slice(0, 80)}`)
}

// TEST-BEGIN wave-usage-extract — extracted by
// tests/wave-usage-probe-overhead.test.sh and run with the same jq flags as
// the agents use. Keep it free of workflow globals.
//
// Run as `jq -c -n -R -f <this> <transcript>`: raw lines, so a line that is
// not JSON is skipped instead of aborting the file. Prints ONE object.
//
// The bootstrap is the content of the first user message that is not the
// harness's user-request relay: a string as-is, a content array JSON-encoded,
// so its line breaks arrive as a literal backslash-n. Every marker below is
// therefore newline-free, and READ_JOB's regex accepts either a real newline
// or that two-byte sequence.
//
// The relay is skipped because the harness may prepend it ahead of the
// brief: a string opening "[Workflow harness — user request]" that carries
// the operator's words and none of the markers below, so reading it would
// file every agent as not a wave agent. Only that prefix is skipped, never
// searched past: the later user messages are tool results, and their output
// can quote a `docket step record STEP-N` it merely read.
//
// probe is the four-way read test: the explicit declaration wave.js's
// probeBrief() opens with, the block probe's opening sentence, the legacy
// probe self-description (truncated on purpose: wave.js writes "what the
// record currently says", tribunal.js "what the VOTE record currently says"),
// and the READ JOB itself — the fixed opening line followed by one docket
// read verb. Keying on the command keeps classification working when the
// prose is reworded, and anchoring it to the opening line keeps an
// implementer brief that merely MENTIONS `docket step show` from reading as
// a probe.
//
// cast and record are the joins, each read from the very command the agent
// is required to run. step_mention is NOT a join: it is the loose "which step
// is this agent looking at" read that labels an overhead agent in the report.
//
// claim_agent is the declaration wave.js's claimBrief() closes with. The
// claim agent runs wave-claim for an executor and is wave overhead: its
// brief never spells a claim or record of the step, so it never joins one.
//
// reseat is the sentence tribunal.js opens a re-seated judge's brief with.
// tool_uses counts distinct tool_use block ids over every assistant line, not
// the deduplicated messages: see TOOL USE IS COUNTED BY BLOCK ID above.
//
// Backslashes are doubled once for the template literal: the file the agent
// writes carries jq source, in which `\\s` is the regex escape.
//
// BRIEF_DEFS_JQ is the bootstrap rule and the cast join, shared verbatim with
// SELECT_JQ below: seats mode extracts only what SELECT_JQ selects, so a
// transcript this program would seat must be one that program selects.
const BRIEF_DEFS_JQ = `def bootstrap_candidate: .type == "user"
    and (.message.content | type == "string"
        and startswith("[Workflow harness — user request]") | not);
def bootstrap_text: .message.content | if type == "string" then . else tojson end;
def cast_join: capture("docket vote cast\\\\s+(?<proposal>\\\\S+)\\\\s+--voter\\\\s+(?<voter>\\\\S+)");
`
const EXTRACT_JQ = `${BRIEF_DEFS_JQ}[inputs | fromjson? | select(type == "object")] as $lines
| ([$lines[] | select(bootstrap_candidate)] | .[0]) as $first
| (if $first == null then null else ($first | bootstrap_text) end) as $boot
| ($boot // "") as $b
| (reduce ($lines[] | select(.type == "assistant") | .message
            | select((.usage // {}) != {} and (.id // "") != "")) as $m
        ({}; .[$m.id] = $m) | [.[]]) as $messages
| {
    bootstrap: ($boot != null),
    cast: (($b | cast_join) // null),
    record: (($b | capture("docket step (?:claim|record|complete)\\\\s+(?<step>STEP-\\\\d+)") | .step) // null),
    probe: ($b | (
        contains("WAVE PROBE: not a step execution")
        or contains("You are a DIAGNOSTIC PROBE inside a running Docket wave")
        or (contains("Run exactly this one command:") and contains("read-only probe reporting what the"))
        or test("Run exactly this one command:(?:\\\\\\\\n|\\\\s)+\`?docket\\\\s+(?:[a-z-]+\\\\s+)?(?:show|context|list|tally|next|log)\\\\b"))),
    exec: ($b | contains("You are executing one step of a Docket run")),
    claim_agent: ($b | contains("WAVE CLAIM: not a step execution")),
    step_mention: (($b | [match("STEP-\\\\d+")][0].string) // null),
    reseat: ($b | contains("THIS IS A SECOND ATTEMPT AT YOUR SEAT")),
    tool_uses: ([$lines[] | select(.type == "assistant") | .message.content
                 | if type == "array"
                   then .[] | select(type == "object" and .type == "tool_use") | .id // empty
                   else empty end]
                | unique | length),
    models_observed: ([$messages[].model | select(type == "string" and . != "" and . != "<synthetic>")] | unique),
    model_observation_complete: ($messages | length > 0 and all(.[];
        (.model | type) == "string" and .model != "" and .model != "<synthetic>")),
    usage: (
        $messages | map(.usage)
        | {
            input_tokens:          (map(.input_tokens // 0) | add // 0),
            output_tokens:         (map(.output_tokens // 0) | add // 0),
            cache_creation_tokens: (map(.cache_creation_input_tokens // 0) | add // 0),
            cache_read_tokens:     (map(.cache_read_input_tokens // 0) | add // 0)
        })
  }
`
// TEST-END wave-usage-extract

// TEST-BEGIN wave-usage-select — extracted and run by
// tests/wave-usage-probe-overhead.test.sh after the extract region, whose
// BRIEF_DEFS_JQ it reads. Keep it free of workflow globals.
//
// Run by the seats-mode scout as `jq -r -n -R -f <this> <transcript>...`
// (any number of files per invocation): prints the path of every transcript
// whose bootstrap carries the cast command, so seats mode spawns no extract
// agent for a claimant, claim agent or probe. Only the first bootstrap
// candidate per file is kept and read, never a later tool result.
const SELECT_JQ = `${BRIEF_DEFS_JQ}reduce (inputs | fromjson? | select(type == "object" and bootstrap_candidate)
        | {file: input_filename, text: bootstrap_text}) as $u
    ({}; if has($u.file) then . else .[$u.file] = $u.text end)
| to_entries[] | select(.value | cast_join) | .key
`
// TEST-END wave-usage-select

// TEST-BEGIN wave-usage-classify — extracted and exercised by
// tests/wave-usage-probe-overhead.test.sh over jq output from fixture
// transcripts. Keep everything between the markers free of workflow globals
// (agent, log, args) so it stays evaluable on its own.
const UNITS = ['input_tokens', 'output_tokens', 'cache_creation_tokens', 'cache_read_tokens']

const zeroSums = () => Object.fromEntries(UNITS.map((u) => [u, 0]))

// The tool-call count rides beside `sums`, never inside it: the four token
// units are the engine's per-step contract and the overhead log, and a
// partial or synthetic extract may carry no count at all.
const toolUses = (extract) => (Number.isInteger(extract.tool_uses) ? extract.tool_uses : 0)

// The extract relay copies jq's output into structured fields, and one
// measured copy wrapped two step ids in literal quotes (`"\"STEP-10391\""`),
// which `dispatch backfill-usage` refused for the whole 160-row batch. Every
// key the ledger is joined on is trimmed and stripped of one layer of
// surrounding quotes here; a step key that still is not STEP-N is an error
// naming the file, never a row the engine refuses later.
const unquote = (v) => (typeof v === 'string'
    ? v.trim().replace(/^"(.*)"$/, '$1').replace(/^'(.*)'$/, '$1').trim()
    : v)
const STEP_KEY_RE = /^STEP-\d+$/
function normalizeKeys(x) {
    if (!x || typeof x !== 'object') return x
    const out = { ...x }
    if (typeof x.record === 'string') out.record = unquote(x.record)
    if (typeof x.step_mention === 'string') out.step_mention = unquote(x.step_mention)
    if (x.cast && typeof x.cast === 'object') {
        out.cast = { ...x.cast, proposal: unquote(x.cast.proposal), voter: unquote(x.cast.voter) }
    }
    return out
}

// The three questions, in the one order that cannot misfile a read: briefed
// to cast? briefed only to read? briefed to record? First yes wins. `file`
// appears only in labels and error text.
function classify(raw, mode, file) {
    const x = normalizeKeys(raw)
    if (mode === 'seats') {
        if (!x.cast) return { bucket: 'unattributed', key: null, label: file }
        const key = [x.cast.proposal, x.cast.voter]
        return { bucket: 'row', key, label: key.join('/') }
    }
    if (x.cast) {
        return { bucket: 'seated', key: [x.cast.proposal, x.cast.voter],
                 label: `${file} (${x.cast.proposal}/${x.cast.voter})` }
    }
    if (!x.bootstrap) {
        // The relaying agent said jq found no first `type:"user"` line. Twice
        // in a row (bootstrapFallback set by the caller after a fresh retry
        // repeats the answer) is treated as a misreport rather than truth —
        // wave.js never dispatches an agent without a bootstrap brief, so a
        // reproducible "no user message" is far more likely a relay error
        // than an actual bootstrap-free transcript. Reported here as
        // overhead (with its usage) rather than thrown, so one misreport
        // does not sink the whole join.
        if (x.bootstrapFallback) {
            return { bucket: 'overhead', key: null,
                     label: `no user message reported twice (misreport, not thrown)` +
                            `${x.step_mention ? `, mentions ${x.step_mention}` : ''}` }
        }
        return { bucket: 'error', key: null,
                 label: `${file}: no user message — cannot classify (agent answer: ${JSON.stringify(x)})` }
    }
    // An executor brief never carries a probe marker, so both together mean
    // drift, and the claimant path (with its own drift error) still wins.
    const probe = x.probe && !x.exec
    const record = probe ? null : x.record
    if (!record) {
        if (x.exec) {
            return { bucket: 'error', key: null,
                     label: `${file}: opens as a step executor but names no ` +
                            '`docket step claim/record STEP-N` — the bootstrap brief and ' +
                            'the record join have drifted' }
        }
        const what = x.claim_agent ? 'claim agent' : probe ? 'read-only probe' : 'not a wave agent'
        return { bucket: 'overhead', key: null,
                 label: `${what}${x.step_mention ? `, mentions ${x.step_mention}` : ''}` }
    }
    if (!STEP_KEY_RE.test(record)) {
        return { bucket: 'error', key: null,
                 label: `${file}: the record join returned ${JSON.stringify(record)}, ` +
                        'not a STEP-N id — the relay mangled the key' }
    }
    return { bucket: 'row', key: record, label: record }
}

function modelObservation(file, extract, classification, mode) {
    const models = Array.isArray(extract.models_observed)
        ? [...new Set(extract.models_observed.filter((model) =>
            typeof model === 'string' && model !== '' && model !== '<synthetic>'))].sort()
        : []
    return {
        file,
        kind: classification.bucket === 'overhead' ? 'overhead' : mode === 'seats' ? 'seat' : 'step',
        key: classification.key,
        models,
        complete: extract.model_observation_complete === true && models.length > 0,
        source: 'assistant.message.model',
        effort_resolved: 'unknown',
    }
}

function addUsage(sums, usage) {
    for (const unit of UNITS) sums[unit] += usage[unit] || 0
}

// results: [{file, extract}] in directory order. Sums per key, in the order
// the ledger wants: numeric by step, or grouped by proposal then seat.
function reduceRows(results, mode, exclude) {
    const totals = new Map()
    const overhead = { agents: [], sums: zeroSums() }
    const skipped = []
    const errors = []
    const model_observations = []
    const excluded = new Set(exclude || [])
    // A claimant transcript with no usage is judged AFTER the whole batch is
    // summed, not in line: wave.js re-spawns a claimant whose first spawn
    // died before its first assistant turn, and that dead transcript still
    // opens with the step's brief. Beside a live transcript for the same
    // key it is a dead spawn and is skipped; alone, silence is still an
    // error, not a zero row. Directory order does not decide which of the
    // two is read first, hence the deferral.
    const silent = []
    for (const { file, extract } of results) {
        const c = classify(extract, mode, file)
        if (c.bucket === 'error') {
            errors.push(c.label)
            continue
        }
        if (c.bucket === 'seated' || c.bucket === 'unattributed') {
            skipped.push({ file, reason: c.bucket, key: c.key, label: c.label })
            continue
        }
        model_observations.push(modelObservation(file, extract, c, mode))
        if (c.bucket === 'overhead') {
            overhead.agents.push({ file, label: c.label })
            addUsage(overhead.sums, extract.usage)
            continue
        }
        const excludeName = mode === 'seats' ? c.key[1] : c.key
        if (excluded.has(excludeName)) {
            skipped.push({ file, reason: 'excluded', key: c.key, label: c.label })
            continue
        }
        const id = mode === 'seats' ? c.key.join(' ') : c.key
        if (!UNITS.some((u) => extract.usage[u] > 0)) {
            silent.push({ file, id, c })
            continue
        }
        if (!totals.has(id)) totals.set(id, { key: c.key, sums: zeroSums(), tool_uses: 0 })
        addUsage(totals.get(id).sums, extract.usage)
        totals.get(id).tool_uses += toolUses(extract)
    }
    for (const { file, id, c } of silent) {
        if (totals.has(id)) {
            skipped.push({ file, reason: 'dead-spawn', key: c.key, label: c.label })
        } else {
            errors.push(`${file} (${c.label}): transcript carries no usage`)
        }
    }
    const cmp = mode === 'seats'
        ? (a, b) => (a.key[0] < b.key[0] ? -1 : a.key[0] > b.key[0] ? 1 :
                     a.key[1] < b.key[1] ? -1 : a.key[1] > b.key[1] ? 1 : 0)
        : (a, b) => parseInt(a.key.split('-')[1], 10) - parseInt(b.key.split('-')[1], 10)
    // Seats mode carries the tool-call count as a fifth unit row; steps mode
    // keeps the four-row contract docket-run pipes to dispatch backfill-usage.
    const rows = [...totals.values()].sort(cmp).flatMap(({ key, sums, tool_uses }) =>
        mode === 'seats'
            ? [...UNITS.map((unit) => ({ proposal: key[0], voter: key[1], unit, quantity: sums[unit] })),
               { proposal: key[0], voter: key[1], unit: 'tool_uses', quantity: tool_uses }]
            : UNITS.map((unit) => ({ step: key, unit, quantity: sums[unit] })),
    )
    return { rows, overhead, skipped, errors, model_observations }
}

// The wave's coordination counts, for docket-retro's integration-health row
// rather than for the ledger: what the store cannot see about a wave (a
// refused claim or close writes no event, a deferred row never claims).
const DEFERRAL_STATUSES = {
    'not-launched-agent-budget': 'agent_budget',
    'not-launched-writer-budget': 'writer_budget',
    'skipped-chain-dead': 'chain_dead',
    'not-launched-run-parked': 'run_parked',
}
const GATE_STATUSES = {
    'gate-passed': 'passed',
    'gate-rejected': 'rejected',
    'gate-parked': 'parked',
    'gate-blocked': 'blocked',
    'gate-skipped': 'skipped',
}
const OTHER_SHARD_STATUS = 'not-launched-other-shard'
const INSTANCE_ORDINAL_RE = /@(\d+)(?:#\d+)?$/

const instanceOrdinal = (row) => {
    const m = INSTANCE_ORDINAL_RE.exec((row && row.instance) || '')
    return m ? parseInt(m[1], 10) : null
}

// results: the extracts as reduceRows takes them; rows: the manifest rows;
// statuses: the wave's return, one entry per manifest row. null when the
// caller passed neither, so an unmeasured wave never reads as a clean one.
function coordinationOf(results, rows, statuses) {
    if (!Array.isArray(rows) || !Array.isArray(statuses)) return null
    const rowByStep = new Map(rows.filter((r) => r && r.step).map((r) => [r.step, r]))
    const out = {
        rows: 0,
        rounds_per_issue: {},
        gates: { decided: 0, passed: 0, rejected: 0, parked: 0, blocked: 0, skipped: 0,
                 first_pass: { decided: 0, passed: 0, rate: null } },
        reseats: results.filter((r) => r.extract && r.extract.cast && r.extract.reseat === true).length,
        claim_conflicts: 0,
        ancestry_parks: 0,
        spawn_failed: 0,
        deferred: { agent_budget: 0, writer_budget: 0, chain_dead: 0, run_parked: 0, total: 0 },
        unmatched_steps: [],
    }
    const decided = (bucket) => bucket === 'passed' || bucket === 'rejected' || bucket === 'parked'
    for (const s of statuses) {
        if (!s || typeof s.step !== 'string' || s.status === OTHER_SHARD_STATUS) continue
        out.rows++
        const row = rowByStep.get(s.step)
        if (!row) out.unmatched_steps.push(s.step)
        const ordinal = instanceOrdinal(row)
        if (row && row.issue && ordinal != null) {
            const seen = out.rounds_per_issue[row.issue]
            out.rounds_per_issue[row.issue] = seen == null ? ordinal : Math.max(seen, ordinal)
        }
        if (s.status === 'claim-conflict') out.claim_conflicts++
        else if (s.status === 'parked-base-ancestry') out.ancestry_parks++
        else if (s.status === 'spawn-failed') out.spawn_failed++
        else if (DEFERRAL_STATUSES[s.status]) {
            out.deferred[DEFERRAL_STATUSES[s.status]]++
            out.deferred.total++
        } else if (GATE_STATUSES[s.status]) {
            const bucket = GATE_STATUSES[s.status]
            out.gates[bucket]++
            if (!decided(bucket)) continue
            out.gates.decided++
            if (ordinal !== 0) continue
            out.gates.first_pass.decided++
            if (bucket === 'passed') out.gates.first_pass.passed++
        }
    }
    const fp = out.gates.first_pass
    fp.rate = fp.decided > 0 ? fp.passed / fp.decided : null
    return out
}
// TEST-END wave-usage-classify

// TEST-BEGIN wave-usage-paths — extracted and exercised by
// tests/wave-usage-probe-overhead.test.sh. Keep it free of workflow globals.
const sq = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`

// A path as the agents' shell commands carry it. Every path under
// ~/.claude/projects has one component the relay retypes: the flattened
// project directory (`-Users-…-github-com-…`), which a low-effort agent reads
// as a typo and "corrects" to `github.com` or `github_com` (measured on two
// conductor sessions: nine extracts in one, a whole 39-file scout listing in
// the other). That component is left as a `*` glob between the quoted halves,
// so the shell resolves the file whichever way the agent copies it. The
// session, workflow and agent ids around it are hex the relay copies
// faithfully, and a session id occurs under exactly one project directory,
// so the glob names one file. Everything outside ~/.claude/projects is quoted
// whole.
const PROJECTS_SLUG_RE = /^(.*\/\.claude\/projects\/)([^/]+)(\/.+)$/
const shellPath = (p) => {
    const m = PROJECTS_SLUG_RE.exec(p)
    return m ? `${sq(m[1])}*${sq(m[3])}` : sq(p)
}

// The scout's listing, rebuilt on the literal directory the conductor
// passed. The scout's answer is a relay too: measured, its find argv carried
// the directory correctly and its structured return carried every path with
// the project slug retyped (`github-com` → `github.com`), so every extract
// downstream inherited a path no file has, and the path retry, which
// re-hands the same string, could not recover it. Only the basename is the
// scout's. Returns the sorted, deduplicated full paths and how many listed
// paths sat outside the directory.
function rebuildListing(dir, listed) {
    const dirPath = String(dir).replace(/\/+$/, '') || '/'
    const leafOf = (f) => f.slice(f.lastIndexOf('/') + 1)
    const files = [...new Set(listed.map((f) => `${dirPath}/${leafOf(f)}`))].sort()
    const retyped = listed.filter((f) => f.slice(0, f.lastIndexOf('/')) !== dirPath).length
    return { files, retyped }
}

const AGENT_LOG_RE = /\/agent-[^/]*\.jsonl$/

// The transcripts the Extract phase spawns an agent for. Steps mode measures
// every listed transcript, whatever else the scout returned. Seats mode
// measures only the ones SELECT_JQ selected, and refuses a reply that cannot
// show the selection ran clean: seats_exit is the status of the find that
// ran jq, so a jq failure on any transcript, a missing program file or an
// unreadable file throws here instead of arriving as missing seats. A clean
// selection that names nothing is a directory with no judge, where
// reduceRows over every transcript also gives no rows. Selected paths are
// rebuilt on args.dir like the listing and kept only if listed; `unlisted`
// counts the rest.
function filesToExtract(mode, dir, transcripts, listing) {
    if (mode !== 'seats') return { files: transcripts, unlisted: 0 }
    if (!Array.isArray(listing?.seats)) {
        throw new Error('wave-usage: the seats-mode scout returned no seats listing — cannot tell judges from other agents')
    }
    if (listing.seats_exit !== 0) {
        throw new Error(`wave-usage: the seats selection exited ${listing.seats_exit}, not 0 — ` +
            'its seat list may be short, so no seat is measured from it')
    }
    const selected = new Set(rebuildListing(dir, listing.seats.filter((f) => AGENT_LOG_RE.test(f))).files)
    const files = transcripts.filter((f) => selected.has(f))
    return { files, unlisted: selected.size - files.length }
}
// TEST-END wave-usage-paths

const FILES_SCHEMA = {
    type: 'object',
    required: mode === 'seats' ? ['files', 'seats', 'seats_exit'] : ['files'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        seats: { type: 'array', items: { type: 'string' } },
        seats_exit: { type: 'integer' },
    },
}

const EXTRACT_SCHEMA = {
    type: 'object',
    required: ['ok'],
    properties: {
        ok: { type: 'boolean' },
        error: { type: 'string' },
        bootstrap: { type: 'boolean' },
        cast: {
            type: ['object', 'null'],
            required: ['proposal', 'voter'],
            properties: { proposal: { type: 'string' }, voter: { type: 'string' } },
        },
        record: { type: ['string', 'null'] },
        probe: { type: 'boolean' },
        exec: { type: 'boolean' },
        claim_agent: { type: 'boolean' },
        step_mention: { type: ['string', 'null'] },
        reseat: { type: 'boolean' },
        tool_uses: { type: 'integer' },
        models_observed: { type: 'array', items: { type: 'string' } },
        model_observation_complete: { type: 'boolean' },
        usage: {
            type: 'object',
            required: UNITS,
            properties: Object.fromEntries(UNITS.map((u) => [u, { type: 'integer' }])),
        },
    },
}

const LIST_COMMAND = `find ${shellPath(dir)} -maxdepth 1 -type f -name 'agent-*.jsonl' | LC_ALL=C sort; echo "exit=$?"`
const scoutBrief = mode === 'seats'
    ? `You are a read-only scout. Do not cd anywhere. Run these commands verbatim, sandboxed, and report what they print — never a paraphrase. The first writes a jq program with a quoted heredoc so nothing in it is expanded; the second lists the transcripts; the last prints only the transcripts whose brief casts a vote:

\`\`\`
cat > "\${TMPDIR:-/tmp}/wave-usage-select-$$.jq" <<'JQ'
${SELECT_JQ}JQ
${LIST_COMMAND}
echo '--- seats ---'
find ${shellPath(dir)} -maxdepth 1 -type f -name 'agent-*.jsonl' -exec jq -r -n -R -f "\${TMPDIR:-/tmp}/wave-usage-select-$$.jq" {} +; echo "seats_exit=$?"
\`\`\`

The directory is written with one \`*\` where the flattened project name sits; leave that glob exactly as it is and let the shell resolve it. Return {files: [...], seats: [...], seats_exit: N}: \`files\` is every path printed before the \`--- seats ---\` line, \`seats\` every path printed after it, one entry per line, verbatim and in order — a hyphen where a dot might be expected (\`github-com\`) is correct, not a typo — and \`seats_exit\` is the number printed on the \`seats_exit=\` line. An empty listing is an empty array. Do not open, read, or count the files by any other means.`
    : `You are a read-only scout. Do not cd anywhere. Run this command verbatim, sandboxed, and report what it prints — never a paraphrase:

\`\`\`
${LIST_COMMAND}
\`\`\`

The directory is written with one \`*\` where the flattened project name sits; leave that glob exactly as it is and let the shell resolve it. Return {files: [...]} with every path printed, one entry per line, verbatim and in that order — a hyphen where a dot might be expected (\`github-com\`) is correct, not a typo. An empty listing is {files: []}. Do not open, read, or count the files.`

const extractBrief = (file, retry) => `You are a read-only measurement relay for one transcript file. Do not cd anywhere. Run these commands verbatim, sandboxed. The first writes a jq program with a quoted heredoc so nothing in it is expanded; the second runs it:

\`\`\`
cat > "\${TMPDIR:-/tmp}/wave-usage-$$.jq" <<'JQ'
${EXTRACT_JQ}JQ
jq -c -n -R -f "\${TMPDIR:-/tmp}/wave-usage-$$.jq" ${shellPath(file)}; echo "exit=$?"
\`\`\`

The transcript path is exact and must be copied character for character, including the one \`*\` that stands in for the flattened project name (the shell resolves it; do not replace it). A hyphen where a dot might be expected (\`github-com\`) is correct and is not a typo; do not "correct" any part of the path.
${retry === 'path' ? '\nThis is a SECOND run: the first run reported that jq could not open the file, which means the path was retyped incorrectly. Copy the path from the command above byte for byte.\n' : retry ? '\nThis is a SECOND, independent run of the same command against the same file — a prior run reported bootstrap:false and is being re-checked. Run the command fresh; do not reuse or assume any earlier result.\n' : ''}
jq prints exactly one JSON object. Return it as the structured output with ok:true and every field copied verbatim — bootstrap, cast, record, probe, exec, claim_agent, step_mention, reseat, tool_uses, models_observed, model_observation_complete, usage — including every number exactly as printed. Do not compute, estimate, round, or adjust anything, and do not read the transcript by any other means. Model names come only from the extracted message fields; missing observations remain empty. If jq exits non-zero or prints nothing, return ok:false with the error text in \`error\`.`

phase('Scout')
const listing = await agent(scoutBrief, { label: 'scout', phase: 'Scout', schema: FILES_SCHEMA, ...AGENT_CONFIG.scout })
const rawFiles = [...new Set(listing?.files || [])]
const listed = rawFiles.filter((f) => AGENT_LOG_RE.test(f))
if (listed.length !== rawFiles.length) {
    const dropped = rawFiles.filter((f) => !AGENT_LOG_RE.test(f))
    log(`wave-usage: scout listed ${rawFiles.length} path(s), ${dropped.length} not matching agent-*.jsonl and dropped: ${dropped.join(', ')}`)
}
const { files: transcripts, retyped: retypedByScout } = rebuildListing(dir, listed)
if (retypedByScout) {
    log(`wave-usage: scout returned ${retypedByScout} path(s) outside args.dir (the relay retyped the directory); rebuilt each from args.dir and the listed basename`)
}
log(`wave-usage: ${transcripts.length} agent transcript(s) under ${dir} (${mode} mode)`)
if (transcripts.length === 0) {
    throw new Error(`wave-usage: no agent-*.jsonl under ${dir} — nothing to measure, which is a finding, not an empty batch`)
}
const { files, unlisted } = filesToExtract(mode, dir, transcripts, listing)
if (mode === 'seats') {
    if (unlisted) log(`wave-usage: scout selected ${unlisted} path(s) its own listing lacks; dropped`)
    log(`wave-usage: ${files.length} transcript(s) brief a vote cast; the other ${transcripts.length - files.length} are not extracted` +
        (files.length === 0 ? ' — the selection ran clean and found no judge, so no seat row follows' : ''))
}

// TEST-BEGIN wave-usage-recheck-pipeline — extracted and exercised by
// tests/wave-usage-recheck-pipeline.test.sh; EXTRACT_SCHEMA requires only
// `ok`, so a schema-valid reply can still omit `usage` — reduceRows
// dereferences extract.usage[u] unguarded. Shared by the first-attempt
// classification and the bootstrap-recheck retry stage below, so neither
// path can reintroduce the gap the other one guards against.
function hasUsage(extract) {
    return Boolean(extract && extract.usage && typeof extract.usage === 'object')
}

// The test stubs `agent`, `pipeline`, `log`, `phase`, `extractBrief`,
// `EXTRACT_SCHEMA`, `AGENT_CONFIG` and sets `files` (an array of full paths)
// per case; `basename` is self-contained inside this region. One pipeline,
// extract then a conditional bootstrap-recheck stage, not two pipeline()
// calls with a plain-JS filter between them: two calls form a barrier, so a
// transcript reporting bootstrap:false would wait for every other
// transcript's first extract although its own recheck need is known once its
// extract classifies.
//
// agent() can reject (schema validation exhausted, a spawn error) rather
// than resolve to null; extractOnce catches into the null the `!r` branch
// already handled, so a rejection takes the same accounted path a
// resolved-to-null call would (see census-retry-pipeline's comment in
// session-census.js for why an uncaught rejection would be a real regression
// once two pipeline() calls become stages of one).
//
// STAGE 2's four-branch precedence is NOT simplifiable to "retry if
// bootstrap:false, else keep": a failed first attempt (null, !ok, no usage)
// pushes to `errors` and returns null (excluded from `results`, and NEVER
// retried — wave-usage only rechecks a confirmed-good extract that merely
// reported no bootstrap, never a failure); a GOOD extract with
// bootstrap !== false passes straight through, unretried; only
// bootstrap === false triggers stage 3's retry. ONE exception, stage 2b:
// a jq failure whose text says the FILE could not be opened is not a
// transcript failure at all but a relay one — the agent retyped the path
// (measured on one conductor session: a slug carrying `github-com` came
// back as `github.com` or `github_com` in nine extracts, and each sank a
// whole shard's join). That shape alone is retried once with a
// fresh agent; a second miss is then the error, so nothing is retried
// more than once and no other failure is retried at all. The path the
// agents type now carries the project slug as a glob (shellPath above), so
// the miss also arrives as zsh's `no matches found` when the glob's
// neighbours were retyped; both spellings are the same relay miss.
const errors = []
const PATH_MISS_RE = /could not open file|no such file or directory|no matches found/i
const extractOnce = (path, retry, label, config, what) => agent(extractBrief(path, retry), {
    label,
    phase: 'Extract',
    schema: EXTRACT_SCHEMA,
    ...config,
}).catch((err) => {
    log(`wave-usage: ${basename(path)}: ${what} agent error: ${err}`)
    return null
})
function classifyFirstAttempt(r, file, i) {
    if (!r) {
        log(`wave-usage: ${file}: extraction agent returned nothing`)
        errors.push(`${file}: extraction agent returned nothing`)
        return null
    }
    if (!r.extract || !r.extract.ok) {
        const why = (r.extract && r.extract.error) || 'no error text'
        if (PATH_MISS_RE.test(why)) {
            log(`wave-usage: ${file}: jq could not open the file (${why}) — the relay likely retyped the path; retrying once with a fresh agent`)
            return { file, path: files[i], pathMiss: why }
        }
        log(`wave-usage: ${file}: jq failed — ${why}`)
        errors.push(`${file}: jq failed — ${why}`)
        return null
    }
    if (!hasUsage(r.extract)) {
        log(`wave-usage: ${file}: extract reported ok but carried no usage`)
        errors.push(`${file}: extract reported ok but carried no usage`)
        return null
    }
    return { ...r, path: files[i] }
}

// STAGE 2b: fires only when stage 2 marked the item a path miss. The retry
// brief names the miss so the fresh agent copies the path byte for byte;
// its reply takes the same first-attempt classification, minus the retry.
let pathRetried = 0
function retryPathMiss(prev) {
    if (!prev || !prev.pathMiss) return prev
    pathRetried++
    return extractOnce(prev.path, 'path', `${prev.file} · extract (path retry)`, AGENT_CONFIG.extract, 'path-retry').then((second) => {
        if (!second) {
            errors.push(`${prev.file}: jq failed — ${prev.pathMiss} (path retry returned nothing)`)
            return null
        }
        if (!second.ok) {
            const why = second.error || 'no error text'
            log(`wave-usage: ${prev.file}: path retry also failed — ${why}`)
            errors.push(`${prev.file}: jq failed — ${prev.pathMiss} (path retry: ${why})`)
            return null
        }
        if (!hasUsage(second)) {
            errors.push(`${prev.file}: path retry reported ok but carried no usage`)
            return null
        }
        log(`wave-usage: ${prev.file}: path retry succeeded`)
        return { file: prev.file, extract: second, path: prev.path }
    })
}

// STAGE 3: fires only when stage 2 marked the item bootstrap-suspect.
// Every dispatched agent has a bootstrap brief, so a repeated bootstrap:false
// answer is treated as a relay misreport rather than a true bootstrap-free
// transcript, and rechecked once before trusting it.
let bootstrapRechecked = 0
function recheckBootstrap(prev) {
    if (!prev || prev.extract.bootstrap !== false) return prev
    bootstrapRechecked++
    log(`wave-usage: ${prev.file}: reported bootstrap:false — re-checking before trusting it`)
    return extractOnce(prev.path, true, `${prev.file} · extract (retry)`, AGENT_CONFIG.recheck, 'recheck').then((second) => {
        if (second && second.ok && second.bootstrap === false) {
            log(`wave-usage: ${prev.file}: bootstrap:false confirmed on a second, independent read — treating as a misreport and recording as overhead, not an error`)
            return { ...prev, extract: { ...prev.extract, bootstrapFallback: true } }
        }
        if (second && second.ok && hasUsage(second)) {
            log(`wave-usage: ${prev.file}: bootstrap:false did not repeat on retry — using the retry's answer`)
            return { ...prev, extract: second }
        }
        if (second && second.ok) {
            log(`wave-usage: ${prev.file}: retry reported ok but carried no usage — reporting the original error rather than a reply reduceRows cannot use`)
        } else {
            log(`wave-usage: ${prev.file}: retry could not confirm or refute the first answer — reporting the original error`)
        }
        return prev
    })
}

phase('Extract')
const basename = (f) => f.slice(f.lastIndexOf('/') + 1)
const extracted = await pipeline(
    files,
    (file) => extractOnce(file, undefined, `${basename(file)} · extract`, AGENT_CONFIG.extract, 'extract'),
    (extract, file) => ({ file: basename(file), extract }),
    (r, file, i) => classifyFirstAttempt(r, basename(file), i),
    retryPathMiss,
    recheckBootstrap,
)
const results = extracted.filter(Boolean)
// TEST-END wave-usage-recheck-pipeline
if (pathRetried) log(`wave-usage: ${pathRetried} transcript(s) had their path retyped by the relay and were retried once`)
if (bootstrapRechecked) log(`wave-usage: ${bootstrapRechecked} transcript(s) reported bootstrap:false and were rechecked`)
const summary = reduceRows(results, mode, exclude)
const coordination = mode === 'steps' ? coordinationOf(results, manifestRows, waveStatuses) : null
const reduced = { ...summary, errors: [...errors, ...summary.errors], coordination }

for (const observation of reduced.model_observations) {
    log(`wave-usage: ${observation.file}: serving models ` +
        `${observation.models.join(', ') || 'unknown'} ` +
        `(${observation.complete ? 'all parsed response model fields present' : 'model fields missing'}); ` +
        'effective effort unknown')
}

for (const s of reduced.skipped) {
    if (s.reason === 'unattributed') {
        log(`wave-usage: ${s.file}: no seat (never cast) — dropped here; steps mode carries it if it recorded a step, and reports it as wave overhead if it did not`)
    } else if (s.reason === 'seated') {
        log(`wave-usage: ${s.label}: cast a ballot — skipped here, carried by seats mode`)
    } else if (s.reason === 'dead-spawn') {
        log(`wave-usage: ${s.file} (${s.label}): dead spawn — no usage, and another transcript carries this ${mode === 'seats' ? 'seat' : 'step'}; skipped, not thrown`)
    } else {
        log(`wave-usage: ${s.file} (${s.label}): excluded — a prior back-fill already carries this ${mode === 'seats' ? 'seat' : 'step'}`)
    }
}
for (const o of reduced.overhead.agents) {
    log(`wave-usage: ${o.file}: ${o.label} — recorded no step, so its usage is wave overhead and is attributed to none`)
}
if (reduced.overhead.agents.length) {
    const sums = UNITS.map((u) => `${u} ${reduced.overhead.sums[u]}`).join(', ')
    log(`wave-usage: WAVE OVERHEAD: ${reduced.overhead.agents.length} agent(s), ${sums} — no step owns this spend; it is reported, not back-filled`)
}
const keyOf = (r) => (mode === 'seats' ? `${r.proposal} ${r.voter}` : r.step)
log(`wave-usage: ${reduced.rows.length} row(s) over ${new Set(reduced.rows.map(keyOf)).size} key(s)` +
    (mode === 'seats' ? ' (four token units and tool_uses per seat)' : ''))
if (mode === 'steps') {
    if (coordination) {
        const c = coordination
        log(`wave-usage: coordination — ${c.rows} row(s) this launch; rounds per issue ` +
            `${Object.entries(c.rounds_per_issue).map(([i, n]) => `${i}@${n}`).join(', ') || 'none'}; ` +
            `gates ${c.gates.passed} passed / ${c.gates.rejected} rejected / ${c.gates.parked} parked` +
            ` (first pass ${c.gates.first_pass.passed} of ${c.gates.first_pass.decided}); ` +
            `${c.reseats} re-seat(s), ${c.claim_conflicts} claim conflict(s), ` +
            `${c.ancestry_parks} ancestry park(s), ${c.spawn_failed} spawn failure(s), ` +
            `${c.deferred.total} deferred` +
            (c.unmatched_steps.length ? `; no manifest row for ${c.unmatched_steps.join(', ')}` : ''))
    } else {
        log('wave-usage: coordination not measured — pass the wave\'s returned statuses and the ' +
            'manifest rows as args.statuses and args.rows to count rounds, gate passes, ' +
            're-seats, claim conflicts, ancestry parks and deferrals')
    }
} else if (waveStatuses) {
    log('wave-usage: args.rows and args.statuses are read in steps mode only — ignored here')
}
if (reduced.errors.length) {
    for (const e of reduced.errors) log(`wave-usage: ${e}`)
    throw new Error(`wave-usage: ${reduced.errors.length} error(s) — ${reduced.errors.join('; ')}`)
}

return reduced
