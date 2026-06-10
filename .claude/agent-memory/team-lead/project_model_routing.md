---
name: project-model-routing
description: Measured 2026-06-09 — all non-pinned subagent spawns in this repo run claude-opus-4-8 via Fable classifier fallback; explicit Agent(model=...) pins are the only deterministic model control
metadata:
  type: project
---

In this repo, when the main session runs Fable 5, every non-pinned subagent/teammate spawn executes on `claude-opus-4-8` — measured across 4 sessions (f18870ba, 7bcbe316, 2a6fe2ab, 75a49b9a) via `grep -o '"model":"[^"]*"' ~/.claude/projects/<proj>/<session>/subagents/*.jsonl`. Explicit `Agent(model="sonnet"/"opus")` pins land verbatim (sonnet impl spawns + opus security pins all verified in transcripts).

**Why:** the workspace context (agents/, skills/, docs/spec/security.md — security/sandbox/threat-model text) trips Fable 5's safety classifier on subagent requests, rerouting to Opus 4.8 (inference grounded in Anthropic's documented content-fallback behavior; the all-opus distribution is the measurement).

**How to apply:** treat the team-lead.md §Spawning Templates routing table as the ONLY deterministic model control — "inherit" effectively means opus for spawns here. Never assume a spawn runs the session model without checking its subagent transcript. The evolve-* historical auditors now capture per-spawn model distribution automatically (added 2026-06-09). Related: [[agent-effort-settings]].
