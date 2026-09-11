export const meta = {
    name: 'tribunal',
    description: 'Spawn a judge panel that decides one gated proposal by each seat casting a real `docket vote cast`. This script never casts, approves, or tallies — the engine\'s vote machinery tallies. Runs in two modes: CONVERSATIONAL (no `step` arg) verifies its own tally and re-seats a missing cast once, at the cost of one read-only haiku probe of the vote record after the seats return (two when the first returns nothing), plus one more after any re-seat; MID-WAVE (`step` present) renders the same brief with the gate\'s row context and target ref, spawns the seats, and returns without probing — the caller (wave.js) already reads `docket gate status` for the tally and drives the one permitted re-seat itself. A conversational proposal has no step, so `docket gate status` cannot address it and the probe reads `docket vote show`. Invoke by scriptPath ONLY, with args {voteId, voters, context, gateKind, cwd, step?, target?, heldCluster?, isRespawn?} — `voters` is an array of {seat, model, effort, variant} objects, each seat\'s routing already resolved by the caller from the run\'s pinned policy.toml, since the engine renders routing only onto step rows and a conversational gate has none. The script reads no policy and cannot read files.',
    whenToUse: 'Invoked on a CONVERSATIONAL gate the docket-run skill routes to a panel (ack-reap, activation, budget, loop-extension, fix-batch), always as Workflow({scriptPath}) — never by name. Engine `type = "vote"` step rows ride the wave since the staged closure: wave.js calls this same script MID-WAVE (passing `step`) to seat their panels, one level of workflow nesting deep, so the seat brief renders from one place. The CALLER creates the proposal, passes its id, and passes every voter WITH its {model, effort, variant}; tribunal.js only fills an open one.',
    phases: [
        { title: 'Judge', detail: 'one seat per voter, each casting docket vote cast' },
        { title: 'Verify', detail: 'one haiku probe reads the vote record through a schema (conversational mode only)', model: 'haiku' },
    ],
}

// Verifier settings are local; judges keep caller routing from pinned policy.
const AGENT_CONFIG = {
    verify: { model: 'haiku', effort: 'low' },
}

// ---------------------------------------------------------------------------
// Seat routing is the caller's to supply, resolved from the same pinned
// policy.toml the engine routes step rows from: a seat's standing variant with
// the [security] pins applied. The engine renders that triple onto every vote
// step row, but a conversational gate has no row, so it arrives on each
// `voters` entry instead either way. This script re-derives nothing.
// ---------------------------------------------------------------------------

// A seat missing any of the triple was never routed — the run pins no
// policy.toml, or the roster was re-typed without its fields — and a panel
// seated on a guessed tier is the drift a harness-side policy parser used
// to cause.
function assertRouted(who, entry, refusal) {
    for (const k of ['model', 'effort', 'variant']) {
        if (!entry || typeof entry[k] !== 'string' || entry[k] === '') {
            throw new Error(
                `tribunal.js: ${who} carries no ${k} (got ${JSON.stringify(entry && entry[k])}) — ` +
                `the engine renders model/effort/variant from the run's pinned ` +
                `policy.toml, so this was never routed or was re-typed without ` +
                `its fields. ${refusal}`
            )
        }
    }
}

function resolveSeat(seat, routing) {
    if (typeof seat !== 'string' || seat === '') {
        throw new Error(
            `tribunal.js: a voter carries no seat name (got ${JSON.stringify(seat)}). ` +
            `Refusing to seat the panel.`
        )
    }
    assertRouted(`seat ${JSON.stringify(seat)}`, routing, 'Refusing to seat the panel.')
    return { seat, variant: routing.variant, model: routing.model, effort: routing.effort }
}

