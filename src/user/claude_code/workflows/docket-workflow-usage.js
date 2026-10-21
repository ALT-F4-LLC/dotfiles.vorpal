export const meta = {
    name: 'docket-workflow-usage',
    description: 'Internal: launched through scriptPath by docket-run when a wave returns; measures a completed wave\'s token spend from its agent transcripts and emits the back-fill rows for `docket dispatch backfill-usage` or `docket vote backfill-usage`. Args and probe cost in the header comment.',
    whenToUse: 'Never by name. Launched beside the dispatch close, and by the pause and resume paths for a wave never back-filled.',
    phases: [
        { title: 'Scout', detail: 'one agent lists the agent transcripts and, in seats mode, selects the seat transcripts' },
        { title: 'Extract', detail: 'one low-effort agent per listed transcript (seats mode: per seat transcript) runs the fixed jq' },
    ],
}

// ---------------------------------------------------------------------------
// CONTRACT FOR CALLERS (the listing's description is a one-line summary;
// this block and the args and return block further down are the contract).
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
// confidence. PROBE COST: one scout, plus one low-effort
// read-only extract agent per transcript to measure: in steps mode every
// agent-*.jsonl in the directory, in seats mode only each seat transcript
// (one whose bootstrap brief instructs a `docket vote cast`, selected by the
// scout without an agent per file), plus one re-check for any transcript
// relayed as bootstrap:false, plus one retry for any transcript whose path
// the relay retyped. Invoke by scriptPath
// ONLY, with args {dir, mode?, exclude?}.
//
// When and how it is invoked:
// Invoked by the docket-run skill the moment a wave returns. On the normal
// path it launches in docket-run's back-fill step, ahead of that step's close
// call, and the pause and resume paths launch it for a wave whose usage was
// never back-filled. The join's usage record can still land after the close
// call returns. The engine measures the `dispatch.grace` window from the run's
// newest terminal step record, which is the wave's last one. While that record
// is inside the window, every step recorded before it is usage PENDING. A step
// still unbilled once that record is past the window gets the
// `usage-rows-missing` refusal. args is {dir: absolute transcript directory, mode: "steps"
// (default) | "seats", exclude: [STEP-N...] in steps mode or [seat...] in
// seats mode}. The script cannot read files itself; its agents run one fixed jq program per
// transcript and the reduction happens here.
// ---------------------------------------------------------------------------

// scout/extract/recheck only relay a fixed command's output through a schema
// (no judgment involved), so a cheap model is pinned rather than inherited —
// the same reasoning docket-workflow.js:probe and tribunal.js:verify already apply to
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
//    this step": docket-workflow.js probes a row before claiming it, and a first-match
//    join back-filled ~17K tokens per probe onto pending and superseded steps
//    no agent ever ran on a past wave.
//
//  * THE CAST JOIN IS THE SEAT'S INSTRUCTION, NOT ANY CAST TEXT. A step
//    executor's packet quotes cast commands whenever its work is on the vote
//    path, and an unanchored join filed those executors as seats and dropped
//    their steps' usage. The join reads only a cast command that opens a
//    line, in a brief that does not open as a step executor (BRIEF_DEFS_JQ).
//
//  * ASK WHAT THE BRIEF IS FOR BEFORE ASKING WHAT STEP IT NAMES: briefed to
//    cast? briefed only to read? briefed to record? The first yes wins. The
//    read test sits ABOVE the step join on purpose: a probe can quote the
//    obligation it is reading about, and with the join first the ledger was
//    safe only while probe briefs happened to carry no record-shaped text.
//
//  * ALL THREE BOOTSTRAP TESTS (cast, read, record) READ THE BOOTSTRAP ONLY,
//    never a later user message.
//    Later messages carry tool results, and a probe's own `docket step show`
//    output can quote a step artifact naming the record command. What briefs
//    the agent decides; what the agent read back cannot.
//
//  * THE `exec` MARK IS THE DRIFT SAFETY NET. An agent whose brief opens as an
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
//    server_tool_use blocks are not counted, matching session-census.js, nor
//    is the StructuredOutput call every seat's schema forces at its end. The
//    count is an audit signal for docket-retro's seat-calibration row (reads
//    can be spammed, so it is never a tally input) and reaches the ledger
//    only in seats mode, as a fifth unit beside the four token units; steps
//    mode keeps its four-row contract.
//
// args:   {dir, mode?, exclude?}
//         dir       absolute path of the wave's transcript directory
//         mode      'steps' (default) or 'seats'
//         exclude   [STEP-N...] in steps mode, [seat...] in seats mode; [] default
// return: {rows, overhead: {agents: [{file, label}], sums}, skipped, errors,
//          model_observations}
//         rows     [{step, unit, quantity}] or [{proposal, voter, unit, quantity}],
//                  four token unit rows per step, or those four plus one
//                  `tool_uses` row per (proposal, voter), sorted numerically
//                  by step or lexicographically by (proposal, voter)
//                  In steps mode the first unit row of a step carries a
//                  `metadata` object when one transcript served the step, its
//                  model coverage is complete, and its last model is known:
//                  {model_resolved, effort_resolved?, models_observed?}.
//                  effort_resolved appears only when known; models_observed
//                  (sorted) appears only when several models served the step.
//                  `dispatch backfill-usage` merges the object onto the step
//                  record. A step that two or more transcripts served gets no
//                  metadata: its record keeps the executor's `unknown`.
//         overhead the agents that recorded no step and cast no ballot, with
//                  their summed units (steps mode; empty in seats mode)
//         skipped  [{file, reason: 'seated'|'unattributed'|'excluded'|'dead-spawn', key, label}]
//         errors   [string]; when non-empty the script throws after logging
//                  each one, because silence must not look like success
//         model_observations [{file, kind, key, models, last_model, complete,
//                              source, effort_source, effort_resolved}]
//                  serving models from assistant.message.model, separately
//                  from routing requests and token rows. Multiple models can
//                  serve one agent after fallback. last_model is the model of
//                  the final usage-bearing assistant turn, or null; models is
//                  sorted, so it cannot say which model served last.
//                  effort_resolved is the one effort the transcript records on
//                  its assistant turns (top-level `effort`), or 'unknown' when
//                  it records none or several. Missing fields stay unknown;
//                  neither routing settings nor model self-reports fill them.
//                  complete covers parsed, deduplicated usage-bearing messages;
//                  it does not certify that the transcript or task finished.
// Throws on an invalid args.dir or args.mode; on a scout listing whose
// files_exit is not 0, or that is still short of its printed files_count
// (or, in seats mode, seats_count) after one re-run of the scout; in seats mode, on a scout with no seats listing or a
// non-zero seats_exit; when the directory holds no agent transcripts; and
// whenever `errors` is non-empty. `errors` collects, among others, a fresh
// re-check of a relayed bootstrap:false that returns no usable answer, an
// extraction agent that returns nothing, a jq failure that survives its retry,
// a step key that is not STEP-N or an executor brief that names no step to
// record, a steps-mode directory holding only usage-join agents (a lane
// mismatch: args.dir names another join's workflow, so the run measured
// nothing for the lane and is not the lane's join), and a dispatched agent that carries no usage. A bootstrap:false confirmed on that re-check is not an
// error: it is folded into wave overhead instead, since docket-workflow.js never
// dispatches an agent without a bootstrap brief.
// ---------------------------------------------------------------------------

