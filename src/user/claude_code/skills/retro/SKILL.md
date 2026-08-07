---
name: retro
description: Evolve .docket/config/ from run evidence — read run reports and the event log, find what recent runs actually cost and caught, and propose versioned config edits for approval. Operator-invoked only; suggest it after about five completed runs.
---

# retro

You turn what runs actually did into config changes. Evidence first, proposal
second, write only after the human says yes.

**Never run automatically.** The operator invokes you. After roughly five
completed runs a session may *say* "five runs since the last retro — worth
one?" and stop there. A nudge is a sentence, not an execution.

**Never edit a registered file in place.** Changed bytes at an unchanged
`name@version` refuse the whole next activation. Every workflow edit bumps
`[pipeline].version`; every schema edit is a new `name@N+1.json`. Not a style
preference — the only way the edit activates.

## 1. Gather

Gathering and analysis are agent work: spawn `executor-read` analysts (one,
or one per run when runs are many), each briefed with the repo's
`contracts/retro-analyst.md` — the node the corpus already defines for
exactly this — plus §2's table verbatim. They run the verbs and return
evidence-labelled findings; you compose §3's proposals and hold the approval
conversation. The verbs, for their briefs:

```bash
docket run report RUN-N --json          # per run; read-only, never advances a run
docket events list --run RUN-N --json   # the transition trail
docket events list --json --limit 500   # repo-wide: trust grants live here
```

Collect every run since the last retro before concluding anything — one run is
an anecdote.

## 2. Read the evidence

