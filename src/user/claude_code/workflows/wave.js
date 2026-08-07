export const meta = {
  name: 'wave',
  description: 'Spawn one executor per dispatched step row, routed by policy.toml. Invoke by scriptPath ONLY, with args {rows, policyText} as a real object — policy.toml is passed as TEXT, never a path; the script cannot read files.',
  whenToUse: 'Invoked by the conduct skill on an open dispatch, always as Workflow({scriptPath}) — never by name. args is {rows, policyText}: `next` rows verbatim plus the literal TEXT of policy.toml. There is no policyPath and no file access.',
  // phases are deliberately UNDECLARED — none, not just the read stages.
  // Each wave is a unique one-shot launch, and meta is a pure literal: a
  // static declaration cannot describe a unique wave. Declaring 'Writes
  // (serial)' here rendered a selectable "Not started yet" phantom box on
  // every read-only wave (observed 2026-08-06, waves 2 and 5, operator
  // screenshots) — the exact empty-declared-box failure this comment
  // previously documented for read stages, unapplied to the equally
  // conditional write stage. phase() calls auto-create their groups in true
  // execution order for every wave shape. Writers still always run first
  // when they exist — the await structure enforces that, not a declaration;
  // the write stage's one-at-a-time discipline is documented at the staging
  // block below.
}

// wave.js — the harness adapter (03 §1, §3). Static and versioned; never
// per-run generated (01 §4 A2). Inputs are `args = {rows, policyText}` handed
// in by the `run` skill: `next` rows verbatim (engine-spec §11.4) plus
// policy.toml as TEXT, because workflow scripts have no filesystem access.
// There is no policyPath parameter and never was (H-8).
//
// Rows are not spawned all at once: writers run serially, then readers run
// grouped per issue — see "Staging (H-11)" below.
//
// Every routing decision below is code. No model resolves, compares, or
// chooses a tier, model, effort, or executor anywhere in this path (AC-2.2b):
// routing values reach the bootstrap prompt as fixed strings only.

// --- TOML subset parser (§4.2, AC-2.7) --------------------------------------
// NOT a general TOML parser. It handles exactly the subset policy.toml uses:
//   tables [a] / [a.b], array-of-tables [[a]] / [[a.b]], inline tables,
//   quoted (basic) strings, integers, arrays of strings, and `#` comments
//   outside quotes.
// Anything else — multi-line strings, literal '' strings, floats, booleans,
// datetimes, nested arrays, dotted keys — FAILS LOUDLY. A silent mis-parse of
// a security pin is the failure mode this file exists to prevent.

const SUBSET = 'tables, array-of-tables, inline tables, quoted strings, integers, arrays of strings, # comments outside quotes'

function bail(line, n, why) {
  throw new Error(
    `wave.js policy parser: ${why} (line ${n}: ${JSON.stringify(line)}). ` +
    `This is NOT a general TOML parser — it accepts only: ${SUBSET}. ` +
    `Fix policy.toml or widen the parser deliberately; do not parse partially.`
  )
}

// Strip a trailing `#` comment, respecting double-quoted spans.
function decomment(s) {
  let q = false
  for (let i = 0; i < s.length; i++) {
    const c = s[i]
    if (c === '"' && s[i - 1] !== '\\') q = !q
    else if (c === '#' && !q) return s.slice(0, i)
  }
  return s
}

// Scalar: quoted string or integer. Everything else is out of subset.
function scalar(v, line, n) {
  v = v.trim()
  if (/^"(?:[^"\\]|\\.)*"$/.test(v)) return JSON.parse(v)
  if (/^-?\d+$/.test(v)) return parseInt(v, 10)
  if (/^'/.test(v)) bail(line, n, 'literal (single-quoted) strings are out of subset')
  if (/^(true|false)$/.test(v)) bail(line, n, 'booleans are out of subset')
  if (/^-?\d+\./.test(v)) bail(line, n, 'floats are out of subset')
  bail(line, n, `unsupported value ${JSON.stringify(v)}`)
}

