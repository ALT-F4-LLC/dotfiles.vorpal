# 08 — Decisions and measurement

Status: approved — 2026-08-02 — **D1–D16 ratified by Erik** (including D14's trust
posture). Per his structured review, **this design carries no open questions**: every former question is resolved into a ratified decision with a
revisit trigger — keyed to engine-produced facts where the domain allows (E-8;
governance and adoption decisions D6/D7/D10 key to operator experience), under which
the decision earns re-examination through the amendment discipline (§3). D1–D11
resolve the original question list; D12–D16 record the review-round decisions.

## 1. Decisions

**D1 — Conductor placement.** The conductor role runs in the operator's session on the
session model (03 §3). *Revisit if:* relay tokens exceed ~5% of run cost, or
`guard spawn`/`guard record` denials recur across runs (ledger query).

**D2 — Fan-out widths.** Standard-change ships 4 judges; security 5 (05 §2). *Revisit
via:* retro's per-judge sole-reporter analysis — a judge that never uniquely
contributes above `low` across 5 runs is cut by a workflow version bump.

**D3 — Synthesize node stays.** Clustering remains a judged step in v1. *Revisit if:*
duplicate-rate at width ≤4 stays under 10% across 5 runs — then exact-locus dedup
replaces it (retro proposal).

**D4 — Lease TTLs and durations.** read 15m / write 45m / research 20m, plus
`max_step_duration` per class (write 2h) in `[limits]`/config. *Revisit via:* p99 step
duration + lease-expiry false-positive counts after ~10 runs.

**D5 — Planner latitude.** The planner composes the work DAG only; process stays in
workflow definitions. Recurring *work* shapes migrate into workflow templates via
retro proposals — never via planner improvisation. *Revisit if:* run records show the
same multi-issue shape planned ≥3 times.

**D6 — Single-repo runs.** One repo, one DB, per-repo config in v1; multi-repo needs
are served by per-repo bootstrap from shared templates. *Revisit only against:* a real
run materially blocked by the boundary.

**D7 — No metrics exporter.** `docket events --follow` and `run report` are the
observability surface. An exporter over events is a separate tool, never core (06 §7).
*Revisit if:* dashboard need returns in practice.

**D8 — Retro cadence.** Operator-invoked; the session *suggests* a retro after every
5 completed runs (a conversational nudge — zero-touch compliant, never automatic
execution). *Revisit via:* mean runs-between-detection for issues retro eventually
files.

**D9 — Writers serialized; worktrees optional.** Single-writer serialization
(`[limits] write = 1`) is the always-available atomicity baseline — ratified twice
(panel round; review item 3.4). Worktree isolation is an optional optimization an
instance may adopt, **never a requirement** of the solution. *Revisit against:* a real
run materially blocked by serialization, with merge semantics specified before
adoption.

**D10 — Staging governance.** Delivery follows 06 §10's seven stages; `--json=v2`
default-flips when stage 7 ships and the old fleet retires; the genericity rule
(06 §7) is a standing PR review bar. Maintainer prerogative to re-sequence is
governance, not an open question.

**D11 — Heartbeat markers.** Token-bound 0600 markers in a per-user runtime dir,
contingent on M3's private-$TMPDIR check; on failure, markers are cut and TTL +
`max_step_duration` alone carry liveness. Decided fallback; nothing pending.

**D12 — Zero-touch instance (T9).** Ratified: developers provide work and approvals
in conversation; all instance config is machine-authored (bootstrap skill) and
machine-evolved (retro), auto-registered at activation (06 §2). *Revisit:* never — a
design element requiring manual upkeep is a defect by tenet.

**D13 — No one-off harness scripts.** Former glue is core: `step render` (prompt
layout), builtin `aggregate` (ordered-enum reconciliation), the `guard` family (hook
predicates). A drop-in adopter on any harness needs prose, one spawn adapter, and
one-line hook shims — nothing else (06 §2). *Revisit if:* a new glue need appears; the
default answer is a generic core verb, not a script.

**D14 — Conversational trust.** The session proposes, the human approves in-chat, the
session runs `trust add --yes`; the harness's command-permission prompt is the
human-confirmation backstop. Residual risk — a misbehaving session self-trusting a
command — is accepted, bounded by full-argv hashing and the permission layer (06 §4).
*Revisit if:* any run shows a trust entry **or gate resolution** the operator doesn't
recognize (report audit) — approve/resolve are middleware verbs inside the
session-trust boundary, and this trigger is their watchdog (03 §6).

**D15 — Config lifecycle.** Instance config lives in-repo at `.docket/config/`,
git-versioned, content-hash auto-registered at activation; schemas are stable reviewed
files, never generated per-run; strangers start from shipped templates
(`workflow init --template`). *Revisit via:* retro friction reports (e.g. config
churn per run trending up).

**D16 — 02 semantics ratified by expert panel.** Two-expert panel (workflow-engine
semantics; concurrency/crash-safety) returned SOUND WITH FIXES; all fixes are folded
(dispatch TTL/abandon + single-open CAS; loop lineage `name@k#i` with `superseded`;
token retirement at artifact record; at-least-once idempotent gates with
`gate-started` events; write-reap acknowledgment; no-subprocess-in-transaction;
retention-scoped replay; effective-status reads; fanout join semantics; human
resolution vocabulary; floor accrual per claim). *Revisit via:* 06 §9's acceptance
proofs at implementation time — each fix has a testable criterion.

## 2. Measurement plan (first ~10 runs)

All native to the engine — queries, not instrumentation projects.

| Question | Query over |
|---|---|
| Cost per run / node type / model | step ledger (usage, metadata.model) |
| Where does spend concentrate? | step ledger grouped by executor × workflow |
| Real dispatch closure per node | context-bundle byte counts recorded at assembly (02 §8) |
| Intervention profile | `waiting-human` events by reason (designed gate vs breach vs held) |
| Attempt/fix-loop pressure | attempt counters, loop ordinals per issue |
| Gate health | gate results: fail rates, flake disagreements, durations |
| Judge value (D2) | reconciled clusters: sole-reporter counts per judge × severity |
| Reconciliation integrity | held rate, demotion-trail counts (E-3's guardrails as metrics) |
| Model routing drift | metadata requested-vs-resolved per step |
| Budget-floor fidelity | engine floor vs reported usage per run (calibrates expected_cost) |
| Relay overhead (D1) | session tokens per wave vs run total |
| Config churn (D15) | retro-proposed config edits per run |
| AC-integrity (the acceptance criterion) | event-log audit: any transition not attributable to next/gate/threshold/human — must be zero |

## 3. Amendment discipline

This design changes by the same mechanism it prescribes: a proposal (retro issue or
operator request in conversation) → an edit to one versioned file → normal review. Two
standing rules: an amendment that moves work across the AC boundary (model ↔ engine)
must cite evidence per 01 §3's standard, and an amendment that adds manual upkeep for
the developer violates T9 on its face.
