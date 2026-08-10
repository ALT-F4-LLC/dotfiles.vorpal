---
name: shadow
description: Observe another Claude Code session — live, or post-mortem — and find friction across every layer it crosses: harness, skills, workflows, loops, agents, hooks, config, the models themselves, and the Docket engine. Log findings with evidence as they land, then deliver a severity-ranked review and propose definition fixes for approval once the run ends. Fixes target src/user/claude_code — including repetitive bash worth extracting into small deterministic scripts under src/user/claude_code/scripts; engine defects are filed as issues, never patched. Use on a conduct run, on any other skill's run, or on a finished session worth learning from.
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
  advance state. Yours are the read verbs — `run status`, `run report`,
  `events list`, `issue list`, `project list`, `config get`, `trust list`,
  `workflow list|show|lint`, `step show|context|artifacts|artifact` — every
  one write-free, `run report` included, in any run status. A verb off that
  list does not run from this seat, `next` and everything under `dispatch`
  included. Until the run ends, your entire write surface is your findings log
  under `/tmp`.
- **Every fix waits for the run to end.** The run may be mutating the very
  files you would edit — bootstrap writes config, runs commit, and a run over
  the dotfiles repo edits the definitions themselves. The findings log is the
  buffer that makes waiting cheap. After the end: propose, get the yes, apply
  only what got it.
- **Engine defects are filed, never fixed.** Docket is a separate codebase.
  Write the defect up — verb, refusal text verbatim, minimal repro — and file
  it from the docket repo's own checkout (`docket issue create`), which is
  also what routes it: the store is machine-global and a project is a
  checkout's git identity. Ids are a store-wide sequence and the two live
  projects share the prefix `DKT`, so name the project beside any id that
  could be read either way. If you cannot file from this seat, the writeup
  goes in the review addressed to the operator. A definition-side mitigation
  (a warning line in a skill, a guard in wave.js) is yours to propose; the
  engine fix flows through docket's own plan → conduct.

## 1. Attach

The session id is the argument: invoked as `/shadow <session-id>`,
`$ARGUMENTS` names the session — attach without asking. Invoked bare, list the
candidates (the freshest `*.jsonl` under `~/.claude/projects`) and confirm one
with the operator; never guess, and never attach to two. Either way, take the
target skill and the repo under observation from the operator when they know
them, and derive that repo from the transcript's own `.cwd` field — the
project-directory name flattens `/`, `.`, and `_` identically and cannot be
decoded back into a path.

Live and post-mortem are the same job: live you tail transcripts as they grow
and can flag in real time, post-mortem they are complete and §5's interrupts
have no one to interrupt. Orientation, layers, log, review are identical.

**Sit in the observed repo's root.** Same-repo shadowing is the common case
and the right one: where you stand picks both the store and the project the
verbs answer for (§4), and the session-start hook hands you the active-run
status the moment you boot. Sharing the repo means sharing the hooks, and
hooks cannot tell a shadow from a conductor — but **check which hooks are live
before attributing any behavior to one:** all five docket hooks are commented
out of the settings builder today (`src/user/claude_code.rs:148-178`). Where
they run, expect these and use them instead of fighting them:

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

Reading a guard's answer: exit 0 allows, exit 2 denies, and a third case is
easy to misread — no docket database up-tree ALSO exits 0, carrying
`{"allowed":true,"not_applicable":true}`: an abstention, not a blessing. Under
`--json` a denial's reason rides in `.error`, code `NOT_FOUND`, not `.data`.

**A sandboxed seat cannot run docket at all.** Every DB-touching verb opens
the store read-write and migrates it forward before answering — there is no
read-only open — so under the global store at `~/.docket` a sandboxed shell
fails with `unable to open database file (14)` wherever it stands. Take the
sandbox override for the read verbs, or read the DB with
`sqlite3 'file:$HOME/.docket/issues.db?immutable=1'` (plain `mode=ro` fails:
WAL wants the -shm sidecar); `immutable=1` sees the last checkpoint only, fine
for the pre-run baseline and stale for mid-run cross-checks, where the
transcript's own `✔` result lines and the override verbs are the live
surfaces. `--help` opens nothing. And **never point an older docket binary at
that store**: migration is silent, forward-only, and unguarded, so an old
binary reads and writes every project's rows with no project predicate and
nothing behind you — no down-migration, no backup verb. Binary provenance (§4)
is not pedantry.

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
   `$SRC/agents/executor-*.md`, `$SRC/hooks/`, and the docket config source —
   not under `$SRC` but beside it at `src/user/docket/` (`contracts/`,
   `fragments/`, `schemas/`, `workflows/`, `policy.toml`) — plus the observed
   repo's `.docket/config/` when the engine is in play: a link farm back into
   `~/.docket`, so briefs render THROUGH those links, not from source.
