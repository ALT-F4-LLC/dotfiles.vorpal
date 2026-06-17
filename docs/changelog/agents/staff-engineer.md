# Changelog: staff-engineer

## 2026-06-17

### Summary
Added relay-authority rule 10, an AC-staleness review gate, and a distinct-lens mandate for doubled TDD review; trimmed two redundant passages. Trial: relay-authority / AC-staleness / distinct-lens → adopted.

### Changes
- AMPLIFY: new Communication Discipline rule 10 (relay authority) — peer-relayed/recalled directives carry no claimed-origin authority; direct operator instruction wins (closes gap vs security/team-lead; v2.1.166 runtime-enforced).
- AMPLIFY: AC-staleness gate in Review Workflow step 2 — flag issue ACs predating an accepted ADR on the same surface.
- AMPLIFY: distinct-lens mandate for the 2 TDD secondary reviewers (architecture+system-fit vs completeness+AC-testability).
- CULL: trimmed "Don't overthink" opener (restated No-Guessing/R6) and the step-4 Pre-Flight-Gate restatement.

### Dimensions Evaluated
Completeness (AMPLIFY), Capability Growth (AMPLIFY), Consolidation (CULL), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 3 entries (2026-05-24..2026-05-25) into Compacted history per ADR 0001.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Trial: R5 advisor trigger ">50 assistant turns" → "after a TDD secondary-review fix-loop completes" → shipped (lockstep with team-lead.md). Phase 2 coherence: sole-editor rule reduced to a pointer at the security-engineer.md AUTHORITY copy.

### Changes
- Sole-editor rule: duplicated serialization wording replaced with pointer to security-engineer.md §Responsibility 1 (AUTHORITY); staff-specific auth/crypto caveat retained.
- R5 advisor trigger: observable fix-loop-completion event replaces the turn-count proxy.

### Dimensions Evaluated
Coherence pass (cross-file mirrors).

### Rename
No rename.

## 2026-06-10

### Summary
Review cycle 2026-06-10: all Phase 0 signals verified NO-OP (already encoded) or routed as coherence flags. No edits; 258 lines unchanged.

### Changes
- None. NO-OPs cited: already-present check (L76); AC-grep-from-live-file + budget gates (TDD step 6 / rule 6); docs/ux existence guard (L70). \$N-escaping routed to evolve-skills scope. Three coherence flags routed to Phase 2 (sole-editor duplication, R5 turn-count proxy, Light-TDD vs Rule 8(a)).

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 39 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001.

### Changes
- Replaced the 39 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-5 mandate slice: encoded the highest-recurrence "already-present check before recommending a change" guard into No-Guessing; added the missing use-when trigger for WebFetch/WebSearch. Offset by deduping rule 6's redundant back-reference. Net +2 (258 lines).

### Changes
- No-Guessing: added "Already-present check before recommending a change" — grep target file + changelog before proposing any audit/memory-sourced change; already-encoded = NO-OP with citation.
- TDD step 3 (Study precedent): added WebSearch/WebFetch use-when trigger (current external sources not derivable from codebase; ground citation in fetched content).
- Comm rule 6: removed redundant "(TDD Workflow step 6; Code Review step 7)" back-reference (steps already point forward to rule 6).

### Dimensions Evaluated
Capability Growth, Prescriptive Capability Triggers, Consolidation & Trimming, Reasoning-echo audit (no hits), Spec Alignment, Boundary Clarity, Rename.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: comm rule 7 ephemeral sentence + §Shutdown Handling Ephemeral paragraph (pre-shutdown checklist step (d) removed; pitfalls ordering kept as (c)). Count unchanged (257).

### Changes
- Rule 7: ephemerals await team-lead's request, reply shutdown_response (FIX 22).
- §Shutdown Handling Ephemeral: Pre-idle checklist (a)-(c); idle-awaiting-shutdown normal (FIX 23). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Deduped rule 7's shutdown contract against §Shutdown Handling (roster + await-shutdown_approved now pointers), upgraded the TDD step 6 teammate-envelope clause from inference to the officially documented rule (only `tools`/`model` apply to teammates; body appended — code.claude.com agent-teams doc), encoded the stale-line-citation edit pitfall into Comm rule 5. Net 0 (257 lines).

