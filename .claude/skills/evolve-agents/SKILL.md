---
name: evolve-agents
description: >
  Evolve agent definitions in agents/*.md via multi-agent self-review. Phase 0 includes a
  per-agent historical audit of recent Claude Code transcripts, history, agent memory, and
  stall signals (TeammateIdle, -r2 respawns, shutdown-rejection).
  Trigger: "evolve agents", "improve agents", "grow the team", "refine agents".
argument-hint: "[agent-name] [days=N]"
effort: max
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Agents

You are the **Agent Evolution Orchestrator**. Create an agent team (TeamCreate) and spawn each agent to review its own definition file (e.g. @senior-engineer reviews `agents/senior-engineer.md`). All additions pass through the Content Gate.

---

## Argument Handling

Target agent(s) and historical-audit window are determined by `$ARGUMENTS`:

- **No argument** (`/evolve-agents`): Improve ALL agents in `agents/*.md`. Historical audit window defaults to 7 days.
- **Agent name only** (`/evolve-agents staff-engineer`): Improve only the named agent. Pre-flight step 5 validates the name.
- **`days=N`** (optional, e.g. `/evolve-agents staff-engineer days=14` or `/evolve-agents days=7`): Override the historical-audit window. Default `7`. Reject values outside `1..90` and abort with a usage note.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options (logs, reproductions, large diffs, verbatim quotes) AFTER a structured option-led question routes them there.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt, re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All agents", "Specific agent" (pair with `$ARGUMENTS` or free-text follow-up for the agent name), "Specific dimension(s)" (follow-up multiSelect over the 8 dimensions), "Address operator-reported pain (skip to step 2)". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Gather experience feedback** — Skip if orchestrator prompt already includes `experience_feedback`. If it begins with `[friction-driven-evolution: cluster-`, treat it as a structured payload (fields: `friction_class`, `frequency`, `severity`, `example_session_refs`, `proposed_edit.target`, `root_cause`) — Phase 1 reviewers must prioritize the `proposed_edit.target` location and weight changes by `severity`. Otherwise call `AskUserQuestion` (`multiSelect: true`, ≤4 options): `Role & coordination gaps`, `Operator prompts & output quality`, `File-size bloat`, `Other (free-text follow-up)`. If `Other`, ask a follow-up free-text question. Store as `{experience_feedback}`.
3. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries.
4. **Inventory agent files and sizes** — Run `wc -l agents/*.md 2>/dev/null`. Mode per file is **TRIM** (over 500: consolidation primary, removals must exceed additions) or **BALANCED** (under 500: additions allowed but offset by removals). Include line count and mode in each agent's spawning prompt.
5. **Validate inventory** — If no agent files found, or `$ARGUMENTS` is set and `agents/<arg>.md` does not exist, inform user and abort.
6. **Check for existing changelogs** — Run `ls docs/changelog/agents/*.md 2>/dev/null` to see which changelogs already exist. Spawned agents will need this information.
7. **Scope-confirmation gate (HARD GATE)** — If `$ARGUMENTS` is empty (all-agents mode) AND inventory from step 4 contains >3 agents, surface the planned scope via `AskUserQuestion` with options: "Proceed with all <N> agents", "Pick specific agent (free-text follow-up)", "Limit to <≤4 named agents>" (multiSelect follow-up from inventory list, max 4), "Abort". List agent names + total line count in the question body so operator sees est. cycle weight before commit. Skip silently in single-agent mode. Team mode: skip — orchestrator already verified scope.
8. **Resolve historical-audit window** — Parse `days=N` from `$ARGUMENTS` (default `7`; reject outside `1..90` per Argument Handling). Store as `{history_days}`. Compute BOTH cutoff representations in pre-flight to prevent downstream conversion errors:
   - `{history_cutoff_iso}` via Bash: `date -u -v-${history_days}d +%Y-%m-%dT%H:%M:%SZ` on macOS, `date -u -d "${history_days} days ago" +%Y-%m-%dT%H:%M:%SZ` on Linux (detect via `uname`).
   - `{history_cutoff_epoch_ms}` via Bash: `echo $(( $(date -u -v-${history_days}d +%s) * 1000 ))` on macOS, `echo $(( $(date -u -d "${history_days} days ago" +%s) * 1000 ))` on Linux. The historical-auditor template substitutes this directly into the `history.jsonl` timestamp filter — never let the auditor compute it.
   Probe transcript availability: `find ~/.claude/projects -name "*.jsonl" -mtime -${history_days} 2>/dev/null | head -1`. If empty, set `{historical_audit_findings}` = `"SKIPPED: no transcripts in last ${history_days} days"` and skip the historical-auditor spawn in Phase 0 (Phase 1 still runs with the literal SKIPPED string substituted).

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

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing changelog entries — always prepend a NEW entry, even if one already exists for today's date** (stacked same-date entries are fine; the topmost is the latest). Read only the latest entry in existing changelogs. Report honestly if no improvements found. **Normalization:** orchestrator normalizes ONLY the new entry it just prepended — fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extra sections, truncates over 20 lines. Do not touch prior entries.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

1. `TeamCreate(team_name="evolve-agents-{today_date}", description="Agent evolution cycle for {today_date}")`.
2. `TaskCreate` all tasks up-front: Phase 0 ("Docs Research", "Docket CLI Audit", "Historical Audit"), one "Review <name>" per target agent, and "Coherence & Renames".

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `docs-researcher`, `docket-auditor`, `historical-auditor` (skip the third if pre-flight step 8 flagged SKIPPED) | Spawn parallel → all complete → shut down all before Phase 1 |
| 1 | `review-<name>` per target | Spawn parallel → per agent: apply changes → shut down (don't wait for siblings) |
| 2 | `coherence-reviewer` | Spawn after ALL Phase 1 applied → apply fixes → shut down → `TeamDelete` |

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response` **addressed to the orchestrator** (never to a peer). If rejected, read the `reason`, address it, then re-request. If no response, see Crash & Stall Recovery.

### Crash & Stall Recovery

Detect failure via: (a) TeammateIdle notification or `Monitor` stream silence past expected progress (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) Agent() returns an explicit error.

- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior partial report, (b) task ID to claim, (c) target file.
- **Second failure**: mark task completed, record "No review performed — agent unavailable" in the changelog, skip. Never review directly.
- **Compaction recovery**: re-read verified goal, `TaskList()`, latest changelog entries for completed targets, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0: Documentation Research, Docket CLI Audit & Historical Audit

Spawn THREE teammates in parallel per the templates below: `docs-researcher` (claude-code-guide), `docket-auditor` (senior-engineer, needs Bash), and `historical-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/`, `~/.claude/history.jsonl`, `.claude/agent-memory/`). Skip `historical-auditor` only if pre-flight step 8 flagged SKIPPED. Assign Phase 0 tasks via `TaskUpdate`. Each agent's final `SendMessage` report is captured verbatim as `{docs_research_findings}`, `{docket_audit_findings}`, and `{historical_audit_findings}` for Phase 1 template substitution.

**Distinction from `friction-driven-evolution`:** that skill clusters cross-cutting friction into top-5 root causes and routes proposals downstream. This audit is per-agent and feeds Phase 1 reviewers directly.

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

Cross-cutting items append to a running notes list passed verbatim into the Phase 2 prompt's "Phase 1 Coherence Issues" section.

### Phase 2: Coherence & Renames (sequential)

Gate: `TaskList()` shows all Phase 1 tasks `completed`, all Phase 1 edits applied, AND every Phase 1 teammate shut down per lifecycle rules. Only then spawn a single `coherence-reviewer` per the Phase 2 template and assign the Phase 2 task.

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

Audit the docket CLI: run `--help` on all commands/subcommands, cross-reference against
usage in `agents/` and `.claude/skills/`.

Output: New, Changed, Deprecated commands (with synopsis) plus full CLI reference tree.
```

### Phase 0: Historical Audit (per-agent)

Skip spawning if pre-flight step 8 flagged SKIPPED. Substitute `{target_agents}` with the list Phase 1 will review (single agent from `$ARGUMENTS`, or all `agents/*.md`).

```
Agent(team_name="evolve-agents-{today_date}", name="historical-auditor", subagent_type="senior-engineer", prompt="...")

You are the historical auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
Target agents: {target_agents}

## Task
For EACH target agent, mine read-only sources for signals the agent is failing, stalling, or misused.

1. **Agent memory (PRIMARY — read fully, it is small)**:
   - `.claude/agent-memory/<agent-name>/MEMORY.md` and `.claude/agent-memory/<agent-name>/*.md`. Read each file in full and surface 1-3 representative recurring lessons (≤240 chars each). These are persistent learnings that should be reflected in the agent definition.
2. **Transcripts** (under `~/.claude/projects/`):
   - Enumerate in-window files: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`.
   - Invocation contexts: `xargs -0 grep -lE '"subagent_type":"<agent-name>"|"agentSetting":"<agent-name>"'`.
   - Operator-correction phrases in the next user turn after an invocation: `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — extract ≤240-char excerpts (mirror evolve-skills regex for cross-pipeline symmetry).
   - Error/abort signals tied to the agent: `"is_error":true` tool results in turns invoking the agent.
3. **Agent-specific stall signals (NEW vs evolve-skills — strongest evidence of agent-definition gaps):**
   - `TeammateIdle` events: `grep -nE '"TeammateIdle"' <transcript>` within ±5 lines of the agent name. Cluster repeat idles per agent per session.
   - `-r2` respawn convention (canonical from `agents/team-lead.md` and `friction-driven-evolution`'s detection pattern): `grep -hE '"name":"[^"]*-r2"' <transcripts>` then extract root name (strip `-r2` suffix). Every hit means the agent stalled once.
   - Shutdown-rejection: grep `"shutdown_response"` messages where the agent responded with `"approve":false`. Capture the `reason` field — signals ambiguous lifecycle definition.
4. **`~/.claude/history.jsonl`** (one JSON object per line; `display` field carries operator input, `timestamp` is epoch-ms):
   - Count operator-typed `@<agent>` mentions in the window: `jq -r --argjson c {history_cutoff_epoch_ms} 'select(.timestamp >= $c and (.display // "" | test("@<agent-name>"))) | .display' ~/.claude/history.jsonl | wc -l`. Expect low signal — operators rarely `@<agent>` directly; capture `none` if empty.

## Output Format (per agent)
Emit one block per target agent, then SendMessage the orchestrator with all blocks verbatim:

```
### Agent: <agent-name>
- Invocations (window): N (transcripts) + M (history.jsonl)
- Operator-correction signals: <count> with 1-2 example excerpts (≤240 chars each, include session-ref path)
- Error/abort signals: <count> with example
- Stall signals: TeammateIdle=<count> / -r2 respawns=<count> / shutdown-rejections=<count> with reason excerpts
- Memory excerpts: <1-3 representative lessons from .claude/agent-memory/<name>/, ≤240 chars each>
- Suggested focus areas: <1-3 bullets — actionable, Content-Gate-passing>
```

If a category is empty for an agent, write `none` — do not omit the line.

## Rules
- Read-only. Do NOT use Edit/Write. Do NOT commit.
- No sub-agents: do NOT invoke /vote, Skill(), Agent(), or TeamCreate. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator is the only relay.
- Per-agent grep is mandatory — never load wholesale (`~/.claude/projects/` is ~1GB).
- Do not cluster or rank across agents — that is `friction-driven-evolution`'s job. Stay per-agent.
```

### Phase 1: Self-Review & Improve

Spawn one teammate per target. Substitute `<name>`, `{line_count}`, `{mode}`, `{today_date}`, `{verified_goal}`, and `{experience_feedback}` for each (`subagent_type: "<name>"`).

```
Agent(team_name="evolve-agents-{today_date}", name="review-<name>", subagent_type="<name>", prompt="...")

Read agents/<name>.md — this is YOUR definition. You are reviewing yourself to evolve.

Target: agents/<name>.md | Size: {line_count} lines | Mode: {mode}
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Experience feedback: {experience_feedback}
  > If `Experience feedback` begins with `[friction-driven-evolution: cluster-`, it is a structured payload: prioritize `proposed_edit.target` as the change locus and weight your recommendations by `severity`. Cite `example_session_refs` in your CONTEXT field.

## Size Budget

500-line hard limit. **TRIM**: removals must exceed additions. **BALANCED**: additions offset by removals. Report NET_LINES per change.

## Context

Date: {today_date} (for changelog). Read latest changelog entry from docs/changelog/agents/<name>.md, docs/spec/ selectively, other agent files first ~80 lines only. Prioritize the operator experience feedback below.

## Claude Code Documentation Research
{docs_research_findings}

## Docket CLI Audit Findings
{docket_audit_findings}

## Historical Audit Findings
{historical_audit_findings}
> Prioritize the Suggested focus areas from your agent's block; cite example session refs in the `CONTEXT:` field of any CHANGE driven by historical signals. Stall signals (TeammateIdle, -r2 respawns, shutdown-rejection) are the strongest evidence of agent-definition gaps.

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

### Summary
<1-2 sentences or "No changes needed"> | Net line change: <+/- lines>

### Recommended Changes
For each change, emit a fenced block with these fields verbatim:
`CHANGE <n>: <title>` / `DIMENSION:` / `CONTEXT:` / `NET_LINES:` / `OLD_STRING:` / `NEW_STRING:`
Use `<REMOVE>` for deletions and `<INSERT_AFTER>` (with the line you're inserting after) for pure additions.

### Changelog Entry
4 sections in order, max 20 lines: `### Summary`, `### Changes`, `### Dimensions Evaluated`, `### Rename`.

### Rename Recommendation
Single line with reasoning, or "No rename."

### Coherence Issues
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

## Output Format

### Renames
For each: `RENAME: <old> → <new>` with FRONTMATTER_UPDATE, REFERENCES_TO_UPDATE, CHANGELOG_RENAME. Or: "No renames needed."
### Coherence Fixes
For each: `FIX <n>: <title>` / `FILE:` / `OLD_STRING:` / `NEW_STRING:` / `REASON:`. Or: "No issues found."
### Changelog Entries
Standard format (4 sections, max 20 lines) per affected agent.
### Remaining Issues
<Unresolvable issues, or "None">
```

---

## Rules

1. **Always run Phase 2** — even for single-agent improvements.
2. **Orchestrator-only edits.** Teammates are read-only. Never commit.
3. **Fail loud.** See Crash & Stall Recovery.
4. **Clean up.** Shutdown all teammates and `TeamDelete` after wrap-up.
