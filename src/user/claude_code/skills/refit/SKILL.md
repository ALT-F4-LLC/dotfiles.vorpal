---
name: refit
description: Redesign one Docket workflow definition in src/user/docket/config/workflows through an interactive, capability-checked refactor — iterate the target pipeline spec with the operator, verify every claimed engine capability against the live docket engine source, surface each engine-forced deviation as an explicit decision, render the settled design as a visual Artifact for approval before implementing, then land the full surface set (workflow TOML, contracts, fragments, policy rows, vote-seat lenses, schemas), lint it, file engine issues for real gaps, and commit. Use on "refit the ui-change workflow", "/refit standard-change", "refactor a docket workflow", "add a phase to release", "redesign the investigation pipeline", or any request to change what a workflow under src/user/docket/config/workflows does.
---

# refit

You redesign exactly one workflow definition in this repository's shared
docket corpus, as the engineer who checks the engine before promising it
anything: the operator describes the pipeline they want, you verify what the
engine can actually express, every gap between the two becomes a decision the
operator makes — never a silent downgrade — and only then do you implement,
lint, and commit. Source only: nothing under `~/.claude` or `~/.docket` is
edited, and the operator's `just activate` is the only installer.

**You change definitions; you never run them.** No `docket run`, no issue
grooming, no executing the pipeline you just built (`conduct` does that). A
live run is out of scope unless the operator asks for one afterward.

## 1. Intake

Resolve the target: one file under `src/user/docket/config/workflows/`. Read
it whole, plus `policy.toml` and at least one sibling workflow with similar
machinery (fanout, loops, votes) as expression precedent.

Then get the target spec from the operator. A vague ask ("simplify it",
"make it stricter") is iterated until it names concrete behavior: which
steps, which gates, what happens on rejection, who escalates to whom. Batch
what is genuinely underdetermined into ONE `AskUserQuestion` round —
recommended option first — and let everything with a conventional answer
default. When the operator hands you a numbered pipeline spec, treat it as
the contract and ask only about what it leaves open.

## 2. Verify against the engine

**The docket engine source is the only capability authority.** Not memory,
not this file, not what a sibling workflow appears to imply — engines move,
and a design promised on a stale assumption fails at activation or, worse,
at ordinal 3 of a live run. The engine checkout lives beside this repo
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

For each capability the spec leans on, answer from that source before
designing around it: how fan-out expands and when its width is fixed; how
many independent fix-loops a workflow may carry and where re-entry lands;
what `threshold` routing does and does not re-run; which `inputs` forms
exist and how loop ordinals rebind them; what a vote step needs (registered
rule, routable voters) and what its rejection can route to; what exhausting
a budget does. Read until the mechanism is settled — one honest pass, not a
re-derivation loop — and carry the answer as a cited fact (`file:line`).

## 3. Gate the deviations

Where the verified engine and the operator's spec collide, the resolution is
the operator's. Present each collision as an `AskUserQuestion`: what the
engine actually does, the faithful-but-costly option, the cheap
approximation, the wait-for-the-engine option — recommendation first, with
the tradeoff stated in one line each. Never implement a downgrade the
operator has not picked.

Every genuine engine gap accepted as a deviation is **filed as an issue in
the engine's own docket project in the same session** (`docket issue create`
from the engine checkout): what the workflow needed, what the engine
provides, a concrete proposal. Engine defects and gaps are filed, never
patched in place.

## 4. Visualize before implementing

Once the deviations are settled, render the agreed design as an Artifact and
hold for approval on the picture before touching any file. Load the
`artifact-design` and `artifact-diagramming` skills first, then draw the
workflow as it will actually expand: every step with its executor, variant,
and cost; vote gates with their rule and voters; threshold conditions on the
edges they fire; the fix-loop's re-entry point and budget; every
`waiting-human` park; any cross-cutting store the nodes share; and the
`when` predicate that gates a conditional lane. Conditional and superseded
paths draw differently from the happy path — the picture's job is to let the
operator catch a wrong edge cheaper than a wrong implementation.

Present the artifact link and ask for approval via `AskUserQuestion`
(approve / revise). A revision request loops back through §3's gates if it
reopens a deviation, or straight to a redraw if it is design-only; nothing
in §5 onward happens until the picture is approved. Keep the artifact
updated at the same URL as the design moves — after landing, it doubles as
the workflow's schematic.

## 5. Implement every surface

A workflow change is rarely one file. Work the full checklist; skipping a
surface is how activation refuses or a wave refuses to route:

- **Workflow TOML** — the redesigned steps, plus a `version` bump: a
  registered `name@version` is frozen, and activation rejects changed bytes
  at an unchanged version.
- **Contracts** (`config/contracts/<executor>.md`) — one per NEW executor,
  in the house shape: frontmatter (`node`, `version`, `archetype`,
  `packet_includes`, `emits`) then Charter / Not / Method / Emit / Stuck.
  Shared contracts serve other workflows — extend them via a step-level
  packet fragment rather than editing a contract another pipeline depends
  on.
- **Fragments** (`config/fragments/`) — rules shared across the new nodes
  (a protocol, a store convention) live once in a fragment appended to each
  step's `packet`, not copy-pasted into contracts.
- **policy.toml** — an `[executors]` row for every new executor AND every
  new vote seat (the wave refuses to route or seat anything without a row),
  plus the policy version bump. Match variant tiers to comparable existing
  seats; respect the `[security]` node rules.
- **Vote-seat lenses** — a seat's lens is the last hyphen-token of its name,
  resolved against the `LENSES` table in
  `src/user/claude_code/workflows/wave.js`; a new lens key needs an entry
  there or the seat judges generically. `node --check` after editing.
- **Vote rules** — reuse a registered rule when its threshold matches (rules
  are thresholds; voters are orthogonal). A genuinely new rule is a store
  registration (`docket config set --global vote.rule.<name>.threshold`) the
  operator runs — name it in the report rather than mutating the store
  yourself.
- **Schemas** (`config/schemas/`) — a new `payload` kind needs a schema file
  and threshold predicates that match its fields.

## 6. Validate

```bash
docket workflow lint src/user/docket/config/workflows/<name>.toml
```

Lint resolves schemas and vote rules from the current project's store, which
can lag the corpus: before blaming your edit, lint the installed known-good
version of the same workflow — an identical failure is environmental.
A missing corpus schema registers from its source file
(`docket schema register <kind@n> config/schemas/<kind@n>.json`), then
re-lint. The acceptance floor is a clean lint at the bumped version;
anything the lint cannot see (live loop behavior, seat quality) is reported
as unverified, not claimed.

## 7. Land

Commit via the `commit` skill. Other sessions share this tree — stage only
the files this refit touched, nothing else. Then report in plain language:
what changed and why, each deviation the operator accepted and the engine
issue filed for it, what was verified (lint, syntax checks) and what was
not (no live run). Never push; never install — the change reaches
`~/.docket` and `~/.claude` only through the operator's `just activate`.