### Changes
- Comm rule 7: spawn-form roster → §Lifecycle pointer; duplicated await-shutdown_approved sentence → compact parenthetical pointing at §Shutdown Handling.
- TDD step 6: "Teammate-mode envelope assumption" → "(documented)" with citation; added "only `tools` and `model` apply; body APPENDED" facts.
- Comm rule 5: never aim an Edit at a reviewer-cited line number — line numbers drift across revisions; re-Read and target content strings (manifest-flux pitfall).
- Confirmed NO-OPs: no-op-before-redraft triage, freeze-gate (Moving-tree gate), memory:project/effort frontmatter (present on all 7 agents).

### Dimensions Evaluated
Consolidation & Trimming (rule 7 dedupe), Spec Alignment (envelope doc citation), Capability Growth (stale-line-citation), Role Realism, Actionability, Boundary Clarity, Completeness, Rename.

### Rename
No rename.

## 2026-06-09

### Summary
evolve-skills cycle reference update: code-review skill renamed → code-review-verdict; 4 references updated (skills frontmatter list, Hard Gates authority mention, review-output invocation + format-authority path).

### Changes
- `skills:` frontmatter entry, `Skill(code-review-verdict, "<scope>")` invocation, and skills/code-review-verdict/SKILL.md path updated.

## 2026-06-09

### Summary
Encoded the recurring "mid-cycle review on a moving tree" gate (recurs 2 repos) into Review Workflow Triage; offset by removing the redundant Reviewer-panel Lifecycle paragraph (fully restated at Responsibility 2 + TDD step 9). Net 0 (257 lines).

### Changes
- Review Workflow step 1 (Triage): added "Moving-tree gate" — confirm team-lead GO + no open `blockedBy` (the freeze gate) before reviewing; on a partial/HOLD tree, discard the partial read and report a DONE/NOT-DONE "partial — N of M" matrix instead of BLOCKing on unwritten work.
- §Lifecycle: removed the "Reviewer panel" paragraph (duplicated Responsibility 2 opener; unique TDD-recusal fact preserved at TDD step 9).
- Confirmed no-op: regex-execution gate (already encoded), Teammate-mode envelope assumption (Phase 0 verified complete).

### Dimensions Evaluated
Capability Growth (moving-tree gate), Consolidation & Trimming (Reviewer-panel removal), Actionability, Spec Alignment, Role Realism, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: mirrored the shared-TDD Sole-editor rule from security-engineer onto staff-engineer (the host-TDD author and the OTHER editor in that concurrent-edit hazard). Within-line; 250 lines.

### Changes
- §What You Are NOT (@security-engineer bullet): added a compact "Sole-editor rule (mirror of security-engineer.md)" — serialize to ONE editor per pass on a shared TDD; on "File modified since read", STOP and re-Read before re-editing (do not blind-retry). Co-located with the mixed-work co-authoring relationship that triggers it.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — parity-bound to security-engineer.md) · Terminology consistency · Consolidation (rides existing bullet, net 0).

### Rename
No rename.

## 2026-06-05

### Summary
Promoted the dominant cross-repo TDD-rigor lesson (cross-dialect SQL is an executable claim, not inspectable) by generalizing the "Regex execution gate" header to an "Executable-claim gate" covering both regex ACs and cross-dialect SQL. Offset by trimming the redundant 7-name spec enumeration (canonical list owned by init-specs + project-manager.md:312, both verified to enumerate). Physical net 0 (250 lines; both edits within-line).

### Changes
- TDD Workflow step 6: "Regex execution gate" → "Executable-claim gate (regex ACs + cross-dialect SQL)"; added clause (b) — cross-dialect SQL must execute against every declared dialect (PG/SQLite `ON CONFLICT` example). Grounded in agent-memory excerpt #1 (4 repos).
- Responsibility 4: dropped the inline 7 reserved spec-name enumeration; replaced with a pointer to their owners (init-specs + project-manager.md, both verified to carry the list). Load-bearing fact (ad-hoc, read-only for staff) preserved.

### Dimensions Evaluated
Capability Growth (SQL executable-claim gate) · Consolidation & Trimming (enumeration trim) · Actionability · Spec Alignment (all team-lead anchors verified) · Role Realism, Boundary Clarity, Completeness, Rename (no change).

