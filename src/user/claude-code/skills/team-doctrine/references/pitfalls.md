# Recurring-Pitfalls Memory Convention — Maintained Master

**LOCAL-copy consumers:** the 7 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`,
`distinguished-engineer.md`), each carrying a byte-identical copy of this
`CANONICAL:PITFALLS` block plus its own role-specific "What to save here" line.
`team-lead.md` does **not** carry the block — it uses three bespoke lines instead
(write-scope, "Persistent memory" categories, "Recurring-pitfalls memory") that
independently reflect the two-homes split below. Relocated from
`src/user/claude-code/agents/team-lead.md` §Wrap-up & Team Cleanup (DKT-59/60
doctrine-home migration). Deployed at `~/.claude/skills/team-doctrine/references/pitfalls.md`
— repo: `src/user/claude-code/skills/team-doctrine/references/pitfalls.md`. Read on demand
only — never `Skill(team-doctrine)`.

Recurring pitfalls split by content into two homes per role: **in-repo**
(`.claude/agent-memory/{role}/pitfalls.md`, unchanged, git-tracked) for lessons true only of
this codebase, and **centralized** (`~/.claude/agent-memory/{role}/pitfalls.md`,
`$HOME`-rooted, new) for lessons that generalize across repos — a cross-repo lesson stored
in-repo gets re-learned per repository; a repo-specific lesson stored centrally pollutes other
repos and loses git review. The block below carries the write-time classification test.

---

<!-- CANONICAL:PITFALLS:BEGIN -->
**Recurring-pitfalls memory — two homes, chosen by content.** Before shutdown (ephemerals: before or with the final report; team-lead/persistent advisors: before emitting or approving `shutdown_request`), if this session surfaced a RECURRING pitfall (a failure/stall/diagnosis class that has appeared before or will plausibly recur — NOT routine work or a one-shot incident), append ONE entry to exactly one home — never both — chosen by asking: *"Would this lesson help an agent in my role working in a DIFFERENT repository?"* YES → centralized `~/.claude/agent-memory/{role}/pitfalls.md` (about the agent, its orchestration, the harness/skills, or a cross-repo tool; decide by root cause, not symptom — a lesson with both a general root cause and a repo-specific instantiation still files centralized only). NO → in-repo `.claude/agent-memory/{role}/pitfalls.md` (unchanged path; true only of this codebase's build/test/layout/config). Write in `symptom → root cause → resolution` form (`mkdir -p` the target dir if absent). Skip the write entirely if nothing recurring surfaced — per-issue/per-cycle details belong in Docket, not here. Both homes are periodically harvested by the `evolve-*` cycles — ALWAYS APPEND rather than overwriting, never edit or remove prior entries, and avoid duplicating lessons already recorded (check the harvested ledger too). Boundedness differs per home: the in-repo file is owned by the evolve-agents History Compaction phase, which may replace an already-harvested, committed entry with a one-line ledger citation (full text recoverable via git history); the centralized file is per-user runtime state with no git-backed recovery, so it has no compaction owner — its growth is bounded by the write gate above and it stays read-only ingest for harvest.
<!-- CANONICAL:PITFALLS:END -->