const input = (typeof args === 'string' ? JSON.parse(args) : args) || {}
if (typeof args === 'string') log('docket-workflow-usage: decoded args from the harness JSON-encoded transport (normal)')
const dir = input.dir
if (typeof dir !== 'string' || !dir.startsWith('/')) {
    throw new Error(`docket-workflow-usage: args.dir must be an absolute transcript directory, got ${JSON.stringify(dir)}`)
}
const mode = input.mode ?? DEFAULT_MODE
if (mode !== 'steps' && mode !== 'seats') {
    throw new Error(`docket-workflow-usage: args.mode must be "steps" or "seats", got ${JSON.stringify(mode)}`)
}
const exclude = Array.isArray(input.exclude) ? input.exclude.map(String) : []

// TEST-BEGIN docket-workflow-usage-extract — extracted by
// tests/docket-workflow-usage-probe-overhead.test.sh and run with the same jq flags as
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
// probe is the four-way read test: the explicit declaration docket-workflow.js's
// probeBrief() closes with (via probeTrailer()), the block probe's opening sentence, the legacy
// probe self-description (truncated on purpose: docket-workflow.js writes "what the
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
// claim_agent is the declaration docket-workflow.js's claimBrief() closes with. The
// claim agent runs docket-workflow-claim for an executor and is wave overhead: its
// brief never spells a claim or record of the step, so it never joins one.
//
// usage_join marks this workflow's own scout and extract relay: their briefs
// open with fixed sentences (read after the harness preamble, as cast_join
// reads its opening). It is read ahead of exec and probe because a relay's brief
// embeds this file's jq source, which sets both. A usage-join agent is overhead,
// and a steps-mode directory of nothing else is a lane mismatch.
//
// reseat is the sentence tribunal.js opens a re-seated judge's brief with.
// tool_uses counts distinct tool_use block ids over every assistant line, not
// the deduplicated messages: see TOOL USE IS COUNTED BY BLOCK ID above. The
// StructuredOutput call a seat's schema forces is its return, not
// investigation, so it never counts.
//
// Backslashes are doubled once for the template literal: the file the agent
// writes carries jq source, in which `\\s` is the regex escape.
//
// BRIEF_DEFS_JQ is the bootstrap rule and the cast join, shared verbatim with
// SELECT_JQ below: seats mode extracts only what SELECT_JQ selects, so a
// transcript this program would seat must be one that program selects.
//
// The cast join reads the seat's own cast instruction, never a quote of one.
// A step executor's packet quotes the issue body, the diff and file excerpts,
// so work on the vote path carries `docket vote cast <x> --voter <y>` text;
// an unanchored join once filed those executors as seats and dropped their
// usage from the back-fill. Two anchors close that: the command must open a
// line (after optional indentation, a `Cast with:` label, or tribunal.js's
// `cd <cwd> && ` prefix), and a brief that opens as a step executor joins no
// cast at all, wherever its packet puts the quote. The opening is read from
// the first 200 characters, so a seat whose case quotes an executor brief
// further down is still a seat. Those characters are counted after the
// harness's one-line `[Workflow harness — …]` preamble, which can open the
// bootstrap ahead of the brief and is itself longer than 200 characters.
const BRIEF_DEFS_JQ = `def bootstrap_candidate: .type == "user"
    and (.message.content | type == "string"
        and startswith("[Workflow harness — user request]") | not);
def bootstrap_text: .message.content | if type == "string" then . else tojson end;
def brief_head: sub("^\\\\[Workflow harness —[^\\\\n]*\\\\n"; "") | .[0:200];
def cast_join: if brief_head
        | contains("You are executing one step of a Docket run") then null
    else capture("(?:^|\\\\n|\\\\\\\\n)[ \\\\t]*(?:Cast with:[ \\\\t]*)?(?:cd\\\\s+\\\\S+\\\\s+&&\\\\s+)?docket vote cast\\\\s+(?<proposal>\\\\S+)\\\\s+--voter\\\\s+(?<voter>\\\\S+)") end;
`
const EXTRACT_JQ = `${BRIEF_DEFS_JQ}[inputs | fromjson? | select(type == "object")] as $lines
| ([$lines[] | select(bootstrap_candidate)] | .[0]) as $first
| (if $first == null then null else ($first | bootstrap_text) end) as $boot
| ($boot // "") as $b
| (reduce ($lines[] | select(.type == "assistant") | .message
            | select((.usage // {}) != {} and (.id // "") != "")) as $m
        ({}; .[$m.id] = $m) | [.[]]) as $messages
| ([$lines[] | select(.type == "assistant")
            | select((.message.usage // {}) != {} and (.message.id // "") != "")
            | {model: .message.model, effort: .effort}]) as $served
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
    usage_join: ($b | brief_head | (contains("You are a read-only scout.") or contains("You are a read-only measurement relay for one transcript file."))),
    step_mention: (($b | [match("STEP-\\\\d+")][0].string) // null),
    reseat: ($b | contains("THIS IS A SECOND ATTEMPT AT YOUR SEAT")),
    tool_uses: ([$lines[] | select(.type == "assistant") | .message.content
                 | if type == "array"
                   then .[] | select(type == "object" and .type == "tool_use" and .name != "StructuredOutput") | .id // empty
                   else empty end]
                | unique | length),
    models_observed: ([$messages[].model | select(type == "string" and . != "" and . != "<synthetic>")] | unique),
    last_model: (($served | last | .model | select(type == "string" and . != "" and . != "<synthetic>")) // null),
    efforts_observed: ([$served[].effort | select(type == "string" and . != "")] | unique),
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
// TEST-END docket-workflow-usage-extract

// TEST-BEGIN docket-workflow-usage-select — extracted and run by
// tests/docket-workflow-usage-probe-overhead.test.sh after the extract region, whose
// BRIEF_DEFS_JQ it reads. Keep it free of workflow globals.
//
// Run by the seats-mode scout as `jq -r -n -R '<this>' <transcript>...`
// (any number of files per invocation; see scoutBrief): prints the path of
// every transcript whose bootstrap carries the cast command, so seats mode spawns no extract
// agent for a claimant, claim agent or probe. Only the first bootstrap
// candidate per file is kept and read, never a later tool result.
const SELECT_JQ = `${BRIEF_DEFS_JQ}reduce (inputs | fromjson? | select(type == "object" and bootstrap_candidate)
        | {file: input_filename, text: bootstrap_text}) as $u
    ({}; if has($u.file) then . else .[$u.file] = $u.text end)
