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

1. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
2. **Validate skill files exist** — Run `ls .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`
   to list all discoverable skill files.
3. **If targeting a specific skill** — Verify the argument matches an existing skill directory in
   either `.claude/skills/<arg>/SKILL.md` or `skills/<arg>/SKILL.md`. If no match, inform user
   and abort.
4. **If no skill files found at all** — Inform user and abort.
5. **Check for existing changelogs** — Run `ls docs/changelog/skills/*.md 2>/dev/null` to see
   which changelogs already exist. Spawned agents will need this information.
6. **Measure skill file sizes** — Run `wc -l .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`
   and record the line count for each target skill. This determines the evolution mode for each:
   - **Over 500 lines (TRIM mode)**: The skill's primary objective is consolidation. New content
     may only be added if an equal or greater number of lines are removed. Communicate the line
     count and TRIM mode to the spawned agent.
   - **Under 500 lines (BALANCED mode)**: The skill may add content but must offset additions
     with removals to stay under 500 lines. Communicate the line count and BALANCED mode.
   - Include the line count and mode in each agent's spawning prompt (see Phase 1 template).

---

## Content Gate

**Every proposed addition MUST pass ALL checks. Reject content that fails ANY check.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring humans, attending meetings, relationship-building, career development, team building.
2. **Behavioral** — Does removing it change the skill's output? Reject: general knowledge a capable LLM already has.
3. **Non-redundant** — Is this concept already expressed elsewhere in the file? Reject duplicates even if worded differently.
4. **Concrete** — Is it a specific action, check, or output format? Reject: "think holistically", "drive excellence", aspirational fluff.

