# Recurring-Pitfalls Memory Convention — Maintained Master

**LOCAL-copy consumers:** all 7 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`,
`distinguished-engineer.md`) plus `team-lead.md`,
each carrying a copy of this `CANONICAL:PITFALLS` block plus its own role-specific
"What to save here" line. Relocated from `src/user/claude-code/agents/team-lead.md`
§Wrap-up & Team Cleanup (DKT-59/60 doctrine-home migration). Deployed at
`~/.claude/skills/team-doctrine/references/pitfalls.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/pitfalls.md`. Read on demand only —
never `Skill(team-doctrine)`.

---

<!-- CANONICAL:PITFALLS:BEGIN -->
**Recurring-pitfalls memory (`.claude/agent-memory/{role}/pitfalls.md`).** Before shutdown (ephemerals: before or with the final report; team-lead/persistent advisors: before emitting or approving `shutdown_request`), if this session surfaced a RECURRING pitfall (a failure/stall/diagnosis class that has appeared before or will plausibly recur — NOT routine work or a one-shot incident), append one entry to `.claude/agent-memory/{role}/pitfalls.md` in `symptom → root cause → resolution` form (`mkdir -p` the dir if absent). Skip the write entirely if nothing recurring surfaced — per-issue/per-cycle details belong in Docket, not here. This file is periodically harvested (read for recurring lessons) by the `evolve-*` cycles — ALWAYS APPEND a new entry rather than overwriting, never edit or remove prior entries, and avoid duplicating lessons already recorded (check the harvested ledger too). Boundedness is owned by the evolve-agents History Compaction phase (ADR 0001), which may replace an already-harvested, committed entry with a one-line ledger citation; full text remains recoverable via git history.
<!-- CANONICAL:PITFALLS:END -->
