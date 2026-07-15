# Changelog: brief

## 2026-07-14

### Summary
Added a pre-emit self-check for verbatim citations (I42) and restored the Docket-issue-by-ID fallback that a prior edit silently dropped. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: verbatim citations now get a pre-emit `Grep`-tool self-check (search cited file for the quoted line as a fixed string; mark "unverified quote — source drifted" on a miss) — protects the re-verification trust property team-lead's Pre-flight HARD GATE consumes (I42; tool-corrected from the finding's `grep -F` since brief has no Bash)
- AMPLIFY[SUBSTANTIVE]: restored Docket-issue-by-ID fallback (paste-or-placeholder, no fetch) — content documented as added 2026-06-30 was absent from the live file, re-exposing the documented permission-gate stall

### Dimensions Evaluated
Actionability/Completeness (primary, extra pass given ~115x/week leverage), Coherence (changelog↔file regression). Over-Engineering: lean 68-line file, no cull candidate with a fitness signal.

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Bare-word trigger replaced with a self-scoping phrase. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: trigger "brief" → "brief this request" — the bare token fires on summary requests ("brief me on X") unrelated to intake standardization; misfires are costly given the skill's do-not-execute-$ARGUMENTS contract

### Dimensions Evaluated
Disambiguation (confusable-name).

### Rename
No rename.

## 2026-07-12

### Summary
Hardened three corroborated intake gaps (from heavy 104-invocation usage this window) and repointed the docs-path citation to the maintained master. Fixed a run-together typo along the way. Findings: 4 → 4 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: verbatim-citation directive now carries a source locator (file/§/line or vote ID) so team-lead/PM can re-verify rather than trust the brief's word (project-manager pitfalls); fixed run-together typo "accepted.This"
- AMPLIFY[SUBSTANTIVE]: added the light-scoping-vs-performing-the-investigation boundary for read-only tools (team-lead pitfalls; preventive — the documented incident was team-lead itself, not brief, but this is the first place the temptation arises)
- AMPLIFY[SUBSTANTIVE]: cross-cutting "find all references" briefs must frame Scope/AC as an independent repo-root re-sweep, not a fixed site list (recurred twice in one cycle — team-lead + project-manager pitfalls)
- AMPLIFY[SUBSTANTIVE]: docs-path citation repointed from team-lead.md's relocated LOCAL pointer to the maintained master `team-doctrine/references/docs-paths.md` (verified)

### Dimensions Evaluated
Actionability (primary — 3 corroborated intake gaps), Coherence (docs-path master), Skill Design Quality. Over-Engineering: kept each addition to one compact sentence; lean high-usage skill, ample headroom remains.

### Rename
No rename.

## 2026-07-10

### Summary
Escaped two unescaped `$ARGUMENTS` in banner clause (3) so `/brief` renders literal token references instead of inlining the request. Rethink (read-only `docket issue show` Bash grant) evaluated and declined — reverses 2026-06-30 operator resolution, breaks zero-execution invariant. Net +2.

### Changes
- Coherence/Content-Gate: banner `$ARGUMENTS` → `\$ARGUMENTS` (both occurrences), matching body. Brief-unique banner content; no family parity impact (verified no sibling shares this clause).
- DECLINED: `Bash(docket issue show:*)` grant — reversal of the deliberate 2026-06-30 paste-workaround; $ARGUMENTS→shell injection surface; prior cycles rejected Bash-injection twice.

### Dimensions Evaluated
All 8. Over-Engineering primary — no CULL candidate with a cited fitness signal; brief remains lean/healthy.

### Rename
No rename.

## 2026-06-30

### Summary
Amplified Docket/artifact context handling and culled structured-request skip, net -1.

### Changes
- AMPLIFY: add Source context/Unavailable context and deterministic Docket-ID fallback.
- CULL: remove already-structured carve-out.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Added an explicit fallback for Docket-issue references so brief stops stalling against the permission gate. Inline (net 0, stays 65). brief→sonnet routing trial declined by operator.

### Changes
- AMPLIFY: when the request references a Docket issue by ID, brief no longer attempts disallowed `Bash`/`docket` fetches (retrying variants stalls the intake) — it asks the operator to paste the body or emits a bare-ID placeholder Goal flagging the body unavailable. Cited HISTORICAL stall (agentic-services, 2026-06-30; operator had to manually interrupt).

### Dimensions Evaluated
All 8. Over-Engineering: inline append, net 0. disallowed-tools frontmatter preserved; no model/routing/drift change. Phase-2 deferrals: tagged-fence emission (brief↔team-lead gate coordination); `$ARGUMENTS`-escaping family convention pass.

### Rename
No rename.

## 2026-06-20

### Summary
Defense-in-depth + double-invocation fix; net 0 (stays 65). BANNER deferred to Phase 2 (parity).

### Changes
- AMPLIFY: added `disallowed-tools: Edit, Write, Bash, Agent, SendMessage` frontmatter — per-turn mechanical enforcement atop the BANNER prose (Phase-0 innovation signal; brief is a pure transform that must never execute).
- AMPLIFY: strengthened the terminal HALT signal — cited Phase-0 double-invocation signal (operator re-ran /brief when the first done-state was ambiguous).
- CULL: removed the derivable "mid-cycle scope change" When-NOT-to-use bullet (over-engineering; offsets the +1).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Added a cite-source directive for requests that reference an accepted artifact, closing the brief↔TDD paraphrase-drift gap.

