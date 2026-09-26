# Run checklists

Each reader and layer analyst reads its checklist, then reconciles it with the
definition the run pinned and the version the journals evidence. These rows
summarize the supplied docket-run and wave contracts: they establish no
universal engine semantics and authorize no operation. If a row and the
pinned contract disagree, record the disagreement, establish which contract
applied, and never judge a past execution against a newer checklist alone.

## Docket-run conductor

| Obligation | Evidence to inspect |
|---|---|
| Pre-activation provenance | Source and install comparison for Docket config and binary; treatment of retired `.docket/config` symlinks. An absent `.docket` is normally valid. Compare with the pinned target's stated preflight, including doctor if present. |
| Continuous execution | Reconciliation continues after each wave. An agent awaiting its parent's outstanding reply can legitimately end a turn; abandoning actionable work without a wait or terminal condition is different. |
| Fresh run state | Engine results or captured authoritative reads support each transition. The issue roster may legally grow during an active run under the pinned contract. |
| Conductor capability | The token stays in the session-private file: never in a brief, a tool output, a helper's prompt, or the resume prompt. A done or abandoned run removes it. |
| Wave launch | Installed absolute `wave.js` path, real supported args object, original rows and their model, effort, and variant. A source path or copied workaround does not prove the installed workflow ran. Harness args decoding alone is not a defect. |
| Roster and row hygiene | Activation's bound and promoted issue data establishes membership. Only human rows are excluded when prescribed; action and vote rows keep their semantics and stage numbering. |
| Executor completion | The assigned executor used its record protocol and supplied accepted evidence. A returned worker report does not prove engine recording succeeded. Token-file fallback is assessed only against the versioned contract. |
| Integration | The conductor verified the named commit existed, integrated a real commit in prescribed step order, preserved unrelated staged work, handled signing as configured, and surfaced conflicts through the target's gate. |
| Commit-blocked path | Any conductor action on the executor's behalf was specifically authorized by the pinned contract, and the resulting commit was verified before integration. |
| Worktree cleanup | Ownership ties each removed worktree and branch to this run. Unintegrated recorded work remained recoverable by the required named commit reference; ambiguous or unrelated work was not destroyed. |
| Close ordering | Usage back-fill, verify, close followed the target's sequence, and `run report`'s `Coverage:` lines were clean before the done report. Token usage is attributed from transcripts using the established deduplication and assignment rules. |
| Dispatch discipline | No empty or parked dispatch churn; an existing dispatch reconciled before a new one; no dispatch opened while the run was parked. A `next` refusal while a dispatch is open is not an empty ready set. |
| Verification result | The documented result shape and recorded step status were read. A mismatch after an accepted record can be expected reconciliation rather than a failed executor. |
| Operator gates | The actual artifact, diff, or numbers were presented. Notes preserve the operator's decision. A required issue for an accepted condition is present. |
| Exceptional acknowledgments | `--ack-reap` and `--accept-missing-usage` carried the explicit, applicable operator authorization the target requires. Unrelated permission or silence does not supply it. |
| Pause and resume | A paused run's resume prompt carried the session-only state the pause skill lists; the resuming session re-minted the capability and reconciled un-integrated shas before dispatching. |

## Wave and executors

| Obligation | Evidence to inspect |
|---|---|
| Staging | Rows sharing an engine stage may run concurrently; stages are awaited in ascending order and a missing stage follows the installed default. A conflicting engine-certified set is investigated at the certification boundary, not automatically blamed on concurrency. |
| Self-sufficient brief | Repo, assigned step, scope, required source context, artifacts, and record obligations are present in the persisted brief. Attribute missing inputs to the brief that should have supplied them. |
| Recording root | The worker recorded from its own checkout with worktree information when required, without invented store overrides or sibling-checkout probing. Out-of-scope problems used the installed gap path. |
| Null or failed spawn | No usable return leaves execution and recording uncertain. Reconcile actual task, claim, and step state before assuming no work happened. |
| Result acceptance | Separate workflow return status, worker report content, recorded engine result, and integration. Each establishes a different fact. |
| Routing | Recompute selected rows against the pinned policy's resolve, executor, security, escalation, and fallback rules. Compare requested routing with observed message-level models; metadata alone does not prove what served. |
| Journal and usage | Every expected agent has launch, completion or partial state, and transcript linkage. Missing records are coverage gaps; zero-spawn workflows need a different completion surface. |
| Packet regressions | Distinguish old stored empty diffs and stale summaries from newly produced defects. Use actual rendered inputs and payloads with temporal provenance. |
| Fix rounds and lanes | `loop-entered` ordinals and `step-routed` with detail `fix-loop` per issue; parallel writers colliding on the same files show as ancestry parks and claim conflicts, which are a charter or lane finding, not a budget one. |

## Panels and gates

| Obligation | Evidence to inspect |
|---|---|
| Panel seating | Every voter row carried the routing triple the pinned policy resolves; the tribunal launch used the installed `scriptPath` with a real args object. A seat that returned null is a silent seat, visible in `run report`'s vote coverage. |
| Casts | `vote show` per proposal: confidence, domain relevance, effective weight, and verdict per seat; a cast error surfaced rather than swallowed. |
| Tally and threshold | `vote result` against the rule's threshold; a rule whose outcome never differs from a plain human gate is a referral to docket-retro, not a defect. |
| Gate verdicts | `step gates` per parked or failed step: verdict, exit, `output_tail`, and `unmatched` reasons. An `unmatched` verdict is a missing trust entry, not a failing check. |
| Parks and escalation | Each park's `park_reason` and later `routing`; the three standing rulings applied only where they apply; every other park reached the operator with the actual artifact. A condition a seat raised was filed with `-l tribunal`, one issue per condition. |
| Reaps | `lease-reaped` with `data.forced` is a relay declaring a dead spawn; an expiry against a live holder is a lease-sizing referral. |

## Operator touches

Every point where the run waited on or asked a human, judged against the
docket skill's [automation reference](../../docket/references/automation.md).

| Touch | Evidence to inspect |
|---|---|
| Questions | Every `AskUserQuestion` in the driving transcripts and the digests' `operator_touches`: what was asked, whether an artifact, prior ruling, or standing rule already held the answer, and how long the run waited. |
| Parks and holds | `run-paused`, `step-held`, `waiting-human` routing, and `step-resolved` in the events trail: which standing ruling could have answered it machine-side, and which needed a vital condition. |
| Acknowledgments | `--ack-reap`, `--accept-missing-usage`, budget raises, and trust grants: each is vital only under its named condition; a routine acknowledgment is automatable. |
| Corrections | Operator messages that corrected the conductor or a seat: each is evidence of a missing check or contract, not only a slip. |
| Permission prompts | Denials and approvals the harness raised: a recurring prompt for a routine read is a configuration remedy; one guarding a boundary is vital. |
| Recurrence | The same automatable touch across issues, waves, or earlier runs is load-bearing when it stalled the run, and friction otherwise. |
