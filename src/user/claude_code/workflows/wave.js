export const meta = {
    name: 'wave',
    description: 'Run one dispatched manifest end to end: spawn one executor per executor row at the model/effort the engine rendered on it, seat a judge panel on each vote row from its routed roster, and skip action rows (engine-run at record time). Stages run as awaited groups per issue lane, with the cross-issue cohorts the manifest certifies honored — the staged closure means one wave can carry judges -> gate -> reconcile -> report, and no issue idles behind the slower stages of another. PROBE COST PER VOTE ROW: 2 read-only haiku probes of `docket gate status` on the normal path — one before the panel seats (decided yet, which proposal, which target) and one after it returns (missing seats and the tally) — 1 on a gate that was already decided before the wave reached it, and 3 when a re-seat forces a re-read; a gate with no proposal yet spends a `step show` for the engine\'s blocked_reason instead of a panel, and an engine-minted held-cluster gate spends one more read to name its cluster. Each probe answers through a schema, under 1 KB; the per-gate count is reported verbatim in that row\'s spawn_accounting. Invoke by scriptPath ONLY, with args {rows} as a real object — every row carries model/effort/variant resolved by the engine, and the script reads no policy and cannot read files.',
    whenToUse: 'Invoked by the docket-run skill on an open dispatch, always as Workflow({scriptPath}) — never by name. args is {rows, tribunal, cwd}: `next` rows VERBATIM (executor, vote, and action rows; human rows stay with the conductor), each executor row carrying the model/effort/variant the engine resolved from the run\'s pinned policy.toml and each vote row carrying the same per voter in `voter_assignments` — a row re-typed without those fields is refused. `tribunal` is the absolute installed path to tribunal.js, the one workflow-nesting level this script uses to seat every in-wave panel (it cannot resolve that path itself); `cwd` is the repo the run belongs to. On a dispatch carrying a fix round\'s review fanout, args also carries `integrated` — a map from each such issue to the sha of its prior round\'s INTEGRATION commit — so the wave can assert base ancestry before seating the fanout. There is no policy argument of any kind and no file access.',
}

// ---------------------------------------------------------------------------
// Routing rides the row. The engine resolves {model, effort, variant} for
// every executor row and every voter from the run's PINNED policy.toml —
// attempt and round escalation, the [security] never-lists and ceiling, the
// fallback redirects — and renders the answer onto `next`'s rows. This
// script re-derives none of it: the last harness-side copy of that walk was
// a second parser fed a ~28k-char hand-copy of policy.toml every dispatch,
// whose only failure mode was deny-and-retype.
// ---------------------------------------------------------------------------

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

