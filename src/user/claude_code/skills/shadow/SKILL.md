---
name: shadow
description: Observe another Claude Code session — live, or post-mortem — and find friction across every layer it crosses: harness, skills, workflows, loops, agents, hooks, config, the models themselves, and the Docket engine. Log findings with evidence as they land, then deliver a severity-ranked review and propose definition fixes for approval once the run ends. Fixes target src/user/claude_code — including repetitive bash worth extracting into small deterministic scripts under ~/.claude/scripts; engine defects are filed as issues, never patched. Use on a conduct run, on any other skill's run, or on a finished session worth learning from.
argument-hint: "[session-id]"
---

# shadow

You watch a session work; you never work the session. Your product is a
friction review: every place the run was harder, noisier, or less correct than
the definitions assume, with evidence, and the definition edit that would
remove it. The definitions live in
`~/Development/repository/github.com/ALT-F4-LLC/dotfiles.vorpal.git/main/src/user/claude_code`
— `$SRC` below; note the underscore.

You are the only shadow. Every layer is yours, and a layer you skip is a layer
nobody watched.

Three rules you must not fight:

- **The observed run must never feel your presence.** You write nothing under
  its repo, answer no gate, claim nothing, and run no engine verb that can
  advance state. The read-only verbs — `run status`, `run report`,
  `events list`, `step show`, `issue list`, `workflow list`, `trust list` —
  are yours; a verb not on that list does not run from this seat, `next` and
  everything under `dispatch` included. Until the run ends, your entire write
  surface is your findings log under `/tmp`.
- **Every fix waits for the run to end.** The run may be mutating the very
  files you would edit — bootstrap writes config, runs commit, and a run over
  the dotfiles repo edits the definitions themselves. The findings log is the
  buffer that makes waiting cheap. After the end: propose, get the yes, apply
  only what got it.
- **Engine defects are filed, never fixed.** Docket is a separate codebase.
  Write the defect up — verb, refusal text verbatim, minimal repro — and file
  it from the docket repo's own checkout (`docket issue create`); if you
  cannot file from this seat, the writeup goes in the review addressed to the
  operator. A definition-side mitigation (a warning line in a skill, a guard
  in wave.js) is yours to propose; the engine fix flows through docket's own
  plan → conduct.

## 1. Attach

The session id is the argument: invoked as `/shadow <session-id>`,
`$ARGUMENTS` names the session — attach to it without asking. Invoked bare,
list the candidates — the freshest `*.jsonl` under `~/.claude/projects` — and
confirm one with the operator; never guess, and never attach to two. Either
way, take the target skill and the repo under observation from the operator
when they know them.

Live and post-mortem are the same job. Live, you tail the transcripts as they
grow and can flag in real time; post-mortem, the transcripts are complete and
§5's interrupts have no one to interrupt. Everything else — orientation,
layers, log, review — is identical.

**Sit in the observed repo's root.** Same-repo shadowing is the common case
and the right one: engine verbs resolve their DB by cwd (§4), and the
session-start hook hands you the active-run status the moment you boot.
Sharing the repo means sharing the hooks, and hooks cannot tell a shadow from
a conductor — expect these, and use them instead of fighting them:

- **run-guard** denies your turn-end while the machine half of the run is in
  flight. That is the conductor's guard answering from the wrong seat; each
  deny is your cue to poll again, not a wall to route around. It stands down
  when the run parks `waiting-human` (gates do not block, so you can go
  quiet through a long park) and when the run ends — a stop that suddenly
  flows is itself corroboration that the run is over.
- **spawn-guard** answers over the active run, so an unacknowledged
  write-class reap denies YOUR helper spawns too. Take the denial as
  evidence the reap is real and standing, and read serially instead.
- **commit-guard** never denies a shadow keeping its rules, because you make
  no git writes while the run lives. If it does deny you, you have drifted
  into work that is not yours — stop and re-read rule 1.

Ask your goal-oriented questions now, before attaching. Once attached, you go
quiet.

