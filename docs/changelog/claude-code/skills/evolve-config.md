# Changelog: evolve-config

## 2026-07-22 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-30..2026-07-10) into Compacted history per the retention-compaction policy.

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
Compacted 3 entries (2026-06-30..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Coherence pass: crash/stall core fenced, preflight single-homing (step-6), PM-delegation path guard, phantom-path note added.

### Changes
- Fenced detection/nudge/re-spawn as CANONICAL:CRASH-STALL-CORE (fence-only; bullets already matched normalized wording)
- Pre-flight step 3 now consumes evolve_preflight.sh's today_date=/scratchpad= output (step-6 run) instead of hand-rolling
- Pitfalls-triage: verify cited target paths resolve on disk before delegating tracking-issue creation
- Added byte-identical evolve-* phantom-path guard note after DOCS-PATHS-LOCAL

### Dimensions Evaluated
Coherence, terminology consistency, reference accuracy, parity enforcement.

### Rename
No rename.

## 2026-07-20

### Summary
Wired config_render_diff.sh (empirically unreferenced by any skill) into the Content Gate Behavioral check + Phase 1 step 3 as its mechanization — honestly gated on the missing claude_code.rs render target (DKT-309), serde-attribute read stays primary. Consolidated the Phase 2 template's duplicated doctrine_check.sh paragraph into a single-home reference to offset the additions.

### Changes
- AMPLIFY: Content Gate Behavioral check + Phase 1 step 3 now cite `config_render_diff.sh` as the byte-diff mechanization of "does this setter change settings.json" — cited signal: L25 (script exists, zero skill/agent references) + sdet memory (L24) that same-session runtime verification is impossible. Gated explicitly: no render target prints the full config yet, so no overclaim.
- CONSOLIDATE: Phase 2 spawn template step 3 references the authoritative doctrine_check.sh procedure in SKILL.md §Phase 2 step 3 instead of restating it verbatim — removes the two-copy drift surface that caused the 2026-07-13 Phase 2 fix.

### Dimensions Evaluated
Content Gate / verification tooling (AMPLIFY); Hooks & scripts, Redundancy (CONSOLIDATE); Core & model-routing / Permissions / Sandbox / Skills & auto-mode / Plugins-UI-governance (RETAIN). L24 confirmed already-documented (lines 177, 234) — no-op.

### Rename
No rename.

## 2026-07-17 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-19..2026-06-20) into Compacted history per the retention-compaction policy. First compaction for this file — created the terminal Compacted history section.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-17

### Summary
Phase 3 disambiguation: clarified the reviewer-tier note's roster parenthetical so it cannot be read as delegitimizing the sibling skills' gold reviewer seats.

### Changes
- Reworded the P3 tier-note parenthetical - distinguished-engineer.md listing neither reviewer supports silver HERE; it is not evidence against the evolve-agents/evolve-skills gold seats (multi-reading resolved; claims re-verified against staff-engineer.md:48 and distinguished-engineer.md).

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership).

### Rename
No rename.

## 2026-07-17

### Summary
Phase 2 family-wide lockstep application: the docs-researcher rename (P1, bespoke inline copy), deferred from this cycle's Phase 1 pass, applied in lockstep with the shared canonical template + evolve-agents + evolve-skills.

### Changes
- AMPLIFY[SUBSTANTIVE]: renamed bespoke Phase-0 `docs-researcher` -> `docs-researcher-phase0` (9 occurrences) - lockstep with evolve-phase0-templates.md:422 + evolve-agents (8 occ) + evolve-skills (8 occ). team-lead.md's bronze docs-researcher untouched (P1).

### Dimensions Evaluated
Rename, Coherence.

