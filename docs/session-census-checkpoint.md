# Session census checkpoint — run this on or after 2026-08-26

Changes landed 2026-08-19 to cut over-thinking and course-correction. Nothing
about whether they worked is known yet. This file is how you find out.

**Do not read the raw report and judge by feel — that is the failure this whole
exercise was about. Run the comparison and read the deltas.**

## The command

```bash
cd ~/Development/repository/github.com/ALT-F4-LLC/dotfiles.vorpal.git/main
src/user/claude_code/scripts/session-census --days 7 \
  --compare src/user/claude_code/scripts/session-census.baseline.json
```

Takes a few minutes (it parses every session file under `~/.claude/projects`).
Read-only; it writes nothing unless you pass `--json`.

**Prerequisite: `just activate` must have run.** None of the changes are live
until it does. If you never activated, the numbers below will not have moved
and that is not a result — it means the experiment never started.

## Numbers to beat

Lower is better on every row. Percentages are absolute points; ratios are
"characters of private thinking per character of visible output".

| metric | baseline (2026-08-19) | what would count as working |
|---|---|---|
| **main think%** | **45.0%** | below 38% |
| **main think:text** | **4.748 : 1** | below 4.0 |
| subagent think% | 51.14% | below 45% |
| **tribunal-seat think%** | **65.47%** | below 50% — the most direct test |
| **tribunal-seat think:text** | **11.608 : 1** | below 8.0 |
| **interrupt rate** | **22.2%** (82 of 370) | below 15% |
| agents killed | 217 in 39 events | fewer, but see the caveat |
| active hours | 71.0 h | not a target; context only |
| first-request context p50 | 51,740 tokens | roughly flat is expected |

**Read rates and ratios, not raw counts.** Interrupts, kills, and hours all
scale with how much work you happened to do that week. `think%`, `think:text`,
and interrupt *rate* are the only rows that mean anything on their own.

Per-role and per-(model, effort) baselines are in
`src/user/claude_code/scripts/session-census.baseline.json` if you want to go
deeper than the summary.

## What changed, and which number tests it

| change | commit | the row that tests it |
|---|---|---|
| global effort `xhigh` → `high` | `5078de6` | main think% |
| tribunal seats `fable-max` → `opus-high`; investigate/research/retro-analyst → `opus-max` | `5078de6` | tribunal-seat think% |
| first-ever `CLAUDE.md` for the main session | `439c83c`, `a9f7c3d` | interrupt rate |
| stop conditions in executor + seat briefs | `5078de6` | subagent think% |
| docket flag reference split out (body −61%) | `cc7b6be`, `eec8c29` | first-request context, and docket CLI error count |
| `$TMPDIR` scratch rule | `28e6cf8` | worktree-isolation failures (167 in the baseline week) |

**Attribution is compromised, honestly.** The effort change was meant to be the
only variable and it is not. If the numbers move, you will not be able to say
with confidence which lever did it. The per-role and per-(model, effort)
breakouts give partial separation — `tribunal-seat` isolates the policy change
fairly cleanly, since nothing else touched those seats.

## Check these two by hand as well

**1. Did the all-Opus tribunal start rejecting everything?**

This is the known risk. The tribunal had never run all-Opus before; the only
Opus seat on record rejected 22% of the time where the Fable seats rejected 7%.
If the whole panel drifts toward 22%, the savings come back as rework loops and
operator gates — the exact cost this set out to cut.

```bash
sqlite3 -header -column ~/.docket/issues.db \
  "select status, count(*) from proposals group by status;"
```

Baseline on 2026-08-19 was 53 approved / 13 rejected (plus 4 open, 1 closed) —
**13 of 66 decided, 19.7% rejected**. The store is live and the raw counts
drift, so compare the *rate*, not the totals. If the rejected share has climbed
materially above ~20%, revert the
tribunal seats first: in `src/user/docket/config/policy.toml`, put
`tribunal-architecture` and `tribunal-correctness` back to `fable-max`. Restore
effort before reaching for Fable again — the benchmark does not support Fable
as the recovery move.

**2. Did the docket CLI errors drop?**

```bash
src/user/claude_code/scripts/session-census --days 7 | head -30
```

Baseline: 1,630 tool errors in 53,475 calls (3.0%). The specific ones the
changes targeted were 47 `run show` mistakes (the verb does not exist; it is
`run status`) and 167 worktree-isolation refusals from scratch writes to
literal paths instead of `$TMPDIR`.

## If it worked

Push further on the same lever rather than adding new ones. The obvious next
step is `always_thinking_enabled`, which was deliberately left at `true` in
`src/user/claude_code.rs` so this round would have exactly one reasoning dial
moved. Change it, re-baseline, wait another week.

## If it did not

Three things were never addressed and any of them could dominate:

- **Your own Fable main sessions.** $2,667 of ~$9,430 weekly spend — 28% — in
  43 main sessions running Fable at `xhigh`. No config change here touches
  this; `with_model("sonnet")` is already the default, so it is a manual model
  switch. Fable costs $10/$50 per MTok against Opus 5 at $5/$25.
- **Cache reads, not generation, are the bill.** For opus-5 subagents alone:
  $1,705 of cache reads against $681 of output. Spend is dominated by
  re-reading context, which points at fan-out (4.2 subagents per typed input)
  rather than at any per-token setting.
- **67 fork-inside-fork failures** come from the bundled `simplify` skill,
  which is outside this repo and was not patched.

## How the baseline was produced

Every headline was computed twice by independent code paths (a `jq` program and
a pure-Python re-parse) and only reported where both agreed. Six claims were
retracted during the analysis because the falsifying check came back after they
had been stated — which is itself why `CLAUDE.md` now carries a check-before-
speaking rule. Treat any number here as re-derivable: the script is the
definition, not this file.