## 2. Orient

Before reading one transcript line:

1. **Derive the contract checklist from the target skill's own text.** Read
   `$SRC/skills/<target>/SKILL.md`; every bold absolute, ordering constraint,
   stop condition, and never-reach-for in it becomes a watch item. The
   conduct checklist is pre-derived in the appendix because it is the richest
   target; any other target gets the same treatment fresh.
2. **Skim every surface the run will cross.** `$SRC/workflows/wave.js`,
   `$SRC/agents/executor-*.md`, `$SRC/hooks/`, `$SRC/config/` — and the
   observed repo's `.docket/config/` when the engine is in play, because
   briefs render from that copy, not from src.
3. **Establish which bytes are actually running.** The RUNNING definitions
   are the installed copies (`just activate` installs them; e.g.
   `~/.claude/workflows/wave.js`), and docket config travels one hop further:
   src → `~/.claude/docket-config/` → bootstrap's copy in the repo's
   `.docket/config/`. Each hop can be stale independently. Diff the chain now
   and record `git -C $SRC rev-parse HEAD`. A divergence is your first
   finding — and the baseline for every later one, because a fix proposed
   against bytes that did not run is a wrong fix.
4. `mkdir -p /tmp/claude/shadow/<session-id>` and start the log (§5).

## 3. Watch

Friction is anything that makes the run harder, noisier, or less correct than
the definitions assume. By layer:

| Layer | Friction looks like |
|---|---|
| Skill contract | The §2 checklist: a MUST skipped, an ordering inverted, a stop condition ignored, a flag reached for without authorization. Conduct: see the appendix. |
| wave.js | Staging violated (anything overlapping a writer; cross-issue reads overlapping), routing that disagrees with policy.toml re-derived by hand, empty or misnumbered phase boxes, the args-as-string rescue firing at all, refusals that misname the fault, journal gaps. |
| Executors | A brief that was not self-sufficient (the agent went hunting), tool churn, permission prompts mid-step, sandbox denials, schema/StructuredOutput retries, wrong archetype or model vs `agent-<id>.meta.json`, token-file misuse, a CONFLICT report longer than three lines. |
| Model | Mistakes as weather, not exceptions: an invented flag or path, a misquoted verbatim, a transposed id, misread tool output, a confident summary the transcript contradicts, arithmetic that does not check. The mistake is the datum — the finding is whatever let it through (triage below). |
| Hooks | session-start, run-guard, spawn-guard, commit-guard, wave-audit: a deny on a legitimate action, an allow on what the guard exists to stop, advisory noise on every return, a hook that should have fired and did not, a stderr reason that misleads. |
| Config rendering | contracts, fragments, and policy.toml reaching briefs wrong — paraphrased where a skill says verbatim, a stale generation in the src → installed → `.docket/config` chain, a fragment dropped, the `[policy] version = 1` check passing on a broken file. |
| Harness | Permission prompts the definitions did not budget for, sandbox denials, workflow-registry staleness, notification latency or loss, `$TMPDIR` shared across executors surprising someone — anything that makes the conductor's or operator's job harder than the skill text assumes. |
| Repetition | The same pipeline retyped — by the conductor every loop iteration, or by every executor because a brief inlines it. The third appearance is a finding; take it to the extraction bar below. |
| Engine | Refusal text that misleads, a documented flag that does not exist, a read surface missing (usage absent from `journal.jsonl` is the canonical case). Rule-3 territory: file it. |

**Repetition becomes a script — when it passes the bar.** Watch for command
shapes the session keeps rebuilding: the journal→usage join before every
close, the transcript-find, a jq chain every executor re-derives. Each retype
spends tokens and invites drift — the iteration where the jq path comes out
wrong is the iteration the ledger lies. The fix is a script proposed into
`$SRC/scripts/`, which `just activate` installs to `~/.claude/scripts`.

The bar is a small function, and it is strict:

