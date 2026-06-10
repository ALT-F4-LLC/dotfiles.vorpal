---
name: agent-effort-settings
description: Confirmed effort + model settings for agents/* and skills — no model: overrides (inherit main, validated 2026-06-09), xhigh for coding/review roles, high for coordination/planning/design; skills inherit caller effort except evolve-* at xhigh
metadata:
  type: project
---

Effort allocation in `agents/*` frontmatter is settled (validated across three reevaluations, last on 2026-06-09 with operator confirming "keep all as-is"):

- `xhigh`: senior-engineer, staff-engineer, security-engineer, sdet (coding/agentic/review work)
- `high`: team-lead, project-manager, ux-designer (coordination/planning/design)
- `max`: nobody — staff-engineer and security-engineer were deliberately walked DOWN from `max` in prior cycles (overthinking/diminishing-returns risk); do not bounce them back up.

**Why:** Matches Fable/Opus 4.7+ guidance exactly — `xhigh` is best for coding and agentic use cases; `high` is the minimum for intelligence-sensitive work and the cost/quality sweet spot. All agents inherit the main selected model (no `model:` overrides, per commit 37689c9).

**How to apply:** On a future "reevaluate effort" request, re-verify the 7 frontmatters still match this table, then check only whether (a) the model guidance has changed or (b) a role's workload class has shifted. Considered-and-declined tweaks: team-lead → `medium`, project-manager → `xhigh` (operator declined both 2026-06-09).

**Skill effort (settled 2026-06-09, hybrid):** the 12 team skills in `skills/*` carry NO `effort:` key — they inherit the calling agent's session effort (per code.claude.com/docs/en/skills.md, omitted effort = "inherits from session"), so each skill automatically runs at the settled per-agent level. The 3 main-session meta-skills (`.claude/skills/evolve-{agents,skills,coherence}`) are pinned `effort: xhigh` (agentic editorial work; walked down from their prior `max` per the same overthinking rationale). Considered-and-declined: inherit-everywhere (evolve-* would float at session effort), explicit class-aligned split (duplicates the agent table, drift risk), keep-all-max (silently overrode walked-down agent efforts during every skill execution — the original defect). On a future "reevaluate skill effort" request: verify zero `^effort:` matches in `skills/*/SKILL.md` and exactly 3 `effort: xhigh` in `.claude/skills/*/SKILL.md`, then check only whether effort-inheritance semantics or the agent table changed.

**Model setting (evaluated 2026-06-09):** inherit-all confirmed — no `model:` keys in any frontmatter; all 7 agents track the main selected model. Considered-and-declined: pin pm+ux to `opus` (~2× cheaper for planning/spec work), pin pm+ux to `sonnet`, pin all explicitly to `fable`. Hard constraint to remember: Haiku 4.5 errors on `xhigh`/`max` effort — never a candidate for any current agent. On a future "reevaluate model" request, re-verify no `model:` keys appeared, then check only whether the model catalog/pricing tiers shifted.
