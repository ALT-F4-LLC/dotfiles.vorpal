# Changelog: adr

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

## 2026-06-04

### Summary
Dropped vestigial `Glob`/`Grep` from `allowed-tools` — the skill discovers prior art via `docket doc list`/`show` (Bash) and `Read`, never the Glob/Grep tools. Family lockstep with prd/tdd/ux-spec.

### Changes
- `allowed-tools` trimmed to `["AskUserQuestion", "Bash", "Read", "Write"]` (dropped `Glob`, `Grep`).

### Dimensions Evaluated
Skill Design Quality (frontmatter tool pool), Coherence (byte-identical lockstep with prd/tdd/ux-spec).

### Rename
No rename.

## 2026-05-30

### Summary
No-change verdict (15th+ cycle). Re-read the full SKILL.md and verified family parity (frontmatter byte-identical with tdd/prd/ux-spec), tdd scope-boundary reciprocity, COUPLING sync, and canonical-block integrity against ground truth. No removable redundancy or broken refs.

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no slack; a change would be churn), Skill Design Quality, Actionability, Completeness, Orchestration (leaf), Coherence (tdd reciprocity + COUPLING sync verified), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/tdd/ux-spec/init-specs. Family-wide `disable-model-invocation` question raised to Phase 2 (no auto-fire incident in the clean historical audit — defer).

## 2026-05-28

### Summary
No-change verdict. Skill remains mature, lean, and family-aligned (prd/tdd/ux-spec/specs) after 14+ cycles. Operator coordination/handoff priority already served by clear return-to-caller semantics; dimension-5 over-scaffolding check confirms clean (leaf surface, no fake team triggers). Phase 0 under-use flag has no skill-text lever — invocation is the calling agent's responsibility.

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no removable redundancy without breaking family parity), Skill Design Quality, Actionability, Completeness, Orchestration (leaf/no-scaffold confirmed), Coherence (tdd reciprocity verified), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/tdd/ux-spec/specs.

## 2026-05-25

### Summary
Phase 2 coherence: removed redundant TYPE substitution note (lockstep with prd/tdd/ux-spec).

### Changes
- Removed `For this skill, substitute {TYPE} with adr in the usage error.` — Item 1 lockstep.

### Dimensions Evaluated
Coherence.

### Rename
No rename.

## 2026-05-25

### Summary
No-change verdict. Skill remains mature and family-aligned with prd/tdd/ux-spec/specs after 14+ prior cycles. Three Phase 0 historical-audit focus areas evaluated; none warrant a skill-level change. Parallel-dispatch duplication and worktree project-name detection escalated as cross-cutting concerns (separate from this skill).

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no remaining slack), Skill Design Quality, Actionability, Completeness, Orchestration (leaf surface confirmed), Coherence (sibling parity), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/tdd/ux-spec/specs.

## 2026-05-18

### Summary
No-change verdict. Skill is mature and family-aligned with prd/tdd/ux-spec/specs after 13 prior changelog entries. Each candidate trim was evaluated against family-parity and rejected.

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no remaining slack), Skill Design Quality, Actionability, Completeness, Orchestration, Coherence (sibling parity confirmed), Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-17

### Summary
Three over-engineering / coherence fixes: collapsed duplicated Authoring §3-§6 into a pointer at Required Sections + Validation, dropped stale §5.7 forward-reference (reported fixed 2026-05-13 but still present), removed leftover Mermaid-override sentence in Required Sections §2.

### Changes
- Authoring §3-§6 collapsed to 2 entries (section-order pointer + "proceed to Validation Before Save"); removes verbatim restatement of Required Sections §3+§4 and parallels sibling tdd §8.
- Pre-flight §5.7 forward-reference deleted; override block below self-announces with bold "Before Write:" heading.
- Required Sections §2 (Decision): removed sentence instructing author to drop a "Pure-policy ADR — no Mermaid required." override note. Mermaid Mandate was deleted 2026-05-09; override has no consumer.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (sibling tdd/prd/ux-spec/specs symmetry), Skill Design Quality, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename. Family-aligned with tdd/prd/ux-spec/specs.

## 2026-05-16

### Summary
Four small fixes prioritizing over-engineering pass: stripped unactionable "verify topic not in flight" advice from same-slug race guidance, compressed Pre-flight §5.7 forward-reference, removed meta-commentary tail from Authoring §6 (Consequences), and broadened Authoring §1 prior-art Grep scope to match sibling tdd.

### Changes
- Save & Return same-slug race block: dropped unactionable "calling agent must verify the topic is not already in flight" mitigation — leaf-skill caller has no in-flight registry; honest framing is "undetectable race".
- Pre-flight §5.7: compressed forward-reference paragraph — override block below self-announces.
- Authoring §6 Consequences: removed "Future readers consult this section first" rationale tail; folded "easier/harder" prompt into §6 where it guides drafting.
- Authoring §1 Gather Prior Art: Grep scope broadened from `docs/tdd/adr/` to also include `docs/tdd/`, `docs/spec/`, `docs/ux/` — ADRs may supersede TDD approaches or contradict UX spec conventions.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Actionability, Coherence (sibling tdd/prd/ux-spec/specs).

### Rename
No rename. Family-aligned with tdd/prd/ux-spec.

## 2026-05-13

### Summary
Over-engineering pass: trimmed meta-commentary around numbering and race handling. Same-slug race paragraph compressed to actionable core; ADR-specific override anchors deduplicated against the full-sequence summary line; Pre-flight §4 collision note tightened.

### Changes
- Save & Return same-slug race block: compressed multi-sentence mechanism explanation and redundant git-review fallback to two sentences; "Manual resolution required" already implies the git-review escape hatch.
- Save & Return ADR-specific overrides: removed "insert before/between canonical step N" anchor framing — full-sequence line above already conveys ordering.
- Pre-flight §4: trimmed "numbering picks a free NNNN, so same-path collisions are rare" preamble — non-executable context.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Actionability, Coherence (sibling tdd/prd/ux-spec/specs alignment confirmed).

### Rename
No rename.

## 2026-05-09

### Summary
Three actionability + coherence fixes (operator pain points 1, 3): made the same-slug race gap explicit with operator-actionable mitigation, trimmed Pre-flight §4 meta-commentary, and added a one-line full-sequence anchor between the canonical SAVE_AND_RETURN block and the ADR-specific overrides for at-a-glance ordering.

### Changes
- Save & Return post-Write override: replaced the unactionable "see Failure Modes below" punt about same-slug races with an explicit explanation of why same-slug TOCTOU is undetectable here, plus caller-side mitigation guidance and the git-review fallback path.
- Pre-flight §4: tightened to one sentence — removed the redundant "Concurrent races are caught by the post-write override below" pointer that meta-commented on the override section.
- Save & Return: added a single-line full-sequence summary (`mkdir → renumber re-Glob → Write → race-detection Glob → Emit`) between the canonical block and the first ADR-specific override so readers see the order without cross-mapping two override blocks.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration (leaf — verified no sub-agent surface), Coherence (sibling tdd/prd/ux-spec/specs alignment), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with tdd/prd/ux-spec.

## 2026-05-09

### Summary
Phase 2 coherence pass: hardened Validation §3 to self-reference Required Sections instead of hardcoding "all 4".

### Changes
- Replaced hardcoded "all 4 Required Sections" with self-referential enumeration ("(currently 4 sections). Off-by-one against the count is a defect.") — matches tdd's hardened pattern so the count stays in sync if Required Sections evolve.

### Dimensions Evaluated
Coherence, Completeness.

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