| to_entries[] | select(.value | cast_join) | .key
`
// TEST-END docket-workflow-usage-select

// TEST-BEGIN docket-workflow-usage-classify — extracted and exercised by
// tests/docket-workflow-usage-probe-overhead.test.sh over jq output from fixture
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

// A usage-join agent is set aside first (see usage_join above). Then the
// three questions, in the one order that cannot misfile a read: briefed
// to cast? briefed only to read? briefed to record? First yes wins. `file`
// appears only in labels and error text.
function classify(raw, mode, file) {
    const x = normalizeKeys(raw)
    // A seat needs both halves of its key. The extract relay has copied jq's
    // `cast: null` as {proposal: "", voter: ""}, which seated a step executor
    // under ["",""] and dropped its step's usage; such a cast is no cast.
    const seat = x.cast && x.cast.proposal && x.cast.voter ? [x.cast.proposal, x.cast.voter] : null
    if (mode === 'seats') {
        if (!seat) return { bucket: 'unattributed', key: null, label: file }
        return { bucket: 'row', key: seat, label: seat.join('/') }
    }
    if (seat) {
        return { bucket: 'seated', key: seat, label: `${file} (${seat.join('/')})` }
    }
    if (!x.bootstrap) {
        // The relaying agent said jq found no first `type:"user"` line. Twice
        // in a row (bootstrapFallback set by the caller after a fresh retry
        // repeats the answer) is treated as a misreport rather than truth —
        // docket-workflow.js never dispatches an agent without a bootstrap brief, so a
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
    // A usage-join agent (scout, extract relay) is never a lane agent: its
    // spend is overhead, and reduceRows refuses a directory made only of them.
    // It is read ahead of exec and probe because a relay's brief embeds this
    // file's jq source and sets both. A usage-join marker beside a step record
    // is a relay error, never overhead: it would move a step's usage out of
    // the ledger without a word.
    if (x.usage_join) {
        if (x.record) {
            return { bucket: 'error', key: null,
                     label: `${file}: reads as a usage-join agent but names ${JSON.stringify(x.record)} — the relay copied usage_join onto a step record` }
        }
        return { bucket: 'overhead', key: null, usageJoin: true,
                 label: `usage-join agent${x.step_mention ? `, mentions ${x.step_mention}` : ''}` }
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

// A served model name as the API spells it. The haiku relay intermittently
// returns it JSON-quoted ('"claude-opus-5-5"'); one layer is stripped, and
// anything that is still not a model name is no observation, so the back-fill
// never stores a quoted or prose value as model_resolved.
const MODEL_NAME_RE = /^[a-z0-9][a-z0-9.-]*$/
const modelName = (v) => {
    const m = unquote(v)
    return typeof m === 'string' && MODEL_NAME_RE.test(m) ? m : null
}

function modelObservation(file, extract, classification, mode) {
    // Unquote first, so a quoted "<synthetic>" is skipped like a bare one.
    const relayed = (Array.isArray(extract.models_observed) ? extract.models_observed : [])
        .filter((model) => typeof model === 'string')
        .map(unquote)
        .filter((model) => model !== '' && model !== '<synthetic>')
    const named = relayed.map(modelName).filter((model) => model !== null)
    const models = [...new Set(named)].sort()
    const invalidModels = relayed.length - named.length
    const lastModel = typeof extract.last_model === 'string' && extract.last_model !== ''
        ? modelName(extract.last_model) : null
    const lastModelInvalid = typeof extract.last_model === 'string' && extract.last_model !== '' && lastModel === null
    const efforts = Array.isArray(extract.efforts_observed)
        ? [...new Set(extract.efforts_observed.filter((effort) =>
            typeof effort === 'string' && effort !== ''))].sort()
        : []
    return {
        file,
        kind: classification.bucket === 'overhead' ? 'overhead' : mode === 'seats' ? 'seat' : 'step',
        key: classification.key,
        models,
        last_model: lastModel,
        complete: extract.model_observation_complete === true && models.length > 0
            && invalidModels === 0 && !lastModelInvalid,
        source: 'assistant.message.model',
        effort_source: 'assistant.effort',
        effort_resolved: efforts.length === 1 ? efforts[0] : 'unknown',
    }
}

// The step metadata a back-fill row carries: the served model and effort a
// single transcript proves. Null when coverage is partial or no last model is
// known, so the step keeps the executor's own `unknown` sentinel.
function servedMetadata(observation) {
    if (!observation.complete || observation.last_model === null) return null
    const metadata = { model_resolved: observation.last_model }
    if (observation.effort_resolved !== 'unknown') metadata.effort_resolved = observation.effort_resolved
    if (observation.models.length > 1) metadata.models_observed = observation.models
    return metadata
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
    // summed, not in line: docket-workflow.js re-spawns a claimant whose first spawn
    // died before its first assistant turn, and that dead transcript still
    // opens with the step's brief. Beside a live transcript for the same
    // key it is a dead spawn and is skipped; alone, silence is still an
    // error, not a zero row. Directory order does not decide which of the
    // two is read first, hence the deferral.
    const silent = []
    let usageJoinAgents = 0
    let laneAgents = 0
    for (const { file, extract } of results) {
        const c = classify(extract, mode, file)
        if (c.bucket === 'error') {
            errors.push(c.label)
            continue
        }
        if (c.usageJoin) usageJoinAgents++
        else if (c.bucket === 'row' || c.bucket === 'seated') laneAgents++
        if (c.bucket === 'seated' || c.bucket === 'unattributed') {
            skipped.push({ file, reason: c.bucket, key: c.key, label: c.label })
            continue
        }
        const observation = modelObservation(file, extract, c, mode)
        model_observations.push(observation)
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
        if (!totals.has(id)) totals.set(id, { key: c.key, sums: zeroSums(), tool_uses: 0, files: 0, observation: null })
        const total = totals.get(id)
        addUsage(total.sums, extract.usage)
        total.tool_uses += toolUses(extract)
        total.files++
        total.observation = observation
    }
    // A directory of only usage-join agents is another join's workflow, not the
    // lane: a hand-typed wrong dir otherwise yields a join of the join, with no
    // step to back-fill, and invites a repeat join.
    if (mode === 'steps' && usageJoinAgents > 0 && laneAgents === 0) {
        errors.push(`lane mismatch: args.dir holds ${usageJoinAgents} usage-join agent(s) (scout, extract) and no lane executor; it is a usage-join workflow directory, not the lane's. This run measured nothing for the lane and is not the lane's join: point args.dir at the lane's own workflow directory`)
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
    const rows = [...totals.values()].sort(cmp).flatMap(({ key, sums, tool_uses, files, observation }) =>
        mode === 'seats'
            ? [...UNITS.map((unit) => ({ proposal: key[0], voter: key[1], unit, quantity: sums[unit] })),
               { proposal: key[0], voter: key[1], unit: 'tool_uses', quantity: tool_uses }]
            : UNITS.map((unit, i) => ({
                step: key,
                unit,
                quantity: sums[unit],
                ...(i === 0 && files === 1 && servedMetadata(observation)
                    ? { metadata: servedMetadata(observation) } : {}),
            })),
    )
    return { rows, overhead, skipped, errors, model_observations }
}
// TEST-END docket-workflow-usage-classify

