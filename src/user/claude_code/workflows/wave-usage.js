export const meta = {
    name: 'wave-usage',
    description: 'Measure a completed wave\'s token spend from its agent transcripts and emit the back-fill rows: one row per (step, unit) for `docket dispatch backfill-usage --from-json -`, or per (proposal, voter, unit) for `docket vote backfill-usage --from-json -`. Every agent is partitioned exactly once into judge, claimant, or wave overhead by what its bootstrap brief told it to do. PROBE COST: one low-effort read-only agent per agent-*.jsonl in the directory, plus one scout. Invoke by scriptPath ONLY, with args {dir, mode?, exclude?}.',
    whenToUse: 'Invoked by the docket-run skill the moment a wave returns, launched beside the close rather than ahead of it (the engine treats a step recorded less than `dispatch.grace` ago as usage PENDING, so the join may land after the close; a step still unbilled past that window is the `usage-rows-missing` refusal it always was), and by the pause and resume paths for a wave whose usage was never back-filled. args is {dir: absolute transcript directory, mode: "steps" (default) | "seats", exclude: [STEP-N...] in steps mode or [seat...] in seats mode}. The script cannot read files itself; its agents run one fixed jq program per transcript and the reduction happens here.',
    phases: [
        { title: 'Scout', detail: 'one agent lists the agent transcripts' },
        { title: 'Extract', detail: 'one low-effort agent per transcript runs the fixed jq' },
    ],
}

// ---------------------------------------------------------------------------
// THE TRANSCRIPT-DERIVED TOKEN PATH, designed rather than a workaround: a
// claimant cannot observe its own token consumption, so the conductor that
// spawned it measures the transcripts here and pipes the rows to
// `backfill-usage`. `docket step record --usage` is the engine's channel for
// units a claimant CAN measure at source.
//
// Each agent-<id>.jsonl is read by one agent running EXTRACT_JQ below, which
// reports what the bootstrap brief (the first user message) told the agent to
// do and the agent's four typed token units. This script joins, partitions,
// sums and sorts; agents read, the script decides.
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
//    counts every agent at most once; it does not exclude vote steps to
//    compensate.
//
//  * `exclude` drops a key a PRIOR dispatch's back-fill already carries (a
//    gate probed in one wave and seated in the next emits usage in both
//    journals). In seats mode it names a bare seat and drops it under every
//    proposal. Excluded keys are logged, never silently dropped.
//
// args:   {dir, mode?, exclude?}
//         dir      absolute path of the wave's transcript directory
//         mode     'steps' (default) or 'seats'
//         exclude  [STEP-N...] in steps mode, [seat...] in seats mode; [] default
// return: {rows, overhead: {agents: [{file, label}], sums}, skipped, errors,
//          model_observations}
//         rows     [{step, unit, quantity}] or [{proposal, voter, unit, quantity}],
//                  four unit rows per key, sorted numerically by step or
//                  lexicographically by (proposal, voter)
//         overhead the agents that recorded no step and cast no ballot, with
//                  their summed units (steps mode; empty in seats mode)
//         skipped  [{file, reason: 'seated'|'unattributed'|'excluded', key, label}]
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
// Throws when the directory holds no agent transcripts, when an agent's
// bootstrap cannot be read, when an executor brief names no step to record,
// or when a dispatched agent carries no usage.
// ---------------------------------------------------------------------------

let input = args
if (typeof input === 'string') {
    input = JSON.parse(input)
    log('wave-usage: decoded args from the harness JSON-encoded transport (normal)')
}
input = input || {}
const dir = input.dir
if (typeof dir !== 'string' || !dir.startsWith('/')) {
    throw new Error(`wave-usage: args.dir must be an absolute transcript directory, got ${JSON.stringify(dir)}`)
}
const mode = input.mode == null ? 'steps' : input.mode
if (mode !== 'steps' && mode !== 'seats') {
    throw new Error(`wave-usage: args.mode must be "steps" or "seats", got ${JSON.stringify(mode)}`)
}
const exclude = Array.isArray(input.exclude) ? input.exclude.map(String) : []

