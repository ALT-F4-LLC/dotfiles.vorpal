# Docket engine CLI — `docket gate`, `docket policy`, and `docket registry`

Covers the `docket gate`, `docket policy`, and `docket registry` families.
Consumer: the docket-run skill; this file is the single copy of the engine CLI
contract for these verbs, split out of docket's reference.md, whose [JSON
envelope
section](../../docket/reference.md#json-envelope--per-verb-data-shapes) still
holds the response-shape contract and parsing traps. Command and flag inventory
verified 2026-09-14 against `docket nightly-112-gcffd10c` (commit `cffd10c`,
built `2026-09-14T21:28:29Z`) by `--help` and `--version` only; behavioral
claims and JSON examples were not re-run.

<a id="contents"></a>

## Contents

- [`docket gate`](#gate-commands) — 25 lines
  - [`gate status STEP-N`](#gate-status) — 21 lines
- [`docket policy`](#policy-commands) — 17 lines
- [`docket registry`](#registry-commands) — 16 lines

<a id="gate-commands"></a>

### `docket gate` — `gate.go`

<a id="gate-status"></a>

#### `docket gate status STEP-N`

One gate step's whole decision state in one small envelope, replacing the
scatter of `step show`, `vote show` and a re-derived outcome that wave.js's
probes used to relay round trip by round trip. READ-ONLY; writes nothing.
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

`docket policy resolve --run RUN-N SEAT [SEAT...] --json` reads the run's
**pinned** policy and returns each seat's `{voter, model, effort, variant}` in
the requested order. Use this for named panels instead of independently
reconstructing model selection in the skill or relay.

Pass repeatable `--label` values when issue labels govern sensitivity. A seat
is sensitive when named by `security.nodes` or a supplied label matches
`security.labels`. Resolution applies per-seat forbidden models, the security
rules for sensitive seats, the security variant ceiling, and escalation
fallback. Every seat must resolve or the whole call fails with `NOT_FOUND`;
a run without pinned `policy.toml` also fails. Omitting labels resolves as an
unlabelled row, not as automatic discovery of an issue's labels.

<a id="registry-commands"></a>

### `docket registry`

`docket registry audit --json` compares every project's registered workflow
and schema names against the shared corpus. `--project` limits it to a prefix,
name, identity path, or numeric project ID. The verb repairs nothing.

| Finding | Meaning and follow-up |
|---|---|
| `behind` | Highest registered version is below the current corpus version. The next activation adopts current definitions under normal validation. |
| `orphaned` | No scanned file declares the registered name. Review the reported roots before deciding to deprecate a workflow: another project's local config may be absent from this invocation's scan. |

The corpus is scanned once using this invocation's roots, including the current
checkout's local additions. An orphan report alone does not authorize deletion
or prove a different project's local workflow is obsolete.
