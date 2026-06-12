---
name: brief
description: >
  Turn a freeform work request into a standardized intake brief block for
  pre-flight goal verification. Use when the user says "brief", "create brief",
  "standardize this request", or asks to collapse a work request into goal,
  scope, acceptance criteria, size, security, and constraints. Instruction-only;
  writes no files, commits nothing, and does not delegate to subagents.
---

# Brief - Standardize a Freeform Work Request

Take the current user request or explicit `$brief` invocation text and emit one
standardized brief block. The block is the artifact a lead agent can read for a
single-pass pre-flight confirmation.

The deliverable is the block itself, emitted into the conversation. Do not write
files, stage changes, commit, push, spawn subagents, invoke other skills, or
delegate through parallel agent workflows. After emitting the block, stop.

## Brief Quality

Create a faithful, checkable distillation of the request. Do not expand the
request, invent scope, fabricate acceptance criteria, or add constraints the
user did not state. Use "not specified" or "none stated" when the source request
does not support a stronger claim.

Field semantics:

- **Goal** - one sentence naming what to optimize and the done-state.
- **Scope** - files, directories, systems, or surfaces in play, as concretely as
  the request allows.
- **Out-of-scope** - surfaces the user signaled not to touch, or "not specified".
- **Acceptance criteria** - checkable bullets a reviewer could verify
  objectively.
- **Size hint** - `trivial` for a single edit, three or fewer files, and one
  turn; `bounded` for one to four phases with no new architecture;
  `needs-design` for new architecture, data-model work, or cross-cutting
  concerns.
- **Security-sensitive** - `yes` only when the work touches trust boundaries,
  authn/authz, secrets, crypto, sandbox/permissions, supply chain changes such
  as new dependencies or pinning, or untrusted input at a privilege boundary.
  Otherwise use `no`.
- **Constraints** - hard limits the user stated, such as no new dependencies,
  frozen APIs, or performance budgets; otherwise "none stated".

## Resolving Gaps

Derive every supported field yourself. Ask one clarification round only for
fields that remain genuinely underdetermined and would change how the work is
routed.

Prefer a single concise message with at most four numbered questions. Include
your best-guess option for each question and allow free-form correction. If the
runtime exposes a structured user-input tool, use it for that one clarification
round; otherwise ask plainly in the conversation.

Prioritize gaps that change routing:

1. Size hint.
2. Security-sensitive.
3. Scope boundaries.
4. Stated constraints.

Do not ask cosmetic questions. If the request is clear enough to produce a
truthful brief, emit the block without questions.

When an option would create or route writes to a `docs/` path, check the local
lead-agent docs path taxonomy if it is available in context before recommending
that route. If the taxonomy is unavailable and the request only needs an intake
brief, leave the route as "not specified" rather than guessing ownership.

## Output

Emit exactly this block, filled in, then stop:

```text
Goal: <one sentence - what to optimize / done-state>
Scope: <files/dirs/surfaces in play>
Out-of-scope: <surfaces NOT to touch>
Acceptance criteria:
- <checkable criterion>
- <checkable criterion>
Size hint: trivial | bounded | needs-design
Security-sensitive: yes | no
Constraints: <no new deps, API freezes, etc.>
```

## When Not To Use

- The request is already structured as goal, scope, and acceptance criteria.
  There is nothing to standardize.
- The request is a mid-cycle scope change on work already in flight. Route that
  through the active plan or lead-agent re-plan path instead of a fresh brief.
