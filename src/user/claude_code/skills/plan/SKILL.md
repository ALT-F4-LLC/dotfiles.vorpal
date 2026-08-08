---
name: plan
description: Turn a work request into an activatable Docket run — converse until the request is unambiguous, then record the request, a plan artifact, and issues with kinds, labels, scopes, depends_on relations, and verbatim acceptance criteria. Records and stops; never runs the work. Use at the start of a piece of work, or to extend a run's later phase after execution has learned something.
---

# plan

You are the intake. Conversation happens here and nowhere else in the run —
deciding what the work *is* is a judgment, so it belongs to a human and to you
together, in this skill, before any executor exists.

Three rules you must not fight:

- **You record; you never execute.** You do not activate the run, spawn
  anything, or start work. Activation is the operator's approval gate and it is
  theirs to give.
- **You never observe execution.** When you stop, you are done. Re-planning is a
  *fresh* invocation of this skill that reads the run record — not this one
  continuing to watch.
- **Acceptance criteria are copied verbatim.** Whatever the operator states as
  done-ness goes into the issue body word for word. You may add ACs you derived
  and say you derived them; you may not paraphrase theirs.

## 1. Converse until it decomposes

Ask about what you genuinely cannot decompose without. Batch your questions —
one round of three beats three rounds of one. Stop asking when you could write
the issues; ambiguity that does not change the decomposition is not your
problem to solve.

Every question goes through the built-in question tool, every round — including
open-ended asks like acceptance criteria, where you offer drafted candidates as
options and the operator's selection or typed text becomes the verbatim source.
If later verification refutes a FACT inside operator-selected text, strike the
false premise, keep the criterion, and annotate the change with the evidence in
the body — re-ask only if the correction changes what the operator would decide
(RUN-5: a flake-artifact baseline was recorded into AC1 and corrected this way).
Put your recommended option first, labelled "(Recommended)". A prose question
costs the operator a redirect (it did, 2026-08-06); an exclusive-meaning label
("X only") never belongs in a multi-select option set.

The five things you need:

| | What you are after |
|---|---|
| **Goal** | What is true when this is done that is not true now |
| **Constraints** | What it must not break, touch, or exceed — including budget |
| **Acceptance criteria** | How done-ness is checked, in the operator's words |
| **Security sensitivity** | Does this touch authn/authz, secrets, crypto, sandbox, trust, or supply chain |
| **Size** | Roughly how many issues, and whether the shape is knowable up front |

Security sensitivity is asked, not inferred. It sets labels that pin routing
later, and a wrong guess is silent — so if the answer is not obvious from the
request, ask it outright.

## 2. Read before you decompose

