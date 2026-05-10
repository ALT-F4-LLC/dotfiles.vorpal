# Changelog: vote

## 2026-05-09

### Summary
Three CLI-alignment fixes (operator pain points 1, 3): unified docket liveness probe with the canonical `docket version --quiet` (was vote-subsystem-specific overspecification), promoted `--findings-json` to the primary recording path with plaintext heredoc as fallback, and added the executed `docket vote commit` invocation to the Output Format Record block for audit replay.

### Changes
- Pre-flight step 1: replaced `docket vote list --limit 1` with `docket version --quiet` for liveness; aligns with senior-engineer.md canonical pattern (the docket CLI ships as one binary, so vote-subsystem-specific probing is overspecification).
- Phase 2 Recording Votes lead-in: `--findings-json` is now documented as primary (structured reviewer output deserializes cleanly); plaintext `--findings -` heredoc retained as fallback for free-form rationale.
- Output Format Record block: added `Committed via: docket vote commit {vote-id} --outcome "..."` line so the final report echoes the finalize command for audit replay.

### Dimensions Evaluated
Skill Design Quality, Actionability, Output Quality, Coherence (sibling code-review, evolve-skills, evolve-agents; senior-engineer.md liveness probe), Spec Alignment (docs/spec/review-strategy.md), Over-Engineering (light — most trim already done), Orchestration (verified delegation correctness, no stale `create-vote` references), Rename.

### Rename
No rename. `vote` matches `docket vote` CLI exactly.

## 2026-05-09

### Summary
Fixed silent quorum-poisoning in failure-cast (NON-VOTE summary prefix), tightened Delegation Protocol to make team-lead's responsibility a thin re-invoke (not a parallel implementation), removed Phase 2 numbered list duplicating the Reviewer Prompt Template, adopted `docket vote unlink` for multi-round link hygiene, and surfaced criticality classification as an operator-confirmed AskUserQuestion in standalone Pre-flight.

### Changes
- Phase 2 Handling Reviewer Failures: failure-cast summary now prefixed `NON-VOTE (reviewer failed): ...` so audits read accurately; clarified proceed condition is "remaining can meet quorum".
- Delegation Protocol step 4: team-lead's responsibility re-anchored — invoke `Skill(vote, "{vote-id}")` standalone (vote_id branch skips Phase 1) and forward the result; closes asymmetric contract with team-lead's Consensus Integration.
- Phase 2: removed 5-item numbered list duplicating the Reviewer Prompt Template.
- View Change step 4: added `docket vote unlink` before relinking on round N+1; closes audit-trail gap.
- Pre-flight standalone goal-alignment: added third AskUserQuestion for criticality with classified default + override options; addresses operator-prompt-quality pain point.

### Dimensions Evaluated
Skill Design Quality (correctness), Coordination & Handoff, Operator Prompt Quality, Output Quality / Actionability, Over-Engineering, Spec/Docket CLI Alignment, Cross-Skill Coherence, Rename.

### Rename
No rename. `vote` matches `docket vote` CLI exactly.

## 2026-05-07

### Summary
Over-engineering pass on the largest skill (338→316): tightened Pre-flight (dropped tautological "Parse the proposal" + forward-pointer to next section), trimmed Phase 1 caller-context aside, deduplicated Phase 2 wait/isolate clause, collapsed Recording Votes preamble + post-bash bullets, removed Reviewer Prompt Template orchestrator-reference blockquote, compressed Edge Cases, merged Audit Trail's two invariants into Output Format, condensed Agent Selection prose, and updated Delegation Protocol step 1 to drop "parse the proposal" reference for consistency.

### Changes
- Pre-flight: dropped step 2 "Parse the proposal" (tautological) and step 4 forward-pointer to Reviewer Independence Enforcement
- Delegation Protocol step 1: removed "parse the proposal" from Pre-flight summary for consistency with the trimmed Pre-flight section
- Phase 1: removed opening "Gather context..." sentence — caller's job, not coordinator's
- Phase 2: trimmed trailing "Wait for all... never feed output into another's prompt" — duplicates numbered list point 5 + implicit in advancing to Phase 3
- Recording Votes: removed preamble and bullets; bash example is self-documenting; preserved heredoc-rationale and `--findings-json` alternative inline
- Reviewer Prompt Template: dropped orchestrator-reference blockquote and trimmed Artifact placeholder enumeration
- Reviewer Independence Edge Cases: folded critical-vote 4-reviewer math into the pool-smaller-than-required bullet
- Audit Trail standalone section removed — two invariants relocated to Output Format `### Record` block
- Agent Selection: condensed "fresh, independent agent instance / Do NOT reuse" — `Agent()` semantics + canonical banner already enforce

