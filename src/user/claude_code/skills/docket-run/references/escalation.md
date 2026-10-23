# Escalating to the operator

Consumer: the docket-run skill, whose **Gates** section points here. Read
this file in full before putting any gate, park, or question to the
advisor or the operator. The panel mechanics and the standing rulings stay
in the skill body; this file governs what a question carries, how a ruling
is scoped and routed, and which answers the engine's verbs can honor.

**Every decision this file sends to the operator goes advisor-first.**
**Standing ruling: the advisor answers first** in [SKILL.md](../SKILL.md)
governs that route: which answer settles a decision, which classes never
settle, the one reconcile call, and the session without the tool. This
file adds only where the call sits and what the question then carries.
Wherever this file says to present, offer, or ask the operator, the
advisor was consulted first and its answer was not clear.

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
  in `run report`'s "Pinned workflows" block); round from
  `loop_rounds_run` in `docket step show <step the exhausted fix loop
  parked on> --json=v2`, which the engine writes on that row when the loop
  exhausts its cap.
- **Consecutive rejections, listed by proposal id**, not a count, from
  `run report`'s "How steps ended."
- **Fixer and judge variants actually served.** Routing from pinned
  policy.toml's `[executors]`/`[variants]`; what actually ran from the
  journal's `agent-<agentId>.meta.json` `model`; `run report` totals both.
  Report the resolved variant, since round-based escalation may have
  moved it.
- **Spend against budget, including every raise**: `run report`'s
  Budget block plus each `run-budget-set` event's `from=`/`to=`/`reason=`,
  read with `docket events list --run $RUN --json=v2 --tail <N>`. The raise
  list is complete only when `.data.truncated == false`; otherwise raise
  `<N>` and read again.
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
later work. File each as its own issue (`docket issue create` in its
owning project, always `-l tribunal`) before `dispatch close`, linked
to the proposal, id in the close report:

```bash
docket issue create -t "<condition>" -T task -p high -l tribunal \
  --size <tier> -f <file the condition touches> --scope '<glob bounding it>' -d - <<'DESC'
<the seat's rationale, verbatim — backticks and quotes intact>
DESC
```

`-l tribunal` lets a later census separate panel conditions from
everything else; `-l shadow` is never it. A condition living only in a
vote rationale, never filed, vanishes. One condition is one issue, within
the [sizing reference](../../docket/references/sizing.md)'s cap and
carrying its tier as `--size`; a rationale naming several independent
conditions is several filings.

**When the park followed a step's gates, read the verdicts before you
present or characterize the outcome.** `docket step gates STEP-N --json`
carries verdict, exit, argv, duration, and `output_tail` on every
non-passing row (`--full` adds complete output). `step show` and `step
artifacts` do not carry this, and the event stream renders a pass and a
failure identically. Read exits too: a millisecond-fast `operation not
permitted` measured the sandbox, not the code, and presenting it as a
code failure invites an unreal override-pass.

