---
name: corpus-check
description: >-
  Use after a batch of prose changes to src/user/claude_code or
  src/user/docket/config, or on "audit the corpus", "check corpus coherence",
  "/corpus-check", "did my prose edits break anything", or "is the
  skill/docket config still consistent". Audits both trees for mechanical
  reference breakage (runs crossref-check first) and semantic drift
  (contradictions, terminology, staleness) through a multi-agent workflow,
  then files the findings as Docket issues; never edits the checkout.
argument-hint: "[since ref, e.g. main or a commit sha]"
---

# corpus-check

Run this skill inline in the main session. You run the gate, launch the
audit, and file the issues. The checkout is read-only: the only writes are
Docket issues and scratch files. A fix is an issue's work, never this
skill's.

**Automation first is the primary goal of every remedy.** Per the docket
skill's [automation reference](../docket/references/automation.md), a class
of drift a deterministic check could catch gets a proposed rule for
`.docket/bin/crossref-check` or a test beside the prose fix, so the next
audit needs fewer judgment calls. An issue names that rung in its Remedy.

## Scope

Two trees, always both, whole-corpus (not diff-scoped — drift can predate
the working tree, the same reasoning `frozen-drift-check` uses):

- `src/user/claude_code`: `CLAUDE.md`, `skills/**/*.md`, `agents/*.md`,
  `workflows/*.js`.
- `src/user/docket/config`: `contracts/*.md`, `fragments/*.md`,
  `workflows/*.toml`, `policy.toml`, `schemas/*.json`, `README.md`.

Out of scope unless the operator explicitly widens it: `hooks/`,
`settings.rs`, `statusline.sh`, `allowed_signers`, `src/user/docket/bin`.
Never file a remedy that edits `src/user/claude_code/references/working-agreement.md`
or `src/user/claude_code/CLAUDE.md` — the operator's own working agreement,
owned outside this corpus's style authority; report drift there as an
operator decision, never as an issue to work. Never run `just activate`.

`$ARGUMENTS` optionally names a git ref (branch or SHA). Pass it through as
the workflow's `sinceRef` arg (step 2) when given, else pass `null`. It is
informational context only, passed to every reading agent as a note about
what changed recently: it never skips or deprioritizes a file. The workflow
reads every file in full and runs every cross-boundary check regardless,
since drift a stale reference introduces is not confined to files the diff
touched.

Confirm the Docket project bound to this checkout before step 1, since cwd
picks the project. If no project answers, stop and say so; do not register
one.

## 1. Mechanical gate

Run `just crossref-check` first, from the repository root. It is fast, free
of judgment calls, and catches dead paths, dead relative links and heading
anchors, dead `/docket-*` references and skill names in a description,
schema references with no file on disk, undeclared workflow executors,
gate names with no `just` recipe or `PROJECT_GATES` row, bad routing
labels, name/stem mismatches, and stale Contents line counts. Read
`.docket/bin/crossref-check` for the exact rule set.

