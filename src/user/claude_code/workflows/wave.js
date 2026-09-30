export const meta = {
    name: 'wave',
    description: 'Internal: launched through scriptPath by docket-run, once per lane unit, to run one launch\'s share of a dispatched manifest end to end (executors, vote panels, staged issue lanes). Per vote row it spends 3 read-only haiku probes of `docket gate status` on the normal path, 1 on a gate that was already decided, and 4 when a re-seat is needed. Budget, launch, lane and reply-tail contract in the header comment.',
    whenToUse: 'Never by name. Args are {rows, tribunal, cwd, unit?, harnessCap?, integrated?} with the launch\'s own rows verbatim from lane_units.py; the full argument contract is in the header comment.',
}

// ---------------------------------------------------------------------------
// CONTRACT FOR CALLERS (the listing's description is deliberately one line;
// this block is the single copy of what it used to carry).
//
// What it does:
// Run one dispatched manifest end to end: spawn one executor per executor row
// at the model/effort the engine rendered on it, seat a judge panel on each
// vote row from its routed roster, and skip action rows (engine-run at record
// time). Stages run as awaited groups per issue lane, with the cross-issue
// cohorts the manifest certifies honored — the staged closure means one wave
// can carry judges -> gate -> reconcile -> report, and inside a wave no issue
// idles behind the slower stages of another; writers the engine never co-
// staged still serialize, so a wave launches at most three such writer cohorts
// and defers the rest to the next dispatch rather than holding every finished
// lane behind a long writer ladder. AGENT BUDGET: the Workflow tool caps one
// invocation at 1000 agents over its lifetime, so the wave reserves each row's
// projected agents at admission (executor 2, vote row seats+4) against a
// 900-agent budget and defers, on the spot and without holding its lane, every
// row the remainder cannot cover; the engine re-offers deferred rows at the
// next dispatch, and a manifest of any size is safe to hand over whole.
// LAUNCHES: both caps are per invocation, so one dispatch launches one wave
// per lane unit, up to LAUNCH_CAP (20), each handed ONLY its own rows plus
// `unit: {index, of, classCap}` from lane_units.py — whole issue lanes as
// units, writer lanes the engine never co-staged welded into one unit so they
// still serialize, and classCap carrying this launch's share of each class's
// headroom over the full manifest. The retired `shard` arg is refused.
// PROBE COST PER VOTE ROW: 3 read-only haiku probes on the normal
// path — `docket gate status` before the panel seats (decided yet, which
// proposal, which target), one projection of the proposal body (the case every
// seat brief renders verbatim, with no cast in it: seats never read the vote
// record themselves, since it prints every sibling cast already landed), and
// `docket gate status` after the panel returns (missing seats and the tally) —
// 1 on a gate that was already decided before the wave reached it, and 4 when
// a re-seat forces a re-read; a gate with no proposal yet spends a `step show`
// for the engine's blocked_reason instead of a panel, and an engine-minted
// held-cluster gate spends one more read to name its cluster. Each probe
// answers through a schema, under 1 KB; the per-gate count is reported
// verbatim in that row's spawn_accounting. HARNESS CONCURRENCY: admission
// weighs each row against the harness's own per-invocation concurrency cap
// (executor 1, vote row = its seat count — the peak the panel's own
// `parallel()` fan-out draws, a DIFFERENT quantity from the agent-budget
// projection above), narrowed to the conductor-reported `harnessCap` when
// present. Invoke by scriptPath ONLY, with args {rows, tribunal, cwd, unit?,
// harnessCap?} as a real object — every row carries model/effort/variant
// resolved by the engine, and the script reads no policy and cannot read
// files.
//
// When and how it is invoked:
// Invoked by the docket-run skill on an open dispatch, always as
// Workflow({scriptPath}) — never by name, and once per lane unit, every
// launch in the same conductor turn. args is {rows, tribunal, cwd, unit?,
// harnessCap?}: the launch's own rows from `dispatch open` VERBATIM, as
// lane_units.py split them (executor, vote, and action rows; human rows stay
// with the conductor), each
// executor row carrying the model/effort/variant the engine resolved from the
// run's pinned policy.toml and each vote row carrying the same per voter in
// `voter_assignments` — a row re-typed without those fields is refused.
// `tribunal` is the absolute installed path to tribunal.js, the one workflow-
// nesting level this script uses to seat every in-wave panel (it cannot
// resolve that path itself); `cwd` is the repo the run belongs to.
// `harnessCap` is the per-invocation agent() concurrency cap, computed by
// lane_units.py and copied by the conductor from launches.json (this script
// cannot read the machine's CPU count itself); when present and a positive
// integer, the wave admits against min(16, harnessCap) instead of the loose
// 16-agent ceiling it would otherwise assume, and logs which bound it used
// either way — a caller that omits the field is not refused. On a dispatch
// carrying a fix round's review fanout, args also carries `integrated` — a
// map from each such issue to the sha of its prior round's INTEGRATION
// commit — so the wave can assert base ancestry before seating the fanout.
// There is no policy argument of any kind and no file access.
// ---------------------------------------------------------------------------

// TEST-BEGIN configuration — shared by the extracted behavior suites.
// Only helper probes use these defaults. Executors and panel seats retain
// the model/effort the engine resolved from the run's pinned policy.
const AGENT_CONFIG = {
    probe: { model: 'haiku', effort: 'low' },
    gateStatus: { model: 'haiku', effort: 'low' },
    heldCluster: { model: 'haiku', effort: 'low' },
    proposal: { model: 'haiku', effort: 'low' },
    blockProbe: { effort: 'low' }, // Deliberately inherit the session model.
}

const BLOCK_PROBE_LOOKBACK_HOURS = 12
const CONFLICT_REPORT_MAX_LINES = 4
const WRITER_LADDER_BUDGET = 3
const AGENT_LIFETIME_CAP = 1000
const AGENT_BUDGET_RESERVE = 100
const AGENT_BUDGET = AGENT_LIFETIME_CAP - AGENT_BUDGET_RESERVE
let agentsLaunched = 0   // real agent() calls made this invocation (countedAgent below)
const EXECUTOR_AGENT_COST = 2
const VOTE_PROBE_COST = 4
const DEFAULT_PANEL_SEATS = 3
const HARNESS_CAP = 16
// Most concurrent wave launches per dispatch, one per lane unit. 20 is the
// measured bound; nothing above it was tested. Keep it equal to LAUNCH_CAP in
// lane_units.py.
const LAUNCH_CAP = 20
// Every agent() call in this file goes through countedAgent. At the cap it
// rejects with AgentCapError, which the spawn path settles as `agent-cap`.
class AgentCapError extends Error {
    constructor() {
        super(`agent-cap: ${AGENT_LIFETIME_CAP} agent() calls launched this invocation`)
        this.name = 'AgentCapError'
    }
}
function countedAgent(brief, options) {
    if (agentsLaunched >= AGENT_LIFETIME_CAP) return Promise.reject(new AgentCapError())
    agentsLaunched++
    return agent(brief, options)
}
// TEST-END configuration

// Routing rides the row: the engine resolves {model, effort, variant} for
// every executor row and every voter from the run's PINNED policy.toml. This
// script re-derives none of it.

function labelsOf(row) {
    if (Array.isArray(row.labels)) return row.labels
    if (row.issue && Array.isArray(row.issue.labels)) return row.issue.labels
    return []
}

function resolve(row) {
    if (row.kind !== 'executor') {
        // action and vote rows never reach resolve(): the stage loop below
        // handles both natively (skip / seat a panel). Anything else here is
        // a misrouted row.
        const why = {
            human: 'human gate steps are never claimed — they are approved or ' +
                'rejected directly, and they stay with the conductor',
        }[row.kind] || 'only kind:"executor" rows are spawnable'
        throw new Error(
            `wave.js: step ${row.step} is kind:${JSON.stringify(row.kind)} — ${why}. ` +
            `Refusing to route.`
        )
    }

    const hint = row.executor
    assertRouted(`executor ${JSON.stringify(hint)} (step ${row.step})`, row, 'Refusing to route.')
    return {
        hint, variant: row.variant,
        model: row.model, effort: row.effort,
        model_requested: row.model, effort_requested: row.effort,
    }
}

const WRITE_HINTS = [
    'implement', 'fix',
    'prd-author', 'tdd-author', 'tdd-author-security',
    'adr-author', 'ux-spec-author',
    'spec-author-architecture', 'spec-author-security', 'spec-author-operations',
    'spec-author-performance', 'spec-author-code-quality',
    'spec-author-review-strategy', 'spec-author-testing',
]

function archetype(row, hint) {
    if (hint === 'research') return 'executor-research'
    if (row.class === 'write' || WRITE_HINTS.includes(hint)) return 'executor-write'
    return 'executor-read'
}

