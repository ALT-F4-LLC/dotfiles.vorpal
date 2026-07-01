# Changelog: evolve-suite

## 2026-06-30

### Summary
Folded a read-only capacity-plan checkpoint into the existing goal gate. Net 0.

### Changes
- AMPLIFY: goal gate now computes intended runs, fixed order, checkpoints, final gate, and passthrough values before operator confirmation — cited capacity clarity with no new gate.

### Dimensions Evaluated
All 8. Over-Engineering primary.

### Rename
No rename.

## 2026-06-20

### Summary
Trial: surface Mimir 7-day cost trend to inform the rate-limit attestation → adopted (operator-approved). Scoped per-run snapshot walks + de-duplicated the Failure Runbook. Net +2 lines (183→185).

### Changes
- AMPLIFY: scoped both per-run `git status --porcelain` snapshots to the run-surface pathspec already used by the clean-surface check — cheaper walks + sharper delta attribution (innovation signal c).
- CULL: compressed the Failure Runbook from restated recovery bodies to a one-line-per-class pointer index; each class's full contract already lives inline at its primary home (Content Gate Non-redundant).
- AMPLIFY (Trial, adopted): added an informational Mimir 7-day cost-trend probe to the rate-limit attestation step — fail-open, supplements (does not replace) the manual /usage read.

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Drift: reworded "Mid-run compaction is the expensive case" bullet (seed 6f0ab504, pick 7) — responsibility framing clarified, meaning preserved. Corrected stale named-team references (v2.1.178: runtime ignores team_name; one implicit team per session, auto-cleanup at session end). Replaced "REFUSE" with "strongly advise against" — a skill cannot refuse the operator. Compact now recommended after run 1 (heaviest) and run 2.

### Changes
- CULL: Team-free guard and leftover-team collision — removed stale `evolve-<name>-{today_date}` deterministic-team-name references; updated to implicit-team model (team-lead.md authority).
- CULL: Rate-limit attestation >85% tier — "REFUSE" → "strongly advise against" (skill cannot refuse human operator).
- AMPLIFY: /compact checkpoint — recommended after run 1 (evolve-agents, heaviest) AND run 2; previously "after run 2" only.
- DRIFT: Context-Saturation mid-run compaction bullet reworded (nested cycle's responsibility) — neutral allele substitution, seed 6f0ab504 pick 7, net 0.

### Dimensions Evaluated
All 8; Correctness primary (stale team-naming; authority overstep). Operational accuracy (compact guidance). Coherence: CANONICAL:BANNER intact (no change). First changelog entry for this skill.

### Rename
No rename.
