export const meta = {
    name: 'integration-check',
    description: 'Read-only: for every wave worktree (branch worktree-wf_*), report whether its tip is integrated into the shared checkout\'s HEAD, by ancestry then by patch-equivalence. Invoke by scriptPath ONLY, with args {}.',
    whenToUse: 'Invoked by the docket-run skill from the shared checkout before `dispatch close`, always as Workflow({scriptPath}) — never by name.',
    phases: [
        { title: 'Scout', detail: 'one agent lists the wave worktrees' },
        { title: 'Check', detail: 'one agent per worktree: ancestry, then patch-equivalence' },
    ],
}

// ---------------------------------------------------------------------------
// Integration cherry-picks, so a wave tip is rarely an ancestor of HEAD;
// `git cherry` patch-equivalence is the test when ancestry fails. A cherry
// that itself errors is UNINTEGRATED, never assumed equivalent: the cost of
// a false "integrated" is a closed dispatch whose work is not in the tree.
// The worktree list is scouted here rather than passed in so the conductor
// cannot narrow it, and the examined count is always logged so a vacuous
// zero-worktree pass is visible.
//
// args:   {}  (absent or empty is fine; nothing is read from it)
// return: {examined, worktrees: [{path, sha, integrated, how, detail}], unintegrated: [{path, sha, how}]}
//         how is ancestor | patch-equivalent | unintegrated | cherry-error,
//         or unprobed when the agent produced nothing (counted unintegrated).
// ---------------------------------------------------------------------------

const SCOUT_SCHEMA = {
    type: 'object',
    required: ['worktrees'],
    properties: {
        worktrees: {
            type: 'array',
            items: {
                type: 'object',
                required: ['path', 'sha'],
                properties: {
                    path: { type: 'string' },
                    sha: { type: 'string' },
                },
            },
        },
    },
}

const CHECK_SCHEMA = {
    type: 'object',
    required: ['how', 'detail'],
    properties: {
        how: { type: 'string', enum: ['ancestor', 'patch-equivalent', 'unintegrated', 'cherry-error'] },
        detail: { type: 'string' },
    },
}

const sq = (s) => `'${String(s).replace(/'/g, `'\\''`)}'`

const scoutBrief = `You are a read-only scout in the shared checkout. Do not cd anywhere. Run verbatim, sandboxed:

\`\`\`
git worktree list --porcelain; echo "exit=$?"
\`\`\`

Records are blank-line separated. Return one entry per record whose \`branch\` line is \`branch refs/heads/worktree-wf_\` followed by anything: path = the text after \`worktree \`, sha = the 40-hex text after \`HEAD \`. Include every such record and nothing else (the main checkout, detached records and other branches are not wave worktrees). Return worktrees = [] when there are none or when the command fails; report a failure's text nowhere else, since the conductor reads the count.`

function checkBrief(w) {
    return `You are a read-only checker in the shared checkout. Do not cd anywhere and do not enter the worktree. HEAD means this checkout's HEAD. Run verbatim, sandboxed:

\`\`\`
git merge-base --is-ancestor ${sq(w.sha)} HEAD; echo "exit=$?"
\`\`\`

Exit 0 is how = ancestor; stop there. Otherwise run:

\`\`\`
git cherry HEAD ${sq(w.sha)}; echo "exit=$?"
\`\`\`

A non-zero cherry exit is how = cherry-error (put the exit and any error text in detail; it is never assumed equivalent). Exit 0 with NO line beginning with \`+\` is how = patch-equivalent. Exit 0 with any \`+\` line is how = unintegrated; put those lines in detail. Never fetch, merge, cherry-pick, or modify anything.`
}

phase('Scout')
const scout = await agent(scoutBrief, {
    label: 'worktrees',
    phase: 'Scout',
    schema: SCOUT_SCHEMA,
    effort: 'low',
})
if (!scout) throw new Error('integration-check: the worktree scout produced nothing — nothing examined.')
const worktreesIn = scout.worktrees
log(`integration-check: examined ${worktreesIn.length} wave worktree(s)`)

phase('Check')
const checked = await pipeline(worktreesIn, async (w) => {
    const r = await agent(checkBrief(w), {
        label: `check:${w.sha.slice(0, 12)}`,
        phase: 'Check',
        schema: CHECK_SCHEMA,
        effort: 'low',
    })
    if (!r) return { ...w, integrated: false, how: 'unprobed', detail: 'agent produced nothing — NOT examined, counted unintegrated' }
    const integrated = r.how === 'ancestor' || r.how === 'patch-equivalent'
    return { ...w, integrated, how: r.how, detail: r.detail }
})

const worktrees = checked.map((c, i) => c || {
    ...worktreesIn[i], integrated: false, how: 'unprobed', detail: 'check stage threw — NOT examined, counted unintegrated',
})

for (const w of worktrees) {
    const tag = w.integrated ? `integrated (${w.how})` : `UNINTEGRATED (${w.how})`
    log(`${tag.padEnd(32)} ${w.sha}  ${w.path}`)
    if (!w.integrated && w.detail) {
        for (const line of w.detail.split('\n')) log(`                 ${line}`)
    }
}

const unintegrated = worktrees.filter((w) => !w.integrated).map((w) => ({ path: w.path, sha: w.sha, how: w.how }))
log(`integration-check: examined ${worktrees.length} wave worktree(s), ${unintegrated.length} unintegrated`)

return { examined: worktrees.length, worktrees, unintegrated }
