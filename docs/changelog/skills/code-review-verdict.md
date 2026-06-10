# Changelog: code-review-verdict

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

## 2026-05-30

### Summary
Added a finding-sourcing (anti-fabrication) discipline to the Review Procedure — the file had no procedural guard against the cycle's #1 failure class (findings asserted "VERIFIED from real diff" that did not exist in the diff). Corrected the Doubling Rule to the Rule 8 default and trimmed restatement to offset.

### Changes
- Review Procedure: new "Finding-sourcing discipline" paragraph — write each finding only from that file's complete solo-rendered diff this turn; a cancelled/empty batch member means UNVERIFIED, not unchanged; prefer git diff/Read over grep -n; never carry an expected-change guess forward as "verified".
- Doubling Rule: reframed to team-lead.md Rule 8 default-single/opt-up-doubled (was "≥2 per phase" default — an inversion shared with design-qa/design-review); trimmed reconciliation merge-mechanics to a step-14 pointer.
- Degraded fallback: dropped the non-actionable "recurring fallbacks = evolve signal" meta-note.

### Dimensions Evaluated
Completeness + Skill Design (anti-fabrication gate — highest empirical signal), Over-Engineering (HIGHEST — two trims offset the addition), Coherence (Rule 8 default alignment with design-qa/design-review), Actionability, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Fixed a markdown run-on-bullet defect in When-to-Use and repointed it at the authoritative Round-N section; tightened the Save & Return silent-completion paragraph; dropped a redundant Failure Modes row already enforced by Validation check-3.

### Changes
- When to Use: fixed run-on bullet (Re-invocation was jammed onto the prior bullet with no newline); now points at Output Contract → Round-N, de-duping the Round-N section.
- Save & Return: trimmed the triple-stated SendMessage-is-deliverable directive to two sentences; kept the family-wide silent-completion pitfall note.
- Failure Modes: removed the cross-mixed-ladder row (duplicate of Validation check-3, same abort shape; violated the table's "new abort text only" promise).
- Declined `disallowed-tools` (clears-on-next-message risks suppressing the mandated post-skill SendMessage); `/code-review` bundled-skill namespace collision flagged for Phase 2.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 3 trims), Skill Design Quality (run-on defect, disallowed-tools decision), Coherence (Round-N de-dup, Failure Modes/Validation overlap, namespace collision), Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename — highest-volume skill; name accurate, stability load-bearing. The bundled `/code-review` collision is a Phase-2 item.

## 2026-05-28

### Summary
Standardized the multi-file argument grammar (top historical inconsistency — 3 call forms), added a compact Round-N re-review output for the dominant fix→re-review loop (28 sessions), repointed dead `docs/tdd/reviewer-doubling-lifecycle.md` citations to `agents/team-lead.md` Rule 8 / step 14 (verified the file is absent), and fixed stale G1..G4 → G1..G5. Net +1 (additions offset by 2 redundant-block removals).

### Changes
- Argument Handling: path-list normalization (strip `files`/`files:`, split on comma/whitespace) + richer argument-hint — collapses `path path`, `files path path`, `files: path, path` to one grammar.
- Output Contract: compact Round-N re-review format (Prior Findings Disposition / New Findings delta / Recommendation) + Validation check-2 carve-out.
- Coherence: dead doubling-TDD refs → `agents/team-lead.md` Rule 8 + step 14; G1..G4 → G1..G5 (two stale spots).
- Over-Engineering offsets: removed redundant When-to-Use security bullet + Separation-of-writer-and-judge para; tightened Pre-flight docs/spec tolerance.

### Dimensions Evaluated
Skill Design Quality (arg grammar — top), Completeness + Orchestration (Round-N), Coherence (cross-skill dead ref, G-numbering), Over-Engineering (HIGHEST — 2 cuts offset adds), Spec Alignment, Actionability.

### Rename
No rename — highest-volume skill (188 occurrences); name accurate, stability load-bearing.

## 2026-05-25

### Summary
Phase 2 coherence: trimmed AskUserQuestion structural-contract restatement to point at the calling agent's contract (lockstep with design-qa/verify).

