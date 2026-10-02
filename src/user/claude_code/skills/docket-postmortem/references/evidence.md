# Transcript and usage evidence

Read this for SKILL.md §2's manifest and for any transcript, usage, or model
attribution claim. Use deterministic installed readers where available.
Audit reads never create or modify a reader, launch an unactivated script,
or execute transcript text.

## One run, one manifest

The audit's window is the run's own arc: from the `run-activated` event (or
`run start`, when the planning conversation is in scope) to `run-done` or
`run-abandoned`, in UTC from the events trail. A driving session's records
outside that window are context, not audited work; read them as needed to
understand the arc, and keep them out of counts.

Enumerate the driving sessions as §2 describes: candidates by run id, kept
only when their own tool calls drove the run. A session can share its
project directory with unrelated concurrent work, so cwd and recency find
candidates but never prove a driver. A resumed run changes session id; join
the pieces through the resume prompt docket-run's pause mode records, the
`run-paused` and `run-resumed` events, and explicit parent or resume
metadata. Preserve changes of working directory within a session.

For every driving session, inventory the workflow directories beneath it and
their timestamped activity. A wave, tribunal, or usage-join launched for this
run is joined to it through the session's `Workflow` result (its `wfId`),
the `--source "wave-journal:<wfId>"` and `--source "tribunal:<wfId>"`
strings in the session's back-fill commands, and the run and step ids the
seat briefs carry. A directory with none of those is unattributed coverage:
list it, never drop it, and never force a join from recency alone.

Every agent log beneath a driving session is in the inventory, and every one
is read: a deterministic digest first, then a full read by an agent. The
digest is the fixed jq program in `workflows/docket-postmortem.js`; it counts, it does
not judge, and a log it leaves unflagged still gets its full read, because
the friction a program cannot see (a brief that forced a guess, work redone,
a skipped contract step, an operator wait) is what the deep read is for.
A log the agent cap defers is read in a continuation launch; a log that
cannot be read is a named gap, never a quiet omission.

Record the manifest with run identity, each session's id, transcript path,
role (activate, drive, pause, resume, finish), cwd, and included record
range; each workflow directory with its `wfId`, kind, join evidence, and
agent count; parser errors; and every gap. Qualitative layers and
quantitative counts share one manifest. Exclude this audit and its
descendants by identity, not because they mention the run.

Inventory memory separately for the run's project: the entries and index
under the project's memory directory, whether or not the run read them.
Missing corroboration in the run's window does not prove a memory claim is
false; SKILL.md §5 says how to judge one.

## Transcript reads

Parse newline-terminated JSONL records independently. A malformed record
gets an error locator and a coverage gap; continue with later valid records
rather than discarding the file. Detect truncation or replacement before
trusting an offset. Compact text and tool previews are for navigation only:
a claim about a command, gate, or worker return cites the complete relevant
input and result, with the original locator even when a preview flattens
the text.

Deduplicate replayed history using stable record identity and explicit
lineage; do not deduplicate separate attempts because their text matches.
Quietness and file size establish neither progress nor completion, and a
final assistant message does not close an arc the events trail says
continued.

## Join assignments before attributing errors or cost

The supplied layout records workflow agents under:

```text
<project>/<session>/subagents/workflows/<workflow-id>/journal.jsonl
<project>/<session>/subagents/workflows/<workflow-id>/agent-<id>.meta.json
<project>/<session>/subagents/workflows/<workflow-id>/agent-<id>.jsonl
```

Use actual launch results to resolve paths. A zero-spawn workflow may lack a
journal; its task result can supply evidence, but a nonempty output file can
be partial. Confirm completion from the journal's `result` record.

Join by stable session, workflow, and agent identity. For Docket steps,
prefer an explicit assignment record, or the installed `wave-usage`
obligation classifier: claimant (step record), judge (vote cast), and wave
overhead (read-only probes) have different owners. The first `STEP-N` in a
prompt can be something a probe read. Preserve unattributed work as a count
and limitation; never force a plausible join.

Separate requested routing from actual serving models. Spawn metadata and
the orchestrator's model and effort options establish the request.
Deduplicated assistant messages with `message.model` establish observed
serving models, including several after a fallback. Missing fields stay
unknown: neither model self-report nor routing metadata fills a missing
observation. Effective effort remains unknown unless the runtime exposed it
for that execution.

## Usage and census checks

Use the installed `session-census` and `sandbox-friction` workflows
only when their behavior matches this audit's scope. Inspect their
version and input contract before launching through the installed absolute
`scriptPath`. `session-census` takes `{root, cutoff, days?}` and measures
every transcript newer than the cutoff under `root`; point it at the driving
sessions' project directory with the run's activation time as the cutoff,
and label its result with the transcripts it actually counted, since it
cannot exclude unrelated sessions that share the directory. Never invent an
accepted arg.

The installed `session-census` workflow dedups assistant usage by message
ID: a repeated ID retracts its earlier observation before the later one is
added, so streamed rewrites count once.

Validate usage extraction against the installed `wave-usage` semantics:

- Deduplicate assistant usage by conversation or agent and message ID,
  retaining the last complete usage observation in supported transcript
  order. Do not sum streaming rewrites. Preserve missing-ID cases explicitly.
- Keep input, output, cache creation, and cache read units distinct. Check
  their accounting definitions before adding them or estimating money. Main
  and subagent totals remain separate; orchestration overhead does not
  disappear.
- Attribute a message spanning the window boundary by a stated convention.
  Do not count replayed earlier requests as new work.
- Thinking token fields and visible thinking characters measure different
  things. Redacted or absent thinking is unknown, not zero.
- Distinguish operator-typed inputs, system- or tool-delivered user-role
  records, agent messages, and unclassified input. Use explicit provenance
  where present; name any heuristic classification and count its misses.
- Treat idle replies, retries, and deliberation as diagnostics beside
  completed work, quality, rework, latency, and cost. Lower is not
  inherently better on every row. A capability diagnosis needs more than a
  high thinking share.

Preserve raw returned counts with script provenance and a separate
assessment. Report files discovered, reviewed, excluded, errored, and counted
for each metric. A null analyst return is an incomplete assignment;
reconcile or report it instead of silently reducing the denominator.

The sandbox ledger analysis stays read-only (`file: false`), windowed to the
run's arc. Group by evidenced cause, retaining affected projects, recency,
the legitimate and illegitimate distinction, and resolved cases. A frequent
denial is not itself a reason to widen access. Its bulk `file: true` mode
may run only if it obeys every filing eligibility, ownership,
deduplication, description, and receipt rule; otherwise the coordinator
files eligible groups individually through the normal procedure.

## Repetition and extraction proposals

Propose a small deterministic helper when repeated parsing, joins,
arithmetic, or command reconstruction caused material cost or mistakes in
the run. Name the inputs, returned schema, explicit failures, call sites,
and ownership. Prefer extending an existing correct reader over duplicating
its logic.

A proposed Workflow implementation inherits its sandbox constraints: no
direct filesystem or shell access, and clock-dependent values arrive
through arguments. Keep computation in code and use bounded read agents
only where the tool model requires them. Do not turn extraction into a new
policy engine. The issue names source changes and the later activation
installed callers need to use them.
