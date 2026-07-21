# Changelog: team-doctrine

## 2026-07-20

### Summary
Added a source-citation prefix-discipline reminder to the docs-paths master (L40/L53): citing this repo's own agent/skill/script source always uses the `src/user/claude-code/` prefix, never bare `agents/…` or a deployed `.claude/…` prefix (evolve-* skills excepted). Rejected L36 (remove SKILL.md "Cited by" column) — the doctrine_check manifest does NOT own these carrier sets; column is load-bearing. L37/L38 confirmed already-correct. Findings: 1 sub / 0 cos / 1 rej / 2 already-encoded

### Changes
- AMPLIFY[SUBSTANTIVE]: docs-paths.md `CANONICAL:DOCS-PATHS` block — appended citation prefix-discipline reminder to the "Repo-root vs source-tree" note (L40/L53; 3-session recurring wrong-prefix miss). Master edit only; DOCS-PATHS is not parity-registered and LOCAL copies are role-scoped, so no lockstep needed.
- REJECT: L36 (remove SKILL.md "Cited by (LOCAL-copy consumers)" column) — verified doctrine_check_manifest.tsv registers only PITFALLS among the 16 masters; the other 15 have role-scoped (non-byte-identical) LOCAL copies deliberately excluded from byte-parity, so the manifest does not own the column's carrier sets. Removal would be a regression.
- NO-OP: L37 (vorpal-tools.md gofmt) and L38 (shutdown-protocol.md SP-1b union-type trap) confirmed already-encoded correctly.

### Dimensions Evaluated
Actionability (closes recurring-repetition finding), Coherence (accurate path citations). L36 verified and rejected; L37/L38 verified already-correct.

### Rename
No rename.

## 2026-07-17

### Summary
Phase 3 disambiguation: annotated section 4's tool_call_frequency.sh invocation to pin --since day-count semantics against the adjacent ISO-cutoff --since of evolve_signals.py.

### Changes
- Section 4 Repetition Audit: added a day-count-vs-ISO note on `--since {history_days}` (confusable flag semantics across adjacent templates; verified against the script's usage text: days, range 1-90).

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership).

### Rename
No rename.

## 2026-07-17

### Summary
Two Phase-2-sourced fixes to the shared evolve-phase0-templates.md reference (consumed by evolve-agents/evolve-skills/evolve-config): the docs-researcher rename lockstep, and wiring tool_call_frequency.sh into the repetition-audit template to close a recurring hand-rolled-pipeline pattern.

### Changes
- AMPLIFY[SUBSTANTIVE]: canonical Phase-0 spawn template (section 8) renamed `docs-researcher` -> `docs-researcher-phase0` (P1; lockstep with evolve-agents/evolve-skills/evolve-config).
- AMPLIFY[SUBSTANTIVE]: repetition-audit template (section 4) step 1 now prescribes `tool_call_frequency.sh` as the preferred extraction method, falling back to the hand-rolled pipeline only for shapes the script cannot express - cited repetition-auditor FIX 1 (4 independent sessions rebuilt this pipeline from scratch; the script had zero consumers).

### Dimensions Evaluated
Coherence (accurate references), Actionability (closes a recurring-repetition finding), Rename coordination.

### Rename
docs-researcher -> docs-researcher-phase0 (section 8 canonical template only).

## 2026-07-14

### Summary
Coherence-class fix surfaced during Phase 3: corrected docket-cli.md's index Cited-by column, which under-listed consumers 5-to-3.

### Changes
- Index row for `references/docket-cli.md`: Cited-by `project-manager.md, sdet.md, senior-engineer.md` → `all 7 agents + team-lead.md` — verified via `grep -l 'CANONICAL:DOCKET-CLI-LOCAL' src/user/claude-code/agents/*.md`, all 8 files carry the LOCAL block, not just 3.

### Dimensions Evaluated
Coherence (accurate references — routed from Phase 3 as coherence-class, not disambiguation).

### Rename
No rename.

## 2026-07-14

### Summary
Documented 3 undocumented docket capabilities + 2 synopsis nits verified live against `docket b59dd2f`, and elevated the recurring `comment add --body` wrong-flag warning to a bold rendered callout. SKILL.md unchanged; all edits landed in `references/docket-cli.md` (no byte budget). Findings: 8 → 5 sub / 0 cos / 0 rej / 2 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: docket-cli.md — added `docket config` top-level command (K1)
- AMPLIFY[SUBSTANTIVE]: docket-cli.md — `plan` `-l/--label` + `-s/--status` shown repeatable w/ default (K4)
- AMPLIFY[SUBSTANTIVE]: docket-cli.md — `import <file>` positional + `--replace` destructive note (K5)
- AMPLIFY[SUBSTANTIVE]: docket-cli.md — `doc show --rev N` + `doc list` filters documented (K2, K3)
- AMPLIFY[SUBSTANTIVE]: docket-cli.md — bold `comment add` wrong-flag foot-gun outside the code fence (B5)

