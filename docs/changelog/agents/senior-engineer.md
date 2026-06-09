# Changelog: senior-engineer

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

## 2026-05-25 (Phase 1 self-review — shutdown routing example + peer dispatch hard gate)

### Summary
Two targeted rewrites, net 0 lines. (1) Replaced abstract "never to peer agents" shutdown-routing language with concrete `to="team-lead"` / `to=<agentId>` WRONG-vs-RIGHT format example (closes session 107f84d1 tool_use_error). (2) Added explicit "Peer dispatch is forbidden" hard gate to Mode awareness team-mode bullet — distinguishes peer consult/question (fine) from peer dispatch / delegating new work (always routes through team-lead; closes impl-DKT-9 audit pattern).

### Changes
- §Communication Discipline → Shutdown bullet: rewrote routing language with concrete WRONG/RIGHT `to=` format example
- §Mode awareness → Team mode bullet: added "**Peer dispatch is forbidden**" hard gate — delegating new work to a peer agent always routes through team-lead; consult/question SendMessage remains allowed per triggers

### Dimensions Evaluated
Actionability (PRIMARY — concrete shutdown-routing format example) · Boundary Clarity (consult-vs-dispatch distinction) · Cross-Agent Coherence (shutdown routing aligned with security-engineer + staff-engineer)

### Rename
No rename.

## 2026-05-24 (Phase 2 coherence — shutdown_response routing rule)

### Summary
Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead" routing errors (per historical-auditor) by making the routing rule explicit at the rule-level shutdown statement in Communication Discipline. No file-size change — phrase appended inline.

### Changes
- Communication Discipline → "Shutdown within one turn" bullet: appended Routing clause — `shutdown_response` is ALWAYS addressed to team-lead, never to peer agents or the original dispatcher, even when the `shutdown_request` arrives in a thread previously routed to a peer (review handoff, verification consult).

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — closes shared routing bug) · Actionability (rule visibility at the right scope)

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence — brief contradiction-detection + envelope fallback)

### Summary
Closed the second line of defense on the Phase 1 P1 lesson: added brief contradiction-detection at brief-reading time (mirror of team-lead's Closed-vs-Open detector at brief-authoring time). Also documented the Bash+Python heredoc fallback for spawned-instance Edit/Write envelope mismatches surfaced in this cycle.

### Changes
- Execution Workflow step 2: added brief contradiction-detection rule — if dispatch prompt simultaneously prescribes a shape AND lists that dimension as an open consult, treat the consult as authoritative (SendMessage advisor BEFORE implementing).
- Read-before-Edit/Write subsection: added tool envelope check on dispatch — if spawned-instance envelope lacks Edit/Write despite frontmatter declaration, fall back to Bash+Python heredoc and report mismatch to team-lead.

### Dimensions Evaluated
Boundary Clarity (PRIMARY — brief-reading defense layer) · Actionability (envelope fallback procedure) · Capability Growth & Cross-Communication (mismatch-report trigger to team-lead) · Coherence (Phase 1 closure).

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence)

### Summary
Added `ux-advisor` canonical-name reference for symmetry with existing `security-advisor` / `advisor` patterns. Existing UX consult trigger (line 159, 164) gains discoverability from the role-boundary section.

### Changes
- §What You Are NOT (@ux-designer): added `(canonical persistent name: ux-advisor)` and explicit SendMessage trigger for pattern/consistency questions on user-facing surfaces not resolvable from `docs/ux/`.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — canonical-name symmetry).

### Rename
No rename.

## 2026-05-19

### Summary
Cycle 2026-05-19 historical-audit pass. Closes the DKT-2 close-without-verify failure mode (strongest single signal in the audit) with an executable docket-state precondition before posting "Completed:", hardens Read-before-Edit against 16 fleet hits (compaction-resets-Read clause + Edit `new_string` callout for 4 hits of that error), and closes the visibility-mirror prefix gap on @sdet APPROVE confirmations.

