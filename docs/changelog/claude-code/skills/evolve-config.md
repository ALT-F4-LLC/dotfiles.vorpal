# Changelog: evolve-config

## 2026-07-10

### Summary
Phase 3 disambiguation: retuned the colliding trigger phrase "refine Claude Code settings" → "refine config sources" and added a clause naming the bundled update-config (/config) skill for live settings.json edits.

### Changes
- Description: trigger "refine Claude Code settings" → "refine config sources" + added "evolves config SOURCE not live settings.json; use bundled update-config for one-off settings edits" — removes classifier collision with bundled update-config (confusable-name). Achieves parity with sibling skills that name their bundled near-namesakes.

### Dimensions Evaluated
Disambiguation (confusable-name). Cross-evolve-* trigger set otherwise distinct on primary token.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence pass: aligned docs-paths master citation to the relocated team-doctrine reference.

### Changes
- Docs-paths citation → `…/team-doctrine/references/docs-paths.md` (was team-lead.md §copy).

### Dimensions Evaluated
Cross-reference accuracy.

### Rename
No rename.

## 2026-07-10

### Summary
Trimmed a redundant self-referential budget line and propagated the mandatory build-deploy-lag reminder from evolve-model-distribution into Wrap-up.

### Changes
- CULL: removed the "Self-budget." line duplicating Pre-flight step 4 / Wrap-up step 2 — cited innovation-scanner Retire (Non-redundant-gate violation + broke the numbered list).
- AMPLIFY: added build-deploy-lag reminder to Wrap-up step 3 (config-source edits inert until vorpal rebuild+redeploy) — cited innovation-scanner Cross-Skill Leverage; parity with evolve-model-distribution.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Strengthened official-docs digestion, generated-phenotype verification, and setter/call-chain inventory fallback. Net 0; stays 475.

### Changes
- AMPLIFY: Codex config docs research now prefers the OpenAI docs/manual helper and distills installed-version plus config-field changes — cited stale-docs risk.
- AMPLIFY: generated-output verification now compares before/after phenotype without editing deployed `$HOME/.codex/` files — cited source-of-truth safety.
- AMPLIFY: config-history audit now uses a repo-owned inventory helper when present, otherwise an `rg` fallback — cited dead-setter detection robustness.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-3 disambiguation: resolved the "genome" multi-reading. Inline, net 0 (stays 535).

### Changes
- AMPLIFY: the intro line defined "genome" as "the settings.json artifact produced by the Rust builders" while line 38 defines genome = the four source files and settings.json = phenotype. Reworded the intro so genome = the Rust builder sources (per SOURCE-OF-TRUTH) and settings.json = phenotype (per EVOLUTION-MODEL), since all edit-targeting language keys off "genome". Phase-3 finding DISAMBIG 1.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Clarity: intra-file multi-reading fix. No model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 coherence: restored 3-way Crash & Stall parity. Inline, net 0 (stays 535).

### Changes
- AMPLIFY: Crash & Stall detection (a) now carries the "— ≥2 turns with no new tool call is stall evidence" clause that evolve-agents + evolve-skills already had (config had dropped it). Restores byte-parity on the stall clause across the 3 editing evolve skills.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Coherence: parity-drift fix. No model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Named SessionStart + MessageDisplay as candidate hook surfaces in Config-Surface dimension 4 so the Phase-1 config reviewer can evaluate wiring them. Inline (net 0, stays 535). No config-source changes this cycle.

### Changes
- AMPLIFY: dimension 4 (Hooks & scripts) now names `SessionStart` (reloadSkills/sessionTitle) + `MessageDisplay` (v2.1.147+) as candidate surfaces, gated behind a cited fitness signal — cited docs-research signal; the dimension can't surface a setter it never names. Wording corrected at apply (reloadSkills re-scans for newly-added skills; edits auto-apply via file-watching).

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0 (no destructive trim forced on a no-signal RETAIN-biased organism). No model/routing/drift changes. No unescaped `$`+digit. Phase-2 deferral: Crash & Stall Recovery parity — evolve-config is missing the "≥2 turns no new tool call is stall evidence" clause both siblings carry → CANONICAL-ize family-wide.

### Rename
No rename.

## 2026-06-20

### Summary
Phase 2: pinned model= (aliases) on all 8 Agent() spawns + added a $TMPDIR scratch guard to 3 auditor Rules lines. In-line edits, no line growth (stays 535, at self-budget).

### Changes
- AMPLIFY: pinned `model=` on every Agent() spawn — sonnet (config-history/historical/model-routing auditors) / opus (docs-researcher, innovation-scanner, review-config, coherence-reviewer, disambiguation-reviewer). Cited the dispatch-defect rule; operator-approved per-tier pinning.
- AMPLIFY: appended a `$TMPDIR`-not-`/tmp` scratch guard to the config-history-auditor + historical-auditor + model-routing-auditor Rules — directly fixes the cited run ERROR `operation not permitted: /tmp/...` (config-history-auditor).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Coherence trim: removed a false git blame claim from the config-history-auditor description; the changelog-path operator question resolved as a NO-OP (config/claude-code.md is correct, distinct from skills/evolve-config.md).

### Changes
- AMPLIFY: dropped `git blame` from the config-history-auditor Bash description — the Phase-0 template runs only `git log`; over-stated tooling invited needless blame over the 1636-line claude_code.rs. Cited: auditor stall hot-spot (32 TeammateIdle / 9.5% idle on sonnet).
- Drift (rate 7): all SKIP — D0/D3/D4/D5/D6 evolve-family parity (Phase-2 lockstep); D1 already drifted this date (same seed) — guarded as churn.

### Dimensions Evaluated
Coherence, Efficiency, Over-Engineering, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Drift: reworded the Crash & Stall "Compaction recovery" bullet (seed 6f0ab504, pick 4) — instruction order changed, meaning preserved. Tagged config-specific drift sentence CONFIG-ONLY and trimmed its duplicate rationale. All 5 innovation-scanner config features verified real but rejected — they lack claude_code.rs setters and are owned by the runtime innovation pipeline per cycle.

### Changes
- AMPLIFY: tagged Genetic-Drift "Drift targets THIS SKILL's prose" sentence with `<!-- CONFIG-ONLY -->` — signals intentional family divergence to coherence reviewer; trimmed duplicate "config settings carry fitness consequences" rationale (stated twice in 2 lines).
- DRIFT: Crash & Stall "Compaction recovery" bullet reordered — neutral allele substitution, seed 6f0ab504 pick 4, net 0.

### Dimensions Evaluated
All 6 config surfaces RETAIN (no setter exists for enforceAvailableModels / requiredMin|MaxVersion / MessageDisplay; fallbackModel/Tool(param:value) already covered). Runtime note: with_fallback_model defined but never called in src/user.rs (dead capability — next cycle finding).

### Rename
No rename.
