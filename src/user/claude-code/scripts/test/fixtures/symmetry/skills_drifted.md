# Fixture: evolve-skills SKILL.md excerpt (skills side, DRIFTED)
<!-- DRIFT: only the innovation-scanner block drifts — the MISSION line ends with
     "concrete refinements" here vs the agents fixture's normalized "concrete
     improvements". impact-class stays symmetric, so `--check all` reports exactly
     one drift (innovation-scanner). -->

### Phase 0: Innovation Scan

```
Agent(name="innovation-scanner", subagent_type="staff-engineer", model="opus", prompt="...")

MISSION: Surface opportunities for skills — NOT auditing past failures (that is historical-auditor's job). Read .claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md and surface concrete refinements.

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
