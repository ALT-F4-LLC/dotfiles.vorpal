# M4 pre-registration — the v1 shadow run (07 §4)

Ratified by the operator 2026-08-05. Written BEFORE activation; nothing here
may be revised after the run starts. Reviewer: the design-context session.

## 1. The change

Four real engine fixes, standard-change shape, in the docket repo itself
(first permitted self-hosting, 09 §M4):

- DKT-69 — `step fail` accepts `--metadata` (parity with complete; the
  mergeMetadata design is already shaped for it)
- DKT-67 — a ready `type="human"` gate step must not block Stop
  (park-and-resume contradiction)
- DKT-66 — `run pause` does not clear a stop (steps revert to pending;
  guard stop reads step status)
- DKT-65 — `guard spawn` gains `--active` / all-runs semantics (the
  two-concurrent-runs blind spot)

None is test-infra-labeled; none is doc-typed (F-W1/DKT-73 exclusions
honored by construction). The planner adopts these tracker entries into run
issues with verbatim ACs.

## 2. Bands (halt-and-ask past either)

- Cost: ~$50 total.
- Wall-clock: one afternoon of elapsed attention (~4h), human gates dominate.

## 3. Interventions — this list and nothing else

Plan approval · held findings · commit gate · reap-ack (E1 consequence:
TTL-only liveness) · sandbox-disable prompts on research-class fetches.
Any OTHER intervention the run requires is itself a finding.

## 4. Judgment dimensions (verbatim, pre-written)

- AC-integrity: `docket events list --run RUN-N --json` shows ZERO
  scheduling decisions made by a model (closed kind set,
  internal/engine/event.go). Structurally verified at G6; this run is its
  first real transition set.
- Zero-touch: developer supplied only work + conversational approvals (T9).
- Cost attribution: per-step usage present via the agentId join (label is
  not persisted — recorded E2 mechanism); the four metadata keys
  (model/effort requested/resolved) visible in `run report --json`.
- Deterministic work stayed in Docket (AC-2); judgment stayed in briefs
  (AC-1) — the composed packets are the carrier.

## 5. Disposition rule

Adopt-and-iterate iff: bands held, AC-integrity clean, intervention list
not exceeded, post-run audit clean. Otherwise halt-with-cause: stop, write
the cause, no rerun until the cause is dispositioned.

## 6. Pins

- engine commit: 7e705478b8a1a5f4018e823407cc6e2047f6bc9f (binary installed
  from exactly this before start; executors editing engine SOURCE do not
  affect the RUNNING binary)
- dotfiles HEAD at run start: ________ (fill on run day, after the M3-close
  commits; corpus tree expected unchanged at caddfd88…)
- wave.js sha256 0c3aa1f8…a66380cd · policy.expected.json 2ca4a8bb…2fcce597
- TTLs: lease.ttl.default 15m · lease.ttl.write 45m
- vote rules: security-acceptance 0.67 · doc-acceptance 0.60

## 7. No-touch rule

The operator does not edit the repo, the tracker DB, or any config between
activation and disposition, outside the listed interventions.

## 8. Post-run audit

D14: every trust entry and gate resolution recognized by the operator.
Metadata drift query over the four keys. The recorded absences stand: no
old-fleet A/B, no model self-metrics.

## 9. Known-thin spots, recorded now

AC-integrity query untested against real transitions until this run ·
liveness is TTL-only (heartbeat dropped, E1/D11) · attribution rides the
bootstrap prompt naming its step id · spec-doc packets thin (DKT-73,
irrelevant to this run's shape).
