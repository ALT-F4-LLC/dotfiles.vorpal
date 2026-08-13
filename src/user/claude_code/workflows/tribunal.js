export const meta = {
    name: 'tribunal',
    description: 'Spawn a judge panel that decides one gated proposal by each seat casting a real `docket vote cast`. This script never casts, approves, or tallies — the engine\'s vote machinery tallies. Invoke by scriptPath ONLY, with args {voteId, voters, policyText, context, gateKind, cwd} — policy.toml is passed as TEXT, never a path; the script cannot read files.',
    whenToUse: 'Invoked on a `type = "vote"` gate step (or a conversational gate the conduct skill routes to a panel), always as Workflow({scriptPath}) — never by name. The CALLER creates the proposal and passes its id; tribunal.js only fills an open one.',
    phases: ['Judge', 'Verify'],
}

// ---------------------------------------------------------------------------
// TOML subset parser — byte-identical to wave.js's, deliberately duplicated.
// A workflow script has no file access and no module resolution: it cannot
// import a sibling, so the only alternatives are this copy or a second parser
// that drifts. Keep the two in sync; edit both or neither.
// ---------------------------------------------------------------------------

const SUBSET = 'tables, array-of-tables, inline tables, quoted strings, integers, arrays of strings, # comments outside quotes'

function bail(line, n, why) {
    throw new Error(
        `tribunal.js policy parser: ${why} (line ${n}: ${JSON.stringify(line)}). ` +
        `This is NOT a general TOML parser — it accepts only: ${SUBSET}. ` +
        `Fix policy.toml or widen the parser deliberately; do not parse partially.`
    )
}

function decomment(s) {
    let q = false
    for (let i = 0; i < s.length; i++) {
        const c = s[i]
        if (c === '"' && s[i - 1] !== '\\') q = !q
        else if (c === '#' && !q) return s.slice(0, i)
    }
    return s
}

function scalar(v, line, n) {
    v = v.trim()
    if (/^"(?:[^"\\]|\\.)*"$/.test(v)) return JSON.parse(v)
    if (/^-?\d+$/.test(v)) return parseInt(v, 10)
    if (/^'/.test(v)) bail(line, n, 'literal (single-quoted) strings are out of subset')
    if (/^(true|false)$/.test(v)) bail(line, n, 'booleans are out of subset')
    if (/^-?\d+\./.test(v)) bail(line, n, 'floats are out of subset')
    bail(line, n, `unsupported value ${JSON.stringify(v)}`)
}

function arrayOfStrings(v, line, n) {
    const inner = v.trim().slice(1, -1).trim()
    if (inner === '') return []
    if (inner.includes('[')) bail(line, n, 'nested arrays are out of subset')
    return splitTop(inner).map((e) => {
        const s = scalar(e, line, n)
        if (typeof s !== 'string') bail(line, n, 'only arrays OF STRINGS are in subset')
        return s
    })
}

function splitTop(s) {
    const out = []
    let cur = '', q = false
    for (let i = 0; i < s.length; i++) {
        const c = s[i]
        if (c === '"' && s[i - 1] !== '\\') { q = !q; cur += c }
        else if (c === ',' && !q) { out.push(cur); cur = '' }
        else cur += c
    }
    if (cur.trim() !== '') out.push(cur)
    return out.map((e) => e.trim()).filter((e) => e !== '')
}

function inlineTable(v, line, n) {
    const obj = {}
    for (const pair of splitTop(v.trim().slice(1, -1))) {
        const eq = pair.indexOf('=')
        if (eq < 0) bail(line, n, 'inline-table entry without `=`')
        const k = pair.slice(0, eq).trim()
        const raw = pair.slice(eq + 1).trim()
        obj[k] = raw.startsWith('[') ? arrayOfStrings(raw, line, n) : scalar(raw, line, n)
    }
    return obj
}

