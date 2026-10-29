export const meta = {
  name: 'simplify-code',
  description: 'Scout disjoint repository shards against the cleanup catalog and refute every ranked unit',
  phases: [
    { title: 'Scout' },
    { title: 'Refute' },
  ],
}

// Called by skills/simplify-code/SKILL.md, which owns the tick, the ledger,
// the findings queue, the static checks, and the Docket issues it files. The
// workflow is the discovery round and nothing else. It is read-only: every
// seat searches and reads, none edits, and nothing in the repository changes
// inside it. There is no writer seat; a worker applies a filed issue later,
// outside this skill. One scout reads each disjoint shard of the source once
// against the whole catalog, one more scout covers the cross-file signals, and
// each scout's units go to refuters as soon as that scout returns (no
// barrier). Every shard the caller passes is scanned and every ranked unit is
// refuted.
//
// args: {
//   repo: string          absolute path of the repository under review
//   catalogPath: string   absolute path of references/catalog.md
//   discoveryPath: string absolute path of references/discovery.md
//   head: string          `git rev-parse HEAD` the round inspects
//   shards: [{ name, files: string[], lines: number }]
//                         disjoint source-file groups the caller built with
//                         references/shard.sh, highest priority first; the
//                         caller may split them across several launches
//   tree: boolean         false skips the tree scout (default true); the
//                         caller sets it on every launch but one
//   ledger: string[]      repo-relative paths the ledger excludes
//   refutedKeys: string[] `<path>#<item or entry>#<symbol>` keys of items already
//                         settled (refuted, declined, resolved, ...); matching
//                         items are not re-found
//   baselineReports: string
//                         the lint, typecheck, and build diagnostics the
//                         repository already produced, verbatim, trimmed to its
//                         warnings; empty when none were supplied (no build or lint is run)
// }
//
// Returns { head, scouts, agentsUsed, units, unverified, uncovered,
// securitySkipped, excluded, refuted, refutedKeys, summary }.
// `units` are the ranked units whose findings survived refutation, each
// { path, kind, score, sources, findings: [{ entry, section, proofClass, lines,
// symbol, evidence }], testFiles, evidencePaths, reportOnly: [{ item, symbol,
// lines, note }], pickable }. `unverified` lists units whose refutation failed
// or with an item that got no vote, each { path, score, reason }. `uncovered`
// lists shards whose scout returned nothing. `securitySkipped` lists units
// excluded as security boundaries, each { path, boundary }. `excluded` counts
// ledgered, test, generated, and vendored paths dropped. MAX_AGENTS is a
// runaway backstop, not a coverage cut.

// Pin models so the run never inherits the caller's quota-limited model.
const AGENT_CONFIG = {
  scout: { model: 'opus', effort: 'medium' }, // reads a shard, matches the catalog, and judges security boundaries; changes nothing
  refute: { model: 'fable', effort: 'high' }, // defaults to refuted, so it must read closely
}

// TEST-BEGIN simplify-code-decide — pure decision helpers, exercised by
// tests/simplify-code-decide.test.sh without a run.

// Every round scans every shard the caller passes and two refuters judge each
// batch.
const REFUTERS = 2
const MAX_AGENTS = 900

// Items one refuter judges in one agent. A batch groups whole units; a unit
// with more items than this is judged alone.
const REFUTE_BATCH_ITEMS = 10

// The workflow has one mode. A caller that still passes `work` or `apply` gets
// a refusal instead of a silent discovery round, because no writer seat exists.
function parseMode(value) {
  const mode = value === undefined || value === null || value === '' ? 'discover' : String(value)
  if (mode !== 'discover') throw new Error(`simplify-code: args.mode must be discover, got ${mode}`)
  return mode
}