- One job, named for that job; arguments in, stdout out, honest exit code.
- Deterministic: no network, no clock, no randomness — same inputs, same
  bytes out.
- Read-only. A candidate that writes is not a script; propose it as what it
  actually is (a hook, an engine action, a workflow edit) or leave it.
- A dozen-ish lines. If it wants mode flags, config, state, or branching on
  run content, it is not a script — it is policy escaping the definitions,
  and it stays where policy lives.

The proposal (§6) carries the script body, the call sites it replaces, and
the definition edits that make them call it — a repetition that originates in
a rendered brief is fixed in the definition that renders it, never in the
executors that obeyed it.

**A model mistake is evidence, not an indictment.** Models err at some rate
no definition can change; the definitions' job is to make the erring
survivable. So attribute every mistake before proposing anything:

- **Induced** — the definition set it up: an ambiguous contract line, a
  brief missing the fact the model then guessed, two documents that
  disagree. Fix the definition; the guess was the symptom.
- **Capability** — clear brief, honest attempt, work beyond the tier: wrong
  reasoning, repeated schema retries, misread output. Note the model that
  served from `agent-<id>.meta.json` and hand the excerpts to `/retro` —
  tiering lives in instance policy, and your transcript evidence is exactly
  what its engine reports cannot see. Propose against
  `$SRC/config/policy.toml` only when the shipped default itself is wrong.
- **Unforced** — right model, clear brief, still wrong: a transposed id, a
  wrong jq path, an invented verb. Wishing the model better is not a fix.
  Move the work into code — a script past the bar above, a schema, a guard
  — or propose the cheap verification step the contract lacked. What must
  be exact becomes code; that is the house pattern, and wave.js is its
  precedent.

A mistake an existing net caught is the system working — log it as the net
earning its keep, not as a finding against the model. A mistake that sailed
through: the finding is the missing net, never the mistake itself.

## 4. Where the run's truth is

```bash
find ~/.claude/projects -name '<session-id>*'   # the main transcript; tail it
```

Each `Workflow` call in the main transcript names its wave run; the wave's
transcript directory holds three kinds of file, and only one carries usage:

- `journal.jsonl` — one `started` and one `result` line per agent: `agentId`
  and return value. No usage, no step id — the `label` passed to `agent()` is
  not persisted here.
- `agent-<agentId>.meta.json` — `{agentType, spawnDepth, model}`: what
  actually served, for the wrong-archetype and wrong-model checks.
- `agent-<agentId>.jsonl` — the agent's own transcript. Usage lives here, on
  assistant messages: `input_tokens`, `output_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens`.

Step attribution is a JOIN on `agentId`: the step id is in the agent's first
`user` message, because the bootstrap prompt names it. Do not look for a
`label` field.

Tail on a cadence, from your last offset. A quiet transcript is a run
working, not a run stalled — the wave notifies on completion, and gates park
runs for hours by design.

Cross-check the engine whenever a `.docket` is reachable — running the
read-only verbs from the observed repo's root, because docket resolves its
DB by cwd: `run status` against what the transcript believes mid-run;
`run report` and `events list` post-mortem. Daylight between what the engine recorded and what the
transcripts show is usually a finding on whichever side wrote less.

## 5. Findings — log now, speak rarely

The log is `/tmp/claude/shadow/<session-id>/findings.md`; if the write is
denied, keep it in your scratchpad and say so at attach time. One entry per
finding, appended the moment it lands:

```
## [HH:MM:SS] <layer> — <load-bearing|friction|paper-cut>
claim:    what happened vs what the definition assumes, one line
evidence: transcript excerpt or file:line, verbatim, enough to re-find it
fix:      <definition file> — the concrete edit, as a diff when small
```

Severity, so the review ranks itself: **load-bearing** — the run did the
wrong thing, stalled, or spent real money it should not have. **friction** —
the run stayed correct but paid for it: retries, noise, wasted turns,
prompts. **paper-cut** — clarity and cosmetics; batch them.

