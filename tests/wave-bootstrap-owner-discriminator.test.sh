#!/bin/bash

# Behavior suite for wave.js's claim owner discriminator: the number
# appended to `--owner wave:<step>:<n>` that distinguishes two claims of the
# SAME step in one wave.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The discriminator used to be a single counter shared
# across every step the wave rendered a claim for in one invocation,
# incremented once per call regardless of which step the call was for. That
# makes a step's own discriminator depend on how many OTHER steps' claims
# were rendered before it — which follows agent completion order (release()
# timing), not manifest order. The documented resume cache keys on exact
# prompt text: a resumed wave whose agents happen to settle in a different
# order than the original run renders a different owner string for the same
# step, and misses the resume cache on it even though nothing about that
# step's own retry state changed. A per-step counter removes the dependency:
# a step's first claim is always discriminator 1 and its next is always 2,
# regardless of what happened to any other step.
#
# WHAT IS PINNED HERE. (1) two different steps get independent discriminator
# sequences, each starting at 1; (2) the ORDER two different steps are
# claimed in never changes either step's own discriminator sequence; (3) two
# claims of the SAME step still get distinct, incrementing discriminators (1,
# then 2), so a second claim never presents the owner of an earlier one.
#
# HOW. It extracts wave.js's `packet` region (TEST-BEGIN/TEST-END markers)
# into a fresh VM context per scenario and reads the discriminator back off
# the `--owner wave:<step>:<n>` in the claim agent's rendered command.

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
const begin = source.indexOf('// TEST-BEGIN packet')
const end = source.indexOf('// TEST-END packet')
assert(begin >= 0 && end > begin, 'packet region markers exist')
const region = source.slice(begin, end)

const routing = {
    model: 'sonnet', effort: 'high', variant: 'sonnet-high',
    model_requested: 'sonnet', effort_requested: 'high',
}
const fresh = () => vm.runInNewContext(region +
    '\n;({ nextOwner, claimCommand, claimBrief })')
const discriminatorOf = (ctx, step) => {
    const row = { step, issue: 'DKT-1', run: 'RUN-1', attempt: 0 }
    const owner = ctx.nextOwner(step)
    const brief = ctx.claimBrief(row, ctx.claimCommand(row, routing, owner, `/repo/.claude/docket-packets/${step}.a1.js`))
    const line = brief.split('\n').find((l) => l.includes(`wave-claim --step ${step} --owner`))
    assert(line, `rendered claim command exists for ${step}`)
    const m = line.match(new RegExp(`--owner wave:${step}:(\\d+)`))
    assert(m, `owner discriminator is present for ${step}`)
    return parseInt(m[1], 10)
}

// ---- (1) two different steps each start at discriminator 1 --------------
{
    const ctx = fresh()
    assert.equal(discriminatorOf(ctx, 'STEP-A'), 1, 'STEP-A claims at discriminator 1')
    assert.equal(discriminatorOf(ctx, 'STEP-B'), 1, 'STEP-B claims at discriminator 1, independent of STEP-A having gone first')
    console.log('PASS: two different steps each start their own sequence at 1')
}

// ---- (2) call order across steps never changes either step's sequence ---
{
    const ctx1 = fresh()
    const order1 = ['STEP-A', 'STEP-A', 'STEP-B', 'STEP-B', 'STEP-A'].map((s) => discriminatorOf(ctx1, s))
    // Same per-step call counts (A×3, B×2), different interleaving. With a
    // single shared counter STEP-A's sequence here would read 2,3,4.
    const ctx2 = fresh()
    const order2 = ['STEP-B', 'STEP-A', 'STEP-A', 'STEP-A', 'STEP-B'].map((s) => discriminatorOf(ctx2, s))
    assert.deepEqual(order1, [1, 2, 1, 2, 3], 'order 1: A -> 1,2,3 and B -> 1,2 as each is called')
    assert.deepEqual(order2, [1, 1, 2, 3, 2], 'order 2: B -> 1,2 and A -> 1,2,3, same as order 1 despite the interleaving')
    console.log("PASS: each step's discriminator sequence is independent of the other step's call order")
}

// ---- (3) two claims of the SAME step still increment, never repeat ------
{
    const ctx = fresh()
    assert.equal(discriminatorOf(ctx, 'STEP-C'), 1, 'first claim of STEP-C is discriminator 1')
    assert.equal(discriminatorOf(ctx, 'STEP-C'), 2, 'a second claim of STEP-C is discriminator 2, never repeating 1')
    console.log('PASS: two claims of the same step still get distinct, incrementing discriminators')
}
JS
