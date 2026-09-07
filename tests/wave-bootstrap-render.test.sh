#!/bin/bash

# Behavior suite for wave.js's bootstrap() render: what the claim step's
# packet redirect looks like for a read-class executor versus a write-class
# one.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. bootstrap() renders the claim bootstrap that hands every
# executor its packet — a read-class step's packet goes to a FILE
# (<TMP>/<step>.d/<step>.packet.md), opened afterward with the Read tool, and
# the brief prints no packet to stdout, which also keeps a large packet from
# tripping the harness's inline-output cap. Before this suite, no test in the
# repo exercised bootstrap()'s render output at all: a mutant that deletes
# both `jq -r '.data.packet'` lines (dropping the redirect from the claim
# chain entirely) passed every existing suite unchanged.
#
# HOW. wave.js fences bootstrap() in TEST-BEGIN/TEST-END `bootstrap` markers.
# This suite extracts that region and asserts the packet.md redirect, the
# Read-tool instruction naming it, and the absence of a stdout packet print,
# for both the isolated and shared claim forms — read-class (isWrite false)
# is the positive case, write-class (isWrite true) the negative one (the
# claim-and-redirect machinery is identical either way; isWrite only changes
# obligation 2's prose, so a mutant that broke the redirect would fail both
# equally, which is itself informative).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WAVE="${WAVE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/wave.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WAVE" ] || fatal "wave.js not found at ${WAVE}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-bootstrap-render.XXXXXX") || fatal "mktemp failed"
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

extract bootstrap > "${WORK}/bootstrap.js" || fatal "bad or missing TEST markers for bootstrap"
[ -s "${WORK}/bootstrap.js" ] || fatal "extracted bootstrap region is empty"
grep -q 'function bootstrap' "${WORK}/bootstrap.js" || fatal "bootstrap region does not contain bootstrap()"

cp "${WORK}/bootstrap.js" "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const row = { step: 'STEP-4381', issue: 'DOT-99', run: 'RUN-52' }
const r = { variant: 'std', model_requested: 'opus', effort_requested: 'high' }
const PACKET = '<TMP>/STEP-4381.d/STEP-4381.packet.md'

for (const isolated of [true, false]) {
    const label = isolated ? 'isolated' : 'shared'

    // ---- read-class: the positive case ----
    const readBrief = bootstrap(row, r, isolated, false)
    ok(readBrief.includes(`jq -r '.data.packet'`) && readBrief.includes(`> ${PACKET}`),
        `${label} read-class: the claim chain redirects the packet to ${PACKET}`)
    ok(readBrief.includes(`open ${PACKET} with the Read tool`),
        `${label} read-class: the brief carries the Read-tool instruction naming the packet file`)
    ok(!/^\s*docket step claim[\s\S]*\| cat\b/m.test(readBrief),
        `${label} read-class: nothing pipes the claim to a plain cat`)
    // The packet is never printed to stdout: the only place its bytes are
    // asked to land is the redirect target above.
    const packetMentions = (readBrief.match(/\.data\.packet/g) || []).length
    ok(packetMentions === 1,
        `${label} read-class: exactly one packet extraction, always redirected to a file (got ${packetMentions})`)

    // ---- write-class: the negative case — same redirect machinery ----
    const writeBrief = bootstrap(row, r, isolated, true)
    ok(writeBrief.includes(`jq -r '.data.packet'`) && writeBrief.includes(`> ${PACKET}`),
        `${label} write-class: the claim chain ALSO redirects the packet to a file (not a stdout-vs-file split by isWrite)`)
    ok(writeBrief.includes(`open ${PACKET} with the Read tool`),
        `${label} write-class: the brief also carries the Read-tool instruction`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
