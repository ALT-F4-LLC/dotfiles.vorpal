#!/bin/bash

# Behavior suite for wave.js's dispatch SHARDS — one manifest, several
# concurrent wave launches, each running the lanes a deterministic partition
# assigns it.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The Workflow tool caps one invocation at 16 concurrent
# agents and 1000 over its lifetime, and a nested workflow() shares both with
# its parent, so a dispatch gets more headroom only from several top-level
# launches. Every launch receives the FULL manifest (the rows are hashed and
# pass verbatim) plus `shard: {index, of}`, computes the same partition, and
# runs only its own lanes. What has to hold: no lane runs in two launches or
# in none; writer lanes the engine never co-staged land in ONE launch, since
# the coupling rule that serializes them reads an in-flight set no sibling
# launch can see; the engine's class headroom, which is global, is never
# over-admitted in sum; and the return still carries one entry per manifest
# row in manifest order, a sibling's rows reading not-launched-other-shard.
#
# WHAT IS PINNED HERE. (1) no shard spec behaves exactly as one wave — every
# lane launches here, nothing settles other-shard; (2) certified-disjoint
# lanes split across shards largest-first onto the least-loaded shard, ties
# by lane name then lowest shard, and the union of what the shards launch is
# the whole manifest with no overlap; (3) uncertified writer lanes are welded
# into one shard and still serialize there, while a reader-only lane goes to
# a sibling; (4) more shards offered than lane units leaves the surplus idle
# — logged, nothing launched, every row other-shard; (5) a class present in
# several shards admits only its share of the certified count per shard; (6)
# the partition is deterministic across repeated launches; (7) a malformed
# spec, an index past `of`, and an `of` past SHARD_CAP each refuse to route.
#
# HOW. Like tests/wave-issue-lanes.test.sh it wraps the extracted ladder
# region in an async function with stub spawn/runGate/probe/parallel/log
# globals; `input.shard` is set per scenario.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-shard-partition.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

extract() { # <region> — body between the TEST-BEGIN/TEST-END markers
    awk -v r="$1" '
        index($0, "TEST-END " r)   { open = 0; ends++ }
        open                       { print }
        index($0, "TEST-BEGIN " r) { open = 1; begins++ }
        END {
            if (begins != 1 || ends != 1) {
                printf "expected exactly one TEST-BEGIN/TEST-END pair for %s, found %d/%d\n", r, begins, ends > "/dev/stderr"
                exit 1
            }
        }
    ' "$WAVE"
}

extract configuration      > "${WORK}/configuration.js" || fatal "bad or missing TEST markers for configuration"
extract park-signals       > "${WORK}/park.js"          || fatal "bad or missing TEST markers for park-signals"
extract target-envelope    > "${WORK}/envelope.js"      || fatal "bad or missing TEST markers for target-envelope"
extract fix-round-ancestry > "${WORK}/ancestry.js"      || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder       > "${WORK}/ladder.js"        || fatal "bad or missing TEST markers for stage-ladder"
grep -q 'shardPartition' "${WORK}/ladder.js" || fatal "stage-ladder region does not contain shardPartition"

