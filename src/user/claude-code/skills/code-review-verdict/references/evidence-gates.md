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

The gates above guard against false REASSURANCE — a signal that wrongly says the code is
fine. The gates below guard the opposite direction: a self-built probe, control, or
derived exclusion whose failure mode is a false FINDING — a signal that wrongly says the
code is broken.

- **Probe-instrument gates (self-built probes).** A grep or regex you write to detect a
  condition tests your PHRASING of the condition, not the condition itself — Read the
  actual target region before trusting a probe's zero-hit result, don't trust the probe
  alone. Never cache a line number across an edit: a stale anchor fails toward a false
  all-zero column that reads as an authoritative finding, not toward an error.
- **Paired positive controls (self-built probes).** Pair every negative probe with a
  positive control in the same run — "the detector missed my planted input" and "my
  fixture was inert" are the identical observation until a known-positive case confirms
  the probe fires at all. A predicted finding is the LEAST trustworthy result a probe can
  return: false-negative artifacts are self-limiting (silence invites a second look), but a
  false-positive artifact reads as diligence and passes review unchallenged — the asymmetry
  means a "found it" result needs MORE scrutiny than a "found nothing" result, not less.
  When a probe claims a mutation changed an artifact, prove `recomputed != recorded`
  directly — never trust the checker's silence as proof the mutation landed. Trace root
  cause BEFORE writing a finding, even though this is hardest exactly when the finding
  confirms what you expected. Use varied, realistic fixture values — repeated-character
  fixtures (`aaaa...`, `0000...`) are silently suppressed by placeholder filters and will
  produce a false negative that looks like a clean pass.
- **Severity cap when no positive control fired (ratified).** A probe-sourced finding
  with no positive control run in the same pass is not disqualified, but it is capped: a
  Critical/High finding with no fired positive control is emitted at ONE BAND LOWER than
  its uncapped severity — never dropped, never silently kept at full severity. The cap
  never crosses a merge-hold floor: a capped finding that would otherwise sit at Critical
  or Blocker stays merge-holding regardless of the one-band reduction, and a Hard Gate
  (G1-G5 / security-track equivalents) is never capped by this rule — a Hard Gate fires at
  its mechanical severity regardless of control status. Disclose the cap with this fixed literal, verbatim, in the finding itself: "no positive control fired in this run — severity capped pending a control run". Mirror the same finding, capped, into the
  Required Mitigations section — the cap changes severity, not whether the finding is
  actionable. Rider: a later round that runs the missing positive control and confirms the
  finding restores it to full uncapped severity; a later round whose control run comes back
  negative (fixture inert or condition absent) downgrades or withdraws the finding instead,
  per the paired-positive-controls gate above.
- **Derived-control / inherited-exclusion gate.** Enumerate the source tool's SKIP
  SEMANTICS (pragma-marker matches, path/fixture excludes, self-path excludes) from its
  code — literal greps (`git log -S'<literal>'`, `grep -rn '<literal>' .`) are cited as
  EVIDENCE for each enumerated skip, never used as the search space itself: a
  verbatim-literal grep misses a re-implemented skip with a different marker and identical
  semantics, and `git log -S` counts occurrence-CHANGES, so it can return a packaging
  rewrite rather than the introducing commit. A pre-existing occurrence proves the
  exclusion is INHERITED from a source tool, not authored fresh in this diff — different
  CORPORA, not merely different policies, is the operative distinction, because an
  attacker-controlled corpus change can flip an inherited opt-out without touching the
  diff under review. Severity: uncontrasted corpora is High; Critical when the control is
  the sole secret/credential enforcement. `N/A — no detection control in diff` is a CLAIM
  the peer security seat verifies, not a free pass.
