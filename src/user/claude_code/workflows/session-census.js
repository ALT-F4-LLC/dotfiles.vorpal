export const meta = {
    name: 'session-census',
    description: 'Measure deliberation and course-correction cost across Claude Code transcripts: think tokens vs output tokens, thinking chars vs visible text chars, operator inputs, interrupts, killed agents, and idle-notification narration — MAIN and SUBAGENT measured separately and never pooled. Read-only. Invoke by scriptPath ONLY, with args {root, cutoff, days}.',
    whenToUse: 'Invoked by the shadow skill (fleet sweep or single session) to put numbers under "everything is over-thought". Run before a harness change and after, and diff the two returns. Cost: one low-effort agent per transcript newer than the cutoff; a 7-day fleet window is hundreds of files, so the conductor picks the window.',
    phases: [
        { title: 'Scout', detail: 'one agent finds the transcripts newer than the cutoff' },
        { title: 'Extract', detail: 'one low-effort agent per transcript runs the fixed jq' },
    ],
}

// ---------------------------------------------------------------------------
// Why these rules exist (each one was learned by getting the census wrong):
//
// * MAIN vs SUBAGENT are never pooled. Subagents take model and effort from
//   docket policy.toml, so they cannot measure a change to the global harness
//   dial; pooling hides the signal the census exists to find.
// * usage.output_tokens_details.thinking_tokens is not always present.
//   Clients before 2.1.228 never wrote it, and current clients omit it on a
//   sizeable minority of messages. Absent is NOT zero: such a message may
//   still carry thinking blocks, and counting it as zero biases think% low.
//   Those messages are excluded from token metrics and their count is
//   returned. A direct measurement found the excluded set split about evenly
//   between messages with and without thinking blocks (3014 vs 2965), so the
//   exclusion is close to unbiased; when the two disagree, trust
//   think_text_ratio, which every message can contribute to.
// * Most user-role rows are not the operator: task notifications, teammate
//   messages, tool results, and isMeta skill-body injections all arrive as
//   role=user. Only typed prose, slash commands, and !bash count as input.
// * Character counts (thinking chars vs visible text chars) work on every
//   client version and are the version-independent cross-check on think%.
// * Idle-notification narration is measured structurally, with no wording
//   heuristic: a teammate idle ping is a role=user row whose body carries
//   {"type":"idle_notification"}, and the turn answering it is text-only
//   exactly when it emits visible text and zero tool_use blocks. Any
//   user-role row closes the previous turn, tool_result rows included, which
//   is precisely what makes the next user-role row the correct boundary.
//   Silence is the intended response, so lower is better on that row like
//   every other row here.
//
// args: {root, cutoff, days}
//   root   — absolute path of the projects directory (literal, no `~`).
//   cutoff — ISO-8601 UTC timestamp ending in Z (2026-09-01T00:00:00Z); only
//            transcripts modified after it are counted. Computed by the
//            conductor: a script cannot call Date.
//   days   — the window length the cutoff represents, for labelling only.
//
// return: {window:{days, cutoff}, files:{main, subagent}, main:{...}, subagent:{...}}
//   Both kind objects carry msgs, out_tokens, think_tokens, think_pct,
//   think_msgs, think_msgs_pct, think_chars, text_chars, think_text_ratio,
//   tool_uses, sessions, excluded_no_thinking_accounting, notes. main adds
//   operator_inputs, interrupts, interrupt_pct, agents_killed, kill_events,
//   idle, time, context, by_model_effort, matched_cells; subagent adds by_role.
// ---------------------------------------------------------------------------

