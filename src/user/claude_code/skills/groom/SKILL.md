---
name: groom
description: Run one full grooming pass over every open issue in the current Docket project — dedupe overlapping issues, flag stale ones, re-prioritize, and fill missing goals and acceptance criteria so issues are run-ready. Safe edits (labels, priority, comments, field fills) apply directly; closures and merges are proposed and land only on operator approval. One-shot with no parameter: a single pass over the project resolved from cwd, then stop — no loop, no watch, and it never implements an issue (that is tend's job). Use on "groom the backlog", "/groom", "clean up the backlog", "tidy the issues", "make the backlog run-ready", or any request to improve issue quality without working the issues themselves.
---

# groom

You run one grooming pass over the current project's open issues as an
editor, not an implementer: read everything, fix what is safely fixable in
place, and put anything destructive in front of the operator before it
happens. One pass, then stop — groom takes no parameter, has no loop,
schedules no wakeups, and never touches the code the issues describe.

**Never invoke `plan`, `conduct`, or `tend`, and never create, activate, or
advance a docket run.** Grooming is issue hygiene only. The only custom
skill in play is `docket` (issue verbs — exact flags via that skill's
reference or `docket <verb> --help`).

## 1. Survey

```bash
docket issue list --json --limit 1000 -s backlog -s todo -s in-progress -s review
docket run status --active --json
```

Project resolves from cwd's git identity, same as every other docket verb
(see the `docket` skill). A `VALIDATION_ERROR` naming no project, or no
store reachable, means this repo isn't bound — say so and stop. Scope is
every open issue: everything not closed, all statuses, the whole backlog.

Two kinds of issue are in scope to read but not yours to freely edit —
this queue isn't groom's alone:

- **Run-included.** For each run `docket run status --active --json`
  returns, `docket issue list --run <ref> --json --limit 1000` names that
  run's roster. An open issue on any of those rosters belongs to a
  plan/conduct session, even while the run is parked.
- **Claimed.** Any issue with a non-empty `assignee` — someone or something
  else already has it.

Both still get comments and labels (§3); every other edit to them travels
through the proposal gate (§4) instead of applying directly, because a
priority or content change under a live run or an active claimant changes
work mid-flight.

## 2. Read and judge

`docket issue show <id> --json` for every surveyed issue — description,
acceptance criteria, comments, labels, relations. From the full set, build
one grooming ledger with four kinds of finding:

- **Duplicates:** issues asking for the same outcome, clustered, with one
  canonical pick per cluster (oldest issue with the best-written contract
  wins; note anything unique the others carry).
- **Stale:** no activity — no comment, edit, or status change — for 30
  days. That default stands unless the operator named a different window
  when invoking; say the window you used in the report.
- **Not run-ready:** goal unclear or missing, acceptance criteria absent or
  uncheckable.
- **Mis-prioritized:** priority missing, or plainly out of line with the
  issue's content relative to the rest of the backlog.

Judge from what the issues and the repo actually say, not from vibes — a
duplicate call you cannot defend in one sentence is not a duplicate, it is
two issues that share a noun. When a cluster is genuinely ambiguous, leave
it out of §4 and name the ambiguity in the report instead.

## 3. Safe edits, applied now

Non-destructive edits land directly, no questions asked: labels (e.g.
`stale` on §2's stale findings), priority (except on run-included or
claimed issues — those route to §4), comments, and field fills. A field
fill drafts the missing goal or acceptance criteria from the issue's own
description, comments, and the repo — criteria must be checkable, not
aspirational — and edits it into the issue with a comment noting groom
drafted it. Fill what is missing; never rewrite or restyle prose the
operator already wrote. Record every applied edit for the report.

## 4. Propose closures and merges

Closures and merges are destructive and never apply on your own authority.
Batch every proposal from §2 — stale closures, duplicate merges, and any
§3-shaped edit that §1's exclusions rerouted here — each with its
one-sentence defense.

- **Four or fewer:** one `AskUserQuestion` round, multiSelect, one option
  per proposal, so the operator picks exactly which land.
- **More:** a numbered list in chat first, then one `AskUserQuestion` —
  apply all, apply none, or a subset named via Other.

Apply only what was approved, the moment the answer is in. A merge carries
anything unique from the duplicate into the canonical issue first, then
closes the duplicate; every approved closure gets a comment naming why
(`duplicate of <id>`, `stale since <date>`) before `docket issue close
<id>`. Declined proposals are recorded, not retried or argued.

## 5. Report and stop

One summary, plain language: how many issues surveyed, what was edited
automatically (by kind, with ids), what was proposed, what the operator
approved or declined, and what was applied. Name anything you judged too
ambiguous to propose. Then stop — no wakeup, no follow-up pass; the next
groom happens when the operator invokes it again.
