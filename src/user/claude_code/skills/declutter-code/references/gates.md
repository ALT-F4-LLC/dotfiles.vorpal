# Gates

How a declutter pass finds the repository's checks, proves a site is
guarded, decides what is frozen, and remembers what it skipped. The skill
points here instead of restating these; a change to a rule lands here once.

## Discovery

Find the commands the repository itself uses, in this order, and stop at
the first source that names a command for each of build, typecheck, test,
and format. Never invent a command the repository does not name.

1. `CLAUDE.md` or `AGENTS.md` at the root or under the unit's directory: an
   instruction that names a test or build command wins.
2. A task runner: `justfile`, `Makefile`, `Taskfile.yml`, `mise.toml`,
   `package.json` scripts, `composer.json` scripts. Prefer a recipe named
   `test`, `check`, `build`, `lint`, `typecheck`, `fmt`, or `format`.
3. Continuous integration: `.github/workflows/*.yml`, `.gitlab-ci.yml`,
   `.circleci/config.yml`. The commands the pipeline runs are the commands
   the repository trusts.
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
   | `*.csproj`, `*.sln` | `dotnet build` | same | `dotnet test` | `dotnet format <project>` |

The formatter is a layout tool, never a lint autocorrector: an option
that rewrites code rather than whitespace (`rubocop -a`, `eslint --fix`,
`ruff check --fix`) is not a formatter here. It runs on the touched files
before the rerun, so the tree that passes the gates is the tree that is
committed.

A repository with no test command at all has no guard for live-code
transformations: only `reachability` entries can be applied, and the report
says the tree has no test suite. A repository whose discovered command
needs a service, network, or credential this environment lacks has a gate
that cannot run: report which, and rest.

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
   nothing guards it: ledger the site as `no coverage` and leave it alone.
   A run that errors for a reason unrelated to the change (a flaky test, a
   timeout) is retried once; a second error is treated as `no coverage`.

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
of these near the unit, the symbol is treated as reachable and left alone.
After the removal, build, typecheck, and the full suite must pass.

## Inert edits

An `inert` edit cannot change what the program does: a comment, a banner, a
docstring the runtime does not expose, a lint suppression the linter no
longer needs, a compile-time-only cast the type checker no longer needs.
No probe and no reachability search; build, typecheck, and the linter
must still pass afterwards, and the full suite runs once at the end of the
pass with everything else. Inert edits and reachability removals are the
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
and a new session starts with none, which is intended: the operator's own
commits between sessions are what change the answers.
