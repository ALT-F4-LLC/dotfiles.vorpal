---
name: bootstrap
description: Wire a repo into the shared docket corpus for the first time — seed the seven project specs, link ~/.docket's corpus into .docket/config/ (real dirs, file-level symlinks), mine the repo, set the repo-specific layer (project prefix, engine config, trust proposals), and surface the whole binding for approval before the first run. Use at project start, or when `docket run activate` reports no workflow matches an issue. Also the way to bootstrap docs/spec/ on a repo with no engine running yet ("create specs", "generate project specs").
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

**The contract is the authority.** Read `~/.docket/contracts/spec-author.md`
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
*before* §1 linked the config in, so a spec's true-when-written claim that
`.docket/config/` is absent is false by activation. Do not hot-edit a spec to
fix that — especially not while a write-class step holds the tree — note it in
the hand-off and let the `spec-project` review pass catch it; that is the
mechanism built for exactly this.

## 1. Link the shared corpus in

**Every docket verb needs an unsandboxed shell.** The store is user-global at
`~/.docket`, outside the sandbox write root, and every DB-touching command opens
it read-write and migrates forward before doing anything else — sandboxed it
fails with `unable to open database file (14)`. Only `--help` is safe sandboxed.

```bash
docket init          # only if no store exists yet. Bare init targets the SHARED
                     # ~/.docket store; --local makes a repo-local .docket/issues.db

# Bootstrap is for a repo with NO config. Refuse rather than re-link over one.
if [ -n "$(ls -A .docket/config 2>/dev/null)" ]; then
  echo "config exists — evolving it is retro's job, not bootstrap's"; exit 1
fi

# REAL dirs, LINKED files, corpus entries BY NAME (issues.db lives there too).
# -L: the five entries are themselves symlinks into the store. ln -sfn re-runs.
mkdir -p .docket/config
(cd "$HOME/.docket" && find -L contracts fragments schemas workflows -type d) |
  while read -r d; do mkdir -p ".docket/config/$d"; done
(cd "$HOME/.docket" && find -L contracts fragments schemas workflows -type f) |
  while read -r f; do ln -sfn "$HOME/.docket/$f" ".docket/config/$f"; done
ln -sfn "$HOME/.docket/policy.toml" .docket/config/policy.toml

find -L .docket/config -type l   # broken links — must print nothing
grep -qxF '.docket/*' .gitignore 2>/dev/null ||   # the view is machine-local;
  printf '.docket/*\n!.docket/bin/\n' >> .gitignore   # .docket/bin stays tracked

# The corpus does not activate without these two. Set them now; §4b argues the
# numbers and is where the operator approves or changes them.
docket config set vote.rule.security-acceptance.threshold 0.67
docket config set vote.rule.doc-acceptance.threshold 0.60
```

**Real dirs, linked files** — the shape is not stylistic, and §6 holds the
mechanism behind it. The
`.gitignore` line ignores `.docket/*` rather than `.docket/` deliberately, so
`.docket/bin/` — the §4a and §4a′ scripts, real repo content a trust entry binds
to by absolute path — stays versioned while the machine-local view does not. A
fresh clone re-runs the link block; nothing else.

The rows and the config are different places now. **`.docket/config/` is
repo-side instance config**: it sits at the exec root and activation pins what it
finds there, whether the rows live in the shared store or a local one — a normal
arrangement, not a misconfiguration. Every `config set` in this skill takes the
project scope; `--global` re-policies every project sharing the store.

**Claim a prefix, operator-gated like everything else.** Ids are one rowid
sequence across the whole store; only the display prefix tells projects apart,
and two on this machine already render as `DKT`.

```bash
docket project list                    # what is taken
docket project set-prefix VOR          # 1-8 letters; DOC/RUN/STEP reserved
```

Display only — `DKT-42` and `VOR-42` are the same issue, and `DKT-` or a bare
number always parses — so it costs nothing and buys legible reports.

**If the guard fires, stop.** Re-running the link block is harmless — `ln -sfn`
replaces a link with itself, real files beside the links are untouched (measured).
The rest of this skill is not: it sizes engine config, proposes trust entries, and
activates a first run as if none of that had been decided. A populated
`.docket/config/` means it was, and evolving it is retro's job — tell the operator
and suggest `/retro`.

