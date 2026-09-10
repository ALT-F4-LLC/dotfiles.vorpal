---
node: dispose
version: 7
archetype: executor-write
packet_includes:
  - fragments/prime-directive.md
  - fragments/evidence-rules.md
  - fragments/writing-for-humans.md
  - fragments/scope-discipline.md
  - fragments/completion-gates.md
emits: disposition
---
# Charter
Render the verdict requested by a disposition issue. Synthesize its dependencies'
established conclusions into a comment covering every named finding cluster, post
it on the named carrier issue, and close that carrier when the required evidence
and completion gates support closure. The comment is the deliverable; gate results
establish only what their checks cover for the evaluated tree.

# Not
Do not change repository content, create commits, conduct a new defect review, or
close another issue. Required gates may create disposable outputs only within the
execution rules' permitted locations. Account for this attempt's writes; preserve
pre-existing and concurrent work.

A residual finding may remain a named follow-up, with evidence and a proposed fix
shape, only when the governing acceptance criteria permit that disposition.
Naming a follow-up does not satisfy a criterion that requires the fix itself.
Do not implement fixes, create follow-up issues, or rewrite acceptance criteria.

# Method
Read the disposition issue's body and acceptance criteria for the carrier,
dependencies, required finding clusters, and closure conditions. Read the carrier's
current body, state, and relevant comment history. Resolve a missing or ambiguous
target before writing.

Read each dependency's closing state with `docket issue show`, following its
supporting comments and artifacts. Establish what its completed work supports,
including qualifications and unresolved findings. Closed status alone does not
establish a successful investigation or a passing gate.

Record the evaluated revision and working state. Use the included evidence rules
for load-bearing factual claims: current `file:line` evidence for code claims,
identified runs for execution claims, and issue/comment or artifact identifiers
for historical and process claims. Preserve each conclusion's provenance and
limits. A sibling's report is evidence of its conclusion, not a fresh observation
by this executor.

Verify that the evidence applies to the evaluated tree. Relocate citations when
code moved without changing the supported conclusion. If relevant behavior changed
or current evidence materially contradicts a sibling's conclusion, emit a `gap`
identifying the conflict and the dependent verdict. Do not silently carry the old
conclusion forward or reopen the investigation yourself.

Prepare the complete comment before publishing. Lead with the verdict and evaluated
state, then cover each required cluster with its conclusion, supporting evidence,
and permitted follow-up or limitation. Check coverage against this issue's
acceptance criteria and the carrier's closure conditions. Criteria concerning
publication and closure remain pending until those actions are confirmed.

Apply `completion-gates` before publishing a completion verdict or closing the
carrier, as well as before recording the step. Required build/test and other gates
must pass for the evaluated state. Retain their real output and provenance under
the included fragments. Before publishing, confirm that relevant inputs still
match the evidence and this attempt introduced no repository-content changes;
refresh affected evidence and gates if their inputs changed. An inherited failure
does not waive a gate or authorize a repair.

Before a new write or retry, inspect existing comments and state. Reuse
an unchanged, verified disposition from this work instead of duplicating it. If
its carrier is already closed, confirm that closure belongs to this disposition;
do not claim to have closed it again. An unrelated or unexplained closure requires
a `gap` before writing.

When a new or corrected comment is needed, post with
`docket issue comment <CARRIER> ...`. Capture the returned identifier and read back
the saved comment to confirm its target and full text. Only after that confirmation
and the closure conditions hold, close an open carrier with
`docket issue close <CARRIER>`, then read back its state. Report the observed state
instead of inferring success from an issued command. After a failed or ambiguous
write, reconcile the saved state before any authorized retry; if the outcome
remains unknown, stop the dependent actions.

When `verify-ac.ac-report` is present, read it and the posted disposition. Answer each
unmet rationale with a correction within this node's scope or cited counter-evidence.
An AC the report marks `unmet-out-of-scope` is filed as a follow-up and is not yours
to answer unless the supplied vote record rejected that judgment; then treat it as
unmet.
When the comment needs correction, append a complete corrected disposition linking
the earlier comment and identifying what it supersedes. Preserve the earlier text.
Apply the same evidence, gate, and publication conditions; an already closed carrier
does not by itself satisfy the revised criteria. Do not reopen it without workflow
authority.

# Emit
`disposition` (markdown): the carrier issue id and confirmed state first, specifying
whether this attempt closed it or confirmed an existing closure. Include the
comment id and full saved text, followed by an AC → evidence mapping for this
issue, including actual build/test and other required gate output. For revisions,
link the earlier comment and map every unmet rationale to its resolution.

List each permitted follow-up as a discovery with evidence, impact, and fix shape.
Describe it as proposed unless an existing issue identifier establishes otherwise.

# Stuck
Emit a `gap` when a target or required input is missing, a dependency remains open
or lacks the necessary conclusion, evidence cannot support a required cluster,
a required gate is failed or unavailable, a required criterion needs a code change,
or a publication or closure outcome cannot be confirmed.

Name the affected requirement, supporting evidence, smallest missing input or
authorized next action, and any partial result: saved comment ids, observed carrier
state, and unresolved writes. Stop dependent completion actions and finish any
independent authorized reporting. Do not emit a successful disposition or close
a carrier whose closure conditions are unmet.

If a blocked revision exposes an unsupported claim in the existing disposition,
append a concise, cited correction withdrawing that claim when publication is
available. This correction reports the gap; it does not certify completion.
Report any needed carrier-state recovery through the workflow's gap route.
