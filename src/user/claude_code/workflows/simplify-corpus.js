export const meta = {
  name: 'simplify-corpus',
  description: 'Apply the simplify review to whole corpus files, then verify each candidate mechanically and adversarially before the caller lands it',
  phases: [
    { title: 'Simplify' },
    { title: 'Check' },
    { title: 'Verify' },
  ],
}

// Called by skills/simplify-corpus/SKILL.md, which resolves targets, lands
// accepted candidates serially in the main session, and owns the /loop
// contract.
//
// args: {
//   files: string[]      repo-relative paths to simplify, one simplifier each;
//                        any file type the skill admits (Markdown, JS, Python,
//                        shell, Rust, TOML, extensionless scripts)
//   scratchDir: string   absolute, writable, empty per pass; candidates land at
//                        `${scratchDir}/${file}`; the repo file is never written here
//   pass: number         1-based pass counter, informational for labels and prompts
// }
//
// Returns { accepted, rejected, unchanged, summary }. `accepted` carries one
// entry per candidate that shrank the file, passed its kind's mechanical
// check, and survived a majority of three refuters; the caller copies its
// `candidate` over `file`. An entry with `confirm: true` (settings.rs) is
// landed only after the operator confirms it; an entry with `versioned: true`
// (docket contracts, fragments, workflow TOML) carries the version bump the
// frozen-drift-check gate demands. Nothing in the repository changes inside
// this workflow.
//
// How the simplify skill is used. The built-in simplify skill reviews changed
// code for reuse, simplification, efficiency, and altitude and applies the
// fixes; its instructions were not read when this script was written, so
// whether it takes a file target is learned by the simplifier that loads it.
// Each simplifier copies its file into the scratch mirror and, when the Skill
// tool is available, invokes simplify there with the untracked candidate as
// the change under review. When the tool is unavailable, or the skill's
// instructions would have it diff or edit the checkout, the simplifier applies
// the same four criteria itself. Either way the candidate is the only file
// written.
//
// Verification. Every candidate must be strictly smaller (the convergence
// rule: a pass over already-simple files lands nothing) and pass a
// kind-specific mechanical check: a syntax parse for code, a protected-span
// subset diff for Markdown (a simplifier may delete protected content but
// never invent or alter it), and a strictly-greater version for versioned
// docket files. simplify-check.sh runs all of it, a runner agent returns its
// report verbatim, and this file parses the report; a missing or unparsable
// report rejects. Survivors face three refuters leading from different
// angles (behavior or meaning, the reader or caller, churn); two upholds
// accept. Behavior preservation is judged, not proven: the skill's landing
// gates (test suites naming the file, self-hygiene for Rust, the module parse
// gate for workflow scripts) are the mechanical backstop.

// Installed by `just activate` from skills/simplify-corpus/scripts. Unquoted
// in commands so the shell expands `~`.
const SCRIPTS = '~/.claude/skills/simplify-corpus/scripts'

// Pin models so the run never inherits the caller's quota-limited model.
const AGENT_CONFIG = {
  simplify: { model: 'opus', effort: 'medium' },
  check: { model: 'sonnet', effort: 'high' },
  verify: { model: 'sonnet', effort: 'high' },
}

// TEST-BEGIN simplify-corpus-decide — pure decision helpers, exercised by
// tests/simplify-corpus-decide.test.sh without a run.
const UPHOLD_MIN = 2

// One kind per file decides which prompt, which mechanical check, and which
// landing rule apply. `data` files (JSON fixtures, signing keys) are never
// targets; the skill drops them before launching, and the script rejects any
// that arrive.
function classify(file) {
  const base = file.slice(file.lastIndexOf('/') + 1)
  const ext = base.includes('.') ? base.slice(base.lastIndexOf('.') + 1) : ''
  const docketConfig = file.startsWith('src/user/docket/config/')
  if (file === 'src/user/claude_code/settings.rs') return { kind: 'rust', confirm: true, versioned: false }
  if (docketConfig && (file.includes('/contracts/') || file.includes('/fragments/')) && ext === 'md') return { kind: 'contract', confirm: false, versioned: true }
  if (docketConfig && file.includes('/workflows/') && ext === 'toml') return { kind: 'workflow-toml', confirm: false, versioned: true }
  if (ext === 'md') return { kind: 'prose', confirm: false, versioned: false }
  if (ext === 'js') return { kind: 'javascript', confirm: false, versioned: false }
  if (ext === 'py') return { kind: 'python', confirm: false, versioned: false }
  if (ext === 'sh' || base === 'doc-record') return { kind: 'shell', confirm: false, versioned: false }
  if (ext === 'rs') return { kind: 'rust', confirm: false, versioned: false }
  if (ext === 'toml') return { kind: 'toml', confirm: false, versioned: false }
  return { kind: 'data', confirm: false, versioned: false }
}