// Array of strings (single-line only).
function arrayOfStrings(v, line, n) {
  const inner = v.trim().slice(1, -1).trim()
  if (inner === '') return []
  if (inner.includes('[')) bail(line, n, 'nested arrays are out of subset')
  return splitTop(inner).map((e) => {
    const s = scalar(e, line, n)
    if (typeof s !== 'string') bail(line, n, 'only arrays OF STRINGS are in subset')
    return s
  })
}

// Split on top-level commas (not inside quotes) — [security].reason is a
// comma-bearing sentence, so naive split() is wrong.
function splitTop(s) {
  const out = []
  let cur = '', q = false
  for (let i = 0; i < s.length; i++) {
    const c = s[i]
    if (c === '"' && s[i - 1] !== '\\') { q = !q; cur += c }
    else if (c === ',' && !q) { out.push(cur); cur = '' }
    else cur += c
  }
  if (cur.trim() !== '') out.push(cur)
  return out.map((e) => e.trim()).filter((e) => e !== '')
}

function inlineTable(v, line, n) {
  const obj = {}
  for (const pair of splitTop(v.trim().slice(1, -1))) {
    const eq = pair.indexOf('=')
    if (eq < 0) bail(line, n, 'inline-table entry without `=`')
    const k = pair.slice(0, eq).trim()
    const raw = pair.slice(eq + 1).trim()
    obj[k] = raw.startsWith('[') ? arrayOfStrings(raw, line, n) : scalar(raw, line, n)
  }
  return obj
}

function parseToml(text) {
  const root = {}
  let cur = root
  // Multi-line array accumulation: policy.toml's diamond_gates and the
  // spec-author fanout style both wrap.
  let pendingKey = null, pendingBuf = '', pendingLine = 0

  const lines = text.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const rawLine = lines[i]
    const n = i + 1
    let line = decomment(rawLine).trim()
    if (line === '') continue

    if (pendingKey !== null) {
      pendingBuf += ' ' + line
      if (!line.includes(']')) continue
      cur[pendingKey] = arrayOfStrings(pendingBuf, pendingBuf, pendingLine)
      pendingKey = null; pendingBuf = ''
      continue
    }

    // [[array.of.tables]]
    let m = line.match(/^\[\[([A-Za-z0-9_.-]+)\]\]$/)
    if (m) {
      const path = m[1].split('.')
      let node = root
      for (let j = 0; j < path.length - 1; j++) {
        const seg = path[j]
        if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
        else node = (node[seg] = node[seg] || {})
      }
      const leaf = path[path.length - 1]
      if (!Array.isArray(node[leaf])) node[leaf] = []
      const entry = {}
      node[leaf].push(entry)   // declared order preserved — §4.3 step 2 depends on it
      cur = entry
      continue
    }

    // [table] / [table.sub]
    m = line.match(/^\[([A-Za-z0-9_.-]+)\]$/)
    if (m) {
      const path = m[1].split('.')
      let node = root
      for (const seg of path) {
        if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
        else node = (node[seg] = node[seg] || {})
      }
      cur = node
      continue
    }

    if (line.startsWith('[')) bail(rawLine, n, 'malformed table header')

    const eq = line.indexOf('=')
    if (eq < 0) bail(rawLine, n, 'line is neither a table header nor a key/value pair')
    const key = line.slice(0, eq).trim()
    if (!/^[A-Za-z0-9_-]+$/.test(key)) bail(rawLine, n, `unsupported key ${JSON.stringify(key)} (dotted/quoted keys are out of subset)`)
    const val = line.slice(eq + 1).trim()

    if (val === '' ) bail(rawLine, n, 'empty value (multi-line strings are out of subset)')
    if (val.startsWith('"""') || val.startsWith("'''")) bail(rawLine, n, 'multi-line strings are out of subset')
    if (val.startsWith('{')) {
      if (!val.endsWith('}')) bail(rawLine, n, 'multi-line inline tables are out of subset')
      cur[key] = inlineTable(val, rawLine, n)
    } else if (val.startsWith('[')) {
      if (val.endsWith(']')) cur[key] = arrayOfStrings(val, rawLine, n)
      else { pendingKey = key; pendingBuf = val; pendingLine = n }   // wraps
    } else {
      cur[key] = scalar(val, rawLine, n)
    }
  }
  if (pendingKey !== null) bail('', pendingLine, 'unterminated array')
  return root
}

