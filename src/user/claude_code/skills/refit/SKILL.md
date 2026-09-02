---
name: refit
description: Redesign one definition in the shared docket corpus under src/user/docket/config — a workflow, policy.toml, an executor contract, a packet fragment, or a payload schema — through an interactive, capability-checked refactor: sweep the target's blast radius across every consumer, mine run evidence across every project that exercised it to ground optimization proposals, iterate the target spec with the operator, verify every claimed capability against the live docket engine (and wave.js) source, surface each engine-forced deviation as an explicit decision, render the settled design as a visual Artifact for approval before implementing, then land the full co-change closure (workflow TOML, contracts, fragments, policy rows, vote-seat lenses, schemas), lint every consumer, file engine issues for real gaps, and commit. Invoked bare (`/refit` with nothing named) it instead runs corpus mode — mine run evidence across every surface in the corpus (workflows AND policy, contracts, fragments, schemas) triage-then-deep-dive, verdict each one, and carry every refit, removal, and addition the evidence calls for through the same §1–§8 process to a landed commit, target by target, with the same per-target deviation gates and artifact approval as single mode. Use on "refit the ui-change workflow", "/refit standard-change", "/refit policy.toml", "tighten the implement contract", "refit the findings schema", "refactor a docket workflow", "optimize the release pipeline", "add a phase to release", "redesign the investigation pipeline", bare "/refit" to redesign the whole corpus, or any request to change or improve what any definition under src/user/docket/config does.
model: fable
---

# refit

You redesign exactly one definition in this repository's shared docket
corpus, as the engineer who checks the engine before promising it anything:
the operator describes what they want, you verify what the engine can
actually express, every gap between the two becomes a decision the operator
makes — never a silent downgrade — and only then do you implement, lint, and
commit. Source only: nothing under `~/.claude` or `~/.docket` is edited, and
the operator's `just activate` is the only installer.

The corpus has five refittable surfaces, all under
`src/user/docket/config/`, and any one of them can be the named target:

- **Workflows** (`workflows/<name>.toml`) — pipeline definitions.
- **Policy** (`policy.toml`) — variant tiers, executor/seat routing rows,
  security ceilings, escalation rules.
- **Contracts** (`contracts/<executor>.md`) — one executor's charter,
  method, and emit obligations.
- **Fragments** (`fragments/<name>.md`) — rules shared across contracts via
  `packet_includes`.
- **Schemas** (`schemas/<kind@n>.json`) — payload shapes that emits and
  threshold predicates agree on.

**You change definitions; you never run them.** No `docket run`, no issue
grooming, no executing the pipeline you just changed (`conduct` does that).
A live run is out of scope unless the operator asks for one afterward.

Two modes, dispatched on the invocation: a named target enters single mode,
running §1–§8 on that one definition; no parameter at all enters corpus mode
(next section), which runs the same §1–§8 across the whole corpus, one
target at a time.

## Design canon

The corpus is a production configuration system serving every project on
this machine, and it is redesigned the way large-scale SDLC treats shared
infrastructure. These practices are working vocabulary for every proposal
you make, on any surface — not limited to the five above:

- **Change control via frozen versions.** A registered `name@version` is an
  immutable release: changed bytes demand a version bump, exactly as a
  published API version never changes under its consumers. In-flight runs
  finish on the version they started with; the bump is the rollout.
- **Blast-radius review before shared-surface edits.** Contracts, fragments,
  policy rows, and schemas are shared libraries: before proposing an edit,
  enumerate every consumer (the reverse-dependency sweep in §1) and design
  for all of them — the monorepo rule that whoever changes an interface owns
  every caller.
- **Consumer-driven contract testing.** A schema is a contract between the
  executor that emits it and the threshold predicates and downstream steps
  that read it. A change to either side is checked against the other before
  it lands, never discovered at ordinal 3 of a live run.
- **Policy as code.** `policy.toml` is reviewed like an IAM or CODEOWNERS
  change: least-capable tier that meets the bar, every exception explicit
  with a recorded `reason`, security `never` rules treated as invariants a
  refit must prove it preserves.
- **Deprecate, don't break.** When consumers cannot all move at once, the
  old version stays registered while the new one lands, and removal is a
  separate, later change with its own evidence that nothing references it.
- **One source of truth.** A rule needed by two contracts lives in a
  fragment, not in two places; drift between duplicates is a defect the
  refit removes, not preserves.
- **Budgets as SLOs.** `expected_cost`, fix-loop budgets, and vote margins
  are service-level objectives: mined actuals versus declared budgets are
  the primary optimization signal, and a budget nothing has ever approached
  — or one chronically exhausted — is a finding either way.

## Corpus mode (invoked bare)