// TEST-BEGIN docket-workflow-usage-paths — extracted and exercised by
// tests/docket-workflow-usage-probe-overhead.test.sh. Keep it free of workflow globals.
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

// The scout's listing command for one directory. It prints the transcripts in
// C-locale order and then find's own exit status on a `files_exit=` line. A
// `find | sort; echo $?` pipeline reports sort's status, which is 0 when find
// failed on a missing or unreadable directory, and ${PIPESTATUS[0]} is
// bash-only (empty under zsh). Capturing find's output first works in any
// POSIX shell or zsh: `$?` after `var=$(cmd)` is cmd's status.
const listCommand = (dir) =>
    `listing=$(find ${shellPath(dir)} -maxdepth 1 -type f -name 'agent-*.jsonl'); list_exit=$?; ` +
    `printf '%s' "$listing" | LC_ALL=C sort; echo "files_exit=$list_exit"; ` +
    `echo "files_count=$(printf '%s\\n' "$listing" | grep -c .)"`

// The scout's reply, refused unless find exited 0. A failed or partial listing
// would otherwise reach the Extract phase as a short directory, or as an empty
// one only the no-transcripts check catches. Returns the listing unchanged.
function checkListing(mode, listing) {
    if (listing?.files_exit !== 0) {
        throw new Error(`docket-workflow-usage: the ${mode}-mode transcript listing exited ${listing?.files_exit}, not 0 — ` +
            'it may be short, so no transcript is measured from it')
    }
    return listing
}

