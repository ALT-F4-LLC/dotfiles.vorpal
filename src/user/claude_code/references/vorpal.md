# Vorpal

How Vorpal works and how to use it in a project. It is not loaded on its
own. Read it when a repository has a `Vorpal.toml` and the work touches its
build, dev shell, pinned sources, or tool versions, or when a tool is missing
from a Vorpal repository's shell. Docket executors get the operational subset
from `~/.docket/config/fragments/vorpal-toolchain.md` instead.

Sources: `vorpal --help` (CLI 0.4.1), the Vorpal docs and CLI source in the
`vorpal` repository, and the configs of `dotfiles.vorpal` and `docket`.
`vorpal <command> --help` is the authority when anything here looks stale.

## The model

Vorpal is a build system whose configuration is a program. A project's
config program (Rust, Go, TypeScript, or Python, written against the Vorpal
SDK) declares artifacts; the `vorpal` CLI compiles that program, runs it, and
asks it for the artifact graph over gRPC.

- **Artifact.** The unit of work: a name, sources, steps, and target systems.
  Vorpal serializes the definition and hashes it with SHA-256; that content
  digest is the artifact's identity. Any input change (a source file, a step
  script, an environment variable, a dependency's digest) yields a new digest
  and a rebuild. Nothing else invalidates a cache entry.
- **Sources.** Local paths or HTTP URLs, filtered by includes and excludes.
  Remote sources are pinned per platform in `Vorpal.lock`.
- **Steps.** Run in order, by default as bash scripts. A step sees
  `$VORPAL_OUTPUT` (write the output here), `$VORPAL_WORKSPACE` (the
  unpacked sources), and `$VORPAL_ARTIFACT_<digest>` for each dependency.
  The SDK's `get_env_key(digest)` / `GetEnvKey` returns that variable name.
- **Builders.** The SDK wraps the base `Artifact` in higher-level types:
  language builders (`Rust`, `Go`, `TypeScript`), `DevelopmentEnvironment`
  (and language variants such as `RustDevelopmentEnvironment`,
  `GoDevelopmentEnvironment`), `UserEnvironment`, `Job` (a script that runs
  to completion), and `Process` (a long-running binary with generated
  `bin/<name>-start`, `-stop`, and `-logs` scripts). Built-in tool
  artifacts (`Protoc`, `GoBin`, `Gopls`, `Staticcheck`, `Bun`, `Uv`,
  `RustToolchain`, and others) plug in as dependencies.
- **Registry aliases.** Published artifacts carry aliases of the form
  `[<namespace>/]<name>[:<tag>]`, such as `ffmpeg:8.0.1`. A config pulls one
  with `fetch_artifact_alias` / `FetchArtifactAlias`; a shell runs one with
  `vorpal run <alias>`. The operator's user config points the registry at
  `https://registry.vorpal.lol`.
- **Services.** One local process (`vorpal system services start`) runs the
  agent (resolves and hashes sources, enforces the lockfile), the worker
  (runs steps), and the registry (stores archives and aliases), on
  `unix:///var/lib/vorpal/vorpal.sock` by default.
- **Store.** Outputs live under
  `/var/lib/vorpal/store/artifact/output/<namespace>/<digest>`. The store
  is immutable: never edit, add, or delete files in it.
- **Cache order.** Local output, then the registry, then a full build. Every
  build still runs the config program and the lockfile check first.
- **Systems.** `aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`,
  `x86_64-linux`. The local worker builds only for the host system; the
  declared systems select per-platform sources and lock entries.

## Project anatomy