// --- Policy resolution (§4.3) -----------------------------------------------
// Deterministic code, per row. No prose, no judgment.

const INVESTIGATOR_CLASS = ['investigate', 'research', 'retro-analyst']

// Exact lookup only. §4.3 step 3 is `[executors][hint]` and 06 §11.1 types a
// `fanout` member as an executor hint verbatim — there is no suffix, prefix,
// or per-sibling-index resolution anywhere in the design. A hint with no row
// is a coverage-invariant failure and must be loud (AC-2.3).
function executorRow(policy, hint) {
  const row = (policy.executors || {})[hint]
  return row ? { key: hint, row } : null
}

function tierIndex(policy, tier) {
  return Object.keys(policy.tiers).indexOf(tier)
}

function diamondEligible(policy, hint, row, preAscentTier) {
  const gates = (policy.escalation && policy.escalation.diamond_gates) || []
  const labels = labelsOf(row)
  for (const g of gates) {
    if (g === 'investigator-class' && INVESTIGATOR_CLASS.includes(hint)) return true
    if (g === 'novel-architecture' && labels.includes('novel-architecture')) return true
    if (g === 'failed-gold-round' && row.attempt > 1 && preAscentTier === 'gold') return true
  }
  return false
}

// Labels ride on the ROW, not on a nested issue object: `next` renders `issue`
// as a bare id string ("DKT-2") and carries the issue's frozen labels in
// `row.labels` (engine-spec §11.4). Reading them off `row.issue` found
// `undefined` on every real row, so every label-keyed rule below — the resolve
// table, the security ceiling, the diamond gate — silently took its default
// branch. A doc:tdd issue routed to the PRD contract at a lower tier, and a
// security-labelled issue resolved exactly like an unlabelled one. Found
// 2026-08-06 by diffing a live `next` row against this function's assumption.
function labelsOf(row) {
  if (Array.isArray(row.labels)) return row.labels
  // Tolerated only because `step show` and hand-built row sets nest it.
  if (row.issue && Array.isArray(row.issue.labels)) return row.issue.labels
  return []
}

function resolve(row, policy) {
  const labels = labelsOf(row)

  // 0. Action rows are never spawned (P-13). Builtin action steps are run BY
  //    the engine (driveActionSteps) and never claimed by an agent, so an
  //    action row reaching the wave is a routing mistake upstream, not policy
  //    drift — the conduct skill filters to executor rows and this is the
  //    belt-and-braces. Diagnose it accurately: falling through to the
  //    coverage-invariant error below would blame policy.toml for a row that
  //    should never have been handed over at all.
  if (row.kind === 'action') {
    throw new Error(
      `wave.js: step ${row.step} is kind:"action" — action steps are engine-run; ` +
      `not a spawn. Route executor rows to the wave only. Refusing to route.`
    )
  }

  // 1. hint <- row.executor
  let hint = row.executor

  // 2. [[resolve]] — ordered rules, first match wins, else default.
  const table = (policy.resolve || []).find((e) => e.executor === hint)
  if (table) {
    let matched = null
    for (const rule of table.rule || []) {
      const labelsOk = !rule.labels || rule.labels.every((l) => labels.includes(l))
      const docOk = !rule.doc_type || labels.includes('doc:' + rule.doc_type)
      if (labelsOk && docOk) { matched = rule.to; break }
    }
    hint = matched || table.default
  }

  // 3. [executors][hint] — MUST exist (coverage invariant).
  const found = executorRow(policy, hint)
  if (!found) {
    throw new Error(
      `wave.js: executor hint ${JSON.stringify(hint)} has no [executors] row ` +
      `(step ${row.step}). Coverage invariant violated — policy.toml and the ` +
      `workflow corpus have drifted. Refusing to route.`
    )
  }
  const rowPolicy = found.row
  let tier = rowPolicy.tier
  let never = (rowPolicy.never || []).slice()

  // 4. Sensitivity — applied BEFORE escalation (policy.toml:133-134).
  const sec = policy.security || {}
  const sensitive =
    (sec.nodes || []).includes(found.key) ||
    (sec.labels || []).some((l) => labels.includes(l))
  let ceiling = null
  if (sensitive) {
    never = never.concat(sec.never || [])
    ceiling = sec.ceiling
    if (tierIndex(policy, tier) > tierIndex(policy, ceiling)) tier = ceiling
  }

  // 5. Escalation — one rung per failed attempt.
  const preAscentTier = tier
  if (row.attempt > 1) {
    const names = Object.keys(policy.tiers)
    const target = Math.min(tierIndex(policy, tier) + (row.attempt - 1), names.length - 1)
    tier = names[target]
    const max = sensitive ? (policy.escalation.security_max || ceiling) : null
    if (max && tierIndex(policy, tier) > tierIndex(policy, max)) tier = max
  }

  // 6. Diamond gating — applies to BASE tiers, not only escalated ones (§4.3.1).
  if (tier === 'diamond' && !diamondEligible(policy, found.key, row, preAscentTier)) {
    tier = policy.escalation.fallback.diamond
  }

  // 7. {model, effort} <- [tiers][tier]
  let spec = policy.tiers[tier]

  // 8. never-list fallback, then re-check.
  if (never.includes(spec.model)) {
    tier = policy.escalation.fallback[tier] || policy.escalation.fallback.diamond
    spec = policy.tiers[tier]
    if (never.includes(spec.model)) {
      throw new Error(
        `wave.js: no permitted model for step ${row.step} — fallback tier ` +
        `${JSON.stringify(tier)} also names a never-listed model ` +
        `${JSON.stringify(spec.model)}. Refusing to route.`
      )
    }
  }

  // 9. Requested values are what THIS resolution asked for; the executor
  //    echoes them back verbatim on `complete --metadata` (§3.1).
  return {
    hint: found.key, tier,
    model: spec.model, effort: spec.effort,
    model_requested: spec.model, effort_requested: spec.effort,
  }
}

