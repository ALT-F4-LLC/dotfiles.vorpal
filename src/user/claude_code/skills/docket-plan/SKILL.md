---
name: docket-plan
description: Turn a work request or the current Docket backlog into an activatable run. Converse in the main session and prefer the largest feasible complete run, using later waves for known dependencies or safely serialized overlaps. Budget is unlimited unless the operator specifies a limit; show cost forecasts without turning them into caps. Offer concrete smaller-run alternatives when useful. Record the request, plan, issues, routing, scopes, dependencies, and verbatim acceptance criteria; then stop. Invoked bare, select and bind existing backlog issues directly. Use to plan new work, select the next backlog run, or extend a run after findings. Never execute the planned work.
model: fable
---

# docket-plan

You decide what the work *is* in the main conversation with the operator.
Run this skill inline: leave `context` and `agent` out of its frontmatter.
Its multi-round `AskUserQuestion` flow needs direct interaction with the
operator, so do not run it in a forked subagent or delegate its questions.
Keep the repo read, question rounds, and recording in this conversation.

Use the operator's invocation, any supplied `brief` block, and answers
already settled in this conversation as the starting record; do not re-ask
settled questions. Read the repo and refresh Docket state as §2 requires,
since conversation history carries intent but not current evidence. A fresh
invocation is a new planning pass against the run record, not a fresh
context that discards the operator's answers.

Run the `AskUserQuestion` rounds below with their existing batching and
ordering, as many rounds as the ambiguity needs. If that tool is unavailable,
stop before recording and report that this skill requires an interactive main
session; do not substitute inferred answers or confirmations. Reading the
repo, asking the operator, and recording the run are all yours to do here.

Rules you must not fight:

- **Prefer the largest feasible complete run.** Maximize the number of
  legitimate, in-scope issues in one run before proposing smaller runs.
  Include known later-wave work when its prerequisites and safe scheduling
  can be established; the first wave is not the run's size limit. Make each
  wave as wide as the real dependencies and collisions allow. A smaller run
  is an operator choice or a named constraint, never a default. Do not
  inflate the count by inventing work or splitting one cohesive edit into
  artificial issues. Unknown later-phase work still follows §4.
- **Budget is unlimited unless the operator specifies a limit.** A missing
  budget is a settled default, not a question. Keep cost forecasts visible,
  but do not derive a cap from them, shrink the run because of them, or ask
  for numeric budget approval in unlimited mode. Honor explicit limits and
  their units, including still-applicable limits from earlier operator input.
- **You record; you never execute.** You do not spawn anything that starts
  work, and you never activate unprompted. Activation is a gate you do not
  hold: approving it is a tribunal vote that `docket-run` convenes and
  surfaces, so what you produce is a recorded run, never a promise that a
  question is waiting for the operator.
- **You never observe execution.** Once you present the recorded run and
  stop, you are done. Re-docket-planning is a *fresh* invocation of this
  skill that reads the run record, not this conversation continuing to watch.
- **Acceptance criteria are copied verbatim.** Whatever the operator states
  as done-ness goes into the issue body word for word. You may add ACs you
  derived and say you derived them; you may not paraphrase theirs.
- **One condition per criterion.** A derived AC states one observable
  condition. An operator-stated criterion that joins alternatives with "or"
  or bundles several outcomes is put to the operator in the question round
  as a proposed split, one criterion per condition, and their answer is
  recorded verbatim, never split silently. A verify seat judges a criterion
  as written, so every bundled case is a fix round for the fixer to discover.
- **A criterion that encodes the worse design is a reframe, put to the
  operator before it is recorded.** Verbatim copying fixes wording, not
  design. When the read shows the stated done-ness would force a mechanism
  the codebase's own invariants argue against, or a shape generic to any
  repo while this one needs something else, offer the reframe as an option
  in the question round beside the criterion as stated. The operator's pick
  is recorded verbatim, and the losing reframe is noted in the plan artifact
  so a writer does not rediscover it. A reframe inside the issue's scope
  that still satisfies every recorded criterion is the writer's
  implementation choice and needs no question.
- **A derived AC that predicts command output is run before it is
  recorded.** Execute the command, non-mutating check commands only, which
  is all this class of AC ever quotes, against the committed tree the run
  will verify on, and paste what it actually printed. Output quoted from any
  transcript is a fact to verify, not a source: transcripts capture
  transient states that can make an AC assert something false.

**Three invocation shapes, picked by the argument you were given.** A
request or a `DKT-N` issue id enter at §1: the conversation decides what the
work is. An empty invocation (bare `/docket-plan`, or the literal word
`backlog`) enters at §1b: the backlog already says what the work is, and the
conversation decides which of it goes next. Both paths end by recording a
run (or a documented "nothing to record"); neither activates or executes.

## 1. Converse until it decomposes

**A supplied brief block and answers already settled in this conversation
seed this section: do not re-ask what they already answered.** If the
operator's message carries a `brief` skill block (labeled `Goal:` /
`Motivation:` / `Scope:` / `Out-of-scope:` / `Acceptance criteria:` / `Size
hint:` / `Security-sensitive:` / `Constraints:`), read it as already-settled
input to the table below: Goal -> Goal, Constraints <- Constraints plus
Out-of-scope, Acceptance criteria <- Acceptance criteria (still copied
verbatim, per the rule above), Security sensitivity <- Security-sensitive,
Size <- Size hint. Ask only about a field the block leaves as "not
stated"/"not specified", or a contradiction the §2 read surfaces.

Ask about what you genuinely cannot decompose without, via one
`AskUserQuestion` round. Batch your questions: one round of three beats
three rounds of one. Stop asking when you could write the issues; ambiguity
that does not change the decomposition is not your problem to solve.

Put your recommended option first, labelled "(Recommended)", for every
round, including open-ended asks like acceptance criteria, where you offer
drafted candidates as options and the operator's selection or typed text
becomes the verbatim source. If later verification refutes a fact inside
operator-selected text, strike the false premise, keep the criterion, and
annotate the change with the evidence in the body; re-ask only if the
correction changes what the operator would decide. An exclusive-meaning
label ("X only", "neither") never belongs in a multi-select option set; a
set that needs one is a single-select question. You may run more than one
round in the same conversation, since a premise verdict from your own repo
read in §2 can surface a question that only makes sense once the read
lands, but never split one round into two out of convenience.

Do not convene a tribunal to answer these questions. Intent has exactly one
source, and a panel asked to supply it would return a confident guess.

The five things you need:

