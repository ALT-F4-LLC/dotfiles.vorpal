---
name: plan
description: Turn a work request into an activatable Docket run — converse until the request is unambiguous, then record the request, a plan artifact, and issues with kinds, labels, scopes, depends_on relations, and verbatim acceptance criteria. Invoked bare (`/plan` with no request and no issue id) it instead surveys the current Docket project's open backlog and proposes the most optimal next batch — ready, highest-priority, parallel-safe, run-ready, within a stated budget — then on confirmation records that batch as a run binding the backlog issues directly. Records and stops; never runs the work. Use at the start of a piece of work, to pick the next batch off the backlog, or to extend a run's later phase after execution has learned something.
---

# plan

You are the intake. Conversation happens here and nowhere else in the run —
deciding what the work *is* is a judgment, so it belongs to a human and to you
together, in this skill, before any executor exists.

Three rules you must not fight:

- **You record; you never execute.** You do not spawn anything or start work,
  and you never activate unprompted. Activation is a gate you do not hold:
  approving it is a tribunal vote that `conduct` convenes and surfaces, so what
  you hand over is the recorded run itself, never a promise that a question is
  waiting for the operator. If they ask for activation in this session, §5 has
  the path.
- **You never observe execution.** When you stop, you are done. Re-planning is a
  *fresh* invocation of this skill that reads the run record — not this one
  continuing to watch.
- **Acceptance criteria are copied verbatim.** Whatever the operator states as
  done-ness goes into the issue body word for word. You may add ACs you derived
  and say you derived them; you may not paraphrase theirs.
- **A derived AC that predicts command output is run before it is recorded.**
  Execute the command — non-mutating check commands only, which is all this
  class of AC ever quotes — against the COMMITTED tree the run will verify on
  and paste what it actually printed. Output quoted from any transcript is a
  FACT to verify, not a source — transcripts capture transient states (a
  staged-deletion snapshot put an impossible expected string into an AC; a
  judge caught it one step before the verify gate would have hard-failed it).

**Two intakes, picked by the argument.** `/plan <request>` and `/plan DKT-N`
enter at §1 — the conversation decides what the work is. Bare `/plan` — no
request, no issue id (the literal word `backlog` counts as bare) — enters at
§1b: the backlog already says what the work is, and the conversation decides
which of it goes next. Both intakes record through §3 and stop at §5.

Every `RUN-N` and `DKT-N` cited below is a lesson from the PRE-RESET store
epoch. The episodes are real; the ids are not — the store has since been reset,
so those numbers now name unrelated live entities. Read them as history, never
resolve one against the current store.

## 1. Converse until it decomposes

**A supplied brief block seeds this section — do not re-ask what it already
answered.** If the operator's message carries a `brief` skill block (labeled
`Goal:` / `Motivation:` / `Scope:` / `Out-of-scope:` / `Acceptance criteria:`
/ `Size hint:` / `Security-sensitive:` / `Constraints:`), read it as
already-settled input to the table below: Goal -> Goal, Constraints <-
Constraints plus Out-of-scope, Acceptance criteria <- Acceptance criteria
(still copied verbatim, per the rule below), Security sensitivity <-
Security-sensitive, Size <- Size hint. Ask only about a field the block
leaves as "not stated"/"not specified", or a contradiction the §2 read
surfaces — never re-run the whole round for fields it already settled.

Ask about what you genuinely cannot decompose without. Batch your questions —
one round of three beats three rounds of one. Stop asking when you could write
the issues; ambiguity that does not change the decomposition is not your
problem to solve.

Every question goes through the built-in question tool, every round — including
open-ended asks like acceptance criteria, where you offer drafted candidates as
options and the operator's selection or typed text becomes the verbatim source.
If later verification refutes a FACT inside operator-selected text, strike the
false premise, keep the criterion, and annotate the change with the evidence in
the body — re-ask only if the correction changes what the operator would decide
(RUN-5: a flake-artifact baseline was recorded into AC1 and corrected this way).
Put your recommended option first, labelled "(Recommended)". A prose question
costs the operator a redirect (it did, 2026-08-06); an exclusive-meaning label
("X only", "neither") never belongs in a multi-select option set — a set
that needs one is a single-select question.

