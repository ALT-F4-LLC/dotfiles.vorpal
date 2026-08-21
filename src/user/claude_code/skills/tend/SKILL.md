---
name: tend
description: Watch the current Docket project's issue queue — the existing backlog and whatever gets added after — and work issues one at a time by delegating each to a right-sized subagent while this conversation orchestrates — no `/plan`, no `/conduct`, no docket run. Spawns a worker seated for the job (stronger models and efforts than the loop itself), lands the result via the `commit` skill, and closes the issue with a summary comment, then goes quiet once the queue is empty until the next issue appears. Meant to run under `/loop` (self-pacing, e.g. `/loop /tend`) so it can wake on its own cadence without the operator re-invoking it. Use on "watch for new issues and work them", "tend the queue", "sweep the backlog", "/tend", or any request to keep grinding through a project's issues without docket's planning/execution machinery.
---

# tend

You keep one Docket project's issue queue empty as an orchestrator: no
`/plan`, no `/conduct`, no docket run — ever, for this loop. You read an
issue, hand the implementation to a subagent seated for the job, then
commit, close, and move on. The only custom skills in play are `docket`
(issue verbs) and `commit` (landing changes) — everything else here is
built-in Claude Code machinery. Silence is the resting state: report when
you tend an issue, when one blocks you, or when you must ask; say nothing
on a tick that found nothing.

**Never invoke the `plan` or `conduct` skills, and never create or activate a
docket run.** That machinery is exactly what this skill exists to skip.

**Run it under `/loop`.** `tend` has no watch loop of its own — `/loop /tend`
(self-pacing) or `/loop 20m /tend` supplies the recurring wake-up; each firing
re-enters this skill from §1. Invoked bare with no loop wrapping it, do one
pass and say so — there will be no next tick.

## 1. Each tick

```bash
docket issue list --json -s backlog -s todo
docket run status --active --json
```

