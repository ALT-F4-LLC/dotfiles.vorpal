---
project: "main"
maturity: "draft"
last_updated: "2026-06-09"
updated_by: "@staff-engineer"
scope: "Redesign team-lead into a read-only orchestration layer with quality-first per-prompt model routing"
owner: "@staff-engineer"
dependencies:
  - docs/spec/architecture.md
  - docs/spec/review-strategy.md
status: "accepted"
---

# team-lead Read-Only Orchestration & Quality-First Model Routing

## Problem Statement

The operator wants `agents/team-lead.md` to define a pure communication/orchestration layer: team-lead receives messages, makes routing decisions from read-only observations, and delegates ALL artifact work to right-sized sub-agents. Model selection for every spawn must be quality-first — pick the model expected to produce the best result for the specific prompt, with cost explicitly not a criterion — and team-lead itself must run on the most capable available Anthropic model (currently Fable 5), enforced mechanically in the repo's settings source.

Two concrete defects in the current definition motivate this now:

1. **Internal contradiction on writes.** `agents/team-lead.md:23` scopes Edit/Write to `.claude/agent-memory/team-lead/*` only, yet step 14's Mechanical-fix shortcut (`agents/team-lead.md:276`) has team-lead applying source edits itself, and the cycle-bloat option (`agents/team-lead.md:278`) offers "compress remaining increments into team-lead self-edits". Both verified by Read this session. These self-edit paths also bypass review by design ("skip re-doubled-review"), creating the one class of tree changes with no independent reviewer.
2. **Illusory routing tier.** The cost-tiered routing table (`agents/team-lead.md:127-131`) includes an "inherit (omit param)" tier, but measured reality (recorded in both evolve-* skills, verified 2026-06-09: `.claude/skills/evolve-agents/SKILL.md:233`, `.claude/skills/evolve-skills/SKILL.md:235`) is that non-pinned spawns run `claude-opus-4-8` via classifier fallback — the table's middle tier does not do what it says, and the table optimizes for cost, which the operator has ruled out as a criterion.

**Constraints (CLOSED operator decisions — designed within, not reopened):**

- team-lead keeps ONLY the pitfalls-memory append (`.claude/agent-memory/team-lead/`); the mechanical-fix shortcut is removed and those fixes route to fix ephemerals.
- The cost-tiered table is replaced by quality-first per-prompt selection; Fable 5 is the default unless a smaller model genuinely fits the job better; cost is not a selection criterion.
- team-lead's own model is pinned mechanically in `src/user.rs` (repo is the settings source). No `model:` frontmatter pins anywhere; the never-haiku-for-custom-agents ban is preserved.

**Acceptance criteria** are enumerated per phase in Implementation Phases (§11); all are executable greps with baselines run this session.

## Context & Prior Art

- **`agents/team-lead.md` (489 lines, Read in full this session)** — the primary surface. Relevant anchors: Edit/Write scoping preamble (line 23), Per-spawn model routing (lines 127-131), Mechanical-fix shortcut (line 276), Cycle bloat surfacing (line 278), pitfalls-memory sanctioned exception (line 337), Rule 7 (CLOSED persistent set), Rule 8 (panel sizing).
- **`src/user.rs` (556 lines, Read in full this session)** — the settings builder deployed to `~/.claude` via vorpal symlinks (`src/user.rs:539-552`). Load-bearing facts: `with_agent("team-lead")` (line 94) makes team-lead the primary agent; `with_model("claude-fable-5[1m]")` (line 135) pins the session model; `ANTHROPIC_DEFAULT_FABLE_MODEL=claude-fable-5[1m]` (line 107) resolves the `fable` alias; `agents/team-lead.md` frontmatter carries no `model:` field (verified: `grep -c '^model:' agents/*.md` → 0 across all seven files). Consequence: **the mechanical pin the proposal asks for already exists** — team-lead, lacking a frontmatter override, runs on the pinned session model, Fable 5. `src/user/claude_code.rs` also exposes `with_model_override` / `with_available_models` (lines 633-641), available but not needed here.
- **Cross-references outside team-lead.md** (enumerated via repo-wide grep this session): exactly ONE agent-file touchpoint — `agents/security-engineer.md:32` ("team-lead pins opus for security reviewers"). No project skill (`skills/*/SKILL.md`) references the routing table or the mechanical-fix shortcut. The evolve-* skills reference measured model distributions generically and need no edit.
- **`docs/spec/review-strategy.md:21,53`** — names `agents/*.md` as the highest-churn surface with cross-file incoherence as the primary review risk, and documents Rule 8 panel sizing (unaffected by this design).
- **`docs/ux/` does not exist** (verified `ls -d`); no UX surface is touched.

