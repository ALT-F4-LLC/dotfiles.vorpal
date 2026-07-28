# Fixture: evolve-config SKILL.md excerpt (symmetric pair, config side)
# Config-side counterpart to agents_symmetric.md / skills_symmetric.md for the
# `--check all` hermeticity test — carries a byte-identical CANONICAL:SCIENTIFIC-
# TRIAL-PROTOCOL block so the trial-protocol check has a real fixture instead of
# silently defaulting to the live .claude/skills/evolve-config/SKILL.md.

<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->
Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.
<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->

<!-- CONFIG-ONLY -->**Config blast radius is high** — addendum outside the shared block.

<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->
> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (max 4 options per question).
<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->