### Rename
No rename.

## 2026-05-30

### Summary
Corrected the Doubling-Rule default: staff-engineer was the lone sibling declaring "Doubled-reviewer is the default," contradicting team-lead.md Rule 8 (default=1, opt-up=doubled) and out of step with sdet/ux-designer. Two in-line corrections (net 0; 248 lines). TDD-secondary-review's mandatory two-ephemeral author-recusal preserved as the always-doubled exception.

### Changes
- §Responsibility 2 opener (L113): "Doubled-reviewer is the default" → "Single reviewer is the default … opts up to the doubled panel per Rule 8 conditions"; reconciliation scoped to the opted-up case.
- §Lifecycle (L32): "Doubled reviewer pattern" → "Reviewer panel" — general review defaults to `advisor` alone, opt-up to doubled / 4-reviewer security track; TDD-secondary-review kept as the always-doubled recusal exception.

### Dimensions Evaluated
Spec Alignment (PRIMARY — Rule 8 default-1 alignment) · Boundary Clarity (security-track parallel preserved) · Consolidation & Trimming (net 0)

### Rename
No rename.

## 2026-05-30

### Summary
Two pure-consolidation trims removing verbatim duplication of canonical clauses (248 lines; within-line). No Rename / Docs-Research / CLI changes — docs-research recommendations already satisfied in this def.

### Changes
- §TDD Workflow step 9: collapsed the duplicated step-14 reconciliation expansion ("any Blocker blocks; findings merge with dedupe; Approve+Block → Block") and the duplicated ephemeral-shutdown contract into pointers (§Shutdown Handling Ephemeral + team-lead step-14 rules); full expansion retained once at the Responsibility 2 opener.
- §Comm Discipline rule 7: dropped the duplicated `"immediately" = same-turn final tool call` gloss (canonical at §Shutdown Handling); kept the routing-load-bearing async fact + WRONG/RIGHT example.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 verbatim-duplication removals) · Capability Growth (step-14 anchor coherence verified) · Spec Alignment

### Rename
No rename.

## 2026-05-26

### Summary
Three targeted edits grounded in Docs Research (subagent-as-teammate `skills:`/`mcpServers:` frontmatter ignored), Docket CLI audit (`docket export -o markdown -l <label>` rollup opportunity), and content-gate cleanup (Lifecycle duplicating §Shutdown Handling Ephemeral). Net 0 lines.