If it fails, read every failure line and save the output to scratch. Each
line is an unambiguous finding (a name either resolves or it doesn't); it is
filed in step 4 with the semantic findings, grouped by owning file. A failing
gate does not stop the audit: the audit reads without editing, so a
mechanically broken corpus is still a valid base. Report the gate's result
beside the audit's.

## 2. Semantic audit

Invoke by `scriptPath`, always, at the installed path
`~/.claude/workflows/corpus-check.js`, expanding `~` to a literal absolute
path yourself first (`echo ~` or your session's known home). The Workflow
tool does not expand `~` and resolves a relative path against the target
repo's cwd, not the dotfiles source tree. The installed copy under
`~/.claude/workflows` is also the only one the tool may launch, and the
only one guaranteed to match this session's own build (the source file
under `src/user/claude_code/workflows/corpus-check.js` may have moved
since the last `just activate`). A missing installed file means the corpus
was never activated after this skill was added: report that, don't launch
the source copy instead.

```
Workflow({ scriptPath: "<absolute installed path to corpus-check.js>", args: {sinceRef: "<value or null>"} })
```

This fans out one agent per file over both trees (sharded by line range for
any file over 1500 lines, for example `docket-run/SKILL.md` and
the nine rendered `workflows/<workflow>.js` lane scripts; the workflow measures sizes at run time), runs a
completeness pass that re-dispatches any file or range nothing covered,
then a cross-boundary pass pairing claims one tree makes about the other,
then verifies raw findings in per-file batches (three refuters per batch,
each leading from a different angle, majority-uphold) within an agent
budget fixed before the read fan-out.
The workflow returns one JSON object. `findings` holds only
majority-survived findings, each carrying its file, location, quote,
counterpart, severity, and a proposed fix. `unverified` holds every
finding the budget could not cover or that received no vote;
`verificationPartial`, `verifiedCount`, and `unverifiedCount` say how far
verification got. `coverage` is `{complete, gapsFound, refilled,
uncovered}`: `refilled` lists the gaps the completeness pass re-read and
`uncovered` the ones it could not, each `{file, range, reason}`. `summary`
is a one-line digest of the same counts. When `verificationPartial` is
true, report the unverified findings by file as unaudited, never clean;
when `coverage.complete` is false, name every `uncovered` span. Never
report exhaustive coverage the run itself flagged as partial.

If the workflow throws or returns nothing, say so and stop. Do not
substitute a smaller manual read as if it satisfied the step.

## 3. Classify each finding

- **Mechanical** (a gate failure from step 1, or a materially new check the
  audit surfaced): the remedy is the one-for-one fix, plus a candidate rule
  for `.docket/bin/crossref-check` when the audit surfaced a class the gate
  misses.
- **Unambiguous prose fix** (a stale claim, a dropped word, a terminology
  outlier against a clearly dominant term, a wording asymmetry between two
  files that both audits agree should read one way): the remedy is the
  before and after.
- **Needs operator decision** (two files each state a currently-correct but
  incompatible design choice, a deliberate-looking deviation with no
  recorded reason, a schema correction whose cascade is expensive, or
  any finding with `needsOperatorDecision` true): file it as its own issue
  titled for the decision, with the options and a recommendation in the
  body, so the executing worker does not guess.
- **Protected file** (`CLAUDE.md`, `working-agreement.md`): carried to the
  report as an operator decision; never filed.

Frozen-file fixes need a version bump, decided by the file changed. The
issue's Remedy names it so the executing worker applies it:

- `contracts/*.md`, `fragments/*.md`: bump frontmatter `version:`. A changed
  body demands strictly greater; do not bump without a body change.
- `workflows/*.toml`: bump `[pipeline].version` and add the entry for it at
  the top of `changelogs/<name>.md`, in that file's existing style; the TOML
  carries no version comment.
- `schemas/*.json`: cannot be edited in place. A fix here means a new
  `<name>@<N+1>.json` plus a `payload =` update in every workflow step that
  declared the old version, a `payload:` frontmatter update and `version`
  bump in every contract that pinned it, and a `[pipeline].version` bump with
  a changelog entry for each such workflow. Count all of these in the sizing.
  Treat this as expensive by default: file it as a decision issue, not a
  ready remedy, unless the operator already asked for the schema cascade.
- `policy.toml`: carries a `[policy].version`, but `frozen-drift-check` does
  not gate it; bump `version` and add the entry at the top of
  `changelogs/policy.md` when the body changes.
- `skills/**/*.md`, `agents/*.md`, `README.md`: no version field.

Never spend a version bump on a comment that only flags an unresolved
question (a TODO, a "needs operator decision" note) with no other content
change; that forces a second bump later. File the question as a decision
issue instead of a remedy that touches a frozen file.

## 4. File the issues

The filing contract is docket-postmortem's
[worker-ready issue contract](../docket-postmortem/references/filing.md#worker-ready-issue-contract)
and [deduplicate before creating](../docket-postmortem/references/filing.md#deduplicate-before-creating)
sections as written, with these substitutions: the label is `corpus-drift`,
the fingerprint line is `Drift fingerprint:`, and the priority and
description follow this section. Read both sections before the first write.
The dotfiles project owns every issue here, since the corpus lives in this
checkout.

**Group the survivors.** One issue per independent outcome, as the sizing
reference requires: a finding a worker could deliver and verify without the
file's other findings is its own issue. Batch findings into one issue per
owning file only when they are wording-only `chore` drift sharing one
remedy, or one-for-one mechanical rewrites that a single verification
covers. A gate failure files with the finding that explains it. A decision
finding is always its own issue.

**Priority and type.** A finding that breaks behavior (a dead reference a
worker would follow into a wrong action, a contradiction between two rules a
run applies) is a `bug` at `high`. A stale claim or terminology outlier is a
`task` at `medium`. Wording-only drift is a `chore` at `low`. A decision
issue is a `task` at `medium`. A batched issue takes the type and priority
of its highest-ranked finding.

**Fingerprint.** `corpus-check/<repo-relative path>/<claim or rule>/<remedy class>`,
carrying the lead finding's identity. It carries no line numbers, run id, or
audit date, so a repeated audit of an unchanged corpus returns the same
issue.

**Idempotency key.** The key is the fingerprint, verbatim. A repeated create
with it returns the original issue, open or closed, so it covers retries and
repeat audits of unchanged drift. When the dedupe listing finds the finding
again under a closed issue without `wont-do`, that is a regression: follow
filing.md's new-regression convention, link the prior id in the body, and
append `/after-<prior issue id>` to the key so the create does not replay
the closed issue. A closed issue labelled `wont-do` files nothing; record its
id. A closed decision issue without `wont-do` records a chosen option: link
it and file nothing, since the option's work belongs in its own issue. Ask
in each decision issue that a leave-as-is answer close it with `wont-do`.

**Description:**

```text
[Only when the remedy touches authn/authz, secrets, crypto, sandbox or
permissions, a trust boundary, supply chain, or untrusted input at a
privilege boundary, as the first line:] Security gate required: this remedy
touches <the relevant categories>.

Observed: the claim as written (file:line, minimal verbatim excerpt) and the
counterpart that contradicts it.
Evidence: the gate line or the audit finding, with the refuters' tally.
Countercheck: what the refuters tried and what was found.
Remedy: per finding, the kind, the before and after, the automation rung,
and the version bump when a frozen file changes.
Acceptance: the check of resulting behavior and the failing variant it
rejects, plus the gates below.
Drift fingerprint: <identity>.
```

Acceptance for every issue includes:

```bash
just crossref-check
just frozen-drift-check
bash tests/contract-corpus.test.sh
bash tests/contract-includes.test.sh
bash tests/contract-cluster-keys.test.sh
bash tests/frozen-drift-check.test.sh
bash tests/crossref-check.test.sh
just doc-validate
just prose-gates
bash tests/ci-suite-wiring.test.sh
```

State in the Acceptance that a failure means a fix was wrong or incomplete,
not a stale suite, and that a `prose-gates` failure means a fix reworded a
sentence a suite pins verbatim: restore that sentence, or re-anchor the pin
in the same change when the rewording was the intended fix.

When the session can launch agents, launch the `advisor` agent on the drafted
issue set before filing it, and fold its input in. File with `docket issue
create`, `-f`, `--scope`, `--size` and `--idempotency-key` set, no routing
label, no assignee; read each receipt back and record the id.

## 5. Report

State what the mechanical gate caught, what the semantic audit found and
verified, every issue filed with its id and grade, every finding attached to
an existing issue instead of a duplicate, every finding held with its reason,
and every protected-file item left for an operator decision, with enough
context to act on it without re-reading this session. Name any file or line
range the workflow could not cover so "audited" never reads as "audited
everything" when it wasn't. Say that no fixes were applied; filed issues
drain through `docket-groom` into a `docket-plan` and `docket-run` execution
or direct work. Do not claim `just activate` ran; it didn't, and the
installed corpus under `~/.docket/config` and `~/.claude` lags this checkout
until the operator runs it.
