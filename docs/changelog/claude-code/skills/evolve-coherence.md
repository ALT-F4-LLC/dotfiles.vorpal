# Changelog: evolve-coherence

## 2026-07-27

### Summary
Phase 3 disambiguation resolved the `<n>` placeholder collision in the per-finding report format, where one token denoted both the finding ordinal and the dimension number.

### Changes
- DISAMBIG (confusable-name): `FINDING <n>` → `FINDING <i>` in the Coherence Report per-finding block and the Phase 1 spawn template, with an inline gloss distinguishing the finding ordinal from the dimension number — the file's own Phase 1 substitution note already reserves `<n>` for "the dimension in prose".

### Dimensions Evaluated
Disambiguation: confusable-name (applied), multi-reading, overlapping-ownership.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: corrected the D2 #1 tdd/adr ownership map to the post-edit author-attribution contracts; single-homed the Phase 2 reconciler task list in its spawning template.

### Changes
- D2 #1: tdd/adr now map to `@distinguished-engineer` (default, Medium+ cycles) + `@staff-engineer` (fallback/standalone) + security carve-out — was the stale "@staff-engineer" premise the model-routing-auditor tripped on (M1).
- §Phase 2 body: 3-step reconciler checklist trimmed to a pointer at the spawning template (drifted duplicate — template carried 1:1-invariant/Blockers-first/DEGRADED clauses the body copy lacked).

### Dimensions Evaluated
Cross-skill coherence (Phase 2): terminology accuracy, reference accuracy, body/template single-homing.

### Rename
No rename.

## 2026-07-27

### Summary
Pass A applied six confirmed audit findings, all re-verified live: three of the rubric's carve-outs rested on premises that are false at HEAD (a "sole" token count that is 4, a banner that carries no CRITICAL, and three dead quotes behind a cross-grep that returns zero hits on every target), and three detection mechanisms under-scoped (agent-root-only Skill() refs, an unexcluded x placeholder, a frozen 14-name ephemeral list missing 20+ live names). Pass B relocated the no-edit attestation into the first 20KB per the post-compaction placement rule. Net +1,643 bytes (50,450 → 52,093).

