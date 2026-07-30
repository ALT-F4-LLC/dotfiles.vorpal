# Sandbox Permission-Denial Recovery — Maintained Master

Six agents carry compact, role-scoped `CANONICAL:SANDBOX-RECOVERY-LOCAL` copies. Deployed at
`~/.claude/skills/team-doctrine/references/sandbox-recovery.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/sandbox-recovery.md`.

---

## Sandbox Permission-Denial Recovery

<!-- CANONICAL:SANDBOX-RECOVERY:BEGIN -->

**Core rule: retry once, don't investigate.** When a command fails with a sandbox permission
error matching a known signature below, retry the SAME command once with
`dangerouslyDisableSandbox: true` and continue — do NOT investigate, escalate, or treat it
as a tool/config gap. Retry exactly once; if the second attempt fails for a DIFFERENT
reason, that failure follows the normal "stop and ask" rule. NOT covered by this retry:
hook rejections, merge conflicts, signing errors, genuine compile errors.

| Signature | Cause | Action |
|---|---|---|
| git command fails with a permission error on `.git/index.lock` | sandbox blocks the unlink — not a stale lock | retry once sandbox-disabled; do NOT `rm -f .git/index.lock` blindly |
| `~/Library/Caches/go-build`, `~/.cache/uv` write denials | out-of-repo build caches | retry once sandbox-disabled |
| `operation not permitted` on a resource OUTSIDE the repo during build/test (loopback `bind:`, state-dir writes) | sandbox restriction, not a code defect | re-run sandbox-disabled and treat that run as authoritative BEFORE recording any Blocker |
| TLS/cert failure on the FIRST `gh api`/`curl` call to a non-whitelisted endpoint | sandbox network interception | retry the single call sandbox-disabled — never read as "endpoint unreachable"; do not loop |
| `diff <(cmd1) <(cmd2)` fails `/dev/fd/N: Operation not permitted` | process-substitution vs sandbox | retry sandbox-disabled, or write both sides to `$TMPDIR` files and plain-`diff` |
| kubectl waits | Monitor can't read `~/.kube/config` | bounded `Bash(dangerouslyDisableSandbox: true)` `kubectl wait`, never a Monitor-watched stream |
| hardcoded `/tmp` path → "Operation not permitted" | `/tmp` is write-denied | code fix: write to `$TMPDIR` (this one is not a sandbox retry) |
| Unix-socket daemon repro fails `bind:` | sandbox denies `bind()` and default `$TMPDIR` | run sandbox-disabled; separately, `bind: invalid argument` = path over macOS's ~104-char `sun_path` cap (shorten it), `bind: operation not permitted` = sandbox |
| deterministic failure touching process-group kill/reap or a credential-agent socket (`git commit`: `failed to write commit object` with 1Password/gpg-agent signing) | sandbox blocks signals/agent socket | rerun sandbox-disabled before treating as a regression |
| vorpal-wrapped `bun` via `make` aborts `unable to write files to tempdir` | sandbox tempdir denial | rerun the same `make` target sandbox-disabled; don't edit the Makefile. When piping through `tail`, use `set -o pipefail` — the pipeline's last stage masks the real exit |
| `golangci-lint` fails `no go files to analyze: running go mod tidy may solve the problem` while `go vet`/`go list` pass | denied cache/tempdir write — the suggested fix is a red herring | rerun the SAME command sandbox-disabled; do NOT run `go mod tidy` |

**Connectivity/socket verification — 3-bucket classify, never 2.** An unreachable endpoint
is OPENED / FAILED / INDETERMINATE (sandbox-blocked, TLS artifact, timeout) — a sandbox/TLS
artifact misread as FAILED is a false-GREEN defect; re-run sandbox-disabled to disambiguate
before classifying.

<!-- CANONICAL:SANDBOX-RECOVERY:END -->
