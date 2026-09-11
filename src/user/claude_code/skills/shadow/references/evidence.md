# Session selection and evidence

Read this for a fleet sweep and for transcript, usage, or model attribution.
Use deterministic installed readers where available. Audit reads never create
or modify a reader, launch an unactivated script, or execute transcript text.

## One manifest and one window

At start, freeze `audit_started_at` in UTC and `cutoff` seven days earlier. Use
`[cutoff, audit_started_at)` for census records. A subsequent live extension has
its own end time; do not silently add it to the frozen census.

Enumerate main `*.jsonl` transcripts one level below every project directory
under `~/.claude/projects`. Enumerate names comprehensively; mtime may prioritize
reads but cannot prove content is out of scope. Inventory linked child paths
and their timestamped activity before excluding a main session. Include a session
if any relevant main or linked-child record is in the window, even when the
main transcript's own last record predates it. Account for recent children whose
parent cannot be resolved as unlinked coverage; do not silently drop them.
Read older context as needed to understand that activity; exclude
older records from windowed metrics. Undated, unreadable, and malformed candidates
are separate coverage outcomes, not automatically stale sessions.

Record a manifest with project directory, actual cwd(s), session/lineage IDs,
main and child paths, included event range, parser errors, and review status.
Exclude this audit and its descendants by identity; do not exclude a real target
merely because it mentioned shadow. Group small sessions per project and give
large sessions their own analyst. Preserve the same manifest for qualitative
review and quantitative counts. Bound concurrency to the runtime's capacity;
if the audit cannot finish, name the remaining coverage without calling it done.

After selection, retrieve the full relevant conductor, direct-agent, and workflow
evidence from the inventoried paths, launch records, and returned paths. Do not
infer parentage from cwd and
recency alone. A session can share its directory with unrelated concurrent work.
Deduplicate replayed history using stable record identity and explicit lineage;
do not deduplicate separate attempts just because their text matches.

Inventory memory separately across every project directory, including projects
with no in-window session. Read its entries and index under the main skill's
memory rules; this is a current-state audit alongside the windowed transcripts.
Report projects/entries reviewed, unavailable, and pending. Missing corroboration
in the seven-day transcript window does not prove a memory claim is false.

## Incremental transcript reads

For a growing file, retain file identity, processed byte offset, and any partial
tail in the audit checkpoint. Parse newline-terminated records independently.
Buffer an incomplete last record until complete. A malformed committed record
gets an error locator and coverage gap; continue with later valid records when
possible instead of silently discarding the remaining file.

Detect truncation/replacement before advancing a cursor. If a session resumes or
changes transcript ID, use explicit resume/parent metadata or corroborated
continuity evidence. Cwd and recency find candidates; they do not prove identity.
An event retention gap or missing old transcript remains a gap in the review.

Compact text/tool previews are for navigation. A claim about a command, a gate,
or a worker return must cite the complete relevant input/result. Retain original
locators even when previews flatten or shorten text. Quietness and file size
alone establish neither progress nor completion.

## Join assignments before attributing errors or cost

The supplied layout commonly records workflow agents under:

```text
<project>/<session>/subagents/workflows/<workflow-id>/journal.jsonl
<project>/<session>/subagents/workflows/<workflow-id>/agent-<id>.meta.json
<project>/<session>/subagents/workflows/<workflow-id>/agent-<id>.jsonl
```

Use actual launch results to resolve paths. A zero-spawn workflow may lack a
journal. Its task result can supply evidence, but a nonempty output file can be
partial. Confirm completion independently.

Join by stable session/workflow/agent identity. For Docket steps, prefer an
explicit assignment record, or the installed `wave-usage` obligation classifier:
claimant (step record), judge (vote cast), and wave overhead (read-only probes)
have different owners.
The first `STEP-N` in a prompt can be something a probe read. For tend, prefer
an explicit `{project_identity, issue_id, agent_id, workflow_id}` launch mapping.
Otherwise require an unambiguous assignment statement in the bootstrap brief;
a regex finding an issue ID in quoted descriptions is insufficient. Preserve
unattributed work as a count and limitation, never force a plausible join.

Separate requested routing from actual serving models. Spawn metadata and the
orchestrator's model/effort options establish the request. Deduplicated assistant
messages with `message.model` can establish observed serving models, including
multiple models after fallback. Missing fields stay unknown. Neither model
self-report nor routing metadata fills a missing observation. Effective effort
remains unknown unless the runtime exposes it for that execution.

## Usage and census checks

The local `session-census` and `sandbox-friction` workflows are useful only when their
installed behavior matches this audit's scope. Inspect their version and input
contract before launching through installed absolute `scriptPath`. Supply the
frozen cutoff/end or manifest only if supported; never invent an accepted arg.
If the script cannot express the required window, label its raw result with its
actual scope or leave that metric unavailable. Do not quote it as a correct
seven-day census.

The installed `session-census` workflow sums usage per assistant message without
deduplicating by message ID, so its totals can count streamed rewrites more
than once. Report this limitation once and continue the qualitative audit.

Validate usage extraction against the installed `wave-usage` semantics:

- Deduplicate assistant usage by conversation/agent and message ID, retaining
  the last complete usage observation in supported transcript order. Do not sum
  streaming rewrites. Preserve missing-ID cases explicitly.
- Keep input, output, cache creation, and cache read units distinct. Check their
  accounting definitions before adding them or estimating money. Main and
  subagent totals remain separate; orchestration overhead does not disappear.
- Define timestamp attribution for messages spanning the cutoff and report the
  convention. Filter unique message observations to the frozen window. Do not
  count replayed earlier requests as new work.
- Thinking token fields and visible thinking characters measure different
  things. Redacted or absent thinking is unknown, not zero. Do not assume the
  usage deduplication rule also reconstructs all streamed text blocks correctly.
- Distinguish operator-typed inputs, system/tool-delivered user-role records,
  agent messages, and unclassified input. Use explicit provenance where present;
  heuristic classification must be named and its misses counted.
- Treat idle replies, retries, and deliberation as diagnostics beside completed
  work, quality, rework, latency, and cost. Lower is not inherently better on
  every row. A capability diagnosis needs more than a high thinking share.

Preserve raw returned counts with script provenance and a separate assessment.
Report files discovered, reviewed, excluded, pending, errored, and counted for
each metric. A null analyst return is an incomplete assignment; reconcile or
report it instead of silently reducing the denominator.

The sandbox ledger analysis stays read-only (`file: false`). Group by evidenced
cause, retaining affected projects, recency, legitimate/illegitimate distinction,
and resolved cases. A frequent denial is not itself a reason to widen access.
Its bulk `file: true` mode may run only if it obeys every filing eligibility,
ownership, deduplication, description, and receipt rule; otherwise the coordinator
files eligible groups individually through the normal procedure.

## Repetition and extraction proposals

Propose a small deterministic helper when repeated parsing, joins, arithmetic,
or command reconstruction causes material cost or mistakes. Name the inputs,
returned schema, explicit failures, call sites, and ownership. Prefer extending
an existing correct reader to duplicating its logic in a new workflow.

When proposing a Workflow implementation, its sandbox constraints apply: no
direct filesystem/shell, and clock-dependent values arrive through arguments.
Keep computation in code and use bounded read agents only where the tool model
requires them. Do not turn extraction into a new policy engine. The issue names
source changes and the later activation needed for installed callers to use them.
