export const meta = {
  name: 'tighten',
  description: 'Rewrite prose files for concision chunk by chunk, then verify each chunk mechanically and adversarially before the caller lands it',
  phases: [
    { title: 'Split' },
    { title: 'Rewrite' },
    { title: 'Check' },
    { title: 'Verify' },
    { title: 'Assemble' },
  ],
}

// Called by skills/simplify-corpus/SKILL.md in tighten mode, which resolves
// targets, lands accepted candidates serially in the main session, and owns
// the /loop contract.
//
// args: {
//   files: string[]      repo-relative Markdown paths to tighten
//   scratchDir: string   absolute, writable, empty per pass; candidates land at
//                        `${scratchDir}/${file}` and chunk work under
//                        `${scratchDir}/.chunks/${file}`; the repo file is never written here
//   pass: number         1-based pass counter, informational for labels and prompts
// }
//
// Each file splits into chunks of about CHUNK_LINES lines, cut only at a
// heading or paragraph edge outside fences and frontmatter. Every chunk gets
// its own rewriter, mechanical check, and three refuters, so one bad edit
// costs its chunk, not the file. Accepted chunks join with the untouched rest
// into one candidate, which must pass the whole-file check again.
//
// Mechanical steps run scripts installed beside the simplify-corpus skill,
// through a runner agent that returns their output verbatim, and this file
// parses that output. A missing or unparsable report rejects; no model's
// reading of a diff decides anything here.
//
// Returns { pass, accepted, rejected, unchanged, summary }. `accepted` carries
// one entry per file whose joined candidate shrank and kept every protected
// span, with per-chunk votes and the chunks that did not land; the caller
// copies its `candidate` over `file`. Nothing in the repository changes inside
// this workflow.

// Installed by `just activate` from skills/simplify-corpus/scripts. Unquoted
// in commands so the shell expands `~`.
const SCRIPTS = '~/.claude/skills/simplify-corpus/scripts'

// One rewriter given all 2,105 lines of docket-run cut four filler words. A
// chunk is small enough to read sentence by sentence.
const CHUNK_LINES = 200

// Pin models so the run never inherits the caller's quota-limited model. The
// rewriter runs at high effort: at low effort it searched the file for filler
// words instead of reading it.
const AGENT_CONFIG = {
  run: { model: 'haiku', effort: 'low' },
  rewrite: { model: 'opus', effort: 'high' },
  verify: { model: 'sonnet', effort: 'medium' },
}

// Three refuters on one identical prompt are three correlated votes. Each
// refuter leads from a different angle; a majority is then agreement across
// approaches, not one approach counted three times. Every refuter still judges
// on every ground.
const REFUTER_FRAMINGS = [
  {
    key: 'meaning',
    angle: 'MEANING. Walk the original sentence by sentence and find where each rule, qualification, unit, number, name, and contract detail landed in the candidate. Refute if any was dropped, weakened, strengthened, or added.',
  },
  {
    key: 'reader',
    angle: 'THE READER. Take the file for what it is (a skill, an agent definition, a reference) and ask whether someone following the candidate would act exactly as someone following the original. Refute if a step, condition, exception, or order of operations changed, or if a term of art was replaced by a looser word.',
  },
  {
    key: 'churn',
    angle: 'CHURN. Ask whether the candidate is a genuine tightening or a paraphrase. Refute if it mostly swaps one wording for an equivalent, reorders without shortening, or trades clarity for brevity so a later pass would want to rewrite it back.',
  },
]

const RUN_SCHEMA = {
  type: 'object',
  properties: {
    stdout: { type: 'string', description: 'Everything the command printed, complete and verbatim' },
  },
  required: ['stdout'],
}

const REWRITE_SCHEMA = {
  type: 'object',
  properties: {
    changed: { type: 'boolean', description: 'False when the chunk already satisfies every rule and no edit remains in the copy' },
    summary: { type: 'string', description: 'One line on what was tightened, or why nothing was' },
  },
  required: ['changed', 'summary'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string', description: 'The strongest single ground, quoting the original and candidate lines when refuting' },
  },
  required: ['refuted', 'reason'],
}

