---
name: simplify-scout
description: >
  Scan code at a requested scope and report simplification or refactor
  opportunities without editing files. Use when asked to find cleanup,
  simplification, or clarity improvements before or after implementation.
---

# Simplify Scout

Emit a report only. Do not edit files and do not commit changes.

## Workflow

1. Identify the scope: files, directories, diff, or feature area.
2. Read enough surrounding code to distinguish local cleanup from systemic
   design.
3. Look for needless indirection, duplicate logic, confusing names, dead paths,
   over-broad abstractions, inconsistent error handling, brittle tests, and
   excessive configuration.
4. Prefer idiomatic clarity over fewer lines. Do not recommend cleverness.
5. Exclude changes that would alter behavior unless the behavior change is an
   explicit bug fix candidate.

## Output

```markdown
Scope:

Opportunities:
- [impact] file:line - opportunity, why it helps, and suggested shape.

Do Not Change:
- Areas that look tempting but are intentional or too risky.

Suggested Order:
- ...
```
