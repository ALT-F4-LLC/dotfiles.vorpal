# Escalating to the operator

Consumer: the docket-run skill, whose **Gates** section points here. Read
this file in full before presenting any gate, park, or question to the
operator. The panel mechanics and the three standing rulings stay in the
skill body; this file governs everything the operator is asked: what a
question carries, how a ruling is scoped and routed, and which answers
the engine's verbs can honor.

**Every non-approval arrives with the panel's reasoning:** the tally and
every judge's verdict, confidence, and one-line summary, not a count or
your paraphrase, plus the panel's recommended correction where it named
one. A below-threshold vote on an engine vote step parks itself by its
`on_fail`; you present the park, not park or un-park it. One whose
`on_fail` routes machine-side (`fix-loop`) is not an operator gate at
all: carry it into your status report, not a question. Present the thing
being decided alongside the tally: the diff, the finding summary, the
numbers. "Step 12 needs approval" is not a gate, it is a rubber stamp.

**The artifact a question is framed from is read in full**, no `head`,
`tail`, or byte cap, since the window you can see is not the tally.
Where an artifact is too large to quote, summarize from its own tally,
never from the slice you happened to render.

**A fix-round gate past the workflow's `max_fix_loops` presents the
loop, not the round.** On a `--as fix-round` authorization past the cap,
the artifact includes a loop-history line beside the rejection text,
carrying five fields, each a read verb away:

- **Rounds run against the cap**: "round 9 of a loop capped at 3." Cap
  from `docket workflow show <name>@<version> --source` (pinned version
  in `run report`'s "Pinned workflows" block); round from `loop-entered`'s
  `ordinal=N` in `docket events list --run $RUN`.
- **Consecutive rejections, listed by proposal id**, not a count, from
  `run report`'s "How steps ended."
- **Fixer and judge variants actually served.** Routing from pinned
  policy.toml's `[executors]`/`[variants]`; what actually ran from the
  journal's `agent-<agentId>.meta.json` `model`; `run report` totals both.
  Report the resolved variant, since round-based escalation may have
  moved it.
- **Spend against budget, including every raise**: `run report`'s
  Budget block plus each `run-budget-set` event's `from=`/`to=`/`reason=`.
- **Finding-volume trend across rounds**, cluster and blocker counts from
  each round's aggregate artifact (`docket step artifacts STEP-N`, then
  `docket step artifact ARTIFACT-N --payload`). Note when consecutive
  rounds show flat cluster and blocker counts (no workflow sets
  `max_stalled_rounds`; standard-change@37 declined it).

Assembling the line is your work; the engine computes every field. This
governs what the gate presents; **Standing ruling: a loop-bound park**
under **Gates** in the docket-run skill body decides whether the park is
yours to file and pass at all.

**The premise-check runs before the question, not only before a
filing.** The scope-read you do before creating an issue tells you
whether the recommendation is already contradicted by a recorded ruling.
A question an existing ruling has already answered costs the operator
twice. Run the check first, and carry what it found into the question.

**"Tracked by <ID>" is a claim with a status, and you read the status
before you relay it.** Run `docket issue show <id>` and put its current
state beside the claim in the question itself; a closed or missing
tracker is a gate-relevant fact, not bookkeeping to tidy afterward.

A gate that passes over a reject or a concerns cast is not finished when
you relay it: link the proposal to the downstream issue(s) (`docket vote
link <proposal-id> --issue <successor>`) so the record carries the
dissent, not just this session's scrollback.

And read every seat's rationale on such a pass for a condition naming
later work. File each as its own issue (`docket issue create`, per the
gap-routing rule, always `-l tribunal`) before `dispatch close`, linked
to the proposal, id in the close report:

```bash
docket issue create -t "<condition>" -T task -p high -l tribunal \
  -f <file the condition touches> --scope '<glob bounding it>' -d - <<'DESC'
<the seat's rationale, verbatim — backticks and quotes intact>
DESC
```

`-l tribunal` lets a later census separate panel conditions from
everything else; `-l shadow` is never it. A condition living only in a
vote rationale, never filed, vanishes.