**Never add to skill files:** human social dynamics (1:1s, growing engineers, team morale), communication style (Claude's tone is governed by the system prompt), generic guidelines unrelated to the skill's purpose, decision matrices that restate existing workflows abstractly.

---

## Evaluation Dimensions

Every @staff-engineer reviewer evaluates the target skill against ALL 8 dimensions. **Dimensions
1, 3, and 5 propose additions — all proposed additions must pass the Content Gate above.**

1. **Skill Design Quality** — Claude Code best practices, frontmatter, argument handling,
   `disable-model-invocation` usage, structure-brevity balance?
2. **Actionability** — Instructions specific enough for reliable execution? Clear phases,
   concrete templates, defined outputs?
3. **Completeness** — Edge cases, error conditions, pre-flight checks, all workflow paths?
4. **Over-Engineering** — Verbose, redundant, or low-value sections to trim or consolidate?
5. **Orchestration, Cross-Communication & Agent Teams** — Proper agent use, parallelism,
   correct types, clear coordination? Templates must include **explicit SendMessage triggers**
   for peer-to-peer communication — flag hub-and-spoke if >50% of paths route through one agent.
   For skills using agent teams: correct lifecycle (TeamCreate → spawn → work → shutdown →
   TeamDelete)? Shared task lists with proper dependencies and status flow? Shutdown protocol
   correctness? Flag: missing cleanup, broadcast overuse, file conflicts between teammates.
6. **Coherence with Other Skills** — Scope overlaps, terminology, shared conventions,
   accurate references?
7. **Spec Alignment** — Alignment with `docs/spec/` project patterns?
8. **Rename Consideration** — Only if compelling — stability has value.

---

## Changelog Format

All changes are tracked in `docs/changelog/skills/<skill-name>.md`. Create the `docs/changelog/skills/`
directory if it doesn't exist.

**Every changelog file MUST use this exact format — no deviations, no extra sections:**

```markdown
# Changelog: <skill-name>

## <YYYY-MM-DD>

### Summary
<1-2 sentence overview of what this evolution cycle focused on>

### Changes
- <specific change and why>
- <specific change and why>

### Dimensions Evaluated
<which dimensions drove improvements>

### Rename
<if applicable: "Renamed from `<old>` to `<new>`: reasoning">
<if not: "No rename.">
```

### Changelog Rules

1. **H1**: `# Changelog: <skill-name>` (kebab-case). **H2**: `## YYYY-MM-DD` (no suffixes). **H3**: exactly `### Summary`, `### Changes`, `### Dimensions Evaluated`, `### Rename` — in order, no others.
2. **Max 20 lines per entry.** Prepend new entries below H1 so most recent is first.
3. **Read only the most recent `## <date>` entry** in existing changelogs — do NOT read full history.
4. If no improvements found, report that honestly rather than forcing changes.
5. **Normalization**: After applying changes, the orchestrator fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extra sections, and truncates entries over 20 lines.

---

## Orchestration Workflow

### Team Setup

Before spawning any agents, create an Agent Team to coordinate the evolution cycle:

1. **Create the team** using `TeamCreate`:
   ```
   TeamCreate(team_name="evolve-skills-{today_date}", description="Skill evolution cycle for {today_date}")
   ```

2. **Create Phase 0 tasks** (documentation research AND docket CLI audit):
   ```
   TaskCreate(subject="Docs Research", description="Research latest Claude Code documentation for new capabilities")
   TaskCreate(subject="Docket CLI Audit", description="Audit docket CLI for new/changed commands relevant to skills")
   ```

3. **Create Phase 1 tasks** — one per target skill (sequenced after Phase 0 by orchestrator):
   ```
   TaskCreate(subject="Review <name>", description="Review and improve <skill-path>/SKILL.md")
   ```

4. **Create the Phase 2 task** — sequenced after all Phase 1 tasks by orchestrator:
   ```
   TaskCreate(subject="Coherence & Renames", description="Cross-skill coherence review and rename execution")
   ```

### Phase 0: Documentation Research & Docket CLI Audit

Spawn TWO teammates in parallel — a `claude-code-guide` for docs research and a `senior-engineer`
for docket CLI audit (needs Bash access):

```
Agent(team_name="evolve-skills-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")
Agent(team_name="evolve-skills-{today_date}", name="docket-auditor", subagent_type="senior-engineer", prompt="...")
```

Assign Phase 0 tasks via `TaskUpdate`. After both complete, capture outputs as
`{docs_research_findings}` and `{docket_audit_findings}` — both are passed to Phase 1 agents.

Wait for both Phase 0 agents to complete before starting Phase 1.

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer teammate per target skill. **Spawn all teammates in the same turn**
to maximize parallelism. If targeting a single skill, spawn one.

Each teammate is spawned with `team_name` and `name` parameters:

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")
```

After spawning, assign tasks to teammates:

```
TaskUpdate(taskId=<id>, owner="review-<name>", status="in_progress")
```

Each @staff-engineer teammate (read-only — no file edits):

1. Reads the target skill file (e.g., `.claude/skills/<name>/SKILL.md` or `skills/<name>/SKILL.md`)
2. Reads ONLY the most recent entry in `docs/changelog/skills/<name>.md` (if it exists) — the
   first `## <date>` section only, NOT the full history — to avoid repeating the last cycle's changes
3. Checks `docs/spec/` for relevant project specifications (be selective — only files directly
   related to the skill's domain; do NOT read all spec files)
4. Reads the OTHER skill files — but ONLY the first ~80 lines of each to understand the skill
   ecosystem without consuming excessive context
5. Evaluates the skill against ALL 8 dimensions
6. Marks their task completed via `TaskUpdate` and reports back with structured change
   recommendations including net line change estimates

**After each Phase 1 teammate completes**, the orchestrator:

1. Reviews the teammate's change recommendations **against the Content Gate** — reject any
   addition that fails any gate check, even if the agent provides a rationale
2. Applies each approved change to the skill file using the Edit tool
3. Writes/updates the changelog entry in `docs/changelog/skills/<name>.md`
4. **Normalizes the entire changelog** for `docs/changelog/skills/<name>.md` — fix the H1 heading,
   strip H2 suffixes, rename non-standard H3 headers, and delete non-standard sections
   (see "Changelog Normalization" under Changelog Format)
5. Tracks rename recommendations and coherence issues for Phase 2

Use `TaskList()` to check overall Phase 1 progress.

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 teammates complete and the orchestrator has applied their changes, spawn a
single @staff-engineer teammate (read-only) to review coherence and recommend fixes:

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")
```

Assign the Phase 2 task:

```
TaskUpdate(taskId=<coherence_task_id>, owner="coherence-reviewer", status="in_progress")
```

The Phase 2 teammate:

1. Reads ALL skill files (the freshly improved versions)
2. Verifies any renames recommended in Phase 1 and prepares rename instructions
3. Checks cross-skill coherence:
   - No scope overlaps — each skill has a distinct purpose
   - Terminology is consistent across all skills
   - Shared conventions are followed (commit notice, frontmatter format, changelog patterns)
   - References to agents, directories, and project structure are accurate
   - Spawning templates reference correct agent types
   - Argument handling patterns are consistent
4. Marks the coherence task completed via `TaskUpdate` and reports structured recommendations
   (see Phase 2 template for format)

**After the Phase 2 teammate completes**, the orchestrator:

1. Executes any renames (`mv`, frontmatter updates, reference updates across codebase)
2. Applies coherence fixes using the Edit tool
3. Updates `docs/changelog/skills/<name>.md` for any skill that received coherence fixes

### Wrap-up & Team Cleanup

After Phase 2 completes:

1. **Shut down all teammates** via `SendMessage(to="<name>", message={type: "shutdown_request"})`
   for each spawned teammate, then **delete the team** via `TeamDelete(team_name="evolve-skills-{today_date}")`.
2. Run `wc -l` on all target skill files. If any exceed 500 lines, consolidate until under 500.
3. Report: files modified, before/after line counts, improvements made, renames/coherence fixes,
   and reminder that NO changes have been committed — review with `git diff`.

---

## Spawning Templates

### Phase 0: @claude-code-guide (Documentation Research)

```
Agent(team_name="evolve-skills-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")

Research the latest Claude Code documentation for capabilities relevant to skill definitions.
Focus on: new frontmatter fields, tool types, hook patterns, MCP integration, agent SDK features,
agent team patterns (TeamCreate, TeamDelete, task coordination, teammate lifecycle),
and permission/execution settings. Filter for what skill authors need to know.

## Output Format

- **<capability/change>**: <relevance to skill evolution>

Group findings under: New Capabilities, Changed Features, Deprecated/Removed, Recommendations.
```

### Phase 0: Docket CLI Audit

```
Agent(team_name="evolve-skills-{today_date}", name="docket-auditor", subagent_type="senior-engineer", prompt="...")

Audit the docket CLI to produce a structured reference of all commands, flags, and usage.

## Steps

1. Run `--help` on every docket command and subcommand (top-level, `issue`, `vote`, and all leaf commands).
2. Search the codebase for current docket usage: Grep for `docket ` across `agents/` and `.claude/skills/`.
3. Cross-reference: identify new commands not used in codebase, changed flags, and deprecated commands.

## Output Format

### New Commands
Commands found in `--help` output but NOT used anywhere in agents/*.md or skills:
- <command> — <synopsis>

### Changed Commands
Commands where current `--help` flags/syntax differs from how they are used in agent/skill files:
- <command> — <what changed>

### Deprecated/Removed
Commands referenced in agent/skill files but NOT found in `--help` output:
- <command> — <where referenced>

### Full CLI Reference
Complete command tree with synopsis and flags for each leaf command.

## Rules
- DO NOT edit any files. Read-only — audit and report only.
- Be thorough — run --help on every subcommand, not just the common ones.
- If a command errors on --help, note it as unavailable.
```

### Phase 1: @staff-engineer (Review & Improve)

Spawn one teammate per target skill. Substitute `<name>`, `<skill-path>`, `{line_count}`,
`{mode}`, and `{today_date}` (from pre-flight) for each.

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to review and improve a skill definition:

Target: <skill-path>/SKILL.md
Skill: <name>
Current size: {line_count} lines
Mode: {mode} (TRIM if over 500 lines, BALANCED if under)

## Size Budget

Hard limit: 500 lines. **TRIM mode** (over 500): primary objective is consolidation — removals
must exceed additions. **BALANCED mode** (under 500): additions allowed but offset by removals.
Every CHANGE adding lines MUST pair with a removal of equal or greater size. Report NET_LINES.

## Context

- Today's date is {today_date} — use for changelog entries.
- Read docs/changelog/skills/<name>.md — ONLY the most recent `## <date>` entry.
- Read docs/spec/ selectively — only files relevant to the skill's domain.
- Read OTHER skill files — first ~80 lines only. Check both .claude/skills/ and skills/.
- Review the Claude Code documentation research findings below and consider whether any
  new capabilities, features, or settings should be reflected in the skill's design.
- Review the docket CLI audit findings below — verify skills referencing docket commands
  use correct syntax, flags, and subcommands.
- Skip WebFetch — adds latency without value for this task.

## Claude Code Documentation Research
{docs_research_findings}

## Docket CLI Audit Findings
{docket_audit_findings}

## Content Gate (MANDATORY)

Apply the 4-check Content Gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Your Task

Evaluate <skill-path>/SKILL.md against ALL 8 dimensions (see Evaluation Dimensions in evolve-skills).
Over-Engineering is HIGHEST PRIORITY — every addition MUST be offset by a removal.
For Dimension 5, also evaluate agent team patterns if the skill uses teams: lifecycle correctness
(TeamCreate → spawn → shutdown → TeamDelete), task coordination, and cleanup.

## Requirements

- **DO NOT edit any files.** Read-only — analyze and recommend only.
- Build on strengths — improve, don't rewrite from scratch
- If no meaningful improvements needed, report that honestly
- **Minimize context**: First 80 lines of other skills, relevant specs only.

## Output Format

### Summary
<1-2 sentence overview — or "No changes needed">
Net line change: <estimated +/- lines>

### Recommended Changes
For each change:
\```
CHANGE <n>: <short title>
DIMENSION: <which dimension>
CONTEXT: <1 sentence>
NET_LINES: <+N or -N>
OLD_STRING:
<exact text to find — copy-paste precision, enough context to be unique>
NEW_STRING:
<exact replacement text — use `<REMOVE>` to delete, `<INSERT_AFTER>` to add after anchor>
\```

### Changelog Entry (under 20 lines, ONLY 4 sections: Summary, Changes, Dimensions Evaluated, Rename)

### Rename Recommendation
<"No rename" or "Rename to `<new-name>`: <reasoning>">

### Coherence Issues
<Issues noticed, or "None">
```

### Phase 2: @staff-engineer (Coherence & Renames)

Substitute `{today_date}` before spawning.

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to check cross-skill coherence and recommend fixes:

Today's date is {today_date}.

## Renames to Execute
<list recommended renames, or "No renames were recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Requirements

- **DO NOT edit any files.** Read-only — the orchestrator applies all changes.
1. Read ALL skill files in .claude/skills/*/SKILL.md and skills/*/SKILL.md
2. If renames listed, verify and prepare rename instructions (dir, frontmatter, references, changelog)
3. Check coherence: no scope overlaps, consistent terminology, accurate references,
   correct agent types in templates, consistent conventions and argument handling
4. Check cross-communication in orchestration skills: Enumerate which agent pairs have
   SendMessage triggers in spawn templates. Identify pairs sharing dependencies or handoffs
   but lacking triggers — these are gaps. Flag hub-and-spoke patterns where >50% of paths
   route through one agent. Verify triggers are bidirectional where applicable.

## Output Format

### Renames
For each: `RENAME: <old-dir> → <new-dir>` with FRONTMATTER_UPDATE, REFERENCES_TO_UPDATE,
CHANGELOG_RENAME. Or: "No renames needed."

### Coherence Fixes (including cross-communication gaps)
For each: `FIX <n>: <title>` / `FILE:` / `OLD_STRING:` / `NEW_STRING:` / `REASON:`.
Include cross-communication gaps as fixes (e.g., adding missing SendMessage triggers).
Or: "No coherence issues found."

### Changelog Entries
Standard format (4 sections, max 20 lines) for each skill that received fixes.

### Remaining Issues
<Unresolvable issues, or "None">
```

---

## Rules

1. **Run pre-flight before spawning.** Validate skill files exist and arguments resolve.
2. **Create the team before spawning teammates.** `TeamCreate` then `TaskCreate` before any `Agent` calls.
3. **Spawn Phase 1 teammates in parallel.** Maximum parallelism for independent reviews.
   Use `team_name` and `name` parameters when spawning via the `Agent` tool.
4. **Phase 2 runs AFTER all Phase 1 teammates complete.** Coherence requires seeing all
   changes. Use `TaskList` to verify all Phase 1 tasks are completed before proceeding.
5. **Always run Phase 2.** Even for single-skill improvements — coherence matters.
6. **Only the orchestrator edits files.** Spawned teammates are read-only reviewers that
   produce change recommendations. The orchestrator applies all edits using the Edit tool.
7. **Never commit.** No `git add`, no `git commit`, no `git push`.
8. **Respect existing quality.** Improvements build on what works, not rewrite from scratch.
9. **Changelog is mandatory.** Follow Changelog Rules above; orchestrator normalizes each run.
10. **Enforce 500-line budget.** `wc -l` after edits; consolidate if over. Report before/after.
11. **Fail loud.** If a teammate fails, report immediately with details.
12. **Timeout fallback.** If a Phase 1 teammate times out, re-spawn once. After two failures,
    the orchestrator performs the review directly.
13. **Enforce the Content Gate.** Reject any recommendation adding content that fails any gate
    check, even with a compelling rationale. Primary defense against bloat-then-purge cycles.
14. **Clean up the team.** Shut down all teammates and delete the team after wrap-up.
