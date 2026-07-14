# Retention & Compaction Policy — Maintained Master

**Consumers (cite by path, never restate — this file is the sole normative home):**
the evolve-agents, evolve-skills, and evolve-config skills (project-local at the dotfiles
repo's skills home), the evolve-model-distribution skill (same home; optional terminal
compaction step),
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

The agent-facing authoring contract stays append-only for hand edits: agents never
hand-edit or remove prior entries; the sole sanctioned agent-side mutation is
distill-time ledgering (see that section below). Boundedness moves to the evolve-agents
History Compaction phase. Trigger:
decoupled from file size — pitfalls compaction runs in any evolve-agents cycle whose
Phase 1 harvest-outcome report exists, against every entry that qualifies below.
(Rationale: the documented 3-cycle signal re-fire came from a 21-line file, so a
100-line size gate would never activate the fix; per-entry cost is trivial because
triage already happened. A file still exceeding 100 lines after compaction is flagged in
the cycle's final report as undispositioned backlog.) An entry is compactable only when
ALL hold: (a) it received a Phase 1 triage disposition (applied / already-encoded /
Docket-tracked) in this or a previous cycle, per the cycle's harvest-outcome report; (b)
its FULL text is byte-present in `git show HEAD:<file>` (full-entry containment per
invariant check 1); (c) it predates the current cycle. **Entry boundary and
ledger-section grammar** (for selection and parity counting; this is the one grammar
shared by the harvest-then-compact compactor above and the distill-time ledgering script
below): the ledger section is the column-0 heading line `## Harvested ledger
(compacted)`, followed by at most one blank line, followed by a contiguous run of ledger
lines — column-0 lines matching `^- \[[0-9]{4}-[0-9]{2}-[0-9]{2}\] `. The section ends at
the first line after the heading that is neither that single leading blank nor a ledger
line; at most one such section per file. Writer layout invariant (both paths): no blank
lines between ledger lines; exactly one blank line before the heading, one between the
heading and the first ledger line, one after the last ledger line. A new entry begins at
any column-0 line matching `^## ` or `^- ` that is OUTSIDE the ledger section and is not
the H1; it extends to the line before the next entry start, the ledger heading, or EOF;
trailing blank lines belong to the entry; the H1, any intro line, the ledger heading, and
ledger lines are structural, not entries. A `^- [YYYY-MM-DD]` line outside the ledger
section is an ordinary entry start — grammar alone never classifies a line as a ledger
line; only section membership does (this is load-bearing: the centralized
distinguished-engineer file has live entries whose first line matches the ledger-line
date-bracket grammar). Section placement on first creation: immediately after the H1 line
(or at the very top of a no-H1 file). Seam-blank normalization: pre-existing blank
line(s) at the insertion seam are consumed and the layout invariant re-emits exactly one
at each seam position; all original non-blank content stays byte-unchanged.
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

## Distill-time ledgering (edit-time path)

Trigger: the same change that encodes an existing pitfalls entry's resolution into a
git-tracked definition — the fix lands in code, and the pitfalls entry that named the gap
is superseded in the same edit. Distill-time ledgering is the sanctioned mechanism for
retiring that entry immediately, rather than waiting for the next evolve-agents Phase 4
compaction cycle.

The script (`pitfalls_distill.sh`) is the sole mechanism for this path — no hand edits.
It removes the selected entry's narrative text and replaces it with one ledger line under
the `## Harvested ledger (compacted)` section (created on first use per the placement
rule above), mirroring the batch-path ledger format. The script reports the removed
entry's full text on stdout; the caller MUST mirror it into the change's durable record
(commit message, Docket comment, or equivalent) so the narrative is never silently lost.

Both homes are in scope: in-repo `.claude/agent-memory/<role>/pitfalls.md` and
centralized `~/.claude/agent-memory/<role>/pitfalls.md`. The centralized home carries one
additional guard: a centralized entry's `--encoded-in` target must sit under
`src/user/claude-code/` (the deploying tree) — otherwise the script exits 8 rather than
ledgering an entry whose "encoded" definition lives outside the tree that actually ships.

Docket-tracked exclusion: entries disposed as Docket-tracked are NOT distillations — the
fix is tracked but not yet landed, so the entry stays live for the Phase 4 safety net
until the tracked work merges. Distill-time ledgering only ever applies to entries whose
resolution is already a git-tracked definition on disk.

Invariants E0–E4 (edit-time path), mapped against the batch-path checks in the
Lossy-safety invariant section below:

| Compactor check (batch path) | Edit-time equivalent (this path) |
|---|---|
| (0) pure-addition precondition | Not needed: single atomic run on one entry; unrelated content is carried over byte-unchanged by construction (E0) and the write is crash-atomic |
| (1) full-entry HEAD containment | **E1 full-text preservation** — removed entry emitted verbatim on stdout; caller MUST mirror it into the change's durable record; `RECOVERY-CHANNEL: git-history` reported when HEAD containment additionally holds. HEAD containment cannot be a *precondition* here — the files are untracked today and fresh entries are legitimately uncommitted; making it a hard gate would recreate the exact dead-mechanism failure this design fixes |
| — (new) | **E2 encoded-resolution precondition** — the lesson's operative content verifiably persists in a git-*tracked* definition (`--encoded-in` tracked + `--evidence` hit; centralized home additionally requires the deploying tree, exit 8) before the narrative may be removed; the tracked definition becomes the durable carrier, the ledger line the tombstone |
| (2) diff-shape proof | **E0 reconstruction-equivalence** — new file = old file with exactly (i) the selected entry span removed, (ii) the ledger line (+ section heading on first use) inserted per the layout, and (iii) the insertion-seam blank normalized to exactly one; all other bytes identical |
| (3) parity formula | **E3** — entries −1, ledger lines +1, both per the shared grammar (section-terminated, not position-guessed) |
| (4) Trial/Drift preservation | **E4** — identical rule, verbatim in the ledger line, precedence over the 160-char cap |
| (5) budget | Not needed — removal strictly shrinks the file |

Safety-net relationship: the evolve-agents Phase 4 compaction cycle is UNCHANGED by this
section — it selects only un-ledgered entries, remains in-repo-only, and stays inert
until the operator commits the memory tree. Distill-time ledgering and Phase 4
compaction share one ledger format and one entry-boundary grammar (above) but run on
independent triggers.

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
  (`docs/changelog/claude-code/agents/senior-engineer.md` carries three `## 2026-07-10` entries), so a
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
