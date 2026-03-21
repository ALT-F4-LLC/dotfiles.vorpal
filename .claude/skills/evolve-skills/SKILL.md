---
name: evolve-skills
description: >
  Review and improve skill definitions in .claude/skills/*/SKILL.md and skills/*/SKILL.md.
  Evaluates skill design quality, actionability, completeness, orchestration effectiveness,
  cross-skill coherence, spec alignment, and over-engineering. Enforces a Content Gate that
  rejects non-actionable, non-executable, or redundant additions before they enter skill files.
  Enforces a 500-line size budget per skill. Can target a specific skill or improve all skills.
  Agents propose changes; the orchestrator applies all edits, handles renames, and maintains
  changelogs. Use when the user wants to evolve, improve, or refine skill definitions —
  including phrases like "evolve skills", "improve skills", "refine skills", "make the skills
  better", or "grow the skills".
argument-hint: "[skill-name]"
effort: high
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Evolve Skills

You are the **Skill Evolution Orchestrator**. You MUST create an agent team (TeamCreate) and
spawn @staff-engineer teammates to review ALL skill files in `.claude/skills/*/SKILL.md` and
`skills/*/SKILL.md`. **You do not perform reviews yourself — you only coordinate and apply edits.**
This includes the `evolve-*` skills themselves — self-evolution is expected and intentional.
Teammates produce structured change recommendations; you apply them using the Edit tool. All
additions are filtered through the Content Gate to prevent non-actionable content from entering
skill files.

> **Self-evolution note:** When this skill evolves itself, changes to this file take effect on
> the *next* invocation, not the current one.

> **SIZE CONSTRAINT: Skill files MUST stay under 500 lines.** Evolution is about sharpening, not
> accumulating. Every cycle should leave skill files the same size or smaller. If a file is over
> 500 lines, the primary goal of that cycle is consolidation and trimming — new content may only
> be added if an equal or greater amount is removed. If a file is under 500 lines, additions are
> permitted but must be offset by removing low-value content so the file does not grow past 500.

---

## Argument Handling