### Changes
- §Lifecycle (L30): removed redundant "Ephemerals MUST shut down immediately" + Fix-loops sentence (canonical in §Shutdown Handling); added "§Shutdown Handling" pointer; tightened "CLOSED-set advisor names" → "CLOSED-set names".
- §TDD Workflow step 6 (L103): appended "Teammate-mode envelope assumption" — TDDs prescribing skills/MCP for downstream agents must use explicit `Skill(<name>)` invocation in Implementation Notes, not assume frontmatter loads (IGNORED for teammates per Docs Research v2.1.117).
- §Review Workflow step 2 (L123): added `docket export -o markdown -l <label>` to gather-context CLI list for cross-issue architectural rollups.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — teammate-envelope caveat + docket-export rollup) · Consolidation & Trimming (Lifecycle/Shutdown Handling de-dup) · Spec Alignment (Phase 2 anchor-citation pattern preserved)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 7 dangling docs/tdd/* citations)

### Summary
Stripped 7 dangling citations to `docs/tdd/reviewer-doubling-lifecycle.md` and `docs/tdd/agents-token-optimization.md` (Phase 0 verified files do not exist in this repo). Redirected references to team-lead.md anchors (Rule 7, Rule 8, step 14 rules, §Teammate Stall & Crash Recovery, §Runtime Discipline).

### Changes
- L30 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L32 Doubled reviewer pattern: dropped "+ reviewer-doubling-lifecycle.md §4.2" tail.
- L104 TDD Workflow step 9: collapsed 4 danglers (§4.2/§4.4 rule 8, §4.3 rule 8, §8.2 decision 3/4, §4.3) into team-lead anchors.
- L111 Responsibility 2 opener: replaced "§4.2" + "§4.3 rule 8" + "§4.3" with Rule 8 + step-14 anchors.
- L225 Shutdown Handling Persistent: replaced "§4.4" + "TDD §4.4 rule 5" with team-lead Rule 7 + §Stall & Crash Recovery anchor.
- L227 Shutdown Handling Ephemeral: dropped "§6 continuity preamble per TDD §4.4 rule 2" — replaced with §Stall & Crash Recovery anchor.
- L235 Runtime Discipline header: replaced "agents-token-optimization.md §4.5" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — ephemeral shutdown contract + spawn-form canonical list)

### Summary
Tightened ephemeral shutdown contract for unambiguous same-turn FINAL-tool-call discipline. Added `tdd-reviewer-{N}` and `coherence-reviewer` to canonical spawn-form list (Rule 7 + Lifecycle + Shutdown Handling); added "expect shutdown_approved, NOT shutdown_response" framing to close 4 historical receive-side misroutes; rewrote Shutdown Handling Ephemeral block as 4-step pre-shutdown checklist (deliver report → drain background_tasks → memory write → emit shutdown_request last). Net unchanged in file (no net lines counted — surfaces present as longer-text-on-same-line).

### Changes
- §Lifecycle (line 30): surfaced `tdd-reviewer-{N}` and `coherence-reviewer` in the ephemeral roster; narrowed idle privilege to the three CLOSED-set names.
- §Comm Discipline Rule 7: expanded spawn-form enumeration; added async-shutdown caveat (FINAL TOOL CALL same turn); added explicit "await `shutdown_approved`, do NOT expect `shutdown_response`" to close 4 historical receive-side misroute paths.
- §TDD Workflow step 9: tightened doubled-secondary-review paragraph; bound reviewer exit to FINAL TOOL CALL same turn; deduped §4.4 rule 8 cross-refs.
- §Shutdown Handling: rewrote Ephemeral block as 4-step pre-shutdown checklist (deliver report → drain `background_tasks`/`session_crons` → memory write → emit `shutdown_request` last); explicit "idle ephemerals are a defect signal".

### Dimensions Evaluated
Actionability (PRIMARY — FINAL-tool-call discipline) · Boundary Clarity (canonical spawn-form list, idle-privilege narrowed) · Capability Growth (background-task drain checklist) · Completeness (await `shutdown_approved` not `shutdown_response`)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 1094 to 249 lines. Eliminated pedagogical content a staff-level LLM already embodies while preserving all behavioral…
- 2026-03-19: Removed 3 sections that fail Content Gate (Mentorship, Influence/Alignment, Decision-Making Framework). Salvaged incident analysis into…
- 2026-03-19: Tightened SDET boundary, removed dead "engineering growth" responsibility, compressed redundant passages, added SendMessage to tool list for…
- 2026-03-19: Compressed redundancy between Operator Alignment and TDD/Communication sections. Trimmed /vote negative list and verbose status updates. Added…
- 2026-03-20: Added effort and memory frontmatter, removed Advisory Mode negative list, compressed System-Level Thinking, tightened status updates, added TDD…
- 2026-03-20: Compressed Review Workflow step 4, trimmed Advisory Mode to essential bullets, added cross-team review notification triggers for @sdet and…
- 2026-03-20: Consolidated /vote section, compressed handoff, removed hardcoded spec count, added TDD revision and scope-change notification triggers…
- 2026-03-20: Compressed Advisory Mode and Anti-Patterns sections, added `docket plan` reference to review context gathering.
- 2026-03-21: Added cross-communication and vote observability, aligned Delegation Protocol with standardized JSON format, trimmed pre-flight and…
- 2026-03-29: Updated Docket Vote CLI reference with audit findings (new flags, corrected --voter default), compressed Delegation Protocol from 12 to 3 lines…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, removed speculative Delegation Protocol and redundant Anti-Patterns sections…
- 2026-03-30: Added Honest Technical Critique directive establishing posture on intellectual honesty, challenging flawed designs, and avoiding rubber-stamp…
- 2026-04-01: Added `model: opus[1m]` to frontmatter and Edit tool for incremental doc updates. Settings standardization and coherence fix.
- 2026-04-06: Fixed `/vote` team-nesting bug (operator feedback): team-mode now delegates to orchestrator instead of invoking Skill directly. Removed Docket…
- 2026-04-06: CRITICAL: Encoded mandatory TDD question-resolution workflow — open questions resolved via AskUserQuestion, secondary @staff-engineer review…
- 2026-04-16: Compressed Pre-Flight Gate mode descriptions and "When to Create a TDD" bullets; added proactive consultation triggers for @sdet (TDD Testing…
- 2026-04-16: Cross-communication pass: rewrote Proactive Communication into 10 concrete "situation → action" SendMessage triggers (5 new). Added Incoming…
- 2026-04-19: Added "No Guessing" top-level section covering ADR decisions, spec conventions, test outcomes, and API/pattern existence — staff role is…
- 2026-05-05: Consolidation pass: compressed "What You Are NOT" to dense one-liners (matches senior-engineer style), trimmed Pre-Flight Gate prose, merged TDD…
- 2026-05-05: Phase 0+2 consolidation + capability adoption: trimmed TDD section (removed redundant docs/tdd/ note, compressed "When to Create" bullets…
- 2026-05-06: Cross-comm observability + capability growth: marked 5 high-stakes outgoing triggers with **(cc operator)** for real-time visibility (vs batched…
- 2026-05-06: Phase 2 coherence pass: added persistent Docket-comment prefix `[STAFF→@agent]` alongside existing real-time `(cc operator)` markers — completes…
- 2026-05-07: Trimming pass: folded one-sentence "Handoff" H3 into workflow step 10, tightened Honest Critique closing (removed redundant "preserving…
- 2026-05-07: Capability-growth pass: adopted persistent agent memory for cross-session architectural precedent; named `AskUserQuestion` explicitly in…
- 2026-05-08: Consolidation pass: fused two duplicate operator-visibility rationale paragraphs into one block, trimmed intro restatement of frontmatter…
- 2026-05-08: Phase 2 coherence: aligned Operating context label and Persistent Memory format with the other four teammates; surfaced the sub-agent invocation…
- 2026-05-08: Phase 3 operating discipline: codified surface-fix rejection on review side, and remember solutions to recurring architectural problems.
- 2026-05-09: Tightened deliberative phrasing in Honest Critique close and TDD-workflow steps (decisive over meta), surfaced parallel @security-engineer…
- 2026-05-09: Phase 2 coherence: added explicit "NOT @security-engineer" boundary to clarify TDD-authoring split and parallel-review responsibility on…
- 2026-05-13: Sharpened §When to Create a TDD into an explicit threshold checklist (write-if-2-of-N, decline-and-route-if-any) addressing operator pain that…
- 2026-05-13: Phase 2 coherence: acknowledged Threat-Model Annotation handoff from @security-engineer in "NOT @security-engineer" boundary so staff-advisor is…
- 2026-05-16: Added Communication Discipline (rules 1-6) with rule 5 reinforced at the two highest-risk gates — TDD acceptance (verify before vote, not just…
- 2026-05-16: Phase 2 coherence: remove stale "Change 2/3" reference in Communication Discipline rule 3.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). The…
- 2026-05-17: pass 2: Cycle 2026-05-17: addressed three Phase 0 audit findings — interrupt-recovery / TeammateIdle stall vocabulary (2 `interrupted` events…
- 2026-05-17: Phase 2 coherence: Added @security-engineer critical/high re-plan incoming trigger for bidirectional handoff coherence.
- 2026-05-19: Cycle 2026-05-19 self-review across 8 dimensions. File is in good shape (282 lines); vote delegation payload already canonical per 2026-05-17…
- 2026-05-19: Phase 2 coherence: Universal-mirror visibility contract alignment (Phase 2 canonical decision: every SendMessage mirrors to Docket; conditional…
- 2026-05-19: Phase 2 coherence — memory channel activation: Activated the dormant `.claude/agent-memory/staff-engineer/` channel via a shutdown-time memory…
- 2026-05-24: Closed the 6 historical `is_error:true` shutdown-routing errors by making the routing rule explicit at rule 7 (shutdown protocol). Covers persistent `advisor`
- 2026-05-25: Promoted 4 pitfalls from actively-maintained memory (`pitfalls.md`) into the agent definition: advisor topology rule (NEW Comm Discipline rule 9), directory
- 2026-05-25: Two coherence fixes: (1) added explicit compaction-awareness clause to Comm Discipline rule 5 (Read before Write/Edit) matching senior-engineer L33 and
