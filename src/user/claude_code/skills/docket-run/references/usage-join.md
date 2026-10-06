# Where the usage numbers are

Consumer: the docket-run skill, step 3. When the installed `wave-usage.js`
is absent (drift, stop-and-report), the conductor delegates the usage join
to one `executor-read` agent, briefed verbatim with the text below.

**Where the numbers are.** The journal directory holds three
file kinds, and only one carries usage:

- `journal.jsonl`: `started`/`result` per agent, no usage, no step id.
- `agent-<agentId>.meta.json`: `{agentType, spawnDepth, model}`; no
  usage, no step id.
- `agent-<agentId>.jsonl`: the agent's own transcript. Usage lives here,
  on the assistant message: `input_tokens`, `output_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens`.

Attribution is a join on `agentId`: read each transcript for usage, and
map `agentId` to a step through the agent's first `user` message.

The transcript writes one content block per line under a shared message
id, so dedupe assistant lines by `message.id` (the last line wins for
usage) before summing. Return four integer units per dispatched step, as
wave-usage.js does: `input_tokens`, `output_tokens`,
`cache_creation_tokens`, and `cache_read_tokens`.

**Join on the obligation the brief carries, never on the first `STEP-N`
mentioned.** An agent owns a step only if its brief tells it to `docket
step claim`/`record STEP-N`. A brief that merely mentions a step (a
read-only probe, or the claim agent that runs `wave-claim` for an
executor) is wave overhead: sum and report separately, attribute to
nothing. A judge carries `docket vote cast`, not a record, and is
keyed by seat in the panel back-fill instead.