// SCRATCH HYGIENE: every
// file an executor writes lives in a private per-step directory <TMP>/<step>.d,
// mode 0700, built fresh at claim (rm -rf then mkdir -m 700) and removed by the
// executor the moment a record or fail exits 0. Before this, tokens (0600) and
// packets/claims (0644, world-readable) accumulated unbounded at the shared
// TMPDIR root — 911 stale tokens and 139 world-readable packets measured on one
// machine. Step ids are engine-minted and monotonic, so a fresh
// run cannot inherit stale files; the interrupted path (executor dies holding a
// claim) is swept by the conductor at reap — see docket-run/SKILL.md, "A dead
// spawn is reaped, not waited out."
//
// Replay of a stale token is refused by the engine either way (verified
// read-only against docket.git: record/fail/heartbeat
// all authorize through authorizeLease(), which refuses when owner/token_hash
// are NULL; completion and reap NULL them (RetireStepTokenTx/ReapStepTx), and
// a re-claim mints a fresh token the old one cannot match). The dir sweep is
// defense against exposure and accumulation, not the revocation mechanism.
//
// HOW THIS BRIEF IS WORDED, and it is load-bearing: state the required form,
// omit the defense. A brief never addresses the safety classifier, names a
// technique by what it gets past, or pre-argues its own authorization — a
// self-justifying brief once cost an entire dispatch every executor spawn
// (three cycles, every spawn refused, zero steps claimed). Say what to do and
// what containment binds; a rule needs no argument for why it is allowed.
// TEST-BEGIN bootstrap — extracted and exercised by
// tests/wave-bootstrap-render.test.sh, which asserts the read-class render
// (isWrite false) redirects the claim's packet to a packet.md file, carries
// the Read-tool instruction naming it, and prints no packet to stdout; the
// write-class render (isWrite true) is the negative case. Keep this function
// free of workflow globals (agent, log, args) so it stays evaluable on its
// own — the same convention tests/wave-model-attribution.test.sh already
// relies on when it extracts starting at the declaration line below.
function bootstrap(row, r, isolated, isWrite) {
    // The claim bootstrap: seven commands rendered in two joins (isolated:
    // one per Bash call, literal paths; shared: one Bash call, `&&`-chained)
    // — the same sequence duplicated in DOT-1269 already drifted once (one
    // copy wrote the packet to a file while the other printed it to stdout).
    // One array of command strings is the source for both forms; `isolated`
    // picks the token line's exact syntax (the shared form's `&&` chain
    // reads the claim file via an explicit `<` redirect since it cannot rely
    // on argument order the way a standalone call can). Nested here (rather
    // than a sibling top-level function) so the extraction convention every
    // suite already uses for bootstrap — everything from `function
    // bootstrap(` to the next marker — carries this helper along with it.
    // DKT-1709: `--owner wave:${row.step}` is a pure function of the step
    // id, so a retry launched while an earlier claim process for the same
    // step is still alive presents the IDENTICAL owner — same-owner does not
    // imply same-process. DKT-1564's same-owner re-mint (recovering a
    // caller's own committed-but-incomplete lease) can then re-key a lease a
    // DIFFERENT live process is still working under. A per-launch
    // discriminator makes a matching owner mean a matching process, so the
    // re-mint can only ever touch the caller's own earlier attempt. The
    // script has no process id and no dispatch/launch id on the row (a
    // manifest carries neither), and Math.random()/Date.now() throw in a
    // workflow script (they would break resume) — a counter on `bootstrap`
    // itself, incremented once per rendered claim command, is the one
    // resumable source of a number that is unique per LAUNCH of this
    // function rather than per wave: two concurrent launches for the same
    // step (an original and a retry the wave issues before the first
    // process exits) never collide, though two separate wave invocations
    // over their lifetimes can eventually repeat a low count — the engine's
    // guard only needs launches truly in flight together to differ.
    bootstrap.launches = (bootstrap.launches || 0) + 1
    const ownerDiscriminator = bootstrap.launches
    // DKT-1564 makes `docket step claim` exit 0 with `ok: true` when the
    // lease committed but a later stage failed: the response carries the
    // live token plus a non-empty `.data.claim_error` instead of the
    // non-zero exit that used to be the stop signal. Nothing downstream of
    // the claim reads that field on its own — a chain that only checks the
    // claim's own exit status runs straight through and writes the literal
    // string `null` as the packet (`jq -r '.data.packet'` on an envelope
    // with no `packet` key). This guard is the check: it exits non-zero
    // (jq -e, empty output on failure — nothing to relay wrongly) exactly
    // when `.data.claim_error` is present and non-empty, placed after the
    // token is captured (ending the lease is the reason the engine hands it
    // over) and before the packet is ever read.
    function claimCommands(isolated) {
        const dir = `<TMP>/${row.step}.d`
        const claimJson = `${dir}/${row.step}.claim.json`
        const token = `${dir}/${row.step}.token`
        const packet = `${dir}/${row.step}.packet.md`
        return [
            `rm -rf ${dir}`,
            `mkdir -m 700 ${dir}`,
            `docket step claim ${row.step} --owner wave:${row.step}:${ownerDiscriminator} --render --metadata ${claimMetadataArg} --json > ${claimJson}`,
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

0. YOU ARE IN A PRIVATE WORKTREE, and your Bash calls may be guard-screened —
   every rule below binds you either way. The worktree protects your
   SIBLINGS from you — it does not change your own discipline: any probe
   that must modify files still runs on a COPY under <TMP>, never on this
   checkout (never reach for git restore/checkout --/reset/clean — probing
   on copies means never needing them). Never cd out to the shared
   repository tree. Command discipline, non-negotiable — every call you make
   must be obvious at a glance, exactly what it says and nothing more:

   - ONE action per Bash call: no \`&&\` chains, no \`$(...)\` substitution
     around git. Run every command PLAIN and SEPARATE.
   - Spell every redirect target as a LITERAL absolute path (shell variables
     do not survive between your calls — see the token protocol below).
   - Run git against YOUR OWN tree only — never \`git -C\`/\`--git-dir\` at
     another checkout, never cd-then-git elsewhere. Pipes are fine.

   RUN \`docket\` BARE — no DOCKET_PATH prefix; the store resolves from
   anywhere inside the repository, this worktree included.

   Bootstrap, one plain command at a time:

   a. \`printenv TMPDIR\` — your literal scratch root. Call it <TMP>;
      substitute its literal value wherever <TMP> or \`$TMPDIR\` appears in
      this brief. (Use \`printenv\`, not \`echo\` — no variable expansion
      anywhere in your calls.) PIN IT ONCE AND REUSE THE LITERAL: \`$TMPDIR\`
      is not guaranteed to resolve to the same root on a later call, so a
      path written as the variable can name one directory when you create it
      and a different one when you read it back.
   b. \`git worktree list --porcelain\` — every checkout's path and HEAD sha.
   c. Compare \`git rev-parse HEAD\` in your tree to the HEAD of the shared
      checkout from (b) — the one NOT under \`.claude/worktrees\`. If they
      differ, run \`git checkout --detach --quiet <that sha>\`. Config bases
      your worktree on the run's HEAD, so this is normally a no-op — verify,
      never assume.

   If any of these is DENIED by the guard or the permission system, say
   \`BOOTSTRAP DENIED\`, quote the denial verbatim, and STOP — that is an
   operator permission gap, not a repository-state problem. If a command
   fails on its own output instead, report that verbatim and STOP either way;
   do not hunt, do not guess, and NEVER claim after a failed bootstrap — an
   unclaimed step re-dispatches for free, a claimed one strands a token. Once
   (c) passes, your NEXT command is the claim in 1' — no exploratory docket
   verbs first (no --help, no step list/show, no run status/report, no next,
   nothing under dispatch). The brief and the packet carry everything a
   claim needs. The one standing exception, once you hold the packet: when a
   routed finding's evidence body is not there, \`docket step artifact
   ARTIFACT-N --payload\` on an artifact id the packet itself names is the
   one sanctioned read — never run reports, step lists, \`--help\`, or the
   store's database.

   TRANSLATION RULES — obligation 3 below prints a code block written for the
   shared tree; run its ISOLATED form instead, everything else in its prose
   still binding. Obligation 1 already renders your claim form directly below.

   If the claim itself errors naming a packet file ("pinned by this run but is
   no longer on disk"), report the error verbatim and STOP — the ref came from
   a REPO-ADDITION config layer, repo-root-relative and absent from your
   worktree (shared-corpus refs resolve from any cwd); the claim already
   recorded and the token is gone, so a re-claim just burns another attempt —
   the relay's reap is the only way out.
   3'. Record with the token fed to stdin from its literal path:
       \`docket step record ${row.step} ... < <TMP>/${row.step}.d/${row.step}.token\`

   Uncommitted work in the shared tree is deliberately not visible, and
   your inputs arrive in the rendered packet, not from the tree.` : ''
    const pinNote = isolated ? '' : `

0. FIRST, before the claim: \`printenv TMPDIR\` — your literal scratch root.
   Call it <TMP>; substitute its literal value wherever <TMP> appears below.
   (Use \`printenv\`, not \`echo\`.) PIN IT ONCE AND REUSE THE LITERAL:
   \`$TMPDIR\` is not guaranteed to resolve to the same root on a later call,
   so a path written as the variable can name one directory when you create
   it and a different one when you read it back — and the claim token you
   park in obligation 1 depends on exactly that.`
    return `You are executing one step of a Docket run. Follow these obligations exactly.

YOUR ASSIGNMENT: step ${row.step} (issue ${row.issue}, run ${row.run}). This
brief was rendered for that step alone — every occurrence of ${row.step} below
is your real, already-substituted step id, NOT a template placeholder. ${row.step}
is the id you claim in obligation 1; a brief with an unfilled placeholder would
read STEP-N or \${row.step}, and this one does not.${isolationNote}${pinNote}

1. Claim it AND PARK THE TOKEN ON DISK${isolated ? ` — run these as separate
   plain Bash calls, literal paths throughout (form 1' from obligation 0):

${claimCommands(true).map((c) => `   \`${c}\``).join('\n')}
   Then open <TMP>/${row.step}.d/${row.step}.packet.md with the Read tool — the
   packet goes to a FILE here, not stdout, which also keeps a large brief from
   being truncated by the harness's inline-output cap.
` : `, in ONE Bash call, exactly this:

   \`\`\`
   ${claimCommands(false).join(' &&\n     ')}
   \`\`\`
`}

   IF THE CHAIN STOPS BEFORE THE PACKET LINE ABOVE — the claim command itself
   errored, the token file came back empty, or the \`claim_error\` check
   printed \`false\` — do NOT retry the claim and do NOT read a packet: an
   incomplete claim carries no \`packet\` key, so reading it anyway prints the
   four characters \`null\` and nothing past this point is your real contract.
   Diagnose with ONE more read-only command against the claim file that is
   still on disk (the truncation below has not run yet):

   \`jq -c '{error: .error, code: .code, claim_error: .data.claim_error, re_minted: .data.re_minted}' <TMP>/${row.step}.d/${row.step}.claim.json\`

   An EMPTY token file means no lease committed — report CLAIM FAILED with
   that diagnostic verbatim and STOP; there is nothing to end. A token file
   that DID capture something, with \`claim_error\` non-empty, means the lease
   committed but a later stage failed (the RUN-90 shape DKT-1564 exists to
   recover from) — you hold a live token and MUST end it:
   \`docket step fail ${row.step} --note '<claim_error verbatim>' < <TMP>/${row.step}.d/${row.step}.token\`,
   then report CLAIM INCOMPLETE with the diagnostic and STOP. \`re_minted: true\`
   on that diagnostic means the engine recovered YOUR OWN earlier lease under
   this same owner — name it in your report so a reap panel is not convened
   for a claim that was already yours.

   The last command TRUNCATES the claim file rather than deleting it — its
   contents are spent the moment the packet file above is written. Same rule
   at step 3.

   Every path is spelled out because YOUR SCRATCH ROOT <TMP> IS SHARED BY
   EVERY EXECUTOR IN THE WAVE (concurrent subagents all get the same
   directory) and OUTLIVES the wave. That is why EVERYTHING you write goes
   inside <TMP>/${row.step}.d — your PRIVATE STEP SCRATCH DIR, mode 0700,
   built fresh by the rm/mkdir pair above (the \`rm -rf\` clears any stale
   leftover from a prior attempt; never skip it, and never aim it anywhere
   but that literal step-id path). Your step id is what makes the dir and
   these filenames yours; do not shorten them to \`claim.json\` or \`token\`,
   or a sibling's claim overwrites yours.

   THE TOKEN IS RETURNED EXACTLY ONCE, in that response body — re-claiming is
   refused while you hold the lease, so there is NO second chance to capture
   it. SHELL VARIABLES DO NOT SURVIVE BETWEEN BASH CALLS and step 2 takes
   many calls, so a variable is useless here — the file is the only channel
   that reaches step 3.

   WRITING THE TOKEN TO THIS FILE IS REQUIRED AND AUTHORIZED — it is the
   designed mechanism, not a leak. It is mode 0600 inside your own 0700 step
   scratch dir, you remove that dir the moment your record lands (obligation
   3), and the engine retires the token in the same instant. Do not skip the
   write to be cautious: skipping it strands the step, the worse outcome.

   Then open <TMP>/${row.step}.d/${row.step}.packet.md with the Read tool — it
   is your contract. The packet goes to a FILE, not stdout, so a large brief
   is never truncated by the harness's inline-output cap; a 30KB brief is the
   normal case for a step carrying several pinned files, not an anomaly.

   On CONFLICT: stop immediately and report AT MOST three lines: your step id,
   the word CONFLICT, and the engine's error line verbatim. Do not investigate
   the holder, the scopes, or the remedy — the conductor and the engine already
   know.

2. Execute the brief you were handed. It is your entire contract.${isWrite ? `
   Ship the issue's declared change list and NOTHING beyond it: unrequested
   hardening, extra controls, and adjacent cleanups go into gap files
   (obligation 3), never into the diff — reviewers reject what nobody asked
   for. The one exception: a defect you find that is actively exploitable is
   REPORTED in your return immediately, not merely gap-filed.` : ''}
${!isWrite ? `
2r. THE CHECKOUT YOU STAND IN MAY PREDATE THE CHANGE YOUR BRIEF DESCRIBES.
   Write-class siblings work in PRIVATE worktrees and hand work back as a
   COMMIT that nothing merges into this shared checkout, so HEAD here can be
   a round or more behind the change-summary and issue.diff your packet
   renders. Before reading ANY file by path to evaluate the change:

   - FIRST: if the packet's issue.diff is EMPTY and the change-summary
     records a gap-only outcome (no commit, no files changed), there is
     nothing to evaluate. Confirm that pair in ONE read-only pass and record
     immediately, naming which half was engine-computed (the empty
     issue.diff) vs self-reported (the summary); do NOT investigate
     repositories to re-prove a non-change, and do NOT file a duplicate gap —
     the upstream record already carries it.
   - Find the target sha — the change-summary's FIRST LINE carries it.
   - IF THAT FIRST LINE CARRIES NO SHA, or reports COMMIT BLOCKED, the
     packet's target_sha is NOT the change. A blocked commit leaves the
     field EMPTY — the engine's signal for this case — so there is no sha
     to archive at all. Say exactly that in your record, evaluate the
     packet's rendered issue.diff as the change, and file NO finding
     against a file you read from that sha — each would be a false
     blocker against work that is present but uncommitted.
   - OTHERWISE reconstruct the target read-only, ALWAYS — do not first probe
     whether your checkout contains the change: integration cherry-picks, so
     the writer's sha is never an ancestor of the shared branch even after its
     content lands. TWO plain calls, and \`<TMP>\` is the LITERAL from
     bootstrap (a), never the words \`$TMPDIR\`:

       mkdir -p <TMP>/${row.step}.d/target
       git archive <sha> | tar -x -C <TMP>/${row.step}.d/target

     The \`mkdir\` is not optional: \`tar -x -C\` on a directory that does not
     exist fails \`could not chdir\` and extracts NOTHING. The literal is not
     optional either — the same \`$TMPDIR\` hazard the printenv note above
     records: extracting under one root and reading under another gets "no
     such file or directory" against a tree you just built, or worse falls
     back to reading the shared checkout: a judge reviewing a tree a round
     behind the change, exactly what this obligation prevents.

     The sha resolves even when no branch of yours carries it, because every
     worktree shares one object store. Read, build, and probe THERE, and
     attribute every result to that tree, never to this checkout.
   - If the sha does not resolve at all, that is a hard gap: record it as a
     gap file per obligation 3 instead of reviewing whatever the checkout
     happens to hold.
` : ''}${isolated && isWrite ? `
2b. COMMIT YOUR DELIVERABLE IN YOUR WORKTREE before step 3. Your edits live in
   this private worktree and NOTHING merges them back automatically — the
   commit is the hand-back channel: worktrees share the repository's object
   database, so once committed your sha is reachable from every checkout, and
   the conductor integrates it. Two SEPARATE plain calls, exactly this shape
   (no compounds, no global options before \`add\`/\`commit\`):

   git add -A
   git commit -m "type(scope): summary"

   The subject is a CONVENTIONAL COMMIT, whatever the repo's history does:
   type one of feat|fix|docs|refactor|test|perf|build|ci|chore, scope named
   for the area you touched, summary imperative plain language, 72 chars max,
   no trailing period. No body paragraphs — most commits are a subject alone;
   when the subject cannot carry the why, short "- " bullets. Never step,
   issue, or run ids (no STEP-N, DKT-N, RUN-N in subject or body): ids
   already live in your change-summary artifact and the engine record, and
   an id-bearing subject forces a hand-amend at integration.

   Then \`git rev-parse HEAD\` and put that sha ON THE FIRST LINE of your
   change-summary artifact AND in your final report. The commit signs
   non-interactively with the dedicated agent signing key the harness
   injects (ssh-format, \`~/.ssh/agent-signing.pub\`) — never pass
   \`--no-gpg-sign\` and never touch signing config. This is integration
   plumbing on a throwaway worktree branch; publishing stays the operator's
   alone. Do NOT push, and do not touch any other checkout.

   IF THE COMMIT IS REFUSED (guard or permission), do not fight it: leave the
   worktree exactly as it is, and report COMMIT BLOCKED with the refusal's
   first line verbatim plus your worktree path (from \`git rev-parse
   --show-toplevel\`) — the conductor commits on your behalf with
   \`git -C <your worktree> ...\` from its own seat. Then continue to step 3
   (your record may still succeed or park per its own rules; the two
   blockages are independent).
` : ''}

3. Record it yourself with \`docket step record\`, feeding the token file to
   STDIN${isolated ? ` — ISOLATED: run form 3' from obligation 0 (literal
   token path) in place of the command below; everything else still binds you.` : ':'}

   \`docket step record ${row.step}${isWrite ? ' --worktree <YOUR CHECKOUT>' : ''} --artifact-file <TMP>/${row.step}.d/${row.step}-<kind>.md --metadata '{"model_resolved":"unknown","effort_resolved":"unknown"}' < <TMP>/${row.step}.d/${row.step}.token\`

   \`record\` is an exact alias of \`step complete\` — use it, since some
   shells parse the bare word \`complete\` as their own builtin and refuse
   the line before docket sees it.

   Run this command SANDBOXED, same as everything else — do NOT pass
   dangerouslyDisableSandbox. Only the operator can grant that, and never
   through a brief. Most gates are pure local work (build/test/lint/scan)
   and need no elevation at all.

   IF a gate genuinely needs network access and the sandbox denies it —
   record exits non-zero and the error names a DNS failure, a TLS handshake
   failure, or a blocked host — do not retry with the sandbox disabled and
   do not treat it as a normal step failure. Attempt once, then STOP and
   report \`NETWORK GATE BLOCKED\`: the gate name, the exact host/domain the
   error names, and the error verbatim. Leave your token intact, as an
   unresolved record refusal below. The fix is a named domain added to
   \`sandbox_network_allowed_domains\` in \`src/user/claude_code.rs\` through
   the operator's own \`just activate\` — never a live bypass, never on your
   say-so.
${isWrite ? `
   \`--worktree\` names the checkout the work happened in. The engine
   computes the recorded diff THERE, and spawns your step's completion gates
   and the downstream verify pre-gate with that checkout as cwd too. Get its
   literal path once with \`git rev-parse --show-toplevel\` and paste that
   in; without it the engine diffs the wrong tree.
` : ''}
   Leave \`model_resolved\` and \`effort_resolved\` as \`unknown\` unless the
   runtime directly supplies an observation for this execution. Requested
   routing, aliases, settings, and your own identity claim are not observations:
   the harness may substitute a model or cap effort. Do not infer either value.
   When an observation is available, use its exact model ID and effort, and
   identify the source in the artifact. If multiple serving models are observed,
   report them there and keep the single \`model_resolved\` value unknown.

   Native workflow \`agent()\` returns an answer or null, not SDK
   \`modelUsage\` telemetry. After the wave, \`wave-usage.js\` reads serving
   models from assistant-message \`model\` fields in the actual transcripts.
   It reports all observed models separately from requested routing; it cannot
   recover an effective effort that the transcript does not expose.

   or on failure:

   \`docket step fail ${row.step} --note '<why>' < <TMP>/${row.step}.d/${row.step}.token\`

   \`fail\` takes ONLY --note and --metadata — there is no --artifact-file on
   it; \`--artifact-file\` exists on \`record\` alone, where it is MANDATORY.
   Reach for \`fail\` only when a retry might redeem the attempt.

   AN OUT-OF-SCOPE PROBLEM YOUR WORK SURFACED IS NEITHER A FAILURE NOR YOUR
   DECLARED ARTIFACT. Write each one to its own file and pass \`--gap-file
   <path>\` (repeatable) on the record: every gap file lands as a \`gap\`
   artifact beside your declared emit AND files a related backlog issue in
   the SAME transaction — no workflow declaration needed, that channel is
   always open. Your contract's Stuck clause is a SUCCESS recorded this way,
   never a \`fail\`.

   A gap file's FIRST LINE becomes the filed issue's TITLE: one line naming
   the defect itself. Its SECOND LINE is the home declaration, ALWAYS:
   \`Home: <repo/checkout>\` — the other repository when the problem lives
   elsewhere, or \`Home: THIS repository\` when it is local (gaps belong to
   their respective projects; the engine files yours HERE and the conductor
   re-homes it from your Home: line). Its THIRD LINE is \`Files: <path>,
   <path>\` — every concrete file the fix will touch, comma-separated —
   with a \`Scope: <glob>, <glob>\` line after it only when a glob bounds
   the fix wider than those files. The engine files the issue with neither
   \`-f\` nor \`--scope\`, and the conductor promotes these lines into
   both at close so planning can keep the gap apart from colliding work.
${isolated ? `
   IF THE RECORD IS REFUSED (guard or permission), attempt it ONCE and STOP
   TRYING FORMS. Leave your deliverables parked where the brief already has
   them —

     <TMP>/${row.step}.d/${row.step}.token       (intact, 0600 — do NOT truncate it)
     <TMP>/${row.step}.d/${row.step}-<kind>.md   (your artifact body)
     <TMP>/${row.step}.d/${row.step}-payload.json (your payload, when the contract has one)

   (the WHOLE step scratch dir stays intact; the conductor records from it
   on your behalf and sweeps it after)

   — and report RECORD BLOCKED: your step id, the refusal's first line
   verbatim, and every parked path including the token's. ONE refusal is an
   instruction, not a wall: "the lease has expired; claim it again to
   continue" means run the claim from 1' again for a FRESH token and record
   immediately — your finished work is still valid. Park and report only
   when the re-claim or the record refuses for any OTHER reason; the
   conductor is not isolated and records the step from your parked state.
   NEVER record \`fail\` for work that succeeded — a false failure burns an
   attempt and re-runs the whole step to relearn what your parked artifacts
   already hold.
` : ''}

   The CLI reads the token from DOCKET_TOKEN or, when that is unset, from
   stdin. NOTHING SETS DOCKET_TOKEN FOR YOU — a claim cannot export into
   your shell. Redirecting the file into stdin is the channel.

   Never \`cat\` the file, echo its contents, paste it into a command line, or
   reproduce it in your reply. There is deliberately no \`--token\` flag on any
   verb, because argv is world-readable through \`ps\`. Redirect it; never read it.

   After the record command exits 0, REMOVE YOUR STEP SCRATCH DIR in one
   plain call — \`rm -rf <TMP>/${row.step}.d\` — token, packet, and all. The
   engine retires the token the moment the record lands and copies your
   artifact, payload, and gap files into its store during the record itself,
   so nothing in the dir will ever be read again. The sweep is part of the
   record, not optional tidying — a leftover dir parks a spent credential
   and your full rendered brief in a scratch root later agents, runs, and
   sessions all share. The same sweep follows a \`fail\` that exits 0. If
   \`record\` or \`fail\` errored, KEEP the dir and its token file INTACT and
   stop — the token is the only thing that can still drive this step, and
   losing it after a failed record turns a routine step failure into a
   zombie claim the lease must reap.

   If the token file is missing or empty, or a record is refused for a missing
   or invalid token, say so plainly and stop. Do not reconstruct or guess it.

   EVERY record carries an artifact file. The engine refuses a record without
   \`--artifact-file\` before it validates anything else, so the file is
   never optional. Create it WITH BASH
   (a heredoc: \`cat > <TMP>/${row.step}.d/${row.step}-<kind>.md <<'EOF' ... EOF\`)
   as a FRESH file whose name starts with your step id, then pass that path as
   \`--artifact-file\`. NEVER create this file with the Write tool: under the
   sandbox it materializes files at a DIFFERENT physical path than the <TMP>
   root your Bash commands use, and the record then fails "no such file or
   directory" against a file you just wrote.

   ARTIFACT FILES: THREE AUTHORING RULES. A large or brace-heavy heredoc
   body fails in an isolated shell; author files these ways from the start
   and that failure never arises. Every form below writes ONLY to targets
   under your <TMP> or your own worktree — that containment is the rule
   itself.

   - SIZE: never write a large body in one heredoc. Write the file as an
     initial \`cat > <path> <<'EOF'\` of a few KB at most, followed by
     \`cat >> <path> <<'EOF'\` appends of the same size until done.
   - JSON: always \`jq -n\` (below) — never a JSON literal in any heredoc.
   - CODE EXCERPTS (Go signatures, config samples, anything brace- or
     bracket-heavy): let the excerpt travel as file bytes rather than as
     command text. Write it to its own scratch file in small chunks with the
     SIZE form above, then \`cat\` that file into place — or build the
     artifact with \`jq -n --rawfile body <TMP>/<step>.d/<step>-excerpt.txt\`.
     Do not hand-encode, escape, or otherwise transform the content itself.

   (There is no \`--artifact-kind\`: the workflow's
   \`emits\` declares the artifact's KIND — which your brief's OUTPUT section
   already names — it does not make the file optional. A structured payload,
   when your brief requires one, goes in \`--payload-file <path>\` — and you
   BUILD that JSON with \`jq -n\`, never as a JSON literal in a heredoc or
   command: an isolated shell's guard refuses any heredoc body carrying \`{\`
   immediately followed by \`"\` — which is every JSON object literal, so no
   formatting gets a literal past it. \`jq -n --arg id AC1 --arg status met
   '{id: $id, status: $status}' > "$path"\` is the honest shape: the command
   text carries only \`{id:\` (which the guard allows) and jq writes the real
   JSON to the file. Keys needing quotes go as \`{("kebab-key"): $v}\`;
   arrays as \`jq -n '[ ... ]'\` or by \`jq -s\` over per-element files.)
   Never write to or reuse a shared filename like \`change-summary.md\`:
   executors in one wave share the <TMP> root — write inside your private
   step dir so your bytes cannot collide, and under a shared name a racing
   sibling's bytes, or a predecessor's leftover, get recorded as YOUR
   artifact.

   If a write is refused, triage the refusal before anything else. One that
   names the body's SIZE OR CONTENT, on a target under <TMP> or your own
   worktree, means the three forms above are how to write it — use them.
   One that says the command is TOO COMPLEX TO VERIFY that it stays inside
   the worktree names the command's SHAPE, not its body: reissue the same
   work as single plain commands — ONE redirection or ONE heredoc each, no
   \`&&\`, no pipes, no \`;\`, no command substitution — and run them
   separately. Its closing line about git operations is boilerplate that
   fires on non-git commands too, so do NOT read it as a claim that you
   touched git. This is the same guard as the brace-then-quote rule above,
   refusing on a different axis. One that names ANYTHING ELSE — the target
   path, a permission, a policy concern — is a real BLOCKED condition on the
   spot, exactly like a refused record, and so is one that survives the
   three forms: report \`WRITE BLOCKED\`, the refusal's first line, and every
   path involved, then stop that path and record what you can. Never devise
   an encoding, a substitution, or a staged rewrite to get refused content
   through: content that will not go through in the plain forms is a
   BLOCKED report, always.

   Keep the claim's requested model, effort, and variant unchanged. They record
   the engine's routing decision even when execution fails or is interrupted.
   Do not calculate a cost multiplier from model names or token prices; the
   engine's declared cost and supplied routing remain authoritative.

4. End your reply with exactly this line, filled in from the record
   response: <step-id> recorded (<status>) — for example "STEP-12 recorded
   (done)" or "STEP-12 recorded (waiting-human)". The wave parses this tail
   to stop launching this issue's later stages once it parks; do not
   paraphrase it.`
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