### Proposal Evaluation

Mandated evaluation of the operator's proposal, before the design.

**Strengths**

1. **It fixes a live contradiction, not a hypothetical.** Line 23 already declares the memory-only write scope; lines 276/278 violate it. The proposal converges the file on the rule it already states.
2. **It closes the only unreviewed-write hole.** Mechanical-fix self-edits skip re-review by design. Routing them through ephemerals restores the single-writer property: every tree change traces to a briefed, Docket-tracked, reviewable agent.
3. **Quality-first routing matches measured reality.** The "inherit" tier was illusory (classifier fallback lands opus regardless), and the table's organizing principle — cost — is a non-goal per the operator. Replacing it loses nothing that actually worked.
4. **The enforcement item is already implemented.** The mechanical pin exists at `src/user.rs:94,107,135` with no frontmatter override; enforcement cost is zero.

**Weaknesses / risks (honest)**

1. **Trivial-fix latency regresses.** The shortcut existed for a reason: a <5 LOC fix now costs a spawn + claim + report + shutdown cycle (~4-6 orchestration turns) instead of one self-edit. Mitigation (design improvement below): batch at the review-round level — ONE fix ephemeral per round carrying all mechanical findings — so the marginal cost per finding stays near zero. Residual per-round cost is accepted by closed operator decision 1.
2. **"Per-prompt selection" can invite rumination.** A multi-factor scoring rubric per spawn would conflict with team-lead's own "Don't overthink" rule and add a deliberation step to every dispatch. With cost removed as a criterion, the decision space genuinely collapses to "most capable model, unless the brief is mechanical" — so the faithful implementation is a simple default-fable-with-documented-downshift rule, not a rubric. This is a simplification of the proposal's letter that preserves its intent.
3. **"Latest most powerful model" naming drifts.** Hardcoding "Fable 5" in agent prose ages the moment a successor ships. Mitigation: prose refers to the `fable` alias; the concrete model ID lives in exactly one place (`src/user.rs`), giving a single bump point on model releases.
4. **Omitted-model spawns are nondeterministic.** The proposal is silent on this, but quality-first selection is unenforceable while `Agent()` calls may omit `model=` (classifier fallback decides). Improvement: make `model=` mandatory on every spawn.

**Verdict:** net-positive; no component is net-negative once weaknesses 1-2 are mitigated as above. Recommended improvements adopted into the design: (a) round-level batch-fix ephemeral, (b) simplified default-fable routing rule instead of a scoring rubric, (c) alias-based naming in prose with the ID pinned only in `src/user.rs`, (d) `model=` mandatory on every spawn.

## Alternatives Considered

### Routing guidance shape

- **A. Multi-factor per-prompt rubric** — score each spawn on cognitive load, horizon length, review depth; map score to model. Strengths: most literal reading of "selects the model that will produce the BEST results for the PROMPT". Weaknesses: adds a deliberation step to every dispatch, conflicts with team-lead's "Don't overthink" discipline, and with cost excluded the rubric almost always outputs the same answer (most capable model). Verdict: rejected — ceremony without decision value.
- **B. Default-fable with documented downshift (CHOSEN)** — `model=` mandatory on every spawn; default `fable`; downshift to `sonnet` only for fully-Closed mechanical briefs where faster turnaround materially helps and the quality delta is nil, with a one-line justification in the brief; never `haiku`. Strengths: deterministic, zero per-spawn deliberation in the common case, downshifts auditable in spawn briefs and subagent logs. Weaknesses: relies on team-lead honoring "fully-Closed" honestly — mitigated by the existing Brief-Authoring Discipline detector and the evolve-* Model Routing Audit.
- **C. Keep a static table, relabeled by quality** — same table shape, quality-based tiers. Weaknesses: preserves the illusory inherit tier unless rewritten anyway, and a role-name-keyed table contradicts per-prompt selection. Verdict: rejected.

### Read-only enforcement shape