// --- Archetype selection (§4.4) ---------------------------------------------
// `doc-recorder` is absent by design: DKT-60 made recording a trusted ACTION
// step, which the engine runs and never claims, so no archetype is ever chosen
// for it. The seven `spec-author-<axis>` hints are listed individually because
// the hint is the sibling's identity (DKT-64) — there is no bare `spec-author`.
const WRITE_HINTS = [
  'implement', 'test-infra', 'fix', 'commit-author',
  'spec-doc-author', 'prd-author', 'tdd-author', 'tdd-author-security',
  'adr-author', 'ux-spec-author', 'pr-comment-author',
  'spec-author-architecture', 'spec-author-security', 'spec-author-operations',
  'spec-author-performance', 'spec-author-code-quality',
  'spec-author-review-strategy', 'spec-author-testing',
]

function archetype(row, hint) {
  if (hint === 'research') return 'executor-research'
  if (row.class === 'write' || WRITE_HINTS.includes(hint)) return 'executor-write'
  return 'executor-read'
}

// --- Bootstrap prompt (§4.4) ------------------------------------------------
// Four observable obligations, no role content — the brief carries the entire
// contract (02 §8). Routing values are interpolated as FIXED STRINGS.
function bootstrap(row, r) {
  return `You are executing one step of a Docket run. Follow these four obligations exactly.

1. Claim it AND PARK THE TOKEN ON DISK, in ONE Bash call, exactly this:

   \`\`\`
   docket step claim ${row.step} --owner wave:${row.step} --render --json > "$TMPDIR/${row.step}.claim.json" &&
     jq -r '.data.token'  < "$TMPDIR/${row.step}.claim.json" > "$TMPDIR/${row.step}.token" &&
     chmod 600 "$TMPDIR/${row.step}.token" &&
     jq -r '.data.packet' < "$TMPDIR/${row.step}.claim.json" &&
     : > "$TMPDIR/${row.step}.claim.json"
   \`\`\`

   The last command TRUNCATES the claim file rather than deleting it — \`rm\`
   trips the session's permission classifier and parks you on a human
   approval; truncation is a plain redirect and does not. Same rule at step 3.

   Every path is spelled out because \`$TMPDIR\` IS SHARED BY EVERY EXECUTOR IN
   THE WAVE (measured: concurrent subagents all get the same directory). Your
   step id is what makes these filenames yours; do not shorten them to
   \`claim.json\` or \`token\`, or a sibling's claim overwrites yours.

   THE TOKEN IS RETURNED EXACTLY ONCE, in that response body — re-claiming is
   refused while you hold the lease, so there is NO second chance to capture it.
   SHELL VARIABLES DO NOT SURVIVE BETWEEN BASH CALLS and your work in step 2
   will take many calls, so a variable is useless here. The file is the only
   channel that reaches step 3.

   WRITING THE TOKEN TO THIS FILE IS REQUIRED AND AUTHORIZED — it is the
   designed mechanism, not a leak. It is mode 0600 under your own step id, it
   dies with the session's scratch directory, and the engine retires the token
   the moment you record. Do not skip the file write to be cautious: skipping
   it strands the step and is the WORSE outcome.

   The last command prints your rendered brief. Read it — it is your contract.

   On CONFLICT: stop immediately and report AT MOST three lines: your step id,
   the word CONFLICT, and the engine's error line verbatim. Do not investigate
   the holder, the scopes, or the remedy — the conductor and the engine already
   know.

2. Execute the brief you were handed. It is your entire contract.

3. Record it yourself, feeding the token file to STDIN:

   \`docket step complete ${row.step} --metadata '{"model_requested":"${r.model_requested}","effort_requested":"${r.effort_requested}","model_resolved":"<model that served you>","effort_resolved":"<effort you ran at>"}' < "$TMPDIR/${row.step}.token"\`

   or on failure:

   \`docket step fail ${row.step} --note '<why>' < "$TMPDIR/${row.step}.token"\`

   \`fail\` takes ONLY --note and --metadata — there is no --artifact-file on
   it. What you learned goes in the note (or the metadata bag); do not try to
   attach an artifact to a failure. \`--artifact-file\` exists on \`complete\`
   alone. A gap artifact — your contract's Stuck clause — is a SUCCESS
   condition: record it with \`complete\`, exactly as you would the normal
   artifact. Reach for \`fail\` only when a retry might genuinely redeem the
   attempt.

   The CLI reads the token from DOCKET_TOKEN or, when that is unset, from stdin
   (\`internal/cli/token.go\`; engine-spec.md §4, "Tokens pass via env/stdin,
   never argv"). NOTHING SETS DOCKET_TOKEN FOR YOU — a claim cannot export into
   your shell. Redirecting the file into stdin is the channel.

   Never \`cat\` the file, echo its contents, paste it into a command line, or
   reproduce it in your reply. There is deliberately no \`--token\` flag on any
   verb, because argv is world-readable through \`ps\`. Redirect it; never read it.

   After the record command exits 0, leave the token file alone or truncate
   it (\`: > "$TMPDIR/${row.step}.token"\`) — the engine retires the token the
   moment the record lands, so the file is inert either way. Do NOT \`rm\` it:
   deletion trips the permission classifier and parks you on a human approval
   at your very last step (observed on every executor of RUN-1's first wave),
   buying nothing a retired token has not already bought. If \`complete\` or
   \`fail\` errored, KEEP the token file INTACT and stop — it is the only
   thing that can still drive this step, and losing it after a failed record
   turns a routine step failure into a zombie claim the lease must reap.

   If the token file is missing or empty, or a record is refused for a missing
   or invalid token, say so plainly and stop. Do not reconstruct or guess it.

   If the brief requires an emitted artifact, create it WITH BASH (a heredoc:
   \`cat > "$TMPDIR/${row.step}-<kind>.md" <<'EOF' ... EOF\`) as a FRESH file
   whose name starts with your step id, then pass \`--artifact-file <path>\`
   on the complete. NEVER create this file with the Write tool: under the
   sandbox the Write tool materializes files at a DIFFERENT physical path
   than the \`$TMPDIR\` your Bash commands resolve, and the complete then
   fails "no such file or directory" against a file you just wrote
   (observed: RUN-1 STEP-32). (There is no \`--artifact-kind\`:
   the KIND comes from the workflow's \`emits\`, which your brief's OUTPUT
   section already names. A structured payload, when your brief requires one,
   goes in \`--payload-file <path>\`.) Never
   write to or reuse a shared filename like \`change-summary.md\`: executors in
   one wave share \`$TMPDIR\`, and under a shared name a racing sibling's bytes
   — or a predecessor's leftover when your own write silently fails — get
   recorded as YOUR artifact (RUN-3's STEP-11 recorded STEP-21's summary
   exactly this way).

   Copy model_requested and effort_requested EXACTLY as written above — they are
   the harness's record of its own intent, not yours to adjust. Fill the two
   resolved values with what actually served you.

4. End your reply with the step id and the status you recorded.`
}

