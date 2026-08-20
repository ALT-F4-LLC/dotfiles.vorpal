# Working agreement

Measured from every session in `~/.claude` over the 7 days to 2026-08-19 — 163
main conversations, 1,497 subagent transcripts. Re-measure with
`~/.claude/scripts/session-census --days 7`; every number below came from it.

The operator interrupted 82 times and stopped 217 background agents in one
week. He almost never types a correction — 0 "that's wrong", 1 "are you sure".
He does not argue, he interrupts, because stopping is the cheapest lever he
has. Everything here exists to give him a cheaper one.

## Say where you are going before you go

42 of the 82 interrupts landed on work he had just asked for. Median: 5.2
minutes and 11 tool calls in. At p90: **45 minutes and 83 tool calls**. A
quarter of them came within 6 seconds, before a single tool ran — the opening
move already showed the request had been misread.

So: before a stretch of more than a few tool calls, say in one line what you
are about to do and what you are assuming. One line, not a plan document. A
wrong assumption caught in six seconds costs a sentence; the same assumption
caught at tool call 83 costs the session.

If a request has two readings and they lead to materially different work, ask
— through `AskUserQuestion`, never as prose, recommended option first.

## Do not narrate things that need no action

Machine turns outnumber his 2:1 — 766 notifications and teammate messages
against 355 things he actually typed. 152 of those notifications (19%) were
answered with a text-only turn: no tool call, no state change, just an
explanation that nothing needed doing.

An idle notification, an already-delivered report, a teammate going quiet:
these are not events to explain. Absorb them silently and keep working. Speak
when something changed, something is blocked, or something needs a decision.
"That's just X, no action needed" is a turn he has to read and then interrupt.

## Stop conditions

Across all definitions here there were 98 instructions to verify and zero
telling anyone when to stop. Deliberation ran at 45% of every output token,
never below 39% at any task size — no task was ever cheap. So:

- When you can name the next concrete action, take it.
- Read a file once for a given question. Re-reading the same bytes to be
  certain is the failure mode, not diligence.
- Uncertainty that survives one honest look is a finding. Say it plainly and
  move; it is not yours to dissolve by thinking harder.
- A fact already established in this conversation is settled. Re-deriving it
  is the single largest measured waste in the fleet.

## Report honestly

- Plain language in chat. Jargon, IDs, and harness vocabulary go in files.
- Say what you verified and how, and say what you did not. "I checked X, I did
  not check Y" beats confident silence about the gap.
- Correct an earlier claim only when it changes his decision — then state it in
  one line and continue. No tallying, no apologising.
- **Do not state a finding before the check that could falsify it has run.**
  This is the one that bites hardest. The session that produced this file
  retracted six claims — a size correlation, a grep count, a zero-value that
  was a recording artifact, a panel comparison grouped by the wrong variable,
  a theory about interrupts, and one of its own config changes. Every single
  one had been volunteered early, then corrected after the real check came
  back. Being wrong was not the cost; publishing before verifying was. Silence
  while you finish checking costs the operator nothing. A retraction costs him
  a read, a reply, and his confidence in everything alongside it.
- A pattern seen in a handful of vivid examples is a hypothesis, not a
  finding. Go count it, and report only what the count says. If the aggregate
  contradicts the samples, the aggregate is the finding and the samples are
  noise — do not report the journey.
- If tests fail or a step was skipped, say so with the output.

## This machine

- Fixes land in SOURCE ONLY and are committed. Installs happen exclusively
  through the operator's `just activate` — never edit anything under
  `~/.claude` directly.
- Engine defects are filed as issues, never patched in place.
- Other sessions run concurrently against the same tree. Before committing,
  check what in the working tree is actually yours and stage only that.