**Every question in this skill is the operator's, and no panel's.** Elsewhere
a three-judge tribunal now clears batches of proposed definition fixes; it is
the wrong instrument here and you do not convene one. What the work IS — the
goal, the constraints, the done-ness, the security answer — is intent, and
intent has exactly one source. A panel asked to supply it would return a
confident guess, which is the failure this whole section exists to prevent.

The five things you need:

| | What you are after |
|---|---|
| **Goal** | What is true when this is done that is not true now |
| **Constraints** | What it must not break, touch, or exceed — including budget |
| **Acceptance criteria** | How done-ness is checked, in the operator's words |
| **Security sensitivity** | Does this touch authn/authz, secrets, crypto, sandbox, trust, or supply chain |
| **Size** | Roughly how many issues, and whether the shape is knowable up front |

Security sensitivity is asked, not inferred. It sets labels that pin routing
later, and a wrong guess is silent — so if the answer is not obvious from the
request, ask it outright. Security is one instance of a general fact: labels
are the ONLY discriminator that routes an issue to its workflow, and §3 makes
confirming each issue's intended binding a recording obligation.

## 1b. Bare `/plan`: propose the next batch from the backlog

The request here is the backlog itself, so §1's questions are mostly already
answered — by the issues' own bodies. What you owe the operator instead is a
ranked proposal and one confirmation round. Everything in the three rules at
the top still holds: you record, you never activate, and the ACs already in
the bodies are the ACs — you do not rewrite them.

**Survey** (commands you run; the operator types none of them):

```bash
docket next --json=v2 --limit 1000                    # ready: no open blockers, in backlog/todo
docket issue list --json=v2 --limit 1000 -s backlog -s todo   # every field the ranking reads
docket run status --active --json                     # runs that already own issues
docket issue list --run <ref> --json=v2 --limit 1000  # one per run above: its roster
```

