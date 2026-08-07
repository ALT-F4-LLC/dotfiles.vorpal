---
name: bootstrap
description: Draft a complete .docket/config/ for a repo that has none — seed the seven project specs, mine the repo, adapt a shipped template, propose trust entries, and surface the whole binding for approval before the first run. Use at project start, or when `docket run activate` reports no workflow matches an issue. Also the way to bootstrap docs/spec/ on a repo with no engine running yet ("create specs", "generate project specs").
---

# bootstrap

You draft this repo's instance config. The developer provides work and
approvals; you do everything else. `.docket/config/` is machine-authored and
nobody hand-edits it after.

Two rules you must not fight:

- **Never run `workflow register` or `schema register`.** Activation
  auto-registers `.docket/config/`, schemas before workflows. Registering by
  hand freezes a `name@version` before the human has seen it.
- **Never add a trust entry before the human approves it.** You propose; they
  say yes; then you run `trust add --yes`.

## 0. Seed the specs

§2 asks you to mine this repo and §3 refuses any file you cannot cite. The seven
engineering specs are what make those citations cheap and honest — a `testing.md`
that says "no tests exist" decides, on its own, whether you keep a workflow with a
`tests` gate. So they are an *input* to mining, and they are written first.

Skip this section when `docs/spec/` already holds the seven. Re-authoring them is
the `spec-project` pipeline's job, not yours (§0's closing note).

**The contract is the authority.** Read `~/.claude/docket-config/contracts/spec-author.md`
before spawning anything: it defines the seven axes, what each one explores, and the
rigorous-honesty rule that governs all of them. Do not restate its guidance here or
paraphrase it into a brief — hand the file's text to each author and let it speak.
The gap section is where a spec earns its keep, and an invented capability is the
failure mode that outlives the run.

Spawn seven `executor-write` agents in ONE message so they author concurrently, one
axis each:

```
Agent(subagent_type="executor-write", name="spec-author-<axis>", prompt=...)
```

for `architecture`, `security`, `operations`, `performance`, `code-quality`,
`review-strategy`, `testing` — the same seven hint names `spec-project.toml` fans
out over, so a later graph run re-authors the same files under the same identities.

Each agent's prompt carries the verbatim text of `contracts/spec-author.md`, its one
axis, today's date (`date +%Y-%m-%d`), the project name
(`basename $(git rev-parse --git-common-dir) | sed 's/\.git$//'` — worktree-safe),
and its output path `docs/spec/<axis>.md`. Tell it plainly: write only that file,
never a name outside the seven, and skim siblings already on disk to avoid overlap
without ever blocking on one.

These are leaf agents. They must not spawn, form a team, or call `Skill()`.

**No engine is running yet, and that is the point.** There is no `.docket/` to claim
against, no lease, no gate — which is exactly why this section exists rather than
deferring to `spec-project`. That pipeline needs `.docket/config/` (§1) and an
activated run (§5), so it cannot produce the specs §2 wants to read. Seeding here is
what breaks that circle.

**Verify before moving on — with an agent, not your own eyes.** Take
`git status --porcelain > "$TMPDIR/pre-fanout"` before you spawn. After all
seven return, spawn ONE `executor-read` agent to verify and report a
checklist: diff the snapshot against `git status --porcelain` now, confirm
every added line is a path under `docs/spec/` and that there are seven, and
check each file opens with a `# ` title, carries a `Status: … <date>` line,
and ends in its gaps section. You act on the checklist — respawn a stalled
axis, revert a stray — you do not perform the reading. You are an
orchestrator; the whole of this skill's hands-on work belongs to agents.
Anything else is a collateral write, and it happens: the `executor-write`
archetype grants a full write surface, so the contract's prose is the only
containment — and on the 2026-08-06 run prose did not hold: an author left a
non-compiling Go file in `internal/engine/`, breaking test compilation for the
whole package the run was about to gate. On a hit, revert the stray (`rm` an
untracked file, `git checkout --` a modified one) and tell the operator what
you reverted and which axis you suspect; if it might be the operator's own
work in progress, leave it and say so instead.