**When the park followed a step's gates, read the verdicts before you
present or characterize the outcome.** `docket step gates STEP-N --json`
carries verdict, exit, argv, duration, and `output_tail` on every
non-passing row (`--full` adds complete output). `step show` and `step
artifacts` do not carry this, and the event stream renders a pass and a
failure identically. Read exits too: a millisecond-fast `operation not
permitted` measured the sandbox, not the code, and presenting it as a
code failure invites an unreal override-pass. Present every gate through
the question tool, recommended option first, each answer's real routing
in its description, resolved from frozen definitions.

**One gate, one proposal, one question.** Never bundle distinct gates
into a shared proposal or question, even same-issue siblings, since a
bundled answer makes the ledger record one decision where several were
made.

**A gate disposition is scoped to the step it answered.** An
override-pass on STEP-N settles only STEP-N, however identical the next
park's root cause looks: a `waiting-human` park outside the three
standing rulings is always the operator's, and approval never extends
across contexts. Only a standing ruling or an answer whose own text
named a class carries further, exactly as far as that class.

So offer the class option at the first such gate instead of assuming it
at the second, when a park can plainly recur: "Override-pass this step
only (Recommended)" / "Override-pass this step and any recurrence of
this exact defect class for the rest of this run" / "Park and stop the
issue." Every recurrence still gets its own resolve verb, its own note,
and the durable fix issue the broken-check rule below requires. For a
later park identical to one already resolved this run with no
class-scoped answer covering it, ask once whether the resolution
extends.

**Keep shell and JSON literals out of the question text**, since nested
quotes and `$(...)` can be rejected outright. Put a command literal in a
fenced block in your message instead, with plain prose in the question.
Write the question in plain language; cluster ids and engine terms live
in your accompanying message.

**Scope and what-next questions go through the same tool.** "Want me to
pick up X, or leave it for now?" is a decision, not narration.

**A count you state to the operator is read off a surface, never
recalled**, the same rule the close report's pasted output carries. For
"how many waves so far," the surface is the session's own journal:

```bash
ls ~/.claude/projects/<cwd-slug>/<session-id>/workflows/*.json | wc -l
```

**A panel seated inside a wave is not a launch:** wave.js seats every
engine vote row itself with a proposal id but no `workflows/` entry;
only a panel you convened through a separate `Workflow({scriptPath:
…tribunal.js})` call is a launch.

On their answer:

```bash
docket step approve STEP-N --note "<their reasoning, their words>" < <scratchpad>/conductor.d/$RUN.token
docket step approve STEP-N --value <enum member> --note "<their words>" < <scratchpad>/conductor.d/$RUN.token
docket step reject  STEP-N --note "<their reasoning, their words>" < <scratchpad>/conductor.d/$RUN.token
docket step resolve STEP-N --as retry|skip|abandon-issue|override-pass --note "<why>" < <scratchpad>/conductor.d/$RUN.token
```

Which verb is the step's type, not your reading of the situation:
`approve`/`reject` exist only on `type="human"` gate steps; an executor
step parked `waiting-human` takes `resolve --as …` only. A vote step
parked by its `on_fail` follows the same rule. Resolving the parking step
on a rollup-parked run auto-resumes it in the same call; never follow
with `docket run resume` (CONFLICTs). Find and read a gate's artifact as
a pair of verbs: `docket step artifacts STEP-N` lists ids, `docket step
artifact ARTIFACT-N [--payload]` prints one (`--payload` only for a
structured payload). An engine-minted held-cluster row carries nothing
itself; its payload lives on the synthesize-findings/aggregate step's
artifact, a bare JSON list where `#N` is a 1-based index, not a cluster
id, confirmed against the aggregate's `held=[N]` field.

**Before `--as retry` on an executor step: is the rendered brief still
the spec?** A retry re-renders only the issue body and its inputs, so a
fresh executor treats mid-run operator rulings that live only in chat as
unreviewed drift and removes them. `docket step render STEP-N` first: if
rulings are missing, update the issue body and confirm the change
reaches the rendering (bodies snapshot at activation), resolve
`override-pass` with evidence if the work is already on the tree, or
route the ruling per the operator-ruling paragraph below.

**Reject is an escape hatch, not an annotation.** On a held-cluster gate,
`approve` falls through to the threshold; `reject` skips it and routes by
`on_fail`, usually parking, by design. The verdict is sticky: a retry on
the parked routing step re-parks. Present reject as "stop this issue and
ask me again."

