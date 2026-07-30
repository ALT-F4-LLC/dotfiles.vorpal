# Review evidence gates — never attribute from a false signal

Read when a load-bearing claim is about to rest on a test result, an empty diff, or a
green CI status. Each is a way the signal lies:

- **Sandbox-signature-before-attribution.** Before attributing a test failure to the
  reviewed diff, check the failure text for sandbox signatures (`operation not permitted`,
  bind/socket errors) — the sandbox blocks even loopback listeners; only a fresh
  UNSANDBOXED run is citable as a real failure.
- **Stale-cached-test-results.** A bare test re-run can report a stale `(cached)` OK from
  someone else's pass — require `-count=1` (or the toolchain's cache-bypass equivalent)
  before citing a green run as evidence the reviewed code passes.
- **Empty-diff triage triple.** An empty `git diff` on files whose content demonstrably
  changed means STAGED or committed, not "no changes" — run `git status --short`,
  `git diff --staged --stat`, `git log --oneline -3` before concluding, and file
  unauthorized staging itself as a process finding.
- **Hollow-green CI.** Green CI proves an AC only if the job proves the tests RAN: verify
  any artifact a ruling depends on is actually committed (`git ls-files <path>` /
  `git check-ignore -v <path>`), and treat skip-gated suites as hollow-green hazards.

**Finding-sourcing (anti-fabrication).** Write each per-file finding ONLY from that file's
COMPLETE diff rendered in a clean call this turn — never from memory of "what this kind of
change usually does," and never from a cancelled or empty batch result. If a parallel
batch member errors, the harness CANCELS every later call in that batch; an
empty/cancelled result means the file is UNVERIFIED, not unchanged — re-issue the probe as
a solo call before asserting anything about it. Prefer `git diff` / `Read` over `grep -n`
for load-bearing verification (`grep -n` has returned wrong line content). An
evidence-anchored line that is actually fabricated ("VERIFIED from real diff" for a hunk
that does not exist) is worse than an honest "did not verify."