A missing or dateless file in the checklist means its author stalled —
respawn that one axis. Say plainly in §5 that these specs are seeded rather
than gate-validated: `doc-validate` and `reserved-name-check` run under
`spec-project`, not here, so their structural guarantees do not apply yet. If
the repo ships those gates itself, have the verification agent run them
against the seven directly; a real exit 0 beats a predicted one, and the
2026-08-06 run got both green this way. Diff a shipped gate's expectations
against the contract's Emit section only when running it is not possible.

One staleness trap these specs carry: they describe the tree as it stood
*before* §1 copied the config in, so a spec's true-when-written claim that
`.docket/config/` is absent is false by activation. Do not hot-edit a spec to
fix that — especially not while a write-class step holds the tree — note it in
the hand-off and let the `spec-project` review pass catch it; that is the
mechanism built for exactly this.

## 1. Start from the corpus

```bash
docket init                                   # if .docket/ does not exist

# Bootstrap is for a repo with NO config. Refuse rather than overwrite one.
if [ -n "$(ls -A .docket/config 2>/dev/null)" ]; then
  echo "config exists — evolving it is retro's job, not bootstrap's"; exit 1
fi
cp -R ~/.claude/docket-config/. .docket/config/

# The corpus does not activate without these two. Set them now; §4b argues the
# numbers and is where the operator approves or changes them.
docket config set vote.rule.security-acceptance.threshold 0.67
docket config set vote.rule.doc-acceptance.threshold 0.60
```

**If the guard fires, stop.** `cp -R` is an overwrite, and what it overwrites is
the per-file provenance header §3 tells you to write — the mined citations and
`THIN SPOTS` records that are the only account of why the config looks the way
it does (DKT-86 lost exactly this). The corpus does not carry them, so the copy
replaces reasoning with defaults and nothing downstream notices. Refreshing an
adapted config against a newer corpus is a merge, it is retro's job, and it goes
through a version bump. Tell the operator and suggest `/retro`.

**Why those two lines are here and not later.** Activation validates EVERY
registered workflow, not just the one an issue binds, and two of the nine name a
`vote_rule`. Until both rules exist, `run activate` refuses outright — on a
virgin project, for an unlabelled issue that never touches a vote gate. Setting
them at copy time means the first activation an operator sees is a real one.
They authorize no execution, so they are safe to set before approval; what needs
approval is the NUMBER, which §4b puts in front of the operator.

`~/.claude/docket-config/` is the shipped corpus: `workflows/`, `contracts/`,
`fragments/`, `schemas/`, and `policy.toml`. List it for the current inventory —
counts written here go stale. It is a local reference copy — no network, nothing
to fetch. Start here whenever the repo's shape is anywhere near
it, because it encodes a working review topology you would otherwise re-derive.

For a repo unlike it, fall back to a template:

```bash
docket workflow init --template standard-dev  # or parallel-check
```

`standard-dev` is check-then-approve, one fenced gate. `parallel-check` is
prepare → parallel checks → summarize → verify. Pick by the repo's shape.

Either way §2's mining discipline governs what you keep. **Copying is not
adapting** — see §3.

## 2. Mine the repo

Read, don't guess — and the reading is not yours. Spawn THREE `executor-read`
miners in ONE message, each owning one seam and returning a structured,
citation-bearing summary (`claim → file:line`); you compose their returns and
never bulk-read the repo yourself. An orchestrator whose context fills with
Makefile bodies has spent what §5's approval conversation needs:

- **build/CI miner** — build files, CI config, the real check commands and
  who runs them (the paragraphs below on build files are its brief).
- **gate/script miner** — every gate-shaped script in the repo: what each
  actually does, what it reads, what would make it exit non-zero. It also
  RUNS each check command once and reports the real exit code (see below —
  that instruction travels into its brief).
- **docs/history miner** — `docs/spec/` (the paragraphs below on specs are
  its brief), README/CONTRIBUTING, `git log --format='%s' -50`, and any
  deleted-config archaeology the history shows.

