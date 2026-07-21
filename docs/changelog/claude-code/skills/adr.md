# Changelog: adr

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-08..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
No changes needed. Verified both L1 numbering-race findings are already fully encoded — citation-hijack skip in next_doc_number.sh:106-115 (surfaced at Pre-flight §5.1) covers the phantom-number collision; the pre/post-Write race Globs in §Save & Return cover the parallel-author race. Pass B found no removable slack with a cited fitness signal at this 16+-cycle maturity plateau; the prose-heavy §Save & Return double-Glob section is ledger-locked (L2). allowed-tools Glob/Grep re-confirmed genuinely used (race Globs, prior-art Grep).

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable slack outside the L2-locked section); Coherence (family parity with prd/tdd/ux-spec, allowed-tools usage, $-escape clean); Completeness (L1 races already encoded). Deferred: L2 --claim wiring (tracked separately, DKT-19; note: the --claim mode already exists in next_doc_number.sh per DKT-307 — only the SKILL.md wiring remains deferred, deliberately, given interaction risk).

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-05..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: next_doc_number.sh consumer list now cites `src/user/claude-code/agents/...` instead of the dead bare `agents/...` root.

### Changes
- Three agent-file references corrected to the repo-path convention the same sentence already uses for the script itself.

### Dimensions Evaluated
Coherence (reference accuracy).

### Rename
No rename.

## 2026-07-12

### Summary
Added a pre-Write race Glob so a parallel-author collision aborts cleanly before writing (no orphan file, no cryptic harness unread-overwrite error) — closes a documented incident and a coherence defect (the "single-author, no pre-Write renumber needed" claim was contradicted by that same incident). The citation-hijack numbering defect was already fully handled by next_doc_number.sh + Pre-flight step 5.1 — verified, no change. Findings: 2 → 1 sub / 1 cos / 0 rej / 1 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Save & Return sequence now brackets Write with pre- and post-Write race Globs; corrected the inaccurate "single-author" rationale
- AMPLIFY[COSMETIC]: added a Failure Modes table row for the new pre-Write abort, keeping the table a complete lookup

### Dimensions Evaluated
Actionability/Completeness (operational robustness — primary), Coherence (removed the single-author claim contradicted by the documented parallel-author incident). Deferred: doc_validate.py + slug.sh cross-skill extraction (shared with prd/tdd/ux-spec — this file's numbering-script precedent, next_doc_number.sh, is the natural analog). Already-encoded: citation-hijack collision handling (next_doc_number.sh:65-75 + Pre-flight step 5.1).

### Rename
No rename.

## 2026-07-10

### Summary
Fixed the broken COLLISION_DIALOG "Overwrite" branch — it Wrote over an existing file without a prior Read, which the harness rejects. Cross-cutting: applied byte-identically across adr/prd/tdd/ux-spec (surfaced by the ux-spec reviewer, propagated in lockstep).

### Changes
- AMPLIFY: Overwrite branch now Reads `{output_path}` before Write to satisfy the harness read-before-overwrite gate. CANONICAL:COLLISION_DIALOG lockstep across the 4 doc-authoring siblings.

### Dimensions Evaluated
Completeness / Coherence (bug fix). No model/routing/drift change.

### Rename
No rename.

## 2026-07-10

### Summary
No changes needed. Mature, internally consistent (16+ prior cycles); every candidate CULL/AMPLIFY lacked a cited fitness signal (zero correction/error signals, clean model outcomes on both fable-5 and opus). Shared validate_doc.py proposal declined for this leaf skill on Over-Engineering grounds.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST) — no CULL with a cited signal found.

### Rename
No rename.

## 2026-06-30

### Summary
Missing documentation directories explicitly non-fatal in ADR numbering and prior-art discovery, net -1.

### Changes
- AMPLIFY: treat absent/no-match ADR directory as an empty ADR set.
- AMPLIFY: prior-art searches existing dirs only.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Removed a mis-homed multi-agent coordination block that contradicted the leaf BANNER and single-author invariant; verified the cited self-validation path-fragility fix is already applied. Net -2 (273→271).

### Changes
- CULL: removed the "Multi-agent coordination (when applicable)" block — it prescribed a `SendMessage` handoff ("token is yours") that the CANONICAL BANNER forbids a leaf skill from doing, and contradicted "ADR authoring is single-author"; cross-agent coordination is the calling agent's concern (already delegated). Source: internal contradiction (file-cited signal).
- NO-OP (verified already-fixed): the cited fragile self-validation `cd docs/tdd/adr && f=0001-*.md && grep -n '^## '` no longer exists; validation is context-based and the race guard uses a repo-root-relative Glob.

