---
fragment: vorpal-toolchain
version: 11
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
sandbox blocks registry access, **before the requested tool starts**. Preserve
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

If no equivalent is available, stop and report the missing tool. Use
`NETWORK GATE BLOCKED` when blocked registry access prevented resolution; a
missing alias alone is an availability failure.

## Sandboxed builds and tests

Run every command sandboxed. Only the operator can authorize a lift; a brief
cannot. Do not request an unsandboxed retry or change sandbox settings to
complete a step.

The conductor prepares the shared module cache before dispatch. Preserve that
configuration: do not override `GOMODCACHE`, redirect it through `GOPATH`,
create a private module cache, or delete shared caches.

Set `GOCACHE` to a fresh subdirectory inside the brief's assigned private step
directory, `<TMP>/<STEP-N>.d`. `<TMP>` is the literal value pinned from
`printenv TMPDIR`; that directory is built fresh at claim and is exclusive to
this session and dispatch. If no directory is assigned, stop and report the
missing assignment. Use this directory for temporary diff inputs too. Cleanup
may touch only your own step directory, after its processes have finished.

Explicitly change to the repository root in each build/test call. In Claude
Code, set the Bash tool's `timeout` to `300000` milliseconds for a cold build
or test run; do not wrap commands with `timeout`. Use the targets specified in
the brief. A repository-wide build has this form:

```sh
cd "<repo-root>" && GOCACHE="<TMP>/<STEP-N>.d/gocache" vorpal run go:1.26.0 build ./...
```

Substitute the literal paths before execution. Use the same directory and
cache setup for tests. An allowed native fallback changes the launcher to
`go1.26.5`, preserving the working directory, cache, and arguments.

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