function parseToml(text) {
    const root = {}
    let cur = root
    let pendingKey = null, pendingBuf = '', pendingLine = 0

    const lines = text.split('\n')
    for (let i = 0; i < lines.length; i++) {
        const rawLine = lines[i]
        const n = i + 1
        let line = decomment(rawLine).trim()
        if (line === '') continue

        if (pendingKey !== null) {
            pendingBuf += ' ' + line
            if (!line.includes(']')) continue
            cur[pendingKey] = arrayOfStrings(pendingBuf, pendingBuf, pendingLine)
            pendingKey = null; pendingBuf = ''
            continue
        }

        let m = line.match(/^\[\[([A-Za-z0-9_.-]+)\]\]$/)
        if (m) {
            const path = m[1].split('.')
            let node = root
            for (let j = 0; j < path.length - 1; j++) {
                const seg = path[j]
                if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
                else node = (node[seg] = node[seg] || {})
            }
            const leaf = path[path.length - 1]
            if (!Array.isArray(node[leaf])) node[leaf] = []
            const entry = {}
            node[leaf].push(entry)
            cur = entry
            continue
        }

        m = line.match(/^\[([A-Za-z0-9_.-]+)\]$/)
        if (m) {
            const path = m[1].split('.')
            let node = root
            for (const seg of path) {
                if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
                else node = (node[seg] = node[seg] || {})
            }
            cur = node
            continue
        }

        if (line.startsWith('[')) bail(rawLine, n, 'malformed table header')

        const eq = line.indexOf('=')
        if (eq < 0) bail(rawLine, n, 'line is neither a table header nor a key/value pair')
        const key = line.slice(0, eq).trim()
        if (!/^[A-Za-z0-9_-]+$/.test(key)) bail(rawLine, n, `unsupported key ${JSON.stringify(key)} (dotted/quoted keys are out of subset)`)
        const val = line.slice(eq + 1).trim()

        if (val === '') bail(rawLine, n, 'empty value (multi-line strings are out of subset)')
        if (val.startsWith('"""') || val.startsWith("'''")) bail(rawLine, n, 'multi-line strings are out of subset')
        if (val.startsWith('{')) {
            if (!val.endsWith('}')) bail(rawLine, n, 'multi-line inline tables are out of subset')
            cur[key] = inlineTable(val, rawLine, n)
        } else if (val.startsWith('[')) {
            if (val.endsWith(']')) cur[key] = arrayOfStrings(val, rawLine, n)
            else { pendingKey = key; pendingBuf = val; pendingLine = n }   // wraps
        } else {
            cur[key] = scalar(val, rawLine, n)
        }
    }
    if (pendingKey !== null) bail('', pendingLine, 'unterminated array')
    return root
}

// ---------------------------------------------------------------------------
// Seat routing. A seat is not a step: there is no attempt chain, no
// label-keyed [[resolve]] table, and no [security].labels match (a seat carries
// no issue labels). [escalation].fable_gates gate a step's chain-walk into a
// fable variant after failures; a seat's variant is its declared standing
// home, so a fable-max seat resolves to fable-max. What still binds: the
// [security] node pins — the never-list, and the ceiling as a chain-derived
// bound: everything reachable FROM [security].ceiling by escalate_to lies
// beyond it, and a pinned seat standing there is clamped back to the ceiling.
// ---------------------------------------------------------------------------

