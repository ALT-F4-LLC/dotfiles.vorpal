#!/bin/bash

# Behavior suite for wave.js's fix-round base-ancestry guard (DOT-871).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# git repository, no network; the probes the guard spends are stubbed.
#
# WHY THIS EXISTS. The conductor integrates a fix round by cherry-picking the
# sha on the change-summary's first line; nothing verified the NEXT round's
# judged tree descends from that integration. RUN-35 (VPL-160) round 2: all
# five judges recorded that round-1's commit was not an ancestor of the judged
# commit (`git merge-base --is-ancestor` non-zero, `git branch -a --contains`
# empty) and re-filed two defects round 1 had closed — one 17.37M-token round
# re-finding closed work. RUN-51 (AGT-643) rounds 5-6: fix@5's worktree was a
# SIBLING of round 4's commit; two full review rounds went to detecting the
# fork. The guard runs the judges' own check BEFORE the fanout spawns and
# parks the round as a 'parked-base-ancestry' RELAY finding instead — this
# suite asserts both halves: ancestry present spawns as before, ancestry
# absent parks with the evidence and without a single judge spawn.
#
# AND THE THIRD HALF (DOT-1022). The guard is only as good as the sha the
# conductor puts in `args.integrated`, and the hand-off text let it name the
# WRONG ROUND whenever fix@N and its review@N#k fanout were split across
# dispatches (a /pause, a wave that ended between them, a budget stop): "the
# most recent fix round" then IS fix@N, whose integration commit is the
# cherry-pick OF the judged tree, which can never be an ancestor of its own
# source. RUN-66 DISPATCH-360 parked 8 healthy fanout rows and killed 10
# downstream ones on that alone — 18 of 28 rows, one whole dispatch cycle.
# So before parking, the guard self-checks the map entry for a `cherry picked
# from commit <target>` trailer and FAILS OPEN when it finds one; the
# split-dispatch case below is that shape, with RUN-66's own shas.
#
# WHAT THIS SUITE CANNOT SEE: the real probes (haiku agents running the
# docket/git commands), the engine's re-offer of the parked round at the next
# dispatch, and the conductor's derivation of `args.integrated` (conduct
# SKILL.md) are all outside the extracted regions and asserted nowhere here.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-fix-round-ancestry.XXXXXX") || fatal "mktemp failed"
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

extract park-signals       > "${WORK}/park.js"     || fatal "bad or missing TEST markers for park-signals"
extract fix-round-ancestry > "${WORK}/ancestry.js" || fatal "bad or missing TEST markers for fix-round-ancestry"
extract stage-ladder       > "${WORK}/ladder.js"   || fatal "bad or missing TEST markers for stage-ladder"
[ -s "${WORK}/ancestry.js" ] || fatal "extracted fix-round-ancestry region is empty"
grep -q 'needsAncestryCheck' "${WORK}/ancestry.js" || fatal "fix-round-ancestry region does not contain needsAncestryCheck"

{
    # --- stub workflow globals the ladder reaches for ---
    cat <<'JS'
let rows = []
let input = { policyText: '' }
const policyVersion = 16
const LOG = []
const log = (m) => LOG.push(String(m))
const parallel = (fns) => Promise.all(fns.map((f) => f()))
let SPAWNED = []
const spawn = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve({ step: row.step, status: 'returned',
                             text: `${row.step} recorded (done)` })
}
const runGate = (row) => {
    SPAWNED.push(row.step)
    return Promise.resolve({ step: row.step, status: 'gate-passed',
                             text: '{"status":"done"}' })
}
// The probe stub is scripted by COMMAND SHAPE, because the guard spends up to
// three distinct probes: the `docket step context … | grep` target read, the
// `git merge-base` ancestry check, and — only on a non-zero merge-base — the
// `git log -1 --format=%B` self-check asking whether the map entry is the
// JUDGED round's own integration commit rather than the prior round's
// (DOT-1022). Anything else (the pre-claim probe's `docket step show`) answers
// empty, which is fail-open for that path.
let CTX = ''          // target-probe answer
let GIT = ''          // merge-base-probe answer
let SELF = ''         // cherry-pick self-check answer
let CTX_PROBES = 0
let GIT_PROBES = 0
let SELF_PROBES = 0
let GIT_CMDS = []
let SELF_CMDS = []
const probe = (cmd, _label, _phase, _step) => {
    if (cmd.startsWith('git merge-base')) {
        GIT_PROBES++
        GIT_CMDS.push(cmd)
        return Promise.resolve(GIT)
    }
    if (cmd.startsWith('git log')) {
        SELF_PROBES++
        SELF_CMDS.push(cmd)
        return Promise.resolve(SELF)
    }
    if (cmd.includes('docket step context')) {
        CTX_PROBES++
        return Promise.resolve(CTX)
    }
    return Promise.resolve('')
}

