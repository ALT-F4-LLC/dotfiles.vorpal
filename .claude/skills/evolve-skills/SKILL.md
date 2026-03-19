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
disable-model-invocation: true
argument-hint: "[skill-name]"
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Evolve Skills

You are the **Skill Evolution Orchestrator** — you coordinate @staff-engineer agents to review
and improve skill definition files in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`. Each
improvement cycle makes the skills more effective, actionable, and well-structured for Claude
Code execution.

You do not edit skill files yourself. You coordinate.

---

## Argument Handling

Target skill(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills found in `.claude/skills/*/SKILL.md`
  and `skills/*/SKILL.md`.
- **With argument** (`/evolve-skills dev-team`): Improve only the named skill.

Resolve targets by listing what exists:

```bash
ls .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null
```

If an argument is provided and no matching skill directory exists, inform the user and abort.

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

All changes are tracked in `docs/changelog/<skill-name>-skill.md`. Create the `docs/changelog/`
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

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer per target skill. **Spawn all agents in the same turn** to maximize
parallelism. If targeting a single skill, spawn one.

Each @staff-engineer:

1. Reads the target skill file (e.g., `.claude/skills/<name>/SKILL.md` or `skills/<name>/SKILL.md`)
2. Reads the existing changelog in `docs/changelog/<name>-skill.md` (if it exists) to understand
   prior evolution history and avoid repeating prior improvements
3. Checks `docs/spec/` for relevant project specifications
4. Reads the OTHER skill files to understand the current skill ecosystem
5. Evaluates the skill against ALL 8 dimensions
6. Applies improvements directly to the skill file
7. Writes/updates the changelog entry in `docs/changelog/<name>-skill.md`
8. Reports back with:
   - Summary of changes made (or "no changes needed" with reasoning)
   - Whether a rename is recommended (and to what name, with reasoning)
   - Any cross-skill coherence issues noticed

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 agents complete, spawn a single @staff-engineer to:

1. Read ALL skill files (the freshly improved versions)
2. Execute any renames recommended in Phase 1:
   - Rename the directory: `mv <old-dir> <new-dir>` (e.g., `mv skills/dev-team skills/new-name`)
   - Update the `name:` field in the renamed skill's YAML frontmatter
   - Search ALL files for references to the old name and update them:
     - Other skill files in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`
     - Agent files in `agents/*.md`
     - `README.md`
     - Any other files that reference the old name
   - Rename `docs/changelog/<old>-skill.md` to `docs/changelog/<new>-skill.md` (if it exists)
   - Add a rename entry to the changelog
3. Check cross-skill coherence:
   - No scope overlaps — each skill has a distinct purpose
   - Terminology is consistent across all skills
   - Shared conventions are followed (commit notice, frontmatter format, changelog patterns)
   - References to agents, directories, and project structure are accurate
   - Spawning templates reference correct agent types
   - Argument handling patterns are consistent
4. Apply coherence fixes directly to affected skill files
5. Update `docs/changelog/<name>-skill.md` for any skill that received coherence fixes
6. Report: what coherence issues were found and fixed, what renames were executed

### Wrap-up

After Phase 2 completes:

- List all files that were modified
- Summarize the improvements made to each skill
- Note any renames that occurred
- Note any coherence fixes applied
- Remind the user that NO changes have been committed — they can review with `git diff`

---

## Spawning Templates

### Phase 1: @staff-engineer (Review & Improve)

Spawn one of these per target skill. Customize `<name>` and `<skill-path>` for each.

```
Use the @staff-engineer agent to review and improve a skill definition:

Target: <skill-path>/SKILL.md
Skill: <name>

You are reviewing this skill definition to evolve it — making it more effective, actionable,
and well-structured for Claude Code execution.

## Context

- This is a self-evolving process. Each run should build on prior improvements.
- Read docs/changelog/<name>-skill.md (if it exists) to see what was improved before — do NOT
  repeat the same changes or re-tread ground already covered.
- Read docs/spec/ for project specification alignment (be selective — only relevant files).
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
- Write/update docs/changelog/<name>-skill.md with a dated entry documenting what changed
  and why (create docs/changelog/ directory if needed; if the changelog file exists, prepend
  the new entry below the H1 heading)
- In your final output, report:
  - Summary of changes made (or "no changes needed" with reasoning)
  - Whether you recommend a rename (and to what name, with reasoning)
  - Any cross-skill coherence issues you noticed
- Do NOT commit any changes
```

### Phase 2: @staff-engineer (Coherence & Renames)

```
Use the @staff-engineer agent to check cross-skill coherence and execute renames:

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
   - Rename docs/changelog/<old>-skill.md -> docs/changelog/<new>-skill.md (if it exists)
   - Add a rename entry to the affected changelog

3. Check cross-skill coherence across ALL skill files:
   - No scope overlaps — each skill has a distinct, non-overlapping purpose
   - Terminology is consistent across all skills (same concepts use same words)
   - Shared conventions are followed (commit notice, frontmatter, changelog patterns)
   - References to agents, directories, and project structure are accurate
   - Spawning templates reference correct agent types and use consistent patterns
   - Argument handling patterns are consistent where appropriate

4. Apply coherence fixes directly to affected skill files

5. Update docs/changelog/<name>-skill.md for any skill that received coherence fixes

6. Report:
   - What renames were executed (directories renamed, references updated)
   - What coherence issues were found and fixed
   - Any remaining issues that could not be resolved automatically

- Do NOT commit any changes
```

---

## Rules

1. **Spawn Phase 1 agents in parallel.** Maximum parallelism for independent reviews.
2. **Phase 2 runs AFTER all Phase 1 agents complete.** Coherence requires seeing all changes.
3. **Always run Phase 2.** Even for single-skill improvements — coherence matters.
4. **Never edit skill files yourself.** You are the orchestrator, not the author.
5. **Never commit.** No `git add`, no `git commit`, no `git push`.
6. **Respect existing quality.** Improvements build on what works, not rewrite from scratch.
7. **Changelog is mandatory.** Every evolution cycle must be documented with reasoning.
8. **Fail loud.** If an agent fails, report it immediately with details.
