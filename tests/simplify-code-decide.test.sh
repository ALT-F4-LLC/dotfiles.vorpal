#!/bin/bash

# Behavior suite for simplify-code.js's pure decisions: the per-depth agent
# caps, argument parsing, which paths can be units, how scout returns merge and
# rank, which refuted items survive, and which model and effort each seat gets.
# It also pins the skill's contract: read-only on the checkout, with Docket
# issues as its only output.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The skill hands a discovery round a named depth and trusts
# the workflow to hold the agent count under that depth's cap, because the
# round runs unattended under /loop and a drain and nothing else bounds its
# cost. The exclusion and merge helpers decide which units become issues, so
# a regression there files cruft removal against a test file or a security
# boundary. The workflow must stay read-only: a writer seat would let a
# discovery round edit the checkout. Each is exercised here without a run.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOW="${SIMPLIFY_CODE_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/simplify-code.js}"
SKILL="${SIMPLIFY_CODE_SKILL:-${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-code/SKILL.md}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$WORKFLOW" ] || fatal "simplify-code.js not found at ${WORKFLOW}"
DISCOVERY="${SIMPLIFY_CODE_DISCOVERY:-${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-code/references/discovery.md}"
[ -f "$SKILL" ] || fatal "SKILL.md not found at ${SKILL}"
[ -f "$DISCOVERY" ] || fatal "discovery.md not found at ${DISCOVERY}"
for sibling in catalog.md gates.md; do
    [ -f "$(dirname "$DISCOVERY")/${sibling}" ] || fatal "${sibling} not found beside ${DISCOVERY}"
done
for tool in node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/simplify-code-decide.XXXXXX") || fatal "mktemp failed"
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
    ' "$WORKFLOW"
}

extract simplify-code-decide > "${WORK}/region.js" || fatal "bad or missing TEST markers for simplify-code-decide"

cat > "${WORK}/cases.js" <<'JS'
const fs = require('fs')
let pass = 0
let fail = 0
const ok = (cond, label) => {
  if (cond) { pass++; console.log(`PASS: ${label}`) } else { fail++; console.error(`FAIL: ${label}`) }
}
const throws = (fn) => { try { fn(); return false } catch (e) { return true } }

// Depth parsing and caps.
ok(parseDepth(undefined) === 'simple', 'no depth means simple')
ok(parseDepth('') === 'simple', 'an empty depth means simple')
ok(parseDepth('deep') === 'deep', 'deep parses')
ok(throws(() => parseDepth('10')), 'a number is not a depth')
ok(throws(() => parseDepth('toString')), 'an inherited property name is not a depth')
ok(agentTotal('simple') === 10, 'simple plans 10 agents')
ok(agentTotal('standard') === 15, 'standard plans 15 agents')
ok(agentTotal('deep') >= 20 && agentTotal('deep') <= 30, 'deep plans between 20 and 30 agents')
for (const d of ['simple', 'standard', 'deep']) {
  ok(agentTotal(d) <= DEPTHS[d].cap, `${d} plans within its cap`)
}
ok(DEPTHS.simple.cap < DEPTHS.standard.cap && DEPTHS.standard.cap < DEPTHS.deep.cap, 'caps rise with depth')
ok(scoutTasks('simple').length === 7, 'simple seats one scout per section plus one combined signal scout')
ok(scoutTasks('standard').length === 10, 'standard seats six section scouts and four signal scouts')
ok(scoutTasks('deep').length === 16, 'deep seats two angles per section plus four signal scouts')
ok(new Set(scoutTasks('deep').map((t) => t.source)).size === 16, 'every deep scout has a distinct source')
ok(scoutTasks('simple').filter((t) => t.kind === 'section').map((t) => t.section).sort().join('|') === [...SECTIONS].sort().join('|'), 'every catalog pattern section gets a scout')
ok(!SECTIONS.includes('Report only') && !SECTIONS.includes('Leave alone'), 'Report only and Leave alone are not fan-out sections')
const budget = makeBudget(3)
budget.take(); budget.take(); budget.take()
ok(budget.used() === 3, 'the budget counts seats')
ok(throws(() => budget.take()), 'the budget refuses a seat past the cap')

// Mode: discovery only. There is no writer seat to ask for.
ok(parseMode(undefined) === 'discover' && parseMode('') === 'discover' && parseMode('discover') === 'discover', 'mode defaults to discover')
ok(throws(() => parseMode('work')), 'the removed work mode is refused, not run as a discovery round')
ok(throws(() => parseMode('both')), 'an unknown mode is refused')