### Changes
- Execution Workflow step 6: split into close-then-verify-then-comment with mandatory `docket issue show <id> --json` status assertion before posting Completed comment.
- "Read before Edit/Write": added compaction-resets-Read clause + Edit `new_string` callout (covers fleet errors #2 and #4).
- Communication Discipline "Ack on receipt": unconditional dispatch-ack paired with Rule 7 in same turn.
- Incoming triggers @sdet APPROVE: now uses `[SE→@sdet] verification-confirmed` prefix per visibility contract; references Execution Workflow step 6 close-verify-comment sequence.
- Saturation + Verify-claims: tightened preambles; added DKT-2 cross-reference to canonicalize the example.

### Dimensions Evaluated
Role Realism · Actionability (PRIMARY — close-without-verify + Read-before-Edit) · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Tightened dispatch-ack to same-turn pattern matching sdet.md Rule 2. Added @security-engineer CVE/advisory incoming trigger.

### Changes
- Rule 7: bound claim-before-work to same-turn SendMessage ack.
- Incoming triggers: added @security-engineer CVE/advisory entry.

### Dimensions Evaluated
Communication discipline; cross-agent handoff bidirectionality.

### Rename
No rename.

## 2026-05-17 (pass 2)

### Summary
Cycle 2026-05-17 historical-audit pass: dropped aspirational `.claude/agent-memory/senior-engineer/` reference (directory unused across 62 invocations), added explicit Read-before-Edit/Write reflex (closes largest non-sandbox error class — 20 "File has not been read yet" hits), and restructured Operating context into bulleted Mode awareness to make solo-mode entry/exit explicit (operator opt-in pattern from OPS-8506).

### Changes
- Operating context: removed Project memory paragraph; quirks worth preserving redirected to `docs/spec/` (staff-engineer-owned).
- Operating context: split into bulleted Mode awareness (Team / Direct Task) with explicit STOP-on-scope-expansion for solo mode.
- Top-of-file principles: added "Read before Edit/Write" reflex below Stop-and-ask.

### Dimensions Evaluated
Trim (PRIMARY — drop unused memory path), Actionability (Read-before-Edit/Write reflex), Boundary Clarity (Team vs Direct mode), Capability Growth, Completeness, Spec Alignment, Role Realism.

### Rename
No rename.

## 2026-05-17

### Summary
Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).

### Changes
- Using /vote for Consensus §Team mode: replaced ad-hoc `{type, skill, question}` payload with canonical shape (`{type, protocol_version, skill, request_id, vote_id, from, summary?}`). Added `docket vote create ... --json` prerequisite; documented `failed` response on missing `vote_id`.

### Dimensions Evaluated
Cross-skill coherence (vote-skill payload contract), Coordination & Handoff.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: normalize security-advisor canonical form across three references.

### Changes
- First @security-engineer reference now uses canonical "(canonical persistent name: `security-advisor`)" phrasing.
- Dropped two subsequent redundant parentheticals — canonical form established earlier.

### Dimensions Evaluated
Security-advisor aliasing consistency.

### Rename
None.

## 2026-05-16

### Summary
Consolidated all 8 operator communication-discipline rules into a non-negotiable block (closed-loop, ack, claim-first-Rule-7, 10-min progress-Rule-8, immediate blocker, saturation, one-turn shutdown, verify-claims) and reordered Execution Workflow so `docket issue move <id> in-progress` is step 1.

### Changes
- Added Communication discipline (non-negotiable) block — 8 rules with Rule 7/8 explicit.
- Execution Workflow: Claim immediately is now step 1 (was step 3).
- Added `docket issue reopen` to rework workflow for post-close regressions.
- Shutdown Handling: explicit one-turn reply (Rule 6).
- "Blocked >15min" split into same-turn-surface vs 15min-cc-escalation to remove "wait 15min" reading.
- Trimmed Project memory paragraph.

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: added Direct Task / solo-mode invocation acknowledgment to Operating context — defines behavior when team-lead delegates a trivial change directly without team scaffolding.

### Changes
- Operating context: added explicit branch for Direct Task / solo mode — single ad-hoc tracking issue, no peer SendMessage, operator reviews via git diff

### Dimensions Evaluated
Coherence (cross-reference with team-lead.md Direct Task pattern), Capability Growth

### Rename
No rename.

## 2026-05-13

### Summary
Added "Implement Directly vs. Escalate for Design" rubric so SE proceeds directly on bugfixes/config/internal-refactors/pattern-extensions and only escalates for new modules/APIs/architectural decisions/user-facing surfaces/shared interfaces/security boundaries. Tightened triggers to defer to the rubric. Net: +20 lines (251 → 271).

### Changes
- Added Implement-Directly vs. Escalate-for-Design rubric with explicit lists for both paths plus a "gray zone resolution" tiebreaker
- Replaced absolute "no TDD for non-trivial work → STOP" trigger with conditional reference to the rubric
- Collapsed Navigate Ambiguity bullet 2 (TDD/UX missing) to a one-line rubric pointer
- Crisped @sdet APPROVE incoming trigger (drop "if not already closed" hedge)
- Annotated `docket issue close <id>` bash example with "no -m flag" inline comment

