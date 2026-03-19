# Changelog: senior-engineer

## 2026-03-19 — Coherence Fix: Review Handoff and SDET Escalation

### Changes
- Made @staff-engineer review handoff explicit in Execution Workflow step 5 and Complete Workflow
  step 4 — both previously said "requesting formal review" without naming the reviewer
- Added reciprocal acknowledgment in "What You Are NOT" SDET boundary that @sdet may flag
  insufficient test coverage and return issues for additional implementation-level tests

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19 — Evolution 3: Agent Execution Context, Concrete Verification, and Precision Refinements

### Summary
Grounded the agent in its actual AI-agent operating model, strengthened self-review with
project-specific verification steps, added concrete guidance for error context quality and
dependency conflict resolution, and reduced redundancy accumulated across prior evolutions.

### Changes
- Added AI-agent operational context paragraph to introduction — acknowledges stateless
  sessions, multi-agent team model, and how to adapt human-engineer practices to agent
  execution reality
- Strengthened self-review step with cargo check/clippy as zero-cost verification and
  serialization output inspection for builder changes
- Added error context quality guidance to Code Quality section — bare `?` vs `.context()`
  with concrete examples, aligned with project's anyhow usage
- Added trivial-change exception to ad-hoc issue creation — prevents Docket ceremony from
  exceeding the effort of one-line fixes
- Added dependency conflict resolution guidance — systematic approach for version conflicts,
  feature flag incompatibilities, and lock file merge conflicts
- Made "consider the blast radius" actionable with explicit call-site analysis via Grep
- Tightened "verify in production" in Execution Workflow to include concrete build commands
- Consolidated redundant "hidden complexity" guidance via cross-reference to Principle #4

### Dimensions Evaluated
Role Realism (AI-agent context), Actionability (concrete verification steps), Spec Alignment
(testing.md/code-quality.md gaps), Completeness (error context, dependency conflicts),
Over-Engineering (redundancy reduction)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Coherence Fix: ADRs and Cross-Team Negotiation

### Changes
- Added `docs/tdd/adr/` reference to spec check instructions so ADRs inform implementation
- Added cross-team technical negotiation handoff to @staff-engineer when encountering conflicting directions between teams

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename — current name accurately reflects the role.

## 2026-03-19 — Evolution 2: Scope Negotiation, Commit Discipline, Config Safety, and Observability

### Changes Made

**New sections added:**

