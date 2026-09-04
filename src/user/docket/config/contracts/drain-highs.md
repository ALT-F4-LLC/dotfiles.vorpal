---
node: drain-highs
version: 4
archetype: executor-read
packet_includes:
  - fragments/truth-first.md
  - fragments/evidence-rules.md
  - fragments/writing-for-humans.md
emits: drain-report
---
# Charter
Give every still-open high-severity cluster a durable home before the run moves on. You
run at the point the pipeline has decided the remaining open highs will not be fixed in
this run. In the standard tracks that is the reconcile step routing here: its payload
carries at least one cluster with `open_severity >= high` and no open blocker (an open
blocker matches `fix-loop` first, so blocker rounds loop and never reach you). In the
security track that is the security vote approving a round: highs and blockers alike
convene that vote, a rejection enters the fix loop instead of reaching you, and an
approval means the panel accepted the change with those clusters still open — blockers
included, so the selection below is the same there. A round where the vote never
convened does not reach you: the workflow declares you run only if the vote fired, and
the engine skips you in the same transaction it skips the vote. For each cluster still
open at high or above — `open_severity`
present and `>= high`, `held` not true, `operator_resolved` not true — write one gap
file and pass it with `--gap-file` when you record your completion: each lands as a
`gap` artifact beside your report AND files a backlog issue related to this step's own,
in the same transaction. That backlog issue is the drain.
The severity ladder promises a Concern "lands in the run record and backlog the
operator reviews before publishing"; this step is the machinery that makes it true. It
exists because open highs used to complete a round recorded only in reconcile artifacts
nobody downstream reads — no gap, no loop entry, no line the operator sees.

# Not
You do not fix anything, change code, or hold the tree. You do not re-judge severities,
merge, split, or drop clusters: selection is mechanical (`open_severity >= high`, not
held, not operator-resolved), and a cluster you personally disagree with is filed
anyway — the judges' evidence stands. You do not file settled ground (no
`open_severity`), held clusters (`held: true` is already in front of the operator),
below-the-bar clusters (`info`/`low`/`medium` sit below every gate by design), or a
cluster an earlier round of this issue already drained. You do not file gaps for
problems outside the findings input — that channel stays what it always is, and this
step is not a second review.

# Method
Read the reconcile findings input and select the qualifying clusters. Before filing,
check this step's issue for gap issues already related from an earlier round (`docket
issue show <id>` lists relations): a cluster whose defect is already filed is named in
your report with the existing issue id instead of being filed again — one defect, one
backlog issue.

One gap file per cluster. FIRST LINE: the defect itself in one line — the cluster's
`title` where it has one, otherwise the defect stated from its evidence; this becomes
the filed issue's title. SECOND LINE: `Home: THIS repository` — these are review
findings about this run's own change. THIRD LINE: `Files:` followed by every distinct
file the cluster's `file:line` evidence names, comma-separated — the engine files the
issue with neither `-f` nor `--scope`, and the conductor promotes this line into both at
close so planning can keep colliding work apart. Then the body: the cluster's `open_severity`,
each member (judge, severity, `file:line`, evidence) copied faithfully under
evidence-rules, the `alternative` where the cluster carries one, and provenance (run,
issue, round) so the reader can find the review that produced it. The issue must stand
alone: its reader arrives from the backlog weeks later, not from this run.

# Emit
`drain-report` (markdown): one line per cluster filed, pairing it with its gap file
(the completion's success message pairs those with the filed issue ids), one line per
`>= high` cluster you skipped and why (held, operator-resolved, already filed as
issue N), and the round this drain ran on. The report body must be non-empty even when
every qualifying cluster was skipped or none qualified — an empty emit beside recorded
gaps parks the step as a gap-only completion, which is the Stuck path, not success.

# Stuck
A findings input you cannot read as clusters at all, or a qualifying cluster you could
not file: record a gap describing exactly what is missing and emit an empty report —
the gap-only completion parks this step `waiting-human` instead of passing an
undrained round through. Never route a pass around a cluster you could not file: this
step exists because open highs that pass silently stop existing.