JS
    # park-signals and fix-round-ancestry land at MODULE scope so the unit
    # checks at the bottom can reach them; the ladder body closes over them.
    cat "${WORK}/park.js"
    cat "${WORK}/ancestry.js"
    printf 'const ladder = async () => {\n'
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
const ex = (step, issue, stage, executor, instance) =>
    ({ step, issue, stage, kind: 'executor', executor, instance })
const statusOf = (out, step) => (out.find((r) => r.step === step) || {}).status
const textOf = (out, step) => (out.find((r) => r.step === step) || {}).text || ''

// The RUN-35 shape: issue VPL-160's round-2 review fanout (three judge
// siblings, stage 0), its synthesize behind them, and a second issue's own
// round-2 fanout that carries NO integrated entry — the per-issue scoping
// control.
const PRIOR  = '31bd0cd8aa17'
const TARGET = 'fa9c3d217b40'
const CTX_HIT = `"target_sha":"${TARGET}"`
const RUN35 = () => [
    ex('STEP-801', 'VPL-160', 0, 'judge-correctness', 'review@2#1'),
    ex('STEP-802', 'VPL-160', 0, 'judge-architecture', 'review@2#2'),
    ex('STEP-803', 'VPL-160', 0, 'judge-testing', 'review@2#3'),
    ex('STEP-810', 'VPL-160', 1, 'synthesize', 'synthesize@2'),
    ex('STEP-901', 'HRN-99', 0, 'judge-correctness', 'review@2#1'),
]

const run = async (theRows, integrated, ctx, git, self) => {
    rows = theRows
    input = { policyText: '' }
    if (integrated !== undefined) input.integrated = integrated
    SPAWNED = []; GIT_CMDS = []; SELF_CMDS = []
    CTX_PROBES = 0; GIT_PROBES = 0; SELF_PROBES = 0
    LOG.length = 0
    CTX = ctx || ''; GIT = git || ''; SELF = self || ''
    return ladder()
}

// ---- AC (fail case): broken ancestry parks the fanout as a relay finding ----
let out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=1\n')
ok(['STEP-801', 'STEP-802', 'STEP-803'].every(
       (s) => statusOf(out, s) === 'parked-base-ancestry'),
    'AC-fail: every fanout sibling settles parked-base-ancestry')
ok(!SPAWNED.includes('STEP-801') && !SPAWNED.includes('STEP-802') &&
   !SPAWNED.includes('STEP-803'),
    'AC-fail: and not one judge is spawned')
ok(statusOf(out, 'STEP-810') === 'skipped-chain-dead' && !SPAWNED.includes('STEP-810'),
    "AC-fail: the round's later per-round row dies with the chain")
ok(SPAWNED.includes('STEP-901') && statusOf(out, 'STEP-901') === 'returned',
    'AC-fail: the OTHER issue (no integrated entry) is untouched')
ok(CTX_PROBES === 1 && GIT_PROBES === 1,
    'AC-fail: one shared verdict — one target probe and one git probe for three siblings')
ok(GIT_CMDS[0].includes(`git merge-base --is-ancestor ${PRIOR} ${TARGET}`) &&
   GIT_CMDS[0].includes(`git branch -a --contains ${PRIOR}`),
    'AC-fail: the probe carries both evidence directions the RUN-35 judges used')
const parkText = textOf(out, 'STEP-801')
ok(parkText.includes('BASE ANCESTRY BROKEN') &&
   parkText.includes(PRIOR) && parkText.includes(TARGET) &&
   parkText.includes('exited 1') && parkText.includes('ancestry-exit=1'),
    'AC-fail: the park report names both shas, the exit, and the probe evidence verbatim')
ok(parkText.includes('relay finding'),
    'AC-fail: the report says it is a relay finding, not a judge finding')
ok(SELF_PROBES === 1 &&
   SELF_CMDS[0].startsWith(`git log -1 --format=%B ${PRIOR}`) &&
   SELF_CMDS[0].includes(`cherry picked from commit ${TARGET}`),
    'AC-fail: one self-check probe ran before the park, on both shas')

