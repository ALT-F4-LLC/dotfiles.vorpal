---
project: "main"
last_updated: "2026-07-05"
updated_by: "@staff-engineer"
status: "accepted"
---

# ADR 0003: Centralized vs In-Repo Split for Recurring-Pitfalls Memory

## Context

Every team agent maintains a recurring-pitfalls memory file written before shutdown — the `symptom → root cause → resolution` lesson store harvested by the `evolve-*` cycles. Originally this had a single home: the git-tracked in-repo path `.claude/agent-memory/{role}/pitfalls.md`. That single home conflates two kinds of lesson: those true only of *this* codebase (its build/test/layout/config) and those that generalize to an agent doing the same role in *any* repository (harness quirks, orchestration stalls, skill/tool behavior). A cross-repo lesson stored in-repo is invisible to the same agent working elsewhere, so it gets re-learned per repository; a repo-specific lesson stored globally pollutes every other repo's context and loses git-tracked review.

To resolve that, a content-based split into two homes was introduced and is already **operative**: the classification test and both paths live verbatim in the `CANONICAL:PITFALLS` block mastered at `src/user/claude-code/skills/team-doctrine/references/pitfalls.md` (deployed to `~/.claude/skills/team-doctrine/references/pitfalls.md`), and the decision is cited by `references/pitfalls.md:15` plus 7 agent definitions (`staff-engineer.md`, `security-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`, `distinguished-engineer.md`, `team-lead.md`). Those 8 citations reference "ADR-0003" by path, but the file was never written — the number was reserved and left dangling (ADR-0004's *Numbering deviation* note deliberately skipped 0003 to keep it free for exactly this backfill).

This ADR is that backfill: a post-hoc record of an already-operative, non-contested decision, authored so its 8 existing citations resolve against a real file. It is analogous to ADR-0002, which was likewise authored post-rollout at `status: accepted` because the decision was already reviewed and live. It records existing policy verbatim from the operative master — it does not introduce or re-derive one. Discovery context: flagged by a Vote reviewer during DKT-V5 as an out-of-scope documentation-integrity gap; tracked and backfilled under DKT-46. Related master relocation: the `CANONICAL:PITFALLS` block was moved from `team-lead.md` into the team-doctrine references home in a prior Docket instance (see `git log -- src/user/claude-code/skills/team-doctrine/references/pitfalls.md` for the relocation history).

## Decision

Recurring-pitfalls lessons split by **content** into two homes per role, and each lesson is written to **exactly one** home — never both. The write-time classification test is a single question: *"Would this lesson help an agent in my role working in a DIFFERENT repository?"*

- **YES → centralized** `~/.claude/agent-memory/{role}/pitfalls.md` (`$HOME`-rooted, per-user runtime state, not git-tracked): lessons about the agent, its orchestration, the harness/skills, or a cross-repo tool. The classification is decided by **root cause, not symptom** — a lesson with both a general root cause and a repo-specific instantiation files centralized only.
- **NO → in-repo** `.claude/agent-memory/{role}/pitfalls.md` (git-tracked, shared with the team via version control): lessons true only of this codebase's build/test/layout/config.

Lessons are appended in `symptom → root cause → resolution` form (`mkdir -p` the target dir if absent). The write is skipped entirely when nothing recurring surfaced — per-issue/per-cycle detail belongs in Docket, not here. The `CANONICAL:PITFALLS` master remains the single source of truth for the exact wording; this ADR records the decision, not a second copy of the operative text.

## Consequences

**Positive.** Cross-repo lessons are learned once and available to the role everywhere; repo-specific lessons stay scoped to the repo that owns them and remain git-reviewable. The single-home-per-lesson rule (decided by root cause) keeps the `evolve-*` harvest from double-counting the same lesson across both homes. The classification test is one question an agent can answer at write time without cross-referencing.

**Negative / harder.** There are now two files per role to reason about, and a write must classify before appending — a mis-classification (e.g., filing a harness lesson in-repo) hides a generalizable lesson from other repos. Because the "single home, never both" rule forbids dual-writing, a lesson that is genuinely borderline must still be forced to one side by the root-cause tiebreaker rather than hedged into both.

**Neutral — boundedness differs by home.** The two homes have different growth-control owners, and citing files depend on this asymmetry:

- The **in-repo** home is owned by the evolve-agents History Compaction phase (per ADR-0001): an already-harvested, committed entry may be replaced with a one-line ledger citation, with full text recoverable via git history.
- The **centralized** home is per-user runtime state with **no git-backed recovery**, so it has **no compaction owner** — its growth is bounded solely by the write gate (append only when a recurring pitfall surfaces) and it stays read-only ingest for the harvest.

Both homes are ALWAYS APPEND — never edit or remove prior entries — and both are periodically harvested by the `evolve-*` cycles, so a writer must also avoid duplicating a lesson already recorded (including in the harvested ledger).

## Alternatives Considered

- **Single in-repo home for everything (the pre-split status quo).** Rejected: cross-repo lessons stored in a repo are invisible to the same role working elsewhere and get re-learned per repository, while the same store forces per-user harness quirks into version control where they are noise for every other contributor.
- **Centralize everything in `$HOME`.** Rejected: repo-specific build/test/layout lessons lose git-tracked team review and pollute every unrelated repo's context; the in-repo home exists precisely to keep those lessons local and reviewable.
- **Dual-write borderline lessons to both homes.** Rejected: duplication makes the `evolve-*` harvest double-count and creates two entries that can drift; the root-cause tiebreaker forces a single home instead, keeping each lesson canonical in exactly one place.
