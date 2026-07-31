# Changelog: senior-engineer

## 2026-07-30

### Summary
Migration item R1: `effort: xhigh` → `high` with binding provenance — 0 report-only spawns measured (204/204 teammate), so charter alignment, not a Trial. One verified executable-defect fix (B3) plus four consolidations retiring intra-file duplication. Net −61 (48452 → 48391).
Findings: 8 → 3 sub / 0 cos / 2 rej / 1 def / 2 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (R1+I11): `effort: high` + binding-context provenance comment; re-derived per gate §4.
- AMPLIFY[SUBSTANTIVE] (B3): §Shell hygiene's zsh-identifier hazard list extended with the read-only `status` special — verified live (`zsh -c 'status=$(echo hi)'` → `read-only variable: status`); 4 sessions wrote the same `status=$(docket issue show …)` loop. Extension of an existing concrete enumeration, so gate §3's burden does not attach.
- CULL[SUBSTANTIVE] (§1.2/§1.5): CRITICAL banner item (3)'s full `/tmp` rule collapsed to a pointer — the rule was stated twice in full and `guard-tmp-write-hook.sh` caught all 3 in-window violations, so a louder third statement is emphasis inflation. Retires the file's one §2-unmappable `NEVER`.
- CULL[SUBSTANTIVE]: "No surface-level fixes" paragraph deleted — trace-to-root-cause was stated 4×; its unique escalation clause folded into code-philosophy principle 11.
- CULL[SUBSTANTIVE]: shutdown step 5's restatement of the `shutdown_response` reply (stated 3×) and post-shutdown ephemeral routing (stated 4×).
- REJECTED (I6): frontmatter `hooks:` gate — inert on the teammate path (~100% of spawns), and `guard-no-commit-hook.sh` already gates `commit|push|add` path-independently while listing `stash` as a deliberate exclusion, so the proposal would also contradict a ratified decision.

### Dimensions Evaluated
All 9, two ordered passes. 14 markers after, every survivor mapping to §2.1–§2.4.

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 7 entries (2026-07-12..2026-07-15) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 7 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: the terminal-state marker master now scopes its adopter list to the teammate path instead of qualifying sdet alone.

### Changes
- FIX[SUBSTANTIVE] (DISAMBIG 1): Ephemeral completion contract step 3 -- marker adopted "on the TEAMMATE path by staff-engineer.md, distinguished-engineer.md, and sdet.md"; a report-only subagent omits it rather than asserting an await that never resolves. Removes the reading that staff/DE adopt unconditionally while sdet adopts conditionally.

### Dimensions Evaluated
Disambiguation (Phase 3): multi-reading

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: terminal-state marker promoted to fleet-standard at its master with a do-not-reword adopter guard (staff/DE/sdet teammate paths now cite the exact literal).

### Changes
- AMPLIFY[SUBSTANTIVE] (I8): Ephemeral completion contract step 3 marker annotated fleet-standard with adopter list -- exact-string dependency now visible at the master.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Findings: 4 -> 3 sub / 0 cos / 1 rej / 0 def / 0 enc. Corrected the false `impl-*`-only spawn-name claim, deleted the unreachable Edit/Write-absent fallback, named the required SendMessage `summary` param at the ack template, and wired `ac_check.sh` into the Execution Workflow at both ends. Net +729 bytes (77,604 -> 78,333).

### Changes
- FIX[SUBSTANTIVE] (C3): Lifecycle now admits `docs-author`/`-{DOCKET-ID}` and the 4 senior-engineer-typed evolve-* auditors as legitimate spawn names; dropped the no-referent "all other spawns ephemeral" clause. Same narrowing fixed in the Shutdown ephemeral-completion contract.
- CULL[SUBSTANTIVE] (D1): removed the Edit/Write-absent `$TMPDIR` script fallback -- `memory: project` force-enables Read/Edit/Write, so the branch was unreachable. Its dangling Runtime-Discipline back-reference and the doubled PA-mode tool-availability hedge went with it.
- AMPLIFY[SUBSTANTIVE] (B1): ack template now shows the `summary` param; a bare-string `message` without it fails every time (2 of 6 fleet occurrences were agents following this template verbatim).
- AMPLIFY[SUBSTANTIVE] (I4): step 2 runs `ac_check.sh <id> --pre` (an `[UNEXPECTED-PASS]` is a vacuous AC -> escalate before coding); step 5 runs `ac_check.sh <id>` (all `[PASS]`) before close. First agent-file citation of a script whose own header names this file as consumer.
- CULL[COSMETIC] x2: compressed the claim-refusal no-op rationale; dropped the 4th restatement of the inline-OVERRIDE ban.
- REJECTED: H5 multi-spawn-rate clarification -- already encoded by `impl-{DOCKET-ID}`; the discriminator's consumer is team-lead's stall probe.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 4 entries (2026-07-10..2026-07-11) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: added the seat-name addressing convention that security-engineer.md, project-manager.md, sdet.md, and ux-designer.md already carry -- this was the one file without it despite being the heaviest consumer of the advisor consult path. Net +300 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE]: new sentence in What You Are NOT -- the file's thirteen @staff-engineer recipient rows mean the general-architecture SEAT (advisor), whose holder is @distinguished-engineer on Medium+ TDD-bearing cycles, not always @staff-engineer literally. One sentence retires all thirteen rows without editing each individually.