### Dimensions Evaluated
All 8. Over-Engineering (highest): net -2. OPTIONAL-mermaid stance left intact (no parse mandate). No model/routing/drift change; no unescaped `$`+digit. Routed to evolve-agents (out of scope here): the removed stale-state-storm guidance may belong in agents/staff-engineer.md.

### Rename
No rename.

## 2026-06-19

### Summary
Collapsed the ADR-specific dual-Glob (pre-Write renumber + post-Write race-detection) to a single post-Write race-detection Glob.

### Changes
- CULL: removed the pre-Write "Before Write: Re-run Pre-flight step 5" re-Glob — it defended against concurrent ADR authors at the same {NNNN}, a race the single-author topology precludes (parallel staff-engineer spawns are reviewers, not authors). The post-Write Glob remains as the sole detect-and-abort backstop. Tightened the full-sequence line to `mkdir → Write → race-detection Glob → Emit`. Signal: Phase-0 innovation (redundant prevention step). Net -4.
- Drift (rate 7): all 7 SKIP — ordered-list ordinals + slug pseudo-code (parity).

### Dimensions Evaluated
Over-Engineering, Redundancy, Coherence, Content Gate, Rename.

### Rename
No rename.

## 2026-06-17

### Summary
Added a multi-agent single-writer baton guard and the COLLISION_DIALOG teammate-context caveat (lockstep). Trial: baton / inert-caveat → adopted.

### Changes
- AMPLIFY: multi-agent coordination guard in Save & Return — file-on-disk is the sole handoff-state source; send path/token exactly once per handoff (prevents stale-state re-send storms).
- AMPLIFY: COLLISION_DIALOG teammate-context caveat (lockstep across adr/prd/tdd/ux-spec).
- Note: the re-Glob redundancy optimization was CULLED by the reviewer as over-engineering (AskUserQuestion latency is a real race gap; two-Glob guard retained).

### Dimensions Evaluated
Completeness / Correctness (AMPLIFY), Over-Engineering (RETAIN), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
No changes needed. Full 8-dimension audit at 271 lines; Phase 0 signals verified against live file.

### Changes
- None (NO-OP verdict). Triple-Glob re-evaluated — each Glob serves a distinct safety purpose; line-budget pitfall inapplicable (no budget claim in body); proof-form pitfall already encoded at Authoring step 4.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable slack); Coherence ($-escape clean, CANONICAL blocks intact and family-aligned); when_to_use migration + CANONICAL shared-include extraction routed to Phase 2 as parity-bound.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 11 entries (2026-05-09..2026-06-04) into Compacted history per ADR 0001.

### Changes
- Replaced the 11 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 lockstep trim: removed the redundant "additional positional args" Failure-Mode row — CANONICAL:ARGUMENT_HANDLING body (L43) already states the identical ignore-silently rule. Applied identically to all 4 doc-authoring siblings (prd/tdd/adr/ux-spec, -1 each). Net -1 (271 lines).

### Changes
- Failure Modes: deleted last table row (intra-file duplication of the CANONICAL block; byte-identical removal across the family, grep-verified 0 survivors).

### Dimensions Evaluated
Coherence (family lockstep), Over-Engineering.

### Rename
No rename.

## 2026-06-10

### Summary
No changes needed. Verified live file state against all 8 dimensions; `allowed-tools` (Glob/Grep) confirmed correct and genuinely used in body. Triple-Glob pattern evaluated for collapse; pre-Write renumber Glob and post-Write race-detection Glob serve distinct safety purposes and cannot be merged.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable slack; triple-Glob justified by concurrent-author safety, 8-way parallel fan-out ran clean in window), Skill Design Quality ($-escape clean), Coherence (family parity confirmed; CANONICAL blocks intact), Orchestration (leaf confirmed).

### Rename
No rename. Family-aligned with prd/tdd/ux-spec/init-specs.

## 2026-06-09

