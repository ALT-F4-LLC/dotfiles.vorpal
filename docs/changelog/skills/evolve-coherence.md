# Changelog: evolve-coherence

## 2026-06-10

### Summary
Full-cycle audit: NO changes (327 lines). All three Phase-0 pitfall focus areas re-verified NO-OP: leaf-family enumeration current (10 carriers incl. brief — exact grep match); section ordering correct (H1 → primacy banner → EVOLUTION-MODEL → Innovation Mandate); redundant-TaskUpdate guidance correctly absent (orchestrator-owned, belongs in team-lead.md — routed out of scope).

### Changes
- None (NO-OP verdict). D4 #2 invariant↔seed redundancy re-evaluated and RETAINED (protective empty-collapse guard; no cited failure signal).

### Dimensions Evaluated
All 8; Over-Engineering primary; Coherence (BANNER 8b897fe4 + EVOLUTION-MODEL e9ef8d09 byte-identical across all 3 evolve-* carriers; $-escape clean); Spec Alignment (symlink claim grounded in src/user.rs:492).

### Rename
No rename.

## 2026-06-10

### Summary
Introduced evolutionary-theory core: CANONICAL:EVOLUTION-MODEL block carrying the full shared vocabulary, with evolve-coherence explicitly reframed as the **reproductive-isolation monitor** — it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits. D4 CANONICAL:EVOLUTION-MODEL parity check formalized as single-family byte-identical across all three evolve-* carriers (hash e9ef8d09). Innovation Mandate updated to scope evolve-coherence's audit role over sibling innovation-mandate sections.

### Changes
- CANONICAL:EVOLUTION-MODEL block added (Phase A); byte-identical across all three evolve-* carriers.
- Skill identity reframed: evolve-coherence is the reproductive-isolation monitor, not a reproducing organism; never edits or applies selection.
- D4 #2 rubric updated to declare EVOLUTION-MODEL as single-family byte-identical across evolve-agents + evolve-skills + evolve-coherence.
- Innovation Mandate scoped to auditing sibling innovation-mandate sections for completeness and terminology consistency.

### Dimensions Evaluated
Coherence (EVOLUTION-MODEL family parity, D4 0 Blockers; No-Edit Guard consistency with reproductive-isolation framing); Completeness (D4 rubric coverage of new CANONICAL tag).

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes (323 lines). "Operator typed /evolve-coherence, no Skill invocation captured" signal resolved as benign — fast report-and-route exit or scope-gate abort fully explains it; execution path verified sound. BANNER byte-parity with evolve-agents/evolve-skills confirmed.

### Changes
- None (NO-OP verdict). D4 baseline-hash incrementalism and rubric-pinning deferred to Phase 2/operator as budget-positive additions needing paired trims.

### Dimensions Evaluated
All 8; Over-Engineering primary; Coherence ($-escape clean, tool pool consistent with No-Edit Guard); Orchestration (Pre-flight HARD GATEs verified present).

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 fix: escaped documentary `\$ARGUMENTS` at L48 ("Parse … per Argument Handling" — orchestrator-instruction prose, not a shell command). The prior entry's "intentional live substitution" rationale is refuted by this cycle's empirical evidence that substitution occurs inside backticks and renders empty in no-arg mode. L33 already escaped. Net 0 (323 lines).

### Changes
- L48: backticked `$ARGUMENTS` → `\$ARGUMENTS`.

### Dimensions Evaluated
Skill Design Quality (arg-escape); Coherence (family-wide documentary-escape ruling).

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Both Phase-0 signals verified NO-OP via fresh grep: primacy banner correctly ordered (H1 L19 → REPORT+ROUTE banner L23 → Innovation Mandate L25); leaf-family rubric enumeration complete (10 carriers incl. brief, exact match to banner-scoped ground truth).

### Changes
- None (NO-OP verdict). Note for future cycles: `effort: xhigh` is lockstep-shared across all three evolve-* skills.

### Dimensions Evaluated
All 8; Over-Engineering primary (dense but load-bearing); $-escape audit clean (L33 escaped documentary, L48 intentional live substitution).

### Rename
No rename.

## 2026-06-09

### Summary
Added brief to the D4 leaf-family BANNER enumeration — the 2026-06-09 audit found brief is a genuine leaf carrier omitted from the rubric list (FINDING 1, facet b).

### Changes
- D4 #2 leaf-family enumeration now reads "…verify-ac, simplify-scout, brief" so future audits hash brief within the leaf family instead of discovering it ad hoc. Paired with normalizing brief's banner tail (see brief changelog). Net lines: 0.

### Dimensions Evaluated
Coherence (manifest-scoped remediation cycle — other dimensions out of scope per operator-approved slice).

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: D3 stale-name pair code-review→code-review-verdict added; review-and-comment banner carve-out whitelisted in D4; rename reference updates.

