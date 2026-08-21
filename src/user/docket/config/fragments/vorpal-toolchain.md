---
fragment: vorpal-toolchain
version: 2
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

**Exempted — use natively, never via vorpal:** `docket` and `git`.

**This is a preference list, not an availability guarantee.** If
`vorpal run <tool>:<ver>` fails with `artifact alias not found`, fall back to the native
tool or to a covering vorpal tool — e.g. `gofmt` has no standalone alias, so use
`vorpal run go:1.26.0 fmt`. Report the real command you ran, not the one you intended.

## Building and testing inside a sandboxed step

**There is no bare `go` on PATH** — only `go1.26.5`, natively. Use
`vorpal run go:1.26.0 <args>`; the `1.26.0` alias resolves to a binary that reports
`go1.26.5`, which is expected and not a mismatch to chase. Do **not** go hunting for a
binary with `find`, and never `find /` — a RUN-7 executor did exactly that and landed on
the identical artifact the alias resolves to, having paid a filesystem-wide scan for it.

Two denials are normal here and neither means you are doing it wrong:

- A first `go build`/`go test` **downloads modules**, and the sandbox denies the network.
- A **cold** `vorpal run` alias resolves against the registry, which the sandbox also denies.

So run build and test steps with `dangerouslyDisableSandbox: true`, `cd` to the repo root
explicitly in the same call (the tool does not inherit your cwd), redirect `GOCACHE` and
`GOPATH` under `$TMPDIR`, and allow about 300s — a cold build of a real module graph does
not finish in the default timeout. Expect roughly:

```
cd <repo-root> && GOCACHE="$TMPDIR/gocache" GOPATH="$TMPDIR/gopath" go build ./...
```

- **Process substitution is denied**: `diff <(...) <(...)` fails with "Operation not
  permitted" on `/dev/fd/N` — diff temp files under `$TMPDIR` instead.
- **No PyYAML in the executor environment**: `python3 -c "import yaml"` raises
  `ModuleNotFoundError: No module named 'yaml'` — parse YAML with `yq` or Go tooling instead.
