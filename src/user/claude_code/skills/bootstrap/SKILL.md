---
name: bootstrap
description: Wire a repo into the shared docket corpus for the first time — seed the seven project specs, mine the repo, and register the repo itself (project prefix, engine config, trust proposals), then surface the whole binding for approval before the first run. The corpus is read straight from ~/.docket/config and nothing is materialized in the repo; no .docket directory is created. Use at project start, or when `docket run activate` reports no workflow matches an issue. The seven docs/spec/ files it writes are working input to its own mining and are deleted again before it hands off, so it is not the way to obtain lasting project specs ("create specs", "generate project specs") — that is the spec-project workflow.
---

# bootstrap

You bind this repo to the shared corpus. The developer provides work and
approvals; you do everything else. No corpus file lands in the repo at all: the
engine reads the corpus from `~/.docket/config`, and a `.docket/` directory
exists only when this repo genuinely owns something (§3, §4a′). The one thing
this skill writes into the tree is §0's seven specs under `docs/spec/`, and §5a
takes those back out again — they are scaffolding for the work below, not
output.

Three rules you must not fight:

- **Never run `workflow register` or `schema register`.** Activation
  auto-registers both config roots — `~/.docket/config` first, then this repo's
  `.docket/config/` if it has one — schemas before workflows. Registering by
  hand freezes a `name@version` before the human has seen it.
- **Never add a trust entry before the human approves it.** You propose; they
  say yes; then you run `trust add --yes`. The human, specifically: no panel of
  agents can approve a trust entry, and no trust entry is ever one item among
  several in a single question (§5).
- **A defect you surface files in its OWNING project** (operator ruling,
  2026-08-16: gaps belong to their respective projects). An engine gap —
  anything "owed upstream" below — is the docket repo's: `docket issue
  create` from THAT checkout, cwd picks the project, never an issue in the
  repo you are binding. A corpus or definition gap is the dotfiles repo's,
  same mechanics.

## 0. Seed the specs

§2 asks you to mine this repo and §3 refuses any file you cannot cite. The seven
engineering specs are what make those citations cheap and honest — a `testing.md`
that says "no tests exist" decides, on its own, whether you keep a workflow with a
`tests` gate. So they are an *input* to mining, and they are written first.

**They are working artifacts of this run, and that is the whole of their
contract.** This skill is their reader: §2's miners start from them, §3's scope
and gate decisions draw on them, and §5's proposed issue can come out of their
gap sections. Nothing downstream ever opens them again — not `/plan`, not
`/conduct`, not a retro, not a brief, not a gate — so §5a deletes them once the
last of those readers is done, and bootstrap leaves no spec file behind at all.
They are consumed, not maintained: nothing regenerates them, and nothing stale
is left in the tree to tell a later reader something that stopped being true.
The source tree is the source of truth, before and after. Specs meant to
persist are a deliberate act — someone choosing to run `spec-project` — never a
by-product of binding a repo.

Skip this section when `docs/spec/` already holds the seven; a skipped §0 leaves
§5a nothing to do, since it removes only what §0 wrote. Re-authoring them is
the `spec-project` pipeline's job, not yours.

**The contract is the authority.** Read `~/.docket/config/contracts/spec-author.md`
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
ONE message means one response carrying all seven Agent calls — one-spawn-per-
message staggers starts for nothing and was the 2026-08-10 deviation, twice.
`executor-write`/`executor-read` name the archetypes the settings builder
installs under `~/.claude/agents/`; that install is live, so use them. Fall back
only when `ls ~/.claude/agents` comes back missing or empty: spawn
`general-purpose` for writers and `Explore` for readers, carry the archetype
file's text (`src/user/claude_code/agents/` in the dotfiles repo) inline in the
brief, and say in §5 that archetype containment ran prompt-only. And every agent brief in this skill ends the same
way: **deliver your report by calling SendMessage to `team-lead` (ToolSearch
`select:SendMessage` first) BEFORE ending your turn** — a background agent's
final text is delivered to nobody, the idle ping that replaces it is
content-free, and on 2026-08-10 two of five agents finished silently exactly
this way, one stalling the run nine minutes.

**No engine is running yet, and that is the point.** There is no run to claim
against, no lease, no gate — which is exactly why this section exists rather than
deferring to `spec-project`. That pipeline needs a registered project (§1) and an
activated run (§5), so it cannot produce the specs §2 wants to read. Seeding here is
what breaks that circle.

While the seven run, wait properly: ONE `Monitor` call (ToolSearch
`select:Monitor` first) with an until-loop and a 15+ minute timeout, then stop
— completion notifications drive the next step and the Monitor is only the
fallback for when none arrives. Not `CronCreate`, which schedules recurring
work rather than waiting out this one. Polling the output directory and
rescheduling on every idle ping bought the 2026-08-10 run ~30 wakeup schedules
and ~10 polls that changed nothing.

**Verify before moving on — with an agent, not your own eyes.** Take
`git status --porcelain > "$TMPDIR/pre-fanout"` before you spawn. After all
seven return, spawn ONE `executor-read` agent to verify and report a
checklist: diff the snapshot against `git status --porcelain` now, confirm
every added line is a path under `docs/spec/` and that there are seven, and
check each file opens with a `# ` title, carries a `Status: … <date>` line,
and ends in its gaps section. Keep the paths it returns: §5a deletes exactly
those, so the record of what §0 wrote has to survive until then. You act on
the checklist — respawn a stalled axis, revert a stray — you do not perform
the reading. You are an orchestrator; the whole of this skill's hands-on work
belongs to agents. Anything else is a collateral write, and it happens: the
`executor-write` archetype grants a full write surface, so the contract's
prose is the only containment — and on the 2026-08-06 run prose did not hold:
an author left a non-compiling Go file in `internal/engine/`, breaking test
compilation for the whole package the run was about to gate. On a hit, revert
the stray (`rm` an untracked file, `git checkout --` a modified one) and tell
the operator what you reverted and which axis you suspect; if it might be the
operator's own work in progress, leave it and say so instead.

