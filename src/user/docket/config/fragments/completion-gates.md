---
fragment: completion-gates
version: 16
---
# Completion gates

Before `docket step record`, read your packet's `== GATES` section. It is the
declared gate set for your step, one line per gate, and a matched line carries the
trusted command the engine will run; run that command verbatim. `(pre)` marks a gate
that runs at claim. A line reading `unmatched` (with its reason in parentheses) names a gate
that has no trust entry and will not run: report it as a blocker rather than
resolving a command anywhere else.

Commit your final edits, then run every required gate once on that commit, from the
worktree you will record, using the trusted command verbatim and the engine's
documented execution settings. Issue each gate as its own top-level Bash call of
the bare command, such as `just tests`: no `sh -c` wrapper, no redirect, pipe, or
`&&` chain, because the permission allow rules match only the bare form. Save
each gate's full output to a file in your private step directory, so one run serves every later reading. A later change to a gate's
inputs invalidates its result. An amend or rebase that leaves
`git rev-parse 'HEAD^{tree}'` unchanged changes no input: keep those results rather
than rerunning. If a gate changes checked files, validate the resulting state before
recording. Run no gate after `docket step record`; the recorded step belongs to the
engine.

Finish every self-check you run (probes, mutants, and advisor review) before the
required gate set runs, so no gate run precedes a further edit.

For each gate, include its name, command, working directory, exit status, and actual
output in the persisted summary alongside the build and test evidence. Distinguish
passed, failed, blocked, and not run; a refused invocation is not a completed check.
Redact credentials from commands, output, and refusal reasons, and explicitly mark
each redaction.

Fix failures within your step's authorized scope. Report inherited failures,
unavailable prerequisites, or failures requiring broader changes with their evidence.
Do not record while a required gate remains unsatisfied unless the workflow explicitly
provides an exception. A failure reproduced on the base does not itself waive a gate.

A step that never runs `self-hygiene` parks on its findings regardless of
how many times its tests passed.

A refusal from the permission system, sandbox, or auto-mode classifier is a boundary
event, whether it concerns a gate or another action. Recognize the refusal from the
returned decision rather than one particular message string. Stop the affected action and report it. Retry only when the refusing
system's own recovery instruction authorizes it; changing the command's form does not supply
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

Never use `git stash` to establish that a failing gate pre-dated your change: linked
worktrees share `refs/stash`, so a concurrent push can change which entry a bare
`git stash pop` restores.

For a baseline comparison, resolve the intended base to a commit ID and record it
as the baseline; use `HEAD` only when verified to be that base. Export into a fresh
directory under your step's private temporary directory. Use an archive only
when the gate supports exported source trees: archives omit Git metadata and
submodule contents, and export attributes can omit or alter tracked files.

Allocate this attempt's export inside your assigned private step directory
(the brief's `<TMP>/<STEP-N>.d`, wherever one is assigned), set
`gate_baseline_dir` to it and `STEP_BASE_COMMIT` to the resolved baseline commit,
then run from your worktree:

```sh
gate_baseline_dir=$(mktemp -d "<TMP>/<STEP-N>.d/base.XXXXXX") &&
git archive --format=tar \
  --output="$gate_baseline_dir/base.tar" "$STEP_BASE_COMMIT" &&
mkdir "$gate_baseline_dir/tree" &&
tar -xf "$gate_baseline_dir/base.tar" -C "$gate_baseline_dir/tree"
```

Verify the entire sequence succeeded before running the gate in the extracted tree.
Reproduce its required prerequisites and record the baseline commit and comparison
evidence. A setup failure is inconclusive. If an archive cannot support the gate, use
the workflow's approved baseline procedure or report that the comparison is unavailable.

Do not create linked worktrees from this executor: baseline investigation stays
within the assigned checkout's scope and the step's private directory, and it
must not change your working tree or the shared stash.