// Exclusion.
ok(exclusionReason('src/a.test.ts', []) === 'test', 'a .test file is a test')
ok(exclusionReason('tests/foo.sh', []) === 'test', 'a tests directory file is a test')
ok(exclusionReason('pkg/test_util.py', []) === 'test', 'a test_ python file is a test')
ok(exclusionReason('pkg/util_test.go', []) === 'test', 'a _test go file is a test')
ok(exclusionReason('node_modules/x/index.js', []) === 'generated', 'node_modules is vendored')
ok(exclusionReason('Cargo.lock', []) === 'generated', 'a lockfile is generated')
ok(exclusionReason('src/lib.rs', ['src/lib.rs']) === 'ledger', 'a ledgered path is excluded')
ok(exclusionReason('src/mod/a.rs', ['src/mod']) === 'ledger', 'a ledgered directory excludes its files')
ok(exclusionReason('src/modx/a.rs', ['src/mod']) === '', 'a ledgered directory does not exclude a sibling with the same prefix')
ok(exclusionReason('src/auth/login.ts', []) === 'security', 'an auth path is a security boundary')
ok(exclusionReason('src/crypto.rs', []) === 'security', 'a crypto file is a security boundary')
ok(exclusionReason('src/authors.ts', []) === '', 'a word that only contains auth is not a boundary')
ok(exclusionReason('src/util/strings.ts', []) === '', 'an ordinary source file can be a unit')

// Merge, partition, rank.
const f = (entry, lines, cls = 'probe') => ({ entry, section: 'S', proofClass: cls, lines, symbol: 's', evidence: 'x' })
const unit = (path, findings, extra = {}) => ({ path, kind: 'file', findings, testFiles: [], evidencePaths: [], reportOnly: [], securityBoundary: '', ...extra })
const merged = mergeUnits([
  { source: 'section:Dead code', units: [unit('a.js', [f('Unused import', [1], 'reachability')], { testFiles: ['a.test.js'] })] },
  { source: 'signal:unused', units: [unit('a.js', [f('Unused import', [1], 'reachability'), f('Unused function or class', [9], 'reachability')], { evidencePaths: ['b.js'] })] },
  null,
  { source: 'signal:report-only', units: [unit('b.js', [], { reportOnly: [{ item: 'Swallowed exception', symbol: 'load', lines: [4], note: 'n' }] })] },
])
const a = merged.find((u) => u.path === 'a.js')
ok(merged.length === 2, 'units merge by path and a null return is skipped')
ok(a.findings.length === 2, 'the same entry on the same lines merges to one finding')
ok(a.sources.length === 2 && a.testFiles[0] === 'a.test.js' && a.evidencePaths[0] === 'b.js', 'sources, tests, and evidence paths are unioned')
const part = partitionUnits([unit('c.js', [f('X', [1])], { securityBoundary: 'sessions' }), unit('src/auth/z.js', [f('X', [1])]), unit('t/a.test.js', [f('X', [1])]), unit('d.js', [f('X', [1])])], [])
ok(part.kept.length === 1 && part.kept[0].path === 'd.js', 'only the plain unit is kept')
ok(part.securitySkipped.length === 2 && part.securitySkipped.some((s) => s.boundary === 'sessions'), 'a scout-flagged and a path-flagged boundary are both skipped')
ok(part.excluded.test === 1, 'a test file is counted as excluded')
const ranked = rankUnits(merged)
ok(ranked[0].path === 'a.js' && ranked[0].score > ranked[1].score, 'more findings from more scouts rank first')
ok(ranked[0].pickable === true, 'a unit with a test is pickable')
ok(pickable(unit('e.js', [f('Narrating comment', [1], 'inert')])) === true, 'an inert-only unit with no tests is pickable')
ok(pickable(unit('e.js', [f('Forwarding wrapper', [1], 'probe')])) === false, 'a probe unit with no tests is not pickable')
ok(pickable(unit('e.js', [])) === false, 'a unit with no findings is not pickable')

