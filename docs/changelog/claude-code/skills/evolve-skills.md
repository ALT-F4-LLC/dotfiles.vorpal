# Changelog: evolve-skills

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-07-17..2026-07-17) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: scoped two ownership claims in the DKT-106 shared orchestration-core reference (recorded here as this cycle's driver — the reference file has no dedicated changelog family).

### Changes
- AMPLIFY[SUBSTANTIVE]: Hybrid-block note now states that "fully single-homed" describes the CANONICAL BLOCK, not the whole carrier section, and points at §Genetic-Drift Operator's carve-out — the unqualified claim invited trimming protected carrier-local prose.
- AMPLIFY[SUBSTANTIVE]: §Crash & Stall Recovery gained a carrier-scope carve-out — each carrier's like-named heading also hosts the §Second-Failure Recovery pointer and a local-only Compaction-recovery bullet; ownership reads off per-bullet pointers, not the heading. Cited signal: this cycle's Phase 2 had to restore a dropped Compaction-recovery bullet in evolve-agents.

### Dimensions Evaluated
Multi-reading, overlapping-ownership (both applied); confusable-name (none found in this file).

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: trimmed the un-parity-enforced Crash & Stall detection-triad restatement to a bare pointer per the shared doc's fully-single-homed design.

### Changes
- Crash & Stall: bare pointer + Phase-0 read-once/ABORT clause replaces the inline triad (applied lockstep with evolve-config's identical paragraph).

### Dimensions Evaluated
Coherence, shared conventions.

### Rename
No rename.

## 2026-07-27

### Summary
DKT-106: single-homed Scientific Trial Protocol (compressed hybrid), Genetic-Drift Operator (full extraction), Shutdown Protocol, Crash & Stall Recovery, Second-Failure Recovery, and Phase 3 Disambiguation Charter/Boundary into the new shared evolve-orchestration-core.md, mirroring this file's own existing Phase-0 template-sourcing convention. Net -2,686 bytes (60,641 → 57,955). Findings: 15 → 7 sub / 0 cos / 1 rej / 5 def / 2 enc

### Changes
- CULL[SUBSTANTIVE][DKT-106]: Trial-Protocol compressed to a hybrid restatement (HARD GATE scope stays inline); Genetic-Drift-Operator fully extracted (its own per-carrier target-selection paragraph stays local, not extraction-safe); Shutdown+Crash&Stall+Second-Failure and Phase 3 charter/boundary/mechanism fully extracted; Operator-Prompts-Convention restored inline as a hybrid restatement after cross-reviewer reconciliation (API-shape constraints stay visible).
- AMPLIFY[SUBSTANTIVE][D1/D2/D3]: dimension 1 gains `when_to_use` + the 1,536-char combined cap, the `context: fork`/`background: false` tool-stripping guardrail, and the 5,000-token retention cap as the byte budget's platform-mechanical rationale.
- AMPLIFY[SUBSTANTIVE][I1]: phase gates wired as `addBlockedBy` edges at TaskCreate time — zero usage before.
- I9/I10/I11/D6 DEFERRED (script/registry follow-ups, family-wide frontmatter); D4 REJECTED (no Bash() rules to substitute into); H8/D7 ALREADY-ENCODED.
- The untagged compaction-recovery bullet was explicitly NOT reconciled — it is a recorded 2026-06-19 DRIFT allele (seed 6f0ab504, pick 4) in evolve-config's compacted history; extracting/reconciling it would have silently reverted an operator-approved trial.

### Dimensions Evaluated
All 8. Spec Alignment vacuous (docs/spec/ absent repo-wide). Rename: none.

### Rename
No rename.

## 2026-07-24

### Summary
Compacted 5 entries (2026-07-13..2026-07-14) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Phase 3 disambiguation: two self-referential ambiguities. (1) The Phase 3 table names the canonical `gold` tier while the template pins the Trial-downgraded `model="opus"` — added a note reconciling the two so a future cycle doesn't read the table entry as drift. (2) The Phase-1 lifecycle row's "per agent: apply changes → shut down" left the actor for "apply"/"shut down" implicit (reviewer or orchestrator?).

### Changes
- CLARIFY[COSMETIC]: added a **Reviewer-tier note** before **Self-budget** reconciling the table's `gold` entry against the Phase 3 template's active `Trial:` downgrade to `model="opus"`.
- CLARIFY[COSMETIC]: Phase-1 lifecycle row "Spawn parallel → per agent: apply changes → shut down" → "Spawn parallel → as each reviewer completes: orchestrator applies its changes → shut it down" — names the orchestrator as actor.

### Dimensions Evaluated
Coherence (disambiguation pass, Two-arm Boundary test — passed Arm 1 coherence, failed Arm 2 clarity).

### Rename
No rename.

## 2026-07-24

### Summary
Parity-defer paragraph gains the lockstep artifact-existence guard (lockstep with evolve-agents/evolve-config). Own Phase-3 closing paragraph already removed in Phase 1 (verified gone).

### Changes
- AMPLIFY[SUBSTANTIVE]: artifact-existence guard appended after the NO-OP sentence.

### Dimensions Evaluated
Coherence. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Trial: downgrade disambiguation-reviewer fable→opus → operator-approved, applied (baseline: distinguished-engineer 7d spawns 100% fable; TeammateIdle flagged as weak/role-confounded discriminator; adopt/rollback measured next cycle's Phase 3 finding + misroute counts). Self-review: added the concurrent-subagent batching guard (D4) and culled four redundant restatements. Findings: 7 → 3 sub / 0 cos / 0 rej / 2 def / 2 enc

### Changes
- TRIAL[SUBSTANTIVE]: disambiguation-reviewer model="fable"→"opus" — operator-approved 2026-07-24; next cycle's Phase 0 measures adopt/rollback per the criteria in this cycle's Phase 1 report.
- AMPLIFY[SUBSTANTIVE][D4]: Phase 1's "spawn all in the same turn" now gates on the concurrently-running-subagent cap (default 20, CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS env override), prescribing waves of ≤20 — cited this cycle's live failure boundary at 22 targets, which the orchestrator hand-batched into 2 waves.
- CULL[COSMETIC]: removed the trailing "Always run this stage..." paragraph after the Phase 3 template — restated §Phase 3 Mechanism and §Shutdown protocol verbatim.
- CULL[COSMETIC]×3: removed "Skip if pre-flight step 8 flagged SKIPPED" from the Model Routing / Repetition / Bug Audit template preambles — §Phase 0 already gates all four auditors on that flag.
- D5 (shared file, by review-team-doctrine): APPLIED-SUBSTANTIVE, all 8 occurrences fixed in evolve-phase0-templates.md.
- I-evolve-skills-2/3: DEFERRED. H-evolve-skills-1/2: ALREADY-ENCODED.

### Dimensions Evaluated
All 8. Spec Alignment vacuous (docs/spec/ absent repo-wide).

### Rename
No rename.

## 2026-07-22 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-07-12..2026-07-13) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-22

### Summary
Phase 3 disambiguation: family-wide lockstep rewording of the CANONICAL:PHANTOM-PATH-GUARD parenthetical (byte-identity across 5 carriers).

### Changes
- PHANTOM-PATH-GUARD: "(unlike every other skill in the fleet)" → "(every other skill in the fleet lives EXCLUSIVELY under `src/user/claude-code/skills/`; no skill is dual-homed)" — the "counterpart" wording supported a dual-homing reading that could mint the inverse `.claude/skills/<non-evolve>` phantom path.

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-22

### Summary
Phase 2 coherence: phantom-path-guard paragraph promoted to CANONICAL:PHANTOM-PATH-GUARD (I4) — in-file wrap + doctrine_check_manifest.tsv registration, 5 evolve-* carriers, byte-parity now mechanized.

### Changes
- AMPLIFY[SUBSTANTIVE][I4,D4]: wrapped the evolve-* location caveat in CANONICAL:PHANTOM-PATH-GUARD markers; registered 5-carrier tag in doctrine_check_manifest.tsv (no strip-transform — zero per-file tail verified). doctrine_check.sh Arm (c) now enforces parity.

### Dimensions Evaluated
D4 canonical-block parity (primary); D1/D3 re-verified clean.

### Rename
No rename.

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-07-10..2026-07-12) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Coherence pass: crash/stall core fenced, preflight single-homing, PM-delegation path guard, phantom-path note tail normalized.

### Changes
- Fenced detection/nudge/re-spawn as CANONICAL:CRASH-STALL-CORE; re-spawn bullet normalized to the shared 3-carrier wording
- Pre-flight step 3 now consumes evolve_preflight.sh's today_date=/scratchpad= output instead of hand-rolling (DKT-292)
- Pitfalls-triage: verify cited target paths resolve on disk before delegating tracking-issue creation
- Phantom-path guard note tail normalized so all 5 evolve-* copies are byte-identical

### Dimensions Evaluated
Coherence, terminology consistency, reference accuracy, parity enforcement.

### Rename
No rename.

## 2026-07-20

### Summary
Added an evolve-* phantom-path guard note after the DOCS-PATHS-LOCAL block: the 5 evolve-* skills live only under .claude/skills/ and must never be cited under a src/user/claude-code/skills/evolve-* path (L27; corroborated by bug-auditor WRONG-PATH class, 3 sessions). Findings: 3 → 1 sub / 0 cos / 1 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: added phantom-path guard after DOCS-PATHS-LOCAL — states evolve-agents/-coherence/-config/-model-distribution/-skills exist ONLY under .claude/skills/ with no src/user/claude-code/skills/evolve-* counterpart; bans citing such a path in PM issues/spawn prompts/briefs. Verified via find this cycle; placed outside the CANONICAL block (a -LOCAL, non-byte-parity block) to avoid drift checks. Cited signal: L27 + bug-auditor FIX 3.
- REJECTED: L48 (split when_to_use:) — description frontmatter is 310 chars, far below the 1,536-char cap; no split warranted.
- DEFERRED: L20 (CANONICAL-fence triplicated Crash & Stall Recovery text) — cross-skill parity-bound, routed to Phase 2.

### Dimensions Evaluated
Coherence (accurate references); Actionability. Byte budget: 58,570 → 59,126 (BALANCED, SUBSTANTIVE un-offset, under 65,000).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-06-04: Fixed live `/evolve-skills days=7` all-skills pattern — pre-flight guards no longer treat `days=N` as skill name; Parsing rule strips window token first; net +2.
- 2026-06-05: Trimmed redundant Phase 1 reviewer read-list recap from template-forwarding sentence (already verbatim in spawning template); net 0; symmetric with evolve-agents.
- 2026-06-08: Trimmed historical-auditor "never bulk-cat ~/Development" clause (duplicated in CANONICAL:HARVEST); net 0 in-line shorten; parity-bound with evolve-agents.
- 2026-06-19: Phase 2 coherence — added concrete stall threshold; culled "CANONICAL tag" from biodiversity niche-token filter (correctness defect).
- 2026-06-20: Compacted 7 entries (2026-06-04..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-20: Phase 2 self-edit — pinned model= (aliases) on all 8 Agent() spawns; added $TMPDIR scratch guard to shell-heavy auditor Rules. No line growth.
- 2026-06-09: NO-OP Phase 1 (360 lines) — 4 parity-bound items routed to Phase 2; headline: correction-regex FP guard excludes teammate-message/command-output turns.
- 2026-06-09: Phase 2 — historical-auditor FP guard, budget-truth wording mirrored from evolve-agents, WebFetch added to allowed-tools; Coherence + Actionability.
- 2026-06-09: Three mid-run-safe additions (360→359): docs-researcher repo-adoption grep gate, Phase-1 $-escape reviewer flag, rename-sweep LIVE-file scoping; 2 parity-bound with evolve-agents.
- 2026-06-09: NO-OP Phase 1 (378 lines) — `\$ARGUMENTS` escape routed to Phase 2 lockstep; harness-redundant Read-before-Edit prose rejected; $+digit audit clean.
- 2026-03-19: Added Pre-flight section with 5 validation steps; WebFetch graceful degradation; argument matching for both skill paths.
- 2026-03-19: Closed date passthrough gap — {today_date} added to Phase 1/2 spawning templates.
- 2026-03-19: Added allowed-tools frontmatter; trimmed Phase 0 output scaffolding; consolidated orchestrator-only-edits statements.
- 2026-03-19: Restored Phase 0 output format bullets for evolve-agents alignment; added TeamCreate/TeamDelete to allowed-tools.
- 2026-03-19: Condensed Argument Handling 16→4 lines; removed generic agent SDK boilerplate (499→485).
- 2026-03-20: Added effort: high; trimmed Phase 2 preamble; fixed TaskCreate/TaskUpdate/TaskList parameter names; rejected Phase 0 removal.
- 2026-03-20: Trimmed Phase 0 template verbosity; consolidated changelog rules; $ARGUMENTS reference added.
- 2026-03-20: Fixed docket vote start → docket vote create; Phase 1 template back-references Content Gate and dimensions; context: fork added.
- 2026-03-20: Removed phantom ToolSearch step; consolidated docket audit template; rejected context: fork (breaks agent teams).
- 2026-03-21: Added observability report to Wrap-up (cross-communication, votes, course-corrections); expanded Dimension 1 frontmatter checks.
- 2026-03-29: Trimmed over-engineered content; immediate per-agent Phase 1 shutdown; effort high→max; docs-researcher template 25→6 lines.
- 2026-03-30: Added honest-mentor directives to orchestrator identity and Phase 1 template; consolidated Fail-loud + timeout rules.
- 2026-03-30: Trimmed description 758→~185 chars; removed duplicate experience-feedback section; fixed shutdown syntax.
- 2026-04-06: Added anti-sub-agent-spawning instructions at orchestrator, Phase 1, and Phase 2 levels; removed vote invocations from wrap-up.
- 2026-04-16: Removed dead {focus_areas} variable; Over-Engineering promoted to HIGHEST PRIORITY in main dimension list.
- 2026-04-16: Centralized Agent Lifecycle rules; explicit Phase 1 SendMessage triggers; Phase 2 handoff gate; removed duplicate rules (328→316).
- 2026-04-22: Hardened crash recovery: Rule #10 stall/crash signals, shutdown-timeout fail-forward, single re-spawn (316→313).
- 2026-05-04: Trim pass: orchestrator-identity restatements, vague Rule #12 removed, consolidated Pre-flight inventory steps (313→304).
- 2026-05-05: Adopted paths: frontmatter and Monitor tool; merged critical-rules blockquotes; concrete Phase 1→2 cross-cutting handoff (304→303).
- 2026-05-05: Eliminated free-text operator prompts in favor of structured AskUserQuestion; operator-prompts blockquote added (299→314).
- 2026-05-05: Trimmed Pre-flight AskUserQuestion verbosity; justified no-peer-to-peer policy; lifecycle table for evolve-agents parity (314→295).
- 2026-05-05: Phase 2 coherence: inlined Argument Handling validation note for evolve-agents parity.
- 2026-05-06: Removed unverified disable-model-invocation from Dimension 1; docs-researcher template asymmetry trimmed; mode threshold tightened (295→288).
- 2026-05-06: Phase 1 aligned with evolve-agents: Crash & Stall Recovery section extracted, multiSelect Pre-flight step 2, numbered post-review loop.
- 2026-05-06: Rules section collapsed 10→4 (duplicates of CRITICAL block, ordering, Changelog Format, Content Gate); Phase 2 ## Task parity (294→287).
- 2026-05-07: Phase 2 coherence: /evolve-skills dev example changed to tdd — dev skill deleted earlier this cycle.
- 2026-05-07: Self-evolution trim: collapsed orchestrator identity block, removed Self-evolution blockquote, trimmed Dimension 5 (287→278).
- 2026-05-09: Trimmed Phase 1 template Context self-referencing bullets; Pre-flight step 1 forward-reference removed (278→275).
- 2026-05-09: Inlined 8 evaluation dimensions in Phase 1 reviewer template; paths: declared; Size Budget block restored.
- 2026-05-09: Seven trim + parity fixes: CANONICAL banner markers, stale paths reference dropped, Wrap-up numbered list (net -8).
- 2026-05-13: Collapsed top-level Evaluation Dimensions to a pointer; operator-prompts blockquote reordered; Dimension 4 wording restored (290→282).
- 2026-05-13: Removed orphan Evaluation Dimensions pointer block entirely — dimensions live in Phase 1 template (net -6).
- 2026-05-16: Wired friction-driven-evolution payload contract end-to-end; cross-root collision handling; removed duplicate Rule 1.
- 2026-05-16: Operator-prompts banner extended with multiSelect+fixed-catalog carve-out to match 6-option step 2 usage.
- 2026-05-17: Corrected false multiSelect-lifts-4-option-cap carve-out (API hard-rejects >4, verified live); step 2 collapsed to 4 options.
- 2026-05-17: Phase 2 sister-parity trim: condensed Phase 1 template Size Budget block from 2 lines to 1 line, matching evolve-agents' equivalent trim applied earlier this...
- 2026-05-18: Closed the historical-auditor ISO→epoch-ms conversion gap that produced the wrong cutoff (1808066891000 = 2027-04-18 instead of 2026-04-18) in this cycle's a...
- 2026-05-20: Two sister-parity trims (Phase 1 Context clause restating section headers below; Phase 0 Distinction-from-friction negative-form tail duplicating affirmative...
- 2026-05-25: Five changes: trimmed Phase 1 post-review-loop shutdown bullet (duplicates lifecycle table), trimmed orchestrator-identity workflow restatement, bolded Phase...
- 2026-05-28: Phase 2 coherence: added "Always run Phase 2" parity rule (matching evolve-agents Rule 1), consolidated SKIPPED-skip guidance in tandem with evolve-agents (4...
- 2026-05-28: Closed coordination/handoff gaps: de-dup transcript counts in the historical-auditor (raw grep hits ~10x inflated by replication), made the re-invocation sig...
- 2026-05-29: Added a scope-confirmation HARD GATE to Pre-flight (new step 9), achieving parity with evolve-agents step 7 (Phase 2 coherence).
- 2026-05-30: Added a Phase-0-findings-are-signals-not-facts rule to the Phase 1 template, governing both the Docket CLI and Historical audit blocks — closes the recurring...
- 2026-06-09: Phase 2 parity fix — escaped 5 documentary `\$ARGUMENTS` occurrences, lockstep with evolve-agents; net 0 (378 lines).
- 2026-06-09: Compacted 35 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001.
- 2026-06-10: No edits (491 lines) — days= plumbing complete; 3 innovation suggestions rejected as over-engineering/regression.
- 2026-06-10: Compacted 8 entries (2026-05-17..2026-05-30) into Compacted history per ADR 0001.
- 2026-06-10: Introduced evolutionary-theory core — CANONICAL:EVOLUTION-MODEL, selection dispositions, Genetic-Drift Operator, Scientific Trial Protocol.
- 2026-06-10: Drift-only cycle — heading & DOCS-PATHS-LOCAL reorder trials, no reviewer edits (498 lines). | Drift: heading "Phase 0: Historical Audit (per-skill)" → "(one block per target skill)" (seed 124bf552, i=229) → applied, net 0. | Drift: DOCS-PATHS-LOCAL Reads-list reorder (seed 124bf552, i=230) → proposed (operator declined — CANONICAL-maintained block).
- 2026-06-10: Phase 2 coherence (lockstep evolve-agents) — apply step 2 gains Read-before-Edit, re-Read-after-grep/mv, 1:1 Edit↔CHANGE discipline; line-neutral.
- 2026-06-19: BUG fix (docket-auditor scope) + day= alias + Read(limit=80) AMPLIFYs, drift rewords, net-zero. | Drift: Changelog-Format read-latest clause reworded (seed 6f0ab504, pick 5) → applied. | Drift: Crash & Stall "Re-spawn ONCE" bullet reworded (pick 6) → applied. | DRIFT: Changelog-Format read-latest clause reworded — neutral, pick 5, net 0. | DRIFT: Crash & Stall "Re-spawn ONCE" → "Re-spawn exactly once" — neutral, pick 6, net 0.
- 2026-06-30: Fixed live zsh-nomatch glob-abort across 4 inventory/changelog glob sites; added last-run preamble for re-run confirmation.
- 2026-06-30: Pre-flight pinned two Codex skill roots; Phase 1 budget honors prompted caps including the 535-line self-budget.
- 2026-06-30: Restored evolve-agents/evolve-skills symmetry for innovation and model-routing audit text.
- 2026-07-10: Removed redundant Phase 2 coherence steps 6-8 (mechanized by symmetry_check.py); fixed stale top-level `skills/` root blind to 15 skills.
- 2026-07-10: Phase 2 coherence — aligned docs-paths citation to relocated team-doctrine reference. ~3,352B over 65,000 hard limit (operator-gated).
- 2026-07-11: Operator-directed doctrine change — Phase 2/3 reviewers switched staff-engineer/opus → distinguished-engineer/fable, parity w/ evolve-agents.
- 2026-07-12: Self-review — fixed never-existent docs/changelog/skills path (zeroed compaction gate); stale @staff-engineer labels (actually DE).
- 2026-07-12: Adopted cache-first changelog fetch in lockstep with evolve-agents/evolve-config.
- 2026-07-12: Compacted 5 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.
- 2026-07-13: Phase 2 coherence — retired six stale skills/agents root references; EVOLUTION-MODEL lockstep; docket-auditor report-back line.
- 2026-07-13: Phase 3 disambiguation: the Phase 3 spawn template's charter pointer is now self-resolving for the spawned reviewer. Findings: 1 → 1 sub
- 2026-07-13: Compacted 3 entries (2026-06-10..2026-06-19) into Compacted history per the retention-compaction policy.
- 2026-07-14: Wired check_citations.py into the Phase-2 coherence check to mechanize stale repo-layout path-literal detection. Findings: 7 → 1 sub / 0 cos / 0 rej / 3 def...
- 2026-07-14: Propagated nudge-before-respawn + API-error crash signal from evolve-agents' Crash & Stall Recovery; added a post-cycle /evolve-coherence pointer to Wrap-up...
- 2026-07-14: Compacted 3 entries (2026-06-19..2026-06-20) into Compacted history per the retention-compaction policy.
- 2026-07-17: Targeted cycle (self-review, 1 of 4 sibling skills sharing a 3-item mandate) — applied I5(a) cosmetic strip, confirmed P3 gold tier-split already correct; docs-researcher rename + I4/I5b parity fixes deferred to Phase 2.
- 2026-07-17: Phase 2 family-wide lockstep: applied docs-researcher→docs-researcher-phase0 rename + 2 parity-bound findings (I4 findings_ledger_check.py wiring, I5b innovation-scanner-relocation clause strip) across evolve-agents/evolve-skills/evolve-config/template.
- 2026-07-17: coherence-reviewer Phase 2 pass added mechanized doctrine_check.sh byte-identity check after the manual grep-based check in Phase 2 apply instructions; parity-bound with evolve-agents.
- 2026-07-17: Compacted 4 entries (2026-06-30..2026-07-10) into Compacted history per the retention-compaction policy.
