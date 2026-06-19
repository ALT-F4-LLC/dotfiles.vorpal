# Changelog: adr

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

## 2026-06-09

### Summary
No-change verdict (second consecutive). Re-verified against the 2026-06-09 capability audit: zero unescaped `$`-substitution hazards; whole file (~3.3k tokens) fits the 5k compaction re-attachment cap so format authority needs no front-loading; `paths`/`disallowed-tools`/`when_to_use` adoption evaluated and inapplicable or parity-bound.

### Changes
- None. Frontmatter byte-parity and Skill(adr) reciprocity with tdd/prd/ux-spec re-confirmed; absent docs/tdd/adr/ handled by design (mkdir -p, next_num=1).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable slack; remaining candidates are parity-bound or churn), Skill Design Quality (new-frontmatter adoption audit), Coherence (family parity verified), Completeness (absent-dir edge benign).

### Rename
No rename. Family-aligned with prd/tdd/ux-spec/init-specs.

## 2026-06-08

### Summary
Phase 1 no-change verdict (mature skill, 25+ cycles). Re-verified full file against ground truth: allowed-tools (Glob/Grep genuinely used + family-identical), docs-path taxonomy match (team-lead.md §Docs-Path Taxonomy, writer = adr), leaf semantics, COUPLING family parity, canonical-block integrity. No over-engineering slack removable without breaking family parity.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable redundancy), Coherence (family parity + taxonomy verified), Orchestration (leaf confirmed).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 1 no-change verdict (mature skill). Phase 2: added a body-`status:` authority caveat (doc-family parity with tdd) adapted to adr's proposed→accepted→superseded ladder, naming Docket `.data.status` as source of truth; kept the by-design ladder-divergence guardrail.

### Changes
- `status` field rule: appended source-of-truth + documentation-only + never-gate caveat (+4 lines).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — nothing removable), Coherence (family status-authority parity restored).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: added a fenced-code-block carve-out to the §3 Section-order validation (count only `##` headings outside ``` fences), aligning with the §5 placeholder-scan exclusion and the doc-authoring family (lockstep with tdd/prd/ux-spec).

### Changes
- §3 Section order: count only `##` headings at column 0 outside ``` code fences.

### Dimensions Evaluated
Coherence (doc-authoring family lockstep).

### Rename
No rename.

## 2026-06-05

### Summary
Added Authoring Procedure step 4 prompting authors to verify embedded technical assertions (snippets, cross-engine/platform portability claims, relied-on test infra) against their actual target before writing them as settled fact — closing the failure class behind two Phase 0 LESSONs (an ADR codified unverified dual-dialect SQL; cited unrunnable test infra). Kept generic; prior step 4 renumbered to 5. Net +6.

### Changes
- Authoring Procedure: new step 4 (embedded-claim verification — state unverified claims as assumptions, not facts); prior "Proceed to Validation Before Save" renumbered 4→5.

### Dimensions Evaluated
Completeness (PRIMARY — embedded-claim gap), Actionability, Over-Engineering (HIGHEST — single generic step, no migration-specific bloat), Coherence. Family-symmetry of this guidance for tdd/prd/ux-spec routed to Phase 2.

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
