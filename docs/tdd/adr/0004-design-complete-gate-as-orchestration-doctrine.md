---
project: "main"
last_updated: "2026-07-05"
updated_by: "@distinguished-engineer"
status: "accepted"
---

# ADR 0004: Design-Complete Gate as Orchestration Doctrine (Hard Blocker Before Planning)

## Context

Work orchestrated by team-lead is routinely handed off to implementation-only coding harnesses and models (Codex, OpenCode, etc.). team-lead.md sequences Design before Planning only by convention — the pattern diagrams order `advisor → @project-manager → …`, but nothing hard-blocks the Planning Phase (spawning @project-manager, creating Docket issues) or implementation dispatch on the acceptance of the cycle's design artifacts, and the Direct Task pattern is explicitly "no plan, no review" with no documentation bar at all. A dispatch carrying open research/design questions makes an implementation-only harness do design work — un-reviewed, outside the team's acceptance machinery. The operator directed (2026-07-05, confirmed via AskUserQuestion): gate ALL patterns including Direct; completion bar = authored AND accepted via existing machinery; enforcement = hard blocker comparable to the Rule 7 CLOSED-set rule; zero net byte increase to team-lead.md (95,658 B measured against the 80,000 B budget, TRIM mode per DKT-35).

Full design: `src/user/claude-code/skills/team-doctrine/references/design-gate.md` (maintained master; distilled from the accepted TDD, which has since been deleted). Related: ADR 0001/0002 (canonical-family precedent), DKT-35 (byte-budget TRIM tracking, in flight). Accepted with the TDD via vote **DKT-V5**, committed 2026-07-05: "Approved with score 1.00 (3/3 approve-with-concerns, zero rejects, threshold 0.75 met)" — following two-reviewer secondary review; status flipped proposed → accepted by the author post-vote.

**Numbering deviation (deliberate).** The adr skill's max+1 algorithm yields 0003, but 0003 is a taken number with a missing file: `docs/tdd/adr/0003-centralized-vs-in-repo-pitfalls-memory-split.md` is cited by `team-doctrine/references/pitfalls.md:15` and 7 agent definitions. Writing new content at 0003 would hijack that referenced identity; this ADR is numbered 0004, leaving 0003 free for a backfill of the pitfalls-split record.

## Decision

Adopt the **Design-Complete Gate** as a named hard-blocker rule in team-lead.md (new Rule 10): Planning and implementation are LOCKED until every design/research artifact the cycle requires is authored AND accepted via its existing acceptance machinery — TDD/security TDD: secondary review (Rule 8(a)) + vote-commit per Consensus Integration; ADR: vote; UX spec: `Skill(design-review)` by a non-author — author-recusal (deliberately NOT cited as Rule 8, which is code/TDD-review-specific and whose single-reviewer default would be the spec's own author); PRD: operator approval; Direct/Small: a `Design-source:` bar (each embodied decision cites an accepted TDD/ADR section, a verbatim operator instruction, or `mechanical — no decision embodied`) where the operator-verified goal IS the acceptance. Spawning @project-manager/`planner*` or dispatching ANY implementation ephemeral — including the Direct-Task @senior-engineer — before the gate passes is a rule violation of the same class as Rule 7. Verification/Investigation/Standalone-Review tasks are exempt: their deliverable IS research and they never cross the gated boundary; findings that spawn authoring work re-enter Pre-flight. The gate governs entry, not a mid-cycle re-lock — mid-implementation discoveries keep the existing consult/re-plan paths, and a re-plan requiring new design artifacts re-enters the gate for those artifacts.

Mechanically: Rule 10 plus four thin choke-point hooks (Design Phase step 6 tail, Planning Phase step 7 head, Direct and Small templates); the per-pattern artifact/acceptance table, Design-source grammar, and rationale live in a new master `src/user/claude-code/skills/team-doctrine/references/design-gate.md` per the file's established relocation convention. The byte cost is paid by relocating two existing bulk blocks to references masters with compact `CANONICAL:*-LOCAL` marker-wrapped LOCALs (Rule 10 itself stays pointer-only, unmarked — it cites design-gate.md rather than copying it, so a marker would register a false drift pair) — the Fable-distilled completeness heuristics and the Monitor-for-Orchestration watch patterns — for a measured projected net of **−289 B** (adds 2,328 B; savings 2,617 B).

## Consequences

**Positive.** Every implementation dispatch is design-frozen: implementation-only harnesses receive zero open research/design questions — the operator's stated goal. Enforcement is auditable (named rule violation, same surfacing as Rule 7 breaches: operator report, Docket mirror, pitfalls memory, evolve-agents audit). Direct Task gains a proportionate bar — the already-mandatory fully-Closed brief plus one `Design-source:` line, with a `mechanical` arm so a typo fix pays one literal line, not a review cycle. team-lead.md shrinks ~290 B, slightly reducing the DKT-35 trim burden.

**Negative / harder.** Large cycles lose eager per-TDD planning: Planning may not start until EVERY sibling TDD is accepted (strict, per the operator's "all research and documentation" intent) — accepted-but-waiting TDDs idle while a sibling is in review; relaxing this would be a future operator-approved doctrine change. Two collateral relocations add LOCAL-vs-master drift surface (same class as the 9 existing reference-home families, owned by the evolve-* drift audits). Rules grow to 10; every future team-lead evolution must respect that Direct/Small acceptance deliberately has no review body — adding one would be over-tailoring, not a fix.

**Neutral.** No other agent file changes — the gate binds the only actor holding PM-spawn/implementation-dispatch authority. Pattern sizing (the decision tree) is untouched; the gate changes sequencing only. ADR-0002's constraint survives: the TFD master is not relocated or modified. Rollback is a plain `git revert`; the relocated masters are verbatim copies, so rollback is lossless.

## Alternatives Considered

- **Pre-flight self-check bullet instead of a numbered Rule.** Rejected: Pre-flight runs before the pattern (hence the required-artifact set) is known, and a self-check bullet lacks the named-violation strength the operator required. See TDD §3 Alternative A.
- **New canonical family with LOCAL copies in all 8 agent files (TFD-style).** Rejected: only team-lead holds the gated authority; 7 worker LOCALs would be dead-weight context and a multi-file byte cost for zero behavioral delta. See TDD §3 Alternative C.
