export const meta = {
  name: 'wave',
  description: 'Spawn one executor per dispatched step row, routed by policy.toml',
  phases: [{ title: 'Wave', detail: 'one executor agent per spawn row' }],
}

// wave.js — the harness adapter (03 §1, §3). Static and versioned; never
// per-run generated (01 §4 A2). Inputs are `args = {rows, policyText}` handed
// in by the `run` skill: `next` rows verbatim (engine-spec §11.4) plus
// policy.toml as TEXT, because workflow scripts have no filesystem access.
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

function diamondEligible(policy, hint, issue, row, preAscentTier) {
  const gates = (policy.escalation && policy.escalation.diamond_gates) || []
  const labels = (issue && issue.labels) || []
  for (const g of gates) {
    if (g === 'investigator-class' && INVESTIGATOR_CLASS.includes(hint)) return true
    if (g === 'novel-architecture' && labels.includes('novel-architecture')) return true
    if (g === 'failed-gold-round' && row.attempt > 1 && preAscentTier === 'gold') return true
  }
  return false
}

function resolve(row, issue, policy) {
  const labels = (issue && issue.labels) || []

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
  if (tier === 'diamond' && !diamondEligible(policy, found.key, issue, row, preAscentTier)) {
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
const WRITE_HINTS = [
  'implement', 'test-infra', 'fix', 'commit-author', 'doc-recorder',
  'spec-doc-author', 'prd-author', 'tdd-author', 'tdd-author-security',
  'adr-author', 'ux-spec-author', 'spec-author', 'pr-comment-author',
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

1. Claim it: \`docket step claim ${row.step} --render\`
   One atomic mediation returning your capability token and your fully rendered
   brief. On CONFLICT, STOP IMMEDIATELY and report the conflict — another agent
   holds this step.

2. Execute the brief you were handed. It is your entire contract.

3. Record it yourself, with the token from \`DOCKET_TOKEN\`:
   \`docket step complete ${row.step} --metadata '{"model_requested":"${r.model_requested}","effort_requested":"${r.effort_requested}","model_resolved":"<model that served you>","effort_resolved":"<effort you ran at>"}'\`
   or \`docket step fail ${row.step} --note '<why>'\` on failure.
   Copy model_requested and effort_requested EXACTLY as written above — they are
   the harness's record of its own intent, not yours to adjust. Fill the two
   resolved values with what actually served you.

4. End your reply with the step id and the status you recorded.`
}

// --- The wave ---------------------------------------------------------------
const rows = (args && args.rows) || []
const policy = parseToml((args && args.policyText) || '')

if (policy.policy?.version !== 1) {
  throw new Error(
    `wave.js: policy.toml [policy] version is ${JSON.stringify(policy.policy?.version)}, expected 1. ` +
    `Refusing to route against an unknown schema.`
  )
}

phase('Wave')
log(`wave: ${rows.length} row(s)`)

const results = await parallel(rows.map((row) => () => {
  const r = resolve(row, row.issue, policy)
  const type = archetype(row, r.hint)
  log(`${row.step}: ${r.hint} -> ${type} @ ${r.model}/${r.effort} (tier ${r.tier})`)
  return agent(bootstrap(row, r), {
    label: row.step,          // journal attribution per step (§4.2, E2)
    phase: 'Wave',
    agentType: type,
    model: r.model,
    effort: r.effort,
  }).then((text) => ({ step: row.step, status: text == null ? 'no-return' : 'recorded', text }))
}))

// The wave's return is a checklist; the engine's own discrepancy refusal in
// `next` is the enforcement (03 §3).
return results.map((x, i) => x || { step: rows[i].step, status: 'spawn-failed' })
