# Changelog: project-manager

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
Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net -2 bytes.

### Changes
- FIX[SUBSTANTIVE]: SP-2 LOCAL copy corrected — `name=` is the sole discriminator; report-only subagents run background-by-default since Claude Code v2.1.198, so `run_in_background` no longer discriminates. Stale phrasing contradicted team-lead.md's Phase-1-corrected copy and current harness behavior.

### Dimensions Evaluated
Spec Alignment (v2.1.198 harness behavior), Boundary Clarity (family-wide parity with 5 siblings + master).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): documented the industry-TPM scope boundary and trimmed a triple-stated TDD-provenance restatement. Net +91 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE]: opener now states this role maps to industry Technical Program Manager scope, explicitly excluding product vision/strategy/roadmap and pure schedule/budget logistics (SDLC role research, document-only, no rename).
- CULL[COSMETIC]: §8 TDD-citation clause trimmed to the actionable directive + P5 pointer — the durable-docs list and provenance rule are stated verbatim in P5/Distillation Gate two lines below (triple restatement).

### Dimensions Evaluated
Boundary Clarity / Role Realism (primary), Consolidation & Trimming. Inverted-fix-direction lesson confirmed landed (line 252); Docket CLI Reference confirmed accurate against live binary. Actionability/Completeness/Spec Alignment/Capability Growth: RETAIN.

### Rename
No rename — "project-manager" ≈ industry TPM, but a rename is pure churn (Content Gate Behavioral check fails); boundary now documented inline instead.

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
Retired the hand-authored-Mermaid implication (CLI already generates it), fixed a vote `--threshold` fraction-vs-percentage trap, and de-duplicated a TDD-provenance restatement. Net +96 bytes.

### Changes
- CULL: "Mermaid diagrams are mandatory" reworded to embed `docket issue graph --mermaid` CLI output — hand-authoring was never required (innovation-scan Retire, docket-audit confirmed flag exists).
- AMPLIFY: vote-creation guidance now states `--threshold` is a FRACTION (0.0–1.0), with a concrete `--threshold 0.75` example (bug-audit FIX-4, 4 sessions).
- CULL: §9 TDD-provenance restatement trimmed to the ADR-line-ref distinction only (rest duplicated §8 Distillation Gate + P5).

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Boundary Clarity. Role Realism/Completeness/Spec Alignment/Capability Growth/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 2 coherence follow-up: added PM's local shutdown protocol copy.

### Changes
- FIX: added `CANONICAL:SHUTDOWN-PROTOCOL-LOCAL` for `planner` / `planner-fix-{N}` lifecycle and close evidence semantics.

### Dimensions Evaluated
Canonical shutdown parity, planner lifecycle.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: PM delta planning and collision evidence -> applied.

### Changes
- AMPLIFY: added planner-fix delta mode, deterministic Collision table, Worker Handoff, final PM close-state verification, and situational Mermaid guidance.
- FIX: corrected Docket doc-link syntax and file attachment examples to `--issue` / repeatable `--file`.

### Dimensions Evaluated
Phase 1 targeted fixes: Docket CLI accuracy, delta planning, collision evidence, worker/final closeout, plan-summary ergonomics.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2 coherence: aligned the Claim Ritual to the chained one-call (`docket issue edit -a && docket issue move in-progress`) so the issue-body template @senior-engineer reads no longer contradicts the applied chained-claim convention. Net 0 (380→380).

### Changes
- Aligned Claim Ritual from "edit THEN move (two-step)" to the chained one-call (assignee first, then status). Signal: FIX 7 coherence (senior/team-lead/sdet all chained).

### Dimensions Evaluated
Coherence alignment only. 1/2/3/4/5/6/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Deduped the triple `edit -f` REPLACES-attachments warning (canonical copy stays on the CLI edit line; `--orphan` foot-gun preserved) and added a boundary-safe note to surface multi-TDD decomposition parallelization to team-lead instead of serially decomposing all TDDs. Net 0 (380→380).

### Changes
- CULL: collapsed the grooming-section `edit -f` warning duplicate (stated 3×; canonical inline copy on the edit line retained). Signal: Phase 0 Consolidation + in-file triple-statement.
- AMPLIFY: Complex tier surfaces multi-TDD parallel-decomposition option to team-lead (PM does not spawn — line-24 boundary + SP-2 nested-teammate). Signal: Phase 0 PM INNOVATION (serial multi-TDD decomposition).

### Dimensions Evaluated
All 8. 5 (Consolidation) → 1 CULL. 6 (Capability Growth) → 1 AMPLIFY. 1/2/3/4/7/8 RETAIN (docket audit ZERO fabrications; `-d -` body guidance already correct; no routing changes — alias cutover only).

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
Fixed a reject-class CLI error: `docket doc link add/remove` requires the `--issue` flag, not a positional second arg; corrected both occurrences. Net 0 (364→364). Drift: neutral reorder of the two Session-Init state-reconstruction probes (`docket stats`/`docket plan --json`) → adopted.