// An agent's reply is PROSE. Read only the two shapes the brief actually
// mandates — never a substring of the body.
//
// Both park signals used to be `includes` over the whole reply, and one past
// run shows the cost: a judge reviewed the pause skill, quoted the engine
// constant it was reviewing — `CondRunActive = "run is not active"` — and
// recorded `done`. Its last line said so verbatim, `<step> recorded (done)`.
// The wave read the quote, declared the run parked, and never launched stage
// 2; the engine re-offered synthesize one full dispatch round-trip later. A
// reviewer of park handling cannot describe a park without tripping a body
// scan, and this corpus reviews its own park handling constantly.
// TEST-BEGIN park-signals — extracted and exercised by
// tests/wave-park-signals.test.sh against verbatim replies captured from that
// run. Keep everything between the markers free of workflow globals (agent,
// log, args) so it stays evaluable on its own.
const CONFLICT_REPORT_MAX_LINES = 4

function lastLine(text) {
    const lines = String(text).trim().split('\n').filter((l) => l.trim())
    return lines.length ? lines[lines.length - 1].trim() : ''
}

// Obligation 1's CONFLICT clause mandates AT MOST three lines: the step id,
// the word CONFLICT, and the engine's error verbatim (one line of slack for a
// wrapper). Longer than that and the word is a FINDING about conflicts, not a
// conflict — the same confusion, one field over.
function isConflictReport(text) {
    if (typeof text !== 'string' || !text.includes('CONFLICT')) return false
    return text.trim().split('\n').filter((l) => l.trim()).length
        <= CONFLICT_REPORT_MAX_LINES
}

