---
name: docket-refit
description: >-
  Use on "refit the ui-change workflow", "/refit standard-change", "/refit
  policy.toml", "tighten the implement contract", "refit the findings schema",
  "add a phase to security-change", "redesign the investigation pipeline",
  bare "/refit" for the whole corpus, or any request to change what a
  definition under src/user/docket/config does. Redesigns one workflow,
  policy.toml, contract, fragment, or schema: gathers its evidence through a
  read-only Workflow script (consumer sweep, cross-project run mining,
  engine-source verification), iterates the spec with the operator, surfaces
  engine-forced deviations as decisions, renders the design as an Artifact
  for approval, lands the full co-change closure, lints consumers, files
  engine issues, and commits. Bare invocation runs corpus mode over every
  surface. Runs in the main session so its gates are real questions.
model: fable
---

# docket-refit

You redesign definitions in this repository's shared docket corpus — one
named target, or, invoked bare, every target the evidence calls for. The
operator describes what they want; you verify what the engine can actually
express; every gap between the two becomes a decision the operator makes,
never a silent downgrade; only then do you implement, lint, and commit.
Source only: nothing under `~/.claude` or `~/.docket` is edited, and the
operator's `just activate` is the only installer.


You run in the main conversation, never in a forked subagent: the deviation
decisions, the spec iteration, and the artifact approval gate below are real
questions through `AskUserQuestion` and `Artifact`, and a fork has neither.
The evidence the gates rest on is agent work: the blast-radius sweep, the
cross-project mining, the engine-source verification, and corpus mode's
triage each fan out through the read-only workflow script described next.
Treat whatever the conversation already discussed as background, not
evidence: read the target and launch the evidence stages yourself, and
start from `$ARGUMENTS` (the named target, or nothing for corpus mode). If
`AskUserQuestion` is unavailable, stop before §4 and report the decisions
still open instead of implementing. Your closing report names the commit
landed and every decision the operator made along the way.

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
grooming, no executing the pipeline you just changed (`docket-run` does
that). A live run is out of scope unless the operator asks for one
afterward.

Two modes: a named target enters single mode, running §1–§8 on that one
definition; no parameter enters corpus mode (below), running the same
§1–§8 across the whole corpus, one target at a time.

## The evidence workflow