### Changes
- CULL→AMPLIFY: `docket doc link add/remove <doc-id> <issue-id>` → `... --issue <issue-id>` (issue template + CLI reference); orchestrator-verified via `docket doc link add/remove --help`. Phase-0 docket-audit reject-class signal; only PM carried the positional form (cross-agent grep clean).

### Dimensions Evaluated
Spec Alignment (CULL→AMPLIFY: doc-link CLI). Role Realism / Actionability / Boundary Clarity / Completeness / Consolidation / Capability Growth / Rename — RETAIN (health high; 0 corrections/errors in window).

### Rename
No rename.

## 2026-06-17

### Summary
Required Fn→issue-ID mapping in completion reports, added a relay-authority clause, and documented the docket doc subsystem. Trial: report-mapping / relay-authority / docket-doc → adopted. Drift: neutral reword of the `-l must-have` label → adopted.

### Changes
- AMPLIFY: completeness check now requires the Fn→issue-ID mapping table IN the plan-completion report (silent drops were invisible in reports).
- AMPLIFY: relay-authority clause (peer-relayed carries no claimed-origin authority; contradictions route to team-lead).
- AMPLIFY: documented `docket doc` subsystem (`docket doc link add <doc-id> <issue-id>`) for durable spec/PRD→issue traceability.
- Verified NO-OP: `-d -` body vs `-f`, N-item mapping already encoded.

