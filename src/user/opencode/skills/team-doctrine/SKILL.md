---
name: team-doctrine
description: >
  Read-on-demand reference home for team-wide doctrine relocated out of team-lead.md's system
  prompt — Runtime Discipline (R1-R7), Truth-First Debugging, Docs-Path Taxonomy, the
  Vorpal-managed tool inventory, Deep Collaboration mechanics, the recurring-pitfalls memory
  convention, the Shutdown Protocol (SP-1/SP-2), and the Communication-Discipline
  rule-numbering convention. This is a reference index, NOT an invocable workflow — do not
  `skill({ name: "team-doctrine" })`. Read the specific `references/*.md` file a `CANONICAL:*-LOCAL`
  pointer in an agent file cites; there is no trigger phrase that should load this into
  context speculatively.
---

# Team Doctrine

A reference home, not a workflow. Every agent file carries a compact `CANONICAL:<NAME>-LOCAL`
copy of the doctrine below and cites the matching file here as its maintained master — Read
that file only when a LOCAL-copy pointer sends you here (TDD conformance check, master-vs-copy
drift audit, or an evolve-* cycle). Never invoke this skill via the `skill` tool; there is
nothing to execute, and doing so would violate R2 Skill Invocation Restraint
(`references/runtime-discipline.md`).

**Opencode note:** peer-messaging (`SendMessage`), persistent teammates, and the `shutdown`
handshake referenced throughout these masters are INERT under Opencode — Opencode subagents
are one-shot `task`-tool dispatches that run in an isolated child session and return a summary
(no peer messaging, no persistent teammates, no idle, no shutdown handshake). The doctrine
prose is preserved verbatim as the maintained master; sections describing those mechanisms
carry banners marking them historical or hub-relayed under the one-shot model.

| Reference file | Master for | Cited by (LOCAL-copy consumers) |
|---|---|---|
| `references/runtime-discipline.md` | R1-R7 canonical bodies + per-agent applicability matrix | all 6 agents (full bodies where applicable) + `team-lead.md` (LOCAL bodies for R1/R3/R4/R6, pointer for R2/R5/R7) |
| `references/truth-first-debugging.md` | Truth-First Debugging (TFD-1..5, pre-fix gate) | all 6 agents + `team-lead.md` |
| `references/docs-paths.md` | Docs-Path Taxonomy (`docs/` output-path ownership) | all 6 agents + `team-lead.md` + 9 docs-path-touching skills (`adr`, `code-review-verdict`, `design-qa`, `design-review`, `init-specs`, `prd`, `tdd`, `ux-spec`, `verify-ac`) |
| `references/vorpal-tools.md` | Vorpal-managed tool inventory + pinned versions | all 6 agents + `team-lead.md` |
| `references/deep-collaboration.md` | Deep-collaboration mechanics (peer challenge/critique, shared task list, cross-examination) — hub-relayed under Opencode (peer-to-peer mechanics retained as historical) | all 6 agents + `team-lead.md` |
| `references/pitfalls.md` | Recurring-pitfalls memory convention (`~/.opencode/agent-memory/{role}/pitfalls.md`) | all 6 agents + `team-lead.md` |
| `references/shutdown-protocol.md` | Shutdown protocol (SP-1 silent-approve, SP-2 teammate-vs-subagent discriminator) — inert under Opencode (retained as historical reference) | all 6 agents + `team-lead.md` (also retains a compact LOCAL copy stating the protocol is inert under the one-shot model) |
| `references/team-conventions.md` | Communication-Discipline rule-numbering convention | `team-lead.md` only (self-referential meta-convention; no worker agent cites this master) |
| `references/design-gate.md` | Design-Complete Gate (Rule 10) — per-pattern artifact/acceptance table, Design-source grammar, mid-cycle interaction | `team-lead.md` only (Rule 10 cites this master; pointer-only, no LOCAL copy) |
| `references/laziness-discipline.md` | Laziness Discipline (lazy-senior coding reflex) | `senior-engineer.md` + `sdet.md` (each carries a `CANONICAL:LAZINESS-DISCIPLINE-LOCAL` pointer block) |
