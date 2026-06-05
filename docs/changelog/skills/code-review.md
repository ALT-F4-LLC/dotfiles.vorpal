# Changelog: code-review

## 2026-06-05

### Summary
Phase 2 coherence: appended the Doubling-Rule family-parity sentence to the report-emission COUPLING marker (placement already canonical — directly above the When-NOT routes). All 4 family markers now byte-identical.

### Changes
- COUPLING marker: added "The Doubling Rule section is also part of this family — keep its shape in sync across siblings per team-lead Rule 8."

### Dimensions Evaluated
Coherence (report-emission family COUPLING parity with verify-ac/design-qa/design-review).

### Rename
No rename.

## 2026-06-05

### Summary
Trimmed two Doubling-Rule paragraphs (Ephemeral lifecycle + Degraded fallback) that restated team-lead-owned spawn/shutdown/degraded-annotation mechanics verbatim, replacing them with a single calling-layer-ownership pointer to agents/team-lead.md (Rule 8, step 14) — matches the verify-ac family consolidation and removes a duplicated-state drift hazard. Net -2 (401/500).

### Changes
- Doubling Rule: collapsed Ephemeral-lifecycle + Degraded-fallback paragraphs to one team-lead.md ownership pointer; load-bearing single-reviewer-authority fact + 4-parallel topology retained in the opening paragraph.

### Dimensions Evaluated
Over-Engineering (HIGHEST — duplicated team-lead mechanics removed), Coherence (verify-ac family-pattern alignment; drift hazard eliminated). NO-OP verified: $-escape, mid-cycle/partial-tree guard (already encoded), docs/spec tolerance, effort:max, disallowed-tools (prior decline holds).

### Rename
No rename.

## 2026-06-04

### Summary
Added the Phase 0 partial-tree guard (code-review fired mid-cycle on a partial working tree 2x cross-project → stale review) folded into the empty-diff step; de-duplicated an anti-anchoring rationale to a team-lead.md step-14 pointer. Net +2 (403/500, ample headroom).

### Changes
- Pre-flight empty-diff guard: added a partial-tree guard for `uncommitted`/`staged` scopes — a local diff is a point-in-time snapshot, so the skill prefixes the verdict with a files-present / point-in-time line and routes the completeness judgment to the calling agent (which owns AC context) rather than guessing the expected file-set.
- Save & Return: trimmed the duplicated anti-anchoring rationale to a team-lead.md step-14 pointer (directive retained).

### Dimensions Evaluated
Completeness (HIGHEST — partial-tree guard), Over-Engineering (HIGHEST — anti-anchoring rationale de-duplicated to a pointer; net +2 at 403/500), Coherence (anti-anchoring authority owned by team-lead.md).

### Rename
No rename.

## 2026-05-30

### Summary
Added a finding-sourcing (anti-fabrication) discipline to the Review Procedure — the file had no procedural guard against the cycle's #1 failure class (findings asserted "VERIFIED from real diff" that did not exist in the diff). Corrected the Doubling Rule to the Rule 8 default and trimmed restatement to offset.

### Changes
- Review Procedure: new "Finding-sourcing discipline" paragraph — write each finding only from that file's complete solo-rendered diff this turn; a cancelled/empty batch member means UNVERIFIED, not unchanged; prefer git diff/Read over grep -n; never carry an expected-change guess forward as "verified".
- Doubling Rule: reframed to team-lead.md Rule 8 default-single/opt-up-doubled (was "≥2 per phase" default — an inversion shared with design-qa/design-review); trimmed reconciliation merge-mechanics to a step-14 pointer.
- Degraded fallback: dropped the non-actionable "recurring fallbacks = evolve signal" meta-note.