// Two park signals, both in-band, and they now mean DIFFERENT scopes. The
// record-status tail of the agent whose own record parked ('STEP-N recorded
// (waiting-human)') parks that ISSUE: the engine's R2b refuses every later
// claim on the same issue until the operator rules, and the run stays
// `active` for every other lane. Reading it as a run-wide park was what
// RUN-90 paid for — 1372 of 1656 dispatched rows never launched because one
// lane's verify parked. The claim-CONFLICT report of an agent that launched
// INTO a park ('run is not active') is still run-wide: R1 refuses every
// claim, so every lane stops launching. The tail format is mandated by the
// brief's closing instruction below, which says to END the reply with it, so
// it is read at the END and nowhere else; trailing emphasis or punctuation is
// tolerated, a paragraph after it is not. Fail-open: no match keeps launching,
// and the engine refuses a claim into a parked issue or run anyway.
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
// TEST-END park-signals

// ---------------------------------------------------------------------------
// ORPHANED CLAIM. One claim refusal inverts its own meaning when
// relayed at face value: `not ready to claim: the step is not pending` reads
// as "never started" but actually means ALREADY CLAIMED — routinely by a
// PREDECESSOR OF THE VERY AGENT that just reported it.
//
// RUN-61 DISPATCH-332 is the fixture: the operator interrupted
// the fix@1 executor mid-step, harness resume relaunched the identical agent
// spec (none of wave.js's own retry paths fired — resume is invisible from
// inside this script), the relaunched agent's claim was refused with that
// sentence, and the wave reported it as STEP-2760's outcome before
// chain-killing nine downstream rows. The truth was the opposite — claimed,
// holder dead, reap needed — and the conductor had to reconstruct it from
// the journal.
//
// THE CAVEAT: on a harness resume an interrupted executor's brief re-executes
// with IDENTICAL BYTES, and the docket claim is the only thing standing
// between that and silent duplicate work — but only for WRITE-class work,
// which claims. A READ-class brief that never claims re-runs INVISIBLY, so
// this branch diagnoses the write-class case alone.
//
// The remedy is REPORT-ONLY: the chain-kill is correct either way (nothing
// downstream of an unrecorded step becomes claimable this wave), preserved
// via the explicit `claim-conflict` status in chainDead(), independent of
// isConflictReport()'s line budget.
// TEST-BEGIN orphaned-claim — extracted and exercised by
// tests/wave-orphaned-claim.test.sh, which concatenates the park-signals
// region ahead of it (isConflictReport) and the chain-dead region after it.
// Keep everything between the markers free of workflow globals (agent, probe,
// log, args) so it stays evaluable on its own.
const CLAIM_CONFLICT_STATUS = 'claim-conflict'
const NOT_PENDING_CONFLICT = /not ready to claim:\s*the step is not pending/i

// Same domain rule as every other predicate here: a CONFLICT REPORT, which
// obligation 1 caps at three lines, never an arbitrary agent reply. A judge
// writing ABOUT this conflict fails the line budget and is left alone. The
// park signal wins the tie: 'run is not active' is a run-wide park that
// runParked() must still see on a `returned` result, so it is never enriched
// into a status of its own here.
function isOrphanedClaimConflict(text) {
    if (!isConflictReport(text)) return false
    if (text.includes('run is not active')) return false
    return NOT_PENDING_CONFLICT.test(text)
}

// `docket step show STEP-N --json` read the way the rest of this file reads
// engine JSON: named fields, matched wherever they sit in the envelope, each
// one independently OPTIONAL. Absence is normal (a lease block is absent on an
// unclaimed step; `failed_attempts`/`reaped_claims` are omitted at 0), and
// nothing here is asserted that the text did not actually carry.
function parseStepShow(show) {
    const s = typeof show === 'string' ? show : ''
    const grab = (key, val) => {
        const m = s.match(new RegExp(`"${key}"\\s*:\\s*${val}`))
        return m ? m[1] : ''
    }
    return {
        status: grab('status', '"([a-z-]+)"'),
        attempt: grab('attempt', '(\\d+)'),
        owner: grab('owner', '"([^"]*)"'),
        live: grab('live', '(true|false)'),
        failed: grab('failed_attempts', '(\\d+)'),
        reaped: grab('reaped_claims', '(\\d+)'),
    }
}

// A step whose row is HELD by a claim — the orphan case.
const CLAIM_HELD = ['claimed', 'running']
// A step that already recorded. The refusal then means this spawn arrived
// after the fact, which is the opposite diagnosis and needs no reap.
const ALREADY_RECORDED = ['done', 'superseded', 'skipped', 'failed']

// Build the step's real state as the outcome, in place of the raw refusal.
// Returns null when the probe text carries no status at all — the caller then
// relays the CONFLICT exactly as before, so a dead or empty probe degrades to
// precisely the old behavior.
function orphanedClaimReport(step, conflict, show) {
    const st = parseStepShow(show)
    if (!st.status) return null
    const at = st.attempt !== '' ? ` at attempt ${st.attempt}` : ''
    const facts = [
        `status=${st.status}`,
        st.attempt !== '' ? `attempt=${st.attempt}` : '',
        st.owner ? `owner=${JSON.stringify(st.owner)}` : '',
        st.live !== '' ? `lease live=${st.live}` : '',
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
            `--reason '<what you observed>'\` (token-free). Do NOT read this ` +
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

// The safety classifier runs PRE-SPAWN and fails CLOSED: when its stage-2
// check errors out, it blocks the launch and says so in its own reason text.
// One past run lost 3 of 24 executor spawns to the SAME error, verbatim,
// across three different issues/classes/models — infra, not content, since
// all three later recorded `done` on redispatch from the identical brief
// bytes, direct proof that resubmission succeeds.
//
// So the retry is gated on the classifier's own transient admission alone,
// and it resubmits the SAME BYTES — same brief, same opts. A REWORDED
// resubmission is the one thing never to do: to the classifier it reads as
// an obfuscated retry of blocked content. A content-based block (any reason
// without this signature) is a real refusal, deterministic on identical
// bytes anyway, and stays operator-escalated on the first failure.
//
// TEST-BEGIN classifier-retry — extracted and exercised by
// tests/wave-classifier-retry.test.sh against the verbatim reason text
// captured from that run. Keep everything between the markers free of
// workflow globals (agent, log, args) so it stays evaluable on its own.
//
// Both regexes must hit. CLASSIFIER_BLOCK is the harness's own wrapper —
// `[${label}] blocked by safety classifier: ${reason}` — which keeps the
// predicate off every other spawn error; TRANSIENT_CLASSIFIER is the
// classifier's admission that its own stage 2 broke. A content-based reason
// names the content, never its own machinery, so it matches neither phrase.
// Domain is BLOCK-REASON AND ERROR STRINGS ONLY, never an agent reply — the
// park-signal lesson one field over: a judge reviewing this retry will quote
// these sentences, and a body scan would misread the quote as the real thing.
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

// A pre-spawn classifier block resolves agent() to a BARE null: the reason
// goes only to the harness's progress stream, which this script cannot read.
// The harness PERSISTS that stream as JSON at
// ~/.claude/projects/<flattened-cwd>/<session-id>/[subagents/]workflows/<wfId>.json,
// each workflowProgress entry carrying `label`, `blocked`, and the verbatim
// `error` — a read-only probe agent CAN read that file, so the null branch
// recovers the reason out-of-band instead of guessing. Killed waves persist
// partial progress, so the file is not completion-only; whether every
// mid-run block is flushed by the time the probe looks is UNVERIFIED — if
// not, the probe finds nothing and the branch degrades to its old
// conservative behavior.
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
        'step\'s agent launch just resolved to null — blocked by the pre-spawn',
        'safety classifier, skipped by the operator, an unavailable model, or a',
        'mid-flight death. The harness records which, but only in its own wave',
        'state file, unreadable to the workflow script. Your ONLY job is to',
        'recover that record VERBATIM so the wave can tell a transient infra',
        'block (sanctioned to resubmit the IDENTICAL brief once) from everything',
        'else (operator-escalated). Change nothing, rephrase nothing.',
        '',
        'WAVE PROBE: not a step execution. Your usage is wave overhead — the',
        'label below names the step you are READING ABOUT, and the usage join',
        'must not attribute your tokens to it.',
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
        'HOW — parse the JSON (python3 or jq); never raw-grep, since other',
        'fields such as promptPreview quote labels too:',
        '1. Consider only files modified within the last 12 hours whose',
        '   top-level status is NOT "completed", "failed", or "killed" — a',
        '   terminal-status file is some OTHER, older run of the same step.',
        '2. Find workflowProgress entries whose `label` field equals the',
        '   target EXACTLY. Ignore your own entry (label ends "block-probe")',
        '   and NEVER read agent-*.jsonl transcripts — agents quote classifier',
        '   text in prose, out of domain.',
        '3. If exactly one live-wave entry matches, report its fields',
        '   verbatim. If none match, more than one candidate remains, or',
        '   anything is ambiguous, report found: false — never a guess.',
        '',
        'Return via the structured output: found (exactly one match in a live',
        'wave), label (verbatim), blocked, state, error (byte-for-byte, never',
        'trimmed/rewrapped/paraphrased), file (the path you read it from).',
    ].join('\n')
}

// TEST-BEGIN null-probe — extracted and exercised by
// tests/wave-classifier-retry.test.sh. Keep everything between the markers
// free of workflow globals (agent, log, args) so it stays evaluable alone.
//
// The probe returns a structured CLAIM about this step's progress entry.
// Trust none of it structurally: a recovered reason is usable only when the
// probe found a live-wave entry, the entry is a pre-spawn BLOCK
// (blocked === true — an operator skip or mid-flight death is never
// blocked), the label echoes this step's label byte-for-byte (so a sloppy
// probe cannot hand back some other step's block), and the reason is a
// non-empty string. Anything less returns null and the null branch stays
// exactly as conservative as before the probe existed. The returned reason
// still has to pass transientClassifierBlock() at the call site — this
// function decides provenance, not transience.
function probeRecovered(p, label) {
    if (!p || p.found !== true || p.blocked !== true) return null
    if (p.label !== label) return null
    return typeof p.error === 'string' && p.error !== '' ? p.error : null
}
// TEST-END null-probe

// DOT-1265: once a null-recovery probe (either kind below) comes back with
// nothing itself, a burst of nulls across many rows is a session/rate-limit
// event, not N independent dead spawns — measured: a mid-wave 429 nulled 22
// of 26 agent() calls, and the block-probe this file already spawns per
// null is an agent() call too, so probing every one of them just adds more
// corpses to the same storm (11 extra, on that run, all also null). Module
// state, not per-row: `spawn()` runs once per row and shares this flag
// across every row this wave. Date.now() is unavailable in a workflow
// script, so the trip is "a probe itself returned nothing", not a time
// window.
let nullBurstTripped = false