### Dimensions Evaluated
Overlapping-ownership (Phase 3, two-arm test)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: AskUserQuestion hedge corrected (file's own phrasing delta preserved); CANONICAL:PITFALLS compacted to a pointer; orphaned go_verify.sh wired into Build & Commit Hygiene.

### Changes
- FIX[SUBSTANTIVE]: "absent in the common team-mode spawn" -> "stripped from EVERY teammate and subagent spawn unconditionally (sub-agents.md first tool filter)".
- AMPLIFY[SUBSTANTIVE]: new Build & Commit Hygiene bullet citing `go_verify.sh` (zero prior repo references; standardizes hand-rolled `go build`/`go vet` invocations).
- CULL[SUBSTANTIVE]: CANONICAL:PITFALLS (2,811B) -> CANONICAL:PITFALLS-LOCAL pointer.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Findings: 5 -> 4 sub / 2 cos / 0 rej / 0 def / 1 enc, plus 6 reviewer-originated. Removed the commit-skill grant and the prose that told this role to invoke a skill whose caller gate aborts on it; de-duplicated the READ-BEFORE-EDIT master; stopped a class of pointless shutdown rejections. Net +60 bytes (77,675 -> 77,735).

### Changes
- CULL[SUBSTANTIVE] (E1): dropped `commit` from frontmatter `skills:` -- `commit/SKILL.md` Step 0 names `@senior-engineer` in its forbidden-caller list, so the grant could only ever abort.
- AMPLIFY[SUBSTANTIVE] (E1): Commit-mode bullet no longer instructs `Skill(commit, ...)`. Under team-lead, request the commit; standalone with explicit operator authorization, draft it directly against `commit/SKILL.md` Step 2 grammar and gate it on `commit_msg_check.sh` before a scoped `git add`/`git commit -F`.
- CULL[COSMETIC] (I6): collapsed two in-block restatements of the Read/Edit adjacency rule in CANONICAL:READ-BEFORE-EDIT to the single forcing-rule statement (block is not parity-locked; verified absent from doctrine_check_manifest.tsv).
- AMPLIFY[SUBSTANTIVE]: shutdown ground 2 now excludes a stall-framed `shutdown_request` that crossed the completion report in flight -- approve it. Both of this role's in-window rejections were that shape and changed nothing.
- AMPLIFY[SUBSTANTIVE] (repetition FIX 1): R6 now bans re-`ls`-ing doctrine-cited `~/.claude/scripts/*.sh` paths (113 sessions fleet-wide).
- AMPLIFY[SUBSTANTIVE] (B5): R1 states Read's `limit` is a COUNT, not an end line.
- FIX[COSMETIC]: docket_claim.sh described as verifying "the claim landed" rather than `updated_at` -- the staged script fix replaces updated_at comparison with status/assignee.
- CULL[COSMETIC] x4: duplicated rework-signal rationale, PITFALLS bridge pointer, scout-pass restatement, docket `edit -f` semantics (stated in the DOCKET-CLI block below it).

### Dimensions Evaluated
Boundary Clarity, Actionability, Spec Alignment, Capability Growth & Cross-Communication, Consolidation & Trimming. ALREADY-ENCODED: B3 (literal `/tmp` -- CRITICAL banner item 3 is already line 20, the most prominent placement in the file; remaining gap is mechanical, coherence-flagged).

### Rename
No rename.
## 2026-07-21

### Summary
Compacted 4 entries (2026-06-30..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Phase 3 disambiguation: two vocabulary substitutions to remove multi-reading/confusable-name risk, no behavioral change.

### Changes
- FIX[COSMETIC]: Lifecycle "fresh Jobs" → "fresh ephemeral spawns" (sole family-wide occurrence of "Jobs", misreadable as background-job/fork-class dispatch after this cycle's fork-trial revert).
- FIX[COSMETIC]: Operating context "Stateless subagent" → "Stateless between spawns" (bare "subagent" collides with the reserved report-only-subagent mechanism term; every senior-engineer spawn is actually a teammate).

### Dimensions Evaluated
Confusable-name and multi-reading clarity (Phase 3).

### Rename
No rename.

## 2026-07-21

### Summary
Findings: 5 → 3 sub / 1 cos / 0 rej / 2 def / 0 enc. Adopted the shared phase_diff.sh cross-check for pre-close scope self-verification; corrected the AskUserQuestion tool-envelope fallback; made the /tmp→$TMPDIR rule explicit.

### Changes
- AMPLIFY[SUBSTANTIVE] (I-se1): Shared-tree diff scoping now cites `phase_diff.sh` for declared-vs-actual remainder detection before handoff — parity with sdet/security-engineer/staff-engineer, which already cite it.
- AMPLIFY[SUBSTANTIVE] (B6): Tool-envelope fallback corrected — AskUserQuestion has no Bash equivalent and routes via SendMessage team-lead when absent, instead of the wrong grep/find guidance.
- AMPLIFY[SUBSTANTIVE] (B2): Shell hygiene now explicitly prohibits literal `/tmp/…` paths (25x-recurring leak) with a concrete `cat > "$TMPDIR/edit.py"` pattern.
- CULL[COSMETIC]: trimmed the redundant inline pitfalls.md path listing in the pre-CANONICAL:PITFALLS bridge sentence (paths defined in full three lines below).

### Dimensions Evaluated
Actionability, Boundary Clarity, Capability Growth & Cross-Communication, Consolidation & Trimming. Deferred: B4 (READ-BEFORE-EDIT block already sharp, execution-leak not definition gap), D9 (teammate skills-inert caveat already correct).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.
- 2026-03-19: Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.
- 2026-03-19: Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting…
- 2026-03-19: Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage…
- 2026-03-19: Consolidated redundant instructions, compressed status-update checklist, added @staff-engineer review notification to self-review workflow…
- 2026-03-20: Consolidation pass removing duplicate content across sections, added memory frontmatter, calibrated self-review depth to change risk.
- 2026-03-20: Consolidation pass removing self-review/Config-as-Code duplication and implicit "when not to consult" list, added @sdet and @project-manager…
- 2026-03-20: Consolidated duplicate build-verification bullets, removed redundant anti-pattern, added @ux-designer cross-communication trigger, compressed…
- 2026-03-20: Removed Anti-Patterns section (restated by Core Operating Principles), compressed CLI Reference and Cross-Cutting Concerns, updated CLI with…
- 2026-03-21: Added cross-communication observability (SendMessage and /vote logging as Docket comments), updated CLI with missing vote flags and…
- 2026-03-29: CLI reference fixes from docket audit (reopen, --domain-tag, --limit, optional --voter, --status, --assignee, --quiet), consolidated Build &…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed Inter-Agent Communication (merged status updates and observability)…
- 2026-03-30: Added rigorous honest mentor directive near top of file. Removed /vote "when NOT" list, folded Mermaid Diagrams into Cross-Cutting Concerns…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, compressed proactive sharing, /vote guidance, and Docket CLI Reference. Added docket aliases. Net: -13…
- 2026-04-06: Added TDD status gate (only implement from ACCEPTED TDDs). Compressed Core Operating Principles and Verification. Updated CLI reference with…
- 2026-04-16: Consolidation pass: trimmed Operating Context boilerplate, Docket Rules redundancy, and self-review bullet list. Aligned CLI reference with…
- 2026-04-16: Cross-communication pass: replaced vague "proactive sharing" prose with concrete phase-indexed SendMessage trigger matrix (before/during/close…
- 2026-04-19: Embedded operator "No guessing — verify" rule at top-of-file principle level adjacent to Rigorous honesty, and reinforced operationally in…
- 2026-05-05: Consolidation pass eliminating triple-stated "no guessing" overlap, redundant `docs/spec/` references, and the restated Docket Rules block.…
- 2026-05-05: Phase 0+2 capability adoption: added `Monitor` for build/dev-server/test streaming, `docket issue graph --mermaid` for refactor blast-radius…
- 2026-05-06: Capability growth via Phase 0 docket CLI audit — added `docket issue log <id>` (pre-start activity context), `docket issue graph --direction…
- 2026-05-06: Adopted PM's operator-visibility contract: every peer SendMessage is mirrored as a Docket comment with `[SE→@agent] {summary}` prefix (operator…
- 2026-05-06: Phase 2 coherence pass: extended operator-visibility contract with high-stakes real-time cc rule (TDD-deviation-requiring-re-plan…
- 2026-05-07: BALANCED-mode consolidation pass: removed three true duplications between Proactive SendMessage Triggers and Check Specs / Navigate Ambiguity…
- 2026-05-07: Phase 2 coherence: corrected the team-mode coordination model claim that contradicted SE's own SendMessage triggers and the team-wide pattern.
- 2026-05-07: Capability-growth pass: closed worktree-isolation gap (SE is the primary user of `isolation="worktree"` per orchestrator) and project-memory…
- 2026-05-08: Removed redundant Docket CLI cheatsheet, deduped TDD-gate and file-attachment rules, sharpened memory section, and made the ADR-broadcast…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner — teammates only read their own definition, so the team-lead.md…
- 2026-05-08: Phase 3 operating discipline: codified four behavioral rules surfaced by operator — no surface-level fixes, no retry loops / no install…
- 2026-05-09: Trim-heavy pass aligned with operator feedback (file-size bloat, no overthinking, output quality). Compressed top-of-file principles…
- 2026-05-09: Phase 2 coherence: added explicit "NOT @security-engineer" boundary (now that the security consult trigger exists), and closed bidirectional…
- 2026-05-13: Added "Implement Directly vs. Escalate for Design" rubric so SE proceeds directly on bugfixes/config/internal-refactors/pattern-extensions and…
- 2026-05-13: Phase 2 coherence: added Direct Task / solo-mode invocation acknowledgment to Operating context — defines behavior when team-lead delegates a…
- 2026-05-16: Consolidated all 8 operator communication-discipline rules into a non-negotiable block (closed-loop, ack, claim-first-Rule-7, 10-min…
- 2026-05-16: Phase 2 coherence: normalize security-advisor canonical form across three references.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).
- 2026-05-17: pass 2: Cycle 2026-05-17 historical-audit pass: dropped aspirational `.claude/agent-memory/senior-engineer/` reference (directory unused across…
- 2026-05-17: Phase 2 coherence: Tightened dispatch-ack to same-turn pattern matching sdet.md Rule 2. Added @security-engineer CVE/advisory incoming trigger.
- 2026-05-19: Cycle 2026-05-19 historical-audit pass. Closes the DKT-2 close-without-verify failure mode (strongest single signal in the audit) with an…
- 2026-05-19: Phase 2 coherence: Added `ux-advisor` canonical-name reference for symmetry with existing `security-advisor` / `advisor` patterns. Existing UX…
- 2026-05-19: Phase 2 coherence — brief contradiction-detection + envelope fallback: Closed the second line of defense on the Phase 1 P1 lesson: added brief…
- 2026-05-24: Phase 2 coherence — shutdown_response routing rule: Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead"…
- 2026-05-25: Phase 1 self-review — shutdown routing example + peer dispatch hard gate: Two targeted rewrites, net 0 lines. (1) Replaced abstract "never to…
- 2026-05-25: Two coherence fixes: (1) added docs-dir existence guard to "Check Specs Before Implementing" matching project-manager/staff-engineer convention (prevents
- 2026-05-26: Encoded two-step claim ritual (`docket issue edit -a @senior-engineer` BEFORE `docket issue move in-progress`) across bash codeblock + Communication Discipline
- 2026-05-26: Stripped 3 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.
- 2026-05-26: TDD deep-read gate added to step 2; Override Convention compressed. Net -7.
- 2026-05-26: Phase 2 coherence — ux-designer trigger reworded (vacuous → concrete); TaskStop drain doctrine fleet parity.
- 2026-05-30: Dead `commit` skill removed from frontmatter; frozen "(32 fix-round ephemerals)" count trimmed. Net -1.
- 2026-05-30: Frontmatter `**No code comments.**` block compressed to pointer to principle 7. Net 0.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` pointer removed ×5 (fleet sweep). Within-line.
- 2026-06-05: Shared-tree diff scoping + Premise-check + `\!=` escape fix + step-1 probe dedup. Net +1.
- 2026-06-09: Docs-exploration block triplicated → canonical Docs-paths block. Net -6.
- 2026-06-09: Docket cwd-outside-repo guard added to Execution Workflow step 6. Net 0.
- 2026-06-09: evolve-skills reference update: code-review → code-review-verdict; 1 reference updated.
- 2026-06-09: Audit-driven hardening — mv/rename gate, git-add-self-verify prohibition, grep-based edit-site location. Net -2 (360→358).
- 2026-06-09: Phase 2 shutdown flip — completion-contract step 5 + Monitor-watch replaced with await-lead semantics. Count unchanged (358).
- 2026-06-09: Fable-5 calibration — minor-choice autonomy + silence-default narration added; Technical Debt/Navigate-Ambiguity trimmed to offset. Net 0.
- 2026-06-09: Compacted 43 entries (2026-03-19..2026-05-25) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Fixed `.data.status` JSON-path bug in close-verify; compressed Tool-envelope (\$TMPDIR-script); scoped git-stash to shared-tree. Net 0.
- 2026-06-10: Phase 2 coherence — SE→staff cross-reference added linking escalate-or-implement test to staff's TDD-decision rubric.
- 2026-06-10: Compacted 3 entries (2026-05-25..2026-05-26) into Compacted history per ADR 0001.
- 2026-06-17: Repaired dead "see Runtime Discipline" cross-reference (L38) via non-numbered Shell-hygiene (zsh) bullet. Drift: neutral reword of the grep-call-sites bullet → adopted.
- 2026-06-19: Collapsed duplicated two-step-claim mechanic to a pointer; folded Idle-after-report facts into completion-contract step; corrected pitfalls-memory survival claim. Drift: neutral reorder of Core Operating Principle 3's three scenario-bullets → adopted.
- 2026-06-20: Extended @project-manager plan-change trigger to catch late directives contradicting closed work; five Phase-0 signals confirmed already-encoded. Drift: disabled (drift=0).
- 2026-06-21: Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Chained the two docket claim-writes into one Bash call (claim+ack 3→2 tool calls); PA-mode bullet deferred to Phase 2.
- 2026-06-30: Phase 2 landed the PA (plan-approval) mode bullet now that team-lead adopted PA dispatch. Net +1 (489→490). Trial: PA plan-approval → applied.
- 2026-07-01: Close handling drains background tasks pre-report; Plan mode dispatch claims-then-waits for proceed/revise; Docket file-attach example fixed. Trial: close-safety and plan-mode dispatch -> applied.
- 2026-07-10: Coordination & tool-correctness fixes (shared/appended-files rule, docket create -f vs file add, premise-check widened) offset by redundancy trims. Net +119 bytes.
- 2026-07-10: Phase 2 coherence follow-up — flagged vote-delegation JSON as a plain-text payload, never SendMessage's structured `message` object; matches team-lead.md bug-audit FIX-9.
- 2026-07-10: Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-11: evolve-agents cycle (SDLC role-comparison mandate): fixed a confirmed docket CLI drift (`docket issue edit` also accepts `-f`) and added docs-author hosting for end-user documentation. Net +685 bytes.
- 2026-07-11: Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.
- 2026-07-11: Compacted 3 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.
- 2026-07-12: Phase 2 coherence: migrated the hand-rolled team-mode vote proposal to `vote_delegate.sh` (fixes silent 0.67 threshold default); compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form.
- 2026-07-12: Findings: 3 → 3 sub / 0 cos / 0 rej / 3 def / 2 enc. Widened Tool-envelope-check note (Grep/Glob/AskUserQuestion/TaskStop/MCP fall back to Bash equivalents); extended Shared/appended-files rule to docs/tdd & docs/adr with the `stat -f '%Sm %z'` mtime-stability check. Net +811 bytes.
- 2026-07-13: Compacted 3 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.
- 2026-07-15: Compacted 4 entries (2026-06-19..2026-06-30) into Compacted history per the retention-compaction policy.
- 2026-07-15: Stale-dispatch check gains a scope discriminator (duplicate dispatch vs a new contradicting directive); R7 names the Read-before-Edit adjacency rule as a second outranking exception; CANONICAL:READ-BEFORE-EDIT master gains the missing empty-Read/new-path clause.
- 2026-07-15: Hosts two new fleet-wide masters: `CANONICAL:READ-BEFORE-EDIT` (B3) and `CANONICAL:STALE-DISPATCH-CHECK` (R3, receiving-side crossed-in-flight convention); vote wire-form paragraph deduped to a Skill(vote) citation (I4).
- 2026-07-15: Wired the orphaned self_review_scan.sh into self-review step 5; added a terminal-state marker to the completion report to reduce the operator-reported team-lead idle gap.
