# Changelog: staff-engineer

## 2026-03-19 — Coherence Fix: TDD Feedback Loop

### Changes Made
- Added acknowledgment in "What You Are NOT" that @senior-engineer provides implementation-level feedback on TDDs, making the feedback loop bidirectional (senior-engineer already documented sending this feedback)

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Evolution 1: Actionability, Boundary Clarity, and Response Spectrum

### Changes Made

**1. Added Lightweight Architectural Advisory (Responsibility 3)**

Merged the former "Design Review" (old Responsibility 3) and the thin "Technical Planning & RFCs"
section into a new combined "Architectural Guidance & Design Review" responsibility. Added a
concrete "Lightweight Architectural Advisory" workflow with a defined format for when a question
needs more than a review comment but less than a full TDD.

**Why:** The original agent had a binary choice: produce a full TDD or say nothing. Real staff
engineers at FAANG-scale companies spend most of their time giving quick architectural guidance --
"use approach A because X" -- not writing 10-section design documents. The gap between "skip for
small tasks" and "produce a TDD" was the most common operating mode with no guidance. The former
"Technical Planning & RFCs" section (5 bullet points) was redundant with the TDD format and added
no actionable behavior.

**2. Clarified @sdet boundary in "What You Are NOT" section**

Expanded the SDET boundary from a single sentence to explicitly delineate: staff-engineer evaluates
test strategy and coverage during code review, but does not own test architecture, test
infrastructure, or test automation.

**Why:** The original boundary was "You are NOT a SDET. You do not write or run tests." But the
Code Review section contained extensive testing evaluation guidance (testing pyramid, mocking
strategy, coverage analysis). This created ambiguity about who owns testing decisions. The
clarification makes explicit what was implicit: staff-engineer reviews test quality; @sdet owns
test systems.

**3. Added @ux-designer interaction pattern in Design Review triggers**

Added explicit trigger: "When @ux-designer produces a design spec with technical implications --
review the technical feasibility and system integration aspects (not the UX decisions, which are
@ux-designer's domain)."

**Why:** The original had no explicit interaction pattern with @ux-designer beyond "consume their
specs from docs/ux/". The dev-team skill orchestrates UX-heavy tasks where @staff-engineer follows
@ux-designer, but the agent definition gave no guidance on what to evaluate in a UX spec. Now it is
clear: review technical feasibility, not design aesthetics.

**4. Replaced Incident Leadership with actionable Failure Analysis section**

Replaced the "Incident Leadership" section (which described human organizational behaviors like
"shield engineers from pressure" and "coordinate investigation") with "Incident and Failure
Analysis" that describes concrete actions an AI agent can take: diagnose root causes, assess blast
radius, recommend fix categories, update specs, and facilitate postmortems.

**Why:** The original section was well-written for a human staff engineer job description but not
actionable for an AI agent. "Protect the team" and "communicate status clearly to stakeholders" are
not behaviors Claude can execute. The replacement retains the same intellectual rigor (systemic
thinking, root cause analysis, blameless postmortems) but frames it as work the agent actually does:
reading logs, analyzing diffs, updating documentation, and recommending fixes.

**5. Added Proactive System Health Assessment subsection**

Added concrete triggers for when to surface systemic issues: architectural drift, dependency health,
build/CI health, and configuration sprawl. Includes guidance on where to surface findings (review,
TDD, spec update, or direct recommendation).

**Why:** The original "System-Level Thinking" section was aspirational ("maintain a forward-looking
view of the technical platform") but lacked triggers for when the agent should proactively raise
concerns. A real staff engineer at scale notices these issues during routine work and raises them
without being asked. The new subsection gives the agent specific patterns to watch for and specific
actions to take.

**6. Added "Over-formalizing everything" anti-pattern**

Added anti-pattern: "Not every question needs a TDD. Not every concern needs a spec update. Match
the formality of your response to the weight of the decision."

**Why:** Complements the new Architectural Advisory capability. Without this anti-pattern, the
agent's default behavior leans toward producing formal documents for every request, which is the
opposite of how effective staff engineers operate. They match formality to stakes.

**7. Updated core responsibility count from five to six**

Updated the opening paragraph to reflect six responsibilities (adding architectural guidance as
distinct from TDD creation).

### What Was Preserved

- Full TDD format and workflow (unchanged)
- Complete code review section with all six dimensions, severity levels, and output formats
- Project specifications ownership (seven spec files)
- Mentorship and technical growth section
- Influence and alignment section with disagreement resolution
- Decision-making framework with hierarchy and ambiguity management
- All existing anti-patterns
- YAML frontmatter format for all document types

### What Was Removed

- "Technical Planning & RFCs" section (5 bullet points, lines 870-878) — redundant with TDD
  format and now subsumed by the Architectural Advisory capability
- Human-specific incident leadership behaviors ("shield engineers from pressure", "communicate
  status to stakeholders") — replaced with agent-actionable failure analysis

### What Was NOT Changed (Considered but Rejected)

- **Rename**: Considered "principal-engineer" or "tech-lead" but rejected. "Staff engineer" is
  the most widely recognized title for this role at FAANG companies (Google, Meta, Stripe all
  use it). The Will Larson archetype reference in the opening paragraph already establishes the
  scope. Stability of the name across the agent ecosystem outweighs any marginal clarity gain.
- **Adding technical debt roadmapping as a formal responsibility**: Considered but rejected.
  The existing Strategic Technical Direction subsection already covers this ("Prioritize technical
  debt at the org level"). Adding a separate responsibility would over-formalize what is already
  addressed.
- **Adding CI/build pipeline ownership**: Considered but rejected. This is covered by the new
  Proactive System Health Assessment (build/CI health trigger) and by the Operations dimension
  in code review. Making it a standalone responsibility would blur the boundary with
  @senior-engineer, who actually modifies CI configuration.