function spawn(row, phaseLabel) {
    const r = resolve(row)
    const type = archetype(row, r.hint)
    // Only writers get a worktree, so parallel WRITERS cannot cross-
    // contaminate the shared tree (read-class steps never mutate it). The
    // harness guard that polices an isolated shell also refuses any heredoc
    // body carrying `{` immediately followed by `"` — every JSON object
    // literal — so isolating readers taxed exactly the steps whose payloads
    // are JSON (89 refusals across 21 agents in 6 waves).
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
            `${row.step} --reason '<what you observed>'\` (token-free) before ` +
            `any retry. If that error carries the TRANSIENT classifier ` +
            `signature (\`Stage 2 classifier error\` / \`usually transient\`), ` +
            `redispatch the step UNCHANGED — same brief, never reworded`)
        return failed()
    }
    const handle = (text, retried) => {
        if (text != null) {
            const returned = { step: row.step, status: 'returned', text }
            // The ONE refusal whose face value inverts the truth.
            // "not ready to claim: the step is not pending" reads as "never
            // started" and means "already claimed" — ask the engine what the
            // step's row actually says and report THAT, refusal kept verbatim
            // underneath. See the ORPHANED CLAIM note above for the caveat
            // this cannot see: a read-class brief re-runs invisibly on
            // harness resume, since only a claim refuses the duplicate.
            if (!isOrphanedClaimConflict(text)) return returned
            log(`${row.step}: claim refused "the step is not pending" — probing ` +
                `the step's real state rather than relaying the refusal as the ` +
                `outcome`)
            return probe(`docket step show ${row.step} --json`,
                `${row.step} · claim-conflict`, phaseLabel, row.step)
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
        // A bare null is still NEVER retried blind: agent() resolves to
        // `null` for a pre-spawn classifier block, an operator SKIP, an
        // unavailable model, and a mid-flight death alike, and the reason
        // string goes only onto the progress stream (workflowProgress[].error)
        // which this script cannot read. A blind retry here would relaunch
        // agents the operator had just skipped.
        //
        // DOT-1265: a null does not mean nothing happened — the record can
        // complete and the very API turn that would have returned the
        // agent's final text can still die (a rate limit, a dropped
        // connection) afterward, which reads identically to a dead spawn
        // unless something checks. So before any attribution attempt, ask
        // the engine directly with the same read-only probe the
        // claim-conflict path above uses: if the step's own row already
        // reads `done`, the record landed and this lane is alive, whatever
        // this particular agent() call returned.
        if (nullBurstTripped) {
            log(`${row.step}: agent() returned null and this wave already ` +
                `tripped the null-burst breaker (a recovery probe came back ` +
                `empty earlier) — settling directly as a session/rate-limit ` +
                `event rather than spawning another probe`)
            return escalate()
        }
        return probe(`docket step show ${row.step} --json`,
            `${row.step} · null-recovery`, phaseLabel, row.step)
            .then((show) => {
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
                if (show === '') {
                    // The recovery probe's own agent() call came back with
                    // nothing — the same failure the row it was checking
                    // just had. One probe is enough evidence of a storm.
                    nullBurstTripped = true
                    log(`${row.step}: the null-recovery probe itself returned ` +
                        `nothing — treating this as a session/rate-limit event; ` +
                        `no further per-row recovery probes this wave`)
                    return escalate()
                }
                return notRecorded()
            }, () => {
                nullBurstTripped = true
                return escalate()
            })

        // The record did not land (or the probe found nothing conclusive,
        // never a storm signature). Fall back to the pre-existing
        // classifier-block attribution, unchanged: identical-bytes
        // resubmission fires only on a probe-recovered, label-matched,
        // blocked === true entry whose reason carries the transient
        // signature. Every other outcome escalates exactly as before. The
        // probe deliberately inherits the session model (no model override
        // below): nulls are rare, and a wrong extraction here is the one
        // thing that could relaunch an agent the operator skipped.
        function notRecorded() {
            if (retried) return escalate()
            return agent(blockProbeBrief(stepLabel), {
                label: `${row.step} · block-probe`,
                phase: phaseLabel,
                agentType: 'executor-read',
                effort: 'low',
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
        agent(bootstrap(row, r, iso, isWrite), opts(iso)).then((text) => handle(text, retried))
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
        .catch((err) => {
            if (transientClassifierBlock(err)) return retryTransient(err, isolated)
            if (isolated && /base branch|worktree/i.test(String(err))) {
                log(`${row.step}: worktree isolation unavailable (${err}) — retrying ` +
                    `WITHOUT isolation; cross-contamination guard is OFF for this spawn`)
                return launch(false)
                    .catch((err2) => {
                        log(`${row.step}: spawn error on non-isolated retry: ${err2}`)
                        return failed()
                    })
            }
            log(`${row.step}: spawn error: ${err}`)
            return failed()
        })
}

// ---------------------------------------------------------------------------
// Vote rows: the in-wave panel. A `kind:"vote"` row rides the manifest —
// ready, or STAGED behind the work it judges — and the wave seats the panel
// by calling tribunal.js one level deep (`workflow({scriptPath: args.tribunal}, ...)`),
// passing `step` so it renders the mid-wave brief instead of the
// conversational one. The engine remains the only authority: `step record` on
// the gate's last predecessor opens the proposal, each seat casts a REAL
// `docket vote cast`, the engine tallies, and the quorum-reaching cast routes
// the gate. This script never casts, approves, or tallies.
//
// Seat routing is the engine's: each `voter_assignments` entry carries the
// seat's {model, effort, variant} — its standing variant with the [security]
// pins applied and the row's issue labels already weighed — so the wave reads
// it and re-derives nothing, the same contract tribunal.js holds its caller to.
// ---------------------------------------------------------------------------

// A seat missing any of the triple was never routed — the run pins no
// policy.toml, or the roster was re-typed without its fields — and a panel
// seated on a guessed tier is the drift a harness-side policy parser used
// to cause. Used both for executor rows (resolve(), above) and to validate a
// vote row's voter_assignments before they cross into tribunal.js's args.
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
// Everything else the region needs must stay INSIDE the markers;
// tests/wave-target-envelope.test.sh extracts it to assert the gate path
// spends no target probe, and tests/tribunal-seat-brief.test.sh pins the
// brief tribunal.js renders for the mid-wave call this region makes.
function probeBrief(command, servingStep) {
    return `Run exactly this one command:

  ${command}

Return its output VERBATIM as your entire final reply — every line, unedited,
no summary, no commentary, no code fence, nothing added. If the command errors,
return the error text verbatim instead.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution. Your usage is wave overhead${servingStep ? `. This
read serves ${servingStep}, which is the step it READS, not a step you run — the
usage join must not attribute your tokens to it` : ''}.`
}

// A GATE probe that dies at the agent level (one past run hit this on its
// tally read: "API Error: Connection lost mid-response") used to degrade
// straight to an empty answer — the wave then judged the gate on an empty
// read, and the completion notification carried the corpse as a failures
// entry BESIDE the same step's gate-passed verdict. A probe is one read-only,
// idempotent command, so the IDENTICAL brief is resubmitted once — except on
// a non-transient classifier block, which is deterministic on identical
// bytes. The absorbed error and the retry land in `acct`, so a SUCCEEDING
// gate reports them as notes instead of leaving them to read as failures
// (gateSuccess below). Accounting — and with it the retry — rides only the
// gate path: call sites that pass no acct keep the single-shot fail-open
// behavior.
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
        // so the gate summary can say "3 seats, 2 probes".
        if (acct) acct.probes++
        return agent(probeBrief(command, servingStep), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: 'haiku',
            effort: 'low',
        }).then((text) => text == null ? '' : text)
    }
    return retrying(label, acct, once, '')
}

// `docket gate status STEP-N --json` answers a gate's whole decision state in
// one envelope — {step_status, proposal?, outcome, tally?, seats?,
// missing_seats, target?} — so one read replaces the step-show / vote-show /
// outcome scatter that cost three to five relays per vote row, and the roster
// check reads the engine's own `missing_seats` instead of matching seat names
// out of a relayed record.
//
// THE PROBE ANSWERS THROUGH A SCHEMA, NEVER AS TEXT. A haiku seat told to
// retype a 10 KB vote record verbatim corrupted two copies on one wave (a
// dropped closing brace; 81 chars lost mid-body), and the regex fallbacks
// that rescued those reads could equally match a verdict quoted inside a
// seat's free-text summary — one did, flipping an approved gate. The
// envelope is under 1 KB and the harness validates the shape, so a reply is
// the envelope or it is nothing.
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

Return the command's \`data\` object through the structured output, field for
field and value for value — copy, never summarize; add no field the output did
not carry and fill none in. If the command errors or prints no \`data\` object,
return {error: <the error text verbatim>} and nothing else.

THEN, only when that \`data\` carries a non-empty \`target.worktree\`, run one
more command against that literal path:

  test -d <that path> && echo yes || echo no

and report \`target_worktree_exists\`: true for yes, false for no. That single
field is the one thing you add; omit it entirely when there was no worktree to
test, and copy everything else.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution. Your usage is wave overhead. This read serves
${step}, which is the step it READS, not a step you run — the usage join must
not attribute your tokens to it.`
}

