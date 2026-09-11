---
name: finish
description: End this session cleanly, leaving nothing behind — every agent this session spawned stopped, every schedule and watch it created cancelled, every question in both directions answered, its own uncommitted changes committed, and every unfinished item filed as an issue. Use on "finish", "finish up", "we're done", "wrap up", "end the session", "I'm done for good", or "close this out". Distinct from `pause`, which parks a driven Docket run to come back to; finish is for walking away for good, and hands a live run to `pause` rather than halting it. Distinct from the harness EndConversation tool, which ends the conversation and sweeps nothing.
---

# finish

You end this session with nothing left running, nothing left dirty, and
nothing left only in this session's head. `EndConversation` closes the
conversation; it stops no agent, cancels no schedule, and files nothing. This
skill is the sweep that makes ending safe.

**The session being finished runs this skill.** What this session spawned,
scheduled, watched, and created is known only here — no list surface
reconstructs it, and a forked subagent cannot see it. Run the sweep in this
conversation.

**Walking away, not parking.** If the operator means to come back to a driven
run, that is `pause`, not this. Finish still handles a live run: it hands the
run to `pause` and continues sweeping everything else.

## Ownership: stop only what this session owns

Every stop below is bounded by one rule. **This session's own record of what
it created is the proof of ownership** — the agent or task id returned when
you spawned it, the cron id returned when you created it, the watch you
opened, the `wfId` and `worktree-wf_<id>-*` branches of a wave you launched.
That record lives in this conversation. Work from it.

`ListAgents` and `CronList` show more than this session's own, and neither
tags an entry with the session that created it. They are a cross-check
against your own record, never the source of truth: a background helper you
spawned is invisible to `ListAgents` while it runs
(`skills/docket-run/SKILL.md`), so an entry missing from a list does not mean
it is gone, and an entry present in one that is not in your record is not
yours.

**Where ownership cannot be established, report it — do not stop it.** Name
the entry and why it was ambiguous in the closing report, as an
operator-cleanup candidate. Never touch another session's agents, crons,
worktrees, or watches. A wrongly stopped agent belonging to a live session is
worse than one left running for its owner to reap.

## Hand a driven run to pause first

If this session is driving a Docket run, do this before anything else, so the
rest of the sweep happens against a settled run.

Invoke `/pause` for the run and let it complete its own procedure. **Finish
never halts a run itself** — it issues no `run pause`, no `dispatch close`,
and never `dispatch abandon`; that verb discards live work unconditionally
and belongs to pause's hard halt alone. Do not re-derive pause's steps here.

Then continue the sweep. Pause winds down a live `shadow-live` in both of its
halt modes, so once it returns, the shadow row below is already handled —
record it as such and do not message the observer a second time.

## Sweep

Work the rows in order. Each one is answered — swept or marked not
applicable — never skipped.

**Subagents and Workflow tasks this session spawned.** For each one in your
own record that is still live, `SendMessage` it once: finish what you are
doing now and report. Wait within a bound you state (a single check at a
sensible interval, not a poll loop); a helper that has already reported needs
no wait. Then `TaskStop` it. Wind-down is autonomous — do not ask the
operator to confirm each stop. If a message goes unanswered inside the bound,
`TaskStop` anyway and say so in the report, naming what it was doing.

**Background Bash and Monitor tasks this session started.** Stop each one.
Monitors are not restored across a resume, so a monitor left armed is only
noise for whoever inherits the machine.

**Schedules this session created.** A self-paced `/loop` wakeup ends with
`ScheduleWakeup` carrying `stop: true`; an explicit-interval loop is a cron
task and ends with `CronDelete` on the id you created. These are different
mechanisms: clearing a wakeup says nothing about a cron, and cancelling a
cron says nothing about a wakeup. Answer both rows.

**Artifact watches this session opened.** `unwatch` each one.

**A live `shadow-live` agent.** If pause already handled it, that row is
done. Otherwise wind it down exactly the way `skills/pause/SKILL.md` does in
its own shadow section — one message telling it to stop observing and run the
shadow skill's close-out — and do not poll for the review afterwards.

**Git worktrees this session created.** Check each against
`git worktree list` and your own `wfId` record. **Never remove a worktree
carrying an un-integrated sha**; pause's un-integrated-writer-sha rule in
`skills/pause/SKILL.md` governs here unchanged. Name every such sha with its
worktree path and branch in the closing report so the work stays recoverable.
A worktree whose work is integrated, and that this session created, may be
removed. A `wf_*` entry that is not in your record is reported, not removed.

**Unanswered questions, in both directions.** Two lists, both swept:

- Questions the operator asked this session that never got an answer —
  something deferred while other work ran, a "can you also check…" overtaken
  by events. Answer each one now, or say plainly that it is unanswered and
  why.
- `AskUserQuestion` rounds this session raised that the operator never
  answered. Do not re-ask at the end of a session. Carry each one into the
  filing row below, so the open decision outlives the session.

**Uncommitted changes.** Run `git status` and split what you see. Changes
**this session made** are committed through the `commit` skill — invoke it,
do not reimplement it. **Never push**, here or through anything this skill
invokes. Changes this session did not make are left exactly alone and named
in the closing report; another session or the operator owns them.

**Unfinished work.** Anything real that this session will not complete —
started work, a known defect, an unanswered decision, an intention that
exists only in this transcript — becomes one Docket issue each, filed from
the checkout of the project it belongs to, since cwd picks the project:

```bash
docket issue create -t "<the item in one line>" -T <task|bug> -d - <<'DESC'
Current state: <what exists now, including any sha, branch, or artifact id>
Next step: <the concrete next action, specific enough to act on cold>
DESC
```

File with **no routing label**; `/docket-groom` assigns the route. One item
per issue — a single issue holding three unrelated leftovers gets groomed as
one and two of them disappear. Nothing stays only in this transcript.

## Check before you close

Before printing the report, check it against this list — each row filled in
or explicitly marked not applicable, never silently dropped:

- subagents and Workflow tasks spawned this session
- background Bash and Monitor tasks started this session
- `/loop` wakeups armed this session
- crons created this session
- artifact watches opened this session
- worktrees created this session, each with its integration state
- a live `shadow-live` observer
- a driven Docket run, handed to `/pause`
- operator questions this session never answered
- `AskUserQuestion` rounds the operator never answered
- uncommitted changes, split into this session's and others'
- unfinished work, one issue each
- anything whose ownership could not be established

This is the same sweep as above, checked as a gate rather than trusted as a
memory. A row you cannot answer is reported as unanswered — that is a valid
outcome, and a silent gap is not.

## The closing report

Print it in chat, as the last thing this session does. It is short, and it
says what happened:

- **Stopped:** every agent, task, monitor, wakeup, cron, and watch, by name
  or id.
- **Committed:** the commits `commit` made, by sha and subject. Nothing was
  pushed.
- **Filed:** every issue id with its one-line title.
- **Handed to pause:** the run id and which halt mode pause used, or none.
- **Left, and why:** foreign changes, foreign `wf_*` worktrees and agents,
  worktrees kept for an un-integrated sha (with sha, path, and branch),
  anything whose ownership could not be established, and any question that
  stayed unanswered.

With the report printed, the session is safe to end.
