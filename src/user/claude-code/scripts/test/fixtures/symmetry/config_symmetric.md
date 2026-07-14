# Fixture: evolve-config SKILL.md excerpt (symmetric pair, config side)
# Config-side counterpart to agents_symmetric.md / skills_symmetric.md for the
# `--check all` hermeticity test — carries a byte-identical CANONICAL:SCIENTIFIC-
# TRIAL-PROTOCOL block so the trial-protocol check has a real fixture instead of
# silently defaulting to the live .claude/skills/evolve-config/SKILL.md.

<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->
Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.
<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->

<!-- CONFIG-ONLY -->**Config blast radius is high** — addendum outside the shared block.

<!-- CANONICAL:DISAMBIGUATION-CHARTER:BEGIN -->
**Phase 3 Disambiguation charter.** Surface and resolve residual ambiguity Phase 2 Coherence does NOT address: (1) confusable names/triggers/terms, (2) wording with multiple readings, (3) overlapping ownership between organisms.
<!-- CANONICAL:DISAMBIGUATION-CHARTER:END -->

<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:BEGIN -->
**Boundary (the load-bearing distinction — every finding must satisfy both arms or it routes to Phase 2 instead):** a Phase 3 finding's targets each independently PASS every Phase 2 coherence invariant yet still FAIL clarity.
<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:END -->

<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:BEGIN -->
**The variation is a neutral allele substitution** — replace the selected trait's current formulation with a semantically-equivalent alternative.

**Gate + caveat.** Every drift proposal routes through the **same operator-approval HARD GATE** as adaptive trials.
<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:END -->

<!-- CANONICAL:SECOND-FAILURE-RECOVERY:BEGIN -->
- **Second failure**: mark task completed and skip; never do the work directly.
<!-- CANONICAL:SECOND-FAILURE-RECOVERY:END -->

<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->
> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (max 4 options per question).
<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->
