export const meta = {
    name: 'attach-probe',
    description: 'Read-only pre-dispatch probe: seat, store, corpus install, workflow/hook install, pins, link-farm debris, plus a straggler-worktree report. Invoke by scriptPath ONLY, with args {run?, home, checkout, cwd} — every path a literal absolute string, never ~.',
    whenToUse: 'Invoked by the docket-run skill before the first dispatch, and before an activation with no run yet (pins is then SKIP and the return says so), always as Workflow({scriptPath}) — never by name. It never mutates, claims or activates.',
    phases: [{ title: 'Probe', detail: 'six read-only checks and a straggler report, in one parallel' }],
}

// ---------------------------------------------------------------------------
// Why this is a script. Every conductor attaching to a run must clear the
// same checks, and retyped checks drift: one session piped a diff through
// `head -30` and reported head's exit — always 0 — as the diff's verdict,
// and ran `test -f` on an installed workflow where a byte-diff was mandated.
// Both happened to be harmless that day. Here every check names the exact
// command, every diff is `diff -rq` (complete and bounded, so nothing is
// piped through head), and install is compared by bytes, never existence:
// nothing links the install into the source tree, so the two are different
// bytes whenever the source moved since the last `just activate`.
//
// Read-only by construction: `git rev-parse`, `git worktree list`, `find`,
// `diff`, and the two write-nothing verbs `run status` and `run
// verify-pins`. Safe against a run in any status.
//
// All checks run in ONE parallel because the verdict needs every one of
// them; nothing short-circuits, so a vacuous pass is visible in the output
// rather than inferred from silence. The stragglers check is a REPORT: a
// detached worktree homed under a scratch path outlives the session that
// made it and no branch-derived close sweep can see it — three were once
// found registered while the probe said all clean, because it did not look.
// It is WARN or OK and never moves `clean`; removal belongs to the close
// sweep, by literal path, for the one carrying THIS session's id only.
//
// Corpus and install checks compare SOURCE against INSTALL. A run's PINS are
// a third set of bytes that can disagree with both, which is why `pins` is
// the check that bites on an active run and why omitting `run` is reported
// as `skipped`, not as clean.
//
// args:   {run?, home, checkout, cwd}
//         home     literal absolute $HOME
//         checkout literal absolute path of the dotfiles checkout
//         cwd      literal absolute path of the conductor's seat
// return: {clean, skipped, checks: [{check, verdict, detail}]}
//         verdict is OK | FAIL | DRIFT | SKIP | WARN.
//         clean   = every non-WARN verdict is OK (a SKIP is not OK).
//         skipped = any check is SKIP; clean false with skipped true means
//                   everything that ran was clean and only pins is missing.
// ---------------------------------------------------------------------------

let input = args
if (typeof input === 'string') {
    input = JSON.parse(input)
    log('attach-probe: decoded args from the harness JSON-encoded transport (normal)')
}
if (!input || typeof input !== 'object') {
    throw new Error(`attach-probe: args is ${typeof input}, expected {run?, home, checkout, cwd}.`)
}
for (const k of ['home', 'checkout', 'cwd']) {
    if (typeof input[k] !== 'string' || !input[k].startsWith('/')) {
        throw new Error(
            `attach-probe: args.${k} must be a literal absolute path (got ${JSON.stringify(input[k])}). ` +
            `Never ~ and never an environment expansion: the agent's shell is not the conductor's.`
        )
    }
}
const { home, checkout, cwd } = input
const run = typeof input.run === 'string' && input.run !== '' ? input.run : null

const VERDICTS = ['OK', 'FAIL', 'DRIFT', 'SKIP', 'WARN']
const CHECK_SCHEMA = {
    type: 'object',
    required: ['verdict', 'detail'],
    properties: {
        verdict: { type: 'string', enum: VERDICTS },
        detail: { type: 'string' },
    },
}