**Consult the advisor after the evidence and before the question.** When
the session can launch agents, launch the `advisor` agent before any gate,
park, or question is presented to the operator, and only with the evidence
above in hand: the gate verdicts read, the artifact read in full, the
premise-check run, and the status of every cited tracker read. The advisor
sees only its brief, so put that evidence in it, quoted or by path; a launch
made on a slice or a paraphrase weighs evidence
nobody read. Carry the drafted operator question and its options in the
same brief, so this launch is also the question's [question
review](../../../references/working-agreement.md#question-review) and no
further launch is made for it. An answer the standing ruling counts as clear
settles the decision, and no question is asked.

**A question that follows an answer that was not clear carries the
advisor's text.** Put it whole in your accompanying message, in a fenced
block labelled as the advisor's answer and as review input, beside the
evidence; after a reconcile call, both answers. The advisor's single
disposition, or its preferred one when it ranked them, takes
`(Recommended)`; after a reconcile call, the reconcile answer's pick does.
That includes an answer left unclear only because it contradicted your
evidence. The label and an "advisor's pick" note in its description are
the only advisor content on an option. Never fold the advisor's text into
the question text, an option, or your own finding; state your reading of
the evidence beside the label as agreement or dissent. No advisor pick
exists for a conditional answer, two unranked dispositions, an answer that
defers the choice, a disposition outside the offered options, or a failed
or timed-out launch: recommend your own option and say the advisor named
none. A class the ruling names as never clear carries the advisor's
framing the same way and has no advisor pick, since its answer is never a
disposition; a trust matter still carries the exact `docket trust add ...
-- <argv>` line the operator would run, and an override-pass of a failed
security gate row carries its recorded evidence (`gate_repro.sh` runs no
security gate): the script's `VERDICT:` and `REASON:` lines, the step's
recorded sha, and the failing row's `exit`, `argv`, `fingerprint` and
`output_tail` from `docket step gates STEP-N --json`.

Present every gate the advisor's answer left unsettled through the
question tool, recommended option first, each answer's real routing in its
description, resolved from frozen definitions.

**One gate, one proposal, one question.** Never bundle distinct gates
into a shared proposal or question, even same-issue siblings, since a
bundled answer makes the ledger record one decision where several were
made. The queue presented on a switch back to attended (SKILL.md
**Standing ruling: unattended mode**) complies: consecutive rounds, one
question per gate, trust items alone.

**A gate disposition is scoped to the step it answered.** An
override-pass on STEP-N settles only STEP-N, however identical the next
park's root cause looks: a `waiting-human` park the other standing
rulings leave over goes advisor-first and reaches the operator when the
advisor's answer is not clear, and approval never extends across contexts.
Only a standing ruling or an answer whose own text named a class carries
further, exactly as far as that class, under the authority of whoever gave
it.

So offer the class option at the first such gate instead of assuming it
at the second, when a park can plainly recur: "Override-pass this step
only (Recommended)" / "Override-pass this step and any recurrence of
this exact defect class for the rest of this run" / "Park and stop the
issue." The "(Recommended)" shown is this skill's default; the advisor's
pick replaces it, since the class choice goes advisor-first like any other
decision. Every recurrence still gets its own resolve verb, its own note, and the durable
fix issue the broken-check rule below requires, each recorded under the
authority that named the class: the operator form for a class the operator
named, the advisor-first form for one a clear advisor answer named. For a
later park identical to one already resolved this run with no class-scoped
answer covering it, the question whether the resolution extends goes
advisor-first once, and to the operator when that answer is not clear.

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

**A panel seated inside a wave is not a launch:** docket-workflow.js seats every
engine vote row itself with a proposal id but no `workflows/` entry;
only a panel you convened through a separate `Workflow({scriptPath:
…tribunal.js})` call is a launch.

**The form you run records who decided, never whether the advisor was
consulted.** On the operator's answer, including one given after an
advisor answer that was not clear:

```bash
docket step approve STEP-N --authority operator --note "<their reasoning, their words>" < <scratchpad>/conductor.d/$RUN.token
docket step approve STEP-N --value <enum member> --authority operator --note "<their words>" < <scratchpad>/conductor.d/$RUN.token
docket step reject  STEP-N --authority operator --note "<their reasoning, their words>" < <scratchpad>/conductor.d/$RUN.token
docket step resolve STEP-N --as retry|skip|abandon-issue|override-pass --authority operator --note "<why>" < <scratchpad>/conductor.d/$RUN.token
docket step hold STEP-N --reason "<the repeated failure, and the operator's word to hold it>" < <scratchpad>/conductor.d/$RUN.token
```

On a clear advisor answer, with no question asked, the record names the
standing ruling: never record an advisor-settled decision `--authority
operator`, and never describe it as the operator's.

```bash
docket step resolve STEP-N --as <the disposition the advisor named> --authority standing-grant --authority-ref advisor-first --note "advisor-first ruling: <the advisor's answer, quoted>" < <scratchpad>/conductor.d/$RUN.token
docket step approve STEP-N --authority standing-grant --authority-ref advisor-first --note "advisor-first ruling: <the advisor's answer, quoted>" < <scratchpad>/conductor.d/$RUN.token
docket step reject STEP-N --authority standing-grant --authority-ref advisor-first --note "advisor-first ruling: <the advisor's answer, quoted>" < <scratchpad>/conductor.d/$RUN.token
```

These three are the ruling's own lines. Its section in the skill body also
carries the `docket run abandon` form and the forms for the verbs that
take no `--authority` flag, the hold among them, whose reason names the
ruling in place of the operator's word.

**A step that keeps failing is held; its issue is not abandoned.** A step
that declares no `max_attempts` is re-offered after every failure, so the
engine never parks it on its own. When one step fails the same way again,
the hold goes advisor-first; when that answer is not clear,
offer the operator `docket step hold` (above) for that step: it
parks the one PENDING step `waiting-human` (park class `held`), the next
dispatch stops offering it, and the rest of its issue runs on. A claimed
step is force-reaped first, which spends no attempt. The held step resolves like
any park: `--as retry` returns it to the pool, `--as skip` skips it. Never
offer `docket run abandon $RUN --issue` to stop one step: it fails every
step of the issue.

Which verb is the step's type, not your reading of the situation:
`approve`/`reject` exist only on `type="human"` gate steps and on a
materialized `<step>-held` step of either kind; every other parked step,
including an executor step or a vote step parked by its `on_fail`, takes
`resolve --as …` only. Resolving the parking step
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
rulings are missing, write them into the run as a run note and confirm
the note reaches the rendering (an issue-body edit does not: bodies,
labels and scope snapshot at the activation that binds the issue, never
at a later re-activation, per the skill's frozen-binding paragraph),
resolve `override-pass` with evidence if the work is already on the
tree, or route the ruling per the operator-ruling paragraph below.

**Reject is an escape hatch, not an annotation.** On a held-cluster gate,
`approve` falls through to the threshold; `reject` skips it and routes by
`on_fail`, usually parking, by design. The verdict is sticky: a retry on
the parked routing step re-parks. Present reject as "stop this issue and
ask me again."

**A held cluster has a third answer: correct the value.** `docket step
approve STEP-N --value <member> --authority operator` overrides the aggregated field (severity
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
verify, a conditioned re-review) go `skipped` instead. Without
`--drop-interposed`, which acknowledges that the interposed steps are
skipped, the engine refuses the override before anything commits. Resolve interposed steps directly when their
condition should still apply, and read `docket next` / `step show`
afterward to see what the engine actually left standing.

**A gate that failed on the executor's own commit is answered with
`retry`; `override-pass` alone leaves the recorded diff on the failing
sha**, since the verb writes a pass without re-pointing the step at a
fixed tree (`step annotate --integrated-sha` does, once integrated; see
below). So a conductor patch under override-pass alone is invisible
downstream: the next dispatch carries the pre-patch sha as target, and
the panel reads the failing tree. Pass `retry` to the advisor as this
skill's default (its precondition is the rendered-brief check above); its
pick takes `(Recommended)`, with `retry` shown as dissent when they differ.
Override-pass will re-find the gate failure and open a fix round on a defect already fixed.

**If the operator rules the conductor patch anyway**, land it as its own
commit, integrate it, then re-point the step's record immediately:

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

The note carries the reasoning of whoever decided, never your summary: it
is the audit trail's only record. For the operator, their words; prefix
`operator selected:` for a click-endorsement, and only for a person's
click. For an advisor-settled decision, the advisor's answer quoted,
prefixed `advisor-first ruling:`. When the panel decided, name it instead:
`--note "panel <proposal-id>: <one-line tally>"`.

**A resolve `--note` is audit-trail only; it never renders into any
brief.** The packet template carries only the step header, frozen issue
body, input artifacts, pins, and output spec. Guidance for future work
travels as a run note (`docket run note add`), or as an issue body edit
followed by `docket run refresh-body`.

**An operator ruling with no engine route of its own** has one workable
channel: apply it as its own commit on the shared branch, verbatim in
the commit body and resolve note, landed before dispatching the rework
step, never bundled into an integration cherry-pick. It still returns
through a review fanout before the issue is called done. Name every such
commit in the close report. Where it patches a write step whose gate
failed, the rule above governs the same commit.

**A re-review round rebinds to the fix.** Check each judge report's
reviewed sha against the step under review; a mismatch means a packet
regressed, an operator surface and an engine defect to file.

**When an issue's automated loop ends non-clean**, extend the plan
first; conductor-orchestrated out-of-band writes happen only under
explicit operator direction, and still return through a review fanout
before the issue is called done.

**Present only what the decision reaches.** Never offer a gate
option as "the fixer can/will X" unless the engine routes X.
Gathering evidence for a presentation may be delegated; presenting is
yours.

**An option that promises engine routing is checked against the verb
before it is written.** Verify with the verb's documented semantics plus
`docket step show` on the step the routing would reach. Where the verb
does not perform that routing, reword it or offer the answer that does.
