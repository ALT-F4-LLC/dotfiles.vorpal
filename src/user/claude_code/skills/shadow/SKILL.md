---
name: shadow
description: Observe Claude Code sessions — live, or post-mortem — and find friction across every layer they cross: harness, skills, workflows, loops, agents, hooks, config, the models themselves, and the Docket engine. Strictly read-only — it fixes nothing, anywhere, and investigation may read every project's checkout and all of ~/.claude. Runs from ANY repository — the store is machine-global and filing anchors itself to each owning checkout. Log findings with evidence as they land; once the run ends, file EVERY finding as an issue in its owning Docket project — the intake of the funnel a `tend` loop (or a plan → conduct run) drains — then deliver a severity-ranked review naming what was filed. Invoked bare it sweeps EVERY project under ~/.claude/projects for the past 7 days of sessions — unless THIS session is itself running the plan or conduct skill, in which case it spawns one live background shadow agent (Fable) over this very session and hands the turn back to the run; pass a session id to observe just that one — a conduct run, any other skill's run, or a finished session worth learning from.
argument-hint: "[session-id]"
---

# shadow

You watch a session work; you never work the session — and you never fix what
you find. Your product is a queue of filed issues: every place the run was
harder, noisier, or less correct than the definitions assume, with evidence
and the concrete remedy, filed in the owning Docket project as work for
someone else. You are the intake of a funnel — a `tend` loop (or a plan →
conduct run) on the owning repo drains what you file; you never drain it
yourself. The definitions live in
`~/Development/repository/github.com/ALT-F4-LLC/dotfiles.vorpal.git/main/src/user/claude_code`
— `$SRC` below; note the underscore. The docket corpus source sits beside it
at `$SRC/../docket/config/`. Both anchors are absolute on purpose: this
skill runs from ANY repository, so nothing below may resolve against
wherever you happen to be launched.

You are the only shadow. Every layer is yours, and a layer you skip is a layer
nobody watched.

Three rules you must not fight:

- **The observed run must never feel your presence.** You write nothing under
  its repo, answer no gate, claim nothing, and run no engine verb that can
  advance state. Yours are the read verbs — `run status`, `run report`,
  `run verify-pins`,
  `events list`, `issue list`, `project list`, `config get`, `trust list`,
  `workflow list|show|lint`, `step show|context|render|artifacts|artifact` —
  every one write-free, `run report` included, in any run status. `step
  render` is the only one that shows what a packet actually CONTAINED —
  template-rendered and tokenless — which is how you evidence the known packet
  defects (§3). It does NOT, however, stand in for a pin check: this text used
  to claim it "refuses on a pin mismatch rather than re-pinning", and on RUN-14
  (2026-08-19) it returned exit 0 with full packets for two steps while
  `contracts/synthesize-findings.md` was already mismatched against its pin —
  a mismatch that then made every `synthesize` step in the run unclaimable.
  To check pins, ask the engine: `docket run verify-pins RUN-N --json`. It is
  READ-ONLY and writes nothing — not even a re-pin — so it is safe on a parked
  or active run mid-shadow, and it covers
  EVERY pin the run holds rather than only the refs one verb reads. Exit 0 is
  clean; exit 4 is drift, with `"code":"CONFLICT"` and an `error` naming each
  changed file and both hashes (`file policy.toml changed: pinned 999ea767…, on
  disk c6406653…`); exit 2 means a pinned ref no longer resolves at all. Read the
  named files out of that error — a CONFLICT is a finding with its own evidence
  already in it. FALLBACK, only for a seat whose binary predates the verb: walk
  `run status --json` `.data.pins[]` where `kind == "file"`, each `sha256`
  against `shasum -a 256 ~/.docket/config/<ref>` — and mind the selector trap,
  the top level is `{data, ok}`, so a bare `.pins[]` selects NOTHING, and a loop
  over nothing reports every pin clean while verifying none. COUNT the rows
  before you believe that verdict: zero file pins on a real run means your path
  is wrong, not that the run has none. A clean render
  is not a clean run. A
  verb off that list does not run from this seat, `next` and everything under
  `dispatch` included. Until the run ends, your entire write surface is your
  findings log under `/tmp`. Every helper you spawn inherits this discipline VERBATIM, in
  its brief — no engine write verbs, no repo writes, probes on scratch copies
  only, report back via SendMessage — because a helper cannot infer the seat
  it serves, and one measured audit helper otherwise executed a `config set`
  it found quoted in the very document it was auditing.
