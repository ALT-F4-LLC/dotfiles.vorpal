# Changelog: senior-engineer

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
