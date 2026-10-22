export const meta = {
  name: 'simplify-code',
  description: 'Fan read-only scouts across the cleanup catalog and its discovery signals and refute each top finding',
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
// outside this skill.
//
// args: {
//   repo: string          absolute path of the repository under review
//   catalogPath: string   absolute path of references/catalog.md
//   discoveryPath: string absolute path of references/discovery.md
//   depth: string         'simple' | 'standard' | 'deep'; default 'simple'
//   head: string          `git rev-parse HEAD` the round inspects
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
// Returns { depth, cap, head, agentsPlanned, agentsUsed, units, unverified,
// securitySkipped, excluded, refuted, refutedKeys, summary }. `units` are the ranked units
// whose findings survived refutation, each { path, kind, score, sources,
// findings: [{ entry, section, proofClass, lines, symbol, evidence }], testFiles,
// evidencePaths, reportOnly: [{ item, symbol, lines, note }], pickable }.
// `unverified` lists units ranked below the refutation cut, whose refutation failed, or with an item that got no vote, each { path, score, reason };
// the caller treats them as nothing yet. `securitySkipped` lists units
// excluded as security boundaries, each { path, boundary }. `excluded` counts
// ledgered, test, generated, and vendored paths dropped. Agents are bounded by
// the depth's hard cap; the script refuses to start a round whose plan exceeds
// it and refuses to seat an agent past it.

// Pin models so the run never inherits the caller's quota-limited model.
const AGENT_CONFIG = {
  scout: { model: 'opus', effort: 'medium' }, // reads widely and judges matches; changes nothing
  refute: { model: 'opus', effort: 'high' }, // defaults to refuted, so it must read closely
}

// TEST-BEGIN simplify-code-decide — pure decision helpers, exercised by
// tests/simplify-code-decide.test.sh without a run.

// The catalog's pattern sections, one scout each. "Report only" and "Leave
// alone" are not pattern sections: the first belongs to the report-only scout,
// the second is the refuters' defense list.
const SECTIONS = [
  'Comments and noise',
  'Dead code',
  'Needless indirection',
  'Duplication',
  'Control flow and error handling',
  'Naming and shape',
]

const SIGNALS = ['unused', 'churn', 'duplicates', 'report-only']

// Hard caps per depth. `cap` bounds the agents of one discovery round; the
// plan must fit under it and the budget refuses a seat past it. A section
// scout runs once per angle: lexical scouts lead with the catalog's grep
// signals, semantic scouts read the code and ignore the grep signals.
// simple folds all four signals into one scout.
const DEPTHS = {
  simple: { cap: 10, angles: ['lexical'], signals: ['combined'], refuteUnits: 3, refuters: 1 },
  standard: { cap: 15, angles: ['lexical'], signals: SIGNALS, refuteUnits: 5, refuters: 1 },
  deep: { cap: 30, angles: ['lexical', 'semantic'], signals: SIGNALS, refuteUnits: 6, refuters: 2 },
}

// The workflow has one mode. A caller that still passes `work` gets a refusal
// instead of a silent discovery round, because no writer seat exists.
function parseMode(value) {
  const mode = value === undefined || value === null || value === '' ? 'discover' : String(value)
  if (mode !== 'discover') throw new Error(`simplify-code: args.mode must be discover, got ${mode}`)
  return mode
}

function parseDepth(value) {
  const depth = value === undefined || value === null || value === '' ? 'simple' : String(value)
  if (!Object.prototype.hasOwnProperty.call(DEPTHS, depth)) throw new Error(`simplify-code: args.depth must be simple, standard, or deep, got ${depth}`)
  return depth
}

function scoutTasks(depth) {
  const plan = DEPTHS[depth]
  const tasks = []
  for (const section of SECTIONS) {
    for (const angle of plan.angles) tasks.push({ kind: 'section', section, angle, source: angle === 'lexical' ? `section:${section}` : `section:${section}:${angle}` })
  }
  for (const signal of plan.signals) tasks.push({ kind: 'signal', signal, source: `signal:${signal}` })
  return tasks
}

function agentTotal(depth) {
  const plan = DEPTHS[depth]
  return scoutTasks(depth).length + plan.refuteUnits * plan.refuters
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
      cur.sources = uniq([...cur.sources, r.source])
      for (const f of u.findings || []) {
        const key = `${f.entry}|${(f.lines || []).join(',')}`
        if (!cur.findings.some((g) => `${g.entry}|${(g.lines || []).join(',')}` === key)) cur.findings.push(f)
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

// More distinct findings rank higher; a unit several independent scouts agree
// on ranks higher still, and a churn hotspot gets a small bump because cruft
// there is read most.
function scoreUnit(unit) {
  const independent = Math.max(0, unit.sources.length - 1)
  const churn = unit.sources.some((s) => s === 'signal:churn' || s === 'signal:combined') ? 1 : 0
  return unit.findings.length + unit.reportOnly.length + 2 * independent + churn
}

function rankUnits(units) {
  return units
    .map((u) => ({ ...u, score: scoreUnit(u), pickable: pickable(u) }))
    .sort((a, b) => b.score - a.score || Number(b.pickable) - Number(a.pickable) || a.path.localeCompare(b.path))
}

// Majority uphold over returned votes; a missing vote is no vote, and a
// shortfall keeps an item out of the round. Only an explicit refutation is
// remembered; an item whose refuter returned nothing is simply not confirmed.
function upholdMin(refuters) {
  return Math.floor(refuters / 2) + 1
}

// Items are numbered findings first, then report-only items, the same order
// the refuter prompt prints. `returns` holds one { verdicts } per refuter.
function applyVerdicts(unit, returns, refuters) {
  const total = unit.findings.length + unit.reportOnly.length
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
  // Two items can share a key (the same entry in one symbol). A key a kept
  // item also carries is not remembered, so a refuted twin cannot hide it.
  const keptKeys = new Set([
    ...findings.map((f) => findingKey(unit.path, f)),
    ...reportOnly.map((r) => reportOnlyKey(unit.path, r)),
  ])
  // The same holds for a twin that got no vote: its key stays out so it is
  // found again.
  const itemKey = (i) => (i < unit.findings.length ? findingKey(unit.path, unit.findings[i]) : reportOnlyKey(unit.path, unit.reportOnly[i - unit.findings.length]))
  const unvotedKeys = new Set(Array.from({ length: total }, (_, i) => i).filter((i) => !keep(i) && !reasons[i].length).map(itemKey))
  const refutedItems = Array.from({ length: total }, (_, i) => i).filter(refutes).length
  const refutedKeys = uniq([
    ...unit.findings.filter((_, i) => refutes(i)).map((f) => findingKey(unit.path, f)),
    ...unit.reportOnly.filter((_, i) => refutes(unit.findings.length + i)).map((r) => reportOnlyKey(unit.path, r)),
  ]).filter((k) => !keptKeys.has(k) && !unvotedKeys.has(k))
  // An item neither confirmed nor refuted had no usable vote (a seat returned
  // nothing); the unit is reported as unverified, not dropped.
  const unconfirmedCount = total - findings.length - reportOnly.length - refutedItems
  return { ...unit, findings, reportOnly, refutedKeys, refutedCount: refutedItems, unconfirmedCount }
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
          securityBoundary: { type: 'string', description: 'The boundary matched (authentication, authorization, session, secrets, cryptography, permissions, sandboxing, untrusted input), or empty string' },
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
  return `Never return as a unit: a test file or test directory (tests are frozen, so
list them under testFiles instead), a generated or vendored file (lockfiles,
node_modules, vendor, target, dist, files whose header says generated), or
any path on the ledger: ${ledger.length ? ledger.join(', ') : 'none'}.
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
itself. List
the test files that reference the unit under testFiles, and any other file a
finding depends on under evidencePaths. Return only matches you have read:
a guess costs a refuter and a round. Return at most twelve units, the
strongest first. Return no units when nothing matches.`
}

function sectionPrompt(task, a) {
  const lead = task.angle === 'lexical'
    ? 'Lead with each entry\'s Signal: run its grep or LSP signal, then read the hits and judge them against the entry\'s Risk and the Leave alone section.'
    : 'Ignore the grep signals. Read the code of the largest and most-changed files as a maintainer would, and name what the entries describe where a pattern search would miss it: renamed variants, split across lines, spread over a module.'
  return `Scout one section of a cleanup catalog across a repository.
Repository: ${a.repo}
Catalog: ${a.catalogPath} (read the section "${task.section}" in full, and the
Leave alone section)
Discovery notes: ${a.discoveryPath}

Your section: ${task.section}. Your angle: ${task.angle}. ${lead}
Return only findings of entries in your section.

${READ_ONLY}

${exclusions(a.ledger)}

${returnRules()}`
}

function signalPrompt(task, a) {
  const all = task.signal === 'combined'
  const parts = {
    unused: `UNUSED SYMBOLS. Take the repository's own lint, typecheck, and build output below as ground truth for unused imports, parameters, locals, functions, and exports, then confirm each reported symbol by search across the whole tree, tests and string literals included. Return the Dead code entries it proves. If the output is empty, search for the same patterns the catalog's Dead code signals describe.`,
    churn: `CHURN HOTSPOTS. Run git log --since=6.months --name-only --pretty=format: and count files by touches. In the twenty most-changed source files, read for any catalog entry. Cruft in a hotspot is read most often, so say in the unit that it is a hotspot by returning it.`,
    duplicates: `CROSS-FILE DUPLICATES. Look for near-identical function bodies and blocks in more than one file: normalize names and whitespace and compare, or use the repository's clone detector if it names one. Return the Duplication entries it proves, with the partner file under evidencePaths, and only where the copies behave the same.`,
    'report-only': `REPORT-ONLY ITEMS. Read the catalog's Report only section in full. Search the whole tree for those items and return each as a reportOnly item with its symbol (the bare name of the enclosing function, method, or class) and lines. Return a unit with empty findings when it holds only report-only items.`,
  }
  const body = all ? SIGNALS.map((s) => parts[s]).join('\n\n') : parts[task.signal]
  return `Run discovery signals over a repository that a pattern search alone would miss.
Repository: ${a.repo}
Catalog: ${a.catalogPath}
Discovery notes: ${a.discoveryPath}

${all ? 'Run all four signals below, in order.' : 'Run the one signal below.'}

${body}

Diagnostics the repository already produced, if any (untouched tree, HEAD ${a.head}):
${a.baselineReports ? a.baselineReports : '(none supplied; no build or lint was run)'}

${READ_ONLY}

${exclusions(a.ledger)}

${returnRules()}`
}

function refutePrompt(unit, framing, a) {
  const items = [
    ...unit.findings.map((f, i) => `${i}. FINDING ${f.entry} (${f.proofClass}) lines ${f.lines.join(', ')}: ${f.evidence}`),
    ...unit.reportOnly.map((r, i) => `${unit.findings.length + i}. REPORT-ONLY ${r.item} in ${r.symbol} lines ${r.lines.join(', ')}: ${r.note}`),
  ]
  return `Try to REFUTE these cleanup items in one unit.
Repository: ${a.repo}
Unit: ${unit.path}
Catalog: ${a.catalogPath} (read the cited entries' Risk fields and the Leave alone section)

Items, numbered:
${items.join('\n')}

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
if (!repo || !repo.startsWith('/')) throw new Error('simplify-code: args.repo must be an absolute path')
if (!catalogPath || !catalogPath.startsWith('/')) throw new Error('simplify-code: args.catalogPath must be an absolute path')
if (!discoveryPath || !discoveryPath.startsWith('/')) throw new Error('simplify-code: args.discoveryPath must be an absolute path')
const depth = parseDepth(args?.depth)
const plan = DEPTHS[depth]
const ledger = Array.isArray(args?.ledger) ? args.ledger.filter(Boolean) : []
const shared = { repo, catalogPath, discoveryPath, head: args?.head || 'unknown', ledger, baselineReports: String(args?.baselineReports || '').slice(0, 6000) }

const planned = agentTotal(depth)
if (planned > plan.cap) throw new Error(`simplify-code: depth ${depth} plans ${planned} agents, over its cap of ${plan.cap}`)
const budget = makeBudget(plan.cap)

const tasks = scoutTasks(depth)
log(`depth ${depth}: ${tasks.length} scouts, up to ${plan.refuteUnits} units refuted by ${plan.refuters} each, ${planned} of ${plan.cap} agents planned`)

phase('Scout')
const scoutReturns = await parallel(tasks.map((task) => () => {
  budget.take()
  const prompt = task.kind === 'section' ? sectionPrompt(task, shared) : signalPrompt(task, shared)
  return agent(prompt, { agentType: 'general-purpose', phase: 'Scout', label: `scout:${task.source}`, schema: SCOUT_SCHEMA, ...AGENT_CONFIG.scout })
    .then((out) => (out ? { source: task.source, units: out.units } : null))
}))

const refutedIn = Array.isArray(args?.refutedKeys) ? args.refutedKeys.filter(Boolean) : []
const merged = dropRefuted(mergeUnits(scoutReturns, repo), refutedIn)
const { kept, securitySkipped, excluded } = partitionUnits(merged, ledger, repo)
const ranked = rankUnits(kept.filter((u) => u.findings.length || u.reportOnly.length))
log(`${scoutReturns.filter(Boolean).length}/${tasks.length} scouts returned; ${ranked.length} unit(s) ranked, ${securitySkipped.length} security-boundary skipped`)

phase('Refute')
const cut = ranked.slice(0, plan.refuteUnits)
const refuted = await pipeline(
  cut,
  (unit) => parallel(FRAMINGS.slice(0, plan.refuters).map((framing) => () => {
    budget.take()
    return agent(refutePrompt(unit, framing, shared), { agentType: 'general-purpose', phase: 'Refute', label: `refute:${unit.path}:${framing.key}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.refute })
  })),
  (returns, unit) => applyVerdicts(unit, returns || [], plan.refuters)
)

