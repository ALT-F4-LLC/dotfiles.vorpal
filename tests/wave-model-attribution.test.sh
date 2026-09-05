#!/bin/bash

# Execute rendered claim commands against a fake Docket binary. Verify that
# routing survives failure at claim time and is never presented as observation.
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
const start = source.indexOf('function bootstrap(')
const end = source.indexOf('\nlet input = args', start)
assert(start >= 0 && end > start, 'bootstrap boundaries exist')
const bootstrap = vm.runInNewContext(source.slice(start, end) + '\nbootstrap')
const bin = path.join(work, 'bin')
fs.mkdirSync(bin)
fs.writeFileSync(path.join(bin, 'docket'), '#!/bin/bash\nprintf \'%s\\0\' "$@" > "$CAPTURE_ARGS"\n', { mode: 0o755 })
const row = { step: 'STEP-7', issue: 'DKT-3', run: 'RUN-1' }
const marker = path.join(work, 'unexpected-shell-execution')
const cases = [
    { isolated: false, model: 'sonnet', effort: 'high', variant: 'sonnet-high' },
    { isolated: true, model: 'opus', effort: 'medium', variant: 'opus-medium' },
    { isolated: false, model: `model'$(touch ${marker})`, effort: 'high', variant: 'quoted-routing' },
]
for (const [index, c] of cases.entries()) {
    const routing = { ...c, model_requested: c.model, effort_requested: c.effort }
    const brief = bootstrap(row, routing, c.isolated, c.isolated)
    const line = brief.split('\n').find((l) => l.includes('docket step claim STEP-7 --owner'))
    assert(line, 'rendered claim command exists')
    const command = line.trim().replace(/^`/, '').replace(/`$/, '').replace(/\s*&&$/, '')
        .replaceAll('<TMP>', work)
    fs.mkdirSync(path.join(work, 'STEP-7.d'), { recursive: true })
    const capture = path.join(work, `argv-${index}`)
    const run = spawnSync('/bin/bash', ['-c', command], {
        encoding: 'utf8', cwd: work,
        env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, CAPTURE_ARGS: capture },
    })
    assert.equal(run.status, 0, run.stderr)
    const argv = fs.readFileSync(capture, 'utf8').split('\0').slice(0, -1)
    const metadata = JSON.parse(argv[argv.indexOf('--metadata') + 1])
    assert.deepEqual(metadata, {
        variant: c.variant, model_requested: c.model, effort_requested: c.effort,
        model_resolved: 'unknown', effort_resolved: 'unknown',
    })
    assert(!argv.includes('--cost-multiplier'), 'no pricing multiplier is inferred from model names')
    assert(!fs.existsSync(marker), 'routing metadata remains one literal shell argument')
    assert(brief.includes('runtime directly supplies an observation'), 'resolved attribution requires observed evidence')
    assert(brief.includes('not SDK\n   `modelUsage` telemetry'), 'native workflow results are not treated as SDK telemetry')
    assert(!brief.includes('<model that served you>'), 'the executor is not required to invent its model')
    console.log(`PASS: ${c.isolated ? 'isolated' : 'shared'} claim persists requested routing with unknown observations`)
}
JS
