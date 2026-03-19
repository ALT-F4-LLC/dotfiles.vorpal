# Changelog: project-manager

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