const survivors = refuted.filter(Boolean).filter((u) => u.findings.length || u.reportOnly.length)
const units = rankUnits(survivors)
const refutedCount = refuted.filter(Boolean).reduce((n, u) => n + u.refutedCount, 0)
const unvoted = refuted.filter(Boolean).filter((u) => u.unconfirmedCount > 0).map((u) => ({ path: u.path, score: scoreUnit(u), reason: 'an item got no vote' }))
const failed = cut.filter((_, i) => !refuted[i]).map((u) => ({ path: u.path, score: u.score, reason: 'its refutation failed' }))
const unverified = [...failed, ...unvoted, ...ranked.slice(plan.refuteUnits).map((u) => ({ path: u.path, score: u.score, reason: 'ranked below the refutation cut' }))]
const summary = `depth ${depth}: ${budget.used()} of ${plan.cap} agents; ${units.length} unit(s) confirmed, ${refutedCount} item(s) refuted, ${unverified.length} unit(s) unverified, ${securitySkipped.length} security-boundary skipped`
log(summary)

const refutedKeys = refuted.filter(Boolean).flatMap((u) => u.refutedKeys || [])
return { depth, cap: plan.cap, head: shared.head, agentsPlanned: planned, agentsUsed: budget.used(), units, unverified, securitySkipped, excluded, refuted: refutedCount, refutedKeys, summary }