// The scout's relay of find's paths, compared with the counts the command
// printed beside them. The scout copies paths through a model, and a relay
// that drops one passes every other check: the Extract phase then measures a
// short directory and reports nothing for the dropped transcript. Returns ''
// when each relayed list, rebuilt on `dir` as the Extract phase sees it
// (agent-*.jsonl paths only, deduplicated), is as long as its printed count,
// else the message naming both counts. Seats mode checks the seat list the
// same way.
function listingCountMismatch(mode, dir, listing) {
    const checks = mode === 'seats'
        ? [['files', 'files_count'], ['seats', 'seats_count']]
        : [['files', 'files_count']]
    for (const [list, count] of checks) {
        const got = Array.isArray(listing?.[list])
            ? rebuildListing(dir, listing[list].filter((f) => AGENT_LOG_RE.test(f))).files.length
            : undefined
        if (got !== listing?.[count]) {
            return `docket-workflow-usage: the ${mode}-mode scout relayed ${got} ${list} path(s) but the command printed ${count}=${listing?.[count]}`
        }
    }
    return ''
}

// The scout's listing, checked for find's status and for completeness. A relay
// short of the printed count runs the scout once more; a second short relay
// throws naming both counts, never a reduced listing. `run(label)` runs one
// scout and `note(text)` logs.
async function scoutedListing(mode, dir, run, note) {
    let listing = checkListing(mode, await run('scout'))
    let mismatch = listingCountMismatch(mode, dir, listing)
    if (!mismatch) return listing
    note(`${mismatch}; running the scout once more`)
    listing = checkListing(mode, await run('scout-retry'))
    mismatch = listingCountMismatch(mode, dir, listing)
    if (mismatch) throw new Error(`${mismatch} again on the second run — no transcript is measured from a short listing`)
    return listing
}

const AGENT_LOG_RE = /\/agent-[^/]*\.jsonl$/