Target skill(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`.
- **With argument** (`/evolve-skills dev`): Improve only the named skill. See Pre-flight for validation.

---

## Pre-flight

Before spawning any agents:

1. **Verify evolution goal** — HARD GATE: Do not proceed to file validation or agent spawning
   until the goal is verified. In standalone mode, use AskUserQuestion to confirm what evolution
   focus the operator wants (e.g., all skills, specific skill, specific dimensions). In team
   mode (orchestrator prompt includes "Verified goal"), use it as the starting point. Re-verify alignment if your understanding diverges.
2. **Gather experience feedback** — Use `AskUserQuestion` to ask the operator:
   - Current experience with the skill(s) being evolved (what's working well, what's not)
   - Pain points or friction encountered during usage
   - Any specific feedback that should inform this evolution cycle
   Store the response as `{experience_feedback}`. In team mode, skip if the orchestrator
   prompt already includes experience feedback context.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
4. **Validate skill files exist** — Run `ls .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`
   to list all discoverable skill files.
5. **If targeting a specific skill** — Verify the argument matches an existing skill directory in
   either `.claude/skills/<arg>/SKILL.md` or `skills/<arg>/SKILL.md`. If no match, inform user
   and abort.
6. **If no skill files found at all** — Inform user and abort.
7. **Check for existing changelogs** — Run `ls docs/changelog/skills/*.md 2>/dev/null` to see
   which changelogs already exist. Spawned agents will need this information.
8. **Measure skill file sizes** — Run `wc -l .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`
   and record the line count for each target skill. Mode is **TRIM** (over 500: consolidation
   primary, removals must exceed additions) or **BALANCED** (under 500: additions allowed but
   offset by removals). Include line count and mode in each agent's spawning prompt.

---

## Content Gate

**Every proposed addition MUST pass ALL 4 checks. Reject content that fails ANY check.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the skill's output? Reject: general LLM knowledge.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if reworded.
4. **Concrete** — Specific action, check, or output format? Reject aspirational fluff ("think holistically", "drive excellence").

---

## Evaluation Dimensions

Every @staff-engineer reviewer evaluates against ALL 8 dimensions. **Dimensions 1, 3, and 5
propose additions — all must pass the Content Gate.**

1. **Skill Design Quality** — Frontmatter (including `user-invocable`, `effort`, `argument-hint`), argument handling, `disable-model-invocation`, structure-brevity balance.
2. **Actionability** — Specific enough for reliable execution? Clear phases, concrete templates, defined outputs.
3. **Completeness** — Edge cases, error conditions, pre-flight checks, all workflow paths.
4. **Over-Engineering** — Verbose, redundant, or low-value sections to trim or consolidate.
5. **Orchestration & Agent Teams** — Proper agent use, parallelism, correct types, coordination.
   Templates must include **explicit SendMessage triggers** for peer-to-peer communication — flag
   hub-and-spoke if >50% of paths route through one agent. For team skills: correct lifecycle
   (TeamCreate → spawn → shutdown → TeamDelete), task coordination, cleanup, shutdown protocol.
   Check: self-verification, course-correction triggers, efficient context (targeted Grep over broad reads).
6. **Coherence** — Scope overlaps, terminology, shared conventions, accurate references.
7. **Spec Alignment** — Alignment with `docs/spec/` project patterns.
8. **Rename Consideration** — Only if compelling — stability has value.

---

## Changelog Format

All changes tracked in `docs/changelog/skills/<skill-name>.md` (create directory if needed).

**Exact format — no deviations:** `# Changelog: <skill-name>` (kebab-case) > `## YYYY-MM-DD` (no suffixes) > exactly 4 H3 sections in order: `### Summary` (1-2 sentences), `### Changes` (bulleted with reasoning), `### Dimensions Evaluated`, `### Rename` (details or "No rename.").

**Rules:** Max 20 lines per entry. Prepend new entries below H1 (most recent first). Read only the most recent `## <date>` entry — never full history. Report honestly if no improvements found. **Normalization:** orchestrator fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extras, truncates over 20 lines.

---

## Orchestration Workflow

### Team Setup

Create an Agent Team before spawning agents:

1. **Create team:** `TeamCreate(team_name="evolve-skills-{today_date}", description="Skill evolution cycle for {today_date}")`
2. **Create Phase 0 tasks:** `TaskCreate` for "Docs Research" and "Docket CLI Audit"
3. **Create Phase 1 tasks** — one `TaskCreate(subject="Review <name>")` per target skill
4. **Create Phase 2 task:** `TaskCreate(subject="Coherence & Renames")`

### Phase 0: Documentation Research & Docket CLI Audit

Spawn TWO teammates in parallel — `docs-researcher` (claude-code-guide) and `docket-auditor`
(senior-engineer, needs Bash). Assign Phase 0 tasks via `TaskUpdate`. After both complete,
capture outputs as `{docs_research_findings}` and `{docket_audit_findings}` for Phase 1.
Wait for both to complete before starting Phase 1.

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer teammate per target skill (all in the same turn for parallelism).
Assign tasks via `TaskUpdate(taskId=<id>, owner="review-<name>", status="in_progress")`.

Each teammate (read-only — no file edits):
1. Reads target skill file and most recent changelog entry only (first `## <date>` section)
2. Checks `docs/spec/` selectively — only files relevant to the skill's domain
3. Reads OTHER skill files — first ~80 lines only for ecosystem context
4. Evaluates against ALL 8 dimensions, marks task completed, reports structured recommendations

**After each teammate completes**, the orchestrator:
1. Reviews recommendations **against the Content Gate** — reject additions failing any check
2. Applies approved changes via Edit tool
3. Writes/updates and normalizes changelog in `docs/changelog/skills/<name>.md`
4. Tracks renames and coherence issues for Phase 2
5. **Log cross-communication**: record any SendMessage exchanges between agents (sender, recipient, topic) for the wrap-up observability report
6. **Verify edits**: `wc -l` for budget, validate frontmatter/sections, check cross-references

Use `TaskList()` for progress. Route cross-cutting findings from SendMessage to peers and Phase 2.

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 changes are applied, spawn a single @staff-engineer teammate (read-only)
for coherence review. Assign via `TaskUpdate`.

The Phase 2 teammate:
1. Reads ALL skill files (freshly improved versions)
2. Verifies Phase 1 rename recommendations and prepares rename instructions
3. Checks coherence: no scope overlaps, consistent terminology, shared conventions followed,
   accurate references, correct agent types in templates, consistent argument handling
4. Marks task completed and reports structured recommendations

**After completion**, the orchestrator executes renames, applies coherence fixes via Edit,
and updates changelogs for affected skills.

### Wrap-up & Team Cleanup

After Phase 2: shut down all teammates via `SendMessage(shutdown_request)`, then
`TeamDelete(team_name="evolve-skills-{today_date}")`. Run `wc -l` on all target skills —
consolidate any over 500. Report: files modified, before/after line counts, improvements,
renames/coherence fixes, and reminder that NO changes have been committed.

**Observability report** (always include): cross-communication events (which agents messaged
which, and why), vote skill invocations (proposals, outcomes), and course-corrections surfaced.

---

## Spawning Templates

### Phase 0: @claude-code-guide (Documentation Research)

```
Agent(team_name="evolve-skills-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")

MISSION: Research Claude Code documentation for capabilities relevant to SKILL.md definitions.
Report NEW or CHANGED features that affect how skill files are written.

PAGES TO RESEARCH (by priority tier):

TIER 1 — MUST visit every page, extract ALL relevant capabilities:
- Skills — frontmatter fields (name, description, allowed-tools, argument-hint, effort, disable-model-invocation), string substitutions, automatic discovery, skill locations (.claude/skills/ and skills/), argument passing, tool restriction, access control, dynamic context injection, running in subagents, sharing skills, visual output, troubleshooting
- Sub-agents — how skills run in subagents, agent types for spawning, frontmatter fields, capability control, tool restrictions, MCP scoping, skill preloading
- Agent Teams — team patterns (TeamCreate, TeamDelete, task coordination, teammate lifecycle, communication, shutdown protocol)
- Hooks Reference — hooks in skills, all hook event types, matcher patterns, handler types, hooks defined in skill frontmatter

TIER 2 — SHOULD visit each page, extract only skill-relevant capabilities:
- Permissions — permission modes, tool-specific rules, managed permissions affecting skills
- Settings — configuration scopes, settings files, subagent config, plugin config
- MCP — MCP server patterns, tool search, managed configuration
- Plugins Reference — plugin manifest schema, plugin components including skills, plugin caching
- Plugins — plugin creation, skill-plugin relationship
- Best Practices — skill-related practices, verification, context management
- Tools Reference — available tools, tool behavior details

TIER 3 — SCAN quickly, report only new/changed features:
- Commands — built-in commands, MCP prompts
- Output Styles — custom output styles (relationship to skills)
- Memory — auto-memory, CLAUDE.md interaction with skills
- Changelog — recent releases, new features, deprecations
- CLI Reference — CLI flags affecting skills
- How Claude Code Works — agentic loop, context management

RESEARCH INSTRUCTIONS:
- Tier 1: Visit EVERY page. For each, extract: new features, changed behaviors, deprecated patterns. Focus question: "Would this change how a SKILL.md file should be written?"
- Tier 2: Visit each page, extract only capabilities relevant to skill definitions.
- Tier 3: Quick scan, report only actionable new/changed features.
- Visit ALL Tier 1 and Tier 2 pages — do not skip any.
- If a page fails to load, note it and continue to the next page.
- Focus on NEW or CHANGED — skip well-known existing features.
- At the end, report which pages were researched and which were skipped.
- Filter criterion: only report findings that would affect how SKILL.md files are written.

OUTPUT FORMAT: `- **<capability/change>**: <skill definition relevance>` grouped under:
New Capabilities, Changed Features, Deprecated/Removed, Recommendations.
```

### Phase 0: Docket CLI Audit

```
Agent(team_name="evolve-skills-{today_date}", name="docket-auditor", subagent_type="senior-engineer", prompt="...")

Audit the docket CLI to produce a structured reference of all commands, flags, and usage.

1. Run `--help` on every docket command/subcommand (top-level, `issue`, `vote`, all leaf commands).
2. Grep for `docket ` across `agents/` and `.claude/skills/` to find current usage.
3. Cross-reference: identify new/changed/deprecated commands vs. codebase usage.

Output: New, Changed, Deprecated commands (with synopsis) plus full CLI reference tree.
Rules: Read-only only. Run --help on every subcommand. Note unavailable commands.
```

### Phase 1: @staff-engineer (Review & Improve)

Spawn one teammate per target skill. Substitute `<name>`, `<skill-path>`, `{line_count}`,
`{mode}`, `{today_date}`, `{verified_goal}`, and `{experience_feedback}` for each.

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to review and improve a skill definition:

Target: <skill-path>/SKILL.md | Skill: <name> | Size: {line_count} lines | Mode: {mode}
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Experience feedback: {experience_feedback}

## Size Budget
Hard limit: 500 lines. TRIM (over 500): removals must exceed additions. BALANCED (under 500):
additions allowed but offset by removals. Every CHANGE adding lines MUST pair with equal/greater removal. Report NET_LINES.

## Context
- Today's date: {today_date} (for changelog entries)
- Read docs/changelog/skills/<name>.md — ONLY the most recent `## <date>` entry
- Read docs/spec/ selectively — only files relevant to the skill's domain
- Read OTHER skill files — first ~80 lines only (both .claude/skills/ and skills/)
- Review operator experience feedback below — prioritize addressing reported pain points and friction.
- Review docs research and docket audit findings below for new capabilities and correct CLI usage
- Skip WebFetch

## Claude Code Documentation Research
{docs_research_findings}

## Docket CLI Audit Findings
{docket_audit_findings}

## Operator Experience Feedback
{experience_feedback}

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Your Task
Evaluate <skill-path>/SKILL.md against ALL 8 dimensions. Over-Engineering is HIGHEST PRIORITY —
every addition MUST be offset by a removal. For Dimension 5, evaluate agent team patterns if
applicable (lifecycle, task coordination, cleanup).

## Requirements
- **Read-only** — analyze and recommend only. Build on strengths, don't rewrite.
- Minimize context: first 80 lines of other skills, relevant specs only.
- **Course-correction**: SendMessage the orchestrator IMMEDIATELY for cross-cutting issues,
  patterns affecting all targets, or scope expansion beyond target skill.

## Output Format
### Summary
<1-2 sentences or "No changes needed"> | Net line change: <+/- lines>
### Recommended Changes
For each: `CHANGE <n>: <title>` / `DIMENSION:` / `CONTEXT:` / `NET_LINES:` / `OLD_STRING:` / `NEW_STRING:` (use `<REMOVE>` to delete, `<INSERT_AFTER>` to add)
### Changelog Entry (under 20 lines, 4 sections: Summary, Changes, Dimensions Evaluated, Rename)
### Rename Recommendation
### Coherence Issues
```

### Phase 2: @staff-engineer (Coherence & Renames)

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to check cross-skill coherence and recommend fixes.
Today's date: {today_date}. **Read-only** — the orchestrator applies all changes.

## Renames to Execute
<list recommended renames, or "No renames were recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Tasks
1. Read ALL skill files in .claude/skills/*/SKILL.md and skills/*/SKILL.md
2. If renames listed, verify and prepare rename instructions (dir, frontmatter, references, changelog)
3. Check coherence: no scope overlaps, consistent terminology, accurate references,
   correct agent types in templates, consistent conventions and argument handling
4. Check cross-communication: enumerate SendMessage triggers between agent pairs, identify
   gaps (shared dependencies/handoffs without triggers), flag hub-and-spoke (>50% routing
   through one agent), verify bidirectional triggers where applicable

## Output Format
### Renames
For each: `RENAME: <old> → <new>` with FRONTMATTER_UPDATE, REFERENCES_TO_UPDATE, CHANGELOG_RENAME. Or: "No renames needed."
### Coherence Fixes (including cross-communication gaps)
For each: `FIX <n>: <title>` / `FILE:` / `OLD_STRING:` / `NEW_STRING:` / `REASON:`. Or: "No coherence issues found."
### Changelog Entries
Standard format (4 sections, max 20 lines) for each affected skill.
### Remaining Issues
<Unresolvable issues, or "None">
```

---

## Rules

1. **Pre-flight before spawning.** Validate skill files and arguments first.
2. **Team before agents.** `TeamCreate` → `TaskCreate` → `Agent` calls.
3. **Phase 1 in parallel.** Use `team_name` and `name` when spawning.
4. **Phase 2 after all Phase 1.** Use `TaskList` to verify completion.
5. **Always run Phase 2** — even for single-skill improvements.
6. **Only orchestrator edits files.** Teammates are read-only reviewers.
7. **Never commit.** No `git add`, `git commit`, or `git push`.
8. **Build on strengths** — improve, don't rewrite.
9. **Changelog mandatory.** Follow format above; orchestrator normalizes.
10. **500-line budget.** `wc -l` after edits; consolidate if over.
11. **Fail loud.** Report teammate failures immediately.
12. **Timeout fallback.** Re-spawn once; after two failures, orchestrator reviews directly.
13. **Content Gate enforced.** Reject additions failing any check — primary bloat defense.
14. **Clean up.** Shut down teammates and delete team after wrap-up.