// SCRATCH HYGIENE: every file an executor writes lives in its private
// per-step directory <TMP>/<step>.d, mode 0700, built fresh at claim and
// removed by the executor once a record or fail exits 0. An interrupted
// executor's dir is swept by the conductor at reap (docket-run/SKILL.md, "A
// dead spawn is reaped, not waited out."). The engine refuses a stale token
// either way; the sweep limits exposure and accumulation.
//
// HOW THIS BRIEF IS WORDED, and it is load-bearing: state the required form,
// omit the defense. A brief never addresses the safety classifier, names a
// technique by what it gets past, or pre-argues its own authorization.
// TEST-BEGIN bootstrap — extracted and exercised by
// tests/wave-bootstrap-render.test.sh. Keep this function free of workflow
// globals (agent, log, args) so it stays evaluable on its own;
// tests/wave-model-attribution.test.sh and
// tests/wave-bootstrap-owner-discriminator.test.sh extract from the
// declaration line below.
function bootstrap(row, r, isolated, isWrite) {
    // One array of command strings renders both claim forms (isolated: one
    // per Bash call; shared: one `&&`-chained call). claimCommands is nested
    // so every suite that extracts bootstrap carries it along.
    // The owner carries a per-step launch counter, so a retry of the same
    // step never presents the owner of a claim process that is still alive.
    // Per step, not global: a global counter follows agent completion order
    // and would change the rendered bytes on resume. Math.random() and
    // Date.now() throw in a workflow script.
    bootstrap.launchesByStep = bootstrap.launchesByStep || new Map()
    const priorLaunches = bootstrap.launchesByStep.get(row.step) || 0
    bootstrap.launchesByStep.set(row.step, priorLaunches + 1)
    const ownerDiscriminator = priorLaunches + 1
    // `docket step claim` exits 0 with a non-empty `.data.claim_error` when
    // the lease committed but a later stage failed. The `jq -e` guard stops
    // the chain there: after the token is captured, before the packet is read.
    function claimCommands(isolated) {
        const dir = `<TMP>/${row.step}.d`
        const claimJson = `${dir}/${row.step}.claim.json`
        const token = `${dir}/${row.step}.token`
        const packet = `${dir}/${row.step}.packet.md`
        return [
            `rm -rf ${dir}`,
            `mkdir -m 700 ${dir}`,
            `docket step claim ${row.step} --owner wave:${row.step}:${ownerDiscriminator} --render --metadata ${claimMetadataArg} --json > ${claimJson} < /dev/null`,
            isolated
                ? `jq -r '.data.token' ${claimJson} > ${token}`
                : `jq -r '.data.token'  < ${claimJson} > ${token}`,
            `chmod 600 ${token}`,
            `jq -e '(.data.claim_error // "") == ""' ${claimJson} > /dev/null`,
            `jq -r '.data.packet' ${claimJson} > ${packet}`,
            `cat /dev/null > ${claimJson}`,
        ]
    }
    // Routing is known before execution; recording it at claim preserves it
    // when the executor fails. Clear prior-attempt observations at the same
    // boundary. A requested alias is not evidence of the serving model.
    const claimMetadata = JSON.stringify({
        variant: r.variant,
        model_requested: r.model_requested,
        effort_requested: r.effort_requested,
        model_resolved: 'unknown',
        effort_resolved: 'unknown',
    })
    const claimMetadataArg = "'" + claimMetadata.replace(/'/g, "'\\''") + "'"
    // The TMPDIR pin paragraph appears once per brief — in bootstrap (a) for
    // isolated executors, in pinNote for everyone else. The two renderings
    // are deliberate near-mirrors of one rule; a wording change lands in
    // BOTH or the two executor classes drift apart on the same hazard.
    const isolationNote = isolated ? `

0. YOU ARE IN A PRIVATE WORKTREE. These rules bind every call:

   - ONE action per Bash call, PLAIN and SEPARATE: no \`&&\` chains, no
     \`$(...)\` substitution around git. Pipes are fine.
   - Spell every redirect target as a LITERAL absolute path.
   - Run git against YOUR OWN tree only: never \`git -C\`/\`--git-dir\` at
     another checkout, never cd out to the shared repository tree.
   - A probe that must modify files runs on a COPY under <TMP>, never on
     this checkout (never git restore, checkout --, reset, or clean).
   - RUN \`docket\` BARE, with no DOCKET_PATH prefix.

   Bootstrap, one plain command at a time:

   a. \`printenv TMPDIR\` (not \`echo\`). Its literal output is <TMP>:
      substitute it wherever <TMP> or \`$TMPDIR\` appears in this brief and
      REUSE THAT LITERAL on every call; \`$TMPDIR\` can resolve to another
      root later.
   b. \`git worktree list --porcelain\`: every checkout's path and HEAD sha.
   c. Compare \`git rev-parse HEAD\` in your tree to the HEAD of the shared
      checkout from (b), the one NOT under \`.claude/worktrees\`. If they
      differ, run \`git checkout --detach --quiet <that sha>\`.

   If the guard or the permission system DENIES one, put \`BOOTSTRAP DENIED\`
   on a line of its own as the FIRST line of your reply, quote the denial
   verbatim under it, and STOP. If a command fails on its own output, report
   it verbatim and STOP. NEVER claim after a failed bootstrap.

   After (c), your NEXT command is the claim in 1', with no exploratory
   docket verbs first. With the packet in hand, the one sanctioned extra
   read is \`docket step artifact ARTIFACT-N --payload\` on an artifact id
   the packet names.

   Your inputs arrive in the packet; uncommitted work in the shared tree is
   not visible here.` : ''
    const pinNote = isolated ? '' : `

0. FIRST, before the claim: \`printenv TMPDIR\` (not \`echo\`). Its literal
   output is <TMP>: substitute it wherever <TMP> appears below and REUSE
   THAT LITERAL on every call; \`$TMPDIR\` can resolve to another root
   later.`
    return `You are executing one step of a Docket run. Follow these obligations exactly.

YOUR ASSIGNMENT: step ${row.step} (issue ${row.issue}, run ${row.run}). Every
${row.step} below is your real, already-substituted step id.${isolationNote}${pinNote}

1. Claim it AND PARK THE TOKEN ON DISK${isolated ? ` — separate plain Bash
   calls, literal paths throughout (form 1', which obligation 0 names):

${claimCommands(true).map((c) => `   \`${c}\``).join('\n')}
` : `, in ONE Bash call, exactly this:

   \`\`\`
   ${claimCommands(false).join(' &&\n     ')}
   \`\`\`
`}
   EVERYTHING you write goes inside <TMP>/${row.step}.d, your PRIVATE STEP
   SCRATCH DIR, under filenames that start with your step id.

   Then open <TMP>/${row.step}.d/${row.step}.packet.md with the Read tool — it
   is your contract.

   IF THE CHAIN STOPS BEFORE THE PACKET LINE: do NOT retry the claim and do
   NOT read a packet. Run ONE read-only diagnostic:

   \`jq -c '{error: .error, code: .code, claim_error: .data.claim_error, re_minted: .data.re_minted}' <TMP>/${row.step}.d/${row.step}.claim.json\`

   EMPTY token file: report CLAIM FAILED with that diagnostic verbatim and
   STOP. Token captured but \`claim_error\` non-empty: you hold a live token
   and MUST end it with
   \`docket step fail ${row.step} --note '<claim_error verbatim>' < <TMP>/${row.step}.d/${row.step}.token\`,
   then report CLAIM INCOMPLETE with the diagnostic and STOP. Name
   \`re_minted: true\` in your report when the diagnostic shows it.

   If the claim committed but no token was captured, re-run the same claim
   command with the same --owner; it re-mints the token (\`re_minted: true\`).

   On CONFLICT: stop immediately and report AT MOST three lines: your step id,
   the word CONFLICT, and the engine's error line verbatim. Do not investigate
   the holder, the scopes, or the remedy.

2. Execute the brief you were handed (the packet). It is your entire contract.${isWrite ? `
   Ship the issue's declared change list and NOTHING beyond it: unrequested
   hardening, extra controls, and adjacent cleanups go into gap files
   (obligation 3), never into the diff. The one exception: a defect you find
   that is actively exploitable is REPORTED in your return immediately, not
   merely gap-filed.` : ''}
${!isWrite ? `
2r. THE CHECKOUT YOU STAND IN MAY PREDATE THE CHANGE YOUR PACKET DESCRIBES.
   Before reading ANY file by path to evaluate the change:

   - FIRST: if the packet's issue.diff is EMPTY and the change-summary
     records a gap-only outcome (no commit, no files changed), confirm that
     pair in ONE read-only pass and record at once, naming the
     engine-computed half (the empty issue.diff) and the self-reported half
     (the summary); file no duplicate gap.
   - The change-summary's FIRST LINE carries the target sha. IF IT CARRIES
     NONE, or reports COMMIT BLOCKED, the packet's target_sha is NOT the
     change: say so in your record, evaluate the packet's rendered
     issue.diff as the change, and file NO finding against a file read from
     that sha.
   - OTHERWISE reconstruct the target, without probing whether your checkout
     contains the change. TWO plain calls in this order:

       mkdir -p <TMP>/${row.step}.d/target
       git archive <sha> | tar -x -C <TMP>/${row.step}.d/target

     Read, build, and probe THERE, and attribute every result to that tree.
   - A sha that does not resolve is a gap file per obligation 3, never a
     review of whatever the checkout holds.
` : ''}${isolated && isWrite ? `
2b. COMMIT YOUR DELIVERABLE IN YOUR WORKTREE before obligation 3; the commit
   is the only hand-back channel. Two SEPARATE plain calls, exactly this
   shape:

   git add -A
   git commit -m "type(scope): summary"

   CONVENTIONAL COMMIT subject: type one of
   feat|fix|docs|refactor|test|perf|build|ci|chore, scope named for the area
   touched, imperative summary, 72 chars max, no trailing period; a body only
   as short "- " bullets when the subject cannot carry the why; never a step,
   issue, or run id (STEP-N, DKT-N, RUN-N) anywhere in it.

   Then \`git rev-parse HEAD\` and put that sha ON THE FIRST LINE of your
   change-summary artifact AND in your final report. Never pass
   \`--no-gpg-sign\`, never touch signing config. Do NOT push, and do not
   touch any other checkout.

   IF THE COMMIT IS REFUSED, leave the worktree exactly as it is and report
   COMMIT BLOCKED with the refusal's first line verbatim plus your worktree
   path (from \`git rev-parse --show-toplevel\`). Then continue to
   obligation 3.
` : ''}
3. Record it yourself with \`docket step record\`, feeding the token file to
   STDIN:

   \`docket step record ${row.step}${isWrite ? ' --worktree <YOUR CHECKOUT>' : ''} --artifact-file <TMP>/${row.step}.d/${row.step}-<kind>.md --metadata '{"model_resolved":"unknown","effort_resolved":"unknown"}' < <TMP>/${row.step}.d/${row.step}.token\`
${isWrite ? `
   - WORKTREE: \`--worktree\` is the literal path of the checkout the work
     happened in (\`git rev-parse --show-toplevel\`).` : ''}
   - ARTIFACT, MANDATORY on every record: a FRESH file whose name starts
     with your step id, created WITH BASH
     (\`cat > <TMP>/${row.step}.d/${row.step}-<kind>.md <<'EOF' ... EOF\`).
     <kind> is the artifact KIND your packet's OUTPUT section names; there
     is no \`--artifact-kind\`.
   - PAYLOAD, when your packet requires one: \`--payload-file <path>\`,
     built with \`jq -n\`.
   - METADATA: leave \`model_resolved\` and \`effort_resolved\` as
     \`unknown\` unless the runtime directly supplies an observation for
     this execution; requested routing, aliases, settings, and your own
     identity claim are not observations. With one, use its exact model ID
     and effort and name the source in the artifact; several observed
     models go in the artifact with \`model_resolved\` still unknown. Add no
     routing or cost field.
   - GAPS: an out-of-scope problem your work surfaced is neither a failure
     nor your declared artifact. Write each to its own file and pass
     \`--gap-file <path>\` (repeatable) on the record; each files a backlog
     issue. Your contract's Stuck clause is a SUCCESS recorded this way,
     never a \`fail\`. Gap file: line 1 is the issue TITLE naming the
     defect; line 2 is \`Home: <repo/checkout>\` or
     \`Home: THIS repository\`; line 3 is \`Files: <path>, <path>\`, every
     file the fix touches; then \`Scope: <glob>, <glob>\` only when a glob
     bounds the fix wider than those files.
   - FAILURE, only when a retry might redeem the attempt:

     \`docket step fail ${row.step} --note '<why>' < <TMP>/${row.step}.d/${row.step}.token\`

     \`fail\` takes ONLY --note and --metadata.
   - TOKEN: the stdin redirect is its only channel. Never \`cat\` the token
     file, echo it, paste it into a command line, or reproduce it in your
     reply.
   - AFTER \`record\` or \`fail\` exits 0, remove your step scratch dir in
     one plain call: \`rm -rf <TMP>/${row.step}.d\`. If it errored, or the
     token file is missing or empty, KEEP the dir and its token file INTACT,
     say so, and stop; never reconstruct or guess a token.

4. End your reply with exactly this line, filled in from the record
   response: <step-id> recorded (<status>) — for example "STEP-12 recorded
   (done)" or "STEP-12 recorded (waiting-human)". If instead you STOPPED
   without recording, the signal opens its own line, as the first words on
   it:

   CLAIM FAILED or CLAIM INCOMPLETE: as obligation 1 says.

   NETWORK GATE BLOCKED: a gate needs network access the sandbox denies (a
   DNS failure, a TLS handshake failure, or a blocked host). Attempt once;
   add the gate name, the exact host the error names, and the error
   verbatim. Leave your token intact.

   RECORD BLOCKED: the record is refused by the guard or the permission
   system. Attempt once; add your step id, the refusal's first line
   verbatim, and every path under <TMP>/${row.step}.d, the token's
   included. Leave that dir intact.

   WRITE BLOCKED: a write is refused. Add the refusal's first line and
   every path involved, stop that path, and record what you can.`
}
// TEST-END bootstrap

let input = args
if (typeof input === 'string') {
    try {
        input = JSON.parse(input)
        log('wave.js: decoded args from the harness JSON-encoded transport (normal)')
    } catch (e) {
        throw new Error(
            `wave.js: args arrived as a STRING that is not valid JSON (${e.message}). ` +
            `Refusing to route.`
        )
    }
}
if (!input || typeof input !== 'object') throw new Error(
    `wave.js: args is ${typeof input}, expected {rows}. Refusing to route.`
)

const rows = input.rows || []

// An agent's reply is PROSE. Read only the shapes the brief mandates, never
// a substring of the body: a judge reviewing park handling quotes the very
// phrases a body scan would match.
// TEST-BEGIN park-signals — extracted and exercised by
// tests/wave-park-signals.test.sh against verbatim captured replies. Prepend
// the configuration region; these predicates use no workflow globals (agent,
// log, args).
function lastLine(text) {
    const lines = String(text).trim().split('\n').filter((l) => l.trim())
    return lines.length ? lines[lines.length - 1].trim() : ''
}

// Obligation 1 caps a CONFLICT report at three lines (one line of slack
// here). A longer reply is a finding about conflicts, not a conflict.
function isConflictReport(text) {
    if (typeof text !== 'string' || !text.includes('CONFLICT')) return false
    return text.trim().split('\n').filter((l) => l.trim()).length
        <= CONFLICT_REPORT_MAX_LINES
}