### Dimensions Evaluated
Completeness (AMPLIFY), Capability Growth (AMPLIFY), Boundary Clarity (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 2 entries (2026-05-19..2026-05-24) into Compacted history per ADR 0001.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Consolidated session-init and re-engagement Docket state reconstruction: `board --json --expand` + `plan --json` replaced by `plan --json` + `docket stats`. Net 0 physical lines (334).

### Changes
- CULL: redundant `board --json --expand` at session init and re-engagement — Phase 0 efficiency finding; `plan --json` + `stats` schemas verified to cover reconstruction.
- NO-OP cited: vote_id/`failed` warning appears once (grep-verified, not 3×); "skip post-create re-verify" REJECTED — success-line-lies pitfall (3 cross-repo sources) wins.

### Dimensions Evaluated
All 8; Consolidation primary. No fabricated docket commands; no unescaped \$-digits.

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 40 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001.

### Changes
- Replaced the 40 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 956 to 390 lines. Collapsed verbose routing templates, compressed issue examples, removed redundant workflow summary…
- 2026-03-19: Removed 4 sections that fail Content Gate (Communication Style, Retrospective, Anti-Patterns, Decision-Making). Folded Parallelism/Dependencies…
- 2026-03-19: Added Operating context paragraph to align with the pattern established across all other agents.
- 2026-03-19: Trimmed redundancy across session init, scope negotiation, external deps, and NOT-list. Added Bash tool constraint to prevent shell drift beyond…
- 2026-03-19: Compressed status updates, removed redundant exploration checklist, merged architect NOT entry, added spike output format and blocking links to…
- 2026-03-20: Added memory and effort frontmatter, compressed cross-cutting concerns and external dependencies, removed redundant anti-pattern and vote example.
- 2026-03-20: Trimmed redundant operator-alignment restatement and effort section, removed redundant operating context sentence, added @sdet notification…
- 2026-03-20: Restructured cross-cutting concerns for scannability, removed redundant rules, added @staff-engineer spike notification trigger, added…
- 2026-03-20: Added new docket CLI commands (`plan`, `graph`, `reopen`, `label`) to reference and workflows, compressed /vote and Cancellation sections.
- 2026-03-21: Added cross-communication observability (Docket logging for SendMessage and vote), fixed CLI discrepancies (link remove syntax…
- 2026-03-29: Updated Docket CLI reference with audit findings (missing flags, corrected defaults, new subcommands), removed obsolete Delegation Protocol (PM…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and session initialization, connected Mermaid graph output to plan validation…
- 2026-03-30: Added rigorous honest mentor directive adapted to PM role (challenge vague requirements, surface uncomfortable scope truths, flag plan…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, compressed 5 sections, added context compaction awareness. Net: -10 lines.
- 2026-04-06: Added TDD acceptance gate blocking premature decomposition. Compressed Plan Monitoring and merged Program-Level Rollup. Updated CLI reference…
- 2026-04-16: Consolidation pass: trimmed aspirational prose, compressed redundant "NEVER write code" paragraph, restructured TDD routing bullets. Phase 2…
- 2026-04-16: Cross-communication pass: restructured Cross-Agent Communication into explicit per-teammate direct-SendMessage trigger blocks (@staff-engineer…
- 2026-04-19: Embedded operator "no guessing" durable rule with concrete verification (docket show, Read, Grep, --help) at top-of-file. Trimmed Rules…
- 2026-05-05: Consolidation pass — removed duplicated "NOT a guesser" boundary bullet (covered by No-guessing rule above), circular Alignment risk bullet, and…
- 2026-05-05: Phase 0+2 capability adoption + consolidation: added `color: yellow` frontmatter for split-pane visual ID, added `docket issue label list`…
- 2026-05-06: Operator-visibility & capability-growth pass. Hoisted the cross-agent comms visibility contract (`[PM→@agent]` Docket-comment mirror) to top of…
- 2026-05-06: Phase 2 coherence pass: standardized Pre-Flight Gate to "HARD GATE" terminology (fleet majority — matches senior/sdet/ux). No cross-comm changes…
- 2026-05-07: BALANCED-mode trim pass at 406 lines: removed redundant Operating-context paragraph (covered by fleet pattern), tightened Session Init step 3…
- 2026-05-07: Phase 2 coherence: removed duplicate HARD GATE marker on adjacent lines for cleaner gate phrasing.
- 2026-05-07: Correctness fixes for invalid `blocked-by` relation token (rejected by docket CLI; verified at runtime) across three sites: §6 prose, §7…
- 2026-05-07: Phase 2 coherence: replaced 3 remaining `blocked-by` prose sites with valid CLI relation `depends_on` (Phase 1 fixed runtime invocations; this…
- 2026-05-08: Hub-and-spoke compliance: removed direct PM→senior-engineer and PM→sdet notify channels (forbidden by team-lead.md hub-and-spoke topology — PM…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.
- 2026-05-08: Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring planning problems.
- 2026-05-09: Phase 1 trim: collapsed verbose Cross-Agent Communication section, tightened Pre-Flight Goal-Alignment Gate, Persistent memory, Cross-Cutting…
- 2026-05-09: Phase 2 coherence: aligned hub-and-spoke language with team-lead.md canonical model (narrow technical clarification with @senior-engineer/@sdet…
- 2026-05-13: Added explicit "Direct-to-Issues vs Formal Docs" decision rule addressing operator pain (formal docs generated for work that should go direct).…
- 2026-05-13: Phase 2 coherence: corrected CRITICAL banner (removed incorrect `Skill() for vote/prd` ban — PM authors PRDs directly via `Skill(prd, ...)` per…
- 2026-05-16: Added Communication Discipline section enforcing closed-loop replies, receipt ack, blocker surfacing, verify-before-signoff, and saturation…
- 2026-05-16: Phase 2 coherence: add @security-engineer to "What You Are NOT" (bidirectional gap); normalize security-advisor canonical form.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).…
- 2026-05-17: Align Communication Discipline with peer-agent canonical form (numbered rules 1–5 + `TeammateIdle` canonical stall signal). Minor trims offset…
- 2026-05-17: Phase 2 coherence: Added ADR `*` broadcast incoming trigger to match staff-engineer's outgoing broadcast pattern.
- 2026-05-19: Sibling-coherence: add `ux-advisor` canonical persistent name for @ux-designer consults. Trim duplication between the "no guessing" framing and…
- 2026-05-19: Phase 2 coherence: Canonical "Visibility contract" heading alignment + cross-cutting-fallback clause + `[PM→team-lead]` escalation prefix for…
- 2026-05-19: Activated the dormant `.claude/agent-memory/project-manager/` channel via a shutdown-time memory check. Reinforces the existing memory-description examples
- 2026-05-24: Closed the 6 historical shutdown-routing errors by adding the routing rule to the Shutdown Handling section. `planner` ephemerals shut down after operator plan
- 2026-05-25: Phase 1 self-review — four targeted fixes: docs-dir guard (`ls -d` guard), memory-check trigger (first-occurrence), lifecycle compress, CLI `--parent "0"` alias.
- 2026-05-25: Phase 2 coherence — dropped dead "(P7a)" cross-reference from R7 exception clause (fleet-wide cleanup).
- 2026-05-26: Phase 1 — planner FINAL-tool-call + two-step claim ritual; two-step claim ritual in issue template enabling team-lead liveness probe. Net -1.
- 2026-05-26: Phase 2 — stripped 4 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: Epic-close rule, drain doctrine (TaskStop Monitor), docket stats drop, Risks inline, Persistent-advisors fold. Net -7.
- 2026-05-30: Brief-integrity gap — §9 verify-before-attaching + live line-ref re-confirmation; de-triplicated `edit -f` warning.
- 2026-05-30: Consolidation — §Strict Ephemeral Lifecycle/§Plan Monitoring/§Shutdown de-duped. Net -2.
- 2026-06-05: Three historical pitfalls: `depends_on` direct-gate, `-d` sets body vs `-f` attaches refs, §9 resolve-on-disk. Net +2.
- 2026-06-09: Encoded trust-no-success-line-after-`-d`-write + enumerated-list completeness guards. Net +4 (330→334).
- 2026-06-09: Extended §8 `-d`-write distrust guard with cwd-outside-repo no-op + `updated_at` reconcile discipline. Count unchanged (334).
- 2026-06-09: Fable-mandate pass — added use-when triggers for WebFetch/WebSearch + Monitor; reasoning-echo audit clean. Net +1 (334 lines).
- 2026-06-09: Phase 2 lead-initiated shutdown flip — planner lifecycle + Monitor-watch replaced with await-lead semantics. Count unchanged (334).
- 2026-06-09: Encoded \$TMPDIR scratch-file discipline into §8; corrected CLI-default drift (priority `none`, status `backlog`, §7 mandates `-s todo`). Net 0.
