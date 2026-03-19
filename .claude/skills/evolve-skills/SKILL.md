---
name: evolve-skills
description: >
  Review and improve skill definitions in .claude/skills/*/SKILL.md and skills/*/SKILL.md.
  Evaluates skill design quality, actionability, completeness, orchestration effectiveness,
  cross-skill coherence, spec alignment, and over-engineering. Can target a specific skill or
  improve all skills. Directly edits skill files, handles renames with full reference updates,
  and maintains changelogs. Use when the user wants to evolve, improve, or refine skill
  definitions — including phrases like "evolve skills", "improve skills", "refine skills",
  "make the skills better", or "grow the skills".
argument-hint: "[skill-name]"
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Evolve Skills

You are the **Skill Evolution Orchestrator** — you coordinate @staff-engineer agents to review
and improve ALL skill definition files in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`.
This includes the `evolve-*` skills themselves — self-evolution is expected and intentional. Each
improvement cycle makes the skills more effective, actionable, and well-structured for Claude
Code execution.

You do not edit skill files yourself. You coordinate.

> **Self-evolution note:** When this skill evolves itself, changes to this file take effect on
> the *next* invocation, not the current one.

---

## Argument Handling

Target skill(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills found in `.claude/skills/*/SKILL.md`
  and `skills/*/SKILL.md`.
- **With argument** (`/evolve-skills dev`): Improve only the named skill. Match against
  both `.claude/skills/<arg>/SKILL.md` and `skills/<arg>/SKILL.md`. If no match in either
  location, inform user and abort.

Resolve targets by listing what exists:

```bash
ls .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null
```

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

---

## Evaluation Dimensions

Every @staff-engineer reviewer evaluates the target skill against ALL 8 dimensions:

1. **Skill Design Quality** — Does the skill follow Claude Code best practices? Clear trigger
   phrases in description, proper frontmatter, good argument handling, appropriate use of
   `disable-model-invocation`, good balance of structure and brevity?

2. **Actionability** — Are instructions specific enough for Claude to execute reliably? Clear
   phases, concrete spawning templates, defined outputs, consistent results?

3. **Completeness** — Does the skill handle edge cases, error conditions, pre-flight checks?
   All workflow paths covered from start to wrap-up? Cleanup and reporting included?

4. **Over-Engineering** — Verbose, redundant, or low-value sections? Repeated concepts,
   generic guidelines, excessive template variations, rules duplicating agent definitions?

5. **Orchestration Effectiveness** — Does the skill use agents effectively? Parallelism
   maximized, correct agent types, well-structured templates, sequential dependencies
   respected, clear coordination (what each agent receives and reports back)?

6. **Coherence with Other Skills** — Scope overlaps with other skills? Terminology consistent?
   Shared conventions followed (commit notice, frontmatter, changelog)? Accurate references?

7. **Spec Alignment** — Alignment with `docs/spec/` project patterns and conventions?

8. **Rename Consideration** — Should the skill be renamed? Only recommend if compelling —
   stability has value. Consider naming conventions and clarity of purpose.

---

## Changelog Format

All changes are tracked in `docs/changelog/skills/<skill-name>.md`. Create the `docs/changelog/skills/`
directory if it doesn't exist. Each file uses this format:

```markdown
# <Skill Name> Skill Evolution Log

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
<if not applicable: "No rename — current name accurately reflects the skill's purpose.">
```

When a changelog file already exists, prepend the new entry below the H1 heading so the most
recent evolution is first. **Read the existing changelog before making changes** — it contains
the history of prior improvements and helps avoid re-treading the same ground.

If no meaningful improvements are found for a skill, report that in the changelog entry
rather than forcing changes. Not every cycle needs to produce edits.

---

## Orchestration Workflow

### Team Setup

Before spawning any agents, create an Agent Team to coordinate the evolution cycle:

1. **Create the team** using `TeamCreate`:
   ```
   TeamCreate(team_name="evolve-skills-{today_date}", description="Skill evolution cycle for {today_date}")
   ```

2. **Create Phase 1 tasks** — one `TaskCreate` per target skill:
   ```
   TaskCreate(team_name="evolve-skills-{today_date}", title="Review <name>", description="Review and improve <skill-path>/SKILL.md", depends_on=[])
   ```

3. **Create the Phase 2 task** — depends on all Phase 1 tasks:
   ```
   TaskCreate(team_name="evolve-skills-{today_date}", title="Coherence & Renames", description="Cross-skill coherence review and rename execution", depends_on=[<all Phase 1 task IDs>])
   ```

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer teammate per target skill. **Spawn all teammates in the same turn**
to maximize parallelism. If targeting a single skill, spawn one.

Each teammate is spawned with `team_name` and `name` parameters:

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")
```