// TEST-BEGIN session-census-extract — evaluable on its own; run the string as
// `jq -c -n -R --arg kind main|subagent -f <file> <transcript>`.
// -R + fromjson so one malformed line is skipped, not fatal.
const CENSUS_JQ = String.raw`
# Versions that predate thinking_tokens accounting: token-based think% is not
# computable for them, character-based metrics still are.
def no_think_accounting: . == "2.1.219" or . == "2.1.227";

def strip: sub("^\\s+"; "") | sub("\\s+$"; "");

def user_text:
  .message.content as $c
  | if ($c | type) == "string" then $c
    elif ($c | type) == "array"
      then ([$c[] | select(type == "object" and .type == "text") | (.text // "")] | join(" "))
    else "" end;

# Subagent transcripts carry no role field, so the role is read off the opening
# line of the brief. First match wins; tribunal is checked before the generic
# judge/review pattern because a seat brief contains review vocabulary too. A
# large "other" bucket means these patterns drifted from the briefs.
def classify_role:
  if test("one seat of a tribunal"; "i") then "tribunal-seat"
  elif test("retro analyst|mining docket run evidence"; "i") then "retro-analyst"
  elif test("spec-author"; "i") then "spec-author"
  elif test("executing one step|docket engine pipeline"; "i") then "executor-step"
  elif test("judge|review agent|refute|adversar|critic"; "i") then "judge/review"
  elif test("implement|author the|apply the fix|make the change"; "i") then "implement/write"
  elif test("read-only|survey|mine |inventory|scan |locate "; "i") then "read/survey"
  else "other" end;

def sys_prefixes:
  ["<task-notification>", "Another Claude session sent", "[Request interrupted",
   "<local-command", "Caveat:", "<system-reminder>", "<user-prompt-submit-hook>"];

# operator | interrupt | kill:<n> | null (machine noise)
def classify_user($meta):
  (. // "" | strip) as $t
  | if $t == "" then null
    elif ($t | contains("[Request interrupted")) then "interrupt"
    elif ($t | test("^[0-9]+ background agents were stopped by the user"))
      then "kill:" + ($t | capture("^(?<n>[0-9]+) background agents").n)
    elif ($t | startswith("Background agent ") and contains("stopped by the user")) then "kill:1"
    elif any(sys_prefixes[]; . as $p | $t | startswith($p)) then null
    elif $meta then null
    else "operator" end;

# Matched on the JSON key, not the "Another Claude session sent" envelope: that
# envelope also carries real reports, the ones a reply IS the right answer to.
def is_idle_ping: test("\"type\"\\s*:\\s*\"idle_notification\"");

# A turn that called a tool is closed by that tool's own result row and can
# never be miscounted as text-only.
def close_idle:
  if .idle_open then
    (if .idle_tools > 0 then .idle_worked += 1
     elif .idle_texts > 0 then .idle_textonly += 1
     else . end)
    | .idle_open = false
  else . end;

def stamp($rec):
  ($rec.timestamp // null) as $ts
  | if ($ts | type) == "string" and ($ts | length) >= 19
    then (try (($ts[0:19] + "Z") | fromdateiso8601) catch null)
    else null end;

def user_row($rec):
  if $kind == "subagent" then
    if .role == null then
      ($rec | user_text | strip) as $text
      | if $text != "" then .role = ($text[0:300] | classify_role) else . end
    else . end
  else
    ($rec | user_text) as $text
    | close_idle
    | (if ($text | is_idle_ping)
       then .idle_notifs += 1 | .idle_open = true | .idle_tools = 0 | .idle_texts = 0
       else . end)
    | ($text | classify_user($rec.isMeta == true)) as $c
    | if $c == "operator" then .operator += 1
      elif $c == "interrupt" then .interrupts += 1
      elif ($c != null and ($c | startswith("kill:")))
        then .kills += ($c | ltrimstr("kill:") | tonumber) | .kill_events += 1
      else . end
  end;

def assistant_row($rec):
  ($rec.message // {}) as $msg
  | ($msg.usage // {}) as $usage
  | ($usage.output_tokens // 0) as $out
  | (($usage.output_tokens_details // {}).thinking_tokens) as $think
  | ($rec.version // "?") as $version
  | ($rec.effort // null) as $effort
  | ($msg.model // null) as $model
  | ($rec.attributionSkill // "-") as $skill
  | ($msg.content | if type == "array" then map(select(type == "object")) else [] end) as $blocks
  | ([$blocks[] | select(.type == "thinking") | ((.thinking // .text // "") | length)] | add // 0) as $tc
  | ([$blocks[] | select(.type == "text") | ((.text // "") | length)] | add // 0) as $txc
  | ([$blocks[] | select(.type == "text") | select(((.text // "") | strip) != "")] | length > 0) as $visible
  | ([$blocks[] | select(.type == "tool_use")] | length) as $tu
  | (($version | no_think_accounting | not) and $think != null) as $usable
  | .msgs += 1
  | .think_chars += $tc
  | .text_chars += $txc
  | .tool_uses += $tu
  | .versions[$version] += 1
  | (if $kind == "main" then
       (.ctx_last = (($usage.input_tokens // 0) + ($usage.cache_creation_input_tokens // 0) + ($usage.cache_read_input_tokens // 0)))
       | (if .ctx_first == null then .ctx_first = .ctx_last else . end)
       | (if .ctx_peak == null or .ctx_last > .ctx_peak then .ctx_peak = .ctx_last else . end)
     else . end)
  | (if .idle_open then .idle_tools += $tu | (if $visible then .idle_texts += 1 else . end) else . end)
  | (if ($effort // "") != "" then .efforts[$effort] += 1 else . end)
  | if $usable then
      .out += $out
      | .think += $think
      | (if $think > 0 then .think_msgs += 1 else . end)
      | (if $kind == "main" and ($model // "") != "" and ($effort // "") != "" then
           (($model + "|" + $effort + "|" + $skill) as $key
            | .cells[$key] |= ((. // {model: $model, effort: $effort, skill: $skill, msgs: 0, out: 0, think: 0, think_msgs: 0, think_chars: 0, text_chars: 0})
                | .msgs += 1 | .out += $out | .think += $think | .think_chars += $tc | .text_chars += $txc
                | (if $think > 0 then .think_msgs += 1 else . end)))
         else . end)
    else .excluded[$version] += 1 end;

def step($rec):
  if ($rec | type) != "object" then .
  else
    (stamp($rec)) as $t
    | (if $t != null then .stamps += [$t] else . end)
    | .rows[($rec.type // "?")] += 1
    | if $rec.type == "user" then user_row($rec)
      elif $rec.type != "assistant" then .
      # Subagent transcripts flag every row isSidechain=true and that is normal
      # there; inside a MAIN file such a row duplicates subagent work.
      elif $kind == "main" and $rec.isSidechain == true then .sidechain_dropped += 1
      else assistant_row($rec) end
  end;

reduce (inputs | try fromjson catch null) as $rec (
  {kind: $kind, role: null, rows: {}, versions: {}, excluded: {},
   msgs: 0, out: 0, think: 0, think_msgs: 0, think_chars: 0, text_chars: 0, tool_uses: 0,
   sidechain_dropped: 0, efforts: {}, cells: {},
   operator: 0, interrupts: 0, kills: 0, kill_events: 0,
   idle_notifs: 0, idle_textonly: 0, idle_worked: 0, idle_open: false, idle_tools: 0, idle_texts: 0,
   ctx_first: null, ctx_peak: null, ctx_last: null, stamps: []};
  step($rec)
)
# A ping answered in the session's LAST turn has no following user-role row to
# close it; without this the final turn of every such session goes uncounted.
| close_idle
| (.stamps | sort) as $s
| .span_seconds = (if ($s | length) > 1 then $s[-1] - $s[0] else 0 end)
| .active_seconds = (if ($s | length) > 1
    then ([range(1; $s | length) | ($s[.] - $s[. - 1]) | select(. <= 300)] | add // 0)
    else 0 end)
| .first_ts = (if ($s | length) > 0 then ($s[0] | todateiso8601) else null end)
| .last_ts = (if ($s | length) > 0 then ($s[-1] | todateiso8601) else null end)
| .version = (.versions | to_entries | sort_by(-.value) | .[0].key // "?")
| .cells = [.cells[]]
| del(.stamps, .idle_open, .idle_tools, .idle_texts, .ctx_last)
`
// TEST-END session-census-extract