// A seat's lens is its trailing name segment (`tribunal-security` -> security);
// an unrecognised seat gets the whole-system lens below rather than a throw, so
// a generically-briefed judge still decides instead of leaving the gate
// undecidable.
//
// A lens is the seat's VOTER brief only — the same trailing names also exist as
// review-executor contracts (contracts/judge-<name>.md) governing the seat when
// a workflow fans it out as a reviewer: one name, two remits, resolved by row
// kind. architecture, security, and design broadly agree across the two;
// correctness deliberately does not, since the contract hunts logic defects
// while this lens interrogates the evidence behind the gate's ask (the
// contract carries the mirror note).
//
// Only lenses reachable from a current workflow's voter names are kept
// (architecture, security, correctness, design); a seat re-adding a retired one
// (completeness, feasibility, risk) must re-add its lens or it falls to the
// whole-system brief below.
const LENSES = {
    architecture:
        'DESIGN, COUPLING, AND PRECEDENT. Does this fit the shape of the system it ' +
        'lands in, or does it bolt a second way of doing something onto a first? What ' +
        'does it couple that was separate, and what does it make harder to change ' +
        'next? What precedent does accepting it set for the next twenty things like it? ' +
        'Was this mechanism chosen against weighed alternatives, or bolted on by default?',
    security:
        'TRUST BOUNDARIES, PROVENANCE, AND BLAST RADIUS. What boundary does this move ' +
        'data or execution across, and who is trusted after it that was not before? ' +
        'Where did the inputs come from and can that provenance be checked? If this is ' +
        'wrong, how far does the damage reach and how would anyone notice? Was a ' +
        'stronger boundary weighed, and why did this one win?',
    correctness:
        'EVIDENCE, REPRODUCIBILITY, AND VERIFICATION. What is actually demonstrated ' +
        'here versus asserted? Was the claimed behaviour reproduced, and could you ' +
        'reproduce it from what is in front of you? What would have to be true for this ' +
        'to be wrong, and does anything check that? Where the record claims one ' +
        'candidate beat another, does the evidence in front of you bear that out?',
    design:
        'USER-FACING SHAPE AND COHERENCE. Does what a person sees and does here hold ' +
        'together — flows that complete, states that are all accounted for, names that ' +
        'mean what they say? Where does the design contradict itself or the system it ' +
        'joins, and what would a first-time user get wrong because of it? Is this ' +
        'shape a weighed alternative or the first one that fit?',
}
const WHOLE_SYSTEM_LENS =
    'WHOLE-SYSTEM REVIEW. No narrower lens is declared for your seat, so read this ' +
    'as a generalist: design fit, trust and blast radius, and the quality of the ' +
    'evidence behind every claim.'

function lensOf(seat) {
    const key = seat.split('-').pop()
    return { role: key, text: LENSES[key] || WHOLE_SYSTEM_LENS }
}

// ---------------------------------------------------------------------------
// Briefs
// ---------------------------------------------------------------------------

// A sha reaches a brief only when it is SHAPED like the full object id the
// engine records — 40 lowercase hex, never an abbreviation, never prose. One
// wave relayed a fabricated 40-hex sha that existed in no repository and
// briefed three judges with it; this check stands behind every render so no
// caller can route around it.
const TARGET_SHA_RE = /^[0-9a-f]{40}$/

