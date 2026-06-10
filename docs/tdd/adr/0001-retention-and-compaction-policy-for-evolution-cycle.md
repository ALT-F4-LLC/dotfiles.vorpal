---
project: "main"
last_updated: "2026-06-09"
updated_by: "@staff-engineer"
status: "accepted"
---

# ADR 0001: Retention and Compaction Policy for Evolution-Cycle Historical Data

## Context

The evolve-agents and evolve-skills cycles accumulate unbounded historical data that their own later phases re-consume:

- **Changelogs** — `docs/changelog/agents/*.md` (7 files) + `docs/changelog/skills/*.md` (16 files) total 11,901 lines as of 2026-06-09 (11,995 including the three pitfalls files' 94 lines). The largest (`docs/changelog/agents/senior-engineer.md`) holds 58 entries / 974 lines accumulated since 2026-03-19, with growth accelerating (multiple entries per date on 2026-06-09). Both evolve skills already instruct readers to "Read only the latest entry," but a plain Read of a 974-line file loads the whole file, and Phase 1/Phase 2 reviewers, coherence audits, and rename sweeps repeatedly touch these files.
- **Pitfalls memory** — `.claude/agent-memory/*/pitfalls.md` (currently 94 lines across 3 files in this repo) is unbounded *by design*: the `CANONICAL:PITFALLS` block carried by all 7 `agents/*.md` files mandates "never cleared … ALWAYS APPEND." The evolve-* Phase 0 historical-auditor reads every discovered pitfalls file **fully**, across all repos under `~/Development`, every cycle. The staff-engineer pitfalls file itself records the cost: the same harvested lesson re-fired as an audit signal in 3 consecutive cycles (2026-06-04, -08, -09) because nothing marks an entry as already-harvested.

Two existing mechanisms make a safe compaction possible: (a) changelogs and pitfalls files are regularly committed (e.g., `6ce55cb`, `02ef387`), so git history is a complete archive; (b) the evolve-* Phase 1 triage rule already assigns every harvested pitfalls lesson a disposition — *applied as edit / already-encoded NO-OP / captured as Docket tracking issue / never drop* — which is exactly the "harvested" marker a compaction can key off.

Constraints from existing rules that this decision must reconcile: the Changelog Format rule "NEVER modify, edit, or replace existing changelog entries"; the Phase 1 rule "Never Edit/Write/delete any `pitfalls.md` — it is append-only ingest memory"; rename sweeps scoped to live definition files treat changelogs as frozen historical records (`docs/tdd/team-lead-readonly-orchestration.md:153`); and the Innovation Mandate's measurement arm reads prior-cycle `Trial:` lines from changelog Summary sections. Ownership per team-lead.md §Docs-Path Taxonomy: evolve-agents writes `docs/changelog/agents/`, evolve-skills writes `docs/changelog/skills/`.

## Decision

Add a gated **terminal "History Compaction" phase** (changelog arm gated by line budget; pitfalls arm gated by presence of un-ledgered dispositioned entries) to evolve-agents and evolve-skills (running after Phase 2 coherence, before the final report), executed by an ephemeral `history-compactor` teammate (`senior-engineer`, Bash + Edit) so the orchestrator stays read-only. evolve-agents compacts `docs/changelog/agents/*.md` plus this repo's `.claude/agent-memory/*/pitfalls.md`; evolve-skills compacts `docs/changelog/skills/*.md`. Compaction is **summarize-then-remove, never silent deletion**, and only content reachable at `HEAD` may be compacted (uncommitted entries are never touched, guaranteeing git-history recovery).

**Changelog retention policy (per file).** Budget: 300 physical lines (`wc -l`). The orchestrator checks budgets with one `wc -l` pass; if every changelog is under budget AND the pitfalls arm (below) has nothing compactable, the phase is a no-op line in the final report and no compactor is spawned. For an over-budget file: the 10 most recent date-headed entries (count pattern `^## 20`) are always kept verbatim (keep-window); older entries are compacted oldest-first until the file is under budget. Each compacted entry is replaced by exactly one ledger line in a terminal section of the same file:

```markdown
## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation pass removing ~400 lines (758 → 361) to meet the 500-line budget.
- 2026-03-20: <one-line distillation, <=160 chars> | Trial: <hypothesis> → <outcome>
```

`Trial:` and `Drift:` lines are preserved **verbatim** inside the ledger line (the Innovation Mandate measurement arm depends on them); verbatim preservation takes precedence over the ≤160-char cap — a Trial- or Drift-carrying ledger line may exceed the cap, with only the distillation prefix bounded. The compactor also prepends one changelog entry recording the act: "Compacted N entries (YYYY-MM-DD..YYYY-MM-DD) into Compacted history per ADR 0001," keeping the audit trail in-band. The compaction entry is a normal entry in every respect: Changelog Format applies (4 H3 sections, ≤20 lines) and it counts in the parity formula below. The "NEVER modify existing entries" rule gains exactly one scoped exception: the History Compaction phase per this ADR.

**Pitfalls policy (harvest-then-compact).** The agent-facing authoring contract stays append-only: agents never edit or remove prior entries. Boundedness moves to the evolve-agents History Compaction phase. Trigger: decoupled from file size — pitfalls compaction runs in any evolve-agents cycle whose Phase 1 harvest-outcome report exists, against every entry that qualifies below. (Rationale: the documented 3-cycle signal re-fire came from a 21-line file, so a 100-line size gate would never activate the fix; per-entry cost is trivial because triage already happened. A file still exceeding 100 lines after compaction is flagged in the cycle's final report as undispositioned backlog.) An entry is compactable only when ALL hold: (a) it received a Phase 1 triage disposition (applied / already-encoded / Docket-tracked) in this or a previous cycle, per the cycle's harvest-outcome report; (b) its FULL text is byte-present in `git show HEAD:<file>` (full-entry containment per invariant check 1); (c) it predates the current cycle. **Entry boundary** (for selection and parity counting): a new entry begins at any column-0 line matching `^## ` or `^- ` outside the ledger section; it extends to the line before the next such line or EOF; the H1, any intro line, the ledger heading, and ledger lines are structural, not entries. Each compacted entry becomes one ledger line under a `## Harvested ledger (compacted)` section placed immediately below the H1:

```markdown
- [2026-06-04] historical-audit signal re-fires for already-encoded lesson → encoded in skills/design-qa (grep-the-target-first rule)
- [2026-06-09] NO-OP verdict citing dead delivery channel → captured as DKT-261
```

Undispositioned entries are never touched. Cross-project pitfalls files (other repos discovered by the Phase 0 scan) remain read-only ingest — this repo's cycles never edit them. The ledger doubles as the already-harvested marker, ending the re-fire loop documented in staff-engineer's pitfalls memory.

**Exact replacement language for the `CANONICAL:PITFALLS` block** (all 7 `agents/*.md` carriers, byte-identical; only the final sentence changes — replace "This file is periodically harvested (read for recurring lessons) by the `evolve-*` cycles but is never cleared, so prior entries persist across cycles — ALWAYS APPEND a new entry rather than overwriting, and avoid duplicating lessons already recorded." with):

```markdown
This file is periodically harvested (read for recurring lessons) by the `evolve-*` cycles — ALWAYS APPEND a new entry rather than overwriting, never edit or remove prior entries, and avoid duplicating lessons already recorded (check the harvested ledger too). Boundedness is owned by the evolve-agents History Compaction phase (ADR 0001), which may replace an already-harvested, committed entry with a one-line ledger citation; full text remains recoverable via git history.
```

**Lossy-safety invariant (mechanically proven per run).** Per file, the compactor's report to the orchestrator MUST evidence, in order:

- **(0) Pure-addition precondition** — before editing, every hunk in `git diff HEAD -- <file>` is pure addition (this cycle's prepended changelog entry, or pitfalls entries appended by agents mid-cycle); any modified or deleted HEAD line aborts compaction for that file this cycle. A strict `git diff --quiet HEAD -- <file>` (byte-identical-to-HEAD) precondition was considered and rejected as unworkable: Phase 1 prepends an entry to every target changelog before the terminal phase runs (and agents append pitfalls entries mid-cycle per the CANONICAL block), so byte-identity with HEAD would defer compaction forever; pure-addition plus check (1) yields the same recovery guarantee.
- **(1) Full-entry HEAD containment** — every entry selected for compaction is byte-present in `git show HEAD:<file>` as its FULL text (every line from heading/bullet through entry end). Never a date-string spot-check: date headings are non-unique (`docs/changelog/agents/senior-engineer.md` carries six `## 2026-06-09` entries), so a date match cannot prove that an uncommitted same-date entry is safe to remove.
- **(2) Diff-shape proof** — after compaction, `git diff HEAD -- <file>` consists SOLELY of four hunk shapes: (i) the pre-existing same-cycle pure additions from check 0; (ii) deletions exactly matching the selected entries; (iii) additions forming the ledger section/lines; (iv) for changelogs, one added compaction entry. Any other change — including any touch of a surviving entry between the keep-window and the compacted band — fails the check. This is also the byte-untouched proof for all surviving entries: their absence from the diff IS the evidence. Accepted mechanization: reconstruction-equivalence — byte-equality of the post-compaction file with HEAD content minus the selected entries, plus the prepended compaction entry and the ledger additions — proves the SOLELY property without enumerating raw diff hunks (git context-matching splits hunks on blank lines and same-date headings, making literal hunk-shape enumeration unreliable as evidence).
- **(3) Parity formula** — changelogs: with count pattern `^## 20` (date-headed entries only; the `## Compacted history` heading does not match), expected after-count = before-count − N + 1 (the +1 is the prepended compaction entry), and ledger lines after = before + N. Pitfalls: entries per the boundary definition above; after-entries = before-entries − N; ledger lines after = before + N.
- **(4) Trial and Drift preservation** — every `Trial:` and `Drift:` line from a compacted entry appears verbatim in its ledger line.
- **(5) Budget** — post-compaction `wc -l` under budget, or a stated reason the keep-window floor prevents it (changelogs only).

A report failing any check means the orchestrator rejects the compaction; the compactor reverts its own edits (leaving this cycle's pre-existing additions intact) or the file is left untouched and flagged in the cycle's final report — never ship a partial compaction silently.

## Consequences

**Positive.** Steady-state full-text changelog corpus is capped at ~6,900 lines (23 × 300) versus today's 11,901 — a 42.0% reduction and a ceiling on full-text entries for every future Phase 0/1/2 read. (Ledger sections still grow, one line per compacted entry — slow, but not zero; a future amendment may consolidate ledger lines older than a year into per-quarter date-range rollups.) Pitfalls files stop re-firing harvested lessons (3-cycle waste documented) because the ledger marks disposition. Recovery is total: every compacted byte is in git history, findable via the in-band compaction entry's date range and `git log -S`. The orchestrator's read-only contract is preserved (ephemeral compactor does the edits). The gate check itself stays cheap: one `wc -l` pass for changelogs plus a scan of the cycle's own harvest-outcome report for the pitfalls arm.

**Negative / harder.** Two long-standing "never edit history" rules gain a scoped exception each, which weakens their absolute simplicity — mitigated by the pure-addition precondition, full-entry HEAD containment, and the diff-shape proof. Distilling an entry to a ≤160-char ledger line is lossy by construction; a future audit needing full text must do a git-history lookup instead of a working-tree read. The 7-file CANONICAL block edit must land byte-identically (parity-bound family edit, one turn, byte-identity verification per the existing evolve-skills Phase 2 idiom).

**Neutral.** `docs/changelog/` remains excluded from live-definition rename sweeps; ledger lines are historical records like the entries they replace. Out of scope per the brief: evolve-coherence, non-pitfalls agent memory (MEMORY.md, user/feedback/project memories), Docket history, git history. Implementation touches exactly: `.claude/skills/evolve-agents/SKILL.md` (new phase, two rule amendments, task-list and final-report additions), `.claude/skills/evolve-skills/SKILL.md` (new phase, one rule amendment, task-list and final-report additions), and the 7 `agents/*.md` CANONICAL:PITFALLS carriers.

## Alternatives Considered

- **Archive files** (`docs/changelog/archive/…`) instead of git-history recovery — rejected: archive files re-enter `ls`/Glob/grep scans and full-file Reads, defeating the context-reduction goal while duplicating what git already stores.
- **Delete-after-N-days with no summary** — rejected: violates lossy-safety; `Trial:` measurement, "already-encoded" NO-OP verdicts, and rename-precedent citations all depend on historical one-liners surviving.
- **Reader-side discipline only** (ranged Reads, `head -N`, no file mutation) — rejected as the sole fix: "read only the latest entry" is already mandated and demonstrably insufficient (Phase 0 pitfalls full-reads are required by design; full-file Reads keep happening), and it does nothing about unbounded growth.
- **Agent-side per-entry TTL in pitfalls** (each agent prunes its own file) — rejected: distributes write authority across all agents, races the append-only contract, and loses the disposition linkage that makes compaction provably safe; a single-owner terminal phase is auditable.