// --- The wave ---------------------------------------------------------------
// [OBSERVED 2026-08-05, RUN-3] The harness JSON-encodes the args object in
// transit, so `args` can arrive as a STRING. Decode it here rather than routing
// against an empty document — an undecoded string has no .policyText, which
// falls through to `|| ''` and refuses for the wrong reason entirely. Name the
// real fault instead of parsing an empty document.
let input = args
if (typeof input === 'string') {
  try {
    input = JSON.parse(input)
    // LOUD by contract: the conduct skill promises this rescue announces
    // itself, and RUN-1 passed a string on all seven waves with nothing in
    // the record saying so. The log line is the deviation's only witness.
    log('wave.js: args arrived as a JSON-encoded STRING and was decoded — ' +
        'pass {rows, policyText} as a real object; do not rely on this rescue')
  } catch (e) {
    throw new Error(
      `wave.js: args arrived as a STRING that is not valid JSON (${e.message}). ` +
      `Refusing to route.`
    )
  }
}
if (!input || typeof input !== 'object') throw new Error(
  `wave.js: args is ${typeof input}, expected {rows, policyText}. Refusing to route.`
)

const rows = input.rows || []
const policy = parseToml(input.policyText || '')

if (policy.policy?.version !== 1) {
  throw new Error(
    `wave.js: policy.toml [policy] version is ${JSON.stringify(policy.policy?.version)}, expected 1. ` +
    `Refusing to route against an unknown schema.`
  )
}

