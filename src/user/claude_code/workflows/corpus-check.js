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
  discovery: { model: 'sonnet', effort: 'low' },
  sizing: { model: 'sonnet', effort: 'low' },
  read: { model: 'opus', effort: 'high' },
  coverage: { model: 'sonnet', effort: 'low' },
  refill: { model: 'opus', effort: 'high' },
  crossBoundary: { model: 'opus', effort: 'high' },
  verify: { model: 'sonnet', effort: 'low' },
}

const SHARD_LINES = 1500
const REFUTERS_PER_FINDING = 3

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

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['refuted', 'reason'],
}

function parseLines(text) {
  return (text || '')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
}

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
  const gaps = critic?.gaps || []
  if (!gaps.length) {
    log('Completeness pass: full coverage confirmed, no gaps')
    return { reports: [], coverageNote: 'No coverage gaps found.' }
  }

  log(`Completeness pass found ${gaps.length} gap(s); re-dispatching`)
  const gapReads = await pipeline(gaps, (gap) =>
    agent(readPrompt(gap.file, ` (lines ${gap.range})`, sinceRefNote), { phase: 'Completeness', label: `refill:${gap.file}`, schema: FINDING_SCHEMA, ...AGENT_CONFIG.refill })
  )
  return {
    reports: gapReads.filter(Boolean),
    coverageNote: `Re-dispatched ${gaps.length} gap(s) found by the completeness pass: ${gaps.map((gap) => `${gap.file} (${gap.range})`).join(', ')}.`,
  }
}

async function verifyFinding(finding) {
  const prompt = `Try to REFUTE this corpus coherence finding:
File: ${finding.file}
Location: ${finding.location}
Quote: ${finding.quote}
Counterpart: ${finding.counterpart || '(none stated)'}
Severity: ${finding.severity}
Claimed problem: ${finding.summary}

Read the file and any named counterpart yourself. Default to refuted=true
unless you can confirm both the quoted text and the problem. Refute inaccurate
quotes, misrepresented counterparts, claims consistent under a reasonable
reading, and findings that misunderstand the file's scope.`
  const votes = await parallel(Array.from({ length: REFUTERS_PER_FINDING }, () => () =>
    agent(prompt, { phase: 'Verify', label: `verify:${finding.file}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
  ))
  const castVotes = votes.filter(Boolean)
  const refutedCount = castVotes.filter((vote) => vote.refuted).length
  // Require a strict majority of returned votes to uphold; ties and no votes fail.
  if (refutedCount >= castVotes.length / 2) return null
  return { ...finding, refuterVotes: castVotes.length, refutedBy: refutedCount }
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
log(`Read plan: ${readPlan.length} agent(s) over ${files.length} file(s)`)

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
const findings = rawFindings.length
  ? (await parallel(rawFindings.map((finding) => () => verifyFinding(finding)))).filter(Boolean)
  : []
if (rawFindings.length) log(`${findings.length}/${rawFindings.length} finding(s) survived adversarial verification`)

const summary = rawFindings.length
  ? `${rawFindings.length} raw findings, ${findings.length} survived adversarial verification (${REFUTERS_PER_FINDING} refuters/finding, majority-uphold).`
  : 'no findings surfaced.'

return {
  findings,
  filesAudited: files.length,
  readPlanSize: readPlan.length,
  coverageNote,
  rawFindingCount: rawFindings.length,
  survivedCount: findings.length,
  summary: `${files.length} files audited via ${readPlan.length} read(s); ${summary}`,
}
