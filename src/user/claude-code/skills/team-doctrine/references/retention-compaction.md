# Retention & Compaction Policy — Maintained Master

**Consumers (cite by path, never restate — this file is the sole normative home per
constraint 7 of the ADR citation-distillation TDD):** `.claude/skills/evolve-agents/SKILL.md`,
`.claude/skills/evolve-skills/SKILL.md`, `.claude/skills/evolve-config/SKILL.md`,
`.claude/skills/evolve-model-distribution/SKILL.md` (optional terminal compaction step),
`src/user/claude-code/agents/team-lead.md`, and the `CANONICAL:PITFALLS` block carried by
`references/pitfalls.md` + its 7 claude-code agent carriers. Adopted 2026-06-09; relocated
from the retired decision record 2026-07-09 — that record now carries a demotion banner
and is retained only so the opencode/codex trees' citations keep resolving until their
own distillation cycle. Deployed at
`~/.claude/skills/team-doctrine/references/retention-compaction.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/retention-compaction.md`. Read on
demand only — never `Skill(team-doctrine)`.

---

## Changelog retention policy (per file)

Budget: 300 physical lines (`wc -l`). The orchestrator checks budgets with one `wc -l`
pass; if every changelog is under budget AND the pitfalls arm (below) has nothing
compactable, the phase is a no-op line in the final report and no compactor is spawned.
For an over-budget file: the 10 most recent date-headed entries (count pattern `^## 20`)
are always kept verbatim (keep-window); older entries are compacted oldest-first until
the file is under budget. Each compacted entry is replaced by exactly one ledger line in
a terminal section of the same file:

```markdown
## Compacted history

Entries below were compacted per the retention-compaction policy; full text in git
history (see the compaction entry's date).

- 2026-03-19: Major consolidation pass removing ~400 lines (758 → 361) to meet the
  500-line budget.
- 2026-03-20: <one-line distillation, <=160 chars> | Trial: <hypothesis> → <outcome>
```

`Trial:` and `Drift:` lines are preserved **verbatim** inside the ledger line (the
Innovation Mandate measurement arm depends on them); verbatim preservation takes
precedence over the ≤160-char cap — a Trial- or Drift-carrying ledger line may exceed the
cap, with only the distillation prefix bounded. The compactor also prepends one changelog
entry recording the act: "Compacted N entries (YYYY-MM-DD..YYYY-MM-DD) into Compacted
history per the retention-compaction policy," keeping the audit trail in-band. The
compaction entry is a normal entry in every respect: Changelog Format applies (4 H3
sections, ≤20 lines) and it counts in the parity formula below. The "NEVER modify
existing entries" rule gains exactly one scoped exception: the History Compaction phase
per this policy.

## Pitfalls policy (harvest-then-compact)

The agent-facing authoring contract stays append-only: agents never edit or remove prior
entries. Boundedness moves to the evolve-agents History Compaction phase. Trigger:
decoupled from file size — pitfalls compaction runs in any evolve-agents cycle whose
Phase 1 harvest-outcome report exists, against every entry that qualifies below.
(Rationale: the documented 3-cycle signal re-fire came from a 21-line file, so a
100-line size gate would never activate the fix; per-entry cost is trivial because
triage already happened. A file still exceeding 100 lines after compaction is flagged in
the cycle's final report as undispositioned backlog.) An entry is compactable only when
ALL hold: (a) it received a Phase 1 triage disposition (applied / already-encoded /
Docket-tracked) in this or a previous cycle, per the cycle's harvest-outcome report; (b)
its FULL text is byte-present in `git show HEAD:<file>` (full-entry containment per
invariant check 1); (c) it predates the current cycle. **Entry boundary** (for selection
and parity counting): a new entry begins at any column-0 line matching `^## ` or `^- `
outside the ledger section; it extends to the line before the next such line or EOF; the
H1, any intro line, the ledger heading, and ledger lines are structural, not entries.
Each compacted entry becomes one ledger line under a `## Harvested ledger (compacted)`
section placed immediately below the H1:

```markdown
- [2026-06-04] historical-audit signal re-fires for already-encoded lesson → encoded in
  skills/design-qa (grep-the-target-first rule)
- [2026-06-09] NO-OP verdict citing dead delivery channel → captured as DKT-261
```

Undispositioned entries are never touched. Cross-project pitfalls files (other repos
discovered by the Phase 0 scan) remain read-only ingest — this repo's cycles never edit
them. The ledger doubles as the already-harvested marker, ending the re-fire loop.

## Lossy-safety invariant (mechanically proven per run)

Per file, the compactor's report to the orchestrator MUST evidence, in order:

- **(0) Pure-addition precondition** — before editing, every hunk in `git diff HEAD --
  <file>` is pure addition (this cycle's prepended changelog entry, or pitfalls entries
  appended by agents mid-cycle); any modified or deleted HEAD line aborts compaction for
  that file this cycle. A strict `git diff --quiet HEAD -- <file>` (byte-identical-to-HEAD)
  precondition was considered and rejected as unworkable: Phase 1 prepends an entry to
  every target changelog before the terminal phase runs (and agents append pitfalls
  entries mid-cycle per the CANONICAL block), so byte-identity with HEAD would defer
  compaction forever; pure-addition plus check (1) yields the same recovery guarantee.
- **(1) Full-entry HEAD containment** — every entry selected for compaction is
  byte-present in `git show HEAD:<file>` as its FULL text (every line from heading/bullet
  through entry end). Never a date-string spot-check: date headings are non-unique
  (`docs/changelog/agents/senior-engineer.md` carries six `## 2026-06-09` entries), so a
  date match cannot prove that an uncommitted same-date entry is safe to remove.
- **(2) Diff-shape proof** — after compaction, `git diff HEAD -- <file>` consists SOLELY
  of four hunk shapes: (i) the pre-existing same-cycle pure additions from check 0; (ii)
  deletions exactly matching the selected entries; (iii) additions forming the ledger
  section/lines; (iv) for changelogs, one added compaction entry. Any other change —
  including any touch of a surviving entry between the keep-window and the compacted band
  — fails the check. This is also the byte-untouched proof for all surviving entries:
  their absence from the diff IS the evidence. Accepted mechanization:
  reconstruction-equivalence — byte-equality of the post-compaction file with HEAD content
  minus the selected entries, plus the prepended compaction entry and the ledger
  additions — proves the SOLELY property without enumerating raw diff hunks (git
  context-matching splits hunks on blank lines and same-date headings, making literal
  hunk-shape enumeration unreliable as evidence).
- **(3) Parity formula** — changelogs: with count pattern `^## 20` (date-headed entries
  only; the `## Compacted history` heading does not match), expected after-count =
  before-count − N + 1 (the +1 is the prepended compaction entry), and ledger lines after
  = before + N. Pitfalls: entries per the boundary definition above; after-entries =
  before-entries − N; ledger lines after = before + N.
- **(4) Trial and Drift preservation** — every `Trial:` and `Drift:` line from a
  compacted entry appears verbatim in its ledger line.
- **(5) Budget** — post-compaction `wc -l` under budget, or a stated reason the
  keep-window floor prevents it (changelogs only).

A report failing any check means the orchestrator rejects the compaction; the compactor
reverts its own edits (leaving this cycle's pre-existing additions intact) or the file is
left untouched and flagged in the cycle's final report — never ship a partial compaction
silently.
