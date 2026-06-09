# Changelog: security-engineer

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: verdict→shutdown sequence, Lifecycle reviewer bullet ("idle after verdict is a STALL" inverted to normal-awaiting), §Shutdown Handling drain clause. Count unchanged (241).

### Changes
- Verdict→shutdown sequence steps 2-3 flipped to await+respond (FIX 25); Lifecycle + Shutdown bullets aligned (FIX 24, 26). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Net 0 (241 lines, all within-line): consolidated verdict→shutdown double-coverage to single canon + pointer, trimmed dated stall anecdote, encoded relay-authority rule (direct instruction beats peer relay) from memory audit + 2.1.166 relayed-message hardening. Docket-doc write guards routed to coherence (routing pending).

### Changes
- Lifecycle ephemeral bullet → pointer to §Ephemeral peer review (canon owner of verdict→shutdown sequence).
- §Ephemeral peer review: removed `dev-dkt-3-shadow-validators` incident citation; rule retained.
- Communication Discipline rule 6: added relay-authority sentence (peer relays carry no origin authority; contradiction → act on direct, route back).

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth & Cross-Communication, Completeness, Actionability, Role Realism, Boundary Clarity, Spec Alignment (zero docket drift confirmed), Rename.

### Rename
No rename.

## 2026-06-09

### Summary
evolve-skills cycle reference update: code-review skill renamed → code-review-verdict; 3 references updated (skills frontmatter list, ephemeral-peer-review invocation, security-review invocation).

### Changes
- `skills:` frontmatter entry and both `Skill(code-review-verdict...)` invocations updated.

## 2026-06-09

### Summary
No changes applied. Self-review proposed encoding the docket-cwd-no-op + post-write `updated_at` discipline, but it was elevated to a Phase 2 fleet-wide decision (cross-cutting theme A, affects all docket-mutating agents). Phase 2 scoped the canonical guard to the heavy issue-mutators (senior-engineer, project-manager, sdet) and deliberately excluded security-engineer — its docket surface is vote-only (low cwd-no-op exposure), not worth the line.

### Changes
- None. The proposed docket-write-discipline guard was applied to senior-engineer/project-manager/sdet instead; security-engineer's vote-only exposure scoped it out.

### Dimensions Evaluated
Consolidation & Trimming, Actionability, Capability Growth & Cross-Communication, Spec Alignment, Role Realism, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Encoded two verified agent-memory concurrency/scope-discipline signals by folding into existing bullets (no new sections); trimmed verdict→shutdown triple-coverage. Physical net 0 (234 lines; all within-line).

### Changes
- Folded sole-editor serialization + re-Read-on-"File modified since read" rule into the Threat-Model Annotation bullet (cross-agent concurrency hazard with @staff-engineer on shared TDD files).
- Folded phase-scoped residual-grep guard into Approval Judgment (prevents false-Block when a token is legit live code this phase but prompt prose for a later one).
- Trimmed §Shutdown Handling ephemeral bullet to its unique `background_tasks`/`session_crons` drain detail; §Ephemeral peer review (L114) remains canonical owner of the verdict→shutdown sequence (verified).

