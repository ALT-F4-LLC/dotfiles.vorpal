---
name: team-doctrine
description: >
  Read-on-demand reference home for team-wide doctrine relocated out of team-lead.md's system
  prompt — Runtime Discipline (R1-R7), Truth-First Debugging, the Docs-Path Taxonomy, the
  Shutdown Protocol (SP-1/SP-2), and the other masters enumerated in this file's index table;
  that table is the authoritative list and is deliberately not duplicated here. This is a
  reference index, NOT an invocable workflow — do not `Skill(team-doctrine)`. Read the specific
  `references/*.md` file a `CANONICAL:*-LOCAL` pointer in an agent file cites; there is no
  trigger phrase that should load this into context speculatively.
allowed-tools: ["Read"]
disable-model-invocation: true
---

# Team Doctrine

A reference home, not a workflow — there is nothing to execute. Agent files carry compact
`CANONICAL:<NAME>-LOCAL` pointers that cite the matching master below; Read a master only when
a pointer sends you here (TDD conformance check, drift audit, or an evolve-* cycle).
Frontmatter `disable-model-invocation: true` blocks model-initiated `Skill()` calls; an
operator-typed `/team-doctrine` still resolves and harmlessly renders this index. One
exception to the master/pointer model: `evolve-phase0-templates.md` is a spawn-TEMPLATE store
(paste-at-spawn-time, token-contracted, Read once by an evolve-* orchestrator at Phase-0
spawn) — never mirrored into an agent file.

**Source-only — no mirror in the built tree.** This skill lives ONLY at
`src/user/claude-code/skills/team-doctrine/`; there is no `.claude/skills/team-doctrine/`
directory. (Which tree holds a given skill varies: the 5 evolve-* skills live only in
`.claude/skills/`; check both before assuming a path.)

**Index maintenance:** when adding or removing a `references/*.md` file, update the table
below in the same change — `ls references/*.md | wc -l` must equal the table's data-row
count. `bash src/user/claude-code/scripts/doctrine_check.sh` verifies this mechanically, plus
(b) every `CANONICAL:*-LOCAL` `Master:` pointer resolves and (c) manifest-registered
`CANONICAL:<TAG>` blocks stay byte-identical across their carriers
(`src/user/claude-code/scripts/doctrine_check_manifest.tsv`).

| Reference file | Master for | Cited by |
|---|---|---|
| `references/runtime-discipline.md` | R1-R7 canonical bodies + per-agent applicability matrix | 7 agents + `team-lead.md` + `evolve-coherence` |
| `references/truth-first-debugging.md` | Truth-First Debugging (banner, TFD-1..5) | 7 agents + `team-lead.md` |
| `references/docs-paths.md` | Docs-Path Taxonomy (`docs/` output-path ownership, Ephemerality doctrine, Distillation Gate) | 7 agents + `team-lead.md` + 14 docs-path-touching skills (`adr`, `brief`, `code-review-verdict`, `design-qa`, `design-review`, `evolve-agents`, `evolve-config`, `evolve-model-distribution`, `evolve-skills`, `init-specs`, `prd`, `tdd`, `ux-spec`, `verify-ac`) |
| `references/vorpal-tools.md` | Vorpal-managed tool inventory + pinned versions | 7 agents + `team-lead.md` |
| `references/deep-collaboration.md` | Deep-collaboration mechanics (peer challenge, shared task list, cross-examination) | 6 agents (all but `senior-engineer.md`) + `team-lead.md` |
| `references/pitfalls.md` | Recurring-pitfalls memory convention (two-homes content split) | 7 agents + `team-lead.md` |
| `references/retention-compaction.md` | Retention & Compaction Policy (changelog budgets + pitfalls compaction; sole authority for its gate formulas, ledger formats, and invariants) | `evolve-agents`, `evolve-config`, `evolve-model-distribution` |
| `references/shutdown-protocol.md` | Shutdown protocol (SP-1/1b/2/3/4) | 7 agents + `team-lead.md` |
| `references/team-conventions.md` | Communication-Discipline rule-numbering convention | `team-lead.md` + `evolve-coherence` |
| `references/laziness-discipline.md` | Simplicity ladder + when-not-to-simplify boundaries | `senior-engineer.md`, `sdet.md` |
| `references/design-gate.md` | Design-Complete Gate (per-pattern artifact/acceptance table, Design-source grammar) | `team-lead.md` |
| `references/fable-completeness-heuristics.md` | Completeness heuristics for briefs and return-audits | `team-lead.md` |
| `references/monitor-orchestration.md` | Monitor-for-Orchestration watch patterns | `team-lead.md` |
| `references/stall-recovery.md` | Teammate stall/crash triage, Liveness-Gate mechanics, bare-idle disambiguation | `team-lead.md` |
| `references/authoring-verification-gates.md` | Authoring verification gates for TDD/ADR authors | `staff-engineer.md`, `distinguished-engineer.md`, `tdd` |
| `references/sandbox-recovery.md` | Sandbox permission-denial recovery signatures | 6 agents (all but `project-manager.md`) |
| `references/evolve-phase0-templates.md` | Shared evolve-* Phase-0 spawn templates (spawn-TEMPLATE store, token-contracted) | `evolve-agents`, `evolve-skills`, `evolve-config`, `evolve-coherence`, `evolve-model-distribution` |
| `references/evolve-orchestration-core.md` | Shared evolve-* orchestration-core prose (DKT-106) | `evolve-agents`, `evolve-skills`, `evolve-config`, `evolve-coherence`, `evolve-model-distribution` |
