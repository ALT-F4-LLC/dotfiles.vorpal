# Changelog: evolve-coherence

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Coherence pass: phantom-path guard note added (this skill lacks a DOCS-PATHS-LOCAL block; anchored after the REPORT+ROUTE paragraph).

### Changes
- Added byte-identical evolve-* phantom-path guard note — this skill audits cross-references across both skill roots and is most at risk of emitting a phantom src/user/claude-code/skills/evolve-* path into its Remediation Manifest

### Dimensions Evaluated
Coherence, reference accuracy.

### Rename
No rename.

## 2026-07-20

### Summary
L22: wired the existing-but-unreferenced `coupling_check.py` into D3 #6's COUPLING detection seed, replacing manual grep-and-parse with the script for legs (i) count=roster and (ii) reciprocity; leg (iii) delegation-list agreement stays manual (NLP-judgment, out of script scope). Aligned line 108's one-directional-bridge whitelist to include init-specs, matching the script's ONE_DIRECTIONAL_BRIDGES and closing the doc-gap the script's own docstring flagged. L21 verified NO-OP: D4 #2 already derives CANONICAL-block counts live from doctrine_check_manifest.tsv (the old hardcoded "7 carriers" bug is documented as fixed); D3 "family of 5/4" counts match live script output. Net +541 (post-apply ~43.4KB, far under 65KB).

### Changes
- L116: manual COUPLING grep-parse → `coupling_check.py` call (mechanizes legs i+ii; leg iii manual).
- L108: added init-specs to the one-directional-bridge whitelist bullet.

### Dimensions Evaluated
All 8; Coherence + Executability primary (script wiring). L21 (self-referential CANONICAL count) verified already-mitigated at D4 #2. Content gate pass (executable/behavioral/non-redundant/concrete); no unescaped $-digit introduced.

### Rename
No rename.

## 2026-07-17 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-17

### Summary
Coherence-class fix surfaced by the evolve-skills cycle's Phase 2 coherence-reviewer: the ephemeral-name-consistency invariant went stale after evolve-* renamed its Phase-0 docs-researcher auditor to docs-researcher-phase0.

