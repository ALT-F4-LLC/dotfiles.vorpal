# Changelog: project-manager

## 2026-07-15

### Summary
Compacted 4 entries (2026-06-19..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
Added a Read-before-Edit pointer via R7 (PM had no such rule; also resolves a latent R7-vs-adjacency contradiction) and a stale-dispatch-check pointer (R3, B3).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): R7 now names the Read-before-Edit gate as an explicit exception that outranks it, pointing to senior-engineer.md's new master.
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on Rule 2.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Compressed the §8 verify-chain to wrapper-script pointers (docket_write.sh/docket_create.sh verified on disk), added a docket comment-add common-mistakes callout (~20-session gh-cli-habit error class), and caveated the §10 DoR gate for single-issue plans (dor_check.py verified to exit 2 with no children). Findings: 6 → 2 sub / 1 cos / 0 rej / 2 def / 1 enc

### Changes
- CULL[COSMETIC] (I7): §8 "Never trust the success line" trimmed to docket_write.sh/docket_create.sh pointers + marker-grep + timestamp-reconcile; dropped script-internal activity-log-vs-updated_at explanation.
- AMPLIFY[SUBSTANTIVE] (B5): DOCKET-CLI block gains a comment-add common-mistake callout (no `-b`/`--body`/`comment create`; `-m` never positional).
- AMPLIFY[SUBSTANTIVE] (H10): §10 DoR gate notes dor_check.py exits 2 on single-issue plans (verified via source read) — use manual checklist for Trivial/Small.

### Dimensions Evaluated
Actionability, Consolidation & Trimming. H9 routed to Coherence (team-lead spawn-template bug, shared with staff-engineer). I6 deferred (`--emit-map` flag verified absent). D1 already-encoded.

### Rename
No rename.

## 2026-07-13

### Summary
Compacted 4 entries (2026-06-09..2026-06-17) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 3 disambiguation: the architecture-consult row led with `@staff-engineer`, which is wrong on Medium+ (TDD-bearing) cycles when the `advisor` seat is held by `@distinguished-engineer` — a PM following the row's primary label would SendMessage the wrong agent.

### Changes
- AMPLIFY[SUBSTANTIVE]: consult row now leads with the seat name `advisor` (tier-split parenthetical), matching §What You Are NOT's "address the seat by name" claim and the sibling security/ux consult rows' existing format.

### Dimensions Evaluated
Disambiguation (confusable-name) — the row was internally self-contradicting against this file's own stated convention.

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form (parity with the fleet-wide compaction).

### Changes
- CULL[SUBSTANTIVE]: §Shutdown Handling's 19-line SP-1/SP-2 spell-out reduced to a 3-line master pointer + Precondition.

### Dimensions Evaluated
Cross-Agent Coherence (SHUTDOWN-PROTOCOL block byte-parity across all 7 non-team-lead agents).

### Rename
No rename.

## 2026-07-12

### Summary
Findings: 4 → 4 sub / 0 cos / 0 rej / 0 def / 0 enc. Wired the verified `dor_check.py` as a mandatory DoR pre-completion gate, retired the redundant Claim Ritual template block, consolidated vote-proposal instructions to `vote_delegate.sh` (fixes threshold-omission bug), and documented the teammate-mode frontmatter-inert caveat.

### Changes
- AMPLIFY[SUBSTANTIVE] (IS-PM1): §10 DoR now runs `dor_check.py <epic-id> [--expected-count N]` as a deterministic pre-completion gate.
- CULL[SUBSTANTIVE] (IS-PM2): dropped the §8 Claim Ritual template block — executors already bind claim-before-work.
- AMPLIFY+CULL[SUBSTANTIVE] (IS-TL4-PM): replaced hand-rolled `docket vote create` + delegation JSON with a `vote_delegate.sh` pointer — fixes silent-0.67-threshold divergence.
- AMPLIFY[SUBSTANTIVE] (DR1): documented that `skills:`/`mcpServers:` frontmatter is inert in teammate mode.

### Dimensions Evaluated
Actionability/Completeness, Consolidation & Trimming, Capability Growth, Spec Alignment. RETAIN: Role Realism, Boundary Clarity (PM≈TPM reconfirmed per SDLC research).

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
- 2026-06-09: Compacted 40 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001.
- 2026-06-10: Consolidated session-init/re-engagement Docket state reconstruction (`plan --json` + `docket stats` replacing `board --json --expand`). Net 0 (334 lines).
- 2026-06-10: Compacted 2 entries (2026-05-19..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-17: Required Fn→issue-ID mapping in completion reports; added relay-authority clause; documented docket doc subsystem. Trial: report-mapping / relay-authority / docket-doc → adopted. Drift: neutral reword of the `-l must-have` label → adopted.
- 2026-06-19: Fixed reject-class CLI error — `docket doc link add/remove` requires `--issue` flag, not a positional arg. Drift: neutral reorder of the two Session-Init state-reconstruction probes (`docket stats`/`docket plan --json`) → adopted.
- 2026-06-21: Compacted 8 entries (2026-05-25..2026-06-05) into Compacted history per ADR 0001.
- 2026-06-30: Deduped triple `edit -f` REPLACES-attachments warning; added multi-TDD parallel-decomposition surfacing to team-lead.
- 2026-06-30: Aligned Claim Ritual to chained one-call (assignee first, then status), matching senior/team-lead/sdet convention.
