---
name: docket-retro
description: Evolve the shared docket corpus (src/user/docket/config/, operator-installed by `just activate`) and a repo's own optional .docket/config/ additions from run evidence — read run reports and the event log, find what recent runs actually cost and caught, and propose versioned config edits for approval. Operator-invoked only; suggest it after about five completed runs.
context: fork
agent: general-purpose
model: fable
---

# docket-retro

You turn what runs actually did into config changes. Evidence first, proposal
second, write only after the panel says yes — or, where the panel splits and
where trust is involved, after the operator does (§3).

You run in a forked subagent dedicated to this retro. `context: fork` spawns
you fresh on every invocation, and §1's analyst spawn and §3's approval
conversation run exactly as written, through `Workflow` and
`AskUserQuestion`. You carry none of the parent conversation's history —
no run reports already read, no earlier nudge that prompted this — only
`$ARGUMENTS`. Gather the evidence yourself here (§1) rather than assuming
anything was read for you. Your final report is the only thing that reaches
the parent, so it carries every proposal and its outcome.

**Never run automatically.** The operator invokes you. After roughly five
completed runs a session may *say* "five runs since the last docket-retro — worth
one?" and stop there. A nudge is a sentence, not an execution.

**Never edit a registered file in place.** Changed bytes at an unchanged
`name@version` refuse the whole next activation. Every workflow edit bumps
`[pipeline].version`; every schema edit is a new `name@N+1.json`. Not a style
preference — the only way the edit activates.

## 1. Gather