- **A. Prose-scoped (CHOSEN)** — keep `Edit, Write` in team-lead's `tools:` (required for the pitfalls append, the sole sanctioned write), tighten the scoping preamble, and remove both self-edit paths (shortcut + cycle-bloat self-edits). Strengths: smallest coherent change; preserves the pitfalls-memory contract (CANONICAL:PITFALLS block); prose discipline is how every other team-lead constraint is enforced today. Weaknesses: not mechanically enforced — accepted, consistent with the rest of the agent system.
- **B. Drop Edit/Write from `tools:`** — mechanically read-only. Weaknesses: breaks the pitfalls-memory append (closed decision 1 explicitly keeps it); spawning an ephemeral to append one memory line is absurd overhead. Verdict: rejected.
- **C. Settings-level deny rules for team-lead writes** — Weaknesses: permission rules in `src/user.rs` are session-global, not per-agent; a deny on repo paths would break every implementation teammate. Verdict: rejected as infeasible at this layer.

### src/user.rs enforcement shape

- **A. No code change (CHOSEN)** — the pin already exists: `with_agent("team-lead")` (line 94) + `with_model("claude-fable-5[1m]")` (line 135) + no `model:` frontmatter in any agent file. Codify it as a phase-3 grep AC so regressions are caught, and document the single bump point for model-name drift. Verdict: chosen per the already-present check — re-implementing it would be a no-op dressed as work.
- **B. Add `with_model_override` / `with_available_models` constraints** — e.g., restrict available models or force alias mappings. Weaknesses: `ANTHROPIC_DEFAULT_FABLE_MODEL` (line 107) already controls alias resolution; additional constraints add settings surface without changing any behavior the design needs. Verdict: rejected.

## Architecture & System Design

team-lead becomes a hub that only reads the tree and only writes its own memory; all tree mutations flow through briefed ephemerals; every spawn names its model explicitly.

```mermaid
sequenceDiagram
    participant R as Reviewer(s)
    participant TL as team-lead (read-only)
    participant FX as fix ephemeral (impl-{ID}-fix-{N})
    R->>TL: verdicts + findings (mechanical or not)
    TL->>TL: reconcile (step 14); read-only: git diff / docket / grep
    alt all findings mechanical
        TL->>FX: ONE batch-fix spawn, Closed brief, model per routing rule
        FX->>FX: apply edits, close issue, report
        FX->>TL: completion report
        TL->>TL: grep-verify (read-only), cite commands + results
    else non-mechanical findings
        TL->>FX: standard fix-loop ephemeral (continuity preamble)
    end
    TL->>FX: shutdown_request (after spot-check)
```

### Change 1 — Per-spawn model routing replacement (`agents/team-lead.md:127-131`)

The cost-tiered table and its four tier rows are deleted. Replacement text (normative; final wording may be polished at implementation without changing semantics):

```
**Per-spawn model routing (quality-first).** Every `Agent()` spawn MUST set `model=`
explicitly — an omitted param does NOT inherit the session model; it falls to a content
classifier whose fallback is nondeterministic (measured: non-pinned spawns run opus).
Selection criterion: the model expected to produce the best result for THIS prompt —
cost is NOT a criterion. Default `fable` (most capable available; alias resolves via
ANTHROPIC_DEFAULT_FABLE_MODEL — never hardcode the full model ID in prose or briefs)
for every spawn, including trivial ones, unless BOTH: the brief is fully Closed (zero
open design dimensions — mechanical execution of prescribed edits) AND faster
turnaround materially improves the dispatch loop — then `sonnet` is permitted with a
one-line downshift justification recorded in the spawn brief. An `Agent()` call
without `model=` is a dispatch defect. NEVER `haiku` for custom agents (xhigh-effort
frontmatter errors on Haiku). SendMessage-resumed persistent advisors keep their
spawn model — set it once at spawn.
```

Notes: the `opus` tier disappears as a standing target — under quality-first, `fable` supersedes it for every prompt class the table assigned it (security depth included). `agents/security-engineer.md:32` is updated accordingly (Change 4).

### Change 2 — Mechanical-fix shortcut removal (`agents/team-lead.md:276`)

The shortcut paragraph is replaced by mechanical-fix ROUTING (team-lead never edits the tree):