// Verdicts.
const vu = unit('v.js', [f('Unused import', [1], 'reachability'), f('Dead store', [5])], { reportOnly: [{ item: 'Swallowed exception', symbol: 's', lines: [8], note: 'n' }] })
const up = (id) => ({ id, refuted: false, reason: '' })
const rf = (id) => ({ id, refuted: true, reason: 'r' })
const one = applyVerdicts(vu, [{ verdicts: [up(0), rf(1), up(2)] }], 1)
ok(one.findings.length === 1 && one.reportOnly.length === 1 && one.refutedCount === 1, 'one refuter: an upheld item survives and a refuted one is dropped')
const two = applyVerdicts(vu, [{ verdicts: [up(0), up(1), up(2)] }, { verdicts: [up(0), rf(1), up(2)] }], 2)
ok(two.findings.length === 1 && two.findings[0].entry === 'Unused import', 'two refuters: both must uphold')
const missing = applyVerdicts(vu, [{ verdicts: [up(0), up(1), up(2)] }, null], 2)
ok(missing.findings.length === 0 && missing.reportOnly.length === 0, 'two refuters: a missing vote refutes')
const junk = applyVerdicts(vu, [{ verdicts: [up(7), up(-1), up(0)] }], 1)
ok(junk.findings.length === 1, 'an out-of-range verdict id is ignored')
ok(upholdMin(1) === 1 && upholdMin(2) === 2 && upholdMin(3) === 2, 'the uphold threshold is a majority')
ok(one.refutedKeys.length === 1 && one.refutedKeys[0] === 'v.js#Dead store#s', 'a refuted finding is remembered by path, entry, and symbol')
const roRefuted = applyVerdicts(vu, [{ verdicts: [up(0), up(1), rf(2)] }], 1)
ok(roRefuted.refutedKeys.length === 1 && roRefuted.refutedKeys[0] === 'v.js#Swallowed exception#s', 'a refuted report-only item is remembered by path, item, and symbol')
const dropped = dropRefuted([vu], ['v.js#Dead store#s', 'v.js#Swallowed exception#s'])
ok(dropped[0].findings.length === 1 && dropped[0].reportOnly.length === 0, 'remembered keys are not re-found')
const failedSeat = applyVerdicts(vu, [null], 1)
ok(failedSeat.refutedKeys.length === 0 && failedSeat.findings.length === 0, 'a refuter that returned nothing refutes nothing and remembers nothing')
ok(failedSeat.unconfirmedCount === 3 && failedSeat.refutedCount === 0, 'items with no vote are unconfirmed, not refuted')
const piped = findingKey('a.ts', { entry: 'Dead store', symbol: 'x | y' })
ok(!piped.includes('|'), 'a key never carries the queue column separator')
const keptNotRefuted = applyVerdicts(vu, [{ verdicts: [up(0), up(1), up(2)] }, { verdicts: [up(0), up(1), up(2)] }, { verdicts: [rf(0), up(1), up(2)] }], 3)
ok(keptNotRefuted.refutedKeys.length === 0 && keptNotRefuted.findings.length === 2 && keptNotRefuted.reportOnly.length === 1, 'an item a majority kept is not remembered as refuted')
const twin = applyVerdicts(unit('t.js', [f('Restated comment', [1]), f('Restated comment', [9])]), [{ verdicts: [up(0), rf(1)] }], 1)
ok(twin.findings.length === 1 && twin.refutedKeys.length === 0, 'a refuted twin sharing a key with a kept finding is not remembered')
ok(twin.unconfirmedCount === 0 && twin.refutedCount === 1, 'a refuted twin still counts as refuted, not unvoted')
const twins = applyVerdicts(unit('t.js', [f('Restated comment', [1]), f('Restated comment', [9])]), [{ verdicts: [rf(0), rf(1)] }], 1)
ok(twins.refutedKeys.length === 1 && twins.refutedCount === 2 && twins.unconfirmedCount === 0, 'two refuted twins are one key and two refutations')
const mixed = applyVerdicts(unit('t.js', [f('Restated comment', [1]), f('Restated comment', [9])]), [{ verdicts: [rf(0)] }], 1)
ok(mixed.refutedKeys.length === 0 && mixed.refutedCount === 1 && mixed.unconfirmedCount === 1, 'a refuted twin does not hide an unvoted twin')
const dupSym = mergeUnits([{ source: 'a', units: [unit('d.js', [], { reportOnly: [{ item: 'Hollow test', symbol: 'parse', lines: [1], note: 'n' }, { item: 'Hollow test', symbol: 'parse()', lines: [1], note: 'n' }] })] }], '/repo')
ok(dupSym[0].reportOnly.length === 1, 'parse and parse() are one report-only item')
ok(findingKey('a.ts', { entry: 'E', symbol: 'parse()' }) === findingKey('a.ts', { entry: 'E', symbol: ' parse ' }), 'a symbol key ignores a trailing call and spacing')
ok(!findingKey('a.ts', { entry: 'E', symbol: 'x\ny' }).includes('\n'), 'a key never carries a newline')
const otherSymbol = dropRefuted([unit('v.js', [], { reportOnly: [{ item: 'Swallowed exception', symbol: 'other', lines: [9], note: 'n' }] })], ['v.js#Swallowed exception#s'])
ok(otherSymbol[0].reportOnly.length === 1, 'a refuted key does not suppress the same item under another symbol')
const handKey = dropRefuted([unit('h.js', [f('Dead store', [3])])], ['h.js#Dead store#s()'])
ok(handKey[0].findings.length === 0, 'a hand-built cleanup key with a trailing call still drops the finding')
const handKey2 = dropRefuted([unit('h.js', [f('Dead store', [3])])], ['h.js#Dead store# s '])
ok(handKey2[0].findings.length === 0, 'a hand-built cleanup key with stray spaces still drops the finding')
const abs = partitionUnits([unit('src/a.js', [f('X', [1])])], ['/repo/src/a.js'], '/repo')
ok(abs.excluded.ledger === 1, 'an absolute ledger path still excludes')
const nt = mergeUnits([{ source: 'a', units: [unit('src/a.js', [f('X', [1])], { testFiles: ['./src/a.test.js'], evidencePaths: ['/repo/src/b.js'] })] }], '/repo')
ok(nt[0].testFiles[0] === 'src/a.test.js' && nt[0].evidencePaths[0] === 'src/b.js', 'test and evidence paths normalize too')

