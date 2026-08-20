---
name: tend
description: Watch the current Docket project's issue queue — the existing backlog and whatever gets added after — and work issues one at a time, directly in this conversation — no `/plan`, no `/conduct`, no docket run. Implements each issue's fix, commits it, and closes the issue with a summary comment, then goes quiet once the queue is empty until the next issue appears. Meant to run under `/loop` (self-pacing, e.g. `/loop /tend`) so it can wake on its own cadence without the operator re-invoking it. Use on "watch for new issues and work them", "tend the queue", "sweep the backlog", "/tend", or any request to keep grinding through a project's issues without docket's planning/execution machinery.
---

# tend

You keep one Docket project's issue queue empty, working alone: no `/plan`,
no `/conduct`, no docket run — ever, for this loop. You read an issue and
implement it the same way ordinary conversational work does, then commit,
close, and move on. Silence is the resting state: report when you tend an
issue, when one blocks you, or when you must ask; say nothing on a tick that
found nothing.

**Never invoke the `plan` or `conduct` skills, and never create or activate a
docket run.** That machinery is exactly what this skill exists to skip.

**Run it under `/loop`.** `tend` has no watch loop of its own — `/loop /tend`
(self-pacing) or `/loop 20m /tend` supplies the recurring wake-up; each firing
re-enters this skill from §1. Invoked bare with no loop wrapping it, do one
pass and say so — there will be no next tick.

## 1. Each tick

```bash
docket issue list --json -s backlog -s todo
```

Project resolves from cwd's git identity, same as every other docket verb
(see the `docket` skill). A `VALIDATION_ERROR` naming no project, or no store
reachable, means this repo isn't bound — say so and stop. The queue is
everything sitting in `backlog` or `todo` — the pre-existing backlog is fair
game, not just issues that show up after you started watching (operator
ruling, 2026-08-20). Ignore issues already `in-progress` or `review` — you
put them there yourself in a prior tick (see §2's blocked case).

- **Empty:** nothing to do. `ScheduleWakeup({delaySeconds: 1500-1800,
  noop: true, ...})` and stop. No "no new issues" message — a quiet tick is
  not an event (mirrors `shadow`'s rule against narrating idle ticks).
- **Non-empty:** sort by id ascending (lowest = oldest = created first), take
  the first one, tend it (§2), then **loop back to re-poll immediately** —
  don't schedule a wakeup between queued issues. Only go quiet once a poll
  comes back empty. This is what "work them one by one" means: drain the
  whole queue in this turn, sequentially, one commit-and-close per issue.

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
   any size, gets worked directly — there is no plan/conduct step left to
   size or gate it, so don't invent one by hesitating on size alone.
3. Otherwise: `docket issue move <id> in-progress`. Implement the issue's
   acceptance criteria directly in this conversation — Read/Edit/Write/Bash as
   the work requires. No plan document, no sub-agent team, no docket run:
   treat the issue's description and acceptance criteria as the working
   contract, the same way a `brief` direct-route confirmed block is a working
   contract.
4. **Blocked** (the ask is unclear, a prerequisite is missing, something
   fails and doesn't resolve on a reasonable retry): don't spin on it.
   `docket issue move <id> review` with a comment naming the blocker
   (`docket issue comment add <id> -m "..."`), tell the operator in your next
   visible turn, and move on to the next queued issue — the same blocked
   issue does not get retried every tick.
5. **Done:** invoke the `commit` skill to land the change
   (`Skill({skill: "commit"})`) — one commit-cycle per issue, never batched
   across issues. Then `docket issue comment add <id> --json -m "<what
   changed, plainly, citing the commit hash(es)>"`, then
   `docket issue close <id> --json`.
6. Report the tend in one line — issue id, title, commit hash(es). A tended
   issue is a state change; it always gets said, never absorbed silently.

## Stop

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`, or
simply telling you to stop) or ends the `/loop`. There is no other terminal
condition — an empty queue is a rest, not a finish.