// TEST-BEGIN tighten-decide — pure decision helpers, exercised by
// tests/tighten-decide.test.sh without a run.
const UPHOLD_MIN = 2

// A candidate that is not strictly smaller is rejected in code, so a pass over
// already-tight files converges regardless of how eager the rewriter is.
function shrank(check) {
  return check.bytesAfter < check.bytesBefore
}

// Majority uphold over returned votes; a missing vote is no vote, and a
// shortfall rejects, since rejection only leaves the file as it was.
function tallyVotes(returns) {
  const votes = returns.filter(Boolean)
  const upheld = votes.filter((v) => !v.refuted).length
  return { votes: votes.length, upheld, accepted: upheld >= UPHOLD_MIN, reasons: votes.filter((v) => v.refuted).map((v) => v.reason) }
}

function shellQuote(value) {
  return `'${String(value).replace(/'/g, `'\\''`)}'`
}

// The runner appends `echo "exit=$?"`, so the last exit= line is the
// command's status; output without one never ran to the end.
function exitStatus(stdout) {
  const lines = String(stdout || '').split('\n')
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = /^exit=(\d+)$/.exec(lines[i].trim())
    if (m) return Number(m[1])
  }
  return null
}

// Parse protected-spans.sh. Intact needs all of it: exit 0, at least one
// kind line, no changed kind, both size lines, and `result intact`.
function parseSpans(stdout) {
  const text = String(stdout || '')
  const changed = []
  let kinds = 0
  let bytes = null
  let lines = null
  let result = null
  for (const raw of text.split('\n')) {
    const line = raw.trim()
    let m
    if (/^kind \S+ ok$/.test(line)) kinds++
    else if ((m = /^kind (\S+) changed(?::\s*(.*))?$/.exec(line))) {
      kinds++
      changed.push(m[2] ? `${m[1]}: ${m[2]}` : m[1])
    } else if ((m = /^bytes (\d+) (\d+)$/.exec(line))) bytes = [Number(m[1]), Number(m[2])]
    else if ((m = /^lines (\d+) (\d+)$/.exec(line))) lines = [Number(m[1]), Number(m[2])]
    else if ((m = /^result (intact|changed)$/.exec(line))) result = m[1]
  }
  const exit = exitStatus(text)
  const complete = kinds > 0 && bytes !== null && lines !== null && result !== null
  const intact = complete && exit === 0 && result === 'intact' && changed.length === 0
  let problem = ''
  if (!complete) problem = `unparsable check output (exit ${exit === null ? 'missing' : exit})`
  else if (changed.length) problem = `protected span changed: ${changed.join('; ')}`
  else if (!intact) problem = `check failed (exit ${exit === null ? 'missing' : exit}, result ${result})`
  return {
    intact,
    problem,
    bytesBefore: bytes ? bytes[0] : null,
    bytesAfter: bytes ? bytes[1] : null,
    linesBefore: lines ? lines[0] : null,
    linesAfter: lines ? lines[1] : null,
  }
}

// Parse `tighten-chunks.sh split`. The chunks must cover the file from line 1
// with no gap or overlap, and their count must match the closing line.
function parseManifest(stdout) {
  const text = String(stdout || '')
  const chunks = []
  let count = null
  for (const raw of text.split('\n')) {
    const line = raw.trim()
    let m
    if ((m = /^chunk (\d{3,}) lines (\d+)-(\d+) bytes (\d+)$/.exec(line))) {
      chunks.push({ id: m[1], first: Number(m[2]), last: Number(m[3]), bytes: Number(m[4]) })
    } else if ((m = /^chunks (\d+)$/.exec(line))) count = Number(m[1])
  }
  const exit = exitStatus(text)
  if (exit !== 0 || count === null || count !== chunks.length) {
    return { ok: false, chunks: [], problem: `split failed or unparsable (exit ${exit === null ? 'missing' : exit})` }
  }
  for (let i = 0; i < chunks.length; i++) {
    const first = i === 0 ? 1 : chunks[i - 1].last + 1
    if (chunks[i].first !== first || chunks[i].last < chunks[i].first) {
      return { ok: false, chunks: [], problem: `split manifest is not contiguous at chunk ${chunks[i].id}` }
    }
  }
  return { ok: true, chunks, problem: '' }
}

function parseJoin(stdout) {
  const m = /^joined (\d+) chunks, (\d+) rewritten, (\d+) bytes$/m.exec(String(stdout || ''))
  return m ? { total: Number(m[1]), rewritten: Number(m[2]), bytes: Number(m[3]) } : null
}

// A file's next step from its chunks' verdicts: any accepted chunk goes to
// assembly; otherwise a rejected one rejects the file, and all unchanged
// leaves it unchanged. A chunk whose stage threw counts as rejected.
function planAssembly(chunks, outcomes) {
  const verdicts = chunks.map((chunk, i) => outcomes[i] || {
    id: chunk.id,
    lines: `${chunk.first}-${chunk.last}`,
    status: 'rejected',
    reason: 'a stage threw; see the run journal',
  })
  const accepted = verdicts.filter((v) => v.status === 'accepted')
  const rejected = verdicts.filter((v) => v.status === 'rejected')
  const counts = { total: verdicts.length, accepted: accepted.length, rejected: rejected.length, unchanged: verdicts.length - accepted.length - rejected.length }
  const action = accepted.length ? 'assemble' : rejected.length ? 'reject' : 'unchanged'
  return { action, ids: accepted.map((v) => v.id), accepted, rejected, counts }
}
// TEST-END tighten-decide

function candidatePath(scratchDir, file) {
  return `${scratchDir}/${file}`
}

function spansCommand(original, candidate) {
  return `bash ${SCRIPTS}/protected-spans.sh equal ${shellQuote(original)} ${shellQuote(candidate)}`
}

function splitCommand(file, workdir) {
  return `bash ${SCRIPTS}/tighten-chunks.sh split ${shellQuote(file)} ${shellQuote(workdir)} ${CHUNK_LINES}`
}

function assembleCommand(file, workdir, candidate, ids) {
  return `bash ${SCRIPTS}/tighten-chunks.sh join ${shellQuote(workdir)} ${shellQuote(candidate)} ${ids.join(' ')} && ${spansCommand(file, candidate)}`
}

function runPrompt(command) {
  return `Run this one command with the Bash tool, exactly as written, once:

${command}; echo "exit=$?"

Return everything it printed, complete and verbatim, as stdout. Run nothing
else and fix nothing: the caller parses the output, and a retry or a
workaround would hide the failure it needs to see. If the tool refuses the
command, return the refusal as stdout.`
}

function rewritePrompt(file, chunk, orig, cand) {
  return `Tighten the prose in lines ${chunk.first}-${chunk.last} of ${file} (pass ${pass}).

That chunk is copied to ${cand}. Edit that copy in place and write nothing
else. The untouched chunk is ${orig}, and the whole file is ${file}: read
around your chunk when a term or rule in it is defined elsewhere.

Read the whole chunk first, paragraph by paragraph. Then judge every
sentence against the Prose rules in CLAUDE.md: lead with the outcome, one
main idea per sentence, active voice and plain words when equally precise,
cut filler that adds no meaning, remove a sentence or clause that restates
what the chunk already says, replace promotional adjectives with specific
facts. Searching for a list of filler words is not this job; most of the
gain is in restated rules, roundabout phrasing, and clauses that repeat a
neighbor. Preserve every rule, qualification, unit, number, name, and
contract detail. When a sentence cannot be shortened without changing what
it commits to, leave it as it is.

Edit with targeted replacements; never rewrite the chunk from memory, since
everything you do not change must stay byte-identical. Keep the chunk's
trailing blank lines and final newline as they are: the caller joins chunks
end to end.

Protected content, never rewritten; the check rejects the chunk if any of
it differs. Inline code, quotations, references, and links compare after
whitespace collapses, so rewrapping a paragraph around them is fine:
- the YAML frontmatter block, including the description (a trigger
  surface, not prose)
- every fenced code block, heading line, and HTML comment
- every inline code span
- every double-quoted span in prose (trigger phrases, command output,
  quoted rules)
- section references such as §2 or file:line, and relative links with
  their targets

Before returning, run the check yourself:

  ${spansCommand(orig, cand)}

If a kind reports changed, restore that span from the original and run the
check again until it prints "result intact".

Return changed=true when at least one edit remains in the copy. When the
chunk already satisfies every rule, return changed=false with a one-line
summary; do not paraphrase to have something to show.`
}

function verifyPrompt(file, chunk, orig, cand, framing) {
  return `Try to REFUTE this prose rewrite of lines ${chunk.first}-${chunk.last} of ${file}.
Original chunk: ${orig}
Candidate chunk: ${cand}

Start from the word diff, which marks every change:

  git diff --no-index --word-diff=plain ${shellQuote(orig)} ${shellQuote(cand)}

Then read both chunks in full, read around them in ${file} when a change
depends on context, and judge whether the candidate preserves the
original's meaning and is a genuine tightening.

Your angle: ${framing.angle}

Work your angle first and let it lead, but every ground below still
refutes: a dropped or altered rule, qualification, unit, number, name, or
contract detail; a step, condition, or exception a reader would now
follow differently; wording added that the original did not commit to; a
paraphrase that is not shorter or clearer. Default to refuted=true unless
you can confirm the candidate says what the original says, in fewer or
plainer words. Shorter length alone is not a defense. Quote the original
and candidate lines behind your strongest ground.`
}

async function run(command, opts) {
  const out = await agent(runPrompt(command), { schema: RUN_SCHEMA, ...AGENT_CONFIG.run, ...opts })
  return out ? out.stdout : ''
}

async function tightenChunk(file, workdir, chunk) {
  const lines = `${chunk.first}-${chunk.last}`
  const where = `${file}:${lines}`
  const orig = `${workdir}/orig/${chunk.id}.md`
  const cand = `${workdir}/cand/${chunk.id}.md`
  const base = { id: chunk.id, lines }
  const rewrite = await agent(rewritePrompt(file, chunk, orig, cand), { phase: 'Rewrite', label: `rewrite:${where}`, schema: REWRITE_SCHEMA, ...AGENT_CONFIG.rewrite })
  if (!rewrite) return { ...base, status: 'rejected', reason: 'the rewriter returned nothing' }
  if (!rewrite.changed) return { ...base, status: 'unchanged', summary: rewrite.summary }
  const check = parseSpans(await run(spansCommand(orig, cand), { phase: 'Check', label: `check:${where}` }))
  if (!check.intact) return { ...base, status: 'rejected', reason: check.problem }
  if (!shrank(check)) return { ...base, status: 'rejected', reason: `chunk is not smaller (${check.bytesBefore} -> ${check.bytesAfter} bytes)` }
  const returns = await parallel(REFUTER_FRAMINGS.map((framing) => () =>
    agent(verifyPrompt(file, chunk, orig, cand, framing), { phase: 'Verify', label: `verify:${where}:${framing.key}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
  ))
  const tally = tallyVotes(returns)
  if (!tally.accepted) return { ...base, status: 'rejected', reason: `${tally.upheld}/${tally.votes} refuters upheld; ${tally.reasons.join(' | ') || 'no votes returned'}` }
  return { ...base, status: 'accepted', summary: rewrite.summary, refuterVotes: tally.votes, upheldBy: tally.upheld }
}