// TEST-BEGIN seat-brief — extracted and exercised by
// tests/tribunal-seat-brief.test.sh and tests/wave-target-envelope.test.sh,
// which stub `lensOf` (the only global this reaches for) and assert what a
// mode and a target ref do and do not put in front of a judge. Keep every
// other dependency inside the markers.
function judgeBrief(r, voteId, gateKind, context, cwd, isRespawn, step, target, heldCluster) {
    const { role, text } = lensOf(r.seat)
    // Provenance claim recorded on the cast (--metadata): which seat/variant/
    // model/effort cast this vote, so routing and cost are auditable from the
    // ledger. Argv is world-readable via ps, so ONLY these non-sensitive
    // routing identifiers go in. JSON.stringify emits no single quotes for
    // identifier values, so the single-quoted shell literal below is safe.
    const metadataClaim = JSON.stringify({
        seat: r.seat,
        variant: r.variant,
        model: r.model,
        effort: r.effort,
    })
    const respawnNote = isRespawn ? `

THIS IS A SECOND ATTEMPT AT YOUR SEAT. A prior agent held it and returned
without a recorded cast — \`docket vote show ${voteId}\` shows no entry for
${r.seat}. Nothing it may have concluded reached anyone, so decide the case
yourself from scratch. Whatever stopped the first attempt, the cast is the one
thing that must happen this time: if the command errors, do not abandon it
silently — end with the verbatim error as instructed below.` : ''

    const activationNote = (!step && gateKind === 'activation') ? `

BIND-THEN-PIN (read before you cite a registry gap as provenance drift):
\`docket run activate\` registers the source-config version at BIND TIME, as
part of the same transaction that pins it to the run (documented in \`docket
run activate --help\`). That means the
to-be-activated name@version is EXPECTED to be ABSENT from \`docket workflow
show\`'s registry right up until activation runs — absence pre-activation is
normal, not evidence of anything wrong. A provenance objection must diff the
source-config BYTES against the proposal (or, post-activation, compare the
registered version's hash to the run's pins) — never treat registry absence
alone as proof of drift.` : ''

    // MID-WAVE ONLY: the round's target ref. Seats are NOT seated on the
    // checkout the round was written in — writers work in private worktrees
    // — so without this a judge reads its own lagging HEAD, finds the change
    // absent, and rejects on evidence grounds, which no fix loop can answer.
    const rawTargetSha = (target && target.sha) || ''
    const targetSha = TARGET_SHA_RE.test(rawTargetSha) ? rawTargetSha : ''
    const targetWorktree = (target && target.worktree) || ''
    const targetLines = [
        targetSha ? `TARGET SHA:     ${targetSha} — the commit the diff under this gate stood at` : '',
        targetWorktree ? `TARGET WORKTREE:${targetWorktree} — the checkout that recorded it, while it is still on disk` : '',
    ].filter(Boolean)
    const targetReads = [
        targetSha ? `  git cat-file -t ${targetSha}   — proves the object is here at all` : '',
        targetSha ? `  git show --stat ${targetSha}   then \`git show ${targetSha}\` for the body` : '',
        targetSha ? `  git diff ${targetSha}^ ${targetSha} -- <path>` : '',
        targetWorktree ? `  git -C ${targetWorktree} log --oneline -5` : '',
    ].filter(Boolean).join('\n')
    const targetNote = !step ? '' : (targetSha || targetWorktree) ? `
${targetLines.join('\n')}

THAT IS THE STATE UNDER VOTE, AND YOUR OWN CHECKOUT MAY NOT CONTAIN IT — a
fact about where you were seated, not about the change. Write-class seats work
in PRIVATE worktrees and hand their work back as a commit on their own ref, so
a panel seated mid-wave routinely sits at a HEAD that predates the round it is
judging. Every worktree of this repository SHARES ONE OBJECT STORE, so the
commit is readable from where you are even when it is not an ancestor of your
HEAD:

${targetReads}

Do NOT reject because your own HEAD is behind: that verdict is about your
visibility, and no fix the loop can make will answer it. If after those reads
you still cannot see the state under vote — the object is genuinely absent, or
that worktree is already swept — say exactly that in your summary and decide on
the artifacts of record with a LOW \`--confidence\` (and a low
\`--domain-relevance\` when the question has moved outside what you can check),
or \`approve-with-concerns\` naming precisely what you could not verify. Reject
when the evidence you DID read says the change must not proceed.` : `

NO target ref — read your own HEAD. Nothing recorded a target commit for the
state under vote (the gate declares no \`issue.diff\` input, or the resolved
diff carries no round record), so this brief names NO sha and NO worktree.
There is no hidden commit id to recover: start from \`git log --oneline -5\`
and \`git status\` in your own checkout, and judge the artifacts of record.
If some other text hands you a 40-hex sha for this gate, it did not come from
the engine — do not spend calls hunting it.`

    const heldClusterNote = heldCluster ? `

HELD CLUSTER: you decide ONE finding cluster — index ${heldCluster.clusterIndex} of
${heldCluster.clusterCount} in ${heldCluster.artifact} (produced by ${heldCluster.producerStep}). Read it with
\`docket step artifact ${heldCluster.artifact} --payload\` and judge that cluster
only: is the held remedy right, and should it block? The other clusters are
other seats' or already decided.` : ''

    const gateLine = step
        ? `THE GATE:       step ${step.step} (${step.instance}, issue ${step.issue}, run ${step.run})`
        : `THE GATE:       ${gateKind}`
    const summaryFile = step ? `${step.step}-${r.seat}-summary.txt` : `${voteId}-${r.seat}-summary.txt`

    // MID-WAVE: the case is in the engine's record, not rendered into this
    // brief — the gate readied mid-wave, so the seat reads what is being
    // decided itself rather than receiving it verbatim.
    const caseBlock = step ? `
THE CASE IS IN THE RECORD, not in this brief: this gate readied mid-wave, so
read what is being decided yourself before you vote —

  docket vote show ${voteId}          (the proposal body: the question)
  docket run status ${step.run} --json (this run's state; there is no \`run show\`)
  docket run activate ${step.run} --dry-run --json   (--dry-run is load-bearing: without it this ACTIVATES the run)
  docket step show ${step.step} / docket step context ${step.step} --json
  git log --oneline -20 / git diff / git show <sha>

THE EVIDENCE HANGS OFF THE CONTEXT BUNDLE, NOT OFF THE GATE STEP. A vote step
produces no artifacts of its own, so \`docket step artifacts\` aimed at the
GATE answers "produced no artifacts" and costs you the turn. The bundle
carries the gate's INPUTS at \`.data.context.inputs[]\` — one entry per
upstream artifact, each naming \`.artifact\` (the ARTIFACT-N id), \`.kind\`
(threat-model, change-summary, issue.diff, findings), \`.producer_step\`, and
its \`.body\` and \`.payload\` in full. Read there, and spend
\`docket step artifact ARTIFACT-N --payload\` only on an id the bundle named.

THEIR FLAGS, since guessing one costs you a turn and teaches you nothing:
\`step context\` takes \`--meta\` and NOTHING else; \`step artifact\` takes
\`--payload\`; \`events list\` takes \`--tail N\` (the verb is \`events list\`,
not \`event list\`); \`--json\` is global and works on any of them. None of
these READ verbs takes \`--verbose\`, \`-v\`, or \`--version\` — \`-v\` belongs
to the CAST command below, where it means the verdict, and reaching for it
while reading is the one confusion to avoid. If you want a flag that is not
listed here, run that verb's \`--help\` and read it; never guess one.

AND KNOW \`step artifact\`'S TWO JSON SHAPES BEFORE YOU PARSE ONE. With
\`--payload --json\`, the envelope's \`.data\` IS THE PAYLOAD ITSELF — an ARRAY
for a findings or cluster payload, so \`.data[0]\` is the first entry and
\`.data.get(...)\` raises. Without \`--payload\`, \`--json\` returns the artifact
RECORD and the payload hangs off \`.data.payload\` as a JSON STRING you must
parse a second time. Two seats on one wave lost their whole turn to
\`AttributeError: 'list' object has no attribute 'get'\` on \`d['data'].get('payload')\`
against the first shape. Pick one and match it: \`--payload --json | jq '.data'\`
for the payload, or plain \`--json | jq -r '.data.payload' | jq .\` for the record.

plus reading any file those name. The gate sits downstream of the work it
judges — its issue's earlier steps recorded THIS wave, and their artifacts and
payloads are the evidence. Read what the claims rest on. Do not write, edit,
commit, or run anything that mutates state — the ONE state change you are
authorized to make is your own cast, below.` : `
--- WHAT IS BEING DECIDED (verbatim) ---
${context}
--- END OF WHAT IS BEING DECIDED ---

INVESTIGATE BEFORE YOU VOTE. The payload above is the case as presented, not
the whole record, and a vote cast on the summary alone is worth little. You
have read-only tools; use them. Useful and safe from ${cwd}:

  cd ${cwd} && docket vote show ${voteId}
  cd ${cwd} && docket run status RUN-N --json   (there is no \`run show\`)
  cd ${cwd} && docket run activate RUN-N --dry-run --json   (--dry-run is load-bearing: without it this ACTIVATES the run)
  cd ${cwd} && docket step show STEP-N / step context STEP-N / step render STEP-N
  cd ${cwd} && docket step artifacts STEP-N   (then \`docket step artifact ARTIFACT-N\`)
  cd ${cwd} && git log --oneline -20 / git diff / git show <sha>

plus reading any file the payload names. Read what the claims rest on. Do not
write, edit, commit, or run anything that mutates state — the ONE state change
you are authorized to make is your own cast, below.

SCOPE YOUR INVESTIGATION TO WHAT THIS GATE DECIDES. An activation gate decides
whether the run may START: verify the binding against the routing rules, the
budget against the expected cost, the scope warnings, and the corpus/trust
state — the merits of the work itself get their own gates once artifacts
exist, and pre-reviewing the codebase here duplicates them. A budget gate
decides a number against evidence of spend; an ack-reap gate decides whether a
holder is gone; a fix-batch gate decides whether the conductor's batch of fixes
may land as one unit, judged on the files the batch changed; a loop-extension
gate decides whether ONE more fix round is
likely to converge, read from the loop history in the rationale — rounds
against the cap, consecutive rejections, the tiers served, spend, and the
finding-volume trend — not from re-reviewing the work, which the loop's own
judges already did. Depth belongs to gates whose SUBJECT is the work.`

    const settledGround = step ? `

SETTLED GROUND (operator-ratified): a finding whose \`prior_disposition\`
records a ruling — accepted, corrected, rejected, or deferred with its
follow-up issue named — is decided ground: an operator or an earlier panel
already spent that decision, and the fix loop deliberately does not re-route
it. Re-read the ruling before weighing the finding, and re-litigate it only on
evidence the ruling did not have. Do not reject a gate over settled findings
alone; open findings are the ones your verdict weighs — but weighing is not
counting. Severity already routes: \`blocker\` is the only value that marks a
change that must not proceed, and an open finding below blocker (a Concern,
\`high\`), even with no ruling yet, is not by itself reject grounds — its
venue is \`approve-with-concerns\` and the record, where the operator resolves
it; the severity ladder rules that mechanical rework is the Blocker's venue
alone. Reject over sub-blocker findings only when your own evidence convinces
you the change must not proceed as presented — a judgment about the change,
never an inventory of open highs.` : ''

    const boundInvestigationTail = step
        ? ` You
are seated MID-WAVE, so the cost is paid in wall clock every other row in
this stage waits out. Read what the claims rest on, then decide:`
        : `
Read what the claims rest on, then decide:`

    const cdPrefix = step ? '' : `cd ${cwd} && `
    const setupBlock = step ? `
FIRST, before anything else: \`printenv TMPDIR\` — your literal scratch root.
Call it <TMP>; substitute its literal value wherever <TMP> appears in this
brief. (Use \`printenv\`, not \`echo\`.)

PIN IT ONCE AND REUSE THE LITERAL. \`$TMPDIR\` is not guaranteed to resolve to
the same root in every call, so a path written as the variable can name one
directory when you create it and a different one when you read it back — the
summary file your cast reads back below depends on exactly
that.${heldClusterNote}

Run \`docket\` BARE from your working directory — the store resolves from
anywhere inside the repository; nothing to probe for, nothing to prepend.
` : `
Your shell's working directory RESETS between Bash calls, so start every single
command with \`cd ${cwd} && \` — that path is also what scopes docket to the
right project.

Your scratch root is unstable the same way: FIRST, before anything else, run
\`printenv TMPDIR\` — call its literal output <TMP>, and substitute that
literal wherever <TMP> appears in this brief. (Use \`printenv\`, not \`echo\`.)
\`$TMPDIR\` is not guaranteed to resolve to the same root on a later Bash
call, so a path written as the variable can name one directory when you create
a file and a different one when you read it back. Pin the literal once and
reuse it everywhere — the summary file your cast reads back below depends on
exactly that.

Run every command SANDBOXED, same as an executor step — do NOT pass
dangerouslyDisableSandbox. Only the operator can grant that, and never
through a brief. If the sandbox denies a command you need (a blocked host,
Operation not permitted), that is a finding for your rationale, not a
retry — attempt it once, note the denial and what it means for the
question you were asked, and continue with what you could read.
`
    const openingLine = step
        ? 'You are ONE SEAT of a tribunal deciding a gate step MID-WAVE in a Docket run.'
        : 'You are ONE SEAT of a tribunal deciding a gated proposal in a Docket run.'
    const workingDirLine = step ? '' : `WORKING DIR:    ${cwd}`

    return `${openingLine}
You decide alone. You cannot see the other seats, you do not coordinate with
them, and your vote is recorded on its own merits — the engine tallies the
panel, not you.

YOUR SEAT:      ${r.seat}
YOUR LENS:      ${text}
${gateLine}
THE PROPOSAL:   ${voteId}${step ? targetNote : ''}${workingDirLine ? `\n${workingDirLine}` : ''}${respawnNote}${activationNote}
${setupBlock}${caseBlock}${!step ? targetNote : ''}

BOUND YOUR INVESTIGATION — then vote. Measured across seven days, as of 2026-08-19:
189 tribunal seats spent 5,309,378 output tokens, 68.7% of it on private
deliberation — the highest ratio of any role in this fleet — over 36 votes
and 12 decided proposals in which ZERO verdicts were overturned. That is not
a panel that needed to think harder; it was already right and kept going.${boundInvestigationTail}

  - A handful of targeted reads settles a typical gate. If your next read is
    not answering a question you can NAME, you are past the point of value.
  - You are ONE seat, not the panel. Another lens covering what yours does not
    is the design working, not a gap for you to close.
  - A concern you cannot resolve is what \`approve-with-concerns\` and the
    summary field exist for. Write it down; do not investigate it away.
  - When you can state a verdict and one paragraph of why, cast. The bar is
    whether your evidence supports the verdict — not whether more reading
    could raise your confidence further. It always could.

EVIDENCE-QUALITY RULE: A finding backed by reproduced evidence — a mutation
test, a demonstrated failure, a verified repro — outranks any aggregate that
demotes it. Never discount reproduced evidence because other reviewers scored
the issue lower.${settledGround}

ESCALATION (operator-ratified): a reject does not block work forever — the
gate routes onward per its declared routing, to the human operator or into a
rework loop that answers your findings, so reject when the evidence says
reject; do not approve to keep things moving.

CAST YOUR VOTE — exactly once, as your last action, in TWO Bash calls. First
write your one-paragraph summary to a scratch file with a QUOTED heredoc —
quoting the delimiter means the shell expands NOTHING in the body: backticks,
$( ), and $VAR all stay literal text. The filename carries your ${step ? 'step' : 'proposal'} and
seat, so no other seat's file can collide with yours:

  ${cdPrefix}cat > <TMP>/${summaryFile} <<'EOF'
  <your one-paragraph reasoning, on ONE line>
  EOF

Then cast, reading the file back — safe because the substitution wraps a fixed
\`cat\` of your own file, so its content passes into the flag verbatim instead
of being re-parsed as shell syntax:

  ${cdPrefix}docket vote cast ${voteId} --voter ${r.seat} --role ${role} -v <approve|approve-with-concerns|reject> --confidence <0.0-1.0> --domain-relevance <0.0-1.0> --metadata '${metadataClaim}' --summary "$(cat <TMP>/${summaryFile})"

  --verdict/-v      approve                = nothing you found should stop this
                    approve-with-concerns  = proceed, with the risks you name recorded
                    reject                 = the evidence says do not proceed as presented
  --confidence      how sure you are of that verdict GIVEN WHAT YOU ACTUALLY
                    CHECKED. A confident verdict on an uninvestigated payload is
                    a lie about your own work; lower the number instead.
  --domain-relevance how much of this decision falls inside YOUR lens. A seat
                    with little purchase on the question says so with a low
                    number rather than inflating one — the tally weighs it.
  --metadata        pre-filled with requested seat routing (seat, variant,
                    model, effort), not observed serving-model telemetry.
                    Pass it unchanged. It is unverified, stored as-is, and
                    public. The relay measures observed models from the
                    completed transcript; do not infer them from this routing.
  --summary         ONE paragraph: your verdict's reasoning and the specific
                    evidence behind it. Write it to the scratch file EXACTLY as
                    above — NEVER type the paragraph inline in double quotes:
                    backticks, $( ), and $VAR execute there. No line breaks
                    inside the file. Name files, shas, and commands you ran —
                    a summary that could have been written without
                    investigating will read like one.

YOUR FINAL TEXT IS NOT DELIVERED ANYWHERE. THE CAST IS YOUR DELIVERABLE.${step ? ` If the
cast command errors, read the error, fix what it names, and retry ONCE. If it
still fails, end your reply with the verbatim error text and nothing else —
that is the only case where your final text matters.` : ` No
summary you write in chat reaches the panel, the conductor, or the operator;
only the recorded vote does. If the cast command errors, read the error, fix
what it names, and retry ONCE. If it still fails, end your reply with the
verbatim error text and nothing else — that is the only case where your final
text matters.`}`
}
// TEST-END seat-brief

