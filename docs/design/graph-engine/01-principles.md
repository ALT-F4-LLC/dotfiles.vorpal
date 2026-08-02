# 01 — Principles and derivation

Status: approved — 2026-08-02 (nothing here is implemented yet)
Date: 2026-08-02

This document derives the architecture from the two acceptance criteria and the three scale
targets, states the evidence that binds the design, and records the alternatives that were
considered and rejected. Everything downstream (02–07) is an application of this page.

## 1. The acceptance criteria, taken literally

**AC-1: Non-deterministic work is done by LLMs.**
**AC-2: Deterministic work is done by Docket.**

The current fleet violates both in the same way: deterministic work is done by *models
reading prose*. Dispatch rules, promotion gates, liveness probes, vote thresholds, fix-loop
budgets, freeze protocols, and shutdown state machines are all English that a model must
re-interpret every turn. The observable consequences are the three pains this redesign
targets: coordination prose does not parallelize safely (batons, singleton locks, dead-man
watches — all with documented races), it does not maintain cheaply (~800KB of prompts
policed by a hand-built CI: doctrine_check, byte ceilings, symmetry checks, model census),
and it does not run cheaply (tokens spent being a while-loop, re-reading protocol, and
repairing drift).

Taken literally, the ACs produce a single division-of-labor rule:

> **A model is invoked exactly when a judgment is required. Everything that is not a
> judgment — what runs next, who may run it, whether output is recorded, whether a gate
> passed, what a set of severities reconciles to, whether a budget is exhausted, what
> happens on failure — is computed by Docket.**

The corollary that shapes every interface in this design:

> **A schema exists exactly where code consumes the data. Where a model consumes the data,
> the format is prose.** Deterministic work needs machine-readable inputs; judgment does
> not. (Derived here from AC-2; independently, the one experiment that typed model→model
> edges manufactured ~40 edge transforms of pure overhead and was abandoned — see §3, E-2.)

## 2. Design tenets

**T1 — The graph is data in Docket.** Work items, dependencies, process steps, gates,
budgets, and routing live in Docket entities and versioned definition files — never in an
agent prompt, never in a generated script. A prompt describing a workflow is a bug.

**T2 — The model never does deterministic work; the engine never does judgment.** Docket
computes ready sets, enforces claims, runs gates, reconciles severities, meters budgets.
Models plan, author, implement, review, and investigate. If a rule can be written as code
that always gives the same answer, it is not allowed to live in a prompt.

**T3 — Context is assembled, not discovered.** Every LLM node receives a *brief* that
Docket assembles deterministically: task framing + node contract + referenced knowledge
fragments + input artifacts. No node "goes looking" for its inputs; no pointer is followed
at the node's discretion. This makes dispatch closure (the real bytes a node receives) a
measured quantity instead of a hope. (Evidence E-5, E-6: pointer-based progressive
disclosure went unread in practice — 74 pointers, 0 observed reads — and "small contract"
claims hid 27–107KB real closures.)

**T4 — Every node output is an artifact.** Nodes return markdown; the runtime records it
in Docket before anything else happens. Artifacts are immutable once recorded; downstream
nodes read them by reference. There is no peer-to-peer chatter, no mailbox protocol, no
"mirror it to Docket" discipline — recording *is* the return path.

**T5 — Findings are judged; verdicts are computed.** Reviewer nodes emit findings (with a
typed severity, because arithmetic runs over it). They do not emit APPROVE/BLOCK. The
pass/fail decision is a deterministic policy over the reconciled finding set. This removes
the hedging problem at its root (E-4: removing the verdict field eliminated hedging on
first contact, 6/6 judges) and removes the reviewer-override / verdict-reconciliation
protocol entirely. One deliberate exception: explicit **vote gates** (05 §4) do collect
per-voter verdicts, kept exactly where per-voter accountability is the point (waivers,
doc acceptance, destructive actions) — votes carry findings and the tally is arithmetic.

**T6 — All coordination state is machine-owned.** Claims are atomic compare-and-swap with
leases. Liveness is lease expiry, not a probe-once doctrine. Mutual exclusion is scheduler
refusal to co-release overlapping file scopes, not an edit baton. Resume is re-reading run
state, not a crash-recovery narrative. Every one of today's concurrency rituals must map
to an engine mechanism or be deleted.

