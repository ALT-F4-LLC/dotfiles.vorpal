export const meta = {
  name: 'docket-cli-audit',
  description: 'Audit every file under src/user that names a docket command against the installed binary: per-file reads over the refreshed inventory and runtime fixtures, a completeness sweep, then adversarial verification',
  phases: [
    { title: 'Read' },
    { title: 'Completeness' },
    { title: 'Verify' },
  ],
}

// Called by skills/docket-cli-audit/SKILL.md, which refreshes the evidence,
// discovers the files, and lands the fixes. The workflow reads nothing itself.
// args: {
//   files: string[]            repo-relative files that name a docket command
//   evidence: {
//     digest: string           path to the Markdown digest of the fixtures
//     inventoryDiff: string    path to the unified diff of cli-inventory.json (old -> installed), or ''
//     fixturesDiff: string     path to the unified diff of cli-fixtures.json (old -> installed), or ''
//     inventory: string        repo-relative path of cli-inventory.json
//     fixtures: string         repo-relative path of cli-fixtures.json
//     binaryVersion: string    the installed binary's --version line
//     previousVersion: string  the version the inventory recorded before the refresh
//   }
//   protectedFiles: string[]   files whose findings are report-only (still read, never fixed)
// }

const AGENT_CONFIG = {
  sizing: { model: 'haiku', effort: 'low' },
  read: { model: 'sonnet', effort: 'medium' },
  coverage: { model: 'opus', effort: 'low' },
  refill: { model: 'sonnet', effort: 'medium' },
  verify: { model: 'sonnet', effort: 'low' },
}

const SHARD_LINES = 1500
const AGENT_CAP = 1000
const AGENT_CAP_MARGIN = 10
const SIZING_AGENTS = 1
const COMPLETENESS_RESERVE = 1 + 8
const VERIFY_BATCH_MAX = 12

// Each refuter leads from a different angle so a majority is agreement across
// approaches, not one approach counted three times (the corpus-check design).
const REFUTER_FRAMINGS = [
  {
    key: 'quote',
    angle: 'the QUOTED TEXT. Open the file at the stated location and confirm the quote is there verbatim and that it makes the claim the finding says it makes.',
  },
  {
    key: 'evidence',
    angle: 'the EVIDENCE. Check the inventory JSON and the fixtures JSON yourself (grep by command path or record id). Does the installed binary really behave as the finding says, and does that really contradict the prose? A finding whose evidence you cannot locate is unsupported.',
  },
  {
    key: 'reading',
    angle: 'the READING. Ask what the passage is for. Would a reader who knows the file\'s purpose see the prose as wrong, or is it a fair description at its level of detail, an intentional abstraction, or a historical note marked as such?',
  },
]
const REFUTERS_PER_BATCH = REFUTER_FRAMINGS.length

const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    file: { type: 'string' },
    linesRead: { type: 'string', description: 'Spans read, e.g. "1-390" or "1-1500,1501-3116"' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          location: { type: 'string', description: 'file:line or file:line-range' },
          quote: { type: 'string', description: 'The prose as written, verbatim' },
          claim: { type: 'string', description: 'What the prose asserts about the CLI, in one sentence' },
          evidence: { type: 'string', description: 'Where the inventory or fixtures contradict it: command path, flag, record id, or diff hunk' },
          kind: { type: 'string', enum: ['mechanical', 'semantic'], description: 'mechanical: a renamed, removed, or added command, flag, alias, or default. semantic: a described behavior, output shape, message, or exit code that no longer matches' },
          severity: { type: 'string', enum: ['wrong', 'stale', 'missing', 'style'] },
          summary: { type: 'string' },
          proposedFix: { type: 'string', description: 'The replacement prose, or "report only" for a protected file' },
          needsOperatorDecision: { type: 'boolean', description: 'True when two readings are defensible, the fix changes a rule rather than a description, or the file is protected' },
        },
        required: ['location', 'quote', 'claim', 'evidence', 'kind', 'severity', 'summary', 'proposedFix', 'needsOperatorDecision'],
      },
    },
    notes: { type: 'string', description: 'Commands the file names that checked out, or observations without a finding' },
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
function verifyBudget(readPlanSize) {
  return Math.max(0, AGENT_CAP - AGENT_CAP_MARGIN - SIZING_AGENTS - readPlanSize - COMPLETENESS_RESERVE)
}

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

function planVerification(batches, budget) {
  const affordable = Math.floor(budget / REFUTERS_PER_BATCH)
  return { covered: batches.slice(0, affordable), uncovered: batches.slice(affordable) }
}

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

