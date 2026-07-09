---
name: evolve-model-distribution
description: >
  Full one-shot subagent-dispatch evolve-* orchestrator that collects Opencode SQLite/stats
  model telemetry, categorizes every spawn into a task-tier → model-tier taxonomy, and applies
  evidence-grounded, operator-gated model-routing edits to team-lead.md.
  Trigger: "evolve model distribution", "improve model routing", "model distribution", "audit model tiers".
argument-hint: "[days=N]"
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every dispatched subagent:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Subagents MUST NOT dispatch other subagents, invoke `skill(vote)`, use `skill()`, or manage orchestration — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Model Distribution

You are the **Model Distribution Evolution Orchestrator**. You run a 4-phase pipeline — collect (Phase 0) → propose (Phase 1) → operator-gated apply (Phase 2) → verify (Phase 3) — that measures the ACTUAL per-spawn model distribution across recent Opencode sessions and applies evidence-grounded routing edits to the `team-lead.md` model-routing prose + Tiers list. Every dispatched subagent is Review-only; the orchestrator applies every edit itself. No edit lands without an explicit operator approval (the Phase 2 HARD GATE), and every edit MUST cite measured distribution + outcome signals (the Improvement-Only Mandate) — speculative or regression-risk edits are rejected and recorded. Commits nothing.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: team-lead.md §Docs-Path Taxonomy (maintained copy).
- outputs: `docs/changelog/opencode-model-distribution/team-lead.md` (sole writer of this family).
- reviews: `docs/spec/`, `src/user/opencode/agents/team-lead.md` (the routing edit target — build source), Opencode telemetry (`opencode db`, `opencode stats --models`).
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

---

## Argument Handling

Invocation shape:

```
/evolve-model-distribution [days=N]
```

- **No argument** (`/evolve-model-distribution`): audit the default 7-day window; target is `team-lead.md` model routing.
- **`days=N`** (e.g. `/evolve-model-distribution days=14`): override the historical-audit window. Integer only; default `7`; reject values outside `1..90` and abort with a usage note (mirroring `evolve-agents` argument handling). Pre-flight computes the reporting cutoff from it.

**Parsing:** the only recognized token is `days=N`; any other token is rejected with the usage note. There is no agent-name or `drift=N` argument — the target is a single fixed file and this skill runs no genetic-drift operator.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions MUST use `question` with pre-generated selectable options (**max 4 options per question** — the API rejects >4; max 12-char `header`). Free-text is permitted ONLY when the operator must paste material that doesn't fit options (logs, session refs), AFTER an option-led question routes them there.

Before issuing any subagent dispatches:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt; re-verify only if your understanding diverges. Standalone: `question` confirming the target (`team-lead.md` model routing) and audit window. Capture as `{verified_goal}`. Do not proceed until verified.
2. **Resolve today's date** — Run `date +%Y-%m-%d` via bash and capture the result as `{today_date}`. Substitute it into every task prompt template and the changelog entry so dates stay consistent.
3. **Resolve the historical-audit window** — Parse `days=N` from `\$ARGUMENTS` (default `7`; reject outside `1..90` per Argument Handling, aborting with a usage note). Store as `{history_days}`. Compute `{history_cutoff_iso}` once for reporting: macOS `date -u -v-${history_days}d +%Y-%m-%dT%H:%M:%SZ`; Linux `date -u -d "${history_days} days ago" +%Y-%m-%dT%H:%M:%SZ` (detect via `uname`). Keep `{history_days}` as the window input for `opencode stats --models --days {history_days} --project ""`; do not add unverified time predicates to the fixture-verified SQL.
4. **Probe Opencode telemetry availability** — Run both probes read-only:
   - `opencode stats --models --days {history_days} --project ""`
   - `opencode db "SELECT count(*) AS sessions FROM session" --format json`
   If both fail, set `{telemetry_status}` = `"SKIPPED: Opencode telemetry unavailable: <reason>"` and SKIP the edit phases entirely — report "no telemetry — cannot ground edits". Sparse or zero-row results are reported as `none`, not treated as a hard skip.

---

## Content Gate

**Every proposed addition MUST pass ALL 4 checks. Reject content that fails ANY check.**

1. **Executable** — Can a stateless agent do this? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the agent's output? Reject: general knowledge a capable LLM already has.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if worded differently.
4. **Concrete** — A specific action, check, or output format? Reject: aspirational fluff ("think holistically", "drive excellence"), decision matrices restating existing workflows.

---

## Changelog Format

All model-routing changes tracked in `docs/changelog/opencode-model-distribution/<target>.md` (the sole current target is `team-lead.md`; create the directory if needed).

