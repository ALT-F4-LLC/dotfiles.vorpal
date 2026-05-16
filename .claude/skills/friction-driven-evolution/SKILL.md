---
name: friction-driven-evolution
description: >
  Harvest recurring friction from the last 30 days of transcripts + agent memory, cluster
  the top 5 root causes, propose concrete edits, and route each through evolve-skills,
  evolve-agents, or update-config. Manual trigger only — no commits, no scheduling.
  Trigger: "friction-driven evolution", "harvest friction", "evolve from friction",
  "friction sweep", "evolve from operator pain".
argument-hint: "[days=30]"
effort: max
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "AskUserQuestion", "Skill"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Friction-Driven Evolution

You are the **Friction Evolution Orchestrator**. Scan recent session activity for recurring pain, cluster the top 5 by root cause, propose precise edits to the responsible skill/agent/settings file, and route each proposal through the appropriate downstream skill (`evolve-skills`, `evolve-agents`, or `update-config`) which owns the actual file change and its own changelog. You do NOT write changelogs and you do NOT commit.

---

## Argument Handling

Optional `[days=30]` overrides the harvest window (e.g. `/friction-driven-evolution 14`). Default `30`. Reject values outside `1..90` and abort with a usage note.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call, 2-4 options for single-select; up to 8 options when `multiSelect: true` AND options enumerate a fixed dimension catalog; max 12-char `header`). Free-text is permitted ONLY when the operator must paste material that doesn't fit options: logs, reproductions, large diffs, or verbatim quotes — and only AFTER a structured option-led question routes them there.

Before harvesting:

1. **Verify scope (HARD GATE)** — `AskUserQuestion` with two questions in order:
   - Header `Scope`, options: `Confirm` (proceed with 30-day full sweep), `Narrow` (operator picks classes), `Adjust days` (free-text follow-up for window), `Abort`.
   - If `Narrow`: follow up with header `Classes`, `multiSelect: true`, options: `Idle/stalls`, `Sandbox blocks`, `Stale reports`, `Token limits`, `Unverified claims`. Capture as `{enabled_classes}` (default: all five).
   - Do NOT proceed past this gate without an answer. Store outcome as `{verified_goal}`.
2. **Resolve today's date** — `date +%Y-%m-%d` via Bash, store as `{today_date}`.
3. **Compute window** — `{days}` from argument or `30`. Store window cutoff as `{cutoff_iso}` (`date -u -v-${days}d +%Y-%m-%dT%H:%M:%SZ` on macOS, `date -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ` on Linux — detect via `uname`).
4. **Calibrate detection patterns** — For each enabled friction class, pick the 3 newest transcripts (`find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 | xargs -0 ls -t | head -3`) and run the grep/jq pattern from the Detection Patterns section below against a 10-line sample (`head -200 <file>`). If the pattern returns **zero hits across all 3 sampled transcripts**, flag it `MISCALIBRATED` and surface to the operator via `AskUserQuestion` (header `Patterns`, options: `Proceed anyway`, `Skip this class`, `Abort`) before clustering. Do NOT silently report zero friction.
5. **Confirm transcript availability** — If `find ~/.claude/projects -name '*.jsonl' -mtime -${days}` returns no files, abort with "No transcripts in window."

---

## Detection Patterns

Each class lists: **scope** (transcript / memory / both), **root-cause sketch**, **exact grep/jq command**. The harvest emits one JSON record per hit: `{class, session_ref, ts, agent, excerpt}`.

### 1. Idle teammates / stalls (two-stage filter)
- **Scope**: transcripts.
- **Root cause**: orchestrator-shutdown gaps, ambiguous task ownership, missing SendMessage triggers.
- **Stage A — explicit markers** (fast, always emit):
  ```bash
  find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 \
    | xargs -0 grep -lE '"TeammateIdle"|"-r2"|"name":"[^"]*-r2"' 2>/dev/null
  ```