| | What you are after |
|---|---|
| **Goal** | What is true when this is done that is not true now |
| **Constraints** | What it must not break, touch, or exceed, including any explicit budget limit; otherwise budget is unlimited |
| **Acceptance criteria** | How done-ness is checked, in the operator's words |
| **Security sensitivity** | Does this touch authn/authz, secrets, crypto, sandbox, trust, or supply chain |
| **Size** | Whether the full shape is knowable; include all feasible issues by default, with any explicit issue-count limit treated as a hard cap |

Apply the largest-complete-run preference to request intake, single-issue
decomposition, and backlog selection; do not ask the operator to restate it
on every invocation. Offer the run-shape alternatives in §1b when they
expose a useful tradeoff. For new work, stay within the supplied request
rather than adding unrelated backlog items to increase the count. Required
coverage of the agreed goal and ACs is a hard constraint: do not drop
necessary work merely to increase the count or fit an explicit budget
limit. Obtain agreement to a concrete scope reduction or budget increase
when such a limit prevents the agreed work.

Security sensitivity is asked, not inferred: it sets labels that pin
routing later, and a wrong guess is silent, so if the answer is not obvious
from the request, ask it outright.

`needs-research` sits between inferred and asked: apply it yourself when the
request names an external library, API, protocol, framework, or prior art
the plan depends on and the repo alone cannot verify, usually explicit in
the operator's own words. When the signal is genuinely unclear, fold it into
the batched question round instead of guessing either way. It gates an
optional `research` step ahead of authoring in `spec-doc`, `spec-project`,
and `investigation`; absent is the normal case, so a label applied too
eagerly costs a skipped step, not a wrong one, while a label withheld when
needed costs an author writing on recall.

## 1b. Bare `/docket-plan`: propose the next batch from the backlog

The request here is the backlog itself, so §1's questions are mostly already
answered by the issues' own bodies. What you owe the operator instead is a
ranked proposal and one confirmation round. Every rule above still holds: you
record, you never activate, and you do not rewrite the ACs already in the
bodies.

**Survey** (commands you run; the operator types none of them):

```bash
docket next --json=v2 --limit 1000                    # ready: no open blockers, in backlog/todo
docket issue list --json=v2 --limit 1000 -s backlog -s todo   # every field the ranking reads
docket run status --active --json                     # runs that already own issues
docket issue list --run <ref> --json=v2 --limit 1000  # one per run above: its roster
```