**Why those two lines are here and not later.** Activation validates EVERY
registered workflow, not just the one an issue binds, and two of the nine name a
`vote_rule`. Until both rules exist, `run activate` refuses outright — on a
virgin project, for an unlabelled issue that never touches a vote gate. Setting
them at link time means the first activation an operator sees is a real one.
They authorize no execution, so they are safe to set before approval; what needs
approval is the NUMBER, which §4b puts in front of the operator.

`~/.docket/` holds the shipped corpus — `workflows/`, `contracts/`, `fragments/`,
`schemas/`, `policy.toml` — alongside `issues.db`, which is why the loop names the
five entries and never globs the directory. List it for the inventory; counts
written here go stale. The Vorpal builder installs it from `src/user/docket/` (§6).

**Every repo links the whole corpus** — you do not pick a subset and you do not
adapt it; it is generic on purpose, and one repo's opinion of it would become
every repo's. What a repo adds for itself is a REAL file beside the links, which
is §3's business.

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

Mining no longer decides what to keep — the corpus is linked whole. It sizes §3's
repo-specific layer: which globs bound a scope, which commands a fence carries,
which gates earn a trust entry, how long a step really takes. Every one of those
cites something a miner found:

**Start with `docs/spec/`** — §0 wrote it, or it was already there, and it is the
densest source you have. `testing.md` tells you whether a `tests` gate has anything
to gate; `operations.md` names the CI jobs that gate merges today; `code-quality.md`
names the linters a `self-hygiene` gate would run; `architecture.md`'s module
boundaries are where `scope` globs come from; `review-strategy.md` says which
review dimensions this repo warrants, which is how you know whether a shared
workflow's fanout fits or a repo-local one is owed. A spec's gaps section is
equally load-bearing: "no CI exists" is a gate you propose as absent (§5) rather
than one you invent an entry for.

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

## 3. Adapt — the repo-specific layer

