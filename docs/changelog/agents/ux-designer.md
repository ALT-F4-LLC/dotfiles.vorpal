# Changelog: ux-designer

## 2026-06-17

### Summary
Added a rendered-EFFECT obligation to spec self-validation and a relay-authority clause. Trial: rendered-EFFECT / relay-authority → adopted.

### Changes
- AMPLIFY: self-validate step 4 now requires naming the rendered-EFFECT target at real delivery resolution (not just the CSS/token value) for visual/static-export surfaces.
- AMPLIFY: relay-authority clause in Inter-Agent Communication (relay treated as direct inbound; a relayed directive yields to a contradicting direct operator instruction).
- Verified NO-OP: visual-render gate already encoded (lines 35/151/214).

### Dimensions Evaluated
Completeness (AMPLIFY), Spec Alignment (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 3 entries (2026-05-17..2026-05-24) into Compacted history per ADR 0001.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 coherence: R5 ux-advisor self-summary trigger now fires only on a design-QA verdict that surfaced a spec/implementation mismatch — lockstep with team-lead.md R5 per-advisor variant.

### Changes
- R5 trigger conditioned on mismatch, aligning with the existing memory-save trigger; clean Pass verdicts no longer fire a self-summary turn (deferred Phase 1 CHANGE 3, applied lockstep).

### Dimensions Evaluated
Coherence pass (cross-file mirrors).

### Rename
No rename.

## 2026-06-10

### Summary
Fixed undocumented frontmatter `color: magenta` → `purple` and retired the "Text-only medium" framing that contradicted the mandatory render-to-image design-QA gate. R5-trigger alignment deferred to Phase 2 (parity-bound with team-lead.md R5 variant). Net 0 physical lines (255).

### Changes
- AMPLIFY: frontmatter `color: purple` — magenta absent from the documented accepted list (silent-no-op risk; sole family outlier).
- CULL: "Text-only medium" framing — superseded by the render-to-image QA gate (fem-kubernetes Marp/embed pitfalls); now "Text-primary medium, render-verified"; prototyping clarified out-of-scope.
- Deferred: R5 trigger mismatch-only condition → Phase 2 lockstep with team-lead.md.

### Dimensions Evaluated
All 8; Spec Alignment + Consolidation primary.

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 37 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001.

### Changes
- Replaced the 37 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Closed two prescriptive-trigger gaps for the Fable-5 mandate (Fable under-reaches without explicit "use when" conditions). Reasoning-echo audit clean; the three render-QA historical lessons confirmed already-encoded (NO-OP). Net +2 (255 lines).

### Changes
- Wired WebSearch/WebFetch into "Honest critique, no guessing" with a trigger for external-standard research (WCAG criteria, competitive precedent, platform/SDK conventions) — tools were declared but had no body-level use-when condition
- Added "Invoke when..." dispatch leads to Responsibility 3 (Research) and Responsibility 4 (Design System Coherence) — converted flat capability menus into triggered dispatch

### Dimensions Evaluated
Prescriptive Capability Triggers (primary), Reasoning-Echo (clean), Consolidation & Trimming, Coherence

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: exit sequence inverted (old text explicitly forbade waiting for team-lead's request); §Shutdown Handling ephemeral + persistent lines aligned. Count unchanged (254).

### Changes
- §Ephemeral roles exit sequence: report → await → respond (FIX 27).
- §Shutdown Handling: "self-shutdown after verdict" → report-then-await; ux-advisor never self-initiates (FIX 28-29). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Consolidation-only pass (net -2; 256 → 254). Both Phase 0 audit focus areas (render-to-image QA gate; rendered-effect spec rule) confirmed already encoded 2026-06-05 — NO-OPs. Removed R5's Fix-loop continuity paragraph (zero unique facts vs §Ephemeral roles canonical block; R2's counterpart kept for its unique spec-author fact) and deduped the DEGRADED fallback to a §Reviewer Panel pointer, retaining the step-14 rule-6 cite.

### Changes
- §Responsibility 5 Fix-loop continuity paragraph removed — full duplicate of §Ephemeral `@ux-designer` roles.
- §Ephemeral roles DEGRADED clause → pointer to §Reviewer Panel; team-lead.md step-14 reconciliation rule-6 cite preserved.

### Dimensions Evaluated
Consolidation & Trimming (both changes), Completeness + Spec Alignment (focus areas already encoded; cross-refs resolve post-d1eb15e), Role Realism, Actionability, Boundary Clarity, Capability Growth (frontmatter recs already adopted), Rename.

### Rename
No rename.

## 2026-06-09

### Summary
One within-line consolidation (net 0; 256 lines). §"What to save here" (L244) restated the memory save-category list already enumerated at §Persistent memory; trimmed to a pointer, retaining only the symptom → root cause → resolution form directive. All Phase 0 historical lessons (render-to-image QA gate, color+text fallback, embedded-media render check, AskUserQuestion standalone-gating) confirmed already encoded.

### Changes
- §What to save here (L244): duplicated save-category list → pointer to §Persistent memory list; retains symptom → root cause → resolution form. Verified outside the CANONICAL:PITFALLS markers (editable, not parity-bound).

### Dimensions Evaluated
Consolidation & Trimming, Completeness, Spec Alignment, Role Realism, Boundary Clarity, Actionability, Capability Growth, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Encoded two render-gate pitfalls from agent memory (static-export render-to-image QA gate; rendered-effect-at-delivery-resolution spec guidance), plus a within-line trim of a redundant Shutdown bullet. Physical net +4 (245→249; two new paragraphs each add a blank+content line; the CHANGE-3 trim was within-line so it did not offset on a line basis).

### Changes
- QA Workflow: added a MANDATORY static-export/slide render-to-image-and-Read gate — "build green" ≠ render pass; broken-image placeholder / dead embed = Blocker; verify at real delivery resolution. (agent-memory pitfall; grep-verified absent across all agents)
- Spec content rule: added rendered-EFFECT-at-delivery-resolution + color-paired-with-text-fallback (CSS-contract-met ≠ design-intent-met).
- §Shutdown "Ephemeral roles" bullet trimmed to a pointer; Lifecycle §Ephemeral roles (L220) remains canonical owner of the exit sequence (verified).

### Dimensions Evaluated
Completeness + Spec Alignment (two render-gate pitfalls) · Consolidation & Trimming (Shutdown bullet) · Role Realism, Boundary Clarity (no change).

### Rename
No rename.

## 2026-05-30

### Summary
One consolidation fix (net 0 lines; single-line paragraph, 245 unchanged). §Shutdown Handling's ephemeral paragraph restated the verdict-then-shutdown exit sequence + fresh-ephemeral mechanic already canonical in §Ephemeral `@ux-designer` roles; trimmed to a pointer preserving only its unique fact — an ad-hoc spec-author ephemeral delivers a saved `docs/ux/` spec, not a review/QA verdict.

### Changes
- §Shutdown Handling (ephemeral paragraph): full mechanic restatement → 1-line pointer to §Ephemeral `@ux-designer` roles; retains the verdict-vs-saved-spec deliverable distinction.

### Dimensions Evaluated
Consolidation (PRIMARY — cross-section dedup) · Boundary Clarity (What-You-Are-NOT intact) · Cross-Communication (team-lead cross-refs resolve: Rule 7/8, reconciliation rule 6, R1-R7) · Spec Alignment (docs/ux + docs/spec empty — n/a)

### Rename
No rename.

## 2026-05-30

### Summary
Three coherence/consolidation fixes driven from first-principles + cross-agent coherence (zero in-window historical signal — lowest-invocation role, empty docs/ux + docs/spec). (1) Gated AskUserQuestion to standalone-only at the Honest-critique line and Spec Workflow step 5 — the teammate path cannot call it (docs-validated); team mode routes via SendMessage team-lead, matching the staff/security fleet pattern. (2) Corrected a dangling cross-ref: the DEGRADED fallback is team-lead step 14 reconciliation rule 6, not 7. (3) Consolidated the verdict-then-shutdown / continuity-preamble mechanic stated 4× (R2, R5, Ephemeral roles, Shutdown Handling); trimmed the two R2/R5 Fix-loop blocks to pointers preserving each unique fact. Content trimmed; 245 lines (single-line paragraphs, count unchanged).

### Changes
- §Honest critique / §Spec Workflow step 5: AskUserQuestion split into standalone (`AskUserQuestion`) vs team (SendMessage team-lead) — closes the teammate-path-unavailable gap.
- §Ephemeral roles: reconciliation "rule 7" → "rule 6" (matches team-lead step-14 list + L317 cross-ref).
- R2 / R5 Fix-loop continuity: full mechanic → 1-line pointers to §Ephemeral `@ux-designer` roles; unique facts retained.

### Dimensions Evaluated
Consolidation (PRIMARY) · Cross-Communication (AskUserQuestion fleet parity + rule-6 cross-ref) · Spec Alignment (teammate-path tool availability) · Actionability (no ambiguous team-mode AskUserQuestion instruction)

### Rename
No rename.

## 2026-05-26

### Summary
Realigned R2/R5 "Doubled Reviewer Pattern" subsections with team-lead.md Rule 8 (default = single reviewer `ux-advisor` via SendMessage; doubled = opt-up). Previous framing implied doubled was default, contradicting Rule 8's "single verdict is final, no ephemeral peer spawn." Renamed subsections to "Reviewer Panel" to capture both modes. Pluralized hardcoded `design-qa-2` / `design-review-2` to `{N}` for naming-convention parity with team-lead spawn names. Net 0 lines (text content shifted; line count preserved).

### Changes
- R5 §Reviewer Panel (L186-187): renamed "Doubled Reviewer Pattern" → "Reviewer Panel"; prepend default-single + opt-up-doubled framing; pluralize `design-qa-2` → `design-qa-{N}`.
- R2 §Reviewer Panel (L158-159): mirror rename + pluralization in the pointer subsection.

### Dimensions Evaluated
Spec Alignment (PRIMARY — closes Rule 8 default-mismatch) · Cross-Agent Coherence (team-lead spawn-naming parity) · Actionability (default-vs-opt-up clarity for ux-advisor receiving design-QA requests)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 6 dangling docs/tdd/* citations)

### Summary
Stripped 6 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.

### Changes
- L168 design-review Fix-loop: replaced "§6 continuity preamble per docs/tdd/reviewer-doubling-lifecycle.md" with §Stall & Crash Recovery anchor.
- L185 Doubled reviewer pattern: dropped "+ reviewer-doubling-lifecycle.md §4.2 row design-qa" tail.
- L197 design-QA Fix-loop: same fix as L168 (parity).
- L210 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L213 ux-advisor idle: replaced "TDD §4.4 rule 5" with team-lead.md §Stall & Crash Recovery anchor.
- L216 ephemeral roles: replaced "§6" + "TDD §4.3 rule 7" with §Stall & Crash Recovery + step 14 anchors.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — proactive ephemeral self-shutdown vs idle-OK persistent)

### Summary
Distinguished ephemeral (`design-review-{N}`, `design-qa-{N}`) verdict-then-self-shutdown discipline from persistent `ux-advisor` idle-OK lifecycle. Encoded verdict-then-`shutdown_request` SAME turn as the canonical ephemeral exit sequence; pluralized hardcoded `design-review-2`/`design-qa-2` to `{N}`/`{N+1}` to match team-lead spawn naming. Precautionary parity edit — historical profile is clean (TeammateIdle=0). Net +4 lines (331 → 335).

### Changes
- §Shutdown Handling: expanded to three sub-sections — Ephemeral (verdict-then-`shutdown_request` SAME turn), Persistent `ux-advisor` (idle-OK by design), Inbound shutdown_request reply rule.
- §Ephemeral `@ux-designer` roles: explicit exit sequence "deliver final report → emit shutdown_request → stop"; pluralized `{N}`.
- §Responsibility 2 (design-review) Fix-loop continuity: replaced "exit on shutdown_request" passive framing with "self-shutdown after delivering verdict (SAME turn)".
- §Responsibility 5 (design-qa) Fix-loop continuity: parity edit with above; pluralized.

### Dimensions Evaluated
Actionability (PRIMARY — proactive self-shutdown) · Boundary Clarity (ephemeral vs `ux-advisor` lifecycle distinction) · Capability Growth (verdict-then-shutdown parity with fleet)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — shutdown WRONG/RIGHT, sec-incoming trigger, P7a drop)

### Summary
Three coherence fixes: (1) added concrete WRONG/RIGHT shutdown-routing example to Comm Discipline rule 6 (fleet parity); (2) added @security-engineer feasibility-consult incoming trigger to close bidirectionality gap (security-engineer already had both outgoing+incoming for consent/defaults; ux-designer only had outgoing); (3) dropped dead "(P7a)" cross-reference from R7.

### Changes
- Comm Discipline rule 6: appended WRONG/RIGHT (`to="design-review-2"`/`"design-qa-2"` WRONG; `to="team-lead"` RIGHT)
- §Inter-Agent Communication Incoming triggers: added @security-engineer feasibility-consult entry after @staff-engineer
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — bidirectional sec↔ux trigger pair + shutdown example) · Actionability (P7a dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — Read-before-Edit compaction + doubled-reviewer consolidation)

### Summary
Closed the own-session `File has not been read yet` error (session 435785d7) by promoting compaction-awareness from buried R7 exception to the top-level Read-before-Edit/Write rule (mirrors senior-engineer.md line 33 phrasing). Consolidated near-identical "Doubled Reviewer Pattern" subsections from Responsibility 2 (design-review) and Responsibility 5 (design-QA) into one canonical block under Responsibility 5; Responsibility 2 now references it with the `design-review-2` slot-substitution. Added explicit memory save trigger to address persistent memory-gap.

### Changes
- §Read before Edit/Write rule (line 34): appended compaction-awareness clause mirroring senior-engineer.md phrasing — addresses session 435785d7 error
- §Persistent memory: appended explicit save trigger ("after every design-QA verdict that surfaced a recurring root cause; after every cross-surface precedent decision") to address memory-gap-despite-active-invocations audit finding
- §Responsibility 2 → Doubled Reviewer Pattern: collapsed to a one-line reference pointing to the canonical block under Responsibility 5 (slot-substitute `design-review-2` for `design-qa-2`)

### Dimensions Evaluated
Actionability (PRIMARY — own-session Read-before-Edit fix) · Consolidation & Trimming (doubled-reviewer subsection merge) · Cross-Agent Coherence (Read-before-Edit phrasing aligned with senior-engineer canonical form) · Capability Growth (memory save trigger)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 1104 to 318 lines. Compressed verbose sections, collapsed output templates, converted surface expertise to reference…
- 2026-03-19: Trimmed 25 lines through consolidation of redundant philosophy, anti-patterns, and system-level sections. Added "Check Specs Before Designing"…
- 2026-03-19: Added Operating context paragraph to align with the pattern established across all other agents.
- 2026-03-19: Removed 19 lines of duplicated guidance (conflict escalation, cross-surface coherence) and redistributed the one unique idea. Sharpened…
- 2026-03-19: Compressed /vote section and status updates list, tightened spec format descriptions, added accessibility and visual-prototyping checks to…
- 2026-03-20: Added effort and memory frontmatter, compressed Design Philosophy from 8 to 6 principles, removed Design Strategy Briefs, trimmed verbose status…
- 2026-03-20: Merged Content Design into Design Spec Format, deduplicated TDD conflict escalation, added @sdet notification trigger, removed redundant Design…
- 2026-03-20: Removed standalone "Check Specs Before Designing" section (duplicated workflow step 1), folded unique content into Clarify step, compressed…
- 2026-03-20: Compressed Vote CLI Reference, Anti-Patterns, Managing Ambiguity, and Research handoff notes. Added explicit docket comment command for issue…
- 2026-03-21: Added observability for cross-communication and vote audit trails, compressed surface table and anti-patterns, added disallowedTools frontmatter…
- 2026-03-29: Updated Docket Vote CLI reference with audit-discovered flags, compressed Delegation Protocol and Managing Ambiguity subsection. Net -15 lines.
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed spec format list, removed vestigial Anti-Patterns and Delegation…
- 2026-03-30: Added honest UX critique directive, compressed Decision-Making Framework and /vote critical-cases, added trade-off documentation check to…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, added context compaction handling, compressed Pre-Flight and Inter-Agent Communication sections, added…
- 2026-04-06: Fixed `/vote` team-nesting bug (operator feedback): replaced direct `/vote` invocation with team/standalone mode routing. Removed Docket Vote…
- 2026-04-06: Added mandatory "Resolve open questions" workflow step (verified goal). Compressed What You Are NOT, Research, and Shutdown sections. Updated…
- 2026-04-16: Consolidation pass: merged text-medium directives, compressed What You Are NOT (added missing @sdet boundary for cross-agent coherence)…
- 2026-04-16: Cross-communication pass: restructured Inter-Agent Communication around concrete proactive SendMessage triggers (Consult first / Notify…
- 2026-04-19: Added "No guessing — research first" rule after Honest critique — STOP-and-research loop for UX patterns, user workflows, SDK/CLI conventions…
- 2026-05-05: Consolidation pass: compressed three stance paragraphs (Honest critique / No guessing / Text-only medium), tightened workflow step 1 (Clarify)…
- 2026-05-05: Phase 0+2 capability adoption + consolidation: added Bash run_in_background + Monitor pattern for QA of long-running surfaces, `color: magenta`…
- 2026-05-06: Cross-comms visibility + capability growth pass. Added Cross-communication observability paragraph (operator can't see inter-agent SendMessage)…
- 2026-05-06: Phase 2 coherence pass: replaced "summarize in next status update" cross-comm pattern with fleet-standard hybrid (Docket-comment prefix…
- 2026-05-07: Capability fix + Responsibility 4 trim. Added Monitor to tools frontmatter to match the existing Responsibility 5 mandate (introduced 2026-05-05…
- 2026-05-07: Phase 2 coherence: aligned HARD GATE delimiter style with peer agents.
- 2026-05-07: Closed persistent-advisor lifecycle gap (team-lead.md:169 mandates the orchestrator-side behavior but ux-designer.md previously had no…
- 2026-05-07: Phase 2 coherence: added persistent agent-memory paragraph aligning ux-designer with sdet/SE/staff/PM fleet pattern. UX-specific guidance on…
- 2026-05-08: Trim of redundant inter-agent communication structure, surface-table preamble, "How You Work" verb-routing, research framing, and a handoff line…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.
- 2026-05-08: Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring design problems.
- 2026-05-09: Self-review trim pass: compressed Pre-Flight Goal-Alignment Gate, tightened workflow step 5, Design QA verify-behavior paragraph…
- 2026-05-13: Replaced loose "when to create a spec" bullets with an explicit four-tier output table (inline / Docket comment / interaction sketch / full…
- 2026-05-13: Phase 2 coherence: added @security-engineer to "What You Are NOT" and Outgoing triggers — closes bidirectional handoff gap where…
- 2026-05-16: Added Communication Discipline (rules 1-6) with rules 1-3 emphasized for ux-advisor's implementation-phase persistence; strengthened Design QA…
- 2026-05-16: Phase 2 coherence: normalize security-advisor canonical form; drop redundant parenthetical.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).…
- 2026-05-17: pass 2: Addressed two historical-audit findings: highest per-session "File has not been read yet" rate (11/11 sessions) via explicit…
- 2026-05-17: Added canonical `TeammateIdle` stall-signal line for cross-agent terminology coherence.
- 2026-05-19: Addressed the "highest-leverage coherence fix" flagged by historical audit: promoted Visibility contract from conditional mirroring ("When an exchange ties to
- 2026-05-24: Closed the 6 historical shutdown-routing errors by making the routing rule explicit at Communication Discipline rule 6. `design-review-2` and `design-qa-2`
