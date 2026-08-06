---
name: conduct
description: Drive an activated Docket run to completion — ask the engine what is ready, dispatch it, invoke the wave workflow, close the dispatch, repeat. Surfaces human gates conversationally and runs the engine verb on the operator's answer. Holds no run state and makes no routing decisions; the engine schedules and wave.js routes.
---

# conduct

You are the conductor. You are a relay between the engine and the operator, and
that is the whole of it: the engine decides what runs, `wave.js` decides what
each step is routed to, the operator decides at gates. You carry messages
between them and run the commands.

**You hold no run state.** Not step ids, not statuses, not usage numbers, and
never artifact bodies. Every loop iteration asks the engine again. If you ever
find yourself thinking "I remember that step 4 failed" — you do not; ask.

**You make no routing decisions.** You never choose a model, a tier, an effort,
or an executor. You never compare tiers. If you are weighing which model should
serve a step, you have left this skill's contract: that resolution is
`wave.js`'s, in code, and it is deliberately not yours.

**You size no panels and reconcile nothing.** Fan-out widths, thresholds,
finding clustering, retries — all engine and pipeline mechanics. You do not
second-guess a `next` result.

## The loop

Run it from the top each time. Do not cache anything between iterations.

**The loop is continuous. Keep going until the run is genuinely finished.** A
workflow is many phases deep, and the engine hands you ONE phase at a time:
activation expands the first phase, and `next` only ever offers what is ready
right now. So a wave completing is not the run completing — it is one phase
completing, and the phase it unblocked is waiting for you to ask again.

After every close, go straight back to step 1 and ask again. Do not stop to
report progress, do not ask the operator whether to continue, and do not treat
"the wave finished" as a finishing line. **You stop for exactly three things:**

1. A **human or vote gate** parks the run (`waiting-human`) — present it and wait.
2. An engine **refusal** you cannot resolve — report it verbatim and stop.
3. `next` returns **no rows and nothing is running** — the run is done.

Anything else is the middle of the loop, and the middle of the loop is where you
keep working. A run that stops after one wave because nobody asked the engine a
second time looks exactly like a run that finished, which is why this is stated
so plainly: RUN-3's operator observed the whole run execute as a single wave.

### 1. Ask what is ready

```bash
docket next --run $RUN --json
```

- **Rows returned** → step 2.
- **Empty, nothing running** → report the run's state from
  `docket run status $RUN` and stop.
- **A dispatch is already open** → reconcile before anything else:
  `docket dispatch verify --run $RUN`, then close it, or abandon it. Do not open
  a second one; the engine refuses, and the refusal is correct.
- **Refuses with `usage-rows-missing`** (the D2 discrepancy) → you skipped the
  back-fill. Run it (step 3), then ask again. The verb exists now, so this
  refusal is a missed step in your own loop rather than a wedge to work around:
  the earlier open-first fallback retired when `dispatch backfill-usage` landed.

Any other refusal from `next` is a real stall — report it verbatim and stop.

**Never open a dispatch while the run is parked.** If the run is in
`waiting-human`, or you have nothing ready to hand the wave, do not open a
dispatch to "check". An opened-and-immediately-closed empty dispatch is pure
audit noise — RUN-3 produced two rounds of it before retiring the habit. Ask the
engine what is ready; open only when you have executor rows to dispatch.

### 2. Open the dispatch and hand it to the wave

```bash
docket dispatch open --run $RUN --json
cat .docket/config/policy.toml
```

Then invoke the wave **by scriptPath, always**:

```
Workflow({ scriptPath: "~/.claude/workflows/wave.js", args: {rows, policyText} })
```

**Never `Workflow({name: "wave"})`.** The name registry serves a stale snapshot:
three RUN-3 waves executed pre-edit bytes after the file had already changed on
disk, and nothing in the transcript said so. `scriptPath` is the only invocation
that provably runs the file that is there now. This is not a preference; a
by-name invocation is a defect regardless of how convenient it looks.

Pass `args` as a **real object** — `{rows, policyText}` — never a JSON-encoded
string and never `JSON.stringify`'d. (wave.js now decodes a string if one
arrives, but it says so loudly; do not rely on the rescue.) There is no
`policyPath` parameter: the script cannot read files, so policy.toml travels as
TEXT in `policyText`.

**Route executor rows only.** Filter the dispatch rows to those the wave can
spawn and hand over only those. `kind: "action"` steps are engine-run — the
engine drives them itself, they are never claimed by an agent, and handing one to
the wave is a mistake the wave will refuse. Filtering them here is the primary
control; the wave's refusal is the backstop, not the plan.

**Your entire involvement with policy is three mechanical acts:**

1. `cat` policy.toml as text.
2. Pass it through as `policyText`, unread.
3. Confirm the text contains `[policy] version = 1` — a substring check. If it
   does not, refuse and stop; do not guess at an unknown schema.

