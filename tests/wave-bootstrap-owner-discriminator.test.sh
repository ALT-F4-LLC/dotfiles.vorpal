#!/bin/bash

# Behavior suite for wave.js's bootstrap() owner discriminator: the number
# appended to `--owner wave:<step>:<n>` that distinguishes two concurrent
# launch attempts of the SAME step.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The discriminator used to be a single counter shared
# across every step bootstrap() ever rendered a claim for in one wave
# invocation, incremented once per call regardless of which step the call
# was for. That makes a step's own discriminator depend on how many OTHER
# steps' claims were rendered before it — which follows agent completion
# order (release() timing), not manifest order. The documented resume cache
# keys on exact prompt text: a resumed wave whose agents happen to settle in
# a different order than the original run renders a different owner string
# for the same step, and misses the resume cache on it even though nothing
# about that step's own retry state changed. A per-step counter removes the
# dependency: a step's first launch is always discriminator 1 and its retry
# is always 2, regardless of what happened to any other step.
#
# WHAT IS PINNED HERE. (1) two different steps get independent discriminator
# sequences, each starting at 1; (2) the ORDER two different steps are
# bootstrapped in never changes either step's own discriminator sequence —
# this is the property the fix establishes and the prior shared-counter
# code lacked; (3) two launches of the SAME step still get distinct,
# incrementing discriminators (1, then 2), so the original hazard the
# discriminator exists to prevent — a retry racing its own still-alive
# earlier claim under an identical owner — remains fixed.
#
# HOW. Like tests/wave-model-attribution.test.sh, it extracts wave.js's
# `function bootstrap(` region into a fresh VM context (no workflow globals
# needed — the region is self-contained) and calls it directly, reading the
# discriminator back off the rendered `--owner wave:<step>:<n>` claim line.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

node - "$WAVE" <<'JS'
const fs = require('fs')
const vm = require('vm')
const assert = require('assert/strict')
const [sourcePath] = process.argv.slice(2)
const source = fs.readFileSync(sourcePath, 'utf8')
const start = source.indexOf('function bootstrap(')
const end = source.indexOf('\nlet input = args', start)
assert(start >= 0 && end > start, 'bootstrap boundaries exist')

const routing = {
    model: 'sonnet', effort: 'high', variant: 'sonnet-high',
    model_requested: 'sonnet', effort_requested: 'high',
}
const discriminatorOf = (bootstrapFn, step) => {
    const brief = bootstrapFn({ step, issue: 'DKT-1', run: 'RUN-1' }, routing, false, false)
    const line = brief.split('\n').find((l) => l.includes(`docket step claim ${step} --owner`))
    assert(line, `rendered claim command exists for ${step}`)
    const m = line.match(new RegExp(`--owner wave:${step}:(\\d+)`))
    assert(m, `owner discriminator is present for ${step}`)
    return parseInt(m[1], 10)
}
const freshBootstrap = () => vm.runInNewContext(source.slice(start, end) + '\nbootstrap')

// ---- (1) two different steps each start at discriminator 1 --------------
{
    const bootstrap = freshBootstrap()
    const a1 = discriminatorOf(bootstrap, 'STEP-A')
    const b1 = discriminatorOf(bootstrap, 'STEP-B')
    assert.equal(a1, 1, 'STEP-A launches at discriminator 1')
    assert.equal(b1, 1, 'STEP-B launches at discriminator 1, independent of STEP-A having gone first')
    console.log('PASS: two different steps each start their own sequence at 1')
}

// ---- (2) call order across steps never changes either step's sequence ---
{
    // Order 1: A, A, B, B, A
    const bootstrap1 = freshBootstrap()
    const order1 = [
        discriminatorOf(bootstrap1, 'STEP-A'),
        discriminatorOf(bootstrap1, 'STEP-A'),
        discriminatorOf(bootstrap1, 'STEP-B'),
        discriminatorOf(bootstrap1, 'STEP-B'),
        discriminatorOf(bootstrap1, 'STEP-A'),
    ]
    // Order 2: B, A, A, A, B — same per-step call counts (A×3, B×2), different
    // interleaving. If the discriminator were still a single shared counter,
    // STEP-A's sequence here would read 2,3,4 instead of 1,2,3, since B's
    // calls would consume shared ticks between them.
    const bootstrap2 = freshBootstrap()
    const order2 = [
        discriminatorOf(bootstrap2, 'STEP-B'),
        discriminatorOf(bootstrap2, 'STEP-A'),
        discriminatorOf(bootstrap2, 'STEP-A'),
        discriminatorOf(bootstrap2, 'STEP-A'),
        discriminatorOf(bootstrap2, 'STEP-B'),
    ]
    assert.deepEqual(order1, [1, 2, 1, 2, 3], 'order 1: A -> 1,2,3 and B -> 1,2 as each is called')
    assert.deepEqual(order2, [1, 1, 2, 3, 2], 'order 2: B -> 1,2 and A -> 1,2,3, same as order 1 despite the interleaving')
    console.log("PASS: each step's discriminator sequence is independent of the other step's call order")
}

// ---- (3) two launches of the SAME step still increment, never repeat ----
{
    const bootstrap = freshBootstrap()
    const first = discriminatorOf(bootstrap, 'STEP-C')
    const retry = discriminatorOf(bootstrap, 'STEP-C')
    assert.equal(first, 1, 'first launch of STEP-C is discriminator 1')
    assert.equal(retry, 2, 'a retry of the same STEP-C is discriminator 2, never repeating 1')
    console.log('PASS: two launches of the same step still get distinct, incrementing discriminators')
}
JS
