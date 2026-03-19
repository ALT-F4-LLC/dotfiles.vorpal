# Changelog: project-manager

## 2026-03-19 — Evolution 3: Operational Maturity, Complexity Tiering, Plan Lifecycle

### Summary
Third evolution focused on operational maturity — calibrating planning rigor to work complexity,
standardizing issue description format, handling plan cancellation cleanly, adding a stakeholder
alignment gate for complex work, and strengthening scope negotiation and staleness management.

### Changes
- Added plan complexity tiering (trivial/standard/complex) to prevent over-engineering simple
  requests while ensuring complex work gets full rigor
- Added concrete issue description template for consistent, scannable output across sessions
- Added plan cancellation and partial completion handling — clean shutdown of abandoned work
  to prevent zombie issues
- Added stakeholder alignment checkpoint for complex-tier work before investing in full issue
  creation
- Added issue grooming and staleness management guidance to the re-engagement process
- Strengthened the "understand the problem" step with proactive scope negotiation before
  decomposition

### Dimensions Evaluated
Role Realism (scope negotiation, plan cancellation, stakeholder alignment, staleness management),
Actionability (complexity tiering, issue template), Completeness (plan cancellation, staleness),
Over-Engineering (complexity tiering reduces over-engineering), Career Growth (scope negotiation,
stakeholder alignment)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Coherence Fix: ADRs and Cross-Team Negotiation Routing

### Changes
- Added `docs/tdd/adr/` reference to existing spec checks so ADRs inform planning
- Added cross-team technical negotiation routing to @staff-engineer for technical conflicts discovered during planning

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Second Evolution

### Summary

Built on the strong foundation from the first evolution. The first pass elevated the role framing,
added estimation, cross-workstream coordination, decision framework, retrospective awareness, and
communication style. This second pass addresses gaps in actionability (exploration guidance),
program-level thinking (portfolio rollup), risk completeness (integration risks), proactive
communication, and planning discipline (anti-patterns).

### Changes Made

**1. Added Dual-Altitude Framing (Role Realism)**
- New paragraph in the intro establishing that a Staff TPM operates at both feature-level
  (decomposing individual work) and program-level (managing portfolio health across concurrent
  workstreams). At 100+ developer organizations, TPMs are expected to provide portfolio-level
  visibility, not just per-feature plans.

**2. Added Codebase Exploration Patterns (Actionability)**
- New "What to look for during exploration" subsection under "Performing Your Own Exploration"
  with five concrete patterns: module boundaries, dependency fan-out, test adjacency,
  configuration surface, and recent change velocity. Previously the guidance was generic
  ("use Read, Grep, Glob"); now it tells the agent *what signals to look for* and *why each
  signal matters for planning*.

**3. Added Integration Risks to Risk Assessment (Completeness)**
- Added "Integration risks" as a fourth risk category in Section 2 (Assess Risks): will this
  work conflict with other active workstreams? Instructs the agent to check `docket board --json`
  for in-progress work touching overlapping files. The first evolution added cross-workstream
  coordination as a section, but the risk assessment step did not explicitly check for integration
  conflicts during the pre-planning phase.

**4. Added Program-Level Rollup Template (Role Realism, Career Growth)**
- New "Program-Level Rollup" subsection under Plan Monitoring with a structured template for
  portfolio-level status reporting across multiple active epics. Includes workstream progress
  table, cross-workstream risks, resource contention, and recommendations. Produced on-demand,
  not automatically. This is a key Staff TPM responsibility that was missing — the ability to
  give leadership a single view across all active work.

**5. Added Planning Anti-Patterns Section (Career Growth, Completeness)**
- New top-level section with seven anti-patterns: waterfall disguised as agile, phantom precision,
  scope laundering, dependency theater, single-threaded planning, missing the forest, and
  gold-plated plans. Other agent definitions (staff-engineer, senior-engineer) have anti-pattern
  sections. This fills the gap for the PM role and codifies the judgment that distinguishes
  senior TPMs from junior ones.