### Dimensions Evaluated
Over-Engineering (primary), Coherence, Skill Design Quality, Actionability, Completeness, Spec Alignment, Orchestration & Agent Teams.

### Rename
No rename. `vote` matches `docket vote` CLI exactly.

## 2026-05-06

### Summary
Trim cycle on largest skill (366→338): fixed stale `# Create Vote` H1 from rename, collapsed triple-redundant rubber-stamp guidance, dropped forward-pointer Pre-flight step, compressed Execution Mode Detection + Phase 2 wait-and-isolate callout + AskUserQuestion shape, removed Rules section (all 4 rules duplicated content stated upstream).

### Changes
- H1 fix: `# Create Vote` → `# Vote` — rename was incomplete; title contradicted frontmatter `name: vote`
- Consensus-integrity paragraph collapsed into role declaration sentence; reviewer-prompt template retains the load-bearing instance
- Pre-flight step 5 (plan reviewer selection) folded into step 4 — was forward-pointer to next section
- Execution Mode Detection compressed; Delegation Protocol intro sentence removed
- Phase 2 "Critical constraint" callout merged into preceding paragraph — duplicated wait + no-cross-pollination rules
- Reviewer Prompt Template: dropped generic "think step by step" — structured output requirement enforces analysis (Content Gate Behavioral)
- Pre-flight goal-alignment AskUserQuestion shape compressed to single line per evolve-* convention
- Removed Rules section entirely — all 4 rules duplicate Execution Mode / Phase 2 / Phase 3 content
- Unmapped `created_by` note tightened to inline blockquote

### Dimensions Evaluated
Over-Engineering, Coherence, Skill Design Quality, Actionability, Completeness, Spec Alignment, Orchestration & Agent Teams, Rename.

### Rename
No rename. CHANGE 1 above completed the leftover stale H1 from the prior `create-vote` → `vote` rename.

## 2026-05-06

### Summary
**Rename: `create-vote` → `vote`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-vote` → `/vote`, all cross-references updated.

### Changes
- Directory renamed `skills/create-vote/` → `skills/vote/`
- Frontmatter `name: create-vote` → `name: vote`
- Slash command `/create-vote` → `/vote` throughout (banner, argument handling, execution mode detection)
- Delegation protocol: `skill: "create-vote"` → `skill: "vote"`
- Cross-references updated in: all 6 agent files, `.claude/skills/evolve-skills/`, `.claude/skills/evolve-agents/`, `docs/spec/review-strategy.md`, `README.md`
- Changelog file moved: `docs/changelog/skills/create-vote.md` → `vote.md`; H1 updated; historical entries left intact (rule: never modify existing changelog entries)
- Note: `docket vote` CLI commands and `vote-id` placeholder remain unchanged (CLI subcommand of docket; protocol-internal id)

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-vote` → `vote` per operator request.

## 2026-05-06

### Summary
Phase 1 over-engineering trim: removed three minor pockets — proposer-exclusion footnote duplicating next section header, micro-redundancy in coordinator role declaration, and Argument Handling "No argument" bullet whose payload was already implied by "required". Net 371→364.

### Changes
- Removed `> Proposer's agent type is always excluded — see Reviewer Independence Enforcement below.` footnote — pointed to the very next section header
- Merged "You do NOT vote yourself. You coordinate." into the role declaration sentence — the role name already implied non-voting
- Compressed Argument Handling from 4-bullet form (No argument / vote_id / proposal description) to inline abort + 2 dispatch bullets — "required" already covered the no-argument case

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Actionability, Coherence, Spec Alignment, Orchestration & Agent Teams, Cross-Skill Invocation, Rename.

### Rename
No rename. `create-vote` aligns with create-* family per prior 2026-05-06 rename entry.

## 2026-05-06

### Summary
**Rename: `vote` → `create-vote`** to align with the create-* family. Directory moved, frontmatter `name:` updated, slash command `/vote` → `/create-vote`, all cross-references updated.

