---
name: session-metrics
description: >
  Collect transcript-derived metrics for the current Claude Code session — token & cost
  (est.), tool-call breakdown with error counts, timeline/duration, files touched, and a
  subagent roster (model resolved, effort literal "unknown" — never recorded per-subagent)
  — then emit both a chat-facing summary and a self-contained interactive HTML report
  (inline CSS/JS, no CDN) written to a temp file. Transcript-only; OTEL is not consulted.
  Trigger: "session metrics", "show session stats", "how many tokens has this session used",
  "cost so far this session", "subagent token/cost breakdown".
argument-hint: ""
allowed-tools: ["Bash", "Read", "Glob"]
disallowed-tools: ["Agent", "SendMessage", "Task"]
---

<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) Leaf skill — do NOT use `Agent`/`SendMessage`/`Task`, do NOT form or manage a team, do NOT invoke other skills recursively. (2) Do NOT commit any changes. (3) Transcript-only: every metric is derived from the local session JSONL under `~/.claude/projects/`. OTEL is deliberately NOT consulted — OTEL is a remote push-only sink with no local read path, so it cannot answer "what happened in this session."

# Session Metrics — Transcript-Derived Token, Cost, Tool, and Subagent Report

You report on the **current** Claude Code session by parsing its local transcript — no network calls, no telemetry, nothing leaves the machine. The work is split: `scripts/session_metrics.py` does all parsing, aggregation, cost math, and HTML rendering and prints a JSON summary plus an HTML file path; you render that JSON into a chat-facing summary and surface the HTML path.

## Step 1 — Run the script

```bash
python3 ~/.claude/skills/session-metrics/scripts/session_metrics.py
```

If you're running from source inside this repo (e.g. testing an unreleased change) instead of the installed copy, use the repo-relative path: `python3 "$(pwd)"/user/claude-code/skills/session-metrics/scripts/session_metrics.py`. Resolve whichever copy is actually on disk; don't assume. The script takes no arguments. It reads `$CLAUDE_CODE_SESSION_ID` and `$CLAUDE_EFFORT` from the environment and needs no other input.

**Output shape:** all stdout except the final line is a single pretty-printed JSON object (the summary); the final line repeats the absolute path to the generated HTML file. Split on the last newline and parse everything before it as one JSON blob — don't attempt to `json.loads()` line-by-line as JSONL.

**Failure modes:** the script exits non-zero with a one-line message on stderr if it can't find a Claude Code project directory for the current cwd, or can't find any session `*.jsonl` under it. Surface that message verbatim to the user — don't retry or guess a path yourself.

## Step 2 — Render the chat-facing summary

From the JSON summary, build a concise chat reply covering:

1. **The OTEL note** (`summary.note`) — one line, verbatim or near-verbatim. This must appear; it's the one place the user learns the data source.
2. **Headline KPIs**: total tokens, total est. cost (`summary.totals.cost_est_usd`, labeled "est."), cache hit ratio, wall-clock duration, files touched count.
3. **Subagent roster** (`summary.subagents`) as a table: name, role, model, effort (always the literal string from the JSON — never paraphrase or infer a number), tokens, est. cost (`cost_est` is `null` when the subagent used a model absent from the price table — render as "n/a", never as $0), tool calls, errors, files touched. If empty, say "no subagents in this session."
4. **Session-level effort** (`summary.session_effort`, from `$CLAUDE_EFFORT`) called out separately from the roster — it describes the orchestrating session, not any one subagent.
5. **Tool-usage breakdown** (`summary.tool_usage`) — top few by call count, with error counts where nonzero.
6. **The HTML report path** (the script's final stdout line) — tell the user it's a self-contained, sortable HTML file they can open in a browser.

Keep the chat summary terse — the HTML report is the long-form artifact (token/cost tables per model, full files-touched list, raw-JSON drawer). Don't re-paste the whole JSON into chat.

## Step 3 — Hand off the HTML path

State the absolute HTML path plainly (e.g. "Report written to: `<path>`"). Do not open or `cat` the HTML file — it's meant to be opened in a browser, and dumping ~10KB of markup into chat defeats the point of having a separate artifact.

## Notes on what the numbers mean

- **Every cost figure is an estimate** (`est.`) — derived from a hardcoded per-model price table, not billing-authoritative usage. Caching-tier nuances, batch discounts, and `inference_geo` multipliers are not modeled.
- **Subagent effort is never inferred.** The transcript does not record per-subagent effort; the script emits the literal string `"unknown (not recorded in transcript)"`. If asked to estimate it, decline — that would be fabrication.
- **Files-touched is deduped** across the main session and every subagent transcript.
- **Timeline has two numbers**: wall-clock duration (first timestamp to last) and total `turn_duration` (the sum of the harness's own per-turn timing records) — these differ when there were idle gaps.