```
**Mechanical-fix routing.** team-lead NEVER applies fixes itself — every
reviewer-identified fix, regardless of size, routes to a fix ephemeral. When ALL
dispatched reviewers describe their findings as mechanical/find-replace/single-line,
batch ALL such findings from the round into ONE `impl-{DOCKET-ID}-fix-{N}` ephemeral
with a fully Closed brief (verbatim findings: file, line, exact required edit; sonnet
downshift permitted per the routing rule). Every briefed edit must trace 1:1 to a
named reviewer finding — never fold an extra unprompted edit into the batch. After
the ephemeral's completion report, team-lead verifies via read-only grep (verdict
cites commands + results) — mechanical batches skip re-doubled-review; any
non-mechanical finding follows the standard fix-loop instead.
```

This preserves both review-economy properties of the old shortcut (no re-doubled-review; 1:1 finding traceability) while moving the write to a reviewable, Docket-tracked agent.

### Change 3 — Cycle-bloat reword (`agents/team-lead.md:278`) and read-only preamble

- Line 278: "compress remaining increments into team-lead self-edits" → "compress remaining increments into a single consolidated batch-fix ephemeral (one Closed brief enumerating all remaining edits)".
- Line 23 preamble gains the layer statement: team-lead is a pure communication/orchestration layer; file operations are READ-ONLY except the single sanctioned write path `.claude/agent-memory/team-lead/**`; every other file change is delegated. Frontmatter `description` (lines 8-9) appends "read-only on the working tree" to the existing "never writes code, never creates issues, never commits".
- Explicit non-change: Docket mutations (`docket issue/vote/...`), Task tools, TeamCreate/TeamDelete, and SendMessage are orchestration-state operations, not file writes — they remain team-lead's job. The pitfalls block at line 337 already labels itself the sanctioned exception and is untouched.

### Change 4 — Touchpoint: `agents/security-engineer.md:32`

"team-lead pins opus for security reviewers" is stale under quality-first routing. Reword the Model floor note to: security content may still auto-reroute to Opus via the classifier when unpinned, but with `model=` mandatory on every spawn the classifier path is defense-in-depth only — team-lead's quality-first routing pins security spawns to `fable` explicitly; the floor remains "Opus-tier or better" and the grounding discipline is unchanged.

Note: `docs/changelog/agents/security-engineer.md` carries a copy of the "pins opus" language as a frozen historical record (verified by grep this session) — intentionally NOT edited, and excluded from the Phase 3 inverted-scope grep, whose scope deliberately omits `docs/changelog/`.

### Change 5 — `src/user.rs`: no code change

The pin is already present (lines 94, 107, 135 + zero `model:` frontmatter pins). Phase 3 codifies it as a regression grep. Model-name drift procedure: when a more capable model ships, bump `with_model(...)` (line 135) and the three `ANTHROPIC_DEFAULT_*_MODEL` env values (lines 107-109) in `src/user.rs` — the only place full IDs live.

## Data Models & Storage

N/A. Prose-only changes to two agent definitions; no data plane, schema, or persistence is touched.

## API Contracts

The one contract change is the `Agent()` spawn invocation shape team-lead must use:

```
Agent(team_name="dev-{slug}", name="{role-name}", subagent_type="{type}",
      model="{fable|sonnet|opus}",   # REQUIRED on every spawn — omission forbidden
      prompt="Verified goal: ... <canonical ephemeral-brief schema> ...")
```

- `model` is mandatory; `fable` is the default choice; `sonnet` requires a downshift justification line inside the brief; `haiku` is banned.
- The canonical ephemeral-brief schema (`agents/team-lead.md:115`) is unchanged; batch-fix briefs are ordinary Closed briefs under it.

## Migration & Rollout

- **Current state:** team-lead self-applies mechanical fixes and routes models by a cost-tiered table with an illusory inherit tier; the model pin already exists in `src/user.rs`.
- **Target state:** the five changes in §4; no behavioral change to any other agent's lifecycle, panel sizing (Rule 8), shutdown protocol (Rule 7), or rule numbering (Rule 5's asymmetry table is untouched).
- **Rollout:** single PR editing `agents/team-lead.md` + `agents/security-engineer.md` (+ this TDD). Deployment to `~/.claude/agents` happens through the existing vorpal symlink of the `agents/` directory (`src/user.rs:484-487,543`) — no builder change needed. In-flight cycles are unaffected; the new text applies from the next team-lead session.
- **Backward compatibility:** none required — prose contracts, no persisted state.
- **Rollback:** `git revert` of the PR; the symlinked directory picks up the revert on next vorpal build.

