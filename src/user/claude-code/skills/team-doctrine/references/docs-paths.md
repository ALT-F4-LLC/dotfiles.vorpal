# Docs-Path Taxonomy — Maintained Master

**LOCAL-copy consumers:** all 7 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`,
`distinguished-engineer.md`) plus `team-lead.md`,
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
| `docs/spec/{name}.md` | `init-specs` (Seven Spec Files); `prd` (`{slug}.md`) | all 8 agents | `init-specs`, `prd` | Seven reserved Spec-File names owned by `init-specs`: `architecture.md`, `code-quality.md`, `operations.md`, `performance.md`, `review-strategy.md`, `security.md`, `testing.md`. Any other `docs/spec/{slug}.md` is a `prd`-authored PRD. Singular `spec` — NOT `specs`. |
| `docs/tdd/{slug}.md` | `tdd` skill | staff/security/pm/ux/distinguished | `tdd` | Technical design records — EPHEMERAL: Design/Planning input only; safely deletable any time after the cycle's implementation completes. |
| `docs/adr/{NNNN}-{slug}.md` | `adr` skill | staff/security/senior/sdet/pm/ux/distinguished | `adr` | Numbered ADRs — durable decision records (relocated out of the ephemeral TDD directory). |
| `docs/ux/{slug}.md` | `ux-spec` skill | ux/senior/sdet/pm; staff + distinguished consume | `ux-spec` | User-facing design specs. |
| `docs/changelog/agents/*.md` | `evolve-agents` skill | evolve cycles | `evolve-agents` | Agent-evolution changelog. |
| `docs/changelog/skills/*.md` | `evolve-skills` skill | evolve cycles | `evolve-skills` | Skill-evolution changelog. |
| `docs/changelog/model-distribution/*.md` | `evolve-model-distribution` skill | evolve cycles | `evolve-model-distribution` | Model-routing (`team-lead.md`) evolution changelog. |

**On-disk status ≠ orphan.** A path family with a declared writer in the table above is canonical whether or not it currently exists on disk. Skill-owned paths created on first write — currently `docs/spec/`, `docs/ux/`, and `docs/adr/` are not yet materialized — are NOT orphans; their absence on disk simply means no one has invoked the owning skill yet. A future drift-lint MUST treat "declared writer, absent on disk" as healthy, never as an orphan.

**Known orphan (genuine):** `docs/audit/` exists on disk but is empty and has NO declared writer or reader in any agent or skill — it is the one true orphan. It is out of scope for this taxonomy (definitions-only; touching `docs/` is forbidden here). Follow-up mechanism: it needs an ADR to either wire a writer or `rmdir` it — do NOT wire new writes to it without that ADR.

**Ephemerality doctrine.** The following two rules — Persistence & lifecycle and the Distillation Gate — are the canonical source for `docs/tdd/` and Docket-issue ephemerality; every LOCAL copy elsewhere cites this section instead of restating it.

**Persistence & lifecycle (canonical).** `docs/` path families split into DURABLE
records and EPHEMERAL working artifacts. Durable: `docs/spec/`, `docs/ux/`,
`docs/adr/`, `docs/changelog/` — they describe current state or preserve decisions
and are never deleted as routine hygiene. Ephemeral: `docs/tdd/` files and Docket
issues — working artifacts of a single delivery cycle. A TDD is authored, consulted,
and accepted ONLY during the Design and Planning phases; it is never a required
input for Implementation, Review, or Verification, and it is safely deletable at
any time after its cycle's implementation completes. The durable "learned" record
of a cycle is its distilled final solution — code, comments, tests, commit
history — plus whatever was distilled into ADRs and `docs/spec/`.

**Distillation Gate.** At decomposition, @project-manager copies every contract,
constraint, acceptance criterion, and non-obvious WHY an issue depends on VERBATIM
into the issue body. TDD provenance annotations surviving in issue bodies or
dispatch briefs are structurally inert: they name the TDD by slug and section
(e.g. "TDD 'foo' §4, accepted vote V-12"), never by file path, and must never
need dereferencing (ADR citations under `docs/adr/` remain path-cited and
dereferenceable — durable). Self-containment test for every
issue leaving Planning: "Could this issue be implemented, reviewed, and verified
correctly if `docs/tdd/` were deleted right now?" An issue that fails is a planning
defect. No agent may fail, block, or degrade output because a `docs/tdd/` file is
missing.
<!-- CANONICAL:DOCS-PATHS:END -->
