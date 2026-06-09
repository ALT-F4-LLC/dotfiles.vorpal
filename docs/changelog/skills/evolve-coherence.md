# Changelog: evolve-coherence

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