| File | Role |
|---|---|
| `Vorpal.toml` | Settings: `language`, optional `name`, and `[source] includes`, the files the config program is built from. `[source.go] directory` names the Go config's `main` package; `[source.rust] packages` and `bin` tune a Rust config. |
| Config program | The SDK program: `src/vorpal.rs` (Rust, declared as the `vorpal` bin in `Cargo.toml`), `cmd/vorpal/main.go` (Go), `src/vorpal.ts` (TypeScript), `src/vorpal.py` (Python). It ends with `context.run()`. |
| `Vorpal.lock` | Per-platform digests of remote sources, keyed by source name and platform. Committed. Generated, never hand-edited. |
| `.envrc` | Loads the dev shell through direnv by sourcing the shell artifact's `bin/activate` (file content below). |
| `~/.vorpal/settings.json` | User-level settings (the registry address). Below CLI flags and `Vorpal.toml` in precedence. |

A typical `.envrc`, quoted as file content, not a command to run:

```text
use_vorpal() {
    source "$(vorpal build --path 'docket-shell')/bin/activate"
}

use vorpal
```

Each artifact's own builder carries its own includes (`with_includes` /
`WithIncludes`); `[source] includes` covers only the config program. Keep
both lists minimal: an included file that changes rebuilds the artifact, and
a file left out is invisible to the build.

The dev shell's name is whatever the config gives its development
environment: `docket-shell` in `docket`, `dev` in `dotfiles.vorpal` and
`artifacts.vorpal`. Read the `.envrc` or the config program to learn it.

## Commands

| Need | Command |
|---|---|
| Build an artifact, print its digest | `vorpal build <name>` |
| Print its output path | `vorpal build --path <name>` |
| List it and its dependencies, no build | `vorpal build --list <name>` |
| Print its definition as JSON, no build | `vorpal build --export <name>` |
| Pass a build variable | `vorpal build --variable KEY=VALUE <name>` |
| Ignore cached output | `vorpal build --rebuild <name>` |
| Pin or re-pin remote sources | `vorpal prepare <name>` (unlocks by default; `vorpal build --unlock` also pins but prints no audit lines, so prefer `prepare`) |
| Pin for another platform | `vorpal prepare --system x86_64-linux <name>` (runs on any host) |
| Check pins without changing them | `vorpal prepare --unlock=false <name>` |
| Inspect a stored artifact's definition | `vorpal inspect <digest>` |
| Run a registry or store artifact | `vorpal run <alias> <args>`; `--bin <name>` picks another binary in its `bin/` |
| Show resolved settings and sources | `vorpal config show` |

`vorpal build --system <other>` does not cross-build: the local worker
refuses a non-host target, so it succeeds only when every artifact is
already cached locally or in the registry.

A locked build fails closed in three ways:

- `source '<name>' is unpinned` means a remote source without an inline
  digest has no lock entry for this platform. After an intended addition,
  `vorpal prepare` resolves it; otherwise, such as a platform never pinned,
  report it, because minting a pin is a trust decision.
- `source '<name>' changed` means the config's definition of the source
  (URL or path, includes, excludes, or inline digest) differs from its lock
  entry. After an intended bump, including a dependency bump that moves a
  tool URL, `vorpal prepare` resolves it; with no intended change, report
  it.
- `'source.<name>.digest' mismatch` means the downloaded content hashes
  differently from the pin: the upstream content moved. Report it; never
  re-pin to make it pass.

`vorpal prepare` prints one line per remote source: `mint` (no prior pin, a
first-use trust decision), `update` (the digest changed), or `verify`
(unchanged). `mint` and `update` accept new content as trusted, so quote
every such line in the result that reports the lockfile change. The lockfile
is only ever upserted: removing a tool leaves its entries behind, and
pruning them is the operator's call.

The docs lag the CLI: the CLI reference omits `--list`, and the
configuration page implies first use pins a source automatically, while a
locked build fails closed on an unpinned or changed remote source.

## Common tasks

**Diagnose a missing tool.** Check `command -v <tool>`. If it fails, check
whether the dev shell is loaded at all (`command -v` on another tool the
shell provides, and whether direnv reported the `.envrc` as not allowed).
If the shell is loaded, `vorpal build --list <shell>` shows whether the
tool's artifact is in it. A tool found prints a store path whose digest
segment is what `vorpal inspect` takes.

