# Gates

How a simplify-code pass finds the repository's checks, states the guard each
change needs, decides what is frozen, remembers what it filed or skipped, and
tells the worker who later applies a filed issue what to prove. The pass
itself changes nothing: every rule below that sounds like an action is the
instruction the issue hands to that worker. The skill points here instead of
restating these; a change to a rule lands here once.

## Discovery

Find the commands the repository itself uses, in this order, and stop at
the first source that names a command for each of build, typecheck, test,
format, and lint. Never invent a command the repository does not name.
Lint is optional and has no toolchain default: a repository whose sources
below name no lint command has no lint gate. The pass reads these sources
and records the commands; it runs none of them, because a build, test,
formatter, or linter writes into the checkout.

1. `CLAUDE.md` or `AGENTS.md` at the root or under the unit's directory: an
   instruction that names a test or build command wins.
2. A task runner: `justfile`, `Makefile`, `Taskfile.yml`, `mise.toml`,
   `package.json` scripts, `composer.json` scripts. Prefer a recipe named
   `test`, `check`, `build`, `lint`, `typecheck`, `fmt`, or `format`.
3. Continuous integration: `.github/workflows/*.yml`, `.gitlab-ci.yml`,
   `.circleci/config.yml`. The repository trusts the commands its pipeline
   runs.
4. The toolchain default when nothing above names one:

   | Signal | Build | Typecheck | Test | Format |
   | --- | --- | --- | --- | --- |
   | `Cargo.toml` | `cargo build --all-targets` | same | `cargo test` | `cargo fmt -- <files>` |
   | `go.mod` | `go build ./...` | `go vet ./...` | `go test ./...` | `gofmt -w <files>` |
   | `package.json` | script `build` | `tsc --noEmit` if `tsconfig.json` | script `test` | `prettier --write <files>` if configured |
   | `pyproject.toml` | none | `mypy` or `pyright` if configured | `pytest` | `ruff format <files>` or `black <files>` if configured |
   | `*.gemspec`, `Gemfile` | none | `sorbet tc` if configured | `bundle exec rspec` or `rake test` | `rubocop -x <files>` if configured |
   | `mix.exs` | `mix compile --warnings-as-errors` | same | `mix test` | `mix format <files>` |
   | `pom.xml`, `build.gradle` | `mvn -q compile` or `gradle build -x test` | same | `mvn -q test` or `gradle test` | none |
   | `*.csproj`, `*.sln` | `dotnet build` | same | `dotnet test` | `dotnet format whitespace <project>` |

The formatter is a layout tool, never a lint autocorrector: an option
that rewrites code rather than whitespace (`rubocop -a`, `eslint --fix`,
`ruff check --fix`) is not a formatter here. The issue tells the worker to
run it on the touched files before the final rerun, so the tree that passes
the gates is the tree that is committed.

A repository with no test command at all has no guard for live-code
transformations: the pass files only `inert` and `reachability` entries, and
the issue says the tree has no test suite.

The issue tells the worker to run the full suite for its baseline and for its
rerun. A narrowed run (one package, one test file) is allowed only for the
mutation probe, and only when the narrowed set is the tests that reference
the unit; the probe's purpose is to see a failure, and a narrowed failure is
a failure.

## Mutation probe

The probe proves the suite notices a behavior change at one site. The pass
never runs it, because it edits the tree. Every issue that carries a `probe`
entry tells the worker to run it before transforming that site, once per
function or method, on a clean tree.

1. Choose one change that alters observable behavior of the site and
   nothing else: flip a comparison, return a different constant, drop a
   branch, swap the order of two effects, negate a condition. Pick the
   change closest to what the planned cleanup could break. Never change a
   signature; a compile error is not a test failure and proves nothing.
2. Apply it with a targeted edit, run the tests (narrowed as above or
   full), and read the result.
3. Revert by path: `git checkout -- <probed files>` or `git diff` saved to
   a patch and applied in reverse. Never `git stash`: the stash stack is
   shared across sessions on this machine, and the skill runs in arbitrary
   repositories. Confirm `git status --porcelain` is empty and HEAD is
   unchanged before continuing.