**T7 — Local change.** Adding or editing a node, gate, pipeline, or routing row touches
one file. Nothing requires a fleet-wide coherence pass, a parity manifest, or a byte
ceiling. The maintenance toolchain that polices duplication is deleted *with* the
duplication (its existence was a symptom, not a control).

**T8 — Telemetry is native, adjustment is evidence-based.** Every step records model
requested vs resolved, effort, tokens, cost, duration, attempts, and gate results as a
side effect of running. "Which model should judge security?" becomes a query over the run
ledger, not a debate. Self-improvement is an ordinary pipeline reading this ledger — not a
bespoke suite mining transcripts.

**T9 — Zero-touch instance.** The developer provides exactly two things, both in
conversation: work (requests) and judgment (approvals at gates). Everything else —
workflows, schemas, policy, contracts, fragments, trust proposals — is
machine-authored (bootstrap), machine-evolved (retro), and merely human-approved. The
model and harness are the middleware between the human and the system: no developer
runs engine commands, edits TOML, or maintains config by hand. A design element that
requires manual upkeep violates this tenet.

## 3. Evidence that binds this design

Per Phase 0: prior *designs* carry zero authority; prior *measurements* are respected as
dead-end markers. The binding list, with provenance:

- **E-1 — Retrospective corpora cannot ground quality claims.** Issue trackers preserve
  dispositions, not observables; frozen diffs contain the fix, not the defect (4/4 loci
  checked). Consequence: the v1 test in 07 is a concurrent shadow run judged by the
  operator, and no design claim here cites a retrospective benchmark.
- **E-2 — Typing both ends of model→model edges is a work generator.** 54 schemas / 7
  graphs / ~40 bespoke edge transforms existed only because both ends were typed; removing
  the types removed the engineering. Consequence: §1's schema rule; the only typed node
  *content* in this design is the small sanctioned payload set code computes over
  (finding severity, per-AC status).
- **E-3 — Severity aggregation must not be bare max.** Judges put high/high/medium/
  medium/low on one defect; ±2 spread on 4/10 duplicate clusters. Median with a held
  state (spread ≥2) and a recorded demotion trail was deterministic across runs (zero
  arithmetic variance). Consequence: reconciliation semantics in 02 §6.
- **E-4 — Verdict fields cause hedging; their absence cures it.** The fleet needed a
  banned-phrase lint because "don't hedge" failed as an instruction; removing the verdict
  field produced 6/6 clean judge outputs. Consequence: T5.
- **E-5 — Optimize the dominant cost term.** Node contracts measured at ~1% of invocation
  cost; context assembly and fan-out width dominate. Consequence: briefs are assembled and
  measured (T3), fan-out width is a pipeline parameter with a budget, and contract byte
  counts are not a design objective.
- **E-6 — Unenforced pointers go unread.** 74 doctrine pointers, 0 observed reads; one
  relocation silently disabled a behavior. Consequence: T3 (inline assembly, not pointers)
  — the engine inlines fragments into the brief; nothing depends on a node choosing to
  follow a reference.
- **E-7 — Review fan-out with narrow judges is the one empirically strong pattern.**
  0.94 precision (n=73) at 23× the finding volume of a single reviewer, with perfect
  format compliance; the judged half of aggregation (clustering duplicates) showed ~17%
  run-to-run grain variance while the arithmetic half showed zero. Treated as: strong
  support for parallel narrow judges + deterministic reconciliation as the review
  mechanism; *not* treated as a validated component to import (fully-fresh constraint) —
  04 re-derives the judge set.
- **E-8 — Decision rules must not be able to fire on instrument artifacts.** A
  coverage-abort rule nearly killed the best-measured component over a corpus defect.
  Consequence: engine policies in 02 trigger on facts the engine itself produced (gate
  exits, lease expiries, budget counters) or on the one sanctioned judgment→routing
  interface — typed, reconciled payloads (finding severities, per-AC statuses) that
  models emit *for* the engine under 02 §6. What policies never key on is free-form
  model claims: coverage assertions, self-assessments, confidence prose.
- **E-9 — Prose control planes drift and then need their own CI.** One fleet edit cycle
  required two coherence repair passes; 13/17 skills exceeded the fleet's own size
  ceiling by recorded exemption; ~30–35% of agent bytes were duplicated protocol.
  Consequence: T1/T7, and 07 deletes the entire prompt-CI toolchain.