// The transcripts the Extract phase spawns an agent for. Steps mode measures
// every listed transcript, whatever else the scout returned. Seats mode
// measures only the ones SELECT_JQ selected, and refuses a reply that cannot
// show the selection ran clean: seats_exit is the status of the one jq call
// over every transcript, so a jq failure on any transcript, a glob that
// matched nothing or an unreadable file throws here instead of arriving as
// missing seats. A clean selection that names nothing is a directory with no judge, where
// reduceRows over every transcript also gives no rows. Selected paths are
// rebuilt on args.dir like the listing and kept only if listed; `unlisted`
// counts the rest.
function filesToExtract(mode, dir, transcripts, listing) {
    if (mode !== 'seats') return { files: transcripts, unlisted: 0 }
    if (!Array.isArray(listing?.seats)) {
        throw new Error('docket-workflow-usage: the seats-mode scout returned no seats listing — cannot tell judges from other agents')
    }
    if (listing.seats_exit !== 0) {
        throw new Error(`docket-workflow-usage: the seats selection exited ${listing.seats_exit}, not 0 — ` +
            'its seat list may be short, so no seat is measured from it')
    }
    const selected = new Set(rebuildListing(dir, listing.seats.filter((f) => AGENT_LOG_RE.test(f))).files)
    const files = transcripts.filter((f) => selected.has(f))
    return { files, unlisted: selected.size - files.length }
}
// TEST-END docket-workflow-usage-paths

const FILES_SCHEMA = {
    type: 'object',
    required: mode === 'seats'
        ? ['files', 'files_exit', 'files_count', 'seats', 'seats_exit', 'seats_count']
        : ['files', 'files_exit', 'files_count'],
    properties: {
        files: { type: 'array', items: { type: 'string' } },
        files_exit: { type: 'integer' },
        files_count: { type: 'integer' },
        seats: { type: 'array', items: { type: 'string' } },
        seats_exit: { type: 'integer' },
        seats_count: { type: 'integer' },
    },
}

const EXTRACT_SCHEMA = {
    type: 'object',
    required: ['ok', 'last_model', 'efforts_observed'],
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
        usage_join: { type: 'boolean' },
        step_mention: { type: ['string', 'null'] },
        reseat: { type: 'boolean' },
        tool_uses: { type: 'integer' },
        models_observed: { type: 'array', items: { type: 'string' } },
        last_model: { type: ['string', 'null'] },
        efforts_observed: { type: 'array', items: { type: 'string' } },
        model_observation_complete: { type: 'boolean' },
        usage: {
            type: 'object',
            required: UNITS,
            properties: Object.fromEntries(UNITS.map((u) => [u, { type: 'integer' }])),
        },
    },
}

// TEST-BEGIN docket-workflow-usage-scout — extracted by
// tests/docket-workflow-usage-probe-overhead.test.sh, which sets `dir` and `mode`, renders
// the seats-mode brief and runs its fenced command block over fixture
// transcripts.
//
// The seats selection hands SELECT_JQ to jq as one single-quoted argument and
// the transcripts as a glob, so the block writes no program file and runs no
// `find -exec` or `xargs` (both refused by the settings deny list). A scout
// that splits the block across Bash calls loses nothing: each command stands
// alone.
const LIST_COMMAND = listCommand(dir)
const scoutBrief = mode === 'seats'
    ? `You are a read-only scout. Do not cd anywhere. Run these commands verbatim, sandboxed, and report what they print — never a paraphrase. The first lists the transcripts; the last runs a jq program, passed whole as one single-quoted argument so nothing in it is expanded, and prints only the transcripts whose brief casts a vote:

\`\`\`
${LIST_COMMAND}
echo '--- seats ---'
seats=$(jq -r -n -R ${sq(SELECT_JQ)} ${shellPath(dir)}/agent-*.jsonl); seats_exit=$?; [ -z "$seats" ] || printf '%s\\n' "$seats"; echo "seats_exit=$seats_exit"; echo "seats_count=$(printf '%s\\n' "$seats" | grep -c .)"
\`\`\`

The directory is written with one \`*\` where the flattened project name sits; leave that glob exactly as it is and let the shell resolve it. Return {files: [...], files_exit: N, files_count: N, seats: [...], seats_exit: N, seats_count: N}: \`files\` is every path printed before the \`files_exit=\` line, \`files_exit\` and \`files_count\` are the numbers printed on the \`files_exit=\` and \`files_count=\` lines, \`seats\` every path printed after the \`--- seats ---\` line, one entry per line, verbatim and in order — a hyphen where a dot might be expected (\`github-com\`) is correct, not a typo — and \`seats_exit\` and \`seats_count\` are the numbers printed on the \`seats_exit=\` and \`seats_count=\` lines. Copy each count exactly as printed, even if it differs from the number of paths you return. An empty listing is an empty array. Do not open, read, or count the files by any other means.`
    : `You are a read-only scout. Do not cd anywhere. Run this command verbatim, sandboxed, and report what it prints — never a paraphrase:

\`\`\`
${LIST_COMMAND}
\`\`\`

The directory is written with one \`*\` where the flattened project name sits; leave that glob exactly as it is and let the shell resolve it. Return {files: [...], files_exit: N, files_count: N}: \`files\` is every path printed before the \`files_exit=\` line, one entry per line, verbatim and in that order — a hyphen where a dot might be expected (\`github-com\`) is correct, not a typo — and \`files_exit\` and \`files_count\` are the numbers printed on the \`files_exit=\` and \`files_count=\` lines. Copy the count exactly as printed, even if it differs from the number of paths you return. An empty listing is an empty \`files\` array. Do not open, read, or count the files.`
// TEST-END docket-workflow-usage-scout

