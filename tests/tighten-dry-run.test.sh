#!/bin/bash

# Dry run of the whole tighten.js workflow: the script body runs under node
# with agent(), pipeline(), and parallel() stubbed. Runner agents execute the
# real commands their prompts carry, against the scripts in this checkout;
# rewriters and refuters are scripted per chunk. No model is called.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs only `node`, `bash`, and
# coreutils — no engine, no network, and it never spawns a real agent.
#
# WHY THIS EXISTS. The decide suite pins the helpers one at a time, and the
# scripts suite pins the scripts; neither shows that the workflow wires them
# together: that a runner prompt carries a command that runs, that a chunk
# which breaks a protected span or loses its vote stays out of the joined
# candidate, that the accepted chunks land and nothing else changes, and
# that every file comes back in exactly one of accepted, rejected, or
# unchanged. One file here has five chunks, scripted as accepted, broken
# quotation, already tight, voted down, and accepted; another has a chunk
# changed after its check passed, which only the whole-file check can see.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIGHTEN="${TIGHTEN_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/tighten.js}"
SCRIPTS="${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-corpus/scripts"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$TIGHTEN" ] || fatal "tighten.js not found at ${TIGHTEN}"
[ -d "$SCRIPTS" ] || fatal "scripts not found at ${SCRIPTS}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/tighten-dry-run.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SCRIPTS=$(cd "$SCRIPTS" && pwd)

# Sections of 45 three-line paragraphs: each section is one chunk.
fixture() { # <sections>
    printf -- '---\nname: fixture\ndescription: a dry-run fixture\n---\n\n'
    for s in $(seq 1 "$1"); do
        printf '## Section %d\n\n' "$s"
        for p in $(seq 1 45); do
            printf 'Paragraph %d.%d actually says "keep phrase %d.%d" and runs `cmd %d`.\n' "$s" "$p" "$s" "$p" "$p"
            printf 'It actually continues here with more words to fill the line.\n'
            printf 'And it ends.\n\n'
        done
    done
}
mkdir -p "${WORK}/repo/docs"
fixture 5 > "${WORK}/repo/docs/big.md"
fixture 2 > "${WORK}/repo/docs/tamper.md"
printf '# Tight\n\nAlready tight.\n' > "${WORK}/repo/docs/tight.md"

cat > "${WORK}/harness.js" <<'JS'
const fs = require('fs')
const { execSync } = require('child_process')
const [tightenPath, scriptsDir, repo, scratchDir] = process.argv.slice(2)
const INSTALLED = '~/.claude/skills/simplify-corpus/scripts'
const calls = []
const commands = []
const errors = []

const idOf = (path) => (/\/cand\/(\d+)\.md/.exec(path) || [])[1]
const dropActually = (text) => text.replace(/ actually/g, '')

function runner(prompt) {
  const m = /once:\n\n([^\n]+)\n\nReturn everything/.exec(prompt)
  if (!m) throw new Error('runner prompt carries no command line')
  commands.push(m[1])
  const line = m[1].split(INSTALLED).join(scriptsDir)
  const stdout = execSync(`{ ${line}; } 2>&1`, { shell: '/bin/bash', cwd: repo, encoding: 'utf8' })
  return { stdout }
}

function rewriter(prompt) {
  const cand = (/That chunk is copied to (\S+)\. Edit/.exec(prompt) || [])[1]
  const id = idOf(cand)
  if (cand.includes('/docs/tight.md/')) return { changed: false, summary: 'already tight' }
  const text = fs.readFileSync(cand, 'utf8')
  if (cand.includes('/docs/big.md/') && id === '002') {
    fs.writeFileSync(cand, dropActually(text).replace('"keep phrase 2.1"', '"keep phrase two"'))
    return { changed: true, summary: 'cut filler, reworded a quotation' }
  }
  if (cand.includes('/docs/big.md/') && id === '003') return { changed: false, summary: 'already tight' }
  fs.writeFileSync(cand, dropActually(text))
  return { changed: true, summary: 'cut filler' }
}

// A refuter that edits the chunk after its check passed stands in for any
// late write; only the whole-file check after assembly can see it.
function refuter(prompt, label) {
  const cand = (/Candidate chunk: (\S+)/.exec(prompt) || [])[1]
  const id = idOf(cand)
  if (cand.includes('/docs/tamper.md/') && id === '001' && label.endsWith(':meaning')) {
    fs.writeFileSync(cand, fs.readFileSync(cand, 'utf8').replace('"keep phrase 1.1"', '"keep phrase one"'))
  } else if (cand.includes('/docs/big.md/') && id === '004' && !label.endsWith(':churn')) {
    return { refuted: true, reason: `chunk ${id} refuted by ${label}` }
  }
  return { refuted: false, reason: 'upheld' }
}

async function agent(prompt, opts) {
  calls.push(opts.label)
  const kind = opts.label.split(':')[0]
  if (kind === 'split' || kind === 'check' || kind === 'assemble') return runner(prompt)
  if (kind === 'rewrite') return rewriter(prompt)
  if (kind === 'verify') return refuter(prompt, opts.label)
  throw new Error(`unexpected agent label ${opts.label}`)
}
const pipeline = (items, ...stages) => Promise.all(items.map(async (item, i) => {
  let r = item
  try {
    for (const stage of stages) r = await stage(r, item, i)
  } catch (e) {
    errors.push(String(e))
    return null
  }
  return r
}))
const parallel = (thunks) => Promise.all(thunks.map((t) => Promise.resolve().then(t).catch((e) => { errors.push(String(e)); return null })))