### Dimensions Evaluated
Completeness (operator pain on design ceremony), Boundary Clarity, Consolidation, Capability Growth, Cross-Communication, Actionability

### Rename
No rename.

## 2026-05-09

### Summary
Phase 2 coherence: added explicit "NOT @security-engineer" boundary (now that the security consult trigger exists), and closed bidirectional gaps for @staff-engineer Block/Concern verdict and @security-engineer Critical/High verdict review-fix-rereview loops.

### Changes
- §What You Are NOT: added "NOT @security-engineer" bullet — no threat models, security TDDs/ADRs, or security-dimension review; SendMessage @security-engineer (or `security-advisor`) before locking auth/secrets/validation/sandbox/supply-chain approaches
- §Proactive SendMessage Triggers / Incoming triggers: added @staff-engineer review verdict (Block / Concern) trigger — address findings, update diff, SendMessage for re-review, do not close while Blockers remain (closes reciprocal to staff-engineer.md outgoing verdict handback)
- §Proactive SendMessage Triggers / Incoming triggers: added @security-engineer review verdict (Critical / High) trigger — halt patches, address before further work, SendMessage for re-review, do NOT downgrade without a vote per security-engineer.md Consensus Voting

### Dimensions Evaluated
Coherence (PRIMARY — bidirectional review-fix loops + boundary), Boundary Clarity, Coordination & Handoffs, Spec Alignment

### Rename
No rename.

## 2026-05-09

### Summary
Trim-heavy pass aligned with operator feedback (file-size bloat, no overthinking, output quality). Compressed top-of-file principles, Operating-context/Worktree/memory block, Docket workflow intro, Execution Workflow steps, SendMessage Triggers preamble, and System-Level Awareness bullets. Added `--depth` flag to graph reference and a missing @security-engineer SendMessage trigger. Net: −56 lines (304 → 248).

### Changes
- Compressed four top-of-file principle paragraphs (Rigorous honesty, No guessing, No surface-level fixes, Stop and ask) — behavior preserved, restatement removed
- Merged Operating context + Worktree mode + Project memory preamble
- Compressed Docket execute-issues intro and bash example, tightened ad-hoc / trivial-exception carve-out
- Compressed Execution Workflow team-mode preamble and steps 1, 2, 5, 6, 7
- Compressed SendMessage Triggers preamble (visibility contract + TaskUpdate cadence merged)
- Compressed System-Level Awareness; folded backward-compat + serialized-formats bullets; added `docket issue graph --depth N` per Phase 0 audit
- Added @security-engineer SendMessage trigger for auth/secrets/validation/sandbox/supply-chain — closes team-lead Security Track contract gap

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — −56 lines), Output Quality (less monologue at top of file), Capability Growth & Cross-Communication (security-engineer trigger, --depth flag), Role Realism, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: codified four behavioral rules surfaced by operator — no surface-level fixes, no retry loops / no install workarounds (ask for help, session may need restart), never `git stash` (breaks concurrent agents), and remember solutions to non-obvious problems.

### Changes
- Added "No surface-level fixes" rule near intro: trace defects to root cause; if clean fix is out of scope, file a follow-up rather than paper over
- Added "Stop and ask, do not retry" rule: one diagnostic pass, then SendMessage operator/team-lead with failure output and a specific question — no retry loops, no install workarounds, no scope-escalation; surface tool-config gaps that may need a session restart
- Added `Never git stash` to Build & Commit Hygiene: stash hides changes from concurrent agents; use new worktree to swap context, leave uncommitted to pause
- Strengthened Project memory section: explicitly save solutions to non-obvious problems (symptom + root cause + fix) so future sessions don't re-diagnose

### Dimensions Evaluated
Role Realism (PRIMARY — codifies operator-observed misbehaviors), Completeness (rules previously implicit), Capability Growth (memory now captures problem-solution pairs), Boundary Clarity

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner — teammates only read their own definition, so the team-lead.md banner ban was invisible.

### Changes
- CRITICAL banner now covers both commit ban AND `/vote`/Skill/Agent/TeamCreate ban

### Dimensions Evaluated
Coherence (PRIMARY — CRITICAL banner uniformity across fleet), Behavioral (clarifies an existing rule that was hidden)

### Rename
No rename.

## 2026-05-08

### Summary
Removed redundant Docket CLI cheatsheet, deduped TDD-gate and file-attachment rules, sharpened memory section, and made the ADR-broadcast trigger concrete. Net: -29 lines (326→297).

