# Graph engine — design

A graph-engineered replacement for the hub-and-spoke Claude Code fleet in
`src/user/claude-code/`. Status: **APPROVED — 2026-08-02** (Erik Reinert). The binding
basis for implementation; nothing is implemented yet, and the current fleet remains
untouched until M5 cutover (07 §2).

Date: 2026-08-02 · Author: Claude (Cowork session) · Reviewed and approved by Erik Reinert

## The idea in five lines

- **Docket decides. Claude judges. Hooks enforce. Artifacts flow.**
- Work is a DAG of issues (judged into existence by a planner); process is a versioned
  pipeline per issue (expanded deterministically by Docket).
- Every LLM invocation is a task-typed node: assembled brief in, markdown artifact out.
- Everything deterministic — scheduling, claims/leases, gates, budgets, audit — is
  Docket's job: a generic, domain-neutral workflow engine anyone can use; fleet
  specifics ride on top as config. Never a prompt's job.
- The 800KB prose fleet becomes ~15KB of harness definitions plus small, versioned,
  single-homed data files — machine-authored, human-approved in conversation (T9:
  the developer provides work and judgment, nothing else).

## Reading order

| Doc | What it holds |
|---|---|
| [example-run.html](example-run.html) | **Start here** — the whole design as one annotated example run (open in a browser; light/dark) |
| [01-principles.md](01-principles.md) | Acceptance criteria → tenets; binding evidence; rejected alternatives |
| [02-engine.md](02-engine.md) | Engine semantics: entities, two-level graph, scheduling, reconciliation, budgets, resume |
| [03-runtime.md](03-runtime.md) | Claude Code side: planner, conductor, executor archetypes, hooks, human gates, failure table, two worked runs (§9 standard, §10 discovery) |
| [04-nodes.md](04-nodes.md) | Contract format, knowledge fragments, 25-node inventory, three full exemplar contracts |
| [05-pipelines.md](05-pipelines.md) | Pipeline TOML format, the standard nine, gates registry, vote gates, retro pipeline |
| [06-docket-vnext.md](06-docket-vnext.md) | Docket vNext: the generic workflow engine (surface, semantics, trust model, staged delivery) + what stays outside as instance config |
| [07-migration.md](07-migration.md) | Phases, full parity map (every current file → destination), v1 test protocol, risks, rollback |
| [08-decisions.md](08-decisions.md) | Ratified decisions D1–D16 (no open questions) + the measurement plan |
| [09-implementation-plan.md](09-implementation-plan.md) | Phase packets: vehicle, required files, kickoff prompts, review gates, risks (plan v1, living) |

A reviewer short on time should open example-run.html, then read 01, 02, and 07 §4 (the
v1 test), then skim 05 §1's worked pipeline.

## Alignment record (Phase 0, 2026-08-02)

Recorded verbatim so future sessions inherit the constraints rather than re-deriving them.

**Acceptance criteria (Erik):** non-deterministic work done by LLMs; deterministic work
done by Docket.

**Phase 0 answers (Erik):**

1. Prior effort (`docs/migration/graph-redesign/`, corpus, docket_ref_check, docket
   SKILL.md): *fully fresh rethink* — prior designs and even prior recorded answers carry
   no authority; only empirical dead-ends are respected as evidence (01 §3).
2. Engine: *Docket IS the engine* — issues/relations/plan/next as the graph core;
   extending Docket itself (Go) with graph-native primitives is in scope.
3. Spawning: *all agent spawns happen inside the Claude Code harness from prose/definition
   files; not necessarily team-lead.* No external runner drives the system.
4. Deliverable: *design doc only* — reviewed before any implementation.
5. Scope: *everything the fleet does today* gets explicit graph treatment (07 §3 is the
   parity proof).
6. Node model: *task-typed capability nodes*; the 8 role personas dissolve; expertise
   survives as knowledge fragments (04 §3).
7. Docket evolution: *graph-native features OK* (06).
8. Scale targets: *safe parallelism, lower maintenance overhead, cost per cycle* (01 §1).