// Obligation 0's denial reply: `BOOTSTRAP DENIED` on a line of its own, read
// as a whole line, never as a substring. A reply that ends in a record tail
// is a recorded step whatever its prose says.
function isBootstrapDenied(text) {
    if (typeof text !== 'string' || !text.includes('BOOTSTRAP DENIED')) return false
    if (/recorded \((?:done|waiting-human|paused)\)[\s*_`.]*$/.test(lastLine(text))) return false
    return text.split('\n').some((l) => /^[\s*_`>#]*BOOTSTRAP DENIED[\s*_`.:!]*$/.test(l))
}

// Two park signals with different scopes. A record tail of waiting-human or
// paused parks that ISSUE; every other lane keeps launching. A claim CONFLICT
// naming 'run is not active' parks the RUN. The tail is read at the END of
// the reply and nowhere else; trailing emphasis or punctuation is tolerated.
// Fail-open: no match keeps launching, and the engine refuses the claim
// anyway.
function laneParked(res) {
    if (res == null || res.status !== 'returned' ||
        typeof res.text !== 'string') return false
    return /recorded \((?:waiting-human|paused)\)[\s*_`.]*$/.test(lastLine(res.text))
}

function runParked(res) {
    if (res == null || res.status !== 'returned' ||
        typeof res.text !== 'string') return false
    return isConflictReport(res.text) && res.text.includes('run is not active')
}

// THE REPLY-TAIL CONTRACT. A returned executor reply ends in the record tail
// `STEP-N recorded (<status>)`, or carries one of the brief's stop signals on
// a line of its own, which means the step was NOT recorded. A reply with a
// record tail is recorded whatever its prose quotes; a reply with neither is
// `unrecorded`, and `step show` says what happened. COMMIT BLOCKED is not a
// stop signal: the writer reports it and goes on to record.
const STOP_SIGNALS = [
    'CLAIM FAILED', 'CLAIM INCOMPLETE', 'NETWORK GATE BLOCKED',
    'RECORD BLOCKED', 'WRITE BLOCKED',
]

function recordTail(text) {
    if (typeof text !== 'string') return null
    const m = lastLine(text).match(/recorded \((done|waiting-human|paused)\)[\s*_`.]*$/)
    return m ? m[1] : null
}

function stopSignal(text) {
    if (typeof text !== 'string' || recordTail(text)) return null
    const lines = text.split('\n')
    for (const sig of STOP_SIGNALS) {
        if (!text.includes(sig)) continue
        // The signal opens its line; what follows the colon is the report.
        const re = new RegExp('^[\\s*_`>#]*' + sig + '(?:[\\s*_`.:!—-].*)?$')
        if (lines.some((l) => re.test(l))) return sig
    }
    return null
}
// TEST-END park-signals

// ORPHANED CLAIM. The refusal `not ready to claim: the step is not pending`
// means ALREADY CLAIMED, not never started. On a harness resume an
// interrupted executor's brief re-executes with identical bytes; the claim is
// what refuses the duplicate, and only for work that claims. The remedy is
// report-only: the row settles `claim-conflict`, which kills the chain unless
// the step already reads done or skipped (chainDead reads `step_status`).
// TEST-BEGIN orphaned-claim — extracted and exercised by
// tests/wave-orphaned-claim.test.sh, which concatenates the park-signals
// region ahead of it (isConflictReport) and the chain-dead region after it.
// Keep everything between the markers free of workflow globals (agent, probe,
// log, args) so it stays evaluable on its own.
const CLAIM_CONFLICT_STATUS = 'claim-conflict'
const NOT_PENDING_CONFLICT = /not ready to claim:\s*the step is not pending/i

// Domain: a CONFLICT report within the line budget, never an arbitrary
// reply. 'run is not active' is left to runParked().
function isOrphanedClaimConflict(text) {
    if (!isConflictReport(text)) return false
    if (text.includes('run is not active')) return false
    return NOT_PENDING_CONFLICT.test(text)
}

// `docket step show STEP-N --json` fields, each independently OPTIONAL:
// `lease_expired` appears only in the expired-but-unreaped window, and
// `failed_attempts`/`reaped_claims` are omitted at 0. `step show` names no
// lease holder.
function parseStepShow(show) {
    // stepShow() already returns this shape (absence as ''); pass it through.
    if (show && typeof show === 'object') return show
    const s = typeof show === 'string' ? show : ''
    const grab = (key, val) => {
        const m = s.match(new RegExp(`"${key}"\\s*:\\s*${val}`))
        return m ? m[1] : ''
    }
    return {
        status: grab('status', '"([a-z-]+)"'),
        attempt: grab('attempt', '(\\d+)'),
        leaseExpired: grab('lease_expired', '(true|false)'),
        failed: grab('failed_attempts', '(\\d+)'),
        reaped: grab('reaped_claims', '(\\d+)'),
    }
}

// A step whose row is HELD by a claim — the orphan case.
const CLAIM_HELD = ['claimed', 'running']
// A step that already recorded. The refusal then means this spawn arrived
// after the fact, which is the opposite diagnosis and needs no reap.
const ALREADY_RECORDED = ['done', 'superseded', 'skipped', 'failed']

// Builds the step's real state as the outcome. Returns null when the probe
// carries no status; the caller then relays the CONFLICT verbatim.
function orphanedClaimReport(step, conflict, show) {
    const st = parseStepShow(show)
    if (!st.status) return null
    const at = st.attempt !== '' ? ` at attempt ${st.attempt}` : ''
    const facts = [
        `status=${st.status}`,
        st.attempt !== '' ? `attempt=${st.attempt}` : '',
        st.leaseExpired !== '' ? `lease_expired=${st.leaseExpired}` : '',
        st.failed !== '' ? `failed_attempts=${st.failed}` : '',
        st.reaped !== '' ? `reaped_claims=${st.reaped}` : '',
    ].filter(Boolean).join(', ')

    let headline, reading
    if (CLAIM_HELD.includes(st.status)) {
        headline = `claimed${at}, holder returned nothing: likely orphaned ` +
            `claim, reap needed`
        reading = `The step is CLAIMED, not unstarted. The agent this wave ` +
            `launched for ${step} was refused that claim and recorded ` +
            `nothing, so the lease is held by something other than the agent ` +
            `that just ran — the standing case is an executor interrupted ` +
            `mid-step whose claim outlived it (the harness relaunches the ` +
            `identical brief on resume; the claim is what stops the duplicate ` +
            `from doing the work twice). ESTABLISH the holder is gone, then ` +
            `return the step to the pool: \`docket step reap ${step} ` +
            `--reason '<what you observed>'\` under the run's conductor ` +
            `capability (the token file redirected into stdin; docket-run ` +
            `SKILL.md, "The conductor capability"). Do NOT read this ` +
            `outcome as "the step never started".`
    } else if (ALREADY_RECORDED.includes(st.status)) {
        headline = `already ${st.status}${at}: the spawn arrived after the ` +
            `fact, no reap needed`
        reading = `The step already RECORDED (${st.status}). The refusal ` +
            `means this spawn arrived after the work landed, not that the ` +
            `step never started; nothing holds a lease, so there is nothing ` +
            `to reap.`
    } else {
        headline = `refused as "not pending" while \`step show\` reads ` +
            `${st.status}${at}`
        reading = `The refusal and the step's own row disagree — the claim ` +
            `was refused as "not pending" while \`step show\` reads ` +
            `${st.status}. Reconcile before any retry (\`docket dispatch ` +
            `verify\`, \`docket step show ${step}\`); this is not evidence ` +
            `that the step never started.`
    }

    return {
        step,
        status: CLAIM_CONFLICT_STATUS,
        headline,
        step_status: st.status,
        text: [
            `${step} CLAIM CONFLICT — ${headline}.`,
            `docket step show ${step}: ${facts}`,
            reading,
            `Engine refusal, verbatim:`,
            conflict,
        ].join('\n'),
    }
}
// TEST-END orphaned-claim

// The safety classifier runs PRE-SPAWN and fails CLOSED. A retry is gated on
// the classifier's own transient admission alone and resubmits the SAME
// BYTES: same brief, same opts. Never reword a resubmission. A content-based
// block stays operator-escalated on the first failure.
//
// TEST-BEGIN classifier-retry — extracted and exercised by
// tests/wave-classifier-retry.test.sh against verbatim captured reason text.
// Keep everything between the markers free of workflow globals (agent, log,
// args) so it stays evaluable on its own.
//
// Both regexes must hit: CLASSIFIER_BLOCK is the harness's wrapper,
// TRANSIENT_CLASSIFIER the classifier's admission that its own stage 2
// broke. Domain is BLOCK-REASON AND ERROR STRINGS ONLY, never an agent reply.
const CLASSIFIER_BLOCK = /blocked by safety classifier/i
const TRANSIENT_CLASSIFIER = /Stage 2 classifier error|usually transient/i

function reasonText(e) {
    if (typeof e === 'string') return e
    if (e && typeof e === 'object') {
        if (typeof e.error === 'string') return e.error
        if (typeof e.message === 'string') return e.message
    }
    return ''
}

function transientClassifierBlock(e) {
    const s = reasonText(e)
    return CLASSIFIER_BLOCK.test(s) && TRANSIENT_CLASSIFIER.test(s)
}
// TEST-END classifier-retry

// A pre-spawn classifier block resolves agent() to a BARE null; the reason
// goes only to the harness's progress stream, persisted as JSON at
// ~/.claude/projects/<flattened-cwd>/<session-id>/[subagents/]workflows/<wfId>.json.
// A read-only probe recovers it from there. Whether every mid-run block is
// flushed by the time the probe looks is UNVERIFIED; if not, the probe finds
// nothing and the null branch escalates.
const PROBE_SCHEMA = {
    type: 'object',
    properties: {
        found: { type: 'boolean' },
        label: { type: 'string' },
        blocked: { type: 'boolean' },
        state: { type: 'string' },
        error: { type: 'string' },
        file: { type: 'string' },
    },
    required: ['found'],
    additionalProperties: false,
}

function blockProbeBrief(label) {
    return [
        'You are a DIAGNOSTIC PROBE inside a running Docket wave (wave.js). A',
        'step\'s agent launch resolved to null, and the harness recorded why in',
        'its own wave state file. Your ONLY job is to recover that record',
        'VERBATIM. Change nothing, rephrase nothing.',
        '',
        'WAVE PROBE: not a step execution; it READS the step the label names.',
        '',
        `TARGET LABEL (match byte-for-byte): ${label}`,
        '',
        'WHERE: the harness persists each workflow run as JSON at',
        '  ~/.claude/projects/*/workflows/wf_*.json',
        '  ~/.claude/projects/*/subagents/workflows/wf_*.json',
        '(one session-id directory between the project dir and',
        '`workflows`/`subagents`). Each file has a top-level `status` and a',
        '`workflowProgress` array whose entries carry `label`, `state`,',
        '`blocked`, and `error`.',
        '',
        'HOW: parse the JSON with jq, one command per call; never an inline',
        'interpreter handed code as an argument; never raw-grep, since other',
        'fields quote labels too:',
        `1. Consider only files modified within the last ${BLOCK_PROBE_LOOKBACK_HOURS} hours whose`,
        '   top-level status is NOT "completed", "failed", or "killed".',
        '2. Find workflowProgress entries whose `label` field equals the',
        '   target EXACTLY. Ignore your own entry (label ends "block-probe")',
        '   and NEVER read agent-*.jsonl transcripts.',
        '3. If exactly one entry matches, report its fields verbatim. If none',
        '   match, several remain, or anything is ambiguous, report',
        '   found: false, never a guess.',
        '',
        'Return via the structured output: found, label (verbatim), blocked,',
        'state, error (byte-for-byte), file (the path you read it from).',
    ].join('\n')
}

// TEST-BEGIN null-probe — extracted and exercised by
// tests/wave-classifier-retry.test.sh. Keep everything between the markers
// free of workflow globals (agent, log, args) so it stays evaluable alone.
//
// A recovered reason is usable only when the probe found a live-wave entry,
// the entry is a pre-spawn BLOCK (blocked === true), the label echoes this
// step's label byte-for-byte, and the reason is a non-empty string. Anything
// less returns null. This decides provenance, not transience: the reason
// still has to pass transientClassifierBlock() at the call site.
function probeRecovered(p, label) {
    if (!p || p.found !== true || p.blocked !== true) return null
    if (p.label !== label) return null
    return typeof p.error === 'string' && p.error !== '' ? p.error : null
}
// TEST-END null-probe

// TEST-BEGIN spawn-catch — extracted and exercised by
// tests/wave-isolation-unavailable.test.sh with a counting launch spy.
// Settles a rejected top-level launch. The isolation branch is fail-closed:
// an isolated writer whose worktree could not be made is never relaunched
// without isolation. Everything the handler touches is injected, except
// AgentCapError and transientClassifierBlock from the fenced regions above.
function spawnCatch({ row, isolated, log, launch, failed, retryTransient }) {
    return (err) => {
        if (err instanceof AgentCapError) {
            log(`${row.step}: ${err.message} — not a dead executor: nothing was ` +
                `launched; the engine re-offers the row at the next dispatch`)
            return { step: row.step, status: 'agent-cap', text: err.message }
        }
        if (transientClassifierBlock(err)) return retryTransient(err, isolated)
        if (isolated && /base branch|worktree/i.test(String(err))) {
            const text = `worktree isolation unavailable for ${row.step} (${err}); ` +
                `no writer launched without isolation. Reconcile claim state before ` +
                `redispatch`
            log(`${row.step}: ${text}`)
            return { step: row.step, status: 'isolation-unavailable', text }
        }
        log(`${row.step}: spawn error: ${err}`)
        return failed()
    }
}
// TEST-END spawn-catch

// Once a null-recovery probe itself returns nothing, a burst of nulls is a
// session or rate-limit event, not N dead spawns: no further per-row probes
// this wave. Module state, shared across rows. Date.now() is unavailable in
// a workflow script, so the trip is a probe returning nothing, not a time
// window.
let nullBurstTripped = false

function spawn(row, phaseLabel) {
    const r = resolve(row)
    const type = archetype(row, r.hint)
    // Only writers get a worktree, so parallel WRITERS cannot cross-contaminate
    // the shared tree. Read-class steps never mutate it and stay unisolated.
    const isWrite = type === 'executor-write'
    const isolated = isWrite
    log(`${row.step}: ${r.hint} -> ${type} @ ${r.model}/${r.effort} (variant ${r.variant})` +
        ` [${labelsOf(row).join(' ') || 'no labels'}]` +
        (isolated ? ' [worktree]' : ''))
    const stepLabel = `${row.step} · ${r.hint}`
    const opts = (iso) => ({
        label: stepLabel,
        phase: phaseLabel,
        agentType: type,
        model: r.model,
        effort: r.effort,
        ...(iso ? { isolation: 'worktree' } : {}),
    })
    const failed = () => ({ step: row.step, status: 'spawn-failed', text: null })
    const escalate = () => {
        log(`${row.step}: SPAWN PRODUCED NOTHING (launch blocked before the ` +
            `agent existed — this wave's task .output workflowProgress[].error ` +
            `carries the stated reason when there is one — or model ${r.model} ` +
            `unavailable, the agent was skipped, or it died mid-flight) — whether a claim ` +
            `was recorded is UNKNOWN; reconcile via \`docket dispatch verify\` ` +
            `and \`docket step show ${row.step}\`, then, if it is still claimed ` +
            `by this dead spawn, return it to the pool with \`docket step reap ` +
            `${row.step} --reason '<what you observed>'\` under the run's ` +
            `conductor capability before ` +
            `any retry. If that error carries the TRANSIENT classifier ` +
            `signature (\`Stage 2 classifier error\` / \`usually transient\`), ` +
            `redispatch the step UNCHANGED — same brief, never reworded`)
        return failed()
    }
    const handle = (text, retried) => {
        if (text != null) {
            const returned = { step: row.step, status: 'returned', text }
            // A denied bootstrap never claimed: nothing to reap, nothing
            // recorded. Its own status stops the lane.
            if (isBootstrapDenied(text)) {
                log(`${row.step}: BOOTSTRAP DENIED, the guard or permission layer ` +
                    `refused the executor's own bootstrap before any claim; nothing ` +
                    `to reap; this issue's later stages are skipped this wave and ` +
                    `the engine re-offers the row once the gap is fixed`)
                return { step: row.step, status: 'bootstrap-denied', text }
            }
            // The reply-tail contract (recordTail / stopSignal). A CONFLICT
            // report keeps its own path below; everything else settles here.
            if (!recordTail(text) && !isConflictReport(text)) {
                const signal = stopSignal(text)
                if (signal) {
                    log(`${row.step}: the executor stopped on ${signal} — nothing ` +
                        `recorded; this issue's later stages are deferred this wave ` +
                        `and the conductor resolves the block from the reply`)
                    return { step: row.step, status: 'blocked', signal, text }
                }
                log(`${row.step}: the reply ends in neither a record tail nor a stop ` +
                    `signal — settling it unrecorded; this issue's later stages are ` +
                    `deferred this wave; \`docket step show ${row.step}\` says what ` +
                    `actually happened`)
                return { step: row.step, status: 'unrecorded', text }
            }
            // "the step is not pending" means already claimed: ask the engine
            // what the step's row says and report that, refusal kept verbatim
            // underneath.
            if (!isOrphanedClaimConflict(text)) return returned
            log(`${row.step}: claim refused "the step is not pending" — probing ` +
                `the step's real state rather than relaying the refusal as the ` +
                `outcome`)
            return stepShow(row.step, `${row.step} · claim-conflict`, phaseLabel)
                .then((show) => {
                    const diagnosed = orphanedClaimReport(row.step, text, show)
                    if (!diagnosed) {
                        log(`${row.step}: the claim-conflict probe read no status ` +
                            `— relaying the refusal verbatim, exactly as before`)
                        return returned
                    }
                    log(`${row.step}: ${diagnosed.headline}`)
                    return diagnosed
                }, () => returned)
        }
        // A bare null is NEVER retried blind: agent() resolves to null for a
        // pre-spawn classifier block, an operator SKIP, an unavailable model,
        // and a mid-flight death alike. A null does not mean nothing happened
        // either: the record can land before the final turn dies. So ask the
        // engine first; a step that reads `done` is a live lane.
        if (nullBurstTripped) {
            log(`${row.step}: agent() returned null and this wave already ` +
                `tripped the null-burst breaker (a recovery probe came back ` +
                `empty earlier) — settling directly as a session/rate-limit ` +
                `event rather than spawning another probe`)
            return escalate()
        }
        return stepShow(row.step, `${row.step} · null-recovery`, phaseLabel)
            .then((show) => {
                if (show === null) {
                    // The recovery probe itself returned nothing: one is enough
                    // evidence of a storm.
                    nullBurstTripped = true
                    log(`${row.step}: the null-recovery probe itself returned ` +
                        `nothing — treating this as a session/rate-limit event; ` +
                        `no further per-row recovery probes this wave`)
                    return escalate()
                }
                if (show.error) {
                    // The engine's own read errored — a real answer, not a
                    // dead probe, so this is NOT storm evidence. The status
                    // is unknown either way; fall through to notRecorded().
                    log(`${row.step}: the null-recovery probe's \`docket step ` +
                        `show\` errored (${show.error}) — status unknown, not ` +
                        `treating this as a storm signature`)
                }
                const st = parseStepShow(show)
                if (st.status === 'done') {
                    log(`${row.step}: agent() returned null, but \`docket step ` +
                        `show\` reads done (attempt=${st.attempt || '?'}) — the ` +
                        `record landed; treating this as returned rather than ` +
                        `settling a dead spawn`)
                    return {
                        step: row.step,
                        status: 'returned',
                        text: `${row.step}: agent() returned null after the ` +
                            `record completed (docket step show: status=done, ` +
                            `attempt=${st.attempt || '?'}). Treated as ` +
                            `returned — the lane continues.`,
                    }
                }
                return notRecorded()
            }, () => {
                nullBurstTripped = true
                return escalate()
            })

        // The record did not land. Identical-bytes resubmission fires only on
        // a probe-recovered, label-matched, blocked === true entry whose
        // reason carries the transient signature; every other outcome
        // escalates. The probe deliberately inherits the session model: a
        // wrong extraction could relaunch an agent the operator skipped.
        function notRecorded() {
            if (retried) return escalate()
            return countedAgent(blockProbeBrief(stepLabel), {
                label: `${row.step} · block-probe`,
                phase: phaseLabel,
                agentType: 'executor-read',
                ...AGENT_CONFIG.blockProbe,
                schema: PROBE_SCHEMA,
            }).then((p) => probeRecovered(p, stepLabel), () => {
                nullBurstTripped = true
                return null
            })
                .then((reason) => {
                    if (reason && transientClassifierBlock(reason)) {
                        log(`${row.step}: probe recovered the harness's block record and ` +
                            `it admits its own transience (${reason}) — resubmitting the ` +
                            `IDENTICAL brief once (never reworded); a second null is ` +
                            `spawn-failed`)
                        return launch(isolated, true).catch((err2) => {
                            log(`${row.step}: spawn error on transient-classifier retry: ${err2}`)
                            return failed()
                        })
                    }
                    if (reason) {
                        log(`${row.step}: probe recovered a NON-transient classifier block ` +
                            `(${reason}) — a content refusal stays operator-escalated, and ` +
                            `identical bytes would be refused deterministically anyway`)
                    } else {
                        log(`${row.step}: probe could not attribute the null to a ` +
                            `classifier block — leaving it operator-escalated`)
                    }
                    return escalate()
                })
        }
    }
    const launch = (iso, retried) =>
        countedAgent(bootstrap(row, r, iso, isWrite), opts(iso)).then((text) => handle(text, retried))
    // EXACTLY ONCE, and only from the top-level catch: same brief bytes, same
    // opts, same isolation. `retried` rides through so a retry that resolves
    // null does not probe-and-retry again. A second failure returns
    // 'spawn-failed' exactly as an unretried one does.
    const retryTransient = (err, iso) => {
        log(`${row.step}: safety-classifier block admits its own transience ` +
            `(${err}) — resubmitting the IDENTICAL brief once (never reworded); ` +
            `a second failure is spawn-failed`)
        return launch(iso, true).catch((err2) => {
            log(`${row.step}: spawn error on transient-classifier retry: ${err2}`)
            return failed()
        })
    }
    return launch(isolated)
        .catch(spawnCatch({ row, isolated, log, launch, failed, retryTransient }))
}

// Vote rows: the in-wave panel. The wave seats the panel by calling
// tribunal.js one level deep, passing `step` so it renders the mid-wave
// brief. The engine is the only authority: each seat casts a REAL
// `docket vote cast`, the engine tallies, and the quorum-reaching cast routes
// the gate. This script never casts, approves, or tallies. Seat routing is
// the engine's: each `voter_assignments` entry carries {model, effort,
// variant}, and the wave re-derives nothing.

// A seat or row missing any of the triple was never routed. Used for
// executor rows (resolve(), above) and for a vote row's voter_assignments
// before they cross into tribunal.js's args.
function assertRouted(who, entry, refusal) {
    for (const k of ['model', 'effort', 'variant']) {
        if (!entry || typeof entry[k] !== 'string' || entry[k] === '') {
            throw new Error(
                `wave.js: ${who} carries no ${k} (got ${JSON.stringify(entry && entry[k])}) — ` +
                `the engine renders model/effort/variant from the run's pinned ` +
                `policy.toml, so this was never routed or was re-typed without ` +
                `its fields. ${refusal}`
            )
        }
    }
}

function voterToSeat(voter, routing) {
    if (typeof voter !== 'string' || voter === '') {
        throw new Error(
            `wave.js: a voter_assignments entry carries no voter name (got ${JSON.stringify(voter)}). ` +
            `Refusing to seat the panel.`
        )
    }
    assertRouted(`seat ${JSON.stringify(voter)}`, routing, 'Refusing to seat the panel.')
    return { seat: voter, variant: routing.variant, model: routing.model, effort: routing.effort }
}

// TEST-BEGIN gate-vote — extracted and exercised by
// tests/wave-vote-retry-report.test.sh, which concatenates this region after
// the classifier-retry region (whose CLASSIFIER_BLOCK / TRANSIENT_CLASSIFIER /
// reasonText the probe retry below reads) and feeds it stub `agent`,
// `parallel`, `log`, `workflow`, and `voterToSeat` globals — the panel seat is
// tribunal.js's, reached through the stubbed `workflow`, not rendered here.
// Prepend the configuration region. Other dependencies stay inside the markers;
// tests/wave-target-envelope.test.sh extracts it to assert the gate path
// spends no target probe, and tests/tribunal-seat-brief.test.sh pins the
// brief tribunal.js renders for the mid-wave call this region makes.
function probeBrief(command, servingStep) {
    return `Run exactly this one command:

  ${command}

Return its output VERBATIM as your entire final reply: no summary, no
commentary, no code fence. If the command errors, return the error text
verbatim instead.

Run nothing else: no vote, no investigation. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution${servingStep ? `; it READS ${servingStep}` : ''}.`
}

// A probe is one read-only, idempotent command, so a dead one is resubmitted
// once with the IDENTICAL brief, except on a non-transient classifier block,
// which is deterministic on identical bytes. The absorbed error and the
// retry land in `acct`, so a succeeding gate reports them as notes. Call
// sites that pass no acct keep the single-shot fail-open behavior.
function retrying(label, acct, once, empty) {
    return once().catch((err) => {
        if (!acct) {
            log(`${label}: probe spawn error: ${err}`)
            return empty
        }
        const reason = reasonText(err) || String(err)
        acct.absorbed.push(`[${label}] ${reason}`)
        if (CLASSIFIER_BLOCK.test(reason) && !TRANSIENT_CLASSIFIER.test(reason)) {
            log(`${label}: probe blocked on content (${reason}) — deterministic ` +
                `on identical bytes, not retried`)
            return empty
        }
        log(`${label}: probe spawn error (${reason}) — retrying the identical ` +
            `read-only probe once`)
        acct.retries++
        return once().catch((err2) => {
            const reason2 = reasonText(err2) || String(err2)
            acct.absorbed.push(`[${label} (retry)] ${reason2}`)
            log(`${label}: probe spawn error on retry: ${reason2}`)
            return empty
        })
    })
}

function probe(command, label, phaseLabel, servingStep, acct) {
    const once = () => {
        // A probe is wave overhead, NEVER a seat: it lands in its own bucket
        // so the gate summary can say "3 seats, 3 probes".
        if (acct) acct.probes++
        return countedAgent(probeBrief(command, servingStep), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            ...AGENT_CONFIG.probe,
        }).then((text) => text == null ? '' : text)
    }
    return retrying(label, acct, once, '')
}