### Dimensions Evaluated
Completeness + Skill Design (anti-fabrication gate — highest empirical signal), Over-Engineering (HIGHEST — two trims offset the addition), Coherence (Rule 8 default alignment with design-qa/design-review), Actionability, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Fixed a markdown run-on-bullet defect in When-to-Use and repointed it at the authoritative Round-N section; tightened the Save & Return silent-completion paragraph; dropped a redundant Failure Modes row already enforced by Validation check-3.

### Changes
- When to Use: fixed run-on bullet (Re-invocation was jammed onto the prior bullet with no newline); now points at Output Contract → Round-N, de-duping the Round-N section.
- Save & Return: trimmed the triple-stated SendMessage-is-deliverable directive to two sentences; kept the family-wide silent-completion pitfall note.
- Failure Modes: removed the cross-mixed-ladder row (duplicate of Validation check-3, same abort shape; violated the table's "new abort text only" promise).
- Declined `disallowed-tools` (clears-on-next-message risks suppressing the mandated post-skill SendMessage); `/code-review` bundled-skill namespace collision flagged for Phase 2.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 3 trims), Skill Design Quality (run-on defect, disallowed-tools decision), Coherence (Round-N de-dup, Failure Modes/Validation overlap, namespace collision), Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename — highest-volume skill; name accurate, stability load-bearing. The bundled `/code-review` collision is a Phase-2 item.

## 2026-05-28

### Summary
Standardized the multi-file argument grammar (top historical inconsistency — 3 call forms), added a compact Round-N re-review output for the dominant fix→re-review loop (28 sessions), repointed dead `docs/tdd/reviewer-doubling-lifecycle.md` citations to `agents/team-lead.md` Rule 8 / step 14 (verified the file is absent), and fixed stale G1..G4 → G1..G5. Net +1 (additions offset by 2 redundant-block removals).

### Changes
- Argument Handling: path-list normalization (strip `files`/`files:`, split on comma/whitespace) + richer argument-hint — collapses `path path`, `files path path`, `files: path, path` to one grammar.
- Output Contract: compact Round-N re-review format (Prior Findings Disposition / New Findings delta / Recommendation) + Validation check-2 carve-out.
- Coherence: dead doubling-TDD refs → `agents/team-lead.md` Rule 8 + step 14; G1..G4 → G1..G5 (two stale spots).
- Over-Engineering offsets: removed redundant When-to-Use security bullet + Separation-of-writer-and-judge para; tightened Pre-flight docs/spec tolerance.

### Dimensions Evaluated
Skill Design Quality (arg grammar — top), Completeness + Orchestration (Round-N), Coherence (cross-skill dead ref, G-numbering), Over-Engineering (HIGHEST — 2 cuts offset adds), Spec Alignment, Actionability.

### Rename
No rename — highest-volume skill (188 occurrences); name accurate, stability load-bearing.

## 2026-05-25

### Summary
Phase 2 coherence: trimmed AskUserQuestion structural-contract restatement to point at the calling agent's contract (lockstep with design-qa/verify).