**Alignment summary confirmed by Erik on 2026-08-02** (goals, constraints, feature
coverage, work plan) before design work began.

**Boundary ratification (Erik, same day, after a four-seat adversarial panel):** the
engine lives harness-side as one repo-versioned entrypoint (`engine.py` +
`.graph/state.db`) — no new binary, no workflow vocabulary in the public Docket CLI;
Docket core receives only generic primitives (06 §5); the engine implements the FULL
functional scope (not a minimal slice); write-executors are serialized in v1
(read fan-outs stay parallel). Soundness amendments adopted with it: claims as
capability tokens, engine-computed budget floor, brief-at-claim, snapshot-pinned
briefs, gate/AC trust model. Details: 01 §6.

**Ratification #3 (Erik, same day — clarified motivation):** the criterion is *reusable
value*, not Docket's smallness: features belong in Docket exactly when anyone — human
team or agent fleet — would use them. The workflow engine therefore moves INTO Docket
core, redesigned domain-neutrally (zero agent/LLM vocabulary; opaque executor hints and
metadata; ordered enums via user schemas; trusted actions), superseding the harness-only
split; `engine.py`/`.graph/` dissolve into core. Delivery is Docket-first and staged
(06 §10); v1 follows stage 6. Outside core: prompt formatting, node contracts,
fragments, Erik's workflow/policy instances, reconcile arithmetic. Details: 01 §6.

**Mid-design addendum (Erik, same day):** harness facts discovered manually — the
Workflow tool (deterministic JS orchestration: saved versioned scripts, agent() fan-out
at ~16 concurrency, resumable, background with completion notifications), LSP tools,
worktree primitives, and sandbox carve-outs (Bash denied writing
`.claude/{agents,skills,hooks}` while Edit/Write pass; network allowlist). Incorporated:
the conductor's wave mechanics run as a saved workflow (03 §3; 01 §4 A2), executor
archetypes gain LSP (03 §4), worktree isolation is 08 Q9 (now resolved as 08 D9), and the sandbox note is in
07 M3.

**APPROVED — 2026-08-02 (Erik Reinert).** Final acceptance followed a seven-seat
quorum (coherence, engine semantics, security, OSS/genericity, zero-touch + harness
feasibility, parity/migration, evidence integrity): **7/7 ACCEPT-WITH-RESERVATIONS,
zero blocking findings**; all 29 reservations dispositioned by fix before approval.
Prior-effort artifacts quarantined to `_to_delete-graph-redesign/`. Implementation
begins at M1 stage 1 (07 §2; 06 §10); amendments follow 08 §3.

**Ratification #4 (Erik's structured review, same day):** zero-touch instance (T9 —
the developer provides work and approvals in conversation; all instance config is
machine-authored by bootstrap and evolved by retro); harness glue absorbed into core
(`step render`, builtin `aggregate`, the `guard` family — a drop-in adopter on any
harness needs only prose, one adapter, and one-line hook shims); fully conversational
operation including trust approvals (residual risk accepted, 08 D14); worktrees
optional with the single-writer baseline; 02 judged SOUND WITH FIXES by a two-expert
panel, all fixes folded. All former open questions resolved into decisions —
**D1–D16 ratified by Erik same day, including D14's conversational-trust risk
acceptance** (08).

## What this replaces (one paragraph)

The current fleet encodes a workflow engine in prose: dispatch, promotion, liveness,
votes, budgets, freezes, and shutdown live in ~800KB of agent/skill files, policed by a
hand-built prompt-CI (doctrine parity, byte ceilings, model census) and animated by
scripts with documented races (batons, singleton locks, dead-man watches). It works, and
it does not scale on exactly three axes: parallelism safety, maintenance locality, and
cost. This design moves every deterministic behavior into Docket's generic workflow engine
(plus thin, hash-pinned harness glue), reduces the model's role to judgment at typed
nodes, and makes the harness enforce — rather than request — the boundary.
