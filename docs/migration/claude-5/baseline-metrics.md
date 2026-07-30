# Claude 5 Migration — Baseline Metrics (2026-07-29)

Mechanical baseline for the migration described in
`src/user/claude-code/docs/context-engineering-claude-5.md`. All numbers measured
on this date with `wc -c`, `wc -l`, and `grep -o` over
`src/user/claude-code/agents/*.md` and `src/user/claude-code/skills/*/`.
Marker counts are raw substring occurrences of `MUST`, `NEVER`, `ALWAYS`,
`CRITICAL` in markdown files (case-sensitive; `CRITICAL` tracked separately from
the charter's 3-marker census).

## Totals

| Scope | Files | Bytes | MUST | NEVER | ALWAYS | M/N/A total | CRITICAL |
|---|---:|---:|---:|---:|---:|---:|---:|
| Agents (8 .md) | 8 | 553,725 | 49 | 35 | 24 | **108** | 12 |
| Skills (17 dirs, .md only) | 33 .md + 2 scripts | 536,134 (md) + 23,352 (scripts) | 80 | 17 | 3 | **100** | 19 |
| **Fleet** | | **1,113,211** | 129 | 52 | 27 | **208** | 31 |

The charter's census (108 agent markers, 42 in team-lead; 100 skill markers)
reproduces exactly. The charter's size figures are approximate: it says agents
~554KB (measured 553,725 ✓), skills ~360KB of prose (measured 352,187 excluding
team-doctrine, 536,134 including it), and team-doctrine 216KB (measured 183,947
in-tree; the 216KB figure likely reflects the installed `~/.claude` copy or an
earlier revision).

Charter targets against this baseline: agents ≤170KB total with team-lead.md
≤30KB; skills ≥50% prose reduction; zero verbatim multi-line blocks shared
between two or more agent files; every surviving MUST/NEVER/ALWAYS maps to a
keep-list category, typical file ≤5, no file >10.

## Agents

| File | Bytes | Lines | MUST | NEVER | ALWAYS | M/N/A | CRITICAL | model | effort |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| team-lead.md | 137,218 | 530 | 19 | 19 | 4 | 42 | 0 | sonnet | xhigh |
| senior-engineer.md | 78,897 | 429 | 2 | 1 | 3 | 6 | 3 | sonnet | xhigh |
| staff-engineer.md | 67,580 | 326 | 9 | 4 | 3 | 16 | 1 | opus | xhigh |
| sdet.md | 61,892 | 389 | 2 | 4 | 4 | 10 | 3 | opus | xhigh |
| distinguished-engineer.md | 56,691 | 305 | 1 | 1 | 2 | 4 | 1 | fable | xhigh |
| security-engineer.md | 56,068 | 291 | 7 | 2 | 3 | 12 | 1 | opus | xhigh |
| project-manager.md | 48,476 | 370 | 6 | 2 | 3 | 11 | 2 | sonnet | high |
| ux-designer.md | 46,903 | 322 | 3 | 2 | 2 | 7 | 1 | opus | high |
| **Total** | **553,725** | 2,962 | 49 | 35 | 24 | **108** | 12 | | |

Effort pins: 6 of 8 agents pin `effort: xhigh` (charter §3: all three 5-gen
models default to `high` and often exceed prior-model `xhigh` at lower settings —
every pin needs re-derivation). Density note: team-lead.md averages one
MUST/NEVER/ALWAYS per ~3.3KB; it also loads on every orchestration session.

## Skills

`Bytes` is all files in the skill dir; `SKILL.md` is the entry file the charter's
10KB progressive-disclosure ceiling applies to. Marker counts cover .md files
only.

| Skill | Files | Bytes (dir) | SKILL.md bytes | >10KB SKILL.md | MUST | NEVER | ALWAYS | M/N/A | CRITICAL |
|---|---:|---:|---:|:---:|---:|---:|---:|---:|---:|
| team-doctrine | 18 | 183,947 | 7,526 | – | 18 | 8 | 3 | 29 | 0 |
| code-review-verdict | 1 | 42,125 | 42,125 | ✗ | 5 | 2 | 0 | 7 | 1 |
| vote | 1 | 39,047 | 39,047 | ✗ | 11 | 0 | 0 | 11 | 2 |
| docket | 1 | 34,362 | 34,362 | ✗ | 0 | 0 | 0 | 0 | 0 |
| session-metrics | 3 | 29,842 | 6,490 | – | 0 | 0 | 0 | 0 | 2 |
| verify-ac | 1 | 26,055 | 26,055 | ✗ | 3 | 3 | 0 | 6 | 1 |
| tdd | 1 | 25,758 | 25,758 | ✗ | 9 | 0 | 0 | 9 | 1 |
| commit | 1 | 21,633 | 21,633 | ✗ | 2 | 0 | 0 | 2 | 2 |
| ux-spec | 1 | 20,428 | 20,428 | ✗ | 6 | 0 | 0 | 6 | 1 |
| design-review | 1 | 20,402 | 20,402 | ✗ | 3 | 2 | 0 | 5 | 1 |
| simplify-scout | 1 | 19,613 | 19,613 | ✗ | 4 | 0 | 0 | 4 | 1 |
| adr | 1 | 19,261 | 19,261 | ✗ | 5 | 0 | 0 | 5 | 1 |
| design-qa | 1 | 19,024 | 19,024 | ✗ | 3 | 1 | 0 | 4 | 1 |
| prd | 1 | 17,823 | 17,823 | ✗ | 6 | 0 | 0 | 6 | 1 |
| init-specs | 1 | 16,930 | 16,930 | ✗ | 4 | 0 | 0 | 4 | 1 |
| review-and-comment | 1 | 12,125 | 12,125 | ✗ | 0 | 0 | 0 | 0 | 2 |
| brief | 1 | 11,111 | 11,111 | ✗ | 1 | 1 | 0 | 2 | 1 |
| **Total** | 36 | **559,486** | | | 80 | 17 | 3 | **100** | 19 |

15 of 17 skills are single-file monoliths; **15 of 17 SKILL.md files exceed the
10KB ceiling** (only session-metrics and team-doctrine's entry files are under
it — the two skills that already use a split layout).

## team-doctrine per-file breakdown

| File | Bytes | Lines | M/N/A markers |
|---|---:|---:|---:|
| references/evolve-phase0-templates.md | 59,991 | 480 | 9 |
| references/retention-compaction.md | 15,329 | 209 | 4 |
| references/runtime-discipline.md | 14,848 | 178 | 1 |
| references/evolve-orchestration-core.md | 12,836 | 82 | 1 |
| references/shutdown-protocol.md | 9,524 | 85 | 4 |
| references/design-gate.md | 9,268 | 121 | 1 |
| references/authoring-verification-gates.md | 8,636 | 121 | 2 |
| SKILL.md | 7,526 | 45 | 1 |
| references/docs-paths.md | 7,451 | 62 | 4 |
| references/monitor-orchestration.md | 6,897 | 45 | 0 |
| references/sandbox-recovery.md | 6,771 | 107 | 0 |
| references/laziness-discipline.md | 4,896 | 92 | 0 |
| references/pitfalls.md | 4,391 | 28 | 1 |
| references/truth-first-debugging.md | 4,350 | 63 | 0 |
| references/team-conventions.md | 3,992 | 28 | 0 |
| references/fable-completeness-heuristics.md | 3,227 | 16 | 1 |
| references/deep-collaboration.md | 1,682 | 17 | 0 |
| references/vorpal-tools.md | 2,332 | 32 | 0 |
| **Total** | **183,947** | 1,811 | 29 |

The charter names `laziness-discipline.md` and `fable-completeness-heuristics.md`
(8,123 bytes combined) as existing entirely for class 1.2 (4.x workarounds).

## Canonical-block duplication baseline (mechanical)

The tree self-documents its duplication: shared doctrine is fenced with
`<!-- CANONICAL:<NAME>:BEGIN/END -->` markers — a master copy in
`team-doctrine/references/` and `-LOCAL` inlined copies in agent/skill files.
Measured content bytes between fences:

| Block | Copies | Where | Total bytes | Redundant bytes¹ |
|---|---:|---|---:|---:|
| PITFALLS-LOCAL | 7 | all agents except team-lead | 12,446 | 10,668 |
| SHUTDOWN-PROTOCOL-LOCAL | 8 | all 8 agents (team-lead copy 3,910B, others 560B) | 7,830 | 7,270 |
| DOCKET-CLI-LOCAL | 8 | all 8 agents | 7,733 | 7,010 |
| TRUTH-FIRST-DEBUGGING-LOCAL | 7 | all agents except team-lead | 7,612 | 7,051 |
| BANNER | 14 | every skill SKILL.md except team-doctrine/docket/session-metrics² | 7,161 | 6,816 |
| SANDBOX-RECOVERY-LOCAL | 6 | dist/sdet/sec/senior/staff/ux | 6,605 | 5,924 |
| DOCS-PATHS-LOCAL | 16 | 7 agents + 9 skill SKILL.mds | 6,452 | 6,175 |
| VORPAL-TOOLS-LOCAL | 7 | all agents except team-lead | 4,053 | 3,474 |
| AUTHORING-VERIFICATION-GATES-LOCAL | 2 | distinguished, staff | 3,231 | 1,865 |
| DEEP-COLLABORATION-LOCAL | 6 | dist/pm/sdet/sec/staff/ux | 2,808 | 2,347 |
| DOCTRINE-SCRIPT-TRUST-LOCAL | 8³ | all 8 agents | 2,107+ | ~1,806 |
| LAZINESS-DISCIPLINE-LOCAL | 2 | sdet, senior | 1,438 | 719 |
| Single-copy blocks (masters + team-lead-only locals)⁴ | 14 | – | 55,949 | 0 |
| **Total canonical-fenced content** | | | **~125,425** | **~61,159** |

¹ All copies minus one master per block name.
² docket and session-metrics SKILL.md carry no BANNER fence; team-doctrine is the doctrine itself.
³ team-lead.md's copy (L519–521) is a one-line stub; the other 7 are identical 301-byte blocks.
⁴ Masters in team-doctrine/references/ (SHUTDOWN-PROTOCOL 8,657B; AUTHORING-VERIFICATION-GATES 7,571B; DOCS-PATHS 6,557B; SANDBOX-RECOVERY 6,055B; LAZINESS-DISCIPLINE 3,591B; TRUTH-FIRST-DEBUGGING 3,296B; PITFALLS 2,746B; HARVEST 2,010B; VORPAL-TOOLS 1,606B; DEEP-COLLABORATION 912B) plus senior-engineer-only blocks (READ-BEFORE-EDIT 4,175B; CODE-COMMENTS 2,397B; STALE-DISPATCH-CHECK 803B) and team-lead-only locals (RUNTIME-DISCIPLINE 3,001B; MONITOR-ORCHESTRATION 1,728B; FABLE-COMPLETENESS-HEURISTICS 844B).

The charter's "seven multi-line blocks verbatim in all seven specialist agent
files" corresponds to: DOCS-PATHS, VORPAL-TOOLS, PITFALLS, SHUTDOWN-PROTOCOL,
TRUTH-FIRST-DEBUGGING, DOCKET-CLI, and DOCTRINE-SCRIPT-TRUST — confirmed
mechanically. Several agent copies both inline the content and cite the
team-doctrine master path, matching charter class 1.5's "both inline and cite"
observation. ~61KB (11% of agent bytes) is eliminable by deduplication alone,
before any class 1.1–1.4 deletions.

Note for remediation: the charter's zero-verbatim-duplication target makes the
entire CANONICAL-fence machinery (a 4.x attention-decay workaround) obsolete —
the fences themselves, plus the "Master: …" citation lines inside the copies,
are deletable overhead on top of the block content.

## After metrics — Phase 2 agent rewrites (2026-07-29)

Measured with the same commands as the baseline, one row appended as each
agent's rewrite lands. Parity-locked CANONICAL blocks
(`doctrine_check_manifest.tsv`) are retained byte-verbatim, and skill-cited
anchors (team-lead Rules/steps, sdet SP-2/Rule 7, senior-engineer's 12
principles, etc.) are preserved, so per-file floors sit above the charter's
reference-split projections — Phase 2 cannot create reference files (skills are
Phase 3). Checks re-run green per row: doctrine_check.sh (4 arms),
tier_map.sh, drift_guard_check.py, model_census.sh (no new actionable hits),
census exemption anchors.

| File | Bytes before | Bytes after | Δ | MUST | NEVER | ALWAYS | M/N/A (was) | CRITICAL (was) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| team-lead.md | 137,218 | 76,878 | −44.0% | 5 | 7 | 3 | 15 (42) | 0 (0) |
| senior-engineer.md | 78,897 | 48,108 | −39.0% | 0 | 1 | 2 | 3 (6) | 1 (3) |
| staff-engineer.md | 67,580 | 40,785 | −39.7% | 2 | 2 | 3 | 7 (16) | 1 (1) |
| sdet.md | 61,892 | 42,018 | −32.1% | 0 | 2 | 2 | 4 (10) | 1 (3) |
| distinguished-engineer.md | 56,691 | 41,576 | −26.7% | 0 | 1 | 2 | 3 (4) | 1 (1) |
| security-engineer.md | 56,068 | 41,526 | −25.9% | 3 | 2 | 2 | 7 (12) | 1 (1) |
| project-manager.md | 48,476 | 34,446 | −28.9% | 3 | 2 | 3 | 8 (11) | 1 (2) |
| ux-designer.md | 46,903 | 37,485 | −20.1% | 1 | 2 | 2 | 5 (7) | 1 (1) |
| **Fleet** | **553,725** | **362,822** | **−34.5%** | 14 | 19 | 19 | **52 (108)** | **7 (12)** |

**Shortfall note vs the 40–60% task target.** The fleet lands at −34.5% (team-lead
−44.0%, the largest absolute cut at 60.3KB). The residual gap is structurally
pinned in Phase 2, where skills, hooks, and scripts are out of scope:
(a) ~24KB of parity-locked CANONICAL blocks (`doctrine_check_manifest.tsv`
registers PITFALLS/VORPAL-TOOLS/SHUTDOWN-PROTOCOL/DOCTRINE-SCRIPT-TRUST/
LAZINESS across 2–7 carriers each; compacting them is a coordinated
all-carriers + manifest edit — the manifest lives in `scripts/`);
(b) machine-parsed anchors (tier_map.sh's Tiers block + Per-Role Dispatch
Table, drift-guard-pinned fenced script syntax, SP-1/1b/2/3 literals,
model-census exemption substrings) and skill-cited anchors (team-lead
Rules/steps, sdet SP-2/Rule 7, senior-engineer's 12 numbered principles,
ux-designer's HIG catalogue — the declared single home for 3 skills);
(c) evidence-backed keeps the audit manifest routes to reference-file splits
(its remediation items #2/#3/#7) that only the Phase 3 team-doctrine
restructuring can perform. Charter §4's own caveat governs the stop point:
reduction is a consequence of applying §1, never a goal pursued by deleting
context the model cannot reconstruct. Phase 3 unlocks the remainder.

## After metrics — Phase 3 skill rewrites (2026-07-29)

Measured with the same commands as the baseline after rewriting all 17 skills
under `src/user/claude-code/skills/`. `Bytes (dir)` counts every file in the
skill dir (including unchanged scripts and reference files); `SKILL.md` is the
entry file loaded on every invocation — the per-invocation context cost the
charter's progressive-disclosure rule targets. Checks re-run green after every
skill: doctrine_check.sh (all 4 arms), coupling_check.py (8/8 family notes),
symmetry_check.py, docket_ref_check.sh (51 subcommands, no drift).

| Skill | Bytes (dir) before | after | Δ | SKILL.md before | after | refs files | M/N/A (was) |
|---|---:|---:|---:|---:|---:|---:|---:|
| team-doctrine | 183,947 | 129,435 | −29.6% | 7,526 | 5,011 | 17 | 14 (29) |
| code-review-verdict | 42,125 | 31,464 | −25.3% | 42,125 | 19,030 | 4 | 3 (7) |
| vote | 39,047 | 25,267 | −35.3% | 39,047 | 19,184 | 2 | 4 (11) |
| docket | 34,362 | 27,224 | −20.8% | 34,362 | 21,183 | 1 | 0 (0) |
| session-metrics | 29,842 | 27,978 | −6.2% | 6,490 | 4,626 | 0 | 0 (0) |
| verify-ac | 26,055 | 17,503 | −32.8% | 26,055 | 15,424 | 1 | 2 (6) |
| tdd | 25,758 | 16,432 | −36.2% | 25,758 | 16,432 | 0 | 4 (9) |
| commit | 21,633 | 10,828 | −49.9% | 21,633 | 10,828 | 0 | 1 (2) |
| ux-spec | 20,428 | 14,001 | −31.5% | 20,428 | 14,001 | 0 | 4 (6) |
| design-review | 20,402 | 16,099 | −21.1% | 20,402 | 13,623 | 1 | 1 (5) |
| simplify-scout | 19,613 | 13,923 | −29.0% | 19,613 | 10,834 | 1 | 1 (4) |
| adr | 19,261 | 12,638 | −34.4% | 19,261 | 12,638 | 0 | 2 (5) |
| design-qa | 19,024 | 12,654 | −33.5% | 19,024 | 12,654 | 0 | 1 (4) |
| prd | 17,823 | 12,519 | −29.8% | 17,823 | 12,519 | 0 | 2 (6) |
| init-specs | 16,930 | 12,018 | −29.0% | 16,930 | 12,018 | 0 | 1 (4) |
| review-and-comment | 12,125 | 9,654 | −20.4% | 12,125 | 9,654 | 0 | 0 (0) |
| brief | 11,111 | 7,366 | −33.7% | 11,111 | 7,366 | 0 | 1 (2) |
| **Total** | **559,486** | **397,003** | **−29.0%** | **359,713** | **217,025** | **−39.7%** | **41 (100)** |

**Loaded-context view (the operative number).** Summed SKILL.md bytes — what an
invocation actually pays — fell 359,713 → 217,025 (−39.7%); md-only prose
excluding the deliberately unchanged `evolve-phase0-templates.md` (see below)
fell 476,143 → 313,660 (−34.1%). M/N/A markers fell 100 → 41 (−59%), CRITICAL
19 → 19 (banner-carried commit/no-spawn gates, all keep-list cat 1/3); every
surviving marker maps to a keep-list category (commit/authority gates, family
lockstep contracts, validator-enforced format rules), typical file ≤4, no file
above 5 outside team-doctrine's 18-file aggregate.

**Structural result.** 15-of-17 single-file monoliths → 9 skills now carry
`references/` files loaded on demand (crv output templates + hard-gates +
evidence-gates; vote reviewer-template + non-vote; verify-ac rounds;
design-review's shared accessibility checklist consumed by design-qa;
simplify-scout principles-lens; docket workflows; team-doctrine's existing 17).
Recall fixes landed per the audit's counter-current protections: crv triage is
explicitly an effort-ORDER rule, design-review Blockers permit
"alternative: none identified", design-qa reports principle-less findings with
a tag instead of dropping them, simplify-scout maps un-taxonomized wins to the
closest principle instead of discarding them. Live defects fixed: init-specs
max-4-options vs 7-filename multiSelect (routing round), init-specs
ask-on-failure → respawn-once, evolve-orchestration-core's 2-turn stall
heuristic scoped to completed turns (Fable long-turn misfire), session-metrics
"n/a" prose realigned to the renderer's `n/a (unpriced model)`, commit's
`(claude-code)`-scope contradiction resolved in Step 2, adr's atomicity claim
scoped to allocators that consult `next_doc_number.sh`. All five skill `effort:
xhigh` pins removed (charter §3 re-derivation; review holds at lower effort).

**Recorded >10KB justifications (charter §4).** 13 SKILL.md files exceed 10KB;
each carries machine-parsed or parity-locked format authority that cannot move
behind a Read: docket (21.2KB — the 51-subcommand flag reference is parsed in
place by `docket_ref_check.sh`, whose default target is this file), crv/vote/
verify-ac/design-* (report_lint.py section/ladder/trailing-line contracts +
byte-locked BANNER/scope-table parity blocks), doc family (doc_validate.py
frontmatter + Required Sections contracts + ARGUMENT_HANDLING/COLLISION_DIALOG/
SAVE_AND_RETURN parity blocks registered in `doctrine_check_manifest.tsv`),
init-specs (spawning template + RESERVED-NAMES authority), commit and
simplify-scout marginally over on banner + gate text.

**Structurally pinned residue (out of Phase 3 scope).**
(a) `evolve-phase0-templates.md` (59,991B) is byte-unchanged: its §-numbered
templates and per-section token sets are pinned by the out-of-scope
`.claude/skills/evolve-*` consumers, whose Template-sourcing prose enumerates
exact token lists per section ("no spawn-time tokens" for §4/§5; "the only
spawn-time token is {HARVEST_BLOCK}" for §3c) — the manifest's `{SCAFFOLD_*}`
tokenization is only safe as a coordinated evolve-skills-cycle change that
edits consumers in lockstep. (b) Parity-locked CANONICAL blocks (BANNER across
12 registered carriers, ARGUMENT_HANDLING/COLLISION_DIALOG/SAVE_AND_RETURN
across the doc family, BANNER-CALLER-SIDE-EFFECT across commit +
review-and-comment) were kept byte-identical because `doctrine_check.sh` arm
(c) enforces cross-carrier parity from `scripts/doctrine_check_manifest.tsv`
and scripts are out of scope — compacting them is a coordinated all-carriers +
manifest edit. (c) Arm (d) requires team-doctrine/SKILL.md's `Cited by` column
to match live grep results, so the index keeps that column. All 17
team-doctrine reference files remain at their paths — every one is cited by
the read-only Phase 2 agents or the out-of-scope evolve-* skills — with 15
rewritten in place (the shrink-not-delete resolution of the manifest's three
DELETE-WHOLE-FILE verdicts, which predated the citation map).