Invoked with nothing named, redesign the whole corpus instead of one
definition: mine and verdict every surface, then carry every verdict that
calls for a change through the full §1–§8 process to a landed commit,
target by target, in the same session. Unconditional — every definition
gets mined and verdicted and every non-`keep` verdict proceeds straight into
its own §1–§8 run; there is no upfront action list to approve before work
starts. The operator checkpoints are the same ones single mode already has —
§4's deviation gate and §5's artifact approval — hit per target, as each is
reached, not batched.

**Triage, then deep-dive.** Read every definition under
`src/user/docket/config/` whole — every workflow, `policy.toml`, every
contract, fragment, and schema. Mine in two passes: first an aggregate pass
across every project (`docket project list`, then run counts, outcomes, and
costs per workflow via `docket stats` and `docket run`); then §2's full
per-target mining ONLY on what the aggregate flags as suspect — never-run
workflows, chronic parks or budget exhaustions, gates that never reject,
cost far off `expected_cost`, executors whose emits chronically fail their
schema or draw judge rejections, policy rows routing nothing, fragments and
schemas with zero consumers. §2's evidence rules apply throughout: counts
over vivid samples, thin evidence said plainly. A definition cleared on
aggregate numbers alone is reported as such, not as deep-mined. This pass
satisfies §2 for every target it deep-dives — don't re-mine a target on
entry to its own §1–§8 run; carry the evidence forward as the finding.

**Verdicts drive the target, not a suggestion.** Every definition gets one:

- **keep** — evidence shows it earning its shape. Record the finding and
  move to the next target; nothing else runs for this one.
- **refit** — name what needs changing and why, citing numbers. That
  evidence-backed shape IS the target spec for this run — §1's "iterate a
  vague ask with the operator" is what single mode does when the operator
  supplies the ask; here the mining already produced one. Run §1's
  blast-radius sweep, then §2 (already satisfied above) through §8 on this
  target, landing its own commit before moving to the next.
- **remove** — no runs, superseded, or overlapping a sibling that already
  covers it. Confirm via §1's blast-radius sweep that nothing still depends
  on it, gate the removal through §4 like any other deviation, get §5
  approval on the blast-radius picture, then execute the removal — delete
  the file, retire the references that named it — through §7–§8, landing
  its own commit.
- **addition** — a named gap the evidence shows the corpus not covering.
  Design its shape on the surface the gap demands (workflow, contract,
  fragment, or schema), then run §4 for any deviation the design forces,
  §5 for approval, and §6–§8 to implement and land it as its own commit.

Report each target's verdict and evidence in plain language as it's reached,
not held back for an end-of-run summary — the operator sees the corpus-wide
shape of the sweep as it happens, and the §4/§5 gates are where they weigh
in on any one target.

## 1. Intake

Resolve the target: one definition on one of the five surfaces. Read it
whole, plus its immediate context — for a workflow, `policy.toml` and at
least one sibling workflow with similar machinery (fanout, loops, votes) as
expression precedent; for any shared surface, the house-shape precedent of
its siblings.

**Sweep the blast radius before proposing anything.** Every surface except
a workflow is shared, and a workflow shares its executors; enumerate the
consumers with greps over the corpus and carry the list through every later
section:

- **Contract** → every workflow step naming that executor, plus the policy
  row that routes it and the fragments its `packet_includes` pulls.
- **Fragment** → every contract (and step-level packet) that includes it.
- **Schema** → every contract that `emits` the kind and every workflow
  threshold predicate that reads its fields.
- **policy.toml** → every executor and vote seat the touched rows route;
  a `[security]` or `[variants]` change reaches every workflow at once.
- **Workflow** → its executors' contracts, their fragments, its payload
  schemas, and the policy rows and vote-seat lenses it depends on.

Then get the target spec from the operator. A vague ask ("simplify it",
"make it stricter") is iterated until it names concrete behavior: which
steps or rows, which gates, what happens on rejection, who escalates to
whom, which consumers must keep working unchanged. Batch what is genuinely
underdetermined into ONE `AskUserQuestion` round — recommended option first
— and let everything with a conventional answer default. When the operator
hands you a numbered spec, treat it as the contract and ask only about what
it leaves open.

## 2. Mine the evidence

The corpus is shared: every project on this machine runs these same
definitions, so the target's real behavior lives across every project's
ledger, not just this repo's. Enumerate them (`docket project list`) and,
for each with runs that exercised the target, read what actually happened —
runs, steps, events, votes, costs (`docket run`, `docket step`, `docket
events`, `docket stats`; exact verbs and flags via `--help` or the `docket`
skill).

What to count depends on the surface:

- **Workflow** — per step across all runs: spawns versus skips (a `when`
  lane or fanout row never taken is a routing claim nothing tests); gate
  outcomes (a gate that has never rejected, or never passed, is telling you
  something); fix-loop entries, convergence, and budget exhaustions; vote
  margins (unanimous everywhere versus real 2-of-3 decisions); recorded
  cost against `expected_cost`; parks, and what the operator did with each.
