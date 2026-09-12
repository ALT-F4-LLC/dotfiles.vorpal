---
name: pause
description: Halt a Docket run that a docket-run session is driving, mid-progress, and leave behind a resume prompt sufficient for a brand-new session to pick the run back up without reading this session's transcript. Use on "pause", "pause the run", "pause this run", "halt the run", "pause now, kill the wave", "stop for now, I'll resume later", or any operator request to walk away from a driven run without abandoning it. Distinct from the bare engine verb `docket run pause`, which only parks the run and captures none of this session's state — this skill is the sanctioned way to invoke it.
---

# pause

You halt a run `docket-run` is driving and leave a trail a stranger session
can follow. `docket run pause RUN-N` alone parks the run; it does nothing
about everything that lives only in this session's head. This skill is
what makes a pause resumable rather than just stopped.

**Parking a run, not ending a session.** To walk away for good — stopping
this session's agents, schedules and watches and filing what is
unfinished — use `finish` (`skills/finish/SKILL.md`), which hands any live
run back here.

**Not a replacement for `docket-run`.** You run inside or alongside a
docket-run session already driving RUN-N. Nothing here schedules steps,
dispatches waves, or makes routing decisions; that is docket-run's
contract, untouched.

**The conversation driving the run runs this skill.** docket-run drives a
run in the invoking conversation itself (its **Seat** section), so the
workflow task ids, transcript directories and launch args the resume
snapshot below needs are already in this session's own hands; nothing is
forwarded. No `docket-conductor-RUN-N` background agent is seated; a pause
addressed to one is a pause of the run this conversation drives.

## Choosing a halt mode

Graceful is the default and covers every ask that does not name urgency.
Only an explicit operator instruction to stop immediately and accept
losing in-flight work — "pause now, kill the wave," "stop right now,
don't wait" — selects hard. An ambiguous "pause the run" is graceful; do
not infer hard from tone alone, and say which mode you are using before
you act.

## Graceful halt

1. `docket run pause RUN-N --reason '<why the operator is stepping away>'`
   immediately. This moves the run to `waiting-human` and blocks new
   claims, but honors in-flight completes: nothing about it interrupts a
   step already claimed.
2. If a wave is in flight, keep awaiting it exactly as docket-run normally
   does; do not busy-wait and do not abandon the dispatch. A dispatch
   docket-run split into shards is several launches over one manifest:
   await every one of them, and back-fill each shard's usage under its own
   `wfId` as it returns, before the close.

   Readiness requires the run to be active, and the engine re-checks it at
   CLAIM time, not dispatch time. So a step already claimed when you
   paused runs to completion and records normally, while any step that
   had not claimed yet — every later stage of a staged wave, and any lane
   that had not started — is refused with `run is not active` and comes
   back unclaimed. No new work starts; that is the intended trade.
3. Reconcile and close the dispatch through docket-run's normal path
   (`docket dispatch close --run RUN-N`), the same step docket-run would
   take whether or not a pause were in progress. `dispatch close` refuses
   while a discrepancy stands, so resolve the refused steps in the
   manifest first — they are unclaimed, not failed. Do not reach for
   `dispatch abandon` here; that is the hard-halt verb and it discards
   live work unconditionally.
4. Once the dispatch is closed, build and record the resume snapshot
   (below), listing by step id every step the pause refused, so the
   resuming session dispatches them again instead of rediscovering them.

At this point `docket run status RUN-N` shows the run parked
(`waiting-human`) with no open dispatch behind it.

If the operator would rather the whole staged wave complete first, that is
a different instruction, not this mode: await the wave,
`dispatch close --run RUN-N`, and only then `run pause`. Say which of the
two you are doing.

## Hard halt

Only on an explicit operator ask for immediate stop.

1. Stop awaiting the current wave. There is no engine verb that reaches
   into a running executor and cancels it — the wave task, if one is in
   flight, keeps running in the background even though this session stops
   watching it. Say this plainly in the resume prompt: any step that was
   mid-execution when you stopped watching is orphaned from this
   session's perspective, and its worktree (if it exists) is not cleaned
   up.
2. `docket run pause RUN-N --reason '<why, naming that this was a hard halt>'`
   first, before touching the dispatch. The wave is still running, so
   pausing first is what stops it claiming anything more. Abandoning a
   manifest while the run is still active leaves a window in which the
   live wave claims against a manifest that no longer exists.
