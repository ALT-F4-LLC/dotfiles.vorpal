---
name: docket-groom
description: Groom every open issue in the current Docket project and the Docket engine project in the main session until retained work is easy to consume. Validate value and engine relevance, verify and repair every acceptance criterion, triage issues needing operator decisions through AskUserQuestion, retire approved obsolete or duplicate work, group retained work under relevant Docket epics, and close gaps in requirements, files, scope, dependencies, and workflow fit. Safe edits apply directly; closures, merges, scope changes, epic creation, re-parenting, and protected-issue edits require operator approval. One survey across both projects with an optional stale window, including decision follow-through; no implementation or watch. Use on "groom the backlog", "/groom", "clean up the backlog", "triage operator decisions", "which issues are still worth doing", or "make the backlog run-ready".
argument-hint: "[stale window, e.g. 14d]"
model: fable
---

# docket-groom

Run one grooming pass over the current project's open issues and the
Docket engine project's open issues, including engine defects and capability
gaps filed by other Docket skills. Close every grooming gap so retained work
is valuable, clear, and consumable without reconstructing context or asking
the operator to re-settle an existing ambiguity: judge value, resolve missing
facts, triage operator decisions, group retained work under the epics it
serves, and apply the resulting authorized edits. A groomed backlog reads as
a short list of outcomes with their member issues, not a flat list. Seek a
backlog of valuable work, with no target issue count or closure quota.
Identifying a gap or listing a question does not resolve it.

Run this skill inline in the main session: keep the survey, ledger, edits,
proposal gate, and final report here, since §4 needs the main session's
`AskUserQuestion` tool. Do not delegate the pass or the approval gate to a
subagent, or rely on one to ask the operator, send a live message, or arrange
a later handoff.

Take a fresh survey for this invocation. Use `$ARGUMENTS` for the optional
stale window and honor the operator's explicit constraints in this session,
but treat earlier issue reads or backlog discussion as stale, not current
evidence. Maintain one ledger through approval and execution so the report
covers the whole pass.

One pass includes the decision rounds and affected-issue rechecks needed to
finish grooming the surveyed backlog; it does not end at the first operator
question. It takes no parameter beyond the optional stale window, does not
repeat the survey or watch for new work, schedules no wakeups, and never
touches the code the issues describe. If a gap cannot be resolved within the
pass's authority or available evidence, report that work as incomplete
rather than inventing a resolution.

Rules:

- **Never invoke `docket-plan`, `docket-run`, or `tend`, and never create,
  activate, or advance a docket run.** Grooming is issue hygiene only.
  Docket mutations are limited to the `docket issue` write operations
  described below, including `docket issue edit --parent` and, only for an
  epic proposal the operator approved in §4b, `docket issue create -T epic`.
  Read-only `docket issue list`, `docket issue show`, `docket project list`,
  `docket run status`, `docket workflow list`, `docket workflow show`, and CLI
  help are also permitted. Confirm exact command syntax through the relevant
  `--help`.
- **Safe edits are yours; approval-gated edits are not.** Labels, priority,
  comments, field fills, and parenting an unparented retained issue to an
  existing epic apply directly, subject to §1's exclusions and §3's rule on
  eligibility-narrowing hold labels. Closures, merges, changes to existing
  requirements or relations, epic creation, moving an issue between parents,
  and edits rerouted by those exclusions go through §4; only run
  `docket issue close` for a proposal the operator approved there.
- **Judge from evidence.** A duplicate call you cannot defend in one sentence
  is not a duplicate. When a cluster is ambiguous, resolve the missing
  evidence or operator decision through §4a before proposing a merge. An
  unresolved cluster stays open.
- **Value comes before polish.** Do not invent demand, benefits, urgency,
  estimates, or requirements to justify keeping an issue. A complete issue
  can be worthless; an old or poorly written one can still matter. Missing
  evidence is uncertainty, not proof of either value or worthlessness.

## 1. Survey

