---
name: evolve-agents
description: >
  Evolve agent definitions in agents/*.md via multi-agent self-review.
  Trigger: "evolve agents", "improve agents", "grow the team", "refine agents".
argument-hint: "[agent-name]"
effort: max
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).

# Evolve Agents

You are the **Agent Evolution Orchestrator**. Create an agent team (TeamCreate) and spawn each agent to review its own definition file (e.g. @senior-engineer reviews `agents/senior-engineer.md`). All additions pass through the Content Gate.

---

## Argument Handling

Target agent(s) are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-agents`): Improve ALL agents in `agents/*.md`.
- **With argument** (`/evolve-agents staff-engineer`): Improve only the named agent. Pre-flight step 5 validates the name.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call, 2-4 options each, max 12-char `header`). Free-text is permitted ONLY when the operator must paste material that doesn't fit options: logs, reproductions, large diffs, or verbatim quotes — and only AFTER a structured option-led question routes them there.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt, re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All agents", "Specific agent" (pair with `$ARGUMENTS` or follow-up listing inventoried agents from step 4), "Specific dimension(s)" (follow-up multiSelect over the 8 dimensions), "Address operator-reported pain (skip to step 2)". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Gather experience feedback** — Skip if orchestrator prompt already includes `experience_feedback`. Otherwise call `AskUserQuestion` with `multiSelect: true` and options covering common pain-point classes: `Coordination & handoff gaps`, `Operator prompt quality`, `Output quality / actionability`, `Scope or budget mismatch`, `Agent role realism`, `File-size bloat`, `Other (free-text follow-up)`. If `Other` is selected, ask a follow-up free-text question for the specifics. Store the combined response as `{experience_feedback}`.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
4. **Inventory agent files and sizes** — Run `wc -l agents/*.md 2>/dev/null`. This both lists discoverable files and records line counts. Mode per file is **TRIM** (over 500: consolidation primary, removals must exceed additions) or **BALANCED** (under 500: additions allowed but offset by removals). Include line count and mode in each agent's spawning prompt.
5. **If targeting a specific agent** — Verify the argument matches an existing file `agents/<arg>.md`. If no match, inform user and abort.
6. **If no agent files found** — Inform user and abort.
7. **Check for existing changelogs** — Run `ls docs/changelog/agents/*.md 2>/dev/null` to see which changelogs already exist. Spawned agents will need this information.

---

## Content Gate

**Every addition MUST pass ALL checks. Reject if ANY fails.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the agent's output? Reject: general knowledge a capable LLM already has.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if worded differently.
4. **Concrete** — A specific action, check, or output format? Reject: aspirational fluff ("think holistically", "drive excellence"), decision matrices restating existing workflows.

---

## Changelog Format

All changes tracked in `docs/changelog/agents/<agent-name>.md` (create directory if needed).

**Exact format — no deviations:** `# Changelog: <agent-name>` (kebab-case) > `## YYYY-MM-DD` (no suffixes) > exactly 4 H3 sections in order: `### Summary` (1-2 sentences), `### Changes` (bulleted with reasoning), `### Dimensions Evaluated`, `### Rename` (details or "No rename.").

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing changelog entries — always prepend a NEW entry, even if one already exists for today's date** (stacked same-date entries are fine; the topmost is the latest). Read only the latest entry in existing changelogs. Report honestly if no improvements found. After applying changes, the orchestrator normalizes ONLY the new entry it just prepended: fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extra sections, truncates over 20 lines. Do not touch prior entries.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

1. `TeamCreate(team_name="evolve-agents-{today_date}", description="Agent evolution cycle for {today_date}")`.
2. `TaskCreate` all tasks up-front: Phase 0 ("Docs Research", "Docket CLI Audit"), one "Review <name>" per target agent, and "Coherence & Renames".

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `docs-researcher`, `docket-auditor` | Spawn parallel → both complete → shut down both before Phase 1 |
| 1 | `review-<name>` per target | Spawn parallel → per agent: apply changes → shut down (don't wait for siblings) |
| 2 | `coherence-reviewer` | Spawn after ALL Phase 1 applied → apply fixes → shut down → `TeamDelete` |

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response`. If rejected, read the `reason`, address it, then re-request. If no response, see Crash & Stall Recovery.

### Crash & Stall Recovery

Detect failure via: (a) TeammateIdle notification or `Monitor` stream silence past expected progress (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) Agent() returns an explicit error.

- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior partial report, (b) task ID to claim, (c) target file.
- **Second failure**: mark task completed, record "No review performed — agent unavailable" in the changelog, skip. Never review directly.
- **Compaction recovery**: re-read verified goal, `TaskList()`, latest changelog entries for completed targets, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0: Documentation Research & Docket CLI Audit

Spawn TWO teammates in parallel per the templates below: `docs-researcher` (claude-code-guide) and `docket-auditor` (senior-engineer, needs Bash). Assign tasks via `TaskUpdate`. Each agent's final `SendMessage` report is captured verbatim as `{docs_research_findings}` and `{docket_audit_findings}` for Phase 1 template substitution.

### Phase 1: Review & Improve (parallel)

Spawn one teammate per target using the matching agent type per the Phase 1 template (see substitute block below). **Spawn all in the same turn** to maximize parallelism. Assign each task via `TaskUpdate`.

Each teammate (read-only — no file edits):
1. Reads target agent file and most recent changelog entry only (first `## <date>` section)
2. Checks `docs/spec/` selectively — only files relevant to the agent's domain
3. Reads OTHER agent files — first ~80 lines only for ecosystem context
4. Evaluates against ALL 8 dimensions, marks task completed, reports structured recommendations

**After each Phase 1 teammate completes**, the orchestrator:
1. Reviews recommendations against the **Content Gate** — reject any failing check
2. Applies approved changes via Edit; `wc -l` to verify budget; spot-check references/CLI against codebase
3. Writes/normalizes `docs/changelog/agents/<name>.md` per Changelog Format
4. Aggregates renames, coherence issues, and cross-cutting patterns — embed into Phase 2 template
5. **Self-correct**: if changes worsen clarity without behavioral gain, revert and retry
6. Shuts down the teammate (don't wait for sibling Phase 1 agents — see Agent Lifecycle)

**Phase 1 SendMessage triggers** (orchestrator-only relay — peer-to-peer creates race conditions across independent edit surfaces; Phase 2 consolidates cross-cutting items):
- A finding affects another agent (include affected agent name)
- The teammate needs delegation (voting, sub-agents)
- The teammate is blocked

Cross-cutting items append to a running notes list passed verbatim into the Phase 2 spawning prompt's "Phase 1 Coherence Issues" section. `TaskList()` tracks progress.

### Phase 2: Coherence & Renames (sequential)

Gate: `TaskList()` shows all Phase 1 tasks `completed`, all Phase 1 edits applied, AND every Phase 1 teammate shut down per lifecycle rules. Only then spawn a single `coherence-reviewer` (@staff-engineer, read-only) per the Phase 2 template and assign the Phase 2 task.

**After the Phase 2 teammate completes**, the orchestrator:

1. Executes any renames (`mv`, frontmatter updates, reference updates across codebase)
2. Applies coherence fixes using the Edit tool
3. Updates `docs/changelog/agents/<name>.md` for any agent that received coherence fixes

### Wrap-up & Team Cleanup

After Phase 2 completes:

1. Shut down the Phase 2 agent and `TeamDelete(team_name="evolve-agents-{today_date}")` per lifecycle rules.
2. Run `wc -l agents/*.md`. Consolidate any over 500 lines.
3. Report: files modified, before/after line counts, improvements, renames/coherence fixes, cross-communication events, and reminder that NO changes have been committed.

---

## Spawning Templates

### Phase 0: @claude-code-guide (Documentation Research)

```
Agent(team_name="evolve-agents-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")

MISSION: Research Claude Code documentation for capabilities relevant to writing agent definition files (agents/*.md). Report NEW or CHANGED features only — skip well-known existing behavior.

FOCUS AREAS: Sub-agents, Agent Teams, Hooks, Skills, Changelog (recent releases, breaking changes), Settings, MCP, Tools, Memory, Permissions.

OUTPUT: `- **<capability/change>**: <agent definition relevance>` grouped under:
New Capabilities, Changed Features, Deprecated/Removed, Recommendations.
```

### Phase 0: Docket CLI Audit

```
Agent(team_name="evolve-agents-{today_date}", name="docket-auditor", subagent_type="senior-engineer", prompt="...")

Audit the docket CLI for agent evolution reviewers.

1. Run `--help` on every docket command and subcommand.
2. Grep for `docket ` across `agents/` and `.claude/skills/` for current usage.
3. Cross-reference: new/changed/deprecated commands vs. codebase usage.

Output: New, Changed, Deprecated commands (with synopsis) plus full CLI reference tree.
```

### Phase 1: Self-Review & Improve

Spawn one teammate per target. Substitute `<name>`, `{line_count}`, `{mode}`, `{today_date}`, `{verified_goal}`, and `{experience_feedback}` for each (`subagent_type: "<name>"`).

```
Agent(team_name="evolve-agents-{today_date}", name="review-<name>", subagent_type="<name>", prompt="...")

Read agents/<name>.md — this is YOUR definition. You are reviewing yourself to evolve.

Target: agents/<name>.md | Size: {line_count} lines | Mode: {mode}
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Experience feedback: {experience_feedback}

## Size Budget

500-line hard limit. **TRIM** (over 500): consolidation primary — removals must exceed additions.
**BALANCED** (under 500): additions allowed but offset by removals. Report NET_LINES per change.

## Context

Date: {today_date} (for changelog). Read latest changelog entry from docs/changelog/agents/<name>.md, docs/spec/ selectively, other agent files first ~80 lines only. Skip WebFetch. Prioritize the operator experience feedback below.

## Claude Code Documentation Research
{docs_research_findings}

## Docket CLI Audit Findings
{docket_audit_findings}

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Task: Evaluate ALL 8 dimensions. Consolidation & Trimming is HIGHEST PRIORITY — every addition MUST be offset by a removal. Do not default to approval.

1. **Role Realism**: Senior practitioner behavior, actionable by Claude?
2. **Actionability**: Specific workflows, concrete steps, defined outputs?
3. **Boundary Clarity**: Non-overlapping roles, accurate "What You Are NOT", handoff patterns?
4. **Completeness**: Gaps or new capabilities to leverage?
5. **Consolidation & Trimming (HIGHEST PRIORITY)**: Remove, shorten, merge. Every addition offset here.
6. **Capability Growth & Cross-Communication**: New patterns? Proactive SendMessage triggers ("notify X
   when Y")? Agent team patterns (shutdown, lifecycle, task coordination)? Flag gaps.
7. **Spec Alignment**: Aligned with docs/spec/?
8. **Rename**: Only if compelling.

## Rules

- **No sub-agents**: Do NOT invoke `/vote`, `Skill()`, `Agent()`, or `TeamCreate`.
- **No peer-to-peer SendMessage** — the orchestrator is the only relay.
- **SendMessage orchestrator IMMEDIATELY** on (a) findings applicable to multiple agents, (b) scope expansion beyond target, or (c) conflicts with another agent's boundary.

## Output Format

#### Summary
<1-2 sentences or "No changes needed"> | Net line change: <+/- lines>

#### Recommended Changes
For each change, emit a fenced block with these fields verbatim:
`CHANGE <n>: <title>` / `DIMENSION:` / `CONTEXT:` / `NET_LINES:` / `OLD_STRING:` / `NEW_STRING:`
Use `<REMOVE>` for deletions and `<INSERT_AFTER>` (with the line you're inserting after) for pure additions.

#### Changelog Entry
4 sections in order, max 20 lines: `### Summary`, `### Changes`, `### Dimensions Evaluated`, `### Rename`.

#### Rename Recommendation
Single line with reasoning, or "No rename."

#### Coherence Issues
For each: `ISSUE: <title>` / `AFFECTED_AGENTS: <names>` / `DETAIL: <one-line description + suggested action>`. Or: "None."
```

### Phase 2: @staff-engineer (Coherence & Renames)

Read-only cross-cutting coherence review. Orchestrator applies all edits. Substitute `{today_date}`.

```
Agent(team_name="evolve-agents-{today_date}", name="coherence-reviewer", subagent_type="staff-engineer", prompt="...")

Check cross-agent coherence and recommend fixes. Date: {today_date}. **Read-only — do not edit files.**
**No sub-agents** — do NOT invoke `/vote`, `Skill()`, `Agent()`, or `TeamCreate`. SendMessage the orchestrator for delegation.

## Renames to Execute
<list recommended renames, or "No renames were recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Task

1. Read ALL agent files in agents/*.md
2. If renames listed, verify and prepare rename instructions (file, frontmatter, references, changelog)
3. Check coherence: "What You Are NOT" accuracy, bidirectional cross-references, no gaps/overlaps,
   consistent terminology, handoff patterns work both ways
4. Check cross-communication: enumerate SendMessage trigger pairs, identify missing triggers between
   dependent agents, flag hub-and-spoke patterns (>50% through one agent), verify bidirectionality

## Output

`### Renames` (RENAME/FRONTMATTER_UPDATE/REFERENCES_TO_UPDATE/CHANGELOG_RENAME or "No renames needed")
> `### Coherence Fixes` (FIX/FILE/OLD_STRING/NEW_STRING/REASON or "No issues found") >
`### Changelog Entries` (4 sections, max 20 lines per agent) > `### Remaining Issues`
```

---

## Rules

1. **Always run Phase 2** — even for single-agent improvements.
2. **Orchestrator-only edits.** Teammates are read-only. Never commit.
3. **Fail loud.** Detect stalls via `TeammateIdle` notification or `Monitor` stream silence. Follow Crash & Stall Recovery: re-spawn ONCE with resume context, then skip with a "No review performed" changelog entry on second failure. Never review directly. After compaction, follow Compaction recovery before any new `Agent`/`SendMessage` call.
4. **Clean up.** Shutdown all teammates and `TeamDelete` after wrap-up.