- **Contract** — the steps that ran it: emit quality (payloads rejected by
  schema or judges, gaps emitted, stuck escalations), rework drawn (fix-loop
  entries traceable to its output), cost at its routed tier.
- **Fragment** — behavior of every consuming executor: a rule chronically
  violated in outputs is a fragment failing to land; one never exercised is
  packet weight with no effect.
- **Schema** — validation failures at emit time, threshold predicates that
  misfired or never fired on its fields, version skew among consumers.
- **policy.toml** — per routed executor: escalations taken (`escalate_to`
  hops, `on_failure` retries), cost per variant tier against output quality
  signals, security reroutes actually exercised.

A pattern seen in a few vivid runs is a hypothesis, not a finding — go
count it, and the aggregate is the finding even when it contradicts the
samples. Each optimization you propose cites its numbers ("this fanout row:
4 planned, 0 executed across every run → drop it at the version bump");
thin evidence (few runs, young definition) is said plainly and the proposal
leans on design judgment instead — never dressed as data. Mined findings
feed §1's iteration as proposal input; when the operator invoked refit as
"optimize <target>" with no spec of their own, they ARE the proposal. When
the operator arrives with a full spec, mining still runs as a check — does
the evidence contradict anything the spec assumes? (`retro` sweeps the
whole corpus on its own cadence; this mining is scoped to the one
definition being redesigned.)

## 3. Verify against the engine

**Source is the only capability authority.** Not memory, not this file, not
what a sibling definition appears to imply — engines move, and a design
promised on a stale assumption fails at activation or, worse, at ordinal 3
of a live run. Two authorities cover the corpus:

The docket engine checkout lives beside this repo
(`.../github.com/ALT-F4-LLC/docket.git/main`); its load-bearing files:

- `internal/workflow/parse.go` — every legal `[[step]]` field and form
- `internal/workflow/validate.go` — the V-rules lint enforces (`after`,
  `inputs` shapes, loop declarations, fanout bounds)
- `internal/workflow/expand.go` — what expansion actually produces: fanout
  siblings, `when`-skipped rows, interposed threshold targets, loop-ordinal
  re-instantiation
- `internal/engine/loop.go`, `vote.go`, `human.go` — fix-loop entry,
  supersede sweep, budgets and parks, vote tally and rule resolution
- `docket <verb> --help` and `docket config` — registered vote rules,
  schemas, doc-store verbs

The wave runner, `src/user/claude_code/workflows/wave.js`, is the authority
for everything the engine never sees: how policy rows resolve to a variant
and seat, what packet assembly does with `packet_includes` and step-level
fragments, and the `LENSES` table vote-seat names resolve against.

For each capability the spec leans on, answer from source before designing
around it: how fan-out expands and when its width is fixed; how many
independent fix-loops a workflow may carry and where re-entry lands; what
`threshold` routing does and does not re-run; which `inputs` forms exist
and how loop ordinals rebind them; what a vote step needs (registered rule,
routable voters) and what its rejection can route to; what exhausting a
budget does; how a policy row's `variant`, `never`, and `escalate_to`
actually resolve; which schema fields threshold predicates can reach. Read
until the mechanism is settled — one honest pass, not a re-derivation loop
— and carry the answer as a cited fact (`file:line`).

## 4. Gate the deviations

Where the verified engine and the operator's spec collide, the resolution is
the operator's. Present each collision as an `AskUserQuestion`: what the
engine actually does, the faithful-but-costly option, the cheap
approximation, the wait-for-the-engine option — recommendation first, with
the tradeoff stated in one line each. Never implement a downgrade the
operator has not picked.

Every genuine engine gap accepted as a deviation is **filed as an issue in
the engine's own docket project in the same session** (`docket issue create`
from the engine checkout): what the definition needed, what the engine
provides, a concrete proposal. Engine defects and gaps are filed, never
patched in place.

## 5. Visualize before implementing

Once the deviations are settled, render the agreed design as an Artifact and
hold for approval on the picture before touching any file. Load the
`artifact-design` and `artifact-diagramming` skills first. What the picture
shows depends on the target:

- **Workflow** — the pipeline as it will actually expand: every step with
  its executor, variant, and cost; vote gates with their rule and voters;
  threshold conditions on the edges they fire; the fix-loop's re-entry
  point and budget; every `waiting-human` park; any cross-cutting store the
  nodes share; and the `when` predicate that gates a conditional lane.
  Conditional and superseded paths draw differently from the happy path.
