---
name: evolve-skills
description: >
  Review and improve skill definitions via parallel @staff-engineer agents. Evaluates 8
  dimensions, enforces Content Gate and 500-line budget. Phase 0 includes a per-skill
  historical audit of recent Claude Code transcripts, history, and agent memory.
  Trigger: "evolve skills", "improve skills", "refine skills".
argument-hint: "[skill-name] [days=N]"
effort: max
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Skills

You are the **Skill Evolution Orchestrator**. Create an agent team (TeamCreate) and spawn @staff-engineer teammates to review every `SKILL.md` under `.claude/skills/` and `skills/`. All additions pass through the Content Gate.

---

## Argument Handling

Target skill(s) and historical-audit window are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills in `.claude/skills/*/SKILL.md` and `skills/*/SKILL.md`. Historical audit window defaults to 30 days.
- **Skill name only** (`/evolve-skills tdd`): Improve only the named skill. Pre-flight step 5 validates the argument matches an existing skill directory.
- **`days=N`** (optional, e.g. `/evolve-skills tdd days=14` or `/evolve-skills days=7`): Override the historical-audit window. Default `30`. Reject values outside `1..90` and abort with a usage note.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options (logs, reproductions, large diffs, verbatim quotes) AFTER a structured option-led question routes them there.

Before spawning any agents:

1. **Verify evolution goal (HARD GATE)** — Team mode: adopt the verified goal from orchestrator prompt; re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All skills", "Specific skill" (pair with `$ARGUMENTS` or free-text follow-up for the skill name), "Specific dimension(s)" (follow-up multiSelect over the 8 dimensions), "Address operator-reported pain (skip to step 2)". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Gather experience feedback** — Skip if orchestrator prompt already includes `experience_feedback`. If it begins with `[friction-driven-evolution: cluster-`, pass through verbatim — the Phase 1 template's substitution guidance instructs reviewers on payload handling. Otherwise call `AskUserQuestion` with `multiSelect: true` and 4 options: `Coordination, handoff & orchestration gaps`, `Operator-prompt or output quality`, `Scope, budget or file-size mismatch`, `Other (free-text follow-up)`. If `Other`, follow up free-text. Store as `{experience_feedback}`.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
4. **Inventory skill files and sizes** — Run `wc -l .claude/skills/*/SKILL.md skills/*/SKILL.md 2>/dev/null`. Mode per file is **TRIM** (over 500: consolidation primary, removals must exceed additions) or **BALANCED** (under 500: additions allowed but offset by removals). Include line count and mode in each agent's spawning prompt.
5. **If targeting a specific skill** — Verify the argument matches exactly one of `.claude/skills/<arg>/SKILL.md` or `skills/<arg>/SKILL.md`. If neither exists, inform user and abort. If both exist (name collision), inform user, list both paths, and ask which to target via `AskUserQuestion` (options: each path; header `Path`).
6. **If no skill files found at all** — Inform user and abort.
7. **Check for existing changelogs** — Run `ls docs/changelog/skills/*.md 2>/dev/null` to see
   which changelogs already exist. Spawned agents will need this information.
8. **Resolve historical-audit window** — Parse `days=N` from `$ARGUMENTS` (default `30`; reject outside `1..90` per Argument Handling). Store as `{history_days}`. Compute `{history_cutoff_iso}` via Bash: `date -u -v-${history_days}d +%Y-%m-%dT%H:%M:%SZ` on macOS, `date -u -d "${history_days} days ago" +%Y-%m-%dT%H:%M:%SZ` on Linux (detect via `uname`). Probe transcript availability: `find ~/.claude/projects -name "*.jsonl" -mtime -${history_days} 2>/dev/null | head -1`. If empty, set `{historical_audit_findings}` = `"SKIPPED: no transcripts in last ${history_days} days"` and skip the historical-auditor spawn in Phase 0 (Phase 1 still runs with the literal SKIPPED string substituted). The audit is always-on otherwise.

---

## Content Gate

**Every proposed addition MUST pass ALL 4 checks. Reject content that fails ANY check.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the skill's output? Reject: general LLM knowledge.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if reworded.
4. **Concrete** — Specific action, check, or output format? Reject aspirational fluff ("think holistically", "drive excellence").

---

## Changelog Format