// The probe answers a jq projection through a schema, never the raw record
// as text: the full envelope is ~10KB on a 3-seat proposal, two haiku probes
// on one wave corrupted verbatim copies of it (a dropped brace, 81 chars lost
// mid-copy), and the raw-text fallback that rescued them could equally match
// a seat name quoted in prose. Under 300 bytes of fixed shape, validated by
// the harness, is the record or it is nothing. A conversational proposal has
// no step, so `docket gate status` cannot address it; `vote show` is the read.
const VOTE_SHOW_JQ =
    `jq -c '{status: .data.status, final_outcome: .data.final_outcome, ` +
    `votes: [.data.votes[]? | {voter_name, verdict}]}'`

const VOTE_SHOW_SCHEMA = {
    type: 'object',
    properties: {
        status: { type: 'string' },
        final_outcome: { type: 'string' },
        votes: {
            type: 'array',
            items: {
                type: 'object',
                properties: { voter_name: { type: 'string' }, verdict: { type: 'string' } },
                required: ['voter_name'],
            },
        },
        error: { type: 'string' },
    },
}

function checkerBrief(voteId, cwd) {
    return `WAVE PROBE: not a step execution. Run exactly this one command:

  cd ${cwd} && docket vote show ${voteId} --json | ${VOTE_SHOW_JQ}

Run it SANDBOXED — do NOT pass dangerouslyDisableSandbox. Only the operator
can grant that, and never through a brief. If the sandbox denies it, return
{error: <the denial text verbatim>} instead of retrying with the sandbox
disabled.

Return the printed object through the structured output, field for field and
value for value — copy, never summarize; add no field the output did not carry
and fill none in. If the command errors, return {error: <the error text
verbatim>} and nothing else.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the vote record currently says.`
}

