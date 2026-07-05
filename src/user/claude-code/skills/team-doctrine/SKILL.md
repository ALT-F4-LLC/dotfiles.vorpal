---
name: team-doctrine
description: >
  Read-on-demand reference home for team-wide doctrine relocated out of team-lead.md's system
  prompt — Runtime Discipline (R1-R7), Truth-First Debugging, Docs-Path Taxonomy, the
  Vorpal-managed tool inventory, Deep Collaboration mechanics, the recurring-pitfalls memory
  convention, the Shutdown Protocol (SP-1/SP-2), and the Communication-Discipline
  rule-numbering convention. This is a reference index, NOT an invocable workflow — do not
  `Skill(team-doctrine)`. Read the specific `references/*.md` file a `CANONICAL:*-LOCAL`
  pointer in an agent file cites; there is no trigger phrase that should load this into
  context speculatively.
allowed-tools: ["Read"]
---

# Team Doctrine

A reference home, not a workflow. Every agent file carries a compact `CANONICAL:<NAME>-LOCAL`
copy of the doctrine below and cites the matching file here as its maintained master — Read
that file only when a LOCAL-copy pointer sends you here (TDD conformance check, master-vs-copy
drift audit, or an evolve-* cycle). Never invoke this skill; there is nothing to execute, and
doing so would violate R2 Skill Invocation Restraint (`references/runtime-discipline.md`).

| Reference file | Master for | Cited by (LOCAL-copy consumers) |
|---|---|---|
| `references/runtime-discipline.md` | R1-R7 canonical bodies + per-agent applicability matrix | all 7 agents (full bodies where applicable) + `team-lead.md` (LOCAL bodies for R1/R3/R4/R6, pointer for R2/R5/R7) |
| `references/truth-first-debugging.md` | Truth-First Debugging (TFD-1..5, pre-fix gate) | all 7 agents + `team-lead.md` |
| `references/docs-paths.md` | Docs-Path Taxonomy (`docs/` output-path ownership) | all 7 agents + `team-lead.md` + 9 docs-path-touching skills (`adr`, `code-review-verdict`, `design-qa`, `design-review`, `init-specs`, `prd`, `tdd`, `ux-spec`, `verify-ac`) |
| `references/vorpal-tools.md` | Vorpal-managed tool inventory + pinned versions | all 7 agents + `team-lead.md` |
| `references/deep-collaboration.md` | Deep-collaboration mechanics (peer challenge/critique, shared task list, cross-examination) | all 7 agents + `team-lead.md` |
| `references/pitfalls.md` | Recurring-pitfalls memory convention — content-split across in-repo (`.claude/agent-memory/{role}/pitfalls.md`) and centralized (`~/.claude/agent-memory/{role}/pitfalls.md`) homes | all 7 agents + `team-lead.md` |
| `references/shutdown-protocol.md` | Shutdown protocol (SP-1 silent-approve, SP-2 teammate-vs-subagent discriminator) | all 7 agents + `team-lead.md` (also retains a compact LOCAL copy — the lead operates the handshake every cycle) |
| `references/team-conventions.md` | Communication-Discipline rule-numbering convention | `team-lead.md` only (self-referential meta-convention; no worker agent cites this master) |
| `references/laziness-discipline.md` | Laziness Discipline (the lazy-developer ladder, Rules, Output, When NOT to be lazy, Boundaries) | `senior-engineer.md`, `sdet.md` |