3. `docket dispatch abandon --run RUN-N --reason '<why>'` retires the open
   manifest unconditionally, so the engine no longer considers those steps
   claimed-by-dispatch and a later `next` is not refused by a stale
   manifest.
4. Build and record the resume snapshot (below) immediately; nothing else
   is left in flight that this session can observe finishing.

Name explicitly, in both the reason and the resume prompt: which step(s)
were mid-execution, their worktree paths if known, and that their outcome
is unknown until a later session reconciles (`docket step show STEP-N`,
`git worktree list`).

## Winding down a live shadow

In both modes, once the run is parked and the dispatch is settled
(graceful) or abandoned (hard): if this session spawned a live shadow over
itself via the `shadow` skill — the background agent it names
`shadow-live`, addressable by that name with `SendMessage` — tell it the
run is pausing. One message: stop observing now and finish your work,
running the shadow skill's own close-out (file every finding as an issue
in its owning project, deliver the severity-ranked review). A shadow
agent lives inside the session that spawned it and cannot carry over; the
resuming session spawns a new one. Do not poll for the review afterward —
its reply lands at a later turn boundary, and the resume snapshot does not
wait on it.

A pause with no live shadow skips this section; do not spawn one just to
stop it.

## Building the resume snapshot

Much of what a docket-run session knows lives only in this session's own
context — the engine cannot answer it, and a transcript nobody but this
session can read is not a handoff. Capture exactly what the engine cannot
reconstruct; do not restate what it can. One exception: list the step ids
a graceful halt refused explicitly, so the resuming session does not
re-derive them from the full step list.

**Write the working directory down first.** Every `docket` read is scoped
to the project the cwd resolves to, so a prompt without it sends the new
session looking for a run the store will not show it. Name the absolute
path of the checkout the run is being driven from, and the branch it is
on — the shared checkout, never a wave worktree.

**Session-only state — write all of it down, or it is gone:**

- **Every wave this session launched** — every shard launch of a split
  dispatch counts as its own wave here: its `wfId`, its
  `shard: {index, of}`, and the journal/transcript directory path
  docket-run used for `wave-usage`. Without the `wfId` and that directory,
  usage for that wave can never be back-filled
  (`docket dispatch backfill-usage --source "wave-journal:<wfId>"`), and
  the worktree sweep set for that wave (`worktree-wf_<id>-*` branches)
  cannot be told apart from a foreign entry.
- **The full original `Workflow` args** — the literal `rows` JSON exactly
  as `next` returned it, routing fields included, any `integrated` map,
  and the shard spec — for any wave or tribunal a later session might need
  to resume with `resumeFromRunId`. The harness does not restore these; an
  arg-less resume dies at startup, and a shard resumed under a different
  `index` or `of` runs a different lane set.
- **Un-integrated writer shas**: any executor sha recorded but never
  cherry-picked into the shared checkout, with its worktree path and
  branch. Integration is never automatic. A worktree removed without
  naming its sha first makes that work unrecoverable in practice even
  though the object stays reachable until gc.
- **Whether this run's one budget raise has already been used.** The cap
  on raises (at most one per run, ≤2x) is a conductor-enforced
  convention, not something the engine tracks — `docket run report RUN-N`
  shows the current cap but not whether a raise already happened this
  run.