### Changes
- Removed bottom Docket CLI Reference (cheatsheet duplicated `docket --help` and inline workflow examples)
- Deduped "TDD status gate" paragraph (already covered by Before-starting SendMessage trigger)
- Collapsed file-attachment verification step (already covered by Before-starting trigger)
- Sharpened Project Memory section with save/don't-save lists matching staff-engineer/sdet specificity
- Replaced unclear "ADR `*` broadcast" wording with a concrete @staff-engineer trigger
- Removed generic Cross-Cutting Concerns stub (non-executable; code-quality.md pointer is canonical)

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — -29 lines), Actionability (ADR trigger now concrete), Completeness (memory specificity), Role Realism, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-07

### Summary
Capability-growth pass: closed worktree-isolation gap (SE is the primary user of `isolation="worktree"` per orchestrator) and project-memory gap. Tightened Pre-Flight gate, Vote section, and self-review handoff bullet to offset additions. Net: -10 lines (336→326).

### Changes
- Added Worktree mode paragraph to Operating context — closes a real capability gap. SE was the primary user of `isolation="worktree"` spawns but had no behavioral guidance for sibling-worktree cwd, branch HEAD as working ref, absolute paths to non-source assets
- Added one-line `.claude/agent-memory/senior-engineer/` reference so SE actually consults/writes project memory at session start and after operator-validated approaches
- Tightened Pre-Flight gate (-7) by collapsing Standalone/Team mode bullets into a single paragraph; preserved "document confirmed assumptions in a Docket comment" behavioral guidance
- Tightened Vote section (-3) and reframed to make team-lead.md compliance explicit (delegation is the only path under an orchestrator, not "default"); spawning nested teams is forbidden
- Replaced redundant handoff sub-bullet (line 146) with reference to canonical Before-close triggers
- REJECTED: `move <id> review` then close-on-APPROVE workflow change — creates ambiguity with sdet's reopen-on-BLOCK assumption that SE closes first. Flagged for Phase 2 coherence review.

### Dimensions Evaluated
Capability Growth (PRIMARY — worktree, agent memory), Consolidation & Trimming, Boundary Clarity (Vote/team-lead.md alignment), Spec Alignment

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: corrected the team-mode coordination model claim that contradicted SE's own SendMessage triggers and the team-wide pattern.

### Changes
- Operating context: replaced "coordinate via SendMessage to team-lead, never peer-to-peer" (added in Phase 1) with the accurate model — peers SendMessage directly per the triggers section, team-lead is cc'd on high-stakes events. Removes contradiction with the ~15 direct peer SendMessage actions documented in the triggers section and aligns SE with how staff/sdet/ux/PM operate in team mode.

### Dimensions Evaluated
Internal consistency (Operating context vs SendMessage triggers), cross-agent operating-model coherence, operator-visibility contract preservation.

### Rename
None.

## 2026-05-07

### Summary
BALANCED-mode consolidation pass: removed three true duplications between Proactive SendMessage Triggers and Check Specs / Navigate Ambiguity sections (TDD status gate, missing TDD/UX spec, architectural decisions vs TDD deviation). Compressed Pre-Flight "During implementation" restatement and TaskUpdate cadence verbiage. Added one-line note in Operating context that team-lead is the only relay when spawned in a team.

### Changes
- Merged "TDD status != accepted" Before-starting trigger into the existing Check Specs status gate (single source of truth)
- Compressed Navigate Ambiguity items 2 & 3 into one line that defers to the Proactive Triggers contract
- Merged "Architectural decision not covered by TDD" with "Approach deviates from TDD" trigger
- Trimmed Pre-Flight "During implementation" sub-bullet (covered by Standalone/Team mode + No-Guessing)
- Trimmed close-out and discoveries Docket bash blocks to one-liners
- Trimmed SendMessage auto-resume note (redundant with operator-visibility contract)
- Added team-lead-only-relay clarification to Operating context

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Capability Growth, Cross-Communication, Role Realism, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-06

### Summary
Phase 2 coherence pass: extended operator-visibility contract with high-stakes real-time cc rule (TDD-deviation-requiring-re-plan, scope-expansion, blocked-15min, security-boundary). Closed two bidirectional gaps: added @ux-designer outgoing trigger for design QA on user-facing surfaces (inverse of ux-designer's incoming); added @project-manager cc to blocked-15min trigger (closes loop with PM's stalled-work check-in).