Project resolves from cwd's git identity, same as every other docket verb.
A `VALIDATION_ERROR` naming no project, or no store reachable, means this
repo isn't bound — say so and stop. `--limit 1000` is not optional: `issue
list` caps at 50 and `next` at 10 by default, and neither output flags the
truncation — a 108-issue backlog was surveyed as 50 and reported complete
(groom/tend fix, 2026-08-21). `docket next` is the readiness verb: it
returns only issues with no incomplete `depends_on` blocker, so a backlog/todo
issue it omits is blocked and stays out of the batch. Join its ids against the
`issue list` rows, which carry `priority`, `labels`, `scope`, `assignee`, and
`description` (verified 2026-08-21 on `--json=v2`; `next` is for the ids).

**Exclude what is not free** — this queue isn't plan's alone, and the
definitions are the ones `groom` and `tend` already use:

- **Run-included.** An open issue on any active run's roster (`docket run
  status --active --json`, then `docket issue list --run <ref> --limit
  1000` per run —
  planning, active, or paused, anything not done or abandoned) belongs to
  that run's plan/conduct session, even while the run is parked.
- **Claimed.** Any issue with a non-empty `assignee` — someone or something
  else already has it.

Both are listed in the proposal under "not free", never silently dropped.

**Rank what remains, in this order** — the operator's own definition of the
most optimal batch, settled 2026-08-21 ("ready, high-priority, parallel-safe"):

1. **Ready** — in `docket next`'s set. Blocked issues are deferred with the
   blocker named; they are next batch's candidates, not this one's.
2. **Highest priority first** — `critical` > `high` > `medium` > `low` >
   `none`; ties break on id ascending (older first).
3. **Parallel-safe** — walk down the ranked list and admit an issue only when
   its scope globs are prefix-disjoint from every glob already in the batch,
   by the matcher's own rules in §3: the literal prefix before the first
   `*?[{`, containment either way is a collision, no trim back to a
   separator, and a leading wildcard collides with everything. A colliding
   issue is deferred with the glob pair named, whatever its priority: a
   batch that serializes against itself is not the optimal one, it is the
   slow one. Two ready issues never carry an edge between each other
   (readiness means no open blocker), so the batch has no internal
   `depends_on` by construction — an issue the operator pulls in from the
   deferred list brings its own edge with it.
4. **Run-ready** — every §3 recording obligation the bound workflow will
   check at activation, checked here first: the body carries acceptance
   criteria (at least one checkable item, not a restated title); the labels
   produce the intended workflow under `docket workflow show <intended>`
   (§3's labels-confirm-binding rule — a domain-flavored issue carrying none
   of its variant's labels binds the baseline silently); `--scope` is set
   when the bound workflow holds the tree, and every glob matches at least
   one file in this checkout. An issue that fails is not run-ready: list it
   under "not ready" with the missing thing named. The operator may have you
   fill it in this session — `docket issue edit` for labels, `--scope`, or a
   body with ACs in the operator's words, fine until the activate that binds
   it — or send it to `/groom`; you never fill ACs from your own guess.
5. **Fits the stated budget** — size each admitted issue by §3's arithmetic
   (the bound workflow's expected-cost floor with when-gated steps included,
   plus rework headroom: one fix-loop round per two issues on
   standard-change, three rounds per issue on security-load-bearing) and
   take issues in rank order until the next one would breach the cap. No
   cap stated yet means the confirmation round asks for one — it is an
   operator-only question, so it goes in that same round, not a second.

**Read before you propose.** §2 applies unchanged, narrowed to the candidate
batch: spawn ONE `executor-read` agent over the candidates' scope globs — do
the globs match files, has any candidate's fix already landed (`git log`
over its globs since the issue's `created_at`), and does any pair collide
under the matcher's rules — with the verbatim send-your-report sentence §2
quotes, and wait for it the way §2 says: end the turn, one long-fallback
wakeup, no probing. An issue whose work is already on HEAD is not a batch
member; it is a comment on that issue and a line in the proposal.

**Propose, in ONE question round.** Present the proposal as prose above the
question, then ask through the built-in question tool — never as a prose
question:

- the batch, ranked: id, title, priority, labels → the workflow they bind,
  scope globs, expected cost, and the one-line reason it ranks where it does;
  the running total against the cap;
- deferred, with the reason each time: blocked by DKT-N / collides with DKT-N
  on `<prefix>` / not free (run RUN-N, or assignee) / not ready (what is
  missing) / already landed (commit);
- one single-select question, recommended option first: record this batch as
  a run (Recommended); record a subset or a different set — the operator
  names it as typed text; propose again under a different cap; propose only —
  stop here and record nothing. Plus the budget question if no cap was stated.

An empty ready set is a finding, not a failure: say what the survey found —
nothing open, everything blocked, everything claimed or run-included, nothing
run-ready — and stop; `/groom` is the skill for a backlog that is full but
not ready, and you name it rather than grooming here.

**On "record", go to §3 with the batch as the roster.** The differences from
request intake are exactly these, and nothing else in §3 relaxes:

- No `issue create`: the issues exist. Run-readiness fills the operator
  approved in the round land through `docket issue edit` BEFORE `run start`,
  and a corrected glob list passes every glob you mean to keep.
- `run start --issue` names the backlog issues themselves — direct binding
  is the operator's settled choice for batch mode (2026-08-21), and it is
  what makes the §3 `/plan DKT-N` obligations NOT apply here: a batch member
  is the unit of work, not a question the run answers.
- `--request-file` holds the invocation and the operator's confirmation
  verbatim — the option they picked and any text they typed — because that
  is what was asked; the ranked proposal is not a substitute for it.
- The plan artifact carries the ranking rationale, the deferred list with
  its reasons, and the budget arithmetic, written for the person who reads
  this run in three months and wonders why DKT-N waited.
- `--budget` is the cap the round settled, sized by §3's arithmetic.

Then §5: present the recorded run and stop. The same planner, invoked bare
again after this run closes, finds the deferred list waiting as next batch's
ready set — that is the shape, not a shortcoming.

## 2. Read before you decompose

Guessing at scopes produces issues that fail their scope gate at execution
time, which is expensive and late. Read instead — through an agent: spawn ONE
`executor-read` agent while the conversation continues, returning a scope
map — and the premise verdict, when the request rides on one ("already
fixed", "already done") — and never survey the repo yourself — engine-contract
reads (CLI help, the workflow corpus under `~/.docket/config/`, the
scope-matcher's own rules) are yours; the repo survey is the agent's. You are the intake, and your context belongs to the
conversation, not to directory listings.

**While the reader runs, ask operator-only questions and hold premise-riding
ones.** Operator-only — preferences, authorizations, budget, anything whose
answer does not move with repo state — goes in the early round as §1 says.
Premise-riding — anything whose framing assumes a repo fact the reader is at
that moment checking ("how should this already-fixed blocker route") — waits
for the verdict, even if that costs a later round. §1's "one round of three"
still holds; this only decides which round a question belongs in. Asking on an
unverified premise buys a correction plus a second round, which is the more
expensive outcome (2026-08-20: a planner asked how an open blocker should
route, then had to open with "correction to what I told you earlier" when the
verdict two minutes later showed it already fixed on HEAD).

**Every delegate brief ends with this sentence, pasted verbatim** —
unconditionally, whatever the spawn mechanism, with no rewording and no
paraphrase:

> When finished, SEND your complete report to team-lead via SendMessage. Your
> final text is delivered to no one; going idle without sending is a failure.

Copy those two sentences onto the end of the brief exactly as written; do not
restate them in your own words. The mechanism is not knowable at brief-writing
time, and background spawns run as in-process teammates whose final text is
delivered to no one; a redundant send costs one duplicated message, a missing
one costs the report. Three planners have now inverted this instruction while
the rule sat in their context: RUN-5's reader composed its report as final text
no one received; RUN-7's reader repeated it when its brief said "no separate
send needed" — never write that into a brief; and a 2026-08-20 planner told its
scope reader that its final text "is delivered directly back to me", then spent
a recovery round-trip nudging the idle agent before the report arrived. Every
one of those briefs paraphrased the rule instead of pasting it, which is why
the sentence above is quoted rather than described.

Any engine fact the brief carries — run
status, issue ids, branch state — comes from a fresh `docket run
status`/`issue list` read in THIS session, never from memory of prior
sessions: the reader verifies the tree, not the engine, and a mis-premised
brief spends its report correcting you (measured). The agent's brief:

The layout tells you scopes — which directories a change of this shape actually
touches, narrow globs per area. `ls ~/.docket/config/workflows/` tells you which
workflows exist to bind to — activation auto-registers them from the config
roots, so `docket workflow list` reads empty on a store that has not activated
yet and is not the corpus. LABELS are what bind: every `[match]` block routes on
`labels_any`/`unless_labels` and none of them look at kind, which is a closed
field (`bug feature task epic chore`, enforced by `issue create -T`) that routes
nothing. Labels route INSIDE a bound workflow too, via `when`-gated steps: a
`spec-doc` issue picks its author by the COLON-form doc label — `doc:tdd`,
`doc:adr`, `doc:ux-spec`; no doc label means PRD — and `security` /
`security-load-bearing` push a TDD to the security author, so file
doc-producing issues with `doc:<type>` or accept the PRD default (the hyphen
spellings route nothing). `git log --format='%s' -30` tells you the repo's
conventions. Existing
issues (`docket issue list`) tell you whether some of this is already tracked.

**When the read contradicts the request's premise, verify before recording.**
A scope map that says "this bug looks already fixed" changes the run's shape;
spawn a second read-only agent to settle it — a forced verdict taxonomy, the
hole hypotheses named, reproduction in an isolated scratch dir — while the
conversation continues. The run record must not encode a premise a read has
already cast doubt on. (RUN-2: the verifier found the reported mechanism fixed
and a different one real; the recorded issues were built on the truth.)

**Your reader's reply cannot reach you mid-turn — and your own turn is what
blocks it.** Teammate messages deliver at turn boundaries only, so waiting
means ENDING THE TURN: schedule ONE long-fallback wakeup (15+ minutes) and
stop. ScheduleWakeup does not end a turn, and probe calls — ListAgents (which
does not list a busy in-process delegate), re-schedules, tool searches — keep
the turn alive and block the very delivery you are waiting on. A 2026-08-11
planner probed for 40 seconds inside one unbroken turn, declared its reader
dead 114 seconds after spawning it, and recorded solo; the "missing" report
was queued the whole time and delivered the same second the turn finally
ended. A delegate is not failed until a wakeup has actually FIRED and found
nothing, and there is no fallback allowance to re-derive its brief inline — a
solo re-derivation under time pressure is how RUN-2's first record missed a
test that already existed, and how that planner's solo scopes missed every
test file its reader had already mapped. If the operator's pace forces
recording before the reply lands, mark the bodies PROVISIONAL in so many
words and reconcile the moment it arrives — a body stays editable until the
activate that BINDS it, which is the whole `planning` window and, for an
issue added to an already-active run, up to the next activate. That window is
the net, and it only nets what you marked. And when the reader's
report has been folded in and no follow-up question remains, STOP the
delegate (TaskStop) in the same turn: an idle reader wakes you into no-op
turns with idle notifications and otherwise waits for the operator to kill
it by hand (measured in seven of nine multi-agent sessions in one fleet, up
to fifteen hours of idle seat). Cancel any fallback wakeup still armed, or
treat its late fire as a self-discarding no-op.

## 3. Record the run

In this order. Under the global store every docket verb opens `~/.docket`
read-write and migrates before it does anything, so the seat you run from needs
write access to that path — a sandboxed seat is fine wherever `~/.docket` is in
the sandbox's write allowlist, which it normally is. `unable to open database
file` is the symptom when it is not, and it is the only evidence that justifies
asking for an unsandboxed seat (`--help` alone never opens the store). Every
command is one you run; the operator types none of them.
First, if the scope read or premise verdict is more than a few minutes old,
re-check it now: one `git log --since=<read time>` over the scoped paths. A fix
that lands between the read and the record otherwise becomes a bound issue whose
implement step exists to discover the work is done (RUN-8: DKT-99's fix was
committed nine minutes before `run start` recorded it as work to do).

```bash
docket issue create -t "<title>" -T <kind> --idempotency-key <key> \
  -l <label> --scope '<glob>' -d - < <body-file>  # one per unit of work
docket issue link add DKT-<n> depends_on DKT-<m>  # the graph's edges
docket run start --request-file <path> \
  --budget <cap> --issue DKT-<n> --issue DKT-<m>  # request verbatim; issues must exist first
docket doc create -T plan -t "<title>" --idempotency-key <key> -d @<path>  # the plan artifact
```

Issues first: `run start --issue` names them, so they must already exist —
RUN-2's planner discovered the reverse order cannot work. The set is not frozen
there: `docket run issue add RUN-N DKT-N...` attaches and `run issue remove`
detaches while the run is in `planning`, and `add` still works on an `active`
run, where the next activate binds the newcomers as it would a later phase.
ACTIVATION is the freeze, not `run start` — so a list that turns out short costs
an add, not the abandon-and-restart it cost RUN-4 → RUN-5. `--idempotency-key`
makes the creates re-runnable: the same key returns the original entity, never a
duplicate. Flag shapes differ by verb and it matters: `issue create -d` takes a
literal string (`-` reads stdin); the `@<path>` form belongs to `doc create`
alone — followed blindly, every issue body becomes the literal text
"@/path/file", frozen at activation into every brief. Help-check each verb's
flags on first use in a session; the CLI is the authority, not this block.
`--budget` records the cap you elicited in §1 — and you size that cap here
rather than guess it. The FLOOR is the bound workflow's expected-cost sum with
its when-gated steps INCLUDED: a `when` you cannot evaluate at plan time is a
step that may well run, and a floor that omits it is a floor for a run that
did not happen. On top of the floor goes REWORK HEADROOM — at least one full
fix-loop round per two issues. Standard-change's round is fix 1.0 plus four
judges at 0.6 plus synthesize 0.4, so 3.8, and half the issues this epoch took
one. For security-load-bearing budget THREE rounds per issue: rejection-driven
loops are that track's normal case — both complete runs to date had every
security vote rejected at least once, and RUN-34, sized on two rounds (cap
14), hit its wall on the THIRD normal-case fix pass and paid two mid-run
raises to close at 20.9, floor plus three rounds almost exactly (a round is
fix 1.0 + five judges at 0.6 + synthesize 0.4 ≈ 4.4). Price only the track's
normal case into the cap: a round nobody could have planned — an operator's
out-of-band commit needing independent review mid-run — is what the raise
machinery is FOR, not a sizing failure. A cap that is short by arithmetic is
not discipline, it is a
tribunal you scheduled for yourself: RUN-3 walled before it dispatched
anything and spent ~20 minutes raising, 22% of its wall clock; RUN-17 left 0.4
of headroom over a two-issue base and raised 10 -> 18 through two serial
votes; RUN-18 raised 12 -> 20 with 23 minutes of idle; RUN-29 raised three
times, 5 -> 9 -> 12 -> 20, and spent 15, three times its plan. The raise
machinery is for work that turned out harder than it read — not for a sum you
could have taken here (RUN-4's cap of 3 against a 4.8-cost workflow forced a
mid-run raise panel and serialized its review fanout). Round UP and say what
the headroom is for; an unspent cap costs nothing. (`docket run budget --set
<n> --reason '<why>'` adjusts it later, with `--if-version` when a concurrent
change would matter). Ids render with each
project's prefix — the store is machine-global and the number is the identity,
so `DKT-<n>` and a bare number parse in any project.

**The request** goes in verbatim via `--request-file`. It is the run's own
record of what was asked; your summary of it is not a substitute.

**The plan artifact** is prose, and it is the one place your reasoning is
allowed to live: the decomposition rationale, the risks you see, the phasing you
suggest, and anything you asked about that turned out to matter. Write it for
the person who reads this run in three months.

**The issues** carry kind, labels, scope globs, and the ACs in the body.

**Labels are the issue's ROUTING, and you confirm the binding before you
record it.** Binding is exactly-one-match over the corpus's `[match]` blocks
and every one of them discriminates on labels alone (§2): `standard-change` is
the baseline that matches any issue carrying NONE of the variant labels, and
each variant binds on exactly one — `ui`, `docs-only`, `investigation`,
`security-load-bearing`, `spec-doc`, `spec-project`, `release`, `retro`. So a
missing variant label does not fail — it binds the WRONG workflow, exactly one
match, and the engine's zero-or-several refusal structurally cannot see it: no
scope warning, no lint, nothing downstream flags it. Before `issue create`,
name the intended workflow for each issue and check that the labels you are
about to record produce it with the engine's own verbs: `docket workflow
list`, then `docket workflow show <intended>` — the match block prints
`labels_any`/`unless_labels` verbatim from the REGISTERED corpus, which is
what actually binds (the tomls under `~/.docket/config` are its source files
and can diverge; a raw grep over them has also blown the output cap where
one read verb answered). The tell to hunt is an
issue whose title or scope lives in a variant's domain while its labels carry
none of that variant's terms: a TUI/UI-scoped issue without `ui` is the
canonical case (harness HRN-3, 2026-08-16 — "TUI: default on-load screen to
home", scope `internal/tui/**`, `labels=[]` — bound `standard-change`
silently, dropping judge-design from the fanout and skipping the terminal
design-qa/render-verify step; one tribunal seat caught it at the activation
gate, after which the binding was frozen for the whole run). When a related issue on the same exposure surface carries a security label or
rejected security votes — the scope read surfaces both — recommend the
matching security workflow and make the lighter binding the option that needs
justifying, never the default (an activation panel rejected a
`standard-change` recommendation for exactly this, costing a re-plan). Routing
domain-flavored work onto the baseline ON PURPOSE is legitimate, but it is an
operator decision: elicit it and record it in the issue body and the plan
artifact — never route by omission.

**Every issue whose workflow binds a tree-holding step carries `--scope`.** The
engine keys exclusion and the lint on `holds_tree`, not on write-ness, and reads
an unset `holds_tree` as TRUE — "does it hold the tree" is the question, and it
is answered yes by default. A scope-less issue is treated as NEVER
conflicting (S1 is permissive, not conservative); activation emits a scope
warning for it and then activates anyway — the only lint that refuses is a graph
cycle. So under scope-parallel execution its holder runs beside anything and
ships regardless, unless you act on the warning here: RUN-5 shipped its
verify-everything-and-commit issue scopeless and only a shadow noticed. A
tree-holding issue without scope globs is a planning defect, caught here or
nowhere.

**An AC that ranges wider than the issue's own scope is the same defect in a
different shape.** Before recording an issue, check every acceptance
criterion — verbatim or derived — whose verification ranges wider than the
union of its scope globs: a tree-wide grep or check against an issue whose
scope only permits editing five directories, say. Either narrow the AC's
range to the scope, or record an explicit disposition for the excluded
remainder — a stop-and-flag rule PAIRED with an AC that excludes the flagged
region, a separate issue, or a documented permanent exclusion. A stop-and-flag
scope rule alone does not license a tree-wide AC: an AC that can only pass by
editing tree the scope forbids is a planning defect, caught at recording or
at verification — and verification is too late. DOT-3 shipped an AC requiring
a tree-wide grep to return nothing while its own scope forbade editing
outside five directories plus README.md; seven archival files outside that
boundary held matches, so the AC was unsatisfiable as worded and the
contradiction surfaced only at verification, recorded as DOT-4.

**An AC that needs a live cluster is post-merge by construction, not an AC.**
On GitOps repos, author acceptance criteria as statically verifiable render
assertions — a `kustomize build` / manifest-render check the verify step can
actually run — and record cluster-runtime commands (`kubectl`, `flux` against
the live cluster) in the issue body as post-merge checks instead. The sandbox
cannot reach a cluster, so a runtime AC is unverifiable on every run by
construction: across three manifest-flux runs, all 7 cluster-command ACs
came back "unverifiable" and the AC gate delivered zero assurance (operator
ruling 2026-08-19, FLX-137/FLX-138).

**Scope that lives in another repository is a mis-filed issue, not a scope.**
When an issue's Change section, scope globs, or an embedded operator ruling
names paths, worktrees, or conventions of ANOTHER repository, the issue
belongs to THAT repository's project: file it from that checkout (cwd picks
the project) and record at most a relates_to pointer here. A scope glob
matching ZERO files in this repository is the cheap tell — check every glob
against the tree before recording, and stop-and-ask on a miss. Binding such
an issue anyway is not a plan the run can execute: the executor's isolation
contract and sandbox confine it to this repository, so the step can only
gap-file while the downstream pipeline runs over nothing. The same routing
governs side-findings (operator ruling, 2026-08-16: gaps belong to their
respective projects): an engine defect or another repository's bug surfaced
by the scope read or premise verification files in the OWNING repo's project
— `docket issue create` from that checkout — with at most a relates_to
pointer here, never as an issue in this run's project.

**Everything an executor must know goes in the BODY, before activation.** Issue
bodies snapshot at the activation that binds them, frozen from that moment — the
body is what gets rendered into every brief. Comments added later never reach a
brief. So any operator ruling, settled semantics, resolved ambiguity, or decision
that came out of the conversation above must be written into the body now, in the
issue it governs. "We agreed X in chat" is not a channel; "it's in a comment on the issue"
is not a channel. RUN-3 had a gated-inclusion ruling live only in a comment, and
the executor reasoned around it in a vacuum — it did the wrong thing correctly,
because the right thing never reached it. If a ruling arrives mid-run, it cannot
be back-fitted: it goes into the *next* planning pass, in a body.

**Scope** is a path glob checked mechanically against the diff — write the
narrowest glob that can honestly hold the change. Narrow is not a style
preference here: scope overlap is how the engine decides two steps conflict, so a
broad glob serializes the run **against itself**. RUN-3's `internal/engine/**`
made every issue collide with every other issue, and ~40% of all spawns died on
claim conflicts as a result. And conflict is LITERAL-PREFIX containment, not real
glob intersection (the engine's `scope.go`): everything before the first `*?[{`
is the prefix, and containment either way is a collision — so a brace glob
collides with everything under the head it shares, and a nested glob collides
with the one above it, regardless of what they'd actually match. The prefix is
NOT trimmed back to a separator, so sibling-looking globs are honestly disjoint:
`internal/db/**` and `internal/dbx/**` do not collide. The trap is a LEADING
wildcard — `**/*_test.go` has an EMPTY literal prefix, which is contained in
every scope in the run, so one such glob serializes the whole run against
everything and nothing warns you. Write prefix-disjoint globs (one owner per
directory prefix), never lead with a wildcard, and check the partition against
the matcher's own rules before recording it. A glob you correct
later goes through `issue edit --scope`, which REPLACES the whole list rather
than appending — pass every glob you mean to keep. Prefer
`internal/engine/dispatch/**` over `internal/engine/**`, and several narrow globs
over one wide one. Widen only when the change genuinely spans that much — an
honest wide glob is fine, a lazy one costs the whole run. An issue that holds the
tree and declares no scope draws a scope warning at activation, not a refusal:
the engine will ship it, so the warning is yours to act on — and the way to
answer it is narrow globs, never a wide one that silences it by colliding with
everything.

**The edges** are `depends_on` relations. Declare only real dependencies:
a false edge serializes work that could have run in parallel, and a missing one
lets a step run before its input exists.

**Planning FROM a single existing backlog issue** (`/plan DKT-N`) — four
obligations, each checked independently before `run start` (RUN-7's first
body carried three and dropped the deliverable; a shadow caught it inside the
planning window). This is the single-issue intake only: DKT-N here is a
finding or a problem statement the run DECOMPOSES into fresh issues. The
bare-`/plan` batch (§1b) is the other case — its members have already passed
the run-readiness check and ARE the units of work, so §1b binds them with
`--issue` directly and none of the four obligations below apply to them. The
two paths do not contradict each other; they answer different questions about
what the issue is:

- DKT-N itself stays OUT of the run — create fresh run issues; never bind it
  with `--issue`.
- The issue that settles it carries, in its BODY, "resolve DKT-N" as a required
  deliverable: a written verdict with file:line evidence.
- Link `issue link add <new> relates_to DKT-N`.
- DKT-N closes on the run's outcome, never by fiat at plan time. A verdict
  worth recording on DKT-N itself goes in a comment there — it is tracker-side,
  outside the run, so the body-freeze rule does not apply to it.

## 4. Leave later phases uncomposed when you honestly cannot compose them

Some requests cannot be planned to the end — "audit and then build what we
find" does not have a knowable second half. Do not invent one. Record phase one
fully, and record phase two as a single human-gate issue that says what will be
decided and by whom.

The run activates on phase one. When phase one finishes, the operator answers
the gate, and a *fresh* planner invocation reads the run record — steps,
findings, gate notes — and appends phase two. (Reading those artifacts is a
pair of verbs: `docket step artifacts STEP-N` lists ids, then `docket step
artifact ARTIFACT-N [--payload]` prints one — there is no `docket artifact`
command.) Activation lints the extension
like any other graph.

This is a designed shape, not a fallback. Use it whenever the honest answer to
"what are the phase-two issues" is "that depends on what phase one finds."

## 5. Stop

Present the plan — the issues, their edges, the scopes, the budget — and say
plainly where the approval to activate lives now: it is a tribunal vote that
`conduct` convenes and surfaces when the run is driven. Then stop.

Do not offer to activate it yourself as a convenience. Do not start the run.
Do not keep the plan in your head for later; it is in Docket now, which is the
point. When the run is to move, `conduct` takes it from there and carries the
activation through that gate.

If the operator asks for activation in THIS session, run the activate verb on
their words (`--dry-run` first — it is the same transaction rolled back) and
then hand off to `conduct` in-session by invoking the skill — a direct
instruction from the operator outranks the panel that would otherwise have
voted on it, and it is the only route to activation from this seat. If a run-guard hook
is installed on this seat, it will deny a plain stop while executable work is
pending — that deny is a guard answering, not an instruction to start driving.
Whether or not it fires (today the Stop→run-guard IS registered and fires on
every stop; it allows a stop while the run is merely `planning` — measured
2026-08-11), the handoff through `conduct` — which surfaces the
drive/park/abandon choice to the operator — is the designed path, and a silent
stop is not permission to skip it.