// TEST-BEGIN wave-usage-extract — extracted by
// tests/wave-usage-probe-overhead.test.sh and run with the same jq flags as
// the agents use. Keep it free of workflow globals.
//
// Run as `jq -c -n -R -f <this> <transcript>`: raw lines, so a line that is
// not JSON is skipped instead of aborting the file. Prints ONE object.
//
// The bootstrap is the first user message's content: a string as-is, a
// content array JSON-encoded, so its line breaks arrive as a literal
// backslash-n. Every marker below is therefore newline-free, and READ_JOB's
// regex accepts either a real newline or that two-byte sequence.
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
// Backslashes are doubled once for the template literal: the file the agent
// writes carries jq source, in which `\\s` is the regex escape.
const EXTRACT_JQ = `[inputs | fromjson? | select(type == "object")] as $lines
| ([$lines[] | select(.type == "user")] | .[0]) as $first
| (if $first == null then null
   else ($first.message.content | if type == "string" then . else tojson end) end) as $boot
| ($boot // "") as $b
| (reduce ($lines[] | select(.type == "assistant") | .message
            | select((.usage // {}) != {} and (.id // "") != "")) as $m
        ({}; .[$m.id] = $m) | [.[]]) as $messages
| {
    bootstrap: ($boot != null),
    cast: (($b | capture("docket vote cast\\\\s+(?<proposal>\\\\S+)\\\\s+--voter\\\\s+(?<voter>\\\\S+)")) // null),
    record: (($b | capture("docket step (?:claim|record|complete)\\\\s+(?<step>STEP-\\\\d+)") | .step) // null),
    probe: ($b | (
        contains("WAVE PROBE: not a step execution")
        or contains("You are a DIAGNOSTIC PROBE inside a running Docket wave")
        or (contains("Run exactly this one command:") and contains("read-only probe reporting what the"))
        or test("Run exactly this one command:(?:\\\\\\\\n|\\\\s)+\`?docket\\\\s+(?:[a-z-]+\\\\s+)?(?:show|context|list|tally|next|log)\\\\b"))),
    exec: ($b | contains("You are executing one step of a Docket run")),
    step_mention: (($b | [match("STEP-\\\\d+")][0].string) // null),
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

// TEST-BEGIN wave-usage-classify — extracted and exercised by
// tests/wave-usage-probe-overhead.test.sh over jq output from fixture
// transcripts. Keep everything between the markers free of workflow globals
// (agent, log, args) so it stays evaluable on its own.
const UNITS = ['input_tokens', 'output_tokens', 'cache_creation_tokens', 'cache_read_tokens']

const zeroSums = () => Object.fromEntries(UNITS.map((u) => [u, 0]))

// The three questions, in the one order that cannot misfile a read: briefed
// to cast? briefed only to read? briefed to record? First yes wins. `file`
// appears only in labels and error text.
function classify(extract, mode, file) {
    const x = extract
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
        return { bucket: 'error', key: null, label: `${file}: no user message — cannot classify` }
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
        const what = probe ? 'read-only probe' : 'not a wave agent'
        return { bucket: 'overhead', key: null,
                 label: `${what}${x.step_mention ? `, mentions ${x.step_mention}` : ''}` }
    }
    return { bucket: 'row', key: record, label: record }
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
    for (const { file, extract } of results) {
        const c = classify(extract, mode, file)
        if (c.bucket === 'error') { errors.push(c.label); continue }
        if (c.bucket === 'seated' || c.bucket === 'unattributed') {
            skipped.push({ file, reason: c.bucket, key: c.key, label: c.label })
            continue
        }
        const models = Array.isArray(extract.models_observed)
            ? [...new Set(extract.models_observed.filter((m) =>
                typeof m === 'string' && m !== '' && m !== '<synthetic>'))].sort()
            : []
        model_observations.push({
            file,
            kind: c.bucket === 'overhead' ? 'overhead' : mode === 'seats' ? 'seat' : 'step',
            key: c.key,
            models,
            complete: extract.model_observation_complete === true && models.length > 0,
            source: 'assistant.message.model',
            effort_resolved: 'unknown',
        })
        if (c.bucket === 'overhead') {
            overhead.agents.push({ file, label: c.label })
            for (const u of UNITS) overhead.sums[u] += extract.usage[u] || 0
            continue
        }
        const excludeName = mode === 'seats' ? c.key[1] : c.key
        if (excluded.has(excludeName)) {
            skipped.push({ file, reason: 'excluded', key: c.key, label: c.label })
            continue
        }
        if (!UNITS.some((u) => extract.usage[u] > 0)) {
            errors.push(`${file} (${c.label}): transcript carries no usage`)
            continue
        }
        const id = mode === 'seats' ? c.key.join(' ') : c.key
        if (!totals.has(id)) totals.set(id, { key: c.key, sums: zeroSums() })
        const t = totals.get(id).sums
        for (const u of UNITS) t[u] += extract.usage[u] || 0
    }
    const cmp = mode === 'seats'
        ? (a, b) => (a.key[0] < b.key[0] ? -1 : a.key[0] > b.key[0] ? 1 :
                     a.key[1] < b.key[1] ? -1 : a.key[1] > b.key[1] ? 1 : 0)
        : (a, b) => parseInt(a.key.split('-')[1], 10) - parseInt(b.key.split('-')[1], 10)
    const rows = []
    for (const { key, sums } of [...totals.values()].sort(cmp)) {
        for (const unit of UNITS) {
            rows.push(mode === 'seats'
                ? { proposal: key[0], voter: key[1], unit, quantity: sums[unit] }
                : { step: key, unit, quantity: sums[unit] })
        }
    }
    return { rows, overhead, skipped, errors, model_observations }
}
// TEST-END wave-usage-classify

const sq = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`

