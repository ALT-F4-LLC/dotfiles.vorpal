export const meta = {
    name: 'gate-probe',
    description: 'Run EVERY completion gate on this repo\'s trust roster once, each in a fresh worktree of clean HEAD, and report OK|FAIL per gate. Invoke by scriptPath ONLY, with args {run?}.',
    whenToUse: 'Invoked by the docket-run skill before the first dispatch of a run, always as Workflow({scriptPath}) — never by name. The roster is whatever `docket trust list` returns; the conductor passes nothing that could narrow it.',
    phases: [
        { title: 'Roster', detail: 'one scout reads HEAD and the trust roster' },
        { title: 'Probe', detail: 'one isolated worktree agent per roster entry' },
    ],
}

// ---------------------------------------------------------------------------
// Why this is a script and not prose. A gate that fails on clean HEAD is
// surfaced to the operator ONCE here instead of being rediscovered as a
// parked step per issue. Left in prose, the roster became a judgment call:
// one resume ran `make format` alone and skipped build, tests and four more
// because the remaining rows "looked like" vote and action rows. The roster
// is never narrowed by what the next rows look like — the conductor holds no
// run state, `next` is the engine's answer, and a vote's on_fail, an `--as
// retry` or a fix batch puts a write-class step one dispatch later. So the
// only input is an optional run label, and the roster is scouted here.
//
// Each gate gets stdin from /dev/null. An engine ACTION is fed a JSON bundle
// on stdin at record time and can only fail here, so roster entries the
// installed workflow definitions declare as `action = "<name>"` are SKIPPED
// by name and returned as such — the trust roster itself carries no marker
// for them, the workflow TOMLs do. Per-entry roster timeouts are not
// enforced: a hung gate hangs its agent visibly, which beats a gate silently
// skipped. A gate that fails on clean HEAD was not caused by the run's
// changes — commonly an untracked toolchain that never materializes in a
// fresh worktree, a sandbox denial, a network block — but possibly a real
// pre-existing defect. Nothing short-circuits: the report covers the whole
// roster, and a STUB entry (a placeholder trusted under a real gate's name)
// is run and counted like any other, with its hollow pass marked.
//
// args:   {run?}  — a label only; nothing is skipped without it.
// return: {gates: [{name, stub, exit, log_tail}], failed: [name], skipped: [name], passed, head}
//         exit is null when the entry was never run (no argv, or the agent
//         produced nothing); both count as FAIL, so a vacuous pass is
//         impossible. skipped names the declared engine actions, which are
//         not in gates. Throws when the roster is empty: that is a finding.
// ---------------------------------------------------------------------------

let input = args
if (typeof input === 'string') {
    input = JSON.parse(input)
    log('gate-probe: decoded args from the harness JSON-encoded transport (normal)')
}
input = input || {}
const run = typeof input.run === 'string' && input.run !== '' ? input.run : null

const ROSTER_SCHEMA = {
    type: 'object',
    required: ['head', 'items', 'actions'],
    properties: {
        head: { type: 'string' },
        actions: { type: 'array', items: { type: 'string' } },
        items: {
            type: 'array',
            items: {
                type: 'object',
                required: ['name', 'stub', 'argv'],
                properties: {
                    name: { type: 'string' },
                    stub: { type: 'boolean' },
                    argv: { type: 'array', items: { type: 'string' } },
                },
            },
        },
    },
}

const GATE_SCHEMA = {
    type: 'object',
    required: ['exit', 'tail'],
    properties: {
        exit: { type: 'integer' },
        tail: { type: 'string' },
    },
}

// Single quotes survive every shell the roster's argv0 could be; the only
// byte that needs care inside them is the quote itself.
const sq = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`

const rosterBrief = `You are a read-only scout. Do not cd anywhere. Run these three commands verbatim, sandboxed, and report what they print — never a paraphrase:

\`\`\`
git rev-parse HEAD
docket trust list --json=v2
grep -ho '^action *= *"[^"]*"' ~/.docket/config/workflows/*.toml .docket/config/workflows/*.toml 2>/dev/null | sed 's/.*"\\(.*\\)"/\\1/' | sort -u
\`\`\`

Return head = the first command's output (the 40-hex sha); items = one entry per element of \`.data.items\` in the second command's JSON: name, stub (its \`stub\` boolean), argv (its \`argv\` array of strings, verbatim, in order; an entry with no argv gets []); actions = every name the third command printed, one per line ([] when it printed nothing). Include EVERY entry; drop none, reorder none. If the JSON has \`"ok":false\` or the command fails, return items = [] and put the error text in head.`