## Risks & Open Questions

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Trivial-fix latency/turn-count regression after shortcut removal | High | Low | Round-level batching (one ephemeral per review round); sonnet downshift for Closed mechanical briefs; cost accepted by closed operator decision 1 |
| "Fable 5" naming drift when a successor ships | Medium | Medium | Prose uses the `fable` alias only; full IDs live solely in `src/user.rs` (single bump point, documented in Change 5) |
| Per-prompt routing adds dispatch deliberation | Medium | Low | Default-fable rule, not a scoring rubric; downshift is the documented exception |
| Classifier-fallback claim goes stale if harness routing changes | Medium | Low | Claim is sourced from evolve-* measured notes (2026-06-09), flagged as sourced-not-re-measured in §9; the per-cycle Model Routing Audit re-measures it |
| evolve-agents flags shortcut removal as canonical-block drift | Low | Low | Rule numbering and CANONICAL blocks untouched; changelog entry on merge records intent |

**Open questions:** none remaining. The three dimensions the brief left open are decided here: routing shape (Alternatives §A/B/C → B), read-only expression (Alternatives → A, Changes 1-3), `src/user.rs` shape (Alternatives → A, no change). No operator question is outstanding.

## Testing Strategy

Prose-only change — the test suite is the executable grep set in §11, each with a baseline run this session (executable-claim gate: every AC regex below was executed against its target files on 2026-06-09; baseline values are cited per phase). No runtime tests apply; `src/user.rs` is untouched so no cargo delta exists.

**Untested-claims inventory (assumptions, not measurements):**

- "Non-pinned spawns run opus via classifier fallback" — sourced from `.claude/skills/evolve-agents/SKILL.md:233` / `evolve-skills/SKILL.md:235` (their note says verified 2026-06-09); not re-measured in this session.
- Deployed-symlink propagation (`vorpal build` → `~/.claude/agents`) is taken from `src/user.rs:543` + `docs/spec/architecture.md` §2; not exercised here.

## Observability & Operational Readiness

- **Routing compliance is already instrumented:** the evolve-* Phase 0 Model Routing Audit greps per-spawn `"model"` fields from subagent `.jsonl` files. Post-change expectation, checkable each cycle: distribution shifts from opus-dominant (classifier fallback) to fable-dominant (explicit), with sonnet entries traceable to downshift justifications greppable in spawn briefs.
- **Write-scope compliance:** any team-lead tree write outside `.claude/agent-memory/team-lead/` is visible in `git diff` during the operator's normal review (team-lead never commits) and is reject-class on sight.
- **3am diagnosability:** unchanged — orchestration state stays in Docket/TaskList; the batch-fix path adds a Docket-tracked issue + completion comment where the old shortcut left only a diff.

## Implementation Phases

Implementation note (all phases): line numbers cited in this TDD (`agents/team-lead.md:23,127-131,276,278`; `agents/security-engineer.md:32`) reflect the 2026-06-09 Read and WILL drift — implementers re-Read the live file and target content strings, never cited line numbers.

### Phase 1 — `agents/team-lead.md` redesign (S)