// The envelope, or null when the probe died, the command errored, or the
// reply is not one. Null means UNKNOWN to every caller — never "every seat
// missing": an empty read once re-spawned a whole panel that had already
// voted.
function gateStatus(step, label, phaseLabel, acct) {
    const once = () => {
        acct.probes++
        return agent(gateStatusBrief(step), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: 'haiku',
            effort: 'low',
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
// a brief only when it is SHAPED like the full object id the engine records
// — 40 lowercase hex, never an abbreviation, never prose: one relayed
// fabrication once sent three opus judges hunting a phantom commit, and
// seatBrief re-checks the shape so no caller can route around this.
const TARGET_SHA_RE = /^[0-9a-f]{40}$/

function gateTarget(g) {
    const t = g.target
    if (!t || typeof t !== 'object') return null
    const sha = (typeof t.sha === 'string' && TARGET_SHA_RE.test(t.sha)) ? t.sha : ''
    // The conductor sweeps a write-class worktree once its round integrates,
    // so the path the engine recorded is routinely gone by the time a panel
    // seats on it — and every `git -C <path>` the brief then hands a judge
    // dies with "cannot change to … No such file or directory". Only a probe
    // that answered "gone" drops the path: an absent field is UNKNOWN, and
    // the brief keeps what the engine recorded.
    const swept = g.target_worktree_exists === false
    const worktree = (!swept && typeof t.worktree === 'string') ? t.worktree : ''
    if (!sha && !worktree) return null
    return { sha, worktree }
}

// Some gate steps decide ONE held finding cluster out of several, and only
// `step show` names which — `gate status` does not carry it. The engine
// mints those rows as `<name>-held@N#k`, so the instance grammar says when
// the read is worth spending; ordinary gates never pay for it. The
// assignment is a flat four-field object, projected by jq and returned
// through a schema; anything short of all four fields yields null and the
// brief renders unchanged — without the note, seats grep the repo and the
// event log to learn which cluster they are deciding.
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

Return the printed object through the structured output, field for field —
copy, never summarize; add no field the output did not carry and fill none
in. If the command errors, return {error: <the error text verbatim>} and
nothing else.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution. Your usage is wave overhead. This read serves
${step}, which is the step it READS, not a step you run — the usage join must
not attribute your tokens to it.`
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
        return agent(heldClusterBrief(step), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: 'haiku',
            effort: 'low',
            schema: HELD_CLUSTER_SCHEMA,
        }).then(parseHeldCluster)
    }
    return retrying(label, acct, once, null)
}

// Assemble a gate's SUCCESS result. A vote row whose tally succeeds after
// agent-level noise (a seat re-spawn, a probe resubmission, a dead probe)
// must not read as failed: one past run's completion notification carried
// "[STEP-N · gate:tally] failed: ..." BESIDE the same step's trusted
// gate-passed verdict — exactly the shape a conductor misreads as a failed
// gate. So the success result carries seat/probe/retry accounting
// explicitly, and every absorbed error as a NOTE naming the tally's
// success — never as a failure. Failure outcomes (gate-rejected/-blocked/
// -parked) deliberately do NOT come through here: their errors are real.
//
// SEATS AND PROBES ARE COUNTED SEPARATELY. A single "N spawns for M seats"
// total conflated the judges with the read-only haiku probes the gate path
// spends on its own bookkeeping: a real 3-judge panel logged "8 spawns for 3
// seats", and an auditor checking the seat count against the row's roster
// saw 8 vs 3. Worse, an ALREADY-DECIDED gate seats no panel at all and
// logged "1 spawn for 0 seats" — a judge on an empty panel. So the seats
// clause is emitted ONLY when a panel was actually seated; with no panel the
// line reports probes and retries alone.
function gateSuccess(step, text, acct) {
    const n = (count, one, many) => `${count} ${count === 1 ? one : many}`
    const parts = []
    if (acct.seats > 0) parts.push(n(acct.seats, 'seat', 'seats'))
    parts.push(n(acct.probes, 'probe', 'probes'))
    parts.push(n(acct.retries, 'retry', 'retries'))
    const res = {
        step,
        status: 'gate-passed',
        text,
        spawn_accounting: parts.join(', '),
    }
    if (acct.absorbed.length > 0) {
        res.notes = acct.absorbed.map((e) =>
            `absorbed agent-level error (superseded in-wave; the tally ` +
            `SUCCEEDED — NOT a failure of this step): ${e}`)
    }
    return res
}

async function runGate(row, phaseLabel) {
    // Seat/probe accounting for THIS gate, counted in SEPARATE buckets:
    // `seats` is the judge panel (what the row's roster promised), `probes`
    // is every read-only haiku spawn the gate path spends on its own
    // bookkeeping. Seat re-spawns and probe resubmissions are retries;
    // agent-level errors land in `absorbed` and ride the SUCCESS result as
    // notes (gateSuccess above).
    const acct = { seats: 0, probes: 0, retries: 0, absorbed: [] }
    const status = (label) => gateStatus(row.step, `${row.step} · ${label}`, phaseLabel, acct)
    const asText = (g) => JSON.stringify(g)

    // The ballot: record-driving opened the proposal when the gate's last
    // predecessor recorded — an earlier stage this wave already awaited — so
    // one read normally finds it, and says at once whether the gate was
    // decided before the wave reached it.
    const gate = await status('gate:status')
    if (!gate) {
        log(`${row.step}: gate:status probe returned nothing — the gate's state ` +
            `is UNKNOWN; skipping this issue's later stages this wave, and the ` +
            `conductor reads \`docket gate status ${row.step}\` itself`)
        return { step: row.step, status: 'gate-blocked', text: '' }
    }
    // A vote step's STATUS cannot carry the verdict: the engine records a
    // REJECTED vote as `done` when its on_fail routes machine-side (measured
    // three runs: 0-3-0 tallies rendered "gate-passed" and the conductor
    // believed it). The envelope's `outcome` IS the tally.
    if (gateDecided(gate)) {
        if (gate.outcome === 'rejected') {
            log(`${row.step}: gate already decided REJECTED (${gate.proposal}) — ` +
                `engine routes on_fail; skipping this issue's later stages`)
            return { step: row.step, status: 'gate-rejected', text: asText(gate) }
        }
        if (gate.step_status === 'skipped' || gate.step_status === 'superseded') {
            // No proposal was ever tallied here — the engine bypassed voting
            // entirely, so `gate-passed` would read as an approval that never
            // happened (the exact misread a conductor made on a security
            // tribunal that never sat).
            log(`${row.step}: gate step ${gate.step_status} by the engine, no ` +
                `tally — reporting gate-skipped`)
            return { step: row.step, status: 'gate-skipped', text: asText(gate) }
        }
        log(`${row.step}: gate already decided — continuing`)
        const early = gateSuccess(row.step, asText(gate), acct)
        // No panel was seated on this row, so the accounting carries no seats
        // clause at all — reading "0 seats" here made an already-decided gate
        // look like a judge on an empty panel.
        log(`${row.step}: no panel seated — ${early.spawn_accounting}` + (early.notes ?
            ` — ${early.notes.length} agent-level error(s) absorbed (NOT failures for this step)` : ''))
        return early
    }
    // A gate with NO proposal means the predecessors have not all recorded:
    // the gate is blocked, its issue's later rows do not launch this wave,
    // and the next round routes whatever on_fail produced. That is NOT
    // necessarily a failure upstream — the engine can mint a held-cluster
    // panel step between the gate and its `after` predecessor, leaving a
    // healthy predecessor mid-progress. Only `step show` carries the engine's
    // own `blocked_reason`, which the ladder reads off this result to pick
    // "deferred" over "died"; that read is spent here alone, on the one path
    // that needs it.
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
    const held = HELD_INSTANCE_RE.test(row.instance || '')
        ? await heldCluster(row.step, `${row.step} · gate:held-cluster`, phaseLabel, acct)
        : null
    // Name the round's target ref in every seat's brief. Seats are NOT seated
    // on the checkout the round was written in — writers work in private
    // worktrees — so without this a judge reads its own lagging HEAD, finds
    // the change absent, and rejects on evidence grounds, which no fix loop
    // can answer. The envelope carries it, or nothing does.
    const target = gateTarget(gate)
    log(`${row.step}: ${voteId} — seating ${seats.map((s) => s.seat).join(', ')}` +
        (target ? ` on target ${target.sha || '(no sha)'}${target.worktree ? ` (${target.worktree})` : ''}`
                : ` with NO target ref on the gate — seats read their own HEAD`))
    acct.seats = seats.length
    // The panel is seated by ONE workflow-nesting level into tribunal.js,
    // passing `step` so it renders the mid-wave brief (target ref, held
    // cluster, context-bundle navigation) instead of its conversational one.
    // A throw (unreadable scriptPath, tribunal's own arg refusal, a child
    // syntax error) must not crash the whole wave — it settles this row
    // gate-blocked with the error text, same as any other unreadable gate.
    const seatPanel = (panelSeats, isRespawn) =>
        workflow(args.tribunal, {
            voteId, gateKind: row.instance, cwd: args.cwd,
            voters: panelSeats.map((s) => ({ seat: s.seat, model: s.model, effort: s.effort, variant: s.variant })),
            step: { step: row.step, instance: row.instance, issue: row.issue, run: row.run },
            target, heldCluster: held, isRespawn: Boolean(isRespawn),
        }).then((res) => {
            for (const a of (res && res.absorbed) || []) {
                const label = `${row.step} · seat:${a.seat}` + (isRespawn ? ' (retry)' : '')
                log(`${row.step} seat ${a.seat}: ${isRespawn ? 'respawn' : 'spawn'} error: ${a.error}`)
                acct.absorbed.push(`[${label}] ${a.error}`)
            }
            return res
        }).catch((err) => {
            log(`${row.step}: tribunal panel spawn error: ${err}`)
            for (const s of panelSeats) {
                const label = `${row.step} · seat:${s.seat}` + (isRespawn ? ' (retry)' : '')
                acct.absorbed.push(`[${label}] ${reasonText(err) || String(err)}`)
            }
            return null
        })
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
        log(`${row.step}: ${res.spawn_accounting}` + (res.notes ?
            ` — ${res.notes.length} agent-level error(s) absorbed (NOT failures for this step)` : ''))
        return res
    }
    log(`${row.step}: gate did NOT clear (${after.step_status}, tally ${after.outcome}) ` +
        (missing.length > 0 ? `after re-seating ${missing.map((s) => s.seat).join(', ')} ` : '') +
        `— skipping this issue's later stages; the conductor escalates`)
    return { step: row.step, status: 'gate-parked', text: asText(after) }
}
// TEST-END gate-vote

// The round's target ref for the fix-round ancestry guard below. Context
// assembly lifts the resolved `issue.diff` artifact's round record onto the
// bundle as `target_sha` (the commit the diff's tree stood at) and
// `target_worktree` (the producing record's declared checkout); both are
// omitted when the resolved diff carries no round record, so ABSENCE IS
// NORMAL and yields null rather than a throw.
//
// The probe reduces rather than dumping the bundle: `step context` inlines
// every recorded input artifact, and a findings artifact runs to 1MiB. jq
// walks the whole bundle, so it finds both fields wherever they sit.
//
// NEVER HAND A SEAT AN EMPTY RESULT TO RELAY. This used to be a `grep -Eo`
// whose ONLY output on a bundle with no round record was nothing at all — and
// a probe told to "return the output VERBATIM" with no output to return is a
// void the model fills. On one run the haiku probe's own thinking read "since
// there's no output and no error, I should return nothing", and it then
// replied with a 40-hex sha present in no repository and no transcript but
// its own reply; three opus judges spent calls hunting the phantom commit.
// The same probe on the same empty result behaved three different ways
// across one run (silent, fabricating, and chatty): the model behaviour is
// weather, the empty verbatim result is the defect.
//
// So the command PRINTS AN ENVELOPE EITHER WAY — `{"target_sha":null,
// "target_worktree":null}` when the bundle carries no round record — and the
// reply is parsed STRUCTURALLY (JSON.parse of that envelope), never by
// regex over free text. Anything that is not the envelope, including the
// empty string, is "no target".
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

// Read the envelope. Returns {parsed, target}: `parsed` says the reply WAS
// the envelope (so the caller can log a non-envelope reply as such rather
// than as an absent target), `target` is null unless the envelope named at
// least one non-empty string field. A probe's text can carry a harness banner
// ahead of the JSON (seen on two probes), so slice between the outermost
// braces before parsing — that is still a structural read of one object, not
// a field-level regex over prose.
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

// ---------------------------------------------------------------------------
// FIX-ROUND BASE ANCESTRY. The conductor integrates a fix round by
// cherry-picking the sha on the change-summary's first line onto the shared
// branch; the next round's fix worktree is cut from that branch's HEAD, so
// the tree the next review fanout judges must DESCEND from the integrated
// commit. Nothing verified that, and twice the hand-off broke a round late:
// RUN-35 round 2 — all five judges found round-1's commit was not
// an ancestor of the judged commit and re-filed two defects round 1 had
// closed (17.37M tokens re-finding closed work); RUN-51 rounds 5-6
// — fix@5's worktree was a SIBLING of round 4's commit, two full review
// rounds spent detecting and repairing the fork.
//
// So the wave asserts the ancestry BEFORE the fanout spawns — the same check
// the judges already ran one round too late — and parks the round as a RELAY
// finding ('parked-base-ancestry', chain-dead for the issue) instead of
// seating judges on a tree that cannot contain the prior round's fix.
//
// THE SHA IS THE INTEGRATED ONE, AND ONLY THE CONDUCTOR HOLDS IT: integration
// cherry-picks, so the WRITER's sha is never an ancestor of the shared branch
// even after its content lands — asserting on it would park every healthy
// round. The conductor passes `args.integrated`, mapping each issue with a
// fix round in this dispatch to the sha of the PRIOR round's integration
// commit — the integration of the write step the judged tree was BUILT ON,
// which for a review@N fanout is fix@(N-1)'s integration (or implement's when
// N-1 is the implement round), NEVER fix@N's own (docket-run/SKILL.md,
// "Worktree writers" — the other half of this contract). Absent map, absent
// entry, non-sha entry, no round fanout, round 1, missing target on the
// bundle, dead or unparseable probe — every one of these FAILS OPEN to the
// old behavior: the guard exists to stop a measured waste, never to add a new
// way for a healthy round to stall.
//
// AND THE MAP ITSELF CAN NAME THE WRONG ROUND (DOT-1022). When fix@N and its
// review@N#k fanout are SPLIT across dispatches — a /pause, a wave that ended
// between them, a budget stop — fix@N is already integrated by the time the
// conductor derives the map, and "most recent integration" reads as fix@N's
// own commit: the cherry-pick OF the judged tree. A cherry-pick can never be
// an ancestor of its source, so the merge-base exits 1 on every HEALTHY round
// in that shape (RUN-66 DISPATCH-360: 18 of 28 rows lost to it). So before
// parking, self-check the map entry — if `prior` carries a `cherry picked
// from commit <target>` trailer it IS the judged round's own integration and
// the verdict is worthless: fail open and dispatch.
// TEST-BEGIN fix-round-ancestry — extracted and exercised by
// tests/wave-fix-round-ancestry.test.sh (and concatenated ahead of the
// stage-ladder region by tests/wave-chain-dead-ladder.test.sh, whose ladder
// calls into it). Keep everything between the markers free of workflow
// globals (agent, probe, log, args) so it stays evaluable on its own.
//
// ONE declared dependency on another region: the target read shares the gate
// path's command and reader (`target-envelope`, nested inside `gate-vote`),
// so every suite that extracts THIS region prepends that one.

