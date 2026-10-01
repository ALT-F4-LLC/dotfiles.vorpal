# Runtime and Docket reads

Read this before the captures in SKILL.md §2 and before composing the
workflow launch in §4. These are capability checks, not permission to change
the environment. Keep three things apart: public Claude Code behavior, the
installed local contracts, and dated incident evidence.

## Engine reads on a terminal run

The audited run is `done` or `abandoned` before any engine read happens, so
no read here can race a dispatch, wake a queue consumer, or change what a
step will see. Under that precondition these verbs are the audit's read
surface, and the operator has authorized them, `verify-pins` included:

```text
run status | run report | run verify-pins
events list --run RUN-N --all-projects [--since N | --tail N]
issue list | issue show
step show | step context | step render | step gates | step artifacts | step artifact
vote show | vote result
project list | config get | trust list
workflow list | workflow show | workflow lint
doctor, only where its installed build documents a non-repairing check
```

Each of these documents itself as READ-ONLY for run state: no reap, no
lease touch, no re-pin. Shared startup still opens the store and may migrate
it forward, which is why the audit captures once (§2) and hands analysts the
captured files, and why a store the sandbox denies is left alone: report the
denial and use the captures and transcripts you already have. Never
substitute an older binary, change the store path, initialize a project,
or migrate a database to make a read work.

Never run `next`, `dispatch`, `step claim|record|heartbeat|reap`, `run
activate|resume|repin|abandon|note|budget`, `issue` mutations other than the
filing writes in [filing](filing.md), `trust add`, or `config set` as part of
an audit. A verb that refuses is recorded with its exact argv, exit, and JSON
shape; if `--json` suppresses the diagnostic, take one human-format read and
never infer its contents.

Before the first read, establish the binary PATH selects, its version, the
selected store, and the owning project. Do not dump environment variables or
configuration secrets. The supplied resolution order is explicit
`DOCKET_PATH`, then a repository-local store found by walking upward, then
the global store; a matching run id in a different store is a different run.

`events list` is cwd-scoped without `--all-projects` and can return `ok:true,
total 0` for a run driven from another project's directory; always pass the
flag, and paginate with `--since` until `total` is reached. `run report`,
`step show`, and `step artifacts` answer for a run wherever it lives.

## What each read establishes

| Question | Evidence and limit |
|---|---|
| What state did the run end in, and when? | `run status RUN-N`: `status`, `updated_at_ms`, the `issues`, `steps`, and `pins` arrays. `run-done` or `run-abandoned` in the events trail carries the ending; `issue-abandoned` carries a per-issue ruling. |
| What did a packet contain? | The journal's persisted brief for the agent that consumed it; `step render` today may differ from what was consumed and does not validate every pin. |
| Are the pins intact now? | `run verify-pins RUN-N`: `ok`, `changed`, `missing` per pin, plus `references` for closure. Drift after the run ended is a source fact, not a run defect; drift the run hit mid-flight shows as a refusal in the transcript. |
| What produced an artifact? | `step artifacts STEP-N` then `step artifact <id>`. Listing hashes may describe summary bodies rather than payloads. |
| Did a gate pass, and why not? | `step gates STEP-N --json`: verdict, exit, duration, `output_tail` on non-pass rows, `--gate <name>` for one gate's full output. A `gate-recorded` event alone omits the verdict. |
| How did a panel decide? | The proposal id on `run report`'s step `vote`, then `vote show` for casts with confidence, relevance, weight, and verdict, and `vote result` for the tally. |
| Why did a step park? | `run report`'s `park_reason` and `routing` are separate fields; read both. The `step-held`, `step-routed`, and `lease-reaped` events carry the trail. |
| Is the trail complete? | Store and project identity plus the last processed `seq`. Gaps and retention errors are coverage limits in the review. |
| What did a wave spend? | The journal directory, per [evidence](evidence.md#join-assignments-before-attributing-errors-or-cost); `run report`'s `Coverage:` lines name the joins that never landed. |

## Workflow runtime evidence

`Workflow` is a documented Claude Code feature; `wave.js`, `tribunal.js`,
`wave-usage.js`, `session-census.js`, and `docket-postmortem.js` are
local integrations. A completed workflow's journal directory holds
`journal.jsonl` (`started` and `result` per agent, no usage, no step id),
one `agent-<id>.meta.json` per seat, and one `agent-<id>.jsonl` transcript
per seat. A null result in the journal means no usable result; it does not
prove no agent ran or no side effect occurred. Read the installed
`workflow-authoring` reference before launching `docket-postmortem.js`, and launch only
the installed absolute `scriptPath` with literal arguments, never a source
copy.
[Workflows](https://code.claude.com/docs/en/workflows).

As checked 2026-09-11, Fable 5.1 (`claude-fable-5-1`), Opus 5
(`claude-opus-5`), and Sonnet 5 (`claude-sonnet-5`) are the current
documented models, and the `fable` alias resolves to Fable 5.1. Spawn
metadata establishes the requested model and effort; deduplicated assistant
messages with `message.model` establish what served. Neither is evidence
that a behavior evaluation ran on that model.
[Model configuration](https://code.claude.com/docs/en/model-config).

For install drift, compare source, installed paths, symlink targets, and the
bytes the run pinned. The local activation chain is `just activate`; this
skill never runs it. Missing optional roots can mean intentional dormancy.
Dangling roots, conflicting pinned versions, missing repository packets, and
unactivated required fixes need their actual consequences in the run
evidenced before filing.

## Versioned incident evidence

Retain a local workaround only with its observed build, date, reproducer or
source locator, and a condition for retiring it. This applies to delayed
result delivery, missing final reports, transcript rollover, question
flushing, classifier behavior, journal schemas, and hook exit shapes. Public
documentation does not independently verify the supplied Docket incident
history.

Previously fixed empty diffs and stale summaries are regression signatures,
not presumed current defects. Stored artifacts can retain historical
defects; distinguish a record written after the fix from an old artifact
read again. A guard refusal is evidence to investigate, not proof the
attempted action was wrong or that a different tool should have performed it.
