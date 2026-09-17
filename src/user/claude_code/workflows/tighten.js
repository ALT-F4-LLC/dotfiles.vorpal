export const meta = {
  name: 'tighten',
  description: 'Rewrite prose files for concision, then verify each candidate mechanically and adversarially before the caller lands it',
  phases: [
    { title: 'Rewrite' },
    { title: 'Check' },
    { title: 'Verify' },
  ],
}

// Called by skills/tighten/SKILL.md, which resolves targets, lands accepted
// candidates serially in the main session, and owns the /loop contract.
//
// args: {
//   files: string[]      repo-relative Markdown paths to tighten, one rewriter each
//   scratchDir: string   absolute, writable, empty per pass; candidates land at
//                        `${scratchDir}/${file}`; the repo file is never written here
//   pass: number         1-based pass counter, informational for labels and prompts
// }
//
// Returns { accepted, rejected, unchanged, summary }. `accepted` carries one
// entry per candidate that shrank the file, kept every protected span intact,
// and survived a majority of three refuters; the caller copies its `candidate`
// over `file`. Nothing in the repository changes inside this workflow.

// Pin models so the run never inherits the caller's quota-limited model.
const AGENT_CONFIG = {
  rewrite: { model: 'opus', effort: 'low' },
  check: { model: 'haiku', effort: 'low' },
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
const REWRITE_SCHEMA = {
  type: 'object',
  properties: {
    file: { type: 'string' },
    changed: { type: 'boolean', description: 'False when the file already satisfies every rule and no candidate was written' },
    candidate: { type: 'string', description: 'Absolute path of the candidate written, or empty string when changed is false' },
    summary: { type: 'string', description: 'One line on what was tightened, or why nothing was' },
  },
  required: ['file', 'changed', 'candidate', 'summary'],
}

const CHECK_SCHEMA = {
  type: 'object',
  properties: {
    intact: { type: 'boolean', description: 'True only when every protected span compares byte-equal' },
    differences: { type: 'array', items: { type: 'string' }, description: 'One line per protected span that differs, naming the span kind and the first differing line' },
    bytesBefore: { type: 'integer' },
    bytesAfter: { type: 'integer' },
    linesBefore: { type: 'integer' },
    linesAfter: { type: 'integer' },
  },
  required: ['intact', 'differences', 'bytesBefore', 'bytesAfter', 'linesBefore', 'linesAfter'],
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
// TEST-END tighten-decide

function candidatePath(scratchDir, file) {
  return `${scratchDir}/${file}`
}

function rewritePrompt(file, candidate, pass) {
  return `Tighten the prose in ${file} (pass ${pass}).

Read the file in full. Apply the Prose rules in CLAUDE.md to its prose:
lead with the outcome, one main idea per sentence, active voice and plain
words when equally precise, cut filler that adds no meaning, remove
repetition, replace promotional adjectives with specific facts. Preserve
every technical term, qualification, unit, number, name, and contract
detail. When a sentence cannot be shortened without changing what it
commits to, leave it as it is.

Work by copying, then editing in place: mkdir -p the candidate's parent,
cp ${file} ${candidate}, then apply targeted edits to the candidate.
Never regenerate the whole file from memory; everything you do not touch
must stay byte-identical, and a long file written in one go truncates.

Protected content, never rewritten; a mechanical diff rejects the whole
candidate if any of it differs. Frontmatter, fences, headings, and HTML
comments compare line by line; the other spans compare after collapsing
whitespace, so rewrapping a paragraph around them is fine:
- the YAML frontmatter block (including the description; it is a trigger
  surface, not prose)
- every fenced code block at any indentation, and every inline code span
- every heading line (other files link to them as anchors)
- section references such as §2 or file:line
- every double-quoted span (trigger phrases, command output, quoted rules)
- relative links and their targets
- every HTML comment, from <!-- to -->

When at least one edit landed in ${candidate}, return changed=true with
its path. Never write to ${file} itself. If the file already satisfies
every rule and no sentence improves, remove the candidate copy and return
changed=false with a one-line summary; do not produce a paraphrase to
have something to show.`
}

function checkPrompt(file, candidate) {
  return `Compare the protected spans of two Markdown files mechanically.
Original: ${file}
Candidate: ${candidate}

For each span kind below, run its extractor on both files and diff the two
outputs in one bash command, printing the exit code:

  diff <(path="${file}"; <extractor>) <(path="${candidate}"; <extractor>); echo "exit $?"

Extractors ($path is the file under test). Kinds 1, 2, 4, and 8 are
line-based and byte-protected. Kinds 3, 5, 6, and 7 are spans that may wrap
across lines, and tightening rewraps paragraphs, so collapse every run of
whitespace to one space before extracting them:
1. frontmatter: awk 'NR==1 && $0=="---"{f=1; print; next} f{print} f && $0=="---"{exit}' "$path"
2. fenced blocks, any indentation: awk '/^[[:space:]]*\`\`\`/{f=!f; print; next} f{print}' "$path"
3. inline code spans: tr -s '[:space:]' ' ' < "$path" | grep -o '\`[^\`]*\`' | sort
4. headings: grep -E '^#{1,6} ' "$path"
5. section and line references: tr -s '[:space:]' ' ' < "$path" | grep -oE '§[0-9]+|[A-Za-z0-9_./-]+\\.(md|js|sh|toml|json):[0-9]+' | sort
6. relative links: tr -s '[:space:]' ' ' < "$path" | grep -oE '\\]\\([^)]+\\)' | sort
7. double-quoted spans: tr -s '[:space:]' ' ' < "$path" | grep -oE '"[^"]+"' | sort
8. HTML comments: awk '/<!--/{f=1} f{print} /-->/{f=0}' "$path"

Then measure both files with wc -c and wc -l.

Report intact=true only when all eight diffs printed nothing and exited 0.
For every nonzero exit, add one difference line naming the span kind and
the first line diff printed. You compare exit codes and diff output, not
the files by eye; do not judge the prose, that is another agent's job.`
}

function verifyPrompt(file, candidate, framing) {
  return `Try to REFUTE this prose rewrite.
Original: ${file}
Candidate: ${candidate}

Read both in full, then judge whether the candidate preserves the
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

const files = Array.isArray(args?.files) ? args.files.filter(Boolean) : []
const scratchDir = args?.scratchDir
const pass = args?.pass || 1
if (!files.length) throw new Error('tighten: args.files is empty; the skill resolves targets before launching')
if (!scratchDir || !scratchDir.startsWith('/')) throw new Error('tighten: args.scratchDir must be an absolute path')

log(`Pass ${pass}: ${files.length} file(s), one rewriter each; candidates under ${scratchDir}`)

phase('Rewrite')
const results = await pipeline(
  files,
  (file) => agent(rewritePrompt(file, candidatePath(scratchDir, file), pass), { phase: 'Rewrite', label: `rewrite:${file}`, schema: REWRITE_SCHEMA, ...AGENT_CONFIG.rewrite }),
  async (rewrite, file) => {
    if (!rewrite) return { file, status: 'rejected', reason: 'the rewriter returned nothing' }
    if (!rewrite.changed) return { file, status: 'unchanged', summary: rewrite.summary }
    const candidate = rewrite.candidate || candidatePath(scratchDir, file)
    const check = await agent(checkPrompt(file, candidate), { phase: 'Check', label: `check:${file}`, schema: CHECK_SCHEMA, ...AGENT_CONFIG.check })
    if (!check) return { file, status: 'rejected', reason: 'the protected-span check returned nothing' }
    if (!check.intact) return { file, status: 'rejected', reason: `protected span changed: ${check.differences.join('; ')}` }
    if (!shrank(check)) return { file, status: 'rejected', reason: `candidate is not smaller (${check.bytesBefore} -> ${check.bytesAfter} bytes)` }
    return { file, status: 'checked', candidate, check, summary: rewrite.summary }
  },
  async (checked, file) => {
    if (!checked || checked.status !== 'checked') return checked
    const returns = await parallel(REFUTER_FRAMINGS.map((framing) => () =>
      agent(verifyPrompt(file, checked.candidate, framing), { phase: 'Verify', label: `verify:${file}:${framing.key}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
    ))
    const tally = tallyVotes(returns)
    if (!tally.accepted) return { file, status: 'rejected', reason: `${tally.upheld}/${tally.votes} refuters upheld; ${tally.reasons.join(' | ') || 'no votes returned'}` }
    return {
      file,
      status: 'accepted',
      candidate: checked.candidate,
      summary: checked.summary,
      bytesBefore: checked.check.bytesBefore,
      bytesAfter: checked.check.bytesAfter,
      linesBefore: checked.check.linesBefore,
      linesAfter: checked.check.linesAfter,
      refuterVotes: tally.votes,
      upheldBy: tally.upheld,
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

const savedBytes = accepted.reduce((n, o) => n + (o.bytesBefore - o.bytesAfter), 0)
const summary = `Pass ${pass}: ${files.length} file(s); ${accepted.length} accepted (${savedBytes} bytes removed), ${rejected.length} rejected, ${unchanged.length} unchanged; ${REFUTER_FRAMINGS.length} refuters per candidate (${REFUTER_FRAMINGS.map((f) => f.key).join(', ')}), ${UPHOLD_MIN} upholds to accept.`
log(summary)

return { pass, accepted, rejected, unchanged, summary }
