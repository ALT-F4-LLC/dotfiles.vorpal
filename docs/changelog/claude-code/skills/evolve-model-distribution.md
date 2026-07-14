# Changelog: evolve-model-distribution

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: fixed the dead `agents/team-lead.md` citation in the shutdown protocol to `src/user/claude-code/agents/team-lead.md`.

### Changes
- Stale pre-migration root replaced with the resolvable repo path (matches evolve-agents' form).

### Dimensions Evaluated
Coherence (reference accuracy).

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Two multi-reading/confusable-name fixes, no behavioral change to the pipeline.

### Routing Changes
None (prose disambiguation only): Changelog Format parenthetical now pins `<target>` = `team-lead` (was readable as `team-lead.md` → `team-lead.md.md`); description now names the edit target as the BUILD SOURCE (src/user/claude-code/agents/), matching the body's build-deploy-lag reminder.

### Evidence
Phase 3 disambiguation review 2026-07-12; DOCS-PATHS-LOCAL block is the path authority both fixes align to.

### Rejected
None.

## 2026-07-12

### Summary
Corrected the embedded hard-floor role set (4 sites) to match live team-lead.md: added `ux-*`, dropped blanket `verifier*` (routine verifier is legitimately bronze; only new-arch verifier-criteria/verifier-integration are silver), and made the coherence-verifier check re-read the live floor prose instead of a static list. Findings: 3 → 1 sub / 0 cos / 1 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: hard-floor set `tdd-author*/reviewer*/verifier*/security-*` → `tdd-author*/reviewer*/security-*/ux-*` + new-arch verifier only, at 4 sites — cited drift vs live team-lead.md floor (escape-hatch prose + Tiers `silver` bullet), verified live via grep

### Dimensions Evaluated
Spec Alignment, Coherence (primary). Rejected the evolve_signals.py `--distribution` swap (verified categorization regression — script's role field drops instance name, would collapse tdd-author*/reviewer-2 into one row). Declined self-logging suggestion (scope creep — changelog already the durable record). Flagged `mimir_query.sh` cross-skill leverage (shared with evolve-agents/evolve-skills/evolve-config) as DEFERRED.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence pass: aligned docs-paths master citation to the relocated team-doctrine reference.

### Changes
- Docs-paths citation → `…/team-doctrine/references/docs-paths.md` (was team-lead.md §copy).

### Dimensions Evaluated
Cross-reference accuracy.

### Rename
No rename.

## 2026-07-10

### Summary
Culled the stale-by-definition ILLUSTRATIVE SNAPSHOT category→tier table + disclaimer from §Phase 1 — confirmed drift vs live team-lead.md Tiers (Large/long-horizon row and a `haiku` row both contradicted the live gold/silver/bronze system). Net -938.

### Changes
- CULL: removed the ILLUSTRATIVE SNAPSHOT table + 3-sentence disclaimer — cited innovation-scanner Retire + verified drift; the mandated live-Tiers grep recipe (kept) is the actual classification input.

### Dimensions Evaluated
All 8. Over-Engineering primary; Actionability/Completeness/Orchestration strong, no change.

### Rename
No rename.

## 2026-06-30

### Summary
Retargeted categorization from obsolete sonnet/opus Tiers anchors to the current GPT-5.x sizing table, culled the optional model-policy-researcher and Policy-stale class, and labeled TSV fields. Net 0.

### Changes
- AMPLIFY: retargeted categorization to the live GPT-5.x sizing table — cited current routing-table authority drift.
- CULL: removed the optional model-policy-researcher and Policy-stale class — cited obsolete alias-policy branch with no measured comparator evidence.
- AMPLIFY: labeled per-spawn TSV fields explicitly — cited report-consumption clarity.

### Dimensions Evaluated
All 8.

### Rename
No rename.
