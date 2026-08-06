# Fixture: evolve-skills SKILL.md excerpt (symmetric pair, skills side)
# Covers the sole surviving parity-checked-against-agents block: impact-class.
# The Innovation Scan section (and its `### Phase 0: Model Routing Audit` end-anchor
# header) is retained verbatim but is no longer checked here — the Innovation Scan
# template is single-homed in evolve-phase0-templates.md, so there is no duplicated
# copy for symmetry_check.py to compare.

### Phase 0: Innovation Scan

```
Agent(name="innovation-scanner", subagent_type="staff-engineer", model="opus", prompt="...")

MISSION: Surface opportunities for skills — NOT auditing past failures (that is historical-auditor's job). Read .claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md and surface concrete improvements.

Target skills: {target_skills}

## Task — for EACH target skill, identify opportunities:
4. **Cross-Skill Leverage**: shared conventions across 2+ skills.

## Output Format (per skill)
### Skill: <skill-name>
- Cross-Skill Leverage: <1-3 bullets, or "none">
```

### Phase 0: Model Routing Audit

### Phase 1: @staff-engineer (Review & Improve)

<!-- CANONICAL:IMPACT-CLASS:BEGIN -->
**Impact classification.** Every applied change is classified by its DIFF: SUBSTANTIVE alters a rule or gate; COSMETIC is a rewording with no behavioral delta.
<!-- CANONICAL:IMPACT-CLASS:END -->

<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->
Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.
<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->

<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->
> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (max 4 options per question).
<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->
