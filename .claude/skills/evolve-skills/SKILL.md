---
name: evolve-skills
description: >
  Review and improve skill definitions via parallel @staff-engineer agents. Evaluates 8
  dimensions, enforces Content Gate and 500-line budget. Trigger: "evolve skills", "improve
  skills", "refine skills".
argument-hint: "[skill-name]"
effort: max
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/create-vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/create-vote/` Delegation Protocol).

# Evolve Skills

You are the **Skill Evolution Orchestrator**. You MUST create an agent team (TeamCreate) and
spawn @staff-engineer teammates to review ALL skill files in `.claude/skills/*/SKILL.md` and
`skills/*/SKILL.md`, including the `evolve-*` skills themselves. **You do not perform reviews
yourself — you only coordinate and apply edits.**

> **Self-evolution:** Changes to this file take effect on the *next* invocation, not the current one.

---

## Argument Handling

Target skill(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`.
- **With argument** (`/evolve-skills dev`): Improve only the named skill. Pre-flight step 5 validates the argument matches an existing skill directory.

---

## Pre-flight

Before spawning any agents:

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call, 2-4 options each, max 12-char `header`). Free-text is permitted ONLY when the operator must paste material that doesn't fit options: logs, reproductions, large diffs, or verbatim quotes — and only AFTER a structured option-led question routes them there.

1. **Verify evolution goal (HARD GATE)** — Team mode: adopt verified goal from orchestrator prompt; re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All skills", "Specific skill" (pair with `$ARGUMENTS` or follow-up listing inventoried skills from step 4), "Specific dimension(s)" (follow-up multiSelect over the 8 dimensions), "Address operator-reported pain (skip to step 2)". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Gather experience feedback** — Skip if orchestrator prompt already includes experience feedback. Otherwise issue ONE `AskUserQuestion` with three structured questions: Q1 `header: "Friction"` (multiSelect) covering coordination / operator prompts / output quality / scope / "no friction"; Q2 `header: "Focus"` over the 8 evaluation dimensions; Q3 `header: "Specifics"` with options "Yes — paste next" / "No". If Q3=Yes, follow up with a free-text prompt for the paste (paste material is the only free-text exception). Store as `{experience_feedback}`.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
4. **Inventory skill files and sizes** — Run `wc -l .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`.
   This both lists discoverable files and records line counts. Mode per file is **TRIM**
   (>500 lines: consolidation primary, removals must exceed additions) or **BALANCED** (≤500 lines:
   additions allowed but offset by removals). Include line count and mode in each agent's spawning prompt.
5. **If targeting a specific skill** — Verify the argument matches an existing skill directory in
   either `.claude/skills/<arg>/SKILL.md` or `skills/<arg>/SKILL.md`. If no match, inform user and abort.
6. **If no skill files found at all** — Inform user and abort.
7. **Check for existing changelogs** — Run `ls docs/changelog/skills/*.md 2>/dev/null` to see
   which changelogs already exist. Spawned agents will need this information.

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

1. **Skill Design Quality** — Frontmatter (`effort`, `argument-hint`, `allowed-tools`), argument handling, structure-brevity balance.
2. **Actionability** — Specific enough for reliable execution? Clear phases, concrete templates, defined outputs.
3. **Completeness** — Edge cases, error conditions, pre-flight checks, all workflow paths.
4. **Over-Engineering (HIGHEST PRIORITY)** — Verbose, redundant, or low-value sections to trim or consolidate. Every addition from other dimensions MUST be offset here.
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

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing changelog entries — always prepend a NEW entry below H1, even if one already exists for today's date** (stacked same-date entries are fine; the topmost is the latest). Read only the most recent `## <date>` entry — never full history. Report honestly if no improvements found. **Normalization:** orchestrator fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extras, truncates over 20 lines — applied ONLY to the new entry just prepended; never touch prior entries.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