// `docket step show` answers through a schema, never regexed out of relayed
// text.
const STEP_SHOW_SCHEMA = {
    type: 'object',
    properties: {
        status: { type: 'string' },
        attempt: { type: 'integer' },
        lease_expired: { type: 'boolean' },
        failed_attempts: { type: 'integer' },
        reaped_claims: { type: 'integer' },
        blocked_reason: { type: 'string' },
        error: { type: 'string' },
    },
}

// The closing paragraphs every schema probe brief shares. wave-usage.js
// classifies a probe by the WAVE PROBE line.
function probeTrailer(step) {
    return `Run nothing else: no vote, no investigation. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution; it READS ${step}.`
}

function stepShowBrief(step) {
    return `Run exactly this one command:

  docket step show ${step} --json

Return the command's \`data\` object through the structured output: status,
attempt, lease_expired, failed_attempts, reaped_claims, blocked_reason, each
copied exactly as printed. Omit a field the output did not carry; fill none
in. If the command errors or prints no \`data\` object, return {error: <the
error text verbatim>} and nothing else.

${probeTrailer(step)}`
}

// Normalizes the envelope to parseStepShow's string-typed shape (absence is
// ''). Returns null when the agent returned nothing, {error} when the
// engine's read errored. A malformed reply is treated as empty, never
// salvaged.
function stepShow(step, label, phaseLabel) {
    const once = () => countedAgent(stepShowBrief(step), {
        label,
        phase: phaseLabel,
        agentType: 'executor-read',
        ...AGENT_CONFIG.probe,
        schema: STEP_SHOW_SCHEMA,
    }).then((g) => {
        if (g == null) return null
        if (typeof g.error === 'string') return { error: g.error }
        return {
            status: typeof g.status === 'string' ? g.status : '',
            attempt: typeof g.attempt === 'number' ? String(g.attempt) : '',
            leaseExpired: typeof g.lease_expired === 'boolean' ? String(g.lease_expired) : '',
            blockedReason: typeof g.blocked_reason === 'string' ? g.blocked_reason : '',
            failed: typeof g.failed_attempts === 'number' ? String(g.failed_attempts) : '',
            reaped: typeof g.reaped_claims === 'number' ? String(g.reaped_claims) : '',
        }
    })
    return retrying(label, undefined, once, null)
}

// `docket gate status STEP-N --json` answers a gate's whole decision state in
// one envelope: {step_status, proposal?, outcome, tally?, seats?,
// missing_seats, target?}. THE PROBE ANSWERS THROUGH A SCHEMA, NEVER AS
// TEXT: a reply is the envelope or it is nothing.
const GATE_STATUS_SCHEMA = {
    type: 'object',
    properties: {
        step_status: { type: 'string' },
        proposal: { type: 'string' },
        outcome: { type: 'string', enum: ['approved', 'rejected', 'open'] },
        tally: { type: 'object' },
        seats: {
            type: 'array',
            items: {
                type: 'object',
                properties: {
                    voter: { type: 'string' },
                    cast: { type: 'boolean' },
                    verdict: { type: 'string' },
                },
                required: ['voter', 'cast'],
            },
        },
        missing_seats: { type: 'array', items: { type: 'string' } },
        target: {
            type: 'object',
            properties: { sha: { type: 'string' }, worktree: { type: 'string' } },
        },
        target_worktree_exists: { type: 'boolean' },
        error: { type: 'string' },
    },
}

function gateStatusBrief(step) {
    return `Run this command first:

  docket gate status ${step} --json

Return the command's \`data\` object through the structured output, copied
field for field and value for value. Add no field the output did not carry;
fill none in. If the command errors or prints no \`data\` object, return
{error: <the error text verbatim>} and nothing else.

THEN, only when that \`data\` carries a non-empty \`target.worktree\`, run one
more command against that literal path:

  test -d <that path> && echo yes || echo no

and report \`target_worktree_exists\`: true for yes, false for no. Omit the
field when there was no worktree to test.

${probeTrailer(step)}`
}

// The envelope, or null when the probe died, the command errored, or the
// reply is not one. Null means UNKNOWN to every caller, never "every seat
// missing".
function gateStatus(step, label, phaseLabel, acct) {
    const once = () => {
        acct.probes++
        return countedAgent(gateStatusBrief(step), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            ...AGENT_CONFIG.gateStatus,
            schema: GATE_STATUS_SCHEMA,
        }).then((g) => {
            if (g && typeof g.step_status === 'string' && typeof g.outcome === 'string') return g
            if (g && typeof g.error === 'string') log(`${label}: engine error — ${g.error}`)
            return null
        })
    }
    return retrying(label, acct, once, null)
}

// A gate the engine has settled one way or the other. `outcome` is the
// proposal's tally; a step already done/skipped/superseded with the outcome
// still "open" is a gate decided some other way (a closed ballot, an
// operator verb) — continue, as before.
const GATE_SETTLED = ['done', 'skipped', 'superseded']
const gateDecided = (g) => g.outcome !== 'open' || GATE_SETTLED.includes(g.step_status)

// The round's target ref off the envelope, for the seat brief. A sha reaches
// a brief only when it is 40 lowercase hex; seatBrief re-checks the shape.
const TARGET_SHA_RE = /^[0-9a-f]{40}$/

function gateTarget(g) {
    const t = g.target
    if (!t || typeof t !== 'object') return null
    const sha = (typeof t.sha === 'string' && TARGET_SHA_RE.test(t.sha)) ? t.sha : ''
    // The conductor sweeps a write-class worktree once its round integrates.
    // Only a probe that answered "gone" drops the path: an absent field is
    // UNKNOWN, and the brief keeps what the engine recorded.
    const swept = g.target_worktree_exists === false
    const worktree = (!swept && typeof t.worktree === 'string') ? t.worktree : ''
    if (!sha && !worktree) return null
    return { sha, worktree }
}

// Some gate steps decide ONE held finding cluster out of several, and only
// `step show` names which. The engine mints those rows as `<name>-held@N#k`,
// so ordinary gates never pay for the read. Anything short of all four
// fields yields null and the brief renders unchanged.
const HELD_INSTANCE_RE = /-held@\d+#\d+$/
const HELD_CLUSTER_SCHEMA = {
    type: 'object',
    properties: {
        cluster_index: { type: 'number' },
        cluster_count: { type: 'number' },
        artifact: { type: 'string' },
        producer_step: { type: 'string' },
        error: { type: 'string' },
    },
}