// ---------------------------------------------------------------------------
// Transport + validation
// ---------------------------------------------------------------------------

function decodeArgs(value) {
    if (typeof value !== 'string') return value
    try {
        const input = JSON.parse(value)
        log('tribunal.js: decoded args from the harness JSON-encoded transport (normal)')
        return input
    } catch (error) {
        throw new Error(
            `tribunal.js: args arrived as a STRING that is not valid JSON (${error.message}). ` +
            `Refusing to seat the panel.`
        )
    }
}

function assertRequiredStrings(value, fields, path) {
    for (const field of fields) {
        if (typeof value[field] !== 'string' || value[field] === '') {
            throw new Error(
                `tribunal.js: ${path}.${field} is required and must be a non-empty string ` +
                `(got ${JSON.stringify(value[field])}). Refusing to seat the panel.`
            )
        }
    }
}

const input = decodeArgs(args)
if (!input || typeof input !== 'object') throw new Error(
    `tribunal.js: args is ${typeof input}, expected ` +
    `{voteId, voters, context, gateKind, cwd}. Refusing to seat the panel.`
)

// MID-WAVE mode is signaled by a `step` object — the caller is wave.js,
// seating a panel on an engine-scheduled vote row rather than a conversational
// gate it opened itself. Mid-wave carries no rendered `context`: the brief
// tells the seat to read the case from the engine's own record instead.
const isMidWave = input.step !== undefined && input.step !== null
const requiredStrings = isMidWave ? ['voteId', 'gateKind', 'cwd'] : ['voteId', 'context', 'gateKind', 'cwd']
assertRequiredStrings(input, requiredStrings, 'args')
if (isMidWave) assertRequiredStrings(input.step, ['step', 'instance', 'issue', 'run'], 'args.step')
if (!Array.isArray(input.voters) || input.voters.length === 0) {
    throw new Error(
        `tribunal.js: args.voters must be a non-empty array of ` +
        `{seat, model, effort, variant} objects ` +
        `(got ${JSON.stringify(input.voters)}). Refusing to seat the panel.`
    )
}

