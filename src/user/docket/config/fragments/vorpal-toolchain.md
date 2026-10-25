---
fragment: vorpal-toolchain
version: 15
---
# Vorpal toolchain

Prefer these Vorpal aliases. They pin the requested artifact. Availability is
not guaranteed, and native fallback may use a different version.

| Tool | Pinned alias | Invocation |
|---|---|---|
| bun | 1.3.10 | `vorpal run bun:1.3.10 <args>` |
| go | 1.26.0 | `vorpal run go:1.26.0 <args>` |
| uv | 0.10.11 | `vorpal run uv:0.10.11 <args>` |
| kind | 0.31.0 | `vorpal run kind:0.31.0 <args>` |
| eksctl | 0.227.0 | `vorpal run eksctl:0.227.0 <args>` |
| kubeseal | 0.34.0 | `vorpal run kubeseal:0.34.0 <args>` |
| talosctl | 1.13.4 | `vorpal run talosctl:1.13.4 <args>` |

Use `docket` and `git` natively, never through Vorpal. This exemption concerns
tool selection only; their commands still run sandboxed.

For an unlisted tool, use a listed tool that provides the same operation, or
use the native tool. For example, package formatting can use
`vorpal run go:1.26.0 fmt <packages>`. This writes package files; it does not
replace file-level `gofmt` operations, stdin processing, or formatter-specific
flags.

## Fallback

Use native fallback only when Vorpal is unavailable, reports
`artifact alias not found`, or cannot resolve/fetch the artifact because the
sandbox blocks registry access after the bare form of the call (Build and
test calls) has been tried, **before the requested tool starts**. Preserve
the operation, arguments, and scope. If execution may have started, do not use
native fallback; follow the brief's failure procedure. Never retry a build,
test, or other tool failure through another installation merely because it
failed.

On this host, bare `go` is absent from PATH; its native fallback is
`go1.26.5`. The managed alias reported `go1.26.0` at the last measurement. This
difference is expected; do not change versions to reconcile it. Use known
executable names or `command -v` for availability checks; do not hunt for
binaries with `find`, especially `find /`. Do not invent aliases or install
replacements.

If no equivalent is available, stop and report the missing tool. A `vorpal`
call that prints `failed to connect to https://registry.vorpal.lol` ran
sandboxed, which means the call was not a bare `vorpal` command (see Build
and test calls). That result is a sandbox refusal: disclose it as
completion-gates requires, then reissue the call once in the bare shape and
report the reshaped call beside it. Use `NETWORK GATE BLOCKED` only when the
bare form still cannot reach the registry, or when no bare form exists for
the call; a missing alias alone is an availability failure.

## Build and test calls

The operator's sandbox settings exclude `vorpal *`, because Vorpal is a
trusted builder and executor with a sandbox of its own: a `vorpal` command
runs outside the Claude Code sandbox when it is the only command in the Bash
call. Anything else in the call keeps the whole call sandboxed: a `cd`,
`pushd`, or `popd`, a `NAME=value` prefix, a redirect other than `2>&1`, a
pipe into another command, a loop, a subshell, or a command substitution such
as `$(git rev-parse --show-toplevel)`. Spell every `vorpal` call as one bare
command with literal arguments, and pass the directory through the tool's own
flag: Go's `-C <dir>` works for `build`, `test`, `vet`, `fmt`, and `env`. A
command outside the operator's exclusion list, `make` among them, runs
sandboxed. Only the operator can authorize a lift; a brief cannot. Do not
request an unsandboxed retry or change sandbox settings to complete a step.

The conductor prepares the shared module cache before dispatch. Preserve that
configuration: do not override `GOMODCACHE`, redirect it through `GOPATH`,
create a private module cache, or delete shared caches.

Leave `GOCACHE` at its default: the default Go build cache is in the sandbox
write allowlist, and a `NAME=value` prefix on a command matches no allow rule,
goes to the auto-mode classifier, and keeps the call sandboxed. Put
temporary diff inputs in the
brief's assigned private step directory, `<TMP>/<STEP-N>.d`. `<TMP>` is the
literal value pinned from `printenv TMPDIR`; that directory is built fresh at
claim and is exclusive to this session and dispatch. Cleanup may touch only
your own step directory, after its processes have finished.

Name the repository root in each build/test call with Go's `-C` flag, the
first flag after the subcommand; do not prefix the call with `cd`. In Claude
Code, set the Bash tool's `timeout` to `300000` milliseconds for a cold build
or test run; do not wrap commands with `timeout`. Use the targets specified in
the brief. A repository-wide build has this form:

```sh
vorpal run go:1.26.0 build -C "<repo-root>" ./...
```

Substitute the literal path before execution. Run tests the same way
(`vorpal run go:1.26.0 test -C "<repo-root>" ./...`). An isolated
executor's working directory resets to its worktree before every call, so
the bare form already runs at the root there; `-C` is still correct. A
shared executor's working directory may be elsewhere, so `-C` is required.
A tool with no directory flag has no bare form that also changes directory.
An isolated executor runs it bare from its worktree. A shared executor runs
`cd "<repo-root>" && vorpal run <alias> ...` once, sandboxed; if that call
cannot reach the registry, report `NETWORK GATE BLOCKED` or take the
permitted native fallback with the same `cd`. Run the repository's own gate
targets (`make fmt`, `make vet`, `make lint`, or the targets the brief names)
each as its own Bash call with no assignment prefix, never through `sh -c` or
another interpreter: a command handed to an interpreter is refused outright.
The permission rules clear a bare `make` and `vorpal run go:1.26.0`. An
allowed native fallback changes the launcher to `go1.26.5`, preserving the
`-C` directory and arguments.

Go can select or download another toolchain according to its existing
configuration and `go.mod`/`go.work`. Do not change that configuration to
force a version or bypass a download failure.

## Failure handling and reporting

- **Module or Go toolchain retrieval fails with a DNS, TLS, or blocked-host
  error:** stop the step after that attempt and report `NETWORK GATE BLOCKED`.
  Include the requested module/toolchain and version when shown, the exact
  host or path named, and the error verbatim. The conductor handles
  preparation and redispatch. Do not treat this as a code finding or assume
  the error proves a cold cache.
- **Filesystem access is denied:** report the blocked path and exact error.
  Do not relabel it as a network failure, relocate shared caches, or retry
  unsandboxed.
- **Other failures:** follow the brief's failure procedure. Preserve the
  diagnostic; do not infer an alias or network problem from a nonzero exit
  alone.

Report the actual command, outcome, and any fallback reason. For Go
validation, record the selected `go version` once from the repository using
the chosen launcher; the alias alone does not establish the compiler version
used.

## Host-specific command pitfalls

- Process substitution (`diff <(...) <(...)`) is denied on this host.
  Write inputs to separate files inside your private step directory, then
  diff those files.
- This host has no `timeout` executable. Set the tool-call timeout instead.
- This host has no PyYAML. Use an already available YAML parser, such as
  the installed `yq` with its supported syntax or existing project Go
  tooling; do not assume `import yaml` works or add dependencies just to
  parse YAML.
- Shell `grep` resolves to a `ugrep` shim whose matching and ignored-file
  behavior differ from the gate scripts. For counted or gated searches, use
  `/usr/bin/grep` with the gate's exact pattern, flags, and file scope. Do not
  substitute a search tool whose defaults change which files or matches are
  counted.
