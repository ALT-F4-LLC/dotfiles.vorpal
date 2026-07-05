# Changelog: code-review-verdict

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

## 2026-06-09

### Summary
Phase 2: renamed code-review → code-review-verdict (bundled-skill collision) and mode-split the vote-escalation bullet in Save & Return.

### Changes
- Renamed skill + directory + all internal self-references; external refs updated across 4 agents and 6 skills (47 occurrences); description gains a bundled-skill disambiguation clause.
- Save & Return vote bullet: team mode now routes via docket vote create + delegation_request (never Skill(vote)); standalone unchanged. Model: design-review's Phase 1 fix.
- When-NOT-to-Use vote bullet left as routing pointer (family decision).

### Dimensions Evaluated
Coherence (Phase 2 lockstep), Orchestration (vote delegation), Rename.

### Rename
Renamed code-review → code-review-verdict. Observable collision with the bundled /code-review skill (supports --fix, edits the working tree — violates this skill's leaf read-only contract). Precedent: verify → verify-ac.

## 2026-06-09

### Summary
Hardened the freshness gate (moving-tree ABORT precondition for orchestrated `uncommitted`/`staged` reviews — cross-project pitfall where reviews fired before implementers finished despite agent-level gates) and added Validation check 10 (citation-presence scan — fabricated-"VERIFIED" defect class). Offset by collapsing the Role Detection table to prose and folding the one-row Failure Modes table into Argument Handling. Net −13 (395/500).

### Changes
- Pre-flight: Moving-tree precondition — under orchestration, ABORT on `uncommitted`/`staged` without an implementation-complete signal (`docket issue show <id> -q` flag live-verified).
- Validation check 10: every Finding citation must name a file in the resolved diff's captured file list.
- Role Detection table → prose; Failure Modes section removed, gh-CLI abort folded into Argument Handling.

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST — net −13), Completeness (freshness gate), Actionability (anti-fabrication), Coherence (COUPLING md5-parity verified), Skill Design ($-audit clean).

### Rename
RENAME RECOMMENDED (reversal of prior cycles): bundled `/code-review` (v2.1.147) collides observably; proposed `code-review-verdict`; execution routed to Phase 2 pending operator decision (~47 refs, 10 files).

## 2026-06-08

### Summary
Phase 1 no-change verdict (highest-traffic skill, 408/500 lines, at local optimum). Verified the partial-tree/scope-timing guard already exists (Pre-flight step 5) — the exact cross-project pitfall flagged this cycle, confirmed NO-OP. COUPLING marker byte-identical across the 4 leaf siblings; G1-G5→senior-engineer principle map resolves.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no net-negative edit without removing load-bearing content), Completeness (partial-tree guard present), Coherence (family parity verified).

### Rename
No rename. Bundled `/code-review` name-collision surfaced to Phase 2 (not self-acted; stability has compounding value).

## 2026-06-05

### Summary
Phase 2 coherence: appended the Doubling-Rule family-parity sentence to the report-emission COUPLING marker (placement already canonical — directly above the When-NOT routes). All 4 family markers now byte-identical.

### Changes
- COUPLING marker: added "The Doubling Rule section is also part of this family — keep its shape in sync across siblings per team-lead Rule 8."

### Dimensions Evaluated
Coherence (report-emission family COUPLING parity with verify-ac/design-qa/design-review).

### Rename
No rename.

## 2026-06-05

### Summary
Trimmed two Doubling-Rule paragraphs (Ephemeral lifecycle + Degraded fallback) that restated team-lead-owned spawn/shutdown/degraded-annotation mechanics verbatim, replacing them with a single calling-layer-ownership pointer to agents/team-lead.md (Rule 8, step 14) — matches the verify-ac family consolidation and removes a duplicated-state drift hazard. Net -2 (401/500).

### Changes
- Doubling Rule: collapsed Ephemeral-lifecycle + Degraded-fallback paragraphs to one team-lead.md ownership pointer; load-bearing single-reviewer-authority fact + 4-parallel topology retained in the opening paragraph.

### Dimensions Evaluated
Over-Engineering (HIGHEST — duplicated team-lead mechanics removed), Coherence (verify-ac family-pattern alignment; drift hazard eliminated). NO-OP verified: $-escape, mid-cycle/partial-tree guard (already encoded), docs/spec tolerance, effort:max, disallowed-tools (prior decline holds).

### Rename
No rename.

## 2026-06-04

### Summary
Added the Phase 0 partial-tree guard (code-review fired mid-cycle on a partial working tree 2x cross-project → stale review) folded into the empty-diff step; de-duplicated an anti-anchoring rationale to a team-lead.md step-14 pointer. Net +2 (403/500, ample headroom).

### Changes
- Pre-flight empty-diff guard: added a partial-tree guard for `uncommitted`/`staged` scopes — a local diff is a point-in-time snapshot, so the skill prefixes the verdict with a files-present / point-in-time line and routes the completeness judgment to the calling agent (which owns AC context) rather than guessing the expected file-set.
- Save & Return: trimmed the duplicated anti-anchoring rationale to a team-lead.md step-14 pointer (directive retained).

### Dimensions Evaluated
Completeness (HIGHEST — partial-tree guard), Over-Engineering (HIGHEST — anti-anchoring rationale de-duplicated to a pointer; net +2 at 403/500), Coherence (anti-anchoring authority owned by team-lead.md).

### Rename
No rename.

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
