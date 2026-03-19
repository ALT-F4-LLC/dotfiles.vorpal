# UX Designer Evolution Log

## 2026-03-19 (second evolution)

### Summary
Fifth evolution cycle. Added privacy-by-design as a core principle and spec section, added AI/conversational interface design as a surface type, strengthened WCAG specificity, consolidated remaining i18n redundancy, improved design spec workflow with existing spec consistency checks, elevated design critique facilitation, and added operational signals anti-pattern.

### Changes
- Added core principle 8: "Privacy by default" -- at FAANG scale, every data collection decision is a trust decision; this was a significant gap for a Staff-level design role
- Added "Privacy & Data Minimization" as Section 9 in the design spec format (renumbered Measurement to 10, Handoff to 11) -- ensures designers explicitly inventory data handling for every surface
- Added "AI & Conversational Interfaces" surface type -- AI-assisted interfaces are the fastest-growing design surface; covers prompt design, confidence communication, guardrails UX, streaming responses, and feedback loops
- Strengthened WCAG reference from generic "WCAG compliance" to "WCAG 2.2 AA as the floor (not aspirational)" -- specificity matters for actionability
- Further consolidated i18n: removed remaining per-surface "see Section 8" lines (4 occurrences) and replaced with a single note at the top of Surface-Specific Expertise
- Added docs/ux/ consistency check to Design Spec Workflow step 1 -- designers must read existing specs for the same surface to avoid contradicting prior design decisions
- Elevated "Design Critique Culture" to "Design Critique Facilitation" -- staff designers don't just participate in critiques, they facilitate them; added facilitation framing
- Added "Don't ignore operational signals" anti-pattern -- support tickets, error logs, and on-call patterns are user research that already exists

### Dimensions Evaluated
- Role Realism: privacy-by-design and AI interface design are core Staff UX competencies at FAANG in 2026
- Actionability: WCAG 2.2 AA specificity, docs/ux/ consistency check in workflow
- Completeness: privacy principle, AI surface type, operational signals awareness
- Over-Engineering: further i18n consolidation (4 lines removed, 1 added)
- Career Growth: AI/conversational interface design as an emerging surface specialty
- Boundary Clarity: no changes needed (prior evolution covered this well)
- Spec Alignment: no spec updates needed (project is a Rust dotfiles manager, not a user-facing product)

### Rename
No rename -- "ux-designer" remains accurate and stable. "Product Designer" is more common at some FAANG companies but would be misleading here since this agent does not own product strategy.

## 2026-03-19

### Summary
Fourth evolution cycle. Added Design QA as a formal responsibility, consolidated redundant i18n guidance, added design system versioning governance, cross-agent conflict resolution, and structured evaluation output format.

### Changes
- Added Responsibility 7: Design QA — formal workflow and output format for verifying implementations match design intent, a core Staff UX responsibility at FAANG scale
- Consolidated per-surface i18n bullets into references to Section 8 of the design spec format, eliminating redundancy across 4 surface types
- Added Design System Versioning & Evolution section — breaking changes, deprecation, addition criteria, and audit cadence for design system governance
- Added Resolving Cross-Agent Conflicts section — explicit protocol for when TDD user-facing decisions conflict with UX specs
- Formalized shipped experience evaluation output with structured markdown template including principle scores, design debt inventory, and verdict
- Strengthened @staff-engineer boundary in "What You Are NOT" — clarified experience-owns-UX, staff-engineer-owns-architecture division with conflict escalation path

### Dimensions Evaluated
Role Realism (Design QA is standard at FAANG), Over-Engineering (i18n consolidation), Completeness (versioning, conflict resolution), Actionability (structured outputs), Boundary Clarity (@staff-engineer boundary)

### Rename
No rename — current name accurately reflects the role.
