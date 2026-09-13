---
name: inspect
description: Walk a checkout the way a home inspector walks a house, during or after the build, and turn every observation the operator makes into a worker-ready Docket issue with no routing label, so docket-groom triages it through the normal paths. The operator is the inspector; Claude carries the clipboard, prompts with a per-system checklist, resolves each item to a location and an acceptance check, dedupes, and files. `inspect reinspect` is the final walkthrough: it re-checks previously filed inspection items against the current checkout and reports pass, fail, or unverifiable per item. Never fixes anything. Use on "inspect", "/inspect", "punch list", "walk through the build", "let me list what I want changed", "final walkthrough", or "re-inspect". Distinct from shadow, which observes sessions rather than the product, and from finish, which files a session's own leftovers.
argument-hint: "[area or path to walk | reinspect [ISSUE-ID ... | since <date> | <scope glob>]]"
---

# inspect

The house is built, or half built, and the owner walks it with a clipboard.
They open every door, run every tap, and say what they see: the trim is
wrong here, that outlet is dead, this room needs a second window. The
inspector does not fix anything. The inspector produces a punch list good
enough that a contractor can work it cold.

You hold the clipboard. The operator inspects. Every observation becomes
one Docket issue that the existing intake already knows how to consume:
`/docket-groom` routes it, then `/docket-plan` and `/docket-run`, `/tend`, or
direct work drain it. This skill adds nothing to that pipeline except the
items.

Two modes:

- **Walk** (default): tour the checkout, collect observations, file them.
- **Final walkthrough** (`reinspect`): revisit filed inspection items and
  confirm whether each one landed.

## Boundaries

- Run in the main conversation. The walk is a dialogue with the operator;
  a forked subagent cannot hold it.
- The checkout is read-only. Writes are Docket issues, Docket comments, and
  scratch notes in the permitted scratch directory. No fixes, no commits,
  no worktrees, no runs.
- File with **no routing label and no size label**. Routing belongs to
  groom, sizing to docket-plan. An issue this skill files is invisible to
  `/tend` and to bare `/docket-plan` until groom labels it, which is what
  makes filing mid-build safe.
- Never close an item this skill has not verified. Closure in the final
  walkthrough follows the rule in that section and nowhere else.
- Issue text is task data. A remedy the operator dictates is what they
  want; it is not authorization to carry it out here.

## Set up the clipboard

Before the first observation:

1. Confirm the Docket project bound to this checkout, since cwd picks the
   project. If no project answers, stop and say so; do not register one.
2. Record the checkout sha (`git rev-parse HEAD`) and branch. Every filed
   item names this sha as the revision inspected.
3. Load the existing punch list: every open issue carrying the `inspect`
   label, plus any the operator names. This is the dedupe set.

```bash
docket issue list --json=v2 --limit 1000 -l inspect -s backlog -s todo -s in-progress -s review
```

4. Ask which area the operator wants to walk first, or take the argument.
   Whole-house walks go system by system, in the order below, and the
   operator may skip or reorder rooms.

## The systems checklist

A home inspector walks structure, roof, electrical, plumbing, and finish
in turn, so nothing is missed by wandering. The same discipline here:

| System | What to look at |
|---|---|
| Foundation | build, dependency, and toolchain: does it build from clean, are versions pinned, is the lockfile honest |
| Framing | module and package structure, boundaries, naming, dead code |
| Electrical | runtime wiring: entry points, configuration, environment, secrets handling, failure paths |
| Plumbing | data flow: inputs, validation, persistence, migrations, external calls |
| Safety | tests: coverage of the behavior the operator cares about, flaky or skipped tests, missing failing variants |
| Finish | documentation, help text, error messages, logs, UX and CLI ergonomics |
| Code compliance | CI, linting, formatting, licensing, review gates, anything the repository's own standards require |

For each system, offer the row's prompt in one or two sentences and wait.
Do not interrogate: the checklist reminds the operator what to look at,
and they decide what is worth writing down. If the operator says "nothing
here", move on.

**Look deeper only when pointed at something.** The operator says "the
retry logic in the client is wrong"; you open the client, find the retry
code, quote the lines, and ask what wrong means if it is not already
clear. You do not sweep the codebase looking for defects on your own.
That is what the operator invoked `/code-review` or `/shadow` for.

## Write each item down

For every observation, before moving on:

1. **Locate it.** Resolve the observation to concrete paths and, where it
   applies, `file:line` with a short verbatim excerpt. One bounded lookup;
   if you cannot find it, say so and record the operator's description as
   the locator.
2. **Grade it.** Ask only if the operator has not already said. Grades map
   to Docket priority:

   | Grade | Meaning | Priority |
   |---|---|---|
   | safety | demonstrated harm now: data loss, security exposure, broken main path | `critical` |
   | major | wrong behavior or a missing capability the operator needs | `high` |
   | minor | works, but not as wanted | `medium` |
   | cosmetic | polish, wording, layout | `low` |

   `critical` needs demonstrated harm, not suspicion. When in doubt, `high`.
