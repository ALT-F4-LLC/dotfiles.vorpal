# Changelog: code-review

## 2026-05-09

### Summary
Initial creation. New leaf skill that lets `@staff-engineer` and `@security-engineer` produce role-correct code reviews via a single shared format authority. Removes per-agent format duplication: each agent's Responsibility 2 (Review) now points to `Skill(code-review, "<scope>")` instead of restating dimension lists, severity ladders, and output sections inline. Role detection branches the playbook (6 general dimensions for staff; 9 security dimensions for security) and the severity ladder (Blocker/Concern/Suggestion/Question/Praise vs. Critical/High/Medium/Low/Info) so cross-mixing is a validation defect.

### Changes
- Created `skills/code-review/SKILL.md` with: role detection (restricted to `@staff-engineer` / `@security-engineer`); positional `<scope>` argument resolving to PR number/URL, branch, `uncommitted`, `staged`, or file paths; staff-engineer playbook (6 dimensions, 5-tier severity, full output template); security-engineer playbook (9 dimensions, 5-tier severity, Threat Model + Required Mitigations sections); Validation Before Emit checks for role banner, section presence, severity-ladder discipline, explicit empty buckets, recommendation allow-list, and placeholder scan; Save & Return that emits to context (no file written) and explicitly defers peer SendMessage / vote escalation to the calling agent; Failure Modes covering empty diff, unresolvable scope, missing `gh`, and severity cross-mixing.
- Updated `agents/staff-engineer.md`: added `code-review` to `skills:` frontmatter; replaced the inline `### Review Output Format` block with a one-paragraph pointer to `Skill(code-review, "<scope>")` (mirrors how Responsibility 1 points to `Skill(tdd, "<topic>")`).
- Updated `agents/security-engineer.md`: added `code-review` to `skills:` frontmatter; same pointer replacement for the security review section.
- Updated `agents/team-lead.md` spawn templates for `@staff-engineer (Code Review)` and `@security-engineer (Security Review)`: requirement bullets now instruct the spawned reviewer to invoke `Skill(code-review, "uncommitted")` (or pass a different scope) rather than restating the severity ladder and dimension list inline.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Coherence (parity with sibling skills tdd/adr/prd/vote), Spec Alignment (`docs/spec/review-strategy.md` six-dimension model + agent specs' Responsibility 2), Over-Engineering (no file output — review is conversational; leaf skill — no Agent/SendMessage/Skill).

### Rename
No rename.