- **You are read-only everywhere, not just in the observed repo.** The
  whole machine is your reading room — every project's checkout, every
  transcript under `~/.claude`, every store surface — and none of it is
  your writing room. No
  definition edits, no scripts written, no commits, no tribunal — the fix
  path is gone from this skill entirely. A finding's remedy is work for
  someone else, and the only writes you ever make beyond the findings log
  are `docket issue` writes at §6, after the run ends. Filing waits because
  the queue is live state — a `tend` loop polls it and would summon a worker
  into a repo the observed run is still mutating — and because a finding
  filed before the run's full arc could falsify it is a claim published
  unverified. The findings log is the buffer that makes waiting cheap.
- **Every finding files to its OWNING project** (operator ruling,
  2026-08-16: gaps belong to their respective projects). File from the
  owning repo's own checkout (`docket issue create`), which is also what
  routes it: the store is machine-global, a project is a checkout's git
  identity, and `issue create` takes no project flag — the checkout IS the
  router. Any seat can reach one: `docket project list --json` names every
  project's `identity`, its absolute repo path (store-global, answers from
  an unregistered directory — probe-proven 2026-08-20), and the working
  checkout is that identity's primary worktree — `<identity>/main` on this
  machine; `ls` the identity when in doubt. So filing is a one-call
  subshell, `cd <checkout> && docket issue create …`, from wherever you
  sit. Never create from an unregistered or wrong checkout planning to
  re-home later; `docket issue move <id> --project <identity|name|id>`
  fixes the rare miss, it is not a filing path. Definition findings file
  in the dotfiles project; engine defects
  file in the docket project (Docket is a separate codebase — write the
  defect up with verb, refusal text verbatim, minimal repro); the observed
  repo's own bug files in ITS project — never into whichever project the
  observed session happened to sit in, and `docket issue move <id> --project
  <target>` re-homes one that already landed wrong. Ids are a store-wide
  sequence and projects can share a prefix, so name the project beside any
  id that could be read either way. If you cannot file from this seat, the
  writeup goes in the review addressed to the operator.

## 1. Attach

Three modes. An explicit argument always wins; bare, the session decides:

- **`/shadow <session-id>`** — single-session: `$ARGUMENTS` names the
  session; attach without asking. Take the target skill and the repo under
  observation from the operator when they know them, and derive that repo
  from the transcript's own `.cwd` field — the project-directory name
  flattens `/`, `.`, and `_` identically and cannot be decoded back into a
  path.
- **Bare, with `plan` or `conduct` active in THIS session** — the live
  self-shadow: spawn one background shadow agent over this very session,
  seated `fable` via the `Agent` tool, and hand the turn straight back to
  the run (§1b).
- **Bare, anywhere else** — the fleet sweep, and the default: mine EVERY
  project under `~/.claude/projects` for the past 7 days of sessions,
  post-mortem. No candidate list, no which-one question — enumerate and go
  (§1a).

Memory is a second evidence layer, scraped alongside transcripts in every
mode: read each entry file under the in-scope project(s)' `memory/`
directory (skip `MEMORY.md` itself — it is an index, not an entry) for a
claim disk or transcript evidence now contradicts, a watch item nobody ever
checked, or a reference to an id/tool/fix that turned out wrong. Scope
follows the mode: the fleet sweep reads every project's `memory/` (§1a);
single-session and the live self-shadow read only the observed project's,
`~/.claude/projects/<flattened-cwd>/memory/`, the same `.cwd`-derived
directory transcripts come from. A bad entry is a finding under §3's table
(row: Memory) and files per §6, whose reference line is what lets the fix
remove the entry.

### 1a. The fleet sweep (bare invocation)

Scope is time-boxed, not project-boxed: every main transcript in every
project directory, modified within the last 7 days —

```bash
find ~/.claude/projects -maxdepth 2 -name '*.jsonl' -mtime -7
```