### Changes
- Directory renamed `skills/vote/` → `skills/create-vote/`
- Frontmatter `name: vote` → `name: create-vote`; added trigger phrases ("create vote", "vote on this", "consensus vote", "run a vote")
- Title: `# Vote — Multi-Agent Consensus Protocol` → `# Create Vote — Multi-Agent Consensus Protocol`
- Slash command `/vote` → `/create-vote` throughout (banner, argument handling, execution mode detection)
- Delegation protocol: `skill: "vote"` → `skill: "create-vote"`
- Cross-references updated in: `skills/dev/`, `.claude/skills/evolve-skills/`, `.claude/skills/evolve-agents/`, all 5 agent files (frontmatter `skills:` + body), `docs/spec/review-strategy.md`
- Changelog file moved: `docs/changelog/skills/vote.md` → `create-vote.md`; H1 updated; historical entries left intact (rule: never modify existing changelog entries)
- Note: `docket vote` CLI commands and `vote-id` placeholder remain unchanged (CLI subcommand of docket; protocol-internal id)

### Dimensions Evaluated
Rename, Coherence, Spec Alignment

### Rename
Renamed `vote` → `create-vote` per operator request to align naming with the create-* family (create-prd, create-tdd, create-adr, create-ux-spec, create-specs).

## 2026-05-06

### Summary
Removed PBFT terminology, fixed muddled task-ownership in Phase 2, replaced fragile echo-pipe with heredoc, removed cryptic Rule 5, made vote_id detection check explicit, added canonical banner markers. Net 373→370.

### Changes
- Title and Phase headers: dropped "PBFT" / "Pre-Prepare" / "Prepare" / "Commit or Escalate" — the skill does not implement Practical Byzantine Fault Tolerance; formal phase names misled operators
- Phase 2 task lifecycle: clarified coordinator owns tasks (not reviewers)
- Argument Handling vote_id branch: replaced "matches an existing record" with explicit `docket vote show $ARGUMENTS --json; if exit 0` check
- Removed cryptic Rule 5 ("override up, never down for security") — Pre-flight step 4 already covers caller-specified criticality and the asymmetry isn't enforced
- Phase 2 vote-casting example: replaced single-quoted multi-line echo with heredoc
- Reviewer Independence Enforcement: trimmed "non-negotiable" filler
- Added `<!-- CANONICAL:BANNER:BEGIN/END -->` markers around CRITICAL banner

### Dimensions Evaluated
Skill Design Quality, Honesty, Actionability, Over-Engineering, Coherence, Spec Alignment, Rename

### Rename
No rename — `vote` matches `docket vote` CLI exactly.

## 2026-05-05

### Summary
Phase 2 coherence fix: unified CRITICAL banner format with evolve-* skills, preserving coordinator/reviewer terminology native to this skill.

### Changes
- Replaced top-of-file CRITICAL banner with unified two-rule format covering no-commit and no-recursive-vote/sub-agent prohibitions

### Dimensions Evaluated
Coherence

### Rename
No rename.

## 2026-05-05

