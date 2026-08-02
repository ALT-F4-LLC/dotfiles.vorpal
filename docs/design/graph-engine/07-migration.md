# 07 — Migration: from the fleet to the graph

Status: approved — 2026-08-02. This document is the parity proof and the path. §3 maps every current
file to its destination (nothing is dropped silently); §2 sequences the work; §4 defines
the v1 test; §5 lists risks with mitigations; §6 is rollback.

## 1. Honest accounting up front

The fleet is ~800KB of prose the harness loads plus ~83 scripts. The replacement is
~15KB of harness-loaded prose (three skills — plan, run, bootstrap — the wave
workflow, three archetypes),
~130–150KB of *versioned data* (25 contracts, ~16 fragments, 9 pipelines, policy, trust
file), the gate commands that survive as-is, and the deterministic layer per 06: Docket vNext's
generic workflow engine (staged, 06 §10) plus one harness adapter (wave.js) and
one-line hook shims — former glue (brief.sh, reconcile.py, hook logic) is absorbed
into core as `step render`, the builtin `aggregate`, and the `guard` family.

Total bytes are **not** the win and this design does not claim they are (E-5: bytes were
~1% of invocation cost). The wins are structural: no byte is duplicated (fragments have
one home; the doctrine-parity CI has nothing to police), no byte is protocol (the engine
owns coordination; contracts are pure judgment), every change is local (T7), and every
spawn's real context is assembled and measured (T3). The maintenance object shrinks from
"a coherent 800KB narrative" to "independent small files with pinned versions."

## 2. Phases

**M0 — Ratify.** This doc set reviewed/amended by Erik. Freeze the current fleet's
evolve-* cycles for the duration (avoid migrating a moving target). No repo changes.