- **Stage B — gap-based detection.** A hit requires ALL of: (1) inter-event gap > 600s; (2) the 5 messages preceding the gap contain a teammate-handoff signal (`Agent(` call, `SendMessage` to a non-`team-lead` teammate, or wait tokens: `Monitor`, `probe`, `shutdown_request`, `waiting`, `no progress`, `stall`); (3) no `shutdown_response` from the awaited teammate within the gap; (4) no `tool_use` entries inside the gap (concurrent work disqualifies). Implementation: spawn the Phase 0 harvester (decision rule auto-promotes when correlation exceeds 5 invocations) and have it execute the filter in Python using `json.loads` + `datetime.fromisoformat` — inline awk with a per-line date subshell takes 10+s on transcripts >5000 lines and is not maintainable in this file. The harvester emits one hit per surviving gap with `{class:"idle-stall", session_ref, ts, agent, excerpt, gap_seconds, handoff_signal}`.
- **Calibration:** Pre-flight step 4 exercises BOTH stages on 3 sampled transcripts. Stage A or Stage B firing alone is sufficient; both zero → flag `MISCALIBRATED`.

### 2. Sandbox blocks
- **Scope**: transcripts.
- **Root cause**: allowlist gaps in `.claude/settings.json`, agents retrying instead of escalating, missing `dangerouslyDisableSandbox` justification.
- **Detect**:
  ```bash
  find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 \
    | xargs -0 grep -hE 'Operation not permitted|sandbox(-exec)?:|dangerouslyDisableSandbox|denied by sandbox|not in allowlist|Permission denied.*sandbox' 2>/dev/null \
    | jq -rR 'fromjson? | select(.type=="user" or .type=="tool_result") | {cmd:(.message.content//.toolUseResult.stdout//""|tostring|.[0:200]), sid:.sessionId} | @json'
  ```
  Cluster by the offending command/path (e.g. all `~/.aws` blocks group together).

### 3. Stale / fabricated reports
- **Scope**: transcripts (cross-reference agent `completed` claims with operator skepticism in the next user turn).
- **Root cause**: agents reporting completion without re-verifying, compaction loss, stale TaskUpdate.
- **Detect**:
  ```bash
  # operator correction phrases following an assistant "completed/done/applied" claim
  find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 \
    | xargs -0 grep -hE "that's not actually|you said .* but|the diff doesn't show|didn't actually|still showing the old|that file doesn't exist|that line isn't there" 2>/dev/null \
    | jq -rR 'fromjson? | select(.type=="user" and (.message.content|tostring|test("(?i)(not actually|didn.t actually|doesn.t show|still showing|isn.t there)"))) | {excerpt:(.message.content|tostring|.[0:240]), sid:.sessionId, ts:.timestamp} | @json'
  ```

### 4. Output-token-limit errors
- **Scope**: transcripts.
- **Root cause**: agent reports balloon past budget, verbatim quoting of large files, missing summarization budget.
- **Detect**:
  ```bash
  find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 \
    | xargs -0 grep -hE '"stop_reason":"max_tokens"|output token limit|response was truncated|tokens exceeded|max output tokens' 2>/dev/null \
    | jq -rR 'fromjson? | {stop:(.message.stop_reason//"?"), agent:(.message.role//"?"), sid:.sessionId, ts:.timestamp} | select(.stop=="max_tokens") | @json'
  ```

### 5. Unverified claims (heuristic — flag for operator confirmation)
- **Scope**: transcripts.
- **Root cause**: agents pattern-matching success without verification.
- **Detect**:
  ```bash
  # assistant turns containing completion verbs immediately followed by operator skepticism markers
  find ~/.claude/projects -name '*.jsonl' -mtime -${days} -print0 \
    | xargs -0 awk '
        /"type":"assistant".*"(completed|done|applied|fixed|working|verified|tested)"/ {prev=$0; next}
        /"type":"user".*("actually|still broken|didn.t|where is|I don.t see|not seeing|that.s wrong)"/ {if (prev) {print prev; print $0; prev=""}}
      ' 2>/dev/null
  ```
  Surface candidates to operator in Phase 1 with header `Unverified` and options: `Real`, `False positive`, `Skip`.

### Memory & changelog confirmation (all classes)
Cross-reference clusters with persistent records — these confirm a friction pattern is recurring, not a one-off:
```bash
grep -lriE 'idle|stall|sandbox|denied|truncat|max.token|stale|fabricat|unverif' \
  .claude/agent-memory/*/MEMORY.md .claude/agent-memory/*/*.md \
  docs/changelog/agents/*.md docs/changelog/skills/*.md 2>/dev/null
```
Append memory/changelog hits as `confirmation_refs` on the cluster record. A cluster with ≥1 confirmation_ref outranks one with none at equal frequency.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

