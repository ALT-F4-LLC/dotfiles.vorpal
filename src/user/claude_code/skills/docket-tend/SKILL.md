---
name: docket-tend
description: >-
  Use on "tend the queue", "/docket-tend", "watch for new issues and work them",
  "sweep the backlog", or any request to keep grinding through a project's
  route-tend issues without docket's planning and run machinery; meant to run
  under /loop (for example `/loop /docket-tend`). Watches the current Docket
  project's route-tend queue and works issues one at a time, each delegated to
  a right-sized worker while this conversation orchestrates; each issue runs on
  its own branch in its own git worktree, so several sessions can tend one
  queue at once; lands the result via the commit skill, merges the branch
  locally, closes the issue with a summary comment, and goes quiet when the
  queue is empty (bare invocation does one pass). Distinct from docket-groom,
  which routes issues and never implements.
---

# docket-tend

You keep one Docket project's issue queue empty as an orchestrator: read an
issue, hand implementation to a subagent seated for the job, then commit,
close, and move on. The only custom skills in play are `docket` (issue
verbs) and `commit` (landing changes); everything else here is built-in
Claude Code machinery. Report when you tend an issue, when one blocks you,
or when you must ask.

**Never invoke the `docket-plan` or `docket-run` skills, and never create or
activate a docket run.** This skill exists to skip that machinery.

**Several sessions may tend one queue at once.** Each session works one issue
at a time, in a git worktree of its own on a branch of its own, and claims an
issue by a compare-and-set move to `in-progress` (§2 step 3). Never use
`git stash` here, and never touch another session's worktree: the stash stack
and the branch namespace are shared.

**Run it under `/loop`.** `docket-tend` has no watch loop of its own —
`/loop /docket-tend` (self-pacing) or `/loop 20m /docket-tend` supplies the recurring wake-up; each
firing re-enters this skill from §1. Invoked bare with no loop wrapping it,
do one pass and say so; there will be no next tick.

## 1. Each tick

```bash
docket issue list --json=v2 --limit 1000 -s backlog -s todo -l route-tend
docket run status --json=v2
```

Run them as separate Bash calls so each result is one JSON document; narrow
either further with `jq`, never an interpreter.