All changes tracked in `docs/changelog/skills/<skill-name>.md` (create directory if needed).

**Exact format — no deviations:** `# Changelog: <skill-name>` (kebab-case) > `## YYYY-MM-DD` (no suffixes) > exactly 4 H3 sections in order: `### Summary` (1-2 sentences), `### Changes` (bulleted with reasoning), `### Dimensions Evaluated`, `### Rename` (details or "No rename.").

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing changelog entries — always prepend a NEW entry below H1, even if one already exists for today's date** (stacked same-date entries are fine; the topmost is the latest). Read only the most recent `## <date>` entry — never full history. Report honestly if no improvements found. **Normalization:** orchestrator fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extras, truncates over 20 lines — applied ONLY to the new entry just prepended; never touch prior entries.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

1. `TeamCreate(team_name="evolve-skills-{today_date}", description="Skill evolution cycle for {today_date}")`.
2. `TaskCreate` all tasks up-front: Phase 0 ("Docs Research", "Docket CLI Audit", "Historical Audit"), one "Review <name>" per target skill, and "Coherence & Renames".

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `docs-researcher`, `docket-auditor`, `historical-auditor` (skip the third if pre-flight step 8 flagged SKIPPED) | Spawn parallel → all complete → shut down all before Phase 1 |
| 1 | `review-<name>` per target skill | Spawn parallel → per agent: apply changes → shut down (don't wait for siblings) |
| 2 | `coherence-reviewer` | Spawn after ALL Phase 1 applied → apply fixes → shut down → `TeamDelete` |

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response`. If rejected, address the `reason` and re-request. No response → see Crash & Stall Recovery.

### Crash & Stall Recovery

Detect failure via: (a) `TeammateIdle` notification or `Monitor` stream silence past expected progress (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) Agent() returns an explicit error.

- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior partial report, (b) task ID to claim, (c) target file.
- **Second failure**: mark task completed, record "No review performed — agent unavailable" in the changelog, skip. Never review directly.
- **Compaction recovery**: re-read verified goal, `TaskList()`, latest changelog entries for completed targets, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0: Documentation Research, Docket CLI Audit & Historical Audit

Spawn THREE agents in parallel per the templates below: `docs-researcher` (claude-code-guide), `docket-auditor` (senior-engineer, needs Bash), and `historical-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/`, `~/.claude/history.jsonl`, `.claude/agent-memory/`). Skip `historical-auditor` only if pre-flight step 8 flagged SKIPPED. Assign Phase 0 tasks via `TaskUpdate`. Each agent's final `SendMessage` report is captured verbatim as `{docs_research_findings}`, `{docket_audit_findings}`, and `{historical_audit_findings}` for Phase 1 template substitution.

**Distinction from `friction-driven-evolution`:** that skill clusters cross-skill friction into top-5 root causes and routes proposals through downstream skills. This audit is per-skill, scoped to the skills under review here, and feeds Phase 1 reviewers directly — no clustering, no routing.

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer teammate per target skill (all in the same turn for parallelism).
Assign tasks via `TaskUpdate(taskId=<id>, owner="review-<name>", status="in_progress")`.

Each teammate (read-only — no file edits):
1. Reads target skill file and most recent changelog entry only (first `## <date>` section)
2. Checks `docs/spec/` selectively — only files relevant to the skill's domain
3. Reads OTHER skill files — first ~80 lines only for ecosystem context
4. Evaluates against ALL 8 dimensions, marks task completed, reports structured recommendations

**After each Phase 1 teammate completes**, the orchestrator:
1. Reviews recommendations against the **Content Gate** — reject any failing check
2. Applies approved changes via Edit; `wc -l` to verify budget; spot-check references/CLI against codebase
3. Writes/normalizes `docs/changelog/skills/<name>.md` per Changelog Format
4. Aggregates renames and coherence issues for Phase 2
5. **Self-correct**: if changes worsen clarity without behavioral gain, revert and retry
6. Shuts down the teammate (don't wait for siblings — see Agent Lifecycle)

**Phase 1 SendMessage triggers** (orchestrator-only relay — peer-to-peer creates race conditions across independent edit surfaces; Phase 2 consolidates cross-cutting items):
- A finding affects another skill (include affected skill name)
- The teammate needs delegation (voting, sub-agents)
- The teammate is blocked

Cross-cutting items append to a running notes list passed verbatim into the Phase 2 prompt's "Phase 1 Coherence Issues" section. `TaskList()` tracks progress.

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

After Phase 2 completes:

1. Shut down the coherence-reviewer and `TeamDelete(team_name="evolve-skills-{today_date}")` per lifecycle rules.
2. Run `wc -l .claude/skills/*/SKILL.md skills/*/SKILL.md`. Consolidate any over 500 lines.
3. Report: files modified, before/after line counts, improvements, renames/coherence fixes, cross-communication events, and reminder that NO changes have been committed.

---

## Spawning Templates

### Phase 0: @claude-code-guide (Documentation Research)

```
Agent(team_name="evolve-skills-{today_date}", name="docs-researcher", subagent_type="claude-code-guide", prompt="...")

MISSION: Research Claude Code documentation for capabilities relevant to writing skill definition files (.claude/skills/*/SKILL.md and skills/*/SKILL.md). Report NEW or CHANGED features only — skip well-known existing behavior.

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

### Phase 0: Historical Audit (per-skill)

Skip spawning if pre-flight step 8 flagged SKIPPED. Substitute `{target_skills}` with the list of skills Phase 1 will review (single skill from `$ARGUMENTS`, or all `.claude/skills/*/SKILL.md` + `skills/*/SKILL.md`). Distinct from `friction-driven-evolution`: per-skill, no clustering, feeds Phase 1 directly.

```
Agent(team_name="evolve-skills-{today_date}", name="historical-auditor", subagent_type="senior-engineer", prompt="...")

You are the historical auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}).
Target skills: {target_skills}

