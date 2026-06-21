# Changelog: evolve-config

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
