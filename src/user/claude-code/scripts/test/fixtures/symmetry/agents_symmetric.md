# Fixture: evolve-agents SKILL.md excerpt (symmetric pair, agents side)
# Covers the two surviving symmetry_check.py checks: innovation-scanner and impact-class.
# The `### Phase 0: Model Routing Audit` header is retained as the innovation-scanner
# end-anchor only (its body is single-homed in evolve-phase0-templates.md).

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