**6. Added Proactive Communication Guidance (Role Realism)**
- New bullet in Communication Style: "Manage up proactively." Staff TPMs do not wait for status
  requests — they surface at-risk plans immediately with impact and recommendations. This is
  a distinguishing behavior at the Staff level.

**7. Updated Workflow Summary Diagram (Consistency)**
- Updated risk assessment step to include "integration risks" alongside technical, dependency,
  and scope risks, matching the expanded Section 2.

### What Was Preserved

- All first-evolution additions: estimation, cross-workstream coordination, decision framework,
  retrospective awareness, communication style, status update template.
- All original content: Docket CLI workflows, decomposition principles, risk framework, scope
  management, technical investigation needs, UX/TDD design requests, DoR checklist, plan
  monitoring triggers, issue description guidance, file attachment workflow, rules.
- YAML frontmatter unchanged.

### Dimensions Evaluated

| Dimension | Assessment |
|---|---|
| Role Realism | Improved — dual-altitude framing, program rollup, proactive communication |
| Actionability | Improved — concrete exploration patterns with specific signals to look for |
| Boundary Clarity | Maintained — no changes needed, boundaries remain clear |
| Completeness | Improved — integration risks, anti-patterns, program rollup |
| Over-Engineering | Monitored — additions are targeted, no redundancy introduced |
| Career Growth | Improved — anti-patterns section codifies senior judgment; program rollup adds new capability |
| Spec Alignment | Maintained — already well-aligned |
| Rename | Not recommended — same reasoning as first evolution applies |

### Rename Recommendation

**No rename recommended.** The reasoning from the first evolution remains valid: "project-manager"
is deeply wired into all agent definitions, skills, and orchestration. The agent's intro and
framing already establish the Staff TPM mental model without requiring a file rename.

### Cross-Agent Coherence Issues Noticed

- The boundary between @project-manager and @staff-engineer remains clean and consistent across
  both definitions.
- Minor observation: @sdet's "What You Are NOT" section says it "does not create Docket issues"
  and "reports bugs and quality findings as comments on existing issues." This is consistent with
  @project-manager being the primary issue creator. No action needed.
- The @senior-engineer definition correctly states it "may create single ad-hoc tracking issues
  for unplanned work" — this exception is well-scoped and does not conflict with @project-manager
  owning the planning function.

---

## 2026-03-19 — First Evolution

### Summary

Elevated the project-manager agent from a task decomposition tool to a Staff TPM (Technical
Program Manager) operating at FAANG scale. The existing foundation was strong — the core
decomposition workflow, Docket CLI integration, cross-cutting concerns checklist, and Definition
of Ready were all solid. This evolution added the responsibilities and patterns that distinguish
a senior IC PM from a junior one at a 100+ developer organization.

### Changes Made

**1. Elevated Role Framing (Role Realism)**
- Repositioned intro from "your sole job is to decompose" to a Staff TPM framing with five
  core responsibilities: problem decomposition, risk/scope management, plan communication,
  plan health monitoring, and cross-workstream coordination.
- Added impact measurement language: "measured not by the number of issues you create, but by
  how smoothly teams execute against your plans."

**2. Added Estimation & Capacity Section (Completeness)**
- New Section 4: "Estimate Effort" — requires relative sizing (small/medium/large) on every
  issue and a total plan estimate with parallelism assumptions.
- Requires estimation uncertainty to be flagged explicitly rather than hidden.
- Includes capacity-aware planning: shaping plans to fit available resources and offering
  scope alternatives when work exceeds capacity.

**3. Added Cross-Workstream Coordination Section (Role Realism, Completeness)**
- New top-level section for managing conflicts between simultaneous workstreams.
- Covers file collision detection, cross-workstream dependency management, priority arbitration,
  and shared contract identification.
