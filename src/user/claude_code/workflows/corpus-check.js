export const meta = {
  name: 'corpus-check',
  description: 'Audit src/user/claude_code and src/user/docket/config for coherence: per-file reads, a completeness sweep, cross-boundary pairing, then adversarial verification',
  phases: [
    { title: 'Discover' },
    { title: 'Read' },
    { title: 'Completeness' },
    { title: 'Cross-boundary' },
    { title: 'Verify' },
  ],
}

// Pin models to avoid inheriting the caller's quota-limited model.
const AGENT_CONFIG = {
  discovery: { model: 'haiku', effort: 'low' },
  sizing: { model: 'haiku', effort: 'low' },
  read: { model: 'sonnet', effort: 'low' },
  coverage: { model: 'haiku', effort: 'low' },
  refill: { model: 'sonnet', effort: 'low' },
  crossBoundary: { model: 'fable', effort: 'low' },
  verify: { model: 'haiku', effort: 'low' },
}

const SHARD_LINES = 1500
const REFUTERS_PER_BATCH = 3
// Verification runs one refuter agent per (file batch, refuter) rather than per
// finding: a batch carries every finding from one file up to VERIFY_BATCH_MAX,
// and the refuter returns one verdict per finding. A refuter per finding would
// exceed the Workflow tool's 1000-agent lifetime cap on a few hundred findings.
const VERIFY_BATCH_MAX = 12
// Agent budget, fixed before any fan-out so the read plan can never consume the
// verification allowance. Every reserve is a count of agent() calls.
const AGENT_CAP = 1000
const AGENT_CAP_MARGIN = 10
const DISCOVERY_AGENTS = 3
const COMPLETENESS_RESERVE = 1 + 8 // the critic plus at most eight gap refills

const CROSS_PAIRS = [
  {
    key: 'routing-labels',
    a: 'brief/SKILL.md, docket-groom/SKILL.md routing-label rules',
    b: 'src/user/docket/config/README.md Routing labels paragraph and every workflows/*.toml [match].unless_labels',
  },
  {
    key: 'ac-rules',
    a: 'docket-plan/SKILL.md and docket-groom/SKILL.md acceptance-criterion rules',
    b: 'src/user/docket/config/contracts/verify-ac.md, schemas/ac-report@2.json, fragments/fix-ac-only.md',
  },
  {
    key: 'loop-bounds',
    a: 'docket-run/SKILL.md standing rulings and loop bounds',
    b: 'src/user/docket/config/workflows/*.toml max_fix_loops/max_stalled_rounds values and policy.toml [escalation]',
  },
  {
    key: 'docket-reference',
    a: 'docket/SKILL.md and its references/*.md',
    b: 'live schema versions, workflow names, gate names, executor names, policy variant names in src/user/docket/config',
  },
  {
    key: 'frozen-file-rules',
    a: 'docket-refit, docket-reconcile, docket-retro, docket-bootstrap SKILL.md claims about corpus layout and frozen-file rules',
    b: 'src/user/docket/config/README.md, justfile, .docket/bin/frozen-drift-check header',
  },
  {
    key: 'executor-agents',
    a: 'agents/executor-*.md',
    b: 'the contracts and fragments they execute (contracts/*.md archetype: field matches)',
  },
]

// Called by skills/corpus-check/SKILL.md, which defines scope and handles fixes.
// args: { sinceRef: string | null } supplies context without narrowing the audit.

const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    file: { type: 'string' },
    linesRead: { type: 'string', description: 'Spans read, e.g. "1-390" or "1-1500,1501-3116", not the file total' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          location: { type: 'string', description: 'file:line or file:line-range' },
          quote: { type: 'string' },
          counterpart: { type: 'string', description: 'Related file:line and quote, or empty string if none' },
          severity: { type: 'string', enum: ['contradiction', 'stale', 'terminology', 'internal', 'structural', 'style', 'duplicate'] },
          summary: { type: 'string' },
          proposedFix: { type: 'string' },
          needsOperatorDecision: { type: 'boolean', description: 'True when both readings are defensible or the fix is expensive or cascading' },
        },
        required: ['location', 'quote', 'severity', 'summary', 'proposedFix', 'needsOperatorDecision'],
      },
    },
    notes: { type: 'string', description: 'Observations without a finding, such as terminology or confirmed consistency' },
  },
  required: ['file', 'linesRead', 'findings'],
}

const COMPLETENESS_SCHEMA = {
  type: 'object',
  properties: {
    gaps: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          range: { type: 'string' },
          reason: { type: 'string' },
        },
        required: ['file', 'range', 'reason'],
      },
    },
  },
  required: ['gaps'],
}

const BATCH_VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          index: { type: 'integer', description: 'The finding number from the batch, starting at 1' },
          refuted: { type: 'boolean' },
          reason: { type: 'string' },
        },
        required: ['index', 'refuted', 'reason'],
      },
    },
  },
  required: ['verdicts'],
}