### Summary
Fixed Cleanup running in team mode (would shut down agents the delegator doesn't own), closed audit-trail gap where failed rounds were never committed, made the critical-tier domain_relevance ≥ 0.8 invariant explicitly enforceable, and patched two actionability gaps. Net 370→373.

### Changes
- Scoped Cleanup to standalone mode — team-mode delegator never spawned reviewers (Delegation Protocol step 4)
- View Change now calls `docket vote commit --escalation-reason "view-change: round N"` to finalize failed rounds — closes stale open proposals in `docket vote list`
- Failure-cast in Handling Reviewer Failures now includes `--role`, `{vote-id}`, and `--voter` — Audit Trail invariant requires `.role` for proposer-exclusion verification
- Phase 3 explicitly enforces `critical` tier `domain_relevance >= 0.8` floor by parsing `docket vote show --json` after `docket vote result` (docket computes weighted threshold but not custom invariants)
- Argument Handling vote_id branch now references Reviewer Independence Enforcement — was silently skipping proposer exclusion
- Criticality table: `critical` reviewer count `3-4` → `4` (`docket vote create -n` takes a single int)

### Dimensions Evaluated
Orchestration & Agent Teams, Spec/Docket Alignment, Coherence, Actionability, Skill Design Quality, Cross-Skill Invocation, Over-Engineering, Rename

### Rename
No rename — `vote` matches `docket vote` CLI exactly.

## 2026-05-05

### Summary
Restructured operator-facing `AskUserQuestion` calls (goal-alignment, View Change next-step) to use concrete option arrays where the question is a discrete choice; free-text retained for descriptive bodies (criteria/stakeholders, findings rationale). Net 369→370.

### Changes
- Pre-flight goal-alignment now specifies AskUserQuestion shape: `Decision` (Confirm/Revise) + free-text Criteria
- View Change step 2 now specifies AskUserQuestion shape for the three next-step options (Revise/Escalate/Abort)

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Skill Design Quality, Cross-Skill Invocation, Terminology Alignment, Spec/Docket Alignment, Rename

### Rename
No rename — `vote` matches `docket vote` CLI exactly.

## 2026-05-05

### Summary
Phase 1 fixes: removed coherence bug in Phase 2 reviewer prompt (instructed spawned reviewers to update tasks they don't own) and trimmed tautological closing step from Delegation Protocol. Phase 2 fixed a cross-skill contract bug: Argument Handling now dispatches on `vote_id` so dev's `Skill(vote, "{vote_id}")` invocation skips redundant Phase 1 proposal creation. Net 374→369.

### Changes
- Removed "When done, mark your task as completed via TaskUpdate" from Phase 2 reviewer prompt template — contradicted coordinator-driven task lifecycle
- Removed Delegation Protocol step 6 — step 5 already documents each response-status action
- [Phase 2] Argument Handling now has two branches: `vote_id` arg (skip Phase 1, read existing proposal, proceed to reviewers) vs. proposal description arg (full protocol). Closes contract bug where dev's `Skill(vote, "{vote_id}")` would have re-created the proposal in Phase 1

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Skill Design Quality, Cross-Skill Invocation, Terminology Alignment, Spec/Docket Alignment, Rename

### Rename
No rename — `vote` matches `docket vote` CLI exactly.

## 2026-05-04

### Summary
Fixed malformed View Change SendMessage instruction (unterminated quoted message + duplicated agent/user routing); compressed Audit Trail reference table to two non-obvious invariants; trimmed Phase 1 link block, redundant criticality-override blurb, and ad-hoc-fallback filler sentence. Net 399→374.

### Changes
- Fixed View Change view step 3 — collapsed broken/duplicated SendMessage instructions into one notify+options sentence covering both agent and user callers
- Compressed Audit Trail from 11-line reference table to 3-line pointer + two non-obvious post-commit invariants
- Trimmed Phase 1 `docket vote link` block from 11 to 4 lines (read-proposal-files instruction already covered upstream)
- Removed criticality-override blurb under the classification table — Rule 5 is the canonical home
- Removed "For ad-hoc proposals" filler sentence — General/Mixed table row already covers it
- [Phase 2 coherence] Stripped unverifiable "(v2.1.111)" parenthetical from Handling Reviewer Failures

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Skill Design Quality, Completeness, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Hardened crash/stall handling for reviewer failures and clarified Delegation Protocol response schema (15-min timeout, explicit orchestrator responsibilities) to prevent team-mode orchestrator hangs. Net 397→399.

### Changes
- Added Handling Reviewer Failures to Phase 2: v2.1.111 stall auto-fail, partial-quorum continuation via audit-trail reject-cast, single re-spawn policy, abort-on-two-failures
- Clarified Delegation Protocol: `delegation_response` shape, 15-min timeout, orchestrator responsibilities (reviewer spawn + crash monitoring + vote casting on delegator's behalf)
- Removed mermaid-for-escalations rule, proposal-created operator notification (redundant with outcome), AskUserQuestion-fallback paragraph
- Rejected 3 reviewer proposals: removing shutdown_request (team-spawned agents need shutdown before TeamDelete), trimming Reviewer Independence mapping (dev uses synthetic instance names like tdd-author/impl-*/verifier-* as `created_by`), removing Standalone-Mode-Only blockquote (disambiguates for team-mode readers)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Made reviewer output retrieval explicit (Agent() return message is the source), trimmed over-engineered edge-case blocks, unified vote-id placeholder spelling across the skill. Addresses operator feedback on coordination clarity.

### Changes
- Phase 2: replaced vague "TaskList monitors completion" with explicit "parse Agent() return value" — closes Dimension 5 ambiguity about how coordinator retrieves verdict/findings payload
- Compressed unmapped-`created_by` warning from 3 lines to 1
- Compressed Reviewer Independence Edge Cases from 9 lines to 5
- Coherence: unified all `{proposal_id}` and placeholder `{vote_id}` references to canonical `{vote-id}` across CLI examples; JSON field name `vote_id` preserved (snake_case is correct for JSON keys)

### Dimensions Evaluated
Over-Engineering, Orchestration & Agent Teams, Coherence, Actionability, Completeness, Skill Design Quality, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Fixed Pre-flight→Phase 1 ordering bug (TeamCreate referenced `{vote-id}` before it existed) and aligned delegation_request schema with dev skill. Trimmed redundant cross-reference note.

### Changes
- Moved `TeamCreate` + `TaskCreate` from Pre-flight steps 6-7 into Phase 1 after `docket vote create` — pre-flight required a vote-id that didn't exist yet
- Added `protocol_version: "1"` and `request_id` to delegation_request example to match dev/SKILL.md schema
- Trimmed two-line cross-reference blockquote to a single line (section being referenced is the next one)

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Completeness, Skill Design Quality, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Fixed critical nested agent spawning bug: replaced broken Execution Mode Detection (tool-availability check that never triggers for team agents) with team-context awareness. Added explicit team-spawning prohibition to Rules.

### Changes
- Rewrote Execution Mode Detection to use team-context (team_name presence) instead of tool availability — fixes root cause of team agents spawning reviewer sub-agents
- Added Rule 2: explicit prohibition on agent spawning from within a team, with delegation protocol redirect
- Rewrote description to distinguish standalone (spawns reviewers) vs team (delegates to orchestrator) behavior
- Renamed "Sub-Agent Path" to "Team Path" in Delegation Protocol header
- Added "Standalone Mode Only" header and team-mode note to Reviewer Prompt Template section
- Removed trailing blank lines
- Fixed duplicate Rule 3 numbering (renumbered to 3-6) — coherence fix

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description to 250-char limit, simplified Execution Mode Detection, compressed Delegation Protocol and Audit Trail. Net -29 lines.

### Changes
- Trimmed description from 271 to ~195 chars — removed trailing example list
- Replaced 10-line Execution Mode Detection with 2-line conditional (-8 lines)
- Compressed Delegation Protocol from 22 to 10 lines — inlined JSON schema, merged steps
- Compressed Audit Trail table from verbose 3-column to concise 2-column format (-4 lines)
- Added explicit `team_name` to `TeamDelete()` call for consistency with all other skills (coherence)

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added honest consensus integrity directive and reviewer honesty instruction; trimmed redundant audit verification procedure, mapping freshness note, and description. Net -15 lines.

### Changes
- Added "Consensus integrity over false agreement" directive after coordinator role statement (+5 lines)
- Added honest-reviewer instruction to Reviewer Prompt Template (+3 lines)
- Removed redundant Verification Procedure bash block — Audit Questions table is sufficient (-14 lines)
- Removed "Mapping freshness" maintenance note — meta-documentation, not executable (-3 lines)
- Tightened description to ~240 chars, front-loading key use case per 250-char limit (-6 lines)

### Dimensions Evaluated
Cross-Skill Coherence, Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Trimmed identity verdict mapping, folded Phase 3 into Phase 4, removed mid-protocol notification, upgraded effort to max. Net -22 lines.

### Changes
- Removed identity verdict mapping table (approve->approve) left over from request-changes removal (-12 lines)
- Folded Phase 3 (Quorum Evaluation) into Phase 4 — single command doesn't warrant its own phase (-7 lines)
- Removed "all reviews collected" operator notification — redundant with outcome notification (-3 lines)
- Replaced non-standard "ultrathink" directive with concrete reasoning instruction
- Scoped Mermaid diagram requirement to escalation reports only
- Upgraded effort from high to max for Opus 4.6 multi-agent coordination

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Actionability, Coherence, Orchestration & Agent Teams, Completeness, Spec Alignment, Rename

### Rename
No rename.


## 2026-03-21

### Summary
Added operator observability via `[VOTE]`-prefixed SendMessage notifications at phase transitions; removed unsupported `request-changes` reviewer verdict.

### Changes
- Added SendMessage notification to operator after proposal creation (Phase 1) with `[VOTE]` prefix
- Added SendMessage notification to operator after all reviews collected (Phase 2)
- Added `[VOTE]` prefix to existing Phase 4 SendMessage calls for consistent filtering
- Removed `request-changes` from reviewer verdict options and mapping table (not a valid `docket vote cast` verdict)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant explanations, consolidated View Change section, added --findings-json support.

### Changes
- Removed verbose stdin piping explanation from Phase 1 (-1 line)
- Added `--findings-json` as alternative to `--findings` in Phase 2 vote casting
- Trimmed Delegation Protocol step e from 3 to 2 lines
- Simplified argument handling description
- Consolidated View Change Constraints into parent section (-5 lines, +1 folded)

### Dimensions Evaluated
Over-Engineering, Completeness, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Fixed CLI flag usage to match docket vote capabilities; corrected verdict mapping; added `docket vote commit` for finalizing proposals.

### Changes
- Used dedicated `--rationale`, `--domain-tags`, `--files-changed` flags on `docket vote create`
- Fixed verdict mapping: `approve-with-concerns` is a native CLI verdict
- Added `--summary` flag to `docket vote cast` command template
- Added `docket vote commit` step to Phase 4 when quorum is reached
- Removed redundant rule 5 and obsolete "Behavioral change" note

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Added full agent team lifecycle (TeamCreate/TaskCreate/TaskUpdate/TeamDelete) to align with all other skills.

### Changes
- Added TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, TeamDelete to allowed-tools
- Added team creation and task creation to Pre-flight (steps 5-6)
- Updated reviewer spawn template to include team_name parameter
- Added task assignment and TaskList monitoring to Phase 2
- Added TaskUpdate completion instruction to reviewer template
- Added Wrap-up & Team Cleanup section with shutdown and TeamDelete
- Added rules 1 (create team before spawning) and 7 (clean up the team)

### Dimensions Evaluated
Orchestration Effectiveness, Coherence with Other Skills

### Rename
No rename.

## 2026-03-20

### Summary
Fixed inconsistent `$ARGUMENTS` references to align with the skill's own `{proposal}` convention.

### Changes
- Replaced `$ARGUMENTS` in Pre-flight step 2 with plain language matching `{proposal}` convention
- Replaced `$ARGUMENTS` in Phase 1 Pre-Prepare with plain language matching `{proposal}` convention

### Dimensions Evaluated
Coherence with other skills (argument handling consistency)

### Rename
No rename.

## 2026-03-20

### Summary
Removed unused team tools from frontmatter, added SendMessage cross-communication for result reporting, and trimmed redundant content.

### Changes
- Removed TeamCreate/TeamDelete from allowed-tools (unused — vote spawns ephemeral agents, not teams)
- Added SendMessage instructions in Phase 4 for reporting results to invoking agents
- Added SendMessage to view-change escalation path
- Removed redundant "records are permanent" statement
- Removed redundant rule 2 (quorum arithmetic) — duplicates Phase 3 statement

### Dimensions Evaluated
Skill Design Quality, Orchestration Effectiveness & Cross-Communication, Over-Engineering

### Rename
No rename.

## 2026-03-20

### Summary
Added `effort: high` frontmatter, trimmed reviewer prompt scales, enabled ultrathink for deep reasoning, and consolidated duplicate rules.

### Changes
- Added `effort: high` frontmatter (new Claude Code capability)
- Trimmed confidence/domain_relevance scale descriptions in reviewer prompt (-6 lines)
- Added ultrathink trigger to reviewer prompt template for extended thinking
- Removed redundant request-changes verdict explanation (-1 line, implicit in formula)
- Consolidated rules 1+2 into single independence rule (-1 line)
- Renumbered Rules section (was 1,2,4,5,6,7 — now 1-6)
- Added "This applies to ALL agents spawned by this skill." to CRITICAL banner

### Dimensions Evaluated
Skill Design Quality, Completeness, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Added coherence conventions, removed duplication, and fixed Claude Code anti-patterns.

### Changes
- Added TeamCreate/TeamDelete to allowed-tools (convention alignment with dev/specs)
- Added no-commit guard (convention alignment with all other skills)
- Removed duplicate quorum threshold table (verbatim copy in Phase 3)
- Replaced Bash cat-redirect with Write tool for consensus records
- Trimmed consensus record schema (removed nested proposal duplication)
- Consolidated code review agent selection rows
- Removed redundant request-changes/reject usage guidance

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Coherence with Other Skills, Actionability

### Rename
No rename.
