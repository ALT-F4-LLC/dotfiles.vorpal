# Evolve Phase-0 Auditor Templates (shared reference)

Read-on-demand home for the Phase-0 auditor spawn prompts shared by the `evolve-agents`, `evolve-skills`, and `evolve-config` cycles. References carry no byte budget; this file is the single authoritative home for the templates below, extracted from the three `SKILL.md` files to eliminate hand-maintained duplication (the drift class that produced `symmetry_check.py`).

**How consumers use this file.** At Phase-0 spawn time the orchestrator Reads this file ONCE, then for each auditor it spawns: locates the named section below, substitutes the uppercase spawn-time tokens with the VALUES from its own `SKILL.md` stub table, and passes runtime tokens through unchanged. If this file is missing or a named section is absent, the cycle ABORTS loudly (`Error: shared Phase-0 template missing: {section}`) — never spawn an auditor with a hand-reconstructed prompt. The section bodies are wrapped in four-backtick fences purely so their nested triple-backtick blocks render verbatim; paste the fence CONTENTS (not the outer four-backtick fence) into the auditor prompt.

## 1. Token contract

Two token classes, never mixed:

- **Spawn-time tokens** (UPPERCASE, `{LIKE_THIS}`) — replaced by the orchestrator AFTER Read, BEFORE `Agent()`, using the VALUES in the consumer's `SKILL.md` stub. The shared file defines each token's MEANING; the consumer defines its VALUE (single source each way).
- **Runtime tokens** (lowercase, `{like_this}`) — `{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`, `{target_agents}`/`{target_skills}`. These pass through UNCHANGED and are substituted exactly as today (they may appear literally inside a spawn-time token's value, e.g. `{TARGETS_LINE}` → `Target agents: {target_agents}`).

| Token | evolve-agents | evolve-skills | evolve-config |
|---|---|---|---|
| `{TARGET_NOUN}` | `agent` | `skill` | n/a (uses paste-ready variants only) |
| `{TARGET_NOUN_CAP}` | `Agent` | `Skill` | n/a |
| `{A_TARGET_NOUN}` | `an agent` | `a skill` | n/a |
| `{TARGETS_LINE}` | `Target agents: {target_agents}` | `Target skills: {target_skills}` | n/a |
| `{MENTION_COUNT_LINE}` | §6a item-3 mention-count line — full literal in §1a | §6a item-3 invocation-count line — full literal in §1a | n/a |
| `{PROMQL_LABEL}` | `agent_name` | `skill_name` | n/a |
| `{HARVEST_BLOCK}` | §2 HARVEST block, verbatim | same | same |

The repetition (§4) and bug (§5) templates carry NO spawn-time tokens — their fenced bodies are byte-identical across evolve-agents and evolve-skills (the agent/skill wording lives only in each `SKILL.md`'s pre-fence prose stub), so they are single verbatim copies. `symmetry_check.py`'s calibrated normalizer remains the reference inventory of known agent↔skill divergences; a byte-clean post-substitution diff against each consumer's pre-move body is the authoritative completeness gate — close any residual divergence by adding a token row here, never by hand-tuning one consumer's text.

### 1a. `{MENTION_COUNT_LINE}` literal (committed verbatim)

The `{MENTION_COUNT_LINE}` value is the §6a Model-Routing-Audit item-3 slot line. Substitution must reconstruct these byte-exact; they are committed here so the P1-AC4 byte-clean gate does not depend on git history. evolve-agents form:

````
3. **`~/.claude/history.jsonl`** — count operator-typed `@<agent>` mentions in the window per target agent (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`). Surface `none` if empty.
````

evolve-skills form:

````
3. **`~/.claude/history.jsonl`** — count operator-typed `/<skill>` invocations in the window per target skill (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`). Surface `none` if empty.
````

## 2. HARVEST block

Consumers: evolve-agents, evolve-skills, evolve-config (embedded via the `{HARVEST_BLOCK}` slot in each §3 historical variant). Single authoritative copy, keeping its `CANONICAL:HARVEST` markers — this file is the sole repo-wide carrier of the `CANONICAL:HARVEST` markers.

````
<!-- CANONICAL:HARVEST:BEGIN -->
**Cross-project pitfalls scan (read-only).** In addition to the current-repo `.claude/agent-memory/` scan above, enumerate pitfalls files across all projects under `~/Development` AND the centralized per-user home at `~/.claude/agent-memory` with this EXACT bounded command (substitute nothing — it is literal):

```
{
  find "$HOME/Development" -maxdepth 12 \( -name node_modules -o -name '.git' \) -prune \
    -o -type f -path '*/.claude/agent-memory/*/pitfalls.md' -print
  find "$HOME/.claude/agent-memory" -maxdepth 2 -type f -name 'pitfalls.md' -print
} 2>/dev/null | sort -u
```

The `-maxdepth 12` cap and the `node_modules`/`.git` prune (in-repo half only) are mandatory — do NOT remove them and do NOT add `-L` (symlinked dirs are not followed by design). An absent `~/Development` or `~/.claude/agent-memory` yields an empty result from that half → no-op (`2>/dev/null` swallows the error); the trailing `sort -u` also de-dupes any path the two roots both happen to match (they do not overlap under normal `$HOME` layouts, but the pipeline holds even if they did). The current repo is matched by the `~/Development` half automatically (it lives under `~/Development`). Both halves are read-only ingest only — no pitfalls file is ever deleted: do NOT Edit/Write/`rm` any discovered file, in either root. The cross-project scan is per-file grep/read of each `pitfalls.md` — never bulk-cat all of `~/Development` or `~/.claude`. Emit, as part of your findings block, a verbatim **CROSS-PROJECT PITFALLS MANIFEST**: the full sorted list of discovered `pitfalls.md` paths, grouped by repo for the `~/Development` half (derive the repo root as the path prefix up to and including the `*.git/<branch>` segment) and under a single **Centralized (`~/.claude`)** heading for the second half. This manifest is the orchestrator's ingest set for lesson analysis.
<!-- CANONICAL:HARVEST:END -->
````

## 3. Historical Audit — paste-ready variants

Three structurally-divergent variants (only ~30/70 lines shared; evolve-agents Phase 2 step 6 documents this asymmetry as intentional). Each is a byte-exact relocation of that consumer's pre-move body, with the embedded HARVEST text replaced by the single slot line `{HARVEST_BLOCK}` (substitute §2 verbatim). No other tokens.

### 3a. Historical Audit — evolve-agents variant

Consumer: evolve-agents. Substitute `{HARVEST_BLOCK}` (§2); runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`, `{target_agents}`) pass through.

````
Agent(name="historical-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the historical auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
Target agents: {target_agents}

## Task
For EACH target agent, mine read-only sources for signals the agent is failing, stalling, or misused.

1. **Agent memory (PRIMARY — read fully, it is small)**:
   - `.claude/agent-memory/<agent-name>/MEMORY.md` and `.claude/agent-memory/<agent-name>/*.md` (dir may be absent or empty — treat as `none`). Read each file in full and surface 1-3 representative recurring lessons (≤240 chars each). These are persistent learnings that should be reflected in the agent definition.
{HARVEST_BLOCK}
   - **Per-file mapping (agents):** map each discovered `…/.claude/agent-memory/<role>/pitfalls.md` to agent `<role>` (the path segment). For each TARGET agent in this cycle, read its `pitfalls.md` across ALL scanned repos (each is small — read fully) and surface 1-3 representative recurring lessons per agent (≤240 chars each), tagged with the source repo path. Non-target agents' files are listed path-only (not deep-read).
2. **Transcripts** (under `~/.claude/projects/`):
   - Enumerate in-window files: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`.
   - Invocation contexts: `xargs -0 grep -lE '"subagent_type":"<agent-name>"|"agentSetting":"<agent-name>"'`.
   - **De-dupe before counting** — transcripts replicate (same `sessionId` recurs across resumed/subagent `.jsonl` files), inflating raw grep hits ~10x. Report DISTINCT `sessionId` counts, never raw line-hit totals; de-dupe correction excerpts by distinct text + session.
   - Operator-correction phrases in the next user turn after an invocation: `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — match ONLY operator-typed turns: skip user turns containing `<teammate-message`, `<command-name>`, or `tool_result` markers (relayed reports and command output echo these phrases; 3 consecutive audits were FP-dominated). Extract ≤240-char excerpts (mirror evolve-skills regex for cross-pipeline symmetry).
   - Error/abort signals tied to the agent: `"is_error":true` tool results in turns invoking the agent.
   - Re-invocation within the same `sessionId`: count DISTINCT invocation events per session (by subagent-spawn UUID/timestamp, not replicated lines); ≥2 distinct spawns of the same agent in one session is a failure signal.
3. **Agent-specific stall signals (NEW vs evolve-skills — strongest evidence of agent-definition gaps):**
   - `TeammateIdle` events: `grep -nE '"TeammateIdle"' <transcript>` within ±5 lines of the agent name. Cluster repeat idles per agent per session.
   - `-r2` respawn convention (canonical from `src/user/claude-code/agents/team-lead.md`): `grep -hE '"name":"[^"]*-r2"' <transcripts>` then extract root name (strip `-r2` suffix). Count DISTINCT respawn events by `name`+`sessionId` (not replicated lines); each distinct event means the agent stalled once.
   - Shutdown-rejection: grep `"shutdown_response"` messages where the agent responded with `"approve":false`. Capture the `reason` field — signals ambiguous lifecycle definition.
   - **Model distribution (verified 2026-06-09):** subagent `.jsonl` files record the ACTUAL model per turn in the `"model"` field — this is ground truth, not assumed. Run `python3 src/user/claude-code/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}` across the audit window. Non-pinned spawns in this repo run `claude-opus-4-8` via classifier fallback even when the parent session runs a different model. Report per-spawn model distribution; model/effort recommendations MUST be grounded in these measured models, not assumed inherit semantics.
4. **`~/.claude/history.jsonl`** (one JSON object per line; `display` field carries operator input, `timestamp` is epoch-ms):
   - Count operator-typed `@<agent>` mentions in the window: `jq -r --argjson c {history_cutoff_epoch_ms} 'select(.timestamp >= $c and (.display // "" | test("@<agent-name>"))) | .display' ~/.claude/history.jsonl | wc -l`. Capture `none` if empty.
5. **Mimir metrics (supplementary context — https://code.claude.com/docs/en/monitoring-usage)**: Query the Prometheus-compatible endpoint at `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` (unauthenticated GET, no headers required) for session count and total cost over the audit window:
   - `sum(increase(claude_code_session_count[{history_days}d]))`
   - `sum(increase(claude_code_cost_usage[{history_days}d]))`
   Use `{history_days}` from pre-flight — do NOT compute the window yourself. On any non-200 response or empty result, emit `"Mimir metrics unavailable: <reason>"` and proceed.

## Output Format (per agent)
Emit one block per target agent, then SendMessage the orchestrator with all blocks verbatim:

```
### Agent: <agent-name>
- Invocations (window): N (transcripts) + M (history.jsonl)
- Operator-correction signals: <count> with 1-2 example excerpts (≤240 chars each, include session-ref path)
- Error/abort signals: <count> with example
- Re-invocation signals: <count of sessions with ≥2 spawns of this agent>
- Stall signals: TeammateIdle=<count> / -r2 respawns=<count> / shutdown-rejections=<count> with reason excerpts
- Model distribution: <e.g. "854× claude-opus-4-8 (non-pinned), 87× claude-sonnet-4-6 (pinned)"; `none` if no subagent sessions>
- Memory excerpts: <1-3 representative lessons from .claude/agent-memory/<name>/, ≤240 chars each>
- Mimir metrics: <summary of session count and total cost, or "metrics unavailable: <reason>">
- Suggested focus areas: <1-3 bullets — actionable, Content-Gate-passing>
```
If a category is empty for an agent, write `none` — do not omit the line. After the per-agent blocks, append the verbatim **CROSS-PROJECT PITFALLS MANIFEST** — the full sorted `find` output grouped by repo root (the ingest set for lesson analysis). If the scan found nothing, write `CROSS-PROJECT PITFALLS MANIFEST: none`.

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only for delegation. Per-agent grep mandatory — never load wholesale. Do not cluster/rank across agents. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

### 3b. Historical Audit — evolve-skills variant

Consumer: evolve-skills. Substitute `{HARVEST_BLOCK}` (§2); runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`, `{target_skills}`) pass through.

````
Agent(name="historical-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the historical auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
Target skills: {target_skills}

## Task
For EACH target skill, mine three read-only sources for signals that the skill is failing or misused:

1. **Transcripts** (under `~/.claude/projects/`, including subagent transcripts):
   - Enumerate in-window files: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`. Pipe to `xargs -0 grep -lE '"name":"Skill"'` then filter lines containing the skill name (also check `"<command-name>"`, `"<skill-format>"`, and skill-listing attachment markers for the skill).
   - **De-dupe before counting** — transcripts replicate (same `sessionId` recurs across resumed/subagent `.jsonl` files), inflating raw grep hits ~10x. Report DISTINCT `sessionId` counts, never raw line-hit totals; de-dupe correction excerpts by distinct text + session.
   - Operator-correction phrases following an invocation (in the next user turn): `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — match ONLY operator-typed turns: skip user turns containing `<teammate-message`, `<command-name>`, or `tool_result` markers (relayed reports and command output echo these phrases; 3 consecutive audits were FP-dominated). Extract ≤240-char excerpts.
   - Error/abort signals tied to the skill: `"is_error":true` tool results in turns invoking the skill; abort/usage-error strings in the assistant text.
   - Re-invocation within the same `sessionId`: count DISTINCT invocation events per session (by tool-call UUID/timestamp, not replicated lines); ≥2 distinct invocations in one session is a failure signal.
   - **Model distribution (verified 2026-06-09):** subagent `.jsonl` files record the ACTUAL model per turn in the `"model"` field — this is ground truth, not assumed. Run `python3 src/user/claude-code/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}` across the audit window. Non-pinned spawns in this repo run `claude-opus-4-8` via classifier fallback even when the parent session runs a different model. Report per-spawn model distribution; model/effort recommendations MUST be grounded in these measured models, not assumed inherit semantics.
2. **`~/.claude/history.jsonl`** (one JSON object per line; `display` field carries operator input with `timestamp` epoch-ms and `project`):
   - `grep -E '"display":"/<skill-name>' ~/.claude/history.jsonl` to count operator-typed invocations in the window (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`). Surface 1-2 representative `display` prompts per skill.
3. **Agent memory** (`.claude/agent-memory/*/MEMORY.md` and `.claude/agent-memory/*/*.md`, relative to repo; the dir may not exist — treat absence as `none`):
   - `grep -lri '<skill-name>' .claude/agent-memory/ 2>/dev/null` — persistent agent learnings to incorporate into recommendations.
{HARVEST_BLOCK}
   - **Per-file mapping (skills):** for each TARGET skill, `grep -l '<skill-name>' <each discovered pitfalls.md>` (per-file, mirroring the `grep -lri '<skill-name>'` step above) and surface matching excerpts (≤240 chars each) tagged with the source repo path. `pitfalls.md` files mentioning no target skill are listed path-only.
4. **Mimir metrics (supplementary context — https://code.claude.com/docs/en/monitoring-usage)**: Query the Prometheus-compatible endpoint at `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` (unauthenticated GET, no headers required) for session count and total cost over the audit window:
   - `sum(increase(claude_code_session_count[{history_days}d]))`
   - `sum(increase(claude_code_cost_usage[{history_days}d]))`
   Use `{history_days}` from pre-flight — do NOT compute the window yourself. On any non-200 response or empty result, emit `"Mimir metrics unavailable: <reason>"` and proceed.

## Output Format (per skill)
Emit one block per target skill, then SendMessage the orchestrator with all blocks verbatim:

```
### Skill: <skill-name>
- Invocations (window): N (transcripts) + M (history.jsonl)
- Operator-correction signals: <count> with 1-2 example excerpts (≤240 chars each, include session-ref path)
- Error/abort signals: <count> with example
- Re-invocation signals: <count of sessions with ≥2 invocations>
- Model distribution: <e.g. "57× claude-opus-4-8 (non-pinned), 87× claude-sonnet-4-6 (pinned)"; `none` if no subagent sessions>
- Memory references: <list of .claude/agent-memory paths, or "none">
- Mimir metrics: <summary of session count and total cost, or "metrics unavailable: <reason>">
- Suggested focus areas: <1-3 bullets — actionable, Content-Gate-passing>
```
If a category is empty for a skill, write `none` — do not omit the line. After the per-skill blocks, append the verbatim **CROSS-PROJECT PITFALLS MANIFEST** — the full sorted `find` output grouped by repo root (the ingest set for lesson analysis). If the scan found nothing, write `CROSS-PROJECT PITFALLS MANIFEST: none`.

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only for delegation. Per-skill grep mandatory — never load wholesale. Do not cluster/rank across skills. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

### 3c. Historical Audit — evolve-config variant

Consumer: evolve-config. Substitute `{HARVEST_BLOCK}` (§2); runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`) pass through.

````
Agent(name="historical-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the historical auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
Target: the Claude Code config genome (permissions, sandbox, hooks, env, model routing).

## Task
Mine three read-only sources for signals that a CONFIG SETTING is causing friction or is missing:

1. **Transcripts** (under `~/.claude/projects/`, including subagent transcripts):
   - Enumerate in-window files: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`.
   - **Permission-prompt friction (PRIMARY config signal):** grep for repeated permission requests on the SAME command pattern — a command the operator approves repeatedly is a candidate `allow` rule. Surface the top recurring command patterns with counts.
   - **Sandbox friction:** `"Operation not permitted"`, `dangerouslyDisableSandbox`, sandbox denial strings tied to a command/path/domain — each is a candidate sandbox-rule change. De-dupe by distinct command/path + session.
   - **De-dupe before counting** — transcripts replicate (same `sessionId` recurs), inflating raw grep hits ~10x. Report DISTINCT `sessionId` counts, never raw line-hit totals.
   - Operator-correction phrases after a config-related turn: `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — match ONLY operator-typed turns: skip user turns containing `<teammate-message`, `<command-name>`, or `tool_result` markers. Extract ≤240-char excerpts.
   - **Model distribution (verified 2026-06-09):** subagent `.jsonl` files record the ACTUAL model per turn in the `"model"` field — ground truth. Run `python3 src/user/claude-code/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}`. Non-pinned spawns run `claude-opus-4-8` via classifier fallback. Report distribution; any model/effort env recommendation MUST be grounded in these measured models.
2. **`~/.claude/history.jsonl`** (`display` field carries operator input, `timestamp` epoch-ms): `grep -E '"display":"/evolve-config' ~/.claude/history.jsonl` to count operator-typed invocations in the window (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`).
3. **Agent memory** (`.claude/agent-memory/*/MEMORY.md` and `*/*.md`, relative to repo; dir may not exist — treat absence as `none`): `grep -lri 'permission\|sandbox\|allow rule\|settings\|config' .claude/agent-memory/ 2>/dev/null` — durable lessons about config friction.
{HARVEST_BLOCK}
   - **Config-relevance mapping:** for each discovered `pitfalls.md`, `grep -lE 'permission|sandbox|allow rule|settings|hook|env var'` and surface matching excerpts (≤240 chars each) tagged with the source repo path. Files mentioning no config concern are listed path-only.
4. **Mimir metrics (supplementary context — https://code.claude.com/docs/en/monitoring-usage)**: Query `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` (unauthenticated GET, no headers required) for session count and total cost over the window:
   - `sum(increase(claude_code_session_count[{history_days}d]))`
   - `sum(increase(claude_code_cost_usage[{history_days}d]))`
   Use `{history_days}` from pre-flight — do NOT compute the window yourself. On any non-200 response or empty result, emit `"Mimir metrics unavailable: <reason>"` and proceed.

## Output Format
Emit ONE findings block, then SendMessage the orchestrator verbatim:

```
### Config Historical Audit
- Invocations (window): N (transcripts) + M (history.jsonl)
- Recurring permission prompts: <command pattern → count, top 3, or "none">
- Sandbox friction: <command/path/domain → count, or "none">
- Operator-correction signals: <count>, plus 1-2 example excerpts (≤240 chars each, with the session-ref path)
- Model distribution: <e.g. "57× claude-opus-4-8 (non-pinned)"; or `none` when no subagent sessions exist>
- Memory references: <list of .claude/agent-memory paths, or "none">
- Mimir metrics: <summary, or "metrics unavailable: <reason>">
- Suggested focus areas: <1-3 bullets mapped to a named config-surface dimension, Content-Gate-passing>
```
If a category is empty, write `none` — do not omit the line. After the block, append the verbatim **CROSS-PROJECT PITFALLS MANIFEST** (the ingest set). If the scan found nothing, write `CROSS-PROJECT PITFALLS MANIFEST: none`.

## Rules
- Read-only. Do NOT use Edit/Write. Do NOT commit.
- No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator only. Per-source grep mandatory — never load wholesale. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

## 4. Repetition Audit — shared template

Consumers: evolve-agents, evolve-skills. No spawn-time tokens (fenced body byte-identical across both); runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`) pass through. The per-cycle "Scope is GLOBAL … unlike historical-auditor's per-agent/per-skill grep" wording stays in each consumer's pre-fence prose stub.

````
Agent(name="repetition-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the repetition auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).

## Task
Mine for actions UNINTENTIONALLY REPEATED across sessions — the same or near-identical tool call, command, manual step, or lookup performed more than once when it could have been done once, cached, deduped, or automated.

1. **Transcripts**: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`, per-file grep for recurring Bash commands, Read paths, or Grep patterns. Identify same/near-identical patterns recurring across DISTINCT `sessionId`s — mirror historical-auditor's "De-dupe before counting" discipline (never count replicated lines within one session).
2. **`~/.claude/history.jsonl`**: scan operator-typed invocations in the window for repeated manual command sequences recurring across sessions.
3. **Agent memory (optional, narrow)**: `grep -lri 'repeat\|duplicate\|redundant' .claude/agent-memory/ 2>/dev/null` for already-recorded repetition lessons — do NOT re-run historical-auditor's CROSS-PROJECT PITFALLS MANIFEST harvest.
4. **Crossed-in-flight benign duplicates**: distinguish a TRUE unintentional repeat (above) from a benign race — two independent messages/actions that CROSSED IN FLIGHT (e.g. a teammate's confirmation or a peer's answer arrives after the same fact was already independently resolved by the recipient) where the SECOND arrival is correctly recognized as stale and produces "no action needed" — this is coordination working as intended, not a repetition defect. Detect via `grep -inE 'stale duplicate|crossed in flight|already (resolved|handled|confirmed)|no action needed' <transcript>` and confirm from surrounding context that the acknowledgment correctly identifies a race, not a genuine repeat that should have been prevented.

## Output Format
For each finding: `<FIX|PREVENT|BENIGN-RACE> <n>: <what repeated>` / `SESSIONS:` (distinct sessionId count + 1-2 example refs) / `SUGGESTION:` (dedupe/cache/automate action, or "None — correct behavior" for BENIGN-RACE). Tag every finding exactly `FIX` (already-repeated: correct/dedupe/automate now), `PREVENT` (repeat-prone pattern, not yet repeated many times), or `BENIGN-RACE` (a crossed-in-flight duplicate correctly recognized and dismissed as stale — logged for pattern-frequency visibility only). If the SAME race recurs ≥2 times for the same pair of roles, tag it `PREVENT` instead (with a coordination-fix suggestion, e.g. an ack-before-dispatch convention) rather than `BENIGN-RACE`. SendMessage the orchestrator with all findings verbatim, or "No repetition findings."

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only for delegation. Per-source grep mandatory — never load wholesale. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

## 5. Bug Audit — shared template

Consumers: evolve-agents, evolve-skills. No spawn-time tokens (fenced body byte-identical across both); runtime tokens pass through as in §4.

````
Agent(name="bug-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the bug auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).

## Task
Mine for BUGS surfaced during tool use — failed tool calls, incorrect parameters, and other concrete execution defects (not stylistic/quality concerns; those are the reviewers' job).

1. **Transcripts**: `find ~/.claude/projects -name '*.jsonl' -mtime -{history_days} -print0`, per-file grep for `"is_error":true` tool_result blocks. For each hit, read the paired tool_use block (immediately preceding) to capture the tool name + parameters that produced the error, and the error text itself. Mirror historical-auditor's "De-dupe before counting" discipline — count DISTINCT `sessionId` + tool-call occurrences, never replicated lines within one session.
2. **Incorrect-parameter classification**: within the error-tagged hits from step 1, classify each as one of: `BAD-PARAM` (wrong type/missing required/invalid enum value), `WRONG-PATH` (nonexistent file/dir referenced), `PERMISSION` (sandbox/permission denial), `OTHER` (anything else — API error, timeout, etc). Only `BAD-PARAM` and `WRONG-PATH` are in-scope findings (recurring, definition-fixable classes); `PERMISSION` and `OTHER` are dropped unless the SAME failure recurs ≥3 times across distinct sessions (then report as a pattern regardless of class).
3. **`~/.claude/history.jsonl`** (optional, narrow): `grep -E '"display":".*(error|fail)' ~/.claude/history.jsonl` for operator-reported bugs in the window (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`). Surface `none` if empty.
4. **Agent memory (optional, narrow)**: `grep -lri 'bug\|incorrect param\|failed tool\|wrong argument' .claude/agent-memory/ 2>/dev/null` for already-recorded bug lessons — do NOT re-run historical-auditor's CROSS-PROJECT PITFALLS MANIFEST harvest.

## Output Format
For each finding: `<FIX|PREVENT> <n>: <what failed>` / `CLASS:` (BAD-PARAM | WRONG-PATH | PERMISSION | OTHER) / `SESSIONS:` (distinct sessionId count + 1-2 example refs, incl. tool name + the offending parameter/path) / `SUGGESTION:` (definition fix — e.g. correct an example, tighten a parameter description, add a pre-check). Tag every finding exactly `FIX` (already-recurring: correct the definition now) or `PREVENT` (isolated but definition-fixable, not yet recurring). SendMessage the orchestrator with all findings verbatim, or "No bug findings."

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only for delegation. Per-source grep mandatory — never load wholesale. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

## 6. Model Routing Audit — tokenized template (+ config variant)

### 6a. Model Routing Audit — tokenized template

Consumers: evolve-agents, evolve-skills. Substitute `{TARGET_NOUN}`, `{TARGET_NOUN_CAP}`, `{A_TARGET_NOUN}`, `{TARGETS_LINE}`, `{MENTION_COUNT_LINE}`, `{PROMQL_LABEL}` (§1); runtime tokens pass through. After substitution the body is byte-identical to that consumer's pre-move template.

````
Agent(name="model-routing-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the model-routing auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
{TARGETS_LINE}

## Task
Mine read-only sources to measure ACTUAL model distribution per spawn/role and correlate with observed outcomes. Report only factual, evidence-cited findings.

1. **Per-spawn model distribution** — across the audit window, run:
   `python3 src/user/claude-code/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}`
   Report DISTINCT counts per model per {TARGET_NOUN} role. This is ground truth — do NOT assume inherit semantics.

2. **Outcome signals per model** — for each {TARGET_NOUN}/model pair observed, correlate with:
   - Stall signals: `grep -nE '"TeammateIdle"' <transcript>` within ±5 lines of the {TARGET_NOUN} name; count distinct events by `name`+`sessionId`.
   - Fix-loop respawns (`-r2`): `grep -hE '"name":"[^"]*-r2"'` across in-window transcripts; count DISTINCT respawn events by `name`+`sessionId` (not replicated lines).
   - Error/abort: `"is_error":true` tool results in turns invoking the {TARGET_NOUN}; count per model.
   - Operator-correction phrases in the next user turn after an invocation: `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — skip turns containing `<teammate-message`, `<command-name>`, or `tool_result` markers. Count distinct corrections by model.

{MENTION_COUNT_LINE}

4. **`.claude/agent-memory/`** — `grep -lri 'model\|routing\|opus\|sonnet\|haiku\|tier\|gold\|silver\|bronze' .claude/agent-memory/ 2>/dev/null` for any durable routing lessons already recorded.
5. **Mimir metrics (primary factual arm — https://code.claude.com/docs/en/monitoring-usage)**: Query `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` (unauthenticated GET, no headers required) with these PromQL instant queries using `{history_days}` from pre-flight — do NOT compute the window yourself:
   - `sum by (model, {PROMQL_LABEL}) (increase(claude_code_token_usage[{history_days}d]))`
   - `sum by (model) (increase(claude_code_cost_usage[{history_days}d]))`
   - `sum(increase(claude_code_active_time_total[{history_days}d]))`
   On any non-200 response or empty result, emit `"Mimir metrics unavailable: <reason>"` and proceed using transcript signals only. Mimir results are factual ground truth that supplements and cross-checks the transcript grep above — cite discrepancies between the two signal sources.

## Improvement-Only Mandate
Every recommendation MUST carry factual justification grounded in measured distribution counts and observed outcome signals from this audit. Speculative or regression-risk routing changes are explicitly disallowed. A recommendation without an evidence citation (session path + count) is rejected.

## Output Format
Emit one block per target {TARGET_NOUN}, then SendMessage the orchestrator with all blocks verbatim:

### {TARGET_NOUN_CAP}: <{TARGET_NOUN}-name>
- Model distribution (window): <e.g. "854× claude-opus-4-8 (non-pinned), 87× claude-sonnet-4-6 (pinned)"; `none` if no subagent sessions>
- Stall signals by model: <model → TeammateIdle count, or "none">
- Fix-loop respawns by model: <model → -r2 count, or "none">
- Error/abort by model: <model → count, or "none">
- Operator-correction by model: <model → count, or "none">
- Mimir metrics: <summary of labeled token/cost totals by model and {PROMQL_LABEL}, or "metrics unavailable: <reason>">
- Routing recommendations: <1-3 bullets with evidence citations, or "none — no improvement opportunity grounded in data">

If a category is empty for {A_TARGET_NOUN}, write `none` — do not omit the line.

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only. Per-{TARGET_NOUN} grep mandatory — never load wholesale. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````

### 6b. Model Routing Audit — evolve-config variant

Consumer: evolve-config. Paste-ready (structural divergence from 6a: config-genome scope, no target list, `sum by (model)` grouping). No spawn-time tokens; runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`) pass through.

````
Agent(name="model-routing-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the model-routing auditor. Read-only. No file edits. No commits. No sub-agents.
Window: last {history_days} days (cutoff {history_cutoff_iso}, epoch-ms {history_cutoff_epoch_ms}).
Target: the Claude Code config genome — specifically `model`, `effort_level`, `ANTHROPIC_DEFAULT_*_MODEL` env aliases, and the auto-mode env flag in src/user.rs.

## Task
Mine read-only sources to measure ACTUAL model distribution per spawn/role and correlate with observed outcomes, to inform the config's model/effort env settings. Report only factual, evidence-cited findings.

1. **Per-spawn model distribution** — across the audit window:
   `python3 src/user/claude-code/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}`
   Report DISTINCT counts per model. This is ground truth — do NOT assume inherit semantics.

2. **Outcome signals per model** — correlate each model with:
   - Stall signals: `grep -nE '"TeammateIdle"' <transcript>`; count distinct events by `name`+`sessionId`.
   - Fix-loop respawns (`-r2`): `grep -hE '"name":"[^"]*-r2"'`; count DISTINCT events by `name`+`sessionId`.
   - Error/abort: `"is_error":true` tool results; count per model.
   - Operator-correction phrases in the next user turn: `that's not right|didn't work|still showing|actually|that's wrong|not what I asked|broken|doesn't match` — skip turns containing `<teammate-message`, `<command-name>`, or `tool_result` markers. Count by model.

3. **`~/.claude/history.jsonl`** — count operator-typed `/evolve-config` invocations in the window (filter by `timestamp` ≥ `{history_cutoff_epoch_ms}`). Surface `none` if empty.

4. **`.claude/agent-memory/`** — `grep -lri 'model\|routing\|opus\|sonnet\|haiku\|effort\|tier\|gold\|silver\|bronze' .claude/agent-memory/ 2>/dev/null` for durable routing lessons.
5. **Mimir metrics (primary factual arm — https://code.claude.com/docs/en/monitoring-usage)**: Query `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` (unauthenticated GET) with these PromQL instant queries using `{history_days}` from pre-flight — do NOT compute the window yourself:
   - `sum by (model) (increase(claude_code_token_usage[{history_days}d]))`
   - `sum by (model) (increase(claude_code_cost_usage[{history_days}d]))`
   - `sum(increase(claude_code_active_time_total[{history_days}d]))`
   On any non-200 response or empty result, emit `"Mimir metrics unavailable: <reason>"` and proceed using transcript signals only. Mimir results are factual ground truth that supplements and cross-checks the transcript grep — cite discrepancies.

## Improvement-Only Mandate
Every recommendation MUST carry factual justification grounded in measured distribution counts and observed outcome signals. Speculative or regression-risk routing changes are explicitly disallowed. A recommendation without an evidence citation (session path + count) is rejected.

## Output Format
Emit one findings block, then SendMessage the orchestrator verbatim:

### Config Model Routing
- Model distribution (window): <e.g. "854× claude-opus-4-8 (non-pinned), 87× claude-sonnet-4-6 (pinned)"; `none` if no subagent sessions>
- Stall signals by model: <model → TeammateIdle count, or "none">
- Fix-loop respawns by model: <model → -r2 count, or "none">
- Error/abort by model: <model → count, or "none">
- Operator-correction by model: <model → count, or "none">
- Mimir metrics: <summary of labeled token/cost totals by model, or "metrics unavailable: <reason>">
- Routing recommendations: <1-3 bullets, each naming the env/setter to change, with evidence citations, or "none — no improvement opportunity grounded in data">

If a category is empty, write `none` — do not omit the line.

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. No peer-to-peer SendMessage — orchestrator only for delegation. Any scratch file goes under `$TMPDIR`, never `/tmp` (sandbox denies `/tmp` writes).
````