// A candidate that is not strictly smaller is rejected in code, so a pass over
// already-simple files converges regardless of how eager the simplifier is.
function shrank(check) {
  return check.bytesAfter < check.bytesBefore
}

// A versioned file must carry a strictly greater version, or the landing
// would be drift under frozen-drift-check.
function versionBumped(check) {
  return Number.isInteger(check.versionBefore) && Number.isInteger(check.versionAfter) && check.versionAfter > check.versionBefore
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

// Parse simplify-check.sh. Intact needs all of it: exit 0, a gate line that
// is not a failure, no changed kind, the version and size lines, and
// `result intact`.
function parseCheck(stdout) {
  const text = String(stdout || '')
  const failures = []
  let gate = false
  let version = null
  let bytes = null
  let lines = null
  let result = null
  for (const raw of text.split('\n')) {
    const line = raw.trim()
    let m
    if (line === 'gate none' || /^gate \S+ ok$/.test(line)) gate = true
    else if ((m = /^gate (\S+) failed(?::\s*(.*))?$/.exec(line))) {
      gate = true
      failures.push(m[2] ? `gate ${m[1]}: ${m[2]}` : `gate ${m[1]}`)
    } else if ((m = /^kind (\S+) changed(?::\s*(.*))?$/.exec(line))) failures.push(m[2] ? `${m[1]}: ${m[2]}` : m[1])
    else if ((m = /^version (-?\d+) (-?\d+)$/.exec(line))) version = [Number(m[1]), Number(m[2])]
    else if ((m = /^bytes (\d+) (\d+)$/.exec(line))) bytes = [Number(m[1]), Number(m[2])]
    else if ((m = /^lines (\d+) (\d+)$/.exec(line))) lines = [Number(m[1]), Number(m[2])]
    else if ((m = /^result (intact|changed)$/.exec(line))) result = m[1]
  }
  const exit = exitStatus(text)
  const complete = gate && version !== null && bytes !== null && lines !== null && result !== null
  const intact = complete && exit === 0 && result === 'intact' && failures.length === 0
  let problem = ''
  if (!complete) problem = `unparsable check output (exit ${exit === null ? 'missing' : exit})`
  else if (failures.length) problem = failures.join('; ')
  else if (!intact) problem = `check failed (exit ${exit === null ? 'missing' : exit}, result ${result})`
  return {
    intact,
    problem,
    versionBefore: version ? version[0] : null,
    versionAfter: version ? version[1] : null,
    bytesBefore: bytes ? bytes[0] : null,
    bytesAfter: bytes ? bytes[1] : null,
    linesBefore: lines ? lines[0] : null,
    linesAfter: lines ? lines[1] : null,
  }
}
// TEST-END simplify-corpus-decide

const CODE_KINDS = new Set(['javascript', 'python', 'shell', 'rust', 'toml', 'workflow-toml'])

// Three refuters on one identical prompt are three correlated votes. Each
// refuter leads from a different angle; a majority is then agreement across
// approaches, not one approach counted three times. Every refuter still judges
// on every ground.
const CODE_FRAMINGS = [
  {
    key: 'behavior',
    angle: 'BEHAVIOR. Walk every changed site and ask what the program does on the same inputs before and after: outputs, errors, exit codes, side effects, and their order. Refute if any observable behavior differs, including an edge case the original handled and the candidate no longer does.',
  },
  {
    key: 'caller',
    angle: 'THE CALLER. Take the file for what it is (a workflow script, a hook-free helper, a skill script, a settings builder, a docket workflow) and find everything outside it that depends on its shape: exported names, args and return contracts, header comments, TEST-BEGIN/TEST-END regions, test suites that reference it, and tools that parse it. Refute if any of those would now break or read differently.',
  },
  {
    key: 'churn',
    angle: 'CHURN. Ask whether the candidate is a genuine simplification or a rewrite in another style. Refute if it mostly renames, reorders, reformats, or restructures without removing complexity, or trades clarity for brevity so a later pass would want to change it back.',
  },
]

const PROSE_FRAMINGS = [
  {
    key: 'meaning',
    angle: 'MEANING. Walk the original section by section and find where each rule, qualification, unit, number, name, and contract detail landed in the candidate. Refute if any was dropped, weakened, strengthened, or added, unless it was a verbatim restatement of something the candidate still says once.',
  },
  {
    key: 'reader',
    angle: 'THE READER. Take the file for what it is (a skill, an agent definition, a reference, a docket contract or fragment) and ask whether someone following the candidate would act exactly as someone following the original. Refute if a step, condition, exception, or order of operations changed, or if a term of art was replaced by a looser word.',
  },
  {
    key: 'churn',
    angle: 'CHURN. Ask whether the candidate is a genuine simplification or a paraphrase. Refute if it mostly swaps one wording for an equivalent, reorders without removing repetition or needless structure, or trades clarity for brevity so a later pass would want to rewrite it back.',
  },
]

const SIMPLIFY_SCHEMA = {
  type: 'object',
  properties: {
    file: { type: 'string' },
    changed: { type: 'boolean', description: 'False when the file already satisfies every criterion and no candidate was written' },
    candidate: { type: 'string', description: 'Absolute path of the candidate written, or empty string when changed is false' },
    usedSkill: { type: 'boolean', description: 'True when the built-in simplify skill was invoked on the candidate; false when its criteria were applied directly' },
    summary: { type: 'string', description: 'One line on what was simplified, or why nothing was' },
  },
  required: ['file', 'changed', 'candidate', 'usedSkill', 'summary'],
}

const RUN_SCHEMA = {
  type: 'object',
  properties: {
    stdout: { type: 'string', description: 'Everything the command printed, complete and verbatim' },
  },
  required: ['stdout'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string', description: 'The strongest single ground, quoting the original and candidate lines when refuting' },
  },
  required: ['refuted', 'reason'],
}

function candidatePath(scratchDir, file) {
  return `${scratchDir}/${file}`
}

function kindGuidance(kind) {
  switch (kind) {
    case 'prose':
      return `This is Markdown prose. Simplification here is structural: remove
a sentence or paragraph that restates what the file already says once,
collapse steps that duplicate each other, drop a section that no longer
does anything, and replace a roundabout instruction with the direct one.
Preserve every rule, qualification, unit, number, name, trigger phrase,
and contract detail. This is not a wording pass; leave sentences that
carry unique meaning as they are.

Protected content, never invented or altered; a mechanical check rejects
the whole candidate if the candidate contains any of it that the original
did not. Deleting a protected span along with the redundant prose around
it is allowed:
- the YAML frontmatter block, byte for byte (the description is a trigger
  surface, not prose)
- every fenced code block at any indentation, and every indented code
  block
- every double-quoted span (trigger phrases, command output, quoted rules)
- relative links and their targets
- every HTML comment, from <!-- to -->
Headings may go only when the section is removed whole; other files link
to them, and the caller's cross-reference gate reverts a candidate that
breaks a link.`
    case 'contract':
      return `This is a versioned docket contract or fragment: Markdown with a
YAML frontmatter block whose \`version\` field is an integer. Apply the
prose guidance: remove restatement, collapse duplicated steps, drop dead
sections, preserve every rule and contract detail; never invent or alter
a fenced or indented code block, double-quoted span, relative link, or
HTML comment.

The frontmatter is protected except for one line: when you change the
body at all, increment \`version\` by exactly one. A body change without
the bump, or a bump without a body change, is drift the landing gate
rejects. Every other frontmatter line stays byte-identical.`
    case 'workflow-toml':
      return `This is a versioned docket workflow definition in TOML. Apply the
simplify criteria to its structure: remove a key that restates a default,
a table nothing references, or a comment that repeats the key it sits on.
Never change a node's name, its executor, its gate, its edges, or any
value the engine reads; simplification here is what the file says about
itself, not what the workflow does.

When you change anything, increment \`[pipeline].version\` by exactly one.
The version line carries no comment: the caller records this change under
the new version in \`changelogs/<name>.md\` beside the workflows directory,
from your summary, so make the summary one clause naming the change. The
candidate must still parse as TOML.`
    case 'javascript':
      return `This is a Workflow tool script evaluated as an ES module with a
top-level \`return\`. Keep \`export const meta\` a pure literal. Keep every
TEST-BEGIN/TEST-END region's function names and signatures, because a
test suite extracts and calls them. Keep the header comment's args and
return contract true; update its wording only where the code it describes
changed. Prompt template literals are prose to the agent that receives
them: shorten a prompt only when it says the same thing.`
    case 'python':
      return `This is a Python script a skill runs. Keep its command-line
interface, exit codes, output format, and every name a test suite
imports or invokes. The candidate must compile with py_compile.`
    case 'shell':
      return `This is a shell script. Keep its arguments, exit codes, output,
and environment-variable contract. Keep \`set\` options as they are. The
candidate must pass \`bash -n\`.`
    case 'rust':
      return `This is Rust that builds the Claude Code settings. Keep every
public item, every serialized field name, and every value that reaches
the generated settings: permission rules, hook wiring, sandbox flags,
model and environment settings. Simplify only construction, duplication,
and indirection. The candidate must keep \`cargo fmt --check\`,
\`cargo clippy -D warnings\`, and \`cargo test\` green; the caller runs
them and reverts otherwise.`
    case 'toml':
      return `This is TOML configuration. Remove a key that restates a default
or a comment that repeats the key it sits on; never change a value the
consumer reads. The candidate must still parse as TOML.`
    default:
      return 'This file kind is not simplified; return changed=false.'
  }
}

function simplifyPrompt(file, candidate, kind, pass) {
  return `Simplify ${file} (pass ${pass}).

Read the file in full. Work by copying, then editing in place: mkdir -p
the candidate's parent, cp ${file} ${candidate}, then apply targeted
edits to the candidate. Never regenerate the whole file from memory;
everything you do not touch must stay byte-identical, and a long file
written in one go truncates. Never write to ${file} itself.

Use the built-in simplify skill. If the Skill tool is available, invoke
Skill({skill: "simplify"}) and follow its instructions with ${candidate}
as the changed code under review: it reviews a diff, and the untracked
candidate is the change. Return usedSkill=true. If its instructions
direct you to run git diff, read the checkout's changes, or edit any
tracked file, stop following them there: the checkout is not yours to
change, and the candidate is the only file you write. If the Skill tool
is unavailable, or you stopped following the skill, apply its four
criteria yourself and return usedSkill=false:
- reuse: replace a local reimplementation with a helper the file or its
  neighbors already provide, and merge duplicated logic into one place
- simplification: remove needless indirection, dead branches, unused
  names, restated comments, and structure that serves no reader
- efficiency: remove wasted work, repeated computation, and needless
  passes, when the result stays as clear
- altitude: keep the code at one level of abstraction, neither clever
  nor ceremonious for what it does
Quality only: do not hunt for bugs, change behavior, or fix what is not
a simplification.

${kindGuidance(kind)}

When at least one edit landed in ${candidate}, return changed=true with
its path. If the file already satisfies every criterion and nothing
improves, remove the candidate copy and return changed=false with a
one-line summary; do not produce a restyling to have something to show.`
}

function checkCommand(kind, file, candidate) {
  return `bash ${SCRIPTS}/simplify-check.sh ${kind} ${shellQuote(file)} ${shellQuote(candidate)}`
}

function runPrompt(command) {
  return `Run this one command with the Bash tool, exactly as written, once:

${command}; echo "exit=$?"

Return everything it printed, complete and verbatim, as stdout. Run nothing
else and fix nothing: the caller parses the output, and a retry or a
workaround would hide the failure it needs to see. If the tool refuses the
command, return the refusal as stdout.`
}

async function run(command, opts) {
  const out = await agent(runPrompt(command), { schema: RUN_SCHEMA, ...AGENT_CONFIG.check, ...opts })
  return out ? out.stdout : ''
}

function verifyPrompt(file, candidate, kind, framing) {
  const noun = CODE_KINDS.has(kind) ? 'code change' : 'prose rewrite'
  return `Try to REFUTE this ${noun}.
Original: ${file}
Candidate: ${candidate}

Read both in full, then judge whether the candidate preserves what the
original does and is a genuine simplification under the simplify
criteria (reuse, simplification, efficiency, altitude).

Your angle: ${framing.angle}

Work your angle first and let it lead, but every ground below still
refutes: changed observable behavior or meaning; a broken caller, test,
parser, link, or contract; wording or code added that the original did
not commit to; a restyling that is not simpler. Default to refuted=true
unless you can confirm the candidate does what the original does, with
less. Smaller size alone is not a defense. Quote the original and
candidate lines behind your strongest ground.`
}

const files = Array.isArray(args?.files) ? args.files.filter(Boolean) : []
const scratchDir = args?.scratchDir
const pass = args?.pass || 1
if (!files.length) throw new Error('simplify-corpus: args.files is empty; the skill resolves targets before launching')
if (!scratchDir || !scratchDir.startsWith('/')) throw new Error('simplify-corpus: args.scratchDir must be an absolute path')

const targets = files.map((file) => ({ file, ...classify(file) }))
const dataFiles = targets.filter((t) => t.kind === 'data').map((t) => t.file)
if (dataFiles.length) log(`${dataFiles.length} data file(s) rejected without a simplifier: ${dataFiles.join(', ')}`)
const work = targets.filter((t) => t.kind !== 'data')

log(`Pass ${pass}: ${work.length} file(s), one simplifier each; candidates under ${scratchDir}`)

phase('Simplify')
const results = await pipeline(
  work,
  (t) => agent(simplifyPrompt(t.file, candidatePath(scratchDir, t.file), t.kind, pass), { phase: 'Simplify', label: `simplify:${t.file}`, schema: SIMPLIFY_SCHEMA, ...AGENT_CONFIG.simplify }),
  async (simplified, t) => {
    const base = { file: t.file, kind: t.kind }
    if (!simplified) return { ...base, status: 'rejected', reason: 'the simplifier returned nothing' }
    if (!simplified.changed) return { ...base, status: 'unchanged', summary: simplified.summary }
    const candidate = simplified.candidate || candidatePath(scratchDir, t.file)
    const check = parseCheck(await run(checkCommand(t.kind, t.file, candidate), { phase: 'Check', label: `check:${t.file}` }))
    if (!check.intact) return { ...base, status: 'rejected', reason: `mechanical check failed: ${check.problem}` }
    if (!shrank(check)) return { ...base, status: 'rejected', reason: `candidate is not smaller (${check.bytesBefore} -> ${check.bytesAfter} bytes)` }
    if (t.versioned && !versionBumped(check)) return { ...base, status: 'rejected', reason: `version not bumped by exactly a greater integer (${check.versionBefore} -> ${check.versionAfter})` }
    return { ...base, status: 'checked', candidate, check, summary: simplified.summary, usedSkill: simplified.usedSkill }
  },
  async (checked, t) => {
    if (!checked || checked.status !== 'checked') return checked
    const base = { file: t.file, kind: t.kind }
    const framings = CODE_KINDS.has(t.kind) ? CODE_FRAMINGS : PROSE_FRAMINGS
    const returns = await parallel(framings.map((framing) => () =>
      agent(verifyPrompt(t.file, checked.candidate, t.kind, framing), { phase: 'Verify', label: `verify:${t.file}:${framing.key}`, schema: VERDICT_SCHEMA, ...AGENT_CONFIG.verify })
    ))
    const tally = tallyVotes(returns)
    if (!tally.accepted) return { ...base, status: 'rejected', reason: `${tally.upheld}/${tally.votes} refuters upheld; ${tally.reasons.join(' | ') || 'no votes returned'}` }
    return {
      ...base,
      status: 'accepted',
      candidate: checked.candidate,
      summary: checked.summary,
      usedSkill: checked.usedSkill,
      confirm: t.confirm,
      versioned: t.versioned,
      versionBefore: checked.check.versionBefore,
      versionAfter: checked.check.versionAfter,
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
const dropped = work.filter((t) => !outcomes.some((o) => o.file === t.file)).map((t) => t.file)
const accepted = outcomes.filter((o) => o.status === 'accepted')
const rejected = [
  ...outcomes.filter((o) => o.status === 'rejected'),
  ...dropped.map((file) => ({ file, status: 'rejected', reason: 'a stage threw; see the run journal' })),
  ...dataFiles.map((file) => ({ file, kind: 'data', status: 'rejected', reason: 'data files are never simplified' })),
]
const unchanged = outcomes.filter((o) => o.status === 'unchanged')
if (dropped.length) log(`${dropped.length} file(s) dropped by a thrown stage: ${dropped.join(', ')}`)

const savedBytes = accepted.reduce((n, o) => n + (o.bytesBefore - o.bytesAfter), 0)
const viaSkill = accepted.filter((o) => o.usedSkill).length
const awaiting = accepted.filter((o) => o.confirm).length
const summary = `Pass ${pass}: ${work.length} file(s); ${accepted.length} accepted (${savedBytes} bytes removed, ${viaSkill} via the simplify skill, ${awaiting} awaiting operator confirmation), ${rejected.length} rejected, ${unchanged.length} unchanged; 3 refuters per candidate, ${UPHOLD_MIN} upholds to accept.`
log(summary)

return { pass, accepted, rejected, unchanged, summary }