// Review fixes: pickable needs findings, paths normalize, wider patterns.
ok(pickable(unit('w.js', [], { testFiles: ['w.test.js'], reportOnly: [{ item: 'Hollow test', symbol: 's', lines: [1], note: 'n' }] })) === false, 'a unit with tests but no findings is not pickable')
const norm = mergeUnits([{ source: 'a', units: [unit('./src/a.js', [f('X', [1])])] }, { source: 'b', units: [unit('/repo/src/a.js', [f('X', [1])])] }], '/repo')
ok(norm.length === 1 && norm[0].path === 'src/a.js', 'dot-slash and absolute paths merge to one repo-relative unit')
ok(exclusionReason('src/a.js', ['./src/a.js']) === 'ledger', 'a dot-slash ledger path still excludes')
ok(exclusionReason('spec/user_spec.rb', []) === 'test' && exclusionReason('app/user_spec.rb', []) === 'test', 'a _spec file is a test')
ok(exclusionReason('pkg/conftest.py', []) === 'test' && exclusionReason('pkg/testdata/a.json', []) === 'test', 'conftest and testdata are test infrastructure')
ok(exclusionReason('src/jwt.ts', []) === 'security' && exclusionReason('src/tls/config.go', []) === 'security', 'jwt and tls paths are security boundaries')

// The discovery reference table matches the caps in code.
const disco = fs.readFileSync(process.env.DC_DISCOVERY, 'utf8')
for (const d of ['simple', 'standard', 'deep']) {
  const row = disco.split('\n').find((l) => l.startsWith(`| \`${d}\``))
  ok(row && row.split('|')[2].trim() === String(DEPTHS[d].cap) && row.split('|')[4].trim() === String(DEPTHS[d].refuteUnits), `discovery.md table matches the ${d} cap and refuted units`)
}

