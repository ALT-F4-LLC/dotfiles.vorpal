# Changelog: brief

## 2026-06-09

### Summary
Live-test defect fix: brief recommended a taxonomy-violating route with "(Recommended)" confidence (standalone creation of docs/spec/security.md, a reserved init-specs-owned name). Added a docs-path ownership check to the question-construction guidance.

### Changes
- Resolving underdetermined fields: options creating/routing writes to docs/ paths must check the owning writer (team-lead.md §Docs-Path Taxonomy) before being marked Recommended — brief writes no files, but its routing recommendations steer who writes where.

### Dimensions Evaluated
Coherence (docs-path taxonomy), Actionability (recommendation quality). Found via first live invocation, 2026-06-09.

### Rename
No rename.

## 2026-06-09

### Summary
New leaf skill: operator-intake aid that converts a freeform `$ARGUMENTS` request into the standardized brief block team-lead's Pre-flight HARD GATE (step 1) consumes, collapsing goal verification to one confirm. Outcome-oriented body; emits the block and stops, no file writes, no spawns.

### Changes
- Created skills/brief/SKILL.md. Frontmatter: name/description (trigger keywords first) + argument-hint, no effort key (inherits caller), no tool restriction. Body: derive fields from the request, ONE batched AskUserQuestion round for underdetermined routing-relevant fields (Size hint + Security-sensitive prioritized), emit block verbatim. Field semantics mirror team-lead Pre-flight + Pattern Decision Tree.

### Dimensions Evaluated
Coherence (block schema + field semantics aligned to agents/team-lead.md Pre-flight/Decision Tree), Over-Engineering (single round cap, ≤120 lines, no step enumeration). Spec Alignment (docs/spec/ — N/A).

### Rename
No rename (net-new skill).