### Changes
- Replaced `1-4 questions, each having 2-4 options and a header ≤12 chars` restatement with pointer `per the calling agent's structural contract` (Item 4 lockstep, mirrors design-review's Phase 1 trim).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
Two pitfall-driven additions from highest-usage skill (186 sessions, 208 calls): added explicit silent-completion self-check to Save & Return (staff-engineer pitfall #4 — advisor invokes skill, verdict lands in context, advisor idles without SendMessaging team-lead) and added G5 Hard Gate for unexecuted AC regex (pitfall #5 — TDD AC amendments introduce regex without grep-against-actual-files execution). Net +12 lines.

### Changes
- Save & Return: prepended MUST statement clarifying trailing confirmation line is not the deliverable; SendMessage to calling agent IS the deliverable; added self-check question. Cross-cutting fix — same pattern applied to design-qa; verify/design-review to follow when their reports land.
- Hard Gates: added G5 (unexecuted AC regex) — mechanically detectable defect class where TDD/spec diffs introduce regex without execution against actual target files.
- Output template + Validation Before Emit: extended G1..G4 → G1..G5 in `Hard Gates Triggered` section and validation check 4.

### Dimensions Evaluated
Orchestration & Agent Teams (HIGHEST — silent-completion defect), Completeness (G5 gate), Actionability, Coherence (cross-skill propagation flagged), Over-Engineering (3 narrow edits within 108-line headroom).

### Rename
No rename — highest-volume skill; stability load-bearing.

## 2026-05-20

### Summary
Trimmed redundancies surfaced by historical audit (115 invocations across 12 sessions; 30x/19x/14x re-invocation patterns): removed Pre-flight doubling-rule callout (duplicated in section above), collapsed When-to-Use bullets 2-3 into bullet 1 (covered by Doubling Rule + agent docs), dropped Save & Return catch-all abort-echo line (each abort site emits its own error), and merged Standalone-mode footnote into Degraded-fallback paragraph. Net -6 lines.

### Changes
- Pre-flight: removed redundant `Doubling-rule rationale` blockquote — referenced ~15 lines above in Doubling Rule.
- When to Use: collapsed 4 bullets to 2 — team-lead delegation + parallel security review covered by Doubling Rule + agent docs.
- Save & Return: dropped catch-all "On any abort" sentence — each section specifies its own abort format inline.
- Doubling Rule: merged Standalone-mode footnote into Degraded-fallback paragraph (leaf-skill non-spawning is in CANONICAL banner).

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (sibling-family redundancy), Skill Design Quality.

### Rename
No rename.

## 2026-05-18

### Summary
Added Epistemic Discipline enforcement to Common Discipline + Validation Before Emit (banned-words check propagates the agent-level rule into the review-output surface); removed dead `{today_date}` resolution from Pre-flight §3 (templates never consume it); trimmed Failure Modes intro and Code Quality dimension prose. Net -3 lines.

### Changes
- Common Discipline: added Epistemic Discipline bullet — bans confidence phrases (clearly/obviously/should work/100%/guaranteed) in review findings; requires evidence anchoring.
- Validation Before Emit: added check 9 enforcing the banned-phrase scan so silent slips become defects at emit time.
- Pre-flight §3: dropped `{today_date}` resolution — templates never reference it.
- Failure Modes: collapsed 3-line preamble to one sentence.
- Code Quality dimension: cut essayistic through-line; kept the principle→gate mapping and the senior-engineer.md pointer.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (cross-agent Epistemic Discipline propagation), Actionability, Skill Design Quality, Completeness, Spec Alignment, Orchestration, Rename.

### Rename
No rename.

## 2026-05-17

### Summary
Trimmed 12-principle restatement in Code Quality dimension (skill already pointed to senior-engineer.md as full text); documented R1+R2 re-invocation pattern per historical audit (9 sessions confirmed); fixed Validation Before Emit numbering bug (3a → renumbered 3-8). Net -8 lines.

### Changes
- Code Quality dimension: replaced 12 inline principle paraphrases with brief pointer to senior-engineer.md, naming only the 4 principles that fire hard gates (G1-G4) and listing the other 8 by name. Eliminates dual-maintenance.
- When to Use: added explicit bullet documenting R1+R2 re-invocation pattern (Round-1 PR, Round-2 uncommitted after fix) so reviewers know this is expected, not duplication.
- Validation Before Emit: renumbered 3, 3a, 4, 5, 6, 7 → 3, 4, 5, 6, 7, 8 for clean ordinal sequence.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Orchestration & Agent Teams, Coherence, Skill Design Quality, Actionability, Completeness, Spec Alignment, Rename.

### Rename
No rename — highest-volume skill (125 invocations); stability has compounding value.

## 2026-05-16

### Summary
Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract (added to design-review this cycle); Save & Return collapsed to "Output Contract owns the emission rules" per family-wide pattern.

### Changes
- Common Discipline: added "with 1-4 questions, each having 2-4 options and a `header` ≤12 chars" to the AskUserQuestion guidance — parity with design-review/design-qa/verify.
- Save & Return: replaced verbose preamble with "No file is written (Output Contract owns the emission rules)" — matches verify/design-qa/design-review post-Phase-2.

### Dimensions Evaluated
Coherence (operator-prompt contract; family Save & Return phrasing), Over-Engineering.

### Rename
No rename.

## 2026-05-16

### Summary
Added trailing `Code review emitted ({recommendation}).` confirmation line to align with sibling report-emission family (verify, design-qa, design-review); enforced via Validation Before Emit. Trimmed two Pre-flight/When-NOT redundancies for BALANCED-mode tightening.

### Changes
- Save & Return: added `Code review emitted ({recommendation}).` confirmation line — same deterministic end-of-skill signal that verify/design-qa/design-review emit.
- Validation Before Emit: added check 7 enforcing the new confirmation line so silent omission is a defect.
- Pre-flight §6: collapsed "both roles" scoping parenthetical and removed dangling Grep instruction restating the same scoping rule.
- When NOT to Use: trimmed `Skill(verify, ...)` bullet's redundant editorial sentence.

### Dimensions Evaluated
Coherence (HIGHEST — sibling family parity), Over-Engineering, Skill Design Quality, Actionability.

### Rename
No rename.

## 2026-05-13

### Summary
Four targeted fixes: reordered Pre-flight so empty-diff guard fires before spec-read, scoped design-doc reads to changed-file domains, added escalation path when staff surfaces security specifics with no parallel security reviewer in flight, added Recommendation→Vote Verdict mapping to make review-to-vote handoff deterministic, dropped dead `{role}` placeholder scan.

### Changes
- Pre-flight: moved empty-diff guard ahead of design-doc reads so a no-op review aborts before any Read cost.
- Pre-flight (renumbered): scoped spec-read to changed-file domains only — reviewers were previously instructed to read up to 6 spec files unconditionally.
- Staff playbook dimension 2: explicit Concern + SendMessage handoff when auth/crypto/sandbox specifics surface in a routine review and no parallel `@security-engineer` reviewer is running.
- Save & Return: added Recommendation → Vote Verdict mapping table so escalating to `Skill(vote, ...)` is deterministic; references `--findings-json` for severity-bucket preservation.
- Validation Before Emit: dropped `{role}` from placeholder scan — token is never substituted (role names are hard-coded in role-template H2 banners).

### Dimensions Evaluated
Over-Engineering (HIGHEST — Pre-flight scope cut), Skill Design Quality, Actionability, Coherence (vote skill `--findings-json` path), Orchestration (staff↔security handoff).

### Rename
No rename.

## 2026-05-09

### Summary
Four trim + actionability fixes (operator pain points 1, 3, 4): added scope-detection ambiguity rules (PR-number-not-found fallthrough, branch/file token tie), added a 50-file pre-review escalation hint, tightened Validation Before Emit by referencing the Output Contract instead of restating template structure, and trimmed Failure Modes table to the rows that introduce new abort text (the rest are specified inline upstream).

### Changes
- Argument Handling: added explicit ambiguity rules — `^\d+$` first probes `gh pr view` and falls through to branch/file detection on miss; a single token that is both a valid branch and an existing file is treated as a branch unless multi-token or `./`-prefixed.
- Pre-flight §4: added 50-file escalation hint so the calling agent can recommend Split required before deep review effort is wasted.
- Validation Before Emit: items 1-2 now reference the Output Contract directly instead of restating banner text + section list; eliminates double maintenance.
- Failure Modes: table compressed to the two rows with new abort text (`gh` CLI unavailable, severity-ladder cross-mix); other abort paths are specified at the section that introduces them (Argument Handling, Role Detection, Pre-flight, Validation Before Emit) — table now serves as a quick-reference index, not a duplicate spec.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering (HIGHEST PRIORITY — primary cut), Coherence (sibling skills + parent agents), Spec Alignment (`docs/spec/review-strategy.md`, `docs/spec/security.md`), Operator Prompt Quality, Coordination & Handoff.

### Rename
No rename. Family-aligned with sibling skills; matches operator trigger phrases ("review this PR", "code review", "security review of changes").

## 2026-05-09

### Summary
Tightened role-gating contract by removing invented caller-identifier synonyms; clarified parallel-reviewer reconciliation as the first post-review action for security-sensitive changes; added `review-strategy.md` to staff-engineer's pre-flight reading list to align with the six-dimension model authority.

### Changes
- Role Detection table now lists only the two real caller identifiers (`@staff-engineer`, `@security-engineer`); removed synonyms (`staff-advisor`, `advisor`, `tdd-author`, `reviewer`, `security-advisor`, `security-reviewer`) that do not appear in agent files and risked ambiguous playbook collapse on a future rename.
- Pre-flight step 5 (staff-engineer specs list) adds `review-strategy.md` so reviewers consult the documented Tier 1/2/3 risk-area mapping.
- Save & Return promotes parallel-reviewer reconciliation to the first caller responsibility for security-sensitive scopes; sequencing matters because contradictory verdicts to `@senior-engineer` are the documented coordination failure mode.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Coherence (sibling skills + parent agents), Spec Alignment (`docs/spec/review-strategy.md`, `docs/spec/security.md`), Over-Engineering, Operator Prompt Quality, Coordination & Handoff.

### Rename
No rename.

## 2026-05-09

### Summary
Initial creation. New leaf skill that lets `@staff-engineer` and `@security-engineer` produce role-correct code reviews via a single shared format authority. Removes per-agent format duplication: each agent's Responsibility 2 (Review) now points to `Skill(code-review, "<scope>")` instead of restating dimension lists, severity ladders, and output sections inline. Role detection branches the playbook (6 general dimensions for staff; 9 security dimensions for security) and the severity ladder (Blocker/Concern/Suggestion/Question/Praise vs. Critical/High/Medium/Low/Info) so cross-mixing is a validation defect.

### Changes
- Created `skills/code-review/SKILL.md` with: role detection (restricted to `@staff-engineer` / `@security-engineer`); positional `<scope>` argument resolving to PR number/URL, branch, `uncommitted`, `staged`, or file paths; staff-engineer playbook (6 dimensions, 5-tier severity, full output template); security-engineer playbook (9 dimensions, 5-tier severity, Threat Model + Required Mitigations sections); Validation Before Emit checks for role banner, section presence, severity-ladder discipline, explicit empty buckets, recommendation allow-list, and placeholder scan; Save & Return that emits to context (no file written) and explicitly defers peer SendMessage / vote escalation to the calling agent; Failure Modes covering empty diff, unresolvable scope, missing `gh`, and severity cross-mixing.
- Updated `agents/staff-engineer.md`: added `code-review` to `skills:` frontmatter; replaced the inline `### Review Output Format` block with a one-paragraph pointer to `Skill(code-review, "<scope>")` (mirrors how Responsibility 1 points to `Skill(tdd, "<topic>")`).
- Updated `agents/security-engineer.md`: added `code-review` to `skills:` frontmatter; same pointer replacement for the security review section.
- Updated `agents/team-lead.md` spawn templates for `@staff-engineer (Code Review)` and `@security-engineer (Security Review)`: requirement bullets now instruct the spawned reviewer to invoke `Skill(code-review, "uncommitted")` (or pass a different scope) rather than restating the severity ladder and dimension list inline.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Coherence (parity with sibling skills tdd/adr/prd/vote), Spec Alignment (`docs/spec/review-strategy.md` six-dimension model + agent specs' Responsibility 2), Over-Engineering (no file output — review is conversational; leaf skill — no Agent/SendMessage/Skill).

### Rename
No rename.
