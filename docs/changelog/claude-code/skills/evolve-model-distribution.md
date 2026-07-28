# Changelog: evolve-model-distribution

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 6 entries (2026-06-30..2026-07-13) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 6 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: healed drift between the routing-proposer template's step 2b and the body's Spawn-source-authority branch by single-homing the branch in the body; scoped the stale "not a DKT-106 consumer" claim.

### Changes
- routing-proposer step 2b: now Reads the body's Spawn-source-authority branch verbatim — the condensed template copy had dropped the UNCLASSIFIED authoring bucket and the bare-name-grep fallback, which never reached the teammate.
- Crash & Stall preamble: "not a DKT-106 consumer" scoped to the Crash/Stall sections; names the live §Shutdown Protocol bare-pointer dependency.

### Dimensions Evaluated
Cross-skill coherence (Phase 2): body/template single-homing, reference accuracy.

### Rename
No rename.

## 2026-07-27

### Summary
Single-homed the shutdown protocol to a bare citation (dropping the wording variant the master flags as rejected drift), disambiguated this skill's own changelog from its Writes target, and hoisted the post-compaction gate warning above the re-attachment cut it describes. Net +458 bytes (51,189 → 51,647).

### Changes
- FIX[SUBSTANTIVE] (S1, coherence): line 104's restated §Shutdown Protocol body replaced with the bare citation used verbatim by evolve-config/evolve-skills — the master declares the section "fully single-homed — cite it, never restate it" and names the local "read the `reason`, address it, re-request" phrasing as the rejected drift. Adds the missing blank line before `### Phase 0`. (-317 B)
- ADD[SUBSTANTIVE] (H4): a note after the DOCS-PATHS block stating this skill's own history lives at `docs/changelog/claude-code/skills/evolve-model-distribution.md`, not the `model-distribution/team-lead.md` Writes target — the confusion recurred across 3 agent-memory files because the target directory is this skill's name minus `evolve-`. (+366 B)
- ADD[SUBSTANTIVE] (docs-researcher Rec #1): post-compaction re-Read note hoisted into the intro (byte ~1.9 K). Measured: the ~20 KB re-attachment cut lands inside Phase 1, leaving the Improvement-Only Mandate, both Phase-2 gates, Phase 3, Crash & Stall, and the build-deploy-lag reminder out of context — and the pre-existing warning sat at byte 49,903, below its own cut. (+572 B)
- TRIM[COSMETIC]: Crash & Stall compaction bullet reduced to a pointer at the hoisted note. (-137 B)
- FIX[SUBSTANTIVE] (coherence): Phase-2 Step 3's static hard-floor role list replaced with the live-source rule — line 296 already forbids relying on a static copy of a set it states "drifts". (-26 B)
- Companion (other file): `evolve-coherence/SKILL.md`'s D1 rubric pin for `evolve-model-distribution` line number updated to match the new post-edit line (104 → 108).
- No routing recommendation: model-routing-auditor measured ZERO in-window full-cycle spawns of this skill's own roles — insufficient volume to ground one.
- Deferred (Docket tracking): I3 (retire distribution-auditor spawn), I4 (spawn_owner_lookup.sh — highest priority, 3 fix-rounds in one day), I5 (evolve_signals.py lossy, cross-file). Deferred (Phase 2): CLAUDE_PROJECT_DIR parity (3-of-5 evolve-* skills in scope), master consumer-list gap.

### Dimensions Evaluated
All 8. Findings in Coherence (S1 + the static-list self-contradiction), Completeness/Actionability (H4), Skill Design Quality (compaction reachability), Over-Engineering (2 trims). Actionability, Orchestration & Agent Teams, Spec Alignment, Rename: clean.

### Rename
No rename.

## 2026-07-27

### Summary
History compaction: compacted the 2 oldest entries (2026-06-30, 2026-07-10) into `## Compacted history` per the retention-compaction policy — file was 304 lines, over the 300-line budget.

### Changes
- Compacted 2 entries (2026-06-30, 2026-07-10) into one-line ledger entries under a new terminal `## Compacted history` section; full text recoverable via git history.

### Dimensions Evaluated
N/A — mechanical retention-compaction pass, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation of the new spawn-source-authority branch and the OWNING-SKILL REFERRAL disposition: five residual-ambiguity fixes, plus one coherence-class fix (### Routing Changes lead sentence) and one suffix-inventory gap (`-retry`), both surfaced by Phase 3 but applied directly as small, precisely-diagnosed, single-file fixes rather than re-spawning Phase 2.

### Changes
- DISAMBIG[multi-reading]: branch step 3 now names the class floor as a SEPARATE axis from the Tier-invariant floor, reads `hard-floor role` as `review-class role` on-branch, and states REFERRAL overrides every per-class default disposition (class 1/4 REPORT included).
- DISAMBIG[multi-reading]: branch step 2 replaced the closed six-word function list with a judges/proposes-vs-gathers/transforms TEST plus an UNCLASSIFIED arm — five roles in the branch's own population (`reconciler`, `history-compactor`, `docs-researcher-phase0`, `sdlc-role-researcher`, `spec-*`) matched neither bucket.
- DISAMBIG[confusable-name]: distinguished `coherence-reviewer` (siblings' Phase-2 seat) from this skill's `coherence-verifier` (Phase-3) where both appear in the non-declared population list.
- DISAMBIG[multi-reading]: "both anchors" retitled to "both declaration sites" with the missing Per-Role Dispatch Table grep — `docs-author` is declared only there and would otherwise route into the branch wrongly.
- DISAMBIG[multi-reading]: RUNTIME-DISCIPLINE REPORT given an explicit changelog home (`REPORT:` under `### Routing Changes`), the one disposition that had none.
- FIX[SUBSTANTIVE] (coherence-class, applied directly): `### Routing Changes` lead sentence no longer contradicted its own body (said "one bullet per applied edit" while housing `Trial:`/`REPORT:`/`REFERRAL:`, none of which are edits) — reworded to "one bullet per operator-dispositioned proposal".
- FIX[SUBSTANTIVE] (coherence-class, applied directly): branch step 1's stem-suffix inventory gained `-retry` (vote/SKILL.md:188's live retry convention) alongside `-r2`/`-fix-{N}`.

### Dimensions Evaluated
Coherence (Arm 1 pre-check on every finding); confusable-name; multi-reading; overlapping-ownership (evaluated — one unresolvable finding routed to a Docket tracking issue, see next entry / operator report).

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence pass on the DKT-73 changes: generalized the REFERRAL changelog wording and hardened the spawn-source-authority branch's recovery anchors.

### Changes
- FIX[COSMETIC]: `### Routing Changes` REFERRAL sentence generalized from "evolve-*-internal" to any spawn-source divergence (non-evolve owners included) — the disposition's own definition already covers any owning skill.
- FIX[COSMETIC]: `spec-<name>` → `spec-{filename-without-ext}` to match the init-specs literal grep anchor.
- FIX[SUBSTANTIVE]: added `model-routing-auditor`/`sdlc-role-researcher`/`config-history-auditor` to the undeclared-role population list — all three are measured-population members with zero team-lead.md hits, the exact class the list enumerates.
- FIX[SUBSTANTIVE]: branch step 1 gains a bare-name grep fallback for roster/prose-declared spawns (the `history-compactor` case — no `Agent(name=` literal exists for it in either root, so step 1 + stem-retry both missed it despite it being a known owner).
- FIX[COSMETIC]: fixture-harness comment path made repo-root-relative (was skill-dir-relative, non-resolving).

### Dimensions Evaluated
Coherence; reference accuracy (check_citations: 4 false positives adjudicated — docs/spec/, subagents/** runtime glob, both PHANTOM-PATH-GUARD negative citations); terminology consistency (6 REFERRAL sites, zero cross-skill collisions); symmetry checks (all PASS); Phase-0 pin duplicated-state independently confirmed in agreement.

### Rename
No rename.

## 2026-07-27

### Summary
DKT-73: closed the self-referential audit blind spot. Phase 1 gains a spawn-source-authority branch that classifies evolve-*-internal roles (this skill's own three included) against the silver-floor doctrine, and a new OWNING-SKILL REFERRAL disposition routes any divergence to the owning skill under operator approval instead of a team-lead.md edit. Net +4,538 bytes (43,709 → 48,247).
Findings: 23 → 4 sub / 0 cos / 5 rej / 10 def / 4 enc

### Changes
- AMPLIFY[SUBSTANTIVE][I1,M1]: spawn-source-authority branch added to the Categorization AUTHORITY rule — roles matching no Tiers bullet and no Per-Role Dispatch Table row were silently unclassifiable and dropped from the audit (30+ such rows measured across 12 role names in the 7-day window). Recovers the pinned literal by grep across BOTH skill roots, classifies by function (proposer/verifier/reviewer = review-class floor silver; auditor/builder/collector = collection-class bronze OK).
- AMPLIFY[SUBSTANTIVE][I1]: OWNING-SKILL REFERRAL threaded through the divergence-class preamble, proposer task 2b + Output Format, Phase 2 Step 3, and the Changelog Format. Rejected I1's second-surface FILE-EDIT proposal against DKT-73's constraint — editing another skill's model= literal from this cycle bypasses that skill's own review.
- FIX[SUBSTANTIVE][I1]: corrected the proposed grep's scope. `.claude/skills/*/SKILL.md` alone misses the shared evolve-phase0-templates.md (authoritative for 7 Phase-0 auditor pins) and every non-evolve spawner (vote, init-specs), re-creating the same silent drop.
- AMPLIFY[SUBSTANTIVE][D4]: compaction-recovery bullet now names the ~5,000-token retention boundary (measured: line 178) and mandates re-Reading the active phase section.
- AMPLIFY[SUBSTANTIVE][B1]: Team Setup marks the task plane best-effort, cross-referencing team-lead.md's not-enabled-in-this-context triage.
- CULL[SUBSTANTIVE]: Policy-stale tombstone subsection deleted (-666) — its payload is already stated at divergence class 5 and proposer task 1.

### Dimensions Evaluated
All 8. Completeness/Correctness primary (DKT-73 mechanism); Over-Engineering (Pass B, one cull); Coherence (live re-verification of both team-lead.md anchors, the shared template pins, and the SKILL.md restatements). Content Gate clean — no unescaped $+digit.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation (DKT-106, evolve-skills cycle): corrected the scope of the Crash & Stall local-copy mirror anchor.

### Changes
- AMPLIFY[SUBSTANTIVE]: the anchor now names both mirrored master sections (§Crash & Stall Recovery AND §Second-Failure Recovery) and marks the Compaction-recovery bullet local-only — the single-section anchor left two of four bullets with no discoverable owner, indistinguishable from drift to a future auditor.

### Dimensions Evaluated
Overlapping-ownership (applied); confusable-name, multi-reading (none found).

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence (DKT-106, evolve-skills cycle): repointed the Crash & Stall "Mirrors evolve-agents" anchor at the DKT-106 shared doc — evolve-agents no longer carries the mirrored text.

### Changes
- "Mirrors evolve-agents" → mirrors §Crash & Stall Recovery in evolve-orchestration-core.md (local copy; not a DKT-106 consumer).

### Dimensions Evaluated
Accurate references.

### Rename
No rename.

## 2026-07-24

### Summary
Pass A: retired the inline alias→tier map (I1) and removed a phantom `best` alias from all 3 sites — no `best` alias exists anywhere in team-lead.md or src/user.rs's ANTHROPIC_DEFAULT_* bindings; repaired the class-5 Policy-stale read path, whose input (the suspended-alias note) lives outside the block the proposer was told to read. Pass B: deleted a redundant, and factually incorrect, aggregate headline subsection. Net +1,282 bytes (42,127 → 43,409).

### Changes
- RETIRE[SUBSTANTIVE]: dropped the fable→gold/opus→silver/sonnet→bronze parenthetical — team-lead.md declares tier→alias resolves there "and nowhere else"; an embedded copy is a doctrine defect and stale on the next alias re-point.
- FIX[SUBSTANTIVE]: phantom `best` alias removed from class-5, the proposer prompt, and the Phase-2 apply workflow. The instruction would have written a nonexistent alias into the routing authority.
- FIX[SUBSTANTIVE]: Categorization AUTHORITY rule gains a third grep anchor (Per-spawn model routing). The suspended-alias note and closed alias vocabulary live only there, zero times in the Tiers bullets, so class 5 was structurally unevaluable despite claiming "always evaluated."
- FIX[SUBSTANTIVE]: Phase-3 verifier check 4 now rejects any alias outside the live vocabulary, not just a nonexistent tier — the gap that let `best` through undetected.
- RETIRE[SUBSTANTIVE]: Phase-0 §2 aggregate headline deleted (-632 bytes). §1's TSV already yields N spawns and M models; §2 counted per-turn occurrences, reporting TURNS under an "N spawns" label — internally contradictory with its own adjacent warning.

### Dimensions Evaluated
All 8. Correctness/bug (primary — 3 defects found beyond the assigned finding), Coherence (live anchor re-verification against team-lead.md and src/user.rs), Over-Engineering (Pass B), canonical-block parity untouched.

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

## 2026-07-20

### Summary
Coherence pass: phantom-path guard note added. Crash & Stall variant deliberately NOT registered as a CRASH-STALL-CORE carrier.

### Changes
- Added byte-identical evolve-* phantom-path guard note after DOCS-PATHS-LOCAL
- Documented (manifest comment) that this skill's crash-recovery variant is intentionally divergent (different resume-context/second-failure semantics) and excluded from CRASH-STALL-CORE parity

### Dimensions Evaluated
Coherence, parity enforcement.

### Rename
No rename.

## 2026-07-20

### Summary
No changes needed. This skill is a clean pass — anchors verified live (Tiers, gold/silver/bronze bullets, Per-spawn model routing resolve in team-lead.md lines 236, 240-243), ux-* categorization already current, no Content Gate violations. The two ledger findings (L26 script codification, L46 Mimir labeling) are out of scope this cycle. Phase 0 audits show a single clean in-window invocation with zero error/stall signal.

### Changes
- None (NO-OP verdict). L26 deferred (DKT-27, new script authoring); L46 out of scope (Mimir/OTEL instrumentation).

### Dimensions Evaluated
All 8; Coherence (live-anchor re-verification, ux-* categorization currency), Content Gate (no unescaped `$`+digit).

### Rename
No rename.

## 2026-07-17

### Summary
Investigation-sourced targeted fix cycle (P2 of a 3-item mandate spanning evolve-agents/evolve-skills/evolve-config/evolve-model-distribution). Synced the Tier-invariant-floor prose to team-lead.md's current 5 gold-seat classes.

### Changes
- AMPLIFY[SUBSTANTIVE]: Tier-invariant floor prose (~line 204) now enumerates the current 5 gold-seat classes and the ux-advisor gold(spec-authoring)/silver(review-QA-consult) split, matching live team-lead.md Tiers block verbatim-re-read — cited investigation finding P2 (prior text listed only 4 classes, blanketed ux-* silver).

### Dimensions Evaluated
Spec Alignment (7), Coherence (6) — Divergence-class-1 ux-* hard-floor (line 224) re-verified as still correct post-edit, no change needed there.

### Rename
No rename.

## 2026-07-14

### Summary
Coherence-class fix surfaced during Phase 3: dropped a dangling reference to the retired `model-policy-researcher` optional task.

### Changes
- Team Setup task list: removed `(+ optional "Model-Policy Research")` — this cycle's Phase 1 retirement of `model-policy-researcher` left the Phase-0 task list naming a spawn that no longer exists.

### Dimensions Evaluated
Coherence (accurate references — routed from Phase 3 as coherence-class, not disambiguation).

### Rename
No rename.

## 2026-07-14

### Summary
Propagated nudge-before-respawn + API-error crash signal from evolve-agents' Crash & Stall Recovery.

### Changes
- AMPLIFY: Crash & Stall Recovery gains (d) API-error self-report crash signal + a nudge-before-respawn bullet (lockstep from evolve-agents).

### Dimensions Evaluated
Coherence (family lockstep).

### Rename
No rename.

## 2026-07-14

### Summary
Retired the redundant `model-policy-researcher` opus spawn — its Policy-stale grep is folded into the routing-proposer's existing live-Tiers read, making class-5 always-evaluated and removing one spawn/shutdown cycle. Findings: 4 → 1 sub / 0 cos / 0 rej / 2 def / 1 enc

### Changes
- CULL[SUBSTANTIVE]: deleted the `model-policy-researcher` spawn template + `{model_policy_status}` skip machinery; proposer now derives the suspended-alias note from its Categorization AUTHORITY read (I3). Net -1718 bytes.

### Dimensions Evaluated
All 8. Over-Engineering (Pass B) drove the one change. I1 (evolve_signals.py swap) deferred — C2b absent-vs-unreadable-sidecar regression needs a script extension first; I2 deferred — tier_map.sh phantom; I4 PARITY-BOUND; M1 already-encoded (no routing change evidence-justified this cycle).

### Rename
No rename.

## Compacted history

Entries below were compacted per the retention-compaction policy; full text in git
history (see the compaction entry's date).

- 2026-06-30: Retargeted categorization to GPT-5.x sizing table; culled model-policy-researcher/Policy-stale class; labeled TSV fields. Net 0.
- 2026-07-10: Culled stale ILLUSTRATIVE SNAPSHOT category-tier table + disclaimer from Phase 1 (drifted vs live team-lead.md Tiers). Net -938.
- 2026-07-10: Phase 2 coherence pass: aligned docs-paths master citation to the relocated team-doctrine reference.
- 2026-07-12: Corrected embedded hard-floor role set (4 sites) to match live team-lead.md — added ux-*, dropped blanket verifier*, re-reads live floor prose.
- 2026-07-12: Phase 3 disambiguation — pinned Changelog Format `<target>` = `team-lead`; description now names BUILD SOURCE as the edit target.
- 2026-07-13: Phase 2 coherence: fixed dead `agents/team-lead.md` citation in shutdown protocol to `src/user/claude-code/agents/team-lead.md`.