Every adaptation in §3 cites something a miner found:

**Start with `docs/spec/`** — §0 wrote it, or it was already there, and it is the
densest source you have. `testing.md` tells you whether a `tests` gate has anything
to gate and what the real pyramid is; `operations.md` names the CI jobs that gate
merges today; `code-quality.md` names the linters and formatters a `self-hygiene`
gate would run; `architecture.md`'s module boundaries are where `scope` globs come
from; `review-strategy.md` says which review dimensions this repo actually warrants,
which is the fanout shape of your judge steps. A spec's gaps section is equally
load-bearing: "no CI exists" deletes a workflow you would otherwise have kept.

Treat the specs as a map, not as testimony. They point at the file; §3 still demands
you cite the file. A spec that claims a `make check` target is a reason to open the
`Makefile`, never a substitute for it.

Build files (`Makefile`, `justfile`, `package.json`, `Cargo.toml`, `*.nix`) and
CI config give you the real check command — the one a contributor actually
runs, and the ones that gate merges today. `README`/`CONTRIBUTING` give the
review shape: who approves, how many. `git log --format='%s' -50` gives
conventions and cadence. The test/doc layout tells you what a change touches,
for `scope` and `class`.

The gate/script miner runs each check command once — for real. A command
nobody has seen exit 0 is a guess, not a gate. When one does not exit 0, the
miner attributes before you conclude:
check the failure text for environment signatures first — a sandboxed session
blocking the network reads as a gate failure and is not one (`vuln-scan` fails
closed when `vuln.go.dev` is unreachable, with a message that blames
vulnerabilities); rerun unsandboxed before deciding anything. And a gate that
fails honestly on today's tree is doing its job — that is a finding to surface,
never a reason to drop the gate. A gate that needs the network gets that fact
argued explicitly in its §4 `--flaky` row either way.

## 3. Adapt

Adaptation is WRITE work, and write work is an agent's: spawn one
`executor-write` agent carrying the miners' summaries and this section's
rules verbatim; it rewrites the config and authors PROVENANCE.md, and you
review its diff against the citations before surfacing anything in §5. (On
the 2026-08-06 run the orchestrator authored PROVENANCE.md itself — the last
run where that is acceptable.)

The agent rewrites the template into `.docket/config/`:

- `workflows/<name>.toml` — named for the repo's work, `version = 1`, steps
  reflecting the real review shape.
- `schemas/<name>@1.json` — only if a threshold consumes a step's `payload`.
  **A payload schema describes an array**: `type: "array"` with the object
  under `items`. An object-shaped schema registers, then fails workflow
  validation with "declares no top-level properties." Ordered fields need
  `"ordered_enum": true` or `>=` is refused.
