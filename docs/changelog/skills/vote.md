# Changelog: vote

## 2026-06-09

### Summary
Compacted 28 entries (2026-03-19..2026-05-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 28 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Third same-day re-verify, zero drift: NO changes. docket vote CLI zero-drift (all 6 subcommands --help-checked); silent-idle/verdict-capture hardening present (L168/L255); sizing-table parity with team-lead.md L282; delegation contract canonical and coherent across verify-ac/design-review/code-review-verdict callers.

### Changes
- None (NO-OP verdict). `vote list -s` adoption rejected (fails Content Gate — non-behavioral).

### Dimensions Evaluated
All 8; Over-Engineering primary (stable trimmed floor); Coherence (CLI + caller-contract verified).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. The cross-repo silent-idle-reviewer signal RE-VERIFIED (prior cycle's NO-OP justification was wrong about the mechanism, but the skill is correctly hardened): verdict capture is ground-truth docket (`docket vote cast` by coordinator, `docket vote result --json` read; L168/L255 mandate SendMessage delivery, "plain final-turn text is NOT visible"). Cast flags match the verified CLI surface exactly. Reasoning-echo clean; recall-filter clean; $ARGUMENTS at L27 is a documented shell command, not a template token.

### Changes
- None (NO-OP verdict, mechanism re-verified against live file + CLI audit).

### Dimensions Evaluated
All 8; verdict-capture hardening re-verified (do-not-trust-prior-NO-OP applied).

### Rename
No rename.

## 2026-06-09

### Summary
Closed the verdict-delivery channel defect (agentic-services pitfall: 4 reviewers idle, zero verdicts): reviewers are teammates, so plain final-turn text never reaches the coordinator — the template now mandates SendMessage delivery, Phase 2 parses SendMessage payloads (not Agent()-returns), and failure handling treats idle-without-delivery as a failed reviewer. Corrects the 2026-06-08 NO-OP, which cited the dead Agent()-return channel as enforcement. Net −1 (335→334).

### Changes
- Reviewer Prompt Template: added MANDATORY Delivery section (SendMessage full review to team-lead; un-sent review = failed review; then shutdown_request).
- Phase 2: retrieval channel corrected to SendMessage-only; "empty returns" → "idling without a SendMessage'd review".
- Coherence: reviewers deliver, coordinator casts (matches coordinator-casts architecture).
- Offsets: uniqueness restatement (−1), Pre-flight step 1 + proposer-exclusion compression (−3), Findings-JSON note trimmed; template outer fence → 4 backticks (nesting fix).

### Dimensions Evaluated
All 8; Orchestration (PRIMARY — teammate envelope vs Agent()-return), Over-Engineering (HIGHEST), Coherence (CLI zero-drift re-verified live; team-lead.md sizing-table parity intact). Spec Alignment N/A.

### Rename
No rename.

## 2026-06-08

### Summary
Phase 1 no-change verdict (335 lines). Re-verified docket vote CLI live (cast/result/commit/show/create signatures exact; no `-t/--title`); delegation relay contract vs team-lead.md:279; voter-count table dual-ownership (low=2/medium=2/high=3/critical=4 base; 4/4/6/8 doubled; cap 8) matches Consensus Integration verbatim. Both Phase 0 focus items NO-OP: silent-idle verdict capture already enforced (coordinator parses Agent()-returns → casts to docket → reads `vote result --json`, lines 173/185-204/276); delegation path already coherent (lines 40-43).

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable redundancy after prior trim cycles), Orchestration (coordinator-casts architecture, not reviewer self-cast), Coherence (CLI zero-drift + delegation contract + voter-table parity).

### Rename
No rename.

## 2026-06-05

### Summary
Closed a proposer-exclusion gap: the staff row matched `created_by` by exact `"tdd-author"`, missing the real variants `tdd-author-{slug}` / `tdd-author-fix-{N}` (per staff-engineer.md) — a re-spawned author could be selected to review its own TDD. Switched to the prefix idiom already used by the impl-/verifier- rows; dropped the fictional `security-tdd-author` token (exists nowhere in agents/). Net 0.

### Changes
- Exclusion table: staff row → `starts with "tdd-author"` (covers `tdd-author-{slug}`, `tdd-author-fix-{N}`); security row dropped the nonexistent `security-tdd-author`.

### Dimensions Evaluated
Coherence + Completeness (PRIMARY — self-review exclusion gap), Over-Engineering (HIGHEST — both Phase 0 memory lessons already covered, NO-OP; no further removable redundancy). CLI zero-drift re-verified.

### Rename
No rename.

## 2026-06-04

### Summary
Closed two Phase 0 memory failure modes directly in the invocation bar: vote-not-recorded-in-docket and altitude-mismatch-escalated-to-vote. Verified CLI zero-drift; confirmed the prior "adoption gap" signal is stale (all flags already used). Net 0.

### Changes
- "When to invoke" bar: clause (b) now requires a factual altitude/phase read before voting on reviewer disagreement; added the explicit invariant that a vote is not "done" until recorded in docket (`docket vote list` must show it).
- Execution Mode Detection: removed a banner-redundant frontmatter parenthetical (offsets the clause-(b) expansion).

### Dimensions Evaluated
Completeness + Coherence (the two guards), Over-Engineering (HIGHEST — banner-redundant trim offsets the in-place expansion; rejected stale CLI/frontmatter additions). Spec Alignment N/A (no docs/spec/).

### Rename
No rename.

## 2026-05-30

### Summary
NO-CHANGE evolve pass. Re-verified all docket vote CLI flags (create/cast/commit/link/unlink/result/show) against `--help`, the delegation relay contract vs team-lead.md, and exclusion-table agent naming vs canonical agent defs. Zero drift; no edits.

### Changes
- None.

### Dimensions Evaluated
All 8 (Over-Engineering HIGHEST). No defects warranting an edit; already trimmed by the 2026-05-28 + 2026-05-29 cycles. Reviewer-count table dual-ownership with team-lead.md confirmed deliberate (not drift) — flagged to Phase 2.

### Rename
No rename.

## 2026-05-29

### Summary
Over-engineering trim on the largest skill: collapsed the doubled reviewer-count table to a count-only annotation (its threshold/constraint columns duplicated the base table verbatim), and reduced the recursive-doubling paragraph to a pointer (the rule is owned by team-lead.md; the coordinator never computes it).

### Changes
- Doubled table (6 lines) → one-line count annotation: low=4/medium=4/high=6/critical=8; thresholds+constraints inherited from the base table; medium reject-cap delta preserved. Net -5.
- Recursive-doubling paragraph → one-line pointer to agents/team-lead.md Consensus Integration (also resolves a base-vs-doubled-table wording discrepancy with team-lead.md). Net -3.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 2 trims), Coherence (doubled-table + recursive-doubling ownership in team-lead.md; CLI zero-drift verified), Skill Design Quality, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename — `vote` matches the `docket vote` CLI subcommand exactly.

