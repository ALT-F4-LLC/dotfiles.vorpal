# Changelog: brief

## 2026-06-10

### Summary
No changes. Zero correction signals across 17 operator invocations (heaviest-used skill this window). Both Phase 0 signals rejected on ground truth.

### Changes
- None (NO-OP verdict). Output-channel SendMessage instruction is a false positive (CANONICAL:BANNER delegates relay to the calling agent; adding it would contradict the banner). Backtick git-status injection rejected as over-engineering (sandbox caveat; prior cycle rejected similar).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, all load-bearing); Coherence (banner tail byte-parity with leaf family confirmed); evolve-coherence leaf-family enumeration lag flagged to Phase 2.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes. Zero correction signals in 15-18 operator invocations; all 8 dimensions pass. Innovation suggestion (machine-parseable trailer) rejected as over-engineering — the existing `Field: value` block is already machine-parseable; a redundant fenced trailer adds 7-10 lines for no functional gain.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, lean — field-semantics prose load-bearing); Coherence (team-lead Pre-flight HARD GATE and docs-path taxonomy checks confirmed current); Actionability (question-batching rule and field semantics remain precise).

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Banner-tail divergence signal verified already-fixed (L14 carries the correct leaf tail for brief's skill type); `\$ARGUMENTS` correctly escaped at L19; no-spawn consistency confirmed across frontmatter, banner, and body.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, lean — field-semantics prose load-bearing); Coherence (team-lead Pre-flight HARD GATE handoff terminology matches agents/team-lead.md).

### Rename
No rename.

## 2026-06-09

### Summary
Normalized the CANONICAL:BANNER trailing clause to the leaf-family standard, restoring byte-parity under the canonical strip (evolve-coherence 2026-06-09 audit, FINDING 1, operator decision: NORMALIZE).

### Changes
- BANNER tail "The calling agent handles any follow-up after this skill returns." → "The calling agent handles peer messaging after this skill returns." — the canonical strip `sed 's/ The calling agent handles peer messaging.*$//'` anchored on "peer messaging" did not match brief's variant tail, so coherence audits flagged brief as divergent; post-edit all 10 leaf banners strip-normalize to one hash (8cffe6b8). Net lines: 0.

### Dimensions Evaluated
Coherence (manifest-scoped remediation cycle — other dimensions out of scope per operator-approved slice).

### Rename
No rename.

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
