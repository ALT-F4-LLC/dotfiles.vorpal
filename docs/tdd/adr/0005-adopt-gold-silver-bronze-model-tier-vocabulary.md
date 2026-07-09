---
project: "main"
last_updated: "2026-07-09"
updated_by: "@distinguished-engineer"
status: "accepted"
---

# ADR 0005: Adopt Gold/Silver/Bronze Model-Tier Vocabulary

## Context

The repo ships two agent-team deployments: `src/user/claude-code` (Anthropic models via Claude Code) and `src/user/opencode` (multi-provider via opencode). Both route work across three capability tiers, but they name them differently: claude-code uses its model aliases as tier names (`sonnet`/`opus`/`fable`), while opencode uses provider-neutral, benchmark-ordered names (`bronze`/`silver`/`gold`) lexically shared with the `src/user.rs` config constants (`OPENCODE_MODEL_GOLD/SILVER/BRONZE`, `src/user.rs:51-65`, whose comments already anchor them as "Closest to Fable 5 / Opus 4.8 / Sonnet 5").

The alias-as-tier-name conflation has two costs: the two harnesses' routing doctrine cannot be read side-by-side, and claude-code's tier vocabulary churns with every model generation. Operator directive (2026-07-08, verified): adopt opencode's tier naming and seat-table structure in claude-code — naming/structure only, keeping Sonnet 5 / Opus 4.8 / Fable 5 as the only backing models, with no seat re-routing. Scope expansion (operator-confirmed same day): the five `.claude/skills/evolve-*/SKILL.md` consumers of the routing doctrine are updated in the same cycle — most critically `evolve-model-distribution`, whose literal greps and category→tier table functionally depend on the old vocabulary.

Full design: `docs/tdd/gold-silver-bronze-tier-naming-adoption-for-claude-code.md`. Related: opencode's routing prose (`src/user/opencode/agents/team-lead.md:210-223`) already cites "ADR-0005" prospectively (its tier philosophy, its Decision 2 seat table, and `src/user.rs` as the live opencode-side mapping) with no committed ADR behind those citations; this ADR is numbered and structured so they resolve — Decision 2 below IS the seat table they reference. Accepted via consensus vote DKT-V12 (2026-07-09: score 1.00, 3/3, zero blockers).

## Decision

**Decision 1 — Shared tier vocabulary.** Both deployments name their three capability tiers `gold` / `silver` / `bronze`, benchmark-ordered: `gold` is the capability-bound top seat, `silver` the standing authoring/review/verify floor, `bronze` the volume execution tier. Tier names are the routing vocabulary in prose, briefs, and dispatch tables. Each harness resolves the tiers in exactly one normative place — claude-code in `team-lead.md`'s Tiers block (tier → model alias: `gold`→`fable`, `silver`→`opus[1m]`, `bronze`→`sonnet[1m]`, with alias→model-ID staying in `src/user.rs`'s `ANTHROPIC_DEFAULT_*` env vars); opencode in its own Tiers block backed by the `src/user.rs` constants (which remain the live source of truth for opencode's provider/model mapping — on divergence the config wins and the prose is stale).

**Decision 2 — Seat table (structure shared; assignments per harness, unchanged by this ADR).** The seat-table structure is one tier per dispatch-table row, with the `advisor` seat split by cycle class and `impl-*` split by arm:

| Seat / spawn class | claude-code | opencode |
|---|---|---|
| `tdd-author*`, `investigator`/`innovation-scanner`, deep-impl `impl-*` (>1-day arm), `advisor` on Medium+ (TDD/ADR-bearing) cycles — @distinguished-engineer | `gold` | `gold` |
| `advisor` on sub-Medium / non-TDD-bearing cycles (incl. V/I/SR branch), `reviewer-2`, TDD secondary reviewers, standalone vote reviewers — @staff-engineer | `silver` | `silver` |
| ALL `security-*` — @security-engineer (deterministic pin; on claude-code, Fable 5's live classifiers auto-fall-back to Opus 4.8, so the `silver` pin converts a silent nondeterministic reroute into a deterministic choice) | `silver` | `silver` |
| `verifier*` new test-architecture; static-Large `impl-*` — @sdet / @senior-engineer | `silver` | `bronze` (single `sdet`/`senior` tier) |
| `impl-*` ≤Medium, routine verification, `planner` — @senior-engineer / @sdet / @project-manager | `bronze` | `bronze` |
| @ux-designer, team-lead itself | `bronze` | `silver` |

Rows where the harnesses differ are pre-existing routing facts, not changes: this ADR renames and restructures; it moves no seat and changes no backing model.

**Decision 3 — What model words remain legal.** Model aliases (`fable`/`opus`/`sonnet`) stay on harness-consumed surfaces (agent frontmatter `model:`, literal `Agent(model=...)` snippets) because the Claude Code harness takes aliases, not tier names. Model *names* (Fable 5, Opus 4.8, Sonnet 5) stay in model-property prose (classifier fallback, ZDR, prompting deltas, cap economics), historical/provenance notes, the Fable-distilled-heuristics brand (a model-vs-model comparison), and the session-metrics price table. Everything else speaks tiers.

## Consequences

**Positive.** The two deployments' routing doctrine reads identically at the tier level; a future backing-model swap on any tier touches only that harness's Tiers-block resolution line (and config), not the vocabulary; the anti-drift rule ("the mapping resolves in one place") becomes enforceable by grep; opencode's previously dangling ADR-0005 citations now resolve.

**Negative.** One indirection step at dispatch time — a brief says `gold`, the dispatcher passes `model="fable"` per the Tiers block. Transcript/`meta.json` measurements record aliases while doctrine speaks tiers — audits translate via the Tiers block's resolution lines (`evolve-model-distribution` gains this translation step in the same cycle, per the TDD's D6/Phase 4; its literal grep anchors are re-encoded against the new Tiers-block strings under an anchor-sync contract, which leaves a standing string-coupling between that skill and team-lead.md's prose — the recreated-but-now-documented version of the coupling that made the old vocabulary breakage silent). The anchor opener is not claude-code-unique (opencode's team-lead.md carries it verbatim), so consumer greps must stay file-scoped to `src/user/claude-code/agents/team-lead.md`.

**Neutral.** Seat assignments and backing models are unchanged; claude-code's per-spawn `model=` mechanism, effort-dispatch guidance, and two-cap economics are untouched. opencode's flat-rate/metered economics prose is provider-specific and is NOT imported into claude-code. Deploy timing: `src/user/claude-code/**` is build source, so live `~/.claude` agents pick up the new vocabulary at the next standard redeploy (coherent old-vocabulary snapshot until then); `.claude/skills/evolve-*` is git-tracked in place and greps the source team-lead.md path directly — no rebuild-ordering hazard.

## Alternatives Considered

**Status quo (keep `sonnet`/`opus`/`fable` as claude-code tier names).** Zero churn, but contradicts the operator's verified goal, keeps the harnesses' doctrine mutually unreadable, and re-couples tier vocabulary to model generations. Rejected.

**Full opencode parity — multi-provider models (Vertex Gemini, Z.AI GLM, OpenAI GPT) and per-agent-definition model binding.** Maximal convergence, but explicitly out of scope per operator directive: claude-code keeps Anthropic-only models and per-spawn `model=` routing, and opencode's flat-rate/metered economics are false under claude-code's Max-plan caps. Rejected for now / deferred — if claude-code ever adopts additional providers, this ADR's vocabulary already accommodates it (only the Tiers-block resolution lines would change), and that future decision gets its own ADR.