// A fix round's REVIEW FANOUT: the engine mints per-round step instances as
// `name@N`, with `#k` on fanout siblings (roundHops above reads the same
// grammar). Only fanout rows (`@N#k`) are guarded: they are the judge seats,
// a write row (`fix@N`, no `#k`) is what CREATES the round's tree, and
// per-round singletons behind the fanout (synthesize@N) die with the chain
// when the fanout parks. Round 1 reviews the initial implement — there is no
// prior fix round to contain — so the guard starts at round 2.
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

// The judged tree: context assembly lifts the resolved issue.diff round
// record onto the bundle as `target_sha`, read through the envelope above
// (readTargetEnvelope), narrowed to the sha half because the ancestry check
// has no use for the worktree path.
//
// An empty relay here has a worse blast radius than a misleading brief: an
// invented sha resolves nowhere, `git merge-base --is-ancestor` exits
// non-zero on it, and the guard PARKS a healthy fix round's whole judge
// fanout. So the command prints `{"target_sha":null,"target_worktree":null}`
// when the field is absent and the reply is parsed structurally; anything
// that is not that envelope is "no target" and fails open, exactly as an
// absent field always did.
function parseAncestryTargetSha(text) {
    const target = parseTargetRef(text)
    const sha = target ? target.sha : ''
    return ANCESTRY_SHA_RE.test(sha) ? sha : ''
}

// One read-only probe carrying both directions of the evidence the RUN-35
// judges recorded: the merge-base exit status (0 = the judged tree contains
// the prior round's integrated commit) and the branch containment listing.
// Every worktree shares one object store, so both commands resolve from the
// shared checkout the probe runs in.
function ancestryProbeCommand(prior, target) {
    return `git merge-base --is-ancestor ${prior} ${target}; ` +
        `echo "ancestry-exit=$?"; git branch -a --contains ${prior}`
}