## 2026-05-28

### Summary
Phase 2 coherence: repointed two dead `docs/tdd/reviewer-doubling-lifecycle.md` references (the file does not exist) to canonical `agents/team-lead.md`.

### Changes
- Cap-of-8 amendment pointer → `agents/team-lead.md` Rule 8 (reviewer panel sizing).
- Ephemeral vote-reviewer lifecycle "per TDD §4.4" → `agents/team-lead.md` Rule 7 (ephemeral contract).

### Dimensions Evaluated
Coherence (accurate references).

### Rename
No rename.

## 2026-05-28

### Summary
Two coordination fixes at net 0 lines: (1) team-mode delegation finalizes the orphaned `open` proposal on `failed`/timeout; (2) reconciled a crossed shutdown handshake — standalone Cleanup no longer originates `shutdown_request` toward reviewers (which inverted the self-initiated lifecycle), now approves pending requests + `TeamDelete` reaps. CHANGE 2 confirms the specs reviewer's cross-skill flag.

### Changes
- Delegation Protocol step 5: finalize the orphaned proposal on `failed`/timeout before aborting (best-effort `docket vote commit`), mirroring Phase 3 view-change hygiene; no `vote delete` exists.
- Cleanup step 1: approve reviewer self-shutdowns instead of originating `shutdown_request` (fixes the line-90 ↔ line-339 contradiction + aligns with fleet shutdown canon).