**A held cluster has a third answer: correct the value.** `docket step
approve STEP-N --value <member>` overrides the aggregated field (severity
on a spec-doc hold) with an operator-named value from the pinned schema's
enum. Offer all three: approve computed, approve corrected, or reject.

**You never apply a hold ruling's content edit yourself; it routes to a
fix step.** All three hold answers decide the cluster's value, none
touches the tree. Present the pair: the value answer that routes the
loop, plus the fix round or its own issue that carries the edit. A
conductor editing directly produces a commit no step authored and no
judge read.

**A disposition that promises later work files the issue before you run
the verb.** Blocker-only convergence routinely schedules no further
round, so create the issue first, in its owning project, with the id in
the approval note and option text.

**`override-pass` records a generic pass; it evaluates and routes
nothing.** Steps interposed on that outcome (a tribunal gate after a
verify, a conditioned re-review) go `skipped` instead, with only a
post-mutation warning. Resolve interposed steps directly when their
condition should still apply, and read `docket next` / `step show`
afterward to see what the engine actually left standing.

**A gate that failed on the executor's own commit is answered with
`retry`; `override-pass` alone leaves the recorded diff on the failing
sha**, since the verb writes a pass without re-pointing the step at a
fixed tree (`step annotate --integrated-sha` does, once integrated; see
below). So a conductor patch under override-pass alone is invisible
downstream: the next dispatch carries the pre-patch sha as target, and
the panel reads the failing tree. Present `retry` as recommended (its
precondition is the rendered-brief check above); override-pass will
re-find the gate failure and open a fix round on a defect already fixed.

**If the operator rules the conductor patch anyway**, land it as its own
commit, integrate it, then re-point the step's record right here, not
deferred:

```bash
docket step annotate STEP-N --integrated-sha <patch's full sha on the shared branch> \
  --metadata '{"writer_sha":"<sha>"}'
```

The engine verifies ancestry, re-records `issue.diff` from the patch, and
sets `integrated_sha`; `writer_sha` keeps the failing sha findable. This
also works for a done step whose commit was later cherry-picked with a
conflict resolution, where `retry` refuses. Without it, the fanout
reviews the pre-patch tree and re-reports the defect; say so before the
operator answers.

**A gate that failed on a broken check is settled on evidence, not
overridden blind.** Reproduce out-of-band (sandbox off, if authorized)
and resolve `override-pass` with the real result in the note. The second
time a run parks on the same-cause failure, file the durable fix as an
issue and name it in the override note; an override-pass loop is
evidence collection, not remediation.

**Order gate resolutions around in-flight work; the ask itself never
waits.** A park conflicts every claim in flight, so dispatch executors
and present the gate in the same turn, running the resolution verb only
after the wave closes.

The note carries their reasoning, never your summary: it is the audit
trail's only record. Prefix `operator selected:` for a click-endorsement.
When the panel decided, name it instead: `--note "panel <proposal-id>:
<one-line tally>"`.

**A note is audit-trail only; it never renders into any brief.** The
packet template carries only the step header, frozen issue body, input
artifacts, pins, and output spec. Guidance for future work travels only
as a body.

**An operator ruling with no engine route of its own** has one workable
channel: apply it as its own commit on the shared branch, verbatim in
the commit body and resolve note, landed before dispatching the rework
step, never bundled into an integration cherry-pick. It still returns
through a review fanout before the issue is called done. Name every such
commit in the close report. Where it patches a write step whose gate
failed, the rule above governs the same commit.

**A re-review round rebinds to the fix.** Glance at each judge report's
reviewed sha against the step under review; a mismatch means a packet
regressed, an operator surface and an engine defect to file.

**When an issue's automated loop ends non-clean**, extend the plan
first; conductor-orchestrated out-of-band writes happen only under
explicit operator direction, and still return through a review fanout
before the issue is called done.

**Present only what the decision actually reaches.** Never offer a gate
option as "the fixer can/will X" unless the engine genuinely routes X.
Gathering evidence for a presentation may be delegated; presenting is
yours.

**An option that promises engine routing is checked against the verb
before it is written.** Verify with the verb's documented semantics plus
`docket step show` on the step the routing would reach, before the
option text exists. Where the verb does not perform that routing, reword
it or offer the answer that does.