Gathering and analysis are agent work: spawn `executor-read` analysts (one,
or one per run when runs are many), each briefed with the corpus contract
`~/.docket/config/contracts/retro-analyst.md` (source in the dotfiles
checkout: `src/user/docket/config/contracts/retro-analyst.md`) — the node the
corpus already defines for exactly this — plus §2's table verbatim.
`retro-analyst` carries no `policy.toml` row: the retro pipeline that once
dispatched it through the wave was removed (`retro.toml` — deliberate and
permanent, not an accident: "no issue ever carried
the retro label, so no run ever bound it" and this skill "covers the same
analyze/vote/apply loop on its own"), and the row went with it. The skill-side
spawn below is the only path this node has, so seat each analyst through the
built-in `Workflow` tool's `agent()` call with the intended `model` and
`effort` set explicitly in its opts — the plain `Agent` tool carries no effort
parameter, and through it the analysts silently run at the session default.
They run the verbs and return evidence-labelled
findings; you compose §3's proposals and hold the approval conversation. The
verbs, for their briefs:

```bash
docket run report RUN-N --json                        # per run; read-only, never advances a run
docket events list --run RUN-N --json --all-projects  # the transition trail
docket events list --json --limit 500 --all-projects  # recent feed; trust grants live here
docket events list --json --all-projects              # every project sharing the store
docket step artifacts STEP-N --json                   # one step's artifact index
docket step artifact <id> --json                      # one artifact's body; the report indexes only
```

Collect every run since the last docket-retro before concluding anything — one run is
an anecdote. The docket events store is machine-global, but `events list` is
cwd-scoped by default: a run's events may have been recorded from a different
project's working directory, so a cwd-scoped query — `--run RUN-N` included —
can return `ok:true, total 0` for a run that genuinely exists. Always pass
`--all-projects`, as every verb above now does. **Every docket verb opens the store read-write and migrates forward**,
so all of these run sandboxed only where the store path is itself writable
under the sandbox's policy — check the store path against the write allowlist
rather than assuming an unsandboxed shell is needed. Where it is not writable,
`sqlite3 'file:<store>/issues.db?immutable=1'` is the read-only fallback.

## 2. Read the evidence

| Question | Where | What a finding looks like |
|---|---|---|
| Where does spend go? | `budget`: `floor` vs `reported[]` (per unit, never summed; `budget_unit` names the counted one), `spend` = max of the two, `cap` + `cap_source`, `burn_rate`, `breach_reason` (`attempts` is its own top-level section, not a budget field) | one step carries most of the floor, or `reported` dwarfs `floor` → `expected_cost` miscalibrated; a `breach_reason` under `cap_source: config` means the run met a default nobody sized for it |
| Judge value (D2) | `artifacts` grouped by `executor` (+`issue`) — `producer` is the fanout ordinal (`review@0#2`), which says WHERE in the topology, never WHO; bodies come from `step artifact` | a judge that never uniquely contributes above `low` across 5 runs → cut it in a version bump |
| Dedup rate (D3) | duplicate findings across a fanout's artifacts — the report is an index and carries no bodies, so read them with `step artifacts` then `step artifact` | under 10% at width ≤ 4 across 5 runs → propose exact-locus dedup instead of `synthesize` |
| Recurring shapes (D5) | the same topology planned ≥ 3 times | migrate it into a workflow template — never leave the planner to re-improvise |
| Gate health | `gates` pass/fail/**unmatched**, `gate_trail` (its `output` rides non-pass rows only, last 2000 bytes) | any `unmatched` is a missing trust entry, not a failing check |
| Intervention profile | `run-paused`, `step-held`, and `step-routed` with destination `waiting-human` — that string is a run/step STATUS, not an event kind, so filtering events on it returns nothing; `lease-reaped` behind the holds — query with `--all-projects`, since the run being investigated may have been driven from another project's cwd | designed gate vs breach vs held — three different fixes; a hold behind a `lease-reaped` carrying `data.forced` was a relay declaring a dead spawn, not a slow step |
| Attempt pressure | `attempts`, loop ordinals | a step repeatedly at `max_attempts` wants a smaller charter, not a bigger budget |
| Trust drift (D14) | `trust-added`/`trust-removed` (store-level; query with `--all-projects` — visible either way, but only that flag proves you saw all of them) | **an entry the operator does not recognize is a finding, and you raise it first** |
| Config churn (D15) | your own proposals per run over time | churn trending up means docket-bootstrap mined the repo wrong; fix the source, not each symptom |
| Routing drift | the four metadata keys (below), read per step with `docket step show` / `step context` — `run report`'s `metadata` is a key → distinct-values rollup that never pairs requested with resolved on one step, so it shows aggregate skew only | requested ≠ resolved across runs means policy asks for a model it does not get |
| Vote calibration | `vote_rule` outcomes vs the threshold | a rule that never fails, or always fails, is a threshold not doing work |
| Variant fit | `[executors]` rows vs attempts + cost at that variant | a row failing repeatedly at its variant is mis-sized, not under-budgeted |
| Review-yield | output tokens per stage (review vs implement vs verify, from `metadata`/`budget`); distinct clusters the review stage found; distinct issues `drain-highs` filed, post-dedupe; how many of those routed to a fix round; how many prior runs' `review-gap` issues (`docket issue list --label review-gap --json`) have since closed | review spend far exceeding implement's own, or a low post-dedupe filed-to-found ratio, means the stage is expensive relative to what survives it; a flat or falling closed count across runs means filed `review-gap` backlog is accumulating unworked |

Label every claim by what it rests on: a count from the report is observed, a
pattern across five runs is inferred. Say which one you have.

### The M3-era surfaces you may propose edits to

These surfaces exist now that earlier retros had no vocabulary for. Same
mechanism as everything else — evidence, proposal, approval — but know they are
yours to propose against:

**`policy.toml`'s tables.** Pinned, not registered, so an edit needs no version
bump — but note it, because the next docket-retro attributes what followed to it.

| Table | A finding that touches it |
|---|---|
| `[variants]` | a variant's {model, effort} consistently over- or under-serving its rows; an `escalate_to` hop that lands wrong |
| `[executors]` | a hint mis-sized; a row orphaned by a deleted workflow; a hint with no row |
| `[security]` | security-labelled work landing on an unpinned row — widen `nodes` or `labels` |
| `[[resolve]]` | a rule that never matches, or ordering that lets the general rule shadow the specific one |
| `[escalation]` | `one-hop` under- or over-shooting; a `fable_gates` entry that never fires |

Two invariants any `[executors]` proposal must preserve: **every hint has
exactly one row, and every row is reachable from some hint.** The wave refuses
to route otherwise. A proposal that deletes a workflow must delete the rows it
orphans in the same breath.

**Vote-rule thresholds.** These live in engine config, not in either config root:

```bash
docket config set vote.rule.<name>.threshold <0-1>            # this project
docket config set --global vote.rule.<name>.threshold <0-1>   # every project
```

A rule exists iff its threshold is set, and a threshold sized from one repo's
runs belongs on that project's override — `--global` only for a default every
project should inherit. **Thresholds are store state, not shipped config** —
the corpus sets none, so a fresh or reset store has none either, and a corpus
workflow naming a rule (today `security-acceptance` and `doc-acceptance`)
fails `docket workflow lint` with `vote_rule "<name>" is not registered` until
the `config set` above runs. Read `docket config get
vote.rule.<name>.threshold` before assuming a rule exists; empty means the job
is creating it, not calibrating it. Sizing these from evidence — and creating
the missing ones — is explicitly docket-retro's job. A rule whose outcome never
differs from a plain human gate is a rule to question, not tune.

**The four metadata keys.** Every completed step carries
`model_requested` / `effort_requested` (what policy asked for) and
`model_resolved` / `effort_resolved` (what actually served). The gap between
them is routing drift, and it is invisible anywhere else. Read the pair off
the step itself (`docket step show` / `step context`): `run report`'s
`metadata` is a rollup of key → distinct values with counts, so it can show
that resolutions disagree in aggregate but never which step asked for what.
Known blind spot, stated so you do not misread a clean report: **a failed or
crashed step contributes none of the four**, so drift concentrated in failures
will not appear here. Read attempt counts alongside.

**Lease and duration limits, if steps are being reaped mid-work.** Liveness is
no longer TTL-only: `step heartbeat` extends a live claim, `step reap STEP-N
--reason R` is the token-free channel for a relay that watched its executor
die, and `[limits]` classes take `{max, lease_ttl, max_step_duration}`. Read
the reaps apart (query events with `--all-projects`, since the reaped run may
have been driven from another project's cwd). An expiry — or a step completing against a lease it no longer
holds — means `lease.ttl.<class>` is sized below real step duration; propose
the observed worst case plus headroom. **Name the class the way the step
does**: a class is the step's `class` field and it defaults to the EXECUTOR
name, which is why these workflows' `[limits]` tables read
`"judge-architecture"`, `"verify-ac"`, `"synthesize-findings"` — and `"write"`
only because the writer steps declare it. A proposal for `lease.ttl.read` binds
nothing here; the key that covers those steps is `lease.ttl.default`, or the
executor's own name. `config set` warns when a class no registered workflow
declares, so check the warning rather than assuming the write took. A `data.forced` reap is a dead spawn, a
relay finding rather than a config one. And **heartbeating cannot carry a step
past its class's `max_step_duration`, measured from the claim**: a healthy
holder reaped there wants a smaller charter or a bigger ceiling, not a TTL.

## 3. Propose

Proposals go to a three-judge panel of agents. Compose the batch first — one
proposal per finding, ranked by evidence strength; stop at the ones you can
defend — and give every one of them, before anything is written:

- what the evidence says, with the numbers and the run IDs it came from
- the edit, as a diff against the current file
- the version bump it carries
- what it costs if you are wrong

The proposal packet is allowed to cite run IDs — the panel is deciding NOW,
against a store that still holds them. The DIFF is not: whatever comment or
rationale lands in the file is read years later by someone with no run
history, no git log, and no tracker open. A date, a timestamp, a sha, or an
issue id in that comment is a pointer that may already be dead by the time
anyone reads it. Write what was actually found, in plain words, in the
comment itself — the file has to justify itself without you standing next
to it.

That packet is the panel's entire input, so it travels to them whole rather
than summarized. A batch nobody can evaluate line by line gets approved
blindly — which is exactly why the line-by-line burden is the PANEL's now,
three readers against one batch, and why the operator sees only what the panel
could not settle. Open the proposal from the repo the edits target:

```bash
docket vote create -d "<what the batch changes, plainly>" \
  -r "<the evidence: the numbers, the run IDs>" \
  --files-changed "<the config files the batch edits, comma-separated>" \
  -n 3 -c medium --threshold 0.67 --created-by retro
```

then convene the judges on it:

```
Workflow({scriptPath: "<home>/.claude/workflows/tribunal.js", args: {
  voteId: "<id>",
  voters: [{seat: "tribunal-architecture", model, effort, variant}, {seat: "tribunal-security", ...}, {seat: "tribunal-correctness", ...}],
  context: "<every proposal with its evidence, its diff, and its bump>",
  gateKind: "fix-batch", cwd: "<the repo the edits target>"}})
```

By `scriptPath` only and never by name, `args` a real object, each voter
carrying the routing triple looked up from the pinned policy exactly as
docket-run's tribunal launch does (its python lookup, pasted verbatim) — the
script reads no files and parses no policy. The path is the
installed `<home>/.claude/workflows/tribunal.js` with `<home>` expanded to a
literal absolute path (the tool expands no `~`), and there is no source-tree
fallback: the Workflow tool launches
only a scriptPath under the session's cwd or a directory added to the session,
and the settings corpus adds exactly `~/.claude/workflows`
(`permissions.additionalDirectories`) — the source copy in the
dotfiles checkout is refused verbatim from any other seat, and since the
install lags source until the operator's `just activate`, un-activated source
bytes are bytes no session runs anyway. An absent installed file means the
corpus was never activated here: stop and report it rather than hunting for
another copy.
Then `docket vote
result <id>`: **approved is the authority to apply, and §4 runs immediately** —
there is no follow-up question about whether to apply now or later. A rejection
or a split goes to the operator through the built-in question tool — recommended
option first, labelled "(Recommended)" — carrying EVERY judge's verdict,
confidence, and summary verbatim, because they are ruling on the dispute and a
tally you have condensed is not one. Only what they approve is applied.

A docket-retro that proposes nothing because five runs went cleanly is a correct
docket-retro — say so rather than manufacturing work, and convene no panel to hear it.

Never propose a change that adds manual upkeep for the developer; that violates
zero-touch on its face. The answer is config or engine, not a step in someone's
routine.

**A trust proposal is the operator's alone, and rides no batch.** Follow
docket-bootstrap's rule — argue `re-runnable`, `tree`, `flaky` per command, default
off, never add before approval — and ask it in its OWN question, never bundled
with config edits the panel already cleared. Trust authorizes execution; a
panel of agents cannot grant that, and a trust row inside a four-item bundle is
approved in one click without being read.

## 4. Apply what was approved

Only the approved items — whether the panel approved them or the operator did
on escalation — and the moment the result is in, not after asking again.
Applied by an `executor-write` agent carrying the approved diffs, with the
dry-run verification below performed by an `executor-read` agent; you relay
approvals and read their reports. Same variant caveat as §1: spawned from here,
neither agent carries a `policy.toml` variant.

**Approved corpus edits land in the dotfiles checkout, not in the repo.** The
engine reads the corpus from `~/.docket/config`, a content-addressed store
path replaced wholesale by `just activate` — never edit there even when the
filesystem lets you, because the next install silently reverts it and you will
believe you fixed something. Edit `src/user/docket/config/` instead
(`contracts/`, `fragments/`, `schemas/`, `workflows/`, `policy.toml`); the
operator installs it with `just activate`, BETWEEN runs, because an install
changes what already-pinned refs resolve to. **Every repo sharing the corpus
reads the same bytes**, so a corpus edit at an unchanged `name@version`
refuses the next activation in ALL of them. Say that blast radius when you
propose.

A repo may also carry an optional second layer of its own in `.docket/config/`
— repos have none by default, and only that repo reads it. An ADDITION there
that collides with a shared `name@version`, or a pinned ref, refuses every
activation in its own repo until one side moves: bump the shared version, or
rename the addition — and say which you chose and why.

A workflow edit stays in the same file with `[pipeline].version = N+1` and its
mined-facts comment kept current. A schema edit is a new
`schemas/<name>@N+1.json`, plus a bump to every workflow naming it.
`policy.toml`, contracts, and fragments are pinned rather than registered —
edit freely, but note the change so the next docket-retro can attribute what followed.
Trust the OPERATOR approved goes in with `docket trust add <name> --yes --
<argv>` — no other approval opens that door.

Verify twice, and the order is load-bearing. First, `docket workflow lint
<file.toml>` on the edited checkout bytes *before* the proposal reaches the
panel — it runs the exact validation `register` runs, writes nothing, and
returns `CONFLICT` when the edit sits on a frozen `name@version` with the bump
missing. Second, only after the operator has run `just activate`: activation
reads the config roots (`~/.docket/config`, then a repo's `.docket/config` if
it has one) and never the dotfiles checkout, so a dry-run before the install
proves nothing about bytes that are not installed yet. Then `docket run
activate RUN-M --dry-run` must show the new version registering and every
fence still `matched` — against a run still in `planning`. Re-activating an
already-active run expands newly-unblocked phases only and inherits its
original pin set, so a re-registered workflow never reaches it and the dry-run
shows the old version; make a throwaway planning run if none is available.

**Retiring a version.** Binding reduces each name to its highest *non-retired*
version before `[match]` runs, so a bump binds the new version on its own; the
old row stays readable and a run that pinned it still completes. To fall back
beneath a bad version, or take a mistakenly registered name out of routing
altogether, retire it — `docket workflow deprecate <name>@<version>`, reversed
by `--restore`. A binding-time filter, never a deletion: no delete verb exists,
and renaming a pipeline still loses the version lineage pinning preserves.

## 5. Close

Report which proposals were approved and by which authority — the panel, or the
operator on an escalation — which were declined, and what the next docket-retro should
watch. A declined proposal with accumulating evidence is the first thing to
re-raise, and a panel that split is worth naming as such: the disagreement is
evidence about the proposal. A finding that belongs upstream (an engine limitation, a
design deviation) gets filed as an issue, not bent into config — and filed in
its OWNING project (operator ruling: gaps belong to their
respective projects): engine findings from the docket repo's checkout,
definition findings from the dotfiles checkout — cwd picks the project —
never into whichever project this docket-retro read its runs from. `docket issue
move <id> --project <target>` re-homes one that already landed wrong.
