#!/bin/bash

# Behavior suite for wave.js's `packet` region: where a claim's packet module
# lands, how the claim agent is briefed, and which loaded modules the wave
# accepts before it spawns an executor with the packet inline.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. An executor is spawned only with a packet the wave loaded
# from the module wave-claim wrote for THIS claim. packetFromModule() is the
# gate: a module from another step, another owner, or an earlier attempt, or
# one whose token path is not the step's own, spawns nothing. Each refusal
# case below mutates exactly one field of an accepted module, so a check that
# stops being enforced turns its own case red.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-packet.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

awk '
    index($0, "TEST-END packet")   { open = 0; ends++ }
    open                           { print }
    index($0, "TEST-BEGIN packet") { open = 1; begins++ }
    END { if (begins != 1 || ends != 1) exit 1 }
' "$WAVE" > "${WORK}/suite.mjs" || fatal "bad or missing TEST markers for packet"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const row = { step: 'STEP-12', issue: 'DOT-5', run: 'RUN-9', attempt: 2 }
const r = { variant: 'std', model_requested: 'opus', effort_requested: 'high' }

// ---- the attempt fence and the module path ----
ok(expectedAttempt(row) === 3, 'a claim is fenced at the row attempt plus one')
ok(expectedAttempt({ ...row, attempt: 0 }) === 1, 'a never-claimed step is fenced at attempt 1')
ok(expectedAttempt({ step: 'STEP-12' }) === null && expectedAttempt({ ...row, attempt: '2' }) === null,
    'a row with no integer attempt has no fence')
ok(packetModulePath('/repo', row) === '/repo/.claude/docket-packets/STEP-12.a3.js',
    'the module lands under <cwd>/.claude/docket-packets, named for step and attempt')
ok(packetModulePath('/repo/', row) === '/repo/.claude/docket-packets/STEP-12.a3.js', 'a trailing slash on cwd is dropped')
ok(packetModulePath('repo', row) === '' && packetModulePath(undefined, row) === '',
    'a relative or missing cwd places no module')
ok(packetModulePath('/repo', { step: 'STEP-12' }) === '', 'a row with no attempt places no module')

// ---- the claim agent's brief ----
const owner = nextOwner('STEP-12')
const modulePath = packetModulePath('/repo', row)
const command = claimCommand(row, r, owner, modulePath)
const brief = claimBrief(row, command)
ok(command.startsWith(`~/.docket/bin/wave-claim --step STEP-12 --owner ${owner} --attempt 3 --module '${modulePath}' --metadata '`),
    'the claim command names step, owner, fenced attempt and quoted module path')
ok(brief.startsWith('Run exactly this one command:') && brief.includes(`\n  ${command}\n`), 'the brief is one command, verbatim')
ok(brief.includes('WAVE CLAIM: not a step execution'), 'the brief marks the agent as wave overhead')
ok(!/docket step (?:claim|record|complete)\s+STEP-\d+/.test(brief),
    "the brief never spells a claim or record of the step, so wave-usage cannot bill the step's executor for it")
ok(!/STEP-\d+\.d\b/.test(brief), "the brief names no step scratch dir, so the sibling guard has no sibling's dir to weigh")
ok(shellQuote(`it's`) === `'it'\\''s'`, 'shellQuote closes, escapes and reopens a single quote')

// ---- which loaded modules spawn an executor ----
const good = {
    v: 1, step: 'STEP-12', owner, attempt: 3, expected_attempt: 3, re_minted: false,
    lease_expires_ms: 1, dir: '/tmp/claude-1000/STEP-12.d', token: '/tmp/claude-1000/STEP-12.d/STEP-12.token',
    packet_file: '/tmp/claude-1000/STEP-12.d/STEP-12.packet.md', packet_sha256: 'a'.repeat(64),
    packet: '== STEP STEP-12 implement@0\n',
}
const accepted = packetFromModule(good, row, owner)
ok(accepted.ok && accepted.packet === good.packet && accepted.token === good.token && accepted.dir === good.dir &&
    accepted.attempt === 3 && accepted.reMinted === false && accepted.sha256 === good.packet_sha256,
    'a module for this claim is accepted with its packet, token, dir and attempt')
ok(packetFromModule({ ...good, attempt: 4, re_minted: true }, row, owner).ok,
    'a later attempt (a claim taken after this dispatch) is still this claim')
const refusals = [
    ['no object', null],
    ['an array', [good]],
    ['another format', { ...good, v: 2 }],
    ['another step', { ...good, step: 'STEP-13' }],
    ['another owner', { ...good, owner: 'wave:STEP-12:2' }],
    ['an earlier attempt', { ...good, attempt: 2 }],
    ['a non-integer attempt', { ...good, attempt: '3' }],
    ['a relative step dir', { ...good, dir: 'tmp/STEP-12.d', token: 'tmp/STEP-12.d/STEP-12.token' }],
    ["another step's dir", { ...good, dir: '/tmp/claude-1000/STEP-13.d', token: '/tmp/claude-1000/STEP-13.d/STEP-12.token' }],
    ['a token outside the step dir', { ...good, token: '/tmp/claude-1000/STEP-12.token' }],
    ['no packet', { ...good, packet: '' }],
    ['a non-string packet', { ...good, packet: ['x'] }],
]
for (const [what, mod] of refusals) {
    const res = packetFromModule(mod, row, owner)
    ok(res.ok === false && typeof res.why === 'string' && res.why !== '', `a module with ${what} is refused with a reason`)
}
ok(packetFromModule(good, { ...row, attempt: undefined }, owner).ok === false,
    'a row with no attempt never accepts a module')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
