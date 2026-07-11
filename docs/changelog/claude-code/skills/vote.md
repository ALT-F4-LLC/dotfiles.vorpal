# Changelog: vote

## 2026-07-10

### Summary
Compacted 2 entries (2026-05-29..2026-05-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-10

### Summary
CULL the schema-invalid object-shaped delegation_request SendMessage example (root-caused across 13 sessions + 2 pitfalls.md rediscoveries); replaced with a text-prefixed JSON string, verified against the live SendMessage tool schema. AMPLIFY a live-verified jq recipe for the critical-vote domain floor (`.data.votes[]` envelope, confirmed against a real docket record).

### Changes
- CULL/FIX: Delegation Protocol steps 3 & 4 no longer pass a bare `{type: "delegation_request"|"delegation_response", ...}` object to SendMessage's `message` param (schema accepts only string | shutdown/plan-approval union shapes). Now a text-prefixed JSON string. Cited: 13-session bug-audit signal + 2 independent pitfalls.md workarounds.
- AMPLIFY: Phase 3 critical domain-floor now a concrete `jq '[.data.votes[].domain_relevance] | max >= 0.8'` — corrected path verified live against a real docket vote record (`.data` envelope wraps `votes[]`).

### Dimensions Evaluated
All 8. Over-Engineering: no forced cuts (33KB/65KB, ample headroom). No rename.

### Rename
No rename.

## 2026-06-30

### Summary
AMPLIFY frontmatter invocation guard for report-only investigations; target 334 -> 335 lines.

### Changes
- AMPLIFY: frontmatter says load only for actual consensus decisions, not report-only investigations that merely mention votes.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Two cited robustness fixes (both net 0, verified against live docket b59dd2f): Pre-flight DB-existence detection and an operational findings-JSON heredoc mandate + retry guard. Stays 340 lines.

### Changes
- AMPLIFY: Pre-flight step 1 now detects a missing docket DB (`docket vote list` probe → exit 2) and prompts (standalone `AskUserQuestion docket init`/abort) or escalates to team-lead (team mode) instead of hard-failing later at `docket vote create`. DB-creation location stays an operator/orchestrator decision. Cited HISTORICAL signal (2).
- AMPLIFY: Recording Votes now mandates the stdin heredoc (`--findings-json -`/`--findings -`), NEVER inline `--findings-json "..."` (reviewer prose `!`/backslash corrupts the payload, exit 3), and retries with plaintext `--findings -` on a JSON parse error. Cited HISTORICAL signal (1). `@file` rejected — unsupported by CLI (stdin `-` only, verified).

### Dimensions Evaluated
All 8. Over-Engineering (highest): net 0, temp-file approach rejected as over-engineered. No model/routing change (reviewer template stays opus — the sonnet hypothesis had no data); no drift; no unescaped `$`+digit. Phase-2 deferrals: delegation-protocol CANONICAL (shared with team-lead.md); BANNER family block.

### Rename
No rename.

## 2026-06-20

### Summary
Closed the model= dispatch defect; net 0 (stays 340). BANNER (vote singleton) + Delegation Protocol anchor deferred to Phase 2.

### Changes
- AMPLIFY: pinned `model="opus"` on the standalone reviewer Agent() spawn template — omitted model= resolved non-deterministically (dispatch defect per team-lead.md); opus matches decision-review depth for the high-stakes calls vote gates (operator-approved per-tier pinning).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Added a post-vote citation note: a committed outcome seals the voted artifact as canonical authority, so downstream references cite it verbatim.

### Changes
- AMPLIFY (§If Quorum Is Reached, step 1): a committed outcome seals the voted artifact (TDD/ADR/plan); downstream briefs/dispatches MUST cite the committed artifact verbatim (file+line), never paraphrase. Reciprocal to team-lead.md:243 brief-citation requirement; closes the recurring post-vote-drift gap (hermes pitfall). Net +4.
- Drift (rate 7): all 7 SKIP — template placeholders, output fields, detection-logic prose.

### Dimensions Evaluated
Behavioral Completeness, Over-Engineering, Coherence, Content Gate, Rename.

### Rename
No rename.

## 2026-06-17

### Summary
Added an AC-reconciliation check after commit, a deferred-vs-cancelled disposition-clarity rule on escalation, and corrected an inverted reviewer-template shutdown direction. Trial: AC-reconciliation / disposition-clarity / shutdown-direction → adopted.

### Changes
- AMPLIFY: AC-reconciliation check — an outcome reversing prior direction flags that pre-vote sub-issue ACs may encode the contradicted direction and must be reconciled before implementation.
- AMPLIFY: disposition clarity — escalation `--outcome` must distinguish deferred ("blocked by X") from cancelled ("superseded by X") to prevent wrong issue closures.
- CULL: reviewer-template "emit shutdown_request" → idle-AWAIT the coordinator's request (canonical protocol).
- Deferred: `disable-model-invocation` (verify it doesn't block team-lead's `Skill(vote)` delegation first).

### Dimensions Evaluated
Completeness / Correctness (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
NO-OP. All 8 dimensions clean. docket vote cast/create CLI re-verified zero-drift against --help; silent-idle verdict capture verified hardened on the correct mechanism (SendMessage-only delivery L168/L255, idle-without-delivery handling L172/L174); $ARGUMENTS at L27 correctly bare (live shell command).

### Changes
- None (NO-OP verdict). Reviewer-template extraction rejected — no fitness signal, 333/500 budget, extraction adds Read indirection for zero behavioral gain.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — stable trimmed floor); Completeness (verdict-capture re-verified); Coherence (panel-sizing parity with team-lead.md Rule 8 and code-review-verdict verified in-sync).

### Rename
No rename — `vote` maps to the `docket vote` CLI subcommand.

## 2026-06-10

### Summary
Compacted 8 entries (2026-05-13..2026-05-28) into Compacted history per ADR 0001.

### Changes
- Replaced the 8 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Deleted phantom `--double` flag / `doubled=true` parenthetical at L75 — confirmed non-existent against `docket vote create --help` (docket b161f57) and absent from team-lead.md's opt-up wording. Net 0 lines.

### Changes
- L75: removed ghost-flag text; the correct opt-up mechanism (`docket vote create -n N` override) was already stated in the same sentence — pure deletion, no information lost.
- Cross-project pitfall checks: verdict-delivery-via-SendMessage and ground-truth-over-chat (`docket vote result`) verified ALREADY encoded; `docket doc edit -d` full-body-replace hazard not applicable (zero docket doc refs).

### Dimensions Evaluated
All 8; Coherence (CLI ground-truth drift — primary fix); Over-Engineering; Orchestration (verdict-delivery mechanics verified).

### Rename
No rename.

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
- 2026-05-13: Reconciled `--findings-json` "primary path" claim with the Reviewer Template's markdown output by adding a `### Findings JSON` block reviewers emit alongside...
- 2026-05-16: Restructured Pre-flight goal-alignment Q3 to conform to AskUserQuestion contract (was 5 inline options with default-with-rationale jammed into the option lis...
- 2026-05-17: Tightened team-mode delegation payload contract to close coherence gap with calling agents (staff/security/sdet/senior/ux currently document divergent payloa...
- 2026-05-18: Minor over-engineering trim in Phase 2 — folded "coordinator-owned tasks" editorial into the existing actionable sentence. No behavioral or contract changes;...
- 2026-05-20: Light trim cycle: removed self-duplicated cap-at-8 sentence, collapsed recursive-doubling paragraph to a one-line pointer (full semantics live in `team-lead....
- 2026-05-25: Closed team-mode direct-invocation loophole by hoisting delegation gate into the canonical banner (root cause of session 04db218a operator-rejection where ag...
- 2026-05-28: Phase 2 coherence: repointed two dead `docs/tdd/reviewer-doubling-lifecycle.md` references (the file does not exist) to canonical `agents/team-lead.md`.
- 2026-05-28: Two coordination fixes at net 0 lines: (1) team-mode delegation finalizes the orphaned `open` proposal on `failed`/timeout; (2) reconciled a crossed shutdown...
- 2026-05-29: Over-engineering trim on largest skill — collapsed doubled reviewer-count table to a count-only annotation; net -8 lines.
- 2026-05-30: NO-CHANGE evolve pass — re-verified docket vote CLI flags, delegation relay contract, and exclusion-table agent naming; zero drift.