| Question | Where | What a finding looks like |
|---|---|---|
| Where does spend go? | `budget.floor` vs `budget.reported`; `attempts` | one step carries most of the floor, or reported dwarfs floor → `expected_cost` miscalibrated |
| Judge value (D2) | `artifacts` by producer + their payloads | a judge that never uniquely contributes above `low` across 5 runs → cut it in a version bump |
| Dedup rate (D3) | duplicate findings across a fanout's artifacts | under 10% at width ≤ 4 across 5 runs → propose exact-locus dedup instead of `synthesize` |
| Recurring shapes (D5) | the same topology planned ≥ 3 times | migrate it into a workflow template — never leave the planner to re-improvise |
| Gate health | `gates` pass/fail/**unmatched**, `gate_trail` | any `unmatched` is a missing trust entry, not a failing check |
| Intervention profile | `waiting-human` events by reason | designed gate vs breach vs held — three different fixes |
| Attempt pressure | `attempts`, loop ordinals | a step repeatedly at `max_attempts` wants a smaller charter, not a bigger budget |
| Trust drift (D14) | `trust-added`/`trust-removed` repo-wide | **an entry the operator does not recognize is a finding, and you raise it first** |
| Config churn (D15) | your own proposals per run over time | churn trending up means bootstrap mined the repo wrong; fix the source, not each symptom |
| Routing drift | `data.metadata`'s four keys (below) | requested ≠ resolved across runs means policy asks for a model it does not get |
| Vote calibration | `vote_rule` outcomes vs the threshold | a rule that never fails, or always fails, is a threshold not doing work |
| Tier fit | `[executors]` rows vs attempts + cost at that tier | a row failing repeatedly at its tier is mis-tiered, not under-budgeted |

Label every claim by what it rests on: a count from the report is observed, a
pattern across five runs is inferred. Say which one you have.

### The M3-era surfaces you may propose edits to

Three surfaces exist now that earlier retros had no vocabulary for. Same
mechanism as everything else — evidence, proposal, approval — but know they are
yours to propose against:

**`policy.toml`'s tables.** Pinned, not registered, so an edit needs no version
bump — but note it, because the next retro attributes what followed to it.

| Table | A finding that touches it |
|---|---|
| `[tiers]` | a tier's {model, effort} consistently over- or under-serving its rows |
| `[executors]` | a hint mis-tiered; a row orphaned by a deleted workflow; a hint with no row |
| `[security]` | security-labelled work landing on an unpinned row — widen `nodes` or `labels` |
| `[[resolve]]` | a rule that never matches, or ordering that lets the general rule shadow the specific one |
| `[escalation]` | `one-rung` under- or over-shooting; a `diamond_gates` entry that never fires |

Two invariants any `[executors]` proposal must preserve: **every hint has
exactly one row, and every row is reachable from some hint.** The wave refuses
to route otherwise. A proposal that deletes a workflow must delete the rows it
orphans in the same breath.

**Vote-rule thresholds.** These live in engine config, not `.docket/config/`:

```bash
docket config set vote.rule.<name>.threshold <0-1>
```

They ship provisional (`security-acceptance` 0.67, `doc-acceptance` 0.60) and
were never calibrated against real votes — sizing them from evidence is
explicitly retro's job. A rule whose outcome never differs from a plain human
gate is a rule to question, not tune.

**The four metadata keys.** Every completed step carries
`model_requested` / `effort_requested` (what policy asked for) and
`model_resolved` / `effort_resolved` (what actually served). The gap between
them is routing drift, and it is invisible anywhere else. Known blind spot,
stated so you do not misread a clean report: **a failed or crashed step
contributes none of the four**, so drift concentrated in failures will not
appear here. Read attempt counts alongside.

**Lease TTLs, if steps are being reaped mid-work.** There is no heartbeat;
liveness is TTL-only. `waiting-human` events whose reason is a lost or expired
claim, or a step completing against a lease it no longer holds, mean
`lease.ttl.<class>` is sized below real step duration. Propose the observed
worst case plus headroom — you now have the run durations bootstrap had to guess
at.

## 3. Propose

Proposals and approvals go through the built-in question tool — recommended
option first, labelled "(Recommended)"; open-ended asks offer drafted
candidates as options. Present a conversational summary — before writing
anything:

- what the evidence says, with the numbers and the run IDs it came from
- the edit, as a diff against the current file
- the version bump it carries
- what it costs if you are wrong

One proposal per finding, ranked by evidence strength; stop at the ones you can
defend. A batch the human cannot evaluate line by line gets approved blindly.
A retro that proposes nothing because five runs went cleanly is a correct
retro — say so rather than manufacturing work.

Never propose a change that adds manual upkeep for the developer; that violates
zero-touch on its face. The answer is config or engine, not a step in someone's
routine. For a trust proposal, follow bootstrap's rule: argue `re-runnable`,
`tree`, `flaky` per command, default off, never add before approval.

## 4. Apply what was approved

Only the approved items — applied by an `executor-write` agent carrying the
approved diffs, with the dry-run verification below performed by an
`executor-read` agent; you relay approvals and read their reports. A workflow edit stays in the same file with
`[pipeline].version = N+1` and its mined-facts comment kept current. A schema
edit is a new `schemas/<name>@N+1.json`, plus a bump to every workflow naming
it. `policy.toml`, contracts, and fragments are pinned rather than registered —
edit freely, but note the change so the next retro can attribute what followed.
Approved trust goes in with `docket trust add <name> --yes -- <argv>`.

Verify before declaring done: `docket run activate RUN-M --dry-run` must show
your new version registering and every fence still `matched`.

**Known engine defect (DKT, filed by M2a).** Bumping `[pipeline].version` in
place leaves the old version registered with its `[match]` intact, so the next
activation refuses: *"issue DKT-N matches 2 workflows … candidates:
name@1, name@2"*. Narrowing the new version's `[match]` does not help — the
frozen old clause still matches, and `unless_labels` cannot reach it. Until the
engine resolves binding to the highest version, verify every bump against a
real activation before reporting success, and if it wedges, say so and file it
rather than working around it by renaming the pipeline — a rename loses the
version lineage that pinning exists to preserve.

## 5. Close

Report which proposals were approved, which declined, and what the next retro
should watch — a declined proposal with accumulating evidence is the first
thing to re-raise. A finding that belongs upstream (an engine limitation, a
design deviation) gets filed as an issue, not bent into config.
