#!/bin/bash

# Behavior suite for wave.js's claim path (claimPacket and claimFailure):
# the gate between a dispatched executor row and the executor's spawn.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent: `agent`, `workflow` and
# `stepShow` are stubs.
#
# WHY THIS EXISTS. The wave hands an executor its packet inside the spawn
# prompt, and the packet comes only from the module wave-claim wrote for this
# claim. claimPacket() decides from that module, never from the claim agent's
# prose: a valid module launches the executor even when the claim agent
# died, and no module launches nothing whatever the claim agent said. The
# reply only explains a missing module, routed into the same statuses the
# executor path settles (a CONFLICT relayed verbatim, a stop signal as
# `blocked`, anything else `spawn-failed`). One unreadable module path stops
# every later claim in the wave, so a wrong cwd strands one lease, not all.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-claim-path.XXXXXX") || fatal "mktemp failed"
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

for region in configuration classifier-retry park-signals orphaned-claim packet claim-path; do
    extract "$region" >> "${WORK}/regions.js" || fatal "bad or missing TEST markers for ${region}"
    printf '\n' >> "${WORK}/regions.js"
done

cat > "${WORK}/suite.js" <<'JS'
const fs = require('fs')
const vm = require('vm')
const regions = fs.readFileSync(process.argv[2], 'utf8')

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const row = { step: 'STEP-12', issue: 'DOT-5', run: 'RUN-9', attempt: 2, kind: 'executor' }
const r = { variant: 'std', model_requested: 'opus', effort_requested: 'high' }
const MODULE = '/repo/.claude/docket-packets/STEP-12.a3.js'
const PACKET = '== STEP STEP-12 implement@0\n== OUTPUT\nRecord an artifact of kind: change-summary\n'
const goodModule = (owner) => ({
    v: 1, step: 'STEP-12', owner, attempt: 3, expected_attempt: 3, re_minted: false, lease_expires_ms: 1,
    dir: '/tmp/claude-1000/STEP-12.d', token: '/tmp/claude-1000/STEP-12.d/STEP-12.token', dir_physical: '/private/tmp/claude-1000/STEP-12.d',
    packet_file: '/tmp/claude-1000/STEP-12.d/STEP-12.packet.md', packet_sha256: 'a'.repeat(64), packet: PACKET,
})
const NOT_FOUND = `Workflow script file not found: ${MODULE}`
const UNREADABLE = `workflow({scriptPath: '${MODULE}'}): scriptPath must be a script path this tool returned, or a file you can already read (the working directory or a directory you have added): ${MODULE}`

// A fresh wave per scenario. `replies` answers successive agent() calls (the
// command output as a string, null, or an Error to throw); a string reaches
// the wave as the claim agent's structured output, {output}, and only when
// the call passed a schema. `load` answers workflow().
function wave({ replies = [], load, cwd = '/repo', show = { status: 'claimed', attempt: '1' } } = {}) {
    const calls = { agent: [], workflow: [], stepShow: 0, log: [] }
    const sandbox = {
        input: { cwd },
        log: (l) => calls.log.push(l),
        agent: (prompt, opts) => {
            calls.agent.push({ prompt, opts })
            const next = replies.shift()
            if (next instanceof Error) return Promise.reject(next)
            if (next === undefined || next === null) return Promise.resolve(null)
            return Promise.resolve(typeof next === 'string' && opts.schema ? { output: next } : next)
        },
        workflow: (ref) => {
            calls.workflow.push(ref.scriptPath)
            const value = typeof load === 'function' ? load(ref.scriptPath) : load
            return value instanceof Error ? Promise.reject(value) : Promise.resolve(value)
        },
        stepShow: () => { calls.stepShow++; return Promise.resolve(show) },
    }
    vm.createContext(sandbox)
    vm.runInContext(regions + `
;globalThis.__api = { claimPacket, runParked, setLaunched: (n) => { agentsLaunched = n }, AGENT_LIFETIME_CAP }`, sandbox)
    return { api: sandbox.__api, calls }
}