### Changes
- FIX[SUBSTANTIVE]: §Team Setup line 160 — full restatement of the single-homed evolve-orchestration-core.md §Shutdown Protocol (carrying its own explicitly-REJECTED wording variant) replaced by the citation, byte-identical to evolve-agents:137.
- FIX[SUBSTANTIVE]: D2 #4 — "the sole Skill(code-review-verdict) token … in its CRITICAL banner" replaced by the property test; live counts are 4 tokens and 0 CRITICAL.
- FIX[SUBSTANTIVE]: D2 #2 + its seed — issue-creation constraint re-anchored on the three live carriers (sdet.md:282, project-manager.md:12, verify-ac:249); the prior cross-grep's four phrasings were all dead, making it unfalsifiable.
- FIX[SUBSTANTIVE]: D1 #1 + Refs seed — placeholder `x` excluded (live 3× in this file's own prose) and ref scope widened from agents-only to both skill roots (99 live skill→skill refs).
- FIX[SUBSTANTIVE]: D3 #5 + its seed — frozen 14-name ephemeral list replaced by a re-derivation instruction (union grep + team-lead §Per-Role Dispatch Table).
- MOVE[SUBSTANTIVE]: mechanized `git status --porcelain` no-edit attestation relocated from Wrap-up (byte ~41.2K) into §No-Edit Guard (byte ~10.9K), inside the post-compaction re-attachment window.
- Companion fix: the D1 #6 carrier-pin list's `evolve-model-distribution` line citation updated 104 → 108 to match that skill's own S1 fix landing this cycle. The `evolve-coherence`:160 self-pin needed no correction (0 net line-count delta across all 10 edits).
- No-change: H1 (D1 #6 emitter direction re-verified CLEAN at HEAD); H2 (no fitness problem this window). Rejected: I2 (retire reconciler spawn — capability downgrade, not mechanization, disanalogous to the xref-builder precedent). Routed out: I1 (coherence_xref.py rule_matrix key — script change, outside this cycle's 7-SKILL.md scope, needs script+schema landed together).

### Dimensions Evaluated
All 8. Findings under Coherence (1), Actionability (3), Completeness (4), Skill Design Quality/Over-Engineering (2, paired). Orchestration & Agent Teams: reconciler-retirement proposal evaluated and REJECTED. Spec Alignment and Rename: clean.

### Rename
No rename.

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 8 entries (2026-07-10..2026-07-17) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 8 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation pass: resolved two residual multi-readings in the rubric this cycle rewrote — D1 #6(a)'s bare `team-lead` addressee token (which would emit false Blockers against 4 live skill carriers) and D2 #4's verb-coupled hard-restriction property (which excludes the one skill it cites as the missed case).

### Changes
- DISAMBIG[SUBSTANTIVE][multi-reading]: D1 #6(a) — `shutdown_response` addressee re-anchored from the literal token `team-lead` to "its own spawner", with both correct carrier spellings named (agent files "addressed to team-lead"; evolve-* skills "addressed to the orchestrator") and marked as NOT drift against each other.
- DISAMBIG[SUBSTANTIVE][multi-reading]: D2 #4 — hard-restriction property restated as REFUSAL-to-proceed rather than the verbs `HALTS/ABORTs`; `commit`'s Step-0 gate cited as the verified case that uses "STOP"/"Blocked:" and neither verb, with an explicit ban on deciding membership by grepping for the literal verbs.

### Dimensions Evaluated
Phase 3 two-arm boundary test only. Both findings verified Arm-1 PASS (references resolve, role claims map to real owners, no CANONICAL block or ladder/name touched) and Arm-2 FAIL. No CANONICAL block modified.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence pass (same cycle as the Phase 1 entry below): fixed two self-inflicted drift sites this file's own D4 rubric introduced — a stale legend restatement and a dead pre-DKT-59 detection-seed phrase, both now pointing at live sources of truth instead of hand-copied text.

### Changes
- FIX[SUBSTANTIVE]: D4 invariant 1's "✓ body / ▾ pointer" restatement replaced with a pointer to the master legend — the restatement went stale when this cycle's own team-doctrine dispatch reworded the master's ✓ semantics.
- FIX[SUBSTANTIVE]: D4 detection seed's dead `see team-lead.md §Runtime Discipline R{N}` anchor (0 hits across all 8 agent files) replaced with the live master-path substring anchor, verified present in all 8 files.

### Dimensions Evaluated
Coherence (self-referential drift caught by the Phase 2 cross-skill pass). Mechanized checks: symmetry_check.py --check all (exit 0), --check mimir-note (exit 0), check_citations.py fleet-wide (zero genuine stale paths).

### Rename
No rename.

## 2026-07-27

### Summary
Corrected a false protocol invariant that inverted the shutdown emitter direction, replaced two frozen enumerations and two dead citations with derivation rules, and closed three false-positive classes (bundled skills, docket's no-banner status, init-specs's inapplicable coupling leg). Findings: 12 → 10 sub / 2 cos / 0 rej / 2 def / 0 enc

### Changes
- CULL[SUBSTANTIVE][OP-X1,D1]: D1 #6 asserted "only the spawner emits a `_response`" for both protocols — true for plan_approval, INVERTED for shutdown (team-lead.md:439 "team-lead SENDS shutdown_request and RECEIVES shutdown_response"; 6 agent files carry "always addressed to team-lead"). Split into (a) shutdown and (b) plan_approval with explicit directions + drift tests.
- AMPLIFY[SUBSTANTIVE][OP-C1,D1]: bundled-skill Exception added to D1 #1 and #5, mirroring D3 #1 — `Skill(claude-in-chrome)` (ux-designer.md:249) has no dir under either root and falsely read as unresolved.
- CULL[SUBSTANTIVE][OP-C4,OP-S4,D2]: D2 #4's frozen hard-restriction list redefined by PROPERTY (ABORT-on-caller-mismatch) — it omitted `commit`; seed regex widened to all three live ONLY-by spellings; dead `Skill(verify-ac)`-in-staff-engineer example re-pointed to the live team-lead.md:22 `Skill(code-review-verdict)` case.
- CULL[SUBSTANTIVE][OP-C10,OP-C7,D4]: D4 #2's "sole non-registered family" claim replaced by the derivation rule (3 named tags are now manifest-registered); D4 #3's restated per-agent rule counts replaced by a pointer to team-conventions.md — team-lead's hardcoded 1–10 had gone stale against the live 1–11, and team-lead.md Rule 5 is now only a tombstone.
- AMPLIFY[SUBSTANTIVE][OP-S1,OP-S5,OP-S8]: stale R2 placeholder citation re-pointed to runtime-discipline.md and generalized; leg (iii) marked INAPPLICABLE (not vacuous) for init-specs; `docket` added to the no-banner whitelist.
- AMPLIFY[COSMETIC][OP-S6]: Phase 1 spawn literal normalized to `review-d{n}`, matching lines 157/183 and the `{token}` naming convention; `<n>` retained for in-prose dimension refs.
- CULL[COSMETIC]: dropped the sixth restatement of "Phase 0 is not a spawn" (§Spawning Templates preamble), keeping the instance that carries the anti-revert rationale.

### Dimensions Evaluated
All 8. Coherence + Completeness primary; Over-Engineering secondary (one cull; the No-Edit Guard's 9-site redundancy is deliberate defense-in-depth, retained per 2026-07-24). Spec Alignment N/A (no `docs/spec/` in-repo; file cites none). `context: fork`/`background` N/A — repo-wide 0 hits and this skill spawns a team. Two innovation findings deferred to Docket (need new script capability). No CANONICAL block touched.

### Rename
No rename.

## 2026-07-24

### Summary
Compacted 3 entries (2026-06-30..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Re-grounded the main-session-only rule on the documented no-nested-teams limitation after the cited spawn-depth env-var mechanism went unverifiable in current docs; retired a self-referential role count that had already drifted; escaped the fleet's only unescaped $+digit. Findings: 3 → 2 sub / 1 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: corollary (2) now cites the agent-teams "No nested teams" limitation (fetched and verified live) instead of the 2.1.217 CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH default, which appears nowhere in current docs; adds a guard naming why spawn-depth is the wrong authority.
- CULL[SUBSTANTIVE]: "three roles" → "spawned roles" — only two model= pins remain since the xref-builder spawn was retired; dropped the count rather than correcting it, per this file's own anti-hand-enumeration rule.
- AMPLIFY[COSMETIC]: escaped $2 in the D1 registry awk seed — $N substitution is unconditional, so a 3+-token invocation would silently corrupt the seed with no error.

### Dimensions Evaluated
All 8; Correctness/Currency primary, Over-Engineering secondary (no standalone culls; No-Edit Guard's 9-site redundancy is deliberate defense-in-depth, retained). doctrine_check.sh all arms PASS; no CANONICAL block touched.

### Rename
No rename.

## 2026-07-22 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-06-10..2026-06-20) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-22

### Summary
Phase 3 disambiguation: three local multi-reading fixes plus the family-wide PHANTOM-PATH-GUARD rewording.

### Changes
- Phase 2 gate names its task-plane-unavailable fallback (reports + shutdown handshakes), reconciling it with the best-effort note — one reading, not two.
- D4 #2 leaf-family definition keys on the CANONICAL-marked BANNER block body, excluding `commit`'s bespoke un-marked banner from the literal-grep sweep.
- Innovation Mandate names its audited set (evolve-agents/skills/config, the EVOLUTION-MODEL carriers); evolve-model-distribution's mandate absence marked intentional — never a finding.
- CANONICAL:PHANTOM-PATH-GUARD parenthetical rewritten in lockstep (5 carriers) to close the inverse `.claude/skills/<non-evolve>` dual-homing reading.

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership) — all kept findings multi-reading.

### Rename
No rename.

## 2026-07-22

### Summary
Phase 2 coherence (stacked entry — same-date Phase 1 entry below retained per prepend rule): discharged the I4 deferral recorded in this date's Phase 1 entry — phantom-path-guard paragraph wrapped as CANONICAL:PHANTOM-PATH-GUARD in all 5 evolve-* files and registered in doctrine_check_manifest.tsv. No hand-enumeration update needed: D4 #2 reads the tag set from the manifest (the Phase 1 CULL of inline lists made this registration zero-touch here beyond the wrap itself).

### Changes
- AMPLIFY[SUBSTANTIVE][I4,D4]: wrapped the evolve-* location caveat in CANONICAL:PHANTOM-PATH-GUARD markers; registered 5-carrier tag in doctrine_check_manifest.tsv (no strip-transform — zero per-file tail verified). doctrine_check.sh Arm (c) now enforces parity.

### Dimensions Evaluated
D4 canonical-block parity (primary); D1/D2/D3 re-verified clean this pass (symmetry_check 8/8 OK, mimir-note present, coupling_check 8/8, registry/scripts/Skill() refs all resolve, citation MISSING lines all adjudicated false-positive).

### Rename
No rename.

## 2026-07-22

### Summary
Recorded WHY evolve-coherence has no §6a Model Routing Audit job (MR1: no history window, hardcoded non-Tiers model= pins — verified) + main-session-only depth note; hardened Team Setup against TaskCreate/TaskUpdate unavailability (H1, 6 in-window is_error hits); retired two self-inflicted hand-enumerations (I3: leaf-carrier list L125, manifest-tag list L129 which had already drifted, omitting CRASH-STALL-CORE); added `commit` to the bespoke-banner outsider whitelist (L128 said "two" — actually three). Findings: 5 → 5 sub / 0 cos / 1 rej / 2 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE][MR1,D1]: L40 divergence-rationale note (no Model Routing Audit; main-session-only) — cited by 3 independent Phase-0 auditors.
- AMPLIFY[SUBSTANTIVE][H1]: L148 TaskCreate/TaskUpdate best-effort fallback note — cited 6 in-window is_error hits, session 3975dd71.
- CULL[SUBSTANTIVE][I3]: L125/L129 hand-enumerated leaf-carrier + manifest-tag lists → manifest pointers; L129's list had already drifted (omitted live tag CRASH-STALL-CORE, verified).
- AMPLIFY[SUBSTANTIVE][reviewer-originated]: L128 whitelist `commit` as a third bespoke-banner outsider (verified: commit/SKILL.md:18 carries "This is a leaf skill" in a non-CANONICAL banner, unregistered in doctrine_check_manifest.tsv).

### Dimensions Evaluated
All 8; Completeness (3) + Coherence (6) + Over-Engineering (4) primary. H3 (2 pitfalls.md items) verified ALREADY-ENCODED (all 5 orchestrator BANNERs byte-identical + correct path; CANONICAL:HARVEST correctly single-homed). I2 (coherence_xref.py automation) DEFERRED to a project-manager implementation issue — new script authoring is out of this read-only cycle's scope. I4 (phantom-path-guard CANONICAL registration) DEFERRED to Phase 2 — parity-bound across all 5 evolve-* files.

### Rename
No rename.

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
- 2026-06-20: Over-engineering trim + AMPLIFY (Phase 1); model= pinned on all 3 Agent() spawns (Phase 2). Net +1 line (327→328).
- 2026-06-19: Question-severity gloss rejected two AMPLIFY findings (non-executable param; out-of-scope bucket). | DRIFT: Question-severity gloss reworded ("blocked on confirmation before dispositioned") — neutral allele substitution, net 0.
- 2026-06-10: Full-cycle audit — NO changes (327 lines); all 3 Phase-0 pitfall focus areas re-verified NO-OP (leaf-family enumeration, section ordering, redundant-TaskUpdate guidance).
- 2026-06-10: Introduced evolutionary-theory core — CANONICAL:EVOLUTION-MODEL block; evolve-coherence reframed as reproductive-isolation monitor (detects drift, routes to evolve-agents/evolve-skills, never edits).
- 2026-06-30: Encoded the cited ranged-Read confirmation efficiency gain at both binding sites with an absence/coverage grep carve-out. RETAIN otherwise (no-signal organis...
- 2026-06-30: Phase-2 coherence: fixed a high-risk glob-abort in the Phase-0 inventory command. Inline, net 0 (stays 328).
- 2026-06-30: Phase-1 coherence follow-up: expanded D1 lifecycle ownership into lifecycle + report-delivery ownership, added report-delivery obligations to the XREF schema...
- 2026-07-10: Redundancy + roster-drift trim on a zero-invocation organism. Two CULLs, no additions; net -165 bytes. Report-and-route boundary unchanged.
- 2026-07-12: Collapsed the duplicated intentional-variants whitelist to one canonical source (Phase 1 spawn template now points to rubric's inline carve-outs). Rejected xref-builder→script Rethink.
- 2026-07-12: Phase 3 disambiguation: removed a dead reference to a nonexistent "evolve-suite" skill from the description (repo-wide grep confirmed no such skill exists).
- 2026-07-13: Phase 2 coherence: D4 rubric re-grounded against the live CANONICAL carrier map — HARVEST single-homing, BANNER-outsider whitelist, orchestrator-family enumeration.
- 2026-07-14: Compacted 4 entries (2026-06-04..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-14: Refreshed D4 rubric's manifest-enumeration prose after doc-authoring + evolve-* families were registered in doctrine_check_manifest.tsv this cycle.
- 2026-07-14: D4 #2 now reads manifest-registered CANONICAL carrier sets from doctrine_check_manifest.tsv instead of hand-counting (H8) — fixed a live under-count of the PITFALLS carrier set.
- 2026-07-17: Coherence-class fix: ephemeral-name-consistency invariant (D3 #5) now lists docs-researcher and docs-researcher-phase0 as distinct, intentional names.
