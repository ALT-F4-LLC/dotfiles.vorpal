---
name: bootstrap
description: Draft a complete .docket/config/ for a repo that has none — mine the repo, adapt a shipped template, propose trust entries, and surface the whole binding for approval before the first run. Use at project start, or when `docket run activate` reports no workflow matches an issue.
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

## 1. Start from the corpus

```bash
docket init                                   # if .docket/ does not exist
cp -R ~/.claude/docket-config/. .docket/config/
```

`~/.claude/docket-config/` is the shipped corpus: 9 workflows, 24 contracts, 16
fragments, 2 schemas, and `policy.toml`. It is a local reference copy — no
network, nothing to fetch. Start here whenever the repo's shape is anywhere near
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

Read, don't guess. Every adaptation in §3 cites something you found:

Build files (`Makefile`, `justfile`, `package.json`, `Cargo.toml`, `*.nix`) and
CI config give you the real check command — the one a contributor actually
runs, and the ones that gate merges today. `README`/`CONTRIBUTING` give the
review shape: who approves, how many. `git log --format='%s' -50` gives
conventions and cadence. The test/doc layout tells you what a change touches,
for `scope` and `class`.

Run the check command once yourself. A command you have not seen exit 0 is a
guess, not a gate.

## 3. Adapt

Rewrite the template into `.docket/config/`:

- `workflows/<name>.toml` — named for the repo's work, `version = 1`, steps
  reflecting the real review shape.
- `schemas/<name>@1.json` — only if a threshold consumes a step's `payload`.
  **A payload schema describes an array**: `type: "array"` with the object
  under `items`. An object-shaped schema registers, then fails workflow
  validation with "declares no top-level properties." Ordered fields need
  `"ordered_enum": true` or `>=` is refused.
- `policy.toml`, `contracts/`, `fragments/`, `templates/` — pinned, registered
  as nothing. Instance knowledge lives here, including the fenced-check
  convention: a gate declaring `source = "fence:checks"` harvests ` ```checks `
  blocks from the issue body, one command per line, at activation only.

Head each generated file with a comment naming what you mined and the date —
that is what makes the next retro's diff legible.

**Adapting the corpus, if you started from it.** The nine workflows and 24
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

### 4a. Propose the `doc-record` trust entry

If you kept `spec-doc.toml`, its `record` step is an **action**, not an
executor: recording an accepted doc is "insert a row and copy bytes", which the
engine runs itself and never claims. An action named `doc-record` resolves
through the trust store like any gate command, so it needs an entry:

```
name         doc-record
argv         .docket/bin/doc-record
re-runnable  yes — `docket doc create` is idempotent on a doc that already
             exists for this issue; a crash between create and link re-runs clean
tree         no  — writes into the docket database and docs/, not the build tree,
             so it races nothing a parallel read step is reading
flaky        no  — no network, no clock; it either records or exits non-zero
```

`--re-runnable` is the one flag genuinely arguable here: turn it **off** if your
script appends rather than upserts, because then a retry duplicates a DOC-N.
Read the script before arguing the flag.

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

There is **no heartbeat**. Liveness is TTL-only, so the lease TTL is the entire
mechanism keeping a working executor's claim alive:

```bash
docket config get lease.ttl.default          # ships as 15m
docket config set lease.ttl.write 45m        # propose per class
```

**Size it against worst-case step duration, not the typical one.** A TTL shorter
than the longest write step means the lease expires *while the executor is still
working*: the step is reaped, another claimant can take it, and the original
returns to `complete` a step it no longer holds — the ack loop. Under a
heartbeat, a slow step renewed itself and the TTL only had to exceed the
heartbeat interval. Without one, the TTL alone has to cover the whole step.

Argue the number from the corpus's own cost declarations. `expected_cost` is the
proxy you have: in the shipped corpus `implement` carries the highest at `1.50`,
against `0.10` for the cheapest read steps. If your slowest write step has
historically taken ~30 minutes, a 45m write-class TTL leaves 50% headroom —
which is the right direction to be wrong in, because the two errors are not
symmetric:

- **TTL too short** → mid-work reaps, duplicated work, ack loops. Corrupts the
  run's accounting and wastes the spend already made.
- **TTL too long** → a genuinely dead executor's step sits claimed until the TTL
  expires. Costs latency on a failure path, and `max_step_duration` still bounds
  it.

Propose the long side, and say plainly that the number is provisional until real
step durations exist to size it against. This is the first thing a retro should
re-derive from evidence.

## 5. Surface the binding — the approval moment

```bash
docket run start --issue DKT-1
docket run activate RUN-1 --dry-run --pin .docket/config/policy.toml
```

`--dry-run` computes the whole activation and writes nothing. It prints what
registers, what pins, and **every harvested command verbatim**, annotated
`matched` or `unmatched`. Show that output, not a summary of it. Before trust
exists the command reads `(unmatched)` — the correct state to present: this is
what would run, and nothing yet authorizes it.

Ask for approval of the config and the trust proposals together. On yes:

```bash
docket trust add checks --re-runnable --yes -- make check
docket run activate RUN-1 --dry-run --pin .docket/config/policy.toml
```

The second dry-run must read `(matched: checks)`. Still unmatched means the
argv differs from the fence line byte-for-byte — fix the entry, not the issue.

Then ask again, for the activation itself, and run it without `--dry-run`.
Two approvals: one for what you wrote, one for what runs.

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
you activated. `.docket/config/` is git-versioned and machine-authored: changes
go through a version bump, because changed bytes at an unchanged `name@version`
refuse the next activation outright.

Activation's refusals name the file and the fix; follow them literally. Two
worth pre-empting: an issue matching zero workflows is a `[match]` too narrow —
widen it, never label the issue to fit — and an issue matching several is
resolved with `unless_labels` on the loser, which evaluates last and wins.
