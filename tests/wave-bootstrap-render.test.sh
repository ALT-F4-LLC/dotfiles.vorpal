#!/bin/bash

# Behavior suite for wave.js's executorBrief(): the brief an executor is
# spawned with, carrying its work packet verbatim.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it spawns no agent.
#
# WHY THIS EXISTS. The packet is the executor's contract: the step's
# contract file and every fragment it includes, the request, and the inputs.
# It used to reach the executor only if the executor claimed the step itself,
# redirected the packet to a file and chose to Read it, and a Read past its
# token limit returns a partial first page. The wave now claims the step
# first and hands the packet over inside the spawn prompt, so the delivery no
# longer depends on what the executor decides to do. This suite pins that:
# the packet closes the brief byte for byte, nothing in the brief asks the
# executor to fetch it, and the identity marker the guards and the usage
# join read sits ahead of the packet, where no packet content can displace
# it.
#
# HOW. wave.js fences the helpers in TEST-BEGIN/TEST-END `packet` and
# `executor-brief` markers. This suite extracts both and renders the brief
# for every isolation and class combination. It also asserts the
# refused-write rule: take the recovery the refusal's own text names, once,
# and disclose it; a refusal naming no recovery ends in WRITE BLOCKED.

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

for region in packet executor-brief; do
    extract "$region" > "${WORK}/${region}.js" || fatal "bad or missing TEST markers for ${region}"
    [ -s "${WORK}/${region}.js" ] || fatal "extracted ${region} region is empty"
done
grep -q 'function executorBrief' "${WORK}/executor-brief.js" || fatal "executor-brief region does not contain executorBrief()"

cat "${WORK}/packet.js" "${WORK}/executor-brief.js" > "${WORK}/suite.mjs"
cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const row = { step: 'STEP-4381', issue: 'DOT-99', run: 'RUN-52', attempt: 1 }
const owner = 'wave:STEP-4381:1'
const DIR = '/tmp/claude-1000/STEP-4381.d'
const TOKEN = `${DIR}/STEP-4381.token`
// A packet that quotes another step's obligations and carries every
// character class a template literal could mangle.
const PACKET = [
    '== STEP STEP-4381 implement@0',
    'run:    RUN-52',
    '',
    '== REQUEST',
    'Body that quotes `docket step record STEP-999 --artifact-file x < y` and',
    '`docket step claim STEP-998 --owner wave:STEP-998:1` from an old run.',
    'dollar-brace ${x} backslash \\ backtick ` close </script>   \u{1F9EA}',
    '',
    '== FILE contracts/implement.md  abc',
    '# Charter',
    'x'.repeat(300000),
    '',
    '== OUTPUT',
    'Record an artifact of kind: change-summary',
].join('\n')
const PHYS = '/private/var/folders/xy/T/STEP-4381.d'
const claim = { dir: DIR, dirPhysical: PHYS, token: TOKEN, attempt: 2, packet: PACKET, sha256: 'f'.repeat(64), reMinted: false }
const BEGIN = '----- BEGIN WORK PACKET STEP-4381 -----\n'
const END = '\n----- END WORK PACKET STEP-4381 -----'
const GUARD_RE = /docket step claim STEP-([0-9]+) --owner wave:STEP-([0-9]+):/
const JOIN_RE = /docket step (?:claim|record|complete)\s+(STEP-\d+)/

