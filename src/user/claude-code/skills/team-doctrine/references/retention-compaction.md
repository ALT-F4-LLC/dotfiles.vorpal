# Retention & Compaction Policy — Maintained Master

Sole normative home for its gate formulas, ledger formats, and invariants — consumers (the
evolve-* skills, `team-lead.md`, and `references/pitfalls.md`'s carriers) cite by path,
never restate. Deployed at
`~/.claude/skills/team-doctrine/references/retention-compaction.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/retention-compaction.md`.

---

## Changelog retention policy (per file)

Budget: 300 physical lines (`wc -l`). The orchestrator checks budgets with one `wc -l`
pass; if every changelog is under budget AND the pitfalls arm has nothing compactable, the
phase is a no-op line in the final report and no compactor is spawned. For an over-budget
file: the 10 most recent date-headed entries (count pattern `^## 20`) are always kept
verbatim (keep-window); older entries are compacted oldest-first until under budget. Each
compacted entry is replaced by exactly one ledger line in a terminal `## Compacted history`
section of the same file:

```markdown
## Compacted history

Entries below were compacted per the retention-compaction policy; full text in git
history (see the compaction entry's date).

- 2026-03-20: <one-line distillation, <=160 chars> | Trial: <hypothesis> → <outcome>
```

`Trial:` and `Drift:` lines are preserved **verbatim** inside the ledger line (the
Innovation Mandate measurement arm depends on them); verbatim preservation takes precedence
over the ≤160-char cap. The compactor also prepends one changelog entry recording the act
("Compacted N entries (YYYY-MM-DD..YYYY-MM-DD) into Compacted history…") — a normal entry
in every respect (Changelog Format applies; it counts in the parity formula). The "NEVER
modify existing entries" rule has exactly one scoped exception: the History Compaction
phase per this policy.

## Pitfalls policy (harvest-then-compact)

The authoring contract stays append-only for hand edits; the sole agent-side mutation is
distill-time ledgering (below). Boundedness lives in the evolve-agents History Compaction
phase, which runs in any cycle whose Phase 1 harvest-outcome report exists (decoupled from
file size). An entry is compactable only when ALL hold: (a) it received a Phase 1 triage
disposition (applied / already-encoded / Docket-tracked) in this or a previous cycle; (b)
its FULL text is byte-present in `git show HEAD:<file>` (invariant check 1); (c) it
predates the current cycle. Undispositioned entries are never touched. Cross-project
pitfalls files (other repos discovered by the Phase 0 scan) are read-only ingest — this
repo's cycles never edit them. The ledger doubles as the already-harvested marker, ending
signal re-fires. A file still exceeding 100 lines after compaction is flagged in the
cycle's final report as undispositioned backlog.

**Entry boundary and ledger-section grammar** (shared by the batch compactor and
`pitfalls_distill.sh`; implemented identically in `pitfalls_compactable.sh` and
`pitfalls_distill.sh`, guarded by the fixture-driven parity test
`test_pitfalls_compactable.py::test_cross_script_entry_count_parity`):

- The ledger section is the column-0 heading `## Harvested ledger (compacted)`, at most one
  leading blank line, then a contiguous run of ledger lines — column-0 lines matching
  `^- \[[0-9]{4}-[0-9]{2}-[0-9]{2}\] `. At most one section per file; it ends at the first
  line that is neither the single leading blank nor a ledger line.
- A new entry begins at any column-0 `^## ` or `^- ` line OUTSIDE the ledger section that is
  not the H1; it extends to the next entry start, the ledger heading, or EOF. A `^## `
  heading absorbs its immediately-following contiguous run of `^- ` bullets into the SAME
  entry (tolerating at most one blank line between heading and first bullet); a bare `^- `
  line not preceded by such a heading is its own single-line entry. Grammar alone never
  classifies a line as a ledger line — only section membership does (load-bearing: live
  entries exist whose first line matches the date-bracket shape).
- Placement on first creation: immediately after the H1 (or at the top of a no-H1 file).
  Layout invariant (both paths): no blank lines between ledger lines; exactly one blank
  before the heading, one between heading and first ledger line, one after the last;
  pre-existing seam blanks are consumed and re-emitted as exactly one.

## Distill-time ledgering (edit-time path)

Trigger: the same change that encodes an existing pitfalls entry's resolution into a
git-tracked definition. `pitfalls_distill.sh` is the sole mechanism — no hand edits. It
removes the selected entry and inserts one ledger line (creating the section on first use
per the placement rule), reporting the removed entry's full text on stdout; the caller MUST
mirror it into the change's durable record (commit message, Docket comment, or equivalent).
Both homes are in scope; the centralized home carries one extra guard: `--encoded-in` must
sit under `src/user/claude-code/` (the deploying tree), else the script exits 8.
Docket-tracked dispositions are NOT distillations — the fix is tracked but not landed, so
the entry stays live for the Phase 4 safety net.

Invariants E0-E4 (edit-time path), mapped against the batch-path checks below:

| Batch-path check | Edit-time equivalent |
|---|---|
| (0) pre-edit snapshot | not needed — single atomic run; unrelated content carried byte-unchanged by construction |
| (1) full-entry HEAD containment | **E1 full-text preservation** — removed entry emitted verbatim on stdout, mirrored by the caller; `RECOVERY-CHANNEL: git-history` reported when HEAD containment additionally holds (not a precondition — fresh entries are legitimately uncommitted) |
| — | **E2 encoded-resolution precondition** — the lesson's operative content verifiably persists in a git-tracked definition (`--encoded-in` tracked + `--evidence` hit; centralized home also requires the deploying tree, exit 8) before the narrative may be removed |
| (2) diff-shape proof | **E0 reconstruction-equivalence** — new file = old file with exactly the entry span removed, the ledger line (+heading on first use) inserted, and the seam blank normalized; all other bytes identical |
| (3) parity formula | **E3** — entries −1, ledger lines +1, per the shared grammar |
| (4) Trial/Drift preservation | **E4** — verbatim in the ledger line, precedence over the 160-char cap |
| (5) budget | not needed — removal strictly shrinks the file |

The evolve-agents Phase 4 compaction cycle is unchanged by this path — it selects only
un-ledgered entries, remains in-repo-only, and stays inert until the operator commits the
memory tree; the two paths share one ledger format and one grammar but run on independent
triggers.

## Lossy-safety invariant (mechanically proven per run)

Per file, the compactor's report to the orchestrator MUST evidence, in order:

- **(0) Pre-edit snapshot precondition** — capture the file's current content before
  editing; check (2) proves reconstruction-equivalence against this snapshot, not against
  `git diff HEAD` (prior uncommitted compactions make diff-purity unsatisfiable, while HEAD
  containment under check (1) still holds for every previously-removed entry).
- **(1) Full-entry HEAD containment** — every entry selected for compaction is byte-present
  in `git show HEAD:<file>` as its FULL text. Never a date-string spot-check: date headings
  are non-unique, so a date match cannot prove an uncommitted same-date entry safe to
  remove.
- **(2) Diff-shape proof** — the post-compaction file differs from the snapshot SOLELY by
  (i) deletions exactly matching the selected entries, (ii) additions forming the ledger
  section/lines, (iii) for changelogs, one added compaction entry. Accepted mechanization:
  reconstruction-equivalence (byte-equality with snapshot minus selected entries plus the
  additions) — git hunk enumeration is unreliable as evidence. Surviving entries' absence
  from the diff IS their byte-untouched proof.
- **(3) Parity formula** — changelogs: with count pattern `^## 20`, after-count =
  before-count − N + 1 (the +1 is the prepended compaction entry); ledger lines after =
  before + N. Pitfalls: entries per the boundary grammar; after = before − N; ledger lines
  after = before + N.
- **(4) Trial and Drift preservation** — every `Trial:`/`Drift:` line from a compacted
  entry appears verbatim in its ledger line.
- **(5) Budget** — post-compaction `wc -l` under budget, or a stated reason the keep-window
  floor prevents it (changelogs only).

A report failing any check → the orchestrator rejects the compaction; the compactor reverts
its own edits or the file is left untouched and flagged in the final report — never ship a
partial compaction silently.
