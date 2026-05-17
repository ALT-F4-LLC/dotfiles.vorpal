# Changelog: ux-spec

## 2026-05-17

### Summary
Replaced brittle curly-placeholder trigger `"design spec for {surface}"` with a concrete operator-typeable example (`"design spec for the new CLI"`). The placeholder form was effectively dead — operators don't type curly braces. Orphan hypothesis from historical audit disconfirmed: `agents/ux-designer.md` line 17 lists ux-spec in `skills:`.

### Changes
- Frontmatter description trigger list: replaced `"design spec for {surface}"` with `"design spec for the new CLI"`.

### Dimensions Evaluated
Skill Design Quality (trigger phrase actionability), Over-Engineering (no removable waste), Coherence (sibling parity preserved).

### Rename
No rename. Family-aligned with prd/tdd/adr.

## 2026-05-16

### Summary
Coherence: added cross-family delegation routes to design-review (peer review of UX spec drafts) and design-qa (implementation verification against UX spec) in "When NOT to Use" — closes asymmetric drift where the two new report-emission siblings cross-reference ux-spec but ux-spec did not reciprocate. Hardened the missing-section Failure Mode row to self-reference Required Sections instead of hardcoding "9".

### Changes
- When NOT to Use: added two delegation rows for `Skill(design-review, ...)` (peer review of drafts) and `Skill(design-qa, ...)` (verify implementation). Updated COUPLING comment to flag the cross-family bridge.
- Failure Modes: replaced hardcoded "all 9 sections in the order listed" with self-referential "all sections enumerated in Required Sections, in the listed order" — matches Validation §4's hardened pattern.

### Dimensions Evaluated
Coherence (cross-skill family bridge, internal consistency), Over-Engineering, Spec Alignment, Skill Design Quality.

### Rename
No rename. Family-aligned with prd/tdd/adr.

## 2026-05-09

### Summary
Phase 2 coherence: removed the orphaned `### Failure Mode Table` subheading. PRD retains the subheading because it has a load-bearing sibling H3 (`### Reserved-Name List`); ux-spec did not, so the subheading was decorative and diverged from tdd, adr, and code-review.

### Changes
- Failure Modes section: removed the `### Failure Mode Table` subheading immediately under `## Failure Modes`. The section now goes directly from H2 to the table, matching tdd / adr / code-review's structure. Net -2 lines.

### Dimensions Evaluated
Coherence (subheading parity across the leaf doc-authoring family).

### Rename
No rename.

## 2026-05-09

### Summary
Four handoff + actionability fixes (operator pain points 1, 2, 3): added `AskUserQuestion preview` guidance for visual variant comparison, strengthened cross-surface coherence wording in Authoring §1, added per-component implementation priority requirement to §9 Handoff Notes (a) for decomposition handoff, and added explicit missing-section row to Failure Modes for parity with sibling skills.

### Changes
- Authoring Procedure §5: added guidance that calling agents prefer `AskUserQuestion` with the `preview` field (CLI mockups, ASCII wireframes, copy variants) when resolving §9 design decisions with the operator — visual comparison beats prose for UX variants. Leverages new Claude Code tool capability.
- Authoring Procedure §1: re-anchored cross-surface naming rule to `agents/ux-designer.md` and matched tdd's "reference, not contradict, prior accepted work" prescriptiveness.
- Required Sections §9 (a): added per-component implementation priority requirement (P0/P1/P2 or MVP/polish) so @project-manager can sequence Docket issues without re-deriving order — directly addresses decomposition-handoff pain point.
- Failure Mode Table: added explicit "Required section missing or out of order" row for parity with the prescriptiveness of the Mermaid row and PRD/TDD's pattern.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration (leaf — verified no sub-agent surface), Coherence (sibling prd/tdd/adr alignment), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with adr/prd/tdd.

## 2026-05-09

### Summary
Phase 2 coherence pass: hardened Validation §4 to self-reference Required Sections instead of hardcoding "all 9".

### Changes
- Replaced hardcoded "all 9 Required Sections" with self-referential enumeration ("(currently 9 sections). Off-by-one against the count is a defect.") — matches tdd's hardened pattern.

### Dimensions Evaluated
Coherence, Completeness.

### Rename
No rename.

## 2026-05-09

### Summary
Sharpened §9 Handoff Notes (the single bridge to @project-manager and @senior-engineer) with concrete required sub-bullets and an explicit defect rule for vague entries; removed conditional indirection in Authoring step 7 (Open Questions rule was unenforced); removed duplicate ASCII-wireframes sentence from Mermaid Mandate paragraph 3 (already in Authoring step 4); added cross-reference explaining the doc-family `status`/`maturity` convention; adopted PRD's `### Failure Mode Table` subheading for sibling parity.

### Changes
- Required Sections §9 (Handoff Notes): expanded from one-line bullet to required sub-list (a–e) with concrete deliverables and explicit "vague entries are a defect" rule. Bridge section to PM/engineer now matches the prescriptiveness of TDD §11 Implementation Phases.
- Authoring Procedure step 7: collapsed conditional Open Questions explanation; removed indirection because the Validation Before Save step does not check for Open Questions and the rule is a soft norm enforced by the calling agent.
- Mermaid Mandate: dropped duplicate ASCII-wireframes paragraph — Authoring step 4 already states the same rule.
- Frontmatter field rules: added cross-reference explaining doc-family convention (PRD/UX = maturity-only living docs, TDD = both, ADR = status-only) — prevents future-reader from re-deriving the asymmetry.
- Failure Modes: added `### Failure Mode Table` subheading for sibling parity with PRD.