// TEST-BEGIN session-census-aggregate — pure; pools MAIN and SUBAGENT
// separately and derives the ratios the census reports. Free of workflow
// globals so it is evaluable against fixture rows on its own.
const NOTES = {
    both: [
        'main and subagent are measured separately and never pooled',
        'think_pct and think_msgs_pct exclude messages with no thinking_tokens field: absent is not zero (excluded_no_thinking_accounting counts them)',
        'think_text_ratio is computable on every message; trust it over think_pct when they disagree',
        'lower is better on every ratio; counts scale with how much work was done, so read rates, not totals',
    ],
    main: [
        'by_model_effort rows are the only ones that measure the global harness dial',
        'matched_cells hold the same model and skill at more than one effort (n >= 25 msgs): read the direction, not the magnitude',
        'idle.text_only is the narration cost; idle.tool_call is a ping that turned out to need work',
    ],
}

const EFFORT_RANK = {low: 0, medium: 1, high: 2, xhigh: 3, max: 4}

// A subagent transcript lives at <project>/<parent-session>/subagents/...; it
// is attributed to the parent session so sessions count conversations.
function sessionOf(path) {
    const parts = path.split('/')
    const i = parts.indexOf('subagents')
    const base = i > 0 ? parts[i - 1] : parts[parts.length - 1]
    return base.slice(0, 8)
}