;(async () => {
    // ---- a valid module launches; the claim agent is wave overhead ----
    {
        const { api, calls } = wave({ replies: ['CLAIMED STEP-12 attempt=3'], load: (p) => goodModule('wave:STEP-12:1') })
        const res = await api.claimPacket(row, r, 'lane')
        ok(res.ok && res.owner === 'wave:STEP-12:1' && res.claim.packet === PACKET,
            'a valid module hands the packet to the executor launch')
        ok(calls.agent.length === 1 && calls.agent[0].opts.label === 'STEP-12 · claim' &&
            calls.agent[0].opts.agentType === 'executor-read' && calls.agent[0].opts.model === 'haiku',
            'exactly one claim agent ran, haiku, as executor-read, labelled STEP-12 · claim')
        const schema = calls.agent[0].opts.schema
        ok(schema && JSON.stringify(schema.required) === '["output"]' && schema.properties.output.type === 'string',
            'the claim agent answers through the command-output schema')
        ok(calls.agent[0].prompt.includes(`--module '${MODULE}'`) && calls.workflow.length === 1 && calls.workflow[0] === MODULE,
            'the module the claim agent was told to write is the one the wave loads')
    }
    {
        const { api } = wave({ replies: [null], load: () => goodModule('wave:STEP-12:1') })
        const res = await api.claimPacket(row, r, 'lane')
        ok(res.ok && res.claim.packet === PACKET, 'a claim agent that died after the script finished still launches: the module decides')
    }

    // ---- no module: the reply explains, nothing launches ----
    {
        const { api, calls } = wave({
            replies: ['STEP-12\nCONFLICT\nstep implement@0 is not ready to claim: run is not active'],
            load: new Error(NOT_FOUND),
        })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'returned' && api.runParked(res.result),
            'a relayed run-not-active CONFLICT settles returned and reads as a run park')
        ok(calls.stepShow === 0, 'a run park spends no step show')
    }
    {
        const { api, calls } = wave({
            replies: ['STEP-12\nCONFLICT\nstep implement@0 is not ready to claim: the step is not pending'],
            load: new Error(NOT_FOUND),
        })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'claim-conflict' && calls.stepShow === 1 &&
            res.result.text.includes('not ready to claim: the step is not pending'),
            'a not-pending CONFLICT is diagnosed from the step row, the refusal kept verbatim')
    }
    for (const clause of [
        'its scope conflicts with a claimed or running step',
        'no concurrency headroom in its class (2 of 2 write in flight; cap from standard-change)',
    ]) {
        const { api, calls } = wave({
            replies: [`STEP-12\nCONFLICT\nstep implement@0 is not ready to claim: ${clause}`],
            load: new Error(NOT_FOUND),
        })
        const res = await api.claimPacket(row, r, 'lane')
        let reason = null
        try { reason = JSON.parse(res.result.text).data.blocked_reason } catch {}
        ok(!res.ok && res.result.status === 'skipped-not-ready' && reason === clause.replace(/ \(.*\)$/, '') &&
            !api.runParked(res.result) && calls.stepShow === 0,
            `a cross-launch "${clause}" refusal defers the lane with the clause as blocked_reason`)
    }
    for (const [signal, reply] of [
        ['CLAIM FAILED','CLAIM FAILED: STEP-12: database is locked'],
        ['CLAIM INCOMPLETE', 'CLAIM INCOMPLETE: STEP-12: bundle failed; the lease was ended with docket step fail'],
    ]) {
        const { api } = wave({ replies: [reply], load: new Error(NOT_FOUND) })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'blocked' && res.result.signal === signal && res.result.text === reply,
            `a ${signal} line settles blocked with the reply verbatim`)
    }
    {
        const { api } = wave({ replies: ['CLAIMED STEP-12 attempt=3 module=x'], load: new Error(NOT_FOUND) })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && res.result.text.includes('holds a live') &&
            res.result.text.includes('docket step reap STEP-12'),
            'a CLAIMED reply with no module settles spawn-failed and names the live lease for a reap')
    }
    {
        const { api } = wave({ replies: [null], load: new Error(NOT_FOUND) })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && res.result.text.includes('UNKNOWN'),
            'a silent claim agent and no module settles spawn-failed with the claim state UNKNOWN')
    }
    {
        const { api } = wave({ replies: ['CLAIMED STEP-12'], load: () => goodModule('wave:STEP-12:2') })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && res.result.text.includes('REFUSED'),
            "a module carrying another owner's claim is refused and launches nothing")
    }

    // ---- an unreadable module path stops every later claim ----
    {
        const { api, calls } = wave({ replies: ['CLAIMED STEP-12', 'CLAIMED STEP-13'], load: new Error(UNREADABLE) })
        const first = await api.claimPacket(row, r, 'lane')
        const second = await api.claimPacket({ ...row, step: 'STEP-13' }, r, 'lane')
        ok(!first.ok && first.result.status === 'spawn-failed', 'an unreadable module path settles its own row spawn-failed')
        ok(!second.ok && second.result.status === 'spawn-failed' && calls.agent.length === 1 && calls.workflow.length === 1,
            'after an unreadable module path no further claim agent runs this wave')
    }
    {
        const guard = new Error('PreToolUse:Workflow hook error: spawn held by an unacknowledged reap')
        const { api, calls } = wave({ replies: ['CLAIMED STEP-12', 'CLAIMED STEP-13'], load: guard })
        await api.claimPacket(row, r, 'lane')
        const second = await api.claimPacket({ ...row, step: 'STEP-13' }, r, 'lane')
        ok(!second.ok && calls.agent.length === 1,
            'any load error but a missing module stops further claims, however it is worded')
    }
    {
        const { api, calls } = wave({ replies: [null, 'CLAIMED STEP-13'], load: (p) =>
            p.includes('STEP-13') ? { ...goodModule('wave:STEP-13:1'), step: 'STEP-13',
                dir: '/tmp/claude-1000/STEP-13.d', token: '/tmp/claude-1000/STEP-13.d/STEP-13.token', dir_physical: '/private/tmp/claude-1000/STEP-13.d' }
                : new Error(NOT_FOUND) })
        const first = await api.claimPacket(row, r, 'lane')
        const second = await api.claimPacket({ ...row, step: 'STEP-13' }, r, 'lane')
        ok(!first.ok && second.ok && calls.agent.length === 2,
            "a missing module is one row's failure: the next row still claims and launches")
    }

    // ---- rows the wave cannot fence or place claim nothing ----
    {
        const { api, calls } = wave({})
        const res = await api.claimPacket({ ...row, attempt: undefined }, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && calls.agent.length === 0 && calls.workflow.length === 0,
            'a row with no attempt launches no claim agent')
    }
    {
        const { api, calls } = wave({ cwd: 'relative/repo' })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && calls.agent.length === 0,
            'a relative args.cwd launches no claim agent')
    }

    // ---- launch failures of the claim agent itself ----
    {
        const { api, calls } = wave({})
        api.setLaunched(api.AGENT_LIFETIME_CAP)
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'agent-cap' && calls.workflow.length === 0,
            'at the agent cap nothing is claimed and no module is loaded')
    }
    {
        const transient = new Error('[STEP-12 · claim] blocked by safety classifier: Stage 2 classifier error (usually transient)')
        const { api, calls } = wave({ replies: [transient, 'CLAIMED STEP-12'], load: () => goodModule('wave:STEP-12:1') })
        const res = await api.claimPacket(row, r, 'lane')
        ok(res.ok && calls.agent.length === 2 && calls.agent[0].prompt === calls.agent[1].prompt,
            'a transient classifier block resubmits the identical claim brief once')
    }
    {
        const content = new Error('[STEP-12 · claim] blocked by safety classifier: policy')
        const { api, calls } = wave({ replies: [content], load: new Error(NOT_FOUND) })
        const res = await api.claimPacket(row, r, 'lane')
        ok(!res.ok && res.result.status === 'spawn-failed' && calls.agent.length === 1,
            'a content block is not resubmitted, and with no module nothing launches')
    }

    console.log(`\n${pass} passed, ${fail} failed`)
    process.exit(fail === 0 ? 0 : 1)
})()
JS

node "${WORK}/suite.js" "${WORK}/regions.js" || exit 1

# spawn() must reach the executor only through claimPacket(), and the
# executor's prompt must be the brief carrying the claim's packet.
if [ "$(grep -c 'return claimPacket(row, r, phaseLabel).then((claimed) => claimed.ok' "$WAVE")" = 1 ] &&
    [ "$(grep -c 'countedAgent(executorBrief(row, owner, claim, iso, isWrite, input.cwd), opts(iso))' "$WAVE")" = 1 ]; then
    printf 'PASS: spawn() launches the executor only after claimPacket(), with the packet-bearing brief\n'
else
    printf 'FAIL: spawn() no longer gates the executor launch on claimPacket()\n' >&2
    exit 1
fi
