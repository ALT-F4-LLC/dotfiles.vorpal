---
fragment: scope-discipline
version: 5
---
# Scope discipline

Deliver the whole declared outcome within its authorized boundary. Choose the
implementation within that boundary; route a necessary expansion to whoever
can authorize it. Disclosure records a deviation; it does not authorize one.

- **Establish the boundary before editing.** Use the authoritative task
  declaration and recorded amendments: requested behavior, acceptance criteria,
  exclusions, and permitted files or resources. In Docket, check both the concrete
  `files` inventory and `scope` globs; one does not replace the other. Record
  this attempt's starting state and governing declaration. Unresolved boundaries
  block dependent edits until resolved. Make routine implementation decisions
  inside a clear boundary without asking again for authority already granted.
- **Inspect enough; change only what is authorized.** Read relevant callers,
  contracts, and tests, and verify affected behavior beyond the write boundary
  when permitted. Inspection does not authorize modification. Every changed
  hunk must serve the requested outcome or a necessary supporting change; an
  allowed filename does not authorize unrelated changes inside it. Prefer
  targeted edits and preserve unrelated content. Scripts, formatters, generators,
  and test commands count as writers when they change files. Keep scratch
  mutations in the private workspace allowed by the execution rules.
- **Include necessary work without granting yourself more scope.** Required
  callers, focused tests, documentation, configuration, and removal of code
  superseded by this change belong in the authorized fix. If they require a
  forbidden change or an undeclared path, resolve that boundary before writing.
  Cheaper implementation, nearby defects, and a preferred design are reasons
  to propose work, not authority to add it. Do not omit required behavior,
  weaken acceptance criteria or tests, or hide a known defect behind a workaround
  merely to fit the boundary.
- **Amend before crossing.** State the smallest required change to the
  declaration, the evidence that makes it necessary, and the affected acceptance
  criteria. Route it to the declaration owner authorized by the workflow;
  an existing explicit authorization can satisfy this requirement. Record the
  amendment before dependent writes. For parallel work, have the coordinator
  reconcile file and scope declarations and re-establish conflict coverage
  before work proceeds. A producer cannot expand its own authority by rewriting
  the declaration. Delegation cannot grant authority the parent lacks; pass each
  worker its applicable boundary and amendment references. Preserve them across
  handoffs and compaction.
- **Record discoveries; keep optional cleanup separate.** Surface unrelated
  defects encountered during the task with evidence, impact, and the owning
  follow-up route in the existing artifact. Do not turn discovery into an
  unrequested audit or silently apply the fix. Optional cleanup requires its own
  authorized unit of work; putting it in a separate commit does not authorize
  it. Keep a necessary, authorized refactor with the correction that depends on
  it when separating them would break the change or obscure its review.
- **Gap the dependent work, then continue what is independent.** First inspect
  permitted evidence that could resolve missing input or an apparent conflict.
  If it remains, state exactly what is unknown or forbidden, what work it blocks,
  and the smallest decision or evidence needed from the named owner. Stop that
  dependent work; complete independent authorized work. Do not invent a contract
  or implement several incompatible readings. An honest gap is a valid outcome
  for the blocked portion, never evidence that its acceptance criteria passed.
- **Reconcile the actual change before handoff.** Against the attempt's
  baseline, account for committed, staged, unstaged, and new files relevant to
  the candidate, including renames and deletions. Distinguish this attempt's
  changes from pre-existing or concurrent work. The producer lists changed paths
  with one-line reasons, amendment references, and any remaining deviations.
  If an accidental crossing is discovered, stop further affected writes, report
  it, and remove only this attempt's unauthorized edits where that can be done
  safely without disturbing others' work. Do not rewrite history or the
  declaration to conceal it; unresolved restoration needs go to the coordinator.
- **Judge only what the supplied evidence supports.** `verify-ac` owns the
  declaration comparison: the issue body, applicable `files` and `scope`
  metadata, recorded amendments, and the actual candidate diff. Check both
  changed paths and requested behavior; missing declaration or candidate evidence
  leaves that comparison unverified. Under the current fanout contract, judges
  receive the change summary and diff without the declaration. They do not
  raise undeclared-scope findings. `judge-architecture` can still report a
  demonstrated architectural seam or mixed change in its own terms; a judge
  needing unavailable evidence uses its `gap` route.

**Per-item judgments distinguish evidence from repair authority.** Use
`verify-ac`'s per-AC `unverifiable` only when the criterion cannot be judged from
available evidence. A criterion shown false remains failed even if its repair
is outside write scope: `unmet` while any repair route is in scope,
`unmet-out-of-scope` when every route lies outside all applicable step scopes
and the gap is filed. Name the missing evidence or authorized repair route;
preserve independently supported judgments. `retro-analyst` uses its
issues-to-file route and `dispose` its named follow-up. Judges emit findings and
`gap` notes under their own contract, rather than these per-item verdicts.