// --- Staging (H-11) ---------------------------------------------------------
// RUN-3 spawned every row in ONE parallel blast: 21 of 53 spawns (~40%) died on
// claim CONFLICT, because the engine offers mutually-conflicting ready sets
// (E-5) and scope conflict is class-blind across issues (E-6). Both are engine
// fixes. This is the interim that costs nothing and needs no new data: rows
// ALREADY carry `class` and `issue`, and that is enough to schedule the wave so
// the conflicting pairs never run concurrently in the first place.
//
//   Stage 1  — write-class rows, SERIAL, each awaited before the next starts.
//              Writers are what hold broad tree scopes; running them one at a
//              time makes writer-vs-writer and writer-vs-reader contention
//              structurally impossible within a wave.
//   Stage 2+ — read-class rows grouped BY ISSUE: parallel inside a group
//              (same-issue reads already coexist — the ready.go:616-643
//              same-issue exemption), awaited between groups (cross-issue
//              reads exclude each other today; that is exactly E-6).
//
// WRITERS-FIRST IS A CORRECTNESS DEPENDENCY, not only contention control.
// The engine offers a loop's fixer and its re-review judges in ONE ready set
// (observed RUN-1 DISPATCH-5: fix@1 + review@1#0..3 together) and relies on
// this staging to sequence them — a judge spawned before the writer finishes
// would review the PRE-fix tree. Do not relax the serialization or reorder
// the stages without accounting for that.
//
// Everything here is deterministic code: the partition is a `class` test, the
// grouping is a `issue` key, and the order is first-appearance. No model judges
// anything about ordering, and no row's routing changes — only WHEN it spawns.
// Residual races (cross-run lease holders, mid-wave state drift) are out of
// reach without the engine fix; this removes the intra-wave class entirely.

function issueKey(row) {
  const iss = row.issue
  if (iss == null) return '(no-issue)'
  return typeof iss === 'object' ? (iss.id ?? iss.key ?? JSON.stringify(iss)) : String(iss)
}

