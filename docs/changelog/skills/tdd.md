# Changelog: tdd

## 2026-05-25

### Summary
Phase 2 coherence: removed TYPE substitution note (lockstep with prd/adr/ux-spec) and removed stale "(currently 11 sections)" hardcoded count from Validation §3.

### Changes
- Removed `For this skill, substitute {TYPE} with tdd in the usage error.` — Item 1 lockstep.
- Removed stale section-count token from Validation §3 (mirrors prd's Phase 1 fix; Required Sections list is source of truth).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
No-change verdict. Skill is mature — 186 sessions in 7d with zero operator corrections, 288 LOC under 500 cap, four trim-class entries in last 30 days already addressed coherence/over-engineering. Three historical-audit focus areas (stale-token verification, per-row arithmetic, missing-directory preamble) surfaced @staff-engineer/team-lead pitfalls but are NOT TDD-skill-content gaps — wrong layer (review/verification skills or team-lead spot-check own those defects).

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no remaining slack), Skill Design Quality, Actionability, Completeness, Orchestration, Coherence (sibling parity), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/adr/ux-spec/specs.

## 2026-05-20

### Summary
Added non-blocking near-duplicate-slug probe to Pre-flight (closes gap surfaced by sessions dd8cea9d/962bb9d0 where near-identical args derived to different slugs and silently produced adjacent docs/tdd/ files — exact-match collision dialog can't catch this). Collapsed Authoring §4 Mermaid restatement now that Validation §5 + Failure Modes carry the gate. Renumbered Related-doc probe (was §5, now §6). Net +1 line.

### Changes
- Pre-flight: added §5 near-duplicate probe (advisory `Glob docs/tdd/{slug[:12]}*.md`, non-blocking note to calling agent).
- Pre-flight: renumbered existing §5 "Related-doc probe" → §6; Authoring §1 cross-reference "Pre-flight step 5" → "step 6".
- Authoring §4 Mermaid clause: trimmed restatement of Validation §5 + ADR routing (load-bearing gates live elsewhere).

### Dimensions Evaluated
Completeness (HIGHEST — near-duplicate slug gap from historical audit), Over-Engineering.

### Rename
No rename.

## 2026-05-18

### Summary
Three trim-class fixes: collapsed §4 security-track prose bloat that duplicated agents/security-engineer.md Threat-Model Annotation mechanics (skill keeps the validation contract; agent owns routing), condensed the maturity/status orthogonality rationale to its load-bearing fact, and removed the defect-restatement in Authoring §3 now that Validation §3 is the gate. Net -19.

### Changes
- Required Sections §4: trimmed 14-line security-track paragraph to the validation rule the skill enforces; routing of mixed-scope Threat-Model Annotation deferred to `agents/security-engineer.md`.
- Field rules §`maturity`: condensed 5-line ladder-rationale paragraph to the orthogonality fact.
- Authoring §3: removed defect-restatement now redundant with Validation §3; forward-pointer retained.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (security-engineer.md routing ownership), Skill Design Quality.

### Rename
No rename.

## 2026-05-16

### Summary
Three coherence/over-engineering fixes: clarified §4 security-track prose to name the Threat-Model Annotation mechanism (append via Edit to the saved TDD, not re-invoke this skill); added defer-down clause to "When NOT to Use" so TDDs touching user-facing surfaces reference the UX spec rather than inline interaction design; removed the vestigial one-line "Mermaid Mandate" subsection.

### Changes
- Required Sections §4: replaced ambiguous "co-author" prose with explicit Threat-Model Annotation mechanism — @security-engineer appends sections via Edit, not by re-invoking this skill (which would hit the collision dialog).
- When NOT to Use (ux-spec route): added clause directing TDDs that touch user-facing surfaces to reference, not restate, the UX spec.
- Removed standalone "### Mermaid Mandate" subsection — vestigial restatement; rule lives in Authoring §4, Validation §5, and Failure Modes.

### Dimensions Evaluated
Coherence (security-engineer.md Threat-Model Annotation; ux-spec defer-down), Over-Engineering (Mermaid restatement collapse), Skill Design Quality.

### Rename
No rename. Family-aligned with prd/adr/ux-spec.

## 2026-05-13

### Summary
Coherence/Completeness fix: tightened §4 security-gating prose to match what Validation §7 actually enforces, and surfaced the co-author handoff path for mixed @staff-engineer/@security-engineer TDDs per security-engineer.md Responsibility 1. The prior prose mandated three subsections for any auth/secrets/sandbox-touching design, but Validation only checked `updated_by == @security-engineer`, creating an unenforced "should".

### Changes
- Required Sections §4: narrowed the prose mandate to `updated_by: @security-engineer` (matches Validation §7) and added explicit pointer to the team-lead co-author handoff in `agents/security-engineer.md` for mixed-scope TDDs.

### Dimensions Evaluated
Coherence (security-engineer.md co-author model; own Validation §7/§8), Completeness, Skill Design Quality, Orchestration.

### Rename
No rename.

## 2026-05-09

### Summary
Four handoff + actionability fixes (operator pain points 1, 3): added UX-spec input probe to mirror PRD probing, sharpened Implementation Phases §11 with the 6 PM-decomposable fields, encoded the security-track Abuse Cases contract in Testing Strategy §9 (mirrors security-engineer.md:142), and trimmed Authoring §3 redundancy with Validation §3.

### Changes
- Pre-flight §5: renamed "Parent-PRD probe" to "Related-doc probe" and extended Glob to `docs/spec/*.md docs/ux/*.md` so TDDs touching user-facing surfaces consume existing UX specs as input dependencies (closes asymmetry with prd's Authoring §1).
- Authoring §1: now reads candidate parent PRD OR UX spec from Pre-flight step 5.
- Required Sections §11 (Implementation Phases): expanded to specify the 6 fields the planner consumes directly (goal, file scope, acceptance, effort estimate, blocking dependencies, out-of-scope flags). Phases must be independently shippable or explicitly chained.
- Required Sections §9 (Testing Strategy): added security-track Abuse Cases subsection contract gated on `updated_by: @security-engineer` (mirrors security-engineer.md:142 mandate).
- Validation Before Save §8: enforces Abuse Cases subsection for security TDDs.
- Failure Modes table: new row for the Abuse Cases validation failure.
- Authoring §3: trimmed redundancy with Validation §3 ("Every section listed MUST appear, in the order shown" was duplicated); kept the "may be N/A" guidance and added a forward-pointer to Validation §3 as the enforcement gate.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration (leaf — verified no sub-agent surface), Coherence (sibling prd / adr / ux-spec; security-engineer.md, ux-designer.md), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/adr/ux-spec.

## 2026-05-09

### Summary
Coordination & Handoff fix: encoded the Threat Model / Trust Boundaries / Security Considerations subsection contract for security TDDs (security-engineer.md declares them mandatory but the format authority did not enforce them). Two minor trims — collapsed Mermaid Mandate triple-restatement vestige; tightened Pre-flight §5 Parent-PRD probe from advisory note into a deterministic substring rule. Hardened Validation §3 against off-by-one drift as the section list grows.

### Changes
- Required Sections §4: added security-track subsection contract (Threat Model, Trust Boundaries, Security Considerations) gated on `updated_by: @security-engineer` or trust-boundary-crossing designs.
- Validation Before Save: added §7 enforcing the security-track subsections; added Failure Mode row.
- Mermaid Mandate subsection: collapsed to 1 line + ADR-routing pointer (already enforced in Authoring §4 + Validation §5).
- Validation §3: replaced hardcoded "11" with self-referential "all top-level sections enumerated above (currently 11)" to surface drift.
- Pre-flight §5 Parent-PRD probe: tightened from advisory glob-and-judge into deterministic substring-match rule.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence (security-engineer cross-reference, sibling family symmetry), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with adr/prd/ux-spec.

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
Two coherence/over-engineering trims (net 273→269): removed pure-policy TDD escape hatch (delegated to ADR — eliminates scope-overlap with `Skill(adr)` for single-decision artifacts) and collapsed Authoring §8 Self-check into a pointer at Validation Before Save (matches PRD's §6 framing).

### Changes
- Authoring §4 Mermaid clause: dropped pure-policy override; TDDs now always require ≥1 Mermaid block. Pure-policy decisions ("use SemVer", naming conventions) route to `Skill(adr)` per existing "When NOT to Use" delegation
- Mermaid Mandate subsection: rephrased to "always require"; removed pure-policy override sentence; added explicit ADR-route hint
- Validation Before Save §5: removed "OR a pure-policy override note" disjunct
- Failure Modes table: collapsed Mermaid mandate row to single trigger; updated abort message to point to ADR for policy decisions
- Authoring §8: collapsed redundant alternatives self-check (already enforced by Validation §4) into a pointer at Validation Before Save — symmetric with PRD's §6

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence (ADR/TDD scope-overlap), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with adr/prd/ux-spec.

## 2026-05-07

### Summary
Phase 2 coherence: fixed stale H1 prefix to align with `name: tdd` after `create-` prefix was dropped. Symmetric to the vote H1 fix.

### Changes
- H1 changed from `# Create TDD — ...` to `# TDD — ...` to match frontmatter `name:` field

### Dimensions Evaluated
Coherence.

### Rename
No rename.

## 2026-05-06

### Summary
Coherence fix: replaced stale `dev` skill reference with team-lead orchestrator in "When to Use" §3. The `dev` skill was deleted in commit 01b6d0c when the team-lead orchestrator took over its responsibilities; the cross-reference was left behind. Net +0.

### Changes
- "When to Use" §3: "The `dev` skill's Medium Task pattern" → "The team-lead orchestrator's Medium Task pattern" — matches current orchestration model

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
**Rename: `create-tdd` → `tdd`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-tdd` → `/tdd`, all cross-references updated.

### Changes
- Directory renamed `skills/create-tdd/` → `skills/tdd/`
- Frontmatter `name: create-tdd` → `name: tdd`
- Cross-references updated in: sibling skills (`prd`, `adr`, `ux-spec`, `specs`), `agents/staff-engineer.md`, `agents/team-lead.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Changelog file moved: `docs/changelog/skills/create-tdd.md` → `tdd.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-tdd` → `tdd` per operator request.

## 2026-05-06

### Summary
Phase 2 coherence: added create-* family COUPLING comment, collapsed Mermaid Mandate triple-restatement, clarified maturity-vs-status rationale.

### Changes
- Added COUPLING comment to "When NOT to Use" section listing the 4 sibling create-* skills (mirroring create-prd's RESERVED-NAMES marker) — prevents asymmetric drift.
- Mermaid Mandate dedicated subsection: 14 lines → 4; rule lives in Authoring §4 and Validation Before Save.
- Field rules: added one-paragraph note explaining why TDDs carry BOTH `maturity` and `status` while PRDs/UX specs use only `maturity` and ADRs use only `status` — locks the orthogonal-ladder design intent into the file. Phase 1 reviewer's CHANGE 2 (drop maturity) deferred with rationale.

### Dimensions Evaluated
Coherence (cross-skill family symmetry), Over-Engineering (triple-restatement trim), Skill Design Quality (frontmatter contract clarity).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1: collapsed over-engineered Parent-PRD probe (30-line keyword-split + AskUserQuestion) into a single Glob-and-judge step; tightened Validation §4 alternatives heuristic; cleaned up orphaned references to the now-removed missing-parent prompt. Net 311→~285.

### Changes
- Pre-flight §5 Parent-PRD probe: replaced multi-step keyword-split + stopword + per-keyword-glob + zero-result AskUserQuestion procedure with a single Glob-and-note step. Reason: calling-agent judgment is authoritative; the ceremony added no signal beyond "look in docs/spec/".
- Validation §4: removed brittle `### Alt` prefix heuristic; kept the concrete "two `###`-level subsections" rule. Natural alternatives may use `### Option A`, `### In-process worker`, etc.
- SAVE_AND_RETURN: trimmed orphaned "or missing-parent prompt" phrase from the Cancel handler (parallel cleanup to the prior 2026-05-06 entries in create-prd / create-ux-spec / create-adr).
- Failure Modes table: removed orphaned "Parent-PRD probe finds zero results" row (the missing-parent AskUserQuestion no longer exists).
- DEFERRED to Phase 2: reviewer's CHANGE 2 (drop `maturity` frontmatter) — coherence-reviewer must reconcile against create-prd (uses `maturity` only) and create-adr (uses `status` only) before unifying.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename. Family-aligned with create-adr/create-prd/create-ux-spec.

## 2026-05-06

### Summary
First changelog entry. Four fixes: removed stale "TDD §4.3" cross-reference, clarified pure-policy Mermaid override location, collapsed redundant Self-check, removed trailing path restatement. Net 317→311.

### Changes
- Frontmatter field rules: removed unverifiable "see TDD §4.3" cross-reference (this skill is itself the format authority)
- Authoring §4 Mermaid clause: override note now belongs in the drafted Architecture & System Design section, not in the skill's own §4 — eliminates instruction-target ambiguity
- Authoring §8 Self-check: collapsed duplicative checklist into one-line pointer (Validation Before Save is the load-bearing gate)
- Removed redundant `{output_dir}` / `{output_path}` restatement after canonical SAVE_AND_RETURN block (already specified in Pre-flight §2)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename

### Rename
No rename. Family-aligned with create-adr/create-prd/create-ux-spec.
