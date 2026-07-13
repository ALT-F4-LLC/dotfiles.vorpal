# Changelog: ux-designer

## 2026-07-13

### Summary
Compacted 4 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: fixed the threshold-less vote proposal (real bug); compacted the shutdown block; gained the CANONICAL:SANDBOX-RECOVERY-LOCAL block (only render-executing role that lacked it) and a deep-research sanction on competitive/standards research.

### Changes
- AMPLIFY[SUBSTANTIVE]: §Design Spec Approval vote proposal migrated to `vote_delegate.sh` — fixes omitted `--threshold`; Wire form preserved.
- CULL[SUBSTANTIVE]: §Shutdown Handling block compacted to the master-pointer form.
- AMPLIFY[SUBSTANTIVE]: Responsibility 5 gains a byte-parity `CANONICAL:SANDBOX-RECOVERY-LOCAL` block (copied from sdet.md) at the render-mechanism table — prevents sandboxed headless-chrome/bind failures being misread as a render Fail.
- AMPLIFY[SUBSTANTIVE]: Responsibility 3 gains a `Skill(deep-research)` preference for competitive/standards scans.

### Dimensions Evaluated
Cross-Agent Coherence (vote plumbing, shutdown block, sandbox-recovery, deep-research parity across the fleet).

### Rename
No rename.

## 2026-07-12

### Summary
Findings: 3 → 3 sub / 0 cos / 0 rej / 1 def / 0 enc. Surfaced post-implementation design QA in the frontmatter description (HA-UX1 promised-but-never-sent gate), noted `skills:` frontmatter is inert in teammate mode (DR1), and trimmed the ~12-line Go scratch-module recipe to a pointer into centralized pitfalls.md (IS-UX3). Net -120 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE] (HA-UX1): frontmatter description now names design QA on an implementation diff for any `docs/ux/`-spec'd surface — makes the gate discoverable at dispatch time.
- CULL[SUBSTANTIVE] (IS-UX3): Go internal-package render-verification recipe trimmed to trigger+approach + pointer; full recipe retained verbatim in centralized pitfalls.md.
- AMPLIFY[SUBSTANTIVE] (DR1): R2 states frontmatter skills don't auto-load in teammate mode; invoke each explicitly.

### Dimensions Evaluated
Completeness/Actionability, Consolidation & Trimming, Spec Alignment. Role Realism/Boundary Clarity/Capability Growth/Rename: RETAIN (SDLC research confirms fit; UX Researcher + Accessibility already absorbed).

### Rename
No rename.

## 2026-07-11

### Summary
Compacted 3 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-11

### Summary
Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.

### Changes
- FIX[SUBSTANTIVE]: SP-2 LOCAL copy corrected — `name=` is the sole discriminator; report-only subagents run background-by-default since Claude Code v2.1.198, so `run_in_background` no longer discriminates. Stale phrasing contradicted team-lead.md's Phase-1-corrected copy and current harness behavior.

### Dimensions Evaluated
Spec Alignment (v2.1.198 harness behavior), Boundary Clarity (family-wide parity with 5 siblings + master).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): named the render mechanism per surface class for the design-QA render-to-image mandate — the file's most failure-prone gate was improvised per-session with no tooling named. Net +542 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE]: added a surface-class→mechanism table to Responsibility 5 (static-export → headless-browser screenshot→PNG→Read; TUI → existing scratch-module recipe; CLI → captured stdout/stderr). Fills the static-export mechanism gap and consolidates three scattered recipes into one lookup. Script codification deferred (`tui_render_probe.sh`, follow-up Docket item) — prose names categories only.

