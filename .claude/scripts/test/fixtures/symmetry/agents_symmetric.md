# Fixture: evolve-agents SKILL.md excerpt (symmetric pair, agents side)

### Phase 0: Historical Audit (per-agent)

<!-- CANONICAL:HARVEST:BEGIN -->
**Cross-project pitfalls scan (read-only).** In addition to the current-repo `.claude/agent-memory/` scan above, enumerate pitfalls files across all projects under `~/Development` with this EXACT bounded command (substitute nothing — it is literal):

```
find "$HOME/Development" -maxdepth 12 \( -name node_modules -o -name '.git' \) -prune \
  -o -type f -path '*/.claude/agent-memory/*/pitfalls.md' -print 2>/dev/null | sort
```

The `-maxdepth 12` cap and the `node_modules`/`.git` prune are mandatory — do NOT remove them.
<!-- CANONICAL:HARVEST:END -->

### Phase 0: Innovation Scan

```
Agent(name="innovation-scanner", subagent_type="staff-engineer", model="opus", prompt="...")

MISSION: Discover NEW and MORE-EFFICIENT ways for agents to accomplish their tasks — evolutionary variation and exploration, NOT auditing past failures (that is historical-auditor's job). Read agents/*.md and surface concrete opportunities for improvement beyond what error-correction alone would find.

Target agents: {target_agents}

## Task — for EACH target agent, identify opportunities:
4. **Cross-Agent Opportunities**: Coordination patterns that would make the agent family more effective as a whole.

## Output Format (per agent)
### Agent: <agent-name>
- Cross-Agent Opportunities: <1-3 bullets, or "none">
```

### Phase 0: Model Routing Audit

Substitute `{target_agents}`, `{history_days}` from pre-flight.

```
Agent(name="model-routing-auditor", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the model-routing auditor. Read-only. No file edits. No commits. No sub-agents.
Target agents: {target_agents}

## Task
1. **Per-spawn model distribution** — for each session where a target agent spawned subagents, run:
   Report DISTINCT counts per model per agent role.

3. **`~/.claude/history.jsonl`** — count operator-typed `@<agent>` mentions in the window per target agent.

4. **`.claude/agent-memory/`** — `grep -lri 'model\|routing\|opus\|sonnet\|haiku' .claude/agent-memory/ 2>/dev/null` for any durable routing lessons already recorded.
5. **Mimir metrics (primary factual arm — https://code.claude.com/docs/en/monitoring-usage)**: Query `https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query` with these PromQL instant queries:
   - `sum by (model, agent_name) (increase(claude_code_token_usage[{history_days}d]))`
   On any non-200 response, emit `"Mimir metrics unavailable: <reason>"` and proceed.

## Improvement-Only Mandate
Every recommendation MUST carry factual justification.

## Output Format
### Agent: <agent-name>
- Mimir metrics: <summary of labeled token/cost totals by model and agent_name, or "metrics unavailable: <reason>">

If a category is empty for an agent, write `none` — do not omit the line.

## Rules
- Read-only (no Edit/Write, no commit). No sub-agents: do NOT invoke /vote, Skill(), or Agent(); do not form/manage a team. Per-agent grep mandatory.
```

### Phase 1: Self-Review & Improve