function parseAncestryExit(text) {
    const m = (text || '').match(/ancestry-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// SELF-CHECK ON THE MAP ENTRY (DOT-1022). A non-zero merge-base is only
// evidence of a broken hand-off if `prior` is the round BEFORE the one being
// judged. When the conductor derived the map after fix@N had already been
// integrated (the fanout split off into a later dispatch), `prior` is the
// cherry-pick OF `target` — it post-dates the judged tree by construction and
// no healthy tree can ever contain it. Integration cherry-picks with `-x`, so
// that relationship is readable straight off the commit message trailer. Grep
// is `-q`, so the exit marker alone carries the answer: 0 = `prior` is the
// cherry-pick of `target` = wrong round in the map. Both shas are already
// hex-shape-checked before they reach a command line.
function cherryPickOfTargetCommand(prior, target) {
    return `git log -1 --format=%B ${prior} | ` +
        `grep -q "cherry picked from commit ${target}"; ` +
        `echo "cherrypick-of-target-exit=$?"`
}

function parseCherryPickOfTargetExit(text) {
    const m = (text || '').match(/cherrypick-of-target-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// The parked round, as a RELAY finding: the report names what broke, carries
// the probe evidence verbatim, and says what the conductor does about it —
// exactly what five judges per round were re-deriving. chainDead() reads the
// status, so the issue's later rows die with the fanout this wave, and the
// engine re-offers the round's steps after the tree is repaired.
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

// PER-ISSUE LANES, WITH THE ENGINE'S CROSS-ISSUE COHORTS HONORED FROM THE
// MANIFEST ITSELF. The engine's `stage` labels carry two different things at
// once (engine lookahead.go):
//
//   1. DEPENDENCY ORDER, which is SAME-ISSUE ONLY. `after` predecessors,
//      loop re-entry (precedesInSet refuses a cross-issue pair outright)
//      and open interposed gates all live inside one issue's workflow. A
//      cross-issue `depends_on` never reaches a manifest at all: the closure
//      stops at an unsatisfied one ("cross-issue edges resolve at issue
//      completion, which is rollup work no single wave owns"), so a row is
//      offered only once its issue's dependencies are already met, and no
//      manifest row carries a dependency field to inspect.
//   2. COHORT PACKING, which IS cross-issue. Within one stage a bounded
//      class holds at most `[limits] max` rows and tree-holding steps of
//      different issues must have disjoint scopes; a staged row that does
//      not fit its earliest legal stage is bumped later. That coupling is
//      what the first per-issue lanes broke — they ran the bumped row
//      concurrently with the writer it was bumped away from and bounced it
//      off `claim` — and why a global ladder replaced them.
//
// The global ladder honored (2) by making every issue wait for every other
// issue at every stage: measured on one run as an issue's judges idling
// ~12 minutes behind two unrelated implements and a park. This ladder keeps
// (1) per issue — a LANE ascends its own stage labels with an await between
// — and honors (2) from what the manifest proves:
//
//   - CLASS HEADROOM. The engine put at most `max` rows of a bounded class
//     into any one stage (ClaimablePrefix for ready rows, cohortFits for
//     staged ones), so the largest same-stage count of a class in this
//     manifest is a proven lower bound on its limit. The wave never has more
//     rows of a class in flight than that count, whichever stages they came
//     from. An unbounded class is under-used by the rule, never
//     over-committed.
//   - SCOPE. Two writers the engine co-staged were checked against each
//     other, and scope is a property of the ISSUE, so one co-staged writer
//     pair proves the two issues' scopes disjoint (or empty) for every
//     writer either issue owns. A writer launches ahead of another issue's
//     in-flight writer only on that proof; without it the pair keeps the
//     engine's stage order between them, and the log says so. "Writer" is
//     `class: "write"` — the corpus's tree-holding class; every other
//     executor step in the corpus declares `holds_tree = false` and is exempt
//     from R4 engine-side. This is the one place the ladder leans on corpus
//     convention rather than engine data: a step holding a tree under some
//     other class would be scope-serialized by the engine and not by the
//     wave, and would bounce on claim.
//
// A park is still RUN-WIDE: the engine refuses every claim while the run is
// not active (R1 is the first readiness clause and `claim` re-checks it), so
// once a park is observed no lane launches anything further — rows waiting
// for admission settle `not-launched-run-parked`, in-flight rows finish. A
// CONFLICT, a failed spawn, or an uncleared gate still kills only its own
// issue's later rows.
// TEST-BEGIN stage-ladder — extracted and exercised by
// tests/wave-chain-dead-ladder.test.sh, tests/wave-fix-round-ancestry.test.sh
// and tests/wave-issue-lanes.test.sh, which wrap this whole region in an
// async function and feed it stub `parallel`/`spawn`/`runGate`/`probe`/`log`
// globals. Everything the ladder itself needs must stay INSIDE the markers;
// the only workflow globals it may reach for are those stubs, `rows`,
// `input`, and the fix-round-ancestry region's helpers (the suites
// concatenate that region ahead of this one).
const stageOf = (row) => (Number.isInteger(row.stage) ? row.stage : 0)
const stages = new Map()
for (const row of rows) {
    const s = stageOf(row)
    if (!stages.has(s)) stages.set(s, [])
    stages.get(s).push(row)
}
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
    // ...and name the ones it is NOT armed for (DOT-1048). Fail-open is
    // right, silence is not: a round-2 fanout with no `integrated` entry
    // used to leave NO line in the log, so the guard's absence looked
    // identical to a wave that had no fix round in it. RUN-63 DISPATCH-364
    // read the skill's carve-out ("no integration yet for an issue") as "no
    // integration window yet for THIS round", omitted the map on a round-2
    // fanout whose round 1 HAD been integrated, and nothing said so. One
    // line per issue, at the top of the wave, so the omission is visible at
    // close.
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
// superseded/unclaimable by the time their stage arrives (the predecessor
// held or was rejected) — a blind spawn there dies on claim CONFLICT, an
// opus corpse per occurrence (measured: 17 across 4 runs). Probe those
// rows with the same cheap read the gate path uses; skip the spawn when
// the step is no longer claimable. Fail-open: an empty probe spawns.
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

// The fix-round base-ancestry guard (helpers above the ladder). One
// verdict per issue-round, shared by every fanout sibling: two cheap
// read-only probes decide whether the fanout spawns — the round's target sha
// off the bundle, then the merge-base check. The probes run AT THE ROW'S OWN
// STAGE, after its lane's earlier stages settled, so the bundle's round
// record is live. Every uncertain outcome resolves null (fail-open); only a
// positively parsed non-zero merge-base exit parks.
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
            // Before parking: is the map entry even the right round? A
            // `prior` that is the cherry-pick OF `target` is fix@N's own
            // integration, which cannot be an ancestor of the tree it was
            // taken from — the verdict says nothing about the hand-off.
            // Unparseable or dead self-check probe keeps the park (the
            // original evidence still stands).
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
// A park observed anywhere stops every lane's LATER launches (in-flight rows
// finish; the engine re-offers unlaunched steps after the park lifts). A
// CONFLICT, a failed spawn, or an uncleared gate kills only its own ISSUE's
// later rows — the chain behind it cannot become claimable this wave, and
// spawning it anyway boots corpses.
let parked = false
// issue -> { step, status, deferral }: WHICH row stopped the lane, and whether
// the engine said the lane is merely waiting (deferral is the blocked_reason
// text) or something actually failed (deferral null). The skip log picks its
// wording off this — see chainDeferral below.
const deadIssues = new Map()

// TEST-BEGIN chain-dead — see the park-signals note above.
function chainDead(res) {
    if (res == null) return false
    if (res.status === 'gate-parked' || res.status === 'gate-blocked' ||
        res.status === 'gate-rejected' || res.status === 'skipped-not-claimable' ||
        res.status === 'skipped-not-ready') return true
    // A stage-N executor that never produced an agent leaves its step
    // unrecorded, so every later `after` row of the same ISSUE is guaranteed to
    // die on claim ("an `after` predecessor is not done"). One past run spent
    // ~52K tokens booting three such corpses. The engine re-offers the whole
    // chain at the next dispatch, so calling the issue dead here loses nothing.
    if (res.status === 'spawn-failed') return true
    // A diagnosed claim CONFLICT is the SAME dead chain it always
    // was — only the report changed. It carries its own status precisely so
    // the kill does not ride on the report's text staying inside
    // isConflictReport()'s three-line budget, which the diagnosis exceeds.
    if (res.status === 'claim-conflict') return true
    // A fix round parked on broken base ancestry. The judged tree
    // does not contain the prior round's integrated commit, so every later
    // per-round row of the issue (synthesize@N, verify@N) would work the
    // same wrong tree.
    if (res.status === 'parked-base-ancestry') return true
    // A step that parked its own issue (the mandated tail): every later row
    // of that issue is refused by the engine's R2b until the operator rules,
    // so launching one buys a corpse. Other lanes are untouched.
    if (laneParked(res)) return true
    // Same body-scan trap as runParked: `includes('CONFLICT')` would kill an
    // issue's whole remaining chain on a judge that merely REPORTED one.
    return res.status === 'returned' && isConflictReport(res.text)
}

// A CHAIN-DEAD LANE IS NOT THE SAME AS A DEAD CHAIN (DOT-1050). chainDead()
// answers one question — do NOT launch this issue's later rows this wave — and
// two very different situations answer it yes. Something failed (a spawn that
// produced no agent, a claim CONFLICT, a rejected gate, a broken base
// ancestry); or nothing failed at all and the engine has simply not made the
// row claimable yet, because a predecessor is still progressing. RUN-63 hit
// the second shape four waves running: the engine minted a held-cluster panel
// step between a gate and its `after` predecessor, the gate had no proposal to
// seat on, and the wave logged "this wave's chain died at an earlier stage" —
// while that predecessor was recording, holding its step and opening its vote,
// exactly as designed. An operator reading "died" reaches for a repair that
// does not exist.
//
// The engine already distinguishes the two and says so in the row it hands
// back: `blocked_reason` on `step show --json` names the §6.3 readiness clause
// holding a `pending` step back (docket internal/engine/next.go BlockedReason,
// internal/engine/ready.go ReadyCondition). Every clause below describes a step
// that is WAITING; the engine re-offers it at the next dispatch untouched. The
// two conditions deliberately NOT listed are failure-adjacent and keep the
// "died" wording: `run is not active` (the run parked — the wave's own park
// path owns that) and `the step is not pending` (the row is already terminal,
// so nothing is coming).
const PROGRESSING_BLOCKS = [
    'an `after` predecessor is not done',
    'no threshold has routed to this interposed step',
    'an interposed gate on a predecessor has not resolved',
    "the issue's dependencies are not satisfied",
    'its scope conflicts with a claimed or running step',
    'no concurrency headroom in its class',
    'no budget headroom',
]

// Returns the engine's blocked_reason when the result carries one naming a
// still-progressing predecessor, else null. Null is the SAFE answer: an absent
// field, an unparseable payload, a reason the engine added after this list was
// written, or a status that is genuinely a failure all fall back to the
// original "chain died" wording. Under-claiming a deferral costs an operator
// one imprecise line; over-claiming one tells them to wait for a close that is
// never coming.
function blockedReason(res) {
    // Only statuses that can be reached with NOTHING having failed are
    // eligible. gate-rejected, spawn-failed, claim-conflict,
    // parked-base-ancestry and a CONFLICT report are failures whatever the
    // payload says; gate-parked is an uncleared gate the conductor escalates.
    if (res == null) return null
    if (res.status !== 'gate-blocked' && res.status !== 'skipped-not-claimable' &&
        res.status !== 'skipped-not-ready') return null
    if (typeof res.text !== 'string') return null
    const m = res.text.match(/"blocked_reason"\s*:\s*"((?:[^"\\]|\\.)*)"/)
    if (!m) return null
    const reason = m[1].replace(/\\(.)/g, '$1')
    return PROGRESSING_BLOCKS.includes(reason) ? reason : null
}
// TEST-END chain-dead

// ---- lanes: one per issue, an issue-less row riding a lane of its own ----
const laneOf = (row) => (row.issue ? String(row.issue) : `row:${row.step}`)
const lanes = new Map()
for (const row of rows) {
    const l = laneOf(row)
    if (!lanes.has(l)) lanes.set(l, [])
    lanes.get(l).push(row)
}
log(`wave: ${lanes.size} issue lane(s): ` + [...lanes.entries()].map(([name, laneRows]) => {
    const ks = [...new Set(laneRows.map(stageOf))].sort((a, b) => a - b)
    return `${name}×${laneRows.length}${ks.length > 1 ? ` (stages ${ks.join('→')})` : ''}`
}).join(', '))

// ---- what the manifest certifies about cross-issue concurrency ----
// The launch path treats every row that is neither an action nor a vote as
// an executor; the cohort arithmetic reads the same set, so a row without
// `kind` is reserved exactly as it is spawned. The engine keys class headroom
// on the row's `class`, defaulted to the executor hint at expansion (workflow
// validate.go) — mirror that default so a row rendered without the field
// lands in the bucket the engine actually counted.
const isExecutorRow = (row) => row.kind !== 'action' && row.kind !== 'vote'
const classOf = (row) => (typeof row.class === 'string' && row.class !== '')
    ? row.class
    : (typeof row.executor === 'string' ? row.executor : '')
const isWriter = (row) => isExecutorRow(row) && classOf(row) === 'write'
const pairKey = (a, b) => (a < b ? `${a} ${b}` : `${b} ${a}`)
const certifiedClass = new Map()   // class -> largest same-stage count
const scopePairs = new Set()       // lane pairs with writers co-staged
for (const group of stages.values()) {
    const perClass = new Map()
    const writerLanes = new Set()
    for (const row of group) {
        if (!isExecutorRow(row)) continue
        const c = classOf(row)
        perClass.set(c, (perClass.get(c) || 0) + 1)
        if (isWriter(row) && row.issue) writerLanes.add(laneOf(row))
    }
    for (const [c, n] of perClass) {
        if (n > (certifiedClass.get(c) || 0)) certifiedClass.set(c, n)
    }
    const ws = [...writerLanes]
    for (let i = 0; i < ws.length; i++) {
        for (let j = i + 1; j < ws.length; j++) scopePairs.add(pairKey(ws[i], ws[j]))
    }
}
const scopeCertified = (a, b) => a === b || scopePairs.has(pairKey(a, b))
if (lanes.size > 1) {
    log(`wave: lanes run concurrently; the manifest certifies class headroom ` +
        [...certifiedClass.entries()].map(([c, n]) => `${c || '(no class)'}≤${n}`).join(', '))
    const writerLanes = [...new Set(rows.filter((r) => isWriter(r) && r.issue).map(laneOf))]
    const unproven = []
    for (let i = 0; i < writerLanes.length; i++) {
        for (let j = i + 1; j < writerLanes.length; j++) {
            if (!scopeCertified(writerLanes[i], writerLanes[j])) {
                unproven.push(`${writerLanes[i]}/${writerLanes[j]}`)
            }
        }
    }
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
// The Workflow tool documents its own agent() concurrency cap as
// min(16, CPUs-2) per launch — this script cannot read the machine's CPU
// count, so 16 is the loosest bound it can assert, and on a machine under 18
// cores the real cap is tighter than this. A row that clears admission() but
// then queues behind that harness cap was launching into a park the wave had
// already observed: 21 judge agents once queued minutes ahead of a mid-wave
// park and all started into it, each settling on a claim refusal 10-20s
// later. Bounding admission itself to this cap keeps the queue in `waiting`,
// where pump() already flushes it not-launched-run-parked the moment a park
// lands — the fix belongs here, not at the agent() call site: nothing in a
// workflow script runs between the harness dequeuing a call and that call's
// body starting, so a check placed there would see the park too late to
// matter.
const HARNESS_CAP = 16
function blocker(row) {
    if (!isExecutorRow(row)) return null
    if (inFlight.size >= HARNESS_CAP) {
        return `${inFlight.size} row(s) in flight — the harness runs at most ` +
            `${HARNESS_CAP} agents concurrently`
    }
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
// Deterministic and synchronous: lowest stage first (the engine's own order,
// so the global ladder is what falls out wherever nothing is certified), then
// submission order. Every admission changes the in-flight set, so the scan
// restarts from the top. Single-threaded event loop; nothing here awaits.
function pump() {
    waiting.sort((a, b) => stageOf(a.row) - stageOf(b.row) || a.seq - b.seq)
    let i = 0
    while (i < waiting.length) {
        const w = waiting[i]
        if (parked) {
            waiting.splice(i, 1)
            w.resolve(false)
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
        if (isExecutorRow(w.row)) inFlight.set(w.row.step, w.row)
        if (w.held) log(`${w.row.step}: released — launching`)
        w.resolve(true)
        i = 0
    }
}
// Resolves true to launch, false when the run parked while the row waited.
function admission(row) {
    return new Promise((resolve) => {
        waiting.push({ row, seq: submitted++, resolve, held: false })
        pump()
    })
}
function release(row) {
    if (inFlight.delete(row.step)) pump()
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
            return probe(`docket step show ${row.step} --json`,
                `${row.step} · pre-claim`, label, row.step).then((show) => {
                // Skip only on a positively recognized status the wave
                // cannot act on; empty output, prose, and anything
                // unrecognized all spawn (fail-open). `pending` belongs
                // in that set HERE and only here: this probe runs after
                // the row's lane awaited and settled its earlier stages,
                // and admission excludes this wave's own cohort pressure,
                // so nothing left in this wave can advance the step to
                // `ready`. A pending row is dead for the wave — spawning
                // it burns an executor that dies on claim CONFLICT, and
                // the engine re-offers it next dispatch.
                const term = show.match(/"status"\s*:\s*"(done|superseded|skipped|failed|pending)"/)
                if (!term) return spawn(row, label)
                log(`${row.step}: not claimable (${term[1]}) — a same-issue ` +
                    `gate or action upstream left it unreachable for this ` +
                    `wave; skipping the spawn`)
                return { step: row.step, status: 'skipped-not-claimable', text: show }
            })
        }
        return spawn(row, label)
    }
    // A fix round's review fanout is asserted against the prior
    // round's integrated commit BEFORE the judges spawn (ancestryVerdict
    // above; one shared verdict per issue-round). A broken ancestry parks
    // the round as a relay finding; anything short of a positively
    // broken read launches exactly as before.
    if (needsAncestryCheck(row, input.integrated)) {
        return ancestryVerdict(row, label).then((broken) =>
            broken ? ancestryParkReport(row.step, broken) : launchRow())
    }
    return launchRow()
}

async function runLane(name, laneRows) {
    const byStage = new Map()
    for (const row of laneRows) {
        const s = stageOf(row)
        if (!byStage.has(s)) byStage.set(s, [])
        byStage.get(s).push(row)
    }
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
                    : `${row.step}: skipped — this wave's chain died at an earlier ` +
                      `stage (the issue itself is untouched)`)
                return false
            }
            return true
        })
        if (group.length === 0) continue
        const label = `${name} stage ${k} (${group.length} row${group.length === 1 ? '' : 's'})`
        const settled = await parallel(group.map((row) => () => {
            if (row.kind === 'action') {
                // Engine-run, and normally already DONE: the record of its
                // last predecessor drove it (engine drive.go) before that
                // record returned. Nothing to spawn; the row is in the
                // manifest so the stage numbering stays transparent.
                log(`${row.step}: action step — engine-run at record time, no spawn`)
                return Promise.resolve({ step: row.step, status: 'engine-run', text: null })
            }
            return admission(row).then((go) => {
                if (!go) {
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
        }))
        settled.forEach((res, i) => {
            const row = group[i]
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
        })
    }
}

await parallel([...lanes.entries()].map(([name, laneRows]) => () => runLane(name, laneRows)))

return rows.map((row) => byStep.get(row.step) ||
    { step: row.step, status: parked ? 'not-launched-run-parked' : 'spawn-failed' })
// TEST-END stage-ladder
