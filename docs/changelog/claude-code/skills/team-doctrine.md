# Changelog: team-doctrine

## 2026-07-12 (Phase 2 coherence pass)

### Summary
Phase 2 coherence: corrected 3 reference-master defects, one introduced by this cycle's own Phase 1 edit. Findings: 3 → 3 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- FIX[SUBSTANTIVE]: `docket-cli.md` `vote cast` — added `[--role ROLE]` (verified live `--help` b59dd2f; vote/SKILL.md uses it twice; today's earlier addition omitted it)
- FIX[SUBSTANTIVE]: `docs-paths.md` — corrected 3 changelog taxonomy rows to the real `docs/changelog/claude-code/*` tree + added the missing evolve-config row (verified via `ls`)
- FIX[SUBSTANTIVE]: `retention-compaction.md` — re-cited the non-unique-date worked example to a currently-true instance (path + counts verified live)

### Dimensions Evaluated
Coherence (master-vs-writer path agreement; master-vs-live-CLI agreement).

### Rename
No rename.

## 2026-07-12

### Summary
Reference-material gap closure across 5 files, driven by 3 independent Phase 0 auditors converging on repeat-lookup patterns (23+14+17+18+8 sessions across the fleet). Restored index-table completeness (16 files, 13 were indexed) and added a self-check to prevent recurrence. Findings: 7 → 7 sub / 0 cos / 0 rej / 0 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: `docket-cli.md` — added `vote cast` command syntax (23-session repeat-lookup gap) + `--threshold` 0.67 default note; added negative guard on `comment add` (-m only; 14 sessions guessed --body/-b/positional)
- AMPLIFY[SUBSTANTIVE]: `docs-paths.md` — added skill-file-tree disambiguation (.claude vs ~/.claude vs src/user; 18 wrong-tree misses)
- AMPLIFY[SUBSTANTIVE]: `shutdown-protocol.md` SP-1b — added string-message `summary`-required note (8 sessions); the top-level-`type`-flattening half was already covered
- AMPLIFY[SUBSTANTIVE]: `vorpal-tools.md` — added availability caveat + gofmt→`go fmt` fallback (listed tools aren't a publish guarantee)
- AMPLIFY[SUBSTANTIVE]: SKILL.md index table — added 3 missing rows (authoring-verification-gates, docket-cli, sandbox-recovery; verified cited-by lists against live grep); added an index-completeness self-check maintenance note

### Dimensions Evaluated
Completeness/Actionability (primary — closing repeat-lookup gaps across the fleet), Coherence (index-table drift). Already-encoded (no action): SP-1b's top-level-`type` flattening WRONG/RIGHT example was already present. Noted (not this skill's fix): `.claude/skills/vorpal-tools.md` LOCAL copies in agent files are compact pointers, not verbatim mirrors — editing the master here does not break parity.

### Rename
No rename.

## 2026-07-10

### Summary
Restored index-table completeness — registered the previously-omitted `retention-compaction.md` reference master (13 on-disk files, 12 were indexed).

### Changes
- AMPLIFY: added one index row for `references/retention-compaction.md` (per-file changelog retention budget + pitfalls-file compaction), citing its 4 verified evolve-* consumers.

### Dimensions Evaluated
All 8. Coherence drove the sole change (13 on-disk files vs 12 indexed). Over-Engineering: nothing to cull. Orchestration: N/A (non-invocable index).

### Rename
No rename.
