# Docket engine CLI — `docket gate`, `docket policy`, and `docket registry`

Covers the `docket gate`, `docket policy`, and `docket registry` families, the
single copy of this engine CLI contract, split out of docket's
[reference.md](../../docket/reference.md#json-envelope--per-verb-data-shapes)
(consumer: the docket-run skill), which still holds the response-shape
contract and parsing traps. Verified 2026-10-23 against `docket
nightly-37-gce50f60` (commit `ce50f60`, built `2026-10-23T00:58:29Z`) by
`--help`/`--version` and the docket-cli-audit skill's runtime sweep
(`../../docket-cli-audit/references/cli-fixtures.json`); behavior and JSON
examples reflect the swept commands as of that build.

<a id="contents"></a>

## Contents

- [`docket gate`](#gate-commands) — 24 lines
  - [`gate status STEP-N`](#gate-status) — 20 lines
- [`docket policy`](#policy-commands) — 26 lines
- [`docket registry`](#registry-commands) — 20 lines

<a id="gate-commands"></a>

### `docket gate` — `gate.go`

<a id="gate-status"></a>

#### `docket gate status STEP-N`

One gate step's whole decision state in one small envelope. READ-ONLY;
writes nothing.
STEP-N must be a `type="human"` or `type="vote"` step — any other kind is
`VALIDATION_ERROR`.

`--json` data: `step_status` (the step's effective status); `proposal` (the
vote this gate opened; absent on a human gate or before the proposal opens);
`outcome` — `approved` | `rejected` | `open`, where a proposal retired without
a tally reads `open`; `tally` `{weighted_score, threshold}` (absent without a
proposal); `seats` — every DECLARED voter with `cast` and, once cast, its
`verdict` (absent on a human gate); `missing_seats` — the voters in `seats`
who have not cast, always present once a proposal exists; `target`
`{sha, worktree}` the gate judges, absent when the packet names none. The
whole envelope is under 1 KB for a five-seat panel, so a relay copies it
exactly.

<a id="policy-commands"></a>

### `docket policy`

`docket policy resolve --run RUN-N [--size SIZE] SEAT [SEAT...] --json` reads
the run's **pinned** policy and returns each seat's
`{voter, model, effort, variant}` in the requested order. Use this for named panels instead of independently
reconstructing model selection in the skill or relay.

Pass repeatable `--label` values when issue labels govern sensitivity. A seat
is sensitive when named by `security.nodes` or a supplied label matches
`security.labels`. Resolution applies per-seat forbidden models, the security
rules for sensitive seats, the security variant ceiling, and escalation
fallback. Every seat must resolve or the whole call fails with `NOT_FOUND`;
a run without pinned `policy.toml` also fails. Omitting labels resolves as an
unlabelled row, not as automatic discovery of an issue's labels.

Pass `--size` with one of `trivial`, `small`, `bounded`, `needs-design`, or
`unknown` to route `[sizes]` the way a vote step row with that frozen issue
Size does. A size other than `unknown` that `[sizes]` maps sets every seat's
starting variant ahead of any mapped `--label`. An empty `--size` leaves each
seat on its standing variant. A value outside those five is refused with
`VALIDATION_ERROR` (exit 3), for example `invalid size "bogus": must be one of
[trivial small bounded needs-design unknown]`. Verified 2026-10-11 against
docket commit `3cd04e4`.

<a id="registry-commands"></a>

### `docket registry`

`docket registry audit --json` compares every project's registered workflow
and schema names against the shared corpus. `--project` limits it to a prefix,
name, identity path, or numeric project ID. The verb repairs nothing. With no
config directory under the shared store root it refuses `VALIDATION_ERROR`
(exit 3), since with nothing to scan every registered name would look
orphaned.

| Finding | Meaning and follow-up |
|---|---|
| `behind` | Highest registered version is below the current corpus version. The next activation adopts current definitions under normal validation. |
| `orphaned` | No scanned file declares the registered name. Review before deciding to deprecate a workflow: a name defined only in a repository's `.docket/config` is never scanned and always reads as orphaned. |

The corpus is scanned once from the shared store root's `config/` directory,
reported in `roots`. The audit never reads a repository's `.docket/config`,
so no checkout's local additions are scanned. An orphan report alone does not authorize deletion
or prove a different project's local workflow is obsolete.
