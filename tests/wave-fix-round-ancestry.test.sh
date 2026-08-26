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
// The probe stub is scripted by COMMAND SHAPE, because the guard spends two
// distinct probes: the `docket step context … | grep` target read and the
// `git merge-base` ancestry check. Anything else (the pre-claim probe's
// `docket step show`) answers empty, which is fail-open for that path.
let CTX = ''          // target-probe answer
let GIT = ''          // merge-base-probe answer
let CTX_PROBES = 0
let GIT_PROBES = 0
let GIT_CMDS = []
const probe = (cmd, _label, _phase, _step) => {
    if (cmd.startsWith('git merge-base')) {
        GIT_PROBES++
        GIT_CMDS.push(cmd)
        return Promise.resolve(GIT)
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

const run = async (theRows, integrated, ctx, git) => {
    rows = theRows
    input = { policyText: '' }
    if (integrated !== undefined) input.integrated = integrated
    SPAWNED = []; GIT_CMDS = []
    CTX_PROBES = 0; GIT_PROBES = 0
    LOG.length = 0
    CTX = ctx || ''; GIT = git || ''
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
// (that the status kills the chain is asserted structurally by AC-fail above,
// and fenced predicate-level in tests/wave-park-signals.test.sh)
ok(!runParked({ status: 'parked-base-ancestry', text: 'x' }),
    'a base-ancestry park kills its issue, never the whole run')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
