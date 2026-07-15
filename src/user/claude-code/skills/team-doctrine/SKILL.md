---
name: team-doctrine
description: >
  Read-on-demand reference home for team-wide doctrine relocated out of team-lead.md's system
  prompt — Runtime Discipline (R1-R7), Truth-First Debugging, Docs-Path Taxonomy, the
  Vorpal-managed tool inventory, Deep Collaboration mechanics, the recurring-pitfalls memory
  convention, the Shutdown Protocol (SP-1/SP-2), the Communication-Discipline
  rule-numbering convention, the Design-Complete Gate (per-pattern artifact/acceptance table,
  Design-source grammar), and the Fable-distilled completeness / Monitor-for-Orchestration
  watch-pattern heuristics. This is a reference index, NOT an invocable workflow — do not
  `Skill(team-doctrine)`. Read the specific `references/*.md` file a `CANONICAL:*-LOCAL`
  pointer in an agent file cites; there is no trigger phrase that should load this into
  context speculatively.
allowed-tools: ["Read"]
disable-model-invocation: true
---

# Team Doctrine

A reference home, not a workflow. Most files here are doctrine masters: each agent file carries a compact `CANONICAL:<NAME>-LOCAL`
copy of the doctrine below and cites the matching file here as its maintained master — Read
that file only when a LOCAL-copy pointer sends you here (TDD conformance check, master-vs-copy
drift audit, or an evolve-* cycle). A second class is the spawn-TEMPLATE store (`evolve-phase0-templates.md`): paste-at-spawn-time, token-contracted bodies with NO `CANONICAL:*-LOCAL` copies, Read once by an evolve-* orchestrator at Phase-0 spawn and token-substituted — never mirrored into an agent file. Never invoke this skill; there is nothing to execute, and
doing so would violate R2 Skill Invocation Restraint (`references/runtime-discipline.md`). Frontmatter `disable-model-invocation: true` enforces exactly that — it blocks model-initiated `Skill()` calls only, not operator invocation: an operator-typed `/team-doctrine` still resolves and harmlessly renders this index.

**Index maintenance:** when adding/removing a `references/*.md` file, update the table below in the same change — `ls references/*.md | wc -l` MUST equal the table's data-row count. Run `bash src/user/claude-code/scripts/doctrine_check.sh` (repo: `src/user/claude-code/scripts/doctrine_check.sh`) to verify this mechanically — it also checks (b) every `CANONICAL:*-LOCAL` `Master:` pointer resolves to an existing file and (c) `CANONICAL:<TAG>` blocks stay byte-identical across the carriers listed in `src/user/claude-code/scripts/doctrine_check_manifest.tsv` (append new tag/carrier rows there, e.g. for a newly parity-locked block). Read-only; exits 1 if any arm fails.

| Reference file | Master for | Cited by (LOCAL-copy consumers) |
|---|---|---|
| `references/runtime-discipline.md` | R1-R7 canonical bodies + per-agent applicability matrix | all 7 agents (full bodies where applicable) + `team-lead.md` (LOCAL bodies for R1/R3/R4/R6, pointer for R2/R5/R7) |
| `references/truth-first-debugging.md` | Truth-First Debugging (TFD-1..5, pre-fix gate) | all 7 agents + `team-lead.md` |
| `references/docs-paths.md` | Docs-Path Taxonomy (`docs/` output-path ownership) | all 7 agents + `team-lead.md` + 9 docs-path-touching skills (`adr`, `code-review-verdict`, `design-qa`, `design-review`, `init-specs`, `prd`, `tdd`, `ux-spec`, `verify-ac`) |
| `references/vorpal-tools.md` | Vorpal-managed tool inventory + pinned versions | all 7 agents + `team-lead.md` |
| `references/deep-collaboration.md` | Deep-collaboration mechanics (peer challenge/critique, shared task list, cross-examination) | all 7 agents + `team-lead.md` |
| `references/pitfalls.md` | Recurring-pitfalls memory convention — content-split across in-repo (`.claude/agent-memory/{role}/pitfalls.md`) and centralized (`~/.claude/agent-memory/{role}/pitfalls.md`) homes | all 7 agents + `team-lead.md` |
| `references/retention-compaction.md` | Retention & Compaction Policy (per-file changelog retention budget + pitfalls-file compaction) | 4 evolve-* skills (`evolve-agents`, `evolve-skills`, `evolve-config`, `evolve-model-distribution`) |
| `references/shutdown-protocol.md` | Shutdown protocol (SP-1 silent-approve, SP-2 teammate-vs-subagent discriminator) | all 7 agents + `team-lead.md` (also retains a compact LOCAL copy — the lead operates the handshake every cycle) |
| `references/team-conventions.md` | Communication-Discipline rule-numbering convention | `team-lead.md` only (self-referential meta-convention; no worker agent cites this master) |
| `references/laziness-discipline.md` | Laziness Discipline (the lazy-developer ladder, Rules, Output, When NOT to be lazy, Boundaries) | `senior-engineer.md`, `sdet.md` |
| `references/design-gate.md` | Design-Complete Gate (per-pattern artifact/acceptance table, Design-source grammar, mid-cycle interaction) | `team-lead.md` only (Rule 10 + choke-point hooks — pointer-only, no LOCAL copy) |
| `references/fable-completeness-heuristics.md` | Fable-distilled completeness heuristics (provenance, honest scope, full bullet bodies) | `team-lead.md` (compact LOCAL copy) |
| `references/monitor-orchestration.md` | Monitor-for-Orchestration watch patterns | `team-lead.md` (compact LOCAL copy) |
| `references/authoring-verification-gates.md` | Authoring verification gates for TDD/review authors (executable-claim, negative-claim re-grep, insertion-anchor, byte-budget) | `staff-engineer.md`, `distinguished-engineer.md` |
| `references/sandbox-recovery.md` | Sandbox-recovery retry signatures (`.git/index.lock`, loopback bind, out-of-repo state-dir writes) | `sdet.md`, `security-engineer.md`, `senior-engineer.md`, `staff-engineer.md` |
| `references/evolve-phase0-templates.md` | Shared evolve-* Phase-0 spawn templates — auditors plus evolve-agents' SDLC Role Research (§9) (spawn-TEMPLATE store: paste-at-spawn-time, token-contracted; NOT a doctrine master with LOCAL copies) | `evolve-agents`, `evolve-skills`, `evolve-config` skills (Read-once at Phase-0 spawn) |
