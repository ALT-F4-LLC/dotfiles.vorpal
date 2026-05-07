# Changelog: create-adr

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
