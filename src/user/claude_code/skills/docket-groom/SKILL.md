---
name: docket-groom
description: Run one grooming pass over every open issue in the current Docket project in the main session. Validate current value and relevance, propose retiring completed, obsolete, superseded, or unjustified work, dedupe, re-prioritize, and fill missing goals and acceptance criteria for worthwhile work. Safe edits apply directly; closures, merges, scope changes, and protected-issue edits require operator approval through AskUserQuestion. One pass from cwd, optional stale window, then stop — no implementation, loop, or watch. Use on "groom the backlog", "/groom", "clean up the backlog", "which issues are still worth doing", "remove low-value issues", or "make the backlog run-ready".
argument-hint: "[stale window, e.g. 14d]"
model: fable
---

# docket-groom

Run one grooming pass over the current project's open issues. First judge
whether each issue still deserves work; then improve the issues worth
keeping. Every retained issue needs a defensible current purpose. Seek a
backlog of valuable work, without a target issue count or closure quota.
Apply safe edits and propose other changes for operator approval.

Run this skill inline in the main session. Keep the survey, grooming ledger,
edits, proposal gate, and final report in this session; do not delegate the
pass or its approval gate to a subagent. Section 4 requires the main
session's `AskUserQuestion` tool. Do not rely on a subagent to ask the
operator, send a live message, or arrange a later handoff.

Take a fresh survey for this invocation. Use `$ARGUMENTS` for the optional
stale window and honor the operator's explicit constraints in this session,
but do not treat earlier issue reads or backlog discussion as current
evidence. Maintain one ledger through approval and execution so the report
accounts for the whole pass.

One pass, then stop — docket-groom takes no parameter beyond an optional
stale window, has no loop, schedules no wakeups, and never touches the code
the issues describe.

Rules you must not fight:

- **Never invoke `docket-plan`, `docket-run`, or `tend`, and never create,
  activate, or advance a docket run.** Grooming is issue hygiene only.
  Docket mutations are limited to the `docket issue …` operations described
  below. Read-only `docket run status`, `docket workflow list`,
  `docket workflow show`, and CLI help are also permitted for the checks
  below. Confirm exact command syntax through the relevant `--help`.
- **Safe edits are yours; approval-gated edits are not.** Labels, priority,
  comments, and field fills apply directly subject to §1's exclusions.
  Closures, merges, changes to existing requirements or relations, and
  edits rerouted by those exclusions go through §4;
  only run `docket issue close` for a proposal the operator approved there.
- **Judge from evidence.** A duplicate call you cannot defend in one
  sentence is not a duplicate, it is two issues that share a noun. When a
  cluster is genuinely ambiguous, leave it out of the proposals and name
  the ambiguity in the report instead.
- **Value comes before polish.** Do not invent demand, benefits, urgency,
  estimates, or requirements to justify keeping an issue. A complete issue
  can be worthless; an old or poorly written one can still matter. Missing
  evidence is uncertainty, not proof of either value or worthlessness.

## 1. Survey

```bash
docket issue list --json --limit 1000 -s backlog -s todo -s in-progress -s review
docket run status --active --json
```

Project resolves from cwd's git identity, same as every other docket verb.
A `VALIDATION_ERROR` naming no project means this repo isn't bound — say
so and stop. If no store is reachable, report that failure and stop; do not
infer the repo's binding from a connection failure. Scope is every open
issue: everything not closed, all statuses, the whole backlog. Check the
installed CLI's help for any additional open statuses and pagination. If
results are truncated or reach the limit, retrieve the remaining issues
using supported options. Apply the same completeness check to run rosters.
If the full survey cannot be obtained, report the limitation and stop
before editing; do not call a capped result a full pass.

Two kinds of issue are in scope to read but not yours to freely edit — this
queue isn't docket-groom's alone:

- **Run-included.** For each run `docket run status --active --json`
  returns, `docket issue list --run <ref> --json --limit 1000` names that
  run's roster. An open issue on any of those rosters belongs to a
  docket-plan/docket-run session, even while the run is parked.
- **Claimed.** Any issue with a non-empty `assignee` — someone or something
  else already has it.