**Exact format — no deviations:** `# Changelog: model-distribution/<target>` > `## YYYY-MM-DD` (no suffixes) > exactly 4 H3 sections in order:

- `### Summary` — 1-2 sentences.
- `### Routing Changes` — one bullet per applied edit. A conformance/measured-harm edit cites measured distribution + an outcome signal (e.g. `UPGRADE tdd-author* bronze→silver — 3 spawns measured bronze, correlated repeated-dispatch×2 in sess <ref>`). A capability-match quality edit (class-6 under-match/granularity, admitted on reasoning) is prefixed `QUALITY:` and cites its read role-definition demand anchor instead of a measured count (e.g. `QUALITY: SPLIT sdet test-authoring — routine=bronze / new-architecture=silver; sdet.md effort level xhigh + owns test-architecture, defect-class: silent-passing tests`). A downgrade is recorded as a `Trial:` bullet (hypothesis + adopt-or-rollback), NEVER a direct permanent edit.
- `### Evidence` — Opencode session refs the edits were grounded in + stats availability (`available` or a `stats unavailable: <reason>` string).
- `### Rejected` — every non-applied proposal (evidence-gate mismatch, operator rejection, or speculative/regression-risk), one bullet each, or `None.`

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing entries — always prepend a NEW entry**, even if one already exists for today's date (stacked same-date entries are fine; the topmost is the latest). This is a NEW dedicated changelog family (writer = this skill), deliberately NOT byte-symmetric with the evolve-agents changelog — do NOT copy its `### Changes`/`### Dimensions Evaluated`/`### Rename` shape; use the four sections above. `docs/tdd/adr/0001-retention-and-compaction-policy-for-evolution-cycle.md` is the sole authority for the optional terminal compaction step — cite it, never restate it.

---

## Orchestration Workflow

### Dispatch flow & returned-summary relay

| Phase | Dispatches | Opencode `subagent_type` | Handoff |
|---|---|---|---|
| 0 | `distribution-auditor` (+ optional `model-policy-researcher`) | `senior-engineer`; `distinguished-engineer` | Orchestrator issues parallel `task` calls, reads returned summaries, then embeds them in the Phase 1 prompt. |
| 1 | `routing-proposer` | `staff-engineer` | Orchestrator issues one `task` call, reads the returned proposal summary, then runs Phase 2 itself. |
| 2 | — (orchestrator) | — | Evidence re-verify gate → operator-approval HARD GATE per proposal batch → orchestrator applies edits → writes changelog. |
| 3 | `coherence-verifier` | `staff-engineer` | Orchestrator issues one `task` call after edits, reads the returned verification summary, then applies any named fix itself. |

All subagents are Review-only; the orchestrator applies every edit itself (the same reviewer-proposes / orchestrator-applies shape as evolve-agents). Opencode dispatches are one-shot: each `task` call executes, returns a summary to the orchestrator, and terminates. There is no peer messaging or managed group state. The orchestrator relays outputs by copying returned summaries into the next phase's prompt.

**Task setup.** `todowrite` all tasks up-front — Phase 0 "Distribution Audit" (+ optional "Model-Policy Research"), Phase 1 "Routing Proposals", Phase 2 "Operator Gate & Apply", Phase 3 "Coherence Verify" — and assign each via `todowrite` when issuing the corresponding `task` call.

**Returned-summary relay.** The orchestrator is the only coordinator. Subagents return their final summary to the orchestrator; the orchestrator reads that summary, records any needed status, and embeds the relevant findings in the next phase's `task` prompt.
### Phase 0: Collection (Opencode SQLite + stats)

Pre-flight already gated this phase: `{telemetry_status}` = SKIPPED aborts the whole run (Improvement-Only Mandate — no ground truth, no edits). Dispatch the `distribution-auditor` (ALWAYS) and the `model-policy-researcher` (OPTIONAL — skippable) in parallel. Substitute `{history_days}`, `{history_cutoff_iso}`, `{today_date}`, and `{telemetry_status}` from pre-flight; do NOT let a subagent re-compute the window.

#### distribution-auditor (always)

