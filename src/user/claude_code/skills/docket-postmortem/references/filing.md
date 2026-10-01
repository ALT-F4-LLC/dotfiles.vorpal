# Reconcile and file

Read this before any issue write. This conversation owns filing for the
audit; the workflow's analysts and reconciler draft and never file. Audit
authorization permits findings intake once these conditions are met. It
never permits fixing or draining the queue.

## Eligibility

For every finding, recheck the applicable pinned contract, the refutations,
current source, and existing issue state. Use this disposition:

| Disposition | Action |
|---|---|
| Confirmed and unresolved | File, or attach recurrence to an existing issue. |
| Already tracked | Name the owning project and issue. Add new material evidence only; do not repeat the same comment each audit. |
| Fixed during the run's arc or since | Record the resolving artifact or commit and its verification. No new fix issue; a remaining install problem needs its own evidence. |
| Instance policy choice | Refer to docket-retro with evidence; do not file it as a shipped-definition defect. |
| Uncertain, refuted, or only an expected guard firing | Retain as a limitation or control observation; no defect filing. |
| Owning checkout or store unavailable, or the issue command blocked | Mark filing pending and deliver the worker-ready writeup. |

The audited run is terminal, so no filing can wake work on it. Other work
in the owning project can still be live: an issue this skill files carries
no routing label and no assignee, so `tend` and `docket-plan` cannot pick it
up until `docket-groom` routes it. Never invent a safe issue state or stop queue
consumers to create one.

## Route by owner and store

Definition, shared-corpus, workflow, and harness-source remedies normally
belong to the dotfiles project. Engine defects belong to the Docket codebase.
A bug in the audited repository belongs to that repository. An instance
override belongs in the policy referral unless it exposes a shipped defect.

Resolve the owner's actual checkout and Git identity from trustworthy project
metadata and filesystem evidence; do not assume a primary worktree is named
`main`. Verify the selected store as well as the checkout, since explicit
store overrides and legacy local stores can defeat machine-global
assumptions. Project-scoped listings must answer for this owner. Never
create in the launch repo intending to move the issue afterward.

Filing requires an installed compatible Docket binary whose startup effects
are understood. An issue write does not authorize unrelated schema migrations
or project registration. If the binary cannot satisfy that boundary, leave
filing pending with its concrete prerequisite; do not upgrade, register, or
migrate as part of a postmortem.

Run a verified creation operation from the owning checkout, using a subshell
or the tool's cwd parameter. Quote the checkout and every scope glob. Supply
issue text through supported structured input or a literal body file in the
audit directory; do not interpolate transcript text into shell code.

## Deduplicate before creating

Give the finding a stable identity derived from owning project and store,
affected source surface, violated behavior or root cause, and remedy class.
Do not include the run id or audit date in that defect identity. A
fingerprint helps lookup; semantic comparison decides whether findings share
a cause.

Check existing issues across relevant states, including prior issues under the `shadow` label.
An unresolved match receives only new evidence. A closed issue with a
confirmed new regression follows the installed project's reopen or
new-regression convention; link the prior issue. If existing issues cannot
be read, hold creation rather than blindly reproducing the last audit's
queue.

Maintain a ledger: local finding id, fingerprint, owner and store, intended
operation, attempt, returned issue id, and verified result. On a timeout or
ambiguous return, reconcile the store before retrying; pass a stable,
finding-derived `--idempotency-key` so a retried create cannot duplicate the
same issue. Record batch receipts as they arrive so partial success survives
interruption. Do not interpret a missing response as proof that creation
failed.

## Worker-ready issue contract

Create one issue per distinct load-bearing or friction defect; batch
paper-cuts only when they share an owning surface and coherent remedy. Before
each create, measure the issue against the docket skill's
[sizing reference](../../docket/references/sizing.md): pass its tier as
`--size` on every create, file a remedy whose acceptance describes two or
more independent outcomes as one issue per outcome, and keep a paper-cut
batch under the cap or split it into batches that are. Retain the original
local metadata contract when supported by the installed CLI:

- Title: concrete behavior and consequence, one line. Run, step, and session
  ids go in the description, not the title.