### Summary
Compacted 10 entries (2026-05-06..2026-05-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 10 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Fourth consecutive no-change verdict. Glob/Grep confirmed genuinely used (numbering, race detection, prior-art) despite stale 2026-06-04 entry claiming removal — live state correct, historical entry left immutable per changelog policy.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (no removable slack without breaking family parity or safety rails); $-escape clean; family parity with tdd/prd/ux-spec intact.

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean; $-escape clean; no vague verify-reminders; numbering/race-detection steps are deterministic safety rails, not over-prescription. Third+ consecutive no-change verdict.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape audits clean.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-06: First entry: five fixes — forward-references, collision-dialog reachability under auto-numbering, deterministic numbering re-run, stale cross-reference.
- 2026-05-06: Removed dead missing-parent-prompt phrase from Save & Return Cancel handler — only create-tdd runs a parent probe.
- 2026-05-06: Phase 1 over-engineering pass: removed three duplicate restatements and meta-commentary; Mermaid Mandate collapsed to cross-reference (305→~272).
- 2026-05-06: Added create-* family COUPLING comment to When NOT to Use for sibling-asymmetry prevention.
- 2026-05-06: Renamed create-adr → adr per operator request; directory, frontmatter name, /adr slash command, and cross-references updated.
- 2026-05-06: Fixed post-write race-detection ordering — reframed as ADR-specific override between canonical Save & Return steps 3 and 4.
- 2026-05-07: Phase 2 coherence: H1 fixed from # Create ADR to # ADR to match frontmatter name after the create- prefix drop.
- 2026-05-07: Repaired SAVE_AND_RETURN canonical-block contamination (restored 3-step form); added optional superseded_by frontmatter field.
- 2026-05-07: Removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec.
- 2026-05-09: Phase 1 over-engineering: dropped the Mermaid Mandate entirely (now optional, judgment-based); trimmed Pre-flight meta-commentary (277→255).
- 2026-05-09: Three actionability + coherence fixes (operator pain points 1, 3): made the same-slug race gap explicit with operator-actionable mitigation, trimmed Pre-flig...
- 2026-05-09: Phase 2 coherence pass: hardened Validation §3 to self-reference Required Sections instead of hardcoding "all 4".
- 2026-05-13: Over-engineering pass: trimmed meta-commentary around numbering and race handling. Same-slug race paragraph compressed to actionable core; ADR-specific overr...
- 2026-05-16: Four small fixes prioritizing over-engineering pass: stripped unactionable "verify topic not in flight" advice from same-slug race guidance, compressed Pre-f...
- 2026-05-17: Three over-engineering / coherence fixes: collapsed duplicated Authoring §3-§6 into a pointer at Required Sections + Validation, dropped stale §5.7 forward-r...
- 2026-05-18: No-change verdict. Skill is mature and family-aligned with prd/tdd/ux-spec/specs after 13 prior changelog entries. Each candidate trim was evaluated against...
- 2026-05-25: Phase 2 coherence: removed redundant TYPE substitution note (lockstep with prd/tdd/ux-spec).
- 2026-05-25: No-change verdict. Skill remains mature and family-aligned with prd/tdd/ux-spec/specs after 14+ prior cycles. Three Phase 0 historical-audit focus areas eval...
- 2026-05-28: No-change verdict. Skill remains mature, lean, and family-aligned (prd/tdd/ux-spec/specs) after 14+ cycles. Operator coordination/handoff priority already se...
- 2026-05-30: No-change verdict (15th+ cycle). Re-read the full SKILL.md and verified family parity (frontmatter byte-identical with tdd/prd/ux-spec), tdd scope-boundary r...
- 2026-06-04: Dropped vestigial `Glob`/`Grep` from `allowed-tools` — the skill discovers prior art via `docket doc list`/`show` (Bash) and `Read`, never the Glob/Grep tool...
- 2026-06-05: Added Authoring Procedure step 4 (verify embedded technical assertions before writing as settled fact); prior step 4 renumbered to 5. Net +6.
- 2026-06-05: Phase 2 coherence — added fenced-code-block carve-out to §3 Section-order validation (count `##` headings outside fences), lockstep with tdd/prd/ux-spec.
- 2026-06-05: Phase 1 no-change verdict; Phase 2 added body-`status:` authority caveat naming Docket `.data.status` as source of truth (adr's proposed→accepted→superseded ladder).
- 2026-06-08: Phase 1 no-change verdict (25+ cycles); re-verified allowed-tools, docs-path taxonomy, family parity — no removable slack.
- 2026-06-09: No-change verdict (2nd consecutive); zero $-hazards, frontmatter/Skill(adr) reciprocity confirmed, absent docs/tdd/adr handled by design.