const extractBrief = (file, retry) => `You are a read-only measurement relay for one transcript file. Do not cd anywhere. Run these commands verbatim, sandboxed. The first writes a jq program with a quoted heredoc so nothing in it is expanded; the second runs it:

\`\`\`
cat > "\${TMPDIR:-/tmp}/docket-workflow-usage-$$.jq" <<'JQ'
${EXTRACT_JQ}JQ
jq -c -n -R -f "\${TMPDIR:-/tmp}/docket-workflow-usage-$$.jq" ${shellPath(file)}; echo "exit=$?"
\`\`\`

The transcript path is exact and must be copied character for character, including the one \`*\` that stands in for the flattened project name (the shell resolves it; do not replace it). A hyphen where a dot might be expected (\`github-com\`) is correct and is not a typo; do not "correct" any part of the path.
${retry === 'path' ? '\nThis is a SECOND run: the first run reported that jq could not open the file, which means the path was retyped incorrectly. Copy the path from the command above byte for byte.\n' : retry ? '\nThis is a SECOND, independent run of the same command against the same file — a prior run reported bootstrap:false and is being re-checked. Run the command fresh; do not reuse or assume any earlier result.\n' : ''}
jq prints exactly one JSON object. Return it as the structured output with ok:true and every field copied verbatim — bootstrap, cast, record, probe, exec, claim_agent, usage_join, step_mention, reseat, tool_uses, models_observed, last_model, efforts_observed, model_observation_complete, usage — including every number exactly as printed. Do not compute, estimate, round, or adjust anything, and do not read the transcript by any other means. Model and effort names come only from the extracted fields; missing observations remain empty, and a null last_model stays null. If jq exits non-zero or prints nothing, return ok:false with the error text in \`error\`.`

phase('Scout')
const listing = await scoutedListing(mode, dir,
    (label) => agent(scoutBrief, { label, phase: 'Scout', schema: FILES_SCHEMA, ...AGENT_CONFIG.scout }), log)
const rawFiles = [...new Set(listing?.files || [])]
const listed = rawFiles.filter((f) => AGENT_LOG_RE.test(f))
if (listed.length !== rawFiles.length) {
    const dropped = rawFiles.filter((f) => !AGENT_LOG_RE.test(f))
    log(`docket-workflow-usage: scout listed ${rawFiles.length} path(s), ${dropped.length} not matching agent-*.jsonl and dropped: ${dropped.join(', ')}`)
}
const { files: transcripts, retyped: retypedByScout } = rebuildListing(dir, listed)
if (retypedByScout) {
    log(`docket-workflow-usage: scout returned ${retypedByScout} path(s) outside args.dir (the relay retyped the directory); rebuilt each from args.dir and the listed basename`)
}
log(`docket-workflow-usage: ${transcripts.length} agent transcript(s) under ${dir} (${mode} mode)`)
if (transcripts.length === 0) {
    throw new Error(`docket-workflow-usage: no agent-*.jsonl under ${dir} — nothing to measure, which is a finding, not an empty batch`)
}
const { files, unlisted } = filesToExtract(mode, dir, transcripts, listing)
if (mode === 'seats') {
    if (unlisted) log(`docket-workflow-usage: scout selected ${unlisted} path(s) its own listing lacks; dropped`)
    log(`docket-workflow-usage: ${files.length} transcript(s) brief a vote cast; the other ${transcripts.length - files.length} are not extracted` +
        (files.length === 0 ? ' — the selection ran clean and found no judge, so no seat row follows' : ''))
}