function evidenceNote(evidence, protectedFiles) {
  const diffs = [
    evidence.inventoryDiff ? `Help-surface diff (old inventory -> installed): ${evidence.inventoryDiff}` : 'Help-surface diff: none (the inventory already matched the installed binary).',
    evidence.fixturesDiff ? `Runtime-fixture diff (old fixtures -> installed): ${evidence.fixturesDiff}` : 'Runtime-fixture diff: none (first sweep, or the fixtures already matched).',
  ]
  return `The installed binary is ${evidence.binaryVersion}; the prose was last checked against ${evidence.previousVersion || 'an unrecorded version'}.
Evidence, all read-only:
- Digest of every command's recorded behavior (read this first, in full): ${evidence.digest}
- Help surface, exact commands/aliases/flags/defaults: ${evidence.inventory} (grep by "command": "docket ...")
- Runtime fixtures, exact exit codes, JSON shapes, messages: ${evidence.fixtures} (grep by record id from the digest, or by argv). The sweep ran with NO_COLOR=1 and TERM=dumb, which strip the status glyphs (✔, ✘) from human output; a hook sees them, so a missing glyph in a fixture is not evidence against prose that quotes one.
- ${diffs.join('\n- ')}
Protected files (report findings, never propose an edit; set proposedFix to "report only" and needsOperatorDecision to true): ${protectedFiles.join(', ') || 'none'}.`
}

function readPrompt(file, rangeNote, note) {
  return `Read ${file}${rangeNote} in full.

${note}

Audit every claim this file makes about the docket CLI against that evidence:
1. Command paths, subcommand names, aliases (e.g. \`step record\`), flags, short
   flags, flag values and defaults. A name the inventory does not list, or a
   flag the command does not take, is a MECHANICAL finding.
2. Behavior: exit codes and their error \`code\` values (NOT_FOUND, CONFLICT,
   VALIDATION_ERROR, AUTH_ERROR, GENERAL_ERROR), guard exit semantics, JSON
   envelope and \`data\` shapes under both \`--json\` (v1) and \`--format json\` (v2),
   human-readable messages quoted as if literal, required flags, and what a
   verb refuses. A described behavior the fixtures contradict is a SEMANTIC
   finding; cite the record id.
3. Version-stamped statements ("checked against nightly-N", "covers N
   commands", "as of <date>") that are now behind the installed binary.
4. A behavior the fixtures show that the file's own scope should describe but
   omits, when the omission would mislead a reader (severity "missing"). Do not
   pad: an omission is a finding only when the file already tries to document
   that verb.

Rules:
- Quote the prose verbatim with its line. Cite the evidence precisely. A claim
  you cannot check against the evidence is not a finding; note it in notes.
- A claim about a verb the sweep skipped (see the digest) cannot be checked at
  runtime; say so in notes rather than guessing.
- Comments and strings inside .rs, .js, .sh and .toml files count as prose when
  they describe a docket command (a permission row naming a verb, a hook that
  parses an output shape, a script that passes a flag). Code that PASSES a flag
  the binary no longer takes is mechanical and must be reported.
- Do not flag prose that describes engine or workflow semantics the CLI merely
  exposes (routing rules, gate policy, contract wording) unless it names a
  command, flag, exit code, message, or JSON field that the evidence contradicts.
- Do not invent defects. Return empty findings and a one-line note for a clean
  file, listing which commands it names and that they checked out.
Report linesRead as the spans you read.`
}

async function completeCoverage(files, lineCounts, reports, note) {
  const coverageSummary = reports.map((report) => `${report.file}: ${report.linesRead}`).join('\n')
  const sizeLines = files.map((file) => `${file} ${lineCounts.get(file) || '?'}`).join('\n')
  const critic = await agent(
    `File sizes (path lineCount; "?" means under ${SHARD_LINES} lines and not measured):
${sizeLines}

Spans readers reported:
${coverageSummary}

Files over ${SHARD_LINES} lines need multiple non-overlapping ranges covering their
full length; other files need one full range. Return each missing file or
uncovered span as a gap, naming the file and missing range.`,
    { phase: 'Completeness', label: 'completeness-critic', schema: COMPLETENESS_SCHEMA, ...AGENT_CONFIG.coverage }
  )
  if (!critic) throw new Error('docket-cli-audit: the completeness critic returned nothing; coverage is unverified')
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
    agent(readPrompt(gap.file, ` (lines ${gap.range})`, note), { phase: 'Completeness', label: `refill:${gap.file}`, schema: FINDING_SCHEMA, ...AGENT_CONFIG.refill })
  )
  const describe = (list) => list.map((gap) => `${gap.file} (${gap.range})`).join(', ')
  return {
    reports: gapReads.filter(Boolean),
    coverageNote: `Re-dispatched ${refills.length} gap(s) found by the completeness pass: ${describe(refills)}.`
      + (unfilled.length ? ` UNCOVERED, beyond the refill reserve: ${describe(unfilled)}.` : ''),
  }
}