// Group preserving first-appearance order — Map keeps insertion order, so the
// stage sequence is a pure function of the row order the engine handed us.
function groupByIssue(list) {
  const groups = new Map()
  for (const row of list) {
    const k = issueKey(row)
    if (!groups.has(k)) groups.set(k, [])
    groups.get(k).push(row)
  }
  return groups
}

// One spawn. `phaseLabel` puts the row in its stage's box in /workflows.
function spawn(row, phaseLabel) {
  const r = resolve(row, policy)
  const type = archetype(row, r.hint)
  log(`${row.step}: ${r.hint} -> ${type} @ ${r.model}/${r.effort} (tier ${r.tier})` +
      ` [${labelsOf(row).join(' ') || 'no labels'}]`)
  return agent(bootstrap(row, r), {
    // Display label for the fleet TUI ONLY — the journal never persists it
    // (attribution is the agentId join; E2). Bare step ids read as noise in
    // /workflows ("more informed names" — operator, 2026-08-06), and since
    // nothing downstream consumes the label, it is free to inform.
    label: `${row.step} · ${r.hint}`,
    phase: phaseLabel,
    agentType: type,
    model: r.model,
    effort: r.effort,
  }).then((text) => {
    // A NULL return is a DEAD SPAWN, not a quiet success. The runtime returns
    // null — it does not throw — when a model is unavailable or the agent is
    // skipped, and such an executor never claimed and never recorded, so the
    // step is still ready and the engine will offer it again forever. Calling
    // that 'no-return' read like a benign variant of a success and left the
    // conductor looping on a step nothing was working. Say it plainly.
    if (text == null) {
      log(`${row.step}: SPAWN PRODUCED NOTHING (model ${r.model} unavailable, ` +
          `or the agent was skipped) — the step was never claimed`)
      return { step: row.step, status: 'spawn-failed', text: null }
    }
    // 'returned', not 'recorded': the executor came back with a report, but
    // only the report's own text says whether the engine accepted a record —
    // RUN-1's STEP-1 returned a token-lost report and recorded nothing. The
    // conductor must read text, never trust this status as an outcome.
    return { step: row.step, status: 'returned', text }
  })
}

const writes = rows.filter((row) => row.class === 'write')
const reads = rows.filter((row) => row.class !== 'write')
const readGroups = groupByIssue(reads)

// The FIRST log line names the payload: every launch is a fresh workflow all
// listed as "wave" in /workflows, so the list preview is the only place a
// wave can say which wave it is ("each one is new" — operator, 2026-08-06).
log(`wave: ${rows.map((r) => `${r.step}·${r.executor}`).join(', ')}`)
log(
  `wave: ${rows.length} row(s) — ${writes.length} write (serial), ` +
  `${reads.length} read in ${readGroups.size} issue group(s)`
)

// Results are collected per row and re-keyed by step id at the end, so the
// return stays a flat checklist regardless of how the rows were staged.
const byStep = new Map()

// Stage 1 — writers, strictly serial. `await` inside the loop is the point.
// meta declares no phases, so the title is free to carry its count.
if (writes.length) {
  const label = `Writes (${writes.length}, serial)`
  phase(label)
  for (const row of writes) {
    const res = await spawn(row, label)
    byStep.set(row.step, res || { step: row.step, status: 'spawn-failed' })
  }
}

// Stage 2+ — one stage per issue, parallel within, awaited between. The
// counter is seeded by whether a write stage actually ran, so labels reflect
// stages that exist in THIS wave: a read-only wave's first group is stage 1,
// not a "stage 2" under a phantom stage 1 (operator screenshots, 2026-08-06).
let stage = writes.length ? 1 : 0
for (const [key, group] of readGroups) {
  stage++
  const label = `Reads ${key} (stage ${stage}, ${group.length})`
  phase(label)
  const settled = await parallel(group.map((row) => () => spawn(row, label)))
  settled.forEach((res, i) => {
    const row = group[i]
    byStep.set(row.step, res || { step: row.step, status: 'spawn-failed' })
  })
}

// The wave's return is a checklist; the engine's own discrepancy refusal in
// `next` is the enforcement (03 §3). Order follows the INPUT rows, not the
// staging, so the conductor reads it against the dispatch it handed in.
return rows.map((row) => byStep.get(row.step) || { step: row.step, status: 'spawn-failed' })
