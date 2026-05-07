# Changelog: create-adr

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