// ---- DOT-1022: the SPLIT-DISPATCH shape — the map names the WRONG round ----
// RUN-66 DISPATCH-360 (harness.git, wave wf_01c45980-9ff). fix@2 and its
// review@2#k fanout landed in DIFFERENT dispatches, so by the time the
// conductor derived `integrated` the "most recent fix round" was fix@2
// ITSELF and the entry it passed was the cherry-pick OF the judged tree
// (`ff724ee` carries `(cherry picked from commit a6533be112700b…)`). A
// cherry-pick can never be an ancestor of its source, so merge-base exits 1
// on a perfectly healthy tree: 8 fanout rows parked, 10 downstream rows
// "skipped — chain died", 18 of 28 rows lost. The self-check catches it and
// FAILS OPEN — dispatch, do not park.
const RUN66_PRIOR  = 'ff724ee'          // fix@2's OWN integration commit
const RUN66_TARGET = 'a6533be112700b'   // the tree fix@2 produced, judged @2
out = await run(RUN35(), { 'VPL-160': RUN66_PRIOR },
    `"target_sha":"${RUN66_TARGET}"`, 'ancestry-exit=1\n',
    `cherrypick-of-target-exit=0\n`)
ok(SPAWNED.length === 5 && out.every((r) => r.status === 'returned'),
    'DOT-1022: prior is the cherry-pick of target — every row dispatches, none parks')
ok(!out.some((r) => r.status === 'parked-base-ancestry'),
    'DOT-1022: not one row settles parked-base-ancestry')
ok(LOG.some((l) => l.includes(
       "integrated map carries the judged round's OWN integration commit — " +
       'wrong round, fail-open')),
    'DOT-1022: the wave logs the wrong-round fail-open verdict')
ok(SELF_PROBES === 1 && GIT_PROBES === 1 && CTX_PROBES === 1,
    'DOT-1022: one shared verdict — the self-check costs exactly one extra probe')
ok(SELF_CMDS[0] ===
   `git log -1 --format=%B ${RUN66_PRIOR} | ` +
   `grep -q "cherry picked from commit ${RUN66_TARGET}"; ` +
   `echo "cherrypick-of-target-exit=$?"`,
    'DOT-1022: the self-check probe is the read-only trailer grep, both shas inline')

// A self-check that says NO (grep found no trailer: prior is a real prior
// round) leaves the park exactly as it was — this is RUN-35's true breakage.
out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=1\n',
    'cherrypick-of-target-exit=1\n')
ok(statusOf(out, 'STEP-801') === 'parked-base-ancestry' && !SPAWNED.includes('STEP-801'),
    'DOT-1022: a self-check that clears the map entry still parks the real breakage')

// A dead or unparseable self-check probe keeps the park: the merge-base
// evidence still stands, and the fail-open only fires on a POSITIVE detection.
out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=1\n',
    'API Error: Connection lost mid-response')
ok(statusOf(out, 'STEP-801') === 'parked-base-ancestry',
    'DOT-1022: an unparseable self-check does not dissolve the park')

// The self-check is spent ONLY on the park path — a healthy round pays nothing.
out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=0\n* main\n',
    'cherrypick-of-target-exit=0\n')
ok(SELF_PROBES === 0 && SPAWNED.length === 5,
    'DOT-1022: ancestry that holds spends no self-check probe at all')

// A target that cannot even resolve (merge-base exits 128) is the same park.
out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT,
    'fatal: Not a valid object name\nancestry-exit=128\n')
ok(statusOf(out, 'STEP-801') === 'parked-base-ancestry',
    'a merge-base that errors (exit 128) still parks — non-zero is non-zero')

// ---- AC (pass case): ancestry holds, the round dispatches exactly as before ----
out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=0\n* main\n')
ok(SPAWNED.length === 5 && out.every((r) => r.status === 'returned'),
    'AC-pass: with the prior commit an ancestor, every row spawns and returns')
ok(CTX_PROBES === 1 && GIT_PROBES === 1,
    'AC-pass: the verdict is still one shared probe pair')

// ---- Guard scoping: where the check must NOT fire at all ----
out = await run(RUN35(), undefined, CTX_HIT, 'ancestry-exit=1\n')
ok(CTX_PROBES === 0 && GIT_PROBES === 0 && SPAWNED.length === 5,
    'no `integrated` in args: zero probes, old behavior byte-for-byte')

