---
fragment: rerun-discipline
version: 10
---
# Re-run discipline

Treat the change-summary's build and test results as claims to verify under the
evidence rules. Engine gate results recorded only in the ledger are unavailable
to a review step until supplied in its context or retrieved. Do not infer their
outcomes from their absence.

- `judge-testing` independently reproduces the change's claimed test
  evidence in full: one routine full reproduction per panel. Identify the
  commands and evaluated state; report missing or blocked evidence explicitly.
- Every other lens runs only the commands needed to investigate a specific
  candidate finding. State the question before running; any resulting finding
  names the command and explains why its result matters. A probe need not
  produce a finding to have been justified.
- A gate reported `FAILED` in your available review inputs, or whose recorded
  outcome your finding disputes, is yours to reproduce regardless of lens.
  Reproduce the gate as defined; a narrower diagnostic does not replace it.
  These required reproductions can repeat commands from the routine run. When
  the command, inputs, or execution are unavailable, report the verification gap
  and continue independent review work.

Run against a fixed snapshot of the intended candidate or comparison base.
Record which state was actually exercised. A checkout of a commit does not
include staged, unstaged, or untracked candidate changes; include all relevant
candidate inputs in the private snapshot before relying on its results. If the
intended state cannot be established, keep the dependent conclusion unverified.

Create a fresh, uniquely allocated directory beneath the inherited `$TMPDIR`
for each step attempt and set `STEP_PRIVATE_TMP` to it; creating the directory
alone does not redirect those writes. Set each command's `TMPDIR` and relevant
tool-specific paths to redirect its private temporary, build-output, and
writable cache paths beneath it, including `GOCACHE`; for Go, account for
`GOTMPDIR` and `GOMODCACHE` as well.
Follow the evidence rules for fresh execution versus cached results. Use a
private source copy when a command can write into the source tree or sibling
edits could change its inputs. Isolate other mutable resources the command uses,
such as test databases and ports, before concurrent execution.

Triaging an environment signature precedes attributing failure to the change.
Apply the evidence rules: the signature alone neither proves a code defect nor
exonerates the code. Preserve blocked or inconclusive results as such.

For output comparisons, write both outputs to regular files under the step's
private directory and diff those files. Preserve each producer's exit status
and stderr; equal output files do not establish equivalent successful runs if a
producer failed. Distinguish differences from a comparison error. Do not use
process substitution or stdin-backed paths for these comparisons, or seek a
sandbox lift to make them work. A `/dev/fd/N` refusal in the record concerns the
comparison mechanism; it does not establish a defect in the reviewed change.

A code-mutating probe, including a positive control or planted mutant, runs
only in a private copy of the state being tested. Keep the mutation confined
to that copy and preserve the control result and mutation diff as evidence.
Never plant or undo a scratch mutation in the shared checkout.

Never use `git stash` to obtain a clean tree: the stash stack is shared by the
repository's worktrees. For a committed comparison base, resolve the intended
base to a commit ID, set `STEP_BASE_COMMIT` to it, and export that commit with
`git archive` into a fresh directory beneath `$STEP_PRIVATE_TMP`, extracting
the archive into a `tree` subdirectory there. Use `HEAD` only when verified to
be the intended base. An archive omits Git metadata and submodule contents;
when the comparison needs them, report the comparison as unavailable rather
than creating a linked worktree.

Keep logs, comparison files, and state records outside disposable export
directories, and retain them for review and reconciliation. Remove only export
directories created by your step, after preserving the evidence.
