# Docs-Path Taxonomy — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
plus 9 docs-path-touching skills (`adr`, `code-review-verdict`, `design-qa`, `design-review`,
`init-specs`, `prd`, `tdd`, `ux-spec`, `verify-ac`), each carrying a compact, role-scoped
`CANONICAL:DOCS-PATHS-LOCAL` copy. Relocated from
`src/user/claude-code/agents/team-lead.md` §Docs-Path Taxonomy (DKT-59/60 doctrine-home
migration). Deployed at `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Read on demand only —
never `Skill(team-doctrine)`.

---

## Docs-Path Taxonomy

<!-- CANONICAL:DOCS-PATHS:BEGIN -->
Maintained master and authoritative source for `docs/` output-path conventions. Each path family has exactly ONE writer and the skill that authors that path is the authority for its shape; every other agent READS. Each agent — and each docs-path-touching skill (`src/user/claude-code/skills/*` and `.claude/skills/*`) — carries a compact, role-scoped copy (CANONICAL:DOCS-PATHS-LOCAL) in its own file because both agents and skills load into a calling agent's context in isolation; this block is the master those copies are maintained from. The canonical directory name is singular `docs/spec/` — plural `docs/specs/` is the antipattern and must never appear.

| Path | Writer | Readers | Owning skill/agent | Notes |
|---|---|---|---|---|
| `docs/spec/{name}.md` | `init-specs` (Seven Spec Files); `prd` (`{slug}.md`) | all 7 agents | `init-specs`, `prd` | Seven reserved Spec-File names owned by `init-specs`: `architecture.md`, `code-quality.md`, `operations.md`, `performance.md`, `review-strategy.md`, `security.md`, `testing.md`. Any other `docs/spec/{slug}.md` is a `prd`-authored PRD. Singular `spec` — NOT `specs`. |
| `docs/tdd/{slug}.md` | `tdd` skill | staff/security/senior/sdet/pm/ux | `tdd` | Technical design records. |
| `docs/tdd/adr/{NNNN}-{slug}.md` | `adr` skill | staff/security/senior/sdet/pm/ux | `adr` | Numbered ADRs nested under `docs/tdd/`. |
| `docs/ux/{slug}.md` | `ux-spec` skill | ux/senior/sdet/pm; staff consumes | `ux-spec` | User-facing design specs. |
| `docs/changelog/agents/*.md` | `evolve-agents` skill | evolve cycles | `evolve-agents` | Agent-evolution changelog. |
| `docs/changelog/skills/*.md` | `evolve-skills` skill | evolve cycles | `evolve-skills` | Skill-evolution changelog. |
| `docs/changelog/model-distribution/*.md` | `evolve-model-distribution` skill | evolve cycles | `evolve-model-distribution` | Model-routing (`team-lead.md`) evolution changelog. |

**On-disk status ≠ orphan.** A path family with a declared writer in the table above is canonical whether or not it currently exists on disk. Skill-owned paths created on first write — currently `docs/spec/`, `docs/ux/`, and `docs/tdd/adr/` are not yet materialized — are NOT orphans; their absence on disk simply means no one has invoked the owning skill yet. A future drift-lint MUST treat "declared writer, absent on disk" as healthy, never as an orphan.

**Known orphan (genuine):** `docs/audit/` exists on disk but is empty and has NO declared writer or reader in any agent or skill — it is the one true orphan. It is out of scope for this taxonomy (definitions-only; touching `docs/` is forbidden here). Follow-up mechanism: it needs an ADR to either wire a writer or `rmdir` it — do NOT wire new writes to it without that ADR.
<!-- CANONICAL:DOCS-PATHS:END -->