### Changes
- Naming invariant (D3 #5) now lists `docs-researcher` (team-lead's retrieval-only ephemeral) and `docs-researcher-phase0` (the evolve-* Phase 0 doc-research ephemeral) as distinct names, so the intentional split is not flagged as an inconsistency.

### Dimensions Evaluated
D3 (naming & rename drift) - accurate references, consistent terminology.

### Rename
No rename (this file itself was not renamed; it documents a rename in sibling skills).

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-06-04..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Refreshed D4 rubric's manifest-enumeration prose after doc-authoring + evolve-* families were registered in doctrine_check_manifest.tsv this cycle (self-consistency fix for drift my own manifest edit introduced).

### Changes
- AMPLIFY: D4 CANONICAL-parity bullet — dropped the stale "currently PITFALLS/EVOLUTION-MODEL/DISAMBIGUATION-CHARTER" hand-count; ARGUMENT_HANDLING/COLLISION_DIALOG/SAVE_AND_RETURN + evolve-* families now noted as registered.

### Dimensions Evaluated
Coherence (self-consistency after shared-infra edit).

### Rename
No rename.

## 2026-07-14

### Summary
D4 #2 now reads manifest-registered CANONICAL carrier SETS from doctrine_check_manifest.tsv (source of truth doctrine_check.sh enforces) instead of hand-counting them — resolves recurring stale-enumeration drift (H8) and a live instance: the inline "7 carriers" for PITFALLS under-counted the manifest's registered set (omitted the team-doctrine reference carrier). Findings: 7 → 1 sub / 0 cos / 1 rej / 3 def / 0 enc (+ M4 no-change)

### Changes
- CULL/REDIRECT[SUBSTANTIVE][H8]: replaced hardcoded carrier counts for PITFALLS/EVOLUTION-MODEL/DISAMBIGUATION-CHARTER with a manifest pointer; HARVEST + doc-family stay inline (not yet manifest-registered). Net +69.

### Dimensions Evaluated
All 8. Coherence (6) + Over-Engineering (4) primary. Report-and-route-only charter verified intact (4 enforcement layers). No routing change (M4: zero usage, no evidence). Rejected I16 (scratchpad-write conflicts with disallowed-tools no-write design); deferred I17/I19 (cross-skill script builds), partial-applied I18.

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: D4 rubric re-grounded against the live CANONICAL carrier map — HARVEST single-homing, BANNER-outsider whitelist, orchestrator-family enumeration; EVOLUTION-MODEL lockstep.

### Changes
- D4 #2: HARVEST claim corrected to single-homed in evolve-phase0-templates.md §2 (was: 3 skill carriers — false, would emit 3 phantom missing-carrier findings).
- D4 #2: BANNER outsiders now review-and-comment + session-metrics (+ team-doctrine no-banner-by-design); orchestrator family enumerates all identical carriers.
- CANONICAL:EVOLUTION-MODEL header now names all 4 carriers (lockstep).

### Dimensions Evaluated
Coherence (carrier-set accuracy, CANONICAL parity).

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Removed a dead reference to a nonexistent "evolve-suite" skill from the description (confirmed via repo-wide grep — no such skill exists). Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- CULL[SUBSTANTIVE]: description no longer claims "(evolve-suite runs it automatically)" — no `evolve-suite` skill exists anywhere in the repo

### Dimensions Evaluated
Coherence (dead reference). Flagged for a future cycle (shared with evolve-agents' 29-occurrence issue): this file's own description also carries the stale `agents/*.md` / bare `skills/*` path literals — not touched this pass, kept narrowly scoped to the confirmed dead reference.

### Rename
No rename.

## 2026-07-12

### Summary
Collapsed the duplicated intentional-variants whitelist to one canonical source — the Phase 1 spawn template now points to the rubric's inline `(D<n> #<m>)` carve-outs instead of re-enumerating all 9, removing a self-inflicted parity-drift hazard in a skill whose purpose is detecting parity drift. Rejected a Rethink to replace the LLM xref-builder with a deterministic script (embeds fuzzy prose-judgment it cannot safely mechanize). Findings: 2 → 1 sub / 0 cos / 1 rej / 0 def / 0 enc

### Changes
- CULL[SUBSTANTIVE]: Phase 1 spawn template §Task + rubric line-137 note — replaced the 9-item re-enumerated whitelist with a pointer to the rubric's own inline carve-outs, applied in lockstep across both locations to avoid a stale cross-reference

### Dimensions Evaluated
Coherence (6), Over-Engineering (4) — primary. Orchestration verified clean (REPORT-AND-ROUTE-ONLY charter enforced at 4 layers: description, banner, No-Edit Guard, `disallowed-tools`). Rejected: xref-builder → deterministic script (D1 prose-skill-name resolution and D2 claimed-agent extraction are fuzzy judgment calls that a script cannot reliably replace; XREF is already signals-to-verify, re-confirmed downstream).

### Rename
No rename.

## 2026-07-10

### Summary
Redundancy + roster-drift trim on a zero-invocation organism. Two CULLs, no additions; net -165 bytes. Report-and-route boundary unchanged.

### Changes
- CULL: dropped the stale hardcoded "(7 agents + 13+ skills)" parenthetical in the Scope-confirmation HARD GATE — ground-truth is 8 agents now (distinguished-engineer added); a hardcoded roster count is the exact drift class D3 polices, so removed rather than re-pinned.
- CULL: removed the redundant "Canonical excluded instance: Skill(verify-ac)…" restatement in the D2 detection seed — fully subsumed by the general frontmatter-cross-check heuristic on the same bullet; guard stays double-covered via invariant #4 + Phase 1 whitelist (Content Gate Non-redundant).

### Dimensions Evaluated
All 8. Over-Engineering (primary): one redundant restatement culled. Coherence: stale roster count culled. Report-and-route invariant preserved; no model/routing change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-1 coherence follow-up: expanded D1 lifecycle ownership into lifecycle + report-delivery ownership, added report-delivery obligations to the XREF schema, and clarified that Remediation Manifest output is Phase-0 input signals-to-verify for sibling evolve cycles. Net +1 schema field; no report-and-route capability change.

### Changes
- AMPLIFY: D1 now audits report/final-report delivery obligations alongside spawn/lifecycle ownership and emits them in `report_delivery_obligations`, so coherence reviewers can detect silent-completion drift instead of treating lifecycle close semantics alone as sufficient.
- AMPLIFY: Remediation Manifest handoff wording now says operators feed findings into the next evolve-agents/evolve-skills Phase 0 as signals-to-verify, preserving report-and-route and avoiding treating manifest lines as pre-verified facts.
- CULL: removed the stale script-backed-check seed from D1; no Codex-compatible helper path is part of this skill's current contract.

### Dimensions Evaluated
All 8. Coherence/Completeness primary (report-delivery obligations + XREF schema). Over-Engineering: one stale helper-script seed culled. Report-and-route invariant preserved; no model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 coherence: fixed a high-risk glob-abort in the Phase-0 inventory command. Inline, net 0 (stays 328).

### Changes
- CULL: replaced the step-3 inventory `wc -l agents/*.md skills/*/SKILL.md .claude/skills/*/SKILL.md` + `ls -d skills/*/ .claude/skills/*/` globs (both contain the guaranteed-absent top-level `skills/` root → zsh nomatch-aborts the whole command even with `2>/dev/null`) with `find … -exec wc -l {} +` / `find … -type d` forms that tolerate absent roots and preserve the exact `{inventory}` set. Same bug class fixed in evolve-skills this cycle; verified under zsh.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Coherence/Completeness: glob-abort robustness. Report-and-route invariant preserved; no model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Encoded the cited ranged-Read confirmation efficiency gain at both binding sites with an absence/coverage grep carve-out. RETAIN otherwise (no-signal organism, 0 invocations). Net ~0 lines (inline expansion).

### Changes
- AMPLIFY: ranged `Read` of a pinned XREF `file:line` is now the default confirmation path for Phase 1 reviewers (cheaper than whole-file re-grep); grep retained for absence/coverage checks where no line anchor exists. Source: Phase 0 INNOVATION (a), cited — Edit-after-grep v2.1.160 + 1M context.

### Dimensions Evaluated
All 8 (Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename). Report-and-route invariant preserved; no model/routing change; drift=0. Phase-2 deferral noted: add report-family silent-completion/Round-N CANONICAL tags as D4 byte-parity carriers once they exist.

### Rename
No rename.

## 2026-06-20

### Summary
Over-engineering trim + AMPLIFY (Phase 1) and model= pinned on all 3 Agent() spawns (Phase 2). Net +1 line (327→328). Shared-CANONICAL-source flagged for a future cycle.

### Changes
- CULL: collapsed the D4 BANNER byte-parity detection-seed to method-only — it restated invariant #2's full family rules verbatim (Content Gate Non-redundant).
- CULL: dropped the triplicate @senior-engineer cross-tag clause from the Matrix-parity seed — already stated at invariant #3 and the Rule-numbering seed.
- AMPLIFY: added a post-edit-gate cue to the description — cited Phase-0 historical signal (standalone evolve-agents/skills edits skipped the coherence gate this window).
- AMPLIFY (Phase 2): pinned `model=` on the 3 Agent() spawns — xref-builder→sonnet, review-d<n>/reconciler→opus (dispatch-defect rule; operator-approved).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Drift: reworded the Question-severity gloss in the Coherence Report ladder (seed 6f0ab504, pick 3) — meaning preserved. Both AMPLIFY findings rejected on ground truth: spawn-template disallowed-tools is non-executable (Agent() spawn takes no such param; tool restriction lives in the referenced subagent definition's frontmatter), and an evolve-config Remediation bucket is out-of-scope (no dimension audits src/*.rs; bucket would always read None).

### Changes
- DRIFT: Question-severity gloss reworded ("blocked on confirmation before dispositioned") — neutral allele substitution, net 0.

### Dimensions Evaluated
All 8; Over-Engineering primary (density load-bearing, no cull). Coherence: BANNER + EVOLUTION-MODEL byte-identical across all 3 evolve-* carriers (live-verified). $-escape clean.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes (327 lines). All three Phase-0 pitfall focus areas re-verified NO-OP: leaf-family enumeration current (10 carriers incl. brief — exact grep match); section ordering correct (H1 → primacy banner → EVOLUTION-MODEL → Innovation Mandate); redundant-TaskUpdate guidance correctly absent (orchestrator-owned, belongs in team-lead.md — routed out of scope).

### Changes
- None (NO-OP verdict). D4 #2 invariant↔seed redundancy re-evaluated and RETAINED (protective empty-collapse guard; no cited failure signal).

### Dimensions Evaluated
All 8; Over-Engineering primary; Coherence (BANNER 8b897fe4 + EVOLUTION-MODEL e9ef8d09 byte-identical across all 3 evolve-* carriers; $-escape clean); Spec Alignment (symlink claim grounded in src/user.rs:492).

### Rename
No rename.

## 2026-06-10

### Summary
Introduced evolutionary-theory core: CANONICAL:EVOLUTION-MODEL block carrying the full shared vocabulary, with evolve-coherence explicitly reframed as the **reproductive-isolation monitor** — it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits. D4 CANONICAL:EVOLUTION-MODEL parity check formalized as single-family byte-identical across all three evolve-* carriers (hash e9ef8d09). Innovation Mandate updated to scope evolve-coherence's audit role over sibling innovation-mandate sections.

### Changes
- CANONICAL:EVOLUTION-MODEL block added (Phase A); byte-identical across all three evolve-* carriers.
- Skill identity reframed: evolve-coherence is the reproductive-isolation monitor, not a reproducing organism; never edits or applies selection.
- D4 #2 rubric updated to declare EVOLUTION-MODEL as single-family byte-identical across evolve-agents + evolve-skills + evolve-coherence.
- Innovation Mandate scoped to auditing sibling innovation-mandate sections for completeness and terminology consistency.

### Dimensions Evaluated
Coherence (EVOLUTION-MODEL family parity, D4 0 Blockers; No-Edit Guard consistency with reproductive-isolation framing); Completeness (D4 rubric coverage of new CANONICAL tag).

### Rename
No rename.

## Compacted history

Entries below were compacted per the retention-compaction policy; full text in git
history (see the compaction entry's date).

- 2026-06-04: First evolve cycle — hardened never-edits contract: dropped Edit/Write from allowed-tools, added disallowed-tools; fixed self-contradiction.
- 2026-06-05: Removed redundant "Whitelist of intentional variants" section (restated per-dimension carve-outs + Phase 1 template); pointer instead.
- 2026-06-08: Replaced stale hardcoded line refs (staff-engineer.md:103) with content-anchored Skill(verify-ac) token refs, per D4 #1 anti-line-number rule.
- 2026-06-09: Closed spawn-template rubric handoff gap — Read instruction for SKILL.md §Coherence Rubric added to Phase 0/1 templates.
- 2026-06-09: Phase 2 — added code-review→code-review-verdict D3 stale-name pair; whitelisted review-and-comment's non-CANONICAL banner in D4; updated 11 rename refs.
- 2026-06-09: Added brief to the D4 leaf-family BANNER enumeration — confirmed genuine leaf carrier omitted from the rubric list.
- 2026-06-09: Full-cycle audit NO changes — banner ordering + leaf-family rubric enumeration (10 carriers incl. brief) verified NO-OP via fresh grep.
- 2026-06-09: Phase 2 — escaped documentary $ARGUMENTS at L48; refutes prior "live substitution" rationale (substitution occurs inside backticks). Net 0.
- 2026-06-10: Full-cycle audit NO changes (323 lines) — "no Skill invocation captured" signal resolved as benign fast-exit; BANNER byte-parity confirmed.
