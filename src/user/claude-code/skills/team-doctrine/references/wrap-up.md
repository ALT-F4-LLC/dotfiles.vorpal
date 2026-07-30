# Wrap-up & Team Cleanup — Maintained Master

Relocated out of `team-lead.md`'s Execution Workflow (charter §1.7: end-of-cycle
detail loads when the cycle ends, not every turn). `team-lead.md` keeps the
binding core inline — the promised-gate delivery check (which also gates steps
14/15), the shutdown direction rule, and the uncommitted-changes report to the
operator — and cites this file for the step-16 mechanics. Deployed at
`~/.claude/skills/team-doctrine/references/wrap-up.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/wrap-up.md`.

---

**Step 16 — after all phases complete.** Run these in order; the three inline
items in `team-lead.md` interleave where its text says they do.

- Final spot-check (per step 13): `git diff --stat` + `docket issue show <id> --json` for closed issues; surface divergences.
- **Wrap-up ledger pass.** Confirm every teammate name spawned this session is `confirmed-terminated` or a CLOSED-set advisor being shut down now. Unaccounted name → probe → Gate. A duplicate found here → report to the operator AND record a pitfalls entry.
- Summarize: issues completed, files changed (real diff), review findings, test results.
- **Dispatch ledger (instrumentation).** Run the exact command below (skip `--help` — this is the complete, current syntax) instead of hand-formatting; it writes the calibration baseline to `.claude/agent-memory/team-lead/dispatch-ledger.md` (no `--triggers` flag exists; a literal `[...]` suffix glob-expands under zsh — put opt-up trigger letters in `--note=`):
  ```
  ~/.claude/scripts/dispatch_ledger.sh append --cycle=<verified-goal-slug> --pattern=<Direct|Small|Medium|Large|UX|V/I/SR> --review=<n_reviewers> --verify=<1|2> --votes=<crit>:<n>[,...] --fix_rounds=<n> --review_spawns_total=<n> [--note=<...>]
  ```
  Then run `python3 ~/.claude/scripts/cycle_metrics.py`; if it prints `MANDATORY EVOLVE-* REVIEW: YES`, surface the blown threshold(s) in the wrap-up summary.
- Send `shutdown_request` to the CLOSED persistent set. Any delivered-report ephemeral still alive here is a missed step-13 sweep — send `shutdown_request`, note in memory.
- After `teammate_terminated` lands for every ephemeral and every advisor is shut down, actively clean up the team. Cleanup is **best-effort, end-of-all-work only** — it fails if any teammate is still running, and a nested lead's reaped children persist with no de-list tool. If it cannot complete, report cleanup degraded/unconfirmed (manual `rm ~/.claude/teams/{name}/` workaround) and proceed — resources auto-remove at session end.
