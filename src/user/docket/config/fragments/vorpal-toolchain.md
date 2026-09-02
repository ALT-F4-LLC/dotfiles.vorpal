---
fragment: vorpal-toolchain
version: 5
---
# Vorpal toolchain

Prefer `vorpal run <tool>:<version> <args>` when the tool is in the inventory below; fall
back to natively installed tools when no vorpal-managed equivalent exists.

| Tool | Pinned version | Invocation |
|---|---|---|
| bun | 1.3.10 | `vorpal run bun:1.3.10 <args>` |
| go | 1.26.0 | `vorpal run go:1.26.0 <args>` |
| uv | 0.10.11 | `vorpal run uv:0.10.11 <args>` |
| kind | 0.31.0 | `vorpal run kind:0.31.0 <args>` |
| eksctl | 0.227.0 | `vorpal run eksctl:0.227.0 <args>` |
| kubeseal | 0.34.0 | `vorpal run kubeseal:0.34.0 <args>` |
| talosctl | 1.13.4 | `vorpal run talosctl:1.13.4 <args>` |

**Exempted (use natively, never via vorpal):** `docket` and `git`.

**This is a preference list, not an availability guarantee.** If
`vorpal run <tool>:<ver>` fails with `artifact alias not found`, fall back to the native
tool or to a covering vorpal tool: e.g. `gofmt` has no standalone alias, so use
`vorpal run go:1.26.0 fmt`. Report the real command you ran, not the one you intended.

## Building and testing inside a sandboxed step

**There is no bare `go` on PATH**: only `go1.26.5`, natively. Use
`vorpal run go:1.26.0 <args>`; the patch level the alias reports and the native binary's
differ (`go1.26.0` against `go1.26.5` at last measurement), which is expected and not a
mismatch to chase. Do **not** go hunting for a binary with `find`, and never `find /`: an
earlier executor did exactly that and landed on the artifact the alias resolves to, having
paid a filesystem-wide scan for it.

Build and test SANDBOXED, the same as every other command in your brief: the lift is the
operator's to grant, never through a brief and never on your say-so. Leave the module
cache at its default (no `GOMODCACHE` override, no private module root under `$TMPDIR`):
the conductor runs `go mod download` in the checkout before the first dispatch, so the
shared `GOMODCACHE` is already warm and on the sandbox write allowlist, and a cold module
is the conductor's problem, not a reason to lift the sandbox. Put `GOCACHE` alone under
your step's private directory, the `<TMP>/<STEP-N>.d` your brief had you create (`<TMP>`
is the literal you pinned from `printenv TMPDIR`), per rerun-discipline: build caches live
in a fresh subdirectory unique to your step, never a shared path. A cache under the bare
`$TMPDIR` root belongs to every session on the machine; a past executor found one half
filled by a sibling mid-download and wiped it. `cd` to the repo root explicitly in the
same call (the tool does not inherit your cwd), and allow about 300s: a cold `GOCACHE`
compile of a real module graph does not finish in the default timeout. Expect roughly:

```
cd <repo-root> && GOCACHE="<TMP>/<STEP-N>.d/gocache" vorpal run go:1.26.0 build ./...
```

Two denials remain possible, and neither is a reason to retry unsandboxed:

- **A module the conductor did not warm.** `go: downloading ...` followed by a DNS, TLS
  handshake, or blocked-host error, or by `verifying go.mod: ... pkg/sumdb/...: operation
  not permitted` (the checksum database sits outside the allowlisted module cache), is
  NETWORK GATE BLOCKED per your brief: attempt once, then STOP and report the module `go`
  was fetching, the exact host or path the error names, and the error verbatim. The
  conductor reads that as a cold cache, warms it, and redispatches; it is never a code
  finding, and never yours to fix by deleting a module cache: the shared one is every
  session's, and the only directory you may wipe is your own step's.
- **A cold `vorpal run` alias** resolves against the registry, which the sandbox denies.
  That is the fallback rule at the top of this fragment: use the native tool (`go1.26.5`
  for `go`) and report the real command you ran; a tool with no native cover is the same
  NETWORK GATE BLOCKED stop.

Two more pitfalls, neither about the network:

- **Process substitution is denied**: `diff <(...) <(...)` fails with "Operation not
  permitted" on `/dev/fd/N`; diff temp files under `$TMPDIR` instead.
- **No PyYAML in the executor environment**: `python3 -c "import yaml"` raises
  `ModuleNotFoundError: No module named 'yaml'`; parse YAML with `yq` or Go tooling instead.
