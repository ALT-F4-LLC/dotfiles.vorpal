# Changelog: design-review

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean (accessibility rendered-effect line is review-rubric content); $-escape clean; recall-filter grep zero hits (orchestrator-verified); validation ladder + 6 dimensions preserved.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape + recall-filter audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: code-review→code-review-verdict reference updates (lockstep only).

### Changes
- 2 refs updated for the sibling rename, incl. the byte-identical COUPLING marker.
- Monitor retained in allowed-tools despite no body usage — family parity decision (pre-approval, not capability).

### Dimensions Evaluated
Coherence (family lockstep).

### Rename
No rename (sibling code-review renamed → code-review-verdict; refs updated).

## 2026-06-09

### Summary
Coherence: fixed Save & Return vote escalation to mode-split (standalone `Skill(vote)`; team mode delegation_request to team-lead) — prior wording instructed a team-mode Skill(vote) call that agents/ux-designer.md's CRITICAL banner forbids. Trimmed duplicated routing parenthetical + rhetorical tail from the self-check. Net 0.

### Changes
- Save & Return vote bullet: `Skill(vote, ...)` → mode-split escalation per agents/ux-designer.md Design Spec Approval.
- Self-check: dropped routing clause duplicating bullet 1 and "regardless of how complete..." filler.
- Cross-cutting: same Skill(vote) hazard in code-review:390, verify-ac:261, and family When-NOT-to-Use bullets routed to Phase 2 for lockstep harmonization.

### Dimensions Evaluated
All 8. Coherence (vote-routing contradiction), Over-Engineering (HIGHEST — self-check trim), Skill Design (no unescaped $digit; under compaction cap; description under budget). Spec Alignment N/A (docs/spec/ absent).

### Rename
No rename.

## 2026-06-08

### Summary
Coherence: corrected the Doubling Rule reconciliation dedupe key from `(file, symbol)` to `(spec section, surface)` — a UX peer review grounds findings on spec sections/workflows (pre-implementation, often no code), matching Validation check #4 and the design-qa sibling. design-review-local divergence; siblings (code-review/verify-ac key on file/symbol) unaffected. Net 0.

### Changes
- Doubling Rule: dedupe key `(file, symbol)` → `(spec section, surface)`.