Project resolves from cwd's git identity, same as every other docket verb.
A `VALIDATION_ERROR` naming no project, or no store reachable, means this
repo isn't bound: say so and stop. `--limit 1000` is not optional: `issue
list` caps at 50 and `next` at 10 by default, and neither output flags the
truncation; the same limit binds `/docket-groom` and `/tend`. If any result
reaches the requested limit, use the CLI's help-verified pagination or
unlimited form to finish the survey before claiming coverage. Do not infer
blocking from absence in a truncated result. `docket next` identifies issues
ready now, with no incomplete `depends_on` blocker. Join its ids against the
`issue list` rows, which carry `priority`, `labels`, `scope`, `assignee`,
and `description` (verified on `--json=v2`). Inspect the other open issues'
dependency links too: they can join later waves when every open prerequisite
can be included in this same run under the checks below. Absence from
`next` alone no longer excludes an issue from the complete run.

**Align on batch scope before ranking.** The survey tells you what exists.
Resolve what this run should cover, batching missing decisions into one
`AskUserQuestion` round under §1's discipline. These answers constrain the
candidate set, not the ACs inside it. Skip the round when everything is
already settled. A ranked proposal with a which-variant choice does not
replace this alignment. Reuse settled answers and the standing
maximum-run preference and unlimited-budget default; ask only for missing
decisions. The final confirmation approves the concrete roster, showing
Unlimited or the operator's explicit cap separately from the cost forecast.

- **Kind filter**: which kinds of work belong in this batch: every kind
  (Recommended), bugs only, features only, or a kind/label the operator
  names. Show the survey's breakdown (`N bug, M feature, ...`), distinguishing
  ready-now issues from issues with open prerequisites.
- **Run shape**: use **Maximum complete run (Recommended)** unless the
  operator chooses otherwise, maximizing issue count across safe waves.
  Useful alternatives are **Parallel-only run**, restricted to ready-now,
  mutually non-colliding issues, and **Focused run**, with an operator-named
  issue-count cap, priority floor, or subset. These are single-select
  alternatives, not simultaneous preferences. State the default rather than
  requiring a redundant question; present concrete alternatives with the
  final proposal when their counts, costs, or urgency materially differ.
- **Budget**: state **Unlimited (default)** when no limit is specified;
  do not ask a budget question. Preserve an explicit cap in its stated unit.
  Ask only if a supplied limit is ambiguous or conflicts with other settled
  instructions. Smaller-run alternatives may show lower forecasts without
  turning those forecasts into caps.

Skip a question here only when the operator's own invocation or a
still-applicable answer in this conversation already answered it
(`/docket-plan backlog bugs only` needs no kind-filter question; a prior
answer for a re-proposed batch is not re-asked). Batch unresolved alignment
questions together. State the operator's kind filter, run shape, and budget
choice at the top of the eventual proposal, plainly, so the
"not ready"/"deferred" reasoning below reads against what was actually
asked for.

**Exclude what is not free.** This queue isn't docket-plan's alone; the
definitions are the ones `docket-groom` and `tend` already use:

- **Off-scope.** Any issue whose kind or labels fall outside the alignment
  round's kind filter (a `feature` issue when "bugs only" was chosen, say),
  excluded before ranking starts, never scored against the priority or
  parallel rules below.
- **Run-included.** An open issue on any active run's roster (`docket run
  status --active --json`, then `docket issue list --run <ref> --limit
  1000` per run: planning, active, or paused, anything not done or
  abandoned) belongs to that run's docket-plan/docket-run session, even
  while the run is parked.
- **Claimed.** Any issue with a non-empty `assignee`: someone or something
  else already has it.
- **Unrouted or routed elsewhere.** Only an issue carrying `route-run` is a
  candidate. An issue with no routing label is unrouted: count it, name the
  count in the proposal with a pointer to `/docket-groom`, and never rank
  it. An issue carrying `route-direct`, `route-tend`, or `route-loop`
  belongs to another route (the operator's own brief, the tend queue, a
  loop): list it as routed elsewhere (step 4 covers why activation would
  refuse it anyway if named for this run).

List all three kinds in the proposal under "not free"/"off-scope"; never
drop them silently.

**Build the largest feasible roster, then schedule its waves.** Apply all
five checks before final selection. In the maximum complete run, issue count
is the primary objective within the operator's hard constraints; priority
and parallel width decide between equally large feasible rosters.

1. **Ready now or reachable within this run.** A ready-now issue is in the
   complete `docket next` result. A later-wave issue qualifies only if every
   still-open prerequisite, transitively, is also included and passes the
   same ownership, scope, readiness, scheduling, and budget checks. Inspect
   the links; do not invent an edge or assume another run will finish in
   time. Count shared prerequisites once. An excluded prerequisite excludes
   its dependent too: name the missing chain, including external blockers,
   off-scope work, claimed work, and cycles. Offer a scope expansion as an
   option when useful; never silently widen the kind filter to include a
   prerequisite. The final graph must be acyclic with a startable first wave.
2. **Maximum count, then priority.** Compare feasible rosters by issue count
   first. At equal count prefer more `critical` issues, then more `high`,
   `medium`, `low`, and `none`; next prefer a wider safe first wave and
   fewer planned waves, then id ascending (older first). Explicit must-include
   issues, priority floors, and caps are hard constraints. A priority-first
   greedy pass is a starting candidate, not proof of maximum count: compare
   alternatives when cost or overlap excludes other issues. If maximizing
   count leaves critical/high work out, make that tradeoff conspicuous and
   show a concrete priority-first alternative. Do not describe a heuristic
   result as a proven global maximum; state any search or survey limitation.
3. **Safe waves.** Check collisions by the matcher's own rules (§3 Scope).
   The engine keeps a second collision key beside scope: the concrete `-f`
   files, which `docket plan --json` splits into sub-phases when two issues
   name the same path. Inspect both surfaces. In the complete-run default, a
   real overlap changes the schedule rather than automatically excluding an
   issue. Include both only when current engine evidence establishes safe
   serialization: inspect its plan and scheduling rules for the actual
   scopes and files, not merely a wave diagram in the plan doc. If that
   cannot be established, defer with the conflicting pair and scheduling
   limitation named. Never add a false `depends_on` to force an order. In
   parallel-only mode, every admitted issue must be ready now and mutually
   non-colliding.

   Worktree isolation does not excuse this check. Every write step runs in
   its own isolated worktree during implementation, but `docket-run` still
   cherry-picks each write step's commit onto the same shared branch, in
   step-id order, at integration: worktrees isolate the implementation
   window only, and integration is still one shared branch.

   Before serializing or deferring a candidate, check whether the overlap is
   an artifact of an over-broad glob on either side: a leading wildcard, a
   package root where one subdirectory is what the ACs actually name, a `**`
   that predates the work it now describes. If narrowing it to what that
   issue's own ACs honestly need would make the pair disjoint, that is a
   `docket issue edit --scope` the operator can authorize in the confirmation
   round (§3 Scope defines that verb). Offer the narrowing with the
   proposed globs written out; it can widen a wave or admit work that could
   not otherwise be scheduled. Keep genuine overlaps honest and serialize
   them only as verified above. Continue admitting feasible issues across
   later waves until a named constraint binds; never stop because the first
   wave or the roster looks large enough. Retain every real internal
   `depends_on` in the plan. Only the parallel-only option has no internal
   open dependency by construction.
4. **Run-ready**: every §3 recording obligation, checked here because
   activation will not catch most of them (a missing scope draws a warning
   and activates anyway; only a graph cycle refuses): the body carries
   acceptance criteria (at least one checkable item, not a restated title);
   `--scope` is set and every glob matches at least one file in this
   checkout; the row's `files` list is non-empty, naming the concrete files
   the change touches; plus the binding probe and the scope-vs-AC lint
   below. An issue that fails any of them is not run-ready: list it under
   "not ready" with the missing thing named. The operator may have you fill
   it in this session (`docket issue label add` for labels, `docket issue
   edit --scope`, `docket issue file add` for files, or a body with ACs in
   the operator's words, fine until the activate that binds it) or send it
   to `/docket-groom`; you never fill ACs from your own guess. Apply these
   checks to every later-wave issue and prerequisite too. Scheduled for
   later does not waive a missing scope, file, AC, or binding.

   **Routing labels bind the route before the workflow.** An issue the
   operator named that carries `route-direct`, `route-tend`, or
   `route-loop` is not run work: refuse it with the label named, and let
   the operator relabel it (by hand or through `/docket-groom`) before it
   can bind, since every registered workflow lists those three in
   `unless_labels` and activation would refuse it too. An issue the
   operator named that carries no routing label gets `route-run` when the
   run is recorded (`docket issue label add <id> route-run`), so the label
   states the route the record already made.

   **Probe the binding in both directions.** §3's labels-confirm-binding
   rule asks whether an issue's labels produce the intended workflow
   (`docket workflow show <intended>`), and for a backlog issue you did not
   author, the intended one is whatever its ACs and scope imply. Also count
   every registered workflow whose `[match]` accepts those same labels,
   from `docket workflow list` and not the source tomls, since a stale
   registration is invisible in `ls ~/.docket/config/workflows/` and is
   precisely what refuses:

   ```bash
   docket workflow list --json=v2 --limit 0   # every registered name@version; --limit 0
                                              # because the default is 50 and this lists
                                              # every VERSION of every name, not just the
                                              # binding one
   docket workflow show <name>                # per binding-eligible name: its [match] block
   ```

   The bindable set is the highest registered version of each name whose row
   carries no `deprecated_at_ms` (a retired version still resolves under
   `show` and never binds), plus any `.docket/config/workflows/*.toml` this
   repo carries, which activation auto-registers before it matches. Every
   corpus `[match]` routes on labels alone (§2), so evaluate each candidate's
   labels against `labels_any` / `labels_all` / `unless_labels`,
   `unless_labels` last and winning, and count:

   - **Exactly one**: that is the workflow the issue binds. Carry the
     `<name>@<version>` into the proposal beside its labels, whether or not
     it surprises you.
   - **Zero or several**: the `VALIDATION_ERROR` (exit 3) `docket run
     activate <run> --dry-run` would print, naming the issue and every
     candidate. Not ready: `labels match 2 workflows (<a>, <b>)`.
   - **One, but not the one the ACs and scope imply**: §3's
     route-by-omission tell, and an operator decision rather than yours.
     Not ready: `binds <wf>, ACs imply <other>`.

   If `workflow list` comes back empty, this store has never activated and
   nothing is registered yet (§2); say that in the proposal rather than
   reporting a clean probe.

   **Scope covers what the ACs name.** Every file path an acceptance criterion
   names must be matched by one of the issue's scope globs. The check is
   textual, paths against globs by the matcher's own rules in §3, so it
   needs no repo read and can be done before you read the tree. The remedy
   is scope-side, never AC-side: the ACs in a backlog body are the
   operator's words and §1b does not rewrite them. Not ready: `AC names
   <path>, not in scope`; the fix the operator may authorize in the
   confirmation round is `docket issue edit --scope` (§3 Scope).

   **Every AC is satisfiable inside the issue's scope.** An AC whose only
   remedy needs a change outside every scope glob, in another repository, or
   in a capability the engine does not have (read the issue's related gap
   issues, where an earlier run has usually said so) is not bound under
   this issue. Split it out as its own issue in the owning project, or
   record it as a dependency, and say so in the proposal. Bound anyway, it
   can never be `met`: at best verify reports it `unmet-out-of-scope` and a
   vote passes it with a filing, at worst it routes `fix-loop` to the cap and
   parks on every run that carries it.

5. **Forecast cost; fit only an explicit limit.** Size every issue by §3's
   arithmetic; include the full amount for every issue across all waves,
   since later execution does not make headroom reusable. With Unlimited,
   admit every otherwise feasible issue without any budget-driven cutoff.

   With an explicit declared-cost cap, when a candidate plus its
   not-yet-included prerequisites does not fit, defer that candidate and
   keep scanning: one oversized issue is not a reason to end selection.
   Reconsider combinations and replacements that admit more issues,
   recalculate shared prerequisites once, and remove or reconsider any
   dependent whose prerequisite leaves the roster. Finish with a check that
   no further eligible issue or required bundle can be added within the cap
   and schedule; this establishes no omitted feasible addition, not
   necessarily a globally maximum roster.

   If an explicit cap prevents a larger run, recommend the largest roster
   that fits it and optionally show a concrete larger-cap alternative:
   additional issue ids, added count, and the exact extra budget required.
   Never raise the cap without the operator choosing that alternative. State
   the actual limiting factors, including unused budget when no remaining
   feasible bundle fits.

**Read before you propose.** §2 applies unchanged, narrowed to the candidate
batch: read the candidates' scope globs yourself (do the globs match
files), check whether any candidate's fix already landed (`git log` over
its globs since the issue's `created_at`, then the acceptance criteria
themselves read against HEAD; a fix that landed under another path or
before the issue was filed leaves the log over its globs empty), and check
whether any pair collides under the matcher's rules, before you write the
proposal. An issue whose work is already on HEAD, or whose every acceptance
criterion HEAD already meets, is not a batch member; it is a comment on
that issue and a line in the proposal.

**Propose, in one confirmation round.** Lead with the largest feasible
complete run under the settled constraints, or the operator's explicit
alternative. Present the following above one `AskUserQuestion` round:

- the kind filter, run shape, and budget policy: Unlimited or the explicit
  cap and its unit;
- total issue count, ready-now count, planned `First-wave width`, later-wave
  counts, and full cost including each issue's rework allowance;
- the roster by planned wave: id, title, priority, labels, the workflow they
  bind (the `<name>@<version>` step 4's probe returned, named for every
  member, not only the surprising ones), scope globs, expected cost, and
  the one-line reason for inclusion and wave placement; the forecast total,
  compared with the cap only when a relevant finite cap exists;
- deferred, with the reason each time: unavailable prerequisite DKT-N,
  collision with DKT-N on `<prefix>` that cannot be safely scheduled,
  later-wave work excluded by parallel-only choice, not free (run RUN-N, or
  assignee), off-scope (kind filter), not ready (which obligation from step
  4: no ACs, no scope, a glob matching nothing, `labels match N workflows`,
  `binds <wf>, ACs imply <other>`, or `AC names <path>, not in scope`),
  explicit budget or issue cap, dependency cycle, already landed (commit),
  unrouted (no routing label; `/docket-groom` sets one), or routed elsewhere
  (`route-direct`, `route-tend`, or `route-loop`).

When useful, compare two or three concrete alternatives in a compact table:
the maximum complete run first and recommended, a parallel-only or
priority-first roster when it offers a material tradeoff, and a smaller
focused roster if useful. Show actual issue counts, first-wave widths, wave
counts, cost forecasts, budget policies, and what each leaves out. Do not
invent a small default batch size to fill the table. If the operator already
chose a focused or parallel-only run, recommend the best roster within that
choice.

The single-select confirmation offers recording the recommended roster with
its exact count and Unlimited or explicit cap, recording a named displayed
alternative when one exists, or revising/proposing only. Keep revision/propose-only available even
when alternatives are shown, and never preselect recording as if it were
consent. Any different typed subset must be rechecked for dependency closure,
readiness, scheduling, and budget before it is recorded.

If there is no feasible startable run, report the reasons (nothing open,
unavailable prerequisites, cycles, everything claimed or run-included,
nothing run-ready, or no complete bundle within an explicit cap) and stop.
`/docket-groom` is the skill for a backlog that is full but not ready; name
it rather than grooming here. An empty ready-now set calls for inspecting
the blockers, not reporting those issues as merely absent from the backlog.

**On "record", go to §3 with the batch as the roster.** The differences from
request intake are exactly these, and nothing else in §3 relaxes:

- No `issue create`: the issues exist, so there is nothing new to create for
  this path. Run-readiness fills the operator approved in the round
  (`docket issue label add` or `docket issue edit` calls) run before `run
  start`.
- `run start --issue` names the backlog issues themselves. Direct binding
  is the operator's settled choice for batch mode, and it is what makes the
  §3 `/docket-plan DKT-N` obligations do not apply here: a batch member is the
  unit of work, not a question the run answers.
- The request-file content holds the invocation and the operator's
  confirmation verbatim, the option they picked and any text they typed,
  because that is what was asked; the ranked proposal is not a substitute
  for it.
- The plan doc's body carries the selection rationale, dependency closure,
  planned waves and evidence for collision serialization, the deferred list
  with its reasons, and the budget arithmetic, written for the person who reads
  this run in three months and wonders why DKT-N waited.
- The run's budget is Unlimited unless the operator specified a cap.

Then present the recorded run per §5 and stop. A later invocation surveys
the deferred work again; earlier blockers may have cleared, but neither
readiness nor ownership is assumed from this proposal.

**Reshaping a recorded-but-not-yet-active run never ends on an unanswered
question.** The operator asking, later in the same conversation, to fix a
run-readiness blocker on an already-recorded run (relabel an issue, add it
to the roster, adjust the budget) is legitimate reshaping under this
section, not an escape from it. Run it, then re-run §5's presentation with
the run's current state (roster, budget, First-wave width) before yielding
the turn, even if a new open item surfaced along the way: name that item as
a question inside the presentation, not as the last line of the message
with nothing else restated.

## 2. Read before you decompose

Guessing at scopes produces issues that fail their scope gate at execution
time. Read the repo yourself, with your own `Read`/`Grep`/`Glob`/`Bash`: a
scope map, and the premise verdict when the request rides on one ("already
fixed", "already done"). Engine-contract reads (CLI help, the workflow
corpus under `~/.docket/config/`, the scope-matcher's own rules) and the
repo survey are both yours now.

Any engine fact you use (run status, issue ids, branch state) comes from a
fresh `docket run status`/`issue list` read in this session, never from
memory of a prior session.

The layout tells you scopes: which directories a change of this shape
actually touches, narrow globs per area. `ls ~/.docket/config/workflows/`
tells you which workflows exist to bind to; activation auto-registers them
from the config roots, so `docket workflow list` reads empty on a store that
has not activated yet and is not the corpus. Labels are what bind: every
`[match]` block routes on `labels_any`/`unless_labels` and none of them look
at kind, which is a closed field (`bug feature task epic chore`, enforced by
`issue create -T`) that routes nothing. Labels route inside a bound workflow
too, via `when`-gated steps: a `spec-doc` issue picks its author by the
colon-form doc label (`doc:tdd`, `doc:adr`, `doc:ux-spec`; no doc label
means PRD), and `security` / `security-change` push a TDD to the security
author, so file doc-producing issues with `doc:<type>` or accept the PRD
default (the hyphen spellings route nothing). `needs-research` gates an
optional research step ahead of authoring in `spec-doc`, `spec-project`, and
`investigation`; apply it per §1's rule, never because a workflow happens
to support it. `git log --format='%s' -30` tells you the repo's
conventions. Existing issues (`docket issue list`) tell you whether some of
this is already tracked. Any probe you run must itself be non-mutating and
sandbox-feasible: a command that writes state (installs a package, syncs a
`.venv`) or needs network egress the sandbox does not allowlist has no
place in this read.

**When the read contradicts the request's premise, verify before
recording.** A scope map that says "this bug looks already fixed" changes
the run's shape; verify it yourself before you trust it, with a forced
verdict taxonomy, the hole hypotheses named, and reproduction in an
isolated scratch dir. The run record must not encode a premise your own
read has already cast doubt on.

**A landed-fix check covers every path in the candidate's own scope, not the
interesting subset.** The `git log`/diff command that answers "has a fix
already landed" runs over every path in the candidate's scope list, in
order: a path you drop from the command is a path the check reports clean
about, because it never looked there.

**Before declaring a candidate "already fixed" or "do not batch," read that
issue's own history.** `docket issue show <id> --json` carries the issue's
comment history and, emitted only when a run gave up on it, the
`run_disposition` that run left behind, `{run, disposition, by, reason, at}`
with the reason verbatim (`docket issue comment list <id>` is the
comment-only read if you want it separately). An abandoned run's stated
rejection reason is not recoverable from the code, so no amount of clean
`git log` output substitutes for it. Read it before you accept the verdict,
and reconcile the verdict against it in words: when a prior run was
abandoned because "the real fix needs these files," an already-fixed
verdict must say what landed in those files since, or it is not a verdict.

## 3. Record the run

You run the mutating commands yourself, directly, in this same
conversation; the operator types none of them. Under the global store
every docket verb opens `~/.docket` read-write and migrates before it does
anything, so this conversation needs write access to that path even for the
read-only survey and arithmetic commands below. A sandboxed session is
fine wherever `~/.docket` is in the sandbox's write allowlist, which it
normally is. `unable to open database file` is the symptom when it is not,
and it is the only evidence that justifies asking for an unsandboxed
session (`--help` alone never opens the store).

First, if your scope read or premise verdict is more than a few minutes old,
re-check it now: one `git log --since=<read time>` over the scoped paths. A
fix that lands between the read and the record otherwise becomes a bound
issue whose implement step exists to discover the work is done.

**Track the batch in the task list as it records.** Once the issue set for
this run is settled (the decomposition from §1, or the batch from §1b),
`TaskCreate` one `pending` task per issue about to be created, `subject`
the working title. `TaskUpdate` each to `in_progress` right before its own
`issue create` call and to `completed` once the id comes back, rewriting
the subject to the real `DKT-N: <title>`. This is a display for the
operator watching the batch land; it is never where you read the roster
back from, since the roster is what the create/link calls themselves
returned.

Run these, in this order, once you know what shape they take:

```bash
docket issue create -t "<title>" -T <kind> --idempotency-key <key> \
  -l <label> -f <file> -f <file> --scope '<glob>' -d - < <body-file>  # one per unit of work; -f and --scope are never omitted
docket issue link add DKT-<n> depends_on DKT-<m>  # the graph's edges
docket run start --request-file <path> \
  --budget <declared-cap-or-0> --usage-budget <usage-cap-or-0> \
  --issue DKT-<n> --issue DKT-<m>  # request verbatim; issues must exist first
docket doc create -T plan -t "<title>" --idempotency-key <key> -d @<path>  # the plan artifact
```

Write each body/request/doc-content field to a temp file before use.
`issue create -d` takes a literal string (`-` reads stdin); the `@<path>`
form belongs to `doc create` alone. Followed blindly, every issue body
becomes the literal text "@/path/file", frozen at activation into every
brief. Help-check each verb's flags on first use in a session; the CLI is
the authority, not this file.

Issues first: `run start --issue` names them, so they must already exist.
The set is not frozen there: `docket run issue add RUN-N DKT-N...` attaches
and `run issue remove` detaches while the run is in `planning`, and `add`
still works on an `active` run, where the next activate binds the newcomers
as it would a later phase. Activation is the freeze, not `run start`, so a
list that turns out short costs an add, not an abandon-and-restart. The
idempotency key you put on each issue entry makes the creates re-runnable:
the same key returns the original entity, never a duplicate.

**Encode the budget explicitly.** `run start --help` documents `--budget 0`
as unlimited, and `--usage-budget 0` independently disables the
measured-usage cap. On new runs, pass both as `0` unless the operator
specified a limit for that dimension; omission can inherit `budget.default`
or `budget.usage.default`. Map an explicit limit to the correct dimension
and unit using `run budget --help`; do not copy one number into both
dimensions. Declared workflow costs and measured usage are not
interchangeable. Re-check these flags on first use under the help rule
above. After recording, read the run's effective limits and verify that
they match the operator's policy, recorded separately from the cost
forecast below. Do not change global settings or other runs. For a later
planning pass, preserve still-applicable operator-specified limits; a
configured default or an earlier forecast is not an operator limit, so
reconcile any mismatch with this policy in the run being planned.

**Cost forecast, not an automatic cap.** Calculate the proposed run's
declared-cost floor and normal rework allowance in both budget modes. With
Unlimited, the total is informational. With an explicit declared-cost cap,
it is also the admission check. A measured-usage cap remains separate and
requires evidence in its own unit; never compare it to workflow cost units.

The floor is the bound workflow's expected-cost sum with its when-gated
steps included: a `when` you cannot evaluate at plan time is a step that may
well run, and a floor that omits it is a floor for a run that did not
happen. You read that sum, you never estimate it: `docket workflow show`
does not print step costs, so the only surface that has them is the bound
workflow's source: `grep -n expected_cost
~/.docket/config/workflows/<wf>.toml`, summed over every line it returns,
with each `fanout` step's cost multiplied by its sibling count (`grep -n
'fanout =' ~/.docket/config/workflows/<wf>.toml` gives the list; the tomls
annotate those lines `# per expanded sibling`). Standard-change's review is
0.60 × three judges = 1.80, security-change's and ui-change's are 0.60 ×
four, spec-doc's 0.60 × three, and spec-project's `spec-author` fans out
seven ways at 1.00 apiece. The per-track total is the sum you read, never a
figure copied from prose: these tomls are versioned (`grep version
~/.docket/config/workflows/<wf>.toml` gives the current number) and a total
frozen into prose goes stale silently. If the read did not happen, the
number is an estimate and the proposal must say so in those words.

On top of the floor goes rework headroom, read the same way, never guessed:
for every admitted issue, its bound workflow's `rework_round_cost` × that
workflow's own declared `max_fix_loops`, summed across the batch. Both
factors are in the pinned definition. `grep -n max_fix_loops
~/.docket/config/workflows/<wf>.toml` gives the bound: it lives on the step
that owns the loop, which is `reconcile` on standard-change, ui-change,
security-change, spec-doc and spec-project, `review` on small-change,
`verify-ac` on docs-only, disposition and trivial-change, and the
`report-vote` vote on investigation. trivial-change is the one track that
declares `max_fix_loops = 1`. The round is the `loop = true` step plus
everything replayed from its `after_loop` re-entry point up to that owning
step: on the change tracks exactly the fix + judges + synthesize-findings
arithmetic the floor already does. Read the step names, not the costs
alone: the fix step is called `revise-spec` on spec-project,
`revise-investigation` on investigation and `revise-disposition` on
disposition, docs-only's `review` is a single `judge-correctness` with no
fanout and the track has no synthesize-findings step at all, and spec-doc's
five `revise-*` variants are mutually exclusive `when`s: exactly one
fires, so its round carries 1.50 once, not five times.

The corpus as it reads today, round × declared loops = reserved per issue:
standard-change 1.0 + 1.80 + 0.60 = 3.4 × 2 = 6.8; ui-change 4.0 × 2 = 8.0;
security-change 1.0 + 2.40 + 0.60 = 4.0 × 3 = 12.0; spec-doc 1.50 + 1.80 +
0.60 = 3.9 × 2 = 7.8; spec-project (`revise-spec` fans out seven ways at
0.70) 4.90 + 1.80 + 0.60 = 7.3 × 2 = 14.6; docs-only 0.60 + 0.60 +
verify-ac 0.40 = 1.6 × 2 = 3.2; disposition 0.40 + verify-ac 0.40 = 0.8 × 2
= 1.6; small-change 1.0 + review 0.60 = 1.6 × 2 = 3.2; trivial-change 1.0 +
verify-ac 0.50 = 1.5 × 1 = 1.5; investigation `revise-investigation` 0.40
alone, its re-entry being a vote that costs nothing, × 2 = 0.8. Recompute
them from the tomls rather than trusting this list: it is a worked example
of the read, not a substitute for it, and every one of these files is
versioned.

The sizing rules below concern finite caps. They explain accurate
forecasting and admission under an explicit limit; they do not authorize
imposing a cap when the operator left the budget unlimited.

Two things are forbidden, both measured. Never budget a fixed number of
rounds the workflow did not declare: security-change declares three, and
rejection-driven loops are that track's normal case, so sizing on fewer
rounds under-forecasts the reserved headroom the definition already commits
to. And never divide by issue count: every admitted issue reserves its own
workflow's full `max_fix_loops`, because loops are per issue and the batch
is what makes them concurrent, not what makes them share. A number that
came from neither the pinned definition nor this arithmetic is not a
substantiated cost forecast or justification for a raise; an explicit
operator cap still applies. Price only the track's normal case into the
cap: a round nobody could have planned, such as an operator's out-of-band
commit needing independent review mid-run, is what the raise machinery is
for, not a sizing failure. A cap that is short by arithmetic forces a
mid-run raise panel and idle wall-clock time that a correct read would have
avoided. Round the forecast up and say what the headroom is for; an unspent
cap costs nothing (`docket run budget --set <n> --reason '<why>'` adjusts
it later, with `--if-version` when a concurrent change would matter). Write
this arithmetic, one line, into the plan doc's body as the forecast,
alongside Unlimited or the operator's explicit cap. In unlimited mode, keep
the encoded caps at `0` regardless of the forecast. If an explicit cap is
too small, fit the roster without dropping agreed deliverables, or obtain
agreement to a concrete scope reduction or budget increase before
recording. Never silently replace the budget policy with the computed
forecast.

Ids render with each project's prefix: the store is machine-global and the
number is the identity, so `DKT-<n>` and a bare number parse in any
project.

**The request** goes into the request file verbatim via `--request-file`;
it becomes the run's own record of what was asked, and your summary of it
is not a substitute.

**The plan artifact** is prose, and it is the one place your reasoning is
allowed to live: the decomposition rationale, the risks you see, the
phasing you suggest, the run shapes and workflow bindings you weighed
against the one you chose and why it won, and anything you asked about that
turned out to matter. Weigh at least one shape that is not the corpus's
habitual answer before settling; the plan records the comparison in a few
lines, not the search. Before it goes into the doc, check the draft the way
you'd check anyone else's writing: no hedged claim without the read or the
operator answer behind it, no restated obviousness, no padding.

**The issues**, one per unit of work, carry kind, labels, scope globs, and
the ACs in the body. When a draft spans several prefixes with separable
ACs, split along those boundaries and budget each resulting issue's full
workflow and rework allowance.

Never split one cohesive edit or manufacture a criterion to increase
the count. Independent units that touch the same file may share a run only
when their real dependencies and the engine's verified serialization make
that safe; do not rely on claim failures to order them. Keep every scope
wide enough for its actual change. A smaller or sequential run may be the
honest result of these constraints, but an arbitrary preferred batch size is
not a constraint.

Before recording, check the full dependency graph and both collision surfaces
against the engine's plan and scheduling rules. Record total issue count,
ready-now count, planned waves, and `First-wave width`: the number of issues
the plan can make eligible together without a scope or file collision.
Count zero-incoming-edge issues separately if useful; that count alone does
not establish concurrent dispatch. Each wave has one concurrent owner per
conflicting scope or file, with overlaps across waves explicitly accounted
for. Explain any narrow wave and any scheduling uncertainty in the plan doc;
planned width is not a guarantee of runtime capacity.

**Labels are the issue's routing, and you confirm the binding before you
record it.** Binding is exactly-one-match over the corpus's `[match]` blocks
and every one discriminates on labels alone (§2): `standard-change` is the
baseline that matches any issue carrying none of the variant labels, and
each variant binds on its own label or labels: `ui`, `docs-only`,
`investigation`, `disposition`, `spec-doc`, `spec-project`, any of
`security-change`, `security-load-bearing`, or `security` (the same set as
policy's `[security].labels`), and the two size labels, `small`
(small-change) and `trivial` (trivial-change). A missing variant label does
not fail; it binds the wrong workflow, exactly one match, and the engine's
zero-or-several refusal structurally cannot see it: no scope warning, no
lint, nothing downstream flags it. Before recording, name the intended
workflow for each issue and check that the labels you are about to record
produce it with the engine's own verbs: `docket workflow list`, then
`docket workflow show <intended>`. The match block prints
`labels_any`/`unless_labels` verbatim from the registered corpus, which is
what actually binds (the tomls under `~/.docket/config` are its source
files and can diverge). The tell to hunt is an issue whose title or scope
lives in a variant's domain while its labels carry none of that variant's
terms: a TUI/UI-scoped issue without `ui` is the canonical case, silently
binding `standard-change` and dropping judge-design from the fanout and the
design-qa/render-verify step. When a related issue on the same exposure
surface carries a security label or rejected security votes (the scope
read surfaces both), recommend the matching security workflow and make the
lighter binding the option that needs justifying, never the default.
Routing domain-flavored work onto the baseline on purpose is legitimate,
but it is an operator decision: elicit it and record it in the issue body
and the plan artifact, never by omission.

**Size labels are yours to apply at filing, and their absence is the same
tell.** A one- or two-file issue that adds no file and whose acceptance
criteria are verifiable from the diff, carrying neither `small` nor
`trivial`, binds the full `standard-change` chain silently. Apply `small`
when the issue declares at most two files in one directory, adds no file,
and every acceptance criterion is verifiable from the diff or a trusted
fenced command; apply `trivial` only to a typo, a config value, a doc line,
or a one-line fix. Never apply either to a security-sensitive issue, to a
ui-scoped issue (one carrying `ui`, or whose files or scope lie under a TUI
or UI surface), or to one carrying any label in policy's `[security].labels`.
Small-change and trivial-change run no copy-verify or render-verify step,
so a ui issue cannot safely skip those checks. If a ui issue already
carries a size label, remove the size label, never the `ui` label, since
stripping `ui` to satisfy small-change's `unless_labels` is the mistake
this rule exists to prevent. An issue meeting both the `small` and
`trivial` conditions binds the judged small-change track, so apply `small`.
Confirm the binding the same way as every other variant, with `docket
workflow show small-change` or `docket workflow show trivial-change`.

**Every issue carries both file surfaces the engine keys collision on: `-f`
for each concrete file its change will touch, and `--scope` for the globs
that bound it.** `docket plan` splits colliding work into sub-phases on `-f`
(an issue with no files never collides there), and this skill's batch
ranking and the scheduler's mutual exclusion read `--scope`; an issue
missing either is not run-ready and is never recorded. The engine keys
exclusion and the lint on `holds_tree`, not on write-ness, and reads an
unset `holds_tree` as true by default. A scope-less issue is treated as
never conflicting (the scheduler's mutual-exclusion rule is permissive, not
conservative); activation emits a scope warning for it and then activates
anyway: the only lint that refuses is a graph cycle. So under
scope-parallel execution its holder runs beside anything and ships
regardless, unless you act on the warning here. An issue without scope
globs is a planning defect, caught here or nowhere.

**An AC that ranges wider than the issue's own scope is the same defect in a
different shape.** Before recording an issue, check every acceptance
criterion (verbatim or derived) whose verification ranges wider than the
union of its scope globs: a tree-wide grep or check against an issue whose
scope only permits editing five directories, say. Either narrow the AC's
range to the scope, or record an explicit disposition for the excluded
remainder: a stop-and-flag rule paired with an AC that excludes the flagged
region, a separate issue, or a documented permanent exclusion. A
stop-and-flag scope rule alone does not license a tree-wide AC: an AC that
can only pass by editing tree the scope forbids is a planning defect,
caught at recording or at verification, and verification is too late.

**A mechanized check with no written mutant is not mechanized.** For every AC
you record with a command beside it, write down the MUTANT: the specific
edit to the file under check that must make that command go red, and show
the command's pre-fix output red against the tree as it stands. A check
whose mutant nobody wrote down is a check nobody has falsified, and it
passes on files that violate the criterion it claims to enforce. If you
cannot state the mutant, the criterion does not carry a command: mark it
**read-verified** explicitly. For an AC you derived, the marking goes in the
AC text. For an operator-stated one, which is copied verbatim, the marking
is recorded beside the criterion and never inside its wording. An AC list
where every line trails a grep, half of which can never go red, is more
misleading than one that says plainly which criteria a human must read.

**Prefer the section-anchored form over the whole-file grep; restate the
pattern where the mutant escapes on what it says, not where it looks.**
Extract the bullet or block the criterion is about first, then assert on
that extract, since a bare `grep -n 'some string' <file>` over a long
document tests only that the string exists somewhere in it. Anchoring the
extract fixes a mutant that deletes or moves the target text but not one
that rewrites the substance while leaving a matched keyword in place: for
example, a revision-range check anchored on the verb still passes a mutant
that turns a two-dot range into a bare ref, or a refusal check anchored on
`rev-parse HEAD` still passes a mutant that softens "refuse" into "note and
continue." For those, restate the pattern to assert the property itself,
the full range shape or the refusal verb alongside the command, rather
than just narrowing where it looks. Where an extract can hold more than one
matching site, assert the negative (the mutated form absent) rather than a
positive match, since a positive pattern can match a sibling site and pass
while the mutant survives. Split the remedy by failure mode: anchor for
scope, restate the pattern for property.

**An AC that needs a live cluster is post-merge by construction, not an AC.**
On GitOps repos, author acceptance criteria as statically verifiable render
assertions (a `kustomize build` / manifest-render check the verify-ac step
can actually run) and record cluster-runtime commands (`kubectl`, `flux`
against the live cluster) in the issue body as post-merge checks instead.
The sandbox cannot reach a cluster, so a runtime AC is unverifiable on every
run by construction.

**Scope that lives in another repository is a mis-filed issue, not a scope.**
When an issue's Change section, scope globs, or an embedded operator ruling
names paths, worktrees, or conventions of another repository, the issue
belongs to that repository's project: create it from that checkout instead
of this one (same title/kind/labels/scope/idempotency-key/body shape) and
record at most a `relates_to` pointer here. A scope glob matching zero
files in this repository is the cheap tell: check every glob against the
tree before recording, and stop-and-ask on a miss. Binding such an issue
anyway is not a plan the run can execute: the executor's isolation contract
and sandbox confine it to this repository, so the step can only gap-file
while the downstream pipeline runs over nothing. The same routing governs
side-findings: an engine defect or another repository's bug surfaced by the
scope read or premise verification files in the owning repo's project, with
at most a `relates_to` pointer here, never as an issue in this run's
project.

**Everything an executor must know goes in the body, before activation.**
Issue bodies snapshot at the activation that binds them, frozen from that
moment: the body is what gets rendered into every brief. Comments added
later never reach a brief. Any operator ruling, settled semantics, resolved
ambiguity, or decision that came out of the conversation above must be
written into the body now, in the issue it governs. "We agreed X in chat" is
not a channel; "it's in a comment on the issue" is not a channel. If a
ruling arrives mid-run, it cannot be back-fitted: it goes into the *next*
planning pass, in a body.

**Scope** is a path glob checked mechanically against the diff: write the
narrowest glob that can honestly hold the change, since scope overlap is
how the engine decides two steps conflict and a broad glob serializes the
run against itself. Conflict is literal-prefix containment, not real glob
intersection (the engine's `scope.go`): everything before the first `*?[{`
is the prefix, and containment either way is a collision, so a brace glob
collides with everything under the head it shares, and a nested glob
collides with the one above it. The prefix is not trimmed back to a
separator, so sibling-looking globs are honestly disjoint:
`internal/db/**` and `internal/dbx/**` do not collide. The trap is a
leading wildcard: `**/*_test.go` has an empty literal prefix, contained in
every scope in the run, so one such glob serializes the whole run against
everything. Prefer prefix-disjoint globs, never lead with a wildcard, and
check them against the matcher's own rules before recording. Require one
concurrent owner per conflicting prefix; truthful overlap across waves is
allowed only with verified serialization under §1b.
Do not narrow away real work to manufacture parallelism. A glob you correct
later goes through `issue edit --scope`, which replaces the whole list
rather than appending; pass every glob you mean to keep. `issue edit -f`
replaces the file list the same way, and `issue file add` appends to it.
Prefer `internal/engine/dispatch/**` over `internal/engine/**`, and several
narrow globs over one wide one. Widen only when the change genuinely spans
that much. An issue that holds the tree and declares no scope draws a scope
warning at activation, not a refusal: the engine will ship it, so the
warning is yours to act on, and the way to answer it is narrow globs, never
a wide one that silences it by colliding with everything.

**The edges**, recorded as `depends_on` links, are real dependencies only: a
false edge serializes work that could have run in parallel, and a missing
one lets a step run before its input exists. The default is no edge: an
edge is a thing you justify, never a thing you assume. Before writing one,
name the input in a phrase you could put in the plan artifact: the file,
artifact, schema, or decision that B's step reads and A's step is what
produces. "B builds on A", "A should land first", "it reads more naturally
in that order", and "same subsystem" are orderings, not dependencies: drop
the false edges and place the issues in their earliest safe waves. Two
issues whose scopes are prefix-disjoint rarely carry a true edge between
them, so when you find yourself writing one anyway, suspect the
decomposition before the ordering: the shared thing usually belongs inside
one issue, or in a third that both of them depend on, which costs one edge
each instead of a chain. Prefer a shallow fan (many issues depending on one
root) to a chain (each depending on the last): the fan lets the children
become dependency-ready together, while the chain releases one at a time;
collisions still constrain which children can run concurrently. Count the
edges you are about to record and check the resulting graph's width against
the wave arithmetic above; a package where every issue depends on the one
before it is a serial plan wearing a graph's clothes.

**Planning from a single existing backlog issue** (`/docket-plan DKT-N`):
four obligations, each checked independently before recording. This is the
single-issue intake only: DKT-N here is a finding or a problem statement the
run decomposes into fresh issues. The bare-`/docket-plan` batch (§1b) is the
other case: its members have already passed the run-readiness check and
are the units of work, so §1b binds them with `--issue` directly and none of
the four obligations below apply to them. The two paths do not contradict
each other; they answer different questions about what the issue is:

- DKT-N itself stays out of the run: the fresh issues you create are the
  ones you `run start --issue`; never name DKT-N itself there.
- The issue that settles it carries, in its body, "resolve DKT-N" as a required
  deliverable: a written verdict with file:line evidence.
- Add `<new> relates_to DKT-N` as a link.
- DKT-N closes on the run's outcome, never by fiat at plan time. A verdict
  worth recording on DKT-N itself goes in a comment there, later, since it
  is tracker-side, outside the run, so the body-freeze rule does not apply
  to it.

## 4. Leave later phases uncomposed when you honestly cannot compose them

Some requests cannot be planned to the end: "audit and then build what we
find" does not have a knowable second half. Do not invent one. Record phase one
fully, and record phase two as a single human-gate issue that says what will be
decided and by whom.

The run activates on phase one. When phase one finishes, the operator answers
the gate, and a *fresh* invocation of this skill reads the run record (steps,
findings, gate notes) and appends phase two. Reading those artifacts is a
pair of verbs: `docket step artifacts STEP-N` lists ids, then `docket step
artifact ARTIFACT-N [--payload]` prints one; there is no `docket artifact`
command. Activation lints the extension like any other graph.

This is a designed shape, not a fallback. Use it whenever the honest answer to
"what are the phase-two issues" is "that depends on what phase one finds."

## 5. Present and stop

If §1 or §1b concludes with nothing to record (the operator chose "propose
only", or no feasible startable run remains after the full checks), present
your reasoning as given and stop; run no further commands.

Otherwise, once the recording commands above have run, present the recorded
run: total issue count, the issues, their edges, scopes, Unlimited or explicit
budget limits, the separate cost forecast, planned waves, and `First-wave
width` accounting for both dependencies and collisions. State why any
otherwise eligible work remains outside this run, and say plainly where the
approval to activate lives now: it is a tribunal vote that `docket-run`
convenes and surfaces when the run is driven. Then stop.

Do not offer to activate it yourself as a convenience. Do not start the run.
Do not keep the plan in your head for later; it is in Docket now, which is
the point.

If the operator asks for activation in this session, that is a direct
instruction that outranks the panel that would otherwise vote on it: run the
activate verb on their words (`--dry-run` first, since it is the same
transaction rolled back) and then hand off to `docket-run` in-session by
invoking the skill. The handoff through `docket-run`, which surfaces the
drive/park/abandon choice to the operator, is the designed path even when
you activate directly; a silent stop is not permission to skip it.