function gateBrief(item) {
    const cmd = item.argv.map(sq).join(' ')
    return `Your cwd is a fresh git worktree of clean HEAD, made for this one gate. Do not cd anywhere else, and do not read or touch any other checkout.

Run exactly this line, sandboxed, verbatim:

\`\`\`
${cmd} </dev/null > gate.log 2>&1; echo "exit=$?"
\`\`\`

The number after \`exit=\` is the gate's OWN exit status; report it as \`exit\`. Then run:

\`\`\`
tail -n 5 gate.log
\`\`\`

and report its output as \`tail\` (empty string if the log is empty). Then leave the worktree exactly as you found it:

\`\`\`
rm -f gate.log && git checkout -- . && git clean -fdxq
\`\`\`

Do not retry the gate, do not fix anything, do not disable the sandbox. If the sandbox denies the gate, its exit status is the finding: report the number and the denial text in tail.`
}

// ---------------------------------------------------------------------------
// Roster
// ---------------------------------------------------------------------------

phase('Roster')
const roster = await agent(rosterBrief, {
    label: 'roster',
    phase: 'Roster',
    schema: ROSTER_SCHEMA,
    effort: 'low',
})
if (!roster) throw new Error('gate-probe: the roster scout produced nothing — nothing probed.')
if (roster.items.length === 0) {
    throw new Error(
        `gate-probe: the trust roster is EMPTY (${roster.head}) — no gate was probed. ` +
        `That is a finding, not a pass. Report it before dispatching.`
    )
}
const actions = new Set(roster.actions)
const skipped = roster.items.filter((it) => actions.has(it.name)).map((it) => it.name)
const items = roster.items.filter((it) => !actions.has(it.name))
const head = /^[0-9a-f]{40}$/.test(roster.head) ? roster.head : 'unknown'
log(`gate-probe: HEAD ${head}${run ? `, run ${run}` : ''}, ${roster.items.length} roster entr${roster.items.length === 1 ? 'y' : 'ies'}`)
for (const name of skipped) {
    log(`SKIP ${name.padEnd(22)} declared as an engine action (action = "${name}" in a workflow TOML) — the engine feeds it a JSON bundle on stdin at record time, so a stdin-less probe can only fail it`)
}
if (items.length === 0) {
    throw new Error(`gate-probe: every roster entry is a declared engine action (${skipped.join(', ')}) — no gate was probed, which is a finding, not a pass.`)
}

// ---------------------------------------------------------------------------
// Probe — one isolated worktree per entry; every entry runs, nothing stops
// on the first failure.
// ---------------------------------------------------------------------------

function verdictLine(g) {
    const verdict = g.exit === 0 ? 'OK' : 'FAIL'
    return `${verdict.padEnd(4)} ${g.name.padEnd(22)} exit=${g.exit === null ? '-' : g.exit}${g.stub ? ' STUB' : ''}`
}

function report(g) {
    log(verdictLine(g))
    if (g.exit !== 0 && g.tail) {
        for (const line of g.tail.split('\n')) log(`                 ${line}`)
    }
    return g
}

phase('Probe')
const probed = await pipeline(items, async (item) => {
    if (item.argv.length === 0) {
        return report({ name: item.name, stub: item.stub, exit: null, tail: 'roster entry has no argv — nothing to run' })
    }
    const r = await agent(gateBrief(item), {
        label: `gate:${item.name}`,
        phase: 'Probe',
        schema: GATE_SCHEMA,
        effort: 'low',
        isolation: 'worktree',
    })
    if (!r) {
        return report({ name: item.name, stub: item.stub, exit: null, tail: 'agent produced nothing — the gate was NOT probed' })
    }
    return report({ name: item.name, stub: item.stub, exit: r.exit, tail: r.tail })
})

// A stage that threw left a null; the entry was not probed, which is not a pass.
const gates = probed.map((g, i) => g || report({
    name: items[i].name, stub: items[i].stub, exit: null, tail: 'probe stage threw — the gate was NOT probed',
})).map((g) => ({ name: g.name, stub: g.stub, exit: g.exit, log_tail: g.tail }))

const failed = gates.filter((g) => g.exit !== 0).map((g) => g.name)
const passed = failed.length === 0

if (passed) {
    log(`gate-probe: ${gates.length} gate(s) run, all passed on clean HEAD.`)
} else {
    log(`gate-probe: ${gates.length} gate(s) run, ${failed.length} FAILED — ${failed.join(' ')}`)
    log('gate-probe: these fail on CLEAN HEAD, so no step\'s changes caused them.')
    log('gate-probe: surface them to the operator ONCE and record the disposition before dispatching.')
}

return { gates, failed, skipped, passed, head }
