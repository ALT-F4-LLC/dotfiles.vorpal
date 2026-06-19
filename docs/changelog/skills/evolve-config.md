# Changelog: evolve-config

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