The corpus is shared, generic, and already in place. What remains is what the
corpus cannot know, and all of it is this repo's: the **scopes** that bound an
issue (`architecture.md`'s module boundaries, the real test/doc layout); the
**fences** a gate harvests from an issue body (`source = "fence:<tag>"` takes
` ```<tag> ` blocks, one command per line, at activation only — any tag a bound
workflow declares, `checks` being a convention rather than the only one);
**engine config** at project scope (§4b, §4c); **trust entries** and their
scripts (§4); and **repo-local workflow or schema files** when the shared corpus
has no shape for this repo's work.

That last one is WRITE work, and write work is an agent's: spawn one
`executor-write` agent carrying the miners' summaries and this section's rules
verbatim, and review its diff against the citations before surfacing anything in
§5. It writes REAL files beside the links, never over them:

- `workflows/<name>.toml` — named for the repo's work, `version = 1`, steps
  reflecting the real review shape; seed it with `docket workflow init --template
  standard-dev` (check-then-approve, one fenced gate) or `--template
  parallel-check` (prepare → parallel checks → summarize → verify) when either is
  closer than a blank file. Its registered `name@version` comes from the
  `[pipeline]` body, the filename being provenance only. Two step keys are easy
  to miss: **`holds_tree` defaults to TRUE**, so a read-only judge step omitting
  `holds_tree = false` serializes against the tree for nothing; and `packet` (a
  list of config-relative paths, `{executor}` substitutable, `packet_includes`
  in frontmatter, include depth exactly one) carries fragments to a claimant.
  **Do not declare `packet` on a step an isolated executor will claim.** The
  engine resolves packet includes against the CLAIMER's checkout, worktrees do
  not carry the gitignored link farm, and the claim then fails with `packet
  file "…" is pinned by this run but is no longer on disk` — AFTER recording
  the claim, stranding a tokenless claimed step until a reap (measured). Until
  the engine serves packets from pinned bytes, packet steps claim only from
  the shared checkout.
- `schemas/<name>@1.json` — only if a threshold consumes a step's `payload`, and
  the corpus already ships the common ones. **The filename IS the identity**
  (`findings@1.json` → `findings@1`); **a payload schema describes an array**,
  `type: "array"` with the object under `items`, an object-shaped one registering
  and then failing validation with "declares no top-level properties"; ordered
  fields need `"ordered_enum": true` or `>=` is refused.
- `policy.toml`, `contracts/`, `fragments/` — links, every one: pinned by content
  hash, registered as nothing, shared by every repo. Read them freely; write
  nothing there.

Head each generated TOML with a comment naming what you mined and the date —
that is what makes the next retro's diff legible; schemas carry no comment
syntax, so their reasoning goes in the header of the workflow consuming them.
**Do not author a `PROVENANCE.md`.** No copy exists whose origin needs recording:
the corpus's provenance is `src/user/docket/`'s git history.

**A shared file is not yours to change here.** Nothing you write may land on a
link: the store is read-only, so an in-place write is refused outright, and a
tool that edits by REPLACING leaves a real file where the link was — diverged,
and invisible to `find -L` because a real file is not a broken link (§6's second
check is what catches it). A shared file wrong for everyone is a change proposed
against `src/user/docket/` for the operator to install — retro's discipline, not
a local edit. Wrong for this repo only is a repo-local file standing beside the
link. And a pipeline whose review shape this repo does not practice will be
routed around: a finding for §5, not a silent local edit.

Two coupled invariants any repo-local file must keep:

- **Every executor hint needs exactly one `[executors]` row, and every row needs
  a hint.** A new workflow strands a hint the moment its row is missing, and the
  shared `policy.toml` is a link you cannot add the row to — so a repo-local
  workflow reusing a shared hint is the safe shape, and inventing a hint means
  proposing the row upstream. The wave refuses to route on either gap, loudly
  and by design.
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
behind a retry. **Never propose `--global`**: an entry binds to the repository it
was approved in unless `--global` is given, which authorizes the argv in every
repo on the machine. Propose `--prefix` only when the argv genuinely varies, and
say plainly that it over-authorizes.

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

**A scope-containment gate is writable now.** A gate child receives
`DOCKET_GATE`, `DOCKET_REPO`, `DOCKET_ISSUE`, `DOCKET_SCOPE` (the issue's globs,
newline-joined, absent when it declares none) and `DOCKET_GATE_NETWORK` when the
gate declared hosts, so a script can learn which issue it is checking and which
globs bound it; `DOCKET_TOKEN` and `DOCKET_PATH` are denied to children and
asserted absent. No shipped corpus workflow declares `scope`, so proposing one
means adding it to a workflow as well as to the trust store.

**Say plainly when a gate is unavailable anyway.** A check you could not
implement is named as absent in §5, never covered by a neighbour: do not let
`genericity.sh` or any other script stand in for a gate it does not perform. A
gate the operator cannot see missing is coverage they will assume they have. An
unavailable gate named honestly is a known gap; an unavailable gate named
`scope` is a lie the run will act on.

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
re-runnable  yes — the script passes `--idempotency-key` (doc create, issue
             create, and both comment-add verbs take one), so a crash between
             create and link re-runs to the same DOC-N instead of a second
tree         no  — writes into the docket database and docs/, not the build tree,
             so it races nothing a parallel read step is reading
flaky        no  — no network, no clock; it either records or exits non-zero
```

`--re-runnable` is the one flag genuinely arguable here, and the key is what
makes the yes defensible: turn it **off** if your script appends without one,
because then a retry duplicates a DOC-N. Read the script before arguing the flag.

An action's contract is not a gate's, and the difference is what makes the
script writable at all: the engine hands an action the run context as ONE JSON
document on stdin — `{step, issue: {id, labels, …}, inputs: [{artifact, kind,
body, …}], …}` — so unlike a gate it can know *what* to record. It must print
exactly one JSON document back, `{"body": <string>, "payload": <array>}`; the
reply parser rejects unknown fields and trailing bytes, so every diagnostic
goes to stderr — one stray echo on stdout fails the step. The env is an
allowlist and `DOCKET_PATH` is denied outright; cwd is the repo root, so `docket`
resolves the store the ordinary way — `$DOCKET_PATH` (absent here), then a
repo-local `.docket/issues.db` found by walking up to the worktree toplevel, then
the global `~/.docket`. Read the engine's action-exec source or the engine spec's
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
✘ Error: step "security-vote": `vote_rule` "security-acceptance" is not registered; none are registered. Register one with `docket config set vote.rule.security-acceptance.threshold <0-1>`
```

Two of the nine pipelines need one each:

```bash
docket config set vote.rule.security-acceptance.threshold 0.67   # project scope:
docket config set vote.rule.doc-acceptance.threshold 0.60        # no --global
```

A rule exists exactly when its threshold is set, so these two writes are what
bring the rules into being — unqualified, for this project only. `0.67` is
two-thirds: a security acceptance needs a clear majority, and with a
three-judge panel it means two must agree. `0.60` is a simple majority with a
margin — a doc is accepted when most reviewers say yes, and the lower bar
reflects that a doc's cost of being wrong is a revision, not an incident. Both
are provisional; the first retro with five runs of vote data should revisit them.

These are **config writes, not trust entries** — they authorize no execution, so
no `--yes` handshake applies. Surface them for approval anyway: a threshold is
policy the operator owns.

### 4c. Propose write-class lease TTLs

Liveness has three parts, and the TTL is only the first. The lease TTL bounds a
claim. `docket step heartbeat` (token-gated) extends one — but **not past the
class's `max_step_duration`, measured from the claim**, so a runaway holder
cannot renew forever. And `docket step reap STEP-N --reason R` is a token-free
channel for a spawn already known dead, which belongs to whoever spawned it, not
to a clock. Size the TTL for the working case; the other two cover the failures.

```bash
docket config get lease.ttl.default          # ships as 15m
docket config set lease.ttl.write 45m        # project scope, no --global.
docket config set lease.ttl.read  30m        # Propose BOTH classes: RUN-1 sized
                                             #   only write, and its slowest
                                             #   silver judge then ran 13m of the
                                             #   15m read default on 3 files
```

**Size it against worst-case step duration, not the typical one.** A TTL shorter
than the longest write step means the lease expires *while the executor is still
working*: the step is reaped, another claimant can take it, and the original
returns to record a step it no longer holds — the ack loop. A heartbeating
executor renews itself and only has to beat its own interval; nothing in this
instance heartbeats yet, so assume the TTL alone covers the whole step.

Argue the number from the corpus's own cost declarations — and from the one real
datum a virgin repo has by the time you get here: the §0 spec authors'
wall-clock. Seven write-class agents over this repo are a measured sample of
what heavy agent work costs on this codebase; cite YOUR measurement, not a
recorded one — observed runs vary widely (~6 minutes per author on one run,
9–17+ minutes the next day under 7-way concurrency, same repo, same contracts).
Beyond that, `expected_cost` is the proxy you have: in the shipped corpus
`implement` carries the highest at `1.50`, against `0.20` at the cheap end
(spec-doc's `record`) — a 7x spread, and nothing declares less. Read the numbers
off the config you kept rather than quoting these; they move when you cut a
workflow. If your slowest write step has historically taken ~30 minutes, a 45m
write-class TTL leaves 50% headroom — the right direction to be wrong in,
because the two errors are not symmetric:

- **TTL too short** → mid-work reaps, duplicated work, ack loops. Corrupts the
  run's accounting and wastes the spend already made.
- **TTL too long** → a genuinely dead executor's step sits claimed until the TTL
  expires. That used to be unbounded and no longer is: `step reap` closes it the
  moment the relay knows, and a workflow's `[limits]` class table can cap it
  outright — `read = { max = 4, lease_ttl = "45m", max_step_duration = "2h" }`,
  a ceiling no heartbeat crosses. (`dispatch.ttl`/`dispatch.grace` still bound
  the dispatch, not the step.)

So err long. The expensive error is still the short one, and the cheap error is
cheaper than it was. Say plainly that the number is provisional until real step
durations exist to size it against — the first thing a retro should re-derive
from evidence.

## 5. Surface the binding — the approval moment

A virgin repo has no issue yet, and this skill does not say where DKT-1 comes
from unless you make it say: take the issue the operator named; if none was
named, propose ONE drawn from the specs' gap sections and offer the swap
explicitly — never activate work the operator has not seen named. (RUN-1's
conductor improvised exactly this, well; now it is the contract.) One smoke
issue is this skill's ceiling: anything larger is `/plan`'s to structure
BEFORE conducting — plan-up-front is the default, single-issue improvisation
the exception.

**Lint what you wrote before starting anything.** `docket workflow lint FILE`
runs the exact validation `workflow register` runs — grammar, step rules, vote
rules, schema cross-checks — and writes nothing:

```bash
for f in .docket/config/workflows/*.toml; do docket workflow lint "$f"; done
```

Each verdict is `new`, `unchanged` (identical bytes already registered), or
CONFLICT — changed bytes at a frozen `name@version`, which fails the lint and
would refuse the whole activation. Clear every one first: a lint failure is a
five-second loop, the same failure at activation is a refusal the operator sits
through. A CONFLICT on a LINKED workflow is not yours to clear — the shared corpus
moved without a bump and is refusing every repo that links it; the fix is in
`src/user/docket/` (§6), so say that rather than editing around it.

```bash
docket run start --issue DKT-1
docket run activate RUN-1 --dry-run
```

`--dry-run` computes the whole activation and writes nothing. It needs no
`--pin` for anything already under `.docket/config/`: the scan pins every file
there recursively, with refs relative to the config directory so they survive a
re-clone. An explicit `--pin .docket/config/policy.toml` only adds a second row
for the same bytes under a checkout-bound path. Two blocks can come back:

- **The registration report** — every workflow and schema this activation
  would adopt, as `name@version  path  (outcome)`, plus the count of further
  config files pinned by content hash. This proves the config is well-formed
  and accepted; it says nothing about what will execute.
- **The harvested-command list**, annotated `matched`/`unmatched` — printed
  only when a kept workflow declares `source = "fence:<tag>"` AND the bound
  issue carries a fence with that exact tag. No shipped corpus workflow declares
  one, so on a corpus-derived config this block is absent, not empty. Its
  absence is correct, not a failure to debug.

Both blocks are printed prose in human mode only. Under `--json` they become
payload keys — `registered[]` (`{kind,name,version,path,sha256,outcome}`) and
`fences[]`, beside `bound_issues[]`, `promoted_issues[]`, `scope_warnings[]`,
`pins_recorded`, `steps_created` — and every stderr diagnostic is suppressed.
Read it in human mode when the point is showing the operator what printed.

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

- **The trust store is user-global** — `~/.config/docket/trust.toml`, mode 0600,
  outside every repo — so a sandboxed session's first `trust add` fails on its
  lock file with `operation not permitted`. That is the sandbox, not docket, and
  it is the same wall §1 hit: like every other verb here, the adds need an
  unsandboxed shell. This is a legitimate moment for one, because the operator
  just approved these exact entries. Each entry binds to this repository unless
  it was added `--global`.
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

`src/user/docket/` → (`just activate`) → `~/.docket/{contracts, fragments,
schemas, workflows, policy.toml}` → (§1's link step) → this repo's
`.docket/config/`. Two hops that go stale independently, and a link layer that
cannot: the bytes activation pins through a link ARE the bytes `~/.docket` holds.
**Link files in, never copy them** — one centrally maintained corpus is the whole
point, and a copy diverges the moment either side moves with nothing reporting it.

What the engine tolerates, measured both ways: linked FILES read through
byte-identically — same registered SHA256s, same pin count, relative pin refs,
packet resolution included — but the walker does not follow directory symlinks,
so a linked `.docket/config`, or a real config dir holding linked subdirectories,
fails with `reading the pinned config file …/config: is a directory`.

Drift is gone; two failure modes replace it. A **dangling file link** is a hard
`VALIDATION_ERROR` naming the file — the good one, loud and before anything runs.
A **dangling config root** is skipped SILENTLY and surfaces later as "matches no
registered workflow", which is why §1 builds a real root directory. Run both
checks before any activation: `find -L .docket/config -type l` prints the broken
links, `find .docket/config -type f` prints the real files, which should be only
§3's deliberate additions.

Staleness lives one hop up now — `~/.docket` sits behind `src/user/docket/` until
the operator runs `just activate` — so check that before concluding anything
about the corpus's contents. Because an install rewrites the bytes already-pinned
refs resolve to, corpus installs land BETWEEN runs, never during one; and because
every repo links the same bytes, an edit at an unchanged `name@version` refuses
the next activation in all of them. That is the cost of sharing, and why corpus
edits go through `src/user/docket/` with a bump.

There is no network step anywhere in this flow. If `~/.docket/` holds only
`issues.db` and no corpus, there is nothing to link — say so, and fall back to
`workflow init --template` for a repo-local workflow.

## 7. Hand off

Report the config files you wrote, the trust entries they approved, and the run
you activated. Name the next move plainly: real work beyond the smoke issue
goes through `/plan` (issues, phases, gates placed deliberately), then
`/conduct` drives what plan recorded — do not slide from bootstrapping into
driving on your own momentum, or on a stop-guard's push. Say plainly that
`.docket/config/` is a machine-local linked view rebuilt by §1's link block after
a fresh clone, and that shared bytes change only through `src/user/docket/` and a
version bump — the blast radius being every repo that links the corpus (§6).
Retiring a superseded version is `workflow deprecate` — a binding-time filter,
never a deletion, and retro's call rather than yours.

Activation's refusals name the file and the fix; follow them literally. Two
worth pre-empting: an issue matching zero workflows is a `[match]` too narrow —
widen it, never label the issue to fit — and an issue matching several is
resolved with `unless_labels` on the loser, which evaluates last and wins.