A missing or dateless file in the checklist means its author stalled —
respawn that one axis. Say plainly in §5 that these specs are seeded rather
than gate-validated: `doc-validate` and `reserved-name-check` run under
`spec-project`, not here, so their structural guarantees do not apply yet. If
the repo ships those gates itself, have the verification agent run them
against the seven directly; a real exit 0 beats a predicted one, and the
2026-08-06 run got both green this way. Diff a shipped gate's expectations
against the contract's Emit section only when running it is not possible.

One staleness trap these specs carry, and §5a is what bounds it: they describe
the tree as it stood *before* the rest of this run. §1 puts nothing in it —
registering a repo is config-store work — but §3 and §4a′ can each create a real
file (`.docket/config/`, `.docket/bin/commit-exec`), and a spec's
true-when-written claim that the repo has no `.docket/` is false the moment one
does. Do not hot-edit a spec to fix that — especially not while a write-class
step holds the tree — and do not chase it afterwards either. The drift lasts
exactly as long as the files do, which is until §5a removes them; a claim that
was true when written and false an hour later never gets the chance to mislead
anybody outside this run.

## 1. Register the repo

**Every verb that opens the SHARED store needs an unsandboxed shell.** That
store is user-global at `~/.docket`, outside the sandbox write root, and every
command touching its DB opens it read-write and migrates forward before doing
anything else — sandboxed it fails with `unable to open database file (14)`.
What stays safe sandboxed is anything that opens no DB at all (`--help`,
`workflow init`) and anything aimed by `DOCKET_PATH` at a store inside the
sandbox write root (§4a's scratch probe).

```bash
docket init          # only if no store exists yet. Bare init targets the SHARED
                     # ~/.docket store; --local makes a repo-local .docket/issues.db

# The corpus does not activate without these three. Set them now; §4b argues the
# numbers and is where the operator approves or changes them.
docket config set vote.rule.security-acceptance.threshold 0.67
docket config set vote.rule.doc-acceptance.threshold 0.60
docket config set vote.rule.tribunal.threshold 0.67
```

**Nothing about the corpus lands in this repo, and that is the design.** The
engine resolves instance config from ORDERED ROOTS: the shared corpus at
`~/.docket/config` FIRST, then `<repo>/.docket/config` as an OPTIONAL additions
layer. It registers across both, schemas before workflows, shared root first. So
binding a repo copies nothing, links nothing, and ignores nothing: **by default
a repo has no `.docket` directory at all.** One exists only when something is
genuinely this repo's — a workflow or schema addition under `.docket/config/`
(§3), or a repo action script under `.docket/bin/` (§4a′) — and both are
ordinary tracked files. A `name@version`, or a pinned ref, present in BOTH roots
with differing bytes refuses activation naming both paths; byte-identical
duplicates are a no-op. That is the entire collision surface between shared and
local.

**An existing `.docket/config/` is not a refusal.** Real files there are this
repo's additions layer: inventory them (`find .docket/config -type f`), report
what each is, and carry them into §3 and §5 as decisions already made rather
than facts to re-derive. What bootstrap will not do is re-argue an engine config
the repo already carries — if the additions read as a previous bootstrap's whole
output, say so and suggest `/retro`, whose job evolving them is.

**SYMLINKS there are transition debris.** The retired model built a link farm
into `~/.docket` at that path; against the shared root every entry of it now
either duplicates the corpus or dangles, and a dangling file link inside a
scanned root refuses activation naming the file. Surface the directory to the
operator recommending deletion, and let *them* delete it — removing a directory
in their repo is not yours to do. A `.gitignore` block ignoring `.docket/*` is
debris from the same era; name it in the same breath.

**Claim a prefix, operator-gated like everything else.** Ids are one rowid
sequence across the whole store; only the display prefix tells projects apart,
and two on this machine already render as `DKT`.

```bash
docket project list                    # what is taken
docket project set-prefix VOR          # 1-8 letters; DOC/RUN/STEP reserved
```

Display only — `DKT-42` and `VOR-42` are the same issue, and `DKT-` or a bare
number always parses — so it costs nothing and buys legible reports.

The rows and the config are different places now. **Neither config root holds
issues**: the rows sit in whichever store resolution finds, shared or local — a
normal arrangement either way. Every `config set` in this skill takes the
project scope; `--global` re-policies every project sharing the store.

**Why those three lines are here and not later.** Activation validates EVERY
registered workflow, not just the one an issue binds, and the pipelines naming a
`vote_rule` are five of today's nine, between them naming three distinct rules.
Until all three exist, `run activate` refuses outright — on a virgin project,
for an unlabelled issue that never touches a vote gate. Setting them now means
the first activation an operator sees is a real one. Re-derive the set from the
installed corpus (`grep -r vote_rule ~/.docket/config/workflows/`) rather than
trusting that count; a corpus revision that adds a rule adds a line here.
They authorize no execution, so they are safe to set before approval; what needs
approval is the NUMBER, which §4b puts in front of the operator.

`~/.docket/` holds three things: `config/` — the shared corpus, one canonicalized
symlink to the installed artifact of `contracts/`, `fragments/`, `schemas/`,
`workflows/`, `policy.toml` — plus `bin/` for corpus-shipped action scripts (§4a)
and `issues.db` for the rows. List `~/.docket/config/` for the inventory; counts
written here go stale. The Vorpal builder installs it from `src/user/docket/` (§6).

**Every repo gets the whole corpus** — you do not pick a subset and you do not
adapt it; it is generic on purpose, and one repo's opinion of it would become
every repo's, since every repo reads the same bytes. What a repo adds for itself
lives in its own additions layer, which is §3's business.

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

Mining no longer decides what to keep — the corpus is read whole. It sizes §3's
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
`Makefile`, never a substitute for it. That holds harder the older the map is:
where §0 skipped, the seven on disk are not this run's — a `spec-project` run
authored them, or the repo keeps them deliberately — and nothing says how long
ago, so the tree may have moved out from under every line. Cite the source; it
is the thing that is true.

Build files (`Makefile`, `justfile`, `package.json`, `Cargo.toml`, `*.nix`) and
CI config give you the real check command — the one a contributor actually
runs, and the ones that gate merges today. `README`/`CONTRIBUTING` give the
review shape: who approves, how many. `git log --format='%s' -50` gives
conventions and cadence. The test/doc layout tells you what a change touches,
for `scope` and `class`.

The gate/script miner runs each check command once — for real. A command
nobody has seen exit 0 is a guess, not a gate. Its brief carries positive
discipline ONLY: run each check command, report the exit code and the first 20
lines of any failure text verbatim, attribute nothing. Attribution is yours,
over its returns, and the environment is what you check first — a sandboxed
session blocking the network reads as a gate failure and is not one
(`vuln-scan` fails closed when `vuln.go.dev` is unreachable, with a message
that blames vulnerabilities), so have it rerun unsandboxed before you decide
anything. And a gate that fails honestly on today's tree is doing its job —
that is a finding to surface, never a reason to drop the gate. A gate that
needs the network gets that fact argued explicitly in its §4 `--flaky` row
either way.

## 3. Adapt — the repo-specific layer

The corpus is shared, generic, and already in place. What remains is what the
corpus cannot know, and all of it is this repo's: the **scopes** that bound an
issue (`architecture.md`'s module boundaries, the real test/doc layout); the
**fences** a gate harvests from an issue body (`source = "fence:<tag>"` takes
` ```<tag> ` blocks, one command per line, at activation only — any tag a bound
workflow declares, `checks` being a convention rather than the only one);
**engine config** at project scope (§4b, §4c); **trust entries** and their
scripts (§4); and **an additions layer of workflow or schema files** when the
shared corpus has no shape for this repo's work.

That last one has a first preference before it is an addition at all: a shape
the corpus lacks usually belongs IN the corpus, proposed into `src/user/docket/`
with a label-scoped `[match]` so it lies dormant everywhere it does not apply.
Add locally only when the shape is genuinely this repo's and nobody else's —
then it is WRITE work, and write work is an agent's: spawn one `executor-write`
agent carrying the miners' summaries and this section's rules verbatim, and
review its diff against the citations before surfacing anything in §5. Its files
create `.docket/config/` — that directory's only reason to exist alongside
§4a′'s `.docket/bin/` — as ordinary tracked files under names the corpus does
not use, a colliding `name@version` or pinned ref refusing activation outright:

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
  **`packet` is safe on a shared-corpus workflow and banned on a repo addition
  an isolated executor will claim.** The engine resolves packet includes against
  the CLAIMER's checkout: a ref into the shared root resolves from any cwd,
  worktrees included, while a ref into this repo's own `.docket/config/` is
  repo-root-relative and simply absent from a private worktree — the claim then
  fails with `packet file "…" is pinned by this run but is no longer on disk`
  AFTER recording the claim, stranding a tokenless claimed step until a reap
  (measured).
- `schemas/<name>@1.json` — only if a threshold consumes a step's `payload`, and
  the corpus already ships the common ones. **The filename IS the identity**
  (`findings@1.json` → `findings@1`); **a payload schema describes an array**,
  `type: "array"` with the object under `items`, an object-shaped one registering
  and then failing validation with "declares no top-level properties"; ordered
  fields need `"ordered_enum": true` or `>=` is refused.
- `policy.toml`, `contracts/`, `fragments/` — the shared root's, every one:
  pinned by content hash, registered as nothing, read by every repo. Read them
  freely; write nothing there.

Head each generated TOML with a comment naming what you mined and the date —
that is what makes the next retro's diff legible; schemas carry no comment
syntax, so their reasoning goes in the header of the workflow consuming them.
**Do not author a `PROVENANCE.md`.** No copy exists whose origin needs recording:
the corpus's provenance is `src/user/docket/`'s git history.

**A shared file is not yours to change here.** The shared root is read-only
installed bytes, so an in-place write is refused outright — and it would be the
wrong edit anyway, since every repo reads exactly those bytes. A shared file
wrong for everyone is a change proposed against `src/user/docket/` for the
operator to install — retro's discipline, not a local edit. Wrong for this repo
only is an addition in `.docket/config/`, under a name the corpus does not use.
And a pipeline whose review shape this repo does not practice will be routed
around: a finding for §5, not a silent local edit.

Two coupled invariants any addition must keep:

- **Every executor hint needs exactly one `[executors]` row, and every row needs
  a hint.** A new workflow strands a hint the moment its row is missing, and the
  shared `policy.toml` is installed bytes you cannot add the row to — so an
  addition reusing a shared hint is the safe shape, and inventing a hint means
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

The verb's real shape — stated because both wrong shapes got tried on
2026-08-10: `docket trust add <name> [--re-runnable] [--tree] [--flaky] --yes
-- /abs/path/script` — entry flags BEFORE the `--`. Everything after `--` is
stored verbatim as the argv, so a flag placed there becomes an argument your
gate script gets executed with (the engine's `trusting …` echo is where that
mistake shows; read it).

**A repo-internal script needs an ABSOLUTE argv[0].** Containment refuses any
argv[0] that resolves at or under the repo root — a repo-owned script is content
an executor can rewrite between approval and execution. The one exception: a
trust entry whose own argv[0] is already absolute, which is read as the operator
authorizing that exact in-repo path deliberately. So every entry pointing at
`scripts/qa/*` (or anything else in the tree) is proposed as
`$(git rev-parse --show-toplevel)/scripts/qa/tests.sh`, never
`./scripts/qa/tests.sh`. A relative one registers happily and then refuses at
run time — the failure a pre-refactor run shipped. Say in §5 that these entries are
absolute-path-bound: a moved or re-cloned worktree needs them re-added.

**Name every entry after what the script actually does — never after the gate you
wish you had.** A trust entry's name is what the operator reads when approving
and what every later report calls it, so a name that overstates the check buys a
false sense of coverage that nothing will correct. If a repo has a
`genericity.sh`, propose it as `genericity`; do not propose it as `scope` because
a scope gate is what the pipeline wants. That same pre-refactor run proposed
`genericity.sh` under the name `scope`, and what happened next is worth knowing
precisely, because the usual telling gets it backwards: the script never ran. Containment refused its
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

`spec-doc.toml` ships with the corpus, and its `record` step is an **action**,
not an executor: recording an accepted doc is "insert a row and link it", which
the engine runs itself and never claims. An action named `doc-record` resolves
through the trust store like any gate command, so it needs an entry:

The corpus ships the script itself — `~/.docket/bin/doc-record`, versioned
beside `spec-doc.toml` because they change together: the script reads
`record`'s declared inputs and the `doc-<type>` label convention, both corpus
decisions. You never author it and never copy it into the repo; you verify
the shipped bytes (below) and propose the entry. The argv is the literal
absolute expansion of `~/.docket/bin/doc-record` (trust argv takes no
variables and no `~`), identical in every repo:

```
name         doc-record
argv         <absolute $HOME>/.docket/bin/doc-record
re-runnable  yes — the script passes `--idempotency-key` (doc create, issue
             create, and both comment-add verbs take one), so a crash between
             create and link re-runs to the same DOC-N instead of a second
tree         no  — measured: it records through the CLI and writes no file in
             the working tree at all (its only write is a context file under
             its own temp work dir), so it races nothing a parallel read step
             is reading
flaky        no  — no network, no clock; it either records or exits non-zero
```

`--re-runnable` is the one flag genuinely arguable here, and the key is what
makes the yes defensible: read the shipped script before arguing the flag,
and turn it **off** if a corpus revision ever drops the key. A repo whose
trust store already binds `doc-record` to an old repo-local argv needs
`docket trust rm doc-record` first — trust refuses a changed argv under an
existing name rather than updating it. That is the one rm-and-re-add §5's
prohibition does not cover, and the split is exact: a differing ARGV is a
different command, so rm it and re-add under a FRESH approval; differing FLAGS
under an identical argv are never yours to overwrite — those go back to the
operator as a question (§5).

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

Verify the shipped script before you propose its entry — an agent's job, and
cheap: `[ -x "$HOME/.docket/bin/doc-record" ]` first (the engine execs argv[0]
directly, and the exec bit must survive the install chain — a non-executable
file here is an install defect to report, never a `chmod` into the
read-only install), then feed it a synthetic context bundle on stdin and check
it exits 0 printing one parseable reply. Feed it the same bundle twice: the
second run replaying the same DOC-N instead of minting another is the
measured basis for `--re-runnable`, which beats arguing it from prose — the
2026-08-06 authoring-era probes caught three real bugs this way, which is why
the ritual survives the script moving into the corpus. The agent returns both
probe transcripts; that evidence is what you attach to the proposal. Probe
against a SCRATCH store, not the shared one, and brief the sequence itself:
`export DOCKET_PATH=$(mktemp -d)`, confirm it came back non-empty before using
it, `docket init`, then both probes under that same env, reporting every exit
code and transcript verbatim. A probe against the resolved store writes real
DOC/issue rows into shared history — the
2026-08-10 run needed an operator-approved destructive delete to clean up, and
the id sequence keeps the scar either way.

### 4a′. Propose the `commit-exec` trust entry

The 2026-08 corpus mechanizes NO commit inside a pipeline: every shipped
pipeline ends before one. The boundary is conductor-commits /
operator-publishes — the conductor cherry-picks write-step output into real
unsigned commits at integration, and only push and PR stay the operator's
(1Password-gated signing is unavailable to headless executors). This
section applies ONLY if a repo-local workflow YOU wrote declares a
commit-terminal ACTION step; skip it otherwise, and do not invent a
commit-exec entry nothing consumes. Where it does apply, the history in one
line: the 2026-08-06 run (pre-refactor corpus) shipped without the script and
completed with an approved message and a dirty tree, leaving its conductor to
commit by hand under the approved gate.

Unlike `doc-record`, this one IS repo-authored — it encodes the repo's own
commit discipline, so it cannot ship with the corpus: an `executor-write` agent
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

The script is meant to be tracked repo content, so **check that it is** —
`git check-ignore -v .docket/bin/commit-exec`, and the same for whatever §3
wrote under `.docket/config/`. Where §1's era-debris `.gitignore` block
survives it ignores the whole `.docket/` tree, which makes both layers
invisible to git and absent from a fresh clone; surface that with §1's
recommendation rather than editing their `.gitignore` yourself. The one
artifact that SHOULD be ignored is a local store, and only if someone ran
`docket init --local`: ignore `.docket/issues.db*` then, nothing else.

### 4b. Propose the vote-rule thresholds

Vote rules live in **engine config**, not in either config root, so activation
never auto-registers them — and a pipeline naming an unregistered rule **fails
to register at all**:

```
✘ Error: step "security-vote": `vote_rule` "security-acceptance" is not registered; none are registered. Register one with `docket config set vote.rule.security-acceptance.threshold <0-1>`
```

Five of the nine pipelines name one, across three distinct rules:

```bash
docket config set vote.rule.security-acceptance.threshold 0.67   # project scope:
docket config set vote.rule.doc-acceptance.threshold 0.60        # no --global
docket config set vote.rule.tribunal.threshold 0.67              # on any of them
```

A rule exists exactly when its threshold is set, so these three writes are what
bring the rules into being — unqualified, for this project only. `0.67` is
two-thirds: a security acceptance needs a clear majority, and with a
three-judge panel it means two must agree. `0.60` is a simple majority with a
margin — a doc is accepted when most reviewers say yes, and the lower bar
reflects that a doc's cost of being wrong is a revision, not an incident.
`tribunal` is the rule the four converted workflow acceptance gates tally
under — investigation's read-gate, spec-doc's PRD/ux acceptance, spec-project's
and retro's accepts, operator questions until 2026-08-11 (free-standing
fix-batch proposals carry their own `--threshold` and name no rule) — and
it takes `0.67` for the same arithmetic as the security rule: two of three, so
no single seat passes a gate or vetoes one alone. All three are provisional;
the first retro with five runs of vote data should revisit them.

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
docket config set lease.ttl.read  30m        # Propose BOTH classes: the
                                             #   2026-08-06 run sized only
                                             #   write, and its slowest silver
                                             #   judge then ran 13m of the 15m
                                             #   read default on 3 files
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
off the installed corpus rather than quoting these; they move whenever the
corpus does. If your slowest write step has historically taken ~30 minutes, a 45m
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

A virgin repo has no issue yet, and this skill does not say where the first one
comes from unless you make it say: take the issue the operator named; if none
was named, propose ONE drawn from the specs' gap sections and offer the swap
explicitly — never activate work the operator has not seen named. (The
2026-08-06 run's conductor improvised exactly this, well; now it is the
contract.) One smoke
issue is this skill's ceiling: anything larger is `/plan`'s to structure
BEFORE conducting — plan-up-front is the default, single-issue improvisation
the exception.

**Lint what you wrote before starting anything.** `docket workflow lint FILE`
runs the exact validation `workflow register` runs — grammar, step rules, vote
rules, schema cross-checks — and writes nothing:

```bash
for f in .docket/config/workflows/*.toml; do docket workflow lint "$f"; done
```

Only additions need this — a repo with no additions layer has nothing here to
lint, and the shared corpus was linted before it was installed.

Each verdict is `new`, `unchanged` (identical bytes already registered), or
CONFLICT — changed bytes at a frozen `name@version`, which fails the lint and
would refuse the whole activation. Clear every one first: a lint failure is a
five-second loop, the same failure at activation is a refusal the operator sits
through. A CONFLICT you did not cause has two causes worth naming apart: the
shared corpus moved without a bump, which refuses every repo that reads it and
is fixed in `src/user/docket/` (§6) rather than around; or your addition
collides with a shared `name@version`, which is fixed by renaming the addition.
Say which one it is.

On a FIRST bootstrap the registry is empty, so lint refuses any workflow naming
a payload schema — `` `payload` names "findings@1", which is not registered ``
— and its remedy line says to `schema register`, which rule 1 forbids. That
refusal is the empty registry, not the file: lint your additions for grammar,
expect the unresolved-schema refusals, and let the dry-run's registration report
stand in for them (it validates schemas before workflows; all 12 proved clean
this way on 2026-08-10). Lint resolving refs across the registered roots is the
engine fix, owed upstream; until it lands, this is the expected path.

```bash
docket run start --issue DKT-<n>       # the id `issue create` printed — one
                                       # rowid sequence store-wide, so a virgin
                                       # repo's first issue is rarely DKT-1
docket run activate RUN-<n> --dry-run  # the id `run start` printed
```

`--dry-run` computes the whole activation and writes nothing. It needs no
`--pin` for anything under either config root: the scan pins every file it finds
there recursively, with refs relative to the root it found them in — which is
why a shared-root ref resolves from any cwd and a repo-root ref does not (§3's
packet rule). An explicit `--pin` on a file the scan already covers only adds a
second row for the same bytes under a checkout-bound path. Two blocks can come
back:

- **The registration report** — every workflow and schema this activation
  would adopt, as `name@version  path  (outcome)`, plus the count of further
  config files pinned by content hash. This proves the config is well-formed
  and accepted; it says nothing about what will execute.
- **The harvested-command list**, annotated `matched`/`unmatched` — printed
  only when a workflow this activation binds declares `source = "fence:<tag>"`
  AND the bound issue carries a fence with that exact tag. No shipped corpus workflow declares
  one, so on a corpus-derived config this block is absent, not empty. Its
  absence is correct, not a failure to debug.

Both blocks are printed prose in human mode only. Under `--json` the
registration report becomes `registered[]`
(`{kind,name,version,path,sha256,outcome}`); the fence block has no list
counterpart at all — the payload carries `fences_harvested`, an INTEGER count
(`0` on a corpus-derived config), never the harvested commands. Others sit
beside them (`issues_bound`, `issues_expanded`, `pins_recorded`,
`pins_from_config`, `steps_created`, `scope_warnings`, `dry_run`,
`projected_status`), so read one real payload rather than trusting this list.
Every stderr diagnostic is suppressed under `--json`; read it in human mode
when the point is showing the operator what printed.

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

Every gate named by a bound workflow gets a row; a check you could not
implement gets a row with no argv and the reason. A row with no trust entry
will report `unmatched` on its first real run — say it in the row, not a
footnote.

**Trust is approved alone.** What you wrote, the registration report, this gate
table, and the thresholds may go to the operator batched into one question.
Every trust entry gets a question to ITSELF, carrying that one entry's argv and
its three flag arguments and nothing else — never a second trust entry, never a
config item riding along. The reason is measured: an audit of a day of this
skill's approvals found a trust write approved inside a four-item bundle in a
single click, which is what a bundle does to the one item in it that authorizes
execution. If that means four questions in a row, ask four questions in a row.

On the yeses, run `trust add --yes` for each entry that got its own yes, re-run
the dry-run to confirm it still registers clean (a fenced setup must now read
`(matched: <name>)`; named gates resolve in the trust store, not here), then ask
again, for the activation itself, and run it without `--dry-run`. Two approval
moments whatever the question count: one for what you wrote, one for what runs
— and both are the OPERATOR's. No panel stands in for either, and the tribunal
that clears definition-fix batches elsewhere has no seat here: bootstrap is
where a repo's trust is established, a ceremony rather than a run gate, and the
authority that establishes trust cannot be delegated to the thing being
trusted. Every approval, here and everywhere this skill asks, goes through the
built-in question tool with your recommended option first, labelled
"(Recommended)".

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
  reconcile, not yours. That prohibition is about FLAGS. A surviving entry
  whose ARGV differs cannot be updated at all — trust refuses it outright, so
  that one IS `trust rm` plus a fresh `trust add --yes` under a new approval
  (§4a).

After the first real run, read the gate verdicts: `unmatched` in
`gate_results` means the gate never executed — its entry is missing or
containment refused its argv. The verdict text names the fix; follow it
literally.

### 5a. Remove the working specs

Everything that reads §0's seven has now read them: §2's miners mined them, §3
cited them into scopes and gates, and §5's issue may have come out of a gap
section. They were input to this run rather than output of it, so they go here,
and bootstrap leaves no spec file in the tree at all. The moment is chosen, not
incidental: activation creates steps but `/conduct` dispatches them and has not
run, so no executor holds the tree and nothing claimed is reading what you
remove.

**Delete exactly what §0 wrote.** The verification agent returned the
`docs/spec/` paths added against `$TMPDIR/pre-fanout`, and that list is this
step's whole authority. Name each path in the `rm` — never a glob, never
`rm -rf docs/spec` — then `rmdir docs/spec`, whose refusal on a non-empty
directory is precisely the behaviour you want: a sibling file somebody else
keeps there survives by construction, and the refusal is how you find out it
is there.

**A skipped §0 deletes nothing.** Seven specs already on disk when you arrived
are not yours — a `spec-project` run authored them, or the repo keeps them
deliberately — and they outlive this bootstrap untouched, as does any file
under `docs/spec/` that git already tracks. Deleting in the operator's repo is
otherwise not yours to do; §1 hands their symlink debris back to them for
exactly that reason. The exception here is narrow and it is the whole
justification: you wrote these seven, this session, for your own use.

## 6. Where the corpus comes from

`src/user/docket/config/{contracts, fragments, schemas, workflows,
policy.toml}` → (`just activate`) → `~/.docket/config/` → the engine reads it directly, as
the first of its ordered roots. ONE hop, no repo-side copy, nothing to keep in
sync: the bytes activation pins ARE the bytes `~/.docket/config` holds. A repo's
own additions, when it has any, are ordinary tracked files in the second root
and travel with the clone. **Never copy a corpus file into a repo** — one
centrally maintained corpus is the whole point, and a copy diverges the moment
either side moves with nothing reporting it.

One walker fact survives the change: the engine CANONICALIZES a config root
before walking it, which is what lets `~/.docket/config` be itself a symlink to
the installed artifact and still read byte-identically — same registered
SHA256s, same pin count, packet resolution included. It does NOT follow
directory symlinks INSIDE a root; one there fails with `reading the pinned
config file …: is a directory`. So an additions layer is real directories
holding real files, never a linked subtree.

That store is READ-ONLY, and the refusal is the design: corpus edits are made in
`src/user/docket/` and installed by the operator's `just activate`. Because an
install rewrites the bytes already-pinned refs resolve to, corpus installs land
BETWEEN runs, never during one; and because every repo reads the same bytes, an
edit at an unchanged `name@version` refuses the next activation in ALL of them.
That is the cost of sharing, and why corpus edits go through `src/user/docket/`
with a bump.

Staleness therefore lives in exactly one place — `~/.docket/config` sits behind
`src/user/docket/config/` until the operator runs `just activate` — so diff them
before concluding anything about the corpus's contents. The source mirrors the
install tree for tree, so `diff -r "$SRC/config" "$HOME/.docket/config"` and
`diff -r "$SRC/bin" "$HOME/.docket/bin"` is the whole check, `$SRC` being the
dotfiles checkout's `src/user/docket`.

There is no network step anywhere in this flow. If `~/.docket/config` does not
exist, there is no corpus to read — say so, and fall back to `workflow init
--template` for a workflow in this repo's own additions layer.

## 7. Hand off

Report the config files you wrote, the trust entries they approved, and the run
you activated — and name §0's seven specs as working input you have since
removed (§5a), so nobody goes looking for a `docs/spec/` that was never meant
to survive. Name the next move plainly: real work beyond the smoke issue
goes through `/plan` (issues, phases, gates placed deliberately), then
`/conduct` drives what plan recorded — do not slide from bootstrapping into
driving on your own momentum, or on a stop-guard's push. Say plainly that this
repo materializes no corpus of its own: the engine reads `~/.docket/config`
directly, a fresh clone needs no setup step, and shared bytes change only
through `src/user/docket/` and a version bump — the blast radius being every
repo that reads the corpus (§6). Name any additions layer you did create and why
it exists. Retiring a superseded version is `workflow deprecate` — a
binding-time filter, never a deletion, and retro's call rather than yours.

Activation's refusals name the file and the fix; follow them literally. Two
worth pre-empting: an issue matching zero workflows is a `[match]` too narrow —
widen it, never label the issue to fit — and an issue matching several is
resolved with `unless_labels` on the loser, which evaluates last and wins.