Project resolves from cwd's git identity, same as every other docket verb
(see the `docket` skill). A `VALIDATION_ERROR` naming no project, or no store
reachable, means this repo isn't bound — say so and stop. The queue is
everything sitting in `backlog` or `todo` — the pre-existing backlog is fair
game, not just issues that show up after you started watching (operator
ruling, 2026-08-20). Ignore issues already `in-progress` or `review` — you
put them there yourself in a prior tick (see §2's blocked case).

Exclude two more kinds before picking — this queue isn't tend's alone:

- **Run-included.** For each run `docket run status --active --json` returns
  (planning, active, or paused — anything not done or abandoned),
  `docket issue list --run <ref> --json` names that run's whole roster. Any
  backlog/todo issue sitting on any of those rosters belongs to a plan/conduct
  session, even while the run is parked — skip it.
- **Claimed.** Any issue with a non-empty `assignee` — tend never sets one on
  the issues it works, so a populated `assignee` means someone or something
  else already has it. Skip it.

- **Empty:** nothing to do. `ScheduleWakeup({delaySeconds: 150-180,
  noop: true, ...})` and stop. No "no new issues" message — a quiet tick is
  not an event.
- **Non-empty:** sort by id ascending (lowest = oldest = created first), take
  the first one, tend it (§2), then **loop back to re-poll immediately** —
  don't schedule a wakeup between queued issues. Only go quiet once a poll
  comes back empty. Strictly one issue in flight at a time: workers share
  this working tree, so never have two issues' workers alive at once.

## 2. Tend one issue

1. `docket issue show <id> --json` — full detail: description, acceptance
   criteria, comments.
2. **Security-sensitive gate.** If the issue touches authn/authz, secrets,
   crypto, sandbox/permissions, a trust boundary, supply chain, or untrusted
   input at a privilege boundary, do not attempt it blind. Ask the operator
   via `AskUserQuestion` — proceed anyway, skip it, or take it themselves —
   before touching anything. This is the one case this skill defers on:
   "work every issue" doesn't override the standing rule that a
   trust-boundary change gets a human look first. Everything else, any kind,
   any size, gets tended — seat a worker (§3) and go; there is no
   plan/conduct step left to gate it, so don't invent one by hesitating on
   size alone.
3. Otherwise: `docket issue move <id> in-progress`, then delegate the
   implementation (§3). You orchestrate; you do not implement. Read or grep
   in this conversation only as far as seating the worker requires — the
   moment you are editing files or chasing the fix yourself, you have taken
   the worker's job.
4. **Blocked** (the ask is too unclear to brief a worker, a prerequisite is
   missing, or the worker fails and doesn't resolve on one follow-up
   round): don't spin on it. `docket issue move <id> review` with a comment
   naming the blocker (`docket issue comment add <id> -m "..."`), tell the
   operator in your next visible turn, and move on to the next queued
   issue — the same blocked issue does not get retried every tick.
5. **Done:** when the worker's report is in and checks out, invoke the
   `commit` skill to land the change (`Skill({skill: "commit"})`) — one
   commit-cycle per issue, never batched across issues; skip it only when
   the issue changed no files. Then `docket issue comment add <id> --json
   -m "<what changed, plainly, citing the commit hash(es)>"`, then
   `docket issue close <id> --json`.
6. Report the tend in one line — issue id, title, commit hash(es). A tended
   issue is a state change; it always gets said, never absorbed silently.

## 3. Seat and spawn a worker

One worker at a time, ever — no parallel workers within an issue, no
parallel work across issues (operator ruling, 2026-08-20: keep it simple).
The worker spawns into this working tree (no worktree isolation); strict
sequence is what makes that safe. Built-in agent types only —
`general-purpose` to implement, `Explore` when the issue is a pure
read-only investigation — never a custom agent definition.

One seating mechanism, always: the built-in `Workflow` tool's `agent()`
call, whose opts take `agentType`, `model`, and `effort`. Every seat sets
**both `model` and `effort` explicitly**, whatever the tier. The plain
`Agent` tool has no place here at any size: it carries no effort
parameter, so a worker seated through it runs at whatever this session's
default happens to be — an inherited accident, not a decision — and the
remember-to-switch-tools split that "Agent normally, Workflow for big
seats" creates is exactly how seats get mis-sized.

1. **Rule the tier, in one line.** Size the seat to the issue, and when in
   doubt, seat up — the point of delegating is that a worker can afford a
   stronger model and effort than the loop itself:

   - Mechanical single-file edits (typo, config value, doc line): `haiku`
     or `sonnet`.
   - Ordinary implementation work — most issues: `opus`.
   - Gnarly work (subtle correctness, cross-cutting changes, debugging an
     unknown cause): `fable` at `max` effort.

   Effort is an explicit pick at every tier now, not just gnarly's: choose
   it with the same judgment that sized the model — a mechanical edit has
   no use for deep reasoning, gnarly always gets `max` — never by echoing
   the session's own default, which is no longer part of the decision.
   Write the ruling down as one line — the tier named (mechanical /
   ordinary / gnarly) plus why THIS issue fits it — and carry it into the
   spawn as step 2 shows. The line is required, not decoration: one
   mechanism for every seat makes reflexively seating everything
   `fable`/`max` exactly as easy as inheriting the default used to be (two
   issues in a row went out at `fable`/`max` with no per-issue
   justification, 2026-08-21), and stating the reason is what forces the
   judgment to actually happen.

2. **Spawn through `Workflow`**, the worker brief embedded in the script.
   The statement immediately before the `agent()` call is a `log()` line
   carrying step 1's ruling verbatim, so every seat's transcript shows the
   tier, the reason, and the explicit `model`/`effort` pair together. A
   spawn missing the tier line, or missing either opt, is mis-seated
   regardless of which tier it picked:

   ```js
   export const meta = {name: 'tend-issue', description: '<issue title>',
     phases: [{title: 'Implement'}]}
   phase('Implement')
   log('tier: ordinary — one-module fix, cause already named in the issue')
   return await agent(`<worker brief>`, {agentType: 'general-purpose',
     model: 'opus', effort: 'high'})
   ```

   `model` and `effort` take effect only inside `agent()`'s opts, as
   above. Setting either on a `meta.phases` entry instead is display-only
   for the progress UI — it silently seats the session default, with no
   error.

**The worker brief** carries the whole contract: the repo's absolute path,
the issue id, title, description, and acceptance criteria verbatim, plus
these standing rules — implement the acceptance criteria and run whatever
check could falsify the change; leave every change uncommitted and
unstaged; never run docket verbs, git commits, or skills; the final
message is the report — files changed, what was verified and how, anything
left undone.

A report that names its verification and shows the evidence goes to §2.5.
A report with no verification evidence gets one follow-up round, not a
commit — a `Workflow` seat cannot be messaged after its script returns, so
the follow-up is a fresh `agent()` spawn (same tier, same explicit opts,
same tier line) briefed with the first report and the check it failed to
show. If the second report still can't show its check, treat the issue as
blocked (§2.4).

## Stop

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`, or
simply telling you to stop) or ends the `/loop`. There is no other terminal
condition — an empty queue is a rest, not a finish.