### Changes
- D3 invariant 1 + detection seed now cover the code-review→code-review-verdict pair with token-boundary grep (mirrors verify→verify-ac encoding).
- D4 #2 + Phase 1 template whitelist review-and-comment's intentionally non-CANONICAL banner.
- 11 refs updated for the rename (incl. XREF schema examples).

### Dimensions Evaluated
Coherence, Completeness (D3/D4 whitelist accuracy).

### Rename
No rename (audits the renamed code-review-verdict).

## 2026-06-09

### Summary
Closed the spawn-template rubric handoff gap: Phase 0/1 teammate prompts referenced "the rubric" without a path, but spawned teammates never receive the SKILL.md — added an explicit Read instruction for `.claude/skills/evolve-coherence/SKILL.md` §The Coherence Rubric to both templates. Escaped the documentary `\$ARGUMENTS` at L29. Net 0.

### Changes
- Phase 0 + Phase 1 templates: within-line addition of "Read .claude/skills/evolve-coherence/SKILL.md §The Coherence Rubric — NOT in this prompt".
- L29: `$ARGUMENTS` → `\$ARGUMENTS` so the Argument Handling prose stays literal (no-arg invocations previously rendered empty backticks); the live substitution at L44 retained.

### Dimensions Evaluated
Actionability (HIGHEST impact — teammate prompts must be self-sufficient); Skill Design Quality (arg escape); Coherence (re-verified ALL rubric ground-truth claims against today's modified agents/*.md — zero drift). All 8 reviewed; Over-Engineering trims rejected (protective redundancy on the empty-hash guard).

### Rename
No rename.

## 2026-06-08

### Summary
Replaced the stale hardcoded line number `staff-engineer.md:103` (3 occurrences: D2 #4 invariant, D2 detection seed, Phase-1 spawn template) — content drifted to line 112 in the c10195b docs-path refactor — with content-anchored references on the unique `Skill(verify-ac)` rule-body token. Aligns D2 references with the skill's own D4 #1 anti-line-number principle. Net 0.

### Changes
- L82 / L88 / L277: swapped `:103` for a content anchor ("the sole `Skill(verify-ac)` token in `agents/staff-engineer.md`"); verified exactly 1 occurrence (now line 112), excluded-FALSE-Blocker classification unchanged.

### Dimensions Evaluated
Coherence (HIGHEST — accurate references + self-consistency with D4 #1); Over-Engineering (net 0, no additions; rubric density load-bearing). All 8 reviewed; rest sound.

### Rename
No rename.

## 2026-06-05

### Summary
Removed the standalone "Whitelist of intentional variants" rubric section — a redundant restatement of carve-outs already stated inline per dimension (each with a `(D<n> #<m>)` back-pointer) and re-enumerated in the Phase 1 spawn template's `## Task` (bullets 1-8), with bullet 9's full substance inline at D3 #7 (invariant L99 + detection seed L108). Replaced with a 1-line pointer to the two live sources. Net -10 (332→322).

### Changes
- Deleted `### Whitelist of intentional variants` (9 bullets): verified each carve-out is preserved inline in its origin dimension and (1-8) in the line-290 template before removal; left a 1-line pointer so a future editor doesn't re-add it as "lost".

### Dimensions Evaluated
Over-Engineering (HIGHEST — pure restatement removed), Coherence (internal non-redundancy; own CANONICAL:BANNER re-confirmed byte-identical to evolve-agents/evolve-skills; report-and-route discipline intact, no self-invoke). All 8 reviewed; rest sound.

### Rename
No rename.

## 2026-06-04

### Summary
First evolve cycle. Hardened the central never-edits contract structurally: removed Edit/Write from `allowed-tools` and added `disallowed-tools: ["Edit","Write"]`, matching the report-only sibling skills. Resolved the self-contradiction where the No-Edit Guard claimed Edit/Write bookkeeping while Data Models § says all artifacts are in-context. Net +1.

### Changes
- Frontmatter: dropped Edit/Write from `allowed-tools`; added `disallowed-tools: ["Edit","Write"]` (verified real per code.claude.com/docs; clears per operator message — defense-in-depth atop the prose No-Edit Guard, not a replacement).
- No-Edit Guard: rewrote the two stale sentences — artifacts are in-context (never written to disk), bookkeeping uses TaskCreate/TaskUpdate; Edit/Write now hard-removed via disallowed-tools. (Orchestrator self-corrected the middle sentence the reviewer's wording left stale.)

### Dimensions Evaluated
Skill Design Quality + Over-Engineering (HIGHEST — removed a self-contradiction, net +1 at ~333/500); Coherence (report-only sibling parity, internal Data-Models consistency).

### Rename
No rename.