Survey both the invoking project and the Docket engine project. The engine
checkout normally lives at `.../github.com/ALT-F4-LLC/docket.git/main`,
beside this dotfiles repository. Confirm its location and project/store
identity using the checkout and supported read-only CLI inspection; do not
infer ownership from an issue prefix. Follow
[Docket's context rules](../docket/SKILL.md#establish-context) for store
resolution. Do not initialize a store or bind a project during grooming. If
the invoking project is already the engine project in the same store, survey
it once.

Run these commands from each project's own checkout:

```bash
docket issue list --json=v2 --limit 1000 -s backlog -s todo -s in-progress -s review
docket run status --active --json
```

Project resolves from cwd's git identity, same as every other docket verb.
A `VALIDATION_ERROR` naming no project means that repo isn't bound: say so
and stop. If no store is reachable, report that failure and stop; do not
infer the repo's binding from a connection failure. Scope is every open
issue in both projects: everything not closed, all statuses, both whole
backlogs, including engine-related issues filed in the invoking project.
Discovery must not depend on an engine label, age, or a link from a local
issue. Check the installed CLI's help for any additional open statuses and
pagination; if results are truncated or reach the limit, retrieve the
remaining issues using supported options, and apply the same completeness
check to run rosters. If either checkout or project cannot be resolved, or
the full survey cannot be obtained, report the missing coverage and stop
before editing; a capped result or an omitted project is not a full pass.

Keep each issue's owning project, checkout, and store context throughout the
pass. Read files, resolve workflows, inspect active runs and their rosters,
and execute issue commands in that owning context. Review an issue only once
even if it appears through several queries or references.

Epics arrive through the same survey: a row whose `kind` is `epic` is an
epic, and every row's `parent_id` names its epic when it has one. Do not run
a separate epic query; the survey's explicit status flags already cover
every open status. Record each project's open epics and each issue's current
parent in the ledger before judging anything. `docket issue show` lists an
epic's children under `sub_issues`.

Two kinds of issue are in scope to read but not yours to freely edit:

- **Run-included.** For each run `docket run status --active --json`
  returns, `docket issue list --run <ref> --json=v2 --limit 1000` names that
  run's roster. An open issue on any of those rosters belongs to a
  docket-plan/docket-run session, even while the run is parked.
- **Claimed.** Any issue with a non-empty `assignee` already belongs to
  someone or something else.

Both still get comments and labels that leave workflow eligibility unchanged
(§3); every other edit travels through §4. Workflow-affecting labels,
priority, and content changes can alter work mid-flight, so if a label's
effect on eligibility cannot be established, route that protected issue's
label edit through §4 too.

## 2. Read and judge

Run `docket issue show <id> --json=v2` for every surveyed issue: description,
acceptance criteria, comments, labels, relations. Build one ledger covering
every issue, including issues with no hygiene defects. Record its owning
project and store, ID, value decision, one-sentence reason, evidence
references, readiness gaps, and any proposed action. For each gap, track the
evidence or decision needed, affected issues, resolution, and verification
or remaining blocker. Track the recommendation separately from the
operator's decision and the resulting issue state. Keep this review in the
ledger; do not post a boilerplate review comment to every issue.

### 2a. Validate value and relevance for every issue

Use the issue history, related work, current code and tests, project goals,
recorded decisions, and relevant release or support information. Read only
as far as the judgment requires. Identify the version or branch evidence
applies to; a local change is not proof that a required release shipped.
Where a conclusion depends on current external behavior, verify the
relevant authoritative source if available. Report inaccessible evidence
instead of assuming what it would say.

For every engine-related issue in either project, check its original
failure or missing capability against current engine source and tests,
linked fixes, and the consuming workflow or configuration where relevant.
Record the engine revision and any installed or released version relevant
to the claim, and confirm whether the need remains, was fully or partly
fixed, or was superseded by an engine change. A consumer workaround does not
by itself resolve an engine defect or capability gap, and a source fix does
not prove the affected installation has it. Preserve any remaining engine
and consumer work separately; related work in different projects is not
automatically duplicate work. If source or version evidence is unavailable,
record the uncertainty and seek clarification instead of declaring the
issue obsolete. These are evidence checks only; do not implement fixes.

Answer these questions for each issue, concisely and from evidence:

- **What need remains?** Identify the unresolved problem, beneficiary or
  affected system, expected outcome, and consequence of doing nothing. Check
  whether the original premise still holds in supported use cases.
- **Is that outcome already covered?** Check linked changes and related
  issues for complete delivery, partial delivery, duplicates, or a
  replacement. Verify the outcome, not just a similar title, closed
  reference, or matching symbol. A proposed replacement is not delivered
  functionality; partial coverage leaves a remaining need.
- **Does the work still fit?** Compare it with current project goals,
  supported platforms, architecture, commitments, and recorded decisions. A
  retired component or abandoned direction can invalidate a task. A missing
  path may instead reflect a rename or intended new file.
- **Is the benefit worth the cost?** Consider impact, frequency, urgency,
  risk reduction, dependency unlocks, implementation effort, and ongoing
  maintenance burden where evidence exists. Compare with doing nothing and a
  smaller existing solution. Distinguish a temporary workaround from a
  durable resolution. Use qualitative reasoning; do not fabricate ROI, usage
  counts, effort estimates, or numerical scores.
- **What would be lost by dropping it?** Look for unique requirements,
  incident evidence, commitments, and work depending on it. Security,
  accessibility, reliability, compatibility, maintainability, cost
  reduction, and resolving a concrete research question can all justify work
  without a new user-facing feature. A prerequisite needs a credible
  downstream outcome; a circular chain of speculative tasks does not
  establish value.

Assign exactly one decision, keeping readiness as a separate assessment:

- **Retain:** a current, unsatisfied benefit is supported by evidence. If
  blocked or deferred, name the real dependency or condition that makes the
  work actionable; do not invent a date or schedule a follow-up.
- **Clarify:** a material fact or product decision is missing. Record the
  smallest question or evidence that would settle value and pursue it in
  §4a. This is provisional: update the value decision when resolved, keep
  the issue open until then, and do not certify it run-ready.
- **Rescope:** the problem has value, but the proposed approach is obsolete,
  oversized, or mixes useful and unnecessary work. Propose the smallest
  supported change to the existing contract through §4. Suggest a split when
  outcomes are independent, but do not create new issues in this pass; the
  one exception is an epic the operator approves under §4b.
- **Merge:** another retained issue can represent the same outcome after
  preserving this issue's unique information. Use §4's merge proposal.
- **Close:** propose closure through §4 with a specific reason: fully
  delivered, obsolete, superseded, explicitly rejected/out of scope, or
  benefit does not justify cost. Cite the confirming evidence. For a
  superseded issue, name where the remaining need is represented. For a
  value-versus-cost judgment, state the concrete tradeoff and assumptions
  for the operator to decide; low priority alone is not a reason.

An epic is a container, and its value is its open `sub_issues`: retain it
while any child is retained or unresolved. When every child is closed or the
epic's outcome is delivered, propose its closure through §4b. Never propose
closing an epic that still has open children unless the same proposal
re-parents each of them, since an epic closure must not orphan work. An
epic whose stated outcome no longer fits the project can be closed only
after its retained children are re-parented or explicitly left as roots in
the same proposal.

Challenge each retention: would its remaining outcome justify accepting this
issue if filed today? Challenge each closure: what concrete benefit or
obligation would remain unsatisfied? Age, lack of comments, missing
assignee, blocked status, incomplete prose, a missing path, or absence from
a roadmap never suffices by itself to propose closure. Repeated findings
without new evidence are still the same finding, not stronger evidence.

### 2b. Check issue quality and execution fit

Record these findings alongside the value decision:

- **Duplicates:** issues asking for the same outcome, clustered, with one
  canonical pick per cluster (oldest issue with the best-written contract
  wins; note anything unique the others carry).
- **Stale:** no substantive activity for 30 days, unless the operator named
  a different window in the invocation, in which case use it and say so in
  the report. Record the last substantive activity date from history before
  editing. Exclude identifiable grooming-only labels, formatting, and
  repeated review comments; fresh evidence, requirement changes, operator
  decisions, and implementation progress do count. If history cannot
  distinguish these, report raw inactivity separately and mark substantive
  staleness unknown. Staleness prompts value review; it is not a closure
  reason on its own.
- **Not run-ready:** goal unclear or missing, acceptance criteria absent or
  failing §2c's quality review, unresolved operator decisions or
  contradictory requirements, missing execution context, no scope declared
  (the `issue list` row carries no `scope` key, or its value is empty), or
  no files (its `files` list is empty). Files and scope must cover the
  intended changes and paths named by the acceptance criteria, since
  `docket plan` splits collisions on files and the scheduler excludes on
  scope. A populated field alone does not establish readiness.
- **Needs operator decision:** an unanswered question, approval request,
  conflicting direction, or choice about value, requirements, tradeoffs,
  dependencies, or intended workflow. Inspect bodies and comments as well
  as existing labels; do not require a particular label or status. Include
  retained, claimed, and run-included issues in §4a's triage queue — their
  edit protections still apply.
- **Mis-prioritized:** priority missing, or plainly out of line with the
  issue's evidenced impact, urgency, risk, dependencies, and effort relative
  to the backlog. Rank remaining work, not work already delivered. Do not
  lower an unresolved issue's priority because evidence is missing.
- **Broken dependency or scope:** inspect blockers, dependents, and parent
  relationships for contradictions, cycles, obsolete prerequisites, and
  independently valuable outcomes bundled together. Distinguish a true
  prerequisite from a merely related issue. Propose relation corrections
  through §4; missing context is not permission to remove a blocker.
- **Stale-binding label:** a label that no longer matches the issue's
  current content and, in doing so, narrows or zeroes its workflow
  bindings. Check with the same probe `docket-plan`'s bare mode uses:
  `docket workflow list --json=v2 --limit 0`, then
  `docket workflow show <name>` per candidate, evaluated against the
  issue's labels. Establish both that the label is obsolete and that it
  changes matching; zero matches alone does not make a label wrong. An
  obsolete label can exclude an issue from every registered workflow even
  after earlier grooming passes fixed its acceptance criteria, so check
  this drift explicitly rather than assuming a content fill makes an issue
  eligible.
- **Stale or missing size label:** `small` binds the small-change track and
  `trivial` the trivial-change track, under
  [docket-plan](../docket-plan/SKILL.md)'s sizing rule, which is the one
  statement of the criteria. Remove a size label the issue's files, scope,
  or criteria have outgrown, and add one where they fit the rule; an
  eligible issue carrying neither walks the full `standard-change` chain.
- **Missing or stale routing label:** every retained non-epic issue carries
  exactly one of `route-run`, `route-direct`, `route-tend`, `route-loop`,
  the family [brief](../brief/SKILL.md)'s route rules define and
  docket-plan, tend, brief, and every workflow's `unless_labels` read.
  Apply it as a safe edit when the criteria clearly hold, from the issue's
  body, files, scope, and labels: `route-run` when the work is
  security-sensitive or its boundary is unknown, when its size is bounded
  or needs design, or when it needs the review evidence a run produces;
  `route-tend` when it is one-shot, non-security, fits one working turn,
  and leaves no decision open, so a worker finishes it without a question;
  `route-direct` when it is that small but leaves a decision or a judgment
  to the operator; `route-loop` when the ask is explicitly recurring and
  the body states the per-pass action, cadence, and stop policy with a
  trivial pass. Correct a label the issue has outgrown the way a stale size
  label is corrected. When no rule clearly holds, apply nothing and list the
  issue in the report as unrouted with what would settle it, since bare
  `docket-plan` excludes unrouted issues. Epics carry no routing label.
- **Ungrouped:** a retained non-epic issue with no parent, or whose parent
  is not the epic its outcome serves. Match the issue to an open epic in its
  owning project by shared outcome, using the same one-sentence-defense test
  as the duplicate rule. The epic's title and description, `depends_on`
  relations among candidate members, shared files or scope, and recorded
  decisions are evidence; a shared label or component name alone is not.
  Record the epic and the one-sentence defense in the ledger. Where no open
  epic fits and two or more retained issues share one defensible outcome,
  draft an epic proposal for §4b with its title, a description naming the
  outcome, and its members. An issue with no defensible epic stays
  unparented and is reported as such; never force a group, nest an epic
  under another epic, or propose a parent in a different project.

Epics are containers, not work. Skip the not-run-ready, size-label, and
stale-binding checks for an issue whose `kind` is `epic`: it declares no
files, scope, or acceptance criteria, and it carries `blocked` so it matches
zero registered workflows. `standard-change` binds any issue that no label
excludes, so an epic without `blocked` would be selected by a bare
`docket-plan` and walk the chain with nothing to do. `blocked` on an epic is
expected, not a stale-binding finding; an epic without it is a readiness gap
whose repair is adding the label under §3.

For every retained non-epic issue, also confirm its labels match exactly one
intended workflow using [docket-plan](../docket-plan/SKILL.md)'s binding
probe as reference, including local workflow definitions in its owning
project. Zero matches, several matches, an unavailable registry, or a
mismatch with the intended work remains a readiness gap. Resolve uncertain
intent in §4a; do not choose a workflow merely to obtain a match or modify
workflow definitions during grooming.

Judge from what the issues and the repo say. Read the repo (`Read`,
`Grep`, `Glob`) only as far as a judgment needs, such as confirming a
referenced path exists or a described change already landed, never to work
an issue.

### 2c. Verify every acceptance criterion

Review the full acceptance-criteria set on every surveyed non-epic issue,
including existing criteria that appear complete. Check each criterion
individually and the set against the current goal, requirements, and
recorded decisions; one good criterion does not make the rest acceptable.
Record each defective criterion and uncovered requirement in the ledger
with the needed repair. An epic carries no acceptance criteria of its own;
its children carry them, and an epic without criteria is not a gap.

A well-defined set meets all of these conditions:

- **Specific outcomes:** each criterion states the behavior or deliverable,
  relevant inputs or conditions, and observable expected result. Name any
  threshold, unit, or tolerance the requirement needs. "Works correctly",
  "improve performance", or "tests pass" alone does not define acceptance.
- **Complete coverage:** every required outcome has a criterion, including
  failure cases, boundaries, and compatibility constraints established by
  the issue or evidence. Split bundled outcomes, including alternatives
  joined by "or", when they need different checks: a verify seat judges a
  criterion as written, so each bundled case is a separate fix round waiting
  to be found. Do not add speculative requirements or invent numerical
  targets.
- **Clear verification:** each criterion has an objective pass/fail rule and
  a feasible verification method under §3. A command must check the stated
  property, not merely find a keyword or run an unrelated suite. A read
  check names the artifact or section to inspect and the evidence that
  would satisfy or violate the criterion. **read-verified** alone is not a
  verification method.
- **Consistent scope:** criteria agree with each other, the goal, settled
  decisions, files, scope, and intended workflow. Required checks must be
  feasible in that workflow's environment. Identify planned test or
  artifact creation as part of the deliverable rather than implying it
  already exists. Contradictions and unresolved placeholders are gaps.
- **In-scope satisfiability:** every criterion can be met by a change inside
  the issue's files and scope, in this repository, with capabilities the
  engine has. A criterion whose only remedy lies elsewhere is split out to
  its own issue in the owning project or recorded as a dependency, never
  left bound: a verify seat can never judge it `met`, so at best it reports
  `unmet-out-of-scope` and a vote passes it with a filing, at worst it
  routes `fix-loop` to the cap and parks on every run that carries it.

A criterion that encodes the worse design is an operator decision under
§4a, not a repair. When the repo read shows the stated outcome would force
a mechanism the codebase's invariants argue against, or the shape a
requirement would take in any repository while this one needs another,
present the reframe beside the criterion as stated, with the evidence, and
record the operator's pick verbatim. Repairing such a criterion toward its
literal wording makes it testable and still wrong. A reframe the writer can
make inside the issue's scope while satisfying every criterion as written is
the writer's choice and raises no decision here.

For retained work, properly set every missing or defective criterion in the
issue during this pass. Draft missing criteria from established
requirements under §3; prepare exact repairs to existing criteria under
§4b. Resolve unknown expected behavior or thresholds through §4a first. Do
not stop at flagging poor wording, silently weaken a requirement to make it
testable, or replace valid criteria with a generic checklist. Apply the
same review after an approved rescope or merge. Retired work does not need
speculative criteria for work that will not be performed.

Check each criterion against HEAD as well. When the repo read shows every
criterion already met (the described change landed under another issue or
before this one was filed), the issue is finished work, not run-ready work:
propose closing it through §4 with the evidence per criterion instead of
repairing criteria for a run to rediscover.

## 3. Safe edits, applied now

Prioritize substantive corrections over cosmetic activity. Fill execution
details automatically only for issues judged **Retain**. Include known
fills and label changes needed by a proposed rescope in its §4 proposal. Do
not make a closure candidate or an unresolved idea look run-ready. Record a
useful value finding or targeted clarification in a comment only when it
adds information; reuse existing findings instead of repeating them.

Non-destructive edits land directly, no questions asked: labels (e.g.
`stale` on §2's stale findings, or removing a §2 stale-binding label once
its workflow-narrowing effect is confirmed), priority, comments, and field
fills. On run-included or claimed issues, only comments and labels with
confirmed unchanged workflow eligibility apply directly; other edits route
to §4. Use existing label conventions and do not add a value label whose
workflow effect is unknown. Ledger decisions are not Docket statuses or
labels and do not authorize status changes.

Parenting is a safe edit under one condition: the issue is retained, has no
parent, is neither run-included nor claimed, and the target is an existing
open epic in the same project with a §2b defense recorded. Apply it with
`docket issue edit <id> --parent <epic> --if-version <n>` from a fresh read,
then comment the one-sentence defense on the child. Parent and kind route
nothing in any registered workflow and activation does not freeze them, so
this edit changes no eligibility. Moving an issue between parents, parenting
a run-included or claimed issue, and detaching an issue go through §4b.
Adding `blocked` to an epic that lacks it is a direct label edit here, since
the corpus policy documents its exclusion effect. Never remove `blocked`
from an epic during grooming.

Do not automatically broaden workflow eligibility for issues whose value is
unresolved or whose closure, merge, or rescope is pending. Identify any such
issue still eligible for work; propose an existing hold label through §4
only if its exclusion effect is confirmed. If no supported hold exists,
report that the review cannot prevent selection. Do not invent a label and
assume the scheduler honors it.

A field fill drafts the missing goal, acceptance criteria, files, or scope
from the issue's own description, comments, and the repo. Files land via
`docket issue file add` (appends), scope via `docket issue edit --scope`
(replaces): one entry per file the description or a gap's `Files:` and
`Scope:` header lines name. Validate existing paths in the checkout; for an
explicitly intended new file, confirm the proposed location against the
repo layout and check that the installed Docket accepts planned paths. If
it does not, record the readiness limitation rather than inventing an
existing path. Fill only missing scope; preserve existing entries when an
edit replaces the field. If a path or field value cannot be established
from evidence, route the missing fact or decision through §4a. A limitation
that grooming cannot resolve stays explicit in the issue and report.

Every acceptance criterion, existing or drafted, must meet §2c and have its
verification method recorded. A criterion with a verification command must
carry the written mutant required by
[docket-plan](../docket-plan/SKILL.md)'s mutant rule: the specific violating
edit that should make the check fail. Check also which source will produce
its evidence at verification: the project's ac-commands pre-gate,
which runs only its own fixed command set and never a fenced command from an
issue body, or a `docket trust list` entry. A command neither source will
run is never executed and lands `unverifiable` on every run; mark such a
criterion **read-verified**, or restate it against evidence those sources do
produce. A criterion without a command must say **read-verified** and
specify what to inspect and how to decide pass or fail. Repair missing or
inadequate verification text through the same §3/§4b rules as the criterion
itself. Read the local rule as reference if needed; do not invoke
`docket-plan`. If the rule is unavailable, do not invent its format: leave
the affected criterion unresolved and report the missing reference.

Grooming verifies the definition and verification design, not completion of
the work. Record proposed verification text without implementing an issue,
running a mutant, or claiming an unexecuted check passed. **read-verified**
identifies the future verification method; it does not mean the deliverable
was already inspected. Edit an authorized fill into the issue with a
comment noting docket-groom drafted it.

Automatic fills preserve prose the operator already wrote. Rewrites to
existing content apply only as explicitly approved in §4. A content fill
and a stale-binding label often belong to the same issue: check the label
again after any content edit, including approved fills in §4, since
resolving what made a label accurate can leave it stale. Record every
applied edit for the report. Avoid duplicate labels, repeated drafting
comments, or commands that would make no change.

Before editing an issue, refresh its content, assignee, and run membership
as needed to confirm the edit still qualifies for direct application. If it
has become protected, route the edit to §4. Refreshing affected records
does not start another grooming pass.

## 4. Resolve decisions, approve, and apply

### 4a. Triage operator decisions to resolution

Work through every decision and readiness gap in the ledger, including
questions already waiting in issues before this invocation. Read linked
decisions and earlier answers first. Resolve factual gaps from available
evidence and use authority already granted in this session; do not ask the
operator to repeat a settled decision or perform routine investigation.

For each remaining operator decision, prepare a concise question with the
affected issues, the exact unresolved choice, relevant evidence, viable
options and tradeoffs, and a recommendation when supported. Explain what
each answer would change or unblock. Group issues sharing one decision, and
ask prerequisite questions before questions that depend on them. Present a
concrete choice the operator can answer without rereading the backlog. Do
not ask a generic "what should we do with this issue?"

Use `AskUserQuestion` in the main session, in manageable batches within the
tool's limits. Use a single choice for mutually exclusive outcomes. Include
a defer option where a decision genuinely cannot be made yet; capture the
missing input, responsible decision-maker if known, and the condition for
resuming. Continue independent grooming while an answer is pending.
Follow-up questions belong to this pass when an answer exposes another
material gap; do not restart the survey or repeatedly ask a declined
question.

After each answer, update the ledger and record the decision and its
rationale in the affected issues. Carry resolved requirements into the
goal, acceptance criteria, files, scope, and dependency proposals as
needed; the next worker must not need this chat to understand the task.
Apply supported missing-field fills under §3. Send changes to existing
requirements, relations, workflow holds, or protected fields through §4b
with exact proposed edits and commands. Reuse explicit approval already
given for those same edits; answering a product question does not approve
unshown mutations. Reassess affected value decisions and readiness after
the resulting edits, including dependent issues and stale decision labels.
Remove a resolved decision label only under the applicable §3/§4b rules.

An operator decision can settle a decision-only issue. Propose its closure
through §4b only after recording the answer and preserving its effects on
dependent work. A decision to implement work does not complete that work.
An issue whose deliverable is investigation can be ready with an explicit
question, bounded scope, and checkable evidence to produce; do not invent
the investigation's answer during grooming.

If a question is deferred, declined, unanswered, or needs unavailable
evidence, retain the exact gap and next required input. Do not mark it
resolved or certify affected work as run-ready. If `AskUserQuestion` is
unavailable or fails, complete independent safe work and report pending
decisions without transferring the gate or assuming an answer. Once only
these blockers remain, report an incomplete pass under §5 and stop.

### 4b. Approve and apply concrete changes

Closures and merges never apply without the operator's say-so. Batch the
proposals from §2: value-based closures, duplicate merges, rescopes,
repairs to acceptance criteria, relation corrections, epic creations,
re-parents, confirmed workflow holds, and edits §1 rerouted here. Each
proposal must contain:

- A stable number, kind, and every issue ID with its owning project.
- A one-sentence defense tied to the surveyed evidence.
- The disposition reason, remaining unique value, and effects on other
  issues or commitments where applicable. Surface assumptions requiring
  the operator's judgment instead of presenting them as established facts.
- The exact proposed content or field changes, including unique material
  being carried into a canonical issue.
- `Commands:` listing the complete ordered command sequence with exact
  arguments and comment or field text, using syntax confirmed by CLI help.
  State each command's working directory and store context, including any
  context switches in a proposal affecting both projects.

A **merge** carries anything unique from the duplicate into the canonical
issue first (a comment or field edit on the canonical), then comments
`duplicate of <id>` on the duplicate, then runs `docket issue close <id>`.
Include canonical edits in the same proposal, including when the canonical
is run-included or claimed. Do not perform merge preparation before
approval merely because it uses a comment or field edit.

A **value-based closure** records the specific closure reason and evidence
in a comment, then closes. Include staleness only as supporting context.
For a decision that could change, record the concrete condition that would
justify reconsideration, without scheduling a revisit. Do not describe
obsolete, rejected, or superseded work as implemented.

Before proposing any closure or merge, inspect incoming and outgoing
relations, the issue's parent, and its `sub_issues`. Establish whether
closing it would unblock dependent work, imply fulfillment of a
prerequisite, or orphan children — cancellation does not fulfill a
dependency. Include necessary preservation and relation corrections in the
same proposal, using supported CLI operations before the closure. If the
consequences or a suitable representation cannot be established, leave the
closure unresolved. Do not delete an unresolved commitment or remove a real
prerequisite merely to make the backlog appear ready.

A **rescope** proposes the exact change to existing goals, acceptance
criteria, files, or scope, explains what is retained and removed, and
preserves the decision rationale in a comment. This approval is required
even for an unclaimed issue: changing intended work is not a field fill. A
**repair to acceptance criteria** shows the defective or incomplete
criterion, its exact replacement or addition, and how it expresses the
established requirement and verification method. Include any necessary
file or scope corrections. Preserve valid criteria and operator intent. A
**relation correction** likewise shows the exact before/after relation and
its evidence. Neither action implements or activates the issue.

A **workflow hold** proposes an existing label with confirmed exclusion
semantics, explains the unresolved decision or readiness gap it represents,
and names the condition for reconsideration. It does not cancel or change
an active run or claim; if safe isolation would require either, report that
limit.

An **epic creation** proposes one new issue of kind `epic` in one project:
its title, a description naming the shared outcome and what completing it
means, the `blocked` label, and every member with its one-sentence defense.
Two or more retained members are required; one issue is not an epic. The
`Commands:` sequence runs the create first:

```bash
docket issue create -T epic -l blocked -t "<title>" -d "<description>" \
  --idempotency-key groom-<project>-<proposal number> --json=v2
```

Then one `docket issue edit <member> --parent <EPIC> --if-version <n>` per member, then the
defense comment on each member. `<EPIC>` is a named placeholder resolved
from the create's JSON output. The idempotency key is derived from the
project and the proposal's stable number, so a retry after an uncertain
outcome returns the same epic instead of a second one. Use `-d -` with
stdin when the description spans lines. Members that are run-included or
claimed need their protection named in the proposal. The epic's membership
is the approval; do not add members the proposal did not list.

A **re-parent** shows each affected issue's current parent and proposed
parent, or `none` when detaching, with the evidence for the move. Use it
for moving an issue between epics, parenting a run-included or claimed
issue, detaching an issue from an epic that no longer fits, and re-homing
children ahead of an epic closure.

A **rerouted safe edit** lists the operations it would have used in §3,
including `docket issue file add` where needed and the drafting comment for
a field fill. It need not fit into a single `docket issue edit` command.

Make proposals independently selectable. Combine dependent changes into one
proposal; do not offer two proposals that would close the same issue,
require a canonical issue another proposal would close, or parent an issue
to an epic another proposal creates.

If there is nothing to propose, finish any remaining §4a triage; proceed to
§5 only when no further decisions or authorized edits can be completed.
When proposals are ready, show the numbered proposals in chat, including
their proposed content and `Commands:`, then make an initial
`AskUserQuestion` call for that batch in the main session:

- **One proposal:** one question with `multiSelect: false`, options
  `Apply #<n>` / `Apply none`, using that proposal's stable number.
  Describe the proposal and its defense.
- **Two to four proposals:** one question with `multiSelect: true`, one
  option per proposal (label `#<n> <kind> <ids>`, description the defense).
  Say in the question text that the operator can decline all through Other
  by entering `none`. Do not add a fifth option when there are four
  proposals.
- **More than four:** one question with `multiSelect: false`, options
  `Apply all` / `Apply none`. Say in the question text that a subset goes
  through Other as proposal numbers.

Use a short question header, at most 12 characters. Tool availability or
permission to execute a command does not count as approval of a proposal.
If `AskUserQuestion` is unavailable, fails, or returns no decision, leave
the proposals pending, report them with the edits already applied, and
stop. Do not infer approval, poll, or transfer the gate to a subagent.

Apply only proposals the operator explicitly selected. `Apply all` and
`Apply none` refer only to the proposals presented for approval in that
question, including in follow-up questions. Treat unselected proposals as
declined only when the operator submitted a clear selection. A cancelled or
ambiguous answer leaves the affected proposals pending.

If the operator raises something new, such as a different stale window or
"leave that cluster alone," fold it in and re-derive only the affected
entries; never restart the survey. A correction is not approval of changed
commands. Show materially revised entries and obtain explicit approval for
them in a follow-up `AskUserQuestion` call. Preserve the decisions on
unchanged entries and never reuse an old proposal number for a different
action. Clarification and approval remain part of this one pass.

Before applying an approved proposal, re-read its affected issues and any
relevant run membership. If intervening changes invalidate its evidence,
alter what would be overwritten, or change its protection status, mark the
proposal outdated and leave it unapplied. Do not silently substitute new
commands for approved ones.

For each still-valid approved proposal, run exactly its `Commands:` in
order. Preservation and comments must succeed before a closure. If an
operation fails or its outcome is uncertain, check current state before
retrying and stop the dependent sequence until the outcome is known.
Report partial application accurately; do not blindly repeat successful
steps. Execute nothing for declined or pending proposals. Do not add a
closure that was not proposed.

## 5. Verify consumption readiness, report, and stop

Recheck every retained issue against the ledger and its final stored
content. A worker should be able to identify the current goal, intended
deliverable, scope and files, checkable acceptance criteria, required
context, settled operator decisions, true prerequisites, intended
workflow, and routing label from the issue and its explicit references.
Check that decisions are reflected consistently in the body, criteria,
labels, and relations, with superseded directions in comment history
clearly identified. Route any remaining resolvable gap through §3 or §4
within this pass. Re-read each retained issue's entire final
acceptance-criteria set against §2c, including unchanged criteria and
requirement coverage. Only mark the criteria well-defined after every
criterion passes and all required outcomes are covered. An absent, vague,
contradictory, or unverifiable criterion keeps that issue's grooming
incomplete until properly set and verified in the stored issue. That
recheck applies to non-epic issues. An epic's recheck is that it carries
`blocked`, that every open child is retained or has a recorded gap, and
that each membership has its one-sentence defense in the ledger.

Grooming is complete only when every surveyed issue has a verified
disposition and retained work has no unresolved grooming gaps. Distinguish
a complete work contract waiting on a named implementation prerequisite
from work still needing clarification; a real dependency need not be
implemented during grooming. Claimed or run-included work is not free to
consume even when its contract is complete. Pending decisions, unavailable
evidence, required but unapproved edits, or failed mutations make grooming
incomplete for the affected work. Report those limits explicitly.

Before reporting, check the summary and each proposal's one-sentence
defense against §2's evidence: no hedged claim standing without the value,
relevance, duplicate, staleness, or priority fact behind it, no vague label
("seems off") standing in for the reason. Verify the resulting issue state
for edits reported as applied; distinguish attempted operations from
confirmed changes.

One summary in the main session, plain language: how many issues surveyed,
how many received a value review, the stale window used, and counts by
value decision, with survey and review counts for each project. Explicitly
report engine coverage and which engine needs remain, are resolved or
superseded, or could not be verified. Present retained work grouped by
epic, per project: each epic's ID, title, and its retained members with
their readiness, followed by the retained issues that have no epic and the
reason each stayed ungrouped. Include a compact ledger of owning projects,
issue IDs, decisions, reasons, and evidence references so every retention
and proposed retirement is reviewable. Report automatic edits, proposals,
operator decisions, and confirmed applications separately, by kind and
issue ID; list parent edits and epic creations under their own kinds. State
whether grooming is complete, which gaps were closed, and which remain
with the specific input or action needed to close each one.

Name the most consequential opportunities to reduce wasted work: redundant
outcomes, unnecessary scope, obsolete assumptions, or blockers needing a
decision. Distinguish confirmed run-ready retained work from valuable work
still needing refinement. Separately name pending, outdated, failed, or
partially applied proposals, unresolved value questions, and ambiguous
findings. Do not claim only valuable issues remain when retirement
proposals were declined or pending, or value could not be established.
Then stop: no wakeup, no follow-up pass. The next docket-groom happens when
the operator invokes it again.