function parseLines(text) {
  return (text || '')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
}

// TEST-BEGIN verify-budget — pure planning helpers, exercised without a run.
function verifyBudget(readPlanSize, crossPairs) {
  return Math.max(0, AGENT_CAP - AGENT_CAP_MARGIN - DISCOVERY_AGENTS - readPlanSize - COMPLETENESS_RESERVE - crossPairs)
}

// One batch per file slice of at most VERIFY_BATCH_MAX findings, in stable file
// order so a resumed run replays the same batches.
function buildVerifyBatches(findings) {
  const byFile = new Map()
  findings.forEach((finding, index) => {
    if (!byFile.has(finding.file)) byFile.set(finding.file, [])
    byFile.get(finding.file).push({ finding, index })
  })
  return [...byFile.keys()].sort().flatMap((file) => {
    const items = byFile.get(file)
    return Array.from({ length: Math.ceil(items.length / VERIFY_BATCH_MAX) }, (_, slice) => ({
      file,
      slice,
      items: items.slice(slice * VERIFY_BATCH_MAX, (slice + 1) * VERIFY_BATCH_MAX),
    }))
  })
}

// Splits batches into those the budget covers and those it cannot; the second
// list is reported as unverified, never dropped and never counted as survived.
function planVerification(batches, budget) {
  const affordable = Math.floor(budget / REFUTERS_PER_BATCH)
  return { covered: batches.slice(0, affordable), uncovered: batches.slice(affordable) }
}

// Applies one batch's refuter returns to its findings. A refuter that returned
// nothing, or omitted a finding's index, casts no vote on it. A finding with no
// votes at all is unverified, not refuted and not upheld.
function applyBatchVerdicts(batch, returns) {
  const upheld = []
  const unverified = []
  batch.items.forEach(({ finding }, position) => {
    const votes = returns
      .filter(Boolean)
      .map((r) => (r.verdicts || []).find((v) => v.index === position + 1))
      .filter(Boolean)
    if (!votes.length) {
      unverified.push(finding)
      return
    }
    const refutedCount = votes.filter((v) => v.refuted).length
    // Require a strict majority of returned votes to uphold; ties fail.
    if (refutedCount >= votes.length / 2) return
    upheld.push({ ...finding, refuterVotes: votes.length, refutedBy: refutedCount })
  })
  return { upheld, unverified }
}
// TEST-END verify-budget

function buildReadPlan(files, lineCounts) {
  return files.flatMap((file) => {
    const lines = lineCounts.get(file)
    if (!lines) return [{ file, rangeNote: '', label: `read:${file}` }]

    return Array.from({ length: Math.ceil(lines / SHARD_LINES) }, (_, shard) => {
      const start = shard * SHARD_LINES + 1
      const end = Math.min(start + SHARD_LINES - 1, lines)
      return { file, rangeNote: ` (lines ${start}-${end} of ${lines})`, label: `read:${file}#${shard}` }
    })
  })
}

function readPrompt(file, rangeNote, sinceRefNote) {
  return `Read ${file}${rangeNote} in full.
${sinceRefNote}
Audit this file for coherence within these cross-referenced trees:
src/user/claude_code (CLAUDE.md, skills/**/*.md, agents/*.md, workflows/*.js)
src/user/docket/config (contracts/*.md, fragments/*.md, workflows/*.toml,
policy.toml, schemas/*.json, README.md).

Check for:
1. Internal contradictions: conflicting rules, examples that violate their
   rules, and references to missing steps or sections.
2. Stale references: schema or frozen versions, gate/workflow/executor/skill
   names, contracts, fragments, paths, and relative links. Report the claim;
   leave resolution to the later cross-boundary pass unless a quick grep helps.
3. Terminology: record terms for the human principal, work items, halted/parked
   steps, vote steps, AC statuses, provenance/evidence, and contract actors.
   Report usage for later comparison without judging it.
4. Prose violations: filler, promotional adjectives, edit-history narration
   instead of current behavior, and issue-tracker references outside marked
   evidence citations. If CLAUDE.md is in scope, first read its
   "Prose, simplicity, and harness rules" section.

Do not flag "user" versus "operator" in fragments/prime-directive.md:
it copies the operator's external charter, outside this corpus's style authority.
Do not invent defects. Return empty findings and a one-line note for a clean file.
Set needsOperatorDecision=true for fixes touching schemas/*.json, conflicting
defensible rules with no clear dominant answer, or unexplained deliberate-looking
deviations; otherwise false. Schema fixes cascade to workflows declaring them.
Report linesRead as the spans you read.`
}