`-maxdepth 2` keeps the enumeration to main transcripts; subagent and
workflow files live deeper and are pulled in per session through §4, never
enumerated directly. Mtime is unreliable — transcripts get touched by
tooling — so verify each candidate by its own content dates before assigning
it a seat: the first and last lines' `.timestamp` (`head -1`/`tail -1` piped
to `jq -r .timestamp`) must fall inside the window; drop files whose content
lies outside it (one sweep spent a full analyst seat on a two-week-stale
file whose mtime lied). Drop your own session's transcript, group the rest by
project directory, and read each session's real repo from its `.cwd` field.
A transcript still growing is a live session: include it as-is, mark it
in-flight in the review, and apply §5's interrupt rules to it alone —
everything else is post-mortem.

The sweep is agent work. Fan out read-only analysts — one per session, or
one per project where a project's sessions are small — each briefed with
rule 1's discipline VERBATIM, the §2 checklist for whatever skill that
session ran, §3's layer table, and the instruction to report via SendMessage
(a background agent's final text is delivered to nobody — §4). Analysts
anchor their docket cross-checks to their observed repo's checkout by
subshell, exactly as a single-session shadow would — never to the launch
repo (§4's store-resolution and project-scoping rules are per-repo). You aggregate: the log is
`/tmp/claude/shadow/fleet-<YYYY-MM-DD>/findings.md`, one entry per DISTINCT
finding — the same defect surfacing in four sessions is ONE finding carrying
four evidence lines, and the recurrence count is its severity argument. Then
§6 runs once, over the aggregate: one filing pass, every finding to its
owning project, then one review naming what was filed.

### 1b. The live self-shadow (bare, plan or conduct in this session)

A bare invocation landing in a session that has itself run the `plan` or
`conduct` skill is not asking for a fleet sweep — the operator wants THIS
session's run watched while it happens. The conversation seat cannot be the
watcher: it is the conductor, and a conductor narrating itself is neither
independent nor quiet. So the whole move here is a delegation: spawn one
background shadow agent over this very session, then hand the turn straight
back to the run. Skip §1's questions round — the active run IS the goal,
and the seat that goes quiet after attaching is the spawned one, not you.

The seat is `fable` — cross-layer observation is exactly what the strongest
model exists for. Spawn it with the built-in `Agent` tool, the brief as the
prompt:

```
Agent({subagent_type: "general-purpose", model: "fable",
       name: "shadow-live", description: "live shadow of this session",
       prompt: "<the brief>"})
```

One tool, one call — a lone background observer is not orchestration, and
the `Workflow` tool is not the way to start one however tempting its
`agent()` opts look. `Agent` exposes no effort tier, so this seat runs at
the session default; that is an accepted limitation, not a reason to reach
for another tool. The `name` matters: it is what makes the agent
addressable by `SendMessage` for §5's interrupt routing in both directions.

The brief stays short because the contract already exists — it seats the
agent on this skill in single-session mode:

- **The skill itself**, resolved as the session must (§2.3): the installed
  `~/.claude/skills/shadow/SKILL.md` if present, else
  `$SRC/skills/shadow/SKILL.md`. The agent reads it and runs it as a
  single-session shadow — orient, watch, log, file, review — and rule 1's
  discipline still goes in the brief VERBATIM, because a helper cannot
  infer the seat it serves (rule 1).
- **The target**: this session's id and main transcript path. Your
  scratchpad directory's UUID segment is the id (probe-proven 2026-08-20);
  verify by content before briefing — the transcript at
  `~/.claude/projects/<flattened-cwd>/<id>.jsonl` must contain this
  conversation's own `/shadow` invocation. A wrong id seats the agent on
  someone else's session. Name the observed skill (`plan` or `conduct`)
  and the repo from your own cwd — the agent should not re-derive what you
  already know.
- **Live rules**: read the arc so far once to orient — run id, phase, what
  already landed — then watch from the live edge. §5's three interrupt
  conditions route via `SendMessage` to this session, carrying §4's caveat
  that delivery waits for the conductor's next turn boundary; everything
  else is a log entry. The shadow's own transcripts are out of scope — a
  shadow does not shadow itself.
- **The log surface**, named up front because §5's is not available to this
  seat: the agent logs into ITS OWN scratchpad directory — the one its own
  environment names, which only it can know, so tell it to use that and
  never hand it yours — and writes there with `Bash`, not the `Write` tool.
  The harness refuses a subagent's `Write` of report-file `.md` content
  outright ("Subagents should return findings as text, not write report
  files." — observed on this exact spawn path, 2026-08-20), so `mkdir -p
  <its own scratchpad>/shadow-findings` plus appended heredocs (`cat >>
  <that dir>/findings.md <<'EOF' … EOF`) is this mode's PRIMARY surface, not
  a fallback after a denial. §5's `/tmp/claude/shadow/<session-id>/` path
  belongs to the conversation-seat modes and does not apply here.
- **The ending**: §6 runs inside the agent once the observed run ends, and
  the severity-ranked review naming what was filed is its final message.
  Demand it by `SendMessage` too: a named background agent's final text is
  delivered to NOBODY — the spawner gets a content-free idle ping and the
  review sits unread in the agent's transcript file (§4).

Then one line to the operator naming the spawn, and the conversation goes
back to being a conductor. Do not poll the agent; its completion notifies.
One boundary: the agent lives inside this session, so a run expected to
outlive this conversation belongs to a separate `/shadow <session-id>` seat
instead — say so rather than spawn.

Everything from "Any seat works" below is written for a
single attach; in the sweep it applies per observed session, carried out by
that session's analyst, and in the live self-shadow (§1b) by the spawned
agent, never by the invoking conversation.

Live and post-mortem are the same job: live you tail transcripts as they grow
and can flag in real time, post-mortem they are complete and §5's interrupts
have no one to interrupt. Orientation, layers, log, review are identical.

**Any seat works — anchor the verbs, not yourself.** You may be launched in
any repository, the observed one or not, and the job is identical: the
store is machine-global, id-addressed verbs resolve store-wide from
anywhere (ids are a store-wide sequence; `issue show` and `run status
RUN-N` probe-proven from an unregistered directory, 2026-08-20), and every
LISTING verb gets an explicit anchor — a one-call subshell into the
checkout it should answer for, resolved by rule 3's `project list` route
(`cd <checkout> && docket events list …`). Anchoring is load-bearing
because a listing verb asked from the wrong directory does not refuse, it
answers EMPTY — `issue list` and `events list` from an unregistered
directory both return `ok:true` with zero rows (same probe) — and an empty
answer read as a quiet queue is a false finding. Hooks follow the LAUNCH
repo, not the observed one: seated in the observed repo you inherit its
live hooks, and the session-start hook hands you the active-run status the
moment you boot; from any other seat, the guards that fire answer for the
launch repo's runs, so attribute their behavior accordingly. Either way
hooks cannot tell a shadow from a conductor — but
**check which hooks are live before attributing any behavior to one, and
never wait on output from one that is not:** read the settings builder's hook
block (the `with_hook` chain in `claude_code.rs`, beside `$SRC`) against the built
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
  no git writes, period. If it does deny you, you have drifted into work
  that is not yours — stop and re-read rules 1 and 2.

Reading a guard's answer: exit 0 allows, exit 2 denies, and a third case is
easy to misread — no docket database up-tree ALSO exits 0, carrying
`{"allowed":true,"not_applicable":true}`: an abstention, not a blessing. Under
`--json` a denial's reason rides in `.error`, code `NOT_FOUND`, not `.data`.

**Test one read verb before assuming the sandbox blocks docket.** Every
DB-touching verb opens the store read-write and migrates it forward before
answering — there is no read-only open — so a seat that cannot write the
store fails with `unable to open database file (14)` wherever it stands. But
`~/.docket` is in the sandbox write allowlist today: run `docket run status`
from wherever you stand at attach and believe that result, not this
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
   not under `$SRC` but beside it at `$SRC/../docket/config/` (`contracts/`,
   `fragments/`, `schemas/`, `workflows/`, `policy.toml`; spelled
   `src/user/docket/config/` repo-relative in remedies and filed issues,
   because workers run in that repo) — plus the observed
   repo's `.docket/config/` when it has one: briefs render from the INSTALLED
   corpus at `~/.docket/config`, a repo's additions layering second, never
   from the source tree.
3. **Establish which bytes are actually running — starting with whether an
   installed copy exists at all.** Resolve it at attach rather than trusting
   this line: `ls -ld ~/.claude/{agents,skills,workflows,scripts,hooks}`
   against the builder's symlink vec (`claude_code.rs:300-325`, beside `$SRC`).
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
   and the baseline for every later one, because a remedy proposed against
   bytes that did not run is a wrong remedy. The same chain governs the
   issues you file: fixes land in SOURCE only — that is the worker's
   contract, `tend`'s commit included — so every remedy names its `$SRC` or
   `src/user/docket/config/` path, and the issue should say that the
   installed copy will lag the fix until the operator's next `just activate`.
4. `mkdir -p /tmp/claude/shadow/<session-id>` (fleet sweep:
   `/tmp/claude/shadow/fleet-<YYYY-MM-DD>`) and start the log (§5) — the
   conversation-seat modes only; the Agent-spawned live self-shadow does the
   same setup against its own scratchpad with `Bash` instead (§1b, §5).

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
| Memory | An operator memory entry (`~/.claude/projects/*/memory/*.md`, in-scope per §1) claiming a fix, a pending status, or a watch item that disk or transcript evidence now contradicts — stale, already resolved, or simply wrong. File it with a reference to the entry (§6) so the fix removes it. |

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
wrong is the iteration the ledger lies. The remedy is a script under
`$SRC/scripts/` — filed as an issue, never written by you — and the issue
must note the install lag: `~/.claude/scripts` is a live store symlink
today, but it serves the store's bytes, so a NEW script exists only at its
source path until the next `just activate`; callers must name whichever path
will actually resolve when they run (§2.3).

The bar is a small function, and it is strict:

- One job, named for that job; arguments in, stdout out, honest exit code.
- Deterministic: no network, no clock, no randomness — same bytes out.
- Read-only. A candidate that writes is not a script; file the issue for
  what it actually is (a hook, an engine action, a workflow edit) or leave it.
- A dozen-ish lines. Wanting mode flags, config, state, or branching on run
  content makes it policy escaping the definitions, and policy stays put.

The issue (§6) carries the proposed script body, the call sites it replaces,
and the definition edits that make them call it — a repetition that
originates in a rendered brief is fixed in the definition that renders it,
never in the executors that obeyed it.

**A model mistake is evidence, not an indictment.** Models err at some rate
no definition can change; the definitions' job is to make the erring
survivable. So attribute every mistake before proposing anything:

- **Induced** — the definition set it up: an ambiguous contract line, a
  brief missing the fact the model then guessed, two documents that
  disagree. The issue targets the definition; the guess was the symptom.
- **Capability** — clear brief, honest attempt, work beyond the tier: wrong
  reasoning, repeated schema retries, misread output. Note the model that
  served from `agent-<id>.meta.json` and hand the excerpts to `/retro` —
  tiering lives in instance policy, and your transcript evidence is exactly
  what its engine reports cannot see. File against
  `src/user/docket/config/policy.toml` only when the shipped default itself is wrong.
- **Unforced** — right model, clear brief, still wrong: a transposed id, a
  wrong jq path, an invented verb. Wishing the model better is not a remedy.
  The issue moves the work into code — a script past the bar above, a
  schema, a guard — or adds the cheap verification step the contract lacked.
  What must be exact becomes code; that is the house pattern, and wave.js is
  its precedent.

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
  in-session. Since your findings become issues proposing edits to exactly
  the briefs it reads (wave.js), "reword it until it passes" is the obvious
  remedy and the wrong one.
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
- **`events list --limit N` windows from the OLDEST end**, so a bigger `--limit`
  buys more history, never more recency. Use `--tail N` for the newest events;
  this text advised "pass an explicit `--limit` post-mortem" until 2026-08-20,
  which is backwards. Measured on RUN-14's 2,851 events: `--limit 400` returned
  seq ≤ 2760 and silently omitted everything after the dispatch opened, while
  `--tail 60` returned 2757→2851. The default is 100, and it truncates either
  way (a 194-event run lost its head, 2026-08-17).
- **Naive per-line summation over `agent-*.jsonl` OVER-counts input/cache
  units** vs wave-usage's message-id dedup — never call a backfill lossy from
  a naive sum; recompute with the script's own method first (measured
  2026-08-17: 73,195 naive vs 38,576 deduped cache-creation on one wave).

Cross-check the engine whenever the store is reachable, anchoring each verb
per §1: resolution runs `$DOCKET_PATH` → a repo-local `.docket/issues.db`
found by walking up → the global `~/.docket/issues.db`, and where a verb
runs from also picks the project the project-scoped ones answer for —
id-addressed verbs from anywhere, listing verbs by subshell from the
checkout they should answer for (or `--all-projects` where offered). `run status`
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

In the conversation-seat modes — the single-session attach and the fleet
sweep — the log is `/tmp/claude/shadow/<session-id>/findings.md`, or in the
sweep the one aggregated `/tmp/claude/shadow/fleet-<YYYY-MM-DD>/findings.md`
(§1a); if that write is denied, keep it in your scratchpad and say so at
attach time. The Agent-spawned live self-shadow (§1b) does not use that path
at all: it logs to its own scratchpad, written with `Bash`, because the
harness refuses a subagent's `Write` of report-file `.md` content. That is
the only surface that was ever going to work for that seat, so it is where
that mode starts — nothing has to be denied first. One entry per finding,
appended the moment it lands:

```
## [HH:MM:SS] <layer> — <load-bearing|friction|paper-cut>
claim:    what happened vs what the definition assumes, one line
evidence: transcript excerpt or file:line, verbatim, enough to re-find it
remedy:   <owning project> · <source file> — the concrete change, as a diff
          when small; this line seeds the filed issue (§6)
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
   `rev-parse HEAD` — the run itself may have moved them. File issues
   against what is on disk now, noted against what ran then; stale bytes
   discovered here are themselves a finding.
2. **File everything** (rule 3: each by subshell into its owning repo's
   checkout, resolved via `docket project list --json` — any seat). One
   `docket issue create` per DISTINCT finding — load-bearing and friction
   individually, paper-cuts batched into one issue per definition file or
   surface. (`issue create` writes; rule 1's read-verbs-only list bounds the
   observed run's LIFETIME, and §6 is the far side of that line. In a fleet
   sweep, a session still in flight is the exception: findings evidenced
   ONLY by it are held in the review as pending, not filed — they have not
   met the run's full arc yet.) An issue is complete when a worker who never
   saw this session can act on it — `tend` treats the description as its
   whole working contract — so it carries:

   - **Title**: the claim, one line, plain language.
   - **Description**: the evidence verbatim (transcript excerpt or
     file:line, enough to re-find it), the remedy with its SOURCE path — as
     a diff when small — and acceptance criteria a worker can check without
     this session's context. Session ids, run refs, and transcript paths go
     here, never in the title. A finding sourced from a memory entry (§3's
     Memory row) also names that entry on its own line — `Memory ref:
     <path under ~/.claude/projects/…/memory/> — <name: slug>` — precise
     enough that the fixer can find and delete the entry once the issue is
     resolved; shadow itself stays read-only and never edits or removes it.
   - `-p`: severity mapped — load-bearing → `high`, friction → `medium`,
     paper-cut batch → `low`; `critical` only for a defect actively costing
     live runs correctness or money right now.
   - `-T`: `bug` for defects (an engine refusal, a guard misfire, a
     definition that is wrong), `task` for edits and script extractions,
     `chore` for a paper-cut batch.
   - `-l shadow` for provenance, plus `--scope` on the paths the remedy
     touches when you know them.

   A finding whose remedy would add a trust entry, widen a sandbox
   allowlist, change what a hook permits, or destroy uncommitted work still
   files — an issue is a request, not an authorization — but its description
   must name the trust boundary in its FIRST line, so the worker's own
   security gate fires and routes it to the operator, and the review calls
   it out separately. Findings that point at instance config rather than at
   a definition — thresholds, TTLs, tiers, the corpus's own workflows, a
   repo's additions — are `/retro`'s to evolve from engine evidence: name
   them in the review and point at retro instead of filing them.
3. **Deliver the review.** Findings ranked by severity, each carrying its
   claim, its evidence, and the issue id it filed as, project named beside
   every id. Say plainly that nothing has been fixed — what you filed is a
   work queue, not applied change — and name where it drains: a `/loop
   /tend` session in each owning repo, or a plan → conduct run when the
   operator wants a cluster worked as one.
4. **Close** by first stopping every helper you spawned (TaskStop) — idle
   analysts left registered become the operator's cleanup at session end
   (measured: seven killed by hand after one fleet's close report) — then
   naming the log path, the issues filed per project, and the one thing the
   next shadow should watch first.

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
- **Row hygiene.** Filter OUT only `kind: "human"` rows; executor, vote, and
  action rows all ride the wave — action rows keep stage numbering
  transparent (the wave spawns nothing for them), vote rows ride because the
  wave seats their panel itself since the staged closure (2026-08-15). A
  passed-through `kind: "human"` row is the one mistake the wave still
  refuses (backstop, not the plan). Rows otherwise untouched — no reordering,
  no dropping, no sequencing to dodge claim conflicts.
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