Both still get comments and labels that leave workflow eligibility
unchanged (§3). Every other edit travels through §4. In particular,
workflow-affecting labels, priority, and content changes can alter work
mid-flight. If a label's effect on eligibility cannot be established,
route that protected issue's label edit through §4 too.

## 2. Read and judge

`docket issue show <id> --json` for every surveyed issue — description,
acceptance criteria, comments, labels, relations. Build one ledger covering
every issue, including issues with no hygiene defects. Record its ID,
value decision, one-sentence reason, evidence references, readiness gaps,
and any proposed action. Track the recommendation separately from the
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

Answer these questions for each issue, concisely and from evidence:

- **What need remains?** Identify the unresolved problem, beneficiary or
  affected system, expected outcome, and consequence of doing nothing.
  Check whether the original premise still holds in supported use cases.
- **Is that outcome already covered?** Check linked changes and related
  issues for complete delivery, partial delivery, duplicates, or a
  replacement. Verify the outcome, not just a similar title, closed
  reference, or matching symbol. A proposed replacement is not delivered
  functionality; partial coverage leaves a remaining need.
- **Does the work still fit?** Compare it with current project goals,
  supported platforms, architecture, commitments, and recorded decisions.
  A retired component or abandoned direction can invalidate a task. A
  missing path may instead reflect a rename or intended new file.
- **Is the benefit worth the cost?** Consider impact, frequency, urgency,
  risk reduction, dependency unlocks, implementation effort, and ongoing
  maintenance burden where evidence exists. Compare with doing nothing
  and a smaller existing solution. Distinguish a temporary workaround from
  a durable resolution. Use qualitative reasoning; do not fabricate ROI,
  usage counts, effort estimates, or numerical scores.
- **What would be lost by dropping it?** Look for unique requirements,
  incident evidence, commitments, and work depending on it. Security,
  accessibility, reliability, compatibility, maintainability, cost
  reduction, and resolving a concrete research question can all justify
  work without a new user-facing feature. A prerequisite needs a credible
  downstream outcome; a circular chain of speculative tasks does not
  establish value.

Assign exactly one decision, keeping readiness as a separate assessment:

- **Retain:** a current, unsatisfied benefit is supported by evidence.
  If blocked or deferred, name the real dependency or condition that makes
  the work actionable; do not invent a date or schedule a follow-up.
- **Clarify:** a material fact or product decision is missing. Record the
  smallest question or evidence that would settle value. Keep the issue
  open and visibly unresolved in the report; do not certify it run-ready.
- **Rescope:** the problem has value, but the proposed approach is obsolete,
  oversized, or mixes useful and unnecessary work. Propose the smallest
  supported change to the existing contract through §4. Suggest a split
  when outcomes are independent, but do not create new issues in this pass.
- **Merge:** another retained issue can represent the same outcome after
  preserving this issue's unique information. Use §4's merge proposal.
- **Close:** propose closure through §4 with a specific reason: fully
  delivered, obsolete, superseded, explicitly rejected/out of scope, or
  benefit does not justify cost. Cite the confirming evidence. For a
  superseded issue, name where the remaining need is represented. For a
  value-versus-cost judgment, state the concrete tradeoff and assumptions
  for the operator to decide; low priority alone is not a reason.

Challenge each retention: would its remaining outcome justify accepting
this issue if filed today? Challenge each closure: what concrete benefit
or obligation would remain unsatisfied? Age, lack of comments, missing
assignee, blocked status, incomplete prose, a missing path, or absence from
a roadmap never suffices by itself to propose closure. Repeated findings
without new evidence are still the same finding, not stronger evidence.

### 2b. Check issue quality and execution fit

Record these findings alongside the value decision:

- **Duplicates:** issues asking for the same outcome, clustered, with one
  canonical pick per cluster (oldest issue with the best-written contract
  wins; note anything unique the others carry).
- **Stale:** no substantive activity for 30 days. That default stands
  unless the operator named a different window
  in the invocation, in which case use it and say so in the report. Record
  the last substantive activity date from history before editing. Exclude
  identifiable grooming-only labels, formatting, and repeated review
  comments; fresh evidence, requirement changes, operator decisions, and
  implementation progress do count. If history cannot distinguish these,
  report raw inactivity separately and mark substantive staleness unknown.
  Staleness prompts value review; it is not a closure reason on its own.