The skill spawns a team ONLY in Phase 2 (per-cluster proposals). Phase 0 prefers inline Bash; Phase 1 and Phase 3 are orchestrator-only.

| Phase | Mode | Lifecycle |
|---|---|---|
| 0 | Inline Bash, OR single read-only agent if jq pipelines exceed 5 invocations | If spawned: spawn → complete → shut down before Phase 1 |
| 1 | Orchestrator only (cluster, rank, operator confirmation) | n/a |
| 2 | `TeamCreate(team_name="friction-evolution-{today_date}")`, one `propose-cluster-N` @staff-engineer per cluster, spawned in parallel | Spawn parallel → per agent: capture proposal → shut down |
| 3 | Orchestrator only (sequential `Skill()` dispatch per cluster) | n/a |
| Wrap | `TeamDelete(team_name="friction-evolution-{today_date}")` | After all dispatches reported |

`TaskCreate` all tasks up-front: `Harvest`, `Cluster & rank`, one `Propose cluster N` per anticipated cluster (5 placeholders), one `Dispatch cluster N` per cluster, `Wrap-up`. Update via `TaskUpdate` as phases progress.

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response`. If rejected, address `reason` and re-request.

### Crash & Stall Recovery

Detect failure via: (a) `TeammateIdle` notification or `Monitor` stream silence past expected progress (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) `Agent()` returns an explicit error.

- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior partial report, (b) task ID to claim, (c) cluster JSON record.
- **Second failure**: mark task completed, record "No proposal — agent unavailable" in the wrap-up report, skip the cluster (do NOT propose directly).
- **Compaction recovery**: re-read verified goal, `TaskList()`, the cluster JSON file in `$TMPDIR`, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0: Harvest

**Decision rule:** if total harvest fits in ≤5 Bash invocations (one per enabled class plus the memory/changelog cross-reference), run inline. If correlation across files requires programmatic parsing (jq pipelines feeding awk feeding grep, cross-session timestamp diffs), spawn ONE read-only agent:

```
Agent(team_name="friction-evolution-{today_date}", name="harvester", subagent_type="senior-engineer", prompt="...")
```

Either path emits a single findings JSON to `$TMPDIR/friction-findings-{today_date}.json` with shape:

```json
{
  "window_days": 30,
  "cutoff_iso": "2026-04-16T00:00:00Z",
  "hits": [
    {"class": "sandbox-block", "session_ref": "<path>", "ts": "<iso>", "agent": "<name>", "excerpt": "<≤240 chars>", "confirmation_refs": ["<path>"]}
  ],
  "miscalibrated_classes": []
}
```

Read this file back into orchestrator context before Phase 1.

### Phase 1: Cluster & rank (orchestrator only)

1. Read `$TMPDIR/friction-findings-{today_date}.json`. If `miscalibrated_classes[]` is non-empty, apply the operator decision recorded in pre-flight step 4 (skip those classes' hits) before clustering.
2. **Group by root cause, not surface symptom.** Multiple sandbox failures hitting `~/.aws/*` cluster as one root cause ("AWS credentials access pattern"); failures hitting `~/.ssh/*` cluster separately. Idle stalls in `@project-manager` cluster separately from stalls in `@sdet`.
3. **Rank** by `score = frequency × severity_weight × (1 + confirmation_count × 0.2)`. Severity defaults: idle=med, sandbox=high, stale=high, token-limit=med, unverified=high. Operator may override in step 5.
4. Take top 5 (or fewer if total clusters < 5).
5. **Confirm with operator** via `AskUserQuestion`:
   - Header `Top 5`, `multiSelect: true`, options = the five cluster names with frequency suffix (e.g. `AWS sandbox (8x)`, `PM idle stalls (5x)`). Operator deselects any to drop.
   - If `Unverified claims` cluster is in the top 5, ALWAYS add a confirmation question (header `Unverified`, free-text after option-led: paste 1-2 example session refs for operator to triage).
6. Persist the confirmed cluster list to `$TMPDIR/friction-clusters-{today_date}.json` with shape:
   ```json
   {"clusters": [{"id": 1, "name": "...", "class": "...", "frequency": 8, "severity": "high",
     "root_cause": "...", "example_session_refs": ["...", "..."], "confirmation_refs": [...]}]}
   ```

### Phase 2: Propose edits (parallel agents)

`TeamCreate(team_name="friction-evolution-{today_date}", description="Friction-driven proposals for {today_date}")`. Spawn one @staff-engineer per confirmed cluster in the same turn using the Phase 2 template below. Each proposer is read-only — it returns a structured proposal; the orchestrator captures it.

**Target-file resolution rule (passed into each prompt):**
- Cluster root cause is settings/permissions/allowlist → target `.claude/settings.json`, downstream `update-config`.
- Cluster root cause is agent behavior (idle, missing trigger, stale TaskUpdate by a specific role) → target `agents/<role>.md`, downstream `evolve-agents`.
- Cluster root cause is skill workflow (orchestration gap, missing operator prompt, weak content gate) → target `.claude/skills/<name>/SKILL.md`, downstream `evolve-skills`.

Each agent returns:
```
PROPOSAL <n>
TARGET_FILE: <absolute path>
DOWNSTREAM_SKILL: <evolve-skills | evolve-agents | update-config>
FRICTION_CLASS: <class>
ROOT_CAUSE: <one sentence>
OLD_STRING: <verbatim block from target file, or `<NEW_FILE_OR_SETTINGS_PATCH>` for additions>
NEW_STRING: <verbatim replacement>
REASONING: <why this prevents recurrence; cite example session refs>
```

Orchestrator validates each proposal:
- `TARGET_FILE` exists.
- `OLD_STRING` (if non-sentinel) appears verbatim in the file (`grep -F` check).
- `DOWNSTREAM_SKILL` matches the target-file resolution rule.
Reject and re-spawn (`-r2`) once on validation failure. Persist accepted proposals to `$TMPDIR/friction-proposals-{today_date}.json`.

### Phase 3: Review handoff (sequential per cluster)

Orchestrator-only. For each accepted proposal, invoke the downstream skill **sequentially** (parallel `Skill()` calls share orchestrator state and confuse the operator-prompt path):

```
Skill("<DOWNSTREAM_SKILL>", "<argument>")
```

Where `<argument>` is the skill/agent name (for evolve-*) or a brief instruction (for update-config). The orchestrator passes the friction context by **pre-answering** the downstream skill's `experience_feedback` operator prompt — the downstream skill's HARD GATE asks "what experience feedback should we apply?"; the orchestrator answers with the structured payload below, satisfying the gate without re-prompting the operator.

**`experience_feedback` payload** — a single human-readable string that satisfies the downstream skill's HARD GATE (it stores the value verbatim into `{experience_feedback}`; nothing parses it). Format:

```
[friction-driven-evolution: cluster-{id}] friction_class={class}, frequency={N}/{days}d, severity={low|med|high}, target={absolute path}, root_cause={one sentence}, example_refs={path1}; {path2}, proposed_edit={one-line OLD→NEW summary}
```

The downstream skill (`evolve-skills` / `evolve-agents`) owns its review pipeline, Content Gate, and its own changelog entry — friction-driven-evolution does NOT write changelogs. For `update-config`, the orchestrator passes the proposal as the user instruction; that skill validates and applies the settings.json change per its own flow.

Record per cluster: `{cluster_id, downstream_skill, invocation_arg, outcome: applied | rejected | escalated, notes}`.

### Wrap-up

1. Shut down all Phase 2 teammates per the shutdown protocol; `TeamDelete(team_name="friction-evolution-{today_date}")`.
2. Verify no commits occurred: `git status --short` — flag any unexpected staging.
3. Report to operator:
   - Window: `{days}` days ending `{today_date}`.
   - Friction harvest: total hits per class.
   - Top 5 clusters (or fewer): name, frequency, severity, root cause.
   - Per cluster: target file, downstream skill invoked, outcome.
   - Miscalibrated patterns (if any) and operator decisions on them.
   - Reminder: **no commits performed.** Operator reviews via `git diff` and commits explicitly.

---

## Spawning Templates

### Phase 0: Harvester (only if inline harvest fails the decision rule)

```
Agent(team_name="friction-evolution-{today_date}", name="harvester", subagent_type="senior-engineer", prompt="...")

You are the friction harvester. Read-only. No file edits. No commits.

Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Window: last {days} days, cutoff {cutoff_iso}.
Enabled classes: {enabled_classes}
Output file: $TMPDIR/friction-findings-{today_date}.json

## Task
Run the Detection Patterns from the friction-driven-evolution SKILL.md for each enabled class.
For each hit, emit a JSON record: {class, session_ref, ts, agent, excerpt (≤240 chars)}.
Cross-reference with .claude/agent-memory/ and docs/changelog/ — attach confirmation_refs[] per cluster candidate.
Re-validate any pattern flagged MISCALIBRATED in pre-flight before running it broadly.

## Output
Write the structured findings JSON to $TMPDIR/friction-findings-{today_date}.json with shape:
{window_days, cutoff_iso, hits[], miscalibrated_classes[]}.
Then SendMessage the orchestrator with the file path and per-class counts.

## Rules
- No sub-agents: do NOT invoke /vote, Skill(), Agent(), or TeamCreate. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator is the only relay.
- Read-only. No Edit/Write to repo files; only write to $TMPDIR.
- Do not summarize friction — emit raw structured hits. Clustering is the orchestrator's job.
```

### Phase 2: Per-cluster proposer (@staff-engineer)

Spawn one per confirmed cluster. Substitute `{cluster_id}`, `{cluster_json}` (the cluster record from `$TMPDIR/friction-clusters-{today_date}.json`), `{today_date}`, `{verified_goal}`.

```
Agent(team_name="friction-evolution-{today_date}", name="propose-cluster-{cluster_id}", subagent_type="staff-engineer", prompt="...")

You are proposing a concrete edit to prevent recurrence of a single friction cluster.
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Mode: read-only — return a structured proposal. Orchestrator handles all edits via the downstream skill.
Budget: aim for the smallest behavioral change that removes the root cause. No aspirational language.

## Cluster
{cluster_json}

## Target-File Resolution
- Settings/permissions/allowlist root cause → .claude/settings.json, downstream `update-config`.
- Agent behavior root cause (specific role's idle/stale/missing trigger) → agents/<role>.md, downstream `evolve-agents`.
- Skill workflow root cause (orchestration gap, missing prompt, weak Content Gate) → .claude/skills/<name>/SKILL.md, downstream `evolve-skills`.

## Context
Read the target file in full and the 2-3 example session refs in the cluster (use `head -c 4000` per file to bound). Cross-reference the cluster's confirmation_refs (memory/changelog) — they describe whether prior fixes already exist and where they fell short.

## Content Gate
Apply the canonical 4-check gate (Executable, Behavioral, Non-redundant, Concrete) defined in
`.claude/skills/evolve-skills/SKILL.md` and `.claude/skills/evolve-agents/SKILL.md`. Reject any proposed edit failing ANY check. Do NOT re-derive the gate here.

## Rules
- No sub-agents: do NOT invoke /vote, Skill(), Agent(), or TeamCreate. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator is the only relay.
- Read-only — do NOT use Edit or Write. The orchestrator routes your proposal through the downstream skill, which owns the edit and its changelog.
- One proposal per cluster. If you find multiple root causes, SendMessage the orchestrator — do not bundle.
- OLD_STRING must appear verbatim in TARGET_FILE (single occurrence preferred). Use `<NEW_FILE_OR_SETTINGS_PATCH>` sentinel only for pure additions to settings.json.

## Output Format
PROPOSAL {cluster_id}
TARGET_FILE: <absolute path>
DOWNSTREAM_SKILL: <evolve-skills | evolve-agents | update-config>
FRICTION_CLASS: <class>
ROOT_CAUSE: <one sentence — what causes recurrence, not what the symptom is>
OLD_STRING:
<verbatim block from target, or `<NEW_FILE_OR_SETTINGS_PATCH>`>
NEW_STRING:
<verbatim replacement>
REASONING: <2-3 sentences citing example session refs and why this prevents recurrence>
```

---

## Rules

1. **No scheduling.** Manual trigger only. Do not add cron/loop integration or invoke `schedule`/`loop`.
2. **No parallel changelogs.** Downstream skills own their changelogs. This skill never writes to `docs/changelog/`.
3. **Verify no commits in wrap-up.** `git status --short` — flag any staging. Banner covers the prohibition itself.
4. **Fail loud.** See Crash & Stall Recovery. Never propose directly when an agent fails twice.
5. **Bypass downstream HARD GATE only by pre-answering, not by skipping.** The `experience_feedback` payload IS the answer; do not attempt to disable the gate.