Project resolves from cwd's git identity, same as every other docket verb
(see the `docket` skill). A `VALIDATION_ERROR` naming no project, or no
store reachable, means this repo isn't bound: say so and stop. The queue is
every `backlog` or `todo` issue carrying the `route-tend` label — the mark
the [brief](../brief/SKILL.md) skill's route rules define and docket-groom
or brief applies, for mechanical, fully specified work a worker finishes
without a question. The queue includes issues filed before you started
watching. An issue with no routing label, or with `route-run`,
`route-direct`, or `route-loop`, belongs to grooming, a run, the
operator's own brief, or a loop: skip it silently. The query is
`-s backlog -s todo`, so an issue moved to `in-progress` or `review` in a
prior tick never reappears (see §2's blocked case).

Exclude what is not free before picking; this queue isn't docket-tend's alone.
The run-included and claimed rules, and the `--limit 1000` rule for reading
the whole queue, live once in the docket skill's
[queue ownership reference](../docket/references/queue-ownership.md): read
and apply it here rather than a remembered version.

After the exclusions, the queue is either:

- **Empty:** nothing to do. Under self-paced `/loop /docket-tend`, arm
  `ScheduleWakeup({delaySeconds: 150-180, noop: true, ...})` and stop; under
  an explicit interval the cron firing supplies the next tick, so stop;
  invoked bare, stop and say the pass is done. Send no "no new issues"
  message; a quiet tick is not an event.
- **Non-empty:** sort by id ascending (lowest = oldest = created first), take
  the first one, tend it (§2), then **loop back to re-poll immediately** —
  don't schedule a wakeup between queued issues. Keep one issue in flight
  per session (see §3: one worker at a time per session); other sessions
  work other issues in their own worktrees.

  An issue carrying the `review-gap` label was filed by `drain-highs` from a
  prior run's review findings, not by hand; its body names the filing run's
  `source-run:`. Tend it as usual; the label only lets the queue and
  a later `docket-retro` pass tell drain-highs filings apart from other
  issues.

## 2. Tend one issue

1. `docket issue show <id> --json=v2` — full detail: description, acceptance
   criteria, comments. Note `.data.version`, and confirm `.data.status` is
   still `backlog` or `todo`: another session may have taken it since the
   list. If not, skip to the next queued issue.
2. **Security-sensitive gate.** If the issue touches authn/authz, secrets,
   crypto, sandbox/permissions, a trust boundary, supply chain, or untrusted
   input at a privilege boundary, ask the operator via `AskUserQuestion` —
   proceed anyway, skip it, or take it themselves — before touching
   anything. "Skip it" and "take it themselves" are state changes, not
   things to remember: `docket issue move <id> review --if-version <version>`
   with a comment naming the answer (`docket issue comment add <id> --json=v2
   -m "docket-tend: operator skipped, security-sensitive"` or `... -m
   "docket-tend: operator takes it"`), the same exit the blocked case in
   step 4 uses, so the `-s backlog -s todo` query never re-offers the issue.
   The move precedes the claim, so a `CONFLICT` means another session
   claimed the issue while the operator decided: add no comment, and skip to
   the next queued issue. Selection is lowest-id-first,
   so a skip that changed no state would block every issue behind it.
   Everything else, any kind, any size, gets tended: seat a worker (§3)
   and go.
3. Otherwise **claim it**:
   `docket issue move <id> in-progress --json=v2 --if-version <version>`.
   A `CONFLICT` (exit 4) means another session claimed it first: skip to the
   next queued issue and report nothing. Then **open its worktree** (§2a),
   and delegate the implementation (§3). You orchestrate; you do not
   implement. Read or grep in this conversation only as far as seating the
   worker requires — the moment you edit files or chase the fix yourself, you
   have taken the worker's job.
4. **Blocked** (the ask is too unclear to brief a worker, a prerequisite is
   missing, the worker fails and doesn't resolve on one follow-up round, or
   the merge fails per §2a): don't spin on it. `docket issue move <id>
   review` with a comment naming the blocker (`docket issue comment add <id>
   --json=v2 -m "..."`; once a worktree exists, also its branch and path),
   tell the operator in your next visible turn, and move to the next
   queued issue. A blocked issue keeps its branch and worktree for the
   operator; the same blocked issue does not get retried every tick.
5. **Rerun the falsifier.** Before any commit, run the worker's named
   falsifying check once more in this conversation, in the issue worktree
   (`(cd <worktree> && <check>)`, since the shell's working directory
   persists), on the tree as the worker left it, and read the result
   yourself. The report is a claim, not evidence: the worker chose its own
   check and reports its own pass.
   A fresh failure goes back to the worker as the one follow-up round §3
   describes, briefed with the command and its output. A check that
   cannot run in this environment (a tool, service, or permission the
   orchestrator lacks) is neither a pass nor a failure: it takes the same follow-up round, asking for a check
   that can run here, and if none can, treat the issue as blocked (step 4).
   Rerunning a stated check is verification, not the fix-chasing step 3
   forbids. When the advisor tool is available, call it on the rerun result
   before treating it as a pass.
6. **Done:** when the rerun passed, invoke the `commit` skill to land the
   change on the issue branch (`Skill({skill: "commit"})`), with the
   worktree's absolute path in `args` and the instruction to treat it as the
   repository root and run every git command with `git -C <worktree>`: the
   skill takes no root argument of its own, so confirm afterward with
   `git -C <worktree> log` that the commit sits on the issue branch and the
   target checkout gained no change. A commit that landed in the target
   checkout instead blocks the issue (step 4 of §2) and is reported to the
   operator with its hash; never reset, revert, or amend it. One commit-cycle per issue, never
   batched across issues, skipped only when the issue changed no files (then
   remove the worktree and branch, §2a). Then **merge** (§2a). Then
   `docket issue comment add <id> --json=v2 -m "<what changed, plainly,
   citing the commit hash(es), the branch merged into, the rerun command and
   its result, and for a non-trivial issue the candidates the worker
   weighed>"`, then `docket issue close <id> --json=v2`.
7. Report the tend in one line: issue id, title, commit hash(es), and the
   branch it merged into. A tended issue is a state change; never absorb it
   silently.

### 2a. Worktree and merge

Each issue gets a branch and a worktree of its own, so no two sessions share
a working tree. **Name them without the issue id**: a branch or directory
named `tend/<short-slug-of-the-title>-<4 hex digits>` and a worktree
directory `tend-<same slug and digits>`, a sibling of the orchestrator's
checkout (same parent directory). The suffix keeps two sessions' names
apart.

**Open:** record the target branch and checkout once
(`git symbolic-ref --short HEAD` and `git rev-parse --show-toplevel`, in
this conversation's working directory), then
`git worktree add -b <branch> <worktree> <target-branch>`. If the add fails
(the sandbox refuses the path, the name exists), the issue is blocked
(step 4 of §2).

**Merge**, after the commit lands, with no operator step. The merge is a
compare-and-set: `--ff-only` fails when the target moved, and git's own
index lock refuses two merges into one checkout at once, so no extra lock
is needed.

1. In the worktree: `git rebase <target-branch>`.
2. A conflict: `git rebase --abort`, then one fresh worker (same tier, same
   explicit opts, same tier line) in the worktree, briefed to rebase onto
   `<target-branch>`, resolve the conflicts, finish the rebase, and report.
   It may run `git rebase --continue`; the commit rule in its brief
   otherwise stands. A second conflict or a failed rebase blocks the issue.
3. Rerun the worker's falsifier on the rebased tree, as in step 5. A clean
   rebase can still break the change; a failure goes to step 4 of §2.
4. `git -C <target-checkout> merge --ff-only <branch>`. When it fails
   because the target moved, repeat from 1 once; a second failure, or a
   target checkout whose uncommitted changes git refuses to merge over,
   blocks the issue.
5. On success: `git worktree remove <worktree>` and `git branch -d <branch>`.
   Never use `--force` on either.

## 3. Seat and spawn a worker

One worker at a time per session: no parallel workers within an issue, no
parallel issues within a session. Each worker works in its issue worktree
(§2a) and nowhere else, so other sessions' workers cannot collide with it;
never seat two workers in one worktree. Built-in agent
types only — `general-purpose` to implement, `Explore` for a pure
read-only investigation — never a custom agent definition.

One seating mechanism, always: the built-in `Workflow` tool's `agent()`
call, whose opts take `agentType`, `model`, and `effort`. The issue
worktree is the isolation; add no isolation option. Every seat sets
**both `model` and `effort` explicitly**, whatever the tier. Never use the
plain `Agent` tool: it carries no effort parameter, so a worker seated
through it runs at this session's own default instead of a chosen one.

1. **Rule the tier, in one line.** Size the seat to the issue; when in
   doubt, seat up:

   - Mechanical single-file edits (typo, config value, doc line — the class
     docket's `trivial` label names): `haiku` or `sonnet`.
   - Ordinary implementation work, most issues: `opus`.
   - Gnarly work (subtle correctness, cross-cutting changes, debugging an
     unknown cause): `fable` at `max` effort.

   Choose effort with the same judgment that sized the model: a mechanical
   edit has no use for deep reasoning, gnarly always gets `max`, and neither
   choice echoes the session's own default. Write the ruling as one line,
   the tier named (mechanical / ordinary / gnarly) plus why this issue fits
   it, and carry it into the spawn as step 2 shows.

2. **Spawn through `Workflow`**, the worker brief embedded in the script.
   The statement immediately before the `agent()` call is a `log()` line
   carrying step 1's ruling verbatim, so every seat's transcript shows the
   tier, the reason, and the explicit `model`/`effort` pair together. A
   spawn missing the tier line, or either opt, is mis-seated regardless of
   tier:

   ```js
   export const meta = {name: 'tend-issue', description: '<issue title>',
     phases: [{title: 'Implement'}]}
   phase('Implement')
   log('tier: ordinary — one-module fix, cause already named in the issue')
   return await agent(`<worker brief>`, {agentType: 'general-purpose',
     model: 'opus', effort: 'high'})
   ```

   `model` and `effort` take effect only inside `agent()`'s opts, as above.
   Setting either on a `meta.phases` entry instead is display-only and
   silently seats the session default, no error.

**The worker brief** carries the whole contract: the issue worktree's
absolute path (the worker edits and runs checks there, with absolute paths
or `git -C`, never in the orchestrator's checkout or another worktree), the
issue id, title, description, and acceptance criteria verbatim, plus
these standing rules — weigh materially different candidates before
writing, including one the codebase lacks, and ship the winner as the
smallest change; implement the acceptance criteria and run whatever check
could falsify the change; leave every change uncommitted and unstaged;
never run docket verbs, git commits, `git stash`, or skills; the final
message is the report — files changed, what was verified and how, the candidates weighed
and why the pick won (or one line on why no search applied), anything left
undone.

A report that names its verification and shows the evidence goes to step 5
of §2, the rerun; the report alone never commits. A report with no
verification evidence, or one whose named check fails or cannot run on the
rerun, gets one follow-up round, not a commit: a `Workflow` seat cannot be
messaged after its script returns, so the follow-up is a fresh `agent()`
spawn (same tier, same explicit opts, same tier line) briefed with the
first report and the check it failed to show, or the rerun's command and
output. If the second report still can't show a check passing on the
rerun here, treat the issue as blocked (step 4 of §2).

## Stop

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. There is no
other terminal condition: an empty queue is a rest, not a finish.