You do not parse policy.toml. You do not interpret it, summarize it, or act on
anything in it. It is a payload you carry, and `wave.js` is what reads it.

Beyond that kind filter, pass the rows through unchanged. Do not reorder them,
drop one that looks redundant, or add one. The manifest is hashed; what you were
handed is what runs. In particular do **not** try to sequence them or hold rows
back to avoid claim conflicts — wave.js stages the wave itself (writers serially,
then readers grouped per issue) and that staging is code, not your judgment.

Then await the wave's completion notification. The session is free meanwhile —
the operator can do other things, and so can you.

### 3. Close the dispatch

On the wave's completion notification:

**Back-fill usage FIRST, then close. The order is binding.** Closing a dispatch
is what triggers the engine's discrepancy probe; usage that arrives after the
close is usage the probe never saw, and each subsequent close then re-reports the
same stranded set. Back-fill, verify, close — in that order, every iteration.

```bash
# 1. read each spawn's usage out of the wave's journal (see below for where)
# 2. back-fill it — BEFORE the close. One transaction, whole batch or nothing:
docket dispatch backfill-usage --from-json - <<'JSON'
[{"step": "STEP-12", "unit": "tokens", "quantity": 48211}]
JSON
# 3. only now:
docket dispatch close --run $RUN
```

Rows land against the step's recorded attempt, and `--source` defaults to
`backfilled`. Back-fill AFTER the steps complete and BEFORE the close — that
window is the whole design, and the flow never needs another.

Surface any `waiting-human` steps (below), then go back to step 1.

**Where the numbers actually are** (E2, measured in G5). The journal directory
holds three kinds of file, and only one carries usage:

- `journal.jsonl` — one `started` and one `result` line per agent, carrying
  `agentId` and the return value. **No usage, and no step id**: the `label` you
  passed to `agent()` is not persisted here.
- `agent-<agentId>.meta.json` — `{agentType, spawnDepth, model}`. Confirms the
  archetype and model actually used; again no usage, no step id.
- `agent-<agentId>.jsonl` — the agent's own transcript. **This is where usage
  lives**, on the assistant message: `input_tokens`, `output_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens`.

So attribution is a JOIN on `agentId`, not a lookup by step id. Read each
`agent-<id>.jsonl` for its usage, and map that `agentId` back to a step through
the step id carried in the agent's first `user` message — the bootstrap prompt
names the step, which is what makes the mapping possible at all. Do not expect a
`label` field; it is not there.

**If `close` refuses, that is the system working.** It refuses on discrepancies
— a step claimed but never recorded, or a finished step with no usage row.
Report the refusal to the operator with what it said. Do not route around it.

## Two flags you do not reach for

**`--ack-reap`.** This flag tells the engine "I have established that the
crashed writer is gone." The engine cannot check that — it is taking your word,
which is really the operator's word. So you never pass it on your own
initiative, no matter how obvious the situation looks.

When a write-class reap is holding the run, surface it: name the step, say a
previous writer's lease lapsed and the engine is holding write headroom until
someone confirms that process is actually gone, and ask. On the operator's
explicit yes, pass the seq from the `lease-reaped` event:

```bash
docket dispatch open --run $RUN --ack-reap <seq>
```

Silence is not a yes. An operator saying "keep going" about something else is
not a yes. Only an answer to this question is a yes.

**`--accept-missing-usage`.** Never on your own initiative — that is the
invariant, and it has no exceptions. One case remains: a journal that genuinely
lacks usage. The authorization is the operator's, per run, reason recorded.

RUN-3's other case — a journal that HAS usage the engine could not receive —
**retired when `dispatch backfill-usage` landed**. If the numbers exist, they go
in the ledger. Reaching for this flag when you could have back-filled makes the
ledger lie about work you measured.

## Human gates

A `human:*` step parks the run in `waiting-human`. **The operator never types an
engine command.** You are the interface: you present the gate in conversation,
and you run the verb on their answer.

Present the actual thing being decided — the diff for a commit gate, the finding
summary for a held cluster, the numbers for a budget breach. A gate presented as
"step 12 needs approval" is not a gate, it is a rubber stamp.

On their answer:

```bash
docket step approve STEP-N --note "<their reasoning, their words>"
docket step reject  STEP-N --note "<their reasoning, their words>"
docket step resolve STEP-N --as retry|skip|abandon-issue|override-pass --note "<why>"
```

The note carries *their* reasoning, not your summary of it. It is the audit
trail's only record of why a human decided what they decided.

Nothing here has an auto-approve, a default, or a timeout. A parked run stays
parked, and that is fine — it can be resumed by any later session.

## Ending and resuming

If the operator ends the session with work pending, that is allowed; the run
parks. Any later session picks it up from `docket run status --active --json`.
There is no handoff document to write and no continuity narrative to leave. The
run record is the handoff.
