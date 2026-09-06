# Local execution checklists

Read only the relevant checklist, then reconcile it with the target's actual
installed definition and the version evidenced by the run. These rules summarize
the supplied Docket/tend contracts; they do not establish universal engine
semantics or authorize shadow to perform any observed operation. If this file
and the target disagree, record the disagreement and establish which contract
applied. Never judge a past execution solely against a newer checklist.

## Docket-run conductor

| Obligation | Evidence to inspect |
|---|---|
| Pre-activation provenance | Source/install comparison for Docket config and binary; treatment of retired `.docket/config` symlinks. An absent `.docket` is normally valid. Compare with the current target's stated preflight, including doctor if present. |
| Continuous execution | Reconciliation continues after each wave. An agent awaiting its parent's outstanding reply can legitimately end a turn; abandoning actionable work without a wait or terminal condition is different. |
| Fresh run state | Engine results or captured authoritative reads support each transition. The issue roster may legally grow during an active run under the installed contract. |
| Parent/conductor boundary | Parent forwards launches, gates and results; conductor owns its run. Arguments are not silently rewritten while relaying. Multi-run messages retain run identity. |
| Wave launch | Installed absolute `wave.js` path, real supported args object, original rows and their model/effort/variant. A source path or copied workaround does not prove the installed workflow ran. Harness args decoding alone is not a defect. |
| Roster and row hygiene | Activation's bound/promoted issue data establishes membership. Only human rows are excluded when prescribed; action and vote rows keep their semantics and stage numbering. |
| Executor completion | The assigned executor uses its record protocol and supplies accepted evidence. A returned worker report does not prove engine recording succeeded. Token-file fallback is assessed only against the versioned contract. |
| Integration | Conductor verifies the named commit exists, integrates a real commit in prescribed step order, preserves unrelated staged work, handles signing as configured, and surfaces conflicts through the target's gate. No shadow integration or cleanup. |
| Commit-blocked path | Any conductor action on the executor's behalf is specifically authorized by the installed contract, and the resulting commit is verified before integration. |
| Worktree cleanup | Ownership ties each removed worktree/branch to this run. Unintegrated recorded work remains recoverable by the required named commit reference; ambiguous or unrelated work must not be destroyed. |
| Close ordering | Usage backfill, verify, close follow the target's sequence. Token usage is attributed from transcripts using the established deduplication and assignment rules. |
| Dispatch discipline | No empty or parked dispatch churn; existing dispatch reconciled before a new one. A next refusal while a dispatch is open is not an empty ready set. |
| Verification result | Read the documented result shape and recorded step status. A mismatch after an accepted record can be expected reconciliation, rather than a failed executor. |
| Operator gates | The actual artifact/diff/numbers are presented. Notes preserve the operator's decision. A required issue for an accepted condition is present. |
| Exceptional acknowledgments | `--ack-reap` and `--accept-missing-usage` have the explicit, applicable operator authorization required by the target. Unrelated permission or silence does not supply it. |

No completed wave, final assistant message, or report size alone closes the
observation. Integration, outstanding agents, parked gates, and final run state
remain part of the arc.

## Wave and executors

| Obligation | Evidence to inspect |
|---|---|
| Staging | Rows sharing an engine stage may run concurrently; stages are awaited in ascending order and missing stage follows the installed default. A conflicting engine-certified set is investigated at the certification boundary, not automatically blamed on concurrency. |
| Self-sufficient brief | Repo, assigned step, scope, required source context, artifacts and record obligations are present. Attribute missing inputs to the brief that should have supplied them. |
| Recording root | The worker records from its own checkout with worktree information when required, without invented store overrides or sibling-checkout probing. Out-of-scope problems use the installed gap path. |
| Null/failed spawn | No usable return leaves execution and recording uncertain. Reconcile actual task, claim and step state before assuming no work happened or proposing lease cleanup. |
| Result acceptance | Separate workflow return status, worker report content, recorded engine result, and integration. Each establishes a different fact. |
| Routing | Recompute selected rows against the pinned policy's resolve/executor/security/escalation/fallback rules. Compare requested routing with observed message-level models; metadata alone does not prove what served. |
| Journal and usage | Every expected agent has launch, completion/partial state, and transcript linkage. Missing records are coverage gaps; zero-spawn workflows need a different completion surface. |
| Packet regressions | Distinguish old stored empty diffs/stale summaries from newly produced defects. Use actual rendered inputs and payloads with temporal provenance. |

## Tend loop and worker

| Obligation | Evidence to inspect |
|---|---|
| No Docket execution run | Tend follows its issue loop rather than invoking docket-plan/docket-run or creating/activating a run, unless its own contract has explicitly changed. |
| Scheduler ownership | `/loop` provides recurrence; bare tend does one pass. Inspect self-paced wakeup or fixed cron according to the actual invocation. No future tick does not make a current pass complete. |
| One worker | At most one tend issue worker runs in the shared checkout at a time, including follow-ups. Actual execution/task timestamps establish overlap; file mtimes and registration lifetime do not. |
| Queue exclusions | Skip issues reserved by nonterminal runs, assigned issues, and statuses the target excludes. Verify current scope and select in prescribed order. |
| Quiet empty poll | No unsolicited empty-queue narration. Re-poll queued work as the target requires; compare fixed-schedule behavior with that actual mode. |
| Security gate | Before a sensitive change, the worker session has the target's required applicable operator authorization for authn/authz, secrets, crypto, sandbox/permissions, trust boundaries, supply chain, or untrusted input at a privilege boundary. |
| Conductor role | Loop gathers enough context to brief the worker; it does not silently implement or debug the whole fix itself. |
| Blocked disposition | An unclear ask, prerequisite failure, or failed verification after the permitted follow-up is moved to the target's blocked/review path and explained. It is not retried every tick. |
| Worker seating | Follow the installed requirement for Workflow, built-in type, explicit supported model and effort, and the tier ruling adjacent to the actual agent call. Display-only phase metadata does not establish an applied option. |
| Verification | A report supplies evidence of the relevant behavior. Apply the prescribed follow-up limit; absence of evidence does not authorize landing. |
| Landing | Commit workflow when files changed, then close comment with commit hash(es), then issue closure, in the target's order. Multiple issues are not silently batched into one commit cycle. |
| Operator report | Every tended issue gets its required visible line with ID, title and commit hash(es), or an explicit no-change result. |
| Stop | The operator can stop recurrence; expiration or runtime failure may also stop it and must be reported accurately. Empty queue is not completion of a still-armed loop. Settle current work separately. |

For another execution skill, derive an equivalent checklist from its actual
contract. Keep a bounded list of observable obligations and their evidence
surfaces rather than copying every emphatic sentence into another permanent
definition. A disagreement or omission matters through its consequence.
