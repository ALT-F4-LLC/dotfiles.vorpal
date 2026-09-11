---
fragment: completion-gates
version: 7
---
# Completion gates

Before `docket step record`, identify every completion gate declared by your step in
the authoritative workflow definition. Your packet does not list them. Use
`docket trust list` to resolve each declared gate name to the exact command the engine
will run. The trust list establishes available commands; the workflow establishes
which apply. If either the required gate set or a command cannot be resolved, report
the blocker rather than guess.

Run every required gate after your final edits, from the worktree you will record,
using the trusted command verbatim and the engine's documented execution settings.
A later change to a gate's inputs invalidates its result. If a gate changes checked
files, validate the resulting state before recording.

For each gate, include its name, command, working directory, exit status, and actual
output in the persisted summary alongside the build and test evidence. Distinguish
passed, failed, blocked, and not run; a refused invocation is not a completed check.
Redact credentials from commands, output, and refusal reasons, and explicitly mark
each redaction. Preserve the remaining evidence faithfully.

Fix failures within your step's authorized scope. Report inherited failures,
unavailable prerequisites, or failures requiring broader changes with their evidence.
Do not record while a required gate remains unsatisfied unless the workflow explicitly
provides an exception. A failure reproduced on the base does not itself waive a gate.

The engine runs the gates again at record time, and a failure there parks the step;
the conductor resolves it under the run's standing rulings or escalates it to the
operator. Repeated test runs do not substitute for a missing gate: the implement
step that ran its tests six times still parked on one overlong line because it never
ran self-hygiene.

A refusal from the permission system, sandbox, or auto-mode classifier is a boundary
event, whether it concerns a gate or another action. Recognize the refusal from the
returned decision rather than one particular message string. Follow the governing
denial procedure: stop the affected action and report it. Retry only when that
procedure authorizes recovery; changing the command's form does not supply
authorization.

Disclose each denial in both your final step response and the persisted summary
artifact used by `docket step record`. Include the exact command as issued, the
available refusal reason verbatim, and the gate or purpose it served, subject to the
redaction rule above. If no explanation was supplied, say so rather than infer one.

If any retry occurs, report its command, authorization if any, and outcome beside the
original denial in both destinations. This reporting requirement does not authorize
a retry. A later success does not erase the refusal.
`sandbox-friction-hook.sh` and the friction ledger do not replace your report; report
observed denials even when no ledger entry is visible.

Never use `git stash` to establish that a failing gate pre-dated your change. Linked
worktrees share `refs/stash`; a concurrent push can change which entry a bare
`git stash pop` restores.

For a baseline comparison, use the workflow's recorded starting commit, not an
unverified `HEAD`. Export into a fresh directory under your step's private temporary
directory. Use an archive only when the gate supports exported source trees:
archives omit Git metadata and submodule contents, and export attributes can omit
or alter tracked files.

Allocate a private directory for this attempt beneath the literal `$TMPDIR`, set
`STEP_PRIVATE_TMP` to it and `STEP_BASE_COMMIT` to the recorded starting commit,
then run from your worktree:

```sh
STEP_PRIVATE_TMP=$(mktemp -d "$TMPDIR/step.XXXXXX") &&
gate_baseline_dir=$(mktemp -d "$STEP_PRIVATE_TMP/base.XXXXXX") &&
git archive --format=tar \
  --output="$gate_baseline_dir/base.tar" "$STEP_BASE_COMMIT" &&
mkdir "$gate_baseline_dir/tree" &&
tar -xf "$gate_baseline_dir/base.tar" -C "$gate_baseline_dir/tree"
```

Verify the entire sequence succeeded before running the gate in the extracted tree.
Reproduce its required prerequisites and record the baseline commit and comparison
evidence. A setup failure is inconclusive. If an archive cannot support the gate, use
the workflow's approved baseline procedure or report that the comparison is unavailable.

Do not create linked worktrees from this executor: creation and cleanup require
shared repository administrative writes outside its permitted scope. Keep your
working tree and the shared stash unchanged during baseline investigation.