- **E-10 — Harness quirks fossilize into doctrine when prose is the enforcement layer.**
  Today's files carry paragraphs about hook schema traps, silent task resets, and effort
  arguments that don't bind. Consequence: 03 enforces invariants with hooks (exit-2
  deterministic gating), and anything the harness cannot guarantee is owned by Docket
  instead.

## 4. Alternatives considered and rejected

**A1 — External graph/durable-execution engine (LangGraph-class, Temporal-class) driving
the Claude Agent SDK.** Rejected on constraint: all spawning must happen inside the Claude
Code harness from prose definitions (Phase 0, dispatcher answer), and on AC-2: the
deterministic engine of this system is Docket, not a second stateful runtime. The 2026
consensus these engines embody — deterministic control plane, LLM as fallible typed
function, checkpoint/replay, gates as edges — is adopted; the machinery is Docket's.

**A2 — Per-run Claude Code workflow scripts as the plan.** Generating a JS workflow
script per run would relocate the graph out of Docket (violates T1/AC-2), cannot take
mid-run human input, and creates a per-run artifact class to maintain. Rejected **as the
plan carrier** — but the Workflow tool itself is adopted in a narrower role: one *static,
versioned, saved* wave-executor script that spawns whatever `docket next` returned
(03 §3). Control flow in that script is deterministic code executing Docket's decisions,
which is exactly the AC-2 division; the graph never leaves Docket. (Harness fact
confirmed by Erik mid-design: the Workflow tool is available in his Claude Code harness,
runs JS with agent() fan-out at ~16 concurrency, is resumable, and saved workflows are
first-class.)

**A3 — Agent Teams as the runtime.** The current fleet runs on teams, and a measurable
share of its prose exists to manage teams mechanics: shutdown handshakes, teammate
liveness doctrine, idle-hook interpretation, mailbox hygiene, task-list mirroring.
Teammates are peers with lifecycles; this design needs stateless executors with a
report-and-end lifecycle. Background subagents provide exactly that, so the runtime (03)
uses subagents and deletes the lifecycle prose. Teams are not used anywhere.

**A4 — Per-run LLM-composed process graphs.** Letting the planner invent the *process*
(review panels, gates, fix loops) per run reintroduces non-determinism into exactly the
work AC-2 assigns to the engine, and makes process quality a per-run variable. Split
instead: the planner composes the *work* DAG (what to build — a judgment); versioned
pipeline definitions determine the *process* per work item (how it flows — deterministic
expansion). See 02 §4.

**A5 — Keeping the 8 role personas as executors.** Rejected by Phase 0 answer (task-typed
capability nodes). Roles survive only as knowledge: their domain content is distilled into
node contracts and shared knowledge fragments (04); their protocol content is either an
engine mechanism now or deleted.

**A6 — A model as dispatcher (the "3KB team-lead").** A dispatcher that "makes no
decisions" is by definition doing deterministic work, which AC-2 assigns to Docket. The
residual Claude-side relay (03) exists only because spawning must originate in-harness —
and even its wave mechanics (fan-out, concurrency, retry-on-death) run as deterministic
code in the saved wave workflow (A2), not as model behavior. Every choice is precomputed
by `docket next`; hooks and atomic claims make disobedience mechanically impossible.

## 5. Shape of the system (summary)

Four kinds of things:

1. **The deterministic engine** — Docket core, now including a *generic, domain-neutral
   workflow engine* (workflows, steps, runs, claims/leases, gates under a user trust
   model, typed payloads with ordered enums, events, usage ledger), plus hash-pinned
   instance config in the repo; computes everything deterministic. Spec: 02
   (semantics), 06 (core surface + what stays outside). Boundary ratified in §6.
2. **The planner (a judgment)** — an LLM conversation that turns a request into a work
   DAG proposal recorded in Docket; approved by the operator; then it is done. Re-planning
   is a fresh planner invocation reading run state. 03 §2.
3. **The relay (conductor role)** — the operator's session running a ~2KB `run` skill
   plus one saved, versioned wave-executor workflow: `docket next` → invoke the wave →
   executors self-claim, work, self-record → repeat. No state, no decisions; hooks and
   atomic claims enforce that mechanically. 03 §3.
