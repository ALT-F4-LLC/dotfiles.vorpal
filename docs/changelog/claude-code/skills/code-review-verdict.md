# Changelog: code-review-verdict

## 2026-07-15 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-06-05..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-15

### Summary
Phase 3 disambiguation: replaced the two-valued "(both roles)" parentheticals with "(both playbooks)" so the three-caller role model (staff/distinguished/security) reads unambiguously against the new Review evidence gates. Findings: 2 → 1 sub / 1 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE] Review evidence gates bullet: "(both roles)" → "(both playbooks)" — removes the reading that the gates exclude a @distinguished-engineer caller (DISAMBIG 2, multi-reading).
- AMPLIFY[COSMETIC] Common Discipline heading: "(both roles)" → "(both playbooks)" — keeps the section parenthetical consistent with the fixed bullet (DISAMBIG 3, multi-reading).

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership)

### Rename
No rename.

## 2026-07-15

### Summary
Absorbed the 4 role-agnostic review evidence gates (stale-cached-test-results, empty-diff triage triple, sandbox-signature-before-attribution, hollow-green CI) into Common Discipline (H3), and made the audit_snapshot.sh census repo-root-relative + hard-fail-proof for cross-repo invocation (H4). Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: New "Review evidence gates (both roles)" bullet-group under Common Discipline — 4 gates extracted from distinguished-engineer.md's Review-evidence-gates section (H3, innovation-scanner I11 / DKT-335 AC1).
- AMPLIFY[SUBSTANTIVE]: Pre-flight step-4 census now resolves audit_snapshot.sh via `git rev-parse --show-toplevel` (repo-root first, home fallback) guarded with `2>/dev/null || true` (H4, bug-auditor PREVENT 8 / DKT-335 AC3-4).

### Dimensions Evaluated
Actionability, Completeness, Coherence.

### Rename
No rename.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-04..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Fixed a report-lint staging-file collision on doubled/3-way review panels (H17): parallel reviewers share one `$TMPDIR` and a fixed `review.md` name races, causing the validator to lint the wrong reviewer's body. Staging file now allocated per-invocation with `mktemp`. H15/H16 confirmed already-fixed (Pre-Injected section removed 2026-07-12) — no action. Findings: 5 → 1 sub / 0 cos / 0 rej / 1 def / 2 enc

### Changes
- FIX[SUBSTANTIVE]: Validation-Before-Emit staging file → unique `mktemp "$TMPDIR/review-XXXXXX.md"` (was fixed `$TMPDIR/review.md`) — cited historical-auditor H17 (parallel-panel scratchpad collision).

### Dimensions Evaluated
Orchestration & Agent Teams (primary); Completeness. Already-encoded (no action): H15/H16 (`## Pre-Injected Diff-Scope Context` removed 2026-07-12). Deferred: I38 (g5_check.sh — script-authoring). Parity-bound: I39 (CANONICAL:SILENT-COMPLETION).

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): pinned the general-track banner literal for @distinguished-engineer callers; corrected a stale line-number citation.

### Changes
- AMPLIFY[SUBSTANTIVE]: Pre-flight step 3 — the `## Review (general — @staff-engineer)` heading is a fixed TRACK literal emitted VERBATIM by @distinguished-engineer (report_lint.py's CRV_GENERAL banner regex accepts only that banner); author identity rides the delivering SendMessage.
- FIX: replaced stale `distinguished-engineer.md:140` line citation with a content anchor (`§Mode 2 — Code review`) — line 140 had drifted to an unrelated bullet.

### Dimensions Evaluated
Disambiguation (multi-reading); Coherence (reference accuracy).

### Rename
No rename.

## 2026-07-12

### Summary
Root-cause fix for the ~32% skill-load failure class reported by 3 independent Phase 0 auditors: the literal `<command>`-placeholder instance was already fixed at commit ca3f70f (2026-07-11), but the whole `!`command`` auto-injection mechanism remained a live residual risk (cannot degrade gracefully — harness aborts the WHOLE skill load on any failure) and was redundant with Pre-flight step 4 + team-lead's shared brief. Removed it; folded an agent-run, gracefully-degrading census into step 4. Also closed the uncommitted-scope untracked-files gap. Findings: 3 → 2 sub / 0 cos / 0 rej / 1 def / 2 enc

### Changes
- CULL[SUBSTANTIVE]: removed `## Pre-Injected Diff-Scope Context` (3 `!`command`` lines aborted the whole load on any failure; census was redundant with Pre-flight step 4 + Rule-8 shared brief) — cited historical-auditor (5+ live-reproduced sessions), bug-auditor (PREVENT 6), model-routing-auditor (32% error rate, proportional across model tiers)
- AMPLIFY[SUBSTANTIVE]: Pre-flight step 4 now runs the census as agent Bash (missing `audit_snapshot.sh` = N/A, not fatal) + `uncommitted`/`staged` scope-resolution row adds `git status --short` for untracked `??` files

### Dimensions Evaluated
Operations/Coherence/Over-Engineering (primary — root-cause removal of a load-failure class). Already-encoded (no action): the `<command>` literal-placeholder instance (ca3f70f) and the `audit_snapshot.sh` repo-relative path (c2c09f4) were both already fixed. Deferred cross-cutting: `report_lint.py` shared Validation-Before-Emit validator (4 skills: code-review-verdict, verify-ac, design-review, design-qa). Flagged (config-owned, out of scope): SubagentStop-hook silent-completion enforcement → route to evolve-config.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 3 disambiguation: added a description clause distinguishing code-review-verdict (in-context verdict) from review-and-comment (posts inline PR comments), restoring reciprocity with review-and-comment's existing back-reference.

### Changes
- Description: appended "emits a verdict into context only; to post inline PR comments use Skill(review-and-comment)" — resolves shared "review this PR" trigger overlap (overlapping-ownership). Placed in description, not the family-lockstepped When-NOT-to-Use list, to preserve report-emission-family parity.

### Dimensions Evaluated
Disambiguation (overlapping-ownership). Confusable-name and multi-reading: none found.

### Rename
No rename.

## 2026-07-10

### Summary
Folded the redundant @distinguished-engineer playbook-mapping parenthetical in Pre-flight step 3 into the selection sentence's label — the parenthetical restated the preceding sentence; its unique content (severity/output extension) preserved inline. Net -79.

### Changes
- CULL: collapsed the distinguished→staff restatement parenthetical into the Playbook-selection label — cited Over-Engineering-HIGHEST + self-evident intra-step restatement.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST) primary. Cross-cutting validate_report.py proposal (spans 5 report-emission skills) routed to Phase 2.

