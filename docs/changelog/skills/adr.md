# Changelog: adr

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

## 2026-05-09

### Summary
Phase 1 over-engineering pass: dropped the Mermaid Mandate (operator-hostile magic-string validation for single-decision records — ADRs are short, judgment is sufficient); trimmed two pieces of meta-commentary in Pre-flight §4 and §5.7. Net 277→255.

### Changes
- Authoring §4 reframed: Mermaid is now optional with a one-line guideline (judgment-based), no validation pressure
- Mermaid Mandate subsection removed entirely (was redundant with Authoring §4)
- Validation §5 (Mermaid presence) removed; placeholder scan renumbered
- Failure Modes row for "Mermaid mandate not satisfied" removed
- Pre-flight §4 preamble compressed (4 lines → 1 line) — collision-handling rationale was meta-commentary
- Pre-flight §5.7 forward-reference compressed (4 lines → 1 line) — duplicated the override block below

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename. Family-aligned with tdd/prd/ux-spec.

## 2026-05-07

### Summary
Phase 2 coherence: removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec; already enforced by CANONICAL:BANNER + `allowed-tools`. Net -1.

### Changes
- Removed Failure Mode row "Calling agent attempts to spawn sub-agents..." — fully redundant with CANONICAL:BANNER + `allowed-tools` exclusion list (Content Gate: Non-redundant fail). Sibling parity with ux-spec's 2026-05-06 removal.

### Dimensions Evaluated
Coherence — sibling-skill symmetry.

### Rename
No rename.

## 2026-05-07

### Summary
Two fixes (net 276→281): (1) repaired canonical-block contamination in SAVE_AND_RETURN — adr's block diverged from tdd/prd/ux-spec by embedding an ADR-specific renumber step inside the CANONICAL markers; reframed as an explicit pre-Write override outside the canonical region (mirrors the existing post-Write race-detection override). (2) Added optional `superseded_by` frontmatter field so superseded ADRs link forward to their successor.

### Changes
- SAVE_AND_RETURN canonical block restored to 3-step form (mkdir → Write → Emit) matching tdd/prd/ux-spec; ADR-specific renumber step moved outside the canonical markers
- Both ADR-specific overrides now sit together below the canonical block with explicit "insert before/between canonical step N" anchors
- Pre-flight numbering note (sub-step 7) updated to reference the ADR-specific override below the canonical block instead of "Save & Return step 1"
- Frontmatter contract: optional `superseded_by` added; required only when `status: superseded`
- Validation Before Save step 1 extended to require `superseded_by` when status is superseded

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: fixed stale H1 prefix to align with `name: adr` after `create-` prefix was dropped. Symmetric to the H1 fix applied to vote earlier this cycle.

### Changes
- H1 changed from `# Create ADR — ...` to `# ADR — ...` to match frontmatter `name:` field

### Dimensions Evaluated
Coherence (cross-skill H1/name consistency).

### Rename
No rename.

## 2026-05-06

### Summary
Fixed post-write race detection ordering bug: the check was described after the canonical "End." instruction, making it unreachable. Reframed as an explicit ADR-specific override that runs between canonical steps 3 (Write) and 4 (Emit). Net +2.

### Changes
- Save & Return: post-write race-detection paragraph reframed as "ADR-specific override — insert between canonical steps 3 and 4 (before End.)" so the check actually runs before termination
- Added explicit "On clean Glob, proceed to canonical step 4" branch so the agent knows to continue after a passing check

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
**Rename: `create-adr` → `adr`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-adr` → `/adr`, all cross-references updated.

### Changes
- Directory renamed `skills/create-adr/` → `skills/adr/`
- Frontmatter `name: create-adr` → `name: adr`
- Cross-references updated in: sibling skills (`prd`, `tdd`, `ux-spec`, `specs`), `agents/staff-engineer.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Changelog file moved: `docs/changelog/skills/create-adr.md` → `adr.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-adr` → `adr` per operator request.

## 2026-05-06

### Summary
Phase 2 coherence: added create-* family COUPLING comment for sibling-asymmetry prevention.

### Changes
- Added COUPLING comment to "When NOT to Use" section listing the 4 sibling create-* skills (mirroring create-prd's RESERVED-NAMES marker) — prevents asymmetric drift when adding/removing siblings.

### Dimensions Evaluated
Coherence (cross-skill family symmetry).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1 over-engineering pass: removed three duplicate restatements (self-check, post-Validation prose, race-detection honesty), trimmed two pieces of meta-commentary, and collapsed Mermaid Mandate to a cross-reference. Net 305→~272.

### Changes
- Authoring §7 Self-check removed — duplicated Validation Before Save verbatim
- Pre-flight §4 collision-handling preamble compressed — 5 lines of meta-explanation → 1 line
- Removed frontmatter-omission rationale paragraph (`maturity`/`scope`/`owner`/`dependencies`) — non-behavioral; cited unverifiable "TDD §4.3"
- Pre-flight §5.5 zero-padding rationale trimmed — general LLM knowledge
- Post-Validation abort prose collapsed — Failure Modes table covers the abort behavior + retry semantics
- Race-detection honesty paragraph removed — already covered by post-write block + Failure Modes table
- Mermaid Mandate condensed to cross-reference — rule was stated 3x (Authoring §4 + dedicated subsection + Validation §5)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename. Family-aligned with create-tdd/create-prd/create-ux-spec.

## 2026-05-06

### Summary
Phase 2 coherence: removed dead "missing-parent prompt" phrase from SAVE_AND_RETURN. create-adr has no parent-doc probe.

### Changes
- Save & Return Cancel handler: trimmed "or missing-parent prompt" — false-positive contract claim; only create-tdd runs a missing-parent (PRD) probe.

### Dimensions Evaluated
Coherence, Actionability.

### Rename
No rename.

## 2026-05-06

### Summary
First changelog entry. Five fixes addressing forward-references, collision-dialog reachability under auto-numbering, deterministic numbering placement, and a stale cross-reference. Net 304→305.

### Changes
- Pre-flight step 4: removed forward-reference to step 5; clarified that exact-path collisions are essentially impossible under auto-numbering; COLLISION_DIALOG kept as safety net for concurrent races
- Pre-flight step 5.7 + Save & Return: numbering Glob now re-runs inside Save & Return immediately before Write to honor the determinism contract that was previously unenforceable
- Pre-flight step 5.4: removed dead "and no malformed entries" clause (5.3 already aborts on malformed)
- Replaced unverifiable "TDD §8 Q3" reference with inline rationale (4-digit zero-padding ensures lexicographic sort matches numeric sort up to ADR 9999)
- Save & Return: added explicit re-run step

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename

### Rename
No rename. Family-aligned with create-tdd/create-prd/create-ux-spec.
