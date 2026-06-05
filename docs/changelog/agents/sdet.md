# Changelog: sdet

## 2026-06-05

### Summary
Two Consolidation & Trimming dedups (net 0 lines; 341 lines). Execution Workflow step 2 collapsed to a comm rule 7 back-reference (claim convention was near-verbatim duplicated). §Shutdown Proactive's idle-role enumeration collapsed to a comm rule 6 / Lifecycle back-reference, keeping only the unique precondition. Both historical focus areas resolved: literal-command-AC already encoded in verify-ac skill (NO-OP); destroy-recreate-NEW-backend is a runtime concern outside sdet's static-verification charter (routed to a tracking issue, not dropped).

### Changes
- §Execution Workflow step 2: fold spawn-type claim convention into a comm rule 7 back-reference (target verified present at L50).
- §Shutdown Handling Proactive: collapse duplicated advisor/idle-role enumeration to a comm rule 6 / Lifecycle back-reference (targets L38/L304 verified present); retain unique precondition.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups) · Boundary Clarity (single canonical home for idle-role doctrine) · Spec Alignment (team-lead anchors + docket commands verified extant).

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: removed the dangling `§6 continuity preamble` pointer (1× — L38). No §6 heading exists; the preamble is defined in team-lead.md §Teammate Stall & Crash Recovery. Within-line; 341 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble`. Fleet-symmetric sweep across senior-engineer/security-engineer/team-lead.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — dangling cross-ref) · Terminology consistency.

### Rename
No rename.

## 2026-05-30

### Summary
Two Consolidation & Trimming edits (net -3 lines; 344→341) deduping content the verify-ac SKILL already owns. §Verification Workflow step 5's edge-case battery (verbatim verify-ac SKILL.md) folded into a `Skill(verify-ac)` back-reference with the BLOCK/ACCEPT decide-clause merged in (old step 6 absorbed; 6-step list → 5). §Verification Output's "Closeout sequence" triplicated §Execution Workflow step 5 + the recipient matrix + comm rule 6 — collapsed to single back-references. Rejected deleting §Verification Depth (verify-ac names sdet.md as the depth-judgment authority). No behavioral loss.

### Changes
- §Verification Workflow: fold step 5 edge-case list into a verify-ac back-reference; merge old step 6 (decide ladder) into it.
- §Verification Output: collapse the closeout-sequence enumeration to back-references (§Execution Workflow step 5 / §Inter-Agent Communication matrix / comm rule 6).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups vs verify-ac skill) · Boundary Clarity (closeout now points to single-actor §Execution Workflow step 5) · Completeness (no Task() drift; frontmatter memory/effort/color already wired)

### Rename
No rename.

## 2026-05-30

### Summary
Two edits from the evolve-agents self-review (net ~0; 344 lines). (1) Deduped the §Test Failure Diagnosis snapshot sentence — verbatim-redundant with §Testing Philosophy's "never blind-update; trace each diff..."; folded to a back-reference + the non-redundant table-driven pointer. (2) Scoped "move" in the §CRITICAL: Verify Issues header to read-only/BLOCK-reopen-only, closing the historical-audit verifier-ephemeral claim-drift gap at the section opener (Rule 7 / step 2 already encode it; the header undercut them).

### Changes
- §Test Failure Diagnosis Snapshots para: collapse redundant blind-update clause to a §Testing Philosophy back-reference.
- §CRITICAL: Verify Issues header: scope "move" to READ-ONLY + BLOCK-reopen; cross-reference comm rule 7.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — snapshot dedup) · Boundary Clarity (claim-drift gap at section header, historical-audit focus) · Spec Alignment (verify-ac rename consistent, no Task( drift; hook events TeammateIdle/background_tasks/session_crons correct)

### Rename
No rename.

## 2026-05-26 (Phase 2 coherence)

### Summary
Two coherence fixes from Phase 2 cross-agent review. (1) §Execution Workflow step 5 contradicted senior-engineer.md step 6 — both closed the issue, making sdet's `docket issue close` a no-op. Rewritten as "issue already closed by senior; APPROVE = comment-only; ACCEPT WITH CAVEATS = comment + route follow-up; BLOCK = reopen+comment (step 6)". (2) §Shutdown Handling auto-shutdown block now matches project-manager.md's inline `TaskStop the Monitor watch (drain doctrine — outstanding watches at shutdown leak resources)` between final-report and `shutdown_request` per drain-doctrine symmetry.

### Changes
- §Execution Workflow step 5: rewrite to acknowledge prior @senior-engineer close; branch by verdict (APPROVE/ACCEPT-WITH-CAVEATS/BLOCK) without re-closing.
- §Shutdown Handling §Auto-shutdown on idle bullet: add inline TaskStop the Monitor watch per PM symmetry.

### Dimensions Evaluated
Boundary Clarity (PRIMARY — close-flow ownership now single-actor) · Spec Alignment (drain doctrine fleet-symmetric)

### Rename
No rename.

## 2026-05-26

### Summary
Two systemic alignments net +2 lines (337 → 339). (1) §Verifier Composition contradicted team-lead.md — said "no single variant" while team-lead.md DEFAULTS to single `verifier` and opts up to paired only on ≥3 issues / ≥5 files / security-sensitive. Rewritten to match, with canonical-name guard against the 20+ observed drift variants (`verifier-DKT-16`, `verifier-full`, etc.). (2) Claim-via-`docket issue move` drift (team-lead pitfalls.md in cross-project memory flagged sdet ephemerals generalizing senior-engineer's claim-first rule to verification, regressing issue state). Comm rule 7 + Execution Workflow step 2 + rule 2 reference now distinguish: verification = ack-only (no `docket issue move`); test-infra writing = claim+ack per @senior-engineer convention.

### Changes
- §Verifier Composition: rewrite to default-single + opt-up-paired (team-lead Rule 8); codify three canonical spawn names; refuse issue-scoped drift variants.
- §Lifecycle (L38): spawn-name list reframed; fix-loop wording matches default-single.
- §Comm Discipline rule 7 (L50): split verification (ack-only, no move) from test-infra (claim+ack).
- §Execution Workflow step 2 (L237): mirror rule 7 split.
- §Comm Discipline rule 2 (L45): updated cross-reference to rule 7's spawn-type branches.

### Dimensions Evaluated
Spec Alignment (PRIMARY — verifier-composition realignment with team-lead Rule 8) · Boundary Clarity (PRIMARY — claim-via-move drift fix) · Capability Growth (canonical-name guard against drift variants)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 4 dangling docs/tdd/* citations)

### Summary
Stripped 4 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.

### Changes
- L34 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L162 Verifier Composition: dropped "+ reviewer-doubling-lifecycle.md §4.2 row 3" tail.
- L167 reconciliation note: replaced "TDD §4.3" with team-lead.md step 14 anchor.
- L319 Runtime Discipline opener: replaced "§4.5 applicability matrix" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — shutdown coordination: proactive emit + drain)

### Summary
Five edits encoding proactive ephemeral self-shutdown (verdict-then-`shutdown_request` as FINAL TOOL CALL same turn) per operator directive. Lifecycle, Comm Rule 6, Verifier Composition, Verification Output, and Shutdown Handling all clarified. Background-task drain rule added. Sister-verifier coordination clarified as peer-only (not joint persistence). Net +4 lines (367 → 371).

### Changes
- §Lifecycle: enumerated three ephemeral spawn names; explicit "not one of the three sanctioned idle advisors"; sequence ends with `shutdown_request` as FINAL TOOL CALL the same turn.
- §Comm Rule 6: split into proactive-emit (default for sdet, post-verdict) vs reactive-reply; routing rule strengthened.
- §Verifier Composition: sister coordination is peer messaging only — each verifier shuts down independently.
- §Verification Output: explicit 3-step closeout sequence ending in `shutdown_request`.
- §Shutdown Handling: proactive subsection added; `background_tasks`/`session_crons` drain rule added; "only the three advisors stay idle" framing.

### Dimensions Evaluated
Actionability (PRIMARY — verdict-then-shutdown as final tool call) · Boundary Clarity (sister-verifier peer-only) · Capability Growth (proactive emission + drain rule) · Completeness (background-task drain)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — shutdown WRONG/RIGHT, docs-dir guard, P7a drop)

### Summary
Three coherence fixes from Phase 2 audit: (1) added concrete WRONG/RIGHT shutdown-routing example to Comm Discipline rule 6 for fleet parity with security/staff/senior-engineer; (2) added docs-dir existence guard (`ls -d docs/tdd docs/ux docs/spec`) to "Check Specs Before Testing" matching project-manager/staff-engineer convention; (3) dropped dead "(P7a)" cross-reference from R7 (no agent canonically labels its Read rule as P7a).

### Changes
- Comm Discipline rule 6: appended concrete WRONG/RIGHT example (`to="verifier-criteria"`/`"verifier-integration"` WRONG; `to="team-lead"` RIGHT)
- §Check Specs Before Testing: added `ls -d docs/tdd docs/ux docs/spec 2>/dev/null` guard as lead-in
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — fleet parity on shutdown example + docs-dir guard) · Actionability (P7a dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — sandbox awareness + jq robustness + auth consent + CLI alignment)

### Summary
Three behavioral gaps from 10+ sandbox-blocked errors and 2 operator over-reach interruptions in historical audit: sandbox off-limits documentation, jq robustness discipline, and auth-boundary operator-consent qualifier. Two spec-alignment fixes (docket vote list wording, export --format alias). Four line-wrap compressions for balance. Verified `docket issue move <id> review` IS a valid docket status (tested live) — no doc change needed. NET +1 line (368 → 369).

### Changes
- §Test Failure Diagnosis: added `Sandbox off-limits` paragraph — `.env*` and Docker socket are sandbox-blocked (policy, not missing files); surface as environment blocker, never work around
- §Runtime Discipline R1: added `jq robustness` bullet — test expressions in isolation before pipeline embedding
- §Verification Workflow step 4: added operator-consent qualifier for auth-boundary side-effects (credential refresh, token write) — only in-scope when AC explicitly requires credential-state verification
- §Docket CLI Reference: `vote list --all` wording aligned to CLI ("resolved proposals"); `export` documents `--format` as long form of `-o`
- Consolidation: Test Pyramid, Risk-Based high/low risk bullets, Defect Analysis — 4 line-wrap compressions (−4 lines)

### Dimensions Evaluated
Actionability (PRIMARY — sandbox + jq) · Boundary Clarity (PRIMARY — auth over-reach) · Spec Alignment (vote/export) · Consolidation

### Rename
No rename — "sdet" is canonical.

## 2026-05-24 (Phase 2 coherence — shutdown_response routing rule)

### Summary
Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead" routing errors by making the routing rule explicit at rule 6 (shutdown within one turn). Verifier ephemerals communicate with multiple peers mid-task; the routing rule must be at rule-6 visibility. No file-size change.

### Changes
- Communication Discipline rule 6: appended Routing clause — `shutdown_response` ALWAYS addressed to team-lead, never to peer agents or original dispatcher, even when the request arrives in a thread previously routed to a peer (e.g., @senior-engineer source-clarification consult, @security-engineer abuse-case reply).

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY) · Actionability (rule visibility for verifier-criteria / verifier-integration ephemerals)

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence)

### Summary
Universal-mirror visibility contract alignment (replaces narrower "BLOCK / coverage-gap / vote / approach-changing" trigger). Added `ux-advisor` canonical-name symmetry for fleet discoverability.

### Changes
- §Inter-Agent Communication: replaced conditional trigger list with universal-mirror `Visibility contract` clause + cross-cutting-fallback for defect rollups / fleet-wide test-infra concerns.
- §What You Are NOT (@ux-designer): added `(canonical persistent name: ux-advisor)` for symmetry with existing `security-advisor` reference.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — universal-mirror alignment, canonical-name symmetry).

### Rename
No rename.

## 2026-05-19

### Summary
Closes audit gaps: verification-evidence specificity (real-vs-mocked at trust boundaries), `index.lock` recovery (fleet-wide #1 error, sdet=8), `docket export` under-use. Consolidates two duplicated Incoming Consults entries into merged staff/security testability triggers. NET +0.

### Changes
- Verification Workflow §4: real-system evidence requirement at external trust boundaries.
- Test Failure Diagnosis: appended `Git lock recovery` paragraph pointing at sandbox-disabled retry.
- Incoming Consults: merged @staff-engineer test-infra/TDD entries and @security-engineer abuse-case/test-infra entries (4 → 2 lines).
- Bug Reporting: added `docket export -o markdown` trigger for cross-issue defect rollups.

### Dimensions Evaluated
Actionability (PRIMARY — verification-evidence + git-lock) · Consolidation & Trimming (PRIMARY — consults dedup) · Capability Growth (docket export) · Boundary Clarity · Spec Alignment.

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Added Read-before-Edit/Write reflex as Rule 9, matching Phase 1 propagation across Edit/Write-capable agents.

### Changes
- Communication Discipline: added Rule 9 (Read before Edit/Write).
- TeammateIdle reference updated to include rule 9.

### Dimensions Evaluated
Tool-gate reflexes; cross-agent coherence.

### Rename
No rename.

## 2026-05-17

### Summary
Addresses highest-severity audit signal (3 operator history corrections + 17 TeammateIdle hits) by closing the dispatch-to-first-SendMessage gap. Rules 2 and 8 reframed around what team-lead can observe (SendMessage activity), and Execution Workflow §2 explicitly pairs docket-claim with team-lead ack in the same turn.

### Changes
- Rule 2: extended "acknowledge within one turn" to explicitly include the team-lead dispatch message; example wording for dispatch vs. mid-stream ack; explicit pairing with Rule 7 claim-first ordering.
- Rule 8: reframed "every ~10 min" as "measured by SendMessage to team-lead" since absence-of-message is the actual stall signal — long Bash/Monitor calls are invisible.
- Execution Workflow §2: claim-FIRST now requires same-turn SendMessage team-lead ack, cross-referenced to comm rule 2.

### Dimensions Evaluated
Actionability (PRIMARY — operator-visibility gap), Capability Growth & Cross-Communication (dispatch-ack handoff), Boundary Clarity (workflow ordering), Consolidation.

### Rename
No rename.

## 2026-05-17

### Summary
Two Phase 2 handoffs from the 2026-05-17 evolve-skills cycle: (1) Vote delegation payload synced to canonical `skills/vote/` shape; (2) Execution Workflow §4 now makes `Skill(verify, "<scope>")` the canonical "produce verdict" step, addressing the 125-code-reviews vs 0-verifies invocation gap observed in the 30-day historical audit.

### Changes
- Using /vote for Consensus §Team mode: replaced free-form `{type, skill, question}` payload with canonical shape (`{type, protocol_version, skill, request_id, vote_id, from, summary?}`). Added `docket vote create ... --json` prerequisite; documented `failed` response on missing `vote_id`.
- Execution Workflow §4: explicit instruction to invoke `Skill(verify, "<scope>")` as the canonical verdict-emission step (cross-referenced to §Verification Output). Closes the workflow gap where verify was back-loaded and skipped in practice.

### Dimensions Evaluated
Cross-skill coherence (vote payload + verify routing), Workflow Completeness, Output Quality.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: align Communication Discipline rule numbering with brief's canonical map (rule 7 = claim-first, rule 8 = 10-min progress).

### Changes
- Inserted new Rule 7 ("Claim before work") matching senior-engineer.md Rule 7; renumbered prior progress-signal rule 7 → rule 8.
- Updated `TeammateIdle` stall-signal pointer from "rule 1, 2, or 7" to "rule 1, 2, 7, or 8".

### Dimensions Evaluated
Cross-agent rule-number coherence, claim-first ordering parity.

### Rename
None.

## 2026-05-16

### Summary
Encoded 8 operator communication-discipline rules (closed-loop reply, ack, saturation, blocker, verify, shutdown, claim-first, 10-min progress) and elevated `docket issue move <id> in-progress` to step 1 of Execution Workflow.

### Changes
- Added Communication Discipline section (rules 1-6, 8) + TeammateIdle hook reference.
- Reordered Execution Workflow: Find → Claim FIRST → Review → Do work.
- Shutdown Handling cross-references comm rule 6 timing.
- Inter-Agent header notes SendMessage auto-resume.
- Trimmed: merged quality+stop-ask blocks, banner one-liner, Pre-Flight escalation dedup, snapshot prose, "Snapshot review protocol" compressed.

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename — "sdet" is canonical industry abbreviation.

## 2026-05-13

### Summary
Phase 2 coherence: added @security-engineer to "What You Are NOT" with security-advisor persistent-name alias; annotated `docket issue close` with no-`-m` clarification.

### Changes
- "What You Are NOT": added @security-engineer entry referencing canonical persistent name `security-advisor` (closes symmetry gap — body content already references security-engineer triggers)
- Close-out step: annotated `docket issue close <id>` with `(no -m flag)` and separated comment-add into a distinct command

### Dimensions Evaluated
Coherence (bidirectional with security-engineer.md), Boundary Clarity, Actionability (close-flag annotation)

### Rename
No rename.

## 2026-05-13

### Summary
Added LIGHT vs FULL verification depth thresholds — trivial fixes get one-line APPROVE; non-trivial work still uses the structured template. Plus consolidation trims. Net: -5 lines (279 → 274).

### Changes
- Added LIGHT vs FULL verification depth thresholds — operator pain point: templated reports generated for trivial work that needed only `tests pass: <cmd>` confirmation
- Merged Quality stance + No-guessing into one block (same anti-pattern)
- Compressed Inter-Agent table from 13 rows to 9 (merged BLOCK + coverage-gap; ambiguous-criteria + TDD-not-accepted; supply-chain CVE absorbed into security-test row; dropped over-triggered `*` broadcast and duplicate "unrelated work" row)
- Trimmed Greenfield Test Strategy from 6 to 4 steps
- Removed duplicate vote-logging sentence
- Dissolved orphan Testing Philosophy section; moved snapshot review protocol into Test Failure Diagnosis

### Dimensions Evaluated
Completeness (LIGHT vs FULL — operator feedback), Consolidation, Role Realism, Actionability, Boundary Clarity, Cross-Communication

### Rename
No rename.

## 2026-05-09

### Summary
Phase 1 trim + bidirectional coherence — compressed Quality stance, No-guessing, Stop-and-ask, Pre-Flight, Inter-Agent, /vote, Shutdown, and Greenfield blocks per "no over-thinking" feedback; closed @security-engineer coordination gap (zero prior references despite team integration). Net: −24 lines (303 → 279).

### Changes
- Compressed Quality stance, No-guessing, Stop-and-ask, Pre-Flight Goal-Alignment Gate, Inter-Agent preamble, /vote intro, Shutdown, and Greenfield step 6 (boilerplate / restated rules)
- Dropped Per-Session Metrics section — already covered by No-guessing block
- Trimmed Verification Output Template's meta-instruction preamble
- Added @security-engineer to outgoing triggers: security/data-integrity test fails, abuse-case design needed, supply-chain/CVE in fixtures
- Added @security-engineer incoming consults: abuse-case/fuzzing-target consult during security TDD authorship, test-infra alignment check before security review

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Capability Growth & Cross-Communication (PRIMARY — @security-engineer integration), Coherence (bidirectional triggers), Output Quality, Role Realism, Actionability, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: codified two behavioral rules surfaced by operator — no retry loops on failing test commands (ask for help; session may need restart), and remember solutions to non-obvious test/CI/fixture failures.

### Changes
- Added "Stop and ask, do not retry" rule: one diagnostic pass on failing test/fixture/CI commands, then SendMessage operator/team-lead with failure output — no retry loops (spams approval prompts), no install workarounds, no silent skip; surface harness tool-config gaps
- Strengthened Persistent memory: now also captures solutions to non-obvious test/CI/fixture failures (symptom + root cause + fix) so future sessions don't re-diagnose

### Dimensions Evaluated
Role Realism (PRIMARY — codifies operator-observed misbehaviors), Capability Growth (memory captures problem-solution pairs), Completeness

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner; aligned testability-trigger vocabulary with ux-designer.

### Changes
- CRITICAL banner now covers both commit ban AND `/vote`/Skill/Agent/TeamCreate ban
- Renamed shorthand "error/edge/concurrency" to "error states, edge cases, and concurrency" to match the bidirectional outgoing trigger in ux-designer.md

### Dimensions Evaluated
Coherence (PRIMARY — banner uniformity, bidirectional trigger phrasing), Behavioral (no rule changes)

### Rename
No rename.

## 2026-05-08

### Summary
Coherence & trimming pass — merged operating-context + agent-memory paragraphs into senior-engineer-style single block, removed three duplicate "no guessing/no issue creation" restatements, compressed Greenfield step 6 and Verification template preamble. Phase 0 capabilities (Monitor, agent-memory, `[SDET→@agent]` visibility, `docket plan --root`, `move review`) already adopted. Net: -6 lines (307→301).

### Changes
- Merged Operating context + cross-session memory list into one paragraph; added "verify means run the suite" framing matching senior-engineer
- Removed "is theater" rhetorical flourish + "Do not guess at intent" tail in Check Specs (duplicates No-guessing block at top)
- Trimmed Verification Output Template ad-hoc preamble (duplicates Bug Reporting + NOT @project-manager)
- Compressed Greenfield step 6 (removed "flag testing.md if missing" — implicit from step 1)
- Compressed Verify Issues preamble (boundary already in NOT section)

### Dimensions Evaluated
All 8: Consolidation & Trimming (PRIMARY), Coherence (3 duplicate-rule sites), Role Realism, Actionability, Boundary Clarity, Completeness, Capability Growth (no additions — already current), Spec Alignment, Rename

### Rename
No rename.

## 2026-05-07

### Summary
Capability adoption pass — documented persistent agent-memory dir for SDET-specific recurring-signal tracking (flaky patterns, fixture quirks, defect-class repeats), adopted `docket issue move <id> review` for partial-handoff state. Trimmed NOT-staff-engineer reciprocal-review claim (already in inter-agent table). Net: 0 lines (307→307; +2 from agent-memory offset by -2 from step 5 consolidation).

### Changes
- Operating context: added `.claude/agent-memory/sdet/` adoption with explicit do/don't list (recurring flaky patterns, fixture quirks, defect-class repeats — NOT per-issue details)
- Execution Workflow step 5: added `docket issue move <id> review` for partial-handoff state (ACCEPT WITH CAVEATS / BLOCK awaiting rework); `close` remains for clean APPROVE
- What You Are NOT (@staff-engineer): trimmed reciprocal-review claim duplicating inter-agent table at line 246
- REJECTED: Trim of "record ambiguity-resolution decisions" paragraph — kept; documents persisting resolutions to Docket which is unique guidance not duplicated by Pre-Flight gate

### Dimensions Evaluated
Capability Growth (PRIMARY — agent-memory + `move review`), Consolidation & Trimming, Boundary Clarity, Coherence, Actionability

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: aligned standalone-mode AskUserQuestion shape language with peer agents.

### Changes
- Pre-Flight Goal-Alignment Gate (Standalone mode): added "presenting ambiguities as structured, selectable options" so SDET matches the structured-options language used by staff/senior/ux/PM. Team-lead's more specific "2-3 candidate framings + free-text fallback" remains unique to the orchestrator.

### Dimensions Evaluated
Cross-agent Pre-Flight Gate language consistency, operator-experience uniformity across standalone modes.

### Rename
None.

## 2026-05-07

### Summary
Coherence and consolidation pass — removed duplicated push-tests-down rationale (already in Test Pyramid), trimmed Testability Advocacy rationale tail, folded single-sentence Ad-Hoc Verification section into Verification Output Template intro, cross-referenced ACCEPT WITH CAVEATS verdict in template, added `docket stats` to CLI reference. Net: -5 lines (317→312).

### Changes
- Removed "Push edge cases to unit level" from Testing Philosophy — duplicate of Test Pyramid
- Trimmed Testability Advocacy closing rationale sentence
- Folded Ad-Hoc Verification (1-sentence section) into Verification Output Template intro
- Added "ACCEPT WITH CAVEATS" to Recommendation line in template — closes mapping gap with vote section
- Added `docket stats` to Docket CLI reference (audit finding)

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 3 trim sites), Coherence (verdict mapping), Capability Growth (`docket stats`), Actionability, Boundary Clarity, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-06

### Summary
Cross-agent comms visibility pass — adopted PM's `"[SDET→@agent] {summary}"` Docket-comment logging so operator can see SendMessage traffic in the issue timeline. Added SendMessage auto-resume note (wake idle peers on post-verification discovery) and `docket plan --root` for phase-aware verification (sibling-failure check). Net: -3 lines (319→316).

### Changes
- PRIMARY: Adopted `"[SDET→@agent] {summary}"` cross-agent message logging format (matches @project-manager) — addresses operator visibility feedback
- Capability: SendMessage auto-resume note in Inter-Agent preamble — wake idle peers on post-completion gap discovery
- Capability: Added `docket plan --root <id> --json` to Verification Workflow step 1 + CLI reference — phase-aware sibling context (failing sibling can invalidate APPROVE)
- Trimmed Per-Session Metrics — removed list overlapping Verification step 4 ("Layer signals") and Coverage Principles
- Trimmed Ad-Hoc Verification — removed restatement of template + "no new issues" rule already covered in Bug Reporting
- Compressed Bug Reporting severity definitions and required-field list

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — visibility format + auto-resume + docket plan), Consolidation & Trimming (PRIMARY — 3 trim sites), Actionability, Boundary Clarity, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 0+2 capability adoption: added `Monitor` to tools with run_in_background + until-loop pattern for long test runs / CI watches / flaky reruns. Added `color: red` frontmatter. Closed bidirectional gap with @staff-engineer testability consult on TDD drafts. Net: +3 lines (316→319).

### Changes
- Added `Monitor` to tools allowlist + Test Failure Diagnosis pattern (Phase 0)
- Added `color: red` frontmatter (Phase 2 fleet decision)
- Added incoming trigger: @staff-engineer testability consult while drafting TDD Testing Strategy (Phase 2 — closes inverse-trigger gap)
- Compressed Verification step 4 ("Layer signals") and merged step 5
- Tightened Greenfield step 6
- Deferred (Phase 2): `effort: xhigh` — A/B one agent first

### Dimensions Evaluated
Capability Growth (PRIMARY — Monitor), Cross-Communication (testability consult), Consolidation & Trimming, Completeness, Spec Alignment, Role Realism, Actionability, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Consolidation pass — trimmed NOT section restating description, compressed operating-context/TDD-gate to peer-brevity, removed duplicated operator-alignment in Check Specs (regression from 2026-04-16), tightened Verification step 4, Greenfield step 6, Bug Reporting, and Inter-Agent preamble. Net: -28 lines (347→319).

### Changes
- Compressed NOT section by 10 lines — match senior-engineer brevity, fix misplaced "verify @senior-engineer's test adequacy" (an IS, not a NOT)
- Compressed Operating context from 7 lines to 2 — match peer pattern
- Removed duplicated operator-alignment paragraph in Check Specs (regression from 2026-04-16 consolidation pass)
- Compressed TDD status gate to 1 line — aligned with senior-engineer phrasing
- Tightened Verification Workflow step 4, Greenfield step 6, Bug Reporting fields/severity, Inter-Agent preamble
- [Phase 2] Added 3 incoming-consult entries closing inverse-trigger gaps: @ux-designer new testable acceptance criteria, @senior-engineer edge case outside acceptance criteria, @senior-engineer diff-ready verification handoff

### Dimensions Evaluated
All 8: Consolidation & Trimming (PRIMARY — 28 lines removed), Coherence (regression fix), Boundary Clarity (NOT section), Role Realism, Actionability, Completeness, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-19

### Summary
Embedded operator "No guessing" behavioral gate after Quality stance — verification must be evidence-based (Read/Grep source, Bash run code, real log output, not inference). Trimmed duplicated "check context" lead-ins, redundant "production-grade rigor" line, and "Adapt human-SDET practices" filler. Added SendMessage trigger for fixture/framework uncertainty → @senior-engineer.

### Changes
- Added "No guessing" gate after Quality stance — evidence-based verification; "unverified" declaration when evidence is missing
- Consolidated duplicated "check for relevant context" lead-ins; removed redundant "production-grade rigor" line; trimmed "Adapt human-SDET practices" filler
- Added SendMessage trigger: fixture/framework/behavior uncertainty → @senior-engineer
- [Phase 2] Added @project-manager new-test-task incoming consult — reconcile against existing test strategy
- [Phase 2] Added @project-manager acceptance-criteria-change incoming consult — re-verify; prior APPROVE invalidated

### Dimensions Evaluated
All 8: Completeness (primary — no-guessing gate), Consolidation, Cross-Communication, Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: replaced 5 prose Inter-Agent Communication subsections with an 11-trigger notification table (6 new triggers). Added Incoming consults block for bidirectional reciprocity. Fixed Docket CLI audit gaps. Net: -12 lines.

### Changes
- PRIMARY: Consolidated Inter-Agent Communication into scannable trigger table + compact consult paragraph
- Added 6 new proactive SendMessage triggers: APPROVE-complete, flaky-confirmed, security-test-fail, regression `*` broadcast, TDD-not-accepted verify, unrelated-work surfaced
- [Phase 2] Added Incoming consults block: @ux-designer testability on draft spec, @staff-engineer test-infra alignment, ADR `*` broadcast consumption
- Added `-s STATUS` to `docket next`; added `docket export` for defect/verification reports
- Fixed `--findings-json JSON` → `--findings-json FILE|-`; documented `-r` short form for `--rationale`

### Dimensions Evaluated
All 8: Cross-Communication (GOAL — primary), Consolidation & Trimming, Completeness (CLI audit), Actionability, Role Realism, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Consolidation pass — removed duplicated operator-alignment guidance between Pre-Flight gate, Check Specs ambiguity paragraph, and Verification Workflow step 2. Merged duplicate test-coverage-escalation. Trimmed rhetorical opener. Annotated `vote list` default scope. Net: -14 lines.

### Changes
- Removed Verification Workflow step 2 (duplicated Pre-Flight gate) and compressed step 5
- Compressed Check Specs ambiguity paragraph to single directive referencing Pre-Flight mechanism
- Merged `Test coverage escalation` into preceding `@senior-engineer unit tests` paragraph
- Trimmed motivational flourish in opening role statement
- Annotated `docket vote list` default-open-only behavior in CLI reference

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Coherence, Completeness, Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added TDD status gate awareness to spec-checking workflow, updated Docket CLI reference with new vote flags, compressed Testing Philosophy and Greenfield strategy. Net: 0 lines.

### Changes
- Added TDD status gate: do not verify against non-accepted TDDs, require `status: accepted` before acceptance criteria verification
- [Coherence] Fixed TDD gate to check `status` field (not `maturity`) — aligned with staff-engineer and senior-engineer
- Updated `vote create` with `--created-by` and `--escalation-reason` flags, `vote cast` with `--summary` and `--voter` flags
- Compressed snapshot review protocol from 4 numbered steps to inline paragraph (-3 lines)
- Merged Greenfield steps 6-7 into single conditional step (-1 line)

### Dimensions Evaluated
All 8: Completeness (primary — TDD gate, Docket audit), Consolidation & Trimming, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Replaced direct `/vote` invocation with team-mode delegation pattern (critical cross-cutting fix — prevents nested team spawning). Added global flags/aliases to Docket CLI reference, `docket version` to session init, cleaned up vote CLI flags, removed blank line artifact. Net: -3 lines.

### Changes
- **CRITICAL**: Replaced `/vote` section with team-mode delegation pattern matching all other agents (operator-reported issue: direct invocation spawns nested agent teams)
- Added global Docket CLI flags (`--quiet`, `--watch`/`--interval`), aliases, and `docket version` to CLI reference header
- Added `docket version` to session init for traceability
- Standardized `vote cast` to show explicit verdict enum, removed `--created-by` from `vote create`
- Removed double blank line formatting artifact in Testing Philosophy

### Dimensions Evaluated
All 8: Capability Growth & Cross-Communication (primary — vote delegation fix), Consolidation & Trimming, Spec Alignment, Completeness, Role Realism, Actionability, Boundary Clarity, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter, added context compaction awareness, compressed Inter-Agent Communication, merged status/observability sections, removed Mermaid directive, compressed Defect Analysis and severity definitions. Net: -9 lines.

### Changes
- Added `model: opus[1m]` to frontmatter (settings standardization)
- Added context compaction handling to Operating context (team-wide pattern)
- Compressed Inter-Agent Communication preamble from 5 to 2 lines
- Merged Status updates and Cross-communication observability (-4 lines)
- Removed "Mermaid required" directive (not behaviorally relevant for test verification)
- Compressed Defect Analysis and bug severity to inline format

### Dimensions Evaluated
All 8: Completeness (frontmatter), Consolidation & Trimming (primary), Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest quality gatekeeper directive, compressed Mermaid subsection and "When NOT to consult" list, tightened Pre-Flight gate. Net: +1 line.

### Changes
- Added "Quality stance" directive: act as rigorous honest quality gatekeeper, challenge inadequate coverage, prioritize correctness over agreeableness, explain critiques with alternatives
- Compressed Mermaid Diagrams subsection from 5 lines + header to 2-line inline directive
- Compressed "When NOT to consult" from 4-line list to 2-line inline directive
- Tightened Pre-Flight standalone mode (-1 line)
- [Coherence] Standardized heading from "CRITICAL" to "MANDATORY: Pre-Flight Goal-Alignment Gate"

### Dimensions Evaluated
Role Realism (primary — mentor directive), Consolidation & Trimming, Actionability, Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and verification workflow, compressed cross-communication observability, proactive intelligence, delegation protocol, and testing philosophy. Net: -7 lines.

### Changes
- Added task coordination tools to frontmatter and multi-step verification guidance
- Compressed cross-communication observability from 6 to 3 lines
- Compressed proactive quality intelligence from 5 to 3 lines
- Tightened greenfield step 7 (-1 line)
- Compressed Delegation Protocol to inline format (-3 lines)
- Trimmed testing philosophy truism (-2 lines)
- [Coherence] Consolidated standalone Delegation Protocol into /vote section (aligned with staff-engineer/ux-designer pattern)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Coherence (Phase 2), all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Fixed Docket CLI reference inaccuracies (voter defaults, missing reopen/domain-tag/limit), compressed Pre-Flight Goal-Alignment Gate and Delegation Protocol, added --quiet flag awareness.

### Changes
- Fixed `docket vote cast` flags to show optional defaults (--voter defaults to git user.name)
- Added `docket issue reopen` as separate line and `--domain-tag`/`--limit` to vote list CLI reference
- Removed ambiguous `/ reopen <id>` from move line (reopen is its own command)
- Compressed Pre-Flight Goal-Alignment standalone mode from 8 lines to 2
- Compressed Delegation Protocol from 8 lines to 4
- Added `--quiet` flag note to Execution Workflow
- [Coherence] Restored required flags on `vote cast` (--confidence, --domain-relevance, --findings, --role) to match all other agents

### Dimensions Evaluated
Completeness (primary), Consolidation & Trimming, Actionability, Capability Growth, Role Realism, Boundary Clarity, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (Docket logging for BLOCK/coverage-gap/vote), fixed operating context to acknowledge project memory, added --findings-json to vote cast, trimmed testing philosophy and shutdown handling.

### Changes
- Added cross-communication observability: log BLOCK, coverage-gap, and vote interactions as Docket comments
- Fixed operating context to acknowledge `memory: project` instead of claiming stateless
- Added `--findings-json` flag to `docket vote cast` CLI reference
- Trimmed Testing Philosophy opener (redundant with Risk-Based Prioritization)
- Compressed Shutdown Handling from 3 lines to 2

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness, Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Added `reopen` and `log` docket commands to workflow, compressed Docket CLI Reference and Per-Session Metrics, added rework return step.

### Changes
- Added `docket issue log <id>` to Review context step for activity history
- Added step 6 "Return for rework" with `docket issue reopen` for BLOCK scenarios
- Compressed Docket CLI Reference from 15 lines to 9 (removed inline descriptions, merged related commands)
- Compressed Per-Session Metrics (removed restated testing.md content)

### Dimensions Evaluated
Completeness, Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Merged Block/Accept Criteria into Verification Workflow, compressed greenfield edge-case steps, removed standalone test code review section (boundary overlap with @staff-engineer code review), added coverage-gap escalation trigger.

### Changes
- Merged Block/Accept Criteria section into Verification Workflow step 6 (eliminates standalone section)
- Compressed greenfield steps 7-9 into single conditional step
- Removed "Reviewing @senior-engineer Test Code" section (duplicates test quality principles already in agent, overlaps with @staff-engineer's code review boundary)
- Reframed test code review sentence in "What You Are NOT" to match actual verification boundary
- Added "Notify on coverage gap" cross-communication trigger for @senior-engineer and @project-manager
- Added `skills: [vote]` frontmatter (coherence fix — body references /vote but frontmatter didn't declare it)

### Dimensions Evaluated
Consolidation & Trimming (primary), Boundary Clarity, Cross-Communication, Completeness, Role Realism, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated flaky test management into diagnosis workflow, trimmed redundant philosophy opener, added BLOCK notification trigger and build-as-test greenfield step.

### Changes
- Removed standalone "Flaky Test Management" subsection (already covered by Test Failure Diagnosis step 3)
- Trimmed Testing Philosophy opener (redundant with Risk-Based Prioritization and Review Checklist)
- Added "Notify on BLOCK" cross-communication trigger for @staff-engineer and @senior-engineer
- Added greenfield step 9: recognize build-as-test as existing validation layer (aligns with docs/spec/testing.md)
- [Coherence] Added @ux-designer notification trigger for design spec deviations (bidirectional gap fix)

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Spec Alignment, Completeness, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated Operator Alignment into Check Specs preamble, compressed Testing Philosophy, removed inverse /vote guidance, added effort frontmatter, fixed code review boundary coherence.

### Changes
- Merged Operator Alignment section into Check Specs preamble (-12 lines, unique content preserved)
- Compressed Testing Philosophy by removing truisms already in Review Checklist and Test Pyramid
- Removed "When NOT to invoke /vote" list (logical inverse of positive list)
- Added `effort: max` frontmatter for thorough verification reasoning
- Fixed "perform code reviews" to "perform production code reviews" matching frontmatter
- [Coherence] Removed vestigial `docket config` from Session Initialization
- [Coherence] Added `memory: project` frontmatter (aligned with all other agents)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Compressed Inter-Agent Communication section (-20 lines of redundant status/intelligence lists), added greenfield zero-test handling, tightened Test Pyramid prose.

### Changes
- Compressed "Status updates to the operator" 13-line list to 3-line directive
- Compressed "Proactive quality intelligence" 10-line list to 4-line essentials
- Removed redundant "Asking questions about intent" paragraph (covered by Operator Alignment)
- Added step 8 to Greenfield Test Strategy for zero-test-result handling
- Tightened Test Pyramid subsection by removing truism opener
- [Coherence] Frontmatter: "does not perform code reviews" → "does not perform production code reviews"
- [Coherence] Docket comments now conditional ("when working on an issue") for ad-hoc contexts

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Spec Alignment, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Tightened greenfield strategy to reference spec, removed redundant "Running Tests" subsection, replaced prose review section with actionable checklist.

### Changes
- Updated greenfield strategy to reference `docs/spec/testing.md` as primary input, with fallback for missing specs
- Removed "Running Tests in This Codebase" subsection (redundant with spec-check section and greenfield strategy)
- Replaced prose paragraph in "Reviewing @senior-engineer Test Code" with scannable checklist including deterministic assertions check
- [Coherence] Replaced "orchestrator" with "user or team lead" (2 occurrences)

### Dimensions Evaluated
Actionability, Consolidation & Trimming, Spec Alignment, Role Realism, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added stateless operating context, removed non-executable human-process sections (Test Planning, Communication Style), compressed Decision-Making Framework to actionable Block/Accept criteria, fixed formatting artifacts.

### Changes
- Added operating context paragraph explaining stateless subagent execution model
- Removed Test Planning & Incident Analysis section (human processes: timeline negotiation, production incident observation)
- Removed Communication Style section (generic LLM output-quality instructions with zero behavioral impact)
- Compressed Decision-Making Framework to Block/Accept criteria (removed generic 6-factor list)
- Fixed double horizontal rule formatting artifacts

### Dimensions Evaluated
Role Realism, Actionability, Consolidation & Trimming (primary)

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 867 to 308 lines. Merged verbose responsibility sections, eliminated redundant and generic content, compressed all templates and prose.

### Changes
- Merged Responsibilities 1-3 into single "Test Architecture & Infrastructure" section
- Removed Responsibility 7 (Test Environment & Data Management) — generic advice implied by existing principles
- Removed Cross-Cutting Quality Concerns and Anti-Patterns sections — generic SDET knowledge
- Compressed Mentorship to focused test code review guidance
- Compressed Docket workflow, verification template, decision framework, and all prose

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Boundary Clarity, Spec Alignment

### Rename
No rename.