;(async () => {
  const body = fs.readFileSync(tightenPath, 'utf8').replace(/^export const meta/m, 'const meta')
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor
  const run = new AsyncFunction('agent', 'pipeline', 'parallel', 'log', 'phase', 'args', body)
  const args = { files: ['docs/big.md', 'docs/tight.md', 'docs/missing.md', 'docs/tamper.md'], scratchDir, pass: 1 }
  const result = await run(agent, pipeline, parallel, () => {}, () => {}, args)
  process.stdout.write(JSON.stringify({ result, calls, commands, errors }))
})().catch((e) => { process.stderr.write(String(e && e.stack || e)); process.exit(1) })
JS

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

node "${WORK}/harness.js" "$TIGHTEN" "$SCRIPTS" "${WORK}/repo" "${WORK}/scratch" > "${WORK}/out.json"
ok $? 'the workflow body runs to its return under stubs'

get() { node -e "const o=require('${WORK}/out.json'); process.stdout.write(String($1))"; }
count() { get "o.calls.filter((l) => l.startsWith('$1:')).length"; }

[ "$(get 'o.errors.length')" = "0" ]; ok $? 'no stage threw'
[ "$(get 'o.result.accepted.length')" = "1" ] && [ "$(get 'o.result.accepted[0].file')" = "docs/big.md" ]; ok $? 'the five-chunk file is accepted'
[ "$(get 'JSON.stringify(o.result.accepted[0].chunks)')" = '{"total":5,"accepted":2,"rejected":2,"unchanged":1}' ]; ok $? 'its chunks count as 2 accepted, 2 rejected, 1 unchanged'
[ "$(get "o.result.accepted[0].rejectedChunks.map((c) => c.reason).filter((r) => r.startsWith('protected span changed: quotes')).length")" = "1" ]; ok $? 'the chunk that reworded a quotation is rejected by the check'
[ "$(get "o.result.accepted[0].rejectedChunks.map((c) => c.reason).filter((r) => r.startsWith('1/3 refuters upheld')).length")" = "1" ]; ok $? 'the chunk two refuters refuted is rejected by the vote'
[ "$(get 'o.result.accepted[0].chunkVotes.map((v) => v.upheldBy).join()')" = "3,3" ]; ok $? 'accepted chunks carry their vote tallies'
[ "$(get 'o.result.unchanged.map((u) => u.file).join()')" = "docs/tight.md" ]; ok $? 'an already-tight file comes back unchanged'
[ "$(get 'o.result.rejected.map((r) => r.file).join()')" = "docs/missing.md,docs/tamper.md" ]; ok $? 'the unsplittable and the tampered file are rejected'
get 'o.result.rejected[0].reason' | grep -q '^split failed or unparsable (exit 2)$'; ok $? 'the split failure carries the script exit status'
get 'o.result.rejected[1].reason' | grep -q '^joined candidate failed the whole-file check: protected span changed: quotes'; ok $? 'a chunk changed after its check is caught by the whole-file check'

[ "$(count split)" = "4" ]; ok $? 'one split runner per file'
[ "$(count rewrite)" = "8" ]; ok $? 'one rewriter per chunk'
[ "$(count check)" = "6" ]; ok $? 'the check runs only on chunks a rewriter changed'
[ "$(count verify)" = "15" ]; ok $? 'refuters run only on chunks that passed the check, three each'
[ "$(count assemble)" = "2" ]; ok $? 'only a file with an accepted chunk is assembled'
[ "$(get "o.commands.filter((c) => !c.startsWith('bash ~/.claude/skills/simplify-corpus/scripts/')).length")" = "0" ]; ok $? 'every runner command calls an installed script with bash'
[ "$(get "o.commands.filter((c) => !c.endsWith('; echo \"exit=\$?\"')).length")" = "0" ]; ok $? 'every runner command ends with the exit line the parser needs'

CAND="${WORK}/scratch/docs/big.md"
CHUNKDIR="${WORK}/scratch/.chunks/docs/big.md/orig"
[ -f "$CAND" ]; ok $? 'the candidate lands at scratchDir/<file>'
for c in "$CHUNKDIR"/*.md; do
    case "$(basename "$c")" in
        001.md | 005.md) sed 's/ actually//g' "$c" ;;
        *) cat "$c" ;;
    esac
done > "${WORK}/expected.md"
cmp -s "$CAND" "${WORK}/expected.md"; ok $? 'the candidate is the original with only the accepted chunks rewritten'
bash "${SCRIPTS}/protected-spans.sh" equal "${WORK}/repo/docs/big.md" "$CAND" > /dev/null; ok $? 'the candidate passes the protected-span check'
[ "$(get 'o.result.accepted[0].bytesBefore - o.result.accepted[0].bytesAfter')" = "$(( $(wc -c < "${WORK}/repo/docs/big.md") - $(wc -c < "$CAND") ))" ]; ok $? 'the reported sizes are the files'"'"' real sizes'
cmp -s "${WORK}/repo/docs/tight.md" <(printf '# Tight\n\nAlready tight.\n'); ok $? 'the workflow never writes a repository file'
get 'o.result.summary' | grep -q '1 file(s) accepted (2 chunk(s), '; ok $? 'the summary counts accepted files and chunks'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