3. **Establish which bytes are actually running — starting with whether an
   installed copy exists at all.** The `~/.claude/{workflows,scripts,hooks,
   agents}` symlinks `just activate` USED to install are all commented out
   today (`src/user/claude_code.rs:280-290`) and none exist on disk, so
   resolve every definition as the session must: installed path if present,
   else the source under `$SRC` — a session invoking wave.js right now runs
   `$SRC/workflows/wave.js`. Docket config travels a chain of its own —
   `src/user/docket/` → (`just activate`) → those same five names under
   `~/.docket/` → (bootstrap's link step) → the repo's `.docket/config/`,
   whose files are SYMLINKS back into `~/.docket`. Two hops that go stale
   independently, plus a link layer that can dangle but cannot drift: diff
   source against installed BY NAME (never recursing over `~/.docket` whole,
   because `issues.db` lives there too), then `find -L .docket/config -type l`
   for broken links and `find .docket/config -type f` for real files —
   legitimate as the repo's own deliberate additions, but one bearing a corpus
   filename is a link a tool overwrote rather than edited, diverged and
   invisible to the dangle check. Those are the two ways the view goes wrong.
   Record `git -C $SRC rev-parse HEAD`. A divergence is your first finding —
   and the baseline for every later one, because a fix proposed against bytes
   that did not run is a wrong fix.
4. `mkdir -p /tmp/claude/shadow/<session-id>` and start the log (§5).

## 3. Watch

Friction is anything that makes the run harder, noisier, or less correct than
the definitions assume. By layer:

| Layer | Friction looks like |
|---|---|
| Skill contract | The §2 checklist: a MUST skipped, an ordering inverted, a stop condition ignored, a flag reached for without authorization. Conduct: see the appendix. |
| wave.js | Staging that disagrees with the rows' engine `stage` labels, routing that disagrees with policy.toml re-derived by hand, empty or misnumbered phase boxes, spawns launched into a parked run, refusals that misname the fault, journal gaps. (The args-string decode is normal harness transport — never a finding.) |
| Executors | A brief that was not self-sufficient (the agent went hunting), tool churn, permission prompts mid-step, sandbox denials, schema/StructuredOutput retries, wrong archetype or model vs `agent-<id>.meta.json`, token-file misuse, a CONFLICT report longer than three lines. |
| Model | Mistakes as weather, not exceptions: an invented flag or path, a misquoted verbatim, a transposed id, misread tool output, a confident summary the transcript contradicts, arithmetic that does not check. The mistake is the datum — the finding is whatever let it through (triage below). |
| Hooks | session-start, run-guard, spawn-guard, commit-guard, wave-audit: a deny on a legitimate action, an allow on what the guard exists to stop, advisory noise on every return, a hook that should have fired and did not (uninstalled is not broken — §1), a stderr reason that misleads. |
| Config rendering | contracts, fragments, and policy.toml reaching briefs wrong — paraphrased where a skill says verbatim, a stale install anywhere in the `src/user/docket/` → `~/.docket/` → linked `.docket/config/` chain, a fragment dropped, the `[policy] version = 1` check passing on a broken file. Three signatures worth recognizing on sight: a broken FILE link inside config fails activation with a `VALIDATION_ERROR` naming that file; a broken `.docket/config` ROOT link is skipped SILENTLY and surfaces much later as an issue "matching no registered workflow"; and a `packet`-declaring step claimed from an isolated worktree fails with `packet file "…" is pinned by this run but is no longer on disk` — AFTER recording the claim, so the step sits claimed and tokenless until a reap (worktrees lack the gitignored link farm). |
| Harness | Permission prompts the definitions did not budget for, sandbox denials, workflow-registry staleness, notification latency or loss, `$TMPDIR` shared across executors surprising someone — anything that makes the conductor's or operator's job harder than the skill text assumes. |
| Repetition | The same pipeline retyped — by the conductor every loop iteration, or by every executor because a brief inlines it. The third appearance is a finding; take it to the extraction bar below. |
| Engine | Refusal text that misleads, a documented flag that does not exist, a read surface missing (usage absent from `journal.jsonl` is the canonical case). Rule-3 territory: file it. |

**Repetition becomes a script — when it passes the bar.** Watch for command
shapes the session keeps rebuilding: the journal→usage join before every
close, the transcript-find, a jq chain every executor re-derives. Each retype
spends tokens and invites drift — the iteration where the jq path comes out
wrong is the iteration the ledger lies. The fix is a script proposed into
`$SRC/scripts/` — also where its callers must name it while the
`~/.claude/scripts` symlink stays uninstalled.

The bar is a small function, and it is strict:

- One job, named for that job; arguments in, stdout out, honest exit code.
- Deterministic: no network, no clock, no randomness — same bytes out.
- Read-only. A candidate that writes is not a script; propose it as what it
  actually is (a hook, an engine action, a workflow edit) or leave it.
- A dozen-ish lines. Wanting mode flags, config, state, or branching on run
  content makes it policy escaping the definitions, and policy stays put.

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
  `src/user/docket/policy.toml` only when the shipped default itself is wrong.
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

Tail on a cadence, from your last offset —
`$SRC/scripts/shadow-transcript-summary.sh <transcript.jsonl> [from-line]`
renders the compact per-line view; don't retype the jq, and call it at that
source path, since `~/.claude/scripts` is not installed. A quiet transcript is
a run working, not a run stalled — the wave notifies on completion, and gates
park runs for hours by design.

Measured limits of these surfaces (RUN-2's and RUN-5's shadows):

- **A session can ROLL TO A NEW TRANSCRIPT ID at context compaction.** RUN-5's
  conductor continued under a fresh file whose replayed history was
  byte-identical; every watcher keyed on the old id went silently stale for an
  hour. If the engine moves while your transcript is quiet, re-find the live
  file by cwd + recency before concluding anything — and watch engine events
  in parallel; they are rollover-proof. Let the engine tail them for you:
  `events list --follow` streams at `--interval` (500ms floor) and `--tail N`
  jumps to the newest N, both better than a hand-rolled poll loop. Events are
  project-scoped (`--all-projects` widens to the store) and the cursor to
  carry is the last `seq`, passed to `--since` (strictly greater); one that
  has fallen below the retained minimum exits 9 GONE rather than restarting.
- **Gate-recorded EVENTS carry no verdicts.** Pass/fail lives only in
  `gate_results` (or `run report`'s tally); "gates green" read off the event
  stream is a guess.
- **Transcripts flush lazily.** A pending question to the operator hits disk
  only WITH its answer — you cannot watch a gate live, so interrupt-condition
  3 must be caught from your own cross-checks, never from seeing the question.
- **A wave that spawned nothing writes no journal.** The workflow task's
  `.output` file is the only record of a zero-spawn wave.
- **Binary provenance includes the PATH.** `which` on the operator's PATH,
  not just in-repo copies — the shadow that checked only `./bin` and
  `.docket/bin` missed a third, go-installed binary.
- **"No agent ran" is not "nothing read the prompt."** The spawn classifier
  screens rendered briefs before any agent exists; blocked-at-zero-tokens is
  consistent with the TEXT being the problem. Never rule out prompt content
  because no agent came to life.
- **Direct Agent-tool spawns (no wave) transcribe under the SPAWNING session:**
  `<projects-dir>/<session-id>/subagents/agent-a<name>-<hash>.jsonl`. And a
  named background agent's final text is delivered to NOBODY — its spawner
  gets a content-free idle ping — so "went idle, no report" means finished
  work sitting in that file, recoverable (measured twice, 2026-08-10; one
  such loss stalled the observed run nine minutes and was then misreported
  as "report received" in its recap).

Cross-check the engine whenever the store is reachable, from the observed
repo's root: resolution runs `$DOCKET_PATH` → a repo-local `.docket/issues.db`
found by walking up → the global `~/.docket/issues.db`, and where you stand
also picks the project the project-scoped verbs answer for. `run status`
against what the transcript believes mid-run; `run report` and `events list`
post-mortem; `step artifacts STEP-N` then `step artifact ARTIFACT-N
[--payload]` for what a step actually produced — those two retired reading
artifacts out of the DB by hand, though sqlite immutable stays the sandboxed
route. Daylight between what the engine recorded and what the transcripts show
is usually a finding on whichever side wrote less. One caution when you read
with `--json`: it suppresses ALL stderr diagnostics — reap notices,
held-headroom reasons, context-size warnings — so when something looks stuck
and the JSON says nothing about why, ask once more in human mode before
concluding the engine is silent.

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

If the operator directs you to message the observed session directly, expect
the conductor to hold your message as an unverifiable peer claim rather than
act on it — that skepticism is its permission model working, and it should not
be argued with. Say so when relaying, and prefer pointing the operator at the
observed session's own next gate: an instruction given there is the only form
it can execute on (RUN-8: relayed instruction correctly refused, validated
after the fact, and still unexecuted).

## 6. After the run

The run is over when the transcript goes terminal or the operator says so.
Then:

1. **Re-establish the ground.** Walk §2.3's chain again and re-check
   `rev-parse HEAD` — the run itself may have moved them. Propose fixes
   against what is on disk now, noted against what ran then.
2. **Deliver the review.** Findings ranked by severity; each carries its
   claim, its evidence, the diff, and what it costs if the diff is wrong.
   Findings that point at the observed repo's `.docket/config/` —
   thresholds, TTLs, tiers, instance workflows — are `/retro`'s to evolve
   from engine evidence: name them and point at retro rather than bending
   them into definition edits.
3. **Propose → approve → apply.** Proposals go through the built-in question
   tool — grouped, recommended option first, labelled "(Recommended)". Only
   approved items get written; a declined item stays in the log as the next
   shadow's watch list. Script extractions ride the same flow: the body lands
   in `$SRC/scripts/` (`chmod +x` it — file tools do not set the bit), and
   until the `~/.claude/scripts` symlink is restored, every call site you edit
   must name that source path.
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
- **Wave invocation.** By `scriptPath` only — the installed
  `~/.claude/workflows/wave.js` if it exists, else `$SRC/workflows/wave.js`,
  which is what a session runs today. A by-name invocation is a defect even
  when it works (the name registry served pre-edit bytes on RUN-3). `args` is
  a real object `{rows, policyText}`, policy as TEXT. (wave.js's args-decode
  log line is normal harness transport — the harness stringifies args
  regardless of the caller; proven by controlled probe on RUN-5. Never count
  it as a finding.)
- **Roster derivation.** A run's issue set comes from the dry-run
  activation's `bound_issues[]` ({issue, workflow}) and `promoted_issues[]`;
  reconstructing it by timestamp window is a workaround the engine retired.
  Re-derive rather than cache: `run issue add` is legal on an ACTIVE run (the
  next activate binds the additions as a later phase), so a roster that grew
  mid-run is not itself a finding. Removal is planning-only, and
  `issue-promoted` still fires at activation — keep watching it.
- **Completion is the executor's.** Executors run `docket step record`, the
  alias built for exactly these sandboxed and worktree-isolated shells;
  completing on one's behalf is now a finding rather than a protocol, and a
  token parked in `$TMPDIR` is the fallback only when `record` itself failed.
- **Row hygiene.** `kind: "action"` rows filtered before handoff (the wave's
  refusal is the backstop, not the plan); rows otherwise untouched — no
  reordering, no dropping, no sequencing to dodge claim conflicts.
- **Close ordering.** backfill-usage → verify → close, every iteration.
  Usage back-filled after a close is usage the discrepancy probe never saw.
  Backfill is not a workaround but the token path: transcripts are the only
  place tokens exist and only the conductor can read them. `record --usage` is
  the separate at-source channel for units a claimant can measure itself, and
  `budget.unit` names the one the cap counts.
- **Dispatch discipline.** Never opened while the run is parked or the ready
  set empty (open-and-close is pure audit noise); an already-open dispatch
  reconciled before any new one. While one is open `next --run` REFUSES rather
  than returning empty — a conductor reading that refusal as "no work left" is
  a finding. `dispatch verify` writes nothing at all, not even a reap.
- **Gates.** Presented with the actual artifact — the diff, the findings,
  the numbers — never "step N needs approval"; notes carrying the operator's
  words, not a summary of them.
- **The two flags.** `--ack-reap` and `--accept-missing-usage` on explicit
  operator authorization only. Silence is not a yes; "keep going" about
  something else is not a yes.

And the wave:

- **Staging.** Stage-label-driven (2026-08-08 rewrite; the old
  writers-serial interim is retired): rows sharing an engine `stage` value
  run fully parallel, stages ascend with an await between, and a stage-less
  row is stage 0. A stage-0 set offered together IS engine-certified
  concurrent regardless of class — verified live on RUN-8 in both regimes
  (all-stage-0 reader/writer mix; fixer-0/judges-1 ordering). If a claim
  then conflicts, the finding is the engine's certification or the
  dispatch's row set, never the wave's staging.
- **Brief hygiene.** Embedded commands are `docket step record`, run bare from
  the executor's own checkout — no `DOCKET_PATH`, no sibling-checkout probing,
  because resolution walks up from wherever the executor stands. An isolated
  writer records with `--worktree` naming its checkout, so the engine computes
  the diff where the work happened; an out-of-scope problem leaves as
  `--gap-file` (artifact plus backlog issue in one transaction, no workflow
  declaration) instead of being smuggled into a declared emit. Any of that
  reverting is a finding against the brief, never the executor.
- **A null return is a dead spawn.** It says the spawn produced nothing;
  whether a claim was recorded is UNKNOWN, so a conductor that assumes either
  way is load-bearing. The relay reconciles with `docket dispatch verify` and
  `docket step show STEP-N`, and if the step is still claimed, token-free
  `docket step reap STEP-N --reason` clears it — the spawning relay is the only
  party that can assert the holder is gone, and waiting the lease out is
  wasted headroom.
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