function heldClusterBrief(step) {
    return `Run exactly this one command:

  docket step show ${step} --json | jq -c '.data.held_cluster // {}'

Return the printed object through the structured output, copied field for
field. Add no field the output did not carry; fill none in. If the command
errors, return {error: <the error text verbatim>} and nothing else.

${probeTrailer(step)}`
}

function parseHeldCluster(hc) {
    if (!hc || typeof hc.cluster_index !== 'number' || typeof hc.cluster_count !== 'number' ||
        typeof hc.artifact !== 'string' || typeof hc.producer_step !== 'string') return null
    return {
        clusterIndex: hc.cluster_index,
        clusterCount: hc.cluster_count,
        artifact: hc.artifact,
        producerStep: hc.producer_step,
    }
}

function heldCluster(step, label, phaseLabel, acct) {
    const once = () => {
        acct.probes++
        return countedAgent(heldClusterBrief(step), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            ...AGENT_CONFIG.heldCluster,
            schema: HELD_CLUSTER_SCHEMA,
        }).then(parseHeldCluster)
    }
    return retrying(label, acct, once, null)
}

// The CASE a seat decides is read ONCE per gate and rendered verbatim into
// every seat brief, so no seat reads the vote record itself: `docket vote
// show` prints every recorded cast beside the body. The projection carries
// the question and nothing decided. Null lists are normalized by jq so the
// schema always sees arrays.
const PROPOSAL_SCHEMA = {
    type: 'object',
    properties: {
        description: { type: 'string' },
        rationale: { type: 'string' },
        files_changed: { type: 'array', items: { type: 'string' } },
        linked_issues: { type: 'array', items: { type: 'string' } },
        error: { type: 'string' },
    },
}

const PROPOSAL_JQ =
    `jq -c '.data | {description, rationale, ` +
    `files_changed: (.files_changed // []), linked_issues: (.linked_issues // [])}'`

function proposalBrief(voteId, step) {
    return `Run exactly this one command:

  docket vote show ${voteId} --json | ${PROPOSAL_JQ}

Return the printed object through the structured output, copied field for
field and value for value. Add no field the output did not carry; fill none
in. If the command errors, return {error: <the error text verbatim>} and
nothing else.

${probeTrailer(step)}`
}

// The body as brief text: its own words, nothing tallied. '' when the read
// died or answered without a description, so the brief can say so.
function proposalContext(p) {
    if (!p || typeof p.description !== 'string') return ''
    const list = (xs) => Array.isArray(xs) && xs.length > 0 ? xs.join(', ') : '(none recorded)'
    const rationale = typeof p.rationale === 'string' && p.rationale !== '' ? p.rationale : '(none recorded)'
    return [
        `DESCRIPTION: ${p.description}`,
        `RATIONALE: ${rationale}`,
        `FILES CHANGED: ${list(p.files_changed)}`,
        `LINKED ISSUES: ${list(p.linked_issues)}`,
    ].join('\n')
}

function proposalBody(voteId, step, label, phaseLabel, acct) {
    const once = () => {
        acct.probes++
        return countedAgent(proposalBrief(voteId, step), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            ...AGENT_CONFIG.proposal,
            schema: PROPOSAL_SCHEMA,
        }).then((p) => {
            if (p && typeof p.error === 'string') log(`${label}: engine error — ${p.error}`)
            return proposalContext(p)
        })
    }
    return retrying(label, acct, once, '')
}

// Successful tallies report recovered agent errors as notes. Failed gates
// keep their errors and never pass through here. Count seats separately from
// probes and retries; omit the seats clause when no panel was seated.
function gateSuccess(step, text, acct) {
    const n = (count, one, many) => `${count} ${count === 1 ? one : many}`
    const parts = [
        acct.seats > 0 ? n(acct.seats, 'seat', 'seats') : '',
        n(acct.probes, 'probe', 'probes'),
        n(acct.retries, 'retry', 'retries'),
    ].filter(Boolean)
    const notes = acct.absorbed.map((error) =>
        `absorbed agent-level error (superseded in-wave; the tally ` +
        `SUCCEEDED — NOT a failure of this step): ${error}`)
    return {
        step,
        status: 'gate-passed',
        text,
        spawn_accounting: parts.join(', '),
        ...(notes.length > 0 ? { notes } : {}),
    }
}

async function runGate(row, phaseLabel) {
    // Accounting for THIS gate, in SEPARATE buckets: `seats` is the judge
    // panel, `probes` every read-only spawn the gate path spends. Seat
    // re-spawns and probe resubmissions are retries; agent-level errors land
    // in `absorbed` and ride the SUCCESS result as notes.
    const acct = { seats: 0, probes: 0, retries: 0, absorbed: [] }
    const status = (label) => gateStatus(row.step, `${row.step} · ${label}`, phaseLabel, acct)
    const asText = (g) => JSON.stringify(g)
    const accountingLine = (res) => res.spawn_accounting + (res.notes ?
        ` — ${res.notes.length} agent-level error(s) absorbed (NOT failures for this step)` : '')

    // One read finds the proposal and says whether the gate was decided
    // before the wave reached it.
    const gate = await status('gate:status')
    if (!gate) {
        log(`${row.step}: gate:status probe returned nothing — the gate's state ` +
            `is UNKNOWN; skipping this issue's later stages this wave, and the ` +
            `conductor reads \`docket gate status ${row.step}\` itself`)
        return { step: row.step, status: 'gate-blocked', text: '' }
    }
    // A vote step's STATUS cannot carry the verdict: the engine records a
    // REJECTED vote as `done` when its on_fail routes machine-side. The
    // envelope's `outcome` IS the tally.
    if (gateDecided(gate)) {
        if (gate.outcome === 'rejected') {
            log(`${row.step}: gate already decided REJECTED (${gate.proposal}) — ` +
                `engine routes on_fail; skipping this issue's later stages`)
            return { step: row.step, status: 'gate-rejected', text: asText(gate) }
        }
        if (gate.step_status === 'skipped' || gate.step_status === 'superseded') {
            // No proposal was tallied: the engine bypassed voting, so
            // `gate-passed` would read as an approval that never happened.
            log(`${row.step}: gate step ${gate.step_status} by the engine, no ` +
                `tally — reporting gate-skipped`)
            return { step: row.step, status: 'gate-skipped', text: asText(gate) }
        }
        log(`${row.step}: gate already decided — continuing`)
        const early = gateSuccess(row.step, asText(gate), acct)
        // No panel was seated, so the accounting carries no seats clause.
        log(`${row.step}: no panel seated — ${accountingLine(early)}`)
        return early
    }
    // A gate with NO proposal is blocked: its predecessors have not all
    // recorded. That is not necessarily a failure upstream. Only `step show`
    // carries the engine's `blocked_reason`, which the ladder reads off this
    // result to pick "deferred" over "died".
    if (!gate.proposal) {
        const show = await probe(`docket step show ${row.step} --json`,
            `${row.step} · gate:blocked`, phaseLabel, undefined, acct)
        log(`${row.step}: gate has no proposal — its predecessors have not all ` +
            `recorded, so the panel cannot seat; skipping this issue's later ` +
            `stages this wave`)
        return { step: row.step, status: 'gate-blocked', text: show }
    }
    const voteId = gate.proposal
    const roster = Array.isArray(row.voter_assignments) ? row.voter_assignments : []
    if (roster.length === 0) {
        log(`${row.step}: vote row carries no voter_assignments — the engine ` +
            `renders the routed roster on vote rows, so this manifest predates ` +
            `the contract or the run pins no policy.toml; escalate instead of ` +
            `guessing a panel`)
        return { step: row.step, status: 'gate-blocked', text: asText(gate) }
    }
    const seats = roster.map((a) => voterToSeat(a && a.voter, a))
    // Neither read depends on the other, so they fan out together. Both share
    // `acct`; a workflow script has no preemption between awaited steps.
    const [held, context] = await parallel([
        () => HELD_INSTANCE_RE.test(row.instance || '')
            ? heldCluster(row.step, `${row.step} · gate:held-cluster`, phaseLabel, acct)
            : Promise.resolve(null),
        () => proposalBody(voteId, row.step, `${row.step} · gate:proposal`, phaseLabel, acct),
    ])
    // Name the round's target ref in every seat's brief: seats are NOT seated
    // on the checkout the round was written in.
    const target = gateTarget(gate)
    log(`${row.step}: ${voteId} — seating ${seats.map((s) => s.seat).join(', ')}` +
        (target ? ` on target ${target.sha || '(no sha)'}${target.worktree ? ` (${target.worktree})` : ''}`
                : ` with NO target ref on the gate — seats read their own HEAD`))
    // A dead proposal read seats the panel anyway: the gate's context bundle
    // carries the evidence, and the brief says so.
    if (!context) {
        log(`${row.step}: the proposal body read returned nothing — seats are ` +
            `briefed without it and decide from the gate's context bundle`)
    }
    acct.seats = seats.length
    // The panel is seated by ONE workflow-nesting level into tribunal.js. A
    // throw there must not crash the wave; it is absorbed into `acct`.
    const seatPanel = (panelSeats, isRespawn) => {
        const seatLabel = (seat) => `${row.step} · seat:${seat}` + (isRespawn ? ' (retry)' : '')
        return workflow({ scriptPath: args.tribunal }, {
            voteId, gateKind: row.instance, cwd: args.cwd, context,
            voters: panelSeats.map((s) => ({ seat: s.seat, model: s.model, effort: s.effort, variant: s.variant })),
            step: { step: row.step, instance: row.instance, issue: row.issue, run: row.run },
            target, heldCluster: held, isRespawn: Boolean(isRespawn),
        }).then((res) => {
            // A nested workflow() child shares this invocation's agent counter,
            // but countedAgent() never sees the child's calls. tribunal.js
            // reports `seatsSpawned`; fold it into agentsLaunched.
            agentsLaunched += (res && Number.isInteger(res.seatsSpawned)) ? res.seatsSpawned : panelSeats.length
            for (const a of (res && res.absorbed) || []) {
                log(`${row.step} seat ${a.seat}: ${isRespawn ? 'respawn' : 'spawn'} error: ${a.error}`)
                acct.absorbed.push(`[${seatLabel(a.seat)}] ${a.error}`)
            }
            return res
        }).catch((err) => {
            // A throw means tribunal.js never ran: no agents were spawned, so
            // agentsLaunched is left alone.
            log(`${row.step}: tribunal panel spawn error: ${err}`)
            const reason = reasonText(err) || String(err)
            for (const s of panelSeats) acct.absorbed.push(`[${seatLabel(s.seat)}] ${reason}`)
            return null
        })
    }
    await seatPanel(seats, false)

    // One re-spawn for seats whose cast never landed — tribunal.js's rule.
    // The same read answers the roster and the tally; the engine names the
    // missing seats itself, so no name is matched out of prose here.
    let after = await status('gate:outcome')
    const missingIn = (g) => seats.filter((s) => (g.missing_seats || []).includes(s.seat))
    const missing = after ? missingIn(after) : []
    if (missing.length > 0) {
        log(`${row.step}: ${missing.length} seat(s) returned without a recorded ` +
            `cast (${missing.map((s) => s.seat).join(', ')}) — re-spawning each ONCE`)
        // A re-seated judge is a RETRY of a seat already counted in
        // acct.seats — never an extra seat, never a probe.
        acct.retries += missing.length
        await seatPanel(missing, true)
        // The record moved underneath the first read — those re-seated casts
        // postdate it — so the tally re-reads rather than reusing it.
        after = await status('gate:outcome')
        // A seat still silent after its one retry is named, never absorbed
        // into a quorum pass or the generic did-not-clear line.
        const still = after ? missingIn(after) : []
        if (still.length > 0) {
            log(`${row.step}: STILL NO CAST from ${still.map((s) => s.seat).join(', ')} ` +
                `after the one permitted re-spawn — the panel is short ${still.length} ` +
                `vote(s); the tally decides on the engine's record as it stands`)
        }
    }
    if (!after) {
        log(`${row.step}: gate:outcome probe returned nothing — the tally is ` +
            `UNKNOWN; skipping this issue's later stages; the conductor escalates`)
        return { step: row.step, status: 'gate-parked', text: '' }
    }
    if (after.outcome === 'rejected') {
        log(`${row.step}: gate decided REJECTED (${voteId}) — engine ` +
            `routes on_fail; the conductor verifies the routing; ` +
            `skipping this issue's later stages`)
        return { step: row.step, status: 'gate-rejected', text: asText(after) }
    }
    // `done` says only that the step COMPLETED — a rejection whose on_fail
    // routes into rework also reads done/superseded — and the rejected case
    // was read off the tally above, so what remains is a pass.
    if (gateDecided(after)) {
        log(`${row.step}: gate passed — continuing`)
        const res = gateSuccess(row.step, asText(after), acct)
        log(`${row.step}: ${accountingLine(res)}`)
        return res
    }
    log(`${row.step}: gate did NOT clear (${after.step_status}, tally ${after.outcome}) ` +
        (missing.length > 0 ? `after re-seating ${missing.map((s) => s.seat).join(', ')} ` : '') +
        `— skipping this issue's later stages; the conductor escalates`)
    return { step: row.step, status: 'gate-parked', text: asText(after) }
}
// TEST-END gate-vote

// The round's target ref for the fix-round ancestry guard below. Context
// assembly lifts the resolved `issue.diff` round record onto the bundle as
// `target_sha` and `target_worktree`; both are omitted when the diff carries
// no round record, so ABSENCE IS NORMAL and yields null. The probe reduces
// the bundle with jq rather than dumping it.
//
// NEVER HAND A PROBE AN EMPTY RESULT TO RELAY. The command prints an
// envelope either way, `{"target_sha":null,"target_worktree":null}` when the
// bundle carries no round record, and the reply is parsed STRUCTURALLY,
// never by regex over free text. Anything that is not the envelope is "no
// target".
//
// TEST-BEGIN target-envelope — extracted and exercised by
// tests/wave-target-envelope.test.sh, and prepended by
// tests/wave-fix-round-ancestry.test.sh and the ladder suites, whose guard
// reads through it. Keep it free of workflow globals — `log` included.
const TARGET_ENVELOPE_JQ =
    `jq -c '{target_sha: (first(.. | objects | select(has("target_sha")) | ` +
    `.target_sha) // null), target_worktree: (first(.. | objects | ` +
    `select(has("target_worktree")) | .target_worktree) // null)}'`