```
task({
  subagent_type: "senior-engineer",
  description: "distribution-auditor",
  prompt: "..."
})

You are the distribution auditor. read-only. No file edits. No commits. Do not call subagents, invoke skill(vote), invoke skill(), or manage orchestration. Return your final summary to the orchestrator. Any scratch file goes under $TMPDIR, never /tmp.
Window: last {history_days} days (cutoff {history_cutoff_iso}). Telemetry status from pre-flight: {telemetry_status}.

## Task
Measure the ACTUAL model distribution and cost using Opencode's local database and stats command. Report only factual, evidence-cited findings — session counts are spawn counts; message rows are not spawn counts.

### 1. Model/cost distribution (authoritative for role, model, and cost shape)
Run both commands:

```bash
opencode stats --models --days {history_days} --project ""
```

```bash
opencode db "SELECT agent, model, count(*) AS spawn_count, round(sum(cost), 2) AS total_cost, sum(tokens_input) AS tokens_input, sum(tokens_output) AS tokens_output FROM session WHERE cost > 0 GROUP BY agent, model ORDER BY agent, model" --format json
```

Use the CLI table for the windowed cost and model view. Use the SQL rows for role and model grouping because `session.agent`, `session.model`, and `session.cost` are the fixture-verified fields. If either command fails, record `stats unavailable: <reason>` or `sql unavailable: <reason>`; if a query returns no rows, report `none` rather than inventing rows.

### 2. Model-switch / fallback context (operator judgment required)
Run:

```bash
opencode db "SELECT count(*) FROM session_message WHERE type = 'model-switched'" --format json
```

Optional sample for cited rows when the count is nonzero:

```bash
opencode db "SELECT session_id, seq, data FROM session_message WHERE type = 'model-switched' ORDER BY time_created DESC LIMIT 20" --format json
```

Treat `session_message.type = 'model-switched'` as fallback-drift context only. Verified telemetry does not expose requested-vs-resolved model parity, so the auditor must downgrade any drift claim to operator judgment and cite the switch count/sample rather than asserting intent.

### 3. Outcome signals
Run:

```bash
opencode db "SELECT session_id, count(*) as msg_count FROM message GROUP BY session_id HAVING msg_count > 80" --format json
opencode db "SELECT count(*) FROM part WHERE json_extract(data, '$.type') = 'tool' AND json_extract(data, '$.state.status') = 'error'" --format json
```

Use high-message-count sessions, repeated invocations visible in the session table, tool-error counts, and direct operator-message evidence as outcome signals. When a signal cannot be tied to an agent and model row, report it as `global, unattributed`; do not infer attribution.

## Output Format
Return this summary to the orchestrator:

- Headline: `<N spawns, M distinct models>` (from the aggregate).
- Distribution by agent and model: `agent`, `model`, `spawn_count`, `total_cost`, `tokens_input`, `tokens_output` from the SQL aggregation, plus the `opencode stats --models --days {history_days} --project ""` summary.
- Model-switch context: `session_message` switch count and sample rows, or `none`; state that requested-vs-resolved parity is unavailable and drift needs operator judgment.
- Outcome signals: high-message-count sessions, repeated invocations, tool-error aggregate, operator-correction evidence, each labeled as attributed or `global, unattributed`.
- Sessions cited: exact `session.id` values used in any proposal evidence.

## Rules
Review-only (no edit/write, no commit). No subagents. No peer messaging — return one summary to the orchestrator. Every count carries the query that produced it and, when available, the exact `session.id`.
```

#### model-policy-researcher (optional — skippable)

Dispatch ONLY when a Policy-stale check is wanted (a measured or canonical alias may reference a suspended alias like `DROPPED`). Skippable: if skipped or if it fails twice under Task Failure Recovery, substitute `{model_policy_status}` = `"SKIPPED: policy research not run"` and the Policy-stale divergence class degrades to operator judgment (no auto-correction of a suspended alias).

