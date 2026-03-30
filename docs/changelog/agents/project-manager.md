# Changelog: project-manager

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and session initialization, connected Mermaid graph output to plan validation, trimmed restated goal-alignment and proactive-sharing patterns. Net: -3 lines.

### Changes
- Added task coordination tools to frontmatter and planning progress tracking step
- Added `--mermaid` flag guidance to self-review validation step
- Trimmed operating context analogy sentence (-2 lines)
- Compressed proactive information sharing bullets into prose (-6 lines)
- Compressed exploration re-alignment paragraph (-4 lines)

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth, Completeness, Actionability, all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Updated Docket CLI reference with audit findings (missing flags, corrected defaults, new subcommands), removed obsolete Delegation Protocol (PM has /vote skill directly), added --quiet flag awareness, trimmed redundant vote skip guidance. Net: -14 lines.

### Changes
- Updated CLI reference: added `-a ASSIGNEE` on board/list, `-s STATUS` on create, `--orphan`/`-f` on delete, `--merge`/`--replace` on import, `-d`/`--limit` on vote list, `--findings-json` on vote cast, `issue log`, label subcommands with `--color`; fixed `--voter` as optional
- Removed Delegation Protocol section — PM has `/vote` skill in frontmatter, delegation workaround is dead code (-14 lines)
- Added `--quiet` flag note to Session Initialization
- Removed "Skip /vote for trivial/standard plans" sentence (inverse of trigger list)
- [Coherence] Fixed `vote create` flags: `-c`/`-n` restored to required (consistent with all other agents)
- [Coherence] Fixed `vote cast` flag brackets and added `JSON` arg to `--findings-json` (aligned with staff/senior/ux pattern)

### Dimensions Evaluated
Completeness (primary — CLI audit alignment), Consolidation & Trimming, Capability Growth, Actionability, Role Realism, Boundary Clarity, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (Docket logging for SendMessage and vote), fixed CLI discrepancies (link remove syntax, --escalation-reason, approve-with-concerns, next -s), added export/import, trimmed non-behavioral prose.

### Changes
- Added cross-communication observability section: log SendMessage exchanges and vote invocations as Docket comments
- Fixed `link remove` syntax to include required `<relation>` argument
- Added `--escalation-reason` to vote create, `approve-with-concerns` verdict to vote cast, `-s` to next
- Added `docket export / import` to CLI reference
- Removed "NOT a bureaucrat" bullet (aspirational, enforced by DoR/Rules)
- Removed "impact is measured" sentence (aspirational, not behavioral)

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness, Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Added new docket CLI commands (`plan`, `graph`, `reopen`, `label`) to reference and workflows, compressed /vote and Cancellation sections.

### Changes
- Added `docket plan --json` to Session Initialization for phased execution visibility
- Added `docket plan` and `docket issue graph` to self-review validation step
- Updated Docket CLI Reference with `plan`, `graph`, `reopen`, `label` commands and compressed vote lines
- Compressed Cancellation section (removed restated patterns)
- Compressed "When NOT to invoke /vote" to single sentence

### Dimensions Evaluated
Completeness, Consolidation & Trimming, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Restructured cross-cutting concerns for scannability, removed redundant rules, added @staff-engineer spike notification trigger, added spec-aware test task guidance.

### Changes
- Restructured cross-cutting concerns from run-on prose to scannable list format
- Removed redundant "Explore before planning" rule (already in Exploration and Routing section)
- Removed redundant "Complete analysis before creating issues" rule (enforced by section ordering)
- Compressed Docket CLI priorities/types into compact format
- Added @staff-engineer notification trigger when creating spike issues with architectural questions
- Added guidance to check `docs/spec/testing.md` before creating test tasks

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant operator-alignment restatement and effort section, removed redundant operating context sentence, added @sdet notification trigger and build-as-test awareness.

### Changes
- Compressed Alignment risk bullet to reference Operator Alignment section instead of restating
- Merged "Flag uncertainty" and "Shape to capacity" into sizing and total-plan bullets
- Removed redundant "Check progress" definition from Operating Context (covered by Re-Engagement)
- Added SendMessage notification trigger for @sdet when creating test tasks
- Added build-as-test awareness to cross-cutting concerns for projects without test suites

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Added memory and effort frontmatter, compressed cross-cutting concerns and external dependencies, removed redundant anti-pattern and vote example.

### Changes
- Added `memory: project` and `effort: high` frontmatter fields
- Removed redundant "solving the wrong problem well" anti-pattern
- Compressed 7-item cross-cutting concerns checklist into inline prose
- Removed /vote invocation example code block
- Folded "Identify External Dependencies" into Risk Assessment dependency bullet
- Renumbered Core Responsibilities sections 6-10 (was 7-11)
- Compressed Re-Engagement steps 4-5
- Updated Operating Context to reflect project memory

### Dimensions Evaluated
Completeness (memory, effort), Consolidation & Trimming (primary), Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Compressed status updates, removed redundant exploration checklist, merged architect NOT entry, added spike output format and blocking links to issue template.

### Changes
- Compressed 10-line status update enumeration into 3-line prose
- Removed "What to look for" exploration paragraph (signals already in Core Responsibilities)
- Compressed Re-Engagement step 1 to reference Session Initialization
- Added spike acceptance criteria: findings comment, recommendation, sufficient detail
- Added "Blocked by" field to issue description template
- Merged "architect" NOT entry into @staff-engineer NOT entry

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Completeness, Capability Growth

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed redundancy across session init, scope negotiation, external deps, and NOT-list. Added Bash tool constraint to prevent shell drift beyond Docket and read-only commands.

### Changes
- Compressed session initialization from 3 numbered steps to 2, removed `docket config`
- Removed redundant @sdet NOT entry (boundary already clear from cross-cutting concerns)
- Added Bash constraint rule: Docket commands and read-only exploration only
- Removed "cannot spawn sub-agents" platform detail from Exploration section
- Fixed self-referential re-engagement trigger (agent cannot "re-engage" itself)
- Folded scope negotiation into real-scope bullet
- Compressed External Dependencies section
- [Coherence] Replaced "orchestrator" with "user or team lead" (6 occurrences)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Role Realism, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added Operating context paragraph to align with the pattern established across all other agents.

### Changes
- Added "Operating context" paragraph explaining stateless agent execution model, adapted to PM workflows

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Removed 4 sections that fail Content Gate (Communication Style, Retrospective, Anti-Patterns, Decision-Making). Folded Parallelism/Dependencies into Decompose the Work. Calibrated plan summary to tier.

### Changes
- Removed Communication Style, Retrospective, Anti-Patterns, Decision-Making Framework sections
- Folded Maximize Parallelism and Dependencies into Decompose the Work, preserving contract task pattern
- Compressed escalation into Rules section
- Calibrated plan summary checklist to scale with plan complexity tier

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 956 to 390 lines. Collapsed verbose routing templates, compressed issue examples, removed redundant workflow summary, and tightened all sections.

### Changes
- Collapsed Technical Investigation / UX Design / TDD routing into single "Exploration and Routing" section
- Compressed issue creation examples from three verbose blocks to one compact pattern
- Removed Planning Workflow Summary ASCII flowchart (duplicated section headings)
- Compressed Plan Monitoring templates, merged Cross-Workstream Coordination into Plan Monitoring
- Tightened all Core Responsibilities, Communication, Decision-Making, Anti-Patterns, Rules

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Role Realism, Boundary Clarity

### Rename
No rename.