{
    cat "${WORK}/configuration.js"
    cat <<'JS'
let rows = []
let input = {}
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
let SPAWNED = []
let GATES = []
let RESULTS = new Map()
const settleFor = (row) => {
    const r = RESULTS.get(row.step)
    return typeof r === 'function' ? r(row) : r
}
let HOLD = new Set()
let OPEN = new Map()
const spawn = (row) => {
    SPAWNED.push(row.step)
    const canned = settleFor(row) === undefined
        ? { step: row.step, status: 'returned', text: `${row.step} recorded (done)` }
        : settleFor(row)
    if (!HOLD.has(row.step)) return Promise.resolve(canned)
    return new Promise((resolve) => OPEN.set(row.step, () => resolve(canned)))
}
const runGate = (row) => {
    GATES.push(row.step)
    return Promise.resolve(settleFor(row) === undefined
        ? { step: row.step, status: 'gate-passed', text: '{"status":"done"}' }
        : settleFor(row))
}
let PROBED = []
const probe = (_cmd, _label, _phase, step) => {
    PROBED.push(step)
    return Promise.resolve('')
}
const stepShow = (step) => {
    PROBED.push(step)
    return Promise.resolve(null)
}

const ladder = async () => {
JS
    cat "${WORK}/park.js"
    cat "${WORK}/envelope.js"
    cat "${WORK}/ancestry.js"
    cat "${WORK}/ladder.js"
    printf '}\n'
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}
const settle = () => new Promise((r) => setTimeout(r, 0))
const finish = async (step) => {
    const r = OPEN.get(step)
    if (!r) throw new Error(`finish(${step}): not spawned yet, or not held`)
    OPEN.delete(step)
    r()
    await settle()
}
const start = (theRows, opts) => {
    rows = theRows
    input = (opts && opts.shard !== undefined) ? { shard: opts.shard } : {}
    SPAWNED = []; GATES = []; PROBED = []; LOG.length = 0
    RESULTS = new Map(Object.entries((opts && opts.results) || {}))
    HOLD = new Set((opts && opts.hold) || [])
    OPEN = new Map()
    return ladder()
}
const ex = (step, issue, stage, cls, extra) => Object.assign(
    { step, issue, stage, kind: 'executor', executor: cls === 'write' ? 'implement' : cls, class: cls },
    extra || {})
const vote = (step, issue, stage) => ({ step, issue, stage, kind: 'vote', voters: ['judge-correctness'] })
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status
const logged = (frag) => LOG.some((l) => l.includes(frag))
const otherShard = (out) => out.filter((r) => r.status === 'not-launched-other-shard').map((r) => r.step)

// Three certified-disjoint issues (every implement co-staged at stage 0),
// each implement -> judges -> gate -> synthesize -> verify.
const chain = (p, issue) => [
    ex(`${p}-0`, issue, 0, 'write'),
    ex(`${p}-1a`, issue, 1, 'judge-correctness'),
    ex(`${p}-1b`, issue, 1, 'judge-testing'),
    vote(`${p}-2`, issue, 2),
    ex(`${p}-3`, issue, 3, 'synthesize-findings'),
    ex(`${p}-4`, issue, 4, 'verify-ac'),
]
const THREE = () => [...chain('A', 'AGT-602'), ...chain('B', 'AGT-840'), ...chain('C', 'AGT-890')]

// ---- (1) no shard spec: one wave, exactly as before --------------------
let out = await start(THREE())
ok(out.length === 18 && otherShard(out).length === 0,
    'no shard: every row settles in this launch, none read other-shard')
ok(!logged('wave: shard'), 'no shard: nothing about shards is logged')
ok(['A-0', 'B-0', 'C-0', 'A-4', 'B-4', 'C-4'].every((s) => SPAWNED.includes(s)),
    'no shard: every lane launches here')

// ---- (2) certified-disjoint lanes split, union is the manifest ----------
// Three equal units: AGT-602 -> shard 0, AGT-840 -> shard 1, AGT-890 ties
// on load and takes the lowest shard, 0.
const launched = []
for (let index = 0; index < 2; index++) {
    out = await start(THREE(), { shard: { index, of: 2 } })
    launched.push({ spawned: [...SPAWNED], gates: [...GATES], out, log: [...LOG] })
}
ok(launched[0].spawned.includes('A-0') && launched[0].spawned.includes('C-0') && !launched[0].spawned.includes('B-0'),
    'split: shard 0 runs the first and third lanes')
ok(launched[1].spawned.includes('B-0') && !launched[1].spawned.includes('A-0') && !launched[1].spawned.includes('C-0'),
    'split: shard 1 runs the second lane')
ok(launched.every((l) => l.out.length === 18 && l.out.every((r, i) => r.step === THREE()[i].step)),
    'split: every shard returns one entry per manifest row, in manifest order')
ok(otherShard(launched[0].out).join(',') === THREE().filter((r) => r.issue === 'AGT-840').map((r) => r.step).join(','),
    "split: shard 0 reads exactly issue B's rows as other-shard")
ok(otherShard(launched[1].out).length === 12, "split: shard 1 reads the other two lanes' rows as other-shard")
{
    const all = new Set([...launched[0].spawned, ...launched[0].gates, ...launched[1].spawned, ...launched[1].gates])
    const overlap = launched[0].spawned.filter((s) => launched[1].spawned.includes(s))
    ok(all.size === 18 && overlap.length === 0, 'split: the shards together launch every row once')
}
ok(launched[0].log.some((l) => l.includes('wave: shard 1 of 2') && l.includes('12 of 18 row(s)')),
    'split: the shard log names its index, the count, and its row share')
ok(launched[0].log.some((l) => l.includes('class headroom divided')) &&
   launched[0].log.some((l) => l.includes('write≤1')),
    'split: the write class sits in both shards, so each admits half its certified two')

// ---- (3) uncertified writers weld into one shard; readers go elsewhere --
// A and B: writers never co-staged (B rationed to stage 1). C: reader-only.
const COUPLED = () => [
    ex('A-0', 'AGT-602', 0, 'write'),
    ex('A-1', 'AGT-602', 1, 'judge-correctness'),
    ex('A-2', 'AGT-602', 2, 'write', { executor: 'fix' }),
    ex('B-1', 'AGT-840', 1, 'write', { status: 'staged' }),
    ex('B-2', 'AGT-840', 2, 'judge-correctness'),
    ex('C-0', 'AGT-890', 0, 'research'),
    ex('C-1', 'AGT-890', 1, 'investigate'),
]
let run = start(COUPLED(), { shard: { index: 0, of: 2 }, hold: ['A-0'] })
await settle()
ok(SPAWNED.includes('A-0') && !SPAWNED.includes('B-1') && !SPAWNED.includes('C-0'),
    "weld: shard 0 holds A and B together and C is elsewhere")
ok(logged('cross-issue coupling') && LOG.some((l) => l.startsWith('B-1: waiting — writer A-0')),
    "weld: B's writer still serializes behind A's inside the shard")
await finish('A-0')
out = await run
ok(SPAWNED.includes('B-1') && SPAWNED.includes('A-2') && SPAWNED.includes('B-2'),
    'weld: the welded lanes run to the end in their shard')
ok(otherShard(out).join(',') === 'C-0,C-1', "weld: C's rows read other-shard in shard 0")
out = await start(COUPLED(), { shard: { index: 1, of: 2 } })
ok(SPAWNED.join(',') === 'C-0,C-1' && otherShard(out).length === 5,
    'weld: shard 1 runs the reader-only lane and nothing else')

// ---- (4) more shards than units: the surplus idles ----------------------
out = await start(COUPLED(), { shard: { index: 2, of: 3 } })
ok(SPAWNED.length === 0 && GATES.length === 0 && otherShard(out).length === 7,
    'idle: a shard past the unit count launches nothing and reads every row other-shard')
ok(logged('idle shard') && logged('1 idle: fewer lane units than shards'),
    'idle: the log says why the shard is idle')

// ---- (5) class headroom is shared: each shard admits its share ---------
// judge is certified at two (A-1a, A-1b co-staged). HRN-2 has more rows, so
// it takes shard 0 and HRN-1 takes shard 1; judge sits in both, so each
// admits one at a time.
const HEADROOM = () => [
    ex('A-0', 'HRN-1', 0, 'write'),
    ex('A-1a', 'HRN-1', 1, 'judge'),
    ex('A-1b', 'HRN-1', 1, 'judge'),
    ex('B-0', 'HRN-2', 0, 'write'),
    ex('B-1', 'HRN-2', 1, 'synthesize-findings'),
    ex('B-2a', 'HRN-2', 2, 'judge'),
    ex('B-2b', 'HRN-2', 2, 'judge'),
]
run = start(HEADROOM(), { shard: { index: 1, of: 2 }, hold: ['A-1a'] })
await settle()
ok(SPAWNED.includes('A-0') && SPAWNED.includes('A-1a') && !SPAWNED.includes('A-1b'),
    'headroom: the second judge waits while the first holds the shard share of one')
ok(logged('judge≤1 (certified 2+ over 2 shards)'), 'headroom: the log names the divided cap')
ok(logged('1 row(s) of class judge in flight — the manifest certifies at most 1 concurrent'),
    'headroom: the wait names the shard-local bound')
await finish('A-1a')
out = await run
ok(SPAWNED.includes('A-1b') && statusOf(out, 'A-1b') === 'returned',
    'headroom: the second judge launches once the first returns')
ok(!SPAWNED.includes('B-0') && otherShard(out).length === 4, "headroom: HRN-2's rows belong to shard 0")

// ---- (6) determinism: the same launch twice picks the same lanes -------
const first = [...(await start(THREE(), { shard: { index: 0, of: 2 } }), SPAWNED)]
const second = [...(await start(THREE(), { shard: { index: 0, of: 2 } }), SPAWNED)]
ok(first.join(',') === second.join(','), 'determinism: a repeated launch spawns the identical set in the identical order')

// ---- (7) malformed specs refuse to route --------------------------------
const refuses = async (shard, frag, label) => {
    try {
        await start(THREE(), { shard })
        ok(false, label)
    } catch (e) {
        ok(String(e.message).includes('args.shard must be') && String(e.message).includes(frag) &&
           String(e.message).includes('Refusing to route'), label)
    }
}
await refuses({ index: 2, of: 2 }, 'out of range', 'refuse: index past `of`')
await refuses({ index: 0, of: SHARD_CAP + 1 }, `exceeds SHARD_CAP ${SHARD_CAP}`, 'refuse: `of` past SHARD_CAP')
await refuses({ index: '0', of: 2 }, 'non-integer', 'refuse: a non-integer index')
await refuses('1/2', 'not an object', 'refuse: a string spec')
ok(SPAWNED.length === 0, 'refuse: nothing launched on a refused spec')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