**M1 — Docket vNext, staged** (Go, Erik's plate; largest block). Seven stages per
06 §10, each an independently useful public release: reliability delta → claims/
capabilities → workflows/steps/next (the spine; loop semantics land here) → gates +
trust model → payload schemas/ordered enums/action steps → runs/budget floor/report/
dispatch → events. Stage 1 pays off for the *current* fleet immediately (deletes the
nine wrapper scripts — seven docket_*, two vote_*); v4 DBs open unmodified throughout;
the genericity rule (06 §7) is the review bar for every stage. The economics panel's
Go estimate applies to the whole arc — the L-items (state machine, expansion/loops,
gate trust) dominate and come earliest, which is why the v1 shadow run gates on
stage 6, not stage 7.

**M2 — Generate the data corpus** (machine-authored, T9): the bootstrap skill mines
the repo and its git history and drafts the 16 fragments, 24 contract files (04 §4's 25 nodes include `plan`, which lives as
the intake skill; three contracts exist as exemplars seeding the style), 9 workflows +
policy, and trust proposals; Erik
approves conversationally; retro evolves everything thereafter. Hand-authoring is the
fallback, not the plan. Needs no new infrastructure beyond the bootstrap skill
itself.

**M3 — Harness wiring** (small): `plan`/`run` skills + the saved `wave` workflow + three
archetypes + the hook set (03), plus first-use trust setup the zero-touch way: bootstrap proposes the entries (M2),
the operator approves in conversation, the session runs `docket trust add --yes`
(06 §4; 08 D14)
and three explicit checks: each subagent gets a private $TMPDIR (heartbeat markers,
03 §5 — on failure, markers are cut and TTLs carry liveness); the wave journal exposes
per-agent usage (03 §3 — on failure, `--accept-missing-usage` + the engine floor
carry budgets); and the harness permission config matches D14's assumption —
`docket trust *` prompts while other docket verbs are allowlisted (the backstop is
load-bearing only if so configured).
Installed alongside the current fleet (separate subtree in the dotfiles source so both
render; the old fleet stays default until M5). Note Erik's harness sandbox: Bash writes
to `.claude/{agents,skills,hooks}` are denied while Edit/Write pass — wiring happens
through the dotfiles render path (or file tools), not shell scripts.

**M4 — v1 shadow run** (§4). First real run; fix what it exposes; repeat on a second
change if the first forced material changes. The AC-integrity audit reads the events
surface that ships with stage 6 (06 §10).

**M5 — Cutover per workflow.** Adopt the graph system as default for standard changes
first, then security/UI/docs pipelines as each sees a real run. Delete the old fleet
when Erik calls it — deletion is one dotfiles change (§6).

## 3. Parity map

### 3.1 Agents (8 files, 378KB)

| Current | Judgment content → | Protocol content → |
|---|---|---|
| team-lead.md (82.7KB) | plan skill (pattern choice = planner judgment) | run skill + wave workflow (relay) + engine scheduling, activation, promotion, vote gates, run report, policy tiers, hooks |
| senior-engineer.md | `implement`, `fix` contracts; code-philosophy, tdd-discipline, scope-discipline fragments | claims/leases, self-hygiene gate, close-verify recording — engine |
| staff-engineer.md | `tdd-author`, `adr-author`, `judge-architecture` | freeze protocol → `issue.diff` fingerprint; panels → pipeline fanout; acceptance → vote gate |
| distinguished-engineer.md | `tdd-author` (primary), `investigate`, `research`; innovation duties → `retro-analyst` | mode/tier gating → policy; WebFetch falsification → evidence-rules fragment |
| security-engineer.md | `threat-model`, `judge-security`, `tdd-author-security`; both security fragments | security pipeline, model `never` list, vote-gated waivers, vuln/secret gates |
| project-manager.md | plan skill (decomposition), `prd-author` | DoR/distillation/collision → activation lints + scope scheduling |
| sdet.md | `judge-testing`, `verify-ac`, `test-infra` | red-green/regression/flaky → gates; reopen-on-BLOCK → threshold routing |
| ux-designer.md | `ux-spec-author`, `judge-design`, `design-qa`; hig, copy fragments | render/copy gates; ui-change pipeline; QA-verdict-to-Docket ritual → recording is structural |

### 3.2 Skills (17 repo skills + the harness-level evolve-* suite)

| Current | → |
|---|---|
| adr, prd, tdd, ux-spec | author nodes + doc-validate/preflight gates + `spec-doc` pipeline (acceptance = vote/human gate) |
| brief | plan skill (intake half) |
| code-review-verdict | judge contracts + hard-gates/evidence fragments; verdict itself abolished (T5) — thresholds route |
| commit | `commit-author` + commit-msg/commit-exec gates + human commit gate + commit-guard hook |
| design-review / design-qa | `judge-design` (spec stage) / `design-qa` node + render/copy gates |
| docket (24KB ritual doc) | dies with its cause: CLI reliability fixes (06 §5); residual verbs live in conductor/plan definitions |
| init-specs | `spec-project` pipeline + `spec-author` node |
| review-and-comment | `pr-comment-author` + per-item human gate + gh posting gate (`release` pipeline) |
| session-metrics | native run ledger + `docket run report` |
| simplify-scout | `judge-simplicity` (review lens) + `investigation` pipeline for standalone scans |
| team-doctrine | dissolved — see 3.3 |
| verify-ac | `verify-ac` node + ac-commands gate + thresholds |
| vote | vote gates (engine) + policy criticality table |
| evolve-* suite (5, harness-level) | retro pipeline (05 §6) + bootstrap skill (03 §1) |

### 3.3 team-doctrine references (19)

Fragments: truth-first, laziness-ladder, vorpal-toolchain, evidence-rules
(authoring-verification-gates' evidence half). Engine mechanisms: docs-paths (artifact/doc ownership + activation
lint), design-gate (spec-doc pipeline + activation checks), monitor-orchestration &
stall-recovery (leases/events), sandbox-recovery (attempt routing). Deleted with cause
gone: runtime-discipline, deep-collaboration, pitfalls machinery (→ retro pipeline),
retention-compaction, shutdown-protocol, team-conventions, fable-completeness-heuristics
(brief assembly + payload validation), evolve-orchestration-core + phase0-templates
(→ retro pipeline), claude-5-paradigm-gate (its keep-list spirit is 04 §2's format
rules; there is no fleet prose left to police).

### 3.4 Hooks (6)

guard-no-commit → `commit-guard` (engine-queried; awk parser retained). guard-tmp-write
→ kept as-is. stop-guard → `run-guard` (rewritten against run state; signature-file rate
limiting dies). subagent-report → `wave-audit`. task-completed, teammate-idle →
deleted (teams runtime not used). New: `spawn-guard`, `heartbeat`, SessionStart
injection (03 §5, §7).

### 3.5 Scripts (83)

**Survive as registered gates (commands unchanged where possible):** ac_check,
red_green_verify, regression_diff, flaky_confirm, fixture_shape_check, copy_verify,
render_verify, doc_validate.py, doc_preflight, doc_stage_validate, tdd_preflight,
check_citations, xref_check, next_doc_number, slug, spec_verify, self_review_scan,
secret_scan, govulncheck, go_verify, go_get_offline, config_render_diff, config_verify,
audit_snapshot, commit_msg_check, commit_execute, phase_diff (→ scope gate), g5_check,
rc_pr_setup, gh_inline_comment. **(30)**

**Absorbed by engine features:** docket_bootstrap/claim/close/create/promote/write/
ref_check (7 → CLI reliability, claims, activation); gate_check (→ gate results);
dispatch_ledger + cycle_metrics (→ run ledger/report); deadman_watch, singleton_wait,
edit_baton, roster_sweep (→ leases + scope exclusion); with_timeout (→ gate timeouts);
dor_check, plan_collision_check, section_digest (→ activation lints); vote_delegate,
vote_record (→ vote gates); tree_fingerprint, verify_carry_forward (→ issue.diff
fingerprint + delta re-review); tier_map, model_census, ref_census, spawn_model_join,
spawn_owner_lookup, tool_call_frequency, recent_transcripts (→ native ledger/census);
byte_ceiling_check (→ brief size caps); mimir_query (→ events; optional exporter, 08).
**(31)**

**Deleted with their cause:** doctrine_check + doctrine_check_manifest.tsv,
symmetry_check, coherence_xref, coupling_check, changelog_normalize, byte_ceilings.tsv,
model_census_exemptions.tsv, rule_probe + rule_probes.tsv, report_lint +
report_stage_lint (verdict formats abolished; payload validation replaces format
linting), pitfalls_check/compactable/distill, find_pitfalls, findings_ledger_init/check,
evolve_preflight, evolve_signals, drift_target, drift_guard_check (prose-drift seams
have no successor to police). **(22)**

Every script appears in exactly one bucket; 30 + 31 + 22 = 83.

## 4. The v1 test (pre-registered)

Per E-1, no retrospective benchmarks. The test is: **one real change Erik cares about,
run on the graph system, concurrent with his normal expectations, judged by him.**

Protocol (register before the run, in the run's plan artifact):

1. Pick a change of standard-change shape, 2–5 issues, real stakes, in a repo with
   build/test gates available.
2. Record predictions: expected cost band, expected interventions (plan approval, held
   findings, commit gate — target: no others), expected wall-clock band.
3. Run it. Touch nothing mid-run except through human gates (interventions outside gates
   are themselves findings).
4. Judge on the pre-registered dimensions only: outcome quality (Erik's call, on the
   diff), interventions (count + whether each was a designed gate), cost and wall-clock
   vs bands (ledger is native), and AC-integrity — the event log must show zero
   scheduling decisions made by a model (this is the acceptance criterion made testable).
5. Disposition: adopt-and-iterate (fix list into the retro pipeline) or halt-with-cause
   (a structural failure — engine decision made by a model, unrecoverable state, or
   Erik judges the outcome worse than his normal process at similar cost).

What is deliberately absent: quality scoring against the old fleet on the same change
(running both doubles spend for a comparison E-1 says is confounded anyway — the operator
judgment *is* the instrument), corpora, and any metric a model reports about itself.

## 5. Risks

| Risk | Mitigation |
|---|---|
| The engine is public Go work on one person's plate (the economics panel's central objection) | Staged delivery (06 §10): every stage is a small, independently useful release; the old fleet keeps working throughout; v1 needs stages 1–6, stage 1 pays off day one — and phases gate *cutover*, not authoring: M2/M3 proceed in parallel from stage 2 (06 §10) |
| Genericity erosion: fleet-specific vocabulary leaking into core over time | The genericity rule is a stated review bar (06 §7): no model/prompt/agent fields in core surface — metadata KV and executor hints exist precisely to carry such things opaquely; the stranger test (06 §9.1) is an acceptance criterion |
| Residual harness determinism (wave.js adapter + hook shims) drifting into loose scripts | The adapter is hash-pinned and shims are one-line `docket guard` calls; invocation points are mechanical; any new model-discretionary script is a design violation (01 §6) |
| Garbage-in at plan time (bad ACs/scopes poison downstream judgment) | activation lints (DoR, self-sufficiency, scope-required); verify-ac treats bad ACs as reportable defects, not puzzles; scope gate catches wrong guesses |
| Clustering variance (the one judged step inside reconciliation) | measured tolerance (E-7 ±17%); held-cluster escape to human; 08 D3 tracks whether synthesize is needed at small fan-out |
| Relay discipline (run skill drifts, wave mis-invoked) | the relay holds no authority hooks + atomic claims don't check; worst case is stalling, which leases + run-guard surface (08 D1) |
| Harness API drift (Agent tool, hooks, subagent limits) | one seam (conductor + hooks); a break fails loud in one file — never fossilizes into node prose (E-10) |
| Fan-out cost | width is a pipeline knob; budget caps pause runs; ledger makes spend per node visible from run one |
| Fragment/contract drift over time (the new corpus rotting like the old) | no duplication to drift (one home per fact); versions pinned per run; retro pipeline exists precisely to propose edits from evidence |
| Solo-maintainer bandwidth | strict phase gates M1→M4; each phase leaves the previous system fully working; nothing requires a flag-day |

## 6. Rollback

The old fleet is untouched until M5 — except stage 1's nine wrapper-script deletions
(git-reversible, and the new CLI is byte-compatible per 06 §9.8) — and both trees
render from the same dotfiles source.
Rollback at any phase = select the old subtree in the dotfiles build (one change), plus
`docket migrate` having been additive means the DB stays valid for the old wrappers.
There is no data migration to reverse: workflow state lives in additive, dormant tables
the old fleet never touches (06 §9.8 compatibility proof), and the reliability delta is
opt-in via `--json=v2` — rollback needs no data surgery at any stage.