### Changes
- AMPLIFY ("What a good brief is"): when a request points to an accepted artifact (TDD/spec/ADR/vote) that fixes a field's value, cite the source line verbatim rather than paraphrase. Signal: hermes team-lead pitfall — paraphrased D-table values diverged from the voted TDD. Net +1.
- Drift (rate 7): all SKIP — D0/D1 parity-bound to team-lead Pattern Decision Tree; D2–D6 headers/already-concrete.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-17

### Summary
Added `allowed-tools` frontmatter (was absent — brief inherited ALL tools, contradicting its read-only leaf banner). Trial: allowed-tools scoping → adopted.

### Changes
- AMPLIFY: declared `allowed-tools: Read, Grep, Glob, AskUserQuestion` — brief is read-only intake (writes no files, spawns nothing per its banner), so Write/Edit/Agent/Bash are removed from its pool.

### Dimensions Evaluated
Skill Design Quality (AMPLIFY — frontmatter completeness), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
No changes. Zero correction signals across 17 operator invocations (heaviest-used skill this window). Both Phase 0 signals rejected on ground truth.

### Changes
- None (NO-OP verdict). Output-channel SendMessage instruction is a false positive (CANONICAL:BANNER delegates relay to the calling agent; adding it would contradict the banner). Backtick git-status injection rejected as over-engineering (sandbox caveat; prior cycle rejected similar).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, all load-bearing); Coherence (banner tail byte-parity with leaf family confirmed); evolve-coherence leaf-family enumeration lag flagged to Phase 2.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes. Zero correction signals in 15-18 operator invocations; all 8 dimensions pass. Innovation suggestion (machine-parseable trailer) rejected as over-engineering — the existing `Field: value` block is already machine-parseable; a redundant fenced trailer adds 7-10 lines for no functional gain.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, lean — field-semantics prose load-bearing); Coherence (team-lead Pre-flight HARD GATE and docs-path taxonomy checks confirmed current); Actionability (question-batching rule and field semantics remain precise).

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Banner-tail divergence signal verified already-fixed (L14 carries the correct leaf tail for brief's skill type); `\$ARGUMENTS` correctly escaped at L19; no-spawn consistency confirmed across frontmatter, banner, and body.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (62 lines, lean — field-semantics prose load-bearing); Coherence (team-lead Pre-flight HARD GATE handoff terminology matches agents/team-lead.md).

### Rename
No rename.

## 2026-06-09

### Summary
Normalized the CANONICAL:BANNER trailing clause to the leaf-family standard, restoring byte-parity under the canonical strip (evolve-coherence 2026-06-09 audit, FINDING 1, operator decision: NORMALIZE).

### Changes
- BANNER tail "The calling agent handles any follow-up after this skill returns." → "The calling agent handles peer messaging after this skill returns." — the canonical strip `sed 's/ The calling agent handles peer messaging.*$//'` anchored on "peer messaging" did not match brief's variant tail, so coherence audits flagged brief as divergent; post-edit all 10 leaf banners strip-normalize to one hash (8cffe6b8). Net lines: 0.

### Dimensions Evaluated
Coherence (manifest-scoped remediation cycle — other dimensions out of scope per operator-approved slice).

### Rename
No rename.

## 2026-06-09

### Summary
Live-test defect fix: brief recommended a taxonomy-violating route with "(Recommended)" confidence (standalone creation of docs/spec/security.md, a reserved init-specs-owned name). Added a docs-path ownership check to the question-construction guidance.

### Changes
- Resolving underdetermined fields: options creating/routing writes to docs/ paths must check the owning writer (team-lead.md §Docs-Path Taxonomy) before being marked Recommended — brief writes no files, but its routing recommendations steer who writes where.

### Dimensions Evaluated
Coherence (docs-path taxonomy), Actionability (recommendation quality). Found via first live invocation, 2026-06-09.

### Rename
No rename.

## 2026-06-09

### Summary
New leaf skill: operator-intake aid that converts a freeform `$ARGUMENTS` request into the standardized brief block team-lead's Pre-flight HARD GATE (step 1) consumes, collapsing goal verification to one confirm. Outcome-oriented body; emits the block and stops, no file writes, no spawns.

### Changes
- Created skills/brief/SKILL.md. Frontmatter: name/description (trigger keywords first) + argument-hint, no effort key (inherits caller), no tool restriction. Body: derive fields from the request, ONE batched AskUserQuestion round for underdetermined routing-relevant fields (Size hint + Security-sensitive prioritized), emit block verbatim. Field semantics mirror team-lead Pre-flight + Pattern Decision Tree.

### Dimensions Evaluated
Coherence (block schema + field semantics aligned to agents/team-lead.md Pre-flight/Decision Tree), Over-Engineering (single round cap, ≤120 lines, no step enumeration). Spec Alignment (docs/spec/ — N/A).

### Rename
No rename (net-new skill).