// The shards a round scans: every group the caller passes, each a
// non-empty list of files, plus one tree-wide scout for the cross-file signals
// unless the caller turned it off (a launch that scans only some of the shards
// of a split discovery: args.tree false).
function scoutTasks(shards, withTree = true) {
  const usable = (Array.isArray(shards) ? shards : []).filter((s) => s && s.name && Array.isArray(s.files) && s.files.length)
  const tasks = usable.map((shard) => ({ kind: 'shard', shard, source: `shard:${shard.name}` }))
  if (withTree) tasks.push({ kind: 'tree', source: 'tree' })
  return tasks
}

// Refuse a seat past the cap. The count includes seats that later fail.
function makeBudget(cap) {
  let used = 0
  return {
    take() {
      if (used >= cap) throw new Error(`simplify-code: agent cap ${cap} reached`)
      used += 1
    },
    used() {
      return used
    },
  }
}

const TEST_PATH = /(^|\/)(tests?|__tests__|spec|specs|testdata|fixtures|__snapshots__)\/|\.(test|spec)\.[^/]+$|_(test|spec)\.[^/]+$|(^|\/)test_[^/]+\.py$|(^|\/)conftest\.py$/
const GENERATED_PATH = /(^|\/)(node_modules|vendor|target|dist|build|\.git)\/|(^|\/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock|Gemfile\.lock|uv\.lock)$|\.min\.(js|css)$|\.generated\./
const SECURITY_PATH = /(^|[/._-])(auth|authn|authz|oauth|session|sessions|secret|secrets|crypto|cipher|permission|permissions|sandbox|acl|rbac|credential|credentials|token|tokens|password|passwd|jwt|tls|ssl|csrf|login)([/._-]|$)/i

// Why a path is not a unit, or '' when it can be one. Tests are frozen,
// generated and vendored files are not ours, and the ledger names what an
// earlier tick skipped. A security-boundary path is a backstop for scouts that
// miss one; the scouts judge the rest.
function exclusionReason(path, ledgerPaths, repo) {
  if (TEST_PATH.test(path)) return 'test'
  if (GENERATED_PATH.test(path)) return 'generated'
  if ((ledgerPaths || []).map((p) => normalizePath(p, repo)).some((p) => path === p || path.startsWith(`${p}/`))) return 'ledger'
  if (SECURITY_PATH.test(path)) return 'security'
  return ''
}

function uniq(list) {
  return [...new Set(list.filter(Boolean))]
}

// A scout may return `./src/a.js` or an absolute path; the ledger and the
// exclusions compare repo-relative paths exactly.
function normalizePath(path, repo) {
  let p = String(path || '').trim()
  if (repo && p.startsWith(`${repo}/`)) p = p.slice(repo.length + 1)
  while (p.startsWith('./')) p = p.slice(2)
  return p.replace(/\/+$/, '')
}