function addCounts(into, r) {
    into.msgs += r.msgs
    into.out += r.out
    into.think += r.think
    into.think_msgs += r.think_msgs
    into.think_chars += r.think_chars
    into.text_chars += r.text_chars
    into.tool_uses += r.tool_uses || 0
}

function blank() {
    return {msgs: 0, out: 0, think: 0, think_msgs: 0, think_chars: 0, text_chars: 0, tool_uses: 0, sessions: new Set()}
}

function round(x, places) {
    const f = Math.pow(10, places)
    return Math.round(x * f) / f
}

function pct(seg) { return seg.out ? round(seg.think / seg.out * 100, 2) : 0 }
function ratio(seg) { return seg.text_chars ? round(seg.think_chars / seg.text_chars, 3) : 0 }

function percentile(vals, q) {
    if (!vals.length) return 0
    const s = [...vals].sort((a, b) => a - b)
    return s[Math.min(Math.floor(s.length * q), s.length - 1)]
}

function summary(seg) {
    return {
        sessions: seg.sessions.size,
        msgs: seg.msgs,
        out_tokens: seg.out,
        think_tokens: seg.think,
        think_pct: pct(seg),
        think_msgs: seg.think_msgs,
        think_msgs_pct: seg.msgs ? Math.floor(seg.think_msgs * 100 / seg.msgs) : 0,
        think_chars: seg.think_chars,
        text_chars: seg.text_chars,
        think_text_ratio: ratio(seg),
        tool_uses: seg.tool_uses,
    }
}

