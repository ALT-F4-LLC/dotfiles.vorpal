---
name: docket-retro
description: >-
  Use on the operator's request only, after about five completed runs:
  "retro", "what did the runs cost", "evolve the corpus from the runs". Reads
  run reports and the event log, finds what recent runs cost and caught,
  proposes versioned edits to the shared docket corpus and a repo's optional
  .docket/config additions, and files each approved proposal as a Docket
  issue; approved trust is handed over as a command. Edits nothing itself.
---

# docket-retro

You turn what runs actually did into filed config proposals. Evidence first,
proposal second, file only after the panel says yes, or, where the panel
splits, after the operator does (§3). You never
edit the config: a filed issue carries the approved diff, or for store state
the approved command, to the worker who lands it. Approved trust is the one
item not filed: the operator runs its command.

**Automation first is the primary goal of every proposal.** Each one sits
on the highest rung of the docket skill's
[automation ladder](../docket/references/automation.md#the-automation-ladder)
that can carry it, and keeps or adds a human touch only under a named
[vital condition](../docket/references/automation.md#when-a-human-is-vital).
Operator touches the runs needed are evidence: an automatable one that
recurs is a proposal in its own right. This governs what you propose; the
panel and operator approvals below gate what you file, and authorize no edit.

Run in the invoking conversation: §1 seats its analysts through `Workflow`,
and §3's approval conversation runs through `AskUserQuestion`, and a forked
subagent has neither; a fork returns its open questions to its caller
instead of asking them. Gathering and aggregation are the analysts' work
(§1); this conversation reads their findings, composes the proposals, and
holds the approval conversation.
Assume nothing was read for you — no run reports from earlier in the
session, no nudge that prompted this — and gather through §1 every time,
from `$ARGUMENTS`. The §5 report is delivered here and carries every
proposal and its outcome.

**Never run automatically.** The operator invokes you. After roughly five
completed runs a session may say "five runs since the last docket-retro,
worth one?" and stop there. A nudge is a sentence, not an execution.

**Never propose editing a registered file in place.** Changed bytes at an
unchanged `name@version` refuse the whole next activation. Every workflow
edit bumps `[pipeline].version`; every schema edit is a new
`name@N+1.json`. Not a style preference — the only way the edit activates.
Every file-edit proposal and its issue carries its bump; store state has no
file and carries none.

## 1. Gather

Gathering and analysis are agent work: spawn `executor-read` analysts (one,
or one per run when runs are many), each briefed with the corpus contract
`~/.docket/config/contracts/retro-analyst.md` (source in the dotfiles
checkout: `src/user/docket/config/contracts/retro-analyst.md`), the node
the corpus already defines for exactly this, plus §2's table verbatim.
`retro-analyst` carries no `policy.toml` row and no workflow dispatches it
through the wave: no issue carries the retro label, and this skill runs the
analyze/vote/file loop itself. The skill-side spawn below is the only path
this node has, so seat each analyst through
`Workflow({scriptPath: "<home>/.claude/workflows/retro-seat.js", args: {
analysts: [{brief, model, effort}, ...]}})` (source in the dotfiles
checkout: `src/user/claude_code/workflows/retro-seat.js`), one array entry
per analyst, with the intended `model` and `effort` set explicitly since the
script has no row to resolve them from. They run the verbs and return
evidence-labelled findings through a fixed schema; you compose §3's
proposals and hold the approval conversation. The workflow returns
`{reports, seated, returned}`: `reports` holds one entry per `analysts`
entry, in order, each `{window, coverage, findings, gaps}` (a finding is
`{kind, row, title, runs, body}`, `kind` either `config-proposal` or
`issue-to-file`), or `null` for a seat that returned nothing. A `null` is
a coverage gap for that analyst's run window, never a clean window. The
verbs, for their briefs:

```bash
docket run report RUN-N --json                        # per run; read-only, never advances a run
docket events list --run RUN-N --json --all-projects  # the transition trail
docket events list --json --limit 500 --all-projects  # recent feed; trust grants live here
docket events list --json --all-projects              # every project sharing the store
docket step artifacts STEP-N --json                   # one step's artifact index
docket step artifact <id> --json                      # one artifact's body; the report indexes only
```

Collect every run since the last docket-retro before concluding anything;
one run is an anecdote. With no prior retro, the window is every run in the
store. The docket events store is machine-global, but `events list` is
cwd-scoped by default, so a cwd-scoped query — `--run RUN-N` included — can
return `ok:true, total 0` for a run recorded from a different project's
working directory. Always pass `--all-projects` on every `docket events list` call above; the
other three verbs (`docket run report`, `docket step artifacts`, `docket
step artifact`) do not take the flag. Every docket verb opens the store read-write and migrates forward, so
these run sandboxed only where the store path is itself writable under the
sandbox's policy; check the store path against the write allowlist rather
than assuming an unsandboxed shell is needed. Where it is not writable,
`sqlite3 'file:<store>/issues.db?immutable=1'` is the read-only fallback.

## 2. Read the evidence

| Question | Where | What a finding looks like |
|---|---|---|
| Where does spend go? | `budget`: `floor` vs `reported[]` (per unit, never summed; `budget_unit` names the counted one), `spend` = max of the two, `cap` + `cap_source`, `burn_rate`, `breach_reason` (`attempts` is its own top-level section, not a budget field) | one step carries most of the floor, or `reported` dwarfs `floor` → `expected_cost` miscalibrated; a `breach_reason` under `cap_source: config` means the run met a default nobody sized for it |
| Judge value | `artifacts` grouped by `executor` (+`issue`) — `producer` is the fanout ordinal (`review@0#2`), which says WHERE in the topology, never WHO; bodies come from `step artifact` | a judge that never uniquely contributes above `low` across 5 runs → cut it in a version bump |
| Dedup rate | duplicate findings across a fanout's artifacts — the report is an index and carries no bodies, so read them with `step artifacts` then `step artifact` | under 10% at width ≤ 4 across 5 runs → propose exact-locus dedup instead of `synthesize-findings` |
| Recurring shapes | the same topology planned ≥ 3 times | migrate it into a workflow template — never leave the planner to re-improvise |
| Gate health | `gates` pass/fail/**unmatched**, `gate_trail` (its `output` rides non-pass rows only, last 2000 bytes) | any `unmatched` is a missing trust entry, not a failing check |
| Intervention profile | `run-paused`, `step-held`, and `step-routed` with destination `waiting-human` — that string is a run/step STATUS, not an event kind, so filtering events on it returns nothing; `lease-reaped` behind the holds — query with `--all-projects` | designed gate vs breach vs held — three different fixes; a hold behind a `lease-reaped` carrying `data.forced` was a relay declaring a dead spawn, not a slow step |
| Attempt pressure | `attempts`, loop ordinals | a step repeatedly at `max_attempts` wants a smaller charter, not a bigger budget |
| Integration health | the store half, from the event feed with `--all-projects`: `step-annotated` per write-class step recorded (one integration each; its payload cannot tell a verbatim pick from a hand-resolved one), `dispatch-closed` whose `reason` is not `reconciled` (an override such as `--skip-integration-check`), `loop-entered` ordinals and `step-routed` with detail `fix-loop` (rounds per issue), `lease-reaped`, `claim-refused` and `dispatch-close-refused` per CONFLICT refusal (a missing-capability refusal writes none), and `step-deferred` (`data.cause` `budget` or `chain`; a `chain` fact is either engine-recorded at dispatch close, with `data.source` `engine`, or conductor-filed, and the two count as one set, since the engine returns its own record instead of writing a second) and `vote-reseated` where the conductor recorded them with `docket run fact add`. The conversation half: cherry-pick conflicts resolved by hand, `parked-base-ancestry`, and any deferral or re-seat the conductor did not record reach only the conversation that drove the wave, as the `coordination` section docket-workflow.js computes and returns from each wave; its `reseats` counts judges re-spawned after a missing cast (docket-workflow.js runGate), not re-seat casts that landed | an issue repeatedly reaching `fix@3`, or parking on ancestry, means parallel writers collide on the same files: serialize those lanes or split the charter, not a bigger budget; a first-pass gate pass rate falling across runs while spend holds is the review stage catching what implement should; a store-only retro sees the store half alone and says so instead of reporting a clean row |
| Trust drift | `trust-added`/`trust-removed` (store-level; query with `--all-projects` — visible either way, but only that flag proves you saw all of them) | **an entry the operator does not recognize is a finding, and you raise it first** |
| Config churn | your own proposals per run over time | churn trending up is a candidate signal that docket-bootstrap mined the repo wrong; confirm it from the churning proposals' common origin, then fix the source, not each symptom |
| Routing drift | both pairs from step rows: `model_requested` / `effort_requested` and `model_resolved` / `effort_resolved` (below). The resolved pair is the served model and effort the wave annotates from the step's transcript; where a row still carries `unknown` (every row from 2026-09-05 until the annotate path was repaired), run docket-workflow-usage.js's back-fill over the window before reading the row, and say which rows it could not fill | a served pair that differs from the requested one means policy asks for a model or effort it does not get; a row left `unknown` after the back-fill is a gap in the row, never a clean row |
| Vote calibration | `vote_rule` outcomes vs the threshold | a rule that never fails, or always fails, is a threshold not doing work |
| Seat calibration | per cast, from `docket vote show <proposal>` (the proposal per vote step is on `run report`'s step `vote`): `confidence`, `domain_relevance`, `effective_weight` (their product), `verdict`. Investigation depth is the `tool_uses` unit the seats-mode docket-workflow-usage.js join back-fills per seat: `run report`'s `vote_usage` shows it summed per run only, and the per-seat rows reach only the conversation that drove the panel, like the serving model above. The later outcome is the same issue's later trail, with `--all-projects`: `step-routed` with detail `fix-loop` or `waiting-human`, a `fix-round` resolution, a `review-gap` issue filed against it | a seat whose confidence stays high while its tool use stays near zero, or whose approvals precede a later park or fix round on the same item, is mis-calibrated: **inferred** until about five runs carry the pattern, never observed from one. Operator-facing only: never fed back into a seat's brief, and never a tally input |
| Variant fit | `[executors]` rows vs attempts + cost at that variant | a row failing repeatedly at its variant is mis-sized, not under-budgeted |
| Family decorrelation | a seat whose `[executors]` row stands on a second model family while the rest of its panel stands on one (the `changelogs/policy.md` entry that moved it says so and names the baseline): its sole-finder clusters per reconciled round, the clusters whose `member_sources` on the synthesize step's findings-cluster payload all trace to that seat's review step (the step row's `executor` names the seat; the `producer` ordinal alone does not), plus findings per review, and for a vote seat its lone-rejecter casts from `docket vote show`; partition by the step row's `model_requested` so a reap re-run that walked onto the panel's family is read apart | the seat's sole-finder rate holding or rising against the baseline means the lens carried its value and the second family came free; a fall is the model or its tier (that changelog entry names the documented confound), not a verdict on mixing families; how often the seat's findings or cast matched the rest of the panel is not evidence either way while the other seats share a model, and stays out of the proposal |
| Review-yield | output tokens per stage (review vs implement vs verify, from `metadata`/`budget`); distinct clusters the review stage found; distinct issues `drain-highs` filed, post-dedupe; how many of those routed to a fix round; how many prior runs' `review-gap` issues (`docket issue list --label review-gap --json`) have since closed | review spend far exceeding implement's own, or a low post-dedupe filed-to-found ratio, means the stage is expensive relative to what survives it; a flat or falling closed count across runs means filed `review-gap` backlog is accumulating unworked |

Label every claim by what it rests on: a count from the report is observed, a
pattern across five runs is inferred. Say which one you have.

### Further surfaces you may propose edits to

These surfaces are also yours to propose edits against, through the same
mechanism as everything else: evidence, proposal, approval, filing.

**`policy.toml`'s tables.** Pinned, not registered, so an edit needs no
version bump, but the filed issue says to note it, because the next
docket-retro attributes what followed to it.

| Table | A finding that touches it |
|---|---|
| `[variants]` | a variant's {model, effort} consistently over- or under-serving its rows; an `escalate_to` hop that lands wrong |
| `[executors]` | a hint mis-sized; a row orphaned by a deleted workflow; a hint with no row |
| `[security]` | security-labelled work landing on an unpinned row — widen `nodes` or `labels` |
| `[escalation]` | `one-hop` under- or over-shooting; a `fable_gates` entry that never fires |

Two invariants any `[executors]` proposal must preserve: every hint has
exactly one row, and every row is reachable from some hint. The wave
refuses to route otherwise. A proposal that deletes a workflow must delete
the rows it orphans in the same change.

**Vote-rule thresholds.** These live in engine config, not in either config
root:

```bash
docket config set vote.rule.<name>.threshold <0-1>            # this project
docket config set --global vote.rule.<name>.threshold <0-1>   # every project
```

A rule exists iff its threshold is set, and a threshold sized from one
repo's runs belongs on that project's override; use `--global` only for a
default every project should inherit. Thresholds are store state, not
shipped config: the corpus sets none, so a fresh or reset store has none
either, and a corpus workflow naming a rule (today `tribunal`,
`security-acceptance`, and `doc-acceptance`) fails `docket workflow lint`
with `vote_rule "<name>" is not registered` until the `config set` above
runs. Read `docket config get vote.rule.<name>.threshold` before assuming a
rule exists; empty means the job is creating it, not calibrating it. A rule
whose outcome never differs from a plain human gate is a rule to question,
not tune. A threshold lives in the store, not in a file, so the issue names
the workflow file that declares the rule as its `-f` path and carries the
approved `config set` command, the evidence, and the `config get` result in
its body (§4); a worker or the operator runs the command.

**The four metadata keys.** Every completed step carries
`model_requested` / `effort_requested`, set at routing, and
`model_resolved` / `effort_resolved`, annotated from the transcript's
assistant turns (`message.model` and the top-level `effort`); a row
reading `unknown` is one the annotate path missed, which usage_join.sh
back-fills from the transcript. Read them off the
step itself (`docket step show` /
`step context`): `run report`'s `metadata` is a rollup of key to distinct
values with counts, so it shows aggregate skew but never which step asked
for what. A failed or crashed step contributes none of the four keys;
measure drift from usage_join.sh's serving-models lines in the driving conversation, or state
that it was not measured. Read attempt counts alongside.

**Lease and duration limits, if steps are being reaped mid-work.** Liveness
combines TTL and heartbeat: `step heartbeat` extends a live claim, `step
reap STEP-N --reason R` is the token-free channel for a relay that watched
its executor die, and `[limits]` classes take `{max, lease_ttl,
max_step_duration}`. Read the reaps apart (query events with
`--all-projects`, since the reaped run may have been driven from another
project's cwd). An expiry, or a step completing against a lease it no
longer holds, means `lease.ttl.<class>` is sized below real step duration;
propose the observed worst case plus headroom. Name the class the way the
step does: a class is the step's `class` field and it defaults to the
executor name, which is why these workflows' `[limits]` tables read
`"judge-architecture"`, `"verify-ac"`, `"synthesize-findings"`, and
`"write"` only because the writer steps declare it. A proposal for
`lease.ttl.read` binds nothing here; the key that covers those steps is
`lease.ttl.default`, or the executor's own name. `config set` warns when a
class no registered workflow declares, so check the warning rather than
assuming the write took. A `data.forced` reap is a dead spawn, a relay
finding rather than a config one. Heartbeating cannot carry a step past its
class's `max_step_duration`, measured from the claim: a healthy holder
reaped there wants a smaller charter or a bigger ceiling, not a TTL. A
`lease.ttl.<class>` change is store state like a threshold, so it is filed
with the approved `config set` command in the body and the workflow file
that declares the class as `-f` (§4); for `lease.ttl.default`, which no
workflow declares, `-f` is a workflow whose steps fall to it, and the body
says so. A rule or class declared in a repo's `.docket/config` files in that
repo instead. A `[limits]` edit in a workflow file is filed like any other
workflow edit.

## 3. Propose

Proposals go to a three-judge panel of agents. Compose the batch first — one
proposal per finding, ranked by evidence strength; stop at the ones you can
defend — and give every one of them, before anything is filed:

- what the evidence says, with the numbers and the run IDs it came from
- the edit, as a diff against the current file, drafted in a scratch copy of
  the target tree under `$TMPDIR`; the checkout is never edited. A
  store-state item (threshold, lease TTL, deprecation) gives the exact
  command and its before-state (`docket config get`, or `docket workflow
  list --deprecated` for a deprecation) instead
- at least one alternative edit that answers the same evidence, including
  one that is not the corpus's habitual shape, and the reason the proposed
  edit won on correctness, locality of reasoning, deletability, and upkeep
- the version bump it carries (none for store state)
- for a workflow edit, the clean `docket workflow lint <file.toml>` result on
  the scratch bytes (§4 explains what it proves)
- what it costs if you are wrong

When the session can launch agents, launch the `advisor` agent on the packet before opening
the proposal to the panel.

The proposal packet may cite run IDs: the panel is deciding now, against a
store that still holds them. The diff may not: whatever comment or
rationale lands in the file is read years later by someone with no run
history, no git log, and no tracker open. A date, timestamp, sha, or issue
id in that comment is a pointer that may already be dead by the time anyone
reads it. Write what was actually found, in plain words, in the comment
itself; the file has to justify itself without you standing next to it.

That packet is the panel's entire input, so it travels to them whole rather
than summarized. Open the proposal from the repo the edits target:

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
  gateKind: "retro-batch", cwd: "<the repo the edits target>"}})
```

By `scriptPath` only and never by name, `args` a real object, each voter
carrying the routing triple looked up from the pinned policy exactly as
docket-run's tribunal launch does (resolved with docket-run's installed
`seat_roster.py`, run by its installed path, never as an inline interpreter
program); the
script reads no files and parses no policy. The path is the installed
`<home>/.claude/workflows/tribunal.js` with `<home>` expanded to a literal
absolute path (the tool expands no `~`), and there is no source-tree
fallback: the tool launches only under the session's cwd or
`permissions.additionalDirectories`, which adds exactly
`~/.claude/workflows`. An absent installed file means the corpus was never
activated here: stop and report it rather than hunting for another copy. The
workflow returns `{voteId, outcome, seatsSpawned, respawns, respawned, replies}`, the
same shape docket-run reads: `replies` lists `{seat, castError}` for each
seat whose cast failed after its retry. Then `docket
vote result <id>`: approved clears the item for filing, and §4 runs
immediately, with no follow-up question about whether to file now or
later. A rejection or a split goes to the operator through the built-in
question tool after the advisor's [question
review](../../references/working-agreement.md#question-review), the
advisor's pick first, labelled "(Recommended)", carrying
every judge's verdict, confidence, and summary verbatim. Only what they
approve is filed.

A docket-retro that proposes nothing because five runs went cleanly is a
correct docket-retro: say so rather than manufacturing work, and convene no
panel to hear it.

Never propose a change that adds manual upkeep for the operator. The answer
is the highest rung of the
[automation ladder](../docket/references/automation.md#the-automation-ladder)
that fits, not a step in someone's routine.

**A trust proposal is the operator's alone, and rides no batch.** Follow
docket-bootstrap's rule — argue `re-runnable`, `tree`, `flaky`, and `stub`
per command, default off, nothing run before approval — and ask it in its own question,
never bundled with config edits the panel already cleared. Trust authorizes
execution; a panel of agents cannot grant that, and a trust row inside a
four-item bundle is approved in one click without being read.

## 4. File what was approved

File only the approved items, whether the panel approved them or the
operator did on escalation. Each approved item, or each coherent batch the
panel cleared together, becomes one Docket issue, created from this
conversation. This skill edits nothing: no write under
`src/user/docket/config` or `.docket/config`, no `just activate`, no commit,
no `docket trust add`, no `docket config set`, no `docket workflow
deprecate`. The worker who lands the issue makes the edit, and the operator
installs it with `just activate`, between runs.

**The corpus lives in the dotfiles checkout, not in the repo.** The engine
reads it from `~/.docket/config`, a content-addressed store path replaced
wholesale by `just activate`, so an edit there is silently reverted by the
next install. The issue's remedy path is under `src/user/docket/config/`
(`contracts/`, `fragments/`, `schemas/`, `workflows/`, `policy.toml`). Every
repo sharing the corpus reads the same bytes, so an unbumped edit refuses the
next activation everywhere, not just here. Say that blast radius in the
issue.

A repo may also carry an optional second layer of its own in
`.docket/config/`; repos have none by default, and only that repo reads
it. An addition there that collides with a shared `name@version`, or a
pinned ref, refuses every activation in its own repo until one side moves:
the issue says whether to bump the shared version or rename the addition,
and why.

**Route by owner.** Shared-corpus edits belong to the dotfiles project,
`.docket/config` additions to the repo that carries them, and engine
findings to the engine project (§5). Create from the owning checkout, since
cwd picks the project; never create in the launch repo intending to move the
issue afterward. Resolve the checkout and its store the way docket-postmortem's
[route by owner and store](../docket-postmortem/references/filing.md#route-by-owner-and-store)
requires. A store-state item files in the dotfiles project, which
owns the workflow file that declares the rule or class and so supplies a
valid `-f` path (for `lease.ttl.default`, a workflow whose steps fall to
it); a rule, class or workflow declared in a repo's `.docket/config` files in that
repo instead. Its body names the target project and the directory to run
the command from, or says `--global` when the setting is meant for every
project. If the owning project is
unavailable, hold the item and name the prerequisite in the report.

**Deduplicate first**, per docket-postmortem's
[deduplicate before creating](../docket-postmortem/references/filing.md#deduplicate-before-creating)
section as written. The dedupe set is every issue carrying the
`retro-proposal` label in any status, open and done, so a closed match is
visible. Listing is cwd-scoped, so run it from each owning checkout the
items route to and take the union, one output file per owner:

```bash
docket issue list --all --json=v2 --limit 1000 -l retro-proposal > "$TMPDIR/retro-proposals-<owner>.json"
jq '.data.truncated' "$TMPDIR/retro-proposals-<owner>.json"   # must print false for every owner
```

Hold filing if `truncated` prints anything but `false`: a partial set would
re-file a settled proposal. Match each item to the set by its `Retro
fingerprint:` line, then by semantic comparison of the change. By match
state:

- **Open** (any status short of `done`): the new evidence window goes to it
  as a comment instead of a second issue.
- **Closed with the `wont-do` label** (the operator declined it): file
  nothing, record that issue's id, and name it in the report.
- **Closed without `wont-do`** (landed): file a new issue only when the new
  runs confirm the change is still needed, which is a regression. Link the
  prior issue id in the description and follow the project's reopen or
  new-regression convention. Otherwise file nothing.

**The filing contract** is docket-postmortem's
[worker-ready issue contract](../docket-postmortem/references/filing.md#worker-ready-issue-contract)
with these substitutions:

- Label `retro-proposal`. It is not `retro`, which the workflows' `unless_labels`
  lists already use to mean something else. No routing label, no size label,
  no assignee, no parent, no status beyond the default; `docket-groom` routes
  it.
- Type `task`, or `bug` when the evidence shows a shipped definition
  breaching its own contract. Priority: a measured breach or a recurring
  operator touch that is automatable `high`, a calibration `medium`, a tidy
  `low`; `critical` never, since a retro finds patterns, not live harm.
- `--size` from the docket skill's [sizing reference](../docket/references/sizing.md),
  measured on the issue as stored. A batch whose acceptance describes two or
  more independent outcomes is filed as one issue per outcome, even when the
  panel cleared it as one batch. A redesign of a workflow, contract, or
  schema is `needs-design` and names `docket-refit` as the route; a
  well-scoped bump or threshold-in-file edit is `small` or `bounded`.
- `-f` names each remedy path, `--scope` bounds the work, both never
  omitted. A store-state item names the file that declares the rule
  or class, per Route by owner above (see store state below); trust is the one item never filed.
- `--idempotency-key` is `<owning project>/<surface>/<change>/<window end>`,
  so a retried create cannot duplicate the issue. The description's
  `Retro fingerprint:` line carries the same identity without the window end,
  for lookup across retros. A create that repeats a key returns the original
  issue, closed or not, so a regression filing never reuses the prior key:
  append `/after-<prior issue id>` to it, which differs from the
  landed issue's key even when the window end repeats.

```bash
docket issue create --json=v2 -t "<behavior and consequence, one line>" \
  -T <task|bug> -p <high|medium|low> -l retro-proposal \
  --size <trivial|small|bounded|needs-design> \
  -f <remedy path> [-f <remedy path>] --scope '<glob bounding the work>' \
  --idempotency-key '<key>' -d - <<'RETRO_PROPOSAL'
<description as below>
RETRO_PROPOSAL
```

The description follows this structure:

```text
[Only when the remedy touches authn/authz, secrets, crypto,
sandbox/permissions, a trust boundary, supply chain, or untrusted input at
a privilege boundary, as the first line:] Security gate required: this
remedy touches <the relevant categories>.

Observed: what the runs showed, with the numbers and run IDs, each labelled
  observed or inferred; the evidence window.
Proposal: the approved diff, verbatim, with the comment text the file will
  carry (plain words, no date, sha, or issue id).
Alternative considered: the alternative edit and why this one won.
Panel: the vote proposal id, the outcome, and each judge's verdict; or the
  operator's decision on an escalation.
Versioning: the bump the worker must make: a workflow edit bumps
  [pipeline].version and adds the top entry of changelogs/<name>.md; a schema
  edit is a new schemas/<name>@N+1.json plus a bump to every workflow naming
  it; a contract or fragment body edit bumps its front-matter version in the
  same commit; a policy.toml edit adds the changelogs/policy.md entry.
  Registered bytes at an unchanged name@version refuse the next activation
  in every repo sharing the corpus.
Lint: the clean `docket workflow lint` result on the scratch bytes, for a
  workflow edit.
Automation: the ladder rung, and why no higher rung can carry it; for a
  human touch, the vital condition it rests on.
Cost if wrong: the blast radius and the rollback (a version bump rolls back
  by retiring the bad version, which the operator or docket-reconcile does).
Acceptance: `docket workflow lint` on every edited workflow, `just
  frozen-drift-check`, `just crossref-check`, and the named tests, each with
  the failing variant it rejects; or read-verified with what to inspect.
  Store state: `docket config get <key>` (or `docket workflow list
  --deprecated`) shows the new value, with the old value as the failing
  variant; for a newly created rule, `docket workflow lint` of the declaring
  workflow also passes where it failed before.
Command (store state only, replacing Proposal, Versioning and Lint): the
  exact `docket config set` or `docket workflow deprecate` command, the
  project and directory it runs from, and `--global` where intended.
After activation (operator): once `just activate` has run, `docket run
  activate RUN-M --dry-run` against a run still in planning shows the new
  version registering and every fence still matched. Re-activating an
  already-active run inherits its original pin set, so use a throwaway
  planning run.
Retro fingerprint: <owning project>/<surface>/<change>.
```

Read each receipt back through `docket issue show` and verify the id, title,
files, labels, and empty assignee, per the contract. Keep the filing ledger
in scratch so partial progress survives interruption.

**What lint proves.** `docket workflow lint <file.toml>` on the scratch bytes,
run before the proposal reaches the panel, runs the exact validation
`register` runs and writes nothing. It returns `CONFLICT` when the edit sits
on a frozen `name@version` with the bump missing. It proves nothing about
installed bytes: activation reads the config roots (`~/.docket/config`, then a
repo's `.docket/config` if it has one) and never the dotfiles checkout, so
only the post-activation dry-run above proves registration, and the operator
runs it.

**Trust is handed over; store state is filed, never run here.** Trust the
operator approved goes in only when the operator runs `! docket trust add
<name> --yes -- <argv>` themselves: the sandbox refuses any session write to
the trust store, so hand them the exact command and file nothing. A
vote-rule threshold or a `lease.ttl.<class>` limit is store state with no
source file of its own, so the issue's `-f` path is the file that declares
the rule or class, as in Route by owner (related to the change, never an unrelated path
supplied to satisfy `-f`), and its body carries the exact `docket config set` command, the
evidence, and the `docket config get` result before it. This session runs
none of them. The §5 report lists trust as handed over and store state as
filed.

**Retiring a version.** Binding reduces each name to its highest
*non-retired* version before `[match]` runs, so a bump rolls out on its
own. To fall back beneath a bad version, or take a mistakenly registered
name out of routing altogether, the version is retired with `docket workflow
deprecate <name>@<version>`, reversed by `--restore` (retirement semantics:
see docket-reconcile's Step 2, DEPRECATE/RESTORE). That is a registry write
docket-reconcile plans, so a proposal that needs it is filed like any other
store state: the exact command in the body, the workflow's file as `-f`, and
docket-reconcile named as the route. No delete verb
exists, and renaming a pipeline still loses the version lineage pinning
preserves.

## 5. Close

Say that nothing was applied. Report which proposals were approved and by
which authority (the panel, or the operator on an escalation), the issue id
each was filed under or the existing issue that received its evidence, which
were held and why, which trust commands were handed to the operator, and which
were declined. Name what the next docket-retro should
watch: a filed proposal that has not landed yet, since the next retro
attributes what followed a change only after the change is in the corpus, so
check each filed issue's status before reading later runs against it. A
declined proposal with accumulating evidence is the first thing to re-raise,
and a panel that split is worth naming as such: the disagreement is evidence
about the proposal. Filed issues drain through `docket-groom` routing into a
`docket-plan` and `docket-run` execution, or through `docket-refit` for a
redesign; do not start that work.

A finding that belongs upstream (an engine limitation, a design deviation)
gets filed as an issue, not bent into config, and filed in its owning project:
engine findings from the docket repo's checkout, definition findings from the
dotfiles checkout (cwd picks the project), never into whichever project this
docket-retro read its runs from. `docket issue move <id> --project <target>`
re-homes one that already landed wrong.
