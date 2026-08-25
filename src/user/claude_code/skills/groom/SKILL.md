---
name: groom
description: Run one full grooming pass over every open issue in the current Docket project — dedupe overlapping issues, flag stale ones, re-prioritize, and fill missing goals and acceptance criteria so issues are run-ready. Safe edits (labels, priority, comments, field fills) apply directly; closures and merges are proposed and land only on operator approval. One-shot with no parameter: a single pass over the project resolved from cwd, then stop — no loop, no watch, and it never implements an issue (that is tend's job). The survey, the judgment, and the safe edits are done by a dedicated seat (the groomer agent); this session only relays the approval gate and runs the approved closures and merges. Use on "groom the backlog", "/groom", "clean up the backlog", "tidy the issues", "make the backlog run-ready", or any request to improve issue quality without working the issues themselves.
argument-hint: "[stale window, e.g. 14d]"
---

# groom

You are the relay. Judging a backlog — what is a duplicate, what is stale,
what is not run-ready — belongs to a dedicated seat, the `groomer` agent,
using `fable`, so this conversation orchestrates only: spawn the seat, carry
its proposals to the operator and the answers back, and run the approved
closures and merges it hands over. Nothing else — no surveying, no judging
clusters, no drafting field fills, no second-guessing or rewriting the
seat's ledger. The seat's working contract (the survey, the four kinds of
finding, the safe-edit rules, the proposal shape) lives in its own
definition, `agents/groomer.md`; this file governs only the relay around it.

Rules you must not fight, same as the seat's own:

- **Never invoke `plan`, `conduct`, or `tend`, and never create, activate,
  or advance a docket run.** Grooming is issue hygiene only. The only
  custom skill in play is `docket` (issue verbs — exact flags via that
  skill's reference or `docket <verb> --help`).
- **Closures and merges land only on operator approval.** The seat never
  runs `docket issue close`; you run it, and only for proposals the
  operator picked in §2.
- **One pass, then stop.** No loop, no wakeup, no follow-up pass; the next
  groom happens when the operator invokes it again.

## 1. Spawn the seat

`Agent({model: "fable", subagent_type: "groomer", name: "groomer", prompt:
<see below>})`. If the name is taken, suffix it (`groomer-2`); the name is
how `SendMessage` addresses the relay.

The prompt carries two things and paraphrases neither:

- the operator's invocation VERBATIM — the full text after `/groom`,
  untouched, including an empty invocation as such (the seat reads a
  stale window from it if one was named, else defaults to 30 days);
- a one-line reminder that its reports must follow its contract's
  PROPOSALS / FINAL shapes.

## 2. Relay the approval gate

The seat cannot face the operator — `AskUserQuestion` is removed from every
subagent — so its reports come to you and you carry them across, unedited:

- **PROPOSALS report** — the numbered ledger plus a question array. Show
  the numbered list in chat verbatim when it has more than four entries
  (the operator needs to see the numbers to name a subset), then run ONE
  `AskUserQuestion` round passing the seat's question array unchanged: its
  options, its defenses, its multiSelect setting. Do not answer for the
  operator, drop or reword a proposal, or add your own. Then go to §3.
- **FINAL report** — the pass summary. Go to §4.

If the operator raises something new at the gate — a different stale
window, "leave that cluster alone" — relay it to the seat with
`SendMessage` and wait for its next report; do not patch the ledger
yourself.

## 3. Apply what was approved

For each approved proposal, run exactly the `Commands:` lines the seat
listed for it, in order — comment first, then `docket issue close <id>` —
and nothing for a declined one. Do not re-derive a merge, add a closure the
seat did not propose, or skip a command it listed. Then message the seat
with `SendMessage`: which proposal numbers were approved, which declined,
and which commands ran (with any failure output verbatim). Wait for its
FINAL. Waiting means ENDING YOUR TURN — the seat's report is queued and
delivers only at your next turn boundary. Do not probe the seat's
transcript in the same turn, and ignore any idle_notification timestamped
BEFORE your own message: it is stale. Reconstruct from the transcript only
if a FRESH idle arrives after your message with no report following.

## 4. Report and stop

Present the seat's FINAL summary verbatim — issues surveyed, stale window,
automatic edits by kind with ids, what was proposed, approved, declined,
and applied, and anything judged too ambiguous to propose. Then stop.

## If the seat fails

A failed spawn or a dead seat — the `groomer` type is unknown to the Agent
tool until the operator's `just activate` installs it, or the agent dies
mid-run — doesn't cancel the pass. Say what happened in one line, read the
seat's contract at `~/.claude/agents/groomer.md` (it installs alongside
this skill; fall back to the repo source under
`src/user/claude_code/agents/groomer.md` if absent), and run that contract
yourself in this session — same survey, same safe edits, same approval
gate before any closure or merge.
