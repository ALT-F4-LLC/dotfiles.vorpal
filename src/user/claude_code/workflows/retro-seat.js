export const meta = {
    name: 'retro-seat',
    description: 'Internal: launched through scriptPath by docket-retro; seats one or more executor-read analysts that gather and analyze run evidence and return findings. Args and cost in the header comment.',
    whenToUse: 'Never by name. The caller composes each analyst brief (contract, §2 table, assigned run window) and passes {model, effort} per analyst, since retro-analyst carries no policy.toml row for this script to read.',
    phases: [
        { title: 'Analyze', detail: 'one executor-read analyst per assigned run window, each returning evidence-labelled findings' },
    ],
}

// ---------------------------------------------------------------------------
// CONTRACT FOR CALLERS (the listing's description is deliberately one line;
// this block is the single copy of what it used to carry).
//
// What it does:
// Seats one or more `retro-analyst` agents in parallel, each briefed by the
// caller with the retro-analyst contract, the docket-retro skill's §2
// evidence table, and its own assigned run window. Each analyst runs
// read-only docket verbs and returns its findings as free-form text; this
// script neither reads policy nor interprets the findings — it only spawns
// the seats and hands each result back verbatim, in the same order as the
// `analysts` array. Invoke by scriptPath ONLY, with args
// {analysts: [{brief, model, effort}, ...]}.
//
// When and how it is invoked:
// Invoked by the docket-retro skill's §1 (Gather), always as
// Workflow({scriptPath}) — never by name. docket-retro carries no
// policy.toml row for retro-analyst and no workflow dispatches it through
// the wave, so this script is the only seating path this node has, and the
// caller resolves each seat's {model, effort} itself (docket-retro's own
// operator-set default, or an explicit choice for a heavier window) rather
// than this script reading pinned policy the way wave.js does for a real
// step.
// ---------------------------------------------------------------------------

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
if (typeof args === 'string') log('retro-seat: decoded args from the harness JSON-encoded transport (normal)')

if (!Array.isArray(input.analysts) || input.analysts.length === 0) {
    throw new Error('retro-seat: args.analysts must be a non-empty array of {brief, model, effort}')
}
for (const [i, a] of input.analysts.entries()) {
    if (typeof a.brief !== 'string' || a.brief === '') {
        throw new Error(`retro-seat: args.analysts[${i}].brief is required and must be a non-empty string`)
    }
    if (typeof a.model !== 'string' || a.model === '') {
        throw new Error(`retro-seat: args.analysts[${i}].model is required (retro-analyst carries no policy.toml row for this script to resolve it)`)
    }
    if (typeof a.effort !== 'string' || a.effort === '') {
        throw new Error(`retro-seat: args.analysts[${i}].effort is required (retro-analyst carries no policy.toml row for this script to resolve it)`)
    }
}

phase('Analyze')
log(`retro-seat: seating ${input.analysts.length} retro-analyst agent(s)`)

const results = await parallel(input.analysts.map((a, i) => () =>
    agent(a.brief, {
        label: `retro-analyst:${i + 1}/${input.analysts.length}`,
        phase: 'Analyze',
        agentType: 'executor-read',
        model: a.model,
        effort: a.effort,
    })
))

const usable = results.filter((r) => r != null).length
log(`retro-seat: ${usable}/${input.analysts.length} analyst(s) returned a result`)

return { findings: results }