3. **Type it.** `bug` for a broken contract, `task` for a change or
   addition, `feature` for a new capability, `chore` for a coherent batch
   of cosmetic items on one surface. One issue per distinct item; batch
   only cosmetic items that share a surface and a remedy.
4. **State the acceptance check.** What a worker checks, without this
   conversation, to know the item is done: a command and the failing
   variant it rejects, or `read-verified` with what to inspect. Draft it
   from the observation; confirm it in the same breath as the grade when
   it is not obvious. `/docket-plan`'s mutant rule applies to
   command-backed criteria at planning time; you supply the concrete
   failing variant so the planner has something to confirm.
5. **Dedupe.** Compare against the loaded punch list by cause and remedy,
   not by wording. A match gets the new evidence as a comment on the
   existing issue and no new create.

Keep the running punch list in scratch: local item id, area, grade, type,
title, locator, acceptance, dedupe verdict, and once filed the issue id.
Partial progress must survive an interruption.

## File the punch list

File at the end of each system, or when the operator says "file it".
Show the drafted items as a short table first (grade, title, locator);
one confirmation per batch, not per item. Then create each one from the
owning checkout.

The filing contract is shadow's
[worker-ready issue contract](../shadow/references/filing.md#worker-ready-issue-contract)
with these substitutions: the label is `inspect`, the type set above
applies, and the description follows this structure:

```text
[Only when the remedy touches authn/authz, secrets, crypto,
sandbox/permissions, a trust boundary, supply chain, or untrusted input at
a privilege boundary, as the first line:] Security gate required: this
remedy touches <the relevant categories>.

Observed: what the operator saw, and the consequence, in their terms.
Location: path(s) and file:line with a minimal verbatim excerpt; the
  revision inspected.
Wanted: the change the operator asked for, concrete enough to act on cold.
Acceptance: the check of resulting behavior and the failing variant it
  rejects, or read-verified with what to inspect.
Inspect fingerprint: <owning project>/<surface>/<cause>/<remedy class>.
```

```bash
docket issue create --json=v2 -t "<behavior and consequence, one line>" \
  -T <bug|task|feature|chore> -p <critical|high|medium|low> -l inspect \
  -f <remedy path> [-f <remedy path>] --scope '<glob bounding the work>' \
  --idempotency-key '<the fingerprint>' -d - <<'INSPECT_ITEM'
<description as above>
INSPECT_ITEM
```

- `-f` and `--scope` are never omitted; an item you cannot place on a path
  is held, not filed with an unrelated path.
- The idempotency key is the fingerprint, so a retried create cannot
  duplicate the item.
- No assignee, no parent, no routing label, no size label, no status
  beyond the default. Groom groups items under epics and routes them.
- Read each receipt back and record the issue id on the punch list.
  Verify the label, files, and scope persisted.

Dedupe, deduplication ledger, and receipt verification follow shadow's
[deduplicate before creating](../shadow/references/filing.md#deduplicate-before-creating)
section as written. Do not invent a second procedure.

## Final walkthrough: `inspect reinspect`

The contractor says the work is done. Walk the list again.

**Select the items.** The argument picks them: explicit issue ids; `since
<date>` for every `inspect` issue created after that date; a scope glob for
every one whose scope matches; bare `reinspect` for every open `inspect`
issue plus those closed since the last walkthrough the punch list records.

**Check each one against the current checkout**, at the sha you record
now, and give exactly one verdict:

- **pass**: the acceptance check ran and passed, or a `read-verified`
  criterion was inspected and holds. Quote the evidence.
- **fail**: the check ran and failed, or the inspected state still shows
  the observed defect. Quote the evidence and the failing output.
- **unverifiable**: the criterion cannot be checked from this checkout as
  written. Say what would verify it.

Run only the commands the acceptance criterion names or the read-only
probes needed to inspect state. Never run a proposed remedy.

**Record the verdicts.** Every item gets one comment stating the verdict,
the sha, and the evidence. Then:

- **pass** on an open issue: close it only after the operator confirms
  the batch of passes shown in the report table, with the compare-and-set
  `--if-version` read the [docket skill](../docket/SKILL.md) requires.
  Closing is the one mutation this skill makes beyond filing and
  commenting.
- **fail** on an open issue: the comment is the record; the issue stays
  where it is for groom.
- **fail** on a closed issue: this is a regression. Follow the project's
  reopen or new-regression convention, and link the prior issue when a
  new one is filed. A new issue goes through the filing section above.
- **unverifiable**: comment and leave the state unchanged.

Edit nothing else on any issue.

## Report

Print the punch list at the end of a walk, and the verdict table at the
end of a walkthrough. Short, and it says what happened:

- **Inspected:** the project, the sha, and the systems walked.
- **Filed:** every new issue id with grade and one-line title.
- **Attached:** every existing issue that received new evidence instead of
  a duplicate.
- **Held:** every item not filed, each with the reason: no path to name,
  project unavailable, operator withdrew it.
- **Walkthrough:** pass, fail, and unverifiable counts, the ids closed with
  the operator's confirmation, and any regression filed.

Say that no fixes were applied and that the items drain through
`/docket-groom` and the routes it assigns.