- **Shared surface** (policy, contract, fragment, schema) — the blast
  radius as a dependency map: the changed definition at the center, every
  consumer around it, edges annotated with what changes for each (new
  version consumed, tier moved, field added, rule tightened) and consumers
  explicitly unaffected marked as such.

Either way the picture's job is to let the operator catch a wrong edge — or
an unconsidered consumer — cheaper than a wrong implementation.

Present the artifact link and ask for approval via `AskUserQuestion`
(approve / revise). A revision request loops back through §4's gates if it
reopens a deviation, or straight to a redraw if it is design-only; nothing
in §6 onward happens until the picture is approved. Keep the artifact
updated at the same URL as the design moves — after landing, it doubles as
the definition's schematic.

## 6. Implement the co-change closure

A corpus change is rarely one file, whichever surface it enters from. The
blast-radius list from §1 is the worklist: land the target and every
consumer edit it forces, in one change — skipping a surface is how
activation refuses or a wave refuses to route:

- **Workflow TOML** — redesigned steps, plus a `version` bump: a registered
  `name@version` is frozen, and activation rejects changed bytes at an
  unchanged version.
- **Contracts** (`config/contracts/<executor>.md`) — one per NEW executor,
  in the house shape: frontmatter (`node`, `version`, `archetype`,
  `packet_includes`, `emits`) then Charter / Not / Method / Emit / Stuck.
  Editing an EXISTING shared contract is a blast-radius change: bump its
  `version` and verify the edit against every consuming workflow, not just
  the one in hand — a rule needed by only one pipeline belongs in a
  step-level packet fragment instead.
- **Fragments** (`config/fragments/`) — rules shared across nodes (a
  protocol, a store convention) live once in a fragment appended to each
  consumer's packet, never copy-pasted into contracts. A fragment edit is
  reviewed against every including contract; bump its `version`.
- **policy.toml** — an `[executors]` row for every new executor AND every
  new vote seat (the wave refuses to route or seat anything without a row),
  plus the policy version bump. Match variant tiers to comparable existing
  seats — least-capable tier that meets the bar, exceptions carrying an
  explicit `reason` — and prove the `[security]` invariants (`never`
  models, ceiling, node list) still hold for every touched row.
- **Vote-seat lenses** — a seat's lens is the last hyphen-token of its name,
  resolved against the `LENSES` table in
  `src/user/claude_code/workflows/wave.js`; a new lens key needs an entry
  there or the seat judges generically. `node --check` after editing.
- **Vote rules** — reuse a registered rule when its threshold matches (rules
  are thresholds; voters are orthogonal). A genuinely new rule is a store
  registration (`docket config set --global vote.rule.<name>.threshold`) the
  operator runs — name it in the report rather than mutating the store
  yourself.
- **Schemas** (`config/schemas/`) — a new `payload` kind needs a schema
  file and threshold predicates that match its fields. Changing an existing
  kind is a new `kind@n+1` file, both sides of the contract moved together:
  every emitting contract and every reading predicate updated to the new
  version in the same change. The old version stays until no registered
  workflow references it; its removal is a later, separate change.

Before moving to §7, write one line per surface above — touched, or
not-applicable and why — even when the answer is obvious. A surface skipped
by oversight looks identical to one skipped on purpose until it is named;
the checklist is what tells them apart before a lint or an activation does.

**Whatever rationale you write into any of these files, write the finding
itself, not a pointer to it.** A date, a timestamp, a git sha, or an issue
id is not always available or kept — none of it means anything to whoever
reads this comment after the run it came from is gone, the commit is
rewritten, or the issue is closed. Say what was actually measured or
observed, in plain words, inline in the comment.

## 7. Validate

```bash
docket workflow lint src/user/docket/config/workflows/<name>.toml
```

Lint the target workflow — and when the change entered from a shared
surface, lint EVERY workflow the §1 sweep listed as a consumer: a green
target with a broken sibling is the failure the blast-radius review exists
to prevent. `node --check` wave.js if lenses changed.

Lint resolves schemas and vote rules from the current project's store, which
can lag the corpus: before blaming your edit, lint the installed known-good
version of the same workflow — an identical failure is environmental.
A missing corpus schema registers from its source file
(`docket schema register <kind@n> config/schemas/<kind@n>.json`), then
re-lint. The acceptance floor is a clean lint across every consumer at the
bumped versions; anything the lint cannot see (live loop behavior, seat
quality, whether a fragment's rule actually lands in outputs) is reported
as unverified, not claimed.

## 8. Land

Commit via the `commit` skill. Other sessions share this tree — stage only
the files this refit touched, nothing else. Then report in plain language:
what changed and why, the blast radius and how each consumer was handled,
each deviation the operator accepted and the engine issue filed for it,
what was verified (lint, syntax checks) and what was not (no live run).
Never push; never install — the change reaches `~/.docket` and `~/.claude`
only through the operator's `just activate`.
