# Changelog: ux-spec

## 2026-06-09

### Summary
Full-cycle audit: NO changes. 9 verification probes all clean: Glob/Grep present and used (c10195b restore — no phantom drift, pitfall #10 applied via git log -S); agents/ux-designer.md cites grounded (L35 Mermaid, L118-129 Tiers, L147 content-design); allowed-tools byte-lockstep with prd/tdd/adr; COUPLING list accurate; description 340 chars.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (no removable waste); Coherence (CANONICAL blocks intact, boundary routes accurate).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean (rendered-effect lines are artifact-content guidance, not narration); $-escape clean; no over-prescription; recall-filter grep zero hits. Format authority intact.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape + recall-filter audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
No changes. Full 8-dimension review with 6 verification probes, all clean: no unescaped `$`+digit; `allowed-tools` in byte-identical family lockstep (current file correct post-c10195b, body uses Glob and Grep); Mermaid authority cite grounded in agents/ux-designer.md; design-review/design-qa routes reciprocal; placeholder-scan and failure-table rows parity-locked. Net 0.

### Changes
- None.

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST): trim candidates resolved to deliberate prior decisions or parity-bound content. Skill Design Quality: description ~340 chars, under listing budget. Coherence: family lockstep verified; `paths: docs/ux/**` recommended AGAINST (teammate-invoked; glob auto-activation would wrong-skill-load on mere docs/ux reads). Spec Alignment: docs/spec/ absent (template skill — not a defect).

### Rename
No rename. ux-spec (authoring) remains distinct from design-review (peer review) and design-qa (post-impl QA).

## 2026-06-08

### Summary
Removed a false circular cite ("mirrors `agents/ux-designer.md` Responsibility 1 design spec format") from the Required Sections preamble. The 2026-06-05 entry documented this same removal but the edit was not present in the file (un-applied or reverted); grep re-confirms ux-designer.md Responsibility 1 ("Design Specifications", L115) does NOT enumerate the 9 section names. The skill self-owns the section list. Net -1.

### Changes
- Required Sections preamble: dropped the circular ux-designer.md Responsibility 1 cite.

### Dimensions Evaluated
Spec Alignment (false cite — HIGHEST finding), Coherence (allowed-tools sibling parity, COUPLING bridge bidirectionality, docs-path taxonomy all verified clean), Over-Engineering (HIGHEST — none beyond settled trims). §9 Handoff Notes intact.

### Rename
No rename.

## 2026-06-05

### Summary
Phase 1: removed a false "mirrors agents/ux-designer.md Responsibility 1" cross-reference (the skill self-owns the section list; the cite was circular and absent there). Phase 2: restored the body-`status:` authority caveat (lockstep with prd).

### Changes
- Required Sections preamble: dropped the false ux-designer.md cross-ref (-1; verified none of the 9 section names appear there).
- `status` field rule: appended source-of-truth + documentation-only + never-gate caveat (+4).

### Dimensions Evaluated
Spec Alignment (false cite), Over-Engineering (HIGHEST), Coherence (status-authority parity). Historical Write-bypass path verified closed.

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: added a fenced-code-block carve-out to the §4 Section-order validation (count only `##` headings outside ``` fences), for doc-authoring family parity (lockstep with tdd/adr/prd). Phase 1 review found no other gap.

### Changes
- §4 Section order: count only `##` headings at column 0 outside ``` code fences.

### Dimensions Evaluated
Coherence (doc-authoring family lockstep).

### Rename
No rename.

## 2026-06-04

### Summary
Dropped vestigial `Glob`/`Grep` from `allowed-tools` — the skill discovers prior art via `docket doc list`/`show` (Bash) and `Read`, never the Glob/Grep tools. Family lockstep with adr/prd/tdd.

### Changes
- `allowed-tools` trimmed to `["AskUserQuestion", "Bash", "Read", "Write"]` (dropped `Glob`, `Grep`).

### Dimensions Evaluated
Skill Design Quality (frontmatter tool pool), Coherence (byte-identical lockstep with adr/prd/tdd).

### Rename
No rename.

## 2026-05-30

### Summary
One over-engineering trim: Authoring §4 was re-declaring the Mermaid rule (including the diagram-type examples) that the canonical "### Mermaid Mandate" section already owns; converted §4 to a procedural pointer, keeping only the ASCII-alongside clause unique to it. Net -2.

### Changes
- Authoring §4: dropped the duplicate "**mandatory** (per agents/ux-designer.md)" restatement and the diagram-type examples (both owned by the Mermaid Mandate section at line 216, verified); retained the ASCII-does-not-replace-Mermaid clause.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 1 trim), Coherence (authoring-family boundary vs design-review/design-qa verified; docs/ux/ path convention intact), Spec Alignment (agents/ux-designer.md cites verified), Actionability, Completeness (§9 Handoff Notes intact), Skill Design, Orchestration (leaf), Rename.