After spawning, assign tasks to teammates:

```
TaskUpdate(team_name="evolve-skills-{today_date}", task_id=<id>, owner="review-<name>", status="in_progress")
```

Each @staff-engineer teammate:

1. Reads the target skill file (e.g., `.claude/skills/<name>/SKILL.md` or `skills/<name>/SKILL.md`)
2. Reads the existing changelog in `docs/changelog/skills/<name>.md` (if it exists) to understand
   prior evolution history and avoid repeating prior improvements
3. Uses WebFetch if available to research Claude Code documentation; if not, proceeds with
   existing knowledge of Claude Code best practices
4. Checks `docs/spec/` for relevant project specifications (be selective — only files related
   to the skill's domain)
5. Reads the OTHER skill files to understand the current skill ecosystem
6. Evaluates the skill against ALL 8 dimensions
7. Applies improvements directly to the skill file
8. Writes/updates the changelog entry in `docs/changelog/skills/<name>.md`
9. Marks their task completed via `TaskUpdate` and reports back with:
   - Summary of changes made (or "no changes needed" with reasoning)
   - Whether a rename is recommended (and to what name, with reasoning)
   - Any cross-skill coherence issues noticed

Teammates go idle between turns — this is normal. Messages from teammates are delivered
automatically; no polling is needed. The orchestrator receives results as teammates complete.

Use `TaskList(team_name="evolve-skills-{today_date}")` to check overall Phase 1 progress.

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 teammates complete, spawn a single @staff-engineer teammate to handle
coherence and renames:

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")
```

Assign the Phase 2 task:

```
TaskUpdate(team_name="evolve-skills-{today_date}", task_id=<coherence_task_id>, owner="coherence-reviewer", status="in_progress")
```

The Phase 2 teammate:

1. Reads ALL skill files (the freshly improved versions)
2. Executes any renames recommended in Phase 1:
   - Rename the directory: `mv <old-dir> <new-dir>` (e.g., `mv skills/dev skills/new-name`)
   - Update the `name:` field in the renamed skill's YAML frontmatter
   - Search ALL files for references to the old name and update them:
     - Other skill files in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`
     - Agent files in `agents/*.md`
     - `README.md`
     - Any other files that reference the old name
   - Rename `docs/changelog/skills/<old>.md` to `docs/changelog/skills/<new>.md` (if it exists)
   - Add a rename entry to the changelog
3. Checks cross-skill coherence:
   - No scope overlaps — each skill has a distinct purpose
   - Terminology is consistent across all skills
   - Shared conventions are followed (commit notice, frontmatter format, changelog patterns)
   - References to agents, directories, and project structure are accurate
   - Spawning templates reference correct agent types
   - Argument handling patterns are consistent
4. Applies coherence fixes directly to affected skill files
5. Updates `docs/changelog/skills/<name>.md` for any skill that received coherence fixes
6. Marks the coherence task completed via `TaskUpdate` and reports:
   what coherence issues were found and fixed, what renames were executed

### Wrap-up & Team Cleanup

After Phase 2 completes:

1. **Shut down all teammates** — send shutdown requests:
   ```
   SendMessage(to="review-<name>", message={type: "shutdown_request"})
   SendMessage(to="coherence-reviewer", message={type: "shutdown_request"})
   ```
   Send one `SendMessage` per teammate that was spawned.

2. **Delete the team** to clean up resources:
   ```
   TeamDelete(team_name="evolve-skills-{today_date}")
   ```

3. List all files that were modified
4. Summarize the improvements made to each skill
5. Note any renames that occurred
6. Note any coherence fixes applied
7. Remind the user that NO changes have been committed — they can review with `git diff`

---

## Spawning Templates

### Phase 1: @staff-engineer (Review & Improve)

Spawn one teammate per target skill. Substitute `<name>`, `<skill-path>`, and `{today_date}`
(from pre-flight step 1) for each.

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to review and improve a skill definition:

Target: <skill-path>/SKILL.md
Skill: <name>

You are reviewing this skill definition to evolve it — making it more effective, actionable,
and well-structured for Claude Code execution.

## Context

- Today's date is {today_date} — use this for changelog entries.
- This is a self-evolving process. Each run should build on prior improvements.
- Read docs/changelog/skills/<name>.md (if it exists) to see what was improved before — do NOT
  repeat the same changes or re-tread ground already covered.
- Read docs/spec/ for project specification alignment (be selective — only files relevant to
  the skill's domain).
- Read the OTHER skill files to understand the skill ecosystem and conventions.
  Check both .claude/skills/*/SKILL.md and skills/*/SKILL.md.

## Your Task

Evaluate <skill-path>/SKILL.md against ALL of these dimensions:

1. **Skill Design Quality**: Does the skill follow Claude Code best practices? Clear trigger
   phrases, proper frontmatter, good argument handling, well-structured orchestration?

2. **Actionability**: Are instructions specific enough for Claude to execute reliably?
   Clear phases, concrete spawning templates, defined outputs, consistent results?

3. **Completeness**: Does the skill handle edge cases, error conditions, pre-flight checks?
   Are all workflow paths covered from start to wrap-up?

4. **Over-Engineering**: Verbose, redundant, or low-value sections to trim or consolidate?

5. **Orchestration Effectiveness**: Does the skill use agents effectively? Proper parallelism,
   correct agent types, clear prompts, well-structured coordination?

6. **Coherence with Other Skills**: Scope overlaps? Terminology consistency? Convention
   alignment? Accurate references?

7. **Spec Alignment**: Alignment with docs/spec/ project patterns and conventions?

8. **Rename Consideration**: Should this skill be renamed to better communicate its purpose?
   Only recommend if compelling — stability has value.

## Requirements

- Apply improvements directly to <skill-path>/SKILL.md
- Maintain the existing file structure and YAML frontmatter format
- Do NOT remove or weaken existing capabilities that are working well
- Build on strengths — improve, don't rewrite from scratch
- If no meaningful improvements are needed, report that honestly rather than forcing changes
- Write/update docs/changelog/skills/<name>.md with a dated entry documenting what changed
  and why (prepend the new entry below the H1 heading since the file exists)
- In your final output, report:
  - Summary of changes made (or "no changes needed" with reasoning)
  - Whether you recommend a rename (and to what name, with reasoning)
  - Any cross-skill coherence issues you noticed
- Do NOT commit any changes
```

### Phase 2: @staff-engineer (Coherence & Renames)

Substitute `{today_date}` (from pre-flight step 1) before spawning.

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to check cross-skill coherence and execute renames:

Today's date is {today_date} — use this for any changelog entries.

## Renames to Execute
<if renames were recommended, list each: "Rename <old-dir> -> <new-dir>">
<if no renames: "No renames were recommended.">

## Phase 1 Coherence Issues
<list any coherence issues reported by Phase 1 agents, or "None reported.">

## Requirements

1. Read ALL skill files in .claude/skills/*/SKILL.md and skills/*/SKILL.md

2. If renames are listed above, execute each one:
   - Run: mv <old-dir> <new-dir>
   - Update the `name:` field in the renamed skill's YAML frontmatter
   - Use Grep to find ALL references to the old name across the codebase
   - Update references in: .claude/skills/*/SKILL.md, skills/*/SKILL.md, agents/*.md,
     README.md, and any other files
   - Rename docs/changelog/skills/<old>.md -> docs/changelog/skills/<new>.md (if it exists)
   - Add a rename entry to the affected changelog

3. Check cross-skill coherence across ALL skill files:
   - No scope overlaps — each skill has a distinct, non-overlapping purpose
   - Terminology is consistent across all skills (same concepts use same words)
   - Shared conventions are followed (commit notice, frontmatter, changelog patterns)
   - References to agents, directories, and project structure are accurate
   - Spawning templates reference correct agent types and use consistent patterns
   - Argument handling patterns are consistent where appropriate

4. Apply coherence fixes directly to affected skill files

5. Update docs/changelog/skills/<name>.md for any skill that received coherence fixes

6. Report:
   - What renames were executed (directories renamed, references updated)
   - What coherence issues were found and fixed
   - Any remaining issues that could not be resolved automatically

- Do NOT commit any changes
```

---

## Rules

1. **Run pre-flight before spawning.** Validate skill files exist and arguments resolve before
   spending agent resources.
2. **Create the team before spawning teammates.** Use `TeamCreate` to set up the team and
   `TaskCreate` to define tasks before spawning any teammates with the `Agent` tool.
3. **Spawn Phase 1 teammates in parallel.** Maximum parallelism for independent reviews.
   Use `team_name` and `name` parameters when spawning via the `Agent` tool.
4. **Phase 2 runs AFTER all Phase 1 teammates complete.** Coherence requires seeing all
   changes. Use `TaskList` to verify all Phase 1 tasks are completed before proceeding.
5. **Always run Phase 2.** Even for single-skill improvements — coherence matters.
6. **Never edit skill files yourself.** You are the orchestrator, not the author.
7. **Never commit.** No `git add`, no `git commit`, no `git push`.
8. **Respect existing quality.** Improvements build on what works, not rewrite from scratch.
9. **Changelog is mandatory.** Every evolution cycle must be documented with reasoning.
10. **Fail loud.** If a teammate fails, report it immediately with details.
11. **Clean up the team.** After wrap-up, send `shutdown_request` messages to all teammates
    via `SendMessage` and delete the team with `TeamDelete`. Do not leave orphaned teams.
