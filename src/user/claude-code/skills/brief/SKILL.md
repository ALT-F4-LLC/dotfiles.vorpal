---
name: brief
description: >
  Turn a freeform work request into a standardized brief block that team-lead's
  Pre-flight HARD GATE consumes — collapsing goal verification to a single confirm.
  Parses the request, derives every brief field it can support, asks ONE batched
  AskUserQuestion round only for genuinely underdetermined fields, then emits the
  block verbatim and stops. Standalone operator-intake aid; writes no files, spawns
  nothing. Trigger: "create brief", "brief this request", "standardize this request".
argument-hint: "<freeform work request>"
allowed-tools: Read, Grep, Glob, AskUserQuestion
disallowed-tools: Edit, Write, Agent, SendMessage
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns. (3) **Do NOT execute, implement, fix, or edit any files based on `\$ARGUMENTS`.** The request in `\$ARGUMENTS` is INPUT to be distilled — not a task to run. Your entire job is to emit the brief block and stop. Execution happens only after the operator confirms the brief.
<!-- CANONICAL:BANNER:END -->

# Brief — Standardize a Freeform Work Request

You take the freeform request in `\$ARGUMENTS` and emit ONE standardized brief block. That block is the artifact team-lead's Pre-flight step 1 (the goal-verification HARD GATE) reads, so a well-formed brief lets the operator confirm the whole intake in a single pass instead of a multi-question gate.

The deliverable is the block itself, emitted into context. **No file is written. No team is spawned.** After emitting the block, stop.

## What a good brief is

A faithful, checkable distillation of the request — not an expansion of it. Derive each field from what the operator actually said; never invent scope, acceptance criteria, or constraints the request does not support. An honest "Out-of-scope: not specified" beats a fabricated boundary. The brief's value is that team-lead can trust every line, so guessing defeats the purpose. Use your read-only tools only to SCOPE the brief (confirm a path exists, size a surface) — never to perform the investigation, verification, or fix the request describes; producing that answer is the dispatched agent's job, not the brief's. When the request points to an accepted artifact (a TDD, spec, ADR, or vote outcome) that fixes a field's value, cite that source line verbatim — with its source locator (file/§/line, or vote ID) — rather than paraphrasing it, so team-lead can re-verify instead of trusting the brief's word; a paraphrased value can silently diverge from what was voted and accepted. Before emitting, self-check each file-backed verbatim citation with the `Grep` tool: search the cited file for the quoted line as a fixed string; on a miss, mark that field `unverified quote — source drifted` rather than presenting it as citable — a drifted quote defeats the re-verification team-lead's Pre-flight HARD GATE relies on. This is the brief-quality test: "Show your prompt to a colleague with minimal context on the task and ask them to follow it. If they'd be confused, Claude will be too."

Field semantics (mirror team-lead's Pre-flight + Pattern Decision Tree):

- **Goal** — one sentence naming what to optimize and the done-state. The single most load-bearing line.
- **Motivation** — the WHY behind the request: the reason, decision context, or problem that prompted it, drawn only from what the operator actually said. An honest "not stated" (mirroring "Out-of-scope: not specified") beats an invented rationale. Context only — never gates or reshapes the brief.
- **Scope** — files/dirs/surfaces in play, as concretely as the request allows. For a cross-cutting "find every reference/usage of X" request, do NOT enumerate a fixed site list as the Scope (it will be incomplete) — frame Scope and Acceptance criteria as an independent repo-root re-derivation (grep from repo root with explicit exemptions) so downstream re-sweeps rather than inheriting a partial list.
- **Out-of-scope** — surfaces the operator signaled NOT to touch (or "not specified").
- **Acceptance criteria** — checkable bullets a reviewer could verify objectively.
- **Size hint** — `trivial` (single edit, ≤3 files, one turn) | `bounded` (1-4 phases, no architecture) | `needs-design` (new architecture, data-model, or cross-cutting concern). Maps to team-lead's Direct/Small vs Medium+ split.
- **Security-sensitive** — `yes` only when the work touches an enumerated surface: trust boundaries, authn/authz, secrets, crypto, sandbox/permissions, supply chain (new dep / pinning), or untrusted input at a privilege boundary. Otherwise `no`.
- **Constraints** — hard limits the operator stated (no new deps, frozen APIs, perf budgets) or "none stated".

When the request references a Docket issue by ID (e.g. `PROJ-42`) rather than inline content, do NOT attempt to fetch it — brief has no `Bash`/`docket` access, and retrying disallowed fetches stalls the intake against the permission gate. Ask the operator to paste the issue body, or emit the brief with a bare-ID placeholder Goal that flags the body as unavailable.

## Resolving underdetermined fields

Derive everything the request supports on your own. For fields that remain genuinely underdetermined AND would change how team-lead routes the work, ask ONE `AskUserQuestion` round — batch the gaps into at most 4 questions (max 4 options each), each with your best-guess option marked and a free-text fallback. Prioritize the gaps that flip a routing decision: **Size hint** and **Security-sensitive** first, then any scope boundary the request left ambiguous.

Do not ask about fields the request already answers, and do not ask cosmetic questions — a single tightly-scoped round, or none at all when the request is clear, is the target.

When an option would create or route writes to a `docs/` path, check the owning writer in the Docs-Path Taxonomy master `~/.claude/skills/team-doctrine/references/docs-paths.md` (repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`) before marking any option Recommended — never recommend a route that bypasses the declared owner (e.g. the seven reserved `docs/spec/` names belong to `init-specs`).

## Output

Emit exactly this block, filled in. **This is your complete output — do not execute, implement, or apply the described work. Stop after the block.**

```
Goal: <one sentence — what to optimize / done-state>
Motivation: <the WHY behind the request, or "not stated">
Scope: <files/dirs in play>
Out-of-scope: <surfaces NOT to touch>
Acceptance criteria: <checkable bullets>
Size hint: trivial | bounded | needs-design
Security-sensitive: yes | no
Constraints: <no new deps, API freezes, etc.>
```

**HALT — brief complete.** The block above is the deliverable. Do not continue, do not execute, do not ask follow-up questions. The operator carries the block to team-lead's Pre-flight HARD GATE; execution does not begin until they confirm.

## When NOT to use

- **The request is already structured** as a goal + scope + acceptance criteria — there is nothing to standardize; hand it straight to team-lead.