// The catalog's sections and entries match what the workflow fans out over.
const catalog = fs.readFileSync(process.env.DC_DISCOVERY.replace('discovery.md', 'catalog.md'), 'utf8')
const headings = catalog.split('\n').filter((l) => l.startsWith('## ')).map((l) => l.slice(3).trim())
const NOT_PATTERN = ['Evidence that generated code is where to look', 'Report only', 'Leave alone']
ok(headings.filter((h) => !NOT_PATTERN.includes(h)).join('|') === SECTIONS.join('|'), 'the catalog pattern sections match the workflow SECTIONS, in order')
ok(NOT_PATTERN.slice(1).every((h) => headings.includes(h)), 'the catalog keeps its Report only and Leave alone sections')
const patternBody = catalog.slice(catalog.indexOf(`## ${SECTIONS[0]}`), catalog.indexOf('## Report only'))
const entries = patternBody.split(/^### /m).slice(1)
ok(entries.length > 0 && entries.every((e) => /^- Proof: `(inert|reachability|probe)`/m.test(e)), 'every catalog pattern entry names a valid proof class')

// The workflow text and the skill that launches it.
const src = fs.readFileSync(process.env.DC_WORKFLOW, 'utf8')
const skill = fs.readFileSync(process.env.DC_SKILL, 'utf8')
const gates = fs.readFileSync(process.env.DC_DISCOVERY.replace('discovery.md', 'gates.md'), 'utf8')
ok(/refuted, skipped, declined, or filed/.test(skill) && /queued `skipped`|queue the finding `skipped`/.test(skill + gates), 'skipped and filed findings are queued and passed back as keys')
const agentCalls = src.match(/\bagent\(/g) || []
ok(agentCalls.length === 2, 'the workflow seats scouts and refuters and nothing else')
ok((src.match(/agentType: 'general-purpose'/g) || []).length === agentCalls.length, 'every agent call names the general-purpose type')
ok((src.match(/\.\.\.AGENT_CONFIG\.(scout|refute)\b/g) || []).length === agentCalls.length, 'every agent call spreads a model and effort pin')
ok(Object.values(AGENT_CONFIG_FOR_TEST).every((c) => c.model && c.effort), 'every pinned config sets both model and effort')
ok(!/\bWorkflow\b[^\n]*mode: *'work'|WORKER_|workerSeat|phase\('Work'\)/.test(src), 'the workflow carries no writer seat')
ok(/scriptPath/.test(skill) && /simplify-code\.js/.test(skill), 'the skill launches the workflow by scriptPath')
ok(!/mode: "work"/.test(skill) && !/Worker seat/.test(skill), 'the skill seats no worker')

// The skill is read-only on the checkout and files Docket issues.
ok(/The checkout is read-only/.test(skill) && /Docket issues and scratch/.test(skill), 'the skill states it is read-only and writes only issues and scratch')
ok(!/never create issues/i.test(skill + gates) && !/not filed elsewhere/.test(skill), 'the old no-issues rule is gone')
const gatesText = fs.readFileSync(process.env.DC_DISCOVERY.replace('discovery.md', 'gates.md'), 'utf8')
ok(/after-<prior issue id>/.test(skill) && /after-<that issue's id>/.test(gatesText), 'a regression files under a distinct idempotency key that names the prior issue')
ok(/docket issue create/.test(skill) && /--size/.test(skill) && /--idempotency-key/.test(skill) && /-l simplify-code/.test(skill), 'the skill files labelled, sized, idempotent issues')
ok(/-f <path>/.test(skill) && /--scope/.test(skill), 'every issue names files and a scope')
ok(!/Skill\(\{skill: "commit"/.test(skill) && !/commit` skill/.test(skill), 'the skill does not commit')
ok(/Decide:/.test(skill) && /Decision issues/.test(gates), 'report-only findings become decision issues')
ok(/Deduplicate before filing/.test(gates) && /wont-do/.test(gates), 'filing deduplicates against open and declined issues')
ok(/Issue contract/.test(gates) && /frozen/i.test(gates) && /mutation probe/i.test(gates), 'the issue contract carries the frozen contracts and the probe')
ok(/simple/.test(skill) && /standard/.test(skill) && /deep/.test(skill), 'the skill names all three depths')
ok(new RegExp(`simple\`\\s+\\(about ${DEPTHS.simple.cap}\\)`).test(skill) && new RegExp(`standard\`\\s+\\(about ${DEPTHS.standard.cap}\\)`).test(skill) && new RegExp(`deep\`\\s+\\(up to ${DEPTHS.deep.cap}`).test(skill), 'the skill states each depth cap as the workflow enforces it')

console.log(`${pass} passed, ${fail} failed`)
process.exit(fail ? 1 : 0)
JS

# AGENT_CONFIG sits outside the region (it is not a decision helper), so the
# suite reads its literal from the file text.
node -e '
const src = require("fs").readFileSync(process.argv[1], "utf8")
const m = /const AGENT_CONFIG = (\{[\s\S]*?\n\})/.exec(src)
if (!m) { console.error("AGENT_CONFIG not found"); process.exit(1) }
process.stdout.write("const AGENT_CONFIG_FOR_TEST = " + m[1].replace(/\/\/[^\n]*/g, "") + "\n")
' "$WORKFLOW" > "${WORK}/config.js" || fatal "could not read AGENT_CONFIG"

{ cat "${WORK}/region.js"; cat "${WORK}/config.js"; cat "${WORK}/cases.js"; } > "${WORK}/run.js"
DC_WORKFLOW="$WORKFLOW" DC_SKILL="$SKILL" DC_DISCOVERY="$DISCOVERY" node "${WORK}/run.js"