const files = Array.isArray(args?.files) ? args.files.filter(Boolean) : []
const scratchDir = args?.scratchDir
const pass = args?.pass || 1
if (!files.length) throw new Error('tighten: args.files is empty; the skill resolves targets before launching')
if (!scratchDir || !scratchDir.startsWith('/')) throw new Error('tighten: args.scratchDir must be an absolute path')

const workdirOf = (file) => `${scratchDir}/.chunks/${file}`

log(`Pass ${pass}: ${files.length} file(s) in chunks of about ${CHUNK_LINES} lines, one rewriter and ${REFUTER_FRAMINGS.length} refuters per chunk; candidates under ${scratchDir}`)

const results = await pipeline(
  files,
  async (file) => {
    const manifest = parseManifest(await run(splitCommand(file, workdirOf(file)), { phase: 'Split', label: `split:${file}` }))
    if (!manifest.ok) return { file, status: 'rejected', reason: manifest.problem }
    if (!manifest.chunks.length) return { file, status: 'unchanged', summary: 'the file is empty' }
    return { file, status: 'split', chunks: manifest.chunks }
  },
  async (split, file) => {
    if (!split || split.status !== 'split') return split
    const workdir = workdirOf(file)
    const outcomes = await parallel(split.chunks.map((chunk) => () => tightenChunk(file, workdir, chunk)))
    const plan = planAssembly(split.chunks, outcomes)
    const rejectedChunks = plan.rejected.map(({ lines, reason }) => ({ lines, reason }))
    if (plan.action === 'unchanged') return { file, status: 'unchanged', summary: `all ${plan.counts.total} chunk(s) already tight`, chunks: plan.counts }
    if (plan.action === 'reject') return { file, status: 'rejected', reason: rejectedChunks.map((c) => `lines ${c.lines}: ${c.reason}`).join(' || '), chunks: plan.counts }
    const candidate = candidatePath(scratchDir, file)
    const out = await run(assembleCommand(file, workdir, candidate, plan.ids), { phase: 'Assemble', label: `assemble:${file}` })
    const joined = parseJoin(out)
    if (!joined || joined.rewritten !== plan.ids.length) return { file, status: 'rejected', reason: `assembly failed (exit ${exitStatus(out) ?? 'missing'})`, chunks: plan.counts }
    const check = parseSpans(out)
    if (!check.intact) return { file, status: 'rejected', reason: `joined candidate failed the whole-file check: ${check.problem}`, chunks: plan.counts }
    if (!shrank(check)) return { file, status: 'rejected', reason: `joined candidate is not smaller (${check.bytesBefore} -> ${check.bytesAfter} bytes)`, chunks: plan.counts }
    return {
      file,
      status: 'accepted',
      candidate,
      summary: plan.accepted.map((c) => `lines ${c.lines}: ${c.summary}`).join('; '),
      bytesBefore: check.bytesBefore,
      bytesAfter: check.bytesAfter,
      linesBefore: check.linesBefore,
      linesAfter: check.linesAfter,
      chunks: plan.counts,
      chunkVotes: plan.accepted.map(({ lines, upheldBy, refuterVotes }) => ({ lines, upheldBy, refuterVotes })),
      rejectedChunks,
    }
  }
)