4. A failing run is a proven guard for that site. A passing run means
   nothing guards it: the worker leaves the site alone and names it in a
   comment on the issue.
   A run that errors for a reason unrelated to the change (a flaky test, a
   timeout) is retried once; a second error counts as no guard.

What the probe proves: a change at this site breaks at least one test.
What it does not prove: that every branch of the site is exercised. The
worker therefore keeps a `probe` transformation inside the behavior the
site already has and never widens or narrows a condition on the way
through.

## Reachability proof

Dead-code removal (`reachability`) never probes. Its proof is that nothing
can reach the code: no reference by search or LSP across the whole tree
including tests, build scripts, templates, and string literals; or the
compiler, linter, or type checker reports the symbol unused; or the
guarding condition is a literal that cannot vary. Reflection, string-built
symbol names, plugin registries, and exported entry points that an external
consumer may call defeat search; when the language or framework uses any
of these near the unit, treat the symbol as reachable and leave it alone.
The pass re-runs the search itself on the current tree before it files a
`reachability` entry, since search is read-only: an entry whose proof fails
is queued `skipped` at the current HEAD and not filed. A reference that
exists is a false positive: the entry is dropped and queued `refuted`. The
worker repeats the search before deleting, and comments on the issue and
leaves the symbol when a reference has appeared since.
After the removal, build, typecheck, lint when the repository names one,
and the full suite must pass; in a repository with no test command, build,
typecheck, and lint when named must pass.

## Inert edits

An `inert` edit cannot change what the program does: a comment, a
banner, a docstring the runtime does not expose, a lint suppression the
linter no longer needs, a compile-time-only cast the type checker no longer
needs. No probe and no reachability search; build, typecheck, and the lint
gate must still pass afterwards, and the full suite runs once at the end of
the change with everything else. In a repository with no lint gate, removing a
lint suppression is not an inert edit; the pass does not file it and queues
the finding `skipped`. Inert edits and reachability removals are the only
kinds the pass files for a unit no test references.

## Frozen contracts

A change may alter in-repo internal symbols when every caller in the tree
is updated in the same change. Everything below is frozen: it stays
byte-for-byte compatible in name, shape, order, and default.

- **Command-line surfaces.** Flag names, subcommands, positional order,
  defaults, exit codes, help text that a script might parse.
- **Configuration and environment.** File formats and keys the program
  reads, environment variable names, default values.
- **Wire and storage shapes.** Anything serialized: struct or class fields
  carrying serialization annotations or derives, JSON and YAML keys,
  protobuf and schema files, OpenAPI documents, database migrations and
  column names, cache key formats, log lines a downstream parser might
  read.
- **Published-library exports.** Every exported symbol of a package that
  can be consumed outside this repository. Signals that a package is
  published: `package.json` without `"private": true`; a `Cargo.toml`
  package without `publish = false`; a `pyproject.toml` with a `[project]`
  table; a Go module whose exported identifiers live outside a `main`
  package and whose module is not a single binary; a `.gemspec`; a Maven
  or Gradle artifact with a group and version. In such a package, exported
  symbols, their signatures, and their documented behavior are frozen even
  when no in-repo caller uses them.
- **Test files.** A test may change only to delete a test whose subject was
  removed as dead code or to update an import for a renamed internal
  symbol. A test edited to make the suite pass is a behavior change.

When it is unclear whether a symbol is external, it is frozen. Renaming
inside a single file is internal; renaming across files is internal when
the search for callers is complete and every caller changes in the same
change.

## Issue contract

Each issue the pass files tells the worker, in its Acceptance field, what
the old landing steps used to enforce. The worker reads this without the
filing conversation, so the issue states it and points here by the installed
path `~/.claude/skills/simplify-code/references/gates.md` for the detail.

- **Behavior is frozen.** Same outputs, errors, side effects, and observable
  ordering. A change that needs a test rewritten to pass is a behavior
  change, so the worker stops and comments instead.