const { voteId, voters, context, gateKind, cwd, step, target, heldCluster, isRespawn } = input

// The proposal must already exist and be open: the CALLER creates it (or, mid-
// wave, the engine's record-driving does). This script fills a proposal, and
// never creates, approves, tallies, or commits one.
const seats = voters.map((v) => resolveSeat(v && v.seat, v))

log(`tribunal: ${voteId} — ${gateKind} gate, ${seats.length} seat(s), cwd ${cwd}` +
    (isMidWave ? ` (mid-wave, step ${step.step})` : ''))
for (const s of seats) {
    log(`  ${s.seat}: role ${lensOf(s.seat).role} @ ${s.model}/${s.effort} (variant ${s.variant})`)
}

// ---------------------------------------------------------------------------
// Judge / Verify
// ---------------------------------------------------------------------------

function spawnJudge(r, respawn) {
    return agent(judgeBrief(r, voteId, gateKind, context, cwd, respawn, step, target, heldCluster), {
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
        return { seat: r.seat, error: String(err) }
    })
}

// The record, or null when the probe died, the command errored, or the reply
// carried no votes[] — null means UNKNOWN, never "every seat missing".
function verify() {
    return agent(checkerBrief(voteId, cwd), {
        label: `verify:${voteId}`,
        phase: 'Verify',
        agentType: 'executor-read',
        ...AGENT_CONFIG.verify,
        schema: VOTE_SHOW_SCHEMA,
    }).then((record) => {
        if (record && Array.isArray(record.votes)) return record
        if (record && typeof record.error === 'string') log(`verify: engine error — ${record.error}`)
        return null
    }).catch((err) => {
        log(`verify: probe spawn error: ${err}`)
        return null
    })
}