### Changes
- Extended operator-visibility contract to require concurrent team-lead cc on high-stakes events (do not buffer)
- Added "Diff ready on user-facing surface with `docs/ux/` spec → SendMessage @ux-designer for design QA" outgoing trigger
- Added "also SendMessage @project-manager if the block requires re-plan or scope cut" to Blocked-15min trigger

### Dimensions Evaluated
Cross-Communication & Observability (PRIMARY), Bidirectional Trigger Coverage, Coherence with Fleet Standards

### Rename
No rename.

## 2026-05-06

### Summary
Adopted PM's operator-visibility contract: every peer SendMessage is mirrored as a Docket comment with `[SE→@agent] {summary}` prefix (operator reads Docket, not the agent message bus). Added SendMessage auto-resume + TaskUpdate cadence note. Reverted the "discovered follow-up" trigger to use the new mirror contract.

### Changes
- Added operator-visibility contract preamble to Proactive SendMessage Triggers (mirrors PM pattern; closes operator's "can't see cross-agent comms" complaint)
- Added SendMessage auto-resume note + TaskUpdate-at-every-transition cadence rule
- Reworded "Discovered follow-up work" trigger to invoke the visibility contract explicitly

### Dimensions Evaluated
Cross-Communication Visibility (PRIMARY), Capability Growth, Spec Alignment, Role Realism, Actionability

### Rename
No rename.

## 2026-05-06

### Summary
Capability growth via Phase 0 docket CLI audit — added `docket issue log <id>` (pre-start activity context), `docket issue graph --direction up|down|both` (blast-radius), and `docket plan --root <id> --json` (phased execution view) to System-Level Awareness and CLI reference. Trimmed Operating Context restatement (3 lines → 1). Reviewer initially proposed a hub-routing rewrite (rejected — see follow-up entry above for the corrected approach via PM's visibility contract).

### Changes
- Added `docket issue log <id>` pre-start check to System-Level Awareness (Phase 0 audit recommendation)
- Added `docket issue graph --direction up|down|both` for explicit blast-radius direction control
- Added `docket plan --root <id> --json` for parent-scoped phase view before claiming child issues
- Updated CLI reference block to include `docket plan` and graph `--direction`/`--depth` flags
- Trimmed Operating Context paragraph (3 → 1 line; removed restatement already implied by Pre-Flight Gate and Check Specs)
- REJECTED: hub-routing rewrite of SendMessage triggers — based on misinterpretation of EVOLVE-cycle rule

### Dimensions Evaluated
Capability Growth (PRIMARY — CLI surfaces), Completeness (Phase 0 audit), Consolidation, Cross-Communication, Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 0+2 capability adoption: added `Monitor` for build/dev-server/test streaming, `docket issue graph --mermaid` for refactor blast-radius, Team-mode Task system semantics, `color: green` frontmatter. Closed bidirectional gap with @ux-designer pattern-consistency consult. Net: +16 lines (333→349).

### Changes
- Added `Monitor` to tools + Verification Feedback Loop pattern (Phase 0)
- Added `docket issue graph <id> --mermaid` to System-Level Awareness for refactor blast-radius
- Added Team-mode Task system guidance to Execution Workflow (TaskList/TaskUpdate semantics, complementary to Docket)
- Removed duplicated `/vote` teammate-fallback sentence from Operating context
- Added `color: green` frontmatter (Phase 2 fleet decision)
- Added outgoing trigger: pattern/consistency consult to @ux-designer for user-facing surfaces (Phase 2 — closes inverse-trigger gap)
- Deferred (Phase 2): `effort: xhigh`, `model: claude-opus-4-7` — A/B one agent first

### Dimensions Evaluated
Completeness (PRIMARY — Monitor, mermaid, Task system), Cross-Communication (pattern-consult), Capability Growth, Consolidation & Trimming, Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Consolidation pass eliminating triple-stated "no guessing" overlap, redundant `docs/spec/` references, and the restated Docket Rules block. Added subagent-as-teammate tool restriction note (Phase 0 finding) and `docket issue graph` to CLI reference. Net: -20 lines (349→329).

### Changes
- Removed Verification Feedback Loop's "before writing code" bullet (duplicated top-level No Guessing principle)
- Removed Docket Rules subsection (3 bullets restating earlier prose)
- Compressed Pre-Flight "During implementation", `/vote` standalone fallback, Decision-Making Framework, Build & Commit Hygiene, Cross-Cutting Concerns, step 4 spec re-reference
- Added subagent-as-teammate Operating context note: skills like `/vote` may be unavailable when invoked as teammate
- CLI: added `docket issue graph <id>` for dependency context
- [Phase 2] Added 4 incoming-trigger entries closing inverse-trigger gaps: @sdet APPROVE/coverage-gap/flaky-confirmed signals, @staff-engineer review re-plan halt

### Dimensions Evaluated
All 8: Consolidation & Trimming (PRIMARY), Completeness (CLI graph, teammate restrictions), Capability Growth & Cross-Communication (teammate context), Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-19

### Summary
Embedded operator "No guessing — verify" rule at top-of-file principle level adjacent to Rigorous honesty, and reinforced operationally in Verification Feedback Loop. Compressed boundary prose and redundant SendMessage closings to offset.

### Changes
- Added "No guessing — verify" top-level principle — STOP and verify APIs/signatures/paths via Read, Grep, Bash, WebFetch; never invent imports or patch symptoms
- Added pre-code verification bullet to Verification Feedback Loop
- Compressed "What You Are NOT" (8 → 5 lines) and SendMessage preamble; removed redundant "Report transitions" block
- [Phase 2] Added @sdet source-clarification incoming trigger — reciprocates SDET fixture/framework uncertainty outgoing
- [Phase 2] Added @project-manager plan-change incoming trigger — reciprocates PM active-issue scope/dep notifications

### Dimensions Evaluated
All 8: Role Realism (primary — No Guessing), Actionability (verification steps), Consolidation (offset trims), Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: replaced vague "proactive sharing" prose with concrete phase-indexed SendMessage trigger matrix (before/during/close, 14 triggers). Added Incoming triggers for bidirectional reciprocity. Trimmed boilerplate across Operating Context, Rigorous Honesty, What You Are NOT, Pre-Flight Gate, and Check-Specs. Applied Docket CLI audit findings. Net: -29 lines.

### Changes
- PRIMARY: Added phase-indexed SendMessage trigger matrix — 14 concrete "when X → notify Y" rules grouped by implementation phase (before/during/close)
- [Phase 2] Added Incoming triggers block: @sdet BLOCK fix-loop, TDD-accepted/revised preload, @ux-designer spec-revision reconcile, ADR `*` broadcast consumption; flag test-infra-adjacent changes on review handoff
- Trimmed Operating Context (-2), Rigorous Honesty (-4), What You Are NOT (-7), Pre-Flight Gate (-17), Check-Specs (-8)
- CLI: `docket export` expanded; `vote list` added `-d|--domain-tag TAG`; `vote create` documented `-r|--rationale` short form

### Dimensions Evaluated
All 8: Cross-Communication (GOAL — primary), Consolidation (HIGHEST priority), Completeness (CLI audit), Boundary Clarity, Role Realism, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Consolidation pass: trimmed Operating Context boilerplate, Docket Rules redundancy, and self-review bullet list. Aligned CLI reference with Docket audit findings. Phase 2 coherence: normalized `--created-by` value name and added `vote list` default-behavior comment. Net: -13 lines.

### Changes
- Trimmed Operating Context — removed inherited "verify in production" / "own the regression" metaphors already implied by role
- Compressed Docket Rules — removed restated intro guidance
- Compressed Execution Workflow step 5 — merged notify bullets and diff-review bullets
- CLI: `vote cast` now documents `--findings-json FILE` alternative (aligned with @sdet)
- CLI: `vote list` now documents `--all` flag (default is open-only)
- CLI: `issue create` clarified `-f FILE ...` (repeatable, not multi-value)
- [Coherence] `--created-by AGENT` → `--created-by NAME` (peer-agent convention)
- [Coherence] Added `--all` default-behavior comment to `vote list`

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Completeness (CLI audit), Spec Alignment, Actionability, Role Realism, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added TDD status gate (only implement from ACCEPTED TDDs). Compressed Core Operating Principles and Verification. Updated CLI reference with audit findings. Net: -3 lines.

### Changes
- **CRITICAL**: Added TDD status gate — only implement from TDDs with `status: accepted` frontmatter; non-accepted TDDs block implementation with notification
- Compressed "Own the Outcome" — removed non-executable "regressions after close" (-1 line)
- Compressed "Right-Size the Effort" — merged sink-cost paragraph into single sentence (-3 lines)
- Compressed Verification Feedback Loop — removed puffery and redundant "mediocre, redo" bullet (-2 lines)
- Updated CLI: `--created-by`/`--escalation-reason` on vote create, `--summary`/`--voter` on vote cast, `export --status` (+1 line)

### Dimensions Evaluated
All 8: Completeness (TDD gate — primary, CLI audit), Consolidation & Trimming, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter, compressed proactive sharing, /vote guidance, and Docket CLI Reference. Added docket aliases. Net: -13 lines.

### Changes
- Added `model: opus[1m]` to frontmatter (settings standardization)
- Compressed proactive sharing from 12 to 5 lines with trigger→recipient mapping
- Merged /vote "when to invoke" bullets, tightened trailing prose (-5 lines)
- Compressed Docket CLI Reference: inlined VERDICT, merged vote subcommands, added aliases (-3 lines)

### Dimensions Evaluated
All 8: Completeness (frontmatter), Consolidation & Trimming (primary), Capability Growth (docket aliases), Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest mentor directive near top of file. Removed /vote "when NOT" list, folded Mermaid Diagrams into Cross-Cutting Concerns, added missing CLI flags, fixed orphan dependency bullet. Net: -2 lines.

### Changes
- Added "Rigorous honesty over agreeability" directive after intro paragraph (+8 lines)
- Removed "When NOT to invoke /vote" list — logical inverse of "when to invoke" (-4 lines)
- Folded Mermaid Diagrams subsection into Cross-Cutting Concerns one-liner (-3 lines)
- Added `--label` flag to `issue create` and `--escalation-reason` to `vote commit` in CLI reference
- Merged orphan dependency-scrutiny bullet into Technical Debt list (-1 line)

### Dimensions Evaluated
Role Realism (mentor directive), Completeness (CLI audit flags), Consolidation & Trimming (vote, mermaid, orphan bullet), Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed Inter-Agent Communication (merged status updates and observability), trimmed consult list and description, shortened Mermaid section. Net: -13 lines.

### Changes
- Added task coordination tools to frontmatter tools list
- Merged "Status updates to the operator" and "Cross-communication observability" into "Status updates and observability" (-5 lines)
- Compressed @staff-engineer consult list from 4 to 3 bullets (-2 lines)
- Shortened frontmatter description (-2 lines)
- Compressed Mermaid Diagrams section (-2 lines)
- [Coherence] Consolidated standalone Delegation Protocol into /vote section (aligned with staff-engineer/ux-designer pattern)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness (task tools), Coherence (Phase 2), all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
CLI reference fixes from docket audit (reopen, --domain-tag, --limit, optional --voter, --status, --assignee, --quiet), consolidated Build & Commit Hygiene and Decision-Making Framework, merged Dependency Evaluation into Technical Debt.

### Changes
- Fixed CLI reference: added `reopen`, `--domain-tag`, `--limit` on vote list; marked `--voter` optional; added `-s`/`-a` on issue create
- Added `--quiet` flag documentation (global note + ad-hoc example)
- Compressed Build & Commit Hygiene from 5 bullets to 3 (merged lockfile and commit discipline bullets)
- Compressed Decision-Making Framework from 2 paragraphs to 1
- Merged Dependency Evaluation section into Technical Debt as fourth bullet

### Dimensions Evaluated
Completeness (CLI audit — primary), Consolidation & Trimming, Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (SendMessage and /vote logging as Docket comments), updated CLI with missing vote flags and approve-with-concerns verdict, compressed Delegation Protocol and Own the Outcome.

### Changes
- Added cross-communication observability subsection: log SendMessage exchanges and /vote outcomes as Docket comments
- Added vote outcome logging to /vote section
- Updated CLI: -T/-s on next, --domain-tags/--files-changed/--escalation-reason on vote create, --findings-json/--summary on vote cast, approve-with-concerns verdict
- Compressed Delegation Protocol from bullet list to inline format
- Trimmed "Own the Outcome" (removed redundancy with Navigate Ambiguity)

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness (CLI audit), Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Removed Anti-Patterns section (restated by Core Operating Principles), compressed CLI Reference and Cross-Cutting Concerns, updated CLI with `log` and `file add` commands.

### Changes
- Removed Anti-Patterns to Avoid section entirely (scope creep, silent compliance, resume-driven dev all restated in Core Operating Principles and Dependency Evaluation)
- Compressed Docket CLI Reference from 15 to 10 lines, added `log`, `file add`
- Compressed Cross-Cutting Concerns to remove explicit spec file names (already says "relevant docs/spec/")
- Compressed Dependency Evaluation bullet to paragraph

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated duplicate build-verification bullets, removed redundant anti-pattern, added @ux-designer cross-communication trigger, compressed Docket CLI Reference, improved Navigate Ambiguity for stateless model.

### Changes
- Merged two duplicate "run the build" bullets in self-review step 5 into one
- Removed Operator Alignment anti-pattern paragraph (restated by "During implementation" bullets)
- Added @ux-designer to proactive sharing examples in Inter-Agent Communication
- Compressed Docket CLI Reference by removing section headers and shortening descriptions
- Reworded "reasonable timeframe" to "current session" in Navigate Ambiguity

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Consolidation pass removing self-review/Config-as-Code duplication and implicit "when not to consult" list, added @sdet and @project-manager cross-communication triggers, realigned Docket CLI Reference.

### Changes
- Replaced verbose generated-output self-review bullet with pointer to Config-as-Code Safety section
- Removed "When NOT to consult — just proceed" subsection (logical inverse of consult list)
- Added @sdet notification after implementation completion for test verification handoff
- Added @project-manager SendMessage trigger for scope discoveries
- Replaced `docket issue list` in CLI Reference with `docket next` (agent's actual entry point)
- Compressed "Right-Size the Effort" from 3 lines to 1
- [Coherence] Added `vote` to `skills` frontmatter to match body usage
- [Coherence] Description frontmatter now mentions @sdet verification alongside @staff-engineer review

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Consolidation pass removing duplicate content across sections, added memory frontmatter, calibrated self-review depth to change risk.

### Changes
- Removed "Own the Outcome" alignment paragraph (duplicate of Operator Alignment section)
- Removed "Navigate Ambiguity" preamble paragraph (restated by its own bullets)
- Compressed Inter-Agent Communication preamble from 5 lines to 1
- Removed "Plan Before You Execute" subsection (covered by Check Specs and System-Level Awareness)
- Trimmed Docket CLI Reference session-setup block (duplicated by Session Initialization)
- Merged "debuggable code" bullet into error-context bullet in Code Quality
- Added `memory: project` frontmatter for cross-session codebase learning
- Added risk-calibrated self-review guidance
- [Coherence] Added missing `effort: max` frontmatter (aligned with all other agents)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Capability Growth, Role Realism

### Rename
No rename.

## 2026-03-19

### Summary
Consolidated redundant instructions, compressed status-update checklist, added @staff-engineer review notification to self-review workflow, pointed cross-cutting concerns to relevant specs.

### Changes
- Removed duplicate "verify TDD match" from System-Level Awareness (already in self-review step 5)
- Removed "Copy-paste implementation" anti-pattern (redundant with DRY in Code Quality)
- Compressed 6-bullet status-update checklist into compact paragraph format
- Added concrete SendMessage notification to @staff-engineer after self-review in step 5
- Removed "Other SendMessage uses" sub-section (all items covered elsewhere)
- Removed "When asked to cut corners" bullet (covered by anti-patterns and intro)
- Updated cross-cutting concerns to reference relevant spec files
- [Coherence] Clarified file attachment verification: PM attaches, engineer verifies, scoped STOP to pre-planned issues

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Spec Alignment, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage inter-agent communication guidance.

### Changes
- Merged "Verify after deployment" (step 7) into self-review checklist (step 5) to eliminate redundant build-run instructions
- Compressed Dependency & API Surface Evaluation from 3 bullets to 1 focused bullet
- Shortened SDET boundary bullet from 6 lines to 3 without losing key information
- Added Inter-Agent Communication subsection with SendMessage guidance for real-time teammate coordination
- Fixed double blank line formatting inconsistency
- [Coherence] Replaced "orchestrator" with "user or team lead" (3 occurrences)
- [Coherence] Added SendMessage to tools frontmatter
- [Coherence] Streamlined session initialization to context-dependent commands

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth, Role Realism, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting Concerns checklist.

### Changes
- Expanded self-review serialization bullet into a concrete before/after diff step aligned with project's config-generator nature
- Removed Incident Response & Debugging subsection — stateless agent cannot perform ongoing incident management; useful debugging guidance already covered by existing principles
- Compressed Cross-Cutting Concerns from verbose parenthetical definitions to terse checklist

### Dimensions Evaluated
Role Realism, Consolidation & Trimming, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.

### Changes
- Added missing UX spec escalation bullet to "Navigate Ambiguity" section, parallel to existing TDD escalation pattern, with trivial-change carve-out

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.

### Changes
- Removed five entire sections: Database & Schema Changes, Growing Engineers Around You, Technical Spikes & Prototyping, Communication Style, Cross-Functional Collaboration
- Removed Complete Workflow section (duplicate of Docket Execution Workflow)
- Merged Backward Compatibility, Production Ownership, Negotiate Scope, Build & CI Hygiene into existing sections
- Compressed Core Operating Principles, Decision-Making Framework, Anti-Patterns, Docket Rules

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Role Realism

### Rename
No rename.
