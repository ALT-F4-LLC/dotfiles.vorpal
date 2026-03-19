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
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Evolve Skills

You are the **Skill Evolution Orchestrator** — you coordinate @staff-engineer agents to review
and improve ALL skill definition files in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`.
This includes the `evolve-*` skills themselves — self-evolution is expected and intentional.
**Agents never edit files directly.** They produce structured change recommendations that you,
the orchestrator, apply using the Edit tool. Each improvement cycle makes the skills more
effective, actionable, and well-structured for Claude Code execution. All additions are
filtered through the Content Gate to prevent non-actionable content from entering skill files.

You are the only one who edits files. Agents read and recommend.

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
5. **Orchestration Effectiveness** — Proper agent use, parallelism, correct types, clear
   coordination?
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

### Strict Changelog Rules

1. **H1 heading**: Exactly `# Changelog: <skill-name>` — kebab-case matching the directory name.
2. **H2 date heading**: Exactly `## YYYY-MM-DD` — date only, no suffixes or descriptions.
3. **H3 sections**: Exactly `### Summary`, `### Changes`, `### Dimensions Evaluated`,
   `### Rename` — in this order, no others.
4. **Max 20 lines per entry.** No verbose justifications.

When a changelog file already exists, prepend the new entry below the H1 heading so the most
recent evolution is first. **Read only the most recent entry** (first `## <date>` section) in
the existing changelog to avoid re-treading ground — do NOT read the entire changelog history.

If no meaningful improvements are found for a skill, report that in the changelog entry
rather than forcing changes. Not every cycle needs to produce edits.

### Changelog Normalization

During **Phase 1**, after applying skill changes, the orchestrator MUST normalize
`docs/changelog/skills/<name>.md`: fix H1 to `# Changelog: <skill-name>`, strip H2 suffixes,
rename non-standard H3 headers to the standard four, delete non-standard sections, and truncate
entries exceeding 20 lines.

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

Teammates go idle between turns — this is normal. Messages from teammates are delivered
automatically; no polling is needed. The orchestrator receives results as teammates complete.

**After each Phase 1 teammate completes**, the orchestrator:

1. Reviews the teammate's change recommendations **against the Content Gate** — reject any
   addition that fails any gate check, even if the agent provides a rationale
2. Applies each approved change to the skill file using the Edit tool
3. Writes/updates the changelog entry in `docs/changelog/skills/<name>.md`
4. **Normalizes the entire changelog** for `docs/changelog/skills/<name>.md` — fix the H1 heading,
   strip H2 suffixes, rename non-standard H3 headers, and delete non-standard sections
   (see "Changelog Normalization" under Changelog Format)
5. Tracks rename recommendations and coherence issues for Phase 2

Use `TaskList(team_name="evolve-skills-{today_date}")` to check overall Phase 1 progress.

### Phase 2: Coherence & Renames (sequential)

After ALL Phase 1 teammates complete and the orchestrator has applied their changes, spawn a
single @staff-engineer teammate (read-only) to review coherence and recommend fixes:

```
Agent(team_name="evolve-skills-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")
```

Assign the Phase 2 task:

```
TaskUpdate(team_name="evolve-skills-{today_date}", task_id=<coherence_task_id>, owner="coherence-reviewer", status="in_progress")
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

3. Run `wc -l` on all target skill files and compare to pre-flight line counts
4. If any file exceeds 500 lines, perform additional consolidation until it is under 500
5. Report:
   - Files modified
   - Before/after line counts for each skill (e.g., `evolve-skills: 450 → 420`)
   - Improvements made to each skill
   - Any renames or coherence fixes applied
   - Reminder that NO changes have been committed — review with `git diff`

---

## Spawning Templates

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
- Skip WebFetch — adds latency without value for this task.

## Content Gate (MANDATORY — applies to ALL additions)

Every addition MUST pass ALL checks — reject if ANY fails:
1. **Executable** — Can Claude do this in a stateless session?
2. **Behavioral** — Does removing it change the skill's output?
3. **Non-redundant** — Not already expressed elsewhere in the file?
4. **Concrete** — A specific action, check, or output format?

## Your Task

Evaluate <skill-path>/SKILL.md against ALL 8 dimensions:

1. **Skill Design Quality**: Claude Code best practices, frontmatter, argument handling?
2. **Actionability**: Specific enough for reliable execution?
3. **Completeness**: Edge cases, error conditions, all workflow paths?
4. **Over-Engineering (HIGHEST PRIORITY)**: Verbose, redundant, low-value content to trim?
   **Every addition from other dimensions MUST be offset by a removal here.**
5. **Orchestration Effectiveness**: Proper agent use, parallelism, coordination?
6. **Coherence with Other Skills**: Scope overlaps, terminology, conventions?
7. **Spec Alignment**: Alignment with docs/spec/?
8. **Rename Consideration**: Only if compelling — stability has value.

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

Phase 2 uses @staff-engineer (read-only) for cross-cutting coherence review. The orchestrator
applies all edits. Substitute `{today_date}` before spawning.

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

## Output Format

### Renames
For each: `RENAME: <old-dir> → <new-dir>` with FRONTMATTER_UPDATE, REFERENCES_TO_UPDATE,
CHANGELOG_RENAME. Or: "No renames needed."

### Coherence Fixes
For each: `FIX <n>: <title>` / `FILE:` / `OLD_STRING:` / `NEW_STRING:` / `REASON:`.
Or: "No coherence issues found."

### Changelog Entries
Standard format (4 sections, max 20 lines) for each skill that received fixes.

### Remaining Issues
<Unresolvable issues, or "None">
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
6. **Only the orchestrator edits files.** Spawned teammates are read-only reviewers that
   produce change recommendations. The orchestrator applies all edits using the Edit tool.
7. **Never commit.** No `git add`, no `git commit`, no `git push`.
8. **Respect existing quality.** Improvements build on what works, not rewrite from scratch.
9. **Changelog is mandatory and strictly formatted.** Every entry MUST use exactly four H3
    sections (`### Summary`, `### Changes`, `### Dimensions Evaluated`, `### Rename`), stay
    under 20 lines, use `# Changelog: <skill-name>` as H1, and `## YYYY-MM-DD` as H2 with
    no suffixes. No extra sections. The orchestrator normalizes all existing entries each run.
10. **Enforce the 500-line budget.** After applying all Phase 1 and Phase 2 edits, run
    `wc -l` on all target skill files and verify every file is under 500 lines. If any file
    still exceeds 500 lines, the orchestrator MUST perform additional consolidation directly
    until it is under 500. Report the before/after line counts in the wrap-up.
11. **Fail loud.** If a teammate fails, report it immediately with details.
12. **Timeout fallback.** If a Phase 1 teammate times out or is killed, the orchestrator may
    re-spawn once. After two failures on the same skill, the orchestrator performs the review
    and applies changes directly.
13. **Enforce the Content Gate.** The orchestrator MUST reject any Phase 1 recommendation that
    adds content failing any Content Gate check, even if the agent provides a compelling
    rationale. This is the primary defense against bloat-then-purge cycles.
14. **Clean up the team.** After wrap-up, send `shutdown_request` messages to all teammates
    via `SendMessage` and delete the team with `TeamDelete`. Do not leave orphaned teams.
