# Evolve Agents Skill Evolution Log

## 2026-03-19 (third evolution)

### Summary
Fixed a critical orchestration gap where the resolved date from pre-flight was never propagated
to spawned agents, and aligned template structure with evolve-skills conventions.

### Changes
- Added `{today_date}` propagation to Phase 1 spawning template — added "Today's date is
  {today_date} — use this for changelog entries." to the Context section (previously the
  pre-flight resolved the date but no template variable delivered it to spawned agents, meaning
  agents had no way to use a consistent date for changelog entries)
- Added `{today_date}` propagation to Phase 2 spawning template — added "Today's date is
  {today_date} — use this for any changelog entries." line (Phase 2 also writes changelog
  entries for coherence fixes and renames but had no date context)
- Added "Important" callout to Phase 1 orchestration workflow section reminding the orchestrator
  to substitute `{today_date}` into templates before dispatching (makes the substitution
  requirement explicit rather than implied)
- Strengthened pre-flight step 1 wording — changed from "This date is passed to every spawned
  agent" to "Store this as `{today_date}`. This value MUST be substituted into every spawning
  template" (previous wording implied the date was passed but the templates had no mechanism to
  receive it)
- Added `Agent: <name>` identifier line to Phase 1 template header — aligns with evolve-skills
  which has `Skill: <name>` for quick identification of the target
- Added `{today_date}` to Phase 1 template header's customization list — "Customize `<name>`
  and `{today_date}` for each" (was only `<name>`)
- Added "Substitute `{today_date}` (from pre-flight step 1) before dispatching." instruction
  above Phase 2 template (explicit reminder, consistent with Phase 1 callout)
- Added spec selectivity guidance to orchestration workflow step 4 — "be selective — only files
  related to the agent's domain" (aligns with evolve-skills wording and the spawning template's
  existing selective guidance)

### Dimensions Evaluated
- **Actionability**: Date propagation was the highest-impact fix — without it, spawned agents
  could not produce consistently-dated changelog entries, undermining a core skill requirement
- **Coherence with Other Skills**: `Agent: <name>` header line, `{today_date}` customization
  list, and spec selectivity language now match evolve-skills conventions
- **Completeness**: Phase 2 template now receives date context for its changelog writes

### Rename
No rename -- current name accurately reflects the skill's purpose.

## 2026-03-19

### Summary
Applied pending improvements from Phase 1 review that could not be written due to sandbox
restrictions on `.claude/skills/`. Also applied coherence fixes to align with evolve-skills
patterns and conventions across the skill ecosystem.

### Changes
- Added Pre-flight section with 5 steps: resolve date, validate agent files exist, validate
  argument match, handle empty results, check existing changelogs (mirrors the pattern
  established in dev-init and now also in evolve-skills)
- Fixed duplicate step 6 numbering in Phase 1 orchestration workflow — renumbered sequentially
  from 1-9 (was 1-6, 6-8 with two step 6s)
- Removed hardcoded agent role description table from Phase 1 spawning template — replaced with
  instruction to read the role description from the target agent file itself (prevents drift
  when agent definitions are updated without updating this skill)
- Replaced hardcoded Claude Code documentation URL and WebFetch instructions in both the
  orchestration workflow (step 3) and Phase 1 spawning template context section with graceful
  degradation: "Uses WebFetch if available; if not, proceed with existing knowledge of Claude
  Code best practices" (agents do not reliably have WebFetch tool access)
- Added `.claude/skills/*/SKILL.md` to Phase 2 rename search paths — previously only searched
  `skills/*/SKILL.md`, missing the `.claude/skills/` location where evolve-* skills live
- Added "Run pre-flight before spawning" as Rule #1, shifted existing rules 1-8 to 2-9
  (consistent with evolve-skills rule ordering)

### Dimensions Evaluated
- **Completeness**: Pre-flight section closed environment validation gap
- **Actionability**: Graceful WebFetch degradation prevents agent failures; sequential numbering
  eliminates ambiguity; dynamic role reading prevents stale template data
- **Coherence with Other Skills**: Pre-flight pattern, rule ordering, and rename search paths
  now consistent with evolve-skills; both evolve-* skills now follow identical structural
  patterns

### Rename
No rename -- current name accurately reflects the skill's purpose.
