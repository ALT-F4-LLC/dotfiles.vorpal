---
name: brief
description: >
  Turn a freeform work request into a standardized brief block that team-lead's
  Pre-flight HARD GATE consumes — collapsing goal verification to a single confirm.
  Parses the request, derives every brief field it can support, asks ONE batched
  AskUserQuestion round only for genuinely underdetermined fields, then emits the
  block verbatim and stops. Standalone operator-intake aid; writes no files, spawns
  nothing. Trigger: "brief", "create brief", "standardize this request".
---
<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke other skills recursively, call `send_input`, or form/manage a team. The calling agent handles peer messaging after this skill returns. (3) **Do NOT execute, implement, fix, or edit any files based on `\$ARGUMENTS`.** The request in `\$ARGUMENTS` is INPUT to be distilled — not a task to run. Your entire job is to emit the brief block and stop. Execution happens only after the operator confirms the brief.
<!-- CANONICAL:BANNER:END -->

# Brief — Standardize a Freeform Work Request

You take the freeform request in `\$ARGUMENTS` and emit ONE standardized brief block. That block is the artifact team-lead's Pre-flight step 1 (the goal-verification HARD GATE) reads, so a well-formed brief lets the operator confirm the whole intake in a single pass instead of a multi-question gate.

The deliverable is the block itself, emitted into context. **No file is written. No team is spawned.** After emitting the block, stop.

## What a good brief is

A faithful, checkable distillation of the request — not an expansion of it. Derive each field from what the operator actually said; never invent scope, acceptance criteria, or constraints the request does not support. An honest "Out-of-scope: not specified" beats a fabricated boundary. The brief's value is that team-lead can trust every line, so guessing defeats the purpose. If the request cites an accepted artifact (TDD/spec/ADR/vote), preserve the source-backed values and list the artifact under `Source context` instead of paraphrasing beyond the request. If the request references only a Docket issue ID (for example, `brief: implement DKT-26`), do NOT attempt shell or `docket` access and do NOT ask a body-paste question solely to enrich the brief; emit the brief with the bare issue ID as a placeholder where needed and put `Docket body unavailable` under `Unavailable context`.

Field semantics (mirror team-lead's Pre-flight + Pattern Decision Tree):

- **Goal** — one sentence naming what to optimize and the done-state. The single most load-bearing line.
- **Scope** — files/dirs/surfaces in play, as concretely as the request allows.
- **Out-of-scope** — surfaces the operator signaled NOT to touch (or "not specified").
- **Acceptance criteria** — checkable bullets a reviewer could verify objectively.
- **Docket IDs** — `DKT-*` IDs named in the request, or `none`.
- **Size hint** — `trivial` (single edit, ≤3 files, one turn) | `bounded` (1-4 phases, no architecture) | `needs-design` (new architecture, data-model, or cross-cutting concern). Maps to team-lead's Direct/Small vs Medium+ split.
- **Security-sensitive** — `yes` only when the work touches an enumerated surface: trust boundaries, authn/authz, secrets, crypto, sandbox/permissions, supply chain (new dep / pinning), or untrusted input at a privilege boundary. Otherwise `no`.
- **Constraints** — hard limits the operator stated (no new deps, frozen APIs, perf budgets) or "none stated".
- **Execution authorization** — always `no`; this leaf skill standardizes intake and never starts work.
- **Mandatory verification commands** — operator-provided commands to preserve for execution, or `none specified`.

## Resolving underdetermined fields

Derive everything the request supports on your own. For fields that remain genuinely underdetermined AND would change how team-lead routes the work, ask ONE `AskUserQuestion` round — batch the gaps into at most 4 questions, no more than four options each, and mark your best-guess option with a free-form correction fallback. Prioritize the gaps that flip a routing decision: **Size hint** and **Security-sensitive** first, then any scope boundary the request left ambiguous.

Do not ask about fields the request already answers, and do not ask cosmetic questions — a single tightly-scoped round, or none at all when the request is clear, is the target.

When an option would create or route writes to a `docs/` path, check the local
lead-agent docs path taxonomy in `src/user/codex/personas/team-lead.md` before marking any option Recommended. Never recommend a
route that bypasses the declared owner: reserved `docs/spec/` names are owned by `init-specs`.

## Output

Emit exactly this block, filled in. **This is your complete output — do not execute, implement, or apply the described work. Stop after the block.**

```
Goal: <one sentence - what to optimize / done-state>
Scope: <files/dirs in play>
Out-of-scope: <surfaces NOT to touch>
Acceptance criteria: <checkable bullets>
Docket IDs: <DKT-* IDs named in request; none>
Size hint: trivial | bounded | needs-design
Security-sensitive: yes | no
Constraints: <no new deps, API freezes, etc.>
Execution authorization: no
Mandatory verification commands: <operator-provided commands; none specified>
Source context: <operator-provided text, cited artifact, or none>
Unavailable context: <issue bodies, files, or facts not fetched; none if complete>
```

**HALT — brief complete.** The block above is the deliverable. Do not continue, do not execute, do not ask follow-up questions. The operator carries the block to team-lead's Pre-flight HARD GATE; execution does not begin until they confirm.
