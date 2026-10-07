#!/bin/bash

# Execute the claim agent's rendered command against a fake wave-claim.
# Verify that routing survives failure at claim time and is never presented
# as observation, and that every argument stays one literal shell word.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-model-attribution.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

node - "$WAVE" "$WORK" <<'JS'
const fs = require('fs')
const path = require('path')
const vm = require('vm')
const assert = require('assert/strict')
const { spawnSync } = require('child_process')
const [sourcePath, work] = process.argv.slice(2)
const source = fs.readFileSync(sourcePath, 'utf8')
const region = (name) => {
    const begin = source.indexOf(`// TEST-BEGIN ${name}`)
    const end = source.indexOf(`// TEST-END ${name}`)
    assert(begin >= 0 && end > begin, `${name} region markers exist`)
    return source.slice(begin, end)
}
const ctx = vm.runInNewContext(region('packet') + '\n' + region('executor-brief') +
    '\n;({ nextOwner, claimCommand, claimBrief, executorBrief })')
// `~/.docket/bin/wave-claim` resolves under a scratch HOME to this fake.
const home = path.join(work, 'home')
fs.mkdirSync(path.join(home, '.docket', 'bin'), { recursive: true })
fs.writeFileSync(path.join(home, '.docket', 'bin', 'wave-claim'),
    '#!/bin/bash\nprintf \'%s\\0\' "$@" > "$CAPTURE_ARGS"\n', { mode: 0o755 })
const row = { step: 'STEP-7', issue: 'DKT-3', run: 'RUN-1', attempt: 1 }
const marker = path.join(work, 'unexpected-shell-execution')
const cases = [
    { isolated: false, model: 'sonnet', effort: 'high', variant: 'sonnet-high', cwd: '/repo' },
    { isolated: true, model: 'opus', effort: 'medium', variant: 'opus-medium', cwd: '/repo' },
    { isolated: false, model: `model'$(touch ${marker})`, effort: 'high', variant: 'quoted-routing', cwd: '/repo' },
    { isolated: false, model: 'sonnet', effort: 'high', variant: 'quoted-path', cwd: `/repo/it's $(touch ${marker})` },
]
for (const [index, c] of cases.entries()) {
    const routing = { ...c, model_requested: c.model, effort_requested: c.effort }
    const owner = ctx.nextOwner(`STEP-7`)
    const modulePath = `${c.cwd}/.claude/docket-packets/STEP-7.a2.js`
    const brief = ctx.claimBrief(row, ctx.claimCommand(row, routing, owner, modulePath))
    const line = brief.split('\n').find((l) => l.includes('wave-claim --step STEP-7 --owner'))
    assert(line, 'rendered claim command exists')
    const capture = path.join(work, `argv-${index}`)
    const run = spawnSync('/bin/bash', ['-c', line.trim()], {
        encoding: 'utf8', cwd: work,
        env: { ...process.env, HOME: home, CAPTURE_ARGS: capture },
    })
    assert.equal(run.status, 0, run.stderr)
    const argv = fs.readFileSync(capture, 'utf8').split('\0').slice(0, -1)
    const arg = (flag) => argv[argv.indexOf(flag) + 1]
    assert.deepEqual(JSON.parse(arg('--metadata')), {
        variant: c.variant, model_requested: c.model, effort_requested: c.effort,
        model_resolved: 'unknown', effort_resolved: 'unknown',
    })
    assert.equal(arg('--step'), 'STEP-7')
    assert.equal(arg('--owner'), owner)
    assert.equal(arg('--attempt'), '2', 'the claim is fenced at the row attempt plus one')
    assert.equal(arg('--module'), modulePath, 'the module path is one literal argument')
    assert(!argv.includes('--cost-multiplier'), 'no pricing multiplier is inferred from model names')
    assert(!fs.existsSync(marker), 'routing metadata and the module path remain literal shell arguments')
    const claim = { dir: '/tmp/x/STEP-7.d', dirPhysical: '/private/tmp/x/STEP-7.d', token: '/tmp/x/STEP-7.d/STEP-7.token', attempt: 2, packet: '== STEP STEP-7 implement@0\n' }
    const execBrief = ctx.executorBrief(row, owner, claim, c.isolated, c.isolated, c.cwd)
    assert(execBrief.includes('runtime directly supplies an observation'), 'resolved attribution requires observed evidence')
    assert(!execBrief.includes('<model that served you>'), 'the executor is not required to invent its model')
    console.log(`PASS: ${c.variant}: the claim persists requested routing with unknown observations`)
}
JS