async function verifyBatch(batch, note) {
  const listing = batch.items
    .map(({ finding }, position) => `--- Finding ${position + 1}
Location: ${finding.location}
Quote: ${finding.quote}
Claim: ${finding.claim}
Evidence cited: ${finding.evidence}
Kind/severity: ${finding.kind}/${finding.severity}
Claimed problem: ${finding.summary}
Proposed fix: ${finding.proposedFix}`)
    .join('\n')
  const prompt = (framing) => `Try to REFUTE each of these ${batch.items.length} finding(s) about docket CLI prose, all in
File: ${batch.file}

${note}

${listing}

Your angle: ${framing.angle}

Read the file once and the cited evidence yourself, then judge every finding
independently and return one verdict per finding number. Work your angle first
and let it lead, but every ground below still refutes. Default to refuted=true
unless you can confirm both the quoted text and the contradiction. Refute
inaccurate quotes, evidence that does not say what the finding claims, claims
consistent under a reasonable reading, findings that misunderstand the file's
scope, and proposed fixes that would themselves be wrong against the evidence.
A verdict you omit counts as no vote, not as a refutation.`
  const returns = await parallel(REFUTER_FRAMINGS.map((framing) => () =>
    agent(prompt(framing), { phase: 'Verify', label: `verify:${batch.file}#${batch.slice}:${framing.key}`, schema: BATCH_VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
  ))
  return applyBatchVerdicts(batch, returns)
}

const files = Array.isArray(args?.files) ? args.files.filter(Boolean) : []
if (!files.length) throw new Error('docket-cli-audit: args.files is empty; the skill discovers the files before launching')
const evidence = args?.evidence || {}
for (const key of ['digest', 'inventory', 'fixtures', 'binaryVersion']) {
  if (!evidence[key]) throw new Error(`docket-cli-audit: args.evidence.${key} is required`)
}
const protectedFiles = Array.isArray(args?.protectedFiles) ? args.protectedFiles : []
const note = evidenceNote(evidence, protectedFiles)
log(`Auditing ${files.length} file(s) against ${evidence.binaryVersion}`)

phase('Read')
const sizeReport = await agent(
  `Run: wc -l ${files.join(' ')}
Return only files exceeding ${SHARD_LINES} lines as "path lineCount", one per line.
If none qualify, return an empty string.`,
  { phase: 'Read', label: 'size-check', ...AGENT_CONFIG.sizing }
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
const verifyAllowance = verifyBudget(readPlan.length)
log(`Read plan: ${readPlan.length} agent(s) over ${files.length} file(s); verification allowance ${verifyAllowance} agent(s)`)

const initialReports = (await pipeline(readPlan, ({ file, rangeNote, label }) =>
  agent(readPrompt(file, rangeNote, note), { phase: 'Read', label, schema: FINDING_SCHEMA, ...AGENT_CONFIG.read })
)).filter(Boolean)

phase('Completeness')
const { reports: refillReports, coverageNote } = await completeCoverage(files, lineCounts, initialReports, note)

const allReports = [...initialReports, ...refillReports].filter(Boolean)
const rawFindings = allReports.flatMap((report) =>
  (report.findings || []).map((finding) => ({ ...finding, file: report.file }))
)
const cleanNotes = allReports.filter((report) => !(report.findings || []).length && report.notes).map((report) => `${report.file}: ${report.notes}`)
log(`${rawFindings.length} raw finding(s) before verification`)

if (rawFindings.length) phase('Verify')
const batches = buildVerifyBatches(rawFindings)
const { covered, uncovered } = planVerification(batches, verifyAllowance)
if (uncovered.length) log(`Verification allowance covers ${covered.length} of ${batches.length} batch(es); ${uncovered.reduce((n, b) => n + b.items.length, 0)} finding(s) will be reported UNVERIFIED`)
const results = covered.length ? (await parallel(covered.map((batch) => () => verifyBatch(batch, note)))).filter(Boolean) : []
const findings = results.flatMap((r) => r.upheld)
const unverified = [
  ...results.flatMap((r) => r.unverified),
  ...uncovered.flatMap((batch) => batch.items.map(({ finding }) => finding)),
]
const verifiedCount = rawFindings.length - unverified.length
if (rawFindings.length) log(`${findings.length}/${verifiedCount} verified finding(s) survived adversarial verification; ${unverified.length} unverified`)

const partial = unverified.length > 0
const verificationNote = partial
  ? `Verification PARTIAL: ${unverified.length} of ${rawFindings.length} raw finding(s) unverified.`
  : 'Verification complete: every raw finding was judged.'
const summary = rawFindings.length
  ? `${rawFindings.length} raw findings, ${verifiedCount} verified, ${findings.length} survived (${REFUTERS_PER_BATCH} refuters/batch: ${REFUTER_FRAMINGS.map((f) => f.key).join(', ')}; majority-uphold)${partial ? `; ${unverified.length} UNVERIFIED` : ''}.`
  : 'no findings surfaced.'

return {
  findings,
  unverified,
  cleanNotes,
  filesAudited: files.length,
  readPlanSize: readPlan.length,
  coverageNote: rawFindings.length ? `${coverageNote} ${verificationNote}` : coverageNote,
  rawFindingCount: rawFindings.length,
  verifiedCount,
  survivedCount: findings.length,
  unverifiedCount: unverified.length,
  verificationPartial: partial,
  summary: `${files.length} files audited via ${readPlan.length} read(s) against ${evidence.binaryVersion}; ${summary}`,
}