4. **Nodes (judgments)** — task-typed executors spawned per step with an assembled brief:
   3–5KB prose contract + knowledge fragments + input artifacts. They emit markdown
   artifacts (plus a typed findings payload only where code computes over it). 04.

One sentence: **Docket decides, Claude judges, hooks enforce, artifacts flow.**

## 6. Boundary ratification (2026-08-02, adversarial panel)

Erik's concern — that the LLM and harness can carry work 06 originally assigned to
Docket, and that where the line falls decides whether the OSS project's changes stay
generic — was put to a four-seat opposed-brief panel (OSS maintainer, harness
maximalist, determinism purist, implementation economics). Ratified outcome:

- **Docket core stays generic.** Only agent-agnostic primitives are upstreamed
  (06 §5); every workflow-specific feature is withdrawn from the public CLI. The core
  delta makes Docket *more* useful to strangers, not less.
- **The engine is harness-side but singular.** The full workflow semantics live in one
  repo-versioned deterministic entrypoint (`engine.py` + `.graph/state.db`), invoked
  only by hooks, the wave workflow, and the two skills — never at model discretion.
  One entrypoint (not loose scripts) preserves the purist's non-negotiables:
  atomicity, capability-token authorization, refuse-by-default, hash-pinned versions.
- **AC-2, operational form (restated):** deterministic work lives in *versioned
  deterministic code that models cannot bypass* — Docket core for shared tracker
  state, the engine layer for workflow semantics, hooks/wave for in-harness
  enforcement. "Docket" in the acceptance criterion names this deterministic side as a
  whole, per Erik's ratification; what it forbids is unchanged: no deterministic
  behavior in prompts, no model-discretionary invocation in the control path.
- **Accepted risk, recorded.** A script layer is the current fleet's genre, and the
  purist's warning stands: loose, model-invoked scripts would be E-9's failure
  rebuilt. The mitigations are structural, not hortatory — one entrypoint,
  transactions, tokens minted at claim, mutating verbs that refuse non-holders,
  `next` refusing over discrepancies, mechanical invocation points only.
- **Soundness amendments adopted with it** (claims as capabilities, engine-computed
  budget floor, brief-at-claim, snapshot-pinned briefs, gate trust model, serialized
  v1 writers): folded into 02 §5–§8, 06 §2–§4, 03 §3/§5.

**Superseded same day — ratification #3 (clarified motivation).** Erik clarified that
his criterion was never Docket's smallness but *reusable value*: features belong in
Docket exactly when anyone — human team or agent fleet, any domain — would use them.
Under that test the harness-only split above is superseded: the workflow engine moves
**into Docket core, redesigned domain-neutrally** (06's genericity rule: zero agent/LLM
vocabulary; opaque executor hints and metadata; ordered meaning via user-registered
schemas; computations as user-trusted actions). `engine.py`/`.graph/` dissolve into
core; every soundness and security amendment above carries over unchanged into the Go
implementation. What remains outside core is exactly what fails the stranger test:
prompt formatting, node contracts, fragments, Erik's workflow/policy instances, and
the reconcile arithmetic (a registered trusted action). Delivery is Docket-first and
staged (06 §10); the v1 shadow run follows stage 6. The purist's structural
mitigations improve under this pass — the invariants now live in a compiled
single-writer engine rather than Python-over-SQLite.

**Ratification #4 (2026-08-02, Erik's structured review).** Five review outcomes,
binding: (1) **Zero-touch** (T9): developers provide work and approvals in
conversation; all instance config is machine-authored and machine-evolved. (2) **No
one-off harness scripts**: former glue becomes generic core verbs — `step render`,
the builtin `aggregate` action, the `guard` family — so a drop-in adopter on any
harness needs only prose plus one adapter and one-line hook shims. (3)
**Conversational operation**: the human never types an engine command; the session is
the middleware, the CLI the audit surface — including trust approvals (in-chat yes →
`trust add --yes`, backed by the harness permission layer; residual risk accepted,
08 D14). (4) **Worktrees optional, never required**: single-writer serialization is
the always-available atomicity baseline. (5) **02's semantics judged by a two-expert
panel** (workflow-engine; concurrency/crash-safety): verdict SOUND WITH FIXES, all
fixes folded into 02/06 (dispatch recovery, loop lineage with `superseded`, saga
at-least-once gates, zombie-writer fencing, transaction discipline, retention-scoped
replay).
