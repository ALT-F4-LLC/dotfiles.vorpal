# Sandbox Permission-Denial Recovery — Maintained Master

**LOCAL-copy consumers:** `senior-engineer.md`, `sdet.md`, `staff-engineer.md`,
`security-engineer.md` — each carries a compact, role-scoped
`CANONICAL:SANDBOX-RECOVERY-LOCAL` copy replacing what was previously 4 divergent inline
doctrines (DKT-183 consolidation). Deployed at
`~/.claude/skills/team-doctrine/references/sandbox-recovery.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/sandbox-recovery.md`. Read on demand
only — never `Skill(team-doctrine)`.

---

## Sandbox Permission-Denial Recovery

<!-- CANONICAL:SANDBOX-RECOVERY:BEGIN -->

**Core rule: retry once, don't investigate.** When a command fails with a sandbox permission
error matching a known signature below, immediately retry the SAME command once with
`dangerouslyDisableSandbox: true` and continue — do NOT investigate, escalate, or treat it as
a tool/config gap; these are known sandbox behaviors. Retry exactly once; if the second attempt
fails for a DIFFERENT reason, that failure follows the normal "stop and ask, do not retry" rule
(senior-engineer.md). Failures unrelated to sandbox restriction — hook rejection, merge
conflict, signing error, a genuine compile error — are NOT covered by this retry.

### `.git/index.lock`

`git commit`/`git diff`/`git status`/`git log` failing with a permission error on
`.git/index.lock` is a sandbox artifact blocking the unlink, not a stale lock left by a
concurrent git process you control. Retry the same command once with
`dangerouslyDisableSandbox: true`. Do NOT `rm -f .git/index.lock` blindly, and do not
investigate further once the retry succeeds.

### Build/tool caches outside the repo

- `~/Library/Caches/go-build` (`go build`/`go test`)
- `~/.cache/uv` (`uv run`, including a `.git` marker-file error inside the cache)

Both are known write-denied paths — retry once with sandbox disabled.

### Loopback socket bind / state-dir writes

An `operation not permitted` / `os error 1` failure on a resource OUTSIDE the repo during
build/test/verify is a sandbox restriction, not a code defect — covers BOTH a loopback port
bind (`httptest`/any local socket: `bind: operation not permitted`) and a state-dir write
(`~/.cache/uv`, `~/.<tool>`: `Failed to initialize cache … Operation not permitted`). Re-run
the exact command with `dangerouslyDisableSandbox: true` and treat that re-run as authoritative
BEFORE recording any Blocker; sibling no-network/in-repo cases passing in the same run
corroborate the diagnosis. Distinct from the `.git/index.lock` case above (git-specific).

### `gh` / `curl` TLS errors

A TLS/cert failure on the FIRST sandboxed call to a non-whitelisted endpoint (`gh api`,
`curl api.github.com`, supply-chain SHA/advisory checks) clears on retry with
`dangerouslyDisableSandbox: true` — don't read it as "endpoint/advisory feed unreachable."
Retry the single call bounded; do not loop.

### Sandbox-interaction pitfall patterns (recurrent, non-path)

These clear on retry with `dangerouslyDisableSandbox: true` (or a foreground call) — each is a
harness artifact, NOT a bug to "fix" in the script:

1. **`!` negation / process-substitution misfires** — a shell `!`-negation or `<(...)` that
   errors inside the sandbox; re-run with sandbox disabled BEFORE editing the script.
2. **gh / curl TLS errors** — see dedicated section above.
3. **kubectl waits** — use a bounded `Bash(dangerouslyDisableSandbox: true)` `kubectl wait`,
   never a Monitor-watched kubectl stream (Monitor can't read `~/.kube/config`).
4. **`$TMPDIR` vs `/tmp`** — always write temp files to `$TMPDIR`; a hardcoded `/tmp` path
   yields "Operation not permitted" — this one is a code fix, not a sandbox retry.
5. **Unix-socket `bind()` + `mktemp`** — the sandbox denies both the default macOS `$TMPDIR`
   and the `bind()` syscall outright, so a socket-listening daemon repro needs
   `dangerouslyDisableSandbox: true`; separately, macOS caps `sockaddr_un.sun_path` at ~104
   chars, so keep any daemon's socket-directory path SHORT (e.g. `/tmp/claude/h.XXXXXX`) —
   distinguish the two failure modes: `bind: invalid argument` = path too long (shorten it),
   `bind: operation not permitted` = sandbox (disable it).
6. **Process-group kill semantics + ambient git commit-signing** — a
   `setpgid`/process-group-kill-and-reap assertion (e.g. in a subprocess-manager test suite)
   can fail 100% deterministically under the sandbox (not flaky), and a test that shells out
   to `git commit` can fail with `fatal: failed to write commit object` when global git config
   requires an ambient GPG/SSH-agent socket (1Password, gpg-agent) that the sandbox blocks;
   both clear with `dangerouslyDisableSandbox: true` — treat a deterministic failure touching
   process signals or a credential-agent socket as a sandbox artifact to rerun before treating
   it as a regression.
7. **bun tempdir denial via `make`** — a vorpal-wrapped `bun install`/`bun test`/`bun
   typecheck` invoked by a Makefile target can abort with `bun is unable to write files to
   tempdir: PermissionDenied`; rerun the same `make` target with `dangerouslyDisableSandbox:
   true` rather than editing the Makefile or installing deps manually. When piping `make` (or
   any command) output through `tail`, the trailing pipeline stage's exit masks the real one —
   use `set -o pipefail` or grep the tail output for the actual pass/fail line rather than
   trusting `$?`.

**Connectivity/socket verification — 3-bucket classify, never 2.** An unreachable endpoint is
OPENED / FAILED / INDETERMINATE (sandbox-blocked, TLS artifact, timeout) — a sandbox/TLS
artifact misread as FAILED is a false-GREEN defect; re-run sandbox-disabled to disambiguate
before classifying.

<!-- CANONICAL:SANDBOX-RECOVERY:END -->
