---
name: docket-retro
description: >-
  Use on the operator's request only, after about five completed runs:
  "retro", "what did the runs cost", "evolve the corpus from the runs". Reads
  the runs made on the corpus now in force, measures what they cost and
  caught, and turns that into versioned edits to the shared docket corpus,
  store settings, and a repo's optional .docket/config additions; files each
  panel-approved proposal as a Docket issue and hands approved trust over as
  a command. Defects it meets go to their owners as referrals. Edits nothing
  itself. Distinct from docket-postmortem, which audits one run's defects.
argument-hint: "[runs to read, e.g. RUN-12 RUN-15; default: the current cohort, the runs on the workflow versions now in force, plus its baseline]"
---

# docket-retro

You calibrate the corpus from what its runs did. The product is a short list
of corpus changes, each backed by counts from several runs, each cleared by a
panel before it is filed. A retro that ends with defect tickets and no
corpus proposal has done docket-postmortem's job at higher cost; check for
that before you close (§3).

Your outputs, in order of value:

1. **Corpus and store proposals**: workflow, schema, policy, contract,
   fragment, threshold, and lease edits. Panel-approved, then filed (§3, §4).
2. **Trust items**: the operator's alone, asked in one question, handed over
   as a command (§3).
3. **Referrals**: defects and decisions that belong to another owner, listed
   in the report and filed only under §5's rule.

**Never run automatically.** The operator invokes you. After roughly five
completed runs a session may say "five runs since the last docket-retro,
worth one?" and stop there. A nudge is a sentence, not an execution.

**You edit nothing.** No write under `src/user/docket/config` or
`.docket/config`, no `just activate`, no commit, no `docket trust add`, no
`docket config set`, no `docket workflow deprecate`. A filed issue carries
the approved diff, or for store state the approved command, to the worker
who lands it. Approved trust is the one item not filed: the operator runs
its command. Your only writes are tracker records: issues and comments
under §4 and §5, the panel's vote under §3, and the report document under
§6.

**Never propose editing a registered file in place.** Changed bytes at an
unchanged `name@version` refuse the whole next activation. Every workflow
edit bumps `[pipeline].version`; every schema edit is a new
`name@N+1.json`. Every file-edit proposal and its issue carries its bump;
store state has no file and carries none.

