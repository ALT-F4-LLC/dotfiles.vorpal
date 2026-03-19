# Evolve Skills Skill Evolution Log

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