### Dimensions Evaluated
Completeness, Actionability, Coherence. Deferred: I41 (doctrine_check_manifest.tsv expansion, PARITY-BOUND), H19 (vorpal gofmt registry drift, unverifiable this cycle — network-blocked). R1 (docket --help re-discovery) routed cross-cutting to evolve-agents (LOCAL-block distribution question).

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass)

### Summary
Phase 3 disambiguation: scoped the invocation ban, the section-number stability rule, the issue enums, and the byte-exactness claim to their single intended readings.

### Changes
- AMPLIFY[SUBSTANTIVE]: SKILL.md — `disable-model-invocation: true` clarified as blocking model-initiated `Skill()` calls only; operator `/team-doctrine` still renders the index
- AMPLIFY[SUBSTANTIVE]: `evolve-phase0-templates.md` — stable-identifier rule now names who it binds (any editor), why (consumer §-citations break on renumber), and how new sections number (§10+; §7-§8 fillable only by DKT-273)
- AMPLIFY[SUBSTANTIVE]: `docket-cli.md` — Status/Priorities/Types enums prefixed "Issue" — three status vocabularies (issue enum, doc freeform, vote open/committed/rejected) shared one unlabeled line
- AMPLIFY[SUBSTANTIVE]: `docket-cli.md` — "byte-exact vs `--help`" scoped to command synopses; `#` annotations and enum/foot-gun lines are editorial, excluded from synopsis-vs-help drift checks

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading).

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass)

### Summary
Phase 2 coherence: documented the deliberate §7/§8 reservation (DKT-273) in evolve-phase0-templates.md and corrected the SKILL.md index cell to cover §9.

### Changes
- AMPLIFY[SUBSTANTIVE]: `evolve-phase0-templates.md` intro — added never-renumber note: §7-§8 reserved for DKT-273, §6→§9 jump intentional — prevents a future renumber breaking evolve-agents' §9 pointer
- AMPLIFY[COSMETIC]: SKILL.md index "Master for" cell for `evolve-phase0-templates.md` now names the §9 SDLC Role Research template alongside the auditors

### Dimensions Evaluated
Coherence, Completeness, Actionability

### Rename
No rename.

## 2026-07-13

### Summary
Applied 2 accepted Docket findings (DKT-264, DKT-266b) + 6 verified Phase-0 findings from a scoped evolve-skills cycle; added §9 sdlc-role-researcher template. Deferred I3 §7/§8 (symmetry_check.py + tokenization coupling — needs a dedicated cycle touching evolve-skills/SKILL.md too). Findings: 11 → 9 sub / 0 cos / 0 rej / 2 def / 0 enc

### Changes
- FIX[SUBSTANTIVE]: `monitor-orchestration.md` — named `docket --watch`/`-w`+`--interval` as explicit Monitor poll primitive (DKT-264; live --help verified)
- FIX[SUBSTANTIVE]: `evolve-phase0-templates.md` — 5× inline transcript-`find` → `recent_transcripts.sh` (DKT-266b); repo-relative path (undeployed `~/.claude/scripts/` corrected)
- FIX[SUBSTANTIVE]: `docket-cli.md` — added `vote commit` (D1) + doc `-s/-T` freeform note (D2); live `--help` verified
- FIX[SUBSTANTIVE]: SKILL.md — `disable-model-invocation: true` (C1); widened charter for spawn-TEMPLATE class + added `evolve-phase0-templates.md` index row (I1; restored 17=17 index-parity, previously violated 17-vs-16)
- FIX[SUBSTANTIVE]: `shutdown-protocol.md` SP-1b — flattened-shape WRONG variant + request_id-required note (Bug-Audit FIX1; 41 occ/26 sessions)
- FIX[SUBSTANTIVE]: `docs-paths.md` — repo-root vs `src/user/claude-code/` source-tree clarification (Bug-Audit PREVENT7; 8 sessions)
- FIX[SUBSTANTIVE]: `evolve-phase0-templates.md` — added §9 sdlc-role-researcher (I3; verbatim relocation from evolve-agents/SKILL.md, enabling a ~5.4KB relief there)
- DEFER: I3 §7 innovation-scanner (blocked by `symmetry_check.py`'s hardcoded byte-compare) + §8 docs-researcher (tokenization + partial-completion) — both need a dedicated cycle touching evolve-skills/SKILL.md + the script atomically

### Dimensions Evaluated
Completeness/Actionability (primary), Coherence (index-parity restoration, path convention), Over-Engineering (deferred §7/§8 to avoid a half-applied refactor that breaks the symmetry gate).

### Rename
No rename.

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