1. **Negotiate Scope With Data** (Core Operating Principle #4) — Senior engineers at FAANG scale
   do not merely "push back" on scope; they negotiate with data. Added a full principle covering:
   quantifying cost of alternatives, identifying minimum viable changes, splitting oversized issues,
   and saying no with counter-offers. This fills a gap between the existing "Navigate Ambiguity"
   principle (which addresses unclear requirements) and the anti-pattern list (which says "scope
   creep" without teaching how to prevent it). Renumbered existing principles 4 and 5 to 5 and 6.

2. **Configuration-as-Code Safety** (Implementation Responsibilities subsection) — Added after
   Database & Schema Changes. This project is a configuration-as-code system where Rust structs
   generate JSON, YAML, and key-value config output. The original agent had no guidance specific
   to the risks of config generator changes: output diffing, serialization stability, consumer
   verification, and key collision prevention. This is highly aligned with the project's
   architecture spec and addresses a real gap for this codebase.

3. **Commit Hygiene & Version Control** (new top-level section) — Added after Build & CI Hygiene.
   The agent writes code and is expected to produce commits, but had zero guidance on commit
   quality. Added: one logical change per commit, bisectability, commit messages explaining why,
   separating refactors from behavior changes, and keeping generated files in sync (especially
   relevant for Cargo.lock and Vorpal.lock). At FAANG scale with 100+ developers, commit
   discipline directly affects code archaeology and incident response.

**Existing sections enhanced:**

4. **Production Ownership** — Added "Instrument from the start" bullet covering observability-first
   development: structured logging at decision points, metrics for SLA-bound operations, trace
   context propagation, and integrating with existing OTEL setup rather than inventing parallel
   approaches. The project has an OTEL stack (Loki + Mimir) configured in the Claude Code settings;
   the agent should be aware of observability as a first-class implementation concern.

5. **Self-review step** (Execution Workflow) — Made test suite guidance conditional: if no test
   suite exists yet, verify manually and note the absence of automated verification in the Docket
   comment. This aligns with the code-quality spec's observation that the project currently has
   zero tests.

### What Was NOT Changed

- **Docket workflow**: Unchanged. Already well-structured from Evolution 1.
- **Core principles 1-3**: Unchanged. Ownership, right-sizing, and ambiguity navigation remain
  strong.
- **Decision-Making Framework**: Unchanged. The hierarchy and reversibility subsection are solid.
- **Communication Style and Anti-Patterns**: Unchanged. Already comprehensive.
- **Cross-Functional Collaboration and Growing Engineers**: Unchanged. Already enhanced in
  Evolution 1.
- **YAML frontmatter**: Unchanged.

### Reasoning

Evolution 1 addressed the broadest gaps (backward compatibility, database safety, CI ownership,
design participation, technical spikes). Evolution 2 targets the next tier of FAANG-scale senior
engineer responsibilities: scope negotiation as a concrete skill (not just "push back"), commit
discipline for large-team collaboration, configuration-as-code safety aligned to this specific
project's architecture, and observability-first development. These are the patterns that
distinguish a senior engineer who works well on a team of 10 from one who operates effectively
in an organization of 100+.

## 2026-03-19 — Evolution 1: FAANG-Scale Realism and Missing Responsibilities

### Changes Made

**New sections added:**

1. **Backward Compatibility & Safe Changes** — Added a dedicated subsection under Implementation
   Responsibilities covering consumer identification, additive changes, versioning, feature flags
   for risky rollouts, and upgrade path testing. At FAANG scale with 100+ developers, a senior
   engineer's changes routinely touch shared interfaces consumed by other teams. The original
   agent had no guidance on this critical responsibility beyond a single bullet point about
   "backward compatibility."

2. **Database & Schema Changes** — Added guidance on reversible migrations, separating schema
   changes from code changes, handling transition periods during rolling deployments, testing
   with realistic data volumes, and safe backfill patterns. Database migrations are among the
   highest-risk changes a senior engineer makes, and the original agent had zero mention of them.

3. **Concurrency** — Added as a new lens under Cross-Cutting Concerns covering thread safety,
   race conditions, deadlock potential, and preference for established concurrency patterns.
   Missing from the original despite being a daily concern at scale.

4. **Build & CI Hygiene** — New top-level section covering responsibility for keeping the build
   green, respecting CI gate time, and deterministic dependency pinning. At scale, a broken build
   or slow CI pipeline affects hundreds of engineers. The original agent had no mention of CI
   responsibility.

5. **Technical Spikes & Prototyping** — New top-level section with guidance on time-boxing
   exploratory work, producing concrete artifacts, documenting findings, and throwing away
   prototype code. Senior engineers at FAANG companies frequently conduct spikes before
   committing to an approach, but the original agent only described executing pre-planned work
   or escalating to @staff-engineer.

6. **Reversibility as a Decision Accelerator** — Added as a subsection of the Decision-Making
   Framework. Teaches the agent to calibrate deliberation effort based on how hard a decision
   is to reverse — a key judgment pattern that distinguishes senior engineers from mid-level.

**Existing sections enhanced:**

7. **"What You Are NOT" — architect boundary** — Added clarification that while the agent does
   not produce TDDs, it DOES contribute implementation-level feedback on TDDs. This reflects
   the reality that senior engineers at FAANG companies are active participants in design
   discussions, not passive consumers.

8. **Growing Engineers Around You** — Added bullet on contributing to design discussions and
   providing feedback on TDDs from @staff-engineer. Reinforces bidirectional design collaboration
   rather than one-way consumption.

9. **Cross-Functional Collaboration** — Enhanced the UX spec gaps bullet with guidance on when
   small gaps can be resolved with reasonable judgment vs. when to escalate. Added new bullet
   on working across team boundaries. Both reflect FAANG-scale reality where senior engineers
   interact with multiple teams daily.

10. **Incident Response & Debugging** — Added guidance on behavior during active incidents:
    mitigation-first mindset, clear status communication, and coordination with @staff-engineer
    on rollback decisions.

11. **Dependency & API Surface Evaluation** — Added bullet on documenting public interfaces with
    doc-comments, following project conventions. The codebase's own `code-quality.md` spec notes
    the absence of doc comments as a gap — this gives the agent guidance to close that gap.

12. **Anti-Patterns** — Added "copy-paste implementation" anti-pattern. Duplication is the most
    common quality issue in large codebases and was not called out.

### What Was NOT Changed

- **Docket workflow**: Unchanged. The execution workflow, session initialization, and Docket rules
  are well-structured and specific enough for consistent agent behavior.
- **Core Operating Principles**: Unchanged. The five principles (ownership, right-sizing,
  ambiguity navigation, planning, quality) are solid and well-written.
- **Complete Workflow**: Retained as-is. While it partially overlaps with the Execution Workflow
  section, it serves as a quick-reference summary that is useful for the agent to have at the
  end of the document.
- **Communication Style**: Unchanged. Already strong and actionable.
- **YAML frontmatter**: Unchanged. The frontmatter format is consistent with the team convention.

### Reasoning

The original agent definition was strong on Docket workflow mechanics and quality principles but
underweighted the responsibilities that distinguish a senior engineer at FAANG scale from one at
a smaller company: backward compatibility discipline, database migration safety, CI ownership,
cross-team coordination, design participation (not just consumption), and exploratory technical
work. The additions target these gaps without inflating the document with low-value content.