- **Goal:** apply Changes 1-3 (routing replacement, mechanical-fix routing, cycle-bloat reword, read-only preamble + description).
- **File scope:** `agents/team-lead.md` only.
- **Acceptance criteria** (run against `agents/team-lead.md`; baselines from 2026-06-09 session in parens):
  - `grep -c 'Mechanical-fix shortcut'` → 0 (baseline 1)
  - `grep -cE 'self-applied|applies the fix and self-verifies'` → 0 (baseline 1, line 276)
  - `grep -c 'team-lead self-edits'` → 0 (baseline 1, line 278)
  - `grep -c 'inherit (omit param)'` → 0 (baseline 1)
  - `grep -c 'sonnet` — Direct/Small'` → 0 (baseline 1)
  - Table-removal anchor: `grep -cE '^- .(fable|opus). —'` → 0 (baseline 2 — the `fable`/`opus` tier rows; with the two ACs above this covers all four rows) AND the routing-section header paragraph reads quality-first
  - `grep -c 'NEVER `haiku`'` → 1 (baseline 1; ban preserved)
  - `grep -c 'quality-first'` → ≥1 (baseline 0)
  - `grep -c 'batch-fix'` → ≥2 (baseline 0; mechanical-fix routing + cycle-bloat reword)
  - `grep -c 'model='` → ≥2 (baseline 1; mandatory-model rule present — Change 1's normative text carries two literal `model=` tokens)
  - `sed -n '1,30p' agents/team-lead.md | grep -c 'read-only'` → ≥1 (whole-file baseline 0 — verified this session; the layer statement lands in the preamble/description region)
- **Effort:** S. **Depends on:** nothing. **Out of scope:** Rules 5/7/8 bodies, CANONICAL blocks, Docket/Task/Team tool usage, pitfalls block (line 337).

### Phase 2 — `agents/security-engineer.md` touchpoint (S)

- **Goal:** apply Change 4 (Model floor reword to quality-first pinning).
- **File scope:** `agents/security-engineer.md` only (line 32 region).
- **Acceptance criteria:**
  - `grep -c 'pins opus for security reviewers' agents/security-engineer.md` → 0 (baseline 1)
  - `grep -c 'quality-first' agents/security-engineer.md` → ≥1 (baseline 0)
- **Effort:** S. **Depends on:** Phase 1 (references its routing language). **Out of scope:** every other line of the file.

### Phase 3 — Repo-wide coherence verification + pin regression guard (S)

- **Goal:** prove no stale references survive anywhere (inverted-scope) and codify the existing `src/user.rs` pin as a regression check; no edits expected in this phase — it is verification-only, escalating to team-lead if any grep fails.
- **File scope:** read-only over `agents/`, `skills/`, `.claude/skills/`, `src/user.rs`, `docs/spec/`.
- **Acceptance criteria:**
  - `grep -rn 'Mechanical-fix shortcut\|team-lead self-edits\|inherit-all stays settled' agents/ skills/ .claude/skills/ docs/spec/` → 0 hits (baseline 3 hits, all in `agents/team-lead.md` — measured this session; removed in Phase 1). Scope deliberately excludes `docs/changelog/` (frozen historical records per Change 4 note).
  - `grep -c 'with_model("claude-fable-5\[1m\]")' src/user.rs` → 1 (baseline 1; pin unchanged)
  - `grep -c '^model:' agents/*.md` → 0 for every file (baseline 0; no frontmatter pins introduced)
  - `grep -c 'with_agent("team-lead")' src/user.rs` → 1 (baseline 1)
- **Effort:** S. **Depends on:** Phases 1-2. **Out of scope:** evolve-* measured-distribution notes (intentionally unchanged), `docs/spec/review-strategy.md` Rule 8 description (unaffected).

## Post-acceptance amendment (2026-06-10)

**Date:** 2026-06-10  
**Recorded by:** impl-DKT-268 per operator directive  
**Tracking issues:** DKT-266 (routing fix), DKT-268 (this coherence note)

**What §Change 1 prescribed:** Default-fable quality-first routing — every spawn runs `fable` unless the brief is fully Closed and faster turnaround materially helps (then `sonnet` with a one-line downshift justification); cost is explicitly not a criterion.

**What now stands in `agents/team-lead.md`:** A 4-row cost-tiered routing table (heading: "Per-spawn model routing (cost-tiered, quality-upgradable)"): `sonnet` for Direct/Small impl and planner; `opus` for Medium impl, reviewer-2, verifier*; `fable` for tdd-author*, Large/architecture, long-horizon impl; `opus` (security depth) for security-reviewer-2 and security-dominated tdd-author*. Team-lead may exceed any tier with a one-line justification in the spawn brief.

**Why the divergence:** Post-ea127f9 Mirmir telemetry (measured 2026-06-09) showed 12 of 13 spawns using `fable` (94% concentration), including trivial planner/impl spawns. The quality-first "default fable for every spawn, including trivial ones" clause was the root cause. The operator directed restoration of the pre-ea127f9 cost-tier table (c3f0aa6 baseline) with quality-first retained only as an upgrade path.

**What was preserved from ea127f9:** `model=` mandatory on every spawn; never-haiku ban; alias-only naming; read-only orchestration; persistent-advisor spawn-model inheritance; former "inherit (omit param)" tier promoted to explicit `opus`.

**TDD history note:** This amendment records a post-acceptance divergence. The original §Change 1 text and all other sections of this TDD remain authoritative as the design record; this section documents only the operator decision that caused the live implementation to deviate.
