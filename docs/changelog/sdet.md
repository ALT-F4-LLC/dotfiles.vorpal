# Changelog: SDET Agent

## 2026-03-19 — Evolution 1: Scale Realism, Greenfield Strategy, Environment Ownership

**Reviewed by:** @staff-engineer

### Changes Made

**New Responsibility: Test Environment & Data Management (Responsibility 7)**
- Added a complete new section covering test environment ownership, configuration parity,
  isolation for parallel execution, reproducibility, and ephemeral-over-persistent environments.
- Added test data strategy: deterministic generation over production snapshots, minimal and
  targeted data, cleanup-by-default, and sensitive data handling.
- **Why:** At FAANG scale (100+ developers), test environment reliability is a first-class
  engineering concern. Flaky environments are the leading cause of flaky tests, and test data
  management (especially PII handling and isolation) is a compliance and reliability requirement.
  The original agent had no guidance on this critical SDET responsibility.

**New Section: Greenfield Test Strategy**
- Added a prioritized 6-step workflow for establishing test infrastructure in codebases with
  no existing tests.
- **Why:** The project's `docs/spec/testing.md` documents zero tests in the codebase. The
  original agent had extensive guidance for mature test suites but no actionable workflow for
  bootstrapping from nothing — a common real-world scenario.

**New Section: Resilience Testing (under Cross-Cutting Concerns)**
- Added guidance on testing graceful degradation: dependency unavailability, resource exhaustion,
  network partitions, and configuration errors.
- **Why:** At scale, availability-impacting bugs are the most costly class of defect. Resilience
  testing (chaos engineering lite) is standard practice at FAANG companies but was absent from
  the agent definition.

**Enhanced Boundary Clarity: SRE/Infrastructure Boundary**
- Added a fifth "What You Are NOT" entry clarifying the boundary between SDET and SRE/infrastructure
  roles: production environments belong to operations, test environments belong to the SDET.
- **Why:** At large organizations, the overlap between "test infrastructure" and "infrastructure"
  is a common source of ownership confusion. Making this explicit prevents gaps.

**Consolidated Test Philosophy Sections**
- Merged the separate "Integration Test Philosophy" and "Unit Test Philosophy" subsections into
  a single "Lean Test Design" section that covers all pyramid levels including snapshot tests.
- Added snapshot/golden-file test guidance as a first-class testing pattern.
- **Why:** The original had two nearly identical subsections both saying "lean and high-value"
  with the same framing. Consolidation reduces redundancy and adds room for the snapshot test
  pattern, which is particularly relevant to this project (configuration generators).

**Enhanced CI/CD Quality Gates**
- Added "Lint and format" as a blocking gate in the CI/CD quality gates table.
- **Why:** The project's `docs/spec/code-quality.md` documents that no lint or format enforcement
  exists in CI. Making this an explicit gate in the SDET's mental model ensures it gets
  prioritized during test infrastructure setup.

**Enhanced Test Pyramid Table**
- Added "Configuration generators" row to the test pyramid decisions table.
- **Why:** This project is a configuration generator. Having a pyramid shape specifically for
  this system type makes the guidance immediately actionable.

**Smaller Improvements**
- Added "Examine the implementation" step to Verification Workflow (step 5) — reading the code
  before testing it catches architectural issues that black-box testing misses.
- Added "Coverage delta" to Verification Output template — trend data is more useful than absolute
  numbers.
- Added "Test-to-code ratio" metric to Test Suite Health Metrics table.
- Added "Proportional to risk?" question to Reviewing Test Code section.
- Added "Participate in production readiness discussions" to Quality Advocacy section.
- Replaced "Snapshot test abuse" anti-pattern with "Snapshot test rubber-stamping" — the original
  discouraged snapshot tests too broadly; the real anti-pattern is updating without reviewing.
- Added "Test data coupling" anti-pattern.
- Added "Snapshot/golden-file test" entry to Test Pyramid Placement decision tree.
- Added "Fixture and seed data management" to What You Build list.
- Updated core responsibilities count from six to seven in the introduction.

### What Was NOT Changed

- YAML frontmatter: left unchanged (no frontmatter fields in this agent format).
- Docket integration: workflow, rules, and session initialization are well-designed and unchanged.
- Core testing philosophy principles: all six principles retained as-is.
- Decision-making framework: hierarchy and block/accept criteria retained.
- Communication style: retained in full — precise, quantified, audience-calibrated.
- Bug reporting format and severity classification: retained as-is.
- Mentorship section structure: retained, only minor additions.

### Cross-Agent Coherence Notes

- The boundary between @sdet and @senior-engineer on unit test ownership is well-stated in both
  agents. No conflicts found.
- The boundary between @sdet and @staff-engineer on test strategy (TDD Testing Strategy section
  as input, @sdet as executor) is clear and consistent.
- The @project-manager agent correctly references @sdet for testing issue creation.
- No rename recommended: "SDET" is standard terminology at Google, Microsoft, Amazon, and Meta.
