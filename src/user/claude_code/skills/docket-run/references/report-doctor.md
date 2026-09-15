# Docket engine CLI — `docket report` and `docket doctor`

Covers the `docket report` and `docket doctor` families. Consumer: the
docket-run skill; this file is the single copy of the engine CLI contract for
these verbs, split out of docket's reference.md, whose [JSON envelope
section](../../docket/reference.md#json-envelope--per-verb-data-shapes) still
holds the response-shape contract and parsing traps. Command and flag inventory
verified 2026-09-14 against `docket nightly-112-gcffd10c` (commit `cffd10c`,
built `2026-09-14T21:28:29Z`) by `--help` and `--version` only; behavioral
claims and JSON examples were not re-run.

<a id="contents"></a>

## Contents

- [`docket report`](#report-commands) — 32 lines
- [`docket doctor`](#doctor-commands) — 27 lines
  - [`doctor [--run RUN-N] [--source PATH]`](#doctor-check) — 23 lines

<a id="report-commands"></a>

### `docket report` — `report_executors.go`

`docket report executors` is the cross-run ledger: what became of the steps
each executor hint ran and the panels each voter name sat on, over every run
in a window. Per **executor hint** (the opaque `executor` a step declared):
`runs`, `steps`, `fix_loop_routes`, `override_passes`, `reaps` and
`forced_reaps`, and — over every `aggregate` round whose step declares
`source_field` — the clusters a step with the hint contributed to, as
`unique_clusters` (one member), `corroborated_clusters` (more than one), and
`held_clusters`. Per **voter name**: `runs`, `casts`, casts by verdict, and
how many of the vote steps the name cast on then routed `fix-loop`, were
resolved `override-pass`, or were held-cluster ballots. A sealed, still-open
ballot is withheld here as everywhere. `--json` wraps the two lists with
`runs` (how many the window admitted), `scope` (`project` \| `store`), and
`since` in canonical form when one was given.

**READ-ONLY and operator-facing.** It writes nothing, `next` never consults
it, and nothing here reaches a seat: routing policy stays outside the store,
and a track record fed back into a panel becomes an incentive to agree with
it. Read it at retro; the engine acts on none of it. `reaps`, `forced_reaps`,
and `override_passes` count events, so a ruling `events prune` removed
leaves all three together.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--since` | — | string | `""` | keep runs from `RUN-N` on (a bare number is a run id, never a year), or runs created from a date (`2026-09-01`) or RFC 3339 timestamp on |
| `--all-projects` | — | bool | `false` | read every project's runs instead of the current project's |

Not watch-eligible.

<a id="doctor-commands"></a>

### `docket doctor` — `doctor.go`

<a id="doctor-check"></a>

#### `docket doctor [--run RUN-N] [--source PATH]`

The six checks a conductor clears before the first dispatch of an attach, in
one call. READ-ONLY; no lease reap, no re-pin, no migration beyond what any
read verb performs. Every check ALWAYS RUNS and the return carries one row
per check: `{check, verdict, detail}`, verdict `OK` | `FAIL` | `DRIFT` |
`SKIP` | `WARN`.

| Check | What it answers |
|---|---|
| `seat` | cwd is the git toplevel, not a subdirectory |
| `store` | the store opens read-write from this seat |
| `install-drift` | `--source`'s `src/user/docket/{config,bin}` match `~/.docket/{config,bin}`; SKIP without `--source` |
| `pins` | `run verify-pins` for `--run`; SKIP without it |
| `link-farm` | no symlinks under `<cwd>/.docket/config` (retired link-farm debris, resolving or not) |
| `stragglers` | a REPORT of detached worktrees homed under scratch-shaped paths; WARN or OK, never moves `clean` |

`--json` data: `{clean, skipped, checks}`. `clean` is true only when every
check is OK; `skipped` is true when any check is SKIP, and a `--run` omitted
on an active run reads `clean: false, skipped: true` rather than a clean
report that quietly checked five things.