### Changes
- Replaced `1-4 questions, each having 2-4 options and a header ≤12 chars` restatement with pointer `per the calling agent's structural contract` (Item 4 lockstep, mirrors design-review's Phase 1 trim).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
Two pitfall-driven additions from highest-usage skill (186 sessions, 208 calls): added explicit silent-completion self-check to Save & Return (staff-engineer pitfall #4 — advisor invokes skill, verdict lands in context, advisor idles without SendMessaging team-lead) and added G5 Hard Gate for unexecuted AC regex (pitfall #5 — TDD AC amendments introduce regex without grep-against-actual-files execution). Net +12 lines.

### Changes
- Save & Return: prepended MUST statement clarifying trailing confirmation line is not the deliverable; SendMessage to calling agent IS the deliverable; added self-check question. Cross-cutting fix — same pattern applied to design-qa; verify/design-review to follow when their reports land.
- Hard Gates: added G5 (unexecuted AC regex) — mechanically detectable defect class where TDD/spec diffs introduce regex without execution against actual target files.
- Output template + Validation Before Emit: extended G1..G4 → G1..G5 in `Hard Gates Triggered` section and validation check 4.

### Dimensions Evaluated
Orchestration & Agent Teams (HIGHEST — silent-completion defect), Completeness (G5 gate), Actionability, Coherence (cross-skill propagation flagged), Over-Engineering (3 narrow edits within 108-line headroom).

### Rename
No rename — highest-volume skill; stability load-bearing.

## 2026-05-20

### Summary
Trimmed redundancies surfaced by historical audit (115 invocations across 12 sessions; 30x/19x/14x re-invocation patterns): removed Pre-flight doubling-rule callout (duplicated in section above), collapsed When-to-Use bullets 2-3 into bullet 1 (covered by Doubling Rule + agent docs), dropped Save & Return catch-all abort-echo line (each abort site emits its own error), and merged Standalone-mode footnote into Degraded-fallback paragraph. Net -6 lines.

### Changes
- Pre-flight: removed redundant `Doubling-rule rationale` blockquote — referenced ~15 lines above in Doubling Rule.
- When to Use: collapsed 4 bullets to 2 — team-lead delegation + parallel security review covered by Doubling Rule + agent docs.
- Save & Return: dropped catch-all "On any abort" sentence — each section specifies its own abort format inline.
- Doubling Rule: merged Standalone-mode footnote into Degraded-fallback paragraph (leaf-skill non-spawning is in CANONICAL banner).

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (sibling-family redundancy), Skill Design Quality.

### Rename
No rename.

## 2026-05-18

### Summary
Added Epistemic Discipline enforcement to Common Discipline + Validation Before Emit (banned-words check propagates the agent-level rule into the review-output surface); removed dead `{today_date}` resolution from Pre-flight §3 (templates never consume it); trimmed Failure Modes intro and Code Quality dimension prose. Net -3 lines.

### Changes
- Common Discipline: added Epistemic Discipline bullet — bans confidence phrases (clearly/obviously/should work/100%/guaranteed) in review findings; requires evidence anchoring.
- Validation Before Emit: added check 9 enforcing the banned-phrase scan so silent slips become defects at emit time.
- Pre-flight §3: dropped `{today_date}` resolution — templates never reference it.
- Failure Modes: collapsed 3-line preamble to one sentence.
- Code Quality dimension: cut essayistic through-line; kept the principle→gate mapping and the senior-engineer.md pointer.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (cross-agent Epistemic Discipline propagation), Actionability, Skill Design Quality, Completeness, Spec Alignment, Orchestration, Rename.

### Rename
No rename.

## 2026-05-17

### Summary
Trimmed 12-principle restatement in Code Quality dimension (skill already pointed to senior-engineer.md as full text); documented R1+R2 re-invocation pattern per historical audit (9 sessions confirmed); fixed Validation Before Emit numbering bug (3a → renumbered 3-8). Net -8 lines.

### Changes
- Code Quality dimension: replaced 12 inline principle paraphrases with brief pointer to senior-engineer.md, naming only the 4 principles that fire hard gates (G1-G4) and listing the other 8 by name. Eliminates dual-maintenance.
- When to Use: added explicit bullet documenting R1+R2 re-invocation pattern (Round-1 PR, Round-2 uncommitted after fix) so reviewers know this is expected, not duplication.
- Validation Before Emit: renumbered 3, 3a, 4, 5, 6, 7 → 3, 4, 5, 6, 7, 8 for clean ordinal sequence.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Orchestration & Agent Teams, Coherence, Skill Design Quality, Actionability, Completeness, Spec Alignment, Rename.

### Rename
No rename — highest-volume skill (125 invocations); stability has compounding value.

## 2026-05-16

### Summary
Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract (added to design-review this cycle); Save & Return collapsed to "Output Contract owns the emission rules" per family-wide pattern.

### Changes
- Common Discipline: added "with 1-4 questions, each having 2-4 options and a `header` ≤12 chars" to the AskUserQuestion guidance — parity with design-review/design-qa/verify.
- Save & Return: replaced verbose preamble with "No file is written (Output Contract owns the emission rules)" — matches verify/design-qa/design-review post-Phase-2.

### Dimensions Evaluated
Coherence (operator-prompt contract; family Save & Return phrasing), Over-Engineering.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-09: Initial creation (as code-review): shared review format authority — role-gated staff/security playbooks, severity ladders, validation; agents point to it.
- 2026-05-09: Role Detection restricted to the two real caller identifiers; review-strategy.md added to staff pre-flight; reviewer reconciliation promoted to first duty.
- 2026-05-09: Added scope-detection ambiguity rules and 50-file escalation hint; Validation references Output Contract; Failure Modes trimmed to new-abort-text rows.
- 2026-05-13: Empty-diff guard moved ahead of spec reads; spec reads scoped to changed domains; security-handoff escalation; Recommendation→Vote Verdict mapping added.
- 2026-05-16: Added 'Code review emitted ({recommendation}).' confirmation line with validation check 7; trimmed two Pre-flight/When-NOT redundancies.
