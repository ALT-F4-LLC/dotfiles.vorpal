# evolve-model-distribution fixture harness

Synthetic `projects/<sess>/subagents/` tree (all content fabricated — no real
session transcripts) so `spawn_model_join.sh` (the `distribution-auditor`
per-spawn join, codified as a script) and the categorization logic can be
dry-run against deterministic, re-runnable input instead of a hand-simulated
one. Point the script's `[session-path]` argument at `test/fixtures/projects`
to exercise it, e.g.:

```bash
~/.claude/scripts/spawn_model_join.sh 7 .claude/skills/evolve-model-distribution/test/fixtures/projects
```

## `fixture-session-divergent/` — one pair per divergence class

| Pair (`agent-a<role>-<hash>`) | `.meta.json.model` | resolved (`.jsonl`) | Expected classification |
|---|---|---|---|
| `reviewer-2-a1b2c3d4e5f6a7b8` | `opus` | `claude-opus-4-8` | **Clean** — pinned opus, canonical for `reviewer-2` is opus, no divergence. |
| `tdd-author-b2c3d4e5f6a7b8c9` | `sonnet` | `claude-sonnet-4-6` | **Under-powered defect** — `tdd-author*` hard floor is opus (never-below-opus rule); explicitly pinned sonnet, so RUNTIME-DISCIPLINE REPORT, not a file-edit. |
| `impl-DKT-99-c3d4e5f6a7b8c9d0` | absent (no `model` key) | `claude-opus-4-8` | **Fallback-drift (corroborated)** — `model=` omitted at spawn, resolved landed on opus, over the sonnet canonical for `impl-*` Small/Medium. |
| `impl-DKT-77-d4e5f6a7b8c9d0e1` | `opus` (present) | `claude-opus-4-8` | **Permitted-upgrade** — explicitly pinned opus on a sonnet-canonical `impl-*` role; over-canonical but intentional, so an over-powered/cost-waste Trial-only candidate, never drift. |
| `impl-scorer-e5f6a7b8c9d0e1f2` | `sonnet` | `<synthetic>` (x2) + `claude-sonnet-4-6` | **Filter target** — the `<synthetic>` sentinel turns must be dropped by `grep -v '<synthetic>'`; only `claude-sonnet-4-6` counts, matching canonical (clean once filtered). |
| `impl-DKT-66-f6a7b8c9d0e1f2a3` | n/a — `.meta.json` is truncated/non-JSON | n/a — `.jsonl` is zero-byte | **Malformed-file case** — meta parse failure degrades role/requested to `<unparseable>`; the zero-byte jsonl degrades resolved to `<none>`; the loop emits this pair as an `<unparseable>`/`<none>` row and keeps running rather than aborting the cycle. |

## `fixture-session-noop/` — no-op cycle

One clean pair (`verifier-1a2b3c4d5e6f7a8b`, pinned opus, canonical opus) in a
session of its own, so it can be pointed at in isolation to assert "no
divergences — no changes" when nothing else is in scope.

## `fixture-session-empty/`

An empty `subagents/` dir (`.gitkeep` only, no `agent-a*` pairs) — asserts the
empty-LOCAL-window path: SKIP the edit phases and report "no local metrics —
cannot ground edits".

## Mimir mock/absent path

Mimir is an external HTTP dependency (no local fixture file). Exercise the
`"Mimir metrics unavailable: <reason>"` fallback deterministically by pointing
the collection at an address that always fails closed, e.g.
`MIMIR_BASE=http://127.0.0.1:1` (nothing listens there — connection refused)
in place of `https://mimir.bulbasaur.altf4.domains`, or by skipping the Mimir
arm entirely (a `--no-remote` collection run) and asserting LOCAL-only
proceeds with cost-magnitude claims marked "unquantified".