// TEST-BEGIN docket-workflow-usage-recheck-pipeline — extracted and exercised by
// tests/docket-workflow-usage-recheck-pipeline.test.sh; EXTRACT_SCHEMA requires only
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
// retried — docket-workflow-usage only rechecks a confirmed-good extract that merely
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
    log(`docket-workflow-usage: ${basename(path)}: ${what} agent error: ${err}`)
    return null
})
function classifyFirstAttempt(r, file, i) {
    if (!r) {
        log(`docket-workflow-usage: ${file}: extraction agent returned nothing`)
        errors.push(`${file}: extraction agent returned nothing`)
        return null
    }
    if (!r.extract || !r.extract.ok) {
        const why = (r.extract && r.extract.error) || 'no error text'
        if (PATH_MISS_RE.test(why)) {
            log(`docket-workflow-usage: ${file}: jq could not open the file (${why}) — the relay likely retyped the path; retrying once with a fresh agent`)
            return { file, path: files[i], pathMiss: why }
        }
        log(`docket-workflow-usage: ${file}: jq failed — ${why}`)
        errors.push(`${file}: jq failed — ${why}`)
        return null
    }
    if (!hasUsage(r.extract)) {
        log(`docket-workflow-usage: ${file}: extract reported ok but carried no usage`)
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
            log(`docket-workflow-usage: ${prev.file}: path retry also failed — ${why}`)
            errors.push(`${prev.file}: jq failed — ${prev.pathMiss} (path retry: ${why})`)
            return null
        }
        if (!hasUsage(second)) {
            errors.push(`${prev.file}: path retry reported ok but carried no usage`)
            return null
        }
        log(`docket-workflow-usage: ${prev.file}: path retry succeeded`)
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
    log(`docket-workflow-usage: ${prev.file}: reported bootstrap:false — re-checking before trusting it`)
    return extractOnce(prev.path, true, `${prev.file} · extract (retry)`, AGENT_CONFIG.recheck, 'recheck').then((second) => {
        if (second && second.ok && second.bootstrap === false) {
            log(`docket-workflow-usage: ${prev.file}: bootstrap:false confirmed on a second, independent read — treating as a misreport and recording as overhead, not an error`)
            return { ...prev, extract: { ...prev.extract, bootstrapFallback: true } }
        }
        if (second && second.ok && hasUsage(second)) {
            log(`docket-workflow-usage: ${prev.file}: bootstrap:false did not repeat on retry — using the retry's answer`)
            return { ...prev, extract: second }
        }
        if (second && second.ok) {
            log(`docket-workflow-usage: ${prev.file}: retry reported ok but carried no usage — reporting the original error rather than a reply reduceRows cannot use`)
        } else {
            log(`docket-workflow-usage: ${prev.file}: retry could not confirm or refute the first answer — reporting the original error`)
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
// TEST-END docket-workflow-usage-recheck-pipeline
if (pathRetried) log(`docket-workflow-usage: ${pathRetried} transcript(s) had their path retyped by the relay and were retried once`)
if (bootstrapRechecked) log(`docket-workflow-usage: ${bootstrapRechecked} transcript(s) reported bootstrap:false and were rechecked`)
const summary = reduceRows(results, mode, exclude)
const reduced = { ...summary, errors: [...errors, ...summary.errors] }

for (const observation of reduced.model_observations) {
    log(`docket-workflow-usage: ${observation.file}: serving models ` +
        `${observation.models.join(', ') || 'unknown'} ` +
        `(${observation.complete ? 'all parsed response model fields present' : 'model fields missing'}); ` +
        `last ${observation.last_model || 'unknown'}, effort ${observation.effort_resolved}`)
}

for (const s of reduced.skipped) {
    if (s.reason === 'unattributed') {
        log(`docket-workflow-usage: ${s.file}: no seat (never cast) — dropped here; steps mode carries it if it recorded a step, and reports it as wave overhead if it did not`)
    } else if (s.reason === 'seated') {
        log(`docket-workflow-usage: ${s.label}: cast a ballot — skipped here, carried by seats mode`)
    } else if (s.reason === 'dead-spawn') {
        log(`docket-workflow-usage: ${s.file} (${s.label}): dead spawn — no usage, and another transcript carries this ${mode === 'seats' ? 'seat' : 'step'}; skipped, not thrown`)
    } else {
        log(`docket-workflow-usage: ${s.file} (${s.label}): excluded — a prior back-fill already carries this ${mode === 'seats' ? 'seat' : 'step'}`)
    }
}
for (const o of reduced.overhead.agents) {
    log(`docket-workflow-usage: ${o.file}: ${o.label} — recorded no step, so its usage is wave overhead and is attributed to none`)
}
if (reduced.overhead.agents.length) {
    const sums = UNITS.map((u) => `${u} ${reduced.overhead.sums[u]}`).join(', ')
    log(`docket-workflow-usage: WAVE OVERHEAD: ${reduced.overhead.agents.length} agent(s), ${sums} — no step owns this spend; it is reported, not back-filled`)
}
const keyOf = (r) => (mode === 'seats' ? `${r.proposal} ${r.voter}` : r.step)
log(`docket-workflow-usage: ${reduced.rows.length} row(s) over ${new Set(reduced.rows.map(keyOf)).size} key(s)` +
    (mode === 'seats' ? ' (four token units and tool_uses per seat)' : ''))
if (reduced.errors.length) {
    for (const e of reduced.errors) log(`docket-workflow-usage: ${e}`)
    throw new Error(`docket-workflow-usage: ${reduced.errors.length} error(s) — ${reduced.errors.join('; ')}`)
}

return reduced