function aggregate(results) {
    const kinds = {main: blank(), subagent: blank()}
    const excluded = {main: {}, subagent: {}}
    const cells = {}
    const roles = {}
    const roleEfforts = {}
    let operator = 0, interrupts = 0, kills = 0, killEvents = 0
    let idleNotifs = 0, idleTextonly = 0, idleWorked = 0
    let active = 0, span = 0
    let sidechainDropped = 0
    const firstCtx = [], peakCtx = []

    for (const r of results) {
        const seg = kinds[r.kind]
        const sid = sessionOf(r.path)
        addCounts(seg, r)
        seg.sessions.add(sid)
        for (const [v, n] of Object.entries(r.excluded || {})) {
            excluded[r.kind][v] = (excluded[r.kind][v] || 0) + n
        }
        if (r.kind === 'subagent') {
            const role = r.role || 'other'
            roles[role] = roles[role] || blank()
            addCounts(roles[role], r)
            roles[role].sessions.add(sid)
            roleEfforts[role] = roleEfforts[role] || {}
            for (const [e, n] of Object.entries(r.efforts || {})) {
                roleEfforts[role][e] = (roleEfforts[role][e] || 0) + n
            }
            continue
        }
        sidechainDropped += r.sidechain_dropped || 0
        operator += r.operator
        interrupts += r.interrupts
        kills += r.kills
        killEvents += r.kill_events
        idleNotifs += r.idle_notifs
        idleTextonly += r.idle_textonly
        idleWorked += r.idle_worked
        active += r.active_seconds || 0
        span += r.span_seconds || 0
        if (r.ctx_first != null) { firstCtx.push(r.ctx_first); peakCtx.push(r.ctx_peak) }
        for (const c of r.cells || []) {
            const key = `${c.model}|${c.effort}|${c.skill}`
            cells[key] = cells[key] || Object.assign(blank(), {model: c.model, effort: c.effort, skill: c.skill})
            addCounts(cells[key], c)
            cells[key].sessions.add(sid)
        }
    }

    const byModelEffort = {}
    for (const c of Object.values(cells)) {
        const key = `${c.model}|${c.effort}`
        byModelEffort[key] = byModelEffort[key] || Object.assign(blank(), {model: c.model, effort: c.effort})
        addCounts(byModelEffort[key], c)
        for (const s of c.sessions) byModelEffort[key].sessions.add(s)
    }
    const rank = (e) => EFFORT_RANK[e] == null ? 9 : EFFORT_RANK[e]
    const modelEffortRows = Object.values(byModelEffort)
        .sort((a, b) => a.model.localeCompare(b.model) || rank(a.effort) - rank(b.effort))
        .map((c) => ({model: c.model, effort: c.effort, sessions: c.sessions.size, msgs: c.msgs, out_tokens: c.out, think_pct: pct(c), think_text_ratio: ratio(c)}))

    // Same model+skill at more than one effort: the only quasi-controlled
    // comparison observational data offers.
    const grouped = {}
    for (const c of Object.values(cells)) {
        if (c.msgs < 25) continue
        const key = `${c.model}|${c.skill}`
        grouped[key] = grouped[key] || {model: c.model, skill: c.skill, efforts: []}
        grouped[key].efforts.push({effort: c.effort, think_pct: pct(c), think_text_ratio: ratio(c), msgs: c.msgs, sessions: c.sessions.size})
    }
    const matchedCells = Object.values(grouped)
        .filter((g) => g.efforts.length > 1)
        .map((g) => ({model: g.model, skill: g.skill, efforts: g.efforts.sort((a, b) => rank(a.effort) - rank(b.effort))}))

    const byRole = {}
    for (const [name, c] of Object.entries(roles).sort((a, b) => b[1].out - a[1].out)) {
        byRole[name] = {msgs: c.msgs, out_tokens: c.out, think_pct: pct(c), think_text_ratio: ratio(c), efforts: roleEfforts[name]}
    }

    const sumExcluded = (m) => Object.values(m).reduce((a, b) => a + b, 0)
    const main = Object.assign(summary(kinds.main), {
        excluded_no_thinking_accounting: {total: sumExcluded(excluded.main), by_version: excluded.main},
        sidechain_rows_dropped: sidechainDropped,
        operator_inputs: operator,
        interrupts,
        interrupt_pct: operator ? Math.floor(interrupts * 100 / operator) : 0,
        agents_killed: kills,
        kill_events: killEvents,
        idle: {
            pings: idleNotifs,
            text_only: idleTextonly,
            text_only_pct: idleNotifs ? round(idleTextonly / idleNotifs * 100, 2) : 0,
            tool_call: idleWorked,
            silent: idleNotifs - idleTextonly - idleWorked,
        },
        time: {
            active_hours: round(active / 3600, 2),
            idle_share_pct: span ? Math.round((1 - active / span) * 100) : 0,
            active_min_per_input: operator ? round(active / 60 / operator, 1) : 0,
        },
        context: {
            first_p50: percentile(firstCtx, 0.5),
            first_p90: percentile(firstCtx, 0.9),
            peak_p50: percentile(peakCtx, 0.5),
            peak_max: peakCtx.length ? Math.max(...peakCtx) : 0,
        },
        by_model_effort: modelEffortRows,
        matched_cells: matchedCells,
        notes: NOTES.both.concat(NOTES.main),
    })
    const subagent = Object.assign(summary(kinds.subagent), {
        excluded_no_thinking_accounting: {total: sumExcluded(excluded.subagent), by_version: excluded.subagent},
        by_role: byRole,
        notes: NOTES.both,
    })
    return {main, subagent}
}
// TEST-END session-census-aggregate

