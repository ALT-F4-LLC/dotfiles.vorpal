#!/bin/bash

# Behavior suite for wave.js's fail-closed writer-isolation branch.
#
# When an isolated spawn rejects because the harness could not create the
# worktree, the spawn catch must return `isolation-unavailable` and launch
# nothing: relaunching without isolation would put a writer in the shared
# checkout. This suite runs the real catch handler (the `spawn-catch` fenced
# region) with a counting launch spy, so reintroducing a `launch(false)`
# fallback fails here instead of relying on review.
#
# Needs only `node` and `awk`; it never runs a wave. WAVE_JS overrides the
# wave.js path for mutant runs.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-isolation-unavailable.XXXXXX") || fatal "mktemp failed"
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

for region in configuration classifier-retry spawn-catch; do
    extract "$region" > "${WORK}/${region}.js" \
        || fatal "bad or missing TEST markers for ${region}"
    [ -s "${WORK}/${region}.js" ] || fatal "extracted ${region} region is empty"
done

cat "${WORK}/configuration.js" "${WORK}/classifier-retry.js" "${WORK}/spawn-catch.js" > "${WORK}/suite.js"
cat >> "${WORK}/suite.js" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// Runs the real handler against one rejection and records every relaunch.
function settle(err, isolated) {
    const calls = { launch: [], failed: 0, retry: [] }
    const handler = spawnCatch({
        row: { step: 'STEP-7' },
        isolated,
        log: () => {},
        launch: (iso, retried) => { calls.launch.push(iso); return { step: 'STEP-7', status: 'relaunched' } },
        failed: () => { calls.failed++; return { step: 'STEP-7', status: 'spawn-failed' } },
        retryTransient: (e, iso) => { calls.retry.push(iso); return { step: 'STEP-7', status: 'retried' } },
    })
    return { result: handler(err), calls }
}

const WORKTREE_ERRORS = [
    new Error('failed to create worktree: base branch main not found'),
    new Error('base branch is missing'),
    new Error('Worktree creation failed'),
]
for (const err of WORKTREE_ERRORS) {
    const { result, calls } = settle(err, true)
    ok(result && result.status === 'isolation-unavailable',
        `isolated spawn rejected with "${err.message}" yields isolation-unavailable`)
    ok(calls.launch.length === 0 && calls.retry.length === 0,
        `isolated spawn rejected with "${err.message}" launches nothing further`)
    ok(calls.failed === 0, `"${err.message}" is not settled as spawn-failed`)
    ok(result && typeof result.text === 'string' && result.text.includes(err.message),
        `the isolation-unavailable text carries the original error "${err.message}"`)
}

{
    const { result, calls } = settle(new Error('failed to create worktree'), false)
    ok(result && result.status === 'spawn-failed',
        'a worktree-worded error with isolation off yields spawn-failed')
    ok(calls.launch.length === 0, 'a non-isolated spawn error launches nothing further')
}

{
    const { result, calls } = settle(new Error('network timeout'), true)
    ok(result && result.status === 'spawn-failed',
        'an isolated spawn error not matching base branch|worktree yields spawn-failed')
    ok(calls.launch.length === 0, 'an unmatched isolated spawn error launches nothing further')
}

{
    const block = new Error('[STEP-7 · implement] blocked by safety classifier: Stage 2 classifier error (usually transient)')
    const { result, calls } = settle(block, true)
    ok(result && result.status === 'retried' && calls.retry.length === 1 && calls.retry[0] === true,
        'a transient classifier block on an isolated spawn retries with isolation kept on')
    ok(calls.launch.length === 0, 'the transient retry goes only through retryTransient')
}

{
    const { result, calls } = settle(new AgentCapError(), true)
    ok(result && result.status === 'agent-cap', 'an AgentCapError yields agent-cap')
    ok(calls.launch.length === 0 && calls.failed === 0, 'agent-cap launches nothing and is not spawn-failed')
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js" || exit 1

# spawn() must route its top-level rejection through the fenced handler, or
# the behavior above stops describing the live path.
if [ "$(grep -c '\.catch(spawnCatch({ row, isolated, log, launch, failed, retryTransient }))' "$WAVE")" = 1 ]; then
    printf 'PASS: spawn() settles its rejected launch through spawnCatch at exactly one call site\n'
else
    printf 'FAIL: spawn() no longer settles its rejected launch through spawnCatch\n' >&2
    exit 1
fi