- **The guard per entry.** Each entry names its proof class. `inert`: the
  gates in [Inert edits](#inert-edits). `reachability`: the search in
  [Reachability proof](#reachability-proof), repeated before deleting.
  `probe`: the [mutation probe](#mutation-probe) on each site before the
  site is touched; a site whose probe passes is left alone and named in a
  comment.
- **The gates.** The build, typecheck, lint, test, and format commands found
  under [Discovery](#discovery), by name, and the rule that the worker runs
  the formatter on the touched files, then the full gates, and reads the
  output itself.
- **The review bar.** The diff must show none of: a test file changed other
  than to delete a test for removed dead code or to update an import for a
  renamed internal symbol; a [frozen contract](#frozen-contracts) changed; a
  file outside the unit changed other than to update a caller of a renamed
  symbol; a change that reads as a rewrite rather than a removal or a
  flattening; a touched file on a [security-boundary
  path](#security-boundary-paths). When one holds, the worker restores by
  path and comments on the issue.
- **No tests.** A unit no test references carries only `inert` and
  `reachability` entries; its `probe` entries are ledgered `no tests` and
  not filed.
- **Landing.** The worker commits through the repository's own flow and never
  pushes.

## Ledger

`simplify-ledger.md` in the session's scratchpad directory, or under
`$TMPDIR` when the session lists none. One line per entry:

```text
<unit path or site> | <reason> | <HEAD at the time> | <one-line note>
```

Reasons: `no tests`, `security boundary`, `held`.

Expiry, checked at the start of every tick before the ledger is read:

- `no tests` expires when
  `git log <recorded HEAD>..HEAD -- <unit paths> <its test paths>` is
  non-empty. A commit that touched the unit or its tests may have added
  the guard.
- `held` expires when HEAD moves at all: the cause (no Docket project, no
  path to name, a failed create) may have cleared.
- `security boundary` never expires within a session; the operator decides
  those by hand.

The ledger is session state, not repository state. It is never committed,
and a new session starts with none by design: the operator's own commits
between sessions change the answers.

## Session files

Three files live in the same directory as the ledger, beside it. All are
session state, never committed, and survive context compaction, which is why
state lives there and not in the conversation. Read them at the start of
every tick.

- `simplify-ledger.md`: the [ledger](#ledger).
- `simplify-findings.md`: the [findings queue](#findings-queue).
- `simplify-state.md`: one line, `surveyed-head: <sha>`, the HEAD the last
  survey covered; a missing file means survey every shard.

## Findings queue

A confirmed finding is queued, not dropped, so it can be filed once and
never twice. One line per finding:

```text
<fingerprint> | <state> | <HEAD at the time> | <one-line note>
```

The fingerprint is `<repo-relative path>#<item>#<enclosing symbol>`, with
the item named as the catalog names it. It carries no line numbers and no
HEAD, so a rerun of discovery finds the same finding and does not queue it
twice. It is also the key passed back to discovery as `refutedKeys`: the
first column of every `refuted`, `skipped`, `declined`, and `filed` line,
unchanged, so those items are not re-found and re-refuted. A cleanup finding
(a catalog entry with a proof class) has the same shape,
`<path>#<entry>#<enclosing symbol>`. The symbol is the bare name of the
innermost enclosing function, method, or class, or the declared name for a
top-level declaration or import. Build a key by replacing each `|` or line
break with a space, collapsing runs of whitespace to one space, removing
spaces around each `#`, dropping a trailing `()`, and trimming the symbol;
the workflow does the same. States:

- `open`: a report-only finding a refuter confirmed, not yet filed.
- `filed`: an issue carries it; the note holds the issue id.
- `declined`: a closed issue (labelled `wont-do`, or a decision issue with its
  answer recorded) already settles it. Never
  re-queued within a session.
- `held`: confirmed but not filed: no Docket project answered, the finding
  names no path, or the create failed. Retried at the next tick; its key is
  not passed back.
- `refuted`: a refuter explicitly rejected it, or its reachability proof
  found a reference. A refuter that returned nothing refutes nothing.
- `skipped`: a confirmed cleanup finding the pass did not file because it
  had no guard: a failed reachability proof, or a lint suppression in a
  repository with no lint gate. Its key is passed back so the finding stops
  holding a refutation slot.
- `stale`: the entry's path changed after it was recorded.

Expiry, checked at the start of every tick: an `open`, `filed`, `refuted`,
or `skipped` entry whose path shows `git log <recorded HEAD>..HEAD -- <its path>`
non-empty is marked `stale` and never trusted from the file. The next
discovery round re-confirms a stale report-only item (back to `open`) or does
not find it, and a re-found cleanup finding is deduplicated against Docket
before anything is filed. A stale `refuted` or `skipped` key is only a
suppression and is dropped. A `stale` entry still present at the following
tick is dropped, and its key is no longer passed back. `declined` stays for
the session.

## Deduplicate before filing

Docket is the durable memory; the queue only saves rounds. Before a create,
list the issues carrying the `simplify-code` label in every status and read
each one whose files overlap the finding's path. Each issue body ends with a
`Finding keys:` line listing the fingerprints it carries.

- A key on an open issue: the finding is tracked. Drop it from the new
  issue; add a comment only when the new round has material new evidence.
  Queue it `filed` with that issue's id.
- A key on a closed issue labelled `wont-do`: the operator declined it.
  Queue it `declined` and file nothing.
- A key on a closed work issue (not a decision issue) without that label: the
  cleanup landed and the finding is back. File a new issue and link the prior id in its body. The
  idempotency key carries `/after-<that issue's id>`: a repeated key returns
  the original issue, so the unsuffixed key would replay the closed one.
- A key on a closed decision issue without that label: the operator chose
  an option. Queue it `declined`, link the decision, and file nothing; the
  chosen option's work belongs in its own issue, not a second decision.
- No match: file.

If the existing issues cannot be read, hold creation (`held`) rather than
reproducing an earlier pass's queue.

## Security-boundary paths

A path is a security boundary when any `/`-, `.`-, `_`-, or `-`-delimited
component of it is one of: `auth`, `authn`, `authz`, `oauth`, `session`,
`sessions`, `secret`, `secrets`, `crypto`, `cipher`, `permission`,
`permissions`, `sandbox`, `acl`, `rbac`, `credential`, `credentials`,
`token`, `tokens`, `password`, `passwd`, `jwt`, `tls`, `ssl`, `csrf`, `login`
(case-insensitive). The discovery workflow applies the same list as a
backstop to what its scouts judge. The pass files nothing for such a unit, and
each issue's review bar refuses any touched path on the list.

## Queued units

A discovery round yields a ranked queue the tick works down. The queue saves
ranking, never proof: the reachability search and the dedupe reread run at
filing time on the current tree, and discovery-time evidence is never reused.

A queued unit stays only while
`git diff --quiet <scout HEAD> HEAD -- <unit paths> <its test paths> <its evidence paths>`
is clean. Evidence paths are the other files a finding depends on: a
duplicate's partner, the callers of a pass-through or flag argument, the
callers of a rename. A unit that fails the check is dropped to the next
discovery round.

## Decision issues

A report-only finding changes behavior or needs a decision, so the pass never
files it as ready work. It files a decision issue instead: the finding, two
or three concrete options, always a last option to leave it as is, and a
recommendation. A decision issue changes no code; its deliverable is the
recorded answer, which `docket-groom` triages and which the operator makes.
The issue asks that the answer be recorded as an issue comment, that a
leave-as-is answer close it with `wont-do`, and that a chosen option be
filed as its own work issue.
Dependency removal, orphan-file deletion, and any option that touches a
[frozen contract](#frozen-contracts) are decisions only an operator makes; the
body says so, and no model vote or advisor pick settles them. A test file
changes only if the chosen option names it (strengthening a hollow test is the
usual case).
