---
name: retro
description: Evolve the shared docket corpus (src/user/docket/, operator-installed by `just activate`) and a repo's own .docket/config/ additions from run evidence — read run reports and the event log, find what recent runs actually cost and caught, and propose versioned config edits for approval. Operator-invoked only; suggest it after about five completed runs.
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
docket run report RUN-N --json           # per run; read-only, never advances a run
docket events list --run RUN-N --json    # the transition trail
docket events list --json --limit 500    # this project's feed; trust grants live here
docket events list --json --all-projects # every project sharing the store
```

Collect every run since the last retro before concluding anything — one run is
an anecdote. `events list` is project-scoped and the store is machine-global,
so other repos' runs share the ledger; `--all-projects` is for a store-wide
audit. **Every docket verb opens the store read-write and migrates forward, so
all of these need an unsandboxed shell** — sandboxed, `sqlite3
'file:<store>/issues.db?immutable=1'` is the only read-only open.

## 2. Read the evidence

| Question | Where | What a finding looks like |
|---|---|---|
| Where does spend go? | `budget`: `floor` vs `reported[]` (per unit, never summed; `budget_unit` names the counted one), `spend` = max of the two, `cap` + `cap_source`, `burn_rate`, `breach_reason`; `attempts` | one step carries most of the floor, or `reported` dwarfs `floor` → `expected_cost` miscalibrated; a `breach_reason` under `cap_source: config` means the run met a default nobody sized for it |
| Judge value (D2) | `artifacts` by producer + their payloads | a judge that never uniquely contributes above `low` across 5 runs → cut it in a version bump |
| Dedup rate (D3) | duplicate findings across a fanout's artifacts | under 10% at width ≤ 4 across 5 runs → propose exact-locus dedup instead of `synthesize` |
| Recurring shapes (D5) | the same topology planned ≥ 3 times | migrate it into a workflow template — never leave the planner to re-improvise |
| Gate health | `gates` pass/fail/**unmatched**, `gate_trail` (its `output` rides non-pass rows only, last 2000 bytes) | any `unmatched` is a missing trust entry, not a failing check |
| Intervention profile | `waiting-human` events by reason; `lease-reaped` behind the holds | designed gate vs breach vs held — three different fixes; a hold behind a `lease-reaped` carrying `data.forced` was a relay declaring a dead spawn, not a slow step |
| Attempt pressure | `attempts`, loop ordinals | a step repeatedly at `max_attempts` wants a smaller charter, not a bigger budget |
| Trust drift (D14) | `trust-added`/`trust-removed` (store-level; visible in either scoping) | **an entry the operator does not recognize is a finding, and you raise it first** |
| Config churn (D15) | your own proposals per run over time | churn trending up means bootstrap mined the repo wrong; fix the source, not each symptom |
| Routing drift | `data.metadata`'s four keys (below) | requested ≠ resolved across runs means policy asks for a model it does not get |
| Vote calibration | `vote_rule` outcomes vs the threshold | a rule that never fails, or always fails, is a threshold not doing work |
| Tier fit | `[executors]` rows vs attempts + cost at that tier | a row failing repeatedly at its tier is mis-tiered, not under-budgeted |

Label every claim by what it rests on: a count from the report is observed, a
pattern across five runs is inferred. Say which one you have.

### The M3-era surfaces you may propose edits to

These surfaces exist now that earlier retros had no vocabulary for. Same
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
docket config set vote.rule.<name>.threshold <0-1>            # this project
docket config set --global vote.rule.<name>.threshold <0-1>   # every project
```

A rule exists iff its threshold is set, and a threshold sized from one repo's
runs belongs on that project's override — `--global` only for a default every
project should inherit. They ship provisional (`security-acceptance` 0.67,
`doc-acceptance` 0.60) and were never calibrated against real votes — sizing
them from evidence is explicitly retro's job. A rule whose outcome never
differs from a plain human gate is a rule to question, not tune.

**The four metadata keys.** Every completed step carries
`model_requested` / `effort_requested` (what policy asked for) and
`model_resolved` / `effort_resolved` (what actually served). The gap between
them is routing drift, and it is invisible anywhere else. Known blind spot,
stated so you do not misread a clean report: **a failed or crashed step
contributes none of the four**, so drift concentrated in failures will not
appear here. Read attempt counts alongside.

**Lease and duration limits, if steps are being reaped mid-work.** Liveness is
no longer TTL-only: `step heartbeat` extends a live claim, `step reap STEP-N
--reason R` is the token-free channel for a relay that watched its executor
die, and `[limits]` classes take `{max, lease_ttl, max_step_duration}`. Read
the reaps apart. An expiry — or a step completing against a lease it no longer
holds — means `lease.ttl.<class>` is sized below real step duration; propose
the observed worst case plus headroom. A `data.forced` reap is a dead spawn, a
relay finding rather than a config one. And **heartbeating cannot carry a step
past its class's `max_step_duration`, measured from the claim**: a healthy
holder reaped there wants a smaller charter or a bigger ceiling, not a TTL.

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
`executor-read` agent; you relay approvals and read their reports.

**Approved corpus edits land in the dotfiles checkout, not in the repo.** A
repo's `.docket/config/` is a link farm into `~/.docket`, so editing a file
there rewrites the SHARED corpus through the link — unversioned, and behind
the operator's install gate. Edit `src/user/docket/` instead (`contracts/`,
`fragments/`, `schemas/`, `workflows/`, `policy.toml`); the operator installs
it with `just activate`, BETWEEN runs, because an install changes what
already-pinned refs resolve to. Real files a repo dropped beside its links are
the only in-place edits left — and every repo sharing the corpus binds the
same bytes, so an edit at an unchanged `name@version` refuses the next
activation in ALL of them. Say that blast radius when you propose.

A workflow edit stays in the same file with `[pipeline].version = N+1` and its
mined-facts comment kept current. A schema edit is a new
`schemas/<name>@N+1.json`, plus a bump to every workflow naming it.
`policy.toml`, contracts, and fragments are pinned rather than registered —
edit freely, but note the change so the next retro can attribute what followed.
Approved trust goes in with `docket trust add <name> --yes -- <argv>`.

Verify twice. `docket workflow lint <file.toml>` on the edited bytes *before*
the proposal reaches the human — it runs the exact validation `register` runs,
writes nothing, and returns `CONFLICT` when the edit sits on a frozen
`name@version` with the bump missing. Then `docket run activate RUN-M
--dry-run` must show the new version registering and every fence still
`matched`.

**Retiring a version.** Binding reduces each name to its highest *non-retired*
version before `[match]` runs, so a bump binds the new version on its own; the
old row stays readable and a run that pinned it still completes. To fall back
beneath a bad version, or take a mistakenly registered name out of routing
altogether, retire it — `docket workflow deprecate <name>@<version>`, reversed
by `--restore`. A binding-time filter, never a deletion: no delete verb exists,
and renaming a pipeline still loses the version lineage pinning preserves.

## 5. Close

Report which proposals were approved, which declined, and what the next retro
should watch — a declined proposal with accumulating evidence is the first
thing to re-raise. A finding that belongs upstream (an engine limitation, a
design deviation) gets filed as an issue, not bent into config.
