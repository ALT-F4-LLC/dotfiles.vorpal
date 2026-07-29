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
