# Design-Complete Gate — Maintained Master

`team-lead.md` Rule 10 cites this file (pointer-only — no LOCAL copy by design; a
`CANONICAL:DESIGN-GATE-LOCAL` marker would register a false drift pair). The gate binds only
the actor holding spawn authority. Distilled from the TDD accepted via vote DKT-V5. Deployed
at `~/.claude/skills/team-doctrine/references/design-gate.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/design-gate.md`.

---

## 1. The gate, stated

> **Design-Complete Gate (Rule 10).** Planning and implementation are LOCKED until every
> design/research artifact the cycle requires is authored AND accepted via its EXISTING
> acceptance machinery. Spawning @project-manager/`planner*` or dispatching ANY
> implementation ephemeral (including the Direct-Task @senior-engineer) before the gate
> passes is a rule violation of the same class as Rule 7.

The gate boundary is also the TDD consumption boundary: docs/tdd/ artifacts are inputs to
Design and Planning only — post-gate phases receive their content via the Distillation Gate
(docs-paths.md §Ephemerality doctrine) and never read the files. The point is
handoff-readiness: every implementation dispatch is design-frozen, so implementation-only
harnesses never receive open research or design questions.

The gate governs exactly one boundary — Design → Planning/dispatch. A breach surfaces
exactly like a Rule 7 breach: operator report, Docket mirror (Rule 2), a pitfalls-memory
entry, and evolve-agents historical-audit pickup.

## 2. Per-pattern required artifacts and acceptance (normative table)

| Pattern | Required before Planning / dispatch | "Accepted" means (existing machinery only) |
|---|---|---|
| Direct | The dispatch brief IS the artifact: fully Closed (exact file, old string, new string, done-state) + a `Design-source:` line (§3 grammar) | Operator-verified goal (Pre-flight step 1) + zero Open dimensions + every embodied decision cites its settling source. No review body. |
| Small | Design-source inventory: every decision KNOWN at pre-flight cites its settling source (accepted TDD distilled per the Distillation Gate / ADR / logged advisor consult / verbatim operator instruction) | Citable sources exist for all known decisions; an unsettled known decision → `advisor` consult first (logged as a Docket comment when issues exist, else carried verbatim in the plan brief) or graduate to Medium. |
| Medium | TDD (plus security TDD / co-authored security sections when flagged) | The merged acceptance panel (author recuses; `high`=3 general TDD seats @staff-engineer/@senior-engineer/@sdet, `critical`=4 security TDD adds @security-engineer) IS the review-and-acceptance body — vote-commit per Consensus Integration criticality; security sections cross-reviewed before vote. |
| Large | ALL TDDs (lead + every parallel `tdd-author-` sibling); PRD first when product-defined | Each TDD as Medium; PRD accepted by operator approval. Planning may not start until EVERY sibling is accepted (strict; relaxing this is a future operator-approved doctrine change). |
| UX-Heavy | UX spec + TDD | Spec: `Skill(design-review)` by a non-author reviewer (when `ux-advisor` authored it, the reviewer is a `design-review-{N}` ephemeral); TDD as Medium. |
| V/I/SR | EXEMPT | Deliverable IS research (report/verdict); the shape authors no changes and dispatches no implementation ephemeral, so it never crosses the gated boundary. Findings that spawn authoring work start a successor cycle, which re-enters Pre-flight and meets the gate there. |

## 3. Design-source grammar (API contract)

The gate's interchange contract is the **Design-source line** carried in Direct-Task
dispatch briefs (and, for Small, per known decision in the planning brief):

```
Design-source: <exactly one of>
  - distilled TDD decision     verbatim decision text + inert provenance, e.g.
                               "phases serialize on file collisions" — provenance:
                               TDD 'foo' §4 (accepted, vote V-12; provenance-only, not a file reference)
  - accepted ADR citation      e.g. "docs/adr/0004-bar.md (accepted, vote V-9)" (durable, dereferenceable)
  - verbatim operator instruction   e.g. "operator, this cycle: 'rename X to Y everywhere'"
  - mechanical — no decision embodied   (typo/dep-bump/log-tweak class)
```

**Gate-pass predicate (Direct):** brief fully Closed AND `Design-source:` present AND no
Open dimension AND no embodied decision left uncited. Any failure → run the design work
first (advisor consult / TDD / ADR per size) or graduate the pattern. The `mechanical` arm
keeps the bar proportionate: a typo fix pays one literal line, not a review cycle.

**FORM check, never merits.** Team-lead evaluates the predicate — including the
`mechanical` classification — as a form check only (line present, citations resolve, zero
Open dimensions); it never judges whether the cited decision was the RIGHT decision, and any
doubt about whether a decision is embodied graduates the pattern or routes to `advisor`. The
no-engineering-decisions boundary is unchanged.

## 4. Security Track composition (orthogonal to the gate arm)

The Q7 security flag binds ORTHOGONALLY: Rule 10's "no new review body" refers to the gate's
acceptance side only and never waives the Security Track. Small + security-sensitive keeps
the non-negotiable `security-advisor` review; a Direct task touching an enumerated security
surface graduates per the Direct template's surfacing-decision trigger — a security-touching
one-liner cannot ride the Design-source bar past the security consult.

## 5. Mid-cycle interaction (governs ENTRY, not a mid-cycle re-lock)

Decisions that genuinely surface mid-implementation keep their existing paths (advisor
consults, `Discovered:` comments, step-13 re-plan). A step-13 re-plan that requires NEW
design artifacts re-enters the gate for those artifacts before the revised plan dispatches;
the gate never retro-blocks resuming already-planned in-flight work.
