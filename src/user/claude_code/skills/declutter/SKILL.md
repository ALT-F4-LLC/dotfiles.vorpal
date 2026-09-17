---
name: declutter
description: >-
  Use on "declutter", "/declutter", "declutter the repo", "strip the
  generated cruft", "run the declutter loop", or `/loop /declutter`. Works
  the repository in the current working directory one unit per pass:
  finds code carrying the tells of generated, over-structured, or dead code
  from a bundled catalog, proves the existing tests would catch a behavior
  change there, removes the cruft without changing what the code does,
  reruns the gates, and lands the result through the commit skill. Never
  pushes, never touches external contracts, never refactors code the tests
  do not cover. Distinct from the built-in simplify skill, which reviews the
  current diff once, and from code-review, which hunts bugs; declutter is a
  standing loop over the whole tree.
---

# declutter

You keep one repository free of cruft as an orchestrator: scout the tree for
the patterns in the [catalog](references/catalog.md), pick one unit, prove
the tests guard it, hand the cleanup to a worker seated for the job, rerun
every gate yourself, and commit. The only custom skill in play is `commit`;
everything else is built-in Claude Code machinery. Report each unit you
declutter, each you skip and why, and each time you must stop.

**Behavior is frozen.** Every change must leave the program doing the same
thing on the same inputs: same outputs, same errors, same side effects, same
observable ordering. Removing dead code, needless indirection, restated
comments, and duplicate helpers changes nothing observable; that is the
whole job. A change that needs a test rewritten to pass is a behavior
change, not a cleanup. Formatting-only churn is not cleanup either: run the
repository's formatter on the files the pass touched, never as a pass of
its own.

**Never push, never open a pull request, never create issues or runs.**
Landing is one commit cycle per pass through the `commit` skill, which never
pushes. The operator reviews history later.

**Run it under `/loop`.** `declutter` has no watch loop of its own: `/loop
/declutter` (self-pacing) or `/loop 30m /declutter` supplies the recurring
wake-up, and each firing re-enters this skill from §1. Invoked bare with no
loop wrapping it, do one pass and say so; there will be no next tick.

## 1. Each tick