- Priority: load-bearing → `high`, friction → `medium`, paper-cut batch →
  `low`. Use `critical` only for a demonstrated defect actively causing
  material harm.
- Type: `bug` for a broken contract or implementation, `task` for an
  improvement or extraction, `chore` for a coherent paper-cut batch.
- Label: `shadow`. The label and the `Shadow fingerprint:` line keep this
  skill's former name so new findings match prior ones. Required file metadata (`-f`) names each remedy source
  path; required `--scope` globs bound that work. Verify both persisted after
  creation.
- No assignee, claim, run membership, routing label, or transition to
  in-progress. This skill supplies the intake; it never reserves execution.
- Remedy: on the highest rung of the
  [automation ladder](../../docket/references/automation.md#the-automation-ladder)
  that can carry it. A remedy that keeps or adds a human touch names its
  [vital condition](../../docket/references/automation.md#when-a-human-is-vital);
  one that removes a touch names the automated check that replaces it.
  Rewrite a draft whose refuters marked the remedy under-automated before
  filing it.

Use this description structure:

```text
[If applicable, first line:] Security gate required: this remedy touches <the
relevant categories from authn/authz, secrets, crypto, sandbox/permissions,
a trust boundary, supply chain, or untrusted input at a privilege boundary>.

Observed: behavior, expected contract, consequence, confidence.
Evidence: run/step/session/agent ids, UTC time, exact source locator and
minimal verbatim excerpt; command + refusal text + exit where material.
Countercheck: what the refuters tried and what was found.
Current status: what ran then, what exists now, and why the remedy is still needed.
Remedy: owning source path(s), concrete change or small diff; activation lag.
Automation: the ladder rung, and why no higher rung can carry it; for a human
gate, the vital condition it rests on.
Acceptance: a check of resulting behavior and the failing variant it rejects.
Shadow fingerprint: <stable identity>.
Memory ref: <exact entry path and slug, only for a memory finding>.
```

Preserve evidence accurately while omitting unrelated secrets and private
content. Mark redactions; retain a local locator for the full source. A
finding about a security boundary is still filed as a request. It carries no
permission for the worker to change that boundary or destroy uncommitted
work. Preserve the installed tend security-gate requirement and any
authorization already present in the actual worker session; this skill does
not manufacture or waive approval.

Acceptance criteria must be checkable by a worker without this conversation.
A command-backed criterion states the concrete failing variant or mutant the
local docket-plan contract requires. For a prose judgment without an
executable check, mark it `read-verified` and state what to inspect; never
use that label to hide an unperformed behavioral test, and never claim a
proposed acceptance check already ran.

Source fixes belong in the source repository, not the installed store. Name
`src/user/claude_code/...` or `src/user/docket/config/...` as appropriate,
and state that installed consumers use the fix after activation. A memory
remedy may instead update the specific mutable entry; do not invent a source
file for runtime memory. If required file or scope metadata cannot represent
that target, hold it with a precise routing limitation rather than supplying
unrelated paths.

Verify each receipt's id, title, files, labels, and empty assignee through a
permitted read path (`docket issue show`); verify scope from the create or
edit response itself, since `issue show` does not return it. Name the owning
project from the create call's target, not from a subsequent read. Correct
only this audit's own filing metadata when authorized and necessary; do not
use this allowance to edit other issue content or re-home unrelated work. A
wrong-project receipt is a filing error to surface, not a successful item to
count.

## Review and closure

Every confirmed finding must have a project-qualified issue id or a reason
it was not filed. Preserve instance-policy referrals and findings resolved
during the run without counting them as open defects. Name affected trust
boundaries separately when relevant. Include the evidence coverage,
unresolved limitations, the absolute audit log path, and the condition the
next postmortem of a run should look at first.

Persist the review and final ledger to the audit directory before delivery.
If storage was denied, deliver the full review through the conversation and
say explicitly that no durable audit log was created.

Say that no fixes were applied. Filed issues drain through `docket-groom`
routing into `tend` or a docket-plan → docket-run execution; do not start
that work.