### Dimensions Evaluated
Orchestration/handoff (HIGHEST — delegation failure path + crossed handshake), Completeness, Over-Engineering (net 0), Coherence (team-lead.md relay contract + shutdown canon).

### Rename
No rename. Referenced by name across team-lead.md + 6 agent files.

## 2026-05-25

### Summary
Closed team-mode direct-invocation loophole by hoisting delegation gate into the canonical banner (root cause of session 04db218a operator-rejection where agent invoked Skill(vote) directly in team context because Execution Mode Detection gate was buried below the load-time banner). Two minor clarifications: Output Format marks base-vs-doubled table for audit clarity; vote_id detection rule made visually distinct. Net +3 lines.

### Changes
- Canonical banner: added clause 3 forbidding team-mode direct invocation of Skill(vote) — delegation via SendMessage to team-lead is the only team-mode path; standalone /vote remains operator entry. Closes load-time gap.
- Output Format Reviewers line: appended `— {base|doubled} table` so audit record self-documents which sizing was used (base table is new default per 2026-05-25).
- Argument Handling vote_id branch: extracted "Detection:" sub-clause clarifying dispatch keys on `docket vote show` exit code, not string-shape heuristics.

### Dimensions Evaluated
Orchestration (HIGHEST — delegation gate), Output Quality, Actionability, Coherence (team-lead.md reviewer-defaults base-table).

### Rename
No rename.

## 2026-05-20

### Summary
Light trim cycle: removed self-duplicated cap-at-8 sentence, collapsed recursive-doubling paragraph to a one-line pointer (full semantics live in `team-lead.md` + reviewer-doubling-lifecycle TDD), and sharpened Argument Handling dispatch comments so team-mode callers don't pass free-text args (signal: captured session 962bb9d0 where vote was invoked with free-text proposal in team-mode).

### Changes
- Criticality Classification: removed duplicated second sentence of cap-at-8 note.
- Recursive-doubling paragraph: collapsed 5-line cross-document duplicate to 2-line pointer referencing `docs/tdd/reviewer-doubling-lifecycle.md` §8.2 decision 5.
- Argument Handling: clarified vote_id branch is the canonical team-lead relay path; flagged proposal-description branch as standalone-only.

### Dimensions Evaluated
Over-Engineering (primary), Coherence (team-lead.md, reviewer-doubling-lifecycle.md), Actionability.

### Rename
No rename.

## 2026-05-18

### Summary
Minor over-engineering trim in Phase 2 — folded "coordinator-owned tasks" editorial into the existing actionable sentence. No behavioral or contract changes; CLI flags verified intact against `docket vote --help`; cross-caller Delegation Protocol payloads (6 agent files) confirmed coherent.

### Changes
- Phase 2: removed standalone "Tasks are coordinator-owned for observability" paragraph; merged the TaskUpdate sentence into the spawn paragraph.

### Dimensions Evaluated
Over-Engineering (primary), Coherence, Spec Alignment.

### Rename
No rename.

## 2026-05-17

