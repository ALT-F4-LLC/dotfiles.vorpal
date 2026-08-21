---
name: brief
description: Turn a freeform work request into a standardized brief — one batched round of AskUserQuestion for whatever's genuinely underdetermined — then route it: hand off to /plan for docket-tracked work, /loop for work that repeats until a condition holds, another orchestration skill when one fits better, or proceed straight into the work for anything small and non-sensitive, confirmed with you either way. The brief itself is written by a dedicated seat (the briefer agent); this session only relays the gates and performs the handoff. The front door for a fuzzy ask you'd rather not prompt-engineer yourself. Trigger on "brief this", "help me think this through", "brief this request", or any new freeform ask before you've decided whether it needs a plan.
argument-hint: "<freeform work request>"
---

# brief

Take the freeform request in `$ARGUMENTS` and turn it into one standardized
block, then route the work — to `/plan` for anything docket-tracked, to
`/loop` for anything that repeats until a condition holds, to another
orchestration skill when the session offers a better fit, or straight into
execution for anything small enough not to need any of that. Either
way you confirm the route before anything happens beyond the questions
themselves. This is the front door: hand off a raw ask, answer one batched
round of questions, and the routing is handled — no separate skill to
remember, no prompt to engineer.

This session orchestrates only. A dedicated seat — the `briefer` agent,
using `fable` — writes the brief, so distillation quality rides
the strongest tier while this conversation stays a thin relay: spawn the
seat, carry its questions to the operator and the answers back, confirm the
route, perform the handoff. Nothing else — no distilling, no reference
lookups, no second-guessing or rewriting the seat's block. The seat's
working contract (field semantics, citation rules, question and route
computation, the block template) lives in its own definition,
`agents/briefer.md`; this file governs only the relay around it.

## 1. Spawn the seat

`Agent({model: "fable", subagent_type: "briefer", name: "briefer", prompt: 
<see below>})`. If the name is taken, suffix it (`briefer-2`); the name is how
`SendMessage` addresses the relay. (A frontmatter seat, not the Workflow
`agent()` call `tend` and `shadow` use for their strongest seats, because only
a spawned agent can be messaged mid-run — and these gates are a multi-turn
relay.)

The prompt carries three things and paraphrases none of them:

- the operator's request VERBATIM — every word of `$ARGUMENTS`, untouched;
- the names of the orchestration skills invocable in THIS session that could
  carry the work (`plan`, `loop`, and any other orchestration skill the
  session lists — the seat cannot see this session's skill listing, and only
  listed skills may be recommended as routes);
- a one-line reminder that its reports must follow its contract's QUESTIONS /
  FINAL shapes.

## 2. Relay the gates

The seat cannot face the operator — `AskUserQuestion` is removed from every
subagent — so its reports come to you and you carry them across, unedited:

- **QUESTIONS report** — run ONE `AskUserQuestion` round passing the seat's
  question array unchanged: its questions, its options, its recommended
  marks. Do not answer for the operator, drop or reword a question, or add
  your own. Send the answers back to the seat with `SendMessage`, verbatim —
  including any free-text "Other" entries — then wait for its FINAL.
- **FINAL report** — the block plus a recommended route, one-line reason,
  and alternates. Go to §3.

## 3. Confirm the route

Present the seat's block VERBATIM plus its recommended route and reason as
an `AskUserQuestion`: the recommended route first, the seat's alternate(s)
next, and "just give me the block" last — a pure emit-and-stop for when the
operator wants to route it themselves. Never act past the block without this
confirmation; the route changes what happens next materially enough that it
isn't yours to decide silently.

If the answer is substantive new information rather than a pick — a
rewritten goal, a new constraint — relay it to the seat with `SendMessage`,
take its fresh FINAL, and re-run this gate.

## 4. Handoff

**Route: `/plan`.** Invoke `Skill({skill: "plan", args: "<the confirmed
block, verbatim>"})`. Plan's own §1 reads a supplied brief block as
already-answered input and only asks about what it left open — this skill's
job ends the moment plan takes the turn.

**Route: `/loop`.** If `loop` appears in this session's invocable skills,
invoke `Skill({skill: "loop", args: "<the confirmed block, verbatim>"})`.
Where the harness offers loop only as a command the operator types, you
cannot start it yourself — emit a ready-to-paste one-liner (`/loop <goal and
stop condition, distilled from the block>`), then stop. Either way the block
travels whole: its Acceptance criteria are the loop's stop condition.

**Route: another orchestration skill.** Same contract as `/plan`: invoke
`Skill({skill: "<name>", args: "<the confirmed block, verbatim>"})` and end
your involvement the moment it takes the turn.

**Route: direct.** No docket issue, no plan artifact, no team spawn —
proceed in this same conversation using the confirmed block as your working
contract: Goal is the definition of done, Scope and Out-of-scope bound the
diff, Constraints and Acceptance criteria are what you check before
reporting back. This is ordinary conversational work, just executed against
a spec instead of the raw ask.

**Route: "just give me the block".** Emit the block verbatim and stop. Do
not continue, execute, or invoke any route skill; the operator carries it
from here.

## If the seat fails

A failed spawn or a dead seat — the `briefer` type is unknown to the Agent
tool until the operator's `just activate` installs it, or the agent dies
mid-run — doesn't close the front door. Say what happened in one line, read
the seat's contract at `~/.claude/agents/briefer.md` (it installs alongside
this skill; fall back to the repo source under
`src/user/claude_code/agents/briefer.md` if absent), and run that contract
yourself in this session — same block, same gates, same handoff.