### Rename
No rename.

## 2026-06-30

### Summary
Added vote-compatible Findings JSON contract while keeping skill at 393 lines.

### Changes
- AMPLIFY: added Staff/Security Findings JSON blocks and parse/count validation.
- CULL: compressed duplicated delivery/vote routing prose.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-20

### Summary
Over-engineering merge; net -2 (398→396). Doubling Rule + silent-completion self-check deferred to Phase 2 (family-wide).

### Changes
- CULL: merged the Partial-tree + Moving-tree Pre-flight guards into one Snapshot-tree guard — both addressed the same "uncommitted/staged diff is an incomplete point-in-time snapshot" premise with duplicated framing; merged form keeps both behaviors (ABORT under orchestration; one-line caveat standalone). Verified non-parity (unique to this skill — only sibling reviewing a moving code tree).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename (trigger already disambiguates from the bundled /code-review).

## 2026-06-19

### Summary
Added a G5 Round-N carry-forward rule to cut redundant regex re-execution on the dominant fix→re-review loop.

### Changes
- AMPLIFY (Round-N Re-Review): a prior-round G5 PASS is reusable without re-running the regex only when `git diff --stat` shows the AC regex block AND its named target files untouched since that round; prior G5 Blockers are never carried forward. Mirrors verify-ac §3a. Net +1.
- AMPLIFY (Output Contract): added a classifier-block fallback — if the Stage-2 auto-mode classifier blocks invocation, render the review per THIS format authority (banner + required sections + verdict ladder). Phase-2 family extension of verify-ac's measured fallback. Net +1.
- Drift (rate 7): all 7 SKIP — every target is a format-authority output-template line.

### Dimensions Evaluated
Over-Engineering, Actionability, Completeness, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes (396/500). Both Phase 0 focus signals verified already-resolved against live content.

### Changes
- None (NO-OP verdict). Vote mode-split correct at L387 (team: docket vote create + delegation_request); rename-collision contract re-confirmed vs LIVE bundled /code-review (--fix present). Innovation suggestions (!injection, format.md extraction, round=N) reject-class: net-new surface, zero cross-skill adoption, no failure signal.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no addition earns its offset); Coherence (silent-completion family-phrasing variance routed to Phase 2); Rename (live skill-listing check).

### Rename
No rename. Deliberate rename away from bundled /code-review stands.

## 2026-06-10

### Summary
Compacted 9 entries (2026-05-16..2026-05-30) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes (396/500). Highest-usage skill in window (8 sessions, 26 invocations, zero corrections). Recall fix verified applied to BOTH playbooks (L169 Common Discipline with general/security callouts; zero residual self-filter phrasing). Post-compaction ordering measured: ladders ~4k tokens deep, gates at ~5.5k — already front-loaded optimally.

### Changes
- None (NO-OP verdict). `round=N` arg and batched-validation-grep innovations declined (net new surface, no offsetting removal, no failure signal).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST); Completeness (recall coverage grep-verified); Coherence (docket refs verified vs --help; SILENT-COMPLETION drift + design-review gap routed to Phase 2).

### Rename
No rename. Deliberate rename away from bundled /code-review stands.

## 2026-06-09

### Summary
Compacted 5 entries (2026-05-09..2026-05-16) into Compacted history per ADR 0001.