const sq = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`

const PREAMBLE = `You are a read-only probe. Run only the commands given, sandboxed, verbatim, and never with the sandbox disabled: a denial is itself the finding — report it as FAIL with the denial text. Do not fix, retry or paraphrase anything. Report the real output and exit status (\`cmd; echo "exit=$?"\`). Return exactly one verdict and a detail string; put multi-line evidence in detail, first line a one-sentence summary.`

// Applies to every one-sided diff line: a directory with no file at any
// depth cannot move a pin (a pin is the sha256 of a FILE), and harness
// scratch (`.claude/.cc-writes`) lands in these trees exactly that way. It
// made the check fail on every run for a non-condition, and a stop signal
// that always fires gets read past. Such lines are set aside and NAMED.
const ONE_SIDED_RULE = `For every \`Only in X: Y\` line, run \`find X/Y ! -type d | head -n 1\` (only when X/Y is a directory and not a symlink). If that prints nothing, the entry is a one-sided directory holding no file at any depth: DISREGARD it for the verdict but NAME it in detail as "disregarded — holds no file at any depth: <path>". Every other line counts: a one-sided file, a one-sided directory with a file however deep, any symlink, and every "Files ... differ" line.`

const briefs = {
    seat: `${PREAMBLE}

The conductor's seat is ${sq(cwd)}. Run:

\`\`\`
cd ${sq(cwd)} && pwd -P; echo "exit=$?"
git -C ${sq(cwd)} rev-parse --show-toplevel; echo "exit=$?"
\`\`\`

OK when rev-parse succeeds and its output equals the \`pwd -P\` output. FAIL when the seat is not inside a git work tree, or when it is a SUBDIRECTORY of the toplevel (say so, and name both paths: seated in a subdirectory, the sandbox write-allow covers only that subtree, so every repo-level git write, the conductor's and every wave executor's, is denied).`,

    store: `${PREAMBLE}

Run from the seat:

\`\`\`
cd ${sq(cwd)} && docket run status ${run ? sq(run) : '--active'} --json; echo "exit=$?"
\`\`\`

OK when exit is 0 AND the body does not contain \`"ok":false\` (trust the body as well as the exit). FAIL otherwise, with the body in detail. If the body contains NOT_FOUND, say the store opened but ${run ? `${run} is not in it — check the run id and that this cwd is the run's repo` : 'no active run exists in it'}. Any other failure is the seat's write access to ~/.docket/issues.db, not the engine: every verb opens the store read-write, and a sandbox that does not write-allow the store fails every verb with "unable to open database file (14)".`,

    corpus: `${PREAMBLE}

Compare the docket corpus source against its install, one tree at a time:

\`\`\`
diff -rq ${sq(checkout + '/src/user/docket/config')} ${sq(home + '/.docket/config')}; echo "exit=$?"
diff -rq ${sq(checkout + '/src/user/docket/bin')} ${sq(home + '/.docket/bin')}; echo "exit=$?"
\`\`\`

${ONE_SIDED_RULE}

FAIL if either tree is missing on either side (diff exit 2 with "No such file"). OK when no counted line remains in either tree — say "no file differs" and name every disregarded directory. DRIFT when any counted line remains: list every one in detail, per tree. A stale pin cannot be fixed mid-run, so a DRIFT is stop-and-report.`,

    install: `${PREAMBLE}

Compare the installed workflow scripts and hooks against their source, by bytes, never by existence:

\`\`\`
diff -rq ${sq(checkout + '/src/user/claude_code/workflows')} ${sq(home + '/.claude/workflows')}; echo "exit=$?"
diff -rq ${sq(checkout + '/src/user/claude_code/hooks')} ${sq(home + '/.claude/hooks')}; echo "exit=$?"
\`\`\`

${ONE_SIDED_RULE}

Then classify the counted lines. "Files ... differ" is DRIFT (the wave runs the INSTALLED bytes; a source edit since the last \`just activate\` is bytes no session executes). "Only in <source dir>" is DRIFT (a file the source ships that is not installed). "Only in <install dir>" is NOT drift of this corpus — another installer may own it — but NAME each such file in detail. FAIL if either tree is missing on either side. OK when nothing is DRIFT: say "bytes identical for every source file" and name every disregarded directory and every install-only file.`,

    pins: `${PREAMBLE}

Run from the seat:

\`\`\`
cd ${sq(cwd)} && docket run verify-pins ${sq(run)} --json; echo "exit=$?"
\`\`\`

Map the result: a body containing NOT_FOUND is FAIL ("${run} is not in this store — nothing was verified"); a body saying the subcommand is unknown is FAIL ("this binary predates run verify-pins"); exit 0 is OK ("every pin still resolves to the bytes the run froze at activation"); exit 4 is DRIFT ("CONFLICT — a pinned ref changed on disk"); exit 2 is FAIL ("a pinned ref no longer resolves at all"); any other exit is FAIL ("verify-pins exit N"; exit 3 means the pin set is not closed). Put the body in detail on anything but OK.`,

    debris: `${PREAMBLE}

The retired link-farm model put symlinks under a repo's own .docket/config; a dangling one refuses activation by name. Run:

\`\`\`
test -d ${sq(cwd + '/.docket/config')}; echo "exit=$?"
find ${sq(cwd + '/.docket/config')} -type l; echo "exit=$?"
\`\`\`

OK when the directory does not exist (say "no .docket/config in this repo — the normal case against the shared root"). OK when it exists and find prints no symlink (real files there are the repo's own additions). DRIFT when any symlink is printed: list them.`,

    stragglers: `${PREAMBLE}

This is a REPORT, not a verdict: return OK or WARN only, never FAIL. Run:

\`\`\`
git -C ${sq(cwd)} worktree list --porcelain; echo "exit=$?"
\`\`\`

Records are blank-line separated. Consider ONLY records carrying a \`detached\` line (a record with a \`branch\` line is a wave checkout the close sweep already derives from its branch name; leave it alone). Of those, a straggler is one whose path is scratch-shaped: it contains \`/scratchpad\` as a component or subtree, or starts with \`/tmp/claude-\` or \`/private/tmp/claude-\`. OK when there are none. WARN when there are any: one line per straggler in detail — \`<path> <sha> (session <uuid or unknown>)\`, the session being the 8-4-4-4-12 hex path component if the path has one — followed by: "detached, no worktree-wf_* branch — invisible to a branch-derived close sweep. Not removed here: name every one in the close report, remove only the one carrying THIS session id, by literal path, once git status --porcelain there is empty; every other one belongs to another session and is left registered and named for the operator."`,
}

// Stragglers can only report; any other verdict from it is coerced so the
// report can never move `clean`.
const ALLOWED = {
    seat: ['OK', 'FAIL'],
    store: ['OK', 'FAIL'],
    corpus: ['OK', 'FAIL', 'DRIFT'],
    install: ['OK', 'FAIL', 'DRIFT'],
    pins: ['OK', 'FAIL', 'DRIFT'],
    debris: ['OK', 'DRIFT'],
    stragglers: ['OK', 'WARN'],
}

function probe(check) {
    return agent(briefs[check], {
        label: `check:${check}`,
        phase: 'Probe',
        schema: CHECK_SCHEMA,
        effort: 'low',
    }).then((r) => {
        if (!r) return { check, verdict: check === 'stragglers' ? 'WARN' : 'FAIL', detail: 'agent produced nothing — the check did NOT run' }
        let verdict = r.verdict
        if (!ALLOWED[check].includes(verdict)) {
            const coerced = check === 'stragglers' ? 'WARN' : 'FAIL'
            log(`attach-probe: ${check} returned ${verdict}, outside its vocabulary — recorded as ${coerced}`)
            verdict = coerced
        }
        return { check, verdict, detail: r.detail }
    })
}

phase('Probe')
const order = ['seat', 'store', 'corpus', 'install', 'pins', 'debris', 'stragglers']
const spawned = order.filter((c) => !(c === 'pins' && !run))
if (!run) log('attach-probe: no run given — pins will be SKIP without a spawn (expected at activation only)')

const results = await parallel(spawned.map((c) => () => probe(c)))
const byCheck = {}
spawned.forEach((c, i) => {
    byCheck[c] = results[i] || { check: c, verdict: c === 'stragglers' ? 'WARN' : 'FAIL', detail: 'probe threw — the check did NOT run' }
})
if (!run) {
    byCheck.pins = {
        check: 'pins',
        verdict: 'SKIP',
        detail: 'no run given — required on an already-active run; source and install agreeing says nothing about pins',
    }
}

const checks = order.map((c) => byCheck[c])
for (const c of checks) {
    const [first, ...rest] = c.detail.split('\n')
    log(`${c.verdict.padEnd(5)} ${c.check.padEnd(10)} ${first}`)
    for (const line of rest) log(`                 ${line}`)
}

const skipped = checks.some((c) => c.verdict === 'SKIP')
const ranClean = checks.every((c) => ['WARN', 'SKIP', 'OK'].includes(c.verdict))
const clean = ranClean && !skipped
const ran = checks.filter((c) => c.check !== 'stragglers').length

if (!ranClean) {
    log(`attach-probe: ${ran} check(s) run — NOT CLEAN. Stop and report to the operator; do not dispatch.`)
} else if (skipped) {
    log(`attach-probe: ${ran} check(s) run — clean, but a check was SKIPPED. Re-run with run before dispatching into an active run.`)
} else {
    log(`attach-probe: ${ran} check(s) run — all clean.`)
}

return { clean, skipped, checks }