Every read-only evidence phase runs through one script, launched by
`scriptPath`, always, at the installed path
`~/.claude/workflows/docket-refit.js`, expanding `~` to a literal absolute
path yourself first (`echo ~` or your session's known home). The Workflow
tool does not expand `~` and resolves a relative path against the target
repo's cwd, not the dotfiles source tree. The installed copy under `~/.claude/workflows` is also the only one the
tool may launch. A missing installed file means the corpus was never
activated after this script was added: report that, don't launch the
source copy instead.

The script runs one stage per launch, selected by `args.stage`, because the
capability questions §3 verifies exist only once the operator's spec is
settled, after §1's sweep:

```
Workflow({ scriptPath: "<absolute installed path to docket-refit.js>", args: {
  stage: "evidence" | "verify" | "triage",
  checkoutRoot: "<absolute path of this dotfiles checkout>",
  projects: [{ name, prefix, root }, ...],   // evidence and triage; from `docket project list --json`, root is the identity path
  target: { surface, path, name } | null,    // evidence only; surface is workflow|policy|contract|fragment|schema
  engineRoot: "<absolute engine checkout>" | null,
  capabilities: ["<question>", ...],         // verify only
} })
```

Scout the arguments inline before launching: resolve the target and read it
whole, list the projects with `docket project list --json`, and resolve the
engine checkout (§3) — the script cannot inspect files or run commands
itself. Every agent it spawns is an `executor-read` agent, whose tool set
carries no write verb: sweeps grep the corpus and the harness scripts,
mining analysts run `docket` read verbs from each project's checkout root,
verifiers read engine source. Nothing in it edits, mutates a store, or asks
the operator anything. Each return carries a `summary` line and an
`uncovered` list naming every agent that returned nothing, every project
whose checkout could not be entered, and every pair a fan-out bound
dropped; report those as uncovered, never as clean. If the workflow throws
or returns nothing, say so and stop rather than substituting a manual grep
or a from-memory answer.

## Design canon

The corpus is a production configuration system serving every project on
this machine. These practices are working vocabulary for every proposal,
on any surface, not only the five above:

- **Change control via frozen versions.** A registered `name@version` is
  immutable: changed bytes demand a version bump. In-flight runs finish on
  the version they started with; the bump is the rollout.
- **Blast-radius review before shared-surface edits.** Contracts, fragments,
  policy rows, and schemas are shared: before proposing an edit, enumerate
  every consumer (the reverse-dependency sweep in §1) and design for all of
  them.
- **Consumer-driven contract testing.** A schema is a contract between the
  executor that emits it and the threshold predicates and downstream steps
  that read it. Check a change to either side against the other before it
  lands, never discovered at ordinal 3 of a live run.
- **Policy as code.** Review `policy.toml` for least-capable tier that meets
  the bar, every exception explicit with a recorded `reason`, and security
  `never` rules as invariants a refit must prove it preserves.
- **Deprecate, don't break.** When consumers cannot all move at once, the
  old version stays registered while the new one lands. Removal is a
  separate, later change with its own evidence that nothing references it.
- **One source of truth.** A rule needed by two contracts lives in a
  fragment, not in two places; drift between duplicates is a defect the
  refit removes, not preserves.
- **Budgets as SLOs.** `expected_cost`, fix-loop budgets, and vote margins
  are service-level objectives. Mined actuals versus declared budgets are
  the primary optimization signal; a budget nothing has ever approached, or
  one chronically exhausted, is a finding either way.

## Corpus mode (invoked bare)

Invoked with nothing named, redesign the whole corpus instead of one
definition: triage and verdict every surface, then carry every verdict that
calls for a change through the full §1–§8 process to a landed commit,
target by target, in the same session. Every definition gets triaged and
verdicted, and every non-`keep` verdict proceeds straight into its own
§1–§8 run; there is no upfront action list to approve before work starts.
The operator checkpoints are the same ones single mode has — §4's deviation
gate and §5's artifact approval — hit per target, as each is reached, not
batched.

**Triage, then deep-dive, in one launch.** Read every definition under
`src/user/docket/config/` whole: every workflow, `policy.toml`, every
contract, fragment, and schema. Then launch the script with
`stage: "triage"`. It seats one aggregate analyst per project (run counts,
outcomes, parks, gate outcomes, budget exhaustions, and cost against
`expected_cost` per workflow, attributed onward to the contracts,
fragments, schemas, and policy rows those workflows consume) plus one
static consumer census over the corpus tree (fragments and schemas with
zero consumers, policy rows routing nothing, version skew), merges the
flags, and then runs §2's full mining and §1's sweep only on what the
aggregate or census flagged. The return separates `suspects` (each with its
`reasons`, `sweep`, and per-project `mining`) from `cleared` (each with the
aggregate that cleared it). A definition cleared on aggregate numbers alone
is reported as such, not as deep-mined. This launch satisfies §1's sweep and
§2's mining for every suspect — don't relaunch `evidence` for a target on
entry to its own §1–§8 run; carry the suspect's `sweep` and `mining` forward
as the finding.

**Verdicts drive the target, not a suggestion.** Every definition gets one:

- **keep** — evidence shows it earning its shape. Record the finding and
  move to the next target; nothing else runs for this one.
- **refit** — name what needs changing and why, citing numbers. That
  evidence-backed shape is the target spec for this run, since the mining
  already produced it. Weigh the shapes (§1), then run §3 through §8 on
  this target, landing its own commit before moving to the next.
- **remove** — no runs, superseded, or overlapping a sibling that already
  covers it. Confirm from the suspect's sweep that nothing still depends
  on it, gate the removal through §4 like any other deviation, get §5
  approval on the blast-radius picture, then execute the removal — delete
  the file, retire the references that named it — through §7–§8, landing
  its own commit.
- **addition** — a named gap the evidence shows the corpus not covering.
  Launch `evidence` for the nearest sibling on the surface the gap demands
  (even an empty consumer set is worth recording for a wholly new
  definition) and run §3's engine verification alongside designing its
  shape (workflow, policy row, contract, fragment, or schema), then run §4
  for any deviation the design forces, §5 for approval, and §6–§8 to
  implement and land it as its own commit.

Report each target's verdict and evidence in plain language as it's reached,
not held back for an end-of-run summary; the §4/§5 gates are where the
operator weighs in on any one target.

## 1. Intake

Resolve the target: one definition on one of the five surfaces. Read it
whole, plus its immediate context — for a workflow, `policy.toml` and at
least one sibling workflow with similar machinery (fanout, loops, votes) as
expression precedent; for any shared surface, the house-shape precedent of
its siblings.

**Sweep the blast radius before proposing anything.** Every surface except
a workflow is shared, and a workflow shares its executors. In single mode
launch the script with `stage: "evidence"` and the resolved target: its
sweep agent greps the corpus and the harness scripts and returns every
consumer with the `file:line` of the reference, plus the siblings that
serve as precedent, while its mining analysts (§2) run in the same launch.
Carry the consumer list through every later section. What the sweep
enumerates, per surface:

- **Contract** → every workflow step naming that executor, plus the policy
  row that routes it and the fragments its `packet_includes` pulls.
- **Fragment** → every contract (and step-level packet) that includes it.
- **Schema** → every contract that `emits` the kind and every workflow
  threshold predicate that reads its fields.
- **policy.toml** → every executor and vote seat the touched rows route;
  a `[security]` or `[variants]` change reaches every workflow at once.
- **Workflow** → its executors' contracts, their fragments, its payload
  schemas, and the policy rows and vote-seat lenses it depends on.

A consumer the sweep names without a citation is not in the blast radius
until you can cite it yourself; a sweep that returned nothing leaves the
blast radius unknown, which stops the refit rather than narrowing it.

Then get the target spec from the operator. A vague ask ("simplify it",
"make it stricter") is iterated until it names concrete behavior: which
steps or rows, which gates, what happens on rejection, who escalates to
whom, which consumers must keep working unchanged. Batch what is genuinely
underdetermined into one `AskUserQuestion` round, recommended option first,
and let every detail with a conventional answer default; the proposal's
shape is weighed below, never defaulted. When the operator hands you a
numbered spec, treat it as the contract and ask only about what it leaves
open.

**Weigh the shapes before proposing one.** The incumbent definition and the
engine's conventional expression are two candidates, not the field. Derive
what this target needs from the mined evidence and its consumers, weigh at
least one shape the corpus does not already use, and, when the operator's
spec itself encodes the worse design, frame the alternative as an option in
the same question round. Choose on correctness under the verified engine,
locality of reasoning for the next author, deletability, and what the
consumers must carry; deliver the winner as the smallest co-change closure.
The candidates weighed and why the pick won go into the §5 artifact.

## 2. Mine the evidence

The corpus is shared: every project on this machine runs these same
definitions, so the target's real behavior lives across every project's
ledger, not just this repo's. The `evidence` launch seats one analyst per
project from `docket project list --json`, each running read-only verbs
from that project's checkout root (`docket run status`, `docket run
report`, `docket step list`, `docket step artifacts`, `docket events
list`; exact flags via `--help` or the `docket` skill) and returning
metrics and findings that name the verbs and run ids they came from. The
`mining` array in the return is that evidence; a project with no runs
touching the target returns zero runs examined, which is a real result.

What the analysts count depends on the surface, and the script's briefs
carry the same table:

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

A pattern seen in a few vivid runs is a hypothesis, not a finding: the
analysts count it, and the aggregate across projects is the finding even
when it contradicts the samples. Each optimization you propose cites its
numbers ("this fanout row: 4 planned, 0 executed across every run → drop it
at the version bump"); a finding the analyst marked `thin` (few runs, young
definition) is said plainly and the proposal leans on design judgment
instead, never dressed as data. Mined findings feed §1's iteration as
proposal input; when the operator invoked docket-refit as "optimize
<target>" with no spec of their own, they are the proposal. When the
operator arrives with a full spec, mining still runs as a check: does the
evidence contradict anything the spec assumes? (`docket-retro` sweeps the
whole corpus on its own cadence; this mining is scoped to the one
definition being redesigned.)

## 3. Verify against the engine

**Source is the only capability authority** — not memory, not this file,
not what a sibling definition appears to imply: engines move, and a design
promised on a stale assumption fails at activation or worse. Two
authorities cover the corpus:

The docket engine checkout normally lives beside this repo
(`.../github.com/ALT-F4-LLC/docket.git/main`), but that worktree may not be
present in every environment (a bare clone with no checked-out `main`, for
instance). Confirm it resolves before launching; if it does not, pass
`engineRoot: null`, and the script returns `engineUnavailable` without
spawning an agent: report engine verification as unavailable rather than
proceeding from memory of these files, and carry every unverified
capability into §4 as an open deviation the operator decides. Its
load-bearing files, which the verifiers are pointed at:

- `internal/workflow/parse.go` — every legal `[[step]]` field and form
- `internal/workflow/validate.go` — the V-rules lint enforces (`after`,
  `inputs` shapes, loop declarations, fanout bounds)
- `internal/workflow/expand.go` — what expansion actually produces: fanout
  siblings, `when`-skipped rows, interposed threshold targets, loop-ordinal
  re-instantiation
- `internal/engine/loop.go`, `vote.go`, `human.go` — fix-loop entry,
  supersede sweep, budgets and parks, vote tally and rule resolution
- `internal/workflow/packet.go` — packet assembly: what `packet_includes` and
  step-level fragments become in the rendered packet
- `docket <verb> --help` and `docket config` — registered vote rules,
  schemas, doc-store verbs

The wave runner, `src/user/claude_code/workflows/wave.js`, is the authority
for everything the engine never sees: how policy rows resolve to a variant
and seat. It pipes the packet out of the engine's claim envelope and assembles
none of it. The `LENSES` table vote-seat names resolve against lives in
`src/user/claude_code/workflows/tribunal.js`.

Compose one capability question per mechanism the settled spec leans on,
and launch the script with `stage: "verify"` and that list: how fan-out
expands and when its width is fixed; how many independent fix-loops a
workflow may carry and where re-entry lands; what `threshold` routing does
and does not re-run; which `inputs` forms exist and how loop ordinals
rebind them; what a vote step needs (registered rule, routable voters) and
what its rejection can route to; what exhausting a budget does; how a
policy row's `variant`, `never`, and `escalate_to` actually resolve; which
schema fields threshold predicates can reach. One verifier per question
reads until the mechanism is settled in one pass and returns the answer
with `file:line` citations quoting the source. Carry each `settled` answer
as a cited fact; an answer returned `settled: false` is an open question
you read the cited source for yourself or carry into §4 as a deviation
candidate, never a fact the design may lean on. Store verbs (`docket
<verb> --help`, `docket config`) you run inline; they need no agent.

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
provides, a concrete proposal. One gap is one issue, within the docket
skill's [sizing reference](../docket/references/sizing.md)'s cap and
carrying its tier as `--size`; a deviation that needs two independent
engine changes is two filings.

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

The picture also carries the §1 comparison: the shapes weighed, the one
chosen, and the reason, so the operator approves a decision and not only a
drawing.

When the advisor tool is available, call it on the design before rendering
the artifact.

Present the artifact link and ask for approval via `AskUserQuestion`
(approve / revise). A revision request loops back through §4's gates if it
reopens a deviation, or straight to a redraw if it is design-only; nothing
in §6 onward happens until the picture is approved. Keep the artifact
updated at the same URL as the design moves — after landing, it doubles as
the definition's schematic.

## 6. Implement the co-change closure

A corpus change is rarely one file, whichever surface it enters from. The
blast-radius list from §1 is the worklist: land the target and every
consumer edit it forces, in one change, serially, in this session — never
through the workflow script and never through parallel subagents, since
consumers routinely share files and a parallel writer would race.

- **Workflow TOML** — redesigned steps, plus a `version` bump (frozen
  versions, see the design canon above).
- **Contracts** (`src/user/docket/config/contracts/<executor>.md`) — one
  per new executor, in the house shape named by
  `src/user/docket/config/README.md`'s naming convention: frontmatter
  (`node`, `version`, `archetype`, `packet_includes`, `emits`) then Charter /
  Not / Method / Emit / Stuck. Editing an existing shared contract is a
  blast-radius change: bump its `version` and verify the edit against every
  consuming workflow, not just the one in hand — a rule needed by only one
  pipeline belongs in a step-level packet fragment instead. Add README.md to
  this checklist as touched whenever a naming exception or convention
  changes, not-applicable otherwise.
- **Fragments** (`src/user/docket/config/fragments/`) — rules shared across
  nodes (a protocol, a store convention) live once in a fragment appended to
  each consumer's packet (one source of truth, see the design canon above).
  A fragment edit is reviewed against every including contract; bump its
  `version`.
- **policy.toml** — an `[executors]` row for every new executor and every
  new vote seat (the wave refuses to route or seat anything without a row),
  plus the policy version bump. Match variant tiers to comparable existing
  seats — least-capable tier that meets the bar, exceptions carrying an
  explicit `reason` — and prove the `[security]` invariants (`never`
  models, ceiling, node list) still hold for every touched row.
- **Vote-seat lenses** — a seat's lens is the last hyphen-token of its name,
  resolved against the `LENSES` table in
  `src/user/claude_code/workflows/tribunal.js`; a new lens key needs an
  entry there or the seat judges generically. `node --check` after editing.
- **Vote rules** — reuse a registered rule when its threshold matches (rules
  are thresholds; voters are orthogonal). A genuinely new rule is a store
  registration (`docket config set --global vote.rule.<name>.threshold`)
  the operator runs; name it in the report rather than mutating the store
  yourself.
- **Schemas** (`src/user/docket/config/schemas/`) — a new `payload` kind
  needs a schema file and threshold predicates that match its fields.
  Changing an existing kind is a new `kind@n+1` file, both sides moved
  together: every emitting contract and every reading predicate updated to
  the new version in the same change (deprecate, don't break — see the
  design canon above).

Before moving to §7, write one line per surface above — touched, or
not-applicable and why — even when the answer is obvious.

Whatever rationale you write into any of these files, write the finding
itself, not a pointer (date, timestamp, sha, issue id) to it; say what was
measured, in plain words, inline (see docket-retro §3 for why).

## 7. Validate

```bash
docket workflow lint src/user/docket/config/workflows/<name>.toml
just frozen-drift-check
```

Lint the target workflow, and when the change entered from a shared
surface, lint every workflow the §1 sweep listed as a consumer: a green
target with a broken sibling is the failure the blast-radius review exists
to prevent. `node --check` tribunal.js if lenses changed. These run inline;
they are cheap, and their output is the acceptance evidence.

Lint resolves schemas and vote rules from the current project's store, which
can lag the corpus: before blaming your edit, lint the installed known-good
version of the same workflow — an identical failure is environmental.
A missing corpus schema registers from its source file
(`docket schema register <kind@n> src/user/docket/config/schemas/<kind@n>.json`), then
re-lint. Schema registration into the local project's engine store is a
lint prerequisite this skill may perform directly, unlike a genuinely new
vote rule (§6), reserved for the operator: a schema registered here binds
only the one project being worked on, while a vote-rule threshold set with
`--global` changes every project's tally at once. The acceptance floor is a
clean lint across every consumer at the bumped versions; anything the lint
cannot see (live loop behavior, seat quality,
whether a fragment's rule actually lands in outputs) is reported as
unverified, not claimed.

## 8. Land

Commit via the `commit` skill. Other sessions share this tree, so stage
only the files this refit touched. The commit skill's message is final: no
post-commit amendment for attribution, `Claude-Session:` or otherwise. Then
report in plain language: what changed and why, the blast radius and how
each consumer was handled, each deviation the operator accepted and the
engine issue filed for it, what the evidence launches covered and what
they returned as uncovered, what was verified (lint, syntax checks) and
what was not (no live run). Never push; never install — the change reaches
`~/.docket` and `~/.claude` only through the operator's `just activate`.