// ---------------------------------------------------------------------------
// Transport + validation
// ---------------------------------------------------------------------------

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
if (typeof args === 'string') log('session-census: decoded args from the harness JSON-encoded transport (normal)')

for (const k of ['root', 'cutoff']) {
    if (typeof input[k] !== 'string' || input[k] === '') {
        throw new Error(`session-census: args.${k} is required and must be a non-empty string (got ${JSON.stringify(input[k])})`)
    }
}
if (input.root.startsWith('~')) throw new Error('session-census: args.root must be an absolute path; agents do not expand ~')
if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(input.cutoff)) {
    throw new Error(`session-census: args.cutoff must be an ISO-8601 UTC timestamp ending in Z (got ${JSON.stringify(input.cutoff)})`)
}
const {root, cutoff} = input
const days = input.days == null ? null : Number(input.days)

const SANDBOX_RULE = `Run it SANDBOXED — do NOT pass dangerouslyDisableSandbox. If the sandbox denies it, report the denial text instead of retrying with the sandbox disabled.`

// ---------------------------------------------------------------------------
// Scout
// ---------------------------------------------------------------------------

// A reference file instead of -newermt: BSD find rejects a Z-suffixed
// timestamp and reads a bare one as local time, while bfs (which the harness
// substitutes for find) reads it differently again. touch -d parses the Z
// form as UTC on both, and -newer is the same everywhere.
phase('Scout')
const scouted = await agent(
`List every Claude Code transcript under ${root} modified after ${cutoff}. Run exactly this, verbatim:

\`\`\`
touch -d '${cutoff}' "$TMPDIR/session-census.cutoff" && find '${root}' -name '*.jsonl' -newer "$TMPDIR/session-census.cutoff" -print; echo "exit=$?"
\`\`\`

${SANDBOX_RULE}

Return every path the command printed, one entry per path, none dropped or deduplicated. kind is "subagent" when the path contains a "/subagents/" segment, otherwise "main". If the command printed nothing, return an empty files array.`,
    {label: 'scout:transcripts', phase: 'Scout', effort: 'low', schema: {
        type: 'object',
        properties: {
            files: {type: 'array', items: {
                type: 'object',
                properties: {path: {type: 'string'}, kind: {type: 'string', enum: ['main', 'subagent']}},
                required: ['path', 'kind'],
            }},
        },
        required: ['files'],
    }},
)

if (!scouted) throw new Error('session-census: the scout agent returned nothing; no transcript list to census')
const files = scouted.files.map((f) => {
    const kind = f.path.includes('/subagents/') ? 'subagent' : 'main'
    if (kind !== f.kind) log(`session-census: scout labelled ${f.path} as ${f.kind}; path rule says ${kind} (path rule wins)`)
    return {path: f.path, kind}
})
if (files.length === 0) throw new Error(`session-census: no transcripts under ${root} newer than ${cutoff}; nothing to measure`)
const nMain = files.filter((f) => f.kind === 'main').length
log(`session-census: ${files.length} transcripts newer than ${cutoff} (${nMain} main, ${files.length - nMain} subagent); one extract agent each`)

// ---------------------------------------------------------------------------
// Extract
// ---------------------------------------------------------------------------

const EXTRACT_SCHEMA = {
    type: 'object',
    properties: {
        kind: {type: 'string'},
        role: {type: ['string', 'null']},
        rows: {type: 'object'},
        versions: {type: 'object'},
        excluded: {type: 'object'},
        msgs: {type: 'integer'},
        out: {type: 'integer'},
        think: {type: 'integer'},
        think_msgs: {type: 'integer'},
        think_chars: {type: 'integer'},
        text_chars: {type: 'integer'},
        tool_uses: {type: 'integer'},
        sidechain_dropped: {type: 'integer'},
        efforts: {type: 'object'},
        cells: {type: 'array'},
        operator: {type: 'integer'},
        interrupts: {type: 'integer'},
        kills: {type: 'integer'},
        kill_events: {type: 'integer'},
        idle_notifs: {type: 'integer'},
        idle_textonly: {type: 'integer'},
        idle_worked: {type: 'integer'},
        ctx_first: {type: ['integer', 'null']},
        ctx_peak: {type: ['integer', 'null']},
        span_seconds: {type: 'number'},
        active_seconds: {type: 'number'},
        first_ts: {type: ['string', 'null']},
        last_ts: {type: ['string', 'null']},
        version: {type: 'string'},
        error: {type: 'string'},
    },
    required: ['kind'],
}

