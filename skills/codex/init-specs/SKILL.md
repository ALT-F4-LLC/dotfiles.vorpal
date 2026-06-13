---
name: init-specs
description: >
  Bootstrap docs/spec/ with the standard project specification files. Use when
  asked to create, generate, or initialize project specs. Always delegates spec
  authoring to parent-led Codex staff-engineer subagents, one spec file per
  worker; asks before overwriting existing specs.
---

# Init Specs

Create or refresh project specification files under `docs/spec/`. Do not commit
changes. The parent Codex session coordinates and verifies only; it does not
write spec files itself.

## Spec Files

- `architecture.md`
- `security.md`
- `operations.md`
- `testing.md`
- `performance.md`
- `code-quality.md`
- `review-strategy.md`

If the invocation names files, limit work to those names and reject unknown
names. With no names, target all seven files.

## Spec File Reference

Use the file-specific exploration guidance when briefing each worker:

| Spec File | Exploration Guidance |
|---|---|
| `architecture.md` | Examine project structure, entry points, module boundaries, dependency graph, generated artifacts, and integration points. Defer style and test details to their dedicated specs. |
| `security.md` | Examine trust boundaries, permissions, sandboxing, secret handling, environment variables, generated tool settings, remote access, and security-relevant dependencies. |
| `operations.md` | Examine build, deployment, CI, generated config publication, rollback or recovery paths, runbooks, observability, and environment management. |
| `testing.md` | Examine test directories, runners, test configs, CI test steps, coverage tools, fixtures, mocks, and missing test surfaces. State explicitly when tests are absent. |
| `performance.md` | Examine build latency, caching, remote artifact use, generated config size, local feedback loops, concurrency, and known bottlenecks. |
| `code-quality.md` | Examine linting, formatting, naming, error handling, builder patterns, generated-file practices, docs conventions, and repo-specific style. Defer architecture shape and testing strategy to their dedicated specs. |
| `review-strategy.md` | Examine high-risk files, frequent-change surfaces, reviewer roles, CI gates, PR or change-review conventions, and evidence expectations for safe review. |

## Workflow

1. Check which target files already exist.
2. Ask before overwriting existing files unless the user already approved a
   refresh.
3. Resolve shared context for worker briefs: today's date, repository name,
   target file set, existing spec files, and any operator-provided emphasis.
4. Dispatch one Codex `staff-engineer` subagent per target file, in parallel
   where possible. Each worker owns exactly one output path,
   `docs/spec/<filename>`, and receives the matching exploration guidance above.
5. Do not fall back to direct parent-session authoring. If a worker fails or
   stalls, ask whether to respawn that file's worker, skip that file with a
   final-report gap, or abort.
6. Reconcile worker final reports, then verify each generated file exists,
   starts with YAML frontmatter, uses today's `last_updated`, includes
   `updated_by: "@staff-engineer"` and `owner: "@staff-engineer"`, and has a
   `## Gaps & Risks` section.
7. Keep each spec descriptive and evidence-based. Mark gaps plainly.
8. Cross-link dependencies in frontmatter where a spec depends on another.

## Worker Brief

Each worker brief must include:

- Verified goal and any operator emphasis.
- Target file and exact allowed write path.
- The target file's exploration guidance from the table above.
- Existing spec files to skim for overlap.
- Requirement to explore the codebase independently using the available file and
  command tools.
- Requirement to document only observed repository facts and state gaps plainly.
- Frontmatter requirements from the template below.
- Final report requirement: files written, evidence sources used, gaps, and
  verification performed.

## Frontmatter

```yaml
---
project: "<repo name>"
maturity: "draft"
last_updated: "YYYY-MM-DD"
updated_by: "@staff-engineer"
scope: "<one sentence>"
owner: "@staff-engineer"
dependencies: []
---
```

## Output

Report workers dispatched, files created or skipped, evidence sources used, and
any gaps that need follow-up.
