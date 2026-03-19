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
- Removed five entire sections: Database & Schema Changes (irrelevant to zero-DB project), Growing Engineers Around You (non-actionable for stateless AI agent), Technical Spikes & Prototyping (non-actionable for stateless agent), Communication Style (duplicated other sections), Cross-Functional Collaboration (duplicated other sections)
- Removed Complete Workflow section (duplicate of Docket Execution Workflow)
- Merged Backward Compatibility into System-Level Awareness, Production Ownership into Code Quality, Negotiate Scope into Navigate Ambiguity, Build & CI Hygiene with Commit Hygiene
- Compressed Core Operating Principles from 6 to 4, Decision-Making Framework, Anti-Patterns from 9 to 4, Docket Rules, Config-as-Code Safety, Cross-Cutting Concerns, Incident Response, Dependency & API Surface
- Tightened introduction and self-review step

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Role Realism

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fix: made @staff-engineer review handoff explicit and added SDET escalation acknowledgment.

### Changes
- Made @staff-engineer review handoff explicit in Execution Workflow step 5
- Added reciprocal acknowledgment in "What You Are NOT" SDET boundary for test coverage escalation

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Grounded the agent in its AI-agent operating model, strengthened self-review with project-specific verification steps, added error context and dependency conflict guidance.

### Changes
- Added AI-agent operational context paragraph to introduction
- Strengthened self-review with cargo check/clippy and serialization output inspection
- Added error context quality guidance (.context() vs bare ?)
- Added trivial-change exception to ad-hoc issue creation
- Added dependency conflict resolution guidance

### Dimensions Evaluated
Role Realism, Actionability, Spec Alignment, Completeness

### Rename
No rename.

## 2026-03-19

### Summary
Added scope negotiation, commit discipline, config-as-code safety, and observability-first development guidance.

### Changes
- Added Negotiate Scope With Data as Core Operating Principle #4
- Added Configuration-as-Code Safety subsection aligned to project architecture
- Added Commit Hygiene & Version Control section
- Added "Instrument from the start" to Production Ownership
- Made test suite guidance conditional on test existence

### Dimensions Evaluated
Role Realism, Completeness, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
First evolution adding FAANG-scale responsibilities: backward compatibility, database safety, CI ownership, concurrency, technical spikes, and decision reversibility.

### Changes
- Added Backward Compatibility & Safe Changes, Database & Schema Changes, Build & CI Hygiene, Technical Spikes & Prototyping sections
- Added Concurrency lens to Cross-Cutting Concerns, Reversibility to Decision-Making Framework
- Enhanced architect boundary, Growing Engineers, Cross-Functional Collaboration, Incident Response, Dependency evaluation, Anti-Patterns

### Dimensions Evaluated
Role Realism, Completeness, Boundary Clarity

### Rename
No rename.