out = await run([ex('STEP-701', 'VPL-160', 0, 'judge-correctness', 'review@1#1')],
    { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=1\n')
ok(CTX_PROBES === 0 && SPAWNED.includes('STEP-701'),
    'round 1 has no prior fix round: unguarded')

out = await run([ex('STEP-702', 'VPL-160', 0, 'fix', 'fix@2')],
    { 'VPL-160': PRIOR }, CTX_HIT, 'ancestry-exit=1\n')
ok(CTX_PROBES === 0 && SPAWNED.includes('STEP-702'),
    'a non-fanout per-round row (fix@2, no #k) is unguarded — it CREATES the tree')

out = await run(RUN35(), { 'VPL-160': 'HEAD~2' }, CTX_HIT, 'ancestry-exit=1\n')
ok(CTX_PROBES === 0 && SPAWNED.length === 5,
    'a non-sha integrated entry is treated as absent (nothing shell-shaped reaches a probe)')

// ---- Fail-open: every uncertain outcome dispatches as before ----
out = await run(RUN35(), { 'VPL-160': PRIOR }, '', 'ancestry-exit=1\n')
ok(CTX_PROBES === 1 && GIT_PROBES === 0 && SPAWNED.length === 5,
    'no target_sha on the bundle: fail-open, no git probe, everything spawns')

out = await run(RUN35(), { 'VPL-160': PRIOR }, '"target_sha":"$(rm -rf /)"', 'ancestry-exit=1\n')
ok(GIT_PROBES === 0 && SPAWNED.length === 5,
    'a non-hex target_sha never reaches a probe command (shape-checked), and spawns fail-open')

out = await run(RUN35(), { 'VPL-160': PRIOR }, CTX_HIT, 'API Error: Connection lost mid-response')
ok(SPAWNED.length === 5 && out.every((r) => r.status === 'returned'),
    'a dead git probe (no exit marker) is fail-open: the round dispatches')

// ---- Predicate units on the extracted helpers ----
ok(parseAncestryExit('ancestry-exit=0\n* main') === 0 &&
   parseAncestryExit('ancestry-exit=1\n') === 1 &&
   parseAncestryExit('ancestry-exit=128\n') === 128,
    'parseAncestryExit reads the exit marker wherever it sits')
ok(parseAncestryExit('') === null && parseAncestryExit('exit=1') === null,
    'parseAncestryExit refuses text without the marker (fail-open upstream)')
ok(fixRoundFanoutRound({ instance: 'review@3#4' }) === 3 &&
   fixRoundFanoutRound({ instance: 'review@1#1' }) === 1 &&
   fixRoundFanoutRound({ instance: 'fix@2' }) === 0 &&
   fixRoundFanoutRound({}) === 0,
    'fixRoundFanoutRound reads only the @N#k fanout grammar')
ok(parseAncestryTargetSha('"target_sha":"abc123f"') === 'abc123f' &&
   parseAncestryTargetSha('"target_sha":"not a sha"') === '' &&
   parseAncestryTargetSha('') === '',
    'parseAncestryTargetSha accepts hex shas only')
ok(!needsAncestryCheck({ kind: 'vote', issue: 'A', instance: 'gate@2#1' }, { A: 'abc123f' }),
    'needsAncestryCheck guards executor rows only')
ok(parseCherryPickOfTargetExit('cherrypick-of-target-exit=0\n') === 0 &&
   parseCherryPickOfTargetExit('cherrypick-of-target-exit=1') === 1 &&
   parseCherryPickOfTargetExit('') === null &&
   parseCherryPickOfTargetExit('ancestry-exit=0') === null,
    'parseCherryPickOfTargetExit reads its own marker and no other')
ok(cherryPickOfTargetCommand('abc123f', 'def456a').startsWith('git log -1 --format=%B abc123f') &&
   cherryPickOfTargetCommand('abc123f', 'def456a').includes('grep -q "cherry picked from commit def456a"') &&
   !/[;&|]\s*rm|>/.test(cherryPickOfTargetCommand('abc123f', 'def456a').replace(/echo "cherrypick-of-target-exit=\$\?"/, '')),
    'cherryPickOfTargetCommand is a read-only trailer grep in the prior→target direction')
// (that the status kills the chain is asserted structurally by AC-fail above,
// and fenced predicate-level in tests/wave-park-signals.test.sh)
ok(!runParked({ status: 'parked-base-ancestry', text: 'x' }),
    'a base-ancestry park kills its issue, never the whole run')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
