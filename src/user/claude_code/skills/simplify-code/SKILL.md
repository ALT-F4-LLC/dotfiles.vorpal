---
name: simplify-code
description: >-
  Use on "/simplify-code", "simplify the whole repo's code", "strip the
  generated cruft", "run the simplify-code loop", `/loop /simplify-code`, or
  `/goal /simplify-code`. Audits the repository in the current working
  directory without editing it: fans read-only scouts across the bundled
  catalog and discovery signals at a named depth (simple, standard, deep),
  refutes what they find, checks the static proof each cleanup needs, and
  files one worker-ready Docket issue per unit of cruft, plus a decision
  issue per report-only finding. Each issue tells the worker who later
  applies it which guard to prove, which contracts are frozen, and which
  gates to rerun. Never edits the checkout, pushes, opens a pull request, or
  creates a run. Distinct from the built-in simplify skill (reviews the
  current diff once), code-review (hunts bugs), and simplify-corpus (files
  issues for shrinking this repo's skills and Docket config).
---

# simplify-code

You keep one repository's cruft on the backlog as an orchestrator: run
discovery against the [catalog](references/catalog.md), re-check the static
proof for each unit, and file what survives as Docket issues that a worker
can apply cold. You edit nothing. The custom pieces in play are the Docket
CLI and the `simplify-code.js` workflow; everything else is built-in Claude
Code machinery. Report each issue you file, each finding you attach to an
existing issue, each unit you skip and why, and each time you must stop.

**The checkout is read-only. The only writes are Docket issues and scratch
files.** Never edit a file in the repository, run a build, test, formatter,
or linter in it, probe a site, commit, push, open a pull request, or create a
run. Scratch files live under the session's scratchpad directory, or
`$TMPDIR` when the session lists none. Filed issues drain through
`docket-groom` into a `docket-plan` and `docket-run` execution, or direct
work; do not start that work.

**Behavior is frozen, and each issue says so.** The change an issue asks for
must leave the program doing the same thing on the same inputs: same outputs,
same errors, same side effects, same observable ordering. Removing dead code,
needless indirection, restated comments, and duplicate helpers changes
nothing observable; that is the whole job. A change that needs a test
rewritten to pass is a behavior change, not a cleanup. Formatting-only churn
is not cleanup either: the worker runs the repository's formatter on the
files it touched, never as a change of its own. The one thing that may alter
behavior is a decision an operator makes on a
[decision issue](references/gates.md#decision-issues).

## Invocation

`/simplify-code [simple|standard|deep] [unattended] [drain]`

- **Depth** sets how many read-only agents a discovery round may spend, by
  name, never by number: `simple` (about 10), `standard` (about 15), `deep`
  (up to 30, two angles per section). The
  [discovery reference](references/discovery.md#depth) holds the table. The
  workflow enforces the caps.
  1. A depth passed with the invocation wins and is recorded in
     `simplify-state.md`.
  2. Otherwise the recorded depth wins.
  3. Otherwise, on an attended invocation, ask once through `AskUserQuestion`
     with the three names and a line each (simple: a fast pass; standard: all
     signals; deep: two angles per section and two refuters per unit), record
     the answer, and never ask again this session.
  4. Otherwise (unattended) use `simple` and record it.
- **Unattended** means no one is at the keyboard: the argument, or any
  firing of `/loop` after its first. An unattended run never calls
  `AskUserQuestion`. Filing needs no answer from anyone, so this only skips
  the depth question.
- **Run modes.** Under `/loop`, the skill rests between ticks. Under a
  session goal whose condition names `/simplify-code`, or with `drain`, it
  drains: it works until nothing is left (see Stop) and never rests. Invoked
  bare, it does one discovery round, files its queue, then stops and says
  there will be no next tick.

`/loop /simplify-code deep` (self-pacing) or `/loop 30m /simplify-code`
supplies the recurring wake-up; each firing re-enters this skill from §1.

## 1. Each tick

1. **Project, tree, and session files.** Confirm the Docket project bound to
   this checkout, since the working directory picks the project. If none
   answers, stop and say so, and never register one. Record
   `git rev-parse HEAD`, and save `git status --porcelain` to scratch. Every
   path it lists is someone else's work in progress: pass those paths in the
   round's `ledger` for this tick, so no unit describes code in flux, and
   touch nothing. Read the [session files](references/gates.md#session-files):
   the ledger, the findings queue, and the depth. Drop expired entries before
   reading the rest.
2. **Gate commands.** Discover the repository's build, typecheck, test,
   format, and lint commands as the
   [gates reference](references/gates.md#discovery) describes, and record
   them for the issues. Run none of them. The `unused` signal gets whatever
   diagnostics already exist without a build (language-server diagnostics, a
   CI log the operator names); otherwise `baselineReports` is empty and the
   scout falls back to the catalog's Dead code signals.
3. **Discover.** Keep the queue from this tick's last round while its units
   pass the queued-units staleness check; launch a new round (§4) when there
   is no queue or when step 5 sends it back. The round returns ranked units
   whose findings survived refutation, the units it skipped as security
   boundaries, and the report-only items it confirmed.
   - Scouts are read-only by instruction only. Before anything else, require
     that `git status --porcelain` matches the scratch copy from step 1 and
     that HEAD is unchanged. If either differs, stop, report that the round
     changed the tree, and restore nothing: the changes are evidence. The
     check cannot see writes to ignored files.
   - Ledger each security-boundary unit as `security boundary` with the
     HEAD, and name it in the report. Nothing is filed for it and it is never
     analyzed.
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
4. **File.** Take the queued units from the highest rank down. A unit whose
   test references are non-empty, or whose matched entries all carry proof
   class `inert` or `reachability`, is filed whole (§2). A unit with no tests
   and a mix of classes is filed for its inert and reachability entries only;
   its `probe` entries are ledgered as `no tests` with the HEAD. Any other
   unit with no test references and only `probe` entries is ledgered the same
   way and not filed. Nothing is reused from discovery: §2 re-runs its checks
   on the current tree.
5. **Resolve.** When no queued unit is left to file, file the findings queue
   through §3. Invoked bare, go to step 6. Otherwise, if the round that just
   drained filed at least one issue, or added a key to the passed-back set (a
   `refuted`, `skipped`, `declined`, or `filed` entry, §3 outcomes included)
   or a new unit-level ledger path while units remain `unverified`, return to
   step 3: the next round excludes what this one checked. Both sets only grow
   while HEAD stands still, which bounds the loop. Otherwise go to step 6.
6. **Rest or end.** Under self-paced `/loop /simplify-code`, arm
   `ScheduleWakeup` (1200 to 1800 seconds, `noop: true`) and stop; under an
   explicit interval the cron firing supplies the next tick, so stop; invoked
   bare, stop and say the pass is done. A drain does not rest: it ends per
   Stop. A quiet tick still reports the units it skipped on this tick, in one
   line each, and the findings it holds; a tick that skipped and held nothing
   sends no message.

## 2. File one unit

1. **Check the guard statically.** Each catalog entry names its proof class,
   and the issue carries the matching guard for the worker to prove, per the
   [issue contract](references/gates.md#issue-contract).
   - `inert`: nothing to check here; the worker's gates are
     [named in the issue](references/gates.md#inert-edits).
   - `probe`: a transformation of live code. You cannot probe, because a probe
     edits the tree. The issue tells the worker to run the
     [mutation probe](references/gates.md#mutation-probe) on each site first.
   - `reachability`: removal of code that nothing can execute. Re-run the
     search on the current tree to the bar of the
     [reachability proof](references/gates.md#reachability-proof). "This
     cannot happen at runtime" is not a proof. An entry whose search finds a
     reference is dropped and queued `refuted`; one defeated by reflection,
     a plugin registry, or a published export is dropped and queued `skipped`.
   Say in the report which class each filed entry used. The operator chose to
   skip uncovered code; filing inert edits and dead-code removals for units
   without tests is this skill's reading of that choice, so the report names
   every `inert` and `reachability` entry filed for such a unit.
2. **Deduplicate.** Follow
   [deduplicate before filing](references/gates.md#deduplicate-before-filing).
   Findings already tracked or declined are queued and left out; the rest
   continue. Nothing left means no issue.
3. **Size and split.** Measure the unit against the docket skill's
   [sizing reference](../docket/references/sizing.md) and pass the tier as
   `--size` on every create. A single-file unit is `small`; a unit spanning
   files (a rename across callers, a dedupe with its partner) with one
   independent outcome is `bounded`; a unit you cannot measure is `unknown`.
   Apply no size label: `docket-plan` applies those. Two or more independent
   outcomes in one unit (a rename and an unrelated dedupe) are one issue per
   outcome, each with its own findings and keys. A finding you cannot place on
   a path is held, not filed with an unrelated path.
4. **Create.** One issue per unit (or outcome), from the checkout. The
   description follows the worker-ready issue contract in
   `docket-postmortem`'s
   [filing reference](../docket-postmortem/references/filing.md#worker-ready-issue-contract),
   adapted:

   ```text
   Observed: the unit and the cruft in it, and the consequence for a reader.
   Evidence: HEAD <sha>; per entry: the catalog entry name, proof class,
     path:lines, enclosing symbol, and the matched code quoted.
   Remedy: apply every entry below and nothing else, with each entry's
     Simplification and Risk lines from the catalog quoted verbatim.
   Constraints: behavior is frozen; the frozen contracts that apply to this
     unit; the security-boundary refusal; the review bar.
   Acceptance: the guard per entry (the probe command for each probe site, the
     reachability search for each deletion), then the formatter on the touched
     files and the discovered build, typecheck, lint, and test commands by
     name, run by the worker with the output read. A site whose probe passes
     is left alone and named in a comment. Detail:
     ~/.claude/skills/simplify-code/references/gates.md (issue contract).
   Finding keys: one `<path>#<entry>#<symbol>` per entry, one per line.
   ```

   ```bash
   docket issue create --json=v2 -t "<the cruft and where, one line>" \
     -T chore -p low -l simplify-code --size <small|bounded|unknown> \
     -f <path> [-f <path>] --scope '<glob bounding the work>' \
     --idempotency-key "simplify-code/<path>/<12 hex>" -d - <<'SIMPLIFY_CODE_ISSUE'
   <description as above>
   SIMPLIFY_CODE_ISSUE
   ```

   - The 12 hex are the first twelve characters of the SHA-256 of the unit's
     finding keys, sorted and newline-joined, so a retried create cannot
     duplicate the issue and a changed finding set files a new one.
   - A repeated key returns the original issue, even a closed one. When the
     [deduplication](references/gates.md#deduplicate-before-filing) found
     the finding on a closed issue without `wont-do` (a regression), the key
     is `simplify-code/<path>/<12 hex>/after-<prior issue id>` (the most
     recent such issue), so the create files a new issue instead of
     replaying the closed one, and the body links the prior id.
   - `-f`, `--scope`, and `--size` are never omitted. No assignee, no parent,
     no routing label, no status beyond the default.
   - A unit that touches authn or authz, secrets, crypto, sandbox or
     permissions, a trust boundary, supply chain, or untrusted input at a
     privilege boundary starts its description with `Security gate required:
     this remedy touches <the categories>.` Security-boundary paths are never
     filed, so this applies to the rare unit outside them that still
     qualifies.
   - Priority is `low`; never `critical`.
5. **Read the receipt back.** Verify the id, title, files, label, and empty
   assignee with `docket issue show <id> --json=v2`, and scope from the create
   response, since `issue show` does not return it. A failed or ambiguous
   create is reconciled against the store before any retry; a still-failed
   create is queued `held` with the CLI's error. Record each filed finding in
   the findings queue as `filed` with the issue id.
6. **Report** in one line: the unit, the catalog entries filed with their proof
   class, the issue id, its size, and any entries attached to an existing
   issue. Then one line per site or unit skipped on this pass, with the
   reason. A filed issue is a state change; always say so.

## 3. File the report-only findings

The findings queue holds report-only items a refuter confirmed. They change
behavior or need a decision, so the pass never files them as ready work. Each
becomes a [decision issue](references/gates.md#decision-issues), one per
`open` finding, so no finding stays silently `open`.

1. **Draft.** From the catalog item and the code, work out two or three
   concrete options (for a swallowed exception: propagate it, log and
   rethrow, keep it with a reason comment), always a last option to leave it
   as is, and a recommendation.
2. **Deduplicate and create.** Run §2 steps 2, 3, and 5. The command differs
   as follows: `-T task -p medium -l simplify-code`, the title starts with
   `Decide:`, and the idempotency key is `simplify-code/<the finding key>`,
   with `/after-<prior issue id>` appended on a regression as in §2 step 4.
   The description carries the finding with its evidence, the options with
   their effects, the recommendation, and a closing `Finding keys:` line as in gates.md; its Acceptance is
   the recorded answer as an issue comment, with no code change. A decision
   that reaches a frozen contract, removes a dependency, or deletes an
   orphan file says in the body that only an operator decides it.
3. **Report** one line per finding filed, attached to an existing issue,
   declined, held, or still open.

## 4. Seat and spawn

Read-only discovery seats (scouts and refuters) run in parallel inside one
discovery round. Nothing in the checkout changes, so a round never overlaps a
write. Seats are always the built-in `general-purpose` agent type, never a
custom agent definition; `Explore` is not used, because ranking a tree
against a catalog is the cross-file analysis that agent type excludes.

One seating mechanism, always: the committed `simplify-code.js` workflow,
launched by `scriptPath` at the installed path
`~/.claude/workflows/simplify-code.js`, expanding `~` to a literal absolute
path yourself first (the Workflow tool does not expand it). A missing
installed file means the corpus was never activated after this skill was
added: report that, and do not launch the source copy. Never use the plain
`Agent` tool for a seat: it carries no effort parameter. Every seat pins
both `model` and `effort` explicitly; the workflow holds the pins, `opus` at
`medium` for scouts and `high` for refuters.

```
Workflow({ scriptPath: "<absolute installed path>", args: { repo: "<absolute repo path>", catalogPath: "<absolute installed catalog.md>", discoveryPath: "<absolute installed discovery.md>", depth: "<simple|standard|deep>", head: "<HEAD>", ledger: [<ledgered paths and the dirty paths from step 1>], baselineReports: "<diagnostics, or empty>" } })
```

`ledger` holds the paths of unit-level entries only (`no tests`, `security
boundary`, `held`) and the dirty paths from step 1.
The workflow also accepts `refutedKeys: [<first column of every finding line
in state refuted, skipped, declined, or filed>]`.

It refuses a depth whose plan exceeds its cap and a seat past it. The
return, and how a round is built, are in the workflow header and the
[discovery reference](references/discovery.md).

## Stop

Under `/loop`, the loop ends when the operator stops it
(`ScheduleWakeup` with `stop: true` under self-pacing, or telling you to stop) or
ends the `/loop`. There is no other terminal condition: a tree with nothing
left to file is a rest, not a finish, because the next commit can add cruft.

A drain ends on its own, when any step sends it to step 6: step 5 when it
does not return to step 3; step 1 when no Docket project answers; step 3 when
the round changed the tree; or §4 when the installed workflow is missing or
refuses the round. The report names the reason. Report what was filed, what
was attached to an existing issue, what was declined, what is `held`, and any
units still `unverified`; say that no fixes were applied and that the filed
issues drain through `docket-groom`; then stop without arming a wakeup. A
drain also ends when the operator tells it to stop.
