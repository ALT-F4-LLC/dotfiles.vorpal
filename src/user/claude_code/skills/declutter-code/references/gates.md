# Gates

How a declutter pass finds the repository's checks, proves a site is
guarded, decides what is frozen, and remembers what it skipped. The skill
points here instead of restating these; a change to a rule lands here once.

## Discovery

Find the commands the repository itself uses, in this order, and stop at
the first source that names a command for each of build, typecheck, test,
format, and lint. Never invent a command the repository does not name.
Lint is optional and has no toolchain default: a repository whose sources
below name no lint command has no lint gate.

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
`ruff check --fix`) is not a formatter here. It runs on the touched files
before the rerun, so the tree that passes the gates is the tree that is
committed.

A repository with no test command at all has no guard for live-code
transformations: only `inert` and `reachability` entries can be applied,
and the report says the tree has no test suite. A repository whose discovered command
needs a tool, service, network access, permission, or credential this
environment lacks has a gate
that cannot run: ledger it as `gate unavailable` with HEAD, report which
gate is unavailable, once, and rest.

Run the full suite for the baseline and for the rerun. A narrowed run (one
package, one test file) is allowed only for the mutation probe, and only
when the narrowed set is the tests that reference the unit; the probe's
purpose is to see a failure, and a narrowed failure is a failure.

## Mutation probe

The probe proves the suite notices a behavior change at one site. It runs
before the worker touches that site, once per function or method the pass
will transform, on a clean tree.

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
   nothing guards it: ledger the site as `no coverage`, queue its finding
   `skipped` at the current HEAD, and leave it alone.
   A run that errors for a reason unrelated to the change (a flaky test, a
   timeout) is retried once; a second error counts as `no coverage`.

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
of these near the unit, treat the symbol as reachable, leave it alone, and
queue the finding `skipped` at the current HEAD. A reference that exists is a
false positive instead, and the unit is `blocked` under §2.
After the removal, build, typecheck, lint when the repository names one,
and the full suite must pass; in a repository with no test command, build,
typecheck, and lint when named must pass.

## Inert edits

An `inert` edit cannot change what the program does: a comment, a banner, a
docstring the runtime does not expose, a lint suppression the linter no
longer needs, a compile-time-only cast the type checker no longer needs.
No probe and no reachability search; build, typecheck, and the lint gate
must still pass afterwards, and the full suite runs once at the end of the
pass with everything else. In a repository with no lint gate, removing a
lint suppression is not an inert edit; the suppression stays and its finding
is queued `skipped`. Inert edits and reachability removals are the
only kinds the pass may apply in a unit no test references.

## Frozen contracts

A change may alter in-repo internal symbols when every caller in the tree
is updated in the same pass. Everything below is frozen: it stays
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
pass.

## Ledger

`declutter-ledger.md` in the session's scratchpad directory, or under
`$TMPDIR` when the session lists none. One line per entry:

```text
<unit path or site> | <reason> | <HEAD at the time> | <one-line note>
```

Reasons: `no tests`, `no coverage`, `blocked`, `refused`, `baseline red`,
`security boundary`, `gate unavailable`.

Expiry, checked at the start of every tick before the ledger is read:

- `no tests` and `no coverage` expire when
  `git log <recorded HEAD>..HEAD -- <unit paths> <its test paths>` is
  non-empty. A commit that touched the unit or its tests may have added
  the guard.
- `baseline red` and `gate unavailable` expire when HEAD moves at all.
- `blocked` and `refused` expire when the unit's own paths changed since
  the recorded HEAD.
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

