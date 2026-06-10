# Changelog: senior-engineer

## 2026-06-09

### Summary
Compacted 43 entries (2026-03-19..2026-05-25) into Compacted history per ADR 0001.

### Changes
- Replaced the 43 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-5 calibration: added minor-choice autonomy directive and silence-default narration; trimmed redundant Technical Debt and Navigate-Ambiguity bullets to offset (net 0, 357 lines).

### Changes
- Added "Minor choices — pick, don't ask" to Decision-Making Framework (autonomy calibration; reserve asks for scope/irreversible/TDD-deviation)
- Added "Silence-default narration" to Communication discipline (text only on finding/direction-change/blocker)
- Collapsed 4-bullet Technical Debt section to one directive (redundant with code-philosophy #9, Discoveries step, System-Level Awareness)
- Tightened "When scope is unreasonable" bullet (redundant with Core Principle 1 + scope-expansion trigger)

### Dimensions Evaluated
Role Realism, Actionability, Consolidation & Trimming (primary), Capability Growth, Spec Alignment

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: completion contract step 5 + Monitor-watch paragraph replaced with await-lead semantics; lifecycle/scope/trigger lines aligned. Both rejection grounds and drain doctrine preserved. Count unchanged (358).

### Changes
- Completion contract intro + step 5: deliver report → idle awaiting `shutdown_request` (FIX 12-13).
- Auto-shutdown Monitor watch → "Idle after final report" (no self-emit, no ~60s re-emit) (FIX 15).
- Lifecycle, closed-loop scope, @sdet-APPROVE trigger, rejection-ground-1 tail aligned (FIX 9-11, 14). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence, Role Realism.

### Rename
No rename.

## 2026-06-09

### Summary
Audit-driven hardening: mv/rename added to Read-before-Edit gate (13 gate-trips this window), git-add-to-self-verify prohibition made explicit with failure-mode rationale (recurred in two repos), edit-site location by grep not issue line anchors; removed duplicated shutdown-routing line. Net -2 (360→358).

### Changes
- Read-before-Edit: after `mv`/rename the NEW path is un-Read — Read before first Edit.
- Shared-tree diff scoping: self-verify via plain working-tree diff ONLY; never stage-then-inspect (staged changes vanish from plain `git diff`, corrupting spot-check).
- Execution Workflow step 4: locate edit sites by grep/content match, never issue line anchors (anchors drift after sibling phases).
- Removed duplicate shutdown-routing line in §Shutdown Handling (stated at Communication-discipline bullet).

### Dimensions Evaluated
Consolidation & Trimming, Actionability, Completeness, Role Realism, Boundary Clarity, Spec Alignment, Capability Growth & Cross-Communication, Rename. State-divergence rejection ground retained — second positive exemplar (impl-prompts).

### Rename
No rename.

## 2026-06-09

### Summary
evolve-skills cycle reference update: code-review skill renamed → code-review-verdict; 1 reference updated (Hard Gates enforcement mention in code-philosophy through-line).

### Changes
- "the reviewer enforces hard gates via the code-review-verdict skill".

## 2026-06-09

### Summary
Phase 2 fleet decision: added the docket cwd-outside-repo silent-no-op guard + reconcile-by-`updated_at` discipline to Execution Workflow step 6 (within the existing close-noop line; line count unchanged at 360). Encodes recurring 4/5-repo docket-clobber/stale-reader theme A — no prior cwd-failure-mode coverage.

### Changes
- Step 6: appended cwd guard — docket commands silently NO-OP from a cwd outside the repo tree; `cd` repo-root same Bash call + confirm `updated_at` advanced; a stale read is not a write-failure (reconcile by timestamp, never force-write).

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Actionability, Spec Alignment, Consolidation & Trimming, Rename

### Rename
No rename.

## 2026-06-09

### Summary
Collapsed the triplicated docs-exploration block into the canonical Docs-paths block + rubric (net −6; 366→360). Historical-memory focus items (git-add-under-no-commit, state-divergence authority) confirmed already-encoded — no additions. The dead-AskUserQuestion-path finding was DEFERRED to Phase 2 as a fleet-wide parity-bound question (reviewers disagree on whether "Standalone" is reachable).

### Changes
- §Implement: collapsed restated per-dir docs descriptions (duplicated the CANONICAL Docs-paths block + Implement-Directly rubric) into one line; kept ls-guard, `adr/` location, and conflict/deviation escalation.

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Completeness, Boundary Clarity, Role Realism, Actionability, Capability Growth, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Four changes, physical net +1 (358→359; the reviewer's intended consolidation offset was a within-line token reduction, not a line removal). Two historical-memory gaps folded into existing structure (shared-tree git-diff scoping; dispatch-cited reuse-helper premise-check), one consolidation of duplicated probe-rationale, one fix of a `\!=` zsh-escape artifact that had leaked literally into step 6.

### Changes
- Step 6 (close/verify/comment): `status \!= "in-progress"` → assert `status` is `done` — removed the markdown-rendered backslash-bang; aligns with the agent's own "assert the positive" memory and is more precise (close = move done).
- Build & Commit Hygiene: added "Shared-tree diff scoping" bullet — `git diff` shows all agents' work; scope to your own paths; never `git add` siblings (highest cross-cutting senior-engineer trap; was absent).
- Execution Workflow step 2: added "Premise-check" to Contradiction-detection — grep to confirm a dispatch-cited "reuse existing X helper" exists before planning reuse (distinct from staff TDD-claim rule).
- Execution Workflow step 1: consolidated near-verbatim probe-rationale to a §Communication discipline → "Claim before work" back-reference (L44 verified canonical).

### Dimensions Evaluated
Completeness + Capability Growth (two memory gaps) · Consolidation & Trimming (step-1/L44 dedup) · Actionability (escape-artifact fix) · Boundary Clarity, Role Realism, Spec Alignment, Rename (no change).

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: removed the dangling `§6 continuity preamble` pointer (5 occurrences — the full phrase ×4 at L42/L54/L174/L326 + a `§6 preamble` variant at L340). No §6 heading exists; the continuity preamble is defined in team-lead.md §Teammate Stall & Crash Recovery (Fix-loop re-spawn). Within-line; 358 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble` (×4) and `§6 preamble` → `continuity preamble` (×1). Self-defining term; fleet-symmetric with the same sweep across sdet/security-engineer/team-lead.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — dangling cross-ref) · Terminology consistency.

### Rename
No rename.

## 2026-05-30

### Summary
One consolidation (net 0 lines; ~120 fewer duplicated words). Compressed the frontmatter `**No code comments.**` block to a terse rule + pointer; Code Quality principle 7 is the canonical home for the full remedy, the machine-required-directives allowlist, and the override path — the frontmatter block restated all three and already forward-referenced "rule 7". Up-front hard-rule placement preserved (sibling-parity with sdet.md).

### Changes
- Frontmatter `**No code comments.**`: full restatement (allowlist + remedy + override path) → rule + remove-on-changed-lines + pointer to principle 7 / Override Convention. Behavior unchanged (principle 7 governs identically).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — frontmatter/principle-7 dedup) · Completeness (12 code-philosophy principles audited; each a distinct gate — NOT a consolidation target) · Boundary Clarity (ad-hoc-issue carve-out intact) · Cross-references (sdet 6/7/8, security Consensus Voting, team-lead Rule 7 — stable)

### Rename
No rename.

## 2026-05-30

### Summary
Two self-contained edits (net -1; 359→358). Removed the dead `commit` skill from `skills:` frontmatter (no such skill exists anywhere — verified — and it contradicted the no-commit CRITICAL banner) and trimmed the frozen "(32 fix-round ephemerals)" audit count from the TDD deep-read gate. The recommended closure-authority gate was DEFERRED to Phase 2 coherence — it is paired with a team-lead brief-template change that review-team-lead declined, and an unpaired flag would never fire (fails the Behavioral gate).

### Changes
- `skills:` frontmatter: removed `commit` (dead reference; contradicted no-commit banner). `vote`/`simplify-scout` retained (both exist + invoked in-body).
- Execution Workflow step 2: trimmed frozen "(32 fix-round ephemerals)" count from the TDD deep-read gate.
- DEFERRED to Phase 2: closure-authority gate (cross-cutting; paired team-lead change in dispute).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — frontmatter + frozen-count trim) · Boundary Clarity (no-commit contradiction resolved) · Capability Growth (closure-authority deferred to coherence)

### Rename
No rename.

## 2026-05-26 (Phase 2 coherence)

### Summary
Two coherence fixes from Phase 2 cross-agent review. (1) §Proactive SendMessage Triggers ux-designer line was vacuous when `docs/ux/` is empty (current repo state) — "not resolvable from docs/ux/" read as always-true OR never-true. Reworded as "Introducing a new user-facing pattern OR an existing docs/ux/ spec is ambiguous." (2) §Shutdown Handling auto-shutdown block now matches project-manager.md's inline `TaskStop the Monitor watch (drain doctrine — outstanding watches at shutdown leak resources)` per drain-doctrine symmetry.

### Changes
- §Proactive SendMessage Triggers (L165): reword ux-designer trigger from "not resolvable from docs/ux/" to "Introducing a new pattern OR existing spec is ambiguous" — unambiguous when docs/ux/ is empty.
- §Shutdown Handling §Auto-shutdown on idle bullet: add inline TaskStop the Monitor watch per PM symmetry.

### Dimensions Evaluated
Actionability (PRIMARY — vacuous trigger now concrete) · Spec Alignment (drain doctrine fleet-symmetric)

### Rename
No rename.

## 2026-05-26

### Summary
Two targeted changes net -7 lines (360 → 353). (1) Added TDD deep-read gate to Execution Workflow step 2 — when issue cites a TDD, read end-to-end and consult @staff-engineer/advisor on any WHY ambiguity BEFORE first line of code. Directly targets the audit's dominant rework signal: 32 fix-round ephemerals (DKT-3 fix-3, DKT-15/31/122/138 fix-2) indicating impl-to-TDD divergence surfaced only after code lands. One pre-impl consult is cheaper than a fix-loop respawn. (2) Compressed Override Convention subsection — format authority already stated inline at §Code Quality opener and through-line.

### Changes
- Execution Workflow step 2 (L139): appended "**TDD deep-read gate**" clause — when issue cites TDD, read end-to-end pre-impl; ambiguous WHY → SendMessage advisor BEFORE coding (citing the 32 fix-round audit signal as load-bearing context).
- §Code Quality / Override Convention: compressed prose block to a one-paragraph spec preserving the `OVERRIDE: code-philosophy/<id> — <reason>` format and visible-not-silent principle.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — pre-impl consult gate targets dominant rework signal) · Actionability (concrete checkpoint inside existing workflow step) · Consolidation & Trimming (Override Convention compression)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 3 dangling docs/tdd/* citations)

### Summary
Stripped 3 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.

### Changes
- L50 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L324 Ephemeral completion contract: replaced "(TDD §4.4 rule 7)" with "(per team-lead.md Rule 7)".
- L338 Runtime Discipline opener: replaced "§4.5 applicability matrix" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — two-step claim + same-turn completion + state-divergence rejection authority)

### Summary
Encoded two-step claim ritual (`docket issue edit -a @senior-engineer` BEFORE `docket issue move in-progress`) across bash codeblock + Communication Discipline bullet + Execution Workflow step 1 — three surfaces kept self-consistent. Strict same-turn close-to-shutdown sequence enforced (closes 25-file TeammateIdle gap from audit). State-divergence rejection authority added as second authorized ground (with impl-DKT-40 positive exemplar). Net +8 lines (387 → ~395).

### Changes
- Bash codeblock: inserted `docket issue edit <id> -a @senior-engineer` BEFORE `docket issue move <id> in-progress` (enables team-lead's `-a @senior-engineer -s in-progress` shutdown-sweep probe).
- Comm Discipline claim-before-work bullet: two-step ritual + probe rationale.
- Execution Workflow step 1: two-step ritual + probe rationale (third surface — self-consistency).
- Ephemeral completion contract: 5 steps MUST execute SAME turn; `shutdown_request` is FINAL tool call; drain background Bash before step 5. Targets 25-file TeammateIdle gap from Phase 0.
- Receiving shutdown_request: state-divergence rejection authority added with impl-DKT-40 (2026-05-23) as positive exemplar; tightened against "stay alive for review/verification" rejections.

### Dimensions Evaluated
Actionability (PRIMARY — two-step ritual + same-turn close-to-shutdown) · Capability Growth (state-divergence rejection authority, monitoring probe enabler) · Completeness (drain background Bash, two rejection grounds) · Role Realism (positive exemplar documents impl-DKT-40 behavior)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — docs-dir guard, P7a drop)

### Summary
Two coherence fixes: (1) added docs-dir existence guard to "Check Specs Before Implementing" matching project-manager/staff-engineer convention (prevents spec-not-found in early-stage repos); (2) dropped dead "(P7a)" cross-reference from R7.

### Changes
- §Check Specs Before Implementing: added `ls -d docs/tdd docs/ux docs/spec 2>/dev/null` guard as lead-in
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — docs-dir guard parity) · Actionability (P7a dead-reference removal)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.
- 2026-03-19: Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.
- 2026-03-19: Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting…
- 2026-03-19: Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage…
- 2026-03-19: Consolidated redundant instructions, compressed status-update checklist, added @staff-engineer review notification to self-review workflow…
- 2026-03-20: Consolidation pass removing duplicate content across sections, added memory frontmatter, calibrated self-review depth to change risk.
- 2026-03-20: Consolidation pass removing self-review/Config-as-Code duplication and implicit "when not to consult" list, added @sdet and @project-manager…
- 2026-03-20: Consolidated duplicate build-verification bullets, removed redundant anti-pattern, added @ux-designer cross-communication trigger, compressed…
- 2026-03-20: Removed Anti-Patterns section (restated by Core Operating Principles), compressed CLI Reference and Cross-Cutting Concerns, updated CLI with…
- 2026-03-21: Added cross-communication observability (SendMessage and /vote logging as Docket comments), updated CLI with missing vote flags and…
- 2026-03-29: CLI reference fixes from docket audit (reopen, --domain-tag, --limit, optional --voter, --status, --assignee, --quiet), consolidated Build &…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed Inter-Agent Communication (merged status updates and observability)…
- 2026-03-30: Added rigorous honest mentor directive near top of file. Removed /vote "when NOT" list, folded Mermaid Diagrams into Cross-Cutting Concerns…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, compressed proactive sharing, /vote guidance, and Docket CLI Reference. Added docket aliases. Net: -13…
- 2026-04-06: Added TDD status gate (only implement from ACCEPTED TDDs). Compressed Core Operating Principles and Verification. Updated CLI reference with…
- 2026-04-16: Consolidation pass: trimmed Operating Context boilerplate, Docket Rules redundancy, and self-review bullet list. Aligned CLI reference with…
- 2026-04-16: Cross-communication pass: replaced vague "proactive sharing" prose with concrete phase-indexed SendMessage trigger matrix (before/during/close…
- 2026-04-19: Embedded operator "No guessing — verify" rule at top-of-file principle level adjacent to Rigorous honesty, and reinforced operationally in…
- 2026-05-05: Consolidation pass eliminating triple-stated "no guessing" overlap, redundant `docs/spec/` references, and the restated Docket Rules block.…
- 2026-05-05: Phase 0+2 capability adoption: added `Monitor` for build/dev-server/test streaming, `docket issue graph --mermaid` for refactor blast-radius…
- 2026-05-06: Capability growth via Phase 0 docket CLI audit — added `docket issue log <id>` (pre-start activity context), `docket issue graph --direction…
- 2026-05-06: Adopted PM's operator-visibility contract: every peer SendMessage is mirrored as a Docket comment with `[SE→@agent] {summary}` prefix (operator…
- 2026-05-06: Phase 2 coherence pass: extended operator-visibility contract with high-stakes real-time cc rule (TDD-deviation-requiring-re-plan…
- 2026-05-07: BALANCED-mode consolidation pass: removed three true duplications between Proactive SendMessage Triggers and Check Specs / Navigate Ambiguity…
- 2026-05-07: Phase 2 coherence: corrected the team-mode coordination model claim that contradicted SE's own SendMessage triggers and the team-wide pattern.
- 2026-05-07: Capability-growth pass: closed worktree-isolation gap (SE is the primary user of `isolation="worktree"` per orchestrator) and project-memory…
- 2026-05-08: Removed redundant Docket CLI cheatsheet, deduped TDD-gate and file-attachment rules, sharpened memory section, and made the ADR-broadcast…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner — teammates only read their own definition, so the team-lead.md…
- 2026-05-08: Phase 3 operating discipline: codified four behavioral rules surfaced by operator — no surface-level fixes, no retry loops / no install…
- 2026-05-09: Trim-heavy pass aligned with operator feedback (file-size bloat, no overthinking, output quality). Compressed top-of-file principles…
- 2026-05-09: Phase 2 coherence: added explicit "NOT @security-engineer" boundary (now that the security consult trigger exists), and closed bidirectional…
- 2026-05-13: Added "Implement Directly vs. Escalate for Design" rubric so SE proceeds directly on bugfixes/config/internal-refactors/pattern-extensions and…
- 2026-05-13: Phase 2 coherence: added Direct Task / solo-mode invocation acknowledgment to Operating context — defines behavior when team-lead delegates a…
- 2026-05-16: Consolidated all 8 operator communication-discipline rules into a non-negotiable block (closed-loop, ack, claim-first-Rule-7, 10-min…
- 2026-05-16: Phase 2 coherence: normalize security-advisor canonical form across three references.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).
- 2026-05-17: pass 2: Cycle 2026-05-17 historical-audit pass: dropped aspirational `.claude/agent-memory/senior-engineer/` reference (directory unused across…
- 2026-05-17: Phase 2 coherence: Tightened dispatch-ack to same-turn pattern matching sdet.md Rule 2. Added @security-engineer CVE/advisory incoming trigger.
- 2026-05-19: Cycle 2026-05-19 historical-audit pass. Closes the DKT-2 close-without-verify failure mode (strongest single signal in the audit) with an…
- 2026-05-19: Phase 2 coherence: Added `ux-advisor` canonical-name reference for symmetry with existing `security-advisor` / `advisor` patterns. Existing UX…
- 2026-05-19: Phase 2 coherence — brief contradiction-detection + envelope fallback: Closed the second line of defense on the Phase 1 P1 lesson: added brief…
- 2026-05-24: Phase 2 coherence — shutdown_response routing rule: Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead"…
- 2026-05-25: Phase 1 self-review — shutdown routing example + peer dispatch hard gate: Two targeted rewrites, net 0 lines. (1) Replaced abstract "never to…