function resolveSeat(seat, policy) {
    const row = (policy.executors || {})[seat]
    if (!row) {
        throw new Error(
            `tribunal.js: seat ${JSON.stringify(seat)} has no [executors] row. ` +
            `Every voter named by a vote gate must be routable — policy.toml and ` +
            `the workflow corpus have drifted. Refusing to seat the panel.`
        )
    }

    let variant = row.variant
    let never = (row.never || []).slice()

    const sec = policy.security || {}
    if ((sec.nodes || []).includes(seat)) {
        never = never.concat(sec.never || [])
        if (sec.ceiling) {
            const beyond = new Set()
            let c = (policy.variants || {})[sec.ceiling]
            if (!c) {
                throw new Error(
                    `tribunal.js: [security].ceiling ${JSON.stringify(sec.ceiling)} ` +
                    `has no [variants] row — a mistyped ceiling would silently stop ` +
                    `binding. Fix policy.toml. Refusing to seat the panel.`
                )
            }
            while (c && c.escalate_to && !beyond.has(c.escalate_to)) {
                beyond.add(c.escalate_to)
                c = (policy.variants || {})[c.escalate_to]
            }
            if (beyond.has(variant)) variant = sec.ceiling
        }
    }

    let spec = (policy.variants || {})[variant]
    if (!spec) {
        throw new Error(
            `tribunal.js: seat ${JSON.stringify(seat)} names variant ${JSON.stringify(variant)}, ` +
            `which has no [variants] row. Refusing to seat the panel.`
        )
    }

    if (never.includes(spec.model)) {
        const fallback = (policy.escalation || {}).fallback || {}
        variant = fallback[variant]
        spec = (policy.variants || {})[variant]
        if (!spec || never.includes(spec.model)) {
            throw new Error(
                `tribunal.js: no permitted model for seat ${JSON.stringify(seat)} — ` +
                `fallback variant ${JSON.stringify(variant)} is missing or also names a ` +
                `never-listed model. Refusing to seat the panel.`
            )
        }
    }

    return { seat, variant, model: spec.model, effort: spec.effort }
}

// A seat's lens is its trailing name segment: `tribunal-security` -> security.
// An unrecognised seat gets the whole-system lens rather than a throw — a gate
// decided by a generically-briefed judge is still decided; a thrown panel
// leaves the gate undecidable.
const LENSES = {
    architecture:
        'DESIGN, COUPLING, AND PRECEDENT. Does this fit the shape of the system it ' +
        'lands in, or does it bolt a second way of doing something onto a first? What ' +
        'does it couple that was separate, and what does it make harder to change ' +
        'next? What precedent does accepting it set for the next twenty things like it?',
    security:
        'TRUST BOUNDARIES, PROVENANCE, AND BLAST RADIUS. What boundary does this move ' +
        'data or execution across, and who is trusted after it that was not before? ' +
        'Where did the inputs come from and can that provenance be checked? If this is ' +
        'wrong, how far does the damage reach and how would anyone notice?',
    correctness:
        'EVIDENCE, REPRODUCIBILITY, AND VERIFICATION. What is actually demonstrated ' +
        'here versus asserted? Was the claimed behaviour reproduced, and could you ' +
        'reproduce it from what is in front of you? What would have to be true for this ' +
        'to be wrong, and does anything check that?',
}
const WHOLE_SYSTEM_LENS =
    'WHOLE-SYSTEM REVIEW. No narrower lens is declared for your seat, so read this ' +
    'as a generalist: design fit, trust and blast radius, and the quality of the ' +
    'evidence behind every claim.'

function lensOf(seat) {
    const parts = seat.split('-')
    const key = parts[parts.length - 1]
    return { role: key, text: LENSES[key] || WHOLE_SYSTEM_LENS }
}

// ---------------------------------------------------------------------------
// Briefs
// ---------------------------------------------------------------------------

