# Reconcile and file

Read this before any issue write. One coordinator owns filing for the audit.
Observation authorization permits findings intake after these conditions are
met; it never permits fixing or draining the queue.

## Eligibility

For every finding, recheck the applicable historical contract, counterevidence,
current source, affected work, and existing issue state. Use this disposition:

| Disposition | Action |
|---|---|
| Confirmed, unresolved, affected observed work terminal | File or attach recurrence to an existing issue. |
| Based only on incomplete work, or filing may trigger workers into affected observed work | Hold pending and give the complete writeup in the review. Completed evidence elsewhere does not remove this collision risk. |
| Already tracked | Name the owning project and issue. Add new material evidence only; do not repeat the same comment each sweep. |
| Fixed during the observed arc | Record the resolving artifact/commit and verification. No new fix issue; a remaining install problem needs its own evidence. |
| Instance policy choice | Refer to docket-retro with evidence; do not file it as a shipped-definition defect. |
| Uncertain, contradicted, or only an expected guard firing | Retain as a limitation or control observation; no defect filing. |
| Owning checkout/store unavailable or issue command blocked | Mark filing pending and deliver the worker-ready writeup. |

A run is terminal only with reliable run/task evidence and settled relevant
children. A loop also requires confirmed scheduling stop and settled current
work. Paused/waiting-human is not terminal. Unknown state stays pending. Recheck
before each batch that could wake a queue consumer; these checks do not lock the
repository or guarantee no other session can begin afterward. If the required
noninterference needs an atomic guarantee, hold the finding until an explicitly
non-dispatchable intake mechanism is available. Never invent a safe issue state
or stop queue consumers to create one.

## Route by owner and store

Definition, shared-corpus, workflow, and harness-source remedies normally belong
to the dotfiles project. Engine defects belong to the Docket codebase. A bug in
an observed repository belongs to that repository. An instance override belongs
in the policy referral unless it exposes a shipped defect.

Resolve the owner's actual checkout and Git identity from trustworthy project
metadata and filesystem evidence. Do not assume a primary worktree is named
`main`. Verify the selected store as well as the checkout; explicit store
overrides and legacy local stores can defeat machine-global assumptions.
Project-scoped listings must answer for this owner. Never create in the launch
repo intending to move the issue afterward.

Filing requires an installed compatible Docket binary whose startup effects are
understood. An issue write does not authorize unrelated schema migrations or
project registration. If the binary cannot satisfy that boundary, leave filing
pending with its concrete prerequisite; do not upgrade, register, or migrate as
part of shadow.

Run a verified creation operation from the owning checkout, using a subshell or
the tool's cwd parameter. Quote the checkout and every scope glob. Supply issue
text through supported structured input or a literal body file in the permitted
audit directory; do not interpolate transcript text into shell code.

## Deduplicate before creating

Give the finding a stable identity derived from owning project/store, affected
source surface, violated behavior/root cause, and remedy class. Do not include
the audit date or session ID in that defect identity. A fingerprint helps lookup;
semantic comparison decides whether findings share a cause.

Check existing issues across relevant states, including prior shadow issues.
An unresolved match receives only new evidence. A closed issue with a confirmed
new regression follows the installed project's reopen/new-regression convention;
link the prior issue. If existing issues cannot be read, hold creation rather
than blindly reproducing the last sweep's queue.

Maintain a ledger: local finding ID, fingerprint, owner/store, intended operation,
attempt, returned issue ID, and verified result. On a timeout or ambiguous return,
reconcile the store before retrying; pass a stable, finding-derived
`--idempotency-key` so a retried create cannot duplicate the same issue. Record
batch receipts as they arrive so partial success survives interruption. Do not
interpret a missing response as proof that creation failed.

## Worker-ready issue contract

Create one issue per distinct load-bearing or friction defect; batch paper-cuts
only when they share an owning surface and coherent remedy. Retain the original
local metadata contract when supported by the installed CLI:

- Title: concrete behavior and consequence, one line. Session/run IDs go in the
  description, not the title.
- Priority: load-bearing → `high`, friction → `medium`, paper-cut batch → `low`.
  Use `critical` only for a demonstrated defect actively causing material harm.
- Type: `bug` for a broken contract/implementation, `task` for an improvement or
  extraction, `chore` for a coherent paper-cut batch.
- Label: `shadow`. Required file metadata (`-f`) names each remedy source path;
  required `--scope` globs bound that work. Verify both persisted after creation.
- No assignee, claim, run membership, or transition to in-progress. Shadow
  supplies the intake; it never reserves execution.

Use this description structure:

```text
[If applicable, first line:] Security gate required: this remedy touches <the
relevant categories from authn/authz, secrets, crypto, sandbox/permissions,
a trust boundary, supply chain, or untrusted input at a privilege boundary>.

Observed: behavior, expected contract, consequence, confidence.
Evidence: project/session/run/agent IDs, UTC time, exact source locator and
minimal verbatim excerpt; command + refusal text + exit where material.
Countercheck: what could have invalidated this claim and what was found.
Current status: what ran then, what exists now, and why the remedy is still needed.
Remedy: owning source path(s), concrete change or small diff; activation lag.
Acceptance: a check of resulting behavior and the failing variant it rejects.
Shadow fingerprint: <stable identity>.
Memory ref: <exact entry path and slug, only for a memory finding>.
```

Preserve evidence accurately while omitting unrelated secrets and private
content. Mark redactions; retain a local locator for the full source. A finding
about a security boundary is still filed as a request. It carries no permission
for the worker to change that boundary or destroy uncommitted work. Preserve the
installed tend security-gate requirement and any authorization already present
in the actual worker session; shadow does not manufacture or waive approval.

Acceptance criteria must be possible for a worker without this conversation.
For command-backed criteria, give the command, expected observable result, and
the concrete failing variant/mutant required by the local docket-plan contract.
For a prose judgment without an executable check, mark it `read-verified` and
state what to inspect; do not use that label to hide an unperformed behavioral
test. Never claim a proposed acceptance check was already run.

Source fixes belong in the source repository, not the installed store. Name
`src/user/claude_code/...` or `src/user/docket/config/...` as appropriate, and
state that installed consumers use the fix after activation. A memory remedy
may instead update the specific mutable entry; do not invent a source file for
runtime memory. If required file/scope metadata cannot represent that target,
hold it with a precise routing limitation rather than supplying unrelated paths.

Verify each receipt's project, ID, title, files, scopes, labels, and empty
assignee through a permitted read path. Correct only the coordinator's own
filing metadata when authorized and necessary; do not use this allowance to
edit other issue content or re-home unrelated work. A wrong-project receipt is
a filing error to surface, not a successful item to count.

## Review and closure

Every confirmed finding must have a project-qualified issue ID or a reason it
was not filed. Preserve instance-policy referrals and findings resolved during
the run without counting them as open defects. Name affected trust boundaries
separately when relevant. Include the evidence coverage, unresolved limitations,
absolute log path, and the next condition another shadow should watch first.

Persist the review and final ledger before sending. Collect and stop this
audit's remaining helpers and monitors, preserving partial evidence; never stop
observed work. If storage was denied, deliver the full review through the
permitted result channel and explicitly say no durable audit log was created.

Say that no fixes were applied. Filed issues drain through `tend` in their owning
repos or through a docket-plan → docket-run execution. Do not start that work.
