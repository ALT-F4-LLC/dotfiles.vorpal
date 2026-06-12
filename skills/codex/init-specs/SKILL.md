---
name: init-specs
description: >
  Bootstrap docs/spec/ with the standard project specification files. Use when
  asked to create, generate, or initialize project specs. Coordinates through the
  current Codex session and optional parent-led subagents; asks before
  overwriting existing specs.
---

# Init Specs

Create or refresh project specification files under `docs/spec/`. Do not commit
changes.

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

## Workflow

1. Check which target files already exist.
2. Ask before overwriting existing files unless the user already approved a
   refresh.
3. Read repository source, README, CI config, tests, docs, and deployment code.
4. For delegated workflows, the parent session may spawn parallel
   `staff-engineer` workers, one file each. Otherwise write the specs directly.
5. Keep each spec descriptive and evidence-based. Mark gaps plainly.
6. Cross-link dependencies in frontmatter where a spec depends on another.

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

Report files created or skipped, evidence sources used, and any gaps that need
follow-up.