function judgeBrief(r, voteId, gateKind, context, cwd, isRespawn) {
    const { role, text } = lensOf(r.seat)
    const respawnNote = isRespawn ? `

THIS IS A SECOND ATTEMPT AT YOUR SEAT. A prior agent held it and returned
without a recorded cast — \`docket vote show ${voteId}\` shows no entry for
${r.seat}. Nothing it may have concluded reached anyone, so decide the case
yourself from scratch. Whatever stopped the first attempt, the cast is the one
thing that must happen this time: if the command errors, do not abandon it
silently — end with the verbatim error as instructed below.` : ''

    return `You are ONE SEAT of a tribunal deciding a gated proposal in a Docket run.
You decide alone. You cannot see the other seats, you do not coordinate with
them, and your vote is recorded on its own merits — the engine tallies the
panel, not you.

YOUR SEAT:      ${r.seat}
YOUR LENS:      ${text}
THE GATE:       ${gateKind}
THE PROPOSAL:   ${voteId}
WORKING DIR:    ${cwd}${respawnNote}

Your shell's working directory RESETS between Bash calls, so start every single
command with \`cd ${cwd} && \` — that path is also what scopes docket to the
right project.

--- WHAT IS BEING DECIDED (verbatim) ---
${context}
--- END OF WHAT IS BEING DECIDED ---

INVESTIGATE BEFORE YOU VOTE. The payload above is the case as presented, not
the whole record, and a vote cast on the summary alone is worth little. You
have read-only tools; use them. Useful and safe from ${cwd}:

  cd ${cwd} && docket vote show ${voteId}
  cd ${cwd} && docket step show STEP-N / step context STEP-N / step render STEP-N
  cd ${cwd} && docket step artifacts STEP-N   (then \`docket step artifact ARTIFACT-N\`)
  cd ${cwd} && git log --oneline -20 / git diff / git show <sha>

plus reading any file the payload names. Read what the claims rest on. Do not
write, edit, commit, or run anything that mutates state — the ONE state change
you are authorized to make is your own cast, below.

EVIDENCE-QUALITY RULE: A finding backed by reproduced evidence — a mutation
test, a demonstrated failure, a verified repro — outranks any aggregate that
demotes it. Never discount reproduced evidence because other reviewers scored
the issue lower.

ESCALATION (operator-ratified): a reject does not block work forever — the
gate routes onward per its declared routing, to the human operator or into a
rework loop that answers your findings, so reject when the evidence says
reject; do not approve to keep things moving.

CAST YOUR VOTE — exactly once, as your last action, in ONE Bash call:

  cd ${cwd} && docket vote cast ${voteId} --voter ${r.seat} --role ${role} -v <approve|approve-with-concerns|reject> --confidence <0.0-1.0> --domain-relevance <0.0-1.0> --summary "<one-paragraph reasoning>"

  --verdict/-v      approve                = nothing you found should stop this
                    approve-with-concerns  = proceed, with the risks you name recorded
                    reject                 = the evidence says do not proceed as presented
  --confidence      how sure you are of that verdict GIVEN WHAT YOU ACTUALLY
                    CHECKED. A confident verdict on an uninvestigated payload is
                    a lie about your own work; lower the number instead.
  --domain-relevance how much of this decision falls inside YOUR lens. A seat
                    with little purchase on the question says so with a low
                    number rather than inflating one — the tally weighs it.
  --summary         ONE paragraph, on ONE line, in double quotes: your verdict's
                    reasoning and the specific evidence behind it. No line
                    breaks; escape any embedded double quote as \\". Name files,
                    shas, and commands you ran — a summary that could have been
                    written without investigating will read like one.

YOUR FINAL TEXT IS NOT DELIVERED ANYWHERE. THE CAST IS YOUR DELIVERABLE. No
summary you write in chat reaches the panel, the conductor, or the operator;
only the recorded vote does. If the cast command errors, read the error, fix
what it names, and retry ONCE. If it still fails, end your reply with the
verbatim error text and nothing else — that is the only case where your final
text matters.`
}

function checkerBrief(voteId, cwd) {
    return `Run exactly this one command:

  cd ${cwd} && docket vote show ${voteId}

Return its output VERBATIM as your entire final reply — every line, unedited,
no summary, no commentary, no code fence, nothing added. If the command errors,
return the error text verbatim instead.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the vote record currently says.`
}

// ---------------------------------------------------------------------------
// Transport + validation
// ---------------------------------------------------------------------------

let input = args
if (typeof input === 'string') {
    try {
        input = JSON.parse(input)
        log('tribunal.js: decoded args from the harness JSON-encoded transport (normal)')
    } catch (e) {
        throw new Error(
            `tribunal.js: args arrived as a STRING that is not valid JSON (${e.message}). ` +
            `Refusing to seat the panel.`
        )
    }
}
if (!input || typeof input !== 'object') throw new Error(
    `tribunal.js: args is ${typeof input}, expected ` +
    `{voteId, voters, policyText, context, gateKind, cwd}. Refusing to seat the panel.`
)

