# Runtime and Docket observation

Read this before live delegation or engine access. These are capability checks,
not permission to change the environment. Preserve a distinction between public
Claude Code behavior, installed local contracts, and dated incident evidence.

## Agent and schedule behavior

Use the installed tool schema and returned task/agent identity. A named launch
can be a teammate when agent teams are enabled; an ordinary background subagent
has native completion delivery. An addressable observer may also send interim
findings through `SendMessage`. Retain the log-before-delivery recovery path
without assuming every final answer disappears. Monitor behavior and message
latency should be recorded for the actual mode and build. Neither a message
acknowledgment nor a collected event proves the receiver processed it.
[Tools reference](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior).

An existing custom observer definition can specify effort and a smaller tool
surface while remaining addressable. Do not invent an `effort` field on a tool
that does not expose it. Do not install or edit an agent definition during an
audit. A prompt boundary alone is not enforced containment; unrestricted shell
and write-capable MCP tools can exceed a nominally read-only tool selection.
[Subagents](https://code.claude.com/docs/en/sub-agents).

As checked 2026-09-11, Fable 5.1 (`claude-fable-5-1`), Opus 5 (`claude-opus-5`),
and Sonnet 5 (`claude-sonnet-5`) are the current documented models, and the
`fable` alias resolves to Fable 5.1; provider mappings and overrides matter.
Preserve the Fable observer preference, while recording fallbacks from
message-level evidence. These model IDs are routing choices,
not evidence that a behavior evaluation ran on those models.
[Model configuration](https://code.claude.com/docs/en/model-config).

Determine the loop's actual scheduling mechanism:

- Self-paced `/loop /tend`: inspect its armed `ScheduleWakeup` state and current
  pass. A missing wakeup alone does not establish that a worker finished.
- Explicit-interval `/loop 20m /tend`: inspect its corresponding cron task and
  current pass. A missing self-paced wakeup says nothing about that cron job.
- Bare `tend`: one pass, no promised recurrence; wait for the pass and its worker
  to settle before calling it a post-mortem.

Check for cancellation, expiration, and resume gaps. Fixed recurring jobs can
expire, and monitors are not restored on resume. An operator stop can end the
schedule while child work remains alive. Do not create, alter, or cancel the
observed schedule to discover its state.
[Scheduled tasks](https://code.claude.com/docs/en/scheduled-tasks).

`Workflow` is a documented Claude Code feature, while `wave.js`, the census,
and Docket are local integrations. Read the installed `workflow-authoring`
reference before launching a local workflow, and launch only the installed
absolute `scriptPath` with literal arguments (never an unactivated source
script or a refused script copied into an allowed directory; see
[evidence](evidence.md#usage-and-census-checks)). A workflow's null result
means no usable result; it does not prove no agent ran or no side effect
occurred. [Workflows](https://code.claude.com/docs/en/workflows).

## Docket access gate

Before any live store access, establish the binary selected by PATH, its source
or build provenance, selected store, and owning project. Do not dump environment
variables or configuration secrets. The supplied local resolution contract is:
explicit `DOCKET_PATH`, then a repository-local store found by walking upward,
then the global store. Verify this for the installed build; a matching issue ID
in a different store is not the same issue.

No Docket verb is write-free against the live store: shared startup opens the
database and migrates it before command handlers run, and the connection
configures WAL, so a handler with no update statements can still write through
startup or project resolution. `verify-pins` in particular is absent from the
inspected read-verb registration exemption; never invoke it against the live
store under this observation boundary.

Use a supported, verified read-only observer connection if one becomes
available. Otherwise use the observed session's already-recorded results and
existing consistent exports. Report their time and freshness. Do not substitute
an older binary, change the live store path, initialize a project, reap a lease,
or migrate a database merely to make observation work.

Use `immutable=1` only for a known consistent immutable snapshot, never for a
changing live database. A main-file view can omit committed WAL records, so
absence from it does not prove absence from the run. A casual separate copy of
database and WAL files is not a consistent snapshot. Read-only WAL access has
prerequisites; do not force a checkpoint or create sidecars to satisfy them
during observation.
[SQLite URI semantics](https://www.sqlite.org/uri.html),
[SQLite WAL](https://www.sqlite.org/wal.html).

## Observation operations

These names describe intended read operations, not an unconditional allowlist:
`run status`, `run report`, `run verify-pins` (per the access gate above),
`events list`, `issue list|show`, `project list`, `config get`, `trust list`,
`workflow list|show|lint`, `step show|context|render|artifacts|artifact`, and a
verified non-repairing `doctor` check. Reassess after a binary change. `next`,
`dispatch`, claim/record, reap, activation, and configuration writes stay
outside the observer's role.

Anchor project-scoped queries to a verified checkout. An empty listing from an
unregistered or wrong directory is not evidence of an empty queue. A project
identity is not necessarily its usable checkout; verify the actual worktree
instead of constructing `<identity>/main` blindly.

Preserve these local evidence distinctions when supported by the build:

| Question | Evidence and limit |
|---|---|
| What did a packet contain? | Captured packet or `step render`; today's render may differ from what was consumed. A successful render does not validate every run pin. |
| Are pins intact? | `run verify-pins` through a verified read-only path, never the live store. Record each unresolved or mismatched reference. Do not re-pin. |
| Manual pin fallback? | Validate the JSON envelope and pin array. Resolve each reference using its recorded origin/root precedence; do not assume every file belongs to the shared corpus. Compare hashes and count verified, mismatched, unresolved and unsupported pins separately. A valid empty array, a missing field and a parse failure are different outcomes. |
| What produced an artifact? | `step artifacts` then `step artifact`, including payload where needed. Listing hashes may describe summary bodies rather than payloads. |
| Did a gate pass? | Gate result/artifact or authoritative report. A gate-recorded event alone may omit the verdict. |
| Is the event history complete? | Preserve store/project identity and last processed sequence. Use the installed cursor semantics; record gaps and retention errors. A newest-page view cannot replace full pagination for a post-mortem. |
| Why did a command refuse? | Preserve exact argv, exit, JSON shape, and available diagnostics. If JSON suppresses useful diagnostics in this build, use one safe human-format read; never infer its contents. |

For install drift, compare source, installed paths, symlink targets, and the
observed launch. The local activation chain is `just activate`; shadow never
runs it. Missing optional roots can mean intentional dormancy. Dangling roots,
conflicting pinned versions, missing repository packets, and unactivated
required fixes need their actual consequences evidenced before filing.

## Versioned incident evidence

Retain a local workaround only with its observed build/mode, date, reproducer or
source locator, and a condition for retiring it. This applies to delayed monitor
delivery, missing final reports, transcript rollover, question flushing,
classifier behavior, journal schemas, and hook exit shapes. Public documentation
does not independently verify the supplied Docket incident history.

Previously fixed empty diffs and stale loop summaries are regression signatures,
not presumed current defects. Stored artifacts can retain historical defects.
Distinguish a new record after the fix from an old artifact read again. Likewise,
a guard refusal is evidence to investigate, not proof the attempted action was
wrong or that a different tool should perform it.
