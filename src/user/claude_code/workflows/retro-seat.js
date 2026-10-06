export const meta = {
    name: 'retro-seat',
    description: 'Internal: launched through scriptPath by docket-retro; seats one or more executor-read analysts that gather and analyze run evidence and return one structured report each. Args, return, and cost in the header comment.',
    whenToUse: 'Never by name. The caller composes each analyst brief (contract, §2 table, assigned run window) and passes {model, effort} per analyst, since retro-analyst carries no policy.toml row for this script to read.',
    phases: [
        { title: 'Analyze', detail: 'one executor-read analyst per assigned run window, each returning its findings and gaps through a schema' },
    ],
}

// ---------------------------------------------------------------------------
// CONTRACT FOR CALLERS
//
// What it does:
// Seats one or more `retro-analyst` agents in parallel, each briefed by the
// caller with the retro-analyst contract, the docket-retro skill's §2
// evidence table, and its own assigned run window. Each analyst runs
// read-only docket verbs and returns its findings and gaps through
// REPORT_SCHEMA; this script neither reads policy nor interprets the
// findings — it only spawns the seats and hands each report back unchanged.
// Args: {analysts: [{brief, model, effort}, ...]}.
//
// Return: {reports, seated, returned}. `reports` holds one entry per
// `analysts` entry, in the same order: the analyst's {window, coverage,
// findings, gaps}, or null when the seat returned nothing (blocked, skipped,
// or died). `seated` counts the analysts launched and `returned` the
// non-null reports.
//
// Cost: one executor-read agent per `analysts` entry, no probe or claim
// agents.
//
// When and how it is invoked:
// Invoked by the docket-retro skill's §1 (Gather), always as
// Workflow({scriptPath}), never by name. No policy.toml row or wave
// dispatch covers retro-analyst, so this script is its only seating path
// and the caller sets each seat's {model, effort} explicitly per analyst
// entry instead of this script reading pinned policy as wave.js does for a real step.
// ---------------------------------------------------------------------------

// The retro-analyst contract's Emit and Stuck sections, as fields: the window
// and coverage stated once, ranked findings, and gaps. A finding's full
// content (facts, inferences, diff, design-search record, cost if wrong)
// stays in `body`; the fields around it are what docket-retro sorts on.
const REPORT_SCHEMA = {
    type: 'object',
    properties: {
        window: { type: 'string', description: 'The analysis window, once: last-retro boundary, collection cutoff, runs and projects covered' },
        coverage: { type: 'string', description: 'Evidence coverage, once: what was read and what was unavailable' },
        findings: {
            type: 'array',
            description: 'Ranked: trust drift first, then config churn, then the rest by evidence strength; empty when nothing is supported',
            items: {
                type: 'object',
                properties: {
                    kind: { type: 'string', enum: ['config-proposal', 'issue-to-file'] },
                    row: { type: 'string', description: 'The docket-retro §2 row the finding answers' },
                    title: { type: 'string' },
                    runs: { type: 'array', items: { type: 'string' }, description: 'Supporting run IDs' },
                    body: { type: 'string', description: 'The finding in the contract Emit shape, every claim labelled observed or inferred' },
                },
                required: ['kind', 'row', 'title', 'runs', 'body'],
            },
        },
        gaps: {
            type: 'array',
            items: {
                type: 'object',
                properties: {
                    available: { type: 'string', description: 'What evidence was available' },
                    blocked: { type: 'string', description: 'The claims the gap blocks' },
                    missing: { type: 'string', description: 'The smallest missing input or observation that would resolve it' },
                },
                required: ['available', 'blocked', 'missing'],
            },
        },
    },
    required: ['window', 'coverage', 'findings', 'gaps'],
}

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
if (typeof args === 'string') log('retro-seat: decoded args from the harness JSON-encoded transport (normal)')

if (!Array.isArray(input.analysts) || input.analysts.length === 0) {
    throw new Error('retro-seat: args.analysts must be a non-empty array of {brief, model, effort}')
}
for (const [i, a] of input.analysts.entries()) {
    if (typeof a.brief !== 'string' || a.brief === '') {
        throw new Error(`retro-seat: args.analysts[${i}].brief is required and must be a non-empty string`)
    }
    for (const key of ['model', 'effort']) {
        if (typeof a[key] !== 'string' || a[key] === '') {
            throw new Error(`retro-seat: args.analysts[${i}].${key} is required (retro-analyst carries no policy.toml row for this script to resolve it)`)
        }
    }
}

phase('Analyze')
log(`retro-seat: seating ${input.analysts.length} retro-analyst agent(s)`)

const reports = await parallel(input.analysts.map((a, i) => () =>
    agent(a.brief, {
        label: `retro-analyst:${i + 1}/${input.analysts.length}`,
        phase: 'Analyze',
        agentType: 'executor-read',
        model: a.model,
        effort: a.effort,
        schema: REPORT_SCHEMA,
    })
))

const returned = reports.filter((r) => r != null).length
log(`retro-seat: ${returned}/${input.analysts.length} analyst(s) returned a report`)

return { reports, seated: input.analysts.length, returned }