const outcomes = results.filter(Boolean)
const dropped = files.filter((file) => !outcomes.some((o) => o.file === file))
const accepted = outcomes.filter((o) => o.status === 'accepted')
const rejected = [
  ...outcomes.filter((o) => o.status === 'rejected'),
  ...dropped.map((file) => ({ file, status: 'rejected', reason: 'a stage threw; see the run journal' })),
]
const unchanged = outcomes.filter((o) => o.status === 'unchanged')
if (dropped.length) log(`${dropped.length} file(s) dropped by a thrown stage: ${dropped.join(', ')}`)

const chunkTotal = outcomes.reduce((n, o) => n + (o.chunks ? o.chunks.total : 0), 0)
const chunksLanded = accepted.reduce((n, o) => n + o.chunks.accepted, 0)
const savedBytes = accepted.reduce((n, o) => n + (o.bytesBefore - o.bytesAfter), 0)
const summary = `Pass ${pass}: ${files.length} file(s), ${chunkTotal} chunk(s); ${accepted.length} file(s) accepted (${chunksLanded} chunk(s), ${savedBytes} bytes removed), ${rejected.length} rejected, ${unchanged.length} unchanged; ${REFUTER_FRAMINGS.length} refuters per chunk (${REFUTER_FRAMINGS.map((f) => f.key).join(', ')}), ${UPHOLD_MIN} upholds to accept.`
log(summary)

return { pass, accepted, rejected, unchanged, summary }