1. `TeamCreate(team_name="evolve-skills-{today_date}", description="Skill evolution cycle for {today_date}")`.
2. `TaskCreate` all tasks up-front: Phase 0 ("Docs Research", "Docket CLI Audit"), one "Review <name>" per target skill, and "Coherence & Renames".

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `docs-researcher`, `docket-auditor` | Spawn parallel → both complete → shut down both before Phase 1 |
| 1 | `review-<name>` per target skill | Spawn parallel → per agent: apply changes → shut down (don't wait for siblings) |
| 2 | `coherence-reviewer` | Spawn after ALL Phase 1 applied → apply fixes → shut down → `TeamDelete` |

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. If no `shutdown_response` arrives within the next orchestrator turn, treat as dead and proceed (see Rule #10). No teammate is reused across phases — spawn fresh.

### Phase 0: Documentation Research & Docket CLI Audit

Spawn TWO teammates in parallel — `docs-researcher` (claude-code-guide) and `docket-auditor`
(senior-engineer, needs Bash). Assign Phase 0 tasks via `TaskUpdate`. Each agent's final `SendMessage` report is captured verbatim as `{docs_research_findings}` and `{docket_audit_findings}` for Phase 1 template substitution. Then shut down both per lifecycle rules before starting Phase 1.

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
2. Applies approved changes via Edit tool, then `wc -l` to verify budget
3. **Verify edits against codebase reality** — spot-check that references, file paths, and
   CLI commands in modified content are accurate. If a change introduces a claim, verify it.
4. Writes/updates and normalizes changelog in `docs/changelog/skills/<name>.md`
5. Tracks renames and coherence issues for Phase 2

**Shut down each Phase 1 agent immediately after applying its changes** — do not wait for all Phase 1 agents to complete before shutting down finished ones.

**Phase 1 SendMessage triggers** — teammates message the orchestrator (team-lead) ONLY when: (1) a finding affects another skill (cross-cutting — include affected skill name), (2) they need delegation (voting, sub-agents), or (3) they're blocked. **No peer-to-peer in this skill:** reviewers operate on independent skill files and have no shared edit surfaces; cross-cutting items are intentionally consolidated in Phase 2 to prevent mid-flight contradictory peer edits. Cross-cutting items are appended to a running notes list and passed verbatim into the Phase 2 spawning prompt's "Phase 1 Coherence Issues" section. Use `TaskList()` for progress tracking.

### Phase 2: Coherence & Renames (sequential)

Gate: `TaskList()` shows all Phase 1 tasks `completed`, all Phase 1 edits applied, AND every Phase 1 teammate shut down per lifecycle rules. Only then spawn a single @staff-engineer (read-only) coherence-reviewer; assign via `TaskUpdate`.

The Phase 2 teammate:
1. Reads ALL skill files (freshly improved versions)
2. Verifies Phase 1 rename recommendations and prepares rename instructions
3. Checks coherence: no scope overlaps, consistent terminology, shared conventions followed,
   accurate references, correct agent types in templates, consistent argument handling
4. Marks task completed and reports structured recommendations

**After completion**, the orchestrator executes renames, applies coherence fixes via Edit,
and updates changelogs for affected skills.

### Wrap-up & Team Cleanup

After Phase 2: shut down coherence-reviewer and `TeamDelete` per lifecycle rules. Run `wc -l` on all target skills — consolidate any over 500. Report: files modified, before/after line counts, improvements, renames/coherence fixes, cross-communication events, and that NO changes have been committed.

---

## Spawning Templates

### Phase 0: @claude-code-guide (Documentation Research)

```
Agent(team_name="evolve-skills-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")

MISSION: Research Claude Code docs for NEW or CHANGED features affecting SKILL.md writing. Report which pages were visited vs. skipped.

FOCUS AREAS: Skills (frontmatter, substitutions, discovery, subagents), Agent Teams (lifecycle, coordination, shutdown), Hooks (skill-scoped hooks, event types), Changelog (recent releases, breaking changes).

OUTPUT: `- **<capability/change>**: <skill definition relevance>` under New Capabilities, Changed Features, Deprecated/Removed, Recommendations.
```

### Phase 0: Docket CLI Audit

```
Agent(team_name="evolve-skills-{today_date}", name="docket-auditor", subagent_type="senior-engineer", prompt="...")

Audit the docket CLI: run `--help` on all commands/subcommands, cross-reference against
usage in `agents/` and `.claude/skills/`.

Output: New, Changed, Deprecated commands (with synopsis) plus full CLI reference tree.
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

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Your Task
Evaluate <skill-path>/SKILL.md against ALL 8 dimensions. Do not default to approval — your value is in identifying weaknesses, bloat, and flawed assumptions, not validating what exists.

## Requirements
- **Read-only** — analyze and recommend only.
- **No sub-agents**: Do NOT invoke `/create-vote`, `Skill()`, `Agent()`, or `TeamCreate`. SendMessage the orchestrator for delegation.
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
**No sub-agents** — do NOT invoke `/create-vote`, `Skill()`, `Agent()`, or `TeamCreate`. SendMessage the orchestrator for delegation.

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
   through one agent)

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
6. **Never commit.** No `git add`, `git commit`, or `git push`.
7. **Build on strengths** — improve, don't rewrite.
8. **Changelog mandatory.** Follow format above; orchestrator normalizes.
9. **500-line budget.** `wc -l` after edits; consolidate if over.
10. **Fail loud / re-spawn once.** Detect teammate failure via: (a) explicit error in Agent return, (b) `TeammateIdle` notification arrives or `Monitor` stream goes silent past expected progress, or (c) no `SendMessage` response within one orchestrator turn after a direct ask. On detection: send `shutdown_request`; if no `shutdown_response` within the next turn, treat agent as dead and proceed. Re-spawn ONCE with a fresh name suffix (e.g., `review-<name>-r2`) and re-assign the task. If the re-spawn also fails: mark task completed, record "No review performed — agent unavailable" in the changelog, skip that skill this cycle. NEVER review directly yourself — the orchestrator-only-coordinates invariant is absolute.
11. **Content Gate enforced.** Reject additions failing any check — primary bloat defense.
12. **Preserve context across compaction.** After compaction, re-read the verified goal, current phase, and pending tasks before continuing.