### Rename
docs-researcher -> docs-researcher-phase0 (bespoke inline Phase-0 auditor instance; team-lead.md's docs-researcher is a separate, untouched agent).

## 2026-07-17

### Summary
Targeted cycle (one of 4 sibling skills sharing a 3-item mandate). Applied I9 (retired self-contradicting hardcoded CANONICAL enumeration, 2 sites), P3 rationale (KEEP silver - grounded in staff-engineer.md's own spawn list), and H9 (symmetric forward-fitness-signal gate on wiring a dead setter). Rename (P1, bespoke inline copy, 9 occurrences) deferred to Phase 2 for lockstep with the shared template + siblings.

### Changes
- CULL[SUBSTANTIVE]: deleted the hardcoded 8-block CANONICAL enumeration at 2 sites (Phase 2 prose + template) - self-contradicted the "manifest-is-authority, not a hand-count" instruction it prefaced (I9; subsumes phantom-HARVEST H8, already-fixed).
- AMPLIFY[SUBSTANTIVE]: reviewer-tier rationale note documenting the intentional silver-here/gold-there split (P3) - grounded in staff-engineer.md:48 owning coherence-reviewer; distinguished-engineer.md owns neither reviewer.
- AMPLIFY[SUBSTANTIVE]: symmetric forward-fitness-signal gate on WIRING a dead setter, not just CULLing one (H9, staff-engineer/pitfalls.md:595).

### Dimensions Evaluated
Rename (P1, Phase 2), Coherence, Over-Engineering, Actionability, Orchestration & Agent Teams.

### Rename
Deferred to Phase 2: docs-researcher -> docs-researcher-phase0 (9 occurrences, bespoke inline copy), lockstep with evolve-phase0-templates.md + evolve-agents + evolve-skills.

## 2026-07-14

### Summary
Coherence-class fix surfaced during Phase 3: replaced two stale "five CANONICAL blocks" hand-counts with a manifest-anchored instruction — this cycle's doctrine_check_manifest.tsv edit registered this file as a carrier of 8 tags, not 5.

### Changes
- Phase 2 prose + coherence-reviewer template (2 locations): "the five CANONICAL blocks... (list)" → verify every `CANONICAL:<TAG>` this file carries against `doctrine_check_manifest.tsv`, naming the 8 currently-registered families explicitly.

### Dimensions Evaluated
Coherence (accurate references — routed from Phase 3 as coherence-class, not disambiguation).

### Rename
No rename.

## 2026-07-14

### Summary
Propagated nudge-before-respawn + API-error crash signal from evolve-agents' Crash & Stall Recovery (findings-ledger half not applicable — evolve-config produces no findings-ledger.md).

### Changes
- AMPLIFY: Crash & Stall Recovery gains (d) API-error self-report crash signal + a nudge-before-respawn bullet (lockstep from evolve-agents).

### Dimensions Evaluated
Coherence (family lockstep).

### Rename
No rename.

## 2026-07-14

### Summary
Extended the Hooks & scripts checklist with the Notification hook's background-agent events, documented a static-vs-runtime verification split, and guarded the CULL gate against dead-setter false signals. Findings: 5 → 3 sub / 0 cos / 1 rej / 1 def

### Changes
- AMPLIFY[SUBSTANTIVE]: added `Notification` hook `agent_needs_input`/`agent_completed` to item-4 hook-event checklist (I14) — cited innovation+docs signal, verified live at code.claude.com/docs/en/hooks.
- AMPLIFY[SUBSTANTIVE]: Phase 1 step 3 now states serialization checks are static-only; enforcement is runtime, deferred to next-cycle Phase 0 (H3) — cited sdet/pitfalls.md:78-80.
- AMPLIFY[SUBSTANTIVE]: Phase 1 template CULL gate now excludes bare dead-setter observations as fitness signals (H4) — cited staff-engineer/pitfalls.md:595 / DKT-282.

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename — all 8.

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): charter pointer made self-resolving; two spawn-prompt openers no longer read as delegation instructions. Findings: 3 → 3 sub

### Changes
- AMPLIFY[SUBSTANTIVE]: Phase 3 template charter citation names `.claude/skills/evolve-config/SKILL.md` §Phase 3 (was a dangling "section above")
- AMPLIFY[SUBSTANTIVE]: Phase 2/3 spawn-prompt openers "Use the @staff-engineer agent to X" → direct imperative "X" — the old form reads as a delegation instruction to the recipient, contradicting the template's own no-sub-agents rule; siblings already use the imperative

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: corrected the six→five CANONICAL-block self-description (HARVEST is single-homed in evolve-phase0-templates.md §2, not carried here); fixed two dead `agents/` root references; EVOLUTION-MODEL lockstep.

### Changes
- Phase-2 workflow prose + spawn template no longer instruct reviewers to find a nonexistent in-file HARVEST block (phantom-drift hazard).
- Shutdown-protocol team-lead.md citation and biodiversity-invariant grep scope now use `src/user/claude-code/agents/`.
- CANONICAL:EVOLUTION-MODEL header now names all 4 carriers (lockstep).

### Dimensions Evaluated
Coherence (carrier-set accuracy, reference accuracy, CANONICAL parity).

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Trigger scoped to the skill's actual target; corrected a stale CANONICAL-block count (said four, file carries six); aligned the `day=N` alias with evolve-skills/evolve-agents. Findings: 3 → 3 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: trigger "review config" → "review config sources" — the bare phrase was indistinguishable from a lightweight read request or a bundled update-config errand, yet launches a full xhigh multi-agent cycle
- AMPLIFY[SUBSTANTIVE]: Phase 1/2 coherence-verifier tasks now correctly enumerate all six CANONICAL blocks (BANNER, EVOLUTION-MODEL, DOCS-PATHS-LOCAL, SOURCE-OF-TRUTH, HARVEST, DISAMBIGUATION-CHARTER) instead of four — HARVEST and DISAMBIGUATION-CHARTER were silently escaping the parity-verification list
- AMPLIFY[SUBSTANTIVE]: Argument Handling — documented `day=N` as an accepted alias for `days=N`, matching evolve-skills

### Dimensions Evaluated
Disambiguation (confusable-name, internal count mismatch, argument-parsing family consistency).

### Rename
No rename.

## 2026-07-12 (Phase 2 coherence pass)

### Summary
Adopted cache-first changelog fetch in lockstep with evolve-agents/evolve-skills. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: pre-flight step 7 — cache-first changelog fetch via `~/.claude/cache/changelog.md` (<24h mtime), curl-refresh fallback

### Dimensions Evaluated
Efficiency (family-wide lockstep with evolve-agents/evolve-skills).

### Rename
No rename.

## 2026-07-12

### Summary
Added a `cargo check` compile-gate to Phase 1 step-3 verification — closes the Rust-compile-failure class the serde-attribute read cannot catch. No config-source changes this cycle. Findings: 6 → 1 sub / 0 cos / 0 rej / 3 def / 2 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Phase 1 step-3 now runs `cargo check` before the serde-attribute read — catches calls to non-existent setters / type errors an applied Edit could introduce (innovation-scan Rethink, executable arm verified feasible; snapshot-test arm declined — no cited fitness signal, new test infra out of scope)

### Dimensions Evaluated
Actionability / Completeness (AMPLIFY). Deferred cross-cutting: shared Phase-0 template extraction + `mimir_query.sh` (shared with evolve-agents/evolve-skills), changelog-cache adoption (Repetition FIX 2), family-shared drift/S2 verbosity trim — all routed to Phase 2. Confirmed no-ops: `display-name`/`default-enabled`/`fallback` absent (correct); `disableBundledSkills` follow-up already Declined 2026-06-12, not re-proposed.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 3 disambiguation: retuned the colliding trigger phrase "refine Claude Code settings" → "refine config sources" and added a clause naming the bundled update-config (/config) skill for live settings.json edits.

### Changes
- Description: trigger "refine Claude Code settings" → "refine config sources" + added "evolves config SOURCE not live settings.json; use bundled update-config for one-off settings edits" — removes classifier collision with bundled update-config (confusable-name). Achieves parity with sibling skills that name their bundled near-namesakes.

### Dimensions Evaluated
Disambiguation (confusable-name). Cross-evolve-* trigger set otherwise distinct on primary token.

### Rename
No rename.

## Compacted history

Entries below were compacted per the retention-compaction policy; full text in git history (see the compaction entry's date).

- 2026-06-19: Tagged Genetic-Drift CONFIG-ONLY marker; trimmed duplicate rationale; rejected 5 innovation-scanner config features (no claude_code.rs setters). | DRIFT: Crash & Stall "Compaction recovery" bullet reordered — neutral allele substitution, seed 6f0ab504 pick 4, net 0.
- 2026-06-19: Coherence trim — removed false git blame claim from config-history-auditor description; changelog-path question resolved NO-OP.
- 2026-06-20: Phase 2 — pinned model= (aliases) on all 8 Agent() spawns; added $TMPDIR scratch guard to 3 auditor Rules lines.
- 2026-06-30: Phase-3 disambiguation — resolved "genome" multi-reading; genome = Rust builder sources, settings.json = phenotype. Inline, net 0.
- 2026-06-30: Phase-2 coherence — restored 3-way Crash & Stall Recovery parity (stall clause) with evolve-agents/evolve-skills. Inline, net 0.
- 2026-06-30: Named SessionStart + MessageDisplay as candidate hook surfaces in dimension 4 (Hooks & scripts) for Phase-1 evaluation. Inline, net 0.
- 2026-06-30: Strengthened official-docs digestion, generated-phenotype verification, and setter/call-chain inventory fallback. Net 0.
- 2026-07-10: CULL removed redundant self-budget line; AMPLIFY added build-deploy-lag reminder to Wrap-up step 3 (parity with evolve-model-distribution).
- 2026-07-10: Phase 2 coherence — aligned docs-paths master citation to the relocated team-doctrine reference (was team-lead.md §copy).