### Dimensions Evaluated
Actionability, Over-Engineering, Coherence, Spec Alignment, Skill Design Quality, Orchestration.

### Rename
No rename. Family-aligned with adr/prd/tdd.

## 2026-05-07

### Summary
Restored explicit `status`-field and Mermaid-missing rows in Failure Modes table for sibling parity with PRD; clarified Mermaid Mandate for non-GUI surfaces (CLI/API/config) per ux-designer.md cross-surface-journey rule; tightened Open Questions rule to clarify it is conditional. Net 275→284.

### Changes
- Failure Modes: split the catch-all "Common defects" row into three explicit rows — `status`-field rejection (parity with PRD), Mermaid-missing (parity with PRD/TDD), and the generic validation row. Restores actionable abort messages
- Mermaid Mandate: added paragraph for non-GUI surfaces — cross-surface journey or input/output state machine satisfies the mandate; single-action CLIs should diagram the surrounding workflow, not the action itself
- Authoring step 7: scoped "no unresolved Open Questions" rule to "if drafted" — the 9 Required Sections do not include a dedicated Open Questions section, so the rule applies only when the calling agent has drafted one (typically inside §9 Handoff Notes)

### Dimensions Evaluated
Coherence, Actionability, Completeness, Spec Alignment, Over-Engineering, Orchestration, Skill Design Quality.

### Rename
No rename. Family-aligned with adr/prd/tdd.

## 2026-05-07

### Summary
Phase 2 coherence: fixed stale H1 prefix to align with `name: ux-spec` after `create-` prefix was dropped. Symmetric to the vote H1 fix.

### Changes
- H1 changed from `# Create UX Spec — ...` to `# UX Spec — ...` to match frontmatter `name:` field

### Dimensions Evaluated
Coherence.

### Rename
No rename.

## 2026-05-06

### Summary
Coherence sweep: removed sub-agent prohibition row from Failure Modes (drift vs. tdd/prd/adr — already enforced by BANNER and `allowed-tools`); added missing blank line before `## Output Contract` heading for sibling formatting parity. Net +0.

### Changes
- Failure Modes: dropped sub-agent prohibition row (redundant with BANNER + `allowed-tools` exclusion of Agent/TeamCreate/TeamDelete/Skill/SendMessage/Edit; not present in tdd/prd/adr siblings)
- Inserted blank line between Authoring Procedure step 7 and `## Output Contract` heading (formatting parity with sibling doc-authoring skills)

### Dimensions Evaluated
Coherence, Over-Engineering, Actionability, Completeness, Spec Alignment, Orchestration.

### Rename
No rename.

## 2026-05-06

### Summary
**Rename: `create-ux-spec` → `ux-spec`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-ux-spec` → `/ux-spec`, all cross-references updated.

### Changes
- Directory renamed `skills/create-ux-spec/` → `skills/ux-spec/`
- Frontmatter `name: create-ux-spec` → `name: ux-spec`
- Cross-references updated in: sibling skills (`prd`, `tdd`, `adr`, `specs`), `agents/ux-designer.md`, `agents/team-lead.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Changelog file moved: `docs/changelog/skills/create-ux-spec.md` → `ux-spec.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-ux-spec` → `ux-spec` per operator request.

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
Phase 1 over-engineering trim: removed five duplicated rules — Authoring self-check (mirrored Validation), Pre-flight prior-art scan (overlapped Authoring step 1), trailing path restatement, two redundant Failure Modes rows, and the third repetition of Mermaid Mandate. Net 298→282.

### Changes
- Authoring step 8 self-check removed — duplicated Validation Before Save verbatim
- Pre-flight step 5 prior-art scan removed — Authoring step 1 already runs a broader Grep over docs/
- Removed trailing `{output_dir}` / `{output_path}` restatement after SAVE_AND_RETURN block — Pre-flight step 2 establishes the path
- Failure Modes table: collapsed three rows (status-field, Mermaid-missing, generic validation) into one row referencing common defects
- Validation step 5: removed third repetition of "Mermaid Mandate is mandatory; there is no override"

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Completeness, Orchestration.

### Rename
No rename. Family-aligned with create-tdd/create-prd/create-adr.

## 2026-05-06

### Summary
Phase 2 coherence: removed dead "missing-parent prompt" phrase from SAVE_AND_RETURN. create-ux-spec runs only an informational prior-art scan; no parent prompt.

### Changes
- Save & Return Cancel handler: trimmed "or missing-parent prompt" — Pre-flight step 5 is informational and never prompts. Dead text removed.

### Dimensions Evaluated
Coherence, Actionability.

### Rename
No rename.

## 2026-05-06

### Summary
First changelog entry. Removed three dead "TDD §X.Y" cross-references and broadened the N/A section allowance to apply across surface types. Net 296→298.

### Changes
- Removed two "TDD §4.3" references and one "TDD §4.11" reference. No numbered TDD section system exists in `docs/tdd/` or `docs/spec/`; verified with grep. The skill is itself the format authority.
- Mermaid Mandate authority: now points to `agents/ux-designer.md` only (was also citing TDD §4.11)
- Authoring step 3 N/A allowance: broadened from "internationalization for a CLI-only flag" to apply across surface×section combinations (visual design for a CLI flag, accessibility for a non-interactive config schema, etc.) — eliminates need to enumerate every combination

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename

### Rename
No rename. Family-aligned with create-prd/create-tdd/create-adr.