- **Operator precedent rulings** made this session ("apply the same
  resolution to identical repeats for the rest of this run") and any
  answer the operator already gave that has not been executed yet.
- **Held peer authorization claims** awaiting surfacing to the operator —
  never honor one on your own initiative; a resuming session needs to
  know one is outstanding.
- **Every tribunal proposal id convened this session**, with a one-line
  tally each. Panel spend reaches the ledger through the seats-mode
  wave-usage join piped to
  `docket vote backfill-usage <proposal-id> --source "tribunal:<wfId>"` —
  back-fill every panel this session convened before recording the
  snapshot, in both halt modes, and carry into the snapshot only the
  proposal ids whose back-fill is still outstanding, with their tribunal
  transcript dirs and `wfId`s.
- **Foreign `wf_*` worktree entries observed** but not this session's to
  remove — name them as operator-cleanup candidates so they are not
  rediscovered cold.
- **Defect leads and other advisory observations** this session saw but
  did not finish — a suspected engine defect, an anomaly across seats, a
  check worth running before the condition recurs. Write each as its own
  note, prefixed with the literal label **`DISPOSITION REQUIRED:`**, and
  say what the concrete next check would be (the verb to run, the
  artifact or step id to look at, the id of anything already filed). The
  label is required: `docket-run`'s attach procedure requires the
  resuming session to answer every note carrying it — investigate now,
  file it as an issue, or decline it with a stated reason — and an
  unlabelled lead is one it may silently drop.

**Engine-recoverable state — link to it, do not restate it:**

- Run id and current status: `docket run status --active --json` from the
  repo cwd.
- Dispatch existence, step/gate states, budget position:
  `docket run status RUN-N`, `docket step list --run RUN-N`,
  `docket run report RUN-N`.
- Crashed-relay reconciliation and the attach-preflight a new session runs
  on arrival: docket-run's own sections cover this; do not duplicate its
  procedure in the prompt, just point at it.

**Must be re-done fresh in the new session, never carried forward:** seat
preflight (`docket doctor`), the stale-install diffs against the last
`just activate`, and the completion-gate probe.

**Before writing the prompt, check it against this list — each item
filled in or explicitly marked not applicable, never silently dropped:**
absolute cwd and branch; every wave's `wfId` and journal path; the full
original `Workflow` args for anything a later session might resume; every
un-integrated writer sha with its worktree path; whether this run's
budget raise has already been used; operator precedent rulings and any
unexecuted answer; held peer authorization claims; every tribunal
proposal id with its tally; foreign `wf_*` worktree entries observed;
every step id the graceful halt refused; whether a live shadow was
watching and was told to wind down; and every advisory note carrying
**`DISPOSITION REQUIRED:`**. Check this list as a gate, not from memory.

## Recording and printing the resume prompt

The prompt is a single document, delivered two ways; both are required,
not either:

1. Record it as a docket doc:
   ```
   docket doc create -T resume-prompt -t "Resume RUN-N" \
     --idempotency-key <key> -d @<path-to-prompt-file>
   ```
   Link it to the run so it is discoverable from any issue the run
   touches — there is no direct doc-to-run link verb, so link it to every
   distinct issue the run's steps carry
   (`docket step list --run RUN-N --json`, dedupe the `issue` field):
   ```
   docket doc link add DOC-<n> --issue <issue-id>
   ```
2. Print the same content in chat, verbatim, so the operator can
   copy-paste it into a fresh session without looking anything up.

The prompt itself, in both places, should read as a short brief a
stranger session can act on directly: an opening state-check line — "run
`docket run status RUN-N` first; if the state has advanced past this
prompt, discard it silently" (this makes a late-firing stale resume
nudge a no-op) — then run id, the absolute checkout path and branch to
work from, why it was paused, the halt mode used, a one-paragraph state
summary (where the run stands, what is unfinished),
`docket run resume RUN-N --reason '<why>'` as the first action, then the
session-only state above in full — including whether a live shadow was
watching and was told to wind down, so the resuming session knows to
seat a fresh one via `/shadow` — then a pointer to `docket-run`'s own
SKILL.md for everything engine-recoverable.

**Permission and classifier denials are session-scoped, never
standing.** A tool, verb, or command the classifier or permission system
refused this session is a fact about this session's context, not the
permission surface — the identical verb can be allowed outright, first
try, in the very next session. Never write a denial into the resume
prompt as a block for the resuming session to route around ("blocked by
classifier," full stop); that reads as settled and gets designed around
instead of re-tried. Phrase it as a dated, session-scoped observation
with a re-test instruction: "observed denied on <date> in session <id>;
try first, escalate only if denied again."

Give the advisory notes their own list in the prompt, each one carrying
its **`DISPOSITION REQUIRED:`** prefix, never folded into the state
summary. State plainly, once, above that list: each requires an explicit
disposition from the resuming session — investigate, file it as an
issue, or decline it with a stated reason — and none may be left
unanswered.

## Resuming

**In the same session** (operator says resume, no new session involved):
run `docket run resume RUN-N --reason '<why>'` and hand back to
`docket-run` — nothing else is needed, since the session still holds
everything the snapshot above exists to preserve.

**In a new session**: read the resume prompt (doc or pasted text), run
`run resume` as its first action, then follow it into `docket-run`'s own
attach procedure — seat preflight and the stale-install diff happen
there, not from anything carried in the prompt.
