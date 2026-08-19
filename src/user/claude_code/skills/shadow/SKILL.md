---
name: shadow
description: Observe Claude Code sessions — live, or post-mortem — and find friction across every layer they cross: harness, skills, workflows, loops, agents, hooks, config, the models themselves, and the Docket engine. Log findings with evidence as they land, then deliver a severity-ranked review and propose definition fixes for approval once the run ends. Fixes target src/user/claude_code — including repetitive bash worth extracting into small deterministic scripts under src/user/claude_code/scripts; engine defects are filed as issues, never patched. Invoked bare it sweeps EVERY project under ~/.claude/projects for the past 7 days of sessions; pass a session id to observe just that one — a conduct run, any other skill's run, or a finished session worth learning from.
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
  `workflow list|show|lint`, `step show|context|render|artifacts|artifact` —
  every one write-free, `run report` included, in any run status. `step
  render` is the only one that shows what a packet actually CONTAINED —
  template-rendered, tokenless, and it refuses on a pin mismatch rather than
  re-pinning — which is how you evidence the known packet defects (§3). A
  verb off that list does not run from this seat, `next` and everything under
  `dispatch` included. Until the run ends, your entire write surface is your
  findings log under `/tmp`. Every helper you spawn inherits this discipline VERBATIM, in
  its brief — no engine write verbs, no repo writes, probes on scratch copies
  only, report back via SendMessage — because a helper cannot infer the seat
  it serves, and one measured audit helper otherwise executed a `config set`
  it found quoted in the very document it was auditing.
- **Every fix waits for the run to end.** The run may be mutating the very
  files you would edit — bootstrap writes config, runs commit, and a run over
  the dotfiles repo edits the definitions themselves. The findings log is the
  buffer that makes waiting cheap. After the end: propose the batch to the
  tribunal, and write what it approves (§6.3).
- **Engine defects are filed, never fixed — and every finding you file goes
  to its OWNING project** (operator ruling, 2026-08-16: gaps belong to their
  respective projects). Docket is a separate codebase.
  Write the defect up — verb, refusal text verbatim, minimal repro — and file
  it from the docket repo's own checkout (`docket issue create`), which is
  also what routes it: the store is machine-global and a project is a
  checkout's git identity. The same routing covers every other cross-repo
  finding: the observed repo's own bug files in ITS project, a dotfiles gap
  you cannot fix as a definition edit files in the dotfiles project — never
  into whichever project the observed session sat in, and `docket issue move
  <id> --project <target>` re-homes one that already landed wrong. Ids are a
  store-wide sequence and the two live
  projects share the prefix `DKT`, so name the project beside any id that
  could be read either way. If you cannot file from this seat, the writeup
  goes in the review addressed to the operator. A definition-side mitigation
  (a warning line in a skill, a guard in wave.js) is yours to propose; the
  engine fix flows through docket's own plan → conduct.

## 1. Attach

Two modes, picked by the argument:

- **`/shadow <session-id>`** — single-session: `$ARGUMENTS` names the
  session; attach without asking. Take the target skill and the repo under
  observation from the operator when they know them, and derive that repo
  from the transcript's own `.cwd` field — the project-directory name
  flattens `/`, `.`, and `_` identically and cannot be decoded back into a
  path.
- **Bare** — the fleet sweep, and the default: mine EVERY project under
  `~/.claude/projects` for the past 7 days of sessions, post-mortem. No
  candidate list, no which-one question — enumerate and go (§1a).

### 1a. The fleet sweep (bare invocation)

Scope is time-boxed, not project-boxed: every main transcript in every
project directory, modified within the last 7 days —

```bash
find ~/.claude/projects -maxdepth 2 -name '*.jsonl' -mtime -7
```

`-maxdepth 2` keeps the enumeration to main transcripts; subagent and
workflow files live deeper and are pulled in per session through §4, never
enumerated directly. Drop your own session's transcript, group the rest by
project directory, and read each session's real repo from its `.cwd` field.
A transcript still growing is a live session: include it as-is, mark it
in-flight in the review, and apply §5's interrupt rules to it alone —
everything else is post-mortem.