function targetRefCommand(step) {
    return `docket step context ${step} --json | ${TARGET_ENVELOPE_JQ}`
}

// Returns {parsed, target}: `parsed` says the reply WAS the envelope,
// `target` is null unless it named a non-empty string field. A probe's text
// can carry a harness banner ahead of the JSON, so slice between the
// outermost braces before parsing.
function readTargetEnvelope(text) {
    const s = (text || '').trim()
    const i = s.indexOf('{')
    const j = s.lastIndexOf('}')
    if (i < 0 || j <= i) return { parsed: false, target: null }
    let env
    try {
        env = JSON.parse(s.slice(i, j + 1))
    } catch {
        return { parsed: false, target: null }
    }
    if (!env || typeof env !== 'object' || Array.isArray(env)) {
        return { parsed: false, target: null }
    }
    // The envelope is defined by carrying BOTH keys — a stray object that
    // happens to mention one of them is prose, not this probe's answer.
    if (!('target_sha' in env) || !('target_worktree' in env)) {
        return { parsed: false, target: null }
    }
    const sha = typeof env.target_sha === 'string' ? env.target_sha : ''
    const worktree = typeof env.target_worktree === 'string' ? env.target_worktree : ''
    if (!sha && !worktree) return { parsed: true, target: null }
    return { parsed: true, target: { sha, worktree } }
}

function parseTargetRef(text) {
    return readTargetEnvelope(text).target
}
// TEST-END target-envelope

// FIX-ROUND BASE ANCESTRY. The conductor integrates a fix round by
// cherry-picking onto the shared branch, and the next round's tree must
// DESCEND from that integrated commit. The wave asserts the ancestry BEFORE
// the fanout spawns and parks a broken round as a RELAY finding
// ('parked-base-ancestry', chain-dead for the issue).
//
// THE SHA IS THE INTEGRATED ONE, AND ONLY THE CONDUCTOR HOLDS IT: the
// writer's sha is never an ancestor of the shared branch. `args.integrated`
// maps each issue to the PRIOR round's integration commit, never the judged
// round's own (docket-run/SKILL.md, "Worktree writers"). Absent map, absent
// entry, non-sha entry, no round fanout, round 1, missing target, dead or
// unparseable probe: every one FAILS OPEN.
//
// THE MAP CAN NAME THE WRONG ROUND. When fix@N and its fanout are split
// across dispatches, the map can carry fix@N's own integration, the
// cherry-pick OF the judged tree, which no healthy tree contains. Before
// parking, a `cherry picked from commit <target>` trailer on `prior` fails
// open.
// TEST-BEGIN fix-round-ancestry — extracted and exercised by
// tests/wave-fix-round-ancestry.test.sh (and concatenated ahead of the
// stage-ladder region by tests/wave-chain-dead-ladder.test.sh, whose ladder
// calls into it). Keep everything between the markers free of workflow
// globals (agent, probe, log, args) so it stays evaluable on its own.
//
// ONE declared dependency on another region: the target read shares the gate
// path's command and reader (`target-envelope`, nested inside `gate-vote`),
// so every suite that extracts THIS region prepends that one.

// A fix round's REVIEW FANOUT: the engine mints per-round instances as
// `name@N`, with `#k` on fanout siblings. Only fanout rows (`@N#k`) are
// guarded, and the guard starts at round 2: round 1 reviews the initial
// implement.
const FANOUT_INSTANCE_RE = /@(\d+)#\d+$/

function fixRoundFanoutRound(row) {
    const m = FANOUT_INSTANCE_RE.exec((row && row.instance) || '')
    return m ? parseInt(m[1], 10) : 0
}

// Both shas travel into a probe's command line, so both are shape-checked:
// the integrated sha against the conductor's map entry, the target sha as
// parsed off the engine bundle. Anything not plain hex is treated as absent.
const ANCESTRY_SHA_RE = /^[0-9a-f]{7,40}$/i

function integratedShaFor(row, integrated) {
    if (!integrated || typeof integrated !== 'object' ||
        Array.isArray(integrated)) return ''
    const sha = row && row.issue ? integrated[row.issue] : ''
    return typeof sha === 'string' && ANCESTRY_SHA_RE.test(sha) ? sha : ''
}

function needsAncestryCheck(row, integrated) {
    if (!row || row.kind !== 'executor') return false
    if (fixRoundFanoutRound(row) < 2) return false
    return integratedShaFor(row, integrated) !== ''
}

// The judged tree's sha, read through the envelope above. Anything that is
// not the envelope is "no target" and fails open: an invented sha would park
// a healthy round's whole fanout.
function parseAncestryTargetSha(text) {
    const target = parseTargetRef(text)
    const sha = target ? target.sha : ''
    return ANCESTRY_SHA_RE.test(sha) ? sha : ''
}

// One read-only probe: the merge-base exit status (0 = the judged tree
// contains the prior round's integrated commit) and the branch containment
// listing. Every worktree shares one object store.
function ancestryProbeCommand(prior, target) {
    return `git merge-base --is-ancestor ${prior} ${target}; ` +
        `echo "ancestry-exit=$?"; git branch -a --contains ${prior}`
}