### Dimensions Evaluated
Actionability + Capability Growth (primary). SDLC role research confirms fit to industry UX Designer; accessibility already in-scope (Principle 6, design-review's six dimensions, QA workflow) — no change, checklist-depth work routes to evolve-skills. Consolidation/Role Realism/Boundary Clarity/Completeness/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence follow-up: flagged vote-delegation JSON as a plain-text payload.

### Changes
- AMPLIFY: appended a wire-form clarification to the vote-delegation paragraph — the JSON is sent as a plain-text string, never SendMessage's structured `message` object (`delegation_*` are vote-skill conventions, not real `message.type` values). Matches team-lead.md:360's receiving-side fix (bug-audit FIX-9, fleet-wide sweep).

### Dimensions Evaluated
Actionability (cross-agent coherence sweep).

### Rename
No rename.

## 2026-07-10

### Summary
Scoped session-start reads (removed internal R1 contradiction), made the design-QA verdict a terminal artifact only via a durable Docket comment (DKT-76 near-miss), and trimmed redundant prose. Net -72 bytes.

### Changes
- CULL: session-start blanket whole-tree reads → scoped to dispatched-surface slugs via `ls docs/ux/` first. Signal: innovation-scan Retire (R1 self-contradiction).
- AMPLIFY: design-QA verdict is not terminal until posted as a durable `[UX→team-lead] Design QA: <verdict>` Docket comment. Signal: historical-audit DKT-76 shutdown-rejection near-miss (team-lead nearly closed an issue with no QA verdict on record).
- CULL: verbose code-samples paragraph compressed; redundant "What to save here" pitfalls-restatement line removed (dup of §Persistent memory + CANONICAL:PITFALLS block).

### Dimensions Evaluated
Consolidation & Trimming (primary); Capability Growth & Cross-Communication; Actionability. Role Realism/Boundary Clarity/Completeness/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 3 Disambiguation follow-up: normalized UX shutdown report fields.

### Changes
- DISAMBIG: updated local SP-1 to require scope or changed files, checks run, unresolved risks, and explicit `safe_to_close` close readiness.

### Dimensions Evaluated
Phase 3 Disambiguation; shutdown schema.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: UX lifecycle and QA classification -> applied. Phase 1 update tightened dispatch, plan-review, QA evidence, and ephemeral close guidance for ux-designer only.

### Changes
- AMPLIFY: dispatch now includes operator-visible lifecycle, cleanup, status, and handoff flow changes.
- AMPLIFY: incoming @senior-engineer implementation PLAN review returns Pass / Pass-with-Issues / Fail with pattern, copy, and error-state findings.
- AMPLIFY: design-QA findings now classify deviation/spec/tradeoff/operator-choice class and name inspected commands/artifacts/outputs.
- AMPLIFY: ephemeral close handling adds a pre-idle checklist; removed duplicate Fix-loop continuity paragraph.

### Dimensions Evaluated
Capability Growth, Lifecycle Coherence, QA Evidence, Consolidation.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2 (operator-approved PA): landed the deferred PA plan-stage incoming trigger — ux-advisor reviews a team-lead-routed @senior-engineer PLAN for a spec'd surface before code, converting a would-be post-impl QA-Fail into a plan note. Net +1 (299→300). Trial: PA plan-approval → applied.

### Changes
- AMPLIFY: incoming trigger — @senior-engineer implementation PLAN routed by team-lead (plan-approval mode) for a surface with a docs/ux/ spec → pre-impl design check flagging pattern/copy/error-state deviations before code. Signal: Phase 0 PA innovation.

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY. 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Culled a redundant Fix-loop restatement (Responsibility 2) that duplicated §Ephemeral-roles + §ux-advisor Lifecycle. Confirmed the three render-gate pitfalls remain structurally encoded (NO-OP). Net -2 (301→299). PA pre-impl plan-review trigger deferred to Phase 2 cross-cutting PA aggregation.

### Changes
- CULL: removed "Fix-loop continuity" paragraph — restated §Ephemeral-roles + Lifecycle §ux-advisor in substance. Signal: Consolidation (every-addition-offset).
- Verified NO-OP: render gate encodes all three fem-kubernetes pitfalls (Marp broken-diagram export, giphy 200-but-dead embed, CSS-cue unreadable at delivery scale).
- Deferred: PA plan-stage incoming trigger → Phase 2 (applied family-wide only if team-lead adopts PA primitive).

### Dimensions Evaluated
All 8. 5 (Consolidation) → 1 CULL. 6 (Capability Growth) → PA deferred to Phase 2. 1/2/3/4/7/8 RETAIN.

### Rename
No rename.

## 2026-06-21

### Summary
Compacted 8 entries (2026-05-25..2026-06-05) into Compacted history per ADR 0001.

### Changes
- Replaced the 8 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-19

### Summary
Maintenance review (lowest-usage agent, 2 spawns/window). Verified the design-QA render gate already covers the cross-project "build-green ≠ render-correct" lesson; no edits warranted. Net 0 (284→284). Drift: skipped (seed-target was the cross-agent Pre-Flight parity gate — unsafe).

### Changes
- Verified NO-OP: design-QA render gate covers broken-image placeholders, 200-but-removed media, and CSS-correct-but-unreadable-at-scale cues — full strength vs the lesson.

### Dimensions Evaluated
All 8 RETAIN. Consolidation examined closest (render-verification authoring→validate→QA progression; distinct TeammateIdle polarities) — no trim clears the bar given lowest-usage + 0 historical failures.

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
- 2026-05-25: Phase 1 self-review — Read-before-Edit compaction-awareness promoted; Doubled Reviewer Pattern consolidated into R5 canonical block; memory save trigger added.
- 2026-05-25: Phase 2 coherence — rule 6 WRONG/RIGHT shutdown example; @security-engineer incoming trigger added; P7a dropped from R7.
- 2026-05-26: Phase 1 — ephemeral verdict-then-shutdown vs persistent ux-advisor idle-OK lifecycle distinguished; design-review-{N}/design-qa-{N} pluralized. Net +4.
- 2026-05-26: Phase 2 — stripped 6 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: R2/R5 Reviewer Panel realigned to default-single + opt-up-doubled (Rule 8); design-qa-{N} naming convention parity. Net 0.
- 2026-05-30: Three coherence/consolidation fixes: AskUserQuestion standalone-only gate; reconciliation rule 6 (not 7); R2/R5 Fix-loop → pointers. Net 0.
- 2026-05-30: Consolidation — §Shutdown Handling ephemeral restatement → 1-line pointer to §Ephemeral roles. Net 0.
- 2026-06-05: Two render-gate pitfalls encoded: render-to-image QA gate + rendered-EFFECT-at-delivery-resolution spec rule. Net +4.
- 2026-06-09: Trimmed duplicated "What to save here" list to a pointer to §Persistent memory; kept symptom→cause→resolution form. Net 0 (256 lines).
- 2026-06-09: Consolidation pass — removed duplicate Fix-loop continuity paragraph, deduped DEGRADED fallback to Reviewer Panel pointer. Net -2 (256→254).
- 2026-06-09: Phase 2 shutdown flip — exit sequence inverted (report→await→respond); PITFALLS family fix. Net 0 (254 lines).
- 2026-06-09: Closed two Fable-5 prescriptive-trigger gaps; reasoning-echo audit clean; render-QA lessons already-encoded. Net +2 (255 lines).
- 2026-06-09: Compacted 37 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Fixed undocumented frontmatter `color: magenta` → `purple`; retired "Text-only medium" framing (superseded by render-to-image QA gate). Net 0 (255 lines).
- 2026-06-10: Phase 2 coherence — R5 ux-advisor self-summary trigger fires only on a design-QA verdict surfacing spec/implementation mismatch (lockstep with team-lead.md R5).
- 2026-06-10: Compacted 3 entries (2026-05-17..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-17: Added rendered-EFFECT obligation to spec self-validation + relay-authority clause. Trial: rendered-EFFECT / relay-authority → adopted.
