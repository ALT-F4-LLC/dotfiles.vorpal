---
fragment: vorpal-toolchain
version: 1
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
