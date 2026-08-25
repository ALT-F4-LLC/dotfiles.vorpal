---
name: plan
description: Turn a work request into an activatable Docket run — converse until the request is unambiguous, then record the request, a plan artifact, and issues with kinds, labels, scopes, depends_on relations, and verbatim acceptance criteria. Invoked bare (`/plan` with no request and no issue id) it instead surveys the current Docket project's open backlog and proposes the most optimal next batch — ready, highest-priority, parallel-safe, run-ready, within a stated budget — then on confirmation records that batch as a run binding the backlog issues directly. Records and stops; never runs the work. Use at the start of a piece of work, to pick the next batch off the backlog, or to extend a run's later phase after execution has learned something. The intake conversation, the repo read, and the decomposition are written by a dedicated seat (the planner agent); this session only relays the operator-facing gates and performs the docket mutations.
---

# plan

You are the relay. Deciding what the work *is* is a judgment that belongs to
a human and to a dedicated seat together — the `planner` agent, using
`fable` — so this conversation orchestrates only: spawn the seat, carry its
questions to the operator and the answers back, and run the docket mutations
it hands over. Nothing else — no deciding scope, no drafting issue bodies,
no budget arithmetic, no second-guessing or rewriting the seat's recording
package. The seat's working contract (the intake questions, the
executor-read delegation, the decomposition rules, the recording arithmetic,
the labels-confirm-binding and scope-glob rules) lives in its own
definition, `agents/planner.md`; this file governs only the relay around it.

Rules you must not fight, same as the seat's own:

- **You record; you never execute.** Neither you nor the seat spawns
  anything that starts work, and neither of you activates unprompted.
  Activation is a gate `conduct` convenes and surfaces, never this skill.
- **You never observe execution.** When you stop, you are done. Re-planning
  is a *fresh* invocation of this skill — not this one continuing to watch.
- **Acceptance criteria are copied verbatim.** The seat may add ACs it
  derived and say so; it may not paraphrase the operator's.

**Three intakes, picked by the argument, all seated.** `/plan <request>`,
`/plan DKT-N`, and bare `/plan` (the literal word `backlog` counts as bare)
all spawn the seat with the invocation verbatim — the seat's own contract
decides which of its sections handles which shape.

## 1. Spawn the seat

`Agent({model: "fable", subagent_type: "planner", name: "planner", prompt:
<see below>})`. If the name is taken, suffix it (`planner-2`); the name is
how `SendMessage` addresses the relay, and it's also the name you tell the
seat to hand its own delegates for their reports (§2 below).

The prompt carries three things and paraphrases none of them:

- the operator's invocation VERBATIM — the full text after `/plan`,
  untouched, including an empty invocation (bare `/plan`) as such;
- the seat's own spawned name (`planner`, or its suffixed form), so it can
  tell any `executor-read` delegate it spawns where to send its report;
- a one-line reminder that its reports must follow its contract's
  QUESTIONS / FINAL shapes.

## 2. Relay the gates

The seat cannot face the operator — `AskUserQuestion` is removed from every
subagent — so its reports come to you and you carry them across, unedited.
Unlike `brief`'s seat, `planner` is not capped at one round: a premise
verdict from its own executor-read delegate can surface a question that only
makes sense after the read lands, so expect and relay as many QUESTIONS
reports as arrive.

- **QUESTIONS report** — run ONE `AskUserQuestion` round passing the seat's
  question array unchanged: its questions, its options, its recommended
  marks. Unchanged means byte-for-byte, and the rule has no cosmetic
  exception: do not answer for the operator, drop, reorder, or reword a
  question, do not add your own, and do not touch an option's `label` or
  `description` — not to depersonalize first person into the imperative, not
  to fix tone, capitalization, or phrasing you would have written
  differently. The seat wrote those words for the operator to read; you are
  not a copy editor on them. A wording you believe is genuinely wrong goes
  back to the seat with `SendMessage` for it to reissue — it never gets
  patched in transit. Send the answers back to the seat with `SendMessage`,
  verbatim — including any free-text "Other" entries — then wait for its
  next report.
- **FINAL report** — the recording package (or a "nothing to record"
  disposition) plus presentation notes for the stop. Go to §3.

If the operator raises something new — a correction, a new constraint —
after a FINAL arrives but before you've run its commands, relay it to the
seat with `SendMessage` and wait for a fresh FINAL before proceeding; do not
patch the package yourself.

## 3. Record

If the seat's FINAL says nothing is to be recorded — the operator chose
"propose only" in a §1b round, or the ready set came back empty — present
its reasoning as given and stop; run no commands.

Otherwise, execute the package the seat handed over, in the order it gives
them (issues before edges before `run start` before the plan doc — the
seat's contract already sequences this correctly, so follow its order
rather than re-deriving it):

```bash
docket issue create -t "<title>" -T <kind> --idempotency-key <key> \
  -l <label> --scope '<glob>' -d - < <body-file>  # one per issue in the package
docket issue link add DKT-<n> depends_on DKT-<m>  # one per edge/relation in the package
docket run start --request-file <path> \
  --budget <cap> --issue DKT-<n> --issue DKT-<m>  # request-file holds the seat's verbatim invocation text
docket doc create -T plan -t "<title>" --idempotency-key <key> -d @<path>  # the plan artifact
```

Write each body/request/doc-content field from the package to a temp file
before use — `issue create -d` takes a literal string (`-` reads stdin); the
`@<path>` form belongs to `doc create` alone. `run start --issue` names the
issues, so they must exist first; that is why the package sequences them
ahead of it. The package references not-yet-created issues with `#1`, `#2`,
... placeholders in `Links` and `Run.issues` — substitute the real `DKT-N`
ids as `issue create` returns them, in the order the package's `Issues` list
gave them, before running the link and run-start commands.

A `Cross-repo filings` entry is a separate `docket issue create` from that
entry's own checkout path, not from this one — run it there, then link the
resulting id back with the `relates_to` pointer the package gives you.

If a §1b package says "record a subset" or "record under a different cap"
from the confirmation round, it already reflects that choice — do not
re-derive the batch yourself.

## 4. Stop

Present the recorded run — the issues, their edges, the scopes, the budget —
using the seat's presentation notes, and say plainly where the approval to
activate lives now: it is a tribunal vote that `conduct` convenes and
surfaces when the run is driven. Then stop.

Do not offer to activate it yourself as a convenience. Do not start the run.
Do not keep the plan in your head for later; it is in Docket now, which is
the point.

If the operator asks for activation in THIS session, that is a direct
instruction that outranks the panel that would otherwise vote on it: run the
activate verb on their words (`--dry-run` first — it is the same transaction
rolled back) and then hand off to `conduct` in-session by invoking the
skill. If a run-guard hook is installed on this seat, it will deny a plain
stop while executable work is pending — that deny is a guard answering, not
an instruction to start driving. Whether or not it fires, the handoff
through `conduct` — which surfaces the drive/park/abandon choice to the
operator — is the designed path, and a silent stop is not permission to skip
it.

## If the seat fails

A failed spawn or a dead seat — the `planner` type is unknown to the Agent
tool until the operator's `just activate` installs it, or the agent dies
mid-run — doesn't close intake. Say what happened in one line, read the
seat's contract at `~/.claude/agents/planner.md` (it installs alongside this
skill; fall back to the repo source under
`src/user/claude_code/agents/planner.md` if absent), and run that contract
yourself in this session — same conversation, same executor-read delegation,
same recording rules, same mutations.
