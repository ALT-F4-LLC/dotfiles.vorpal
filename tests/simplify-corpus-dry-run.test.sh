#!/bin/bash

# Dry run of the whole simplify-corpus.js workflow: the script body runs
# under node with agent(), pipeline(), and parallel() stubbed. Check runners
# execute the real command their prompt carries, against simplify-check.sh
# in this checkout; simplifiers and refuters are scripted per file. No model
# is called.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs `node`, `python3`, `yq`, and
# bash — no engine, no network, and it never spawns a real agent.
#
# WHY THIS EXISTS. The decide suite pins the parser and the scripts suite
# pins the script; neither shows that the workflow passes a candidate's kind
# to the script, rejects on the script's report rather than an agent's
# reading of it, keeps the version rule after the check, and sends to the
# refuters only what passed. Eight files cover every outcome: a prose and a
# contract simplification accepted, a broken workflow module, an unbumped
# fragment, a broken docket workflow, and an altered quotation rejected, a
# JSON fixture rejected unread, and settings.rs left unchanged.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SIMPLIFY="${SIMPLIFY_CORPUS_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/simplify-corpus.js}"
SCRIPTS="${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-corpus/scripts"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SIMPLIFY" ] || fatal "simplify-corpus.js not found at ${SIMPLIFY}"
[ -d "$SCRIPTS" ] || fatal "scripts not found at ${SCRIPTS}"
for tool in node python3 yq; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/simplify-corpus-dry-run.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SCRIPTS=$(cd "$SCRIPTS" && pwd)

R="${WORK}/repo"
mkdir -p "$R/src/user/claude_code/skills/x/evals" "$R/src/user/claude_code/skills/y" "$R/src/user/claude_code/workflows" \
    "$R/src/user/docket/config/contracts" "$R/src/user/docket/config/fragments" "$R/src/user/docket/config/workflows"
printf '%s\n' '# X' '' 'Say "keep this" once.' 'Say it once more, again, as a restatement.' > "$R/src/user/claude_code/skills/x/SKILL.md"
printf '%s\n' '# Y' '' 'Say "keep this" once, and once more.' > "$R/src/user/claude_code/skills/y/SKILL.md"
printf '%s\n' 'export const meta = { name: "x" }' 'function a() { return 1 }' 'return a()' > "$R/src/user/claude_code/workflows/x.js"
printf '%s\n' '---' 'node: c' 'version: 4' '---' '' 'Body, said twice.' 'Body.' > "$R/src/user/docket/config/contracts/c.md"
printf '%s\n' '---' 'node: f' 'version: 3' '---' '' 'Body, said twice.' 'Body.' > "$R/src/user/docket/config/fragments/f.md"
printf '%s\n' '[pipeline]' 'name = "w"' 'version = 2' > "$R/src/user/docket/config/workflows/w.toml"
printf '%s\n' '{}' > "$R/src/user/claude_code/skills/x/evals/cases.json"
printf '%s\n' 'fn main() {}' > "$R/src/user/claude_code/settings.rs"

cat > "${WORK}/harness.js" <<'JS'
const fs = require('fs')
const path = require('path')
const { execSync } = require('child_process')
const [simplifyPath, scriptsDir, repo, scratchDir] = process.argv.slice(2)
const INSTALLED = '~/.claude/skills/simplify-corpus/scripts'
const calls = []
const commands = []
const errors = []

// Scripted simplifications, by file: each returns the candidate's text, or
// null for a file already simple.
const EDITS = {
  'src/user/claude_code/skills/x/SKILL.md': (t) => t.replace('\nSay it once more, again, as a restatement.', ''),
  'src/user/claude_code/skills/y/SKILL.md': (t) => t.replace('"keep this" once, and once more.', '"keep that" once.'),
  'src/user/claude_code/workflows/x.js': (t) => t.replace('return a()', 'function a() { return 2 }\nreturn a()'),
  'src/user/docket/config/contracts/c.md': (t) => t.replace('version: 4', 'version: 5').replace('Body, said twice.\n', ''),
  'src/user/docket/config/fragments/f.md': (t) => t.replace('Body, said twice.\n', ''),
  'src/user/docket/config/workflows/w.toml': (t) => t.replace('[pipeline]', '[pipeline'),
  'src/user/claude_code/settings.rs': () => null,
}