The sweep is agent work. Fan out read-only analysts — one per session, or
one per project where a project's sessions are small — each briefed with
rule 1's discipline VERBATIM, the §2 checklist for whatever skill that
session ran, §3's layer table, and the instruction to report via SendMessage
(a background agent's final text is delivered to nobody — §4). Analysts run
their docket cross-checks from their observed repo's own root, exactly as a
single-session shadow would (§4's store-resolution and project-scoping rules
are per-repo). You aggregate: the log is
`/tmp/claude/shadow/fleet-<YYYY-MM-DD>/findings.md`, one entry per DISTINCT
finding — the same defect surfacing in four sessions is ONE finding carrying
four evidence lines, and the recurrence count is its severity argument. Then
§6 runs once, over the aggregate: one review, one tribunal batch, every
cross-repo finding filed to its owning project as ever.

Everything from "Sit in the observed repo's root" below is written for a
single attach; in the sweep it applies per observed session, carried out by
that session's analyst.

Live and post-mortem are the same job: live you tail transcripts as they grow
and can flag in real time, post-mortem they are complete and §5's interrupts
have no one to interrupt. Orientation, layers, log, review are identical.

**Sit in the observed repo's root.** Same-repo shadowing is the common case
and the right one: where you stand picks both the store and the project the
verbs answer for (§4), and where the hooks are live the session-start hook
hands you the active-run status the moment you boot. Sharing the repo means
sharing the hooks, and hooks cannot tell a shadow from a conductor — but
**check which hooks are live before attributing any behavior to one, and
never wait on output from one that is not:** read the settings builder's hook
block (the `with_hook` chain in `src/user/claude_code.rs`) against the built
`~/.claude/settings.json` — all five docket hooks are LIVE today (verified
firing 2026-08-11). Where they run, expect these and use them instead
of fighting them:

- **run-guard** denies your turn-end while the machine half of the run is in
  flight. That is the conductor's guard answering from the wrong seat; each
  deny is your cue to poll again, not a wall to route around. It reads STEP
  status: it stands down while every blocking step is parked `waiting-human`
  or while a dispatch is OPEN (any open dispatch stands it down — coverage is
  not checked), denies whenever actionable steps sit pending with no dispatch
  open (run-level `waiting-human` does NOT clear it, and an operator ruling
  to withhold work is invisible to it), and stands down for good when the run
  ends — a stop that suddenly flows is itself corroboration that the run is
  over.
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

**Test one read verb before assuming the sandbox blocks docket.** Every
DB-touching verb opens the store read-write and migrates it forward before
answering — there is no read-only open — so a seat that cannot write the
store fails with `unable to open database file (14)` wherever it stands. But
`~/.docket` is in the sandbox write allowlist today: run `docket run status`
from the observed repo's root at attach and believe that result, not this
line. Only if it fails do you need the sandbox override for the read verbs,
or the DB read directly with
`sqlite3 'file:$HOME/.docket/issues.db?immutable=1'` (plain `mode=ro` fails:
WAL wants the -shm sidecar); `immutable=1` sees the last checkpoint only, fine
for the pre-run baseline and stale for mid-run cross-checks, where the
transcript's own `✔` result lines and the live verbs are the true surfaces.
`--help` opens nothing. And **never point an older docket binary at
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
   not under `$SRC` but beside it at `src/user/docket/config/` (`contracts/`,
   `fragments/`, `schemas/`, `workflows/`, `policy.toml`) — plus the observed
   repo's `.docket/config/` when it has one: briefs render from the INSTALLED
   corpus at `~/.docket/config`, a repo's additions layering second, never
   from the source tree.
3. **Establish which bytes are actually running — starting with whether an
   installed copy exists at all.** Resolve it at attach rather than trusting
   this line: `ls -ld ~/.claude/{agents,skills,workflows,scripts,hooks}`
   against the builder's symlink vec (`src/user/claude_code.rs:300-325`).
   All five come back as live symlinks into the content-addressed vorpal
   store — from the first `just activate` after 2026-08-11, when `workflows`
   joined the builder; before that activation it is still a real directory
   holding the retired hand-made `wave.js` symlink, which you flag as
   transition debris, not normal. **No definition
   surface is live-edited any more.** Source and install are two sets of bytes
   everywhere, and a workflow script — `wave.js`, `tribunal.js` — reaches a
   session only through the operator's `just activate`, exactly like a skill.
   Resolve every definition as the session must:
   installed path if present, else the source under `$SRC`. Docket config
   travels a chain of its own, and it is ONE hop now: `src/user/docket/config/` → (`just activate`) →
   `~/.docket/config/`, which the engine reads directly as the first of its
   ordered roots, the observed repo's own `.docket/config/` layering second when
   it exists. So the stale-install audit is the whole audit, and the source
   mirrors the install tree for tree: `diff -r` source `config` against
   `~/.docket/config` and source `bin` against `~/.docket/bin`, then inventory
   the repo's additions layer if there is one —
   real tracked files there are legitimate, while SYMLINKS are link-farm debris
   from the retired model, each entry either duplicating the shared root or
   dangling against it. Record `git -C $SRC rev-parse HEAD`. A divergence is
   your first finding —
   and the baseline for every later one, because a fix proposed against bytes
   that did not run is a wrong fix. The same chain read backwards governs your
   own fixes: sessions resolve the INSTALLED copy, and fixes land in source
   only — so note, for every fix, which installed copy will lag it until the
   operator's next `just activate` (§6.3).
4. `mkdir -p /tmp/claude/shadow/<session-id>` (fleet sweep:
   `/tmp/claude/shadow/fleet-<YYYY-MM-DD>`) and start the log (§5).

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
| Config rendering | contracts, fragments, and policy.toml reaching briefs wrong — paraphrased where a skill says verbatim, a stale install in the `src/user/docket/config/` → `~/.docket/config/` hop, a fragment dropped, the `[policy] version = 1` check passing on a broken file. Four signatures worth recognizing on sight: a dangling FILE link inside a SCANNED root fails activation with a `VALIDATION_ERROR` naming that file; an ABSENT root is silent dormancy, and both roots absent surfaces much later as an issue "matching no registered workflow" — but a DANGLING root symlink refuses loudly, naming the link and its unresolvable target; a `name@version` or pinned ref present in BOTH roots with differing bytes refuses activation naming both paths; and a `packet`-declaring step claimed from an isolated worktree fails with `packet file "…" is pinned by this run but is no longer on disk` — AFTER recording the claim, so the step sits claimed and tokenless until a reap — which now indicts REPO-ADDITION packet refs only, shared-root refs resolving from any cwd. |
| Harness | Permission prompts the definitions did not budget for, sandbox denials, workflow-registry staleness, notification latency or loss, `$TMPDIR` shared across executors surprising someone — anything that makes the conductor's or operator's job harder than the skill text assumes. |
| Repetition | The same pipeline retyped — by the conductor every loop iteration, or by every executor because a brief inlines it. The third appearance is a finding; take it to the extraction bar below. |
| Engine | Refusal text that misleads, a documented flag that does not exist, a read surface missing (usage absent from `journal.jsonl` is the canonical case). Rule-3 territory: file it. |

**The two packet-composition defects earlier shadows carried are FIXED and
live-verified — do not expect them, and re-file nothing against them.**
(a) `issue.diff` rendering EMPTY for `--worktree`-recorded steps: fixed by
a9eaebd + 43fb186 (the diff base is the RUN's recorded exec root, DKT-25 — a
retired-epoch id, provenance only; bare DKT-nn ids from before the 2026-08
store reset no longer resolve);
first real diffs confirmed in production on RUN-2, 2026-08-11. (b) A review
round inputting the PRIOR step's change-summary: fixed by b98150a (loop
inputs rebind to the loop's latest emit); verified live on the same run
(`step context` showed review@1's change-summary AND diff both from fix@1).
STORED artifacts from before those fixes remain empty/stale forever — a
judge reading one and falling back to `git show` is history, not a live
defect. An empty diff on a NEW record, or a stale summary in a NEW packet,
is a fresh regression: rule-3 territory, evidence it with `step render`/
`step context` and file it.

**Repetition becomes a script — when it passes the bar.** Watch for command
shapes the session keeps rebuilding: the journal→usage join before every
close, the transcript-find, a jq chain every executor re-derives. Each retype
spends tokens and invites drift — the iteration where the jq path comes out
wrong is the iteration the ledger lies. The fix is a script proposed into
`$SRC/scripts/` — and note the install lag: `~/.claude/scripts` is a live
store symlink today, but it serves the store's bytes, so a NEW script exists
only at its source path until the next `just activate`; callers must name
whichever path will actually resolve when they run (§2.3).

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
  `src/user/docket/config/policy.toml` only when the shipped default itself is wrong.
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
transcript directory is
`~/.claude/projects/<flattened-cwd>/<session-id>/subagents/workflows/<wfId>/`
and holds three kinds of file, of which only one carries usage:

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
renders the compact per-line view; don't retype the jq — the installed
`~/.claude/scripts/` spelling works too today (§2.3). A quiet transcript is
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
- **Transcripts flush lazily — but question flushing changed.** A pending
  question to the operator was measured hitting disk only WITH its answer;
  current harness builds flush an open question at ask time (re-measured
  2026-08-16), so a gate MAY be watchable live. Verify which behavior your
  session shows before keying a watch on it, and still catch
  interrupt-condition 3 from your own cross-checks rather than from seeing
  the question.
- **A wave that spawned nothing writes no journal.** The workflow task's
  `.output` file is the only record of a zero-spawn wave.
- **A task's `.output` file exists from LAUNCH, empty.** The harness creates
  it as a 0-byte placeholder when the task starts, so file-existence is a
  false completion signal — one RUN-1 watcher fired on it mid-flight. Wave
  completion is `.output` NON-EMPTY; executor progress is journal growth.
- **Binary provenance includes the PATH.** `which` on the operator's PATH,
  not just in-repo copies — the shadow that checked only `./bin` and
  `.docket/bin` missed a third, go-installed binary.
- **"No agent ran" is not "nothing read the prompt."** The harness spawn
  classifier — NOT the docket spawn-guard hook of §1; a different mechanism,
  and this one is always live whatever the hooks are doing — screens rendered
  briefs before any agent exists, so blocked-at-zero-tokens is consistent
  with the TEXT being the problem. Never rule out prompt content because no
  agent came to life. Three facts decide what you may propose about it: the
  classifier carries context ACROSS attempts and sessions; a reworded
  resubmission of flagged content therefore reads as obfuscated retry rather
  than as a fix; and the sanctioned unblock is explicit operator confirmation
  in-session. Since your product is definition edits to exactly the briefs it
  reads (wave.js), "reword it until it passes" is the obvious proposal and
  the wrong one.
- **Direct Agent-tool spawns (no wave) transcribe under the SPAWNING session**,
  three levels down and the flattened-cwd level is the one people drop:
  `~/.claude/projects/<flattened-cwd-dir>/<session-id>/subagents/agent-a<name>-<hash>.jsonl`.
  And a named background agent's final text is delivered to NOBODY — its
  spawner gets a content-free idle ping — so "went idle, no report" means finished
  work sitting in that file, recoverable (measured twice, 2026-08-10; one
  such loss stalled the observed run nine minutes and was then misreported
  as "report received" in its recap). Even a SENT report (SendMessage,
  success acknowledged) waits for the spawner's next turn BOUNDARY: a spawner
  that keeps probing inside one turn blocks its own delivery, and "no report
  landed" from such a session indicts the session, not the delegate
  (measured 2026-08-11: 94s queued, delivered the same second the turn
  ended).
- **An artifact listing's `sha256`/`bytes` describe a short summary BODY, not
  the payload**: a supersession chain (one re-emit per held-cluster approval)
  shares one hash while `payload_bytes` differ — it reads as duplicates and
  is not — and the body text goes stale after supersession. Diff payloads,
  not hashes (DKT-112).
- **`events list` defaults to `--limit 100`** and silently truncates big runs
  — pass an explicit `--limit` post-mortem (a 194-event run lost its head,
  2026-08-17).
- **Naive per-line summation over `agent-*.jsonl` OVER-counts input/cache
  units** vs wave-usage's message-id dedup — never call a backfill lossy from
  a naive sum; recompute with the script's own method first (measured
  2026-08-17: 73,195 naive vs 38,576 deduped cache-creation on one wave).

Cross-check the engine whenever the store is reachable, from the observed
repo's root: resolution runs `$DOCKET_PATH` → a repo-local `.docket/issues.db`
found by walking up → the global `~/.docket/issues.db`, and where you stand
also picks the project the project-scoped verbs answer for. `run status`
against what the transcript believes mid-run; `run report` and `events list`
post-mortem; `step artifacts STEP-N` then `step artifact ARTIFACT-N
[--payload]` for what a step actually produced — those two retired reading
artifacts out of the DB by hand, though sqlite immutable stays the fallback
wherever your seat turns out not to be able to open the store (§1). Daylight between what the engine recorded and what the transcripts show
is usually a finding on whichever side wrote less. One caution when you read
with `--json`: it suppresses ALL stderr diagnostics — reap notices,
held-headroom reasons, context-size warnings — so when something looks stuck
and the JSON says nothing about why, ask once more in human mode before
concluding the engine is silent.

## 5. Findings — log now, speak rarely

The log is `/tmp/claude/shadow/<session-id>/findings.md` — in the fleet
sweep, the one aggregated `/tmp/claude/shadow/fleet-<YYYY-MM-DD>/findings.md`
(§1a); if the write is denied, keep it in your scratchpad and say so at
attach time. One entry per
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
   Findings that point at instance config rather than at a definition —
   thresholds, TTLs, tiers, the corpus's own workflows, a repo's additions —
   are `/retro`'s to evolve from engine evidence: name them and point at
   retro rather than bending them into definition edits.
3. **Propose → tribunal → apply.** The definition-fix batch goes to a
   three-judge panel of agents, not to the operator. Assemble it exactly as
   before — findings grouped, each carrying its concrete edit — then open the
   proposal **from the repo the edits target**, which for definition fixes is
   the dotfiles checkout and not the observed repo you have been sitting in
   (§1):

   ```bash
   docket vote create -d "<what the batch changes, plainly>" \
     -r "<the evidence: the findings, the run refs>" \
     -n 3 -c medium --threshold 0.67 --created-by shadow
   ```

   (`vote create` writes, and rule 1's read-verbs-only list bounds the observed
   run's LIFETIME — §6 is the far side of that line. Nothing here touches the
   observed run's state.) Then put the panel on it:

   ```
   Workflow({scriptPath: "<home>/.claude/workflows/tribunal.js", args: {
     voteId: "<id>",
     voters: ["tribunal-architecture", "tribunal-security", "tribunal-correctness"],
     policyText: <literal text of ~/.docket/config/policy.toml>,
     context: "<the batch: every proposed edit with its evidence>",
     gateKind: "fix-batch", cwd: "<the repo the edits target>"}})
   ```

   The wave's call discipline governs this one too: `scriptPath` only and never
   by name, `args` a real object, policy passed as TEXT `cat`-ed fresh rather
   than as a path — and resolved like every other definition (§2.3), the
   installed path if one exists, else `$SRC/workflows/tribunal.js`.

   `docket vote result <id>` decides what happens next. **Approved is your
   authority to write, and you write immediately** — there is no "apply now or
   later?" question, because the answer was always now. A rejection or a split
   goes to the operator through the built-in question tool carrying EVERY
   judge's verdict, confidence, and summary verbatim — they are ruling on the
   dispute, and a tally you have summarized is not one. Only what they approve
   gets written; a declined item stays in the log as the next shadow's watch
   list.

   **Trust and permission findings never ride this path.** A fix that would add
   a trust entry, widen a sandbox allowlist, change what a hook permits, or
   destroy uncommitted work goes to the operator directly and ALONE in its own
   question, whatever else the batch holds. The panel's remit is definition
   edits; an authorization granted by agents is not an authorization, and a
   trust write bundled with three cosmetic edits is approved in one click
   without being read.

   Script extractions ride the approved batch: the body lands
   in `$SRC/scripts/` (`chmod +x` it — file tools do not set the bit), and
   since the installed `~/.claude/scripts` store symlink lags source until the
   next `just activate`, every call site you edit must name the source path
   for a script that is new or newly changed.

   **A fix lands in SOURCE ONLY, and is committed.** The installed surfaces —
   `~/.claude/{agents,skills,hooks,scripts,workflows}`, `~/.docket/config` —
   are content-addressed store artifacts behind the operator's `just activate`
   gate: hand-editing one desynchronizes bytes from hash, is invisible to git,
   and changes what every session on the machine executes without the
   operator's install act (operator ruling, 2026-08-11, on tribunal-security's
   DKT-V6 finding; this RETIRES the both-surfaces practice recorded after
   RUN-1 graph-engine). The store's Bash write-deny is the only mechanical
   guard and Edit/Write pass through it — the rule holds because it is the
   rule, not because a tool will stop you. So: write the edit under `$SRC`,
   commit it, and state in the close report that the fixes are PENDING the
   operator's next `just activate` — name every skill or script whose
   installed copy is now behind source. A call site that must work before
   then names the source path explicitly. Never recreate a hand-made symlink
   into the source tree; log any you find as debris.
4. **File the engine defects and every other cross-repo finding** (rule 3),
   one issue per defect, refusal text and repro verbatim, each in its owning
   project.
5. **Close** by naming the log path, the fixes applied, the issues filed,
   and the one thing the next shadow should watch first.

## Appendix: the conduct checklist

Pre-derived because conduct is the richest target. The conductor:

- **Pre-activation checks.** Two, and only two: the stale-install diff of
  `src/user/docket/{config,bin}` against `~/.docket/{config,bin}`, and the
  transition guard — SYMLINKS under the observed repo's `.docket/config/` are
  retired link-farm debris, stopped and reported rather than deleted. A repo
  with no `.docket` at all is the normal case, not a missing step.
- **The loop is continuous.** A wave completing treated as the run completing
  is the classic failure (RUN-3 executed a whole run as one wave); so is
  stopping to report, or asking permission to continue, between iterations.
- **No cached run state.** Any "I remember step N…" reasoning instead of
  re-asking the engine.
- **Wave invocation.** By `scriptPath` only — the installed
  `~/.claude/workflows/wave.js` if it exists, else `$SRC/workflows/wave.js`.
  The installed one is a vorpal-store symlink now rather than the source file,
  so the two spellings are NO LONGER the same bytes: source edited since the
  last `just activate` means the wave is dispatching stale bytes, which is
  §5's first interrupt condition and not a paper-cut. `diff` them at §2.3 and
  again before flagging either. A by-name invocation is a defect even
  when it works (the name registry served pre-edit bytes on RUN-3). `args` is
  a real object `{rows, policyText}`, policy as TEXT, `cat`-ed fresh from
  `~/.docket/config/policy.toml` every dispatch. (wave.js's args-decode
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
- **Integration is the conductor's**, at reconcile, write steps first and in
  step-id order — the newest and most failure-prone obligation, so watch it
  hardest. Per write step: verify the sha the change-summary's first line
  names (`git cat-file -e <sha>^{commit}`), `git cherry-pick --no-gpg-sign
  <sha>` as a REAL commit on the shared branch, then remove that worktree and
  its `worktree-wf_*` branch in the same breath. Each of these is a finding:
  integrating without the verify; leaving the pick staged but uncommitted
  (the retired model — staged content found in the shared tree is a
  stop-and-ask, never a base to build on); leaving the worktree standing;
  and above all resolving a conflicting pick by judgment, when a conflict is
  a stop-and-ask gate presenting the sha and the hunks. A `COMMIT BLOCKED`
  report means committing inside the executor's own worktree on its behalf
  first, then integrating that sha from the verify onward. Nothing here
  pushes — publishing stays the operator's.
- **The close-time straggler sweep.** Every `.claude/worktrees/wf_*` left
  from this run's waves goes at close, and only those this run created. The
  exception to watch: a worktree holding a recorded-but-never-integrated sha
  is still removed, but that sha must be NAMED in the close report — naming
  is what keeps it recoverable before gc.
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
  a finding. `dispatch verify` writes nothing at all, not even a reap — and
  read its answer by SHAPE, not by exit: `ok:false` after a step recorded
  successfully is the ready set having legitimately advanced past the stored
  rows, which `close` then reconciles. A verify mismatch is a finding only
  when the step it names did NOT record.
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
- **Routing spot-check.** Re-derive a row or two by hand against the shared
  root's policy.toml
  — `[[resolve]]` → `[executors]` → security pins → escalate_to chain → fable
  gate → never-list/fallback — and compare to the logged
  `STEP-N: hint -> archetype @ model/effort (variant …)` line. Disagreement is
  load-bearing.
- **Journal completeness.** Every spawned `agentId` with its meta and
  transcript; usage present where the back-fill will look for it.