// A seat has cast when its voter name is in the record's votes[]. The engine
// enforces one cast per voter name, so a false negative costs one refused
// re-cast, never a double count.
function missingSeats(record) {
    const cast = record.votes.map((v) => v.voter_name)
    return seats.filter((s) => !cast.includes(s.seat))
}

// Retry an unknown record before deciding whether any seats need another attempt.
async function verifyWithRetry() {
    const outcome = await verify()
    if (outcome !== null) return outcome
    log(`tribunal: the verify probe returned nothing — retrying the probe ONCE before reading any seat as missing`)
    return verify()
}

async function verifyPanel() {
    phase('Verify')
    const initialOutcome = await verifyWithRetry()
    const missing = initialOutcome === null ? [] : missingSeats(initialOutcome)
    if (missing.length > 0) {
        log(`tribunal: ${missing.length} seat(s) returned without a recorded cast ` +
            `(${missing.map((s) => s.seat).join(', ')}) — re-spawning each ONCE`)
        await parallel(missing.map((r) => () => spawnJudge(r, true)))
    }

    const outcome = missing.length > 0 ? await verify() : initialOutcome
    const stillMissing = missing.length > 0 && outcome !== null ? missingSeats(outcome) : []
    if (stillMissing.length > 0) {
        log(`tribunal: STILL NO CAST from ${stillMissing.map((s) => s.seat).join(', ')} ` +
            `after the one permitted re-spawn. The panel is short a vote and the tally ` +
            `cannot resolve as designed. The caller decides what happens next — its ` +
            `contract allows ONE re-invocation for the missing seats, and after that ` +
            `the gate escalates to the operator. The record below is what the engine has.`)
    }

    if (outcome === null) {
        log(`tribunal: the verify probe returned nothing twice — the outcome is null, ` +
            `which says nothing about whether the casts landed, and no seat was re-spawned ` +
            `on that silence. Read the record directly with \`docket vote show ${voteId}\` ` +
            `before acting on this return.`)
    }

    return { voteId, outcome, seatsSpawned: seats.length, respawns: missing.length }
}

phase('Judge')
const spawned = await parallel(seats.map((seat) => () => spawnJudge(seat, Boolean(isRespawn))))

// Mid-wave callers own verification and the one permitted re-seat; conversational
// panels verify their own record because they have no gate-status envelope.
const result = isMidWave
    ? { voteId, seatsSpawned: seats.length, absorbed: spawned.filter((seat) => seat && typeof seat === 'object' && typeof seat.error === 'string') }
    : await verifyPanel()

return result
