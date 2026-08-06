# Fixture: evolve-agents SKILL.md excerpt (symmetric pair, agents side)
# Covers the sole surviving parity-checked-against-skills block: impact-class.
# The Innovation Scan section (and its `### Phase 0: Model Routing Audit` end-anchor
# header) is retained verbatim but is no longer checked here — the Innovation Scan
# template is single-homed in evolve-phase0-templates.md, so there is no duplicated
# copy for symmetry_check.py to compare.

### Phase 0: Innovation Scan

```
Agent(name="innovation-scanner", subagent_type="staff-engineer", model="opus", prompt="...")

MISSION: Surface opportunities for agents — NOT auditing past failures (that is historical-auditor's job). Read src/user/claude-code/agents/*.md and surface concrete improvements.

Target agents: {target_agents}

## Task — for EACH target agent, identify opportunities:
4. **Cross-Agent Leverage**: shared conventions across 2+ agents.

## Output Format (per agent)
### Agent: <agent-name>
- Cross-Agent Leverage: <1-3 bullets, or "none">
```

### Phase 0: Model Routing Audit

### Phase 1: Self-Review & Improve

<!-- CANONICAL:IMPACT-CLASS:BEGIN -->
**Impact classification.** Every applied change is classified by its DIFF: SUBSTANTIVE alters a rule or gate; COSMETIC is a rewording with no behavioral delta.
<!-- CANONICAL:IMPACT-CLASS:END -->

<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->
Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.
<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->

<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->
> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (max 4 options per question).
<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->