- `policy.toml`, `contracts/`, `fragments/` — pinned, registered as nothing. Instance knowledge lives here, including the fenced-check
  convention: a gate declaring `source = "fence:checks"` harvests ` ```checks `
  blocks from the issue body, one command per line, at activation only.

Head each generated TOML with a comment naming what you mined and the date —
that is what makes the next retro's diff legible. JSON carries no comment
syntax, so schemas stay byte-clean and their reasoning goes in
`.docket/config/PROVENANCE.md` instead: one config-wide record holding where
the copy came from, the keep-or-cut rationale per directory, the
gate-verification results, and a `THIN SPOTS` section for every gap found and
deliberately not fixed. Activation pins it by content hash like any other
config file and registers nothing. Headers and PROVENANCE.md together are the
only record of why a file survived §2's citation test; nothing regenerates
them, which is why §1 refuses to overwrite a populated config.

**Adapting the corpus, if you started from it.** The shipped workflows and
contracts encode *this project's* conventions — its build commands, its review
shape, its scopes. A target repo differs, and transcribing someone else's
conventions is worse than starting from the template, because the result looks
authoritative while being wrong. Every file you keep must survive a citation
from §2: name the build file, the CI job, or the CONTRIBUTING line that says
this repo works that way. Delete what you cannot cite. A pipeline whose review
shape the repo does not practice is a pipeline that will be routed around.

Two coupled invariants to keep intact while you cut:

- **Every executor hint needs exactly one `[executors]` row, and every row needs
  a hint.** Deleting a workflow usually orphans rows; deleting a row usually
  strands a hint. The wave refuses to route on either, loudly and by design.
- **`fanout` members are the sibling's identity.** Distinct names (the seven
  `spec-author-<axis>` hints) tell each sibling which artifact it owns; repeated
  names (`["research","research"]`) mean the siblings are interchangeable. Keep
  whichever the work actually is; do not "tidy" seven names into one.

## 4. Propose trust — do not add it

For each command a gate will run, propose the entry and argue every flag from
what you read:

```
name         checks
argv         make check
re-runnable  yes — the scripts only read docs/ and print; safe after a crash
tree         no  — writes nothing in the working tree
flaky        no  — no network, no clock; deterministic exit code
```

Default every flag **off** and justify turning it on. `--tree` wrong lets a
build race a parallel read step. `--re-runnable` wrong parks an interrupted
gate on a human. `--flaky` on a deterministic command hides a real failure
behind a retry. Never propose `--global`; propose `--prefix` only when the argv
genuinely varies, and say plainly that it over-authorizes.

**A repo-internal script needs an ABSOLUTE argv[0].** Containment refuses any
argv[0] that resolves at or under the repo root — a repo-owned script is content
an executor can rewrite between approval and execution. The one exception: a
trust entry whose own argv[0] is already absolute, which is read as the operator
authorizing that exact in-repo path deliberately. So every entry pointing at
`scripts/qa/*` (or anything else in the tree) is proposed as
`$(git rev-parse --show-toplevel)/scripts/qa/tests.sh`, never
`./scripts/qa/tests.sh`. A relative one registers happily and then refuses at
run time — the failure RUN-3 shipped. Say in §5 that these entries are
absolute-path-bound: a moved or re-cloned worktree needs them re-added.

**Name every entry after what the script actually does — never after the gate you
wish you had.** A trust entry's name is what the operator reads when approving
and what every later report calls it, so a name that overstates the check buys a
false sense of coverage that nothing will correct. If a repo has a
`genericity.sh`, propose it as `genericity`; do not propose it as `scope` because
a scope gate is what the pipeline wants. RUN-3 proposed `genericity.sh` under the
name `scope`, and what happened next is worth knowing precisely, because the
usual telling gets it backwards: the script never ran. Containment refused its
relative argv three times, and each refusal was recorded in `gate_results` as
`scope unmatched (null)` with the reason and the remedy spelled out in full.
Nobody read the verdicts, and three changes landed with a gate that had reported
its own refusal each time. **Read the verdicts** — after a real run,
`gate_results` is the only place that says whether a gate you proposed actually
executed, and `unmatched` there means nothing ran. If the honest name and the
pipeline's expected gate name differ, that is information — surface the gap, do
not paper it with a name.

**Say plainly when a gate is unavailable.** There is **no scope-containment
gate**, and there cannot be one: a gate process receives no issue identity, so
no script can learn which globs to check — the gap is action-shaped, not
gate-shaped (DKT-84), and the shipped workflows no longer declare `scope`
anywhere. Do not propose one under any name, and do not let `genericity.sh` or
any other script stand in for it. When you present the binding in §5, state
absences outright — a gate the operator cannot see missing is coverage they
will assume they have. An unavailable gate named honestly is a known gap; an
unavailable gate named `scope` is a lie the run will act on.

### 4a. Propose the `doc-record` trust entry

If you kept `spec-doc.toml`, its `record` step is an **action**, not an
executor: recording an accepted doc is "insert a row and copy bytes", which the
engine runs itself and never claims. An action named `doc-record` resolves
through the trust store like any gate command, so it needs an entry:

The corpus ships the action *name*, not the script — an `executor-write`
agent writes `.docket/bin/doc-record` (you hand it this section and §4a's
context-bundle facts as its brief; you review and propose, you do not
author), and its argv is proposed absolute per the argv[0] rule above:

```
name         doc-record
argv         $(git rev-parse --show-toplevel)/.docket/bin/doc-record
re-runnable  yes — `docket doc create` is idempotent on a doc that already
             exists for this issue; a crash between create and link re-runs clean
tree         no  — writes into the docket database and docs/, not the build tree,
             so it races nothing a parallel read step is reading
flaky        no  — no network, no clock; it either records or exits non-zero
```

`--re-runnable` is the one flag genuinely arguable here: turn it **off** if your
script appends rather than upserts, because then a retry duplicates a DOC-N.
Read the script before arguing the flag.

An action's contract is not a gate's, and the difference is what makes the
script writable at all: the engine hands an action the run context as ONE JSON
document on stdin — `{step, issue: {id, labels, …}, inputs: [{artifact, kind,
body, …}], …}` — so unlike a gate it can know *what* to record. It must print
exactly one JSON document back, `{"body": <string>, "payload": <array>}`; the
reply parser rejects unknown fields and trailing bytes, so every diagnostic
goes to stderr — one stray echo on stdout fails the step. The env is an
allowlist (no `DOCKET_PATH`; cwd is the repo root, so `docket` finds the DB by
ordinary discovery). Read the engine's action-exec source or the engine spec's
context-bundle section rather than trusting this paragraph — the shape is the
engine's to evolve.

The same agent proves the script before you propose its entry: `chmod +x` it
(file-writing tools do not set the execute bit, and the engine execs argv[0]
directly), feed it a synthetic context bundle on stdin, and check it exits 0
printing one parseable reply — on the 2026-08-06 run this caught a wrong
stdin-flag spelling a read-through had missed, and a same-day probe harness
caught two more real bugs (a missed `{ok,data}` envelope and a replay echoing
its input instead of the stored record). Feed it the same bundle twice: the
second run replaying the same DOC-N instead of minting another is the
measured basis for `--re-runnable`, which beats arguing it from prose. The
agent returns the script plus both probe transcripts; that evidence is what
you attach to the proposal.

### 4a′. Propose the `commit-exec` trust entry

If you kept a workflow whose terminal step is `commit` (standard-change,
ui-change, security-load-bearing), know what its author does NOT do: the
`commit-author` contract composes the message only — "execution is gated and
happens without you" — and the execution half is the `commit-exec` ACTION
step those workflows declare after it. RUN-1 (2026-08-06) shipped without
this script and completed with an approved message and a dirty tree; the
conductor had to hand-commit under the approved gate. Do not repeat that.

Same pattern and same delegation as `doc-record`: an `executor-write` agent
writes `.docket/bin/commit-exec` — context bundle on stdin carries the
`commit-message` artifact and the issue (id, scope globs); the script stages
ONLY paths matching the issue's scope globs, commits with the artifact text
verbatim (`git commit -F -`), prints one JSON reply carrying the new HEAD
sha, and exits non-zero on an empty staging set or any path outside scope.
Prove it twice in a scratch repo: the second run against a HEAD whose message
already matches must be a detected no-op, which is the measured basis for:

```
name         commit-exec
argv         $(git rev-parse --show-toplevel)/.docket/bin/commit-exec
re-runnable  yes — measured: a re-run with the message already at HEAD is a
             detected no-op, not a duplicate commit
tree         yes — it writes the git index and object store; say so plainly
             and argue it: it runs strictly AFTER the pipeline's read steps
             and inside the engine's single-writer discipline
flaky        no  — no network, no clock
```

### 4b. Propose the vote-rule thresholds

Vote rules live in **engine config**, not `.docket/config/`, so activation never
auto-registers them — and a pipeline naming an unregistered rule **fails to
register at all**:

```
✘ Error: step "security-vote": `vote_rule` "security-acceptance" is not registered
```

Two of the nine pipelines need one each:

```bash
docket config set vote.rule.security-acceptance.threshold 0.67
docket config set vote.rule.doc-acceptance.threshold 0.60
```

`0.67` is two-thirds: a security acceptance needs a clear majority, and with a
three-judge panel it means two must agree. `0.60` is a simple majority with a
margin — a doc is accepted when most reviewers say yes, and the lower bar
reflects that a doc's cost of being wrong is a revision, not an incident. Both
are provisional; the first retro with five runs of vote data should revisit them.

These are **config writes, not trust entries** — they authorize no execution, so
no `--yes` handshake applies. Surface them for approval anyway: a threshold is
policy the operator owns.

### 4c. Propose write-class lease TTLs

A heartbeat verb exists (`docket step heartbeat`, token-gated) but **no
executor calls it**, so in practice liveness is TTL-only and the lease TTL is
the entire mechanism keeping a working executor's claim alive:

```bash
docket config get lease.ttl.default          # ships as 15m
docket config set lease.ttl.write 45m        # propose BOTH classes, not one:
docket config set lease.ttl.read  30m        #   RUN-1 sized only write; its
                                             #   slowest silver judge then ran
                                             #   13m of the 15m read default
                                             #   on a three-file diff
```

**Size it against worst-case step duration, not the typical one.** A TTL shorter
than the longest write step means the lease expires *while the executor is still
working*: the step is reaped, another claimant can take it, and the original
returns to `complete` a step it no longer holds — the ack loop. Under a
heartbeat, a slow step renewed itself and the TTL only had to exceed the
heartbeat interval. Without one, the TTL alone has to cover the whole step.

Argue the number from the corpus's own cost declarations — and from the one
real datum a virgin repo has by the time you get here: the §0 spec authors'
wall-clock. Seven write-class agents over this repo are a measured sample of
what heavy agent work costs on this codebase; cite YOUR measurement, not a
recorded one — observed runs vary widely (~6 minutes per author on one run,
9–17+ minutes the next day under 7-way concurrency, same repo, same
contracts). Beyond that, `expected_cost`
is the proxy you have: in the shipped corpus `implement` carries the highest at
`1.50`, against `0.10` for the cheapest read steps. If your slowest write step has
historically taken ~30 minutes, a 45m write-class TTL leaves 50% headroom —
which is the right direction to be wrong in, because the two errors are not
symmetric:

- **TTL too short** → mid-work reaps, duplicated work, ack loops. Corrupts the
  run's accounting and wastes the spend already made.
- **TTL too long** → a genuinely dead executor's step sits claimed until the TTL
  expires. Costs latency on a failure path — and NOTHING else bounds it: this
  engine has no `max_step_duration` or per-step duration key at all (probed on
  RUN-1; `dispatch.ttl`/`dispatch.grace` bound the dispatch, not a step). The
  TTL is the failure path's only clock, which sharpens rather than weakens the
  rule: size it long, and say plainly the number is provisional.

Propose the long side, and say plainly that the number is provisional until real
step durations exist to size it against. This is the first thing a retro should
re-derive from evidence.

## 5. Surface the binding — the approval moment

A virgin repo has no issue yet, and this skill does not say where DKT-1 comes
from unless you make it say: take the issue the operator named; if none was
named, propose ONE drawn from the specs' gap sections and offer the swap
explicitly — never activate work the operator has not seen named. (RUN-1's
conductor improvised exactly this, well; now it is the contract.) One smoke
issue is this skill's ceiling: anything larger is `/plan`'s to structure
BEFORE conducting — plan-up-front is the default, single-issue improvisation
the exception.

```bash
docket run start --issue DKT-1
docket run activate RUN-1 --dry-run --pin .docket/config/policy.toml
```

`--dry-run` computes the whole activation and writes nothing. Two blocks can
come back:

- **The registration report** — every workflow and schema this activation
  would adopt, as `name@version  path  (outcome)`, plus the count of further
  config files pinned by content hash. This proves the config is well-formed
  and accepted; it says nothing about what will execute.
- **The harvested-command list**, annotated `matched`/`unmatched` — printed
  only when a kept workflow declares `source = "fence:checks"` AND the bound
  issue carries a ` ```checks ` fence. No shipped corpus workflow declares
  one, so on a corpus-derived config this block is absent, not empty. Its
  absence is correct, not a failure to debug.

Show what printed verbatim, not a summary. Then supply what the dry run
cannot: **named gates are invisible to it.** A `gates = ["build", ...]` entry
resolves through the trust store at execution, not activation, so a gate with
no trust entry looks identical here to a satisfied one. Compose the gate table
yourself and put it beside the dry-run output:

```
gate       trust entry  argv                             status
build      build        /abs/repo/scripts/qa/build.sh    proposed (absolute — ok)
tests      tests        /abs/repo/scripts/qa/tests.sh    proposed (absolute — ok)
<absent>   —            —                                NO GATE — say why
```

Every gate named by a workflow you kept gets a row; a check you could not
implement gets a row with no argv and the reason. A row with no trust entry
will report `unmatched` on its first real run — say it in the row, not a
footnote. This table, the registration report, and §4's flag arguments are
what the operator approves, together. On yes, run the `trust add --yes`
commands, re-run the dry-run to confirm it still registers clean (a fenced
setup must now read `(matched: <name>)`; named gates resolve in the trust
store, not here), then ask again, for the activation itself, and run it
without `--dry-run`. Two approvals: one for what you wrote, one for what runs.
Every approval, here and everywhere this skill asks, goes through the built-in
question tool with your recommended option first, labelled "(Recommended)".

Two facts about the store that surface exactly here, at the moment of adding:

- **The store is user-global** — `~/.config/docket/trust.toml`, outside every
  repo — so a sandboxed session's first `trust add` fails on its lock file
  with `operation not permitted`. That is the sandbox, not docket. Retry the
  adds unsandboxed; this is the legitimate moment for it, because the operator
  just approved these exact entries. (`config set` is unaffected — engine
  config lives in the repo's DB.)
- **The store survives un-bootstraps and earlier sessions**, so proposed names
  may already exist. `trust add` is a silent no-op on a byte-identical entry
  and *refuses* when anything differs — and its conflict error prints the argv
  (identical) without naming the field that differs, which is usually a flag.
  On a conflict: `trust list`, diff the surviving flags against what was just
  approved, and put the difference in front of the operator as its own
  question. Do not `trust rm` and re-add to make the store match your
  proposal: the existing flags were once approved by the same authority you
  just asked, and two approvals that disagree are the operator's to
  reconcile, not yours.

After the first real run, read the gate verdicts: `unmatched` in
`gate_results` means the gate never executed — its entry is missing or
containment refused its argv. The verdict text names the fix; follow it
literally.

## 6. Where the corpus comes from

`.docket/config/` lives **in the target repo**, git-versioned, and activation
content-hash pins it from there. The reference copy at `~/.claude/docket-config/`
is a *source to copy from*, never a place activation looks.

So: **copy bytes in, do not link to them.** A symlink from `.docket/config/` back
to the reference copy breaks the pin's provenance story and makes one repo's
edit mutate every repo. Copy, adapt per §3, commit the result — the repo owns
its config from that moment, and retro evolves it in place.

There is no network step anywhere in this flow. If `~/.claude/docket-config/` is
missing, fall back to `workflow init --template` and say that you did; do not
fetch.

## 7. Hand off

Report the config files you wrote, the trust entries they approved, and the run
you activated. Name the next move plainly: real work beyond the smoke issue
goes through `/plan` (issues, phases, gates placed deliberately), then
`/conduct` drives what plan recorded — do not slide from bootstrapping into
driving on your own momentum, or on a stop-guard's push. `.docket/config/` is git-versioned and machine-authored: changes
go through a version bump, because changed bytes at an unchanged `name@version`
refuse the next activation outright.

Activation's refusals name the file and the fix; follow them literally. Two
worth pre-empting: an issue matching zero workflows is a `[match]` too narrow —
widen it, never label the issue to fit — and an issue matching several is
resolved with `unless_labels` on the loser, which evaluates last and wins.