function parseAncestryExit(text) {
    const m = (text || '').match(/ancestry-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// SELF-CHECK ON THE MAP ENTRY. Integration cherry-picks with `-x`, so a
// `prior` that is the cherry-pick OF `target` is readable off its commit
// trailer. Exit 0 = wrong round in the map. Both shas are hex-shape-checked
// before they reach a command line.
function cherryPickOfTargetCommand(prior, target) {
    return `git log -1 --format=%B ${prior} | ` +
        `grep -q "cherry picked from commit ${target}"; ` +
        `echo "cherrypick-of-target-exit=$?"`
}

function parseCherryPickOfTargetExit(text) {
    const m = (text || '').match(/cherrypick-of-target-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// The parked round, as a RELAY finding: what broke, the probe evidence
// verbatim, and what the conductor does about it. chainDead() reads the
// status.
function ancestryParkReport(step, broken) {
    const headline = `fix round ${broken.round} parked before its judge ` +
        `fanout: the prior round's integrated commit ${broken.prior} is not ` +
        `an ancestor of the judged tree ${broken.target}`
    return {
        step,
        status: 'parked-base-ancestry',
        headline,
        text: [
            `${step} BASE ANCESTRY BROKEN — ${headline}.`,
            `git merge-base --is-ancestor ${broken.prior} ${broken.target} ` +
                `exited ${broken.exit} (0 would mean the judged tree ` +
                `contains the prior round's fix).`,
            `Probe evidence (exit marker, then \`git branch -a --contains ` +
                `${broken.prior}\`):`,
            broken.evidence,
            `This is a relay finding, not a judge finding: seating the ` +
                `fanout would spend a full review round re-discovering work ` +
                `the prior round already closed. Repair the hand-off — ` +
                `verify the integration commit is actually on the shared ` +
                `branch, and repair the tree this round judges so it ` +
                `descends from it (a conflict there is a stop-and-ask) — ` +
                `then redispatch; the engine re-offers the round's steps.`,
        ].join('\n'),
    }
}
// TEST-END fix-round-ancestry

// Each issue awaits its own stages; unrelated lanes can advance independently.
// The manifest also certifies cross-issue concurrency (engine lookahead.go):
// - A class's largest same-stage count bounds its in-flight rows.
// - Co-staged writers prove their issues' scopes disjoint. Other writer pairs
//   keep the engine's stage order. This relies on the corpus convention that
//   only class "write" holds a tree; the engine still checks every claim.
// Cross-issue dependencies are already satisfied before a row is offered.
// A run park stops all later launches, while in-flight rows finish. A lane
// park, conflict, failed spawn, or uncleared gate stops only its own issue.
// TEST-BEGIN stage-ladder — extracted and exercised by
// tests/wave-chain-dead-ladder.test.sh, tests/wave-fix-round-ancestry.test.sh
// and tests/wave-issue-lanes.test.sh, which wrap this whole region in an
// async function and feed it stub `parallel`/`spawn`/`runGate`/`probe`/
// `stepShow`/`log` globals. The suites prepend configuration, park-signals
// (laneParked, runParked, isConflictReport) and fix-round-ancestry with its
// nested target-envelope helpers; other ladder dependencies stay inside the
// markers, and the only workflow globals it may reach for are those stubs,
// `rows`, `input`, and the prepended regions' helpers.
const stageOf = (row) => (Number.isInteger(row.stage) ? row.stage : 0)

// Preserve manifest order within each group; only the new map is mutated.
function groupRows(rows, keyOf) {
    const groups = new Map()
    for (const row of rows) {
        const key = keyOf(row)
        if (!groups.has(key)) groups.set(key, [])
        groups.get(key).push(row)
    }
    return groups
}

const pairsOf = (items) => items.flatMap((first, index) =>
    items.slice(index + 1).map((second) => [first, second]))
const stages = groupRows(rows, stageOf)
const stageKeys = [...stages.keys()].sort((a, b) => a - b)

log(`wave: ${rows.map((r) => `${r.step}·${r.kind === 'executor' ? r.executor : r.kind}`).join(', ')}`)
log(`wave: ${rows.length} row(s) across stage(s) ${stageKeys.join('→')}`)
{
    // Say up front which issues the fix-round ancestry guard is
    // armed for, so a wave with no `integrated` map is legible as unguarded
    // rather than silently skipping the check.
    const guarded = rows.filter((r) => needsAncestryCheck(r, input.integrated))
    if (guarded.length > 0) {
        const issues = [...new Set(guarded.map((r) => r.issue))]
        log(`wave: fix-round ancestry guard armed for ${issues.join(', ')} ` +
            `(${guarded.length} fanout row(s))`)
    }
    // ...and name the ones it is NOT armed for: fail-open is right,
    // silence is not. One line per issue.
    const unguarded = new Map()
    for (const r of rows) {
        if (!r || r.kind !== 'executor' || !r.issue) continue
        const round = fixRoundFanoutRound(r)
        if (round < 2) continue
        if (integratedShaFor(r, input.integrated) !== '') continue
        if (!unguarded.has(r.issue)) unguarded.set(r.issue, round)
    }
    for (const [issue, round] of unguarded) {
        log(`wave: fix-round fanout for ${issue} round ${round} dispatched ` +
            `UNGUARDED — no integrated entry for it`)
    }
}

// Executor rows staged BEHIND a same-issue action or vote row can be
// unclaimable by the time their stage arrives. Probe those rows and skip the
// spawn when the step is no longer claimable. Fail-open: an empty probe
// spawns.
const gateStageByIssue = new Map()
for (const row of rows) {
    if ((row.kind === 'action' || row.kind === 'vote') && row.issue) {
        const s = stageOf(row)
        const cur = gateStageByIssue.get(row.issue)
        if (cur === undefined || s < cur) gateStageByIssue.set(row.issue, s)
    }
}
function needsClaimProbe(row) {
    if (row.kind !== 'executor' || !row.issue) return false
    const g = gateStageByIssue.get(row.issue)
    return g !== undefined && g < stageOf(row)
}

// One verdict per issue-round, shared by every fanout sibling. The probes
// run AT THE ROW'S OWN STAGE, so the bundle's round record is live. Every
// uncertain outcome resolves null (fail-open); only a positively parsed
// non-zero merge-base exit parks.
const ancestryVerdicts = new Map()
function ancestryVerdict(row, phaseLabel) {
    const round = fixRoundFanoutRound(row)
    const prior = integratedShaFor(row, input.integrated)
    const key = `${row.issue}@${round}`
    if (!ancestryVerdicts.has(key)) {
        ancestryVerdicts.set(key, (async () => {
            const ctx = await probe(targetRefCommand(row.step),
                `${row.step} · ancestry:target`, phaseLabel, row.step)
            const target = parseAncestryTargetSha(ctx)
            if (!target) {
                // Two distinct causes, both fail-open, logged apart so a
                // relayed non-envelope is never mistaken for the engine
                // recording no round record.
                if (!readTargetEnvelope(ctx).parsed) {
                    log(`${row.step}: ancestry:target probe reply did not ` +
                        `parse — treating as no target; fail-open, ` +
                        `dispatching round ${round} as before`)
                } else {
                    log(`${row.step}: fix-round ancestry guard found no ` +
                        `target_sha on the bundle — fail-open, dispatching ` +
                        `round ${round} as before`)
                }
                return null
            }
            const evidence = await probe(ancestryProbeCommand(prior, target),
                `${row.step} · ancestry:merge-base`, phaseLabel, row.step)
            const exit = parseAncestryExit(evidence)
            if (exit === null) {
                log(`${row.step}: ancestry probe carried no exit marker — ` +
                    `fail-open, dispatching round ${round} as before`)
                return null
            }
            if (exit === 0) {
                log(`${row.step}: round ${round} judged tree ${target} ` +
                    `contains the prior round's integrated ${prior} — ` +
                    `ancestry holds`)
                return null
            }
            // Before parking: a `prior` that is the cherry-pick OF `target` is
            // the judged round's own integration and says nothing about the
            // hand-off. A dead or unparseable self-check keeps the park.
            const selfCheck = await probe(
                cherryPickOfTargetCommand(prior, target),
                `${row.step} · ancestry:self-check`, phaseLabel, row.step)
            if (parseCherryPickOfTargetExit(selfCheck) === 0) {
                log(`${row.step}: integrated map carries the judged round's ` +
                    `OWN integration commit — wrong round, fail-open. ` +
                    `${prior} is the cherry-pick of the judged tree ` +
                    `${target}, so it post-dates it and no healthy round ` +
                    `could contain it; dispatching round ${round} and ` +
                    `spending no park on it`)
                return null
            }
            log(`${row.step}: BASE ANCESTRY BROKEN — merge-base ` +
                `--is-ancestor ${prior} ${target} exited ${exit}; parking ` +
                `round ${round} as a relay finding instead of spending its ` +
                `judge fanout`)
            return { round, prior, target, exit, evidence }
        })())
    }
    return ancestryVerdicts.get(key)
}

const byStep = new Map()
// A park observed anywhere stops every lane's LATER launches; in-flight rows
// finish. A CONFLICT, a failed spawn, or an uncleared gate kills only its own
// ISSUE's later rows.
let parked = false
// issue -> { step, status, deferral }: which row stopped the lane, and
// whether the lane is waiting (deferral is the blocked_reason text) or
// something failed (deferral null).
const deadIssues = new Map()

// TEST-BEGIN chain-dead — see the park-signals note above.
// Each status leaves later same-issue steps unclaimable this wave.
const CHAIN_DEAD_STATUSES = [
    'gate-parked', 'gate-blocked', 'gate-rejected',
    'skipped-not-claimable', 'skipped-not-ready',
    'spawn-failed', 'claim-conflict', 'parked-base-ancestry',
    'bootstrap-denied', 'isolation-unavailable',
    // The reply-tail contract: a stop signal, or no record tail at all.
    'blocked', 'unrecorded',
    // The harness lifetime cap, reached knowingly (countedAgent).
    'agent-cap',
]

// A claim conflict on a step whose own row already reads one of these is a
// settled stage: the work (or the engine's skip) landed before this spawn
// arrived, so the lane's later rows are claimable. Every other diagnosed row
// state, and an undiagnosed relay (no step_status), still kills the chain.
const SETTLED_CONFLICT_STEP_STATUSES = ['done', 'skipped']

// A pre-claim probe that read one of these found the stage already settled by
// the engine (a conditional step it legitimately skipped, or one already done):
// the spawn is skipped, but the lane's later rows stay launchable this wave.
const SETTLED_PROBE_STATUSES = ['done', 'skipped']

// Reads the `step show` envelope startRow() carries in `text`. An absent or
// unparseable envelope is not settled, so the row keeps killing its chain.
function probeSettled(res) {
    if (res.status !== 'skipped-not-claimable' || typeof res.text !== 'string') return false
    try {
        return SETTLED_PROBE_STATUSES.includes(JSON.parse(res.text)?.data?.status)
    } catch {
        return false
    }
}

function chainDead(res) {
    if (res == null) return false
    if (res.status === 'claim-conflict' &&
        SETTLED_CONFLICT_STEP_STATUSES.includes(res.step_status)) return false
    if (probeSettled(res)) return false
    return CHAIN_DEAD_STATUSES.includes(res.status) || laneParked(res) ||
        (res.status === 'returned' &&
            (isConflictReport(res.text) || isBootstrapDenied(res.text)))
}

// A CHAIN-DEAD LANE IS NOT A DEAD CHAIN. chainDead() says only: do NOT launch
// this issue's later rows this wave. Either something failed, or nothing
// failed and the engine has not made the row claimable yet. The engine names
// the second case in `blocked_reason` on `step show --json`. Every clause
// below describes a step that is WAITING. Two conditions are deliberately
// NOT listed and keep the "died" wording: `run is not active` and `the step
// is not pending`.
const PROGRESSING_BLOCKS = [
    'an `after` predecessor is not done',
    'no threshold has routed to this interposed step',
    'an interposed gate on a predecessor has not resolved',
    "the issue's dependencies are not satisfied",
    'its scope conflicts with a claimed or running step',
    'no concurrency headroom in its class',
    'no budget headroom',
]

// Returns the engine's blocked_reason when it names a still-progressing
// predecessor, else null. Null is the SAFE answer: under-claiming a deferral
// costs one imprecise line; over-claiming one tells the operator to wait for
// a close that is never coming.
function blockedReason(res) {
    // Only statuses that can be reached with NOTHING having failed are
    // eligible. gate-rejected, spawn-failed, claim-conflict,
    // parked-base-ancestry and a CONFLICT report are failures whatever the
    // payload says; gate-parked is an uncleared gate the conductor escalates.
    if (res == null) return null
    if (!['gate-blocked', 'skipped-not-claimable', 'skipped-not-ready'].includes(res.status)) return null
    if (typeof res.text !== 'string') return null
    const m = res.text.match(/"blocked_reason"\s*:\s*"((?:[^"\\]|\\.)*)"/)
    if (!m) return null
    const reason = m[1].replace(/\\(.)/g, '$1')
    return PROGRESSING_BLOCKS.includes(reason) ? reason : null
}
// TEST-END chain-dead

// ---- lanes: one per issue, an issue-less row riding a lane of its own ----
const laneOf = (row) => (row.issue ? String(row.issue) : `row:${row.step}`)

// ---- what the manifest certifies about cross-issue concurrency ----
// Every row that is neither an action nor a vote is an executor. The engine
// keys class headroom on the row's `class`, defaulted to the executor hint
// (workflow validate.go); mirror that default.
const isExecutorRow = (row) => row.kind !== 'action' && row.kind !== 'vote'
const classOf = (row) => (typeof row.class === 'string' && row.class !== '')
    ? row.class
    : (typeof row.executor === 'string' ? row.executor : '')
const isWriter = (row) => isExecutorRow(row) && classOf(row) === 'write'
const pairKey = (a, b) => (a < b ? `${a} ${b}` : `${b} ${a}`)
// A scope pair is a fact about two lanes' own rows, and every lane arrives
// whole, so co-staging read here is the full manifest's answer. Class
// headroom is not: it rides in on args.unit.classCap and overrides the local
// count.
const certifiedClass = new Map()   // class -> largest same-stage count
for (const group of stages.values()) {
    for (const [name, members] of groupRows(group.filter(isExecutorRow), classOf)) {
        certifiedClass.set(name, Math.max(certifiedClass.get(name) || 0, members.length))
    }
}
const writerLanesOf = (rows) => [...new Set(rows.filter((row) => isWriter(row) && row.issue).map(laneOf))]
const scopePairs = new Set([...stages.values()].flatMap((group) =>
    pairsOf(writerLanesOf(group)).map(([a, b]) => pairKey(a, b))))
const scopeCertified = (a, b) => a === b || scopePairs.has(pairKey(a, b))

// ---- launches: one dispatch, one wave per lane unit ----
// The Workflow tool caps ONE invocation at HARNESS_CAP concurrent agents and
// AGENT_LIFETIME_CAP over its life; a nested workflow() shares both, separate
// top-level launches share neither. lane_units.py owns the partition: whole
// issue lanes as units, writer lanes the engine never co-staged welded into
// one unit, units packed largest-first only when they outnumber LAUNCH_CAP.
// A launch runs every row it holds. A launch still carrying the retired
// `shard` arg is refused.
function launchUnit(spec) {
    if (spec === undefined || spec === null) return { index: 0, of: 1, classCap: null }
    const bad = (why) => new Error(
        `wave.js: args.unit must be {index, of, classCap?} with integers ` +
        `0 <= index < of <= ${LAUNCH_CAP}; got ${JSON.stringify(spec)} (${why}). Refusing to route.`)
    if (typeof spec !== 'object') throw bad('not an object')
    const { index, of, classCap } = spec
    if (!Number.isInteger(index) || !Number.isInteger(of)) throw bad('non-integer')
    if (of < 1 || index < 0 || index >= of) throw bad('out of range')
    if (of > LAUNCH_CAP) throw bad(`of exceeds LAUNCH_CAP ${LAUNCH_CAP}`)
    if (classCap === undefined || classCap === null) return { index, of, classCap: null }
    if (typeof classCap !== 'object' || Array.isArray(classCap)) throw bad('classCap is not an object')
    for (const n of Object.values(classCap)) {
        if (!Number.isInteger(n) || n < 1) throw bad('classCap values must be positive integers')
    }
    return { index, of, classCap }
}
if (input.shard !== undefined) throw new Error(
    'wave.js: args.shard is retired — a launch now receives only its own rows ' +
    'and args.unit {index, of, classCap}, both from lane_units.py. Re-split the ' +
    'dispatch and relaunch; never resume a pre-split wave. Refusing to route.')
const unit = launchUnit(input.unit)
if (unit.classCap) {
    for (const [c, n] of Object.entries(unit.classCap)) certifiedClass.set(c, n)
}
if (unit.of > 1) {
    log(`wave: launch ${unit.index + 1} of ${unit.of} — this launch holds ${rows.length} ` +
        `row(s); its sibling launches hold the rest of the dispatch` +
        (unit.classCap
            ? `; class headroom from the full manifest: ` +
              Object.entries(unit.classCap).map(([c, n]) => `${c || '(no class)'}≤${n}`).join(', ')
            : ''))
}

const lanes = groupRows(rows, laneOf)
log(`wave: ${lanes.size} issue lane(s): ` + [...lanes.entries()].map(([name, laneRows]) => {
    const ks = [...new Set(laneRows.map(stageOf))].sort((a, b) => a - b)
    return `${name}×${laneRows.length}${ks.length > 1 ? ` (stages ${ks.join('→')})` : ''}`
}).join(', '))
log('wave: no wall-clock deadline exists in this harness — a hung seat holds its ' +
    'stage, lane and harness slot until the Workflow returns; a phase that stops ' +
    'advancing in the task output is the only tell, and the conductor\'s dead-launch ' +
    'check (docket-run §2) is the bound')

// Bound long writer queues so finished lanes can reach the next dispatch.
// Depth counts earlier stages with uncertified writers in OTHER lanes; a
// lane's own chain and certified neighbours do not count. Defer depth >= 3
// and the lane's later rows; the engine re-offers them next dispatch.
// Read off THIS launch's rows: an uncertified writer in a sibling launch was
// welded into this launch by lane_units.py, so none exists elsewhere.
const writersByLane = groupRows(rows.filter((row) => isWriter(row) && row.issue), laneOf)
const writerStagesByLane = new Map([...writersByLane].map(([lane, writers]) =>
    [lane, new Set(writers.map(stageOf))]))

function writerLadderDepth(row) {
    const earlierStages = [...writerStagesByLane]
        .filter(([lane]) => !scopeCertified(laneOf(row), lane))
        .flatMap(([, stages]) => [...stages].filter((stage) => stage < stageOf(row)))
    return new Set(earlierStages).size
}
const overWriterBudget = (row) => isWriter(row) && !!row.issue &&
    writerLadderDepth(row) >= WRITER_LADDER_BUDGET

const seatCount = (row) => Array.isArray(row.voter_assignments) && row.voter_assignments.length > 0
    ? row.voter_assignments.length : DEFAULT_PANEL_SEATS

// Reserve projected agents at admission against the invocation's lifetime
// cap. Reservations never release: a row that cannot fit is deferred at once,
// allowing other lanes to continue. Deepest-first admission finishes chains.
// Project the ordinary path: executor + one probe; panel + two status reads
// + one proposal body read + one blocked/held read. Keep 100 agents for
// retries, re-seats and block probes.
function agentCost(row) {
    if (row.kind === 'action') return 0
    if (row.kind === 'vote') return seatCount(row) + VOTE_PROBE_COST
    return EXECUTOR_AGENT_COST
}
// A DIFFERENT quantity from agentCost(): how many of a row's agent() calls
// are ever SIMULTANEOUSLY in flight. An executor row's spawn and probes are
// awaited one after another, so its weight is 1. A vote row's panel fans out
// in parallel, so its weight is the seat count, a safe over-approximation of
// the row's peak draw.
function concurrencyWeight(row) {
    if (row.kind === 'action') return 0
    if (row.kind === 'vote') return seatCount(row)
    return 1
}
let agentsReserved = 0
const agentsProjected = rows.reduce((n, r) => n + agentCost(r), 0)
if (agentsProjected > AGENT_BUDGET) {
    log(`wave: the manifest projects ~${agentsProjected} agents against a budget of ` +
        `${AGENT_BUDGET} (the Workflow tool's ${AGENT_LIFETIME_CAP}-agent lifetime cap less a ` +
        `${AGENT_BUDGET_RESERVE}-agent reserve for retries and re-seats); rows the budget ` +
        `cannot cover are deferred to the next dispatch as they come up, deepest stages first`)
}
const overAgentBudget = (row) => agentsReserved + agentCost(row) > AGENT_BUDGET
const AGENT_BUDGET_DEFERRAL = 'agent budget: the wave reserves at most ' +
    `${AGENT_BUDGET} projected agents per launch`

if (lanes.size > 1) {
    log(`wave: lanes run concurrently; the manifest certifies class headroom ` +
        [...certifiedClass.entries()].map(([c, n]) => `${c || '(no class)'}≤${n}`).join(', '))
    const unproven = pairsOf(writerLanesOf(rows))
        .filter(([a, b]) => !scopeCertified(a, b))
        .map(([a, b]) => `${a}/${b}`)
    if (unproven.length > 0) {
        log(`wave: cross-issue coupling — the engine never co-staged writers of ` +
            `${unproven.join(', ')}, so their scopes are unproven disjoint; those ` +
            `writers keep the global stage order between them`)
    }
}

// ---- admission: a row launches only when the in-flight set plus the row is
// a cohort the manifest certifies. Nothing here is a claim: the engine's own
// `claim` re-checks R1-R7 and stays the authority; this rule exists so the
// wave never spawns an executor INTO a refusal it can foresee. ----
const inFlight = new Map()   // step -> row, executor rows launched and unsettled
const waiting = []           // { row, seq, resolve, held }
let submitted = 0
// The Workflow tool's agent() concurrency cap is min(16, CPUs-2) per launch.
// This script cannot read the CPU count, so HARNESS_CAP is the loosest bound
// it can assert; the conductor passes the real figure as `input.harnessCap`.
// Admission is bounded to the cap so the queue stays in `waiting`, where
// pump() flushes it the moment a park lands. A caller that omits the field
// keeps the loose bound and is not refused.
const effectiveHarnessCap = (Number.isInteger(input.harnessCap) && input.harnessCap > 0)
    ? Math.min(HARNESS_CAP, input.harnessCap)
    : HARNESS_CAP
if (input.harnessCap === undefined) {
    log(`wave: harness concurrency cap — no harnessCap in args, using the ` +
        `${HARNESS_CAP}-agent ceiling as a loose bound (the real per-machine cap may be tighter)`)
} else if (effectiveHarnessCap !== HARNESS_CAP) {
    // A tighter reported cap narrows admission.
    log(`wave: harness concurrency cap — conductor reported ${input.harnessCap}, ` +
        `using ${effectiveHarnessCap} (min of that and the ${HARNESS_CAP}-agent ceiling)`)
} else if (input.harnessCap !== HARNESS_CAP) {
    // A reported cap that clamps to HARNESS_CAP, or a malformed one, still
    // gets a line: it is not the same as a caller omitting the field.
    const malformed = !Number.isInteger(input.harnessCap) || input.harnessCap <= 0
    log(`wave: harness concurrency cap — conductor reported ${JSON.stringify(input.harnessCap)}` +
        (malformed
            ? `, which is not a positive integer — ignoring it and using the ${HARNESS_CAP}-agent ceiling`
            : `, clamped to the ${HARNESS_CAP}-agent ceiling (a reported cap above it cannot widen this script's own bound)`))
}
// Weighted harness-slot occupancy, tracked separately from `inFlight`, which
// stays executor-rows-only. Every row that reaches the harness occupies
// concurrencyWeight() slots while in flight.
//
// CLAMP, not a refusal: a row whose own weight exceeds effectiveHarnessCap
// is clamped to the cap, since the harness queues the excess itself.
// Refusing to admit it would deadlock.
let harnessWeight = 0
const harnessSlots = (row) => Math.min(concurrencyWeight(row), effectiveHarnessCap)
function blocker(row) {
    const weight = harnessSlots(row)
    if (harnessWeight + weight > effectiveHarnessCap) {
        return `${harnessWeight} of ${effectiveHarnessCap} harness slot(s) in flight ` +
            `(this row needs ${weight}) — the harness runs at most ` +
            `${effectiveHarnessCap} agents concurrently`
    }
    if (!isExecutorRow(row)) return null
    const c = classOf(row)
    let live = 0
    for (const other of inFlight.values()) {
        if (classOf(other) === c) live++
        if (isWriter(row) && isWriter(other) && !scopeCertified(laneOf(row), laneOf(other))) {
            return `writer ${other.step} (${laneOf(other)}, stage ${stageOf(other)}) is ` +
                `in flight and the engine never co-staged writers of ${laneOf(row)} ` +
                `and ${laneOf(other)} — scopes unproven disjoint, holding to the ` +
                `engine's stage order`
        }
    }
    const cap = certifiedClass.get(c) || 1
    if (live >= cap) {
        return `${live} row(s) of class ${c || '(no class)'} in flight — the manifest ` +
            `certifies at most ${cap} concurrent`
    }
    return null
}
// Deterministic and synchronous. Writers first, lowest stage first (the
// engine's own order). Then every other executor row DEEPEST stage first, so
// a chain finishes instead of every chain advancing one rung per release.
// Submission order breaks ties. Every admission changes the in-flight set, so
// the scan restarts from the top.
const admissionRank = (w) => (isWriter(w.row) ? [0, stageOf(w.row)] : [1, -stageOf(w.row)])
function pump() {
    waiting.sort((a, b) => {
        const [ga, sa] = admissionRank(a)
        const [gb, sb] = admissionRank(b)
        return ga - gb || sa - sb || a.seq - b.seq
    })
    let i = 0
    while (i < waiting.length) {
        const w = waiting[i]
        if (parked) {
            waiting.splice(i, 1)
            w.resolve('parked')
            continue
        }
        // The budget is decided BEFORE the cohort blockers and never waited
        // on: a reservation is only ever released by the wave ending, so a
        // row that does not fit now will not fit later, and holding it would
        // idle its lane behind a slot that is not coming.
        if (overAgentBudget(w.row)) {
            waiting.splice(i, 1)
            w.resolve('budget')
            continue
        }
        // The session's own output-token target, a DIFFERENT budget from
        // AGENT_BUDGET: it counts TOKENS across the whole turn. budget.total
        // is null when the operator set no target. Checked once the target
        // is exhausted, since a script cannot project one agent's cost. An
        // agent() call made after exhaustion throws and would read as a
        // dead executor.
        if (budget.total && budget.remaining() <= 0) {
            waiting.splice(i, 1)
            w.resolve('token-budget')
            continue
        }
        const why = blocker(w.row)
        if (why) {
            if (!w.held) {
                w.held = true
                log(`${w.row.step}: waiting — ${why}`)
            }
            i++
            continue
        }
        waiting.splice(i, 1)
        agentsReserved += agentCost(w.row)
        harnessWeight += harnessSlots(w.row)
        if (isExecutorRow(w.row)) inFlight.set(w.row.step, w.row)
        if (w.held) log(`${w.row.step}: released — launching`)
        w.resolve('launch')
        i = 0
    }
}
// Resolves 'launch' to launch, 'parked' when the run parked while the row
// waited, 'budget' when the agent budget cannot cover the row.
function admission(row) {
    return new Promise((resolve) => {
        waiting.push({ row, seq: submitted++, resolve, held: false })
        pump()
    })
}
// Called exactly once per row that reached 'launch', so the unconditional
// decrement is safe. harnessSlots() is the same clamp pump() applied.
function release(row) {
    harnessWeight -= harnessSlots(row)
    inFlight.delete(row.step)
    pump()
}
function observePark(res) {
    if (parked || !runParked(res)) return
    parked = true
    log('wave: run parked mid-wave — no lane launches a later stage; the ' +
        'engine refuses every claim until the park lifts, then re-offers ' +
        'their steps')
    pump()
}

// One row's launch, once admitted: the gate path for a vote row, else the
// fix-round ancestry guard and the pre-claim probe ahead of the spawn.
function startRow(row, label) {
    if (row.kind === 'vote') return runGate(row, label)
    const launchRow = () => {
        if (needsClaimProbe(row)) {
            return stepShow(row.step, `${row.step} · pre-claim`, label).then((show) => {
                // Skip only on a positively recognized status; a dead probe, an
                // engine error, and any other status all spawn (fail-open).
                // `pending` belongs in the set HERE only: the lane's earlier
                // stages settled, so nothing left in this wave can advance the
                // step to `ready`.
                const terminal = ['done', 'superseded', 'skipped', 'failed', 'pending']
                if (!show || show.error || !terminal.includes(show.status)) return spawn(row, label)
                log(`${row.step}: not claimable (${show.status}) — a same-issue ` +
                    `gate or action upstream left it unreachable for this ` +
                    `wave; skipping the spawn`)
                // blockedReason() (chain-dead region) still reads `text` as
                // the raw `docket step show` envelope — render the same
                // shape the engine emits so it keeps working unchanged.
                const envelope = { data: { step: row.step, status: show.status } }
                if (show.blockedReason) envelope.data.blocked_reason = show.blockedReason
                return { step: row.step, status: 'skipped-not-claimable', text: JSON.stringify(envelope) }
            })
        }
        return spawn(row, label)
    }
    // A broken ancestry parks the round as a relay finding; anything short
    // of a positively broken read launches.
    if (needsAncestryCheck(row, input.integrated)) {
        return ancestryVerdict(row, label).then((broken) =>
            broken ? ancestryParkReport(row.step, broken) : launchRow())
    }
    return launchRow()
}

function runRow(row, label) {
    if (row.kind === 'action') {
        // Engine-run, and normally already DONE: the record of its
        // last predecessor drove it (engine drive.go) before that
        // record returned. Nothing to spawn; the row is in the
        // manifest so the stage numbering stays transparent.
        log(`${row.step}: action step — engine-run at record time, no spawn`)
        return Promise.resolve({ step: row.step, status: 'engine-run', text: null })
    }
    if (overWriterBudget(row)) {
        log(`${row.step}: not launched — writer ladder budget: ${writerLadderDepth(row)} ` +
            `stage(s) of uncertified other-lane writers sit below stage ${stageOf(row)} ` +
            `and the wave launches at most ${WRITER_LADDER_BUDGET} such cohorts; the ` +
            `engine re-offers it next dispatch (issue ${row.issue}'s later stages deferred)`)
        deadIssues.set(row.issue, { step: row.step, status: 'not-launched-writer-budget',
            deferral: `writer ladder budget: the wave launches at most ${WRITER_LADDER_BUDGET === 3 ? 'three' : WRITER_LADDER_BUDGET} uncertified writer cohorts` })
        return Promise.resolve({ step: row.step, status: 'not-launched-writer-budget', text: null })
    }
    return admission(row).then((go) => {
        if (go === 'budget') {
            // Nothing failed: the row is not launched this wave, and the
            // deadIssues mark keeps its lane's later rows from booting
            // into a claim refusal.
            log(`${row.step}: not launched — agent budget: ${agentsReserved} of ` +
                `${AGENT_BUDGET} projected agents reserved and this row needs ` +
                `${agentCost(row)} more; the engine re-offers it next dispatch` +
                (row.issue ? ` (issue ${row.issue}'s later stages deferred)` : ''))
            if (row.issue) {
                deadIssues.set(row.issue, { step: row.step, status: 'not-launched-agent-budget',
                    deferral: AGENT_BUDGET_DEFERRAL })
            }
            return { step: row.step, status: 'not-launched-agent-budget', text: null }
        }
        if (go === 'token-budget') {
            // The operator's own token target, independent of AGENT_BUDGET.
            log(`${row.step}: not launched — token budget: the session's target is exhausted ` +
                `(${budget.spent()} of ${budget.total} spent); the engine re-offers it next ` +
                `dispatch, or the operator raises the target` +
                (row.issue ? ` (issue ${row.issue}'s later stages deferred)` : ''))
            if (row.issue) {
                deadIssues.set(row.issue, { step: row.step, status: 'not-launched-token-budget',
                    deferral: 'token budget: the session\'s own output-token target is exhausted' })
            }
            return { step: row.step, status: 'not-launched-token-budget', text: null }
        }
        if (go !== 'launch') {
            log(`${row.step}: not launched — the run parked while it waited`)
            return { step: row.step, status: 'not-launched-run-parked', text: null }
        }
        return Promise.resolve()
            .then(() => startRow(row, label))
            .then((res) => {
                // Read the park signal PER ROW, the moment it lands,
                // and BEFORE the row's slot is released: releasing
                // first would admit a waiter into a run the engine
                // already refuses claims on.
                observePark(res)
                release(row)
                return res
            }, (err) => {
                release(row)
                throw err
            })
    })
}

function settleRow(row, res) {
    // Normalize BEFORE the chain test: a missing settle is recorded as
    // spawn-failed, so it has to be read as one too.
    const out = res || { step: row.step, status: 'spawn-failed', text: null }
    byStep.set(row.step, out)
    if (chainDead(out) && row.issue && laneParked(out)) {
        // A lane park is a deferral, not a death: nothing failed, the
        // issue waits on a person, and the engine re-offers its later
        // rows once the operator rules. Every other lane keeps going.
        deadIssues.set(row.issue, { step: row.step, status: out.status,
            deferral: 'parked waiting-human: the issue is on an operator decision' })
        log(`${row.step}: parked waiting-human — issue ${row.issue}'s later ` +
            `stages wait on the operator; every other lane keeps launching`)
    } else if (chainDead(out) && row.issue) {
        const deferral = blockedReason(out)
        deadIssues.set(row.issue, { step: row.step, status: out.status, deferral })
        log(deferral
            ? `${row.step}: settled ${out.status}, but the engine reports ` +
              `"${deferral}" — its predecessor is progressing, NOT failed, so ` +
              `issue ${row.issue}'s later stages are deferred to the next ` +
              `dispatch rather than dead`
            : `${row.step}: settled ${out.status} — issue ${row.issue}'s later ` +
              `stages will not be launched this wave`)
    }
}

async function runLane(name, laneRows) {
    const byStage = groupRows(laneRows, stageOf)
    const keys = [...byStage.keys()].sort((a, b) => a - b)
    for (const k of keys) {
        if (parked) break
        const group = byStage.get(k).filter((row) => {
            if (row.issue && deadIssues.has(row.issue)) {
                byStep.set(row.step, { step: row.step, status: 'skipped-chain-dead', text: null })
                // Same settle either way — the row is not launched this wave and
                // the engine re-offers it — but say WHICH of the two it is.
                // "Died" is reserved for a predecessor that actually failed.
                const d = deadIssues.get(row.issue)
                log(d.deferral
                    ? `${row.step}: later stages deferred — predecessor ${d.step} is ` +
                      `${d.status} ("${d.deferral}"); ask next after close. Nothing ` +
                      `failed: the predecessor is progressing and the engine re-offers ` +
                      `this row (the issue itself is untouched)`
                    : d.status === 'bootstrap-denied'
                    ? `${row.step}: skipped, predecessor ${d.step}'s bootstrap was ` +
                      `DENIED by the guard or the permission layer; fix that gap ` +
                      `before the next dispatch (the issue itself is untouched)`
                    : `${row.step}: skipped — this wave's chain died at an earlier ` +
                      `stage (the issue itself is untouched)`)
                return false
            }
            return true
        })
        if (group.length === 0) continue
        const label = `${name} stage ${k} (${group.length} row${group.length === 1 ? '' : 's'})`
        const settled = await parallel(group.map((row) => () => runRow(row, label)))
        settled.forEach((res, index) => settleRow(group[index], res))
    }
}

await parallel([...lanes.entries()].map(([name, laneRows]) => () => runLane(name, laneRows)))

const countSettled = (status) => rows.filter((row) => {
    const out = byStep.get(row.step)
    return out && out.status === status
}).length

// The budget's accounting, always, so the per-kind costs above can be
// recalibrated from evidence.
{
    const deferred = countSettled('not-launched-agent-budget')
    log(`wave: agent budget — ${agentsReserved} of ${AGENT_BUDGET} projected agents ` +
        `reserved this launch` + (deferred > 0
            ? `; ${deferred} row(s) deferred to the next dispatch for want of budget`
            : ''))
}
// The session's own token target, a separate budget from the one above —
// reported only when a target was set at all, since remaining() is
// Infinity otherwise and there is nothing to say.
if (budget.total) {
    const tokenDeferred = countSettled('not-launched-token-budget')
    log(`wave: token budget — ${budget.spent()} of ${budget.total} spent this turn` +
        (tokenDeferred > 0
            ? `; ${tokenDeferred} row(s) deferred to the next dispatch for want of budget`
            : ''))
}

// One entry per row this launch holds, in manifest order.
log(`wave: ${agentsLaunched} agent() call(s) launched this invocation (harness cap ${AGENT_LIFETIME_CAP})`)
return rows.map((row) => byStep.get(row.step) ||
    { step: row.step, status: parked ? 'not-launched-run-parked' : 'spawn-failed' })
// TEST-END stage-ladder