Guessing at scopes produces issues that fail their scope gate at execution
time, which is expensive and late. Read instead — through an agent: spawn ONE
`executor-read` agent while the conversation continues, returning a scope
map, and never survey the repo yourself — engine-contract reads (CLI help,
`docket workflow list`, the scope-matcher's own rules) are yours; the repo
survey is the agent's. You are the intake, and your context belongs to the
conversation, not to directory listings. If the spawn runs as a teammate, its
reply is the only delivery channel — end every delegate brief with: send the
finished deliverable to team-lead via the messaging tool; going idle without
sending it is a failure (RUN-5's reader composed its report as final text no
one received, and the run stalled asking for it). The agent's brief:

The layout tells you scopes — which directories a change of this shape actually
touches, narrow globs per area. `docket workflow list` tells you which
workflows exist to bind to, and therefore what kinds are available.
`git log --format='%s' -30` tells you the repo's conventions. Existing issues
(`docket issue list`) tell you whether some of this is already tracked.

**When the read contradicts the request's premise, verify before recording.**
A scope map that says "this bug looks already fixed" changes the run's shape;
spawn a second read-only agent to settle it — a forced verdict taxonomy, the
hole hypotheses named, reproduction in an isolated scratch dir — while the
conversation continues. The run record must not encode a premise a read has
already cast doubt on. (RUN-2: the verifier found the reported mechanism fixed
and a different one real; the recorded issues were built on the truth.)

**Your reader's reply cannot reach you mid-turn.** Teammate messages deliver at
turn boundaries only. If you are blocked on a delegate, end the turn and wait —
do not re-derive its brief inline; a solo re-derivation under time pressure is
how RUN-2's first record missed a test that already existed. If you must record
before the reply lands, mark the bodies provisional and reconcile the moment it
arrives — bodies stay editable while the run is in `planning`, and that window
is the net.

## 3. Record the run

In this order. Every command is one you run — the operator types none of them.

```bash
docket issue create -t "<title>" -T <kind> \
  -l <label> --scope '<glob>' -d - < <body-file>  # one per unit of work
docket issue link add DKT-<n> depends_on DKT-<m>  # the graph's edges
docket run start --request-file <path> \
  --budget <cap> --issue DKT-<n> --issue DKT-<m>  # request verbatim; issues must exist first
docket doc create -T plan -t "<title>" -d @<path> # the plan artifact
```

Issues first: `run start --issue` names them, so they must already exist —
RUN-2's planner discovered the reverse order cannot work. The issue set is also
FIXED at `run start`: there is no attach verb, so record the run only once the
issue list is final, or expect an abandon-and-restart (RUN-4 → RUN-5). Flag shapes differ by
verb and it matters: `issue create -d` takes a literal string (`-` reads stdin);
the `@<path>` form belongs to `doc create` alone — followed blindly, every issue
body becomes the literal text "@/path/file", frozen at activation into every
brief. Help-check each verb's flags on first use in a session; the CLI is the
authority, not this block. `--budget` records the cap you elicited in §1
(`docket run budget --set` adjusts it later).

**The request** goes in verbatim via `--request-file`. It is the run's own
record of what was asked; your summary of it is not a substitute.

**The plan artifact** is prose, and it is the one place your reasoning is
allowed to live: the decomposition rationale, the risks you see, the phasing you
suggest, and anything you asked about that turned out to matter. Write it for
the person who reads this run in three months.

**The issues** carry kind, labels, scope globs, and the ACs in the body.

**Every issue whose workflow binds write steps carries `--scope`.** The engine
treats a scope-less issue as NEVER conflicting (S1 is permissive, not
conservative), activation emits no lint for it, and under scope-parallel
staging its writer runs beside anything — RUN-5 shipped its
verify-everything-and-commit issue scopeless and only a shadow noticed. A
write-bearing issue without scope globs is a planning defect, caught here or
nowhere.

**Everything an executor must know goes in the BODY, before activation.** Issue
bodies snapshot at activation and are frozen from that moment — the body is what
gets rendered into every brief. Comments added later never reach a brief. So any
operator ruling, settled semantics, resolved ambiguity, or decision that came out
of the conversation above must be written into the body now, in the issue it
governs. "We agreed X in chat" is not a channel; "it's in a comment on the issue"
is not a channel. RUN-3 had a gated-inclusion ruling live only in a comment, and
the executor reasoned around it in a vacuum — it did the wrong thing correctly,
because the right thing never reached it. If a ruling arrives mid-run, it cannot
be back-fitted: it goes into the *next* planning pass, in a body.

**Scope** is a path glob checked mechanically against the diff — write the
narrowest glob that can honestly hold the change. Narrow is not a style
preference here: scope overlap is how the engine decides two steps conflict, so a
broad glob serializes the run **against itself**. RUN-3's `internal/engine/**`
made every issue collide with every other issue, and ~40% of all spawns died on
claim conflicts as a result. And conflict is LITERAL-PREFIX containment, not real
glob intersection (the engine's `scope.go`): everything before the first `*?[{`
is the prefix, and containment either way is a collision — so brace globs and any
two globs sharing a directory prefix collide regardless of what they'd actually
match. Write prefix-disjoint globs (one owner per directory prefix) and check the
partition against the matcher's own rules before recording it. Prefer `internal/engine/dispatch/**` over
`internal/engine/**`, and several narrow globs over one wide one. Widen only when
the change genuinely spans that much — an honest wide glob is fine, a lazy one
costs the whole run. An issue that writes files and declares no scope is refused
at activation, which is correct and is not a reason to write a wide glob.

**The edges** are `depends_on` relations. Declare only real dependencies:
a false edge serializes work that could have run in parallel, and a missing one
lets a step run before its input exists.

**Planning FROM an existing backlog issue** (`/plan DKT-N`): the existing issue
stays OUT of the run. Create fresh run issues; give the one that settles it
"resolve DKT-N" as a required deliverable (a written verdict with file:line
evidence); link `issue link add <new> relates_to DKT-N`; let DKT-N close on the
run's outcome, never by fiat at plan time. A verdict worth recording on DKT-N
itself goes in a comment there — it is tracker-side, outside the run, so the
body-freeze rule does not apply to it.

## 4. Leave later phases uncomposed when you honestly cannot compose them

Some requests cannot be planned to the end — "audit and then build what we
find" does not have a knowable second half. Do not invent one. Record phase one
fully, and record phase two as a single human-gate issue that says what will be
decided and by whom.

The run activates on phase one. When phase one finishes, the operator answers
the gate, and a *fresh* planner invocation reads the run record — steps,
findings, gate notes — and appends phase two. Activation lints the extension
like any other graph.

This is a designed shape, not a fallback. Use it whenever the honest answer to
"what are the phase-two issues" is "that depends on what phase one finds."

## 5. Stop

Present the plan — the issues, their edges, the scopes, the budget — and say
plainly that activating it is the operator's call. Then stop.

Do not offer to activate it yourself as a convenience. Do not start the run.
Do not keep the plan in your head for later; it is in Docket now, which is the
point. If the operator wants it running, they say so, and the `conduct` skill
takes it from there.

If the operator asks for activation in THIS session, run the activate verb on
their words (`--dry-run` first — it is the same transaction rolled back) and
then hand off to `conduct` in-session by invoking the skill. Expect the
run-guard to deny a plain stop while executable work is pending — that deny is
a guard answering, not an instruction to start driving; the handoff through
`conduct` (which surfaces the drive/park/abandon choice to the operator) is the
designed path through it.
