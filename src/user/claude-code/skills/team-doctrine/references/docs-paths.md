# Docs-Path Taxonomy — Maintained Master

Authoritative source for `docs/` output-path conventions; agents and docs-path-touching
skills carry compact `CANONICAL:DOCS-PATHS-LOCAL` pointers. Deployed at
`~/.claude/skills/team-doctrine/references/docs-paths.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/docs-paths.md`.

---

## Docs-Path Taxonomy

<!-- CANONICAL:DOCS-PATHS:BEGIN -->
Each path family has exactly ONE writer, and the skill that authors that path is the
authority for its shape; every other agent READS. The canonical directory name is singular
`docs/spec/` — plural `docs/specs/` must never appear.

| Path | Writer | Readers | Notes |
|---|---|---|---|
| `docs/spec/{name}.md` | `init-specs` (Seven Spec Files); `prd` (`{slug}.md`) | all 8 agents | Seven reserved Spec-File names owned by `init-specs`: `architecture.md`, `code-quality.md`, `operations.md`, `performance.md`, `review-strategy.md`, `security.md`, `testing.md`. Any other `docs/spec/{slug}.md` is a `prd`-authored PRD. |
| `docs/tdd/{slug}.md` | `tdd` skill | staff/security/pm/ux/distinguished | EPHEMERAL — Design/Planning input only; deletable after the cycle's implementation completes. |
| `docs/adr/{NNNN}-{slug}.md` | `adr` skill | staff/security/senior/sdet/pm/ux/distinguished | Numbered ADRs — durable decision records. |
| `docs/ux/{slug}.md` | `ux-spec` skill | ux/senior/sdet/pm; staff + distinguished consume | User-facing design specs. |
| `docs/changelog/claude-code/{agents,skills,config,model-distribution}/*.md` | the matching `evolve-*` skill | evolve cycles | Evolution changelogs. |

**On-disk status ≠ orphan.** A path family with a declared writer is canonical whether or
not it exists on disk yet — skill-owned paths are created on first write. One genuine
orphan: `docs/audit/` exists empty with no declared writer or reader; wiring a writer to it
needs an ADR first.

**Where definitions live.** The 5 evolve-* skills live ONLY under `.claude/skills/<name>/`
(project-scoped, never deployed to `~/.claude/`); every other skill lives at
`~/.claude/skills/<name>/` (deployed) with source at `src/user/claude-code/skills/<name>/`.
`docs/` and the repo's `.claude/` tree (agent-memory, skills, settings) live at the REPO
ROOT; `src/user/claude-code/` is the source tree for deployed agents/skills/scripts only.
When citing this repo's own agent/skill/script SOURCE by repo-relative path, the path starts
with `src/user/claude-code/` (sole exception: the evolve-* skills, cited at
`.claude/skills/<name>/SKILL.md`).

**Ephemerality doctrine.** The two rules below are the canonical source for `docs/tdd/` and
Docket-issue ephemerality; every LOCAL copy cites this section instead of restating it.

**Persistence & lifecycle (canonical).** `docs/` path families split into DURABLE records —
`docs/spec/`, `docs/ux/`, `docs/adr/`, `docs/changelog/`, never deleted as routine hygiene —
and EPHEMERAL working artifacts: `docs/tdd/` files and Docket issues, working artifacts of a
single delivery cycle. A TDD is authored, consulted, and accepted ONLY during Design and
Planning; it is never a required input for Implementation, Review, or Verification, and is
safely deletable any time after its cycle's implementation completes. The durable "learned"
record of a cycle is its distilled final solution — code, comments, tests, commit history —
plus whatever was distilled into ADRs and `docs/spec/`.

**Distillation Gate.** At decomposition, @project-manager copies every contract, constraint,
acceptance criterion, and non-obvious WHY an issue depends on VERBATIM into the issue body.
TDD provenance annotations surviving in issue bodies or briefs are structurally inert: they
name the TDD by slug and section ("TDD 'foo' §4, accepted vote V-12"), never by file path,
and must never need dereferencing (ADR citations under `docs/adr/` remain path-cited —
durable). Self-containment test for every issue leaving Planning: "Could this issue be
implemented, reviewed, and verified correctly if `docs/tdd/` were deleted right now?" An
issue that fails is a planning defect. No agent may fail, block, or degrade output because a
`docs/tdd/` file is missing.
<!-- CANONICAL:DOCS-PATHS:END -->
