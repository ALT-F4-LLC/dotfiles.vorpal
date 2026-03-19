# Changelog: senior-engineer

## 2026-03-19

### Summary
Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage inter-agent communication guidance.

### Changes
- Merged "Verify after deployment" (step 7) into self-review checklist (step 5) to eliminate redundant build-run instructions
- Compressed Dependency & API Surface Evaluation from 3 bullets to 1 focused bullet
- Shortened SDET boundary bullet from 6 lines to 3 without losing key information
- Added Inter-Agent Communication subsection with SendMessage guidance for real-time teammate coordination
- Fixed double blank line formatting inconsistency
- [Coherence] Replaced "orchestrator" with "user or team lead" (3 occurrences)
- [Coherence] Added SendMessage to tools frontmatter
- [Coherence] Streamlined session initialization to context-dependent commands

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth, Role Realism, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting Concerns checklist.

### Changes
- Expanded self-review serialization bullet into a concrete before/after diff step aligned with project's config-generator nature
- Removed Incident Response & Debugging subsection — stateless agent cannot perform ongoing incident management; useful debugging guidance already covered by existing principles
- Compressed Cross-Cutting Concerns from verbose parenthetical definitions to terse checklist

### Dimensions Evaluated
Role Realism, Consolidation & Trimming, Spec Alignment

### Rename
No rename.

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
