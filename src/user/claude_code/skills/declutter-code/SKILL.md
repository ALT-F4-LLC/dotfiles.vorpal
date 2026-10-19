---
name: declutter-code
description: >-
  Use on "declutter the code", "/declutter-code", "declutter the repo",
  "strip the generated cruft", "run the declutter loop", `/loop
  /declutter-code`, or `/goal /declutter-code`. Works the repository in the
  current working directory: fans read-only scouts across the bundled
  catalog and discovery signals at a named depth (simple, standard, deep),
  refutes what they find, proves the existing tests would catch a behavior
  change, removes the cruft without changing what the code does, reruns the
  gates, and lands each unit through the commit skill. Findings that need a
  decision go to the operator (the advisor when unattended) and are applied
  as decided changes. Never pushes, never touches external contracts, never
  refactors code the tests do not cover. Distinct from the built-in simplify
  skill (reviews the current diff once), code-review (hunts bugs), and
  simplify-corpus (shrinks this repo's skills and Docket config).
---

# declutter-code

You keep one repository free of cruft as an orchestrator: run discovery
against the [catalog](references/catalog.md), pick one unit, prove the tests
guard it, hand the cleanup to a worker seated for the job, rerun every gate
yourself, and commit. Findings that need a decision go through §3 to a
recorded decision and then to a worker. The custom skill in play is `commit`;
everything else is built-in Claude Code machinery plus the
`declutter-code.js` workflow. Report each unit you declutter, each you skip
and why, each finding you resolve, and each time you must stop.

**Behavior is frozen.** Every change must leave the program doing the same
thing on the same inputs: same outputs, same errors, same side effects, same
observable ordering. Removing dead code, needless indirection, restated
comments, and duplicate helpers changes nothing observable; that is the
whole job. A change that needs a test rewritten to pass is a behavior
change, not a cleanup. Formatting-only churn is not cleanup either: run the
repository's formatter on the files the pass touched, never as a pass of
its own. One exception, and only as far as it goes: a
[decided change](references/gates.md#decided-changes) (§3) alters behavior
exactly as a recorded decision says.

**Never push, never open a pull request, never create issues or runs.**
Landing is one commit cycle per pass through the `commit` skill, which never
pushes. Findings are resolved in this session, not filed elsewhere. The
operator reviews history later.

## Invocation

`/declutter-code [simple|standard|deep] [unattended] [drain]`

- **Depth** sets how many read-only agents a discovery round may spend, by
  name, never by number: `simple` (about 10), `standard` (about 15), `deep`
  (up to 30, two angles per section). The
  [discovery reference](references/discovery.md#depth) holds the table. The
  workflow enforces the caps.
  1. A depth passed with the invocation wins and is recorded in
     `declutter-state.md`.
  2. Otherwise the recorded depth wins.
  3. Otherwise, on an attended invocation, ask once through `AskUserQuestion`
     with the three names and a line each (simple: a fast pass; standard: all
     signals; deep: two angles per section and two refuters per unit), record
     the answer, and never ask again this session.
  4. Otherwise (unattended) use `simple` and record it.
- **Unattended** means no one is at the keyboard: the argument, or any
  firing of `/loop` after its first. An unattended run never calls
  `AskUserQuestion`. Where §3 would ask the operator, it asks the advisor.
- **Run modes.** Under `/loop`, the skill rests between ticks. Under a
  session goal whose condition names `/declutter-code`, or with `drain`, it
  drains: it works until nothing is left (see Stop) and never rests. Invoked
  bare, it does one discovery round, works its queue, takes the findings
  queue through §3, then stops and says there will be no next tick.

`/loop /declutter-code deep` (self-pacing) or `/loop 30m /declutter-code`
supplies the recurring wake-up; each firing re-enters this skill from §1.

## 1. Each tick

1. **Tree and session files.** `git status --porcelain` must be empty. A
   dirty tree is someone else's work in progress: stop, say so, and rest
   (step 6) without touching anything. Record `git rev-parse HEAD`. Read the
   [session files](references/gates.md#session-files): the ledger, the
   findings queue, and the depth. Drop expired entries before reading the
   rest.
2. **Gates.** Discover the repository's build, typecheck, test, format, and
   lint commands as the [gates reference](references/gates.md#discovery)
   describes, then run the baseline: build, typecheck, lint when the
   repository names one, and the full test suite on the untouched tree. Keep
   the warnings that output printed; discovery's `unused` signal reads them.
   A red baseline means the pass cannot prove anything: ledger the failing
   command with HEAD, report it once, and rest. Later ticks stay quiet on
   that ledger entry until HEAD moves. A gate that cannot run in this
   environment is neither red nor green; the same reference says how to
   ledger it. Nothing is refactored on a tree whose gates you cannot run.
   After a landing, rerun the baseline only when the
   [queued-units rule](references/gates.md#queued-units) says to.
3. **Discover.** Keep the queue from this tick's last round while its units
   pass the queued-units staleness check; launch a new round (§4) when there
   is no queue or when step 5 sends it back. The round returns ranked units whose findings survived refutation, the units
   it skipped as security boundaries, and the report-only items it
   confirmed.
   - Scouts are read-only by instruction only. Before anything else, require
     an empty `git status --porcelain` and an unchanged HEAD. If either
     fails, stop, report that the round changed the tree, and restore
     nothing: the changes are evidence. The check cannot see writes to
     ignored files.
   - Ledger each security-boundary unit as `security boundary` with the
     HEAD, and name it in the report. An unattended loop cannot ask about
     those, so they are skipped, never analyzed.
   - Add each confirmed report-only item to the findings queue as `open`,
     skipping any fingerprint already queued (in any state). A `stale`
     entry the round finds again returns to `open`; the
     [expiry rule](references/gates.md#findings-queue) owns the rest.
   - Add each key the return lists under `refutedKeys` to the findings queue
     as `refuted` (current HEAD), so the next round does not re-find and
     re-refute it. A `stale` line for the key is replaced; a line in any
     other state is kept. A key is new when the findings queue did not hold
     it before this round.
   - Units ranked below the cut or whose refutation failed, and items left
     unvoted, are nothing yet. A unit's confirmed findings in `units` still
     count. The next round re-ranks the rest.
4. **Pick.** Take the highest-ranked queued unit whose test references are
   non-empty, or whose matched entries all carry proof class `inert` or
   `reachability` in the catalog, which need no tests. A unit with no tests
   and a mix of classes is taken for its inert and reachability entries
   only; its `probe` entries are ledgered as `no tests` with the HEAD. Any
   other queued unit with no test references and probe entries is ledgered
   the same way. Queued units with tests that were not picked are not
   ledgered. The guard reruns here on the current tree: discovery's evidence
   is never reused. Then declutter the unit (§2) and **go back to step 2
   or 4 immediately** (step 2 only when a rerun is required); do not
   schedule a wakeup between units while candidates remain.
5. **Resolve.** When no queued unit is pickable, take the findings queue
   through §3. Invoked bare, go to step 6. Otherwise, if the round that just
   drained landed at least one unit (a decided change's commit counts),
   return to step 3. If it landed nothing but added a key to the passed-back
   set (any state the `refutedKeys` list names, §3 outcomes included) or a
   new unit-level ledger path while units remain `unverified`, return to
   step 3: the next round excludes what this one checked. Both sets only grow
   while HEAD stands still, which bounds the loop. Otherwise go to step 6.
6. **Rest or end.** Under self-paced `/loop /declutter-code`, arm
   `ScheduleWakeup({delaySeconds: 1200-1800, noop: true, ...})` and stop;
   under an explicit interval the cron firing supplies the next tick, so
   stop; invoked bare, stop and say the pass is done. A drain does not rest:
   it ends per Stop. A quiet tick still reports the units it skipped on this
   tick, in one line each, and the findings it holds; a tick that skipped
   and held nothing sends no message.

## 2. Declutter one unit

1. **Prove the guard.** Each catalog entry names its proof class.
   - `inert`: an edit that cannot change runtime behavior (a comment, a
     banner, commented-out code, a suppression the linter no longer
     needs). No probe; the gates the
     [gates reference](references/gates.md#inert-edits) names must pass
     afterwards.
   - `probe`: a transformation of live code (inline, extract, flatten,
     dedupe, rename with callers). Before the worker touches a function or
     method, the orchestrator runs a
     [mutation probe](references/gates.md#mutation-probe) on it, which also
     bounds what the worker may change there. A site whose probe survives
     has no guard; it is left as it is, ledgered as `no coverage`, and its
     finding is queued `skipped` at the current HEAD (see gates.md).
   - `reachability`: removal of code that nothing can execute (unused
     symbols, unreachable statements, a branch on a constant, an import
     nothing uses). The proof is static, to the bar the
     [gates reference](references/gates.md#reachability-proof) sets.
     "This cannot happen at runtime" is not a proof. No probe runs, and
     the full gates in step 4 must still pass after removal.

   Say in the report which class each applied entry used. The operator
   chose to skip uncovered code; applying inert edits and dead-code
   removals in units without tests is this skill's reading of that choice.
   The report names every `inert` and `reachability` change in such a unit
   so the operator can veto the reading.
2. **Seat a worker** (§4) with the unit, the catalog entries the round
   matched with their lines, the probe results per site, and the frozen
   contracts from the [gates reference](references/gates.md#frozen-contracts).
   The worker applies every matched entry whose guard is proven, and
   nothing else. You orchestrate; you do not implement. Read or grep in
   this conversation only as far as seating the worker requires.
3. **Blocked** (the worker reports it cannot preserve behavior, a matched
   entry turns out to be a false positive, or the worker fails and does not
   resolve on one follow-up round): ledger the unit as `blocked` with the
   reason, restore the tree to the recorded HEAD by path, tell the operator
   in your next visible turn, and go back to §1. The same blocked unit is
   not retried every tick. A decided change (§3) that blocks marks its
   finding `blocked` instead and leaves the unit's ordinary cleanup alone.
4. **Rerun the gates.** Run the repository formatter on the touched files,
   layout only, as the gates reference defines it. Then, on that tree, run
   build, typecheck, lint when the repository names one, and the full test
   suite yourself and read the output. The
   worker's report is a claim, not evidence. A fresh failure goes to a
   fresh worker as the one follow-up round §4 describes, briefed with the
   command and its output. When the session can launch agents, launch the
   `advisor` agent on the rerun result before treating it as a pass.
5. **Review the diff.** `git diff --stat` and `git diff` against the
   recorded HEAD. Refuse the pass, restoring by path, if any of these hold:
   a test file changed other than to delete a test for removed dead code
   or to update an import for a renamed internal symbol; a frozen contract
   changed; a file outside the unit changed for any reason other than
   updating a caller of a renamed symbol; the change reads as a rewrite
   rather than a removal or a flattening; any touched file is a
   [security-boundary path](references/gates.md#security-boundary-paths) or
   has a `security boundary` ledger entry. A refused pass is ledgered as
   `refused` with the reason; a refused decided change marks its finding
   `blocked` instead and writes no ledger entry.

   A decided change is reviewed against its recorded decision instead: it
   must match the option and nothing else, it may add code the option calls
   for, and it may change the test files the decision names. The
   security-boundary and frozen-contract refusals still apply, and the
   [decided changes](references/gates.md#decided-changes) rules say when a
   frozen contract is allowed.
6. **Land.** Invoke the `commit` skill (`Skill({skill: "commit", args: "<unit's paths>"})`):
   one commit cycle per unit, never
   batched across units, never sweeping in files the pass did not touch.
7. **Report** in one line: the unit, the catalog entries applied with their
   proof class, lines removed and added, the gate commands and their
   results, and the commit hash. Then one line per site or unit skipped on
   this pass, with the reason. A landed unit is a state change; always say
   so.

## 3. Resolve findings

The findings queue holds report-only items a refuter confirmed. They change
behavior or need a decision, so the loop never applies one on its own. They
are also not left as a report: each ends this session `resolved`,
`declined`, `blocked`, `undecided`, or `withheld`, never silently `open`.

1. **Decide.** For each `open` finding (and, on an attended run, each
   `withheld` one), work out two or three concrete
   options from the catalog item and the code (for a swallowed exception:
   propagate it, log and rethrow, keep it with a reason comment), and always
   a last option, leave it as is.
   - **Attended:** ask through `AskUserQuestion`, up to four findings per
     call, each question naming the path, the symbol, and what is wrong.
     When the session can launch agents, the `advisor` reviews each drafted
     set first, per the working agreement.
   - **Unattended:** do not ask. The standing ruling below applies.
   - Record the result in the queue: `decided` with the option, or
     `declined` for leave-as-is.

   ### Standing ruling: the advisor decides findings when unattended

   The operator ruled, for this skill, that an unattended run refers
   findings to the advisor instead of asking. Terms:

   - Launch the `advisor` agent once per finding with the finding, its
     evidence, the options, and the invariants (tests are the guard, the
     smallest change wins). Its brief carries the unit, never this
     conversation.
   - A clear pick among the options is the decision, recorded with the note
     `advisor`. The advisor's answer is review input that the ruling turns
     into the decision; it is no authority beyond this ruling.
   - An unclear answer records the finding as `undecided`. It is never asked
     again this session and is listed in the final report.
   - An advisor decision never reaches a frozen contract, a dependency
     removal, or an orphan-file deletion. Those findings are recorded
     `withheld` without asking, and are put to the operator at the next
     attended invocation in this session and listed in the final report.
   - The ruling covers only the findings queue. It authorizes no other
     action and no other skill.
2. **Apply.** Each `decided` finding is a
   [decided change](references/gates.md#decided-changes): one worker, one
   finding, one commit. Brief the worker with the finding, the exact option
   chosen, and the frozen contracts; run §2 steps 3 through 7 on it. The
   commit message names the finding and the decision. On success mark the
   entry `resolved` with the commit hash; on a block mark it `blocked`.
3. **Report** one line per finding resolved, declined, blocked, undecided,
   withheld, or still open.

## 4. Seat and spawn

Read-only discovery seats (scouts and refuters) run in parallel inside one
discovery round, and only while no probe or worker edit is in flight: a probe
mutates the shared working tree, and a scout reading during one would read
mutated code. A probe or worker never overlaps any other seat, and never two
units are in flight, because the writer works in this working tree with no
worktree isolation. Seats are always the built-in `general-purpose` agent
type, never a custom agent definition; `Explore` is not used, because ranking
a tree against a catalog is the cross-file analysis that agent type excludes.

One seating mechanism, always: the committed `declutter-code.js` workflow,
launched by `scriptPath` at the installed path
`~/.claude/workflows/declutter-code.js`, expanding `~` to a literal absolute
path yourself first (the Workflow tool does not expand it). A missing
installed file means the corpus was never activated after this skill was
added: report that, and do not launch the source copy. Never use the plain
`Agent` tool for a seat: it carries no effort parameter. Every seat pins
both `model` and `effort` explicitly; the workflow holds the pins.

**Discovery round:**

```
Workflow({ scriptPath: "<absolute installed path>", args: { repo: "<absolute repo path>", catalogPath: "<absolute installed catalog.md>", discoveryPath: "<absolute installed discovery.md>", depth: "<simple|standard|deep>", head: "<HEAD>", ledger: [<ledgered paths>], baselineReports: "<warnings from the baseline run>" } })
```

`ledger` holds the paths of unit-level entries only (`no tests`, `blocked`,
`refused`, `security boundary`); site-level `no coverage` entries and
non-path reasons (`baseline red`, `gate unavailable`) are not passed.
The workflow also accepts `refutedKeys: [<first column of every finding line
in state refuted, skipped, declined, undecided, withheld, blocked, or
resolved>]`.

It refuses a depth whose plan exceeds its cap and a seat past it. The
return, and how a round is built, are in the workflow header and the
[discovery reference](references/discovery.md).

**Worker seat:**

```
Workflow({ scriptPath: "<absolute installed path>", args: { mode: "work", brief: "<worker brief>", tier: "ordinary|gnarly", followUp: false, unit: "<unit path>" } })
```

1. **Rule the tier, in one line.**
   - Worker, ordinary unit (one file, entries of one or two kinds): `opus`
     at `high`.
   - Worker, gnarly unit (a module, a rename crossing many callers, a
     dedupe that merges near-duplicates with subtle differences): `opus`
     at `xhigh`; its one follow-up round (below) seats `fable` at `xhigh`.

   Name the seat and why the unit fits the tier. The scout and refuter tiers
   are `opus` at `medium` and `high`.

2. **Spawn the worker** with the brief below. `followUp: true` seats the
   follow-up tier.

**The worker brief** carries: the repository's absolute path, the unit, the
matched catalog entries verbatim with their Simplification and Risk fields,
the probe result per site, the frozen contracts, and these standing rules.
Apply only the matched entries whose guard is proven; leave a site whose
probe survived untouched. Preserve behavior exactly as the top of this
skill defines it (a decided change adds the recorded option as the only
behavior change). Update every in-repo caller of a renamed internal symbol
in the same change. Run the gates after the change and report their
output. Leave every change uncommitted and unstaged. Never run git commits,
skills, or the formatter. The final message is the report: files changed,
each entry applied and where, the gate commands and their output, anything
the worker judged unsafe to apply and why.

A report that names its gates and shows their output goes to step 4 of §2,
the rerun; the report alone never commits. A report with no gate output, or
whose gates fail on the rerun, gets one follow-up round: a fresh worker
seat at the same tier, or the gnarly follow-up tier for a gnarly unit,
briefed with the first report and the rerun's command and output. If the
second report still cannot pass the rerun here, the unit is blocked (step 3
of §2).

## Stop

Under `/loop`, the loop ends when the operator stops it
(`ScheduleWakeup({stop: true})` under self-pacing, or telling you to stop) or
ends the `/loop`. There is no other terminal condition: a tree with nothing
pickable is a rest, not a finish, because the next commit can add cruft.

A drain ends on its own, when any step sends it to step 6: step 5 when it
does not return to step 3; step 1 or 2 on a dirty tree, a red baseline, or an
unavailable gate; step 3 when the round changed the tree; or §4 when the
installed workflow is missing or refuses the round. The report names
the reason. Report what landed, what was declined, what
is `blocked`, any finding left `undecided` (the advisor gave no clear answer),
`withheld` (the ruling does not reach it), `open`, or `decided`, and any units
still `unverified`; then stop without arming a wakeup. A drain also ends when
the operator tells it to stop.
