---
name: project-model-routing
description: Measured 2026-06-09 — all non-pinned subagent spawns in this repo run claude-opus-4-8 via Fable classifier fallback; explicit Agent(model=...) pins are the only deterministic model control
metadata:
  type: project
---

In this repo, when the main session runs Fable 5, every non-pinned subagent/teammate spawn executes on `claude-opus-4-8` — measured across 4 sessions (f18870ba, 7bcbe316, 2a6fe2ab, 75a49b9a) via `grep -o '"model":"[^"]*"' ~/.claude/projects/<proj>/<session>/subagents/*.jsonl`. Explicit `Agent(model="sonnet"/"opus")` pins land verbatim (sonnet impl spawns + opus security pins all verified in transcripts).

**Why:** the workspace context (agents/, skills/, docs/spec/security.md — security/sandbox/threat-model text) trips Fable 5's safety classifier on subagent requests, rerouting to Opus 4.8 (inference grounded in Anthropic's documented content-fallback behavior; the all-opus distribution is the measurement).

**How to apply:** treat the team-lead.md §Spawning Templates routing table as the ONLY deterministic model control — "inherit" effectively means opus for spawns here. Never assume a spawn runs the session model without checking its subagent transcript. The evolve-* historical auditors now capture per-spawn model distribution automatically (added 2026-06-09). Related: [[agent-effort-settings]].

**Update 2026-06-09 (DKT-256):** alias resolution is now pinned to 1M-context variants via `ANTHROPIC_DEFAULT_{SONNET,OPUS,FABLE}_MODEL` env vars in `src/user.rs` (ClaudeCode builder): sonnet→`claude-sonnet-4-6[1m]`, opus→`claude-opus-4-8[1m]`, fable→`claude-fable-5[1m]`. No haiku pin (no 1M support; never spawned) — `ANTHROPIC_DEFAULT_HAIKU_MODEL` exists but operator declined a base-ID symmetry pin (2026-06-09): unpinned auto-tracks future Haiku releases. Deliberately did NOT use `CLAUDE_CODE_SUBAGENT_MODEL` — it overrides per-invocation `Agent(model=...)` params and would flatten the routing table (per code.claude.com/docs/en/model-config.md + sub-agents.md resolution order). Takes effect after the vorpal config is rebuilt/deployed; verify post-deploy via subagent-transcript model grep expecting `[1m]` IDs.

**Update 2026-06-10 (DKT-266/267/268):** ea127f9's quality-first routing ("default fable for every spawn ... cost is NOT a criterion") measured 12/13 spawns fable / 94% of subagent transcripts within one cycle — operator flagged via Mirmir and directed reversion. team-lead.md §Per-spawn model routing now carries the cost-tier table as DEFAULT (sonnet = Direct/Small impl + planner; opus = Medium impl/reviewer-2/verifier* AND security depth; fable = tdd-author*/Large/long-horizon) with quality-first surviving only as a justified per-prompt UPGRADE path. Operator priority: right-sized spawns; fable-everywhere is explicitly not the policy even though cost-quality tradeoff language invited it. Related: [[agent-effort-settings]].