function simplifier(prompt) {
  const m = /cp (\S+) (\S+), then apply/.exec(prompt)
  if (!m) throw new Error('simplify prompt carries no cp line')
  const [, file, candidate] = m
  const next = EDITS[file](fs.readFileSync(path.join(repo, file), 'utf8'))
  if (next === null) return { file, changed: false, candidate: '', usedSkill: false, summary: 'already simple' }
  fs.mkdirSync(path.dirname(candidate), { recursive: true })
  fs.writeFileSync(candidate, next)
  return { file, changed: true, candidate, usedSkill: false, summary: `simplified ${file}` }
}

function runner(prompt) {
  const m = /once:\n\n([^\n]+)\n\nReturn everything/.exec(prompt)
  if (!m) throw new Error('runner prompt carries no command line')
  commands.push(m[1])
  const line = m[1].split(INSTALLED).join(scriptsDir)
  return { stdout: execSync(`{ ${line}; } 2>&1`, { shell: '/bin/bash', cwd: repo, encoding: 'utf8' }) }
}

async function agent(prompt, opts) {
  calls.push(opts.label)
  const kind = opts.label.split(':')[0]
  if (kind === 'simplify') return simplifier(prompt)
  if (kind === 'check') return runner(prompt)
  if (kind === 'verify') return { refuted: false, reason: 'upheld' }
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
  const body = fs.readFileSync(simplifyPath, 'utf8').replace(/^export const meta/m, 'const meta')
  const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor
  const run = new AsyncFunction('agent', 'pipeline', 'parallel', 'log', 'phase', 'args', body)
  const files = [...Object.keys(EDITS), 'src/user/claude_code/skills/x/evals/cases.json']
  const result = await run(agent, pipeline, parallel, () => {}, () => {}, { files, scratchDir, pass: 1 })
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

node "${WORK}/harness.js" "$SIMPLIFY" "$SCRIPTS" "$R" "${WORK}/scratch" > "${WORK}/out.json"
ok $? 'the workflow body runs to its return under stubs'

get() { node -e "const o=require('${WORK}/out.json'); process.stdout.write(String($1))"; }
count() { get "o.calls.filter((l) => l.startsWith('$1:')).length"; }
reason() { get "(o.result.rejected.find((r) => r.file === '$1') || { reason: 'NOT REJECTED' }).reason"; }

[ "$(get 'o.errors.length')" = "0" ]; ok $? 'no stage threw'
[ "$(get "o.result.accepted.map((a) => a.file).sort().join()")" = "src/user/claude_code/skills/x/SKILL.md,src/user/docket/config/contracts/c.md" ]
ok $? 'the prose and the bumped contract simplification are accepted'
[ "$(get "o.result.accepted.find((a) => a.kind === 'contract').versionAfter")" = "5" ]; ok $? 'the accepted contract carries the version the script read'
[ "$(get "o.result.accepted.find((a) => a.kind === 'contract').versioned")" = "true" ]; ok $? 'the accepted contract keeps its versioned flag'
reason src/user/claude_code/workflows/x.js | grep -q '^mechanical check failed: gate node-module: SyntaxError'; ok $? 'a duplicate function in a workflow module is rejected by the gate'
reason src/user/docket/config/fragments/f.md | grep -q '^version not bumped'; ok $? 'an unbumped fragment is rejected by the version rule'
reason src/user/docket/config/workflows/w.toml | grep -q '^mechanical check failed: gate toml: .*expected character \]'; ok $? 'a broken docket workflow is rejected by the toml gate'
reason src/user/claude_code/skills/y/SKILL.md | grep -q '^mechanical check failed: quotes: added "keep that"'; ok $? 'an altered quotation is rejected by the subset check'
reason src/user/claude_code/skills/x/evals/cases.json | grep -q '^data files are never simplified$'; ok $? 'a JSON fixture is rejected unread'
[ "$(get 'o.result.unchanged.map((u) => u.file).join()')" = "src/user/claude_code/settings.rs" ]; ok $? 'settings.rs comes back unchanged'

[ "$(count simplify)" = "7" ]; ok $? 'one simplifier per non-data file'
[ "$(count check)" = "6" ]; ok $? 'one check runner per changed candidate'
[ "$(count verify)" = "6" ]; ok $? 'refuters run only on the two candidates that passed the check and the version rule'
[ "$(get "o.commands.filter((c) => !c.startsWith('bash ~/.claude/skills/simplify-corpus/scripts/simplify-check.sh ')).length")" = "0" ]; ok $? 'every check runs the installed simplify-check.sh with bash'
[ "$(get "o.commands.filter((c) => !c.endsWith('; echo \"exit=\$?\"')).length")" = "0" ]; ok $? 'every check command ends with the exit line the parser needs'
[ "$(get "o.commands.filter((c) => c.includes(' javascript ')).length")" = "1" ]; ok $? 'the check is told the candidate'"'"'s kind'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
