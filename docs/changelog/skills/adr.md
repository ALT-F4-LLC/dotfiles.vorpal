# Changelog: adr

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