1. **Tree and ledger.** `git status --porcelain` must be empty. A dirty
   tree is someone else's work in progress: stop, say so, and rest (step 5)
   without touching anything. Record `git rev-parse HEAD`. Read the ledger,
   a file named `declutter-ledger.md` in the session's scratchpad
   directory, or under `$TMPDIR` when the session lists none. It holds one
   line per unit skipped on an earlier tick, with the reason and the HEAD
   at the time; the [gates reference](references/gates.md#ledger) gives the
   format and the expiry rule. Drop expired entries before reading the
   rest.
2. **Gates.** Discover the repository's test, build, typecheck, and
   formatter commands as the [gates reference](references/gates.md#discovery)
   describes, then run the baseline: build, typecheck, and the full test
   suite on the untouched tree. A red baseline means the pass cannot prove
   anything: ledger the failing command with HEAD, report it once, and rest.
   Later ticks stay quiet on that ledger entry until HEAD moves. A gate that
   cannot run in this environment (missing tool, network, permission) is
   neither red nor green: report which one, and rest. Nothing is refactored
   on a tree whose gates you cannot run.
3. **Scout.** Seat one read-only scout (§3) to rank candidate units against
   the catalog. A unit is one file, or one directory that forms a module
   when the language groups code that way. The scout returns at most ten
   units, each with the catalog entries it matched, the concrete lines that
   matched, and the test files that reference the unit. It excludes every
   unit on the ledger, every test file (tests are frozen, so a test file
   is never a unit), every generated or vendored file (lockfiles,
   `node_modules`, `vendor`, `target`, `dist`, files whose header says they
   are generated), and every security-boundary path: authentication,
   authorization, session handling, secrets, cryptography, permissions,
   sandboxing, and untrusted input at a privilege boundary. An unattended
   loop cannot ask about those, so they are skipped, ledgered, and named in
   the report.
4. **Pick.** Take the highest-ranked unit whose test references are
   non-empty, or whose matched entries all carry proof class `inert` or
   `reachability` in the catalog, which need no tests. A unit with no
   tests and a mix of classes is taken for its inert and reachability
   entries only; its `probe` entries are ledgered as `no tests` with the
   HEAD. Everything else the scout ranked is ledgered the same way. Then
   declutter it (§2) and **loop back to step 1 immediately**; do not
   schedule a wakeup between units while candidates remain. Go quiet only
   once a scout returns nothing pickable.
5. **Rest.** Under self-paced `/loop /declutter`, arm
   `ScheduleWakeup({delaySeconds: 1200-1800, noop: true, ...})` and stop;
   under an explicit interval the cron firing supplies the next tick, so
   stop; invoked bare, stop and say the pass is done. A quiet tick still
   reports the units it skipped on this tick, in one line each; a tick that
   skipped nothing sends no message.

## 2. Declutter one unit

1. **Prove the guard.** Each catalog entry names its proof class.
   - `inert`: an edit that cannot change runtime behavior (a comment, a
     banner, commented-out code, a suppression the linter no longer
     needs). No proof beyond
     build, typecheck, and linter passing afterwards; see the
     [gates reference](references/gates.md#inert-edits).
   - `probe`: a transformation of live code (inline, extract, flatten,
     dedupe, rename with callers). Before the worker touches a function or
     method, the orchestrator runs a mutation probe on it as the
     [gates reference](references/gates.md#mutation-probe) describes: one
     deliberate behavior change at that site must make the tests fail, and
     the probe is then reverted by path, never by stash. A site whose probe
     survives has no guard; it is left as it is and ledgered as `no
     coverage`. The probe proves the suite notices a change at that site.
     It does not prove the suite checks every branch, so the worker's
     transformation stays inside what the probed site does.
   - `reachability`: removal of code that nothing can execute (unused
     symbols, unreachable statements, a branch on a constant, an import
     nothing uses). The proof is static: no reference
     anywhere in the tree by search or LSP, or the compiler or linter
     reports it unused, or the condition is a literal; the
     [gates reference](references/gates.md#reachability-proof) gives the
     bar. "This cannot happen at runtime" is not a proof. No probe runs,
     and the full gates in step 4 must still pass after removal.

   Say in the report which class each applied entry used. The operator
   chose to skip uncovered code; applying inert edits and dead-code
   removals in units without tests is this skill's reading of that choice,
   so the report names every `inert` and `reachability` change in such a
   unit so the operator can veto the reading.
2. **Seat a worker** (§3) with the unit, the catalog entries the scout
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
   not retried every tick.
4. **Rerun the gates.** Run the repository formatter on the touched files,
   layout only, as the gates reference defines it. Then, on that tree, run
   build, typecheck, and the full test suite yourself and read the output. The
   worker's report is a claim, not evidence. A fresh failure goes back to
   the worker as the one follow-up round §3 describes, briefed with the
   command and its output. When the advisor tool is available, call it on
   the rerun result before treating it as a pass.
5. **Review the diff.** `git diff --stat` and `git diff` against the
   recorded HEAD. Refuse the pass, restoring by path, if any of these hold:
   a test file changed other than to delete a test for removed dead code
   or to update an import for a renamed internal symbol; a frozen contract
   changed; a file outside the unit changed for any reason other than
   updating a caller of a renamed symbol; the change reads as a rewrite
   rather than a removal or a flattening. A refused pass is ledgered as
   `refused` with the reason.
6. **Land.** Invoke the `commit` skill (`Skill({skill: "commit"})`) with
   the unit's paths as its argument: one commit cycle per unit, never
   batched across units, never sweeping in files the pass did not touch.
7. **Report** in one line: the unit, the catalog entries applied with their
   proof class, lines removed and added, the gate commands and their
   results, and the commit hash. Then one line per site or unit skipped on
   this pass, with the reason. A landed unit is a state change; always say
   so.

## 3. Seat and spawn

One seat at a time, ever: the scout, then the worker, never both, and
never two units in flight. Seats spawn into this working tree with no
worktree isolation, so strict sequence is required. Built-in agent types
only, always `general-purpose`, never a custom agent definition. The scout
carries a read-only brief; `Explore` is not used, because ranking a tree
against a catalog is the cross-file analysis that agent type excludes.

One seating mechanism, always: the built-in `Workflow` tool's `agent()`
call, whose opts take `agentType`, `model`, and `effort`. Every seat sets
**both `model` and `effort` explicitly**. Never use the plain `Agent` tool:
it carries no effort parameter, so a seat through it runs at this session's
own default instead of a chosen one.

1. **Rule the tier, in one line.**
   - Scout: `opus` at `medium`. It reads widely and judges matches; it
     changes nothing.
   - Worker, ordinary unit (one file, entries of one or two kinds): `opus`
     at `high`.
   - Worker, gnarly unit (a module, a rename crossing many callers, a
     dedupe that merges near-duplicates with subtle differences): `fable`
     at `max`.

   Write the ruling as one line naming the seat and why the unit fits the
   tier, and carry it into the spawn.

2. **Spawn through `Workflow`**, the brief embedded in the script, with a
   `log()` line carrying step 1's ruling immediately before the `agent()`
   call:

   ```js
   export const meta = {name: 'declutter-unit', description: '<unit path>',
     phases: [{title: 'Declutter'}]}
   phase('Declutter')
   log('tier: ordinary — one file, restated comments and two wrapper functions')
   return await agent(`<worker brief>`, {agentType: 'general-purpose',
     model: 'opus', effort: 'high'})
   ```

   `model` and `effort` take effect only inside `agent()`'s opts. Setting
   either on a `meta.phases` entry is display-only and silently seats the
   session default.

**The scout brief** carries: the repository's absolute path, the catalog
path, the ledger's current entries, the exclusion list from §1 step 3, and
the return shape (ranked units, matched entries with lines, test files
referencing each unit). It runs read-only: search, read, and LSP only, no
edits, no commands that write.

**The worker brief** carries: the repository's absolute path, the unit, the
matched catalog entries verbatim with their Simplification and Risk fields,
the probe result per site, the frozen contracts, and these standing rules.
Apply only the matched entries whose guard is proven; leave a site whose
probe survived untouched. Preserve behavior exactly as the top of this
skill defines it. Update every in-repo caller of a renamed internal symbol
in the same change. Run the gates after the change and report their
output. Leave every change uncommitted and unstaged. Never run git commits,
skills, or the formatter. The final message is the report: files changed,
each entry applied and where, the gate commands and their output, anything
the worker judged unsafe to apply and why.

A report that names its gates and shows their output goes to step 4 of §2,
the rerun; the report alone never commits. A report with no gate output, or
whose gates fail on the rerun, gets one follow-up round: a fresh `agent()`
spawn at the same tier, briefed with the first report and the rerun's
command and output. If the second report still cannot pass the rerun here,
the unit is blocked (step 3 of §2).

## Stop

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. There is no
other terminal condition: a tree with nothing pickable is a rest, not a
finish, because the next commit can add cruft.
