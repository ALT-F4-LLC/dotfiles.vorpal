# Evolve Skills Skill Evolution Log

## 2026-03-19 (cycle 3)

### Summary
Closed the date passthrough gap in spawning templates and tightened template substitution
instructions so spawned agents receive all the context they need to produce correct changelog
entries without re-resolving the date themselves.

### Changes
- Added `Today's date is {today_date} — use this for changelog entries.` to the Phase 1
  spawning template Context section (the pre-flight resolves the date and claims it is "passed
  to every spawned agent" but the template never actually included it — agents had to infer or
  re-resolve the date independently, risking inconsistency)
- Added `Today's date: {today_date} (use for any changelog entries)` to the Phase 2 spawning
  template header (Phase 2 also writes changelog entries for coherence fixes but had no date
  context, same gap as Phase 1)
- Updated Phase 1 template header text from "Customize `<name>` and `<skill-path>` for each"
  to "Substitute `<name>`, `<skill-path>`, and `{today_date}` (from pre-flight step 1) for
  each" — making the substitution list explicit and complete
- Added Phase 2 template header: "Substitute `{today_date}` (from pre-flight step 1) before
  spawning." — parallel guidance to Phase 1
- Refined pre-flight step 1 wording: added "Store this as `{today_date}`" to name the variable
  that templates reference, closing the gap between where the date is captured and where it is
  consumed
- Removed WebFetch mention from Phase 1 spawning template Context section (the prior evolution
  added it but it was slightly misplaced as a context bullet — agents already know their own
  tool availability; the orchestration workflow step 3 retains the guidance for the
  orchestrator's awareness)
- Tightened orchestration workflow step 3 wording: "Uses WebFetch if available to research
  Claude Code skill best practices; if not, proceeds with existing knowledge" (removed
  redundant "of Claude Code best practices" repetition)
- Simplified Phase 1 template changelog requirement from conditional "create docs/changelog/
  directory if needed; if the changelog file exists, prepend..." to direct "prepend the new
  entry below the H1 heading since the file exists" — the orchestrator already validates
  changelog existence in pre-flight step 5

### Dimensions Evaluated
- **Completeness**: Date passthrough was the primary gap — pre-flight captured the date but
  neither spawning template delivered it to the agent
- **Actionability**: Explicit substitution variable naming (`{today_date}`) and complete
  substitution lists in template headers make the orchestrator's job unambiguous
- **Orchestration Effectiveness**: Both phases now receive all context needed to produce
  correct, consistent outputs without redundant tool calls

### Rename
No rename — current name accurately reflects the skill's purpose.

## 2026-03-19

### Summary
Applied pending improvements from Phase 1 review that could not be written due to sandbox
restrictions on `.claude/skills/`. Also applied coherence fixes to align with evolve-agents
patterns and conventions across the skill ecosystem.

### Changes
- Replaced hardcoded Claude Code documentation URL and WebFetch instructions in both the
  orchestration workflow (step 3) and Phase 1 spawning template context section with graceful
  degradation: "Uses WebFetch if available; if not, proceed with existing knowledge of Claude
  Code best practices" (agents do not reliably have WebFetch tool access)
- Fixed duplicate step 6 numbering in Phase 1 orchestration workflow — renumbered sequentially
  from 1-9 (was 1-6, 6-8 with two step 6s)
- Added explicit argument matching guidance: match against both `.claude/skills/<arg>/SKILL.md`
  and `skills/<arg>/SKILL.md`, inform user and abort if no match in either location
- Added self-evolution callout after "You do not edit skill files yourself. You coordinate." to
  clarify that changes to this file take effect on the next invocation, not the current one
- Aligned spec selectivity guidance between workflow step 4 and template context — both now say
  "be selective — only files relevant to the skill's domain"
- Added Pre-flight section (mirroring evolve-agents pattern) with 5 steps: resolve date,
  validate skill files exist, validate argument match, handle empty results, check existing
  changelogs
- Added "Run pre-flight before spawning" as Rule #1, shifted existing rules 1-8 to 2-9
  (consistent with evolve-agents rule ordering)

### Dimensions Evaluated
- **Completeness**: Pre-flight section and argument matching guidance closed validation gaps
- **Actionability**: Graceful WebFetch degradation prevents agent failures; sequential numbering
  eliminates ambiguity
- **Coherence with Other Skills**: Pre-flight pattern, rule ordering, and spec selectivity
  language now consistent with evolve-agents

### Rename
No rename -- current name accurately reflects the skill's purpose.