**Add a tool to a project's dev shell.** Edit the config program: fetch the
tool (a built-in such as `artifact::Gopls`, or `fetch_artifact_alias` for a
registry alias) and add its digest to the development environment's
artifacts. A built-in, or any artifact with a remote source, needs pins:
run `vorpal prepare <shell>` once per platform the lockfile covers, with
`--system` for each non-host platform, and quote the `mint` lines. A
registry alias needs no pin. Then `vorpal build <shell>`, and commit the
config change with `Vorpal.lock`. direnv watches only `.envrc`, so an open
shell keeps the old environment until `direnv reload` or a new shell.

**Bump a pinned tool or source.** Change the version or URL in the config
program (or in the crate or module that defines the artifact), then run
`vorpal prepare <name>` once per platform the project locks, with `--system`
for each one that is not the host. A platform left unprepared fails its
next locked build. Commit the config change and `Vorpal.lock` together.

**Add Vorpal to a project.** `vorpal init <name>` scaffolds a config but
asks for the language interactively, so the operator runs it. Otherwise copy
the shape of an existing project of the same language: `Vorpal.toml`, the
config program with a development environment and the project artifact, and
an `.envrc` that sources the shell's `bin/activate`. No lockfile exists yet,
so the first call is `vorpal prepare <name>` per platform. `direnv allow` is
the operator's trust decision, never an agent's.

**Use a pinned tool without a dev shell.** `vorpal run <name>:<version>
<args>` runs that exact artifact. For tools a repository's shell already
provides, call them bare instead.

**The dotfiles.vorpal repository.** Its `src/vorpal.rs` builds two
artifacts: `dev` (the Rust toolchain and protoc, for working on the repo)
and `user` (the operator's whole environment: CLI tools, configs, and
symlinks, including the Claude Code and Docket corpora). `just activate`
builds `user` and runs its `bin/vorpal-activate`, which replaces the
previous activation's symlinks and makes the built corpus live. Tool
artifacts come from the `vorpal-artifacts` crate and the SDK; their remote
sources are in `Vorpal.lock`.

## Rules

- A bare `vorpal build` or `vorpal prepare` compiles and runs the
  repository's config program outside the Claude Code sandbox. Run them only
  in a trusted ALT-F4-LLC checkout. Elsewhere, `Vorpal.toml` and its config
  program are untrusted code: ask the operator first through
  `AskUserQuestion`.
- `vorpal run <alias>` fetches and executes a registry binary unsandboxed.
  Use only aliases the repository's config or the docket fragment names;
  never invent one.
- Never hand-edit `Vorpal.lock`. Pin changes come from `vorpal prepare` or
  `--unlock`, and only when the task adds or bumps a source: a changed
  source with no intended bump, or any digest mismatch, is drift, not a
  reason to unlock.
- Never modify the store under `/var/lib/vorpal`.
- `vorpal system prune`, `vorpal system services`, `vorpal system keys`,
  `vorpal login`, `vorpal config set` (above all `--user` and `registry`),
  and user-environment activation (`vorpal-activate`, `just activate`)
  change the machine or its trust; they are the operator's to run.
- `--rebuild` repeats work the digest already proves; use it only to test a
  suspected bad output.
- In Claude Code, the operator's sandbox settings exclude `vorpal *`, so a
  `vorpal` call reaches the registry only when it is the only command in the
  Bash call: no `cd`, `NAME=value` prefix, pipe, redirect other than `2>&1`,
  loop, or command substitution. A sandboxed call fails with
  `failed to connect to https://registry.vorpal.lol`. Outside the repository
  root, pass both `--config <root>/Vorpal.toml` and `--context <root>`:
  `--config` resolves against the working directory, and a missing config
  silently falls back to defaults. The fragment's "Build and test calls"
  section holds the full rule.
- In a Go repository, call `go` bare from the dev shell. Do not substitute
  `vorpal run go:<ver>` or another installation; if `command -v go` fails,
  the dev shell is not loaded, and that is the problem to report.