const FILES_SCHEMA = {
    type: 'object',
    required: ['files'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
    },
}

const usageSchema = {
    type: 'object',
    required: UNITS,
    properties: Object.fromEntries(UNITS.map((u) => [u, { type: 'integer' }])),
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
        step_mention: { type: ['string', 'null'] },
        models_observed: { type: 'array', items: { type: 'string' } },
        model_observation_complete: { type: 'boolean' },
        usage: usageSchema,
    },
}

const scoutBrief = `You are a read-only scout. Do not cd anywhere. Run this command verbatim, sandboxed, and report what it prints — never a paraphrase:

\`\`\`
find ${sq(dir)} -maxdepth 1 -type f -name 'agent-*.jsonl' | LC_ALL=C sort; echo "exit=$?"
\`\`\`

Return {files: [...]} with every path printed, one entry per line, verbatim and in that order. An empty listing is {files: []}. Do not open, read, or count the files.`

const extractBrief = (file) => `You are a read-only measurement relay for one transcript file. Do not cd anywhere. Run these commands verbatim, sandboxed. The first writes a jq program with a quoted heredoc so nothing in it is expanded; the second runs it:

\`\`\`
cat > "\${TMPDIR:-/tmp}/wave-usage-$$.jq" <<'JQ'
${EXTRACT_JQ}JQ
jq -c -n -R -f "\${TMPDIR:-/tmp}/wave-usage-$$.jq" ${sq(file)}; echo "exit=$?"
\`\`\`

jq prints exactly one JSON object. Return it as the structured output with ok:true and every field copied verbatim — bootstrap, cast, record, probe, exec, step_mention, models_observed, model_observation_complete, usage — including every number exactly as printed. Do not compute, estimate, round, or adjust anything, and do not read the transcript by any other means. Model names come only from the extracted message fields; missing observations remain empty. If jq exits non-zero or prints nothing, return ok:false with the error text in \`error\`.`

phase('Scout')
const listing = await agent(scoutBrief, { label: 'scout', phase: 'Scout', schema: FILES_SCHEMA, effort: 'low' })
const files = [...new Set((listing && listing.files) || [])]
    .filter((f) => /\/agent-[^/]*\.jsonl$/.test(f))
    .sort()
log(`wave-usage: ${files.length} agent transcript(s) under ${dir} (${mode} mode)`)
if (files.length === 0) {
    throw new Error(`wave-usage: no agent-*.jsonl under ${dir} — nothing to measure, which is a finding, not an empty batch`)
}

phase('Extract')
const basename = (f) => f.slice(f.lastIndexOf('/') + 1)
const extracted = await pipeline(
    files,
    (file) => agent(extractBrief(file), {
        label: `${basename(file)} · extract`,
        phase: 'Extract',
        schema: EXTRACT_SCHEMA,
        effort: 'low',
    }),
    (extract, file) => ({ file: basename(file), extract }),
)

const errors = []
const results = []
extracted.forEach((r, i) => {
    const file = basename(files[i])
    if (!r) {
        log(`wave-usage: ${file}: extraction agent returned nothing`)
        errors.push(`${file}: extraction agent returned nothing`)
        return
    }
    if (!r.extract || !r.extract.ok) {
        const why = (r.extract && r.extract.error) || 'no error text'
        log(`wave-usage: ${file}: jq failed — ${why}`)
        errors.push(`${file}: jq failed — ${why}`)
        return
    }
    results.push(r)
})

const reduced = reduceRows(results, mode, exclude)
reduced.errors.unshift(...errors)

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
log(`wave-usage: ${reduced.rows.length} row(s) over ${reduced.rows.length / UNITS.length} key(s)`)
if (reduced.errors.length) {
    for (const e of reduced.errors) log(`wave-usage: ${e}`)
    throw new Error(`wave-usage: ${reduced.errors.length} error(s) — ${reduced.errors.join('; ')}`)
}

return reduced