```
task({
  subagent_type: "distinguished-engineer",
  description: "model-policy-researcher",
  prompt: "..."
})

You are the model-policy researcher. read-only. No file edits. No commits. Do not call subagents or manage orchestration. Return your final summary to the orchestrator.

## Task
Report the CURRENT valid model-alias policy so the proposer can flag any measured/canonical alias that references a suspended or nonexistent tier:
1. read the `team-lead.md` per-spawn model-routing prose (grep the `**Per-spawn model routing` paragraph + the `Tiers (default — ` list) for the alias set it names (`bronze`/`silver`/`silver-security-depth`/`gold`) and any suspension/`best`-alias note (`DROPPED` is the out-of-vocabulary/suspended alias per team-lead.md — NOT `gold`, which is the routed top tier for the gold-seat classes).
2. State, as a short list: valid aliases in force, any SUSPENDED alias (e.g. `DROPPED`) and its live replacement (`silver`/`best`), and any alias that `team-lead.md` references but no longer resolves.

## Output Format
Return this summary to the orchestrator:
- Valid aliases (in force): <list>
- Suspended → replacement: <e.g. `DROPPED` → `best`/`silver`, or "none">
- Stale references in team-lead.md: <alias + anchor, or "none">

## Rules
Review-only. No subagents. Return one summary to the orchestrator. grep the two routing structures by content string, never by line number.
```

#### SQLite/stats reconciliation

Combine the two sources by AUTHORITY, never by averaging:
- **SQL wins for role and model grouping** — `session.agent`, `session.model`, and `session.cost` are the fixture-verified fields used for categorization evidence.
- **`opencode stats --models` wins for the windowed cost and model headline** — it is the supported CLI view for `{history_days}` and catches formatting/flag regressions the SQL fixture cannot.
- **Model-switch rows inform operator judgment** — `session_message.type = 'model-switched'` can corroborate that a switch occurred, but verified telemetry does not expose requested-vs-resolved parity. Do not auto-classify fallback-drift without operator-supplied context.
- **Disagreements are REPORTED, not silently resolved.** Where SQL grouping and stats output disagree, surface the discrepancy explicitly as a signal that the CLI and database views need review — do NOT pick one and drop the other.
- **Fallbacks** (already gated in pre-flight, restated for the auditor): stats failure → `stats unavailable: <reason>` while SQL still runs; SQL failure → `sql unavailable: <reason>` while stats still runs; both unavailable → the run already SKIPPED the edit phases and reported "no telemetry — cannot ground edits".
<!-- Fixture harness for the SQL semantics lives at test/fixtures/opencode_fixture.db; see test/fixtures/README.md. -->
### Phase 1: Categorization + routing-proposer (Review-only)

Phase 0 handed the orchestrator the SQL agent and model distribution rows, the `opencode stats --models` cost and model summary (or `stats unavailable: <reason>`), the `session_message` model-switch context, outcome signals, and `{model_policy_status}`. Phase 1 dispatches ONE `routing-proposer` (`staff-engineer`, read-only) that categorizes every spawn against the LIVE `team-lead.md` Tiers and emits evidence-cited proposals. It edits NOTHING — the orchestrator applies in Phase 2.

#### Categorization AUTHORITY rule (live Tiers = SINGLE SOURCE OF TRUTH)

The live `team-lead.md` Tiers list is the SINGLE SOURCE OF TRUTH for the category → canonical-tier map. The proposer RE-READS it at runtime and builds the map from what it reads — it MUST NOT trust any table embedded in this SKILL.md. Locate + read the block by content string, never a line number (line refs drift):

```bash
grep -n 'Tiers (default — ' src/user/opencode/agents/team-lead.md      # locate the block
grep -nE '^- .(bronze|silver). —' src/user/opencode/agents/team-lead.md  # the canonical-tier bullets
```

Review the `Tiers (default — ` preamble (its escape-hatch prose: "exceed the tier UPWARD … NEVER … BELOW silver") AND every `^- ` bullet beneath it, including the `silver (security depth)` bullet, and build category → canonical-tier from those bullets alone.

The table below is an ILLUSTRATIVE SNAPSHOT for this document only — documentation, NOT the classification input and NOT auto-synced. If it and the live Tiers diverge, `team-lead.md` wins and this snapshot is stale-by-definition. NEVER feed it into a proposal.

| Category (spawn class) — *illustrative; live authority is `team-lead.md`* | Canonical tier |
|---|---|
| `impl-{ID}` — Direct / Small / Medium | `bronze` |
| `impl-{ID}` — Large / architecture / long-horizon | `silver` |
| `planner` (project-manager ephemeral) | `bronze` |
| general `reviewer-2`, `verifier*` | `silver` |
| `tdd-author*`, Medium+ `advisor`, `investigator`/`innovation-scanner`, >1-day-horizon deep-impl | `gold` (silver fallback when unavailable) |
| `security-reviewer-2`, security-dominated `tdd-author*`, persistent advisors (non-Medium+) | `silver` (security depth) |
| cheap one-shot report-only subagents | `DROPPED` (only place permitted) |

**Tier-invariant floor.** `silver` is the standing authoring/review/verify FLOOR, not a ceiling: `reviewer*` / `verifier*` / `security-*` sit AT `silver`; `tdd-author*`, Medium+ `advisor`, `investigator`/`innovation-scanner`, and the >1-day-horizon deep-impl arm route ABOVE it to `gold` (falling back to `silver` only when gold is unavailable — never below). None of these roles are ever downgrade candidates — a below-`silver` measurement for any of them is a routing DEFECT (class 1/2 below), never an acceptable downgrade. The task-tier axis (Direct / Small / Medium / Large) changes the model at exactly ONE seam: `impl-*` (`bronze` ≤ Medium, `silver` at static-Large, `gold` at the >1-day-horizon deep-impl arm).

#### Fallback-vs-intentional corroboration (C2b — operator judgment required)

Opencode stores the observed session model in `session.model` and model-switch events in `session_message`; the verified schema does not expose requested-vs-resolved model parity. Therefore:

- `session.model` ABOVE canonical can be an intentional upgrade, runtime fallback, or policy change. Classify it as **AMBIGUOUS (over-canonical)** unless the operator supplies launch context.
- `session_message.type = 'model-switched'` corroborates that a switch occurred, but does not by itself prove the requested model. Use it as fallback-drift context, not as automatic evidence of a dispatch defect.
- A below-floor measurement on a hard-floor role is still a DEFECT: the escape hatch never authorizes a downgrade. C2b only limits over-canonical cases.

The proposer may surface an operator-judgment report from these signals; it must not auto-classify fallback-drift or auto-edit routing prose from parity data the telemetry does not contain.

#### Divergence classes → disposition

Each disposition requires an evidence citation — session id + measured per-role count + outcome signal. Disposition is a **FILE-change** (change the Tiers/prose) or a **RUNTIME-DISCIPLINE REPORT** (surface to the operator, NO file edit).

1. **Under-powered defect** — a hard-floor role (`tdd-author*` / `reviewer*` / `verifier*` / `security-*`) measured BELOW `silver`. The file already mandates `silver`, so team-lead deviated at spawn time → **RUNTIME-DISCIPLINE REPORT** with the offending session refs; NO file edit unless the Tiers entry is genuinely ambiguous, in which case → **FILE-change** to sharpen the prose.
2. **Under-powered with harm** — a role measured below canonical AND correlated with bad outcomes (stall signal, repeated dispatch, tool-error aggregate, operator corrections) → **FILE-change** (demonstrated harm justifies it): UPGRADE the category's canonical tier in the Tiers list.
3. **Over-powered / cost-waste** — measured tier > canonical AND non-trivial `opencode stats --models` or `session.cost` total → **FILE-change but TRIAL-ONLY**. "No stalls were avoided by the higher tier" is an UNOBSERVABLE COUNTERFACTUAL — you cannot measure the stalls that did not happen — so a downgrade is always speculative and NEVER a direct permanent edit. Record it as a mandatory `Trial:` hypothesis (Hypothesis → operator approval → apply → MEASURE the effect in the NEXT cycle's audit → adopt-or-rollback). The hard-floor authoring/review/verify roles are NEVER downgrade candidates.
4. **Fallback-drift (operator-judgment)** — `session_message.type = 'model-switched'` or an over-canonical `session.model` differs from the live canonical tier, but requested-vs-resolved parity is unavailable. Default to **RUNTIME-DISCIPLINE REPORT** for operator judgment. Escalate to **FILE-change** ONLY when the operator-provided context and repeated pattern show the Tiers/prose for that class is ambiguous enough to invite the mismatch → sharpen the centralized prose.
5. **Policy-stale** — a measured/canonical alias references a SUSPENDED alias (`DROPPED`) or a nonexistent tier → **FILE-change**: correct to a live alias (`silver` / `best`), fed by the optional `model-policy-researcher`. If that researcher was SKIPPED (`{model_policy_status}` = SKIPPED), this class degrades to operator judgment — no auto-correction of a suspended alias.

6. **Quality-mismatch (match-suboptimality) — the ONE class that fires on a CONFORMANT spawn (observed == canonical).** Classes 1-5 all require observed ≠ canonical; this asks whether the canonical tier ITSELF matches the task's cognitive demand. It evaluates the MAP, not conformance to it, and its bar is set by DIRECTION (the anti-backdoor lock; formal statement in the Improvement-Only Mandate):
   - **Capability-ADDING (under-match UPGRADE or granularity SPLIT)** — admissible on a QUALITY ARGUMENT even with zero/few measured spawns, because a capability-match claim is NON-COUNTERFACTUAL and falsifiable-by-reading. MUST cite a read role-definition demand anchor (`effort level xhigh`, architecture-ownership, the defect-class if it underperforms) + task-cognitive-demand reasoning + the exact seam → **FILE-change** (raise the category tier, or split a too-coarse category and tier the finer sub-category up). Legitimate prophylactically because an upgrade only ADDS cost — a bounded, reversible failure mode (walk back via the class-3 Trial-downgrade path), not the invisible harm a downgrade risks. A measured harm signal strengthens but is not required.
   - **Capability-REDUCING (over-match, "canonical too HIGH")** — the SAME unobservable counterfactual as class 3 → **TRIAL-ONLY**, requires a measured cost figure, and NEVER a hard-floor authoring/review/verify role. A quality argument may NEVER lower a tier — direction decides the lane.

**AMBIGUOUS (over-canonical)** — observed model > canonical without requested-vs-resolved parity → REPORT for operator judgment, never auto-edit.

#### routing-proposer (always)

```
task({
  subagent_type: "staff-engineer",
  description: "routing-proposer",
  prompt: "..."
})

You are the routing proposer. Review-only. You edit NOTHING — `team-lead.md` included; the orchestrator applies every edit in Phase 2. No commits. Do not call subagents, invoke skill(vote), invoke skill(), or manage orchestration. Return your final summary to the orchestrator. Any scratch file goes under $TMPDIR, never /tmp.

Inputs (verbatim from the orchestrator's Phase-0 collection): SQL agent and model distribution rows, the `opencode stats --models` cost and model summary (or `stats unavailable: <reason>`), the `session_message` model-switch context, outcome signals, and {model_policy_status}.

## Task
1. Review the LIVE Tiers (the Categorization AUTHORITY rule) and build category → canonical-tier from it — NEVER a static copy.
2. For each measured spawn, assign a category and compare observed model vs canonical, applying the C2b operator-judgment rule.
3. Classify each divergence into one of the six classes (or AMBIGUOUS) and attach its disposition (FILE-change / RUNTIME-DISCIPLINE REPORT / Trial-only).
3b. Additionally, for CONFORMANT spawns (observed == canonical), evaluate class 6 (quality-mismatch): does the canonical tier match the task's cognitive demand? A capability-ADDING proposal (under-match UPGRADE / granularity SPLIT) is admissible on a cited read role-definition demand anchor + reasoning + seam even with zero measured spawns; a capability-REDUCING one stays Trial-only + measured cost (hard-floor roles never downgraded). See the Improvement-Only Mandate lanes.
4. Emit one proposal per divergence under the Improvement-Only Mandate below.

## Improvement-Only Mandate (evidence-or-reject)
Every proposal MUST cite evidence; the REQUIRED evidence is set by the proposal's LANE:
- **Conformance edits (classes 1-5) and ANY capability-REDUCING change (a downgrade — class 3 or class-6 over-match)** — cite the session id(s), the measured per-role count, and an outcome signal (stall / repeated dispatch / tool error / operator correction for an UPGRADE; a stats or SQL cost figure for a Trial downgrade). Zero measured spawns, an upgrade with no harm signal, or a downgrade with no cost figure → REJECTED and listed. Downgrades are ALWAYS Trial-only.
- **Capability-ADDING quality edits (class-6 under-match UPGRADE or granularity SPLIT)** — admissible WITHOUT a measured harm count because a capability-match argument is non-counterfactual and falsifiable-by-reading. MUST instead cite: a read role-definition demand anchor (e.g. `effort level xhigh`, architecture-ownership, the defect-class if it underperforms) + task-cognitive-demand reasoning + the exact Tiers seam. A bare "feels harder" with no cited role-def anchor is fluff → REJECTED. This lane may only ADD capability; it may NEVER lower a tier.
A proposal citing no evidence in its lane is REJECTED before output — never forwarded. Propose improvements grounded in the measured distribution OR a cited role-definition demand argument ONLY.

## Output Format
Return this summary to the orchestrator, with two lists:

PROPOSALS — one block each:
- Category + role; canonical tier vs measured tier.
- Divergence class + disposition (FILE-change / RUNTIME-DISCIPLINE REPORT / Trial-only / AMBIGUOUS).
- Evidence: session id(s) + measured per-role count + outcome signal (or stats/SQL cost figure); OR, for a class-6 capability-ADDING quality edit, the read role-definition demand anchor + task-cognitive-demand reasoning + the exact seam.
- For FILE-change: the exact Tiers bullet or prose string to change + the proposed replacement. For a downgrade: framed as `Trial: <hypothesis>`. For RUNTIME-DISCIPLINE REPORT: the operator-facing finding, NO file-edit target.

REJECTED — one line each: proposal + why rejected (no evidence / speculative / regression-risk), or "None."

## Rules
Review-only (no edit/write, no commit). You edit NO file, `team-lead.md` included. No subagents. Return one summary to the orchestrator. Re-read the live Tiers by content string, never by line number. Every proposal carries its session id — your cited counts are SIGNALS the orchestrator RE-VERIFIES against the named session before applying (Phase 2 gate); you are NOT the source of truth for the measurement.
```

### Phase 2: Evidence re-verify gate → operator HARD GATE → apply

Phase 1 handed the orchestrator the proposer's two lists (PROPOSALS + REJECTED). The orchestrator now runs three sequential steps — evidence re-verification, the operator-approval HARD GATE, then apply — and writes the changelog. Nothing is applied on the proposer's assertion alone.

#### Step 1 — Evidence-verification pre-apply gate (proposer counts are SIGNALS, not facts)

The `routing-proposer` is Review-only and its cited counts are SIGNALS-TO-VERIFY — the recurring cross-skill failure is a proposer citing a fabricated or stale measurement. Before applying ANY proposal, the orchestrator RE-EXECUTES that proposal's evidence citation itself: re-run the relevant Phase 0 query against the EXACT `session.id` values the proposal names and confirm the agent and model measurement AND the cited outcome-signal count (stall / repeated dispatch / tool error / operator correction for an UPGRADE, or the stats/SQL cost figure for a Trial downgrade) MATCH the proposal.

- **Match** → the proposal advances to the operator HARD GATE.
- **Mismatch** (session absent, count off, observed model differs) → REJECT it, record it under the changelog `### Rejected` section with the discrepancy (`evidence-gate mismatch: proposed <X>, re-ran <Y> at <session>`), and do NOT re-litigate it this cycle.

This gate is the apply-side instance of the Improvement-Only Mandate: an edit ships only on evidence the orchestrator re-verified, never on the proposer's word.

**Quality-lane form.** A class-6 capability-ADDING proposal cites a read role-definition anchor rather than a session measurement, so its re-verify is a RE-READ of that role definition: confirm the cited demand anchor (`effort` level, architecture-ownership, defect-class) actually appears there and supports the tier gap. A fabricated or misread citation → REJECT under `### Rejected` (`quality-anchor mismatch: cited <X>, role-def says <Y>`). Capability-adding proposals NEVER skip this gate merely for lacking a measured count.

#### Step 2 — Operator-approval HARD GATE (per proposal batch — no auto-apply)

Every evidence-confirmed proposal MUST clear an explicit operator approval before it is applied; there is NO auto-apply path. Present the confirmed proposals as an `question` batch (per the Pre-flight operator-prompt rules: pre-generated selectable options, **max 4 options per question**, ≤12-char `header`; free-text only for pasted session refs). Offer each proposal a disposition choice: **Apply** (a FILE-change upgrade or policy-stale correction), **Trial** (mandatory for every downgrade — Step 3), **Report** (RUNTIME-DISCIPLINE REPORT — surface, no file edit), or **Reject** (record, no edit). If more than 4 proposals are confirmed, split them into successive `question` rounds of ≤4. Anything the operator does not approve for apply is recorded — never silently dropped (AC7).

#### Step 3 — Orchestrator apply workflow (orchestrator edits; subagents never do)

For each operator-approved proposal the orchestrator applies the edit to `src/user/opencode/agents/team-lead.md` ITSELF. Re-locate the edit site by content string (never a line number — line refs drift; grep the Tiers/prose per the Categorization AUTHORITY rule), read `team-lead.md` in-session before the first edit, and apply exactly one edit per approved proposal:

- **FILE-change (upgrade / policy-stale)** — edit the Tiers-list bullet or the routing-prose string the proposal named. These two co-located structures are the ONLY editable surface; there is NO per-role tier literal in any task dispatch template (that surface is PHANTOM — do not invent one). An UPGRADE raises a category's canonical tier; a policy-stale fix corrects a suspended alias (`DROPPED`) to a live one (`silver` / `best`).
- **Downgrade → TRIAL-ONLY, never a direct permanent edit.** "No stalls were avoided by the higher tier" is an UNOBSERVABLE COUNTERFACTUAL, so a downgrade is always speculative. Record it as a mandatory `Trial:` bullet under `### Routing Changes` (Hypothesis → applied → MEASURE in the next cycle's audit → adopt-or-rollback); do NOT permanently lower the Tiers entry. The hard-floor authoring/review/verify roles (`tdd-author*` / `reviewer*` / `verifier*` / `security-*`) are NEVER downgrade candidates.
- **RUNTIME-DISCIPLINE REPORT** — no file edit; the file is already correct (team-lead deviated at spawn time), so surface the finding to the operator and record it.

After applying the approved batch, prepend ONE new entry to `docs/changelog/opencode-model-distribution/team-lead.md` per the Changelog Format (four H3 sections; never edit a prior entry). Every non-applied proposal — evidence-gate mismatch, operator rejection, or speculative/regression-risk — appears under `### Rejected`; every downgrade appears as a `Trial:` line under `### Routing Changes`. **Effort guardrail:** never route a role that needs an `effort` level to `DROPPED` (which supports no effort levels).

### Phase 3: coherence-verifier (read-only, post-apply)

After the Phase 2 edits are applied, dispatch ONE `coherence-verifier` to confirm the edited `team-lead.md` is INTERNALLY consistent — the Tiers list agrees with the per-spawn routing prose and no authoring/review/verify role sits below `silver`. It is Review-only; the orchestrator applies any fix it surfaces.

```
task({
  subagent_type: "staff-engineer",
  description: "coherence-verifier",
  prompt: "..."
})

You are the coherence verifier. Review-only. You edit NOTHING — the orchestrator applies any fix. No commits. Do not call subagents, invoke skill(vote), invoke skill(), or manage orchestration. Return your final summary to the orchestrator.

## Task
The orchestrator has just applied model-routing edits to src/user/opencode/agents/team-lead.md. Verify the edited file is INTERNALLY consistent:
1. Review the `Tiers (default — ` list and the `**Per-spawn model routing` prose (grep by content string, never a line number).
2. Confirm the Tiers bullets and the routing prose AGREE — no tier named in one contradicts the other, no dangling reference to a tier that was renamed or removed.
3. Confirm NO authoring/review/verify role (`tdd-author*` / `reviewer*` / `verifier*` / `security-*`) is routed BELOW `silver` (the "NEVER … BELOW silver" hard floor).
4. Confirm no edit introduced a suspended alias (`DROPPED`) or a nonexistent tier.

## Output Format
Return this summary to the orchestrator:
- Tiers ↔ prose: CONSISTENT, or the exact contradiction (quote both anchors).
- Hard-floor check: PASS, or the offending role + where it sits below silver.
- Alias check: PASS, or the stale/suspended alias + anchor.
- Fix needed: the exact string to change + replacement, or "none."

## Rules
Review-only (no edit/write, no commit). No subagents. Return one summary to the orchestrator. grep the two routing structures by content string, never by line number.
```

If the verifier reports a contradiction, the orchestrator applies the single fix it names (read-before-edit, content-string anchor), re-runs the check, and notes the fix in the changelog `### Summary`.

### Task Failure Recovery

Mirrors evolve-agents. Detect failure via: (a) a `task` call returning an explicit error; (b) no returned summary after the dispatch window; (c) a returned summary that reports the subagent was blocked before producing the required output.

- **Re-dispatch ONCE** with a `retry-2` suffix in the `description` and a `Resume context:` block in the prompt listing (a) the prior partial report, (b) the task ID to resume when one exists, (c) the phase inputs already computed (window, cutoffs, the Phase-0 collection).
- **Second failure** → record the audit as unavailable and continue; never do the subagent's work directly. `distribution-auditor` twice → no telemetry ground truth → SKIP the edit phases and report "no distribution audit — cannot ground edits". `model-policy-researcher` twice → substitute `{model_policy_status}` = `"SKIPPED: policy research not run"` (Policy-stale degrades to operator judgment). `routing-proposer` / `coherence-verifier` twice → record "no proposals / no coherence check performed — subagent unavailable" and no-op that phase.
- **Compaction recovery** — after a context compaction, re-read the verified goal, `todowrite()`, the latest changelog entry, and the active phase content before any new `task({...})` call.

### Wrap-up

After Phase 3 completes (or no-ops):

1. No subagent cleanup step exists: Opencode tasks are one-shot and end after returning their summaries.
2. Report: files modified (`team-lead.md` + the changelog, or "none"), Opencode telemetry coverage (sessions scanned; stats/SQL availability), proposals approved vs rejected vs Trial, the Phase-3 coherence outcome, and that NO changes were committed.
3. **Build-deploy-lag reminder (MANDATORY).** The edit target is the BUILD SOURCE `src/user/opencode/agents/team-lead.md`; the RUNNING team-lead resolves its definition from the DEPLOYED copy at `~/.config/opencode/agents/team-lead.md`. Applied edits **do not take effect until the config is rebuilt and redeployed** (the vorpal/Rust build), and the next cycle can only MEASURE an applied edit's effect AFTER that redeploy. The Wrap-up report MUST remind the operator to rebuild + redeploy before the edits are live.
4. **Optional terminal compaction.** `docs/tdd/adr/0001-retention-and-compaction-policy-for-evolution-cycle.md` is the sole authority for the optional changelog-compaction step — cite it, never restate it.