**Automation first.** Each proposal sits on the highest rung of the docket
skill's [automation ladder](../docket/references/automation.md#the-automation-ladder)
that can carry it, and keeps or adds a human touch only under a named
[vital condition](../docket/references/automation.md#when-a-human-is-vital).
An automatable operator touch that recurs across runs is a proposal in its
own right. Never propose a change that adds manual upkeep for the operator.

Run in the invoking conversation: §1 seats analysts through `Workflow` and
§3 asks through `AskUserQuestion`, and a forked subagent has neither; a fork
returns its open questions to its caller. Assume nothing was read for you
and gather through §1 every time, from `$ARGUMENTS`.

**Done-state.** The retro is done when the §6 report has been delivered as
one message after the last write, with every section filled. A held item
with no operator decision is a complete outcome. A run still active or
waiting on a human is listed outside the window and does not block
completion. Invoke the skill
directly. When a `/goal` wraps it, the condition is this paragraph's
done-state, never the bare skill name: an evaluator that reads only the name
infers its own requirements and rejects a finished retro.

## Scope: the cohort window

The unit is a run, not a file, so there is no path argument. Read the runs
whose evidence can still change the corpus:

Classify each terminal run by its `run report` `pinned_workflows[]`, where
`behind` counts the registered versions strictly above the pinned one and
`current_version` is the registry at report time. Do not subtract
`pinned_version` from `current_version`: versions need not be contiguous,
and a retired higher version makes the difference wrong. A retired or
deleted workflow reads `behind: 0` with `current_version: 0`, so every
rule below also requires `current_version > 0`.

- **Current cohort.** Every pinned workflow has `behind == 0` and
  `current_version > 0`: the run used the workflow versions still in
  force. These runs are the evidence for a proposal.
- **Baseline cohort.** Every pinned workflow has `behind` of 0 or 1 and
  `current_version > 0`, with at least one at 1. It answers "did the last change help?" and supplies the
  before-side of a comparison. When the current cohort has under five runs,
  as it will right after a bump, the baseline joins it as the primary
  window and the report says so.
- **Outside the window.** Every older run, every run pinned to a deleted
  workflow, and every run with no pinned workflow. List the count by workflow version in the report. Do
  not analyse them: a proposal drawn from a retired version repairs a
  corpus that no longer exists.

`pinned_workflows` tracks workflows only. Policy, contract, and fragment
bumps are invisible to it, so the report names the `policy.toml` version
in force at the window's first and last run (`changelogs/policy.md`)
instead of claiming the cohort ran one configuration.

The cohort rule governs the window. The newest `retro-report` document
(§6) is an advisory pointer: it shows where the last retro read up to and
which `retro-input` documents it consumed, even when it filed nothing. Read
it from the dotfiles checkout, since documents are project-scoped:

```bash
docket doc list -T retro-report --sort created_at:desc --limit 1 --with-body --json=v2
```

Never drop a current-cohort run because a prior retro read it: until its
proposals land, it is still the evidence for today's corpus. Trust drift and config churn
stay store-wide whatever the cohort. A run still active or waiting on a
human is outside the window and named as such; it never holds the retro
open.

`$ARGUMENTS` only narrows: run ids limit the window to those runs, and the
report names what was left outside. Nothing inside the window is skipped: a
run whose report or events cannot be read is a coverage gap, never a clean
run.

## 1. Gather

Build the cohort yourself before seating anyone. List terminal runs
store-wide from the event log, since `docket run status` is cwd-scoped and
sees one project:

```bash
docket events list --json --all-projects --kind run-done --limit 100000
docket events list --json --all-projects --kind run-abandoned --limit 100000
```

Check that each `data.total` equals the length of its `data.events`. Then
read one `docket run report RUN-N --json` per terminal run, which resolves
a run wherever it lives, keep the reports in scratch, and classify each by
`pinned_version` against `current_version` per Scope. This is cheap and
decides what the analysts read.

Seat analysts by evidence row, not by time slice, so each analyst sees the
whole cohort for its rows and a pattern that recurs across runs lands in
one report instead of several. Default groups:

| Analyst | §2 rows |
|---|---|
| Spend | Where does spend go, Review-yield, Variant fit, Attempt pressure |
| Gates and touches | Gate health, Intervention profile, Integration health |
| Panels and routing | Judge value, Dedup rate, Vote calibration, Seat calibration, Family decorrelation, Routing drift |
| Trust and churn | Trust drift, Config churn, Recurring shapes |

Merge groups for a cohort under ten runs; split one only when its runs
exceed what one analyst can read. Each analyst re-reads every cohort
report, which is the accepted cost of seeing a pattern whole. The Trust and
churn analyst reads store-wide and reports first. Brief each with the corpus contract
`~/.docket/config/contracts/retro-analyst.md` (source:
`src/user/docket/config/contracts/retro-analyst.md`), its §2 rows verbatim,
the cohort and baseline run lists, and this instruction: **a directly
observed count that bears on a row is a finding, not a gap**; a gap names
only what could not be read.

`retro-analyst` carries no `policy.toml` row and no workflow dispatches it,
so seat each through
`Workflow({scriptPath: "<home>/.claude/workflows/retro-seat.js", args: {
analysts: [{brief, model, effort}, ...]}})` (source:
`src/user/claude_code/workflows/retro-seat.js`), with `<home>` expanded to a
literal absolute path and `model` and `effort` set explicitly. It returns
`{reports, seated, returned}`: one entry per analyst, in order, each
`{window, coverage, findings, gaps}` (a finding is `{kind, row, title, runs,
body}`, `kind` `config-proposal` or `issue-to-file`; a gap is `{row,
available, observed, blocked, missing}`), or `null` for a seat that
returned nothing. A `null` is a coverage gap for that analyst's rows.

The verbs, for their briefs:

```bash
docket run report RUN-N --json                        # per run; read-only, never advances a run
docket events list --run RUN-N --json --all-projects  # the transition trail
docket events list --json --limit 500 --all-projects  # recent feed; trust grants live here
docket events list --json --all-projects              # every project sharing the store
docket step artifacts STEP-N --json                   # one step's artifact index
docket step artifact <id> --json                      # one artifact's body; the report indexes only
docket vote show <proposal> --json                    # per-cast confidence, verdict, usage
docket report executors --all-projects --since RUN-N --json=v2  # per-executor and per-voter rollup
```

`docket report executors` rolls up, per executor hint, steps, `fix-loop`
routes, override passes, reaps, forced reaps, and unique, corroborated, and
held clusters; per voter name, casts by verdict and what followed them. It
feeds Judge value, Integration health, and Seat and Vote calibration, not
Attempt pressure, which it does not carry. `--since` is an id range, not
the cohort, so its counts include runs outside the window: treat them as a
store-wide signal and confirm any proposal from cohort run reports. Its
per-voter rows are operator-facing only: they never enter an analyst's
proposal text or the §3 packet, since the panel's own seats may be the
names measured.

**Postmortem referrals.** docket-postmortem records each instance-policy
referral as a `retro-input` document in the dotfiles project. Read every
one created after the newest `retro-report`, or not named as consumed in
it, and pass each to the analyst whose rows it touches:

```bash
docket doc list -T retro-input --sort created_at:asc --limit 1000 --with-body --json=v2
```

The events store is machine-global but `events list` is cwd-scoped by
default, so pass `--all-projects` on every `docket events list` call; the
other verbs do not take the flag. Every docket verb opens the store
read-write and migrates forward: check the store path against the sandbox
write allowlist rather than assuming an unsandboxed shell. Where it is not
writable, `sqlite3 'file:<store>/issues.db?immutable=1'` is the read-only
fallback.

## 2. Read the evidence

| Question | Where | What a finding looks like |
|---|---|---|
| Where does spend go? | `budget`: `floor` vs `reported[]` (per unit, never summed; `budget_unit` names the counted one), `spend` = max of the two, `cap` + `cap_source`, `burn_rate`, `breach_reason` (`attempts` is its own top-level section, not a budget field); `step_usage` per stage | one step carries most of the floor, or `reported` dwarfs `floor` → `expected_cost` miscalibrated; a `breach_reason` under `cap_source: config` means the run met a default nobody sized for it |
| Judge value | `artifacts` grouped by `executor` (+`issue`); `producer` is the fanout ordinal (`review@0#2`), which says where in the topology, never who; bodies from `step artifact` | a judge that never uniquely contributes above `low` across 5 runs → cut it in a version bump |
| Dedup rate | duplicate findings across a fanout's artifacts, read with `step artifacts` then `step artifact` | under 10% at width ≤ 4 across 5 runs → propose exact-locus dedup instead of `synthesize-findings` |
| Recurring shapes | the same topology planned ≥ 3 times | migrate it into a workflow template |
| Gate health | `gates` pass/fail/**unmatched**, `gate_trail` (its `output` rides non-pass rows only, last 2000 bytes) | read each `unmatched` row's reason: a missing entry for this repo is a trust finding; an entry bound to another repo, or a refusal because the worktree is gone, is not. A gate failing a large share of evaluations on one cause (a formatter diff, a missing service) is a corpus finding: the step before the gate should prevent it |
| Intervention profile | `run-paused`, `step-held`, and `step-routed` with destination `waiting-human` (a status string, not an event kind); `lease-reaped` behind the holds | designed gate vs breach vs held: three different fixes; a hold behind a `lease-reaped` carrying `data.forced` was a relay declaring a dead spawn |
| Attempt pressure | `attempts`, loop ordinals | a step repeatedly at `max_attempts` wants a smaller charter, not a bigger budget |
| Integration health | store half from `events list --all-projects`: `step-annotated`, `dispatch-closed` whose `reason` is not `reconciled` (an override such as `--skip-integration-check`), `loop-entered` and `step-routed` detail `fix-loop`, `lease-reaped`, `claim-refused` and `dispatch-close-refused` per CONFLICT refusal (a missing-capability refusal writes none), `step-deferred` (`data.cause` `budget` or `chain`; engine- and conductor-recorded `chain` facts are one set), `vote-reseated`. The conversation half (hand-resolved cherry-picks, `parked-base-ancestry`, unrecorded deferrals and re-seats) reaches only the wave's returned `coordination` section, whose `reseats` counts judges re-spawned after a missing cast, not landed re-seat casts | an issue repeatedly reaching `fix@3`, or parking on ancestry, means parallel writers collide: serialize those lanes or split the charter; a first-pass gate pass rate falling while spend holds means review is catching what implement should; a store-only read says so instead of reporting a clean row |
| Trust drift | `trust-added`/`trust-removed` with `--all-projects`; live entries with no event | **an entry the operator does not recognize is a finding, raised first**; a missing record is a gap, not proof |
| Config churn | prior `retro-proposal` issues per window (never `retro-referral`) | churn trending up is a candidate signal that docket-bootstrap mined the repo wrong; confirm from the churning proposals' common origin |
| Routing drift | step rows: `model_requested`/`effort_requested` vs `model_resolved`/`effort_resolved` | a served pair differing from the requested one means policy asks for what it does not get; an `unknown` row or a failed or crashed step is unmeasured, never clean |
| Vote calibration | `vote_rule` outcomes vs the threshold | a rule that never fails, or always fails, is a threshold not doing work |
| Seat calibration | per cast from `docket vote show`: `confidence`, `domain_relevance`, `effective_weight`, `verdict`, `usage.tool_uses` with `usage_source`; later outcome from the issue's trail (`fix-loop`, `waiting-human`, `review-gap`) | confidence that stays high while tool use stays near zero, or approvals that precede a later park or fix round, is mis-calibration: inferred until about five runs carry it. A cast carrying no `usage` is unmeasured, not zero depth. Operator-facing only: never fed back into a seat's brief, and never a tally input |
| Variant fit | `[executors]` rows vs attempts and cost at that variant | a row failing repeatedly at its variant is mis-sized, not under-budgeted |
| Family decorrelation | a seat on a second model family while its panel stands on one (its `changelogs/policy.md` entry names the baseline): sole-finder clusters whose `member_sources` all trace to that seat's review step, findings per review, lone-rejecter casts; partition by `model_requested` so a reap re-run that walked onto the panel's family is read apart | a holding or rising sole-finder rate means the second family came free; a fall is the model or tier, not a verdict on mixing families; how often the seat matched the rest of the panel is not evidence either way while the other seats share a model, and stays out of the proposal |
| Review-yield | output tokens per stage (review, implement, verify); distinct clusters found; distinct issues `drain-highs` filed, post-dedupe; how many routed to a fix round; how many prior `review-gap` issues have closed (`docket issue list --label review-gap --json`) | review spend far exceeding implement's, or a low filed-to-found ratio, means the stage costs more than what survives it; a flat closed count means `review-gap` backlog accumulates unworked |

Label every claim by what it rests on: a count from the report is observed,
a pattern across five runs is inferred. A directly observed rate over the
cohort (45 of 127 gate evaluations failing on one cause) is observed, and
it supports a proposal on its own.

### Further surfaces

**`policy.toml`'s tables.** Pinned, not registered: no version bump, but the
issue says to note the change, because the next retro attributes what
followed to it.

| Table | A finding that touches it |
|---|---|
| `[variants]` | a variant's {model, effort} consistently over- or under-serving its rows; an `escalate_to` hop that lands wrong |
| `[executors]` | a hint mis-sized; a row orphaned by a deleted workflow; a hint with no row |
| `[security]` | security-labelled work landing on an unpinned row: widen `nodes` or `labels` |
| `[escalation]` | `one-hop` under- or over-shooting; a `fable_gates` entry that never fires |

Every `[executors]` hint keeps exactly one row and every row stays reachable
from some hint, or the wave refuses to route. A proposal that deletes a
workflow deletes the rows it orphans in the same change.

**Vote-rule thresholds** live in engine config as store state:

```bash
docket config set vote.rule.<name>.threshold <0-1>            # this project
docket config set --global vote.rule.<name>.threshold <0-1>   # every project
```

A rule exists iff its threshold is set; a fresh store has none, and a
workflow naming an unset rule fails `docket workflow lint` with `vote_rule
"<name>" is not registered`. Read `docket config get
vote.rule.<name>.threshold` first; empty means the job is creating the
rule, not calibrating it. Size a threshold from one repo's runs on that
project; use `--global` only for a default every project should inherit. A
rule whose outcome never differs from a plain human gate is a rule to
question, not tune.

**Lease and duration limits**, when steps are reaped mid-work. `[limits]`
classes take `{max, lease_ttl, max_step_duration}`; a class is the step's
`class` field and defaults to the executor name, so `lease.ttl.read` binds
nothing and those steps fall to `lease.ttl.default`. An expiry, or a step
completing against a lease it no longer holds, means `lease.ttl.<class>` is
below real step duration: propose the observed worst case plus headroom. A
healthy holder reaped at `max_step_duration` wants a smaller charter or a
bigger ceiling, not a TTL. A `data.forced` reap is a relay finding. `config
set` warns on a class no registered workflow declares; check the warning. A
`lease.ttl.<class>` change is store state like a threshold; a `[limits]`
edit in a workflow file is a workflow edit.

**The four metadata keys.** Read `model_requested`/`effort_requested` and
`model_resolved`/`effort_resolved` off the step (`docket step show`):
`run report`'s `metadata` is a rollup that shows skew but never which step
asked for what.

## 3. Propose

**Compose from findings and gaps.** Read every analyst finding and every
gap. A gap whose `observed` field is not empty carries counts that bear on
its §2 row, and they are evidence: turn it into a proposal when the count alone supports
a change, or into a named measurement gap with the change that would close
it. Zero `config-proposal` findings from the analysts is not, by itself, a
clean retro. Promoting a gap carries the analyst contract's duties with it:
read the current target, check whether a later change already fixed the
condition, and run the design search. Do that here before the packet, or
re-seat one analyst through §1 on that gap alone when it needs evidence you
do not hold.

Rank the batch by evidence strength and stop at the ones you can defend.
Give every proposal, before anything is filed:

- the evidence, with the numbers and the run IDs they came from
- the edit, as a diff drafted in a scratch copy of the target tree under
  `$TMPDIR`; the checkout is never edited. A store-state item (threshold,
  lease TTL, deprecation) gives the exact command and its before-state
  (`docket config get`, or `docket workflow list --deprecated`) instead
- at least one alternative that answers the same evidence, including one
  outside the corpus's habitual shape, and why the proposal won on
  correctness, locality, deletability, and upkeep
- its version bump (none for store state)
- for a workflow edit, the clean `docket workflow lint <file.toml>` result
  on the scratch bytes
- what it costs if you are wrong

The packet carries no per-voter track record from `docket report
executors` or Seat calibration; a Judge value proposal cites cluster counts
only. The packet may cite run IDs; the diff may not. A comment in the file is
read years later by someone with no run history, so it says what was found
in plain words, with no date, sha, or issue id.

When the session can launch agents, launch the `advisor` on the packet
before the panel. Then open the proposal from the repo the edits target
and convene the judges:

```bash
docket vote create -d "<what the batch changes, plainly>" \
  -r "<the evidence: the numbers, the run IDs>" \
  --files-changed "<the config files the batch edits, comma-separated>" \
  -n 3 -c medium --threshold 0.67 --created-by retro
```

```
Workflow({scriptPath: "<home>/.claude/workflows/tribunal.js", args: {
  voteId: "<id>",
  voters: [{seat: "tribunal-architecture", model, effort, variant}, {seat: "tribunal-security", ...}, {seat: "tribunal-correctness", ...}],
  context: "<every proposal with its evidence, its diff, and its bump>",
  gateKind: "retro-batch", cwd: "<the repo the edits target>"}})
```

By `scriptPath` only, `args` a real object, each voter carrying the routing
triple from the pinned policy exactly as docket-run's tribunal launch
resolves it (docket-run's installed `seat_roster.py`, run by its installed
path). `<home>` is a literal absolute path; there is no source-tree
fallback, so an absent installed file means the corpus was never activated
here: stop and report it. The workflow returns `{voteId, outcome,
seatsSpawned, respawns, respawned, replies}`; `replies` lists `{seat,
castError}` per seat whose cast failed after its retry. Then `docket vote
result <id>`: approved clears the item, and §4 runs immediately. A
rejection or a split goes to the operator through `AskUserQuestion` after
the advisor's [question
review](../../references/working-agreement.md#question-review), the
advisor's pick first, carrying every judge's verdict, confidence, and
summary verbatim. Only what the panel or the operator approves is filed.

A retro whose cohort ran cleanly proposes nothing and convenes no panel: say
so rather than manufacturing work. Before you conclude that, confirm the
gaps were mined; a retro whose only output is referrals has to say why the
cohort's counts supported no corpus change.

**A trust proposal is the operator's alone, and rides no batch.** Follow
docket-bootstrap's rule: argue `re-runnable`, `tree`, `flaky`, and `stub`
per command, default off, nothing run before approval. Ask it in its own
question, never bundled with config edits the panel cleared: trust
authorizes execution, a panel of agents cannot grant it, and a trust row in
a bundle is approved without being read. Draft the trust question before
the packet's advisor launch so that launch is its question review. Ask it
once, with each entry's name, repo, and argv in the question and the
advisor's result beside it. For a recognition question that result is "no
pick", since only the operator knows what they added.

## 4. File what was approved

Each approved item, or each coherent batch the panel cleared together,
becomes one Docket issue created from this conversation. The worker who
lands it makes the edit, and the operator installs it with `just activate`
between runs.

**The corpus lives in the dotfiles checkout.** The engine reads
`~/.docket/config`, which `just activate` replaces wholesale, so the remedy
path is under `src/user/docket/config/` (`contracts/`, `fragments/`,
`schemas/`, `workflows/`, `policy.toml`). Every repo sharing the corpus
reads the same bytes, so an unbumped edit refuses the next activation
everywhere; the issue says so. A repo's optional `.docket/config/` layer is
read by that repo alone; an addition there colliding with a shared
`name@version` or pinned ref refuses its activations until one side moves,
and the issue says which side and why.

**Route by owner.** Shared-corpus edits and store-state items file in the
dotfiles project, `.docket/config` additions in the repo that carries them,
engine findings in the engine project. Create from the owning checkout,
since cwd picks the project, resolved per docket-postmortem's [route by
owner and store](../docket-postmortem/references/filing.md#route-by-owner-and-store).
A rule, class, or workflow declared in a repo's `.docket/config` files in
that repo instead, store state included. A store-state item's body names
the target project and directory to run its command from, or `--global`. If the owning project is unavailable, hold
the item and name the prerequisite.

**Deduplicate first**, per docket-postmortem's [deduplicate before
creating](../docket-postmortem/references/filing.md#deduplicate-before-creating).
The set is every `retro-proposal` issue in any status, listed from each
owning checkout:

```bash
docket issue list --all --json=v2 --limit 1000 -l retro-proposal > "$TMPDIR/retro-proposals-<owner>.json"
jq '.data.truncated' "$TMPDIR/retro-proposals-<owner>.json"   # must print false for every owner
```

Hold filing if `truncated` is not `false`. Match by the `Retro
fingerprint:` line, then by the change. Before writing to any existing
issue, whatever its label, read its comment thread (`docket issue comment
list <id>`): an operator ruling there governs, and new evidence that
contradicts it is held and reported, never posted. By match state:

- **Open**: the new evidence goes to it as a comment instead of a second
  issue, unless a ruling on the thread holds it.
- **Closed with `wont-do`**: file nothing; name the issue in the report.
- **Closed without `wont-do`**: file only when the new runs show a
  regression, linking the prior issue and following the project's reopen
  or regression convention.

**The filing contract** is docket-postmortem's [worker-ready issue
contract](../docket-postmortem/references/filing.md#worker-ready-issue-contract)
with these substitutions:

- Label `retro-proposal`, never `retro`, which the workflows'
  `unless_labels` use for something else. No routing label, no size label,
  no assignee, no parent, no status beyond the default; `docket-groom`
  routes it.
- Type `task`, or `bug` when a shipped definition breaches its own
  contract. Priority: a measured breach or a recurring automatable operator
  touch `high`, a calibration `medium`, a tidy `low`; never `critical`.
- `--size` per the docket skill's [sizing reference](../docket/references/sizing.md),
  measured on the issue as stored. A batch with two or more independent
  outcomes files one issue per outcome. A redesign of a workflow, contract,
  or schema is `needs-design` and names `docket-refit` as the route.
- `-f` names each remedy path and `--scope` bounds the work, never omitted.
  A store-state item's `-f` is the file that declares the rule or class
  (for `lease.ttl.default`, a workflow whose steps fall to it), never an
  unrelated path.
- `--idempotency-key` is `<owning project>/<surface>/<change>/<window end>`.
  A regression filing appends `/after-<prior issue id>`, since a repeated
  key returns the original issue.

```bash
docket issue create --json=v2 -t "<behavior and consequence, one line>" \
  -T <task|bug> -p <high|medium|low> -l retro-proposal \
  --size <trivial|small|bounded|needs-design> \
  -f <remedy path> [-f <remedy path>] --scope '<glob bounding the work>' \
  --idempotency-key '<key>' -d - <<'RETRO_PROPOSAL'
<description as below>
RETRO_PROPOSAL
```

```text
[Only when the remedy touches authn/authz, secrets, crypto,
sandbox/permissions, a trust boundary, supply chain, or untrusted input at
a privilege boundary, as the first line:] Security gate required: this
remedy touches <the relevant categories>.

Observed: what the runs showed, with numbers and run IDs, each labelled
  observed or inferred.
Proposal: the approved diff, verbatim, with the comment text the file will
  carry (plain words, no date, sha, or issue id).
Alternative considered: the alternative and why this one won.
Panel: the vote proposal id, the outcome, and each judge's verdict; or the
  operator's decision on an escalation.
Versioning: a workflow edit bumps [pipeline].version and adds the top entry
  of changelogs/<name>.md; a schema edit is a new schemas/<name>@N+1.json
  plus a bump to every workflow naming it; a contract or fragment body edit
  bumps its front-matter version; a policy.toml edit adds the
  changelogs/policy.md entry. Registered bytes at an unchanged name@version
  refuse the next activation in every repo sharing the corpus.
Lint: the clean `docket workflow lint` result on the scratch bytes, for a
  workflow edit.
Automation: the ladder rung, and why no higher rung can carry it; for a
  human touch, the vital condition it rests on.
Cost if wrong: the blast radius and the rollback (retire the bad version,
  which the operator or docket-reconcile does).
Acceptance: `docket workflow lint` on every edited workflow, `just
  frozen-drift-check`, `just crossref-check`, and the named tests, each with
  the failing variant it rejects; or read-verified with what to inspect.
  Store state: `docket config get <key>` (or `docket workflow list
  --deprecated`) shows the new value, the old value as the failing variant;
  for a new rule, `docket workflow lint` of the declaring workflow passes
  where it failed before.
Command (store state only, replacing Proposal, Versioning and Lint): the
  exact `docket config set` or `docket workflow deprecate` command, the
  project and directory it runs from, and `--global` where intended.
After activation (operator): once `just activate` has run, `docket run
  activate RUN-M --dry-run` against a throwaway planning run shows the new
  version registering and every fence matched.
Retro window: <window start run>..<window end run>, <window end date>.
Retro fingerprint: <owning project>/<surface>/<change>.
```

Read each receipt back through `docket issue show` and verify id, title,
files, labels, and empty assignee. Keep the filing ledger in scratch so
partial progress survives interruption.

**What lint proves.** `docket workflow lint` on scratch bytes runs the
validation `register` runs and writes nothing; it returns `CONFLICT` for an
edit on a frozen `name@version` with the bump missing. It proves nothing
about installed bytes: only the post-activation dry-run proves
registration, and the operator runs it.

**Trust is handed over; store state is filed, never run here.** Approved
trust goes in only when the operator runs `! docket trust add <name> --yes
-- <argv>` themselves; the sandbox refuses any session write to the trust
store, so hand them the exact command and file nothing. A threshold or
`lease.ttl.<class>` is filed with its `docket config set` command, the
evidence, and the `docket config get` result in the body. This session runs
none of them.

**Retiring a version.** Binding takes each name's highest non-retired
version, so a bump rolls out on its own. Falling back beneath a bad version
is `docket workflow deprecate <name>@<version>`, reversed by `--restore`, a
registry write docket-reconcile plans: file it as store state with the
workflow's file as `-f` and docket-reconcile as the route. No delete verb
exists, and renaming a pipeline loses the version lineage pinning
preserves.

## 5. Referrals

A defect is not a corpus proposal: a hook that false-denies, a gate script
that ignores its base, an engine limitation. Docket-postmortem owns
single-run defects and files them with full transcripts behind them.
Handle a defect the analysts surface this way:

- **Recurring and file-ready**: seen in three or more cohort runs, owner
  known, dedupe clean. File it in its owning project under §4's contract
  with label `retro-referral` in place of `retro-proposal`, and
  `Panel: none; §5 referral` in place of the panel line, from the owning
  checkout, never into the project the runs were read from. Dedupe against
  the `retro-referral` set the same way. No panel and no question: a defect
  filing changes no corpus and authorizes no work. Cap it at the three
  strongest; list the rest. Referrals never count as config churn.
- **Fewer runs, or owner unresolved**: list it in the report as a referral
  to `/docket-postmortem` on the run that shows it best. File nothing.
- **Needs an operator decision** (it conflicts with a ruling, or the remedy
  is a policy choice): list it as held with the decision it needs. Do not
  ask it mid-retro; a retro question that is not a panel escalation or a
  trust item costs the operator a context switch for no corpus change.
- **Already fixed upstream**: name the closing issue and drop it.

A finding that lands in the wrong project is re-homed with `docket issue
move <id> --project <target>`.

## 6. Close

Write the report once, after every other write of the retro. Record it
first, from the dotfiles checkout, as the retro's last write:

```bash
docket doc create --json=v2 -T retro-report -t "Retro <window end run>, <date>" \
  --idempotency-key 'dotfiles/retro-report/<window end run>/<date>' -d - <<'RETRO_REPORT'
<the report below, plus: Consumed retro-input: <doc ids, or none>>
RETRO_REPORT
```

Then deliver the same report here as one message, naming the document id.
If anything is written after it, re-issue the whole report and record a new
document, never a supplement. Use these sections in this order, each
present even when empty:

1. **Outcome**: one sentence naming the number of corpus proposals filed,
   trust items handed over, and referrals, and that nothing was applied.
2. **Window**: the current and baseline cohorts with run counts, the runs
   outside the window by workflow version, and runs still in progress.
3. **Proposals**: each with its issue id or the existing issue that
   received its evidence, and its authority (panel outcome with vote id, or
   the operator on escalation); each held or declined proposal with its
   reason. A split panel is named as one: the disagreement is evidence.
4. **Trust**: commands handed over, items declined, and items held for the
   operator.
5. **Referrals**: defects filed under §5 with issue ids and idempotency
   keys, referrals to docket-postmortem, held decisions, and items already
   fixed.
6. **Coverage gaps**: what could not be read, and which proposals or rows
   it blocked.
7. **Next retro watches**: each filed proposal not yet landed (judge later
   runs against a change only after it lands, so check each issue's status
   first), declined proposals with accumulating evidence, and the gaps that
   blocked a proposal.

Filed proposals drain through `docket-groom` into `docket-plan` and
`docket-run`, or through `docket-refit` for a redesign; do not start that
work.
