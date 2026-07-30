# Monitor for Orchestration — Maintained Master

`team-lead.md` carries a compact LOCAL copy under its `### Monitor for Orchestration`
header. Deployed at `~/.claude/skills/team-doctrine/references/monitor-orchestration.md` —
repo: `src/user/claude-code/skills/team-doctrine/references/monitor-orchestration.md`.

---

**The discriminator:** default to `Monitor` instead of polling whenever you'd otherwise
block on a long wait (>30s) or repeat a probe more than twice — one event-stream per
occurrence keeps turns cheap. Use `Bash(run_in_background=true)` for one-shot "wait until X
is done"; use Monitor for "tell me each time X happens". Filters must be selective and cover
failure signatures alongside the happy path.

Watch patterns:

- **Phase completion:** `Monitor("docket plan --json --watch", filter: status transitions to
  closed/done)` — prefer docket's native `--watch`/`-w` (with `--interval`) over hand-rolled
  sleep loops.
- **Stall / zombie sweep:** `Monitor("deadman_watch.sh <stall-threshold-minutes>")`
  (`src/user/claude-code/scripts/deadman_watch.sh`) — polls on a timer and emits
  `STALL-CANDIDATE: <role> <issue> unchanged <N>min`, alerting once per stall; one watch
  covers every role `roster_sweep.sh` tracks. `--watch` cannot serve here: it is a
  change-detector, and a genuine stall produces zero change events — only a timer-poll that
  treats an *unchanged* `updated_at` as the signal can fire. Do not reintroduce a
  `--watch`-based stall recipe.
- **CI / PR checks:** `Monitor("gh pr checks <num> --watch", filter: terminal states)`.
- **Inbound Discovered comments:** poll `docket issue comment list <ID> --json` and compare
  the sorted comment-ID set. **Never hash or text-diff rendered CLI output for change
  detection** — rendered docket output embeds relative timestamps that drift on every poll
  (the DKT-345 false-positive loop); compare `--json` IDs, counts, or absolute timestamps.
  A failed docket call treated as "no change" is sound for a blip but blind forever if the
  failure persists — escalate after a bounded run of consecutive failures.

**One wait per condition.** Arm hand-rolled background waits through
`singleton_wait.sh <key> <interval-seconds> <condition-command>`
(`src/user/claude-code/scripts/singleton_wait.sh`), keyed to the condition — the lock makes
re-arming an already-covered key idempotent. A stop-guard nudge is never license to arm a
second wait for a condition an existing poller covers; check for `already-armed key=<key>`
first.
