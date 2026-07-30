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
disallowed-tools: ["Agent", "SendMessage"]
---

<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) Leaf skill — do NOT use `Agent`/`SendMessage`, do NOT form or manage a team, do NOT invoke other skills recursively. Caller-side effect: this skill's `disallowed-tools` frontmatter removes `Agent` and `SendMessage` from the CALLING agent's tool pool until the OPERATOR's next real message — the restriction persists across stop-hook continuations, inbound teammate messages, and any number of autonomous turns. Schedule spawns/teammate messages BEFORE invoking, and treat a subsequent `"exists but is not enabled in this context"` error on those tools as this restriction, not an outage. (2) Do NOT commit any changes. (3) Transcript-only: every metric derives from the local session JSONL under `~/.claude/projects/`; OTEL/aggregate metrics are deliberately NOT consulted — the aggregate sink cannot attribute tokens/cost to THIS session nor reconstruct per-session tool/file/timeline detail.

# Session Metrics — Transcript-Derived Token, Cost, Tool, and Subagent Report

Report on the **current** session by parsing its local transcript — no network calls, nothing leaves the machine. `scripts/session_metrics.py` does all parsing, aggregation, cost math, and HTML rendering; you render its JSON into a chat summary and surface the HTML path.

## Step 1 — Run the script

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/session_metrics.py"
```

No arguments; it reads `$CLAUDE_CODE_SESSION_ID` and `$CLAUDE_EFFORT` from the environment (`${CLAUDE_SKILL_DIR}` resolves to whichever copy is on disk; requires Claude Code 2.1.129+). **Output shape:** all stdout except the final line is ONE pretty-printed JSON object; the final line repeats `summary.html_report_path`. Split on the last newline and parse the rest as one JSON blob — never line-by-line as JSONL. On failure the script exits non-zero with a one-line stderr message (no project dir / no session `*.jsonl`) — surface it verbatim; don't retry or guess a path.

## Step 2 — Render the chat-facing summary

Terse — the HTML report is the long-form artifact; don't re-paste the JSON. Cover:

1. **The data-source note** (`summary.note`), near-verbatim — the one place the user learns the data source.
2. **Headline KPIs**: total tokens, total est. cost, cache hit ratio, wall-clock duration, files-touched count, with the `summary.price_table.updated` date alongside the cost so staleness is visible.
3. **Subagent roster** (`summary.subagents`) as a table: name, role, model, effort, tokens, est. cost, tool calls, errors, files touched — or "no subagents in this session."
4. **Session-level effort** (`summary.session_effort`) called out separately — it describes the orchestrating session, not any subagent.
5. **Tool-usage breakdown** (`summary.tool_usage`) — top few by call count, error counts where nonzero.
6. **The HTML report path** — a self-contained, sortable file to open in a browser. State the absolute path plainly; do not `cat` the HTML into chat.

## Notes on what the numbers mean

- **Every cost figure is an estimate** — derived from `scripts/model_prices.json`, not billing-authoritative; caching tiers, batch discounts, and geo multipliers are not modeled.
- **A `null` `cost_est` means an unpriced model — render it `n/a (unpriced model)`, never $0** (matching the HTML renderer's literal), and add one caveat line that the session total is undercounted, pointing at `price_table.updated`.
- **Subagent effort is never inferred.** The transcript does not record it; the script emits the literal `"unknown (not recorded in transcript)"` — render that string, and decline requests to estimate it.
- **Files-touched is deduped** across the main session and every subagent transcript. **Timeline has two numbers**: wall-clock duration and summed per-turn `turn_duration` — they differ when there were idle gaps.
