# Changelog: sdet

## 2026-03-19

### Summary
Major consolidation from 867 to 308 lines. Merged eight verbose responsibility sections into focused operational sections, eliminated redundant and generic content, compressed all templates and prose.

### Changes
- Merged Responsibilities 1-3 (Architecture, Infrastructure, Automation) into single "Test Architecture & Infrastructure" section
- Removed Responsibility 7 (Test Environment & Data Management) — generic advice already implied by determinism/isolation principles
- Removed Cross-Cutting Quality Concerns section — generic SDET knowledge not applicable to config-generator project
- Removed Anti-Patterns section — restated positive instructions without unique value
- Compressed Mentorship to focused test code review guidance
- Compressed Docket workflow, verification template, decision framework, communication style, and all prose

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Boundary Clarity, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fix: added staff-engineer review and escalation bidirectionality.

### Changes
- Added acknowledgment that @staff-engineer reviews test architecture decisions for risk alignment
- Updated bridging note to reflect @senior-engineer test coverage escalation protocol

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Grounded agent in operational reality with Rust-specific commands, failure diagnosis, ad-hoc verification, and snapshot review protocol.

### Changes
- Added Rust-specific test execution commands aligned with docs/spec/testing.md
- Added ad-hoc verification workflow and test failure diagnosis protocol
- Split metrics into per-session vs. trend categories
- Added test coverage escalation protocol and snapshot review protocol

### Dimensions Evaluated
Actionability, Completeness, Spec Alignment, Role Realism, Boundary Clarity

### Rename
No rename.

## 2026-03-19

### Summary
Added test planning, test intelligence, cross-team coordination, and clarified test code review boundary.

### Changes
- Added Responsibility 8: Test Planning & Estimation (effort estimation, test debt, incident gap analysis)
- Added Test Intelligence & Selection and Cross-Team Quality Coordination sections
- Clarified test code review boundary (production review = @staff-engineer, test QA = @sdet)
- Removed duplicate Test Infrastructure Philosophy subsection

### Dimensions Evaluated
Role Realism, Completeness, Boundary Clarity, Career Growth

### Rename
No rename.

## 2026-03-19

### Summary
First evolution adding FAANG-scale responsibilities: environment ownership, greenfield strategy, resilience testing, and snapshot test patterns.

### Changes
- Added Responsibility 7: Test Environment & Data Management
- Added Greenfield Test Strategy, Resilience Testing, SRE boundary clarification
- Consolidated test philosophy, enhanced CI gates, added config-generator pyramid row
- Various verification workflow and metrics improvements

### Dimensions Evaluated
Role Realism, Completeness, Spec Alignment, Boundary Clarity

### Rename
No rename.
