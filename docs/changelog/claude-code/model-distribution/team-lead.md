# Changelog: model-distribution/team-lead

## 2026-07-17

### Summary
Investigation-sourced cycle (4 governance gaps from investigator@gold+advisor@silver audit, converged). Resolved 1/4 in this skill's team-lead.md-only scope: QUALITY upgrade, PRD authoring bronze→silver. Other 3 are cross-file agent/skill coherence issues, routed to evolve-coherence.

### Routing Changes
- QUALITY: BIND PRD authoring (@project-manager via `Skill(prd)`) to silver — previously ungoverned (absent from the closed gold-authoring enumeration AND the bronze `planner`/decomposition bullet). PRD is spec-authoring landing in `docs/spec/`, matching the silver floor's charter; kept distinct from bronze `planner`. n=1 measured `prd-author` spawn (100% sonnet, zero drift) confirmed the gap was defaulting to bronze, not ruled there. Edit: silver Tiers bullet (line 242), appended PRD-authoring clause after "standalone vote reviewers."

### Evidence
LOCAL: 141 sessions (cutoff 2026-07-10T21:53:31Z), 1207 spawns joined; 73 PM/planner/PRD-family spawns isolated, all sonnet/zero-drift. Mimir: available, agent_name too coarse for PRD-specific cost. Re-verified team-lead.md lines 184/240-243/466 — all citations accurate.

### Rejected
- Secondary edits (gold-floor explicit PRD listing; Dispatch Table PRD row) — operator chose primary-edit-only.
- 3 non-PRD gaps (evolve-model-distribution's stale ux-* categorization; coherence-reviewer gold/silver split across evolve-agents/skills vs evolve-config; docs-researcher name/tier collision) — outside this skill's editable surface, routed to evolve-coherence.

## 2026-07-13

### Summary
DKT-268 measurement cycle: justified planner's bronze exemption from team-lead.md's silver authoring floor with data. No routing-table edit — operator approved JUSTIFY-RETAIN.

### Routing Changes
- JUSTIFY-RETAIN: `planner` stays bronze — 29/29 spawns measured sonnet→claude-sonnet-5 (zero drift), 0/21 sessions with a genuine failure-driven respawn (the 19% naming-convention "multiple spawn" rate traced to sequential new planning rounds, not rework), 0 operator corrections, 0 shutdown-rejections. Class-6 quality-mismatch check found no upgrade case: project-manager.md's own frontmatter self-pins sonnet, and its charter routes hard architectural reasoning OUT via the TDD-required gate. No file edit.

### Evidence
LOCAL: 21 dotfiles-vorpal-git-main sessions, 29 planner spawns (orchestrator-spot-checked: 31 .meta.json files independently found, sample confirmed sonnet). Mimir: available (200), but `claude_code_token_usage` has no per-ephemeral-role `agent_name` granularity — planner's specific cost unisolable; 7d aggregate cost across all agents $5,137.32 (not planner-attributable).

### Rejected
- Class-6 upgrade (planner → silver): rejected — no demand-anchor support in project-manager.md's own charter; would contradict the role's self-pinned sonnet frontmatter and anti-deliberation doctrine.

## 2026-07-11

### Summary
First evolve-model-distribution cycle (761 spawns, 91 sessions, 7d window). One class-6 quality-mismatch upgrade applied (ux-advisor + design-review/QA bronze→silver, operator-approved with the companion floor-scope extension); one RUNTIME-DISCIPLINE REPORT (model= omission, no file edit). Everything else measured CONFORMANT to live Tiers/dispatch-table text.

### Routing Changes
- QUALITY: UPGRADE `ux-advisor` (spec authoring) + `design-review-{N}`/`design-qa-{N}` (doubled review/QA panel) bronze→silver — team-lead.md's own "sub-`silver` authoring/review dispatch is a routing defect" invariant is categorical about authoring/review and only omitted ux-* by list-construction; ux-designer.md's charter (design specs, design reviews, design QA, consensus-before-handoff) is the same cognitive class the floor protects. n=3 measured spawns, all bronze, confirmed the mis-tier live (this cycle's evolve-agents review of ux-designer.md independently reached the same "no exemption justified" conclusion).
- Companion (operator-approved): extended the silver-floor invariant's protected-role enumeration from `tdd-author*/reviewer*/security-*` to include `ux-* (spec-authoring + design-review/QA)`, so a future cycle cannot silently re-downgrade it back to bronze.
- 5 edits total to team-lead.md: dispatch-table `ux-advisor` row (bronze→silver), dispatch-table `design-review-{N}`/`design-qa-{N}` row (bronze→silver), bronze Tiers bullet (removed "@ux-designer default"), silver Tiers bullet (added ux-advisor/design-review/qa clause), Tiers preamble invariant (added ux-* to the protected list).

### Evidence
LOCAL: 91 in-window `subagents/` sessions (cutoff 2026-07-04T18:43:51Z), 761 per-spawn `.meta.json`/`.jsonl` pairs joined. Mimir: available (7d token/cost/active-time queries returned 200 with populated series; `agent_name` label does not map to the 8-role taxonomy — directional cost context only, not per-role ground truth). Quality-lane re-verification: re-read team-lead.md's Tiers preamble + ux-designer.md lines 25-32/58-63/251 — all cited anchors confirmed accurate.

### Rejected
- `docs-researcher` measured at opus (n=3, canonical bronze) — permitted upgrade (requested=opus PRESENT), not a downgrade candidate; no per-role Mimir cost exists to ground a Trial downgrade even if one were proposed.
- `senior-engineer`/`impl-*misc` "wrong-tier" reading of the 8 `model=`-omitted-but-resolved-sonnet spawns — REJECTED as a tier defect (sonnet IS the correct bronze canonical); folded into the RUNTIME-DISCIPLINE REPORT instead (model= omission is a compliance gap, not a routing-table gap).
- `vote-reviewer-*` fable spawns (n=3/88, requested=fable PRESENT) — permitted upgrade above the silver floor, immaterial volume, not a divergence.

**RUNTIME-DISCIPLINE REPORT (no file edit):** 43 of 761 spawns omitted `model=` at dispatch (violates team-lead.md's existing "every `Agent()` spawn MUST set `model=` explicitly" mandate). Sharpest instances: 31 `<unnamed>` spawns (no `name=` AND no `model=`, unattributable to any category by construction — resolved fable-5=12/opus-4-8=12/sonnet-5=6/mixed=1, e.g. sessions `.../vorpal-git-feature-python-sdk/8bc123ea.../subagents`→fable-5 and `.../342462da.../subagents`→opus-4-8) and 1 true `<none>`-resolved spawn (`impl-ok-txt`, session `.../np2-A2-noflag-sanitized-10636-4109/7431defd.../subagents` — jsonl carried no non-synthetic model field at all). Recommend tracing both classes to their spawn call-sites for `name=`/`model=` discipline; no tier was actually wrong where one resolved.

**Build-deploy-lag reminder:** the edit target is the BUILD SOURCE `src/user/claude-code/agents/team-lead.md`; the running team-lead resolves its definition from the DEPLOYED copy at `~/.claude/agents/team-lead.md`. These edits do not take effect until the vorpal/Rust config is rebuilt and redeployed, and the next audit cycle can only measure their effect after that redeploy.