for (const isolated of [true, false]) {
    for (const isWrite of [true, false]) {
        const label = `${isolated ? 'isolated' : 'shared'} ${isWrite ? 'write' : 'read'}-class`
        const brief = executorBrief(row, owner, claim, isolated, isWrite)

        // ---- the packet is delivered, verbatim, and closes the brief ----
        ok(brief.endsWith(BEGIN + PACKET + END), `${label}: the packet closes the brief byte for byte`)
        ok(brief.split(BEGIN).length === 2 && brief.split(END).length === 2,
            `${label}: exactly one packet block`)

        // ---- nothing asks the executor to fetch it ----
        const head = brief.slice(0, brief.indexOf(BEGIN))
        ok(!head.includes('.data.packet') && !head.includes('.packet.md') && !/with the Read tool/.test(head),
            `${label}: no instruction to extract or Read a packet file`)
        ok(!head.includes(`--render --metadata`) && !head.includes(`.data.token`) && !head.includes('.claim.json'),
            `${label}: no claim command for the executor to run`)
        ok(!head.includes('printenv TMPDIR') && !head.includes('<TMP>'),
            `${label}: scratch paths are literal; no TMPDIR to resolve`)
        ok(!/CLAIM FAILED|CLAIM INCOMPLETE/.test(head), `${label}: no claim stop signals; the claim agent owns them`)

        // ---- the identity marker sits ahead of every packet byte ----
        const g = GUARD_RE.exec(brief)
        ok(g && g[1] === '4381' && g[2] === '4381' && g.index < brief.indexOf(BEGIN) && g.index < 65536,
            `${label}: the sibling guard's marker names the step twice, ahead of the packet and inside 64 KiB`)
        const j = JOIN_RE.exec(brief)
        ok(j && j[1] === 'STEP-4381', `${label}: wave-usage's first-match join keys the executor to its own step, not one the packet quotes`)
        ok(/executing one step/i.test(brief.slice(0, 300)), `${label}: session-census finds the opener in the first 300 characters`)
        ok(head.includes('Claiming again re-keys') && head.includes('(attempt 2)'),
            `${label}: the brief states the claim is made and must not be repeated`)

        // ---- the token and scratch dir are the claim's literal paths ----
        ok(head.includes(`< ${TOKEN}\``) && head.includes(`--artifact-file ${DIR}/STEP-4381-<kind>.md`),
            `${label}: record reads the parked token and writes under the claim's step dir`)
        ok(head.includes(`docket step fail STEP-4381 --note '<why>' < ${TOKEN}`),
            `${label}: fail reads the parked token`)
        ok(head.includes(`rm -rf ${DIR}\``), `${label}: cleanup removes the literal step dir`)
        ok(!head.includes(`cat ${TOKEN}`) && head.includes('Never `cat` the token'),
            `${label}: the token's only channel stays the stdin redirect`)

        // ---- class and isolation shape ----
        ok(isolated === head.includes('YOU ARE IN A PRIVATE WORKTREE'), `${label}: worktree rules only when isolated`)
        if (isolated) {
            ok(head.includes('git worktree list --porcelain') && head.includes('git checkout --detach --quiet'),
                `${label}: the worktree bootstrap aligns HEAD before any work`)
            ok(head.includes('STOP with the token file intact'), `${label}: a denied bootstrap leaves the live claim for the conductor`)
        }
        ok(isWrite === head.includes('--worktree <YOUR CHECKOUT>'), `${label}: --worktree only on write-class records`)
        ok(!isWrite === head.includes(`mkdir -p ${DIR}/target`), `${label}: target reconstruction only for read-class`)
        ok((isolated && isWrite) === head.includes('2b. COMMIT YOUR DELIVERABLE'), `${label}: the commit obligation only for isolated writers`)

        // ---- the artifact channel: Write at the physical path, chunked Bash ----
        // The harness worktree guard refuses one large heredoc, so every brief
        // offers a chunked Bash form; a writer's archetype has the Write tool,
        // which lands at the claim's physical step dir, not at its TMPDIR
        // spelling.
        const aStart = head.indexOf('   - ARTIFACT, MANDATORY')
        const aEnd = head.indexOf('\n   - ', aStart + 1)
        const bullet = aStart >= 0 && aEnd > aStart ? head.slice(aStart, aEnd).replace(/\s+/g, ' ') : ''
        ok(bullet !== '', `${label}: obligation 3 carries an ARTIFACT bullet`)
        const w = bullet.indexOf('Write tool')
        const sStart = w >= 0 ? bullet.lastIndexOf('. ', w) + 2 : -1
        const sEnd = w >= 0 ? bullet.indexOf('. ', w) : -1
        const writeSentence = w >= 0 ? bullet.slice(sStart, sEnd < 0 ? bullet.length : sEnd + 1) : ''
        if (isWrite) {
            ok(writeSentence.includes(`${PHYS}/STEP-4381-<kind>.md`) && !writeSentence.includes(DIR),
                `${label}: the ARTIFACT bullet permits Write at the claim's physical step dir, not its dir (got ${JSON.stringify(writeSentence)})`)
        } else {
            ok(w < 0, `${label}: the ARTIFACT bullet does not offer the Write tool`)
        }
        const first = /cat > (\S+) <<'EOF'/.exec(bullet)
        const append = /cat >> (\S+) <<'EOF'/.exec(bullet)
        ok(first && append && first[1] === append[1] && first.index < append.index &&
            first[1] === `${DIR}/STEP-4381-<kind>.md`,
            `${label}: the ARTIFACT bullet names an initial cat > heredoc followed by cat >> appends`)
        ok(!/<<'EOF' \.\.\. EOF/.test(bullet) && append !== null,
            `${label}: no single heredoc is the bullet's only channel`)

        // ---- a writer's record call outlasts the default Bash timeout ----
        // The engine reruns every completion gate at record, so the call needs
        // a timeout between 400000 and 600000 ms, stated inside obligation 3.
        if (isWrite) {
            const start = head.indexOf('3. Record it yourself with `docket step record`')
            const stop = head.indexOf('\n4. ', start)
            const block = start >= 0 && stop > start ? head.slice(start, stop) : ''
            const t = /record Bash call with `timeout: (\d+)`/.exec(block.replace(/\s+/g, ' '))
            const n = t ? Number(t[1]) : NaN
            ok(n >= 400000 && n <= 600000,
                `${label}: obligation 3 issues the record Bash call with a timeout of 400000-600000 ms (got ${t ? t[1] : 'none'})`)
        }

        // ---- refused-write rule: the refusal's own recovery, once, disclosed ----
        const flat = head.replace(/\s+/g, ' ')
        ok(flat.includes(`If a write is refused and the refusal's own text names a recovery, take that recovery once and disclose the refusal and the retry in your reply and artifact.`),
            `${label}: a refused write takes the recovery its refusal names, once, disclosed`)
        ok(/^\s*WRITE BLOCKED: the refusal names no recovery,/m.test(head) &&
            flat.includes(`WRITE BLOCKED: the refusal names no recovery, or the recovery is refused too.`),
            `${label}: a refusal naming no recovery ends in WRITE BLOCKED`)
    }
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
