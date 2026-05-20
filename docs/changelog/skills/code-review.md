# Changelog: code-review

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