for (const k of ['voteId', 'policyText', 'context', 'gateKind', 'cwd']) {
    if (typeof input[k] !== 'string' || input[k] === '') {
        throw new Error(
            `tribunal.js: args.${k} is required and must be a non-empty string ` +
            `(got ${JSON.stringify(input[k])}). Refusing to seat the panel.`
        )
    }
}
if (!Array.isArray(input.voters) || input.voters.length === 0) {
    throw new Error(
        `tribunal.js: args.voters must be a non-empty array of seat names ` +
        `(got ${JSON.stringify(input.voters)}). Refusing to seat the panel.`
    )
}

const { voteId, voters, context, gateKind, cwd } = input
const policy = parseToml(input.policyText)

if (policy.policy?.version !== 2) {
    throw new Error(
        `tribunal.js: policy.toml [policy] version is ${JSON.stringify(policy.policy?.version)}, expected 2 ` +
        `(the [variants]/escalate_to shape). Refusing to route against an unknown schema.`
    )
}

// The proposal must already exist and be open: the CALLER creates it. This
// script fills a proposal, and never creates, approves, tallies, or commits one.
const seats = voters.map((v) => resolveSeat(v, policy))

log(`tribunal: ${voteId} — ${gateKind} gate, ${seats.length} seat(s), policy ${(input.policyText || '').length} chars, cwd ${cwd}`)
for (const s of seats) {
    log(`  ${s.seat}: role ${lensOf(s.seat).role} @ ${s.model}/${s.effort} (variant ${s.variant})`)
}

// ---------------------------------------------------------------------------
// Judge / Verify
// ---------------------------------------------------------------------------

function spawnJudge(r, isRespawn) {
    return agent(judgeBrief(r, voteId, gateKind, context, cwd, isRespawn), {
        label: `seat:${r.seat}`,
        phase: 'Judge',
        agentType: 'executor-read',
        model: r.model,
        effort: r.effort,
    }).then((text) => {
        if (text == null) {
            log(`${r.seat}: SPAWN PRODUCED NOTHING (launch blocked, model ${r.model} ` +
                `unavailable, or the agent died mid-flight) — whether a cast landed is ` +
                `UNKNOWN; the verify pass below is what settles it`)
        }
        return text
    }).catch((err) => {
        log(`${r.seat}: spawn error: ${err}`)
        return null
    })
}

function verify() {
    return agent(checkerBrief(voteId, cwd), {
        label: `verify:${voteId}`,
        phase: 'Verify',
        agentType: 'executor-read',
        model: 'haiku',
        effort: 'low',
    }).then((text) => text == null ? '' : text)
        .catch((err) => {
            log(`verify: probe spawn error: ${err}`)
            return ''
        })
}

// A seat has cast when its voter name appears in the vote record. The engine
// enforces one cast per voter name, so a false negative costs one refused
// re-cast, never a double count.
function missingSeats(record) {
    return seats.filter((s) => !record.includes(s.seat))
}

await parallel(seats.map((r) => () => spawnJudge(r, false)))

let outcome = await verify()
let missing = missingSeats(outcome)
let respawns = 0

if (missing.length > 0) {
    respawns = missing.length
    log(`tribunal: ${missing.length} seat(s) returned without a recorded cast ` +
        `(${missing.map((s) => s.seat).join(', ')}) — re-spawning each ONCE`)
    await parallel(missing.map((r) => () => spawnJudge(r, true)))
    outcome = await verify()
    const stillMissing = missingSeats(outcome)
    if (stillMissing.length > 0) {
        log(`tribunal: STILL NO CAST from ${stillMissing.map((s) => s.seat).join(', ')} ` +
            `after the one permitted re-spawn. The panel is short a vote and the tally ` +
            `cannot resolve as designed. The caller decides what happens next — its ` +
            `contract allows ONE re-invocation for the missing seats, and after that ` +
            `the gate escalates to the operator. The record below is what the engine has.`)
    }
}

if (outcome === '') {
    log(`tribunal: the verify probe returned nothing — the outcome text is EMPTY, ` +
        `which says nothing about whether the casts landed. Read the record ` +
        `directly with \`docket vote show ${voteId}\` before acting on this return.`)
}

return { voteId, outcome, seatsSpawned: seats.length, respawns }