### Dimensions Evaluated
Coherence (dedupe-key accuracy vs this skill's own grounding unit + design-qa parity), Over-Engineering (HIGHEST — nothing to trim at 250 lines after 16 cycles), all 8 reviewed; rest sound. Scope boundary vs design-qa verified crisp.

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: moved the COUPLING marker above "When NOT to Use" and replaced "doubling-rule note below" with directionless wording ("The Doubling Rule section...") — the Doubling Rule sits above the marker post-move, so "below" was inaccurate. All 4 family markers now byte-identical.

### Changes
- COUPLING marker relocated under "When NOT to Use"; "below" wording corrected; family parity restored.

### Dimensions Evaluated
Coherence (report-emission family COUPLING placement + text parity).

### Rename
No rename.

## 2026-05-30

### Summary
Aligned the Doubling Rule with team-lead.md Rule 8: design review defaults to a single ux-advisor (opt up to doubled per Rule 8 triggers) rather than ≥2-by-default. Canonical ephemeral name design-review-{N}. Net 0.

### Changes
- Doubling Rule: default-doubled framing → default-single/opt-up-doubled per team-lead.md Rule 8; ephemeral `design-review-2` → `design-review-{N}`. Applied in lockstep with design-qa and code-review (shared inversion).

### Dimensions Evaluated
Coherence (HIGHEST — Rule 8 default + canonical naming), Over-Engineering (no trim; net 0), Skill Design, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Harmonized the silent-completion self-check framing with the report-emission skill family (Phase 2 coherence).

### Changes
- Self-check reframed to "the calling agent MUST self-check," dropping the self-referential "to the calling agent" destination (now peer/team-lead per trigger). Matches code-review/verify; resolves the deferred Phase-1 "leaf skill can't SendMessage" objection without deleting the load-bearing reminder. [Phase 2 coherence item 3]

### Dimensions Evaluated
Cross-skill coherence; instruction accuracy.

### Rename
No rename.

## 2026-05-29

### Summary
Consolidated the Recommendation-vs-severity validation gate (check #2) from three prose sub-bullets into one enforceable line; the Recommendation Ladder table already defines the tier semantics.

### Changes
- Validation Before Emit check #2: 3 sub-bullets → 1 line (any Blocker ⇒ Block/Redesign/Incremental; any Concern ⇒ Approve-with-follow-up/Redesign/Incremental, plain Approve forbidden; zero/zero ⇒ Approve permitted). Net -3.
- Deferred to Phase 2: removing the Save & Return self-check (conflicts with code-review keeping the same report-emission-family silent-completion reminder — harmonize family-wide); `disallowed-tools` (family decision, not adopting).

### Dimensions Evaluated
Over-Engineering (HIGHEST — 1 trim), Coherence (self-check is a family pattern → deferred), Skill Design Quality, Actionability, Completeness, Orchestration (leaf), Spec Alignment, Rename.

### Rename
No rename — design-review cleanly distinct from design-qa (post-impl) and ux-spec (authoring).

## 2026-05-28

### Summary
Phase 2 coherence: repointed two dead `docs/tdd/reviewer-doubling-lifecycle.md` references (COUPLING comment + body; file does not exist) to `agents/team-lead.md` Rule 8 + step 14.

### Changes
- COUPLING "keep shape in sync" pointer → `agents/team-lead.md` Rule 8.
- Body topology/dispatch → Rule 8; reconciliation → step 14.

### Dimensions Evaluated
Coherence (accurate references).

### Rename
No rename.

## 2026-05-28

### Summary
Coordination/handoff: unified the verdict-routing target, which was inconsistent across three locations (self-check said "team-lead"; Save & Return + Next Steps said "artifact author") and diverged from the family-canonical phrasing in code-review/design-qa. Net 0 lines.

### Changes
- Self-check: "to team-lead" → "the calling agent (team-lead in team mode)", matching code-review/design-qa (reachable in standalone mode too).
- Save & Return bullet 1: direct-to-author SendMessage → route per `agents/ux-designer.md` triggers (through team-lead under orchestration, who reconciles both reviewers before routing to author) — fixes hub-and-spoke violation under the Doubling Rule.
- Next Steps example: removed non-existent agent name `@ux-designer-author`; aligned routing to calling-agent/team-lead deliverable.

### Dimensions Evaluated
Orchestration & Agent Teams (HIGHEST), Coherence (code-review/design-qa family parity), Over-Engineering (no bloat found; all changes net 0), Actionability.

### Rename
No rename.

## 2026-05-25

### Summary
Orchestration + Over-Engineering: added silent-completion self-check to Save & Return per the cross-family pitfall resolution (cross-cutting with code-review, verify, design-qa); trimmed AskUserQuestion structural rehearsal in Common Discipline that pure-restates `@ux-designer` canonical contract. Net +3 lines.

### Changes
- Save & Return: added "Self-check before ending the turn" callout addressing silent-completion pitfall (skill emits verdict to context; calling agent silently idles without SendMessage to team-lead).
- Common Discipline: trimmed AskUserQuestion structural contract restatement (1-4 questions / 2-4 options / ≤12-char header / default in first option); replaced with pointer to calling agent's structural contract.

### Dimensions Evaluated
Orchestration (HIGHEST — silent-completion family parity), Over-Engineering (AskUserQuestion duplication trim), Coherence (vs design-qa/code-review/verify).

### Rename
No rename.

## 2026-05-20

### Summary
Coherence + Over-Engineering: promoted Doubling Rule from a 4-paragraph nested H3 inside `When to Use` to a single-paragraph top-level `## Doubling Rule` section matching sibling design-qa structure and density. Trimmed Failure Modes row that pure-restated Argument Handling. Net -9 lines.

### Changes
- `When to Use` → `## Doubling Rule`: promoted to top-level H2 (was H3 inside `When to Use`); collapsed Reviewer count / Reconciliation / Ephemeral lifecycle / Degraded fallback / Standalone-mode paragraphs into one dense paragraph mirroring design-qa.
- Failure Modes: removed "Caller passes additional positional args" row — restates Argument Handling per 2026-05-17 trim criterion.

### Dimensions Evaluated
Coherence (HIGHEST — vs design-qa family parity), Over-Engineering (HIGHEST), Skill Design Quality.

### Rename
No rename.

## 2026-05-19

### Summary
Phase 2 coherence — added explicit Epistemic Discipline Validation check (new check #10) so the banned-phrases rule from Common Discipline is gate-enforced, matching code-review's check #9. Net +1 line.

### Changes
- Validation Before Emit: added check #10 — scan What's Strong / What Needs Work / Open Questions / Next Steps for banned confidence phrases; a hit is a defect.

### Dimensions Evaluated
Coherence, Epistemic Discipline, Report-Emission Family Parity.

### Rename
No rename.

## 2026-05-18

### Summary
Phase 1 trim + Epistemic Discipline pass: removed incorrect "Stream long inspections" bullet (design-review is PRE-impl — nothing runs), collapsed Pre-flight empty-artifact guard to Failure Modes reference, folded banned-hedge list into Honest Critique bullet. Net -5 lines, behavior unchanged.

### Changes
- Common Discipline: removed "Stream long inspections" bullet — design-review has no binary/dev-server scope.
- Common Discipline "Honest critique" → "Honest critique with evidence": added requirement to cite the grounding artifact and listed banned hedges per Epistemic Discipline.
- Pre-flight step 6: collapsed inline abort code-fence to a one-line reference pointing at Failure Modes table.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Coherence (vs design-qa, family parity), Spec Alignment.

### Rename
No rename.

## 2026-05-17

### Summary
Phase 1 trim pass: removed redundant Role Detection note, dropped Failure Modes row that pure-restates a Validation inline abort, tightened Validation rule #2 and Failure Modes preamble. Net -22 lines, no behavioral change.

### Changes
- Role Detection: removed "Note" block restating @staff-engineer/@security-engineer routing — already covered by When NOT to Use + abort message.
- Failure Modes: removed "Recommendation/severity mismatch" row — pure-restates Validation rule #2's abort, matching the 2026-05-16 trim criterion.
- Validation Before Emit rule #2: tightened wording, dropped parenthetical that duplicated Recommendation Ladder content.
- Failure Modes preamble: compressed enumeration of inline-abort locations to one sentence.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Actionability, Coherence (vs design-qa).

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: banner footer now mentions Docket comments (matches Save & Return obligations and aligns with design-qa); Save & Return collapsed to "Output Contract owns the emission rules" per family-wide pattern.

### Changes
- Banner footer: added `and Docket comments` to the leaf-skill banner — Save & Return §line 236 requires Docket comment mirroring, so banner was inaccurate.
- Save & Return: replaced "This skill does NOT write a file. After Validation Before Emit passes, emit verbatim..." preamble with "No file is written (Output Contract owns the emission rules)" — matches code-review/design-qa/verify post-Phase-2.

### Dimensions Evaluated
Coherence (banner/footer parity, family Save & Return phrasing), Over-Engineering.

### Rename
No rename.

## 2026-05-16

### Summary
First changelog entry. Five fixes: aligned Output Contract frontmatter field with ux-spec contract (`maturity` not `status`), made the `Praise` severity's routing to `What's Strong` explicit, added AskUserQuestion structural contract (1-4 questions, 2-4 options, ≤12-char header), loosened Validation rule #2 to allow Redesign/Incremental Improvement when no Blocker is citable but the foundation is wrong, and trimmed Failure Modes table to rows with new abort text.

### Changes
- Output Contract Artifact section: `Maturity / status` line now reflects UX spec frontmatter contract.
- Severity Ladder Praise row: explicit "routes to What's Strong, not What Needs Work" annotation.
- Common Discipline: AskUserQuestion now specifies 1-4 questions, 2-4 options, ≤12-char header, default recommendation in first option's description.
- Validation Before Emit rule #2: Redesign / Incremental Improvement permitted with Concerns-only OR no severity findings when body argues fundamental rethink or bounded improvement.
- Failure Modes table compressed from 7 rows to 3 — dropped rows that pure-restate inline aborts; kept rows with new abort text.

### Dimensions Evaluated
Over-Engineering (HIGHEST — Failure Modes trim), Skill Design Quality, Actionability, Operator Prompt Quality, Spec Alignment, Coherence (vs design-qa).

### Rename
No rename.