## Task
For EACH target skill, mine three read-only sources for signals that the skill is failing or misused:

1. **Transcripts** (under `~/.claude/projects/`, including subagent transcripts):
   - Enumerate in-window files: `find ~/.claude/projects -name '*.jsonl' -mtime -${history_days} -print0`. Pipe to `xargs -0 grep -lE '"name":"Skill"'` then filter lines containing the skill name (also check `"<command-name>"`, `"<skill-format>"`, and skill-listing attachment markers for the skill).
   - Operator-correction phrases following an invocation (in the next user turn): `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — extract ≤240-char excerpts.
   - Error/abort signals tied to the skill: `"is_error":true` tool results in turns invoking the skill; abort/usage-error strings in the assistant text.
   - Re-invocation within the same `sessionId`: count occurrences per session; ≥2 invocations of the same skill in one session is a failure signal.
2. **`~/.claude/history.jsonl`** (one JSON object per line; `display` field carries operator input with `timestamp` epoch-ms and `project`):
   - `grep -E '"display":"/<skill-name>' ~/.claude/history.jsonl` to count operator-typed invocations in the window (filter by `timestamp` ≥ epoch-ms of `{history_cutoff_iso}`). Surface 1-2 representative `display` prompts per skill.
3. **Agent memory** (`.claude/agent-memory/*/MEMORY.md` and `.claude/agent-memory/*/*.md`, relative to repo; the dir may not exist — treat absence as `none`):
   - `grep -lri '<skill-name>' .claude/agent-memory/ 2>/dev/null` — persistent agent learnings to incorporate into recommendations.

## Output Format (per skill)
Emit one block per target skill, then SendMessage the orchestrator with all blocks verbatim:

```
### Skill: <skill-name>
- Invocations (window): N (transcripts) + M (history.jsonl)
- Operator-correction signals: <count> with 1-2 example excerpts (≤240 chars each, include session-ref path)
- Error/abort signals: <count> with example
- Re-invocation signals: <count of sessions with ≥2 invocations>
- Memory references: <list of .claude/agent-memory paths, or "none">
- Suggested focus areas: <1-3 bullets — actionable, Content-Gate-passing>
```

If a category is empty for a skill, write `none` — do not omit the line.

## Rules
- Read-only. Do NOT use Edit/Write. Do NOT commit.
- No sub-agents: do NOT invoke /vote, Skill(), Agent(), or TeamCreate. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator is the only relay.
- Per-skill grep is mandatory — never load wholesale (~/.claude/projects/ is ~1GB).
- Do not cluster or rank across skills — that is `friction-driven-evolution`'s job. Stay per-skill.
```