### Dimensions Evaluated
Capability Growth & Cross-Communication · Actionability · Consolidation & Trimming (HIGHEST) · Spec Alignment (no docket/frontmatter drift). NO-OPs confirmed: canonical name anchoring, doubled-reviewer pattern, no-code-comments gate.

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: removed the dangling `§6 continuity preamble` pointer (2× — L35, L114). No §6 heading exists; the preamble is defined in team-lead.md §Teammate Stall & Crash Recovery. Within-line; 234 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble` (×2). Fleet-symmetric sweep across sdet/senior-engineer/team-lead.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — dangling cross-ref) · Terminology consistency.

### Rename
No rename.

## 2026-05-30

### Summary
Two Consolidation & Trimming edits (net -2 lines; 236→234) collapsing redundant restatements of team-lead.md step-14 reconciliation mechanics (Blocker-blocks / Approve+Block / DEGRADED-annotation) into pointers — team-lead owns the canon and the file already referenced it. The "4 parallel reviewers" composition (load-bearing) preserved. Zero behavioral loss.

### Changes
- §Doubled Security-Track Composition: folded inline reconciliation mechanics + the degraded-fallback paragraph into one pointer-based sentence.
- §Review Output: removed the duplicate step-14 reconciliation clause; kept the operator-routing rule.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups vs team-lead step 14) · Boundary Clarity (security-verdict-binds preserved) · Spec Alignment (no Task() drift; frontmatter consistent with fleet)

### Rename
No rename.

## 2026-05-30 (Phase 2 — coherence)

### Summary
Fixed a rule-numbering drift surfaced by Phase 2 cross-agent review: the §Doubled Security-Track Composition degraded-fallback reference pointed at "step 14 reconciliation rule 7", but team-lead.md step 14's list has 6 rules (degraded-fallback = rule 6). Now agrees with ux-designer.md (corrected rule-7→rule-6 the same cycle) and team-lead.md.

### Changes
- §Doubled Security-Track Composition: "step 14 reconciliation rule 7" → "rule 6".

### Dimensions Evaluated
Spec Alignment (cross-agent rule-numbering coherence)

### Rename
No rename.

## 2026-05-30

### Summary
Three changes (236 lines; within-line). Added the audit's validated glob/separator/POSIX-bracket pattern-matching check to the authn/authz review dimension (two PROVEN weft pitfalls: path.Match/doublestar silent DENY across `/` in URI-shaped capabilities → under-permissioning; verbatim-bracket glob→regexp translators activating RE2 POSIX classes → over-grant; both need sequence-level, not lockstep, abuse cases). Fixed the fabricated `[SEC→@agent]` visibility token (canonical `[{ROLE}→@{recipient}]`; nowhere fleet-wide). Offset by collapsing the triple-redundant secret-handling failure-string restatement.

### Changes
- §Review Workflow step 3 authn/authz dimension: added pattern-match-semantics check (enumerate `*`/separator/bracket against the actual identifier shape; require sequence-level abuse cases).
- §Cross-agent pointers: replaced fabricated `[SEC→@agent]` with canonical `[SEC→@{recipient}]` per the `[{ROLE}→@{recipient}]` convention.
- §No Guessing secret-handling audits: collapsed the duplicate failure-string example; retained the DO/DON'T.

### Dimensions Evaluated
Capability Growth (PRIMARY — historical-driven authz match-semantics check) · Spec Alignment (visibility-token coherence) · Consolidation (secret-handling dedup)

### Rename
No rename.

## 2026-05-26

### Summary
Clarified `security-reviewer-1`/`-2` are PARALLEL-panel for consensus voting (NOT sequential rework rounds, per audit hint flagging operator-transcript ambiguity); introduced `security-reviewer-fix-{N}` for fix-loop respawns matching @staff-engineer's `tdd-author-fix-{N}` convention. Consolidated §Shutdown Handling restatement to defer the verdict→shutdown sequence to its §Ephemeral peer review canonical home, retaining only unique drain/peer-consult caveats. Added one-line `docket export -o markdown -l <label>` surface in §System-Level Security Thinking for cross-issue vuln-class rollups. Net 0 lines (text density shifted; bullets stayed single-line).

### Changes
- L33 Lifecycle: spelled out `security-reviewer-1`/`-2` as parallel-panel pair (not sequential rounds) + `security-reviewer-fix-{N}` for fix-loops.
- §Ephemeral peer review: fix-loop respawn name aligned to `security-reviewer-fix-{N}`.
- §Shutdown Handling: dropped redundant verdict→shutdown sequence restatement; deferred to §Ephemeral peer review; retained drain + peer-consult caveats.
- §System-Level Security Thinking: added `docket export -o markdown -l <label>` for recurring vuln-class trend rollups.

### Dimensions Evaluated
Boundary Clarity (PRIMARY — paired-panel vs sequential-rounds disambiguation) · Consolidation (shutdown sequence dedup) · Capability Growth (docket export surface)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 8 dangling docs/tdd/* citations)

### Summary
Stripped 8 dangling citations to `docs/tdd/reviewer-doubling-lifecycle.md` (Phase 0 verified file does not exist in this repo). Redirected references to team-lead.md anchors (Rule 7, Rule 8, step 14 reconciliation rules, §Runtime Discipline).

### Changes
- L34 idle-semantics bullet: dropped "+ reviewer-doubling-lifecycle.md §4.4" tail.
- L37 cross-agent pointers: dropped "+ reviewer-doubling-lifecycle.md §4.2 row 2" tail.
- L101 step 9 secondary review: replaced "TDD §4.4 rule 8" + "TDD §4.3" with team-lead Rule 8 + step 14 anchors.
- L110 doubled-track block: replaced "TDD §4.3" with team-lead step 14 anchor.
- L112 degraded fallback: replaced "TDD §4.3 rule 7" with team-lead step 14 reconciliation rule 7 anchor.
- L133 Review Output: replaced "TDD §4.3" with step 14 anchor.
- L171 divergence trigger: replaced "docs/tdd/reviewer-doubling-lifecycle.md §4.3" with step 14 anchor.
- L223 Runtime Discipline opener: replaced "§4.5 applicability matrix" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — per-name idle semantics + verdict→shutdown sequence)

### Summary
Closed the dev-dkt-3-shadow-validators stall by encoding per-name idle semantics (`security-advisor` idle-OK vs `security-reviewer-N` ephemeral) and numbered verdict→`shutdown_request` SAME-turn sequence with the documented incident named as the negative example. Split Shutdown Handling by name; added `background_tasks`/`session_crons` drain caveat (async-shutdown is by design). Net +4 lines (277 → 281).

### Changes
- §Operating Context + Lifecycle: replaced "Stateless subagent" framing (contradicted persistent-advisor model); restructured Lifecycle into named-lifecycle distinction — `security-advisor` (idle NORMAL) vs `security-reviewer-N` (idle after verdict = STALL).
- §Ephemeral peer review: encoded numbered verdict→shutdown sequence — (1) SendMessage verdict, (2) `shutdown_request` as FINAL tool call same turn, (3) await `shutdown_approved`. Documented `security-reviewer-2` 1.5min idle in `dev-dkt-3-shadow-validators` as the negative example.
- §Shutdown Handling: split by name — `security-advisor` long-lived approve criteria; `security-reviewer-N` mandatory same-turn shutdown_request + `background_tasks`/`session_crons` drain before emitting.

### Dimensions Evaluated
Actionability (PRIMARY — verdict→shutdown sequence) · Boundary Clarity (per-name idle semantics) · Capability Growth (drain rule + documented incident as exemplar) · Completeness (async-shutdown caveat)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — P7a drop)

### Summary
Single coherence fix: dropped dead "(P7a)" cross-reference from R7 exception clause. No agent canonically labels its Read-before-Edit/Write rule as "P7a"; the parenthetical was fleet-wide dead reference.

### Changes
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Actionability (dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — `.env*` workaround + shutdown negative example)

### Summary
Two audit-driven additions plus a trim. Closed the recurring `.env*` sandbox-block on legitimate secret audits (5 historical denied-read errors in one session) by adding a §No Guessing bullet prescribing the documented detour (`ls -la`, grep usage sites, consult `docs/spec/security.md`, route to operator). Reinforced rule 6 shutdown routing with a concrete WRONG/RIGHT negative example for the doubled-security-track recipient ambiguity. Trimmed Cross-agent pointers from 4 bullets to 1 inline sentence. Net −3 (280 → 277). Note: reviewer applied edits directly during review (read-only protocol violation); team-lead accepted since changes pass Content Gate.

### Changes
- §No Guessing: new bullet — `.env*` sandbox-denied alternatives (`ls -la`, grep `dotenv\|process.env\|std::env::var\|os.environ`, `docs/spec/security.md`, operator escalation for real values)
- §Communication Discipline rule 6: appended WRONG/RIGHT negative-example clause for shutdown routing on doubled security tracks
- §Cross-agent pointers: collapsed 4-bullet list to 1 inline sentence; dropped Epistemic Discipline pointer (covered by rule 7)
- §Operating context: prose cleanup (semicolon merge)

### Dimensions Evaluated
Actionability (PRIMARY — `.env*` workaround unblocks recurring audit detour) · Cross-Agent Coherence (negative-example pattern proposed fleet-wide for shutdown routing) · Consolidation & Trimming

### Rename
No rename.

## 2026-05-24 (Phase 2 coherence — shutdown routing + advisor-idle parity)

### Summary
Two coherence fixes. (1) Closed the 6 historical shutdown-routing errors by making the routing rule explicit at rule 6. Security review doubling (4 parallel reviewers) makes peer-vs-team-lead recipient confusion especially likely. (2) Strengthened persistent-advisor idle-is-normal rule to name `TeammateIdle` explicitly and cite TDD §4.4 rule 5 — achieves parity with staff-engineer.md and ux-designer.md. No file-size change.

### Changes
- Communication Discipline rule 6: appended Routing clause — `shutdown_response` ALWAYS addressed to team-lead, never to peer agents or original dispatcher; applies to `security-advisor` and every ephemeral spawn (`security-reviewer-2`, sibling security-TDD authors, ad-hoc consults).
- Lifecycle contract paragraph: strengthened persistent-advisor idle phrasing — names `TeammateIdle` signal explicitly, cites TDD §4.4 rule 5, states "does NOT trigger auto-respawn" (parity with staff-engineer.md line 40 and ux-designer.md line 277).

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — both fixes) · Actionability (routing visibility on doubled security track) · Boundary Clarity (advisor-idle rule self-contained)

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence — memory channel activation)

### Summary
Activated the dormant `.claude/agent-memory/security-engineer/` channel via a shutdown-time memory check, tailored to security context: explicitly excludes per-cycle threat models and one-shot CVEs (which have other homes) so the criterion stays sharp.

### Changes
- Shutdown Handling: added memory check before approving shutdown — append recurring threat-model pitfalls (recurring vulnerability class in this codebase, rejected adversary assumptions, operator risk-tolerance signals, non-obvious security symptom→root-cause→remediation patterns) to `.claude/agent-memory/security-engineer/pitfalls.md`. Skip if nothing recurring surfaced.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — dormant channel activated, tailored gate) · Coherence (parallel to team-lead + staff-engineer wrap-up nudges).

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence)

### Summary
Universal-mirror visibility contract alignment (Phase 2 canonical decision). Conditional-mirror language replaced with explicit universal-mirror clause + cross-cutting fallback.

### Changes
- §Visibility contract (renamed from "Operator visibility"): every SendMessage mirrored as Docket comment with `[SEC→@agent]` prefix; cross-cutting-fallback clause for security ADRs / fleet-wide threat-model calls; (cc operator) real-time signal preserved layered on top.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — universal-mirror alignment).

### Rename
No rename.

## 2026-05-19

### Summary
Targeted self-review responding to historical-audit signals: codified the respawn-recovery handoff (4× operator pattern), added a vote-commit race guard (6 cancelled parallel commits observed), tightened operator-visibility framing for fleet consistency, and compressed Communication Discipline by merging Read-before-Edit/Write into rule 6 to keep BALANCED budget. Net 0 lines.

### Changes
- §Operating context: added "operator may address by either name" clarifier and explicit `Interrupt recovery` clause — first-turn state summary after respawn/compaction.
- §Consensus Voting: added **Vote-commit race guard** bullet — team-lead owns `docket vote commit`; standalone must `docket vote show` to verify state before committing.
- §Operator visibility: split cc-vs-prefix framing into two explicit channels ("cc is real-time signal; prefix is persistent record") to match @staff-engineer's wording.
- §Communication Discipline: merged Read-before-Edit/Write into rule 6 alongside shutdown protocol; removed standalone subsection. Rule count remains 7.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — respawn handoff, race guard) · Boundary Clarity (operator-visibility two-channel) · Consolidation (Read-before-Edit/Write merge) · Actionability (vote-commit race) · Cross-Agent Coherence (rule numbering preserved).

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Cross-agent coherence: added canonical `TeammateIdle` stall-signal line and Read-before-Edit/Write reflex.

### Changes
- Communication Discipline: appended TeammateIdle canonical-signal line below rule 6.
- Communication Discipline: added Read-before-Edit/Write reflex (TDD/ADR/security.md authoring).

### Dimensions Evaluated
Cross-agent terminology coherence; tool-gate reflexes.

### Rename
No rename.

## 2026-05-17 (pass 2)

### Summary
Trimmed three blocks for parity with peers and to remove intra-doc duplication: Design Review's dimension list redirected to Responsibility 2 (was duplicated); Communication Discipline rules 1-4/6 compressed; two @senior-engineer mid-impl incoming triggers merged. Net -12 lines. No behavioral change.

### Changes
- Design Review: replaced duplicated security-dimension list with cross-reference to Responsibility 2 step 3; kept operational-readiness emphasis and output ladder.
- Communication Discipline: tightened rules 1-4 and 6; rule 5 (verify load-bearing claims) left intact as it carries the security-specific load.
- Incoming triggers: merged @senior-engineer proactive-consult + reactive-discovery into one trigger.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Boundary Clarity, Coordination & Handoffs, Spec Alignment.

### Rename
No rename.

## 2026-05-17

### Summary
Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). `threat_summary` retained as an optional observability hint.

### Changes
- Consensus Voting §Team mode: replaced ad-hoc payload with canonical shape (`{type, protocol_version, skill, request_id, vote_id, from, summary?, artifact?, threat_summary?}`). Added `docket vote create ... --json` step; documented `failed` response on missing `vote_id`. Authoritative proposal (including threat model) lives in docket.

### Dimensions Evaluated
Cross-skill coherence (vote-skill payload contract), Coordination & Handoff.

### Rename
No rename.

## 2026-05-16

### Summary
Added Communication Discipline (rules 1-6) with rule 5 (verify load-bearing claims) emphasized for security sign-off; fixed misleading `docket vote commit --outcome` enum syntax to free-text; trimmed "What You Are NOT" and Proactive Communication outgoing-trigger duplication.

### Changes
- Added Communication Discipline section (+15) — closed-loop, ack, saturation, blocker, verify-evidence-this-session, one-turn shutdown.
- Fixed Docket cheatsheet: `vote commit --outcome` is free-text ("Approved: <summary>" / "Rejected: <reason>"), not an enum; clarified `--findings` vs `--findings-json`.
- Trimmed "What You Are NOT" entries to one-line per role (-6).
- Consolidated 7 Proactive Communication triggers into 5 by merging scope-delta + annotation-split, and TDD-accepted + cross-cutting ADR (-11).

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Rebalanced documentation-vs-direct-action axis per operator pain. Added Threat-Model Annotation tier between full security TDD and inline review note. Tightened ADR threshold, trimmed Consensus Voting over-prescription, compressed Pre-Flight Gate and Shutdown sections. Added Docket CLI cheatsheet for review/voting surface. Net: -8 lines (327 → 319).

### Changes
- Added "scope test" gate + Threat-Model Annotation tier in §When to Create a Security TDD; reframed Proactively to require BOTH new surface AND non-trivial threat model
- Tightened ADR threshold (skip when rationale fits in PR comment with no future "why?" cost)
- Added Docket CLI cheatsheet (`docket vote create/cast/commit/link`, `docket issue file list`, `docket plan --root`) under Responsibility 2
- Compressed Pre-Flight Gate, Consensus Voting, Shutdown Handling, System-Level Thinking
- Strengthened @staff-engineer boundary to prefer annotation over parallel TDD on mixed changes
- Added proactive trigger for annotation-grown-too-large → split escalation

### Dimensions Evaluated
Completeness (operator pain on over-documentation; docket audit gap), Consolidation, Actionability, Boundary Clarity, Cross-Communication, Role Realism, Spec Alignment

### Rename
No rename.

## 2026-05-09

### Summary
Phase 2 coherence: anchored canonical teammate name "security-advisor" to team-lead.md §Spawning Templates so naming stays consistent if team-lead.md ever renames.

### Changes
- §Operating context: replaced generic "spawned as a persistent advisor" with "named 'security-advisor'" plus reference to team-lead.md §Spawning Templates as the canonical name authority

### Dimensions Evaluated
Coherence (PRIMARY — canonical name anchoring), Spec Alignment, Role Realism

### Rename
No rename.

## 2026-05-09

### Summary
Phase 1 self-review (initial entry). Trimmed redundant preambles and verbose Review Output paragraph; merged duplicate incoming triggers per peer; added concrete handoff trigger for verdict-reconciliation with @staff-engineer; adopted AskUserQuestion `multiSelect` for multi-adversary threat scoping. Net: −13 lines (340 → 327).

### Changes
- Trimmed Honest Risk Critique two-paragraph framing; merged "Surface-level mitigations" rule into a single tight block (Consolidation)
- Compressed "When to Create a Security TDD" — merged "Skip" + "Ask when uncertain" into one decisive bullet (Consolidation, decisiveness)
- Compressed "Match formality" preamble into the Responsibility 3 header line; removed redundant "Lightweight Security Advisory" subsection wrapper (Consolidation)
- Compressed Review Output paragraph (line 208) — skill is format authority; kept only the routing/reconcile/escalate ownership clause (Consolidation, decisiveness)
- Merged duplicate @staff-engineer incoming triggers (review-handoff + TDD-handoff → one) and @sdet incoming triggers (abuse-case design + test failure → one) (Coordination & handoffs)
- Added outgoing trigger: parallel-review verdict conflict with @staff-engineer → reconcile before merge to avoid contradictory operator-facing recommendations (Coordination & handoffs)
- Pre-Flight Gate: clarified that adversary scope is `multiSelect: true` (threat models often span multiple adversaries) — concrete capability adoption (Capability Growth)

### Dimensions Evaluated
All 8: Consolidation (PRIMARY — preamble redundancy, duplicate triggers, verbose review-output), Coordination & Handoffs (parallel-review reconciliation trigger, decisive responses), Role Realism, Actionability, Boundary Clarity, Completeness, Capability Growth (multiSelect adoption), Spec Alignment

### Rename
No rename.