async function completeCoverage(files, lineCounts, reports, sinceRefNote) {
  const coverageSummary = reports.map((report) => `${report.file}: ${report.linesRead}`).join('\n')
  const sizeLines = files.map((file) => `${file} ${lineCounts.get(file) || '?'}`).join('\n')
  const critic = await agent(
    `Corpus file sizes (path lineCount; "?" means small and not measured):
${sizeLines}

Spans readers reported:
${coverageSummary}

Files over ${SHARD_LINES} lines need multiple non-overlapping ranges covering their
full length; other files need one full range (e.g. "1-252"). Return each missing file
or uncovered span in a large file as a gap, naming the file and missing range.`,
    { phase: 'Completeness', label: 'completeness-critic', schema: COMPLETENESS_SCHEMA, ...AGENT_CONFIG.coverage }
  )
  // A critic that returned nothing is not a clean critic; the skill treats a
  // throw as "coverage unverified, stop".
  if (!critic) throw new Error('corpus-check: the completeness critic returned nothing; coverage is unverified')
  const gaps = critic.gaps || []
  if (!gaps.length) {
    log('Completeness pass: full coverage confirmed, no gaps')
    return { reports: [], coverageNote: 'No coverage gaps found.' }
  }

  const refillLimit = COMPLETENESS_RESERVE - 1
  const refills = gaps.slice(0, refillLimit)
  const unfilled = gaps.slice(refillLimit)
  log(`Completeness pass found ${gaps.length} gap(s); re-dispatching ${refills.length}`)
  if (unfilled.length) log(`Refill reserve is ${refillLimit}; ${unfilled.length} gap(s) stay UNCOVERED: ${unfilled.map((gap) => `${gap.file} (${gap.range})`).join(', ')}`)
  const gapReads = await pipeline(refills, (gap) =>
    agent(readPrompt(gap.file, ` (lines ${gap.range})`, sinceRefNote), { phase: 'Completeness', label: `refill:${gap.file}`, schema: FINDING_SCHEMA, ...AGENT_CONFIG.refill })
  )
  const describe = (list) => list.map((gap) => `${gap.file} (${gap.range})`).join(', ')
  return {
    reports: gapReads.filter(Boolean),
    coverageNote: `Re-dispatched ${refills.length} gap(s) found by the completeness pass: ${describe(refills)}.`
      + (unfilled.length ? ` UNCOVERED, beyond the refill reserve: ${describe(unfilled)}.` : ''),
  }
}