### Phase 1: @staff-engineer (Review & Improve)

Spawn one teammate per target skill. Substitute `<name>`, `<skill-path>`, `{line_count}`,
`{mode}`, `{today_date}`, `{verified_goal}`, and `{experience_feedback}` for each.

```
Agent(team_name="evolve-skills-{today_date}", name="review-<name>", subagent_type="staff-engineer", prompt="...")

Target: <skill-path>/SKILL.md | Skill: <name> | Size: {line_count} lines | Mode: {mode}
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Experience feedback: {experience_feedback}
  > If `Experience feedback` begins with `[friction-driven-evolution: cluster-`, it is a structured payload: prioritize `proposed_edit.target` as the change locus and weight your recommendations by `severity`. Cite `example_session_refs` in your CONTEXT field.

## Size Budget

500-line hard limit. **TRIM** (over 500): consolidation primary — removals must exceed additions. **BALANCED** (under 500): additions allowed but offset by removals. Report NET_LINES per change.

## Context

Date: {today_date} (for changelog). Read latest changelog entry from docs/changelog/skills/<name>.md, docs/spec/ selectively, other skill files first ~80 lines only (both .claude/skills/ and skills/). Prioritize the operator experience feedback and apply the docs research / docket audit findings below.

## Claude Code Documentation Research
{docs_research_findings}

## Docket CLI Audit Findings
{docket_audit_findings}

## Historical Audit Findings
{historical_audit_findings}
> Prioritize the Suggested focus areas from your skill's block; cite example session refs in the `CONTEXT:` field of any CHANGE driven by historical signals.

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check.

## Your Task
Evaluate <skill-path>/SKILL.md against ALL 8 dimensions. Over-Engineering is HIGHEST PRIORITY — every addition MUST be offset by a removal. Do not default to approval.

1. **Skill Design Quality**: Frontmatter (`effort`, `argument-hint`, `allowed-tools`), argument handling, structure-brevity balance.
2. **Actionability**: Specific enough for reliable execution? Clear phases, concrete templates, defined outputs.
3. **Completeness**: Edge cases, error conditions, pre-flight checks, all workflow paths.
4. **Over-Engineering (HIGHEST PRIORITY)**: Verbose, redundant, or low-value sections to trim or consolidate. Every addition from other dimensions MUST be offset here.
5. **Orchestration & Agent Teams**: Proper agent use, parallelism, correct types, coordination. Templates must include explicit SendMessage triggers — flag hub-and-spoke if >50% of paths route through one agent.
6. **Coherence**: Scope overlaps, terminology, shared conventions, accurate references.
7. **Spec Alignment**: Alignment with `docs/spec/` project patterns.
8. **Rename**: Only if compelling — stability has value.

## Rules
- **Read-only** — analyze and recommend only; orchestrator applies all edits.
- **No sub-agents**: Do NOT invoke `/vote`, `Skill()`, `Agent()`, or `TeamCreate`. SendMessage the orchestrator for delegation.
- **No peer-to-peer SendMessage** — orchestrator is the only relay.
- **SendMessage orchestrator IMMEDIATELY** on (a) cross-cutting findings (include affected skill name AND which root: `.claude/skills/` or `skills/`), (b) scope expansion beyond target, or (c) blocker.

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
**No sub-agents** — do NOT invoke `/vote`, `Skill()`, `Agent()`, or `TeamCreate`. SendMessage the orchestrator for delegation.

## Renames to Execute
<list recommended renames, or "No renames were recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Task
1. Read ALL skill files in .claude/skills/*/SKILL.md and skills/*/SKILL.md
2. If renames listed, verify and prepare rename instructions (dir, frontmatter, references, changelog)
3. Check coherence: no scope overlaps, consistent terminology, accurate references,
   correct agent types in templates, consistent conventions and argument handling
4. Check cross-communication: identify SendMessage trigger gaps between dependent skills, flag hub-and-spoke patterns (>50% routing through one agent)

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

1. **Orchestrator-only edits.** Teammates are read-only. Never commit.
2. **Fail loud.** See Crash & Stall Recovery.
3. **Clean up.** Shutdown all teammates and `TeamDelete` after wrap-up.
