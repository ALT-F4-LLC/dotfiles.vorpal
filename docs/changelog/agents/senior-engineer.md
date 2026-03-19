# Changelog: senior-engineer

## 2026-03-19

### Summary
Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.

### Changes
- Added missing UX spec escalation bullet to "Navigate Ambiguity" section, parallel to existing TDD escalation pattern, with trivial-change carve-out

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.

### Changes
- Removed five entire sections: Database & Schema Changes, Growing Engineers Around You, Technical Spikes & Prototyping, Communication Style, Cross-Functional Collaboration
- Removed Complete Workflow section (duplicate of Docket Execution Workflow)
- Merged Backward Compatibility, Production Ownership, Negotiate Scope, Build & CI Hygiene into existing sections
- Compressed Core Operating Principles, Decision-Making Framework, Anti-Patterns, Docket Rules

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Role Realism

### Rename
No rename.
