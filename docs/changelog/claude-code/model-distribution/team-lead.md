# Changelog: model-distribution/team-lead

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