- **Not run-ready:** goal unclear or missing, acceptance criteria absent or
  uncheckable, no scope declared (the `issue list` row carries no `scope`
  key, or its value is empty), or no files (its `files` list is empty) —
  every issue names the files its change touches on both keys, since
  `docket plan` splits collisions on files and the scheduler excludes on
  scope.
- **Mis-prioritized:** priority missing, or plainly out of line with the
  issue's evidenced impact, urgency, risk, dependencies, and effort relative
  to the backlog. Rank remaining work, not work already delivered. Do not
  lower an unresolved issue's priority simply because evidence is missing.
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
  changes matching; zero matches alone does not make a label wrong.
  AGT-602's obsolete `retro` label excluded it from every registered
  workflow despite earlier grooming passes that fixed its acceptance
  criteria. Check this drift explicitly rather than assuming a content
  fill makes an issue eligible.

Judge from what the issues and the repo actually say. Read the repo
(`Read`, `Grep`, `Glob`) only as far as a judgment needs — to confirm a
referenced path exists, or that a described change already landed — never
to work an issue.

## 3. Safe edits, applied now

Prioritize substantive corrections over cosmetic activity. Fill execution
details automatically only for issues judged **Retain**. Include known
fills and label changes needed by a proposed rescope in its §4 proposal.
Do not make a closure candidate or an unresolved idea look run-ready.
Record a useful
value finding or targeted clarification in a comment only when it adds
information; reuse existing findings instead of repeating them.

Non-destructive edits land directly, no questions asked: labels (e.g.
`stale` on §2's stale findings, or removing a §2 stale-binding label once
its workflow-narrowing effect is confirmed), priority, comments, and field
fills. On run-included or claimed issues, only comments and labels with
confirmed unchanged workflow eligibility apply directly; other edits
route to §4. Use existing label conventions and do not add a value label
whose workflow effect is unknown. Ledger decisions are not Docket statuses
or labels and do not authorize status changes.

Do not automatically broaden workflow eligibility for issues whose value
is unresolved or whose closure, merge, or rescope is pending. Identify any
such issue still eligible for work; propose an existing hold label through
§4 only if its exclusion effect is confirmed. If no supported hold exists,
report that the review cannot prevent selection. Do not invent a label
and assume the scheduler honors it.

A field fill drafts the missing goal, acceptance criteria, files, or scope
from the issue's own description, comments, and the repo. Files land via
`docket issue file add` (appends), scope via `docket issue edit --scope`
(replaces): one entry per file the description or a gap's `Files:` and
`Scope:` header lines name. Validate existing paths in the checkout; for an
explicitly intended new file, confirm the proposed location against the
repo layout and check that the installed Docket accepts planned paths.
If it does not, report the readiness limitation rather than inventing an
existing path. Fill only missing scope; preserve existing entries when an
edit replaces the field. If a path or field value cannot be established
from evidence, leave that gap unresolved and name it in the report.

Criteria must be checkable, not aspirational. A drafted criterion either
ends with a verification command and carries the written mutant required
by `docket-plan`'s mutant rule, or carries no command and says
**read-verified**. Read the local rule as reference if needed; do not invoke
`docket-plan`. If the rule is unavailable, do not invent its format: leave
the affected criterion unresolved and report the missing reference.
Record proposed verification text without implementing an issue or
running a mutant. Edit the fill into the issue with a comment noting
docket-groom drafted it.

Automatic fills preserve prose the operator already wrote. Rewrites to
existing content apply only as explicitly approved in §4. A content fill
and a stale-binding label often belong to the same issue — check the label
again after any content edit, including approved
fills in §4, since resolving what made a label accurate can leave it stale.
Record every applied edit for the report. Avoid duplicate labels, repeated
drafting comments, or commands that would make no change.

Before editing an issue, refresh its content, assignee, and run membership
as needed to confirm the edit still qualifies for direct application. If
it has become protected, route the edit to §4. Refreshing affected records
does not start another grooming pass.

## 4. Propose, approve, and apply

Closures and merges never apply without the operator's say-so. Batch the
proposals from §2 — value-based closures, duplicate merges, rescopes,
relation corrections, confirmed workflow holds, and edits §1 rerouted
here. Each proposal must contain:

- A stable number, kind, and every issue ID it will affect.
- A one-sentence defense tied to the surveyed evidence.
- The disposition reason, remaining unique value, and effects on other
  issues or commitments where applicable. Surface assumptions requiring
  the operator's judgment instead of presenting them as established facts.
- The exact proposed content or field changes, including unique material
  being carried into a canonical issue.
- `Commands:` listing the complete ordered command sequence with exact
  arguments and comment or field text, using syntax confirmed by CLI help.

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
relations. Establish whether closing it would unblock dependent work or
imply fulfillment of a prerequisite. Cancellation does not fulfill a
dependency. Include necessary preservation and relation corrections in
the same proposal, using supported CLI operations before the closure.
If the consequences or a suitable representation cannot be established,
leave the closure unresolved. Do not delete an unresolved commitment or
remove a real prerequisite merely to make the backlog appear ready.

A **rescope** proposes the exact change to existing goals, acceptance
criteria, files, or scope, explains what is retained and removed, and
preserves the decision rationale in a comment. This approval is required
even for an unclaimed issue: changing intended work is not a field fill.
A **relation correction** likewise shows the exact before/after relation
and its evidence. Neither action implements or activates the issue.

A **workflow hold** proposes an existing label with confirmed exclusion
semantics, explains the unresolved value decision it represents, and names
the condition for reconsideration. It does not cancel or change an active
run or claim; if safe isolation would require either, report that limit.

A **rerouted safe edit** lists the operations it would have used in §3,
including `docket issue file add` where needed and the drafting comment
for a field fill. It need not fit into a single `docket issue edit` command.

Make proposals independently selectable. Combine dependent changes into
one proposal; do not offer two proposals that would close the same issue
or require a canonical issue another proposal would close.

If there is nothing to propose, skip straight to §5. Otherwise, show the
numbered ledger in chat, including its proposed content and `Commands:`,
then make one initial `AskUserQuestion` call in the main session:

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
declined only when the operator submitted a clear selection. A cancelled
or ambiguous answer leaves the affected proposals pending.

If the operator raises something new — a different stale window, "leave
that cluster alone" — fold it in and re-derive only the affected entries;
never restart the survey. A correction is not approval of changed
commands. Show materially revised entries and obtain explicit approval
for them in a follow-up `AskUserQuestion` call. Preserve the decisions on
unchanged entries and never reuse an old proposal number for a different
action. Clarification and approval remain part of this one pass.

Before applying an approved proposal, re-read its affected issues and any
relevant run membership. If intervening changes invalidate its evidence,
alter what would be overwritten, or change its protection status, mark
the proposal outdated and leave it unapplied. Do not silently substitute
new commands for approved ones.

For each still-valid approved proposal, run exactly its `Commands:` in
order. Preservation and comments must succeed before a closure. If an
operation fails or its outcome is uncertain, check current state before
retrying and stop the dependent sequence until the outcome is known.
Report partial application accurately; do not blindly repeat successful
steps. Execute nothing for declined or pending proposals. Do not add a
closure that was not proposed.

## 5. Report and stop

Before reporting, check the summary and each proposal's one-sentence
defense against §2's evidence: no hedged claim standing without the
value, relevance, duplicate, staleness, or priority fact behind it, no vague
label ("seems off") standing in for the reason. Verify the resulting issue state for
edits reported as applied; distinguish attempted operations from confirmed
changes.

One summary in the main session, plain language: how many issues surveyed,
how many received a value review, the stale window used, and counts by
value decision. Include a compact ledger of issue IDs, decisions, reasons,
and evidence references so every retention and proposed retirement is
reviewable. Report automatic edits, proposals, operator decisions, and
confirmed applications separately, by kind and issue ID.

Name the most consequential opportunities to reduce wasted work: redundant
outcomes, unnecessary scope, obsolete assumptions, or blockers needing a
decision. Distinguish confirmed run-ready retained work from valuable
work still needing refinement. Separately name pending, outdated, failed,
or partially applied proposals, unresolved value questions, and ambiguous
findings. Do not claim only valuable issues remain when retirement
proposals were declined or pending, or value could not be established.
Then stop — no wakeup, no follow-up pass; the next docket-groom happens
when the operator invokes it again.