- This is a critical gap at scale — without it, two parallel workstreams can silently conflict.

**4. Added Decision-Making Framework (Completeness)**
- Six-level hierarchy: Feasibility, Risk, Dependencies, Value, Effort, Reversibility.
- Clear escalation guidance: what to resolve yourself, what to defer to @staff-engineer or
  @ux-designer, what to escalate to the orchestrator.
- Consistent with the decision frameworks in other agent definitions.

**5. Added Retrospective Awareness Section (Career Growth)**
- Brief post-completion comment on parent issues capturing estimation accuracy, dependency
  accuracy, scope stability, and parallelism achieved.
- Lightweight by design — 5-10 lines, skip for trivial plans.
- Creates institutional learning loop for improving future plans.

**6. Added Communication Style Section (Completeness)**
- Explicit guidance on leading with the plan, quantifying everything, naming uncertainty,
  framing scope decisions as tradeoffs, and tailoring detail to audience.
- Fills a gap: every other agent had a Communication Style section except the PM.

**7. Added Status Update Format for Re-Engagement (Actionability)**
- Structured template for plan status reports during re-engagement: progress, plan changes,
  updated critical path, risks, decisions needed.
- Makes re-engagement output consistent and actionable.

**8. Structural Improvements**
- Moved "What You Are NOT" section to the top, consistent with staff-engineer, senior-engineer,
  sdet, and ux-designer agents.
- Added "Estimated size" to the DoR checklist.
- Added "Effort estimate" to the plan summary output.
- Added "backward compatibility" to cross-cutting concerns checklist.
- Updated workflow summary diagram to include estimation step and backward compatibility.
- Renumbered core responsibility sections to accommodate new Estimation section (old 4-12
  became 5-13).
- Updated Rules section to reference "Sections 2-6" (was 2-5) and added rule about including
  estimated size in every issue description.

### What Was Preserved

- All existing Docket CLI workflows and command references — untouched.
- Core decomposition principles (independently executable, reasonable unit, parallel by default).
- Risk assessment framework (technical, dependency, scope risks).
- Scope management with MoSCoW labels.
- Technical investigation needs section and escalation patterns.
- UX/TDD design request workflows.
- Definition of Ready checklist (extended, not replaced).
- Plan monitoring and re-engagement triggers.
- Issue description quality guidance.
- File attachment workflow.
- All "What You Are NOT" entries.

### Dimensions Evaluated

| Dimension | Assessment |
|---|---|
| Role Realism | Improved — elevated to Staff TPM, added cross-workstream coordination |
| Actionability | Improved — added estimation, status update template, decision framework |
| Boundary Clarity | Maintained — already strong, no changes needed |
| Completeness | Improved — added estimation, communication style, retrospective, coordination |
| Over-Engineering | Monitored — additions are proportional, no bloat |
| Career Growth | Improved — retrospective awareness creates learning loop |
| Spec Alignment | Maintained — already well-aligned with docs/spec/ patterns |
| Rename | Not recommended — see reasoning below |

### Rename Recommendation

**No rename recommended.** "Technical Program Manager" (TPM) is the more precise FAANG title
for this role's responsibilities (cross-workstream coordination, stakeholder communication,
capacity planning). However, "project-manager" is deeply wired into all four other agent
definitions, the dev-team skill, and the evolve-agents skill. The stability cost of renaming
outweighs the terminological precision. The agent description and intro framing now reference
"Staff TPM" to establish the right mental model without requiring a file rename.

### Cross-Agent Coherence Issues Noticed

- None significant. The boundary between @project-manager (delivery strategy, what to deliver
  when) and @staff-engineer (architecture, how to build it) is well-articulated in both agents
  and consistent.
- The @senior-engineer agent correctly defers complex planning to @project-manager and creates
  only single ad-hoc tracking issues.
- The @sdet agent correctly avoids creating issues and reports findings as comments.