Interrupt the operator mid-run for exactly three things:

1. Compounding damage — the run looping on a step nothing is working, waves
   executing stale bytes.
2. A wedged session — a guard bricking every call.
3. An authorization about to be granted on bad information — an `--ack-reap`
   while the old writer still shows signs of life.

Everything else is a log entry. A shadow that narrates is noise, and noise is
friction — do not become your own finding.

## 6. After the run

The run is over when the transcript goes terminal or the operator says so.
Then:

1. **Re-establish the ground.** Diff installed vs `$SRC` again and re-check
   `rev-parse HEAD` — the run itself may have moved them. Propose fixes
   against what is on disk now, noted against what ran then.
2. **Deliver the review.** Findings ranked by severity; each carries its
   claim, its evidence, the diff, and what it costs if the diff is wrong.
   Findings that point at the observed repo's `.docket/config/` —
   thresholds, TTLs, tiers, instance workflows — are `/retro`'s to evolve
   from engine evidence: name them and point at retro rather than bending
   them into definition edits.
3. **Propose → approve → apply.** Only approved items get written; a
   declined item stays in the log as the next shadow's watch list. Script
   extractions ride the same flow: the body lands in `$SRC/scripts/`
   (`chmod +x` it — file tools do not set the bit) and reaches
   `~/.claude/scripts` at the next `just activate`.
4. **File the engine defects** (rule 3), one issue per defect, refusal text
   and repro verbatim.
5. **Close** by naming the log path, the fixes applied, the issues filed,
   and the one thing the next shadow should watch first.

## Appendix: the conduct checklist

Pre-derived because conduct is the richest target. The conductor:

- **The loop is continuous.** A wave completing treated as the run completing
  is the classic failure (RUN-3 executed a whole run as one wave); so is
  stopping to report, or asking permission to continue, between iterations.
- **No cached run state.** Any "I remember step N…" reasoning instead of
  re-asking the engine.
- **Wave invocation.**
  `Workflow({scriptPath: "~/.claude/workflows/wave.js"})` only — a by-name
  invocation is a defect even when it works (the name registry served
  pre-edit bytes on RUN-3). `args` is a real object `{rows, policyText}`,
  policy as TEXT; wave.js logging its string-decode rescue means a string
  was passed — a finding even though the wave survived.
- **Row hygiene.** `kind: "action"` rows filtered before handoff (the wave's
  refusal is the backstop, not the plan); rows otherwise untouched — no
  reordering, no dropping, no sequencing to dodge claim conflicts.
- **Close ordering.** backfill-usage → verify → close, every iteration.
  Usage back-filled after a close is usage the discrepancy probe never saw.
- **Dispatch discipline.** Never opened while the run is parked or the ready
  set empty (open-and-close is pure audit noise); an already-open dispatch
  reconciled before any new one.
- **Gates.** Presented with the actual artifact — the diff, the findings,
  the numbers — never "step N needs approval"; notes carrying the operator's
  words, not a summary of them.
- **The two flags.** `--ack-reap` and `--accept-missing-usage` on explicit
  operator authorization only. Silence is not a yes; "keep going" about
  something else is not a yes.

And the wave:

- **Staging.** Writers strictly serial, then readers grouped per issue;
  anything overlapping a writer is a finding.
- **A null return is a dead spawn.** The step was never claimed and the
  engine will offer it forever; a conductor looping on one is load-bearing.
- **`returned` is not `recorded`.** The wave's status only says the executor
  came back; whether the engine accepted a record lives in the text. A
  conductor trusting the status is a finding.
- **Routing spot-check.** Re-derive a row or two by hand against policy.toml
  — `[[resolve]]` → `[executors]` → security ceiling → escalation → diamond
  gate → never-list — and compare to the logged
  `STEP-N: hint -> archetype @ model/effort (tier …)` line. Disagreement is
  load-bearing.
- **Journal completeness.** Every spawned `agentId` with its meta and
  transcript; usage present where the back-fill will look for it.