// The keys a refuted item is remembered by, stable across line shifts. The key
// is the first column of a queue line, so it carries no `|` or newline.
function keyText(key) {
  return key.replace(/[|\r\n]+/g, ' ').replace(/\s*#\s*/g, '#').replace(/\s+/g, ' ').replace(/\(\)(?=\s*$)/, '').trim()
}

function findingKey(path, finding) {
  return keyText(`${path}#${finding.entry}#${String(finding.symbol).trim()}`)
}

function reportOnlyKey(path, item) {
  return keyText(`${path}#${item.item}#${String(item.symbol).trim()}`)
}

// Drop items a refuter already rejected in an earlier round, so the next round
// does not re-find and re-refute them.
function dropRefuted(units, refutedKeys) {
  const keys = new Set((refutedKeys || []).map((k) => keyText(String(k))))
  return units.map((u) => ({
    ...u,
    findings: u.findings.filter((f) => !keys.has(findingKey(u.path, f))),
    reportOnly: u.reportOnly.filter((r) => !keys.has(reportOnlyKey(u.path, r))),
  }))
}

// Merge the units every scout returned into one record per path. A finding is
// the same finding when entry and lines match; a report-only item when item
// and symbol match. `sources` names which scouts reported the unit.
function mergeUnits(returns, repo) {
  const byPath = new Map()
  for (const r of returns.filter(Boolean)) {
    for (const raw of r.units || []) {
      if (!raw || !raw.path) continue
      const u = { ...raw, path: normalizePath(raw.path, repo) }
      const cur = byPath.get(u.path) || { path: u.path, kind: u.kind || 'file', sources: [], findings: [], testFiles: [], evidencePaths: [], reportOnly: [], securityBoundary: '' }
      cur.sources = uniq([...cur.sources, ...(u.sources || []), r.source])
      const findingId = (f) => `${f.entry}|${(f.lines || []).join(',')}`
      for (const f of u.findings || []) {
        const key = findingId(f)
        if (!cur.findings.some((g) => findingId(g) === key)) cur.findings.push(f)
      }
      for (const item of u.reportOnly || []) {
        const key = reportOnlyKey(u.path, item)
        if (!cur.reportOnly.some((g) => reportOnlyKey(u.path, g) === key)) cur.reportOnly.push(item)
      }
      cur.testFiles = uniq([...cur.testFiles, ...(u.testFiles || []).map((p) => normalizePath(p, repo))])
      cur.evidencePaths = uniq([...cur.evidencePaths, ...(u.evidencePaths || []).map((p) => normalizePath(p, repo))])
      cur.securityBoundary = cur.securityBoundary || u.securityBoundary || ''
      byPath.set(u.path, cur)
    }
  }
  return [...byPath.values()]
}

// Split merged units into the ones that can be worked, the security-boundary
// skips, and a count of the other exclusions.
function partitionUnits(units, ledgerPaths, repo) {
  const kept = []
  const securitySkipped = []
  const excluded = { test: 0, generated: 0, ledger: 0 }
  for (const u of units) {
    const reason = exclusionReason(u.path, ledgerPaths, repo)
    if (reason === 'security' || (!reason && u.securityBoundary)) securitySkipped.push({ path: u.path, boundary: u.securityBoundary || 'path names a security boundary' })
    else if (reason) excluded[reason] += 1
    else kept.push(u)
  }
  return { kept, securitySkipped, excluded }
}

// A unit is pickable when a test references it or every finding it carries is
// inert or reachability, which need no tests. The caller still proves the
// guard at pick time; this only orders the queue.
function pickable(unit) {
  if (!unit.findings.length) return false
  if ((unit.testFiles || []).length) return true
  return unit.findings.every((f) => f.proofClass === 'inert' || f.proofClass === 'reachability')
}

const itemCount = (unit) => unit.findings.length + unit.reportOnly.length

// More distinct findings rank higher; a unit several independent scouts agree
// on ranks higher still.
function scoreUnit(unit) {
  const independent = Math.max(0, unit.sources.length - 1)
  return itemCount(unit) + 2 * independent
}

function rankUnits(units) {
  return units
    .map((u) => ({ ...u, score: scoreUnit(u), pickable: pickable(u) }))
    .sort((a, b) => b.score - a.score || Number(b.pickable) - Number(a.pickable) || a.path.localeCompare(b.path))
}

// Majority uphold over returned votes (with two refuters, both); a missing
// vote is no vote, and a shortfall keeps an item out of the round. Only an
// explicit refutation is remembered; an item whose refuter returned nothing is
// simply not confirmed.
function upholdMin(refuters) {
  return Math.floor(refuters / 2) + 1
}

// Items are numbered findings first, then report-only items, the same order
// the refuter prompt prints. `returns` holds one { verdicts } per refuter.
function applyVerdicts(unit, returns, refuters) {
  const total = itemCount(unit)
  const upheld = Array.from({ length: total }, () => 0)
  const reasons = Array.from({ length: total }, () => [])
  for (const r of returns.filter(Boolean)) {
    for (const v of r.verdicts || []) {
      if (!Number.isInteger(v.id) || v.id < 0 || v.id >= total) continue
      if (v.refuted) reasons[v.id].push(v.reason)
      else upheld[v.id] += 1
    }
  }
  const keep = (i) => upheld[i] >= upholdMin(refuters)
  const findings = unit.findings.filter((_, i) => keep(i))
  const reportOnly = unit.reportOnly.filter((_, i) => keep(unit.findings.length + i))
  const refutes = (i) => !keep(i) && reasons[i].length > 0
  const ids = Array.from({ length: total }, (_, i) => i)
  const itemKey = (i) => (i < unit.findings.length ? findingKey(unit.path, unit.findings[i]) : reportOnlyKey(unit.path, unit.reportOnly[i - unit.findings.length]))
  // Two items can share a key (the same entry in one symbol). A key a kept
  // item also carries is not remembered, so a refuted twin cannot hide it.
  const keptKeys = new Set(ids.filter(keep).map(itemKey))
  // The same holds for a twin that got no vote: its key stays out so it is
  // found again.
  const unvotedKeys = new Set(ids.filter((i) => !keep(i) && !reasons[i].length).map(itemKey))
  const refutedIds = ids.filter(refutes)
  const refutedItems = refutedIds.length
  const refutedKeys = uniq(refutedIds.map(itemKey)).filter((k) => !keptKeys.has(k) && !unvotedKeys.has(k))
  // An item neither confirmed nor refuted had no usable vote (a seat returned
  // nothing); the unit is reported as unverified, not dropped.
  const unconfirmedCount = total - findings.length - reportOnly.length - refutedItems
  return { ...unit, findings, reportOnly, refutedKeys, refutedCount: refutedItems, unconfirmedCount }
}

// Group ranked units into refuter batches of whole units, at most `maxItems`
// items each; a unit larger than that is a batch of its own. Order is kept, so
// the strongest units are judged first.
function batchUnits(units, maxItems) {
  const batches = []
  let cur = []
  let n = 0
  for (const u of units) {
    const c = itemCount(u)
    if (cur.length && n + c > maxItems) {
      batches.push(cur)
      cur = []
      n = 0
    }
    cur.push(u)
    n += c
    if (n >= maxItems) {
      batches.push(cur)
      cur = []
      n = 0
    }
  }
  if (cur.length) batches.push(cur)
  return batches
}

// A refuter judges a whole batch with ids numbered across its units; cut its
// verdicts down to the one unit's slice and renumber them from zero.
function sliceVerdicts(returns, offset, count) {
  return returns.map((r) => (r ? { verdicts: (r.verdicts || []).filter((v) => Number.isInteger(v.id) && v.id >= offset && v.id < offset + count).map((v) => ({ ...v, id: v.id - offset })) } : null))
}
// TEST-END simplify-code-decide

const FRAMINGS = [
  {
    key: 'false-positive',
    angle: 'FALSE POSITIVE. For each item, find the strongest reason it is not cruft: a Risk field in the catalog that applies, a Leave alone case, a trust boundary, reflection or a plugin registry, an exported symbol an outside consumer may call, a test double, a decorator that adds behavior. Refute when any applies.',
  },
  {
    key: 'evidence',
    angle: 'EVIDENCE. For each item, open the cited file and lines and check them: the code is there, it matches the catalog Signal, and the claim (unused, duplicate, restated) is true on a search of the whole tree, tests and string literals included. Refute when the lines are wrong, the code differs from the claim, or a reference exists.',
  },
]

const SCOUT_SCHEMA = {
  type: 'object',
  properties: {
    units: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          path: { type: 'string', description: 'Repo-relative path of the file or module directory' },
          kind: { type: 'string', enum: ['file', 'directory'] },
          findings: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                entry: { type: 'string', description: 'The catalog entry name, verbatim' },
                section: { type: 'string' },
                proofClass: { type: 'string', enum: ['inert', 'reachability', 'probe'] },
                lines: { type: 'array', items: { type: 'integer' } },
                symbol: { type: 'string', description: 'Bare name of the innermost enclosing function, method, or class, without parentheses or a line number; for a top-level declaration or import, the declared name' },
                evidence: { type: 'string', description: 'The matched code, quoted, or the signal output that shows it' },
              },
              required: ['entry', 'section', 'proofClass', 'lines', 'symbol', 'evidence'],
            },
          },
          testFiles: { type: 'array', items: { type: 'string' } },
          evidencePaths: { type: 'array', items: { type: 'string' }, description: 'Other files a finding depends on: the duplicate partner, callers of a pass-through or flag, rename callers' },
          reportOnly: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                item: { type: 'string', description: 'The Report only item name, verbatim' },
                symbol: { type: 'string', description: 'Bare name of the innermost enclosing function, method, or class, without parentheses or a line number; for a top-level declaration or import, the declared name' },
                lines: { type: 'array', items: { type: 'integer' } },
                note: { type: 'string' },
              },
              required: ['item', 'symbol', 'lines', 'note'],
            },
          },
          securityBoundary: { type: 'string', description: 'The boundary the code in this unit implements (authentication, authorization, session, secrets, cryptography, permissions, sandboxing, untrusted input), or empty string when the code only has a boundary word in its name' },
        },
        required: ['path', 'kind', 'findings', 'testFiles', 'evidencePaths', 'reportOnly', 'securityBoundary'],
      },
    },
  },
  required: ['units'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'integer', description: 'The item number from the list' },
          refuted: { type: 'boolean' },
          reason: { type: 'string', description: 'The strongest single ground, quoting the code when refuting' },
        },
        required: ['id', 'refuted', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

const READ_ONLY = `You are read-only. Use search, file reads, and LSP. For git use only
read commands (git log, git grep, git ls-files, git diff, git show). Run no
build, test, formatter, linter, package install, or any command that writes,
and make no edit: the working tree is in use by the caller and another
session may be editing it between rounds.`

function exclusions(ledger) {
  return `Never return as a unit: a test file or test directory (tests are frozen,
so list them under testFiles instead), a generated or vendored file
(lockfiles, node_modules, vendor, target, dist, files whose header says
generated), or any path on the ledger: ${ledger.length ? ledger.join(', ') : 'none'}.
For a unit in a security boundary (authentication, authorization, session
handling, secrets, cryptography, permissions, sandboxing, untrusted input at a
privilege boundary), return it with findings and reportOnly empty and
securityBoundary set to the boundary; analyze nothing in it.`
}

function returnRules() {
  return `Return one unit per file, or per directory when the language groups code
that way. For each finding give the catalog entry name verbatim, its section,
its proof class from the entry, the lines, the symbol, and the matched code
quoted. For each finding and report-only item the symbol is the bare name of
the innermost enclosing function, method, or class, without parentheses or a
line number; for a top-level declaration or import it is the declared name
itself. List the test files that reference the unit under testFiles, and any
other file a finding depends on under evidencePaths. Return only matches you
have read: a guess costs a refuter and a round. Return the strongest first.
Return no units when nothing matches.`
}

function shardPrompt(task, a) {
  const list = task.shard.files.join('\n')
  return `Scout one shard of a repository against the whole cleanup catalog.
Repository: ${a.repo}
Catalog: ${a.catalogPath} (read every pattern section once, then Report only and
Leave alone)
Discovery notes: ${a.discoveryPath}

Your shard: ${task.shard.name} (${task.shard.lines || 'unknown'} lines). Read every file below in full, once,
and match what you read against the catalog's entries; use an entry's Signal
as a hint, not a filter. The files are disjoint from every other scout's.

${list}

Diagnostics the repository already produced, if any (untouched tree, HEAD ${a.head}). Treat it as ground truth for unused symbols in your files:
${a.baselineReports || '(none supplied; no build or lint was run)'}

Return findings of any pattern section, and Report only items with their
symbol and lines. Return the unit's test files by looking for the tests that
reference it.

${READ_ONLY}

${exclusions(a.ledger)}

${returnRules()}`
}

function treePrompt(a) {
  return `Run the two cross-file signals that a per-shard read cannot see.
Repository: ${a.repo}
Catalog: ${a.catalogPath}
Discovery notes: ${a.discoveryPath}

CROSS-FILE DUPLICATES. Look for near-identical function bodies and blocks in
more than one file: normalize names and whitespace and compare, or use the
repository's clone detector if it names one. Return the Duplication entries it
proves, with the partner file under evidencePaths, and only where the copies
behave the same.

UNUSED ACROSS FILES. Take the lint, typecheck, and build output below as
ground truth for unused imports, parameters, locals, functions, and exports,
then confirm each reported symbol by search across the whole tree, tests and
string literals included. Return the Dead code entries it proves. If the
output is empty, search for exported symbols with no importer.

Diagnostics the repository already produced, if any (untouched tree, HEAD ${a.head}):
${a.baselineReports || '(none supplied; no build or lint was run)'}

${READ_ONLY}

${exclusions(a.ledger)}

${returnRules()}`
}

function refutePrompt(batch, framing, a) {
  let n = 0
  const sections = batch.map((unit) => {
    const items = [
      ...unit.findings.map((f) => `${n++}. FINDING ${f.entry} (${f.proofClass}) lines ${f.lines.join(', ')}: ${f.evidence}`),
      ...unit.reportOnly.map((r) => `${n++}. REPORT-ONLY ${r.item} in ${r.symbol} lines ${r.lines.join(', ')}: ${r.note}`),
    ]
    return `Unit: ${unit.path}\n${items.join('\n')}`
  })
  return `Try to REFUTE these cleanup items.
Repository: ${a.repo}
Catalog: ${a.catalogPath} (read the cited entries' Risk fields and the Leave alone section)

Items, numbered across the units below:
${sections.join('\n\n')}

Your angle: ${framing.angle}

Default to refuted=true unless you can confirm the item is real: the code is
where the item says, the catalog entry applies, and no Risk or Leave alone
case covers it. Return one verdict per item with the strongest ground,
quoting the code when you refute.

${READ_ONLY}`
}

parseMode(args?.mode)
const repo = args?.repo
const catalogPath = args?.catalogPath
const discoveryPath = args?.discoveryPath
for (const [name, value] of Object.entries({ repo, catalogPath, discoveryPath })) {
  if (!value || !value.startsWith('/')) throw new Error(`simplify-code: args.${name} must be an absolute path`)
}
const ledger = Array.isArray(args?.ledger) ? args.ledger.filter(Boolean) : []
const refutedIn = Array.isArray(args?.refutedKeys) ? args.refutedKeys.filter(Boolean) : []
const shared = { repo, catalogPath, discoveryPath, head: args?.head || 'unknown', ledger, baselineReports: String(args?.baselineReports || '').slice(0, 6000) }

const withTree = args?.tree !== false
const tasks = scoutTasks(args?.shards, withTree)
if (!tasks.some((t) => t.kind === 'shard')) throw new Error('simplify-code: args.shards must list at least one non-empty shard')
if (tasks.length > MAX_AGENTS) throw new Error(`simplify-code: ${tasks.length} scouts is over the ${MAX_AGENTS}-agent backstop; pass fewer shards per launch`)
const budget = makeBudget(MAX_AGENTS)
const framings = FRAMINGS.slice(0, REFUTERS)
log(`${tasks.filter((t) => t.kind === 'shard').length} shard scouts and ${withTree ? 1 : 0} tree scout, every ranked unit refuted in batches of up to ${REFUTE_BATCH_ITEMS} items by ${REFUTERS} refuters each`)

// One chain per scout, no barrier: a scout's units go to refuters as soon as
// that scout returns, so refuters overlap the scouts still reading.
const chains = await pipeline(
  tasks,
  (task) => {
    budget.take()
    const prompt = task.kind === 'shard' ? shardPrompt(task, shared) : treePrompt(shared)
    return agent(prompt, { agentType: 'general-purpose', phase: 'Scout', label: `scout:${task.source}`, schema: SCOUT_SCHEMA, ...AGENT_CONFIG.scout })
      .then((out) => (out ? { source: task.source, units: out.units } : null))
  },
  async (scouted, task) => {
    if (!scouted) return { task, scouted: false, securitySkipped: [], excluded: { test: 0, generated: 0, ledger: 0 }, refuted: [], failed: [], batches: 0 }
    const merged = dropRefuted(mergeUnits([scouted], repo), refutedIn)
    const { kept, securitySkipped, excluded } = partitionUnits(merged, ledger, repo)
    const ranked = rankUnits(kept.filter((u) => u.findings.length || u.reportOnly.length))
    const batches = batchUnits(ranked, REFUTE_BATCH_ITEMS)
    const judged = await parallel(batches.map((batch) => async () => {
      const returns = await parallel(framings.map((framing) => () => {
        budget.take()
        return agent(refutePrompt(batch, framing, shared), { agentType: 'general-purpose', phase: 'Refute', label: `refute:${task.source}:${batch[0].path}:${framing.key}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.refute })
      }))
      let offset = 0
      return batch.map((unit) => {
        const slice = sliceVerdicts(returns, offset, itemCount(unit))
        offset += itemCount(unit)
        return applyVerdicts(unit, slice, framings.length)
      })
    }))
    const refuted = judged.flatMap((r, i) => (r ? r : batches[i].map((u) => ({ ...u, failed: true }))))
    return { task, scouted: true, securitySkipped, excluded, refuted: refuted.filter((u) => !u.failed), failed: refuted.filter((u) => u.failed), batches: batches.length }
  }
)

const done = chains.filter(Boolean)
const uncovered = tasks.filter((t, i) => t.kind === 'shard' && !(chains[i] && chains[i].scouted)).map((t) => t.shard.name)
const refutedUnits = done.flatMap((c) => c.refuted)
const securitySkipped = done.flatMap((c) => c.securitySkipped)
const excluded = done.reduce((e, c) => ({ test: e.test + c.excluded.test, generated: e.generated + c.excluded.generated, ledger: e.ledger + c.excluded.ledger }), { test: 0, generated: 0, ledger: 0 })

// The tree scout can name a path a shard scout also named; merge by path.
const survivors = refutedUnits.filter((u) => u.findings.length || u.reportOnly.length)
const units = rankUnits(mergeUnits(survivors.map((u) => ({ source: u.sources[0], units: [u] })), repo))
const refutedCount = refutedUnits.reduce((n, u) => n + u.refutedCount, 0)
const unvoted = refutedUnits.filter((u) => u.unconfirmedCount > 0).map((u) => ({ path: u.path, score: scoreUnit(u), reason: 'an item got no vote' }))
const failedUnits = done.flatMap((c) => c.failed).map((u) => ({ path: u.path, score: scoreUnit(u), reason: 'its refutation failed' }))
const unverified = [...failedUnits, ...unvoted]
const keptKeys = new Set(units.flatMap((u) => [...u.findings.map((f) => findingKey(u.path, f)), ...u.reportOnly.map((r) => reportOnlyKey(u.path, r))]))
const refutedKeys = uniq(refutedUnits.flatMap((u) => u.refutedKeys || [])).filter((k) => !keptKeys.has(k))
const summary = `${budget.used()} agents (${tasks.length} scouts); ${units.length} unit(s) confirmed, ${refutedCount} item(s) refuted, ${unverified.length} unit(s) unverified, ${uncovered.length} shard(s) uncovered, ${securitySkipped.length} security-boundary skipped`
log(summary)

return { head: shared.head, scouts: tasks.length, agentsUsed: budget.used(), units, unverified, uncovered, securitySkipped, excluded, refuted: refutedCount, refutedKeys, summary }