const COUNT_FIELDS = ['msgs', 'out', 'think', 'think_msgs', 'think_chars', 'text_chars', 'tool_uses',
    'operator', 'interrupts', 'kills', 'kill_events', 'idle_notifs', 'idle_textonly', 'idle_worked']

function extractPrompt(f) {
    return `Extract per-transcript census counts from one Claude Code transcript with a fixed jq program. Write the program to a file with a QUOTED heredoc (the body must land byte-for-byte; do not edit it), then run it. Run exactly this, verbatim:

\`\`\`
cat > "$TMPDIR/session-census.jq" <<'CENSUS_JQ_EOF'
${CENSUS_JQ}
CENSUS_JQ_EOF
jq -c -n -R --arg kind '${f.kind}' -f "$TMPDIR/session-census.jq" '${f.path}'; echo "exit=$?"
\`\`\`

${SANDBOX_RULE}

Return the JSON object jq printed, field for field, unchanged: no rounding, no renaming, no interpretation. If jq printed an error instead, return the error text in a field named "error".`
}

phase('Extract')
const results = await pipeline(files,
    (f, _item, i) => agent(extractPrompt(f), {
        label: `extract:${f.kind}:${i + 1}/${files.length}`,
        phase: 'Extract',
        effort: 'low',
        schema: EXTRACT_SCHEMA,
    }),
    (r, f) => (r ? Object.assign(r, {path: f.path, kind: f.kind}) : null),
)

const usable = []
for (let i = 0; i < files.length; i++) {
    const r = results[i]
    if (!r) { log(`session-census: DROPPED ${files[i].path} (extract agent returned nothing)`); continue }
    if (r.error) { log(`session-census: DROPPED ${files[i].path} (jq: ${String(r.error).slice(0, 200)})`); continue }
    const missing = COUNT_FIELDS.filter((k) => typeof r[k] !== 'number')
    if (missing.length) { log(`session-census: DROPPED ${files[i].path} (extract returned no ${missing.join(', ')})`); continue }
    if (r.last_ts && r.last_ts < cutoff) log(`session-census: ${files[i].path} mtime is newer than the cutoff but its last row (${r.last_ts}) is not; counted anyway, as the original did`)
    usable.push(r)
}
log(`session-census: ${usable.length}/${files.length} transcripts extracted`)

const census = aggregate(usable)
const m = census.main, s = census.subagent
log(`session-census: MAIN ${m.sessions} sessions, ${m.msgs} msgs, think ${m.think_pct}%, think:text ${m.think_text_ratio}, ${m.excluded_no_thinking_accounting.total} msgs excluded from token metrics`)
log(`session-census: SUBAGENT ${s.sessions} sessions, ${s.msgs} msgs, think ${s.think_pct}%, think:text ${s.think_text_ratio}, ${s.excluded_no_thinking_accounting.total} msgs excluded from token metrics`)
log(`session-census: operator inputs ${m.operator_inputs}, interrupts ${m.interrupts} (${m.interrupt_pct}%), agents killed ${m.agents_killed} across ${m.kill_events} events`)
log(`session-census: idle pings ${m.idle.pings}, text-only ${m.idle.text_only} (${m.idle.text_only_pct}%, the cost), tool-call ${m.idle.tool_call}, silent ${m.idle.silent}`)

return {
    window: {days, cutoff},
    files: {
        main: usable.filter((r) => r.kind === 'main').length,
        subagent: usable.filter((r) => r.kind === 'subagent').length,
        dropped: files.length - usable.length,
    },
    main: m,
    subagent: s,
}