async function verifyBatch(batch) {
  const listing = batch.items
    .map(({ finding }, position) => `--- Finding ${position + 1}
Location: ${finding.location}
Quote: ${finding.quote}
Counterpart: ${finding.counterpart || '(none stated)'}
Severity: ${finding.severity}
Claimed problem: ${finding.summary}`)
    .join('\n')
  const prompt = `Try to REFUTE each of these ${batch.items.length} corpus coherence finding(s), all in
File: ${batch.file}

${listing}

Read the file once and any named counterpart yourself, then judge every finding
independently and return one verdict per finding number. Default to refuted=true
unless you can confirm both the quoted text and the problem. Refute inaccurate
quotes, misrepresented counterparts, claims consistent under a reasonable
reading, and findings that misunderstand the file's scope. A verdict you omit
counts as no vote, not as a refutation.`
  const returns = await parallel(Array.from({ length: REFUTERS_PER_BATCH }, () => () =>
    agent(prompt, { phase: 'Verify', label: `verify:${batch.file}#${batch.slice}`, schema: BATCH_VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
  ))
  return applyBatchVerdicts(batch, returns)
}

const sinceRef = args?.sinceRef || null
const sinceRefNote = sinceRef
  ? `Context: "${sinceRef}" is informational only. Read this file in full and report every finding, even those predating this ref.\n`
  : ''
if (sinceRef) log(`Staleness hint passed to readers: sinceRef=${sinceRef} (informational only — every file is still read in full)`)

phase('Discover')
const claudeFileList = await agent(
  'List every file under src/user/claude_code matching: CLAUDE.md itself, skills/**/*.md, agents/*.md, workflows/*.js. Return one path per line, repo-relative, nothing else.',
  { phase: 'Discover', label: 'discover:claude_code', ...AGENT_CONFIG.discovery }
)
const docketFileList = await agent(
  'List every file under src/user/docket/config matching: contracts/*.md, fragments/*.md, workflows/*.toml, policy.toml, schemas/*.json, README.md. Return one path per line, repo-relative, nothing else.',
  { phase: 'Discover', label: 'discover:docket_config', ...AGENT_CONFIG.discovery }
)
const files = [...parseLines(claudeFileList), ...parseLines(docketFileList)]
log(`Discovered ${files.length} files across both trees`)

// The workflow cannot inspect files directly.
const sizeReport = await agent(
  `Run: wc -l ${files.join(' ')}
Return only files exceeding ${SHARD_LINES} lines as "path lineCount", one per line.
If none qualify, return an empty string.`,
  { phase: 'Discover', label: 'size-check', ...AGENT_CONFIG.sizing }
)
const largeFiles = parseLines(sizeReport)
  .map((line) => {
    const match = line.match(/^(.+?)\s+(\d+)\s*$/)
    return match ? { file: match[1], lines: parseInt(match[2], 10) } : null
  })
  .filter(Boolean)
const lineCounts = new Map(largeFiles.map(({ file, lines }) => [file, lines]))
if (largeFiles.length) log(`Sharding ${largeFiles.length} large file(s): ${largeFiles.map(({ file, lines }) => `${file} (${lines}L)`).join(', ')}`)

const readPlan = buildReadPlan(files, lineCounts)
const verifyAllowance = verifyBudget(readPlan.length, CROSS_PAIRS.length)
log(`Read plan: ${readPlan.length} agent(s) over ${files.length} file(s); verification allowance ${verifyAllowance} agent(s) (${Math.floor(verifyAllowance / REFUTERS_PER_BATCH)} batches of up to ${VERIFY_BATCH_MAX} findings)`)
if (verifyAllowance < REFUTERS_PER_BATCH) log(`Read plan leaves no verification allowance under the ${AGENT_CAP}-agent cap; every finding will be reported UNVERIFIED`)

phase('Read')
const initialReports = (await pipeline(readPlan, ({ file, rangeNote, label }) =>
  agent(readPrompt(file, rangeNote, sinceRefNote), { phase: 'Read', label, schema: FINDING_SCHEMA, ...AGENT_CONFIG.read })
)).filter(Boolean)

phase('Completeness')
const { reports: refillReports, coverageNote } = await completeCoverage(files, lineCounts, initialReports, sinceRefNote)

phase('Cross-boundary')
const crossReports = await pipeline(CROSS_PAIRS, (pair) =>
  agent(
    `Read both sides in full for cross-boundary consistency:
Side A: ${pair.a}
Side B: ${pair.b}

Report only claims one side makes about the other: stale names, conflicting
rules, or unsupported claims. Other readers cover each side's internal coherence.
Set needsOperatorDecision=true when both readings are defensible or the fix
cascades expensively (e.g. touches schemas/*.json); otherwise false.`,
    { phase: 'Cross-boundary', label: `cross:${pair.key}`, schema: FINDING_SCHEMA, ...AGENT_CONFIG.crossBoundary }
  )
)

const allReports = [...initialReports, ...refillReports, ...crossReports].filter(Boolean)
const rawFindings = allReports.flatMap((report) =>
  (report.findings || []).map((finding) => ({ ...finding, file: report.file }))
)
log(`${rawFindings.length} raw finding(s) before verification`)

if (rawFindings.length) phase('Verify')
const batches = buildVerifyBatches(rawFindings)
const { covered, uncovered } = planVerification(batches, verifyAllowance)
if (uncovered.length) log(`Verification allowance covers ${covered.length} of ${batches.length} batch(es); ${uncovered.reduce((n, b) => n + b.items.length, 0)} finding(s) will be reported UNVERIFIED`)
const results = covered.length ? (await parallel(covered.map((batch) => () => verifyBatch(batch)))).filter(Boolean) : []
const findings = results.flatMap((r) => r.upheld)
const unverified = [
  ...results.flatMap((r) => r.unverified),
  ...uncovered.flatMap((batch) => batch.items.map(({ finding }) => finding)),
]
const verifiedCount = rawFindings.length - unverified.length
if (rawFindings.length) log(`${findings.length}/${verifiedCount} verified finding(s) survived adversarial verification; ${unverified.length} unverified`)

const partial = unverified.length > 0
const verificationNote = partial
  ? `Verification PARTIAL: ${unverified.length} of ${rawFindings.length} raw finding(s) unverified (agent budget or no refuter vote); see the unverified list.`
  : 'Verification complete: every raw finding was judged.'
const summary = rawFindings.length
  ? `${rawFindings.length} raw findings, ${verifiedCount} verified, ${findings.length} survived adversarial verification (${REFUTERS_PER_BATCH} refuters/batch, majority-uphold)${partial ? `; ${unverified.length} UNVERIFIED` : ''}.`
  : 'no findings surfaced.'

return {
  findings,
  unverified,
  filesAudited: files.length,
  readPlanSize: readPlan.length,
  coverageNote: rawFindings.length ? `${coverageNote} ${verificationNote}` : coverageNote,
  rawFindingCount: rawFindings.length,
  verifiedCount,
  survivedCount: findings.length,
  unverifiedCount: unverified.length,
  verificationPartial: partial,
  summary: `${files.length} files audited via ${readPlan.length} read(s); ${summary}`,
}