### Rename
No rename. ux-spec (authoring) cleanly distinct from design-review (peer review) and design-qa (post-impl QA).

## 2026-05-29

### Summary
Merged two overlapping When-to-Use bullets into one, and corrected the same `allowed-tools`-excludes-Edit misinformation found in prd/tdd (per docs, allowed-tools does not restrict the tool pool).

### Changes
- When to Use: merged bullets 1 and 3 (duplicate "surface needs a spec" intent; surface examples + output-path contract retained). Net -3.
- Validation Before Save: replaced "`Edit` is excluded from this skill's tools" / "it has its own tools" with a design-intent rationale (validate-then-write once; caller owns repair). Fixed in lockstep with prd/tdd.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 1 trim), Skill Design Quality (factual accuracy), Coherence (ux-spec↔design-review↔design-qa lifecycle verified; doc-authoring family), Actionability, Completeness, Orchestration (leaf), Spec Alignment, Rename.

### Rename
No rename — ux-spec (authoring) cleanly distinct from design-review and design-qa.

## 2026-05-28

### Summary
Closed a §9 Handoff Notes coordination gap (operator priority): orthogonalized the two priority axes — (a) is now the sequence axis (P0/P1/P2 for @project-manager ordering), (b) is the MVP cutline as the shared scope boundary @senior-engineer builds to and design-qa QAs against. Removed the duplicate "same concept = same name" rule from Authoring §5 (already stated in §1). Net 0 lines.

### Changes
- §9(a)/(b): split overlapping "P0/P1/P2 or MVP/polish" into sequence axis (a) vs scope cutline (b); named design-qa + @senior-engineer as cutline consumers.
- Authoring §5: dropped duplicate cross-surface naming rule (retained in §1).

### Dimensions Evaluated
Orchestration & Coordination (operator priority), Over-Engineering (HIGHEST — offset the addition), Coherence, Spec Alignment.

### Rename
No rename. Family-aligned with adr/prd/tdd/specs.

## 2026-05-25

### Summary
Phase 2 coherence: removed TYPE substitution note (lockstep) and removed stale "(currently 9 sections)" count from Validation §4 (mirrors tdd fix).

### Changes
- Removed `For this skill, substitute {TYPE} with ux-spec in the usage error.` — Item 1 lockstep.
- Removed stale section-count token from Validation §4 (stale-token risk identical to tdd/prd).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
Five over-engineering trims and one sibling-parity hardening: dropped dead "broader than pre-flight scan" parenthetical (2026-05-06 removed that step), collapsed Mermaid Mandate 4× "mandatory" restatement, hardened tdd reciprocal route to mirror tdd's prescriptiveness, trimmed Authoring §3 N/A allowance to one example, removed third repetition of orchestration prohibitions in SAVE_AND_RETURN. Net -6 lines.

### Changes
- Authoring §1: dropped dead "broader than the pre-flight scan" parenthetical (2026-05-06 removed Pre-flight step 5); folded dir list into Grep command.
- Mermaid Mandate: collapsed 4× "mandatory" restatements to 1×; removed override-comparison clause.
- When NOT to Use → tdd route: hardened to mirror tdd's reciprocal "interaction-design portions belong in UX spec" prescriptiveness.
- Authoring §3 N/A allowance: collapsed three example surface×section pairs to one.
- SAVE_AND_RETURN: dropped third repetition of orchestration prohibitions (CRITICAL banner + allowed-tools exclusion already cover it).

### Dimensions Evaluated
Over-Engineering (HIGHEST — 4 trims), Coherence (sibling tdd parity), Spec Alignment, Skill Design Quality.

### Rename
No rename. Family-aligned with adr/prd/tdd.

## 2026-05-18

### Summary
Surfaced the calling agent's Design Output Tiers gating directly in `When NOT to Use` — adds an explicit "skip to lighter tier" route for internal-only surfaces, single-tier design fits, and Tier 1–3 work. Addresses the 30-day adoption-gap finding (0 invocations) by making the skip path explicit at the point of decision.

### Changes
- When NOT to Use: added skip-to-lighter-tier delegation row before the design-review row. References `agents/ux-designer.md` Responsibility 1 Tiers 1–3 as the authority for lighter alternatives.

### Dimensions Evaluated
Completeness (skip-path documentation), Coherence (sibling family parity preserved), Skill Design Quality.

### Rename
No rename.

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