### Summary
Tightened team-mode delegation payload contract to close coherence gap with calling agents (staff/security/sdet/senior/ux currently document divergent payloads). Added "When to invoke (high bar)" rule (historical audit shows 3 invocations vs code-review's 125 — healthy but unstated). Clarified `from` field's role in operator-visibility relay. Restated frontmatter rationale.

### Changes
- Delegation Protocol step 2: made "Create proposal first" explicit + added `failed` contract on payloads missing vote_id.
- Delegation Protocol step 3: added optional summary/artifact operator-observability hints; clarified docket is authoritative.
- Header: added "When to invoke (high bar)" decision rule + do-not-vote-on list.
- Output Format step 4: callee resolves invoking agent via from field; cc team-lead for operator-visibility.
- Execution Mode Detection: parenthetical noting frontmatter Agent/TeamCreate/TeamDelete are for standalone path only.

### Dimensions Evaluated
Orchestration & Agent Teams (primary), Coherence (with team-lead.md, staff/security/sdet/senior/ux agent files), Skill Design Quality, Actionability.

### Rename
No rename. `vote` matches `docket vote` CLI exactly.

## 2026-05-16

### Summary
Restructured Pre-flight goal-alignment Q3 to conform to AskUserQuestion contract (was 5 inline options with default-with-rationale jammed into the option list; now Confirm/Override pair after deterministic classification). Trimmed Delegation Protocol step 4 by extracting team-lead's responsibility narrative to a one-line pointer at team-lead.md Consensus Integration. Reordered Pre-flight steps. Small formatting + reviewer-shutdown reason consistency fixes.

### Changes
- Pre-flight: swapped step ordering so step 2 is "Classify criticality" (deterministic) and step 3 is "Confirm goal-alignment (HARD GATE)" — Q3 now uses `Confirm {classified-level}`/`Override`, satisfying AskUserQuestion 2-4 options contract.
- Delegation Protocol step 4: trimmed team-lead-responsibility prose; replaced with pointer to team-lead.md Consensus Integration. Eliminates duplicated contract drift risk.
- Output Format Cleanup step 1: added `reason: "vote complete"` to `shutdown_request` payload for consistency with evolve-* shutdown protocol.
- Delegation Protocol step 5: added missing blank line before the `---` separator.

### Dimensions Evaluated
Operator Prompt Quality (primary), Coordination & Handoff (Delegation Protocol clarity), Over-Engineering, Coherence (team-lead.md, evolve-* shutdown protocol).

### Rename
No rename. `vote` matches `docket vote` CLI exactly.

## 2026-05-13

### Summary
Reconciled `--findings-json` "primary path" claim with the Reviewer Template's markdown output by adding a `### Findings JSON` block reviewers emit alongside markdown; the coordinator passes the JSON block verbatim to `docket vote cast --findings-json -` with the plaintext heredoc as documented fallback. Closed @security-engineer coherence gap with team-lead Security Track: added security row to Agent Selection table, proposer-exclusion mapping, and Domain-Specific Checklist so security-sensitive votes route correctly and proposer-independence holds.

### Changes
- Recording Votes: reframed `--findings-json` as primary path consuming the reviewer's emitted JSON block; plaintext heredoc demoted to "fallback when JSON missing or malformed".
- Reviewer Prompt Template: added `### Findings JSON` section between Findings and Summary so reviewers emit a structured JSON object for direct passthrough to `--findings-json -`.
- Agent Selection: added "Security-sensitive" row (primary @security-engineer); replaced incorrect "@senior-engineer for security-tagged" with "@security-engineer for security-tagged".
- Reviewer Independence Mapping: added `@security-engineer` row covering `security-engineer`/`security-advisor`/`security-tdd-author` `created_by` values.
- Domain-Specific Checklist: added @security-engineer row (authn/authz, input validation, secrets/crypto, trust boundaries, sandbox, supply chain, logging-leak, DoS).

### Dimensions Evaluated
Skill Design Quality (JSON contract correctness), Actionability, Completeness (security role end-to-end), Coherence (team-lead Security Track, code-review role detection), Orchestration & Agent Teams.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: First evolution cycle: coherence conventions, removed duplicate quorum table, replaced cat-redirect with Write tool, trimmed consensus record schema.
- 2026-03-20: Added effort: high; trimmed reviewer prompt scales; ultrathink trigger; consolidated duplicate rules; renumbered Rules.
- 2026-03-20: Removed unused team tools from frontmatter; added SendMessage result reporting and view-change escalation path; trimmed redundancies.
- 2026-03-20: Fixed inconsistent $ARGUMENTS references to align with the skill's {proposal} convention.
- 2026-03-20: Added full agent team lifecycle (TeamCreate/TaskCreate/TaskUpdate/TeamDelete) to align with all other skills.
- 2026-03-20: Fixed CLI flags to match docket vote capabilities; approve-with-concerns is native; added docket vote commit finalize step.
- 2026-03-20: Trimmed redundant explanations, consolidated View Change section, added --findings-json support.
- 2026-03-21: Added [VOTE]-prefixed SendMessage phase-transition notifications; removed unsupported request-changes reviewer verdict.
- 2026-03-29: Removed identity verdict mapping, folded Phase 3 into Phase 4, removed mid-protocol notification, upgraded effort to max.
- 2026-03-30: Added consensus-integrity and reviewer-honesty directives; removed redundant audit verification procedure; tightened description.
- 2026-03-30: Trimmed description to 250-char limit; Execution Mode Detection 10→2 lines; compressed Delegation Protocol and Audit Trail.
- 2026-04-06: Fixed nested agent spawning bug: Execution Mode Detection now uses team-context awareness; explicit team-spawning prohibition added.
- 2026-04-16: Fixed Pre-flight→Phase 1 ordering bug (TeamCreate before vote-id existed); aligned delegation_request schema with dev skill.
- 2026-04-16: Made reviewer output retrieval explicit (parse Agent() return); trimmed edge-case blocks; unified {vote-id} placeholder spelling.
- 2026-04-22: Hardened crash/stall handling (stall auto-fail, partial-quorum continuation, single re-spawn); Delegation Protocol 15-min timeout clarified.
- 2026-05-04: Fixed malformed View Change SendMessage instruction; compressed Audit Trail to two invariants; trimmed Phase 1 link block (399→374).
- 2026-05-05: Removed reviewer-prompt task-ownership bug; Argument Handling dispatches on vote_id so delegated re-invocation skips Phase 1 (374→369).
- 2026-05-05: Restructured AskUserQuestion calls to concrete option arrays for goal-alignment and View Change next-step.
- 2026-05-05: Scoped Cleanup to standalone mode; View Change commits failed rounds; critical-tier domain_relevance ≥0.8 floor made enforceable.
- 2026-05-05: Phase 2 coherence: unified CRITICAL banner format with evolve-* skills.
- 2026-05-06: Removed PBFT terminology, fixed Phase 2 task ownership, heredoc vote-casting, explicit vote_id detection, CANONICAL banner markers (373→370).
- 2026-05-06: Renamed vote → create-vote to align with the create-* family; directory, frontmatter, /create-vote slash command, cross-references updated.
- 2026-05-06: Phase 1 trim: removed proposer-exclusion footnote, coordinator role micro-redundancy, and no-argument bullet (371→364).
- 2026-05-06: Renamed create-vote → vote per operator request; directory, frontmatter, /vote slash command, all cross-references updated.
- 2026-05-06: Trim cycle: fixed stale # Create Vote H1, collapsed rubber-stamp triple-redundancy, removed Rules section (366→338).
- 2026-05-07: Over-engineering pass on largest skill (338→316): tightened Pre-flight, deduplicated Phase 2, merged Audit Trail into Output Format.
- 2026-05-09: Fixed silent quorum-poisoning (NON-VOTE failure-cast prefix); Delegation Protocol re-anchored as thin re-invoke; docket vote unlink adopted.
- 2026-05-09: CLI alignment: docket version --quiet liveness probe; --findings-json primary recording path; Record block echoes docket vote commit.
