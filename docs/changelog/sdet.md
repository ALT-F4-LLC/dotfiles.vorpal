# Changelog: SDET Agent

## 2026-03-19 — Coherence Fix: ADR References

### Changes
- Added `docs/tdd/adr/` reference to spec check instructions so Architecture Decision Records inform test strategy

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Evolution 2: Planning, Test Intelligence, Cross-Team Coordination

**Reviewed by:** @staff-engineer

### Changes Made

**New Responsibility: Test Planning & Estimation (Responsibility 8)**
- Added a complete new section covering test effort estimation, test debt management, and
  incident-driven test gap analysis.
- Test effort estimation: assess testability early, estimate by risk tier, surface hidden test
  infrastructure costs, negotiate test scope explicitly when timelines are tight.
- Test debt management: identify actively, quantify in business terms, propose incremental paydown.
- Incident-driven test gap analysis: determine if the defect class was testable, specify what
  test would have caught it, drive regression tests to completion, identify systemic gaps.
- **Why:** At FAANG scale, test planning is a first-class activity alongside feature planning.
  SDETs participate in sprint planning, estimate test effort, negotiate scope, and manage test
  debt as a portfolio. The agent had strong execution guidance but no planning/estimation
  responsibility — a gap that leads to testing being treated as an afterthought.

**New Section: Test Intelligence & Selection (under Automation Strategy)**
- Added guidance on change-based test selection, risk-based ordering, and historical failure
  correlation.
- **Why:** Running the full test suite on every change is prohibitively expensive at scale. Test
  selection (running only tests affected by a change) is standard practice at Google, Meta, and
  other large engineering organizations. This is a key technical capability for an SDET that was
  absent.

**New Section: Cross-Team Quality Coordination (under Mentorship)**
- Added guidance on shared test infrastructure ownership, test pattern standardization across
  teams, and quality office hours.
- **Why:** At 100+ developers, quality patterns fragment across teams if not actively coordinated.
  An SDET at this level is responsible for cross-team consistency in testing practices — not just
  their own team's quality.

**Resolved Boundary Contradiction: Test Code Review**
- Changed "You are NOT an architect or code reviewer" to "You are NOT an architect or production
  code reviewer" in the "What You Are NOT" section.
- Added explicit clarification that the SDET reviews test code written by @senior-engineer for
  quality, pattern adherence, and risk coverage — distinguishing this from formal production
  code review owned by @staff-engineer.
- **Why:** The original "What You Are NOT" section said the SDET does not perform code reviews,
  but the "Reviewing Test Code" subsection described the SDET reviewing tests. This contradiction
  could confuse the agent. The fix makes the boundary precise: production code review belongs to
  @staff-engineer; test code quality assurance belongs to @sdet.

**Removed Duplicate: Test Infrastructure Philosophy**
- Removed the "Test Infrastructure Philosophy" subsection from "Testing Philosophy" section.
- **Why:** Its four bullet points (make right thing easy, clear error messages, backward
  compatibility, performance) were substantively identical to the "Infrastructure Quality
  Standards" subsection under Responsibility 2. The duplication added no value and consumed
  context window budget. The content remains in Responsibility 2 where it is more naturally
  situated.

**Updated YAML Description**
- Added "test planning and estimation" and "incident-driven test gap analysis" to the frontmatter
  description. Clarified "does not perform code reviews of production changes" (was "does not
  perform code reviews").

**Updated Responsibility Count**
- Changed from seven to eight core responsibilities in the introduction paragraph.

### What Was NOT Changed

- Core testing philosophy principles: all six retained.
- Decision-making framework: hierarchy and block/accept criteria retained.
- Communication style: retained in full.
- Bug reporting format and severity classification: retained.
- Docket integration: workflow, rules, and session initialization unchanged.
- Test pyramid decisions, risk-based prioritization, greenfield strategy: all retained from
  Evolution 1.
- Cross-cutting quality concerns (security, performance, contract, accessibility, observability,
  resilience): all retained.
- Anti-patterns list: all 11 anti-patterns retained.

### Cross-Agent Coherence Notes

- The clarified test code review boundary now aligns cleanly: @staff-engineer owns formal code
  review of production changes; @sdet owns test code quality assurance. No overlap.
- The new test planning responsibility does not conflict with @project-manager's planning role:
  @project-manager decomposes work into issues; @sdet estimates and negotiates the test effort
  within those issues. The distinction is scope planning vs. effort estimation.
- The incident-driven test gap analysis complements @staff-engineer's postmortem facilitation
  responsibility — @staff-engineer drives the systemic analysis; @sdet drives the specific
  test gap remediation.
- No rename recommended. "SDET" remains standard at Google, Microsoft, Amazon, and Meta.

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
