---
name: brief
description: >
  Turn a freeform work request into a standardized brief block that team-lead's
  Pre-flight HARD GATE consumes — collapsing goal verification to a single confirm.
  Parses the request, derives every brief field it can support, asks ONE batched
  AskUserQuestion round only for genuinely underdetermined fields, then emits the
  block verbatim and stops. Standalone operator-intake aid; writes no files, spawns
  nothing. Trigger: "brief", "create brief", "standardize this request".
argument-hint: "<freeform work request>"
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles any follow-up after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Brief — Standardize a Freeform Work Request

You take the freeform request in `\$ARGUMENTS` and emit ONE standardized brief block. That block is the artifact team-lead's Pre-flight step 1 (the goal-verification HARD GATE) reads, so a well-formed brief lets the operator confirm the whole intake in a single pass instead of a multi-question gate.

The deliverable is the block itself, emitted into context. **No file is written. No team is spawned.** After emitting the block, stop.

## What a good brief is

A faithful, checkable distillation of the request — not an expansion of it. Derive each field from what the operator actually said; never invent scope, acceptance criteria, or constraints the request does not support. An honest "Out-of-scope: not specified" beats a fabricated boundary. The brief's value is that team-lead can trust every line, so guessing defeats the purpose.

Field semantics (mirror team-lead's Pre-flight + Pattern Decision Tree):

- **Goal** — one sentence naming what to optimize and the done-state. The single most load-bearing line.
- **Scope** — files/dirs/surfaces in play, as concretely as the request allows.
- **Out-of-scope** — surfaces the operator signaled NOT to touch (or "not specified").
- **Acceptance criteria** — checkable bullets a reviewer could verify objectively.
- **Size hint** — `trivial` (single edit, ≤3 files, one turn) | `bounded` (1-4 phases, no architecture) | `needs-design` (new architecture, data-model, or cross-cutting concern). Maps to team-lead's Direct/Small vs Medium+ split.
- **Security-sensitive** — `yes` only when the work touches an enumerated surface: trust boundaries, authn/authz, secrets, crypto, sandbox/permissions, supply chain (new dep / pinning), or untrusted input at a privilege boundary. Otherwise `no`.
- **Constraints** — hard limits the operator stated (no new deps, frozen APIs, perf budgets) or "none stated".

## Resolving underdetermined fields

Derive everything the request supports on your own. For fields that remain genuinely underdetermined AND would change how team-lead routes the work, ask ONE `AskUserQuestion` round — batch the gaps into at most 4 questions (max 4 options each), each with your best-guess option marked and a free-text fallback. Prioritize the gaps that flip a routing decision: **Size hint** and **Security-sensitive** first, then any scope boundary the request left ambiguous.

Do not ask about fields the request already answers, and do not ask cosmetic questions — a single tightly-scoped round, or none at all when the request is clear, is the target.

When an option would create or route writes to a `docs/` path, check the owning writer in `agents/team-lead.md` §Docs-Path Taxonomy before marking any option Recommended — never recommend a route that bypasses the declared owner (e.g. the seven reserved `docs/spec/` names belong to `init-specs`).

## Output

Emit exactly this block, filled in, then stop:

```
Goal: <one sentence — what to optimize / done-state>
Scope: <files/dirs in play>
Out-of-scope: <surfaces NOT to touch>
Acceptance criteria: <checkable bullets>
Size hint: trivial | bounded | needs-design
Security-sensitive: yes | no
Constraints: <no new deps, API freezes, etc.>
```

## When NOT to use

- **The request is already structured** as a goal + scope + acceptance criteria — there is nothing to standardize; hand it straight to team-lead.
- **A mid-cycle scope change** on work already in flight — those route through team-lead's re-plan path, not a fresh brief.