- `declutter-ledger.md`: the [ledger](#ledger).
- `declutter-findings.md`: the [findings queue](#findings-queue).
- `declutter-state.md`: one line, `depth: <simple|standard|deep>`, written
  when the depth is first resolved. A missing or unreadable file means
  `simple`.

## Findings queue

A report-only finding confirmed by a refuter is queued, not dropped, so it
can be taken to a decision and resolved. One line per finding:

```text
<fingerprint> | <state> | <HEAD at the time> | <one-line note>
```

The fingerprint is `<repo-relative path>#<item>#<enclosing symbol>`, with
the item named as the catalog names it. It carries no line numbers and no
HEAD, so a rerun of discovery finds the same finding and does not queue it
twice. It is also the key passed back to discovery as `refutedKeys`: the
first column of every `refuted`, `skipped`, `declined`, `undecided`,
`withheld`, `blocked`, and `resolved` line, unchanged, so those items are not re-found and
re-refuted. A cleanup finding (a catalog entry with a proof class) has the
same shape, `<path>#<entry>#<enclosing symbol>`. The symbol is the bare name
of the innermost enclosing function, method, or class, or the declared name
for a top-level declaration or import. Build a key by replacing
each `|` or line break with a space, collapsing runs of whitespace to one
space, removing spaces around each `#`, dropping a trailing `()`, and
trimming the symbol; the workflow does
the same. States:

- `open`: confirmed, not yet put to a decision.
- `decided`: the decision is recorded in the note (the option chosen and who
  chose it); not yet applied.
- `resolved`: applied and landed; the note carries the commit hash.
- `declined`: the decision was to leave it. Never re-queued within a
  session.
- `blocked`: the decided change failed its gates after one follow-up round,
  or its diff review refused it. A block writes no unit ledger entry.
- `undecided`: the advisor gave no clear answer. Never asked again this
  session; listed in the final report.
- `withheld`: a finding an unattended run may not decide (a frozen contract,
  a dependency removal, an orphan-file deletion). Asked at the next attended
  invocation in the same session, and listed in the final report so the
  operator can rerun the skill attended. Session files do not carry across
  sessions.
- `refuted`: a refuter explicitly rejected it. A refuter that returned
  nothing refutes nothing.
- `skipped`: a confirmed cleanup finding the pass left alone because it had
  no guard: a surviving probe site, a failed reachability proof, or a lint
  suppression in a repository with no lint gate. Its key is passed back so
  the finding stops holding a refutation slot.
- `stale`: the entry's path changed after it was recorded.

Expiry, checked at the start of every tick: an `open`, `decided`,
`refuted`, or `skipped` entry whose path shows `git log <recorded HEAD>..HEAD -- <its path>`
non-empty is marked `stale` and never trusted from the file. The next
discovery round re-confirms a stale report-only item (back to `open`) or does
not find it. A stale `refuted` or `skipped` key is only a suppression and is
dropped.
A `stale` entry still present at the following tick is dropped, and its
key is no longer passed back. `blocked` follows the ledger's `blocked` rule.
`resolved`, `declined`, `undecided`, and `withheld` stay for the session.

## Security-boundary paths

A path is a security boundary when any `/`-, `.`-, `_`-, or `-`-delimited
component of it is one of: `auth`, `authn`, `authz`, `oauth`, `session`,
`sessions`, `secret`, `secrets`, `crypto`, `cipher`, `permission`,
`permissions`, `sandbox`, `acl`, `rbac`, `credential`, `credentials`,
`token`, `tokens`, `password`, `passwd`, `jwt`, `tls`, `ssl`, `csrf`, `login`
(case-insensitive). The discovery workflow applies the same list as a
backstop to what its scouts judge. The diff review applies it to every
touched path, and a `security boundary` ledger entry marks the rest.

## Queued units

A discovery round yields a ranked queue the tick works down. The queue saves
ranking, never proof: the guard (mutation probe, reachability proof, ledger
check) reruns at pick time on the current tree, and discovery-time evidence
is never reused.

A queued unit stays only while
`git diff --quiet <scout HEAD> HEAD -- <unit paths> <its test paths> <its evidence paths>`
is clean. Evidence paths are the other files a finding depends on: a
duplicate's partner, the callers of a pass-through or flag argument, the
callers of a rename. A unit that fails the check is dropped to the next
discovery round.

After a landing, re-run the baseline only when `git status --porcelain` is
not empty or HEAD is not the commit this tick just landed. The rerun in
declutter's step 4 already passed on that exact tree.

## Decided changes

A decided finding may change behavior, because the operator chose it. It is
the one kind of change the frozen-behavior rule does not cover, and only as
far as the decision says. The worker applies exactly the option recorded in
the queue entry and nothing else. Its proof is the full gate run: build,
typecheck, lint when the repository names one, and the full suite pass. A
test file changes only if the decision names it (strengthening a hollow test
is the usual case); any other test edit is a refusal. A decided change never
touches a [frozen contract](#frozen-contracts) unless an attended operator's
decision names that contract; a decision recorded by the advisor never does.
Dependency removal and orphan-file deletion are decisions only an attended
operator makes, because they change the supply chain or delete entry points.