### Changes
- Replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Coherence fix: corrected stale `G{1..4}` → `G{1..5}` in the Overrides Recognized output template (L241) — the lone G-range token left un-updated when G5 was added; all other refs already read G1..G5. Net 0 (396 lines, orchestrator-verified post-apply).

### Changes
- Overrides Recognized template gate range `G{1..4}` → `G{1..5}` so a recognized G5 override has a template slot (verified: L241 was the only stale token).

### Dimensions Evaluated
All 8; Coherence (inverted-scope G-range sweep); vote mode-split verified present at L387 (NO-OP); rename-collision sweep clean — bundled /code-review rationale intact.

### Rename
No rename.

## 2026-06-09

### Summary
Recall fix for Fable/Opus-4.8-class literal instruction-following: replaced the lone severity FILTER (Common Discipline "Calibrate to value… skip stylistic") with a report-every-finding mandate — findings always surface with severity + confidence; filtering relocated downstream (team-lead step 14 / operator). Severity ladders untouched. Net +2 (396 lines).

### Changes
- Common Discipline: "Calibrate to value / Skip stylistic preferences and what cargo clippy/audit should catch" → "Report every finding — do NOT self-filter": all issues reported (incl. low-severity/uncertain) tagged severity + confidence; linter-catchable issues become Suggestion/Info rather than omitted; downstream owns filtering.

### Dimensions Evaluated
Skill Design Quality (recall-suppression removal), Over-Engineering, Actionability, Coherence, Reasoning-echo audit (clean), Spec Alignment.

### Rename
No rename. Rename-away-from-/code-review collision note verified still accurate (bundled skill ships --fix).

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-09: Initial creation (as code-review): shared review format authority — role-gated staff/security playbooks, severity ladders, validation; agents point to it.
- 2026-05-09: Role Detection restricted to the two real caller identifiers; review-strategy.md added to staff pre-flight; reviewer reconciliation promoted to first duty.
- 2026-05-09: Added scope-detection ambiguity rules and 50-file escalation hint; Validation references Output Contract; Failure Modes trimmed to new-abort-text rows.
- 2026-05-13: Empty-diff guard moved ahead of spec reads; spec reads scoped to changed domains; security-handoff escalation; Recommendation→Vote Verdict mapping added.
- 2026-05-16: Added 'Code review emitted ({recommendation}).' confirmation line with validation check 7; trimmed two Pre-flight/When-NOT redundancies.
- 2026-05-16: Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract (added to design-review this cycle); Save & Return collapsed t...
- 2026-05-17: Trimmed 12-principle restatement in Code Quality dimension (skill already pointed to senior-engineer.md as full text); documented R1+R2 re-invocation pattern...
- 2026-05-18: Added Epistemic Discipline enforcement to Common Discipline + Validation Before Emit (banned-words check propagates the agent-level rule into the review-outp...
- 2026-05-20: Trimmed redundancies surfaced by historical audit (115 invocations across 12 sessions; 30x/19x/14x re-invocation patterns): removed Pre-flight doubling-rule...
- 2026-05-25: Phase 2 coherence: trimmed AskUserQuestion structural-contract restatement to point at the calling agent's contract (lockstep with design-qa/verify).
- 2026-05-25: Two pitfall-driven additions from highest-usage skill (186 sessions, 208 calls): added explicit silent-completion self-check to Save & Return (staff-engineer...
- 2026-05-28: Standardized the multi-file argument grammar (top historical inconsistency — 3 call forms), added a compact Round-N re-review output for the dominant fix→re-...
- 2026-05-29: Fixed a markdown run-on-bullet defect in When-to-Use and repointed it at the authoritative Round-N section; tightened the Save & Return silent-completion par...
- 2026-05-30: Added a finding-sourcing (anti-fabrication) discipline to the Review Procedure — the file had no procedural guard against the cycle's #1 failure class (findi...
- 2026-06-04: Added Phase 0 partial-tree guard (mid-cycle fire → stale review) to empty-diff step; anti-anchoring rationale → team-lead.md pointer.
- 2026-06-05: Trimmed two Doubling-Rule paragraphs (Ephemeral lifecycle + Degraded fallback) to a team-lead.md Rule 8 pointer, matching verify-ac consolidation.
- 2026-06-05: Phase 2 coherence — appended Doubling-Rule family-parity sentence to report-emission COUPLING marker; all 4 family markers byte-identical.
- 2026-06-08: Phase 1 no-change verdict (408/500 lines) — verified partial-tree/scope-timing guard already exists (Pre-flight step 5); bundled /code-review name-collision surfaced to Phase 2.
- 2026-06-09: Hardened freshness gate (moving-tree ABORT precondition) + added Validation check 10 (citation-presence scan); collapsed Role Detection table to prose. Net -13 (395/500).
- 2026-06-09: Phase 2 — renamed code-review → code-review-verdict (bundled-skill collision, 47 refs across 4 agents/6 skills); mode-split vote-escalation bullet in Save & Return.
