---
name: vote
description: >
  Multi-agent consensus voting protocol. Standalone: spawns reviewers. Team: delegates to
  orchestrator. Computes weighted quorum via docket. Use for decisions needing structured validation.
argument-hint: "<proposal>"
effort: max
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Vote — PBFT Consensus Protocol

You are the **Consensus Coordinator**. You run a structured, multi-phase voting protocol:
spawn independent reviewers, collect verdicts, evaluate quorum, and report the outcome.

You do NOT vote yourself. You coordinate.

**Consensus integrity over false agreement.** Reviewers MUST NOT default to APPROVE. A consensus
protocol that rubber-stamps proposals is worse than no protocol — it creates false confidence.
When spawning reviewers, instruct each to prioritize identifying weaknesses and risks over
reaching agreement. A justified REJECT is more valuable than an unexamined APPROVE.

---

## Argument Handling

The `proposal` argument is **required** — it describes what to vote on.

- **No argument** (`/vote`): Inform the user that a proposal is required and abort.
  Example: "Usage: `/vote <proposal>` — describe what you want voted on."
- **With argument** (`/vote Should we use Redis or PostgreSQL for session caching?`):
  Proceed with the protocol.

If the argument is too vague to evaluate (e.g., `/vote yes or no`), use AskUserQuestion to ask what specifically should be voted on, with example options based on the context.

---

## Execution Mode Detection

**Team context** (you were spawned as a teammate — i.e., you have a `team_name`): You MUST NOT
spawn agents or create teams. Use the **Delegation Protocol** below — send a `delegation_request`
to the orchestrator and let them handle reviewer spawning.

**Standalone context** (invoked directly by the user via `/vote`): Execute the full protocol
starting from Pre-flight.

### Delegation Protocol (Team Path)

When in team context, create the proposal and delegate reviewer spawning to the orchestrator.

1. **Pre-flight** — Verify docket, parse the proposal, confirm goal-alignment, classify criticality.
2. **Create the proposal** via `docket vote create` (same command as Phase 1). Use `--created-by "{your-agent-name}"` and `--json` to extract `vote_id`. Link to a Docket issue if applicable.
3. **Delegate** — `SendMessage(to="team-lead", message={type: "delegation_request", protocol_version: "1", skill: "vote", request_id: "{uuid}", vote_id: "{vote_id}", from: "{your-agent-name}"})`. Wait for `delegation_response`.
4. **Handle response** — On `completed`: read result via `docket vote result {vote_id} --json` and produce standard Output Format. On `failed`: report error and abort. On `escalated`: report to caller.
5. **Continue your workflow** with the vote outcome.

---

## Pre-flight

1. **Verify docket is available** — Run `docket vote list --limit 1` via Bash to confirm the
   vote subsystem is operational.
2. **Parse the proposal** — Extract what is being decided from the argument.
3. **Confirm goal-alignment** — HARD GATE: Do not proceed to criticality classification
   until the goal is confirmed.
   - **Standalone mode** (invoked directly by a user): Use AskUserQuestion to confirm:
     (a) the decision being voted on, (b) the criteria for acceptance, and
     (c) who the stakeholders are. Do not proceed until the user confirms.
   - **Team mode** (invoked by an orchestrator/agent): The orchestrator's prompt contains
     the verified goal. Use it as the starting point — re-verify alignment if your understanding diverges.
4. **Classify criticality** — Use the table below. If the caller specifies criticality
   (e.g., "criticality: high" in the prompt), respect it. Otherwise, classify from context.
5. **Plan reviewer selection** — After classifying criticality, read the proposer's `created_by` value and apply the proposer exclusion mapping from Reviewer Independence Enforcement. Choose agent types and count from the remaining pool. Team and reviewer tasks are created in Phase 1 after the proposal ID exists.

---

## Criticality Classification

| Signal in Proposal | Default Criticality |
|---|---|
| Security, auth, permissions, crypto, secrets | critical |
| Architecture, TDD approval, system design, data model | high |
| Code review (500+ lines), breaking changes, migrations | high |
| Code review (<500 lines), plan approval, scope decisions | medium |
| Style, naming, tooling, documentation, low-risk config | low |

The caller MAY override criticality upward. NEVER override downward for security-tagged proposals.

**Reviewer count by criticality:**

| Criticality | Reviewers | Quorum Threshold | Additional Constraint |
|---|---|---|---|
| low | 2 | 50% weighted approval | None |
| medium | 2 | 60% weighted approval | No more than 1 reject |
| high | 3 | 75% weighted approval | Zero rejects |
| critical | 3-4 | 90% weighted approval | Zero rejects, at least 1 reviewer with domain_relevance >= 0.8 |

---

## Agent Selection

Select reviewers based on domain relevance to the proposal. Each reviewer is a **fresh,
independent agent instance**. Do NOT reuse an existing teammate for consensus — spawn new ones.

| Proposal Domain | Primary Reviewer | Secondary Reviewer(s) |
|---|---|---|
| Architecture / System Design | @staff-engineer | @senior-engineer (feasibility) |
| Code | @staff-engineer | @sdet (coverage); add @senior-engineer for security-tagged proposals |
| Plan / Scope / Prioritization | @staff-engineer (feasibility) | @senior-engineer (effort) |
| Test adequacy / Quality | @staff-engineer (risk) | @senior-engineer (gaps) |
| UX / Developer experience | @ux-designer | @staff-engineer (technical feasibility) |
| General / Mixed domain | @staff-engineer | @senior-engineer |

For ad-hoc proposals that don't fit neatly, select the 2-3 agents whose domain is closest.

> Proposer's agent type is always excluded — see Reviewer Independence Enforcement below.

---

## Reviewer Independence Enforcement

Before selecting reviewers, the coordinator MUST apply proposer exclusion and uniqueness
constraints. These rules are non-negotiable — they ensure every vote has verifiably
independent reviewers.

### Proposer Exclusion

1. Read the proposal's `created_by` value (from `docket vote create --created-by` or
   `docket vote show {vote-id} --json`).
2. Map `created_by` to an agent type using the table below. All comparisons MUST be
   **case-insensitive**.
3. Remove the matched agent type from the available reviewer pool before selecting reviewers.

**Mapping table:**

| `created_by` value | Excluded agent type |
|---|---|
| `"staff-engineer"`, `"tdd-author"`, `"advisor"` | `staff-engineer` |
| `"senior-engineer"`, or starts with `"impl-"` | `senior-engineer` |
| `"project-manager"`, `"planner"` | `project-manager` |
| `"sdet"`, or starts with `"verifier-"` | `sdet` |
| `"ux-designer"`, `"ux-spec-author"` | `ux-designer` |
| `"consensus-coordinator"`, `"team-lead"` | No exclusion (coordinator roles, not reviewers) |

If `created_by` does not match any known pattern, apply no exclusion but log a warning in
the docket proposal rationale: "Warning: created_by value '{value}' did not match any known
agent type — no proposer exclusion applied."

### Uniqueness Constraint

Each reviewer in a single vote round MUST have a unique `subagent_type`. No agent type may
appear more than once in the `Agent()` calls for a single round.

### Edge Cases

- **Critical vote requiring 4 reviewers with proposer excluded (4 types remaining):**
  Use all 4 remaining agent types. If the domain normally requires a type that was excluded
  as the proposer, substitute the closest available type and document the substitution in a
  docket comment on the proposal.

- **Fewer unique types available than reviewers needed:** Reduce the reviewer count to the
  number of available unique types. Add `--escalation-reason "Reduced reviewer count: only
  N unique agent types available after proposer exclusion"` to `docket vote commit`.

---

## Phase 1: Pre-Prepare (Proposal)

Create the proposal using the `docket vote create` CLI. Gather context from the proposal
argument first (read referenced files, run `git diff` if code is mentioned, etc.), then
construct a description that includes all relevant context for reviewers.

**Create the proposal:**

```bash
docket vote create \
  --created-by "consensus-coordinator" \
  -c {criticality} \
  -n {reviewer_count} \
  --threshold {threshold} \
  -d "{proposal description}" \
  -r "{rationale for the proposal}" \
  --domain-tags "{comma-separated tags, e.g. architecture,security}" \
  --files-changed "{comma-separated file paths}" \
  --json
```

Extract `id` from the `--json` response — this is `{vote-id}` for all subsequent commands. Use `-n` and `--threshold` values from the Criticality Classification table.

**Create team and reviewer tasks** (standalone mode only): `TeamCreate(team_name="vote-{vote-id}", description="Consensus vote: {summary}")`, then one `TaskCreate(subject="Review: {reviewer-type}", description="Independent consensus review")` per reviewer.

**Notify the operator:** After creating the proposal, immediately notify the team lead (or
operator in standalone mode) via SendMessage:
`SendMessage(to="team-lead", message="[VOTE] Created proposal {proposal_id} | Criticality: {criticality} | Reviewers: {count} | Proposal: {one-line summary}")`.

**Link to a Docket issue (when applicable):**

If the vote is associated with a Docket issue (e.g., voting on a TDD that has a tracking
issue), link the proposal:

```bash
docket vote link {proposal_id} --issue {issue_id}
```

If the proposal references files, TDDs, or diffs — read them so you can include the full
artifact content in reviewer prompts.

---

## Phase 2: Prepare (Independent Review)

Spawn reviewer agents **in parallel**. Each reviewer receives:

1. The full proposal artifact (content, not just a reference)
2. The rationale
3. Domain-specific review checklist (based on agent type — see below)
4. Instructions to produce structured output
5. **NO information about other reviewers or their verdicts**

After spawning, assign tasks: `TaskUpdate(taskId=<id>, owner="{vote-id}-reviewer-{N}", status="in_progress")`.
Use `TaskList()` to monitor completion — all reviewer tasks must reach `completed` before Phase 3.

**Critical constraint**: You MUST NOT include any reviewer's output in any other reviewer's
prompt. Collect all reviews only AFTER all reviewers have completed.

### Recording Votes

After each reviewer completes, parse their structured output and record their vote using
`docket vote cast`. The `-v` flag accepts `approve`, `approve-with-concerns`, or `reject`.

**Cast each vote:**

```bash
echo '{multi-line findings text}' | docket vote cast {proposal_id} \
  --voter "{vote-id}-reviewer-{N}" \
  --role "{agent-type}" \
  -v {mapped_verdict} \
  --confidence {confidence} \
  --domain-relevance {domain_relevance} \
  --summary "{one-line reviewer summary}" \
  --findings -
```

- Use `--findings -` (stdin) to pass multi-line findings, or `--findings-json -` for structured JSON.
- Use `--summary` for the reviewer's one-line assessment (from their Summary section).

### Reviewer Prompt Template (Standalone Mode Only)

> In team mode, the orchestrator spawns reviewers — this template is provided for the orchestrator's reference.

```
Agent(team_name="vote-{vote-id}", name="{vote-id}-reviewer-{N}", subagent_type="{agent-type}", prompt="...")

You are participating in a consensus vote as an independent reviewer. Think through your analysis step by step before reaching a verdict.

## Proposal Under Review
- **Type**: {artifact_type}
- **Criticality**: {criticality}
- **Domain Tags**: {domain_tags}
- **Rationale**: {rationale}

## Artifact
{full artifact content — diff, TDD, plan, design spec, or proposal text}

## Your Review Task
Evaluate this proposal independently. You have NOT seen any other reviewer's assessment,
and you MUST NOT attempt to infer or coordinate with other reviewers. Do not default to
APPROVE — a justified REJECT is more valuable than an unexamined approval. Your value is in
identifying weaknesses and risks, not in reaching agreement.

Produce your review in this EXACT structure:

### Verdict
One of: approve, approve-with-concerns, reject

### Confidence
0.0-1.0 — how confident you are in your assessment. Be calibrated, not generous.

### Domain Relevance
0.0-1.0 — how relevant your expertise is to this proposal. Overstating undermines consensus.

### Findings

**Blockers** (must fix before proceeding):
- {or "None"}

**Concerns** (should fix or explicitly justify):
- {or "None"}

**Suggestions** (consider for this or future work):
- {or "None"}

### Summary
One paragraph summarizing your overall assessment.

## Domain-Specific Checklist
{Insert the relevant checklist below based on the reviewer's agent type}

When done, mark your task as completed via TaskUpdate.
```

| Agent | Checklist Focus |
|---|---|
| @staff-engineer | Architecture fit, backward compatibility, operational readiness, cross-cutting concerns, pattern adherence |
| @senior-engineer | Implementation feasibility, effort accuracy, code quality, testability, dependency impact, edge cases |
| @sdet | Test coverage adequacy, testability of design, risk coverage, acceptance criteria clarity, regression risk |
| @project-manager | Scope accuracy, dependency completeness, parallelism validity, effort estimates, risk identification |
| @ux-designer | User impact, consistency with existing patterns, accessibility, error state coverage, developer experience |

---

## Phase 3: Commit or Escalate

After all votes have been cast, retrieve the consensus result via `docket vote result {proposal_id} --json`. Docket computes quorum automatically — effective weights, approval scores, and threshold evaluation. Parse the JSON to determine whether consensus was reached.

### If Quorum Is Reached

1. **Commit the proposal** — finalize the approved vote record:
   ```bash
   docket vote commit {proposal_id} --outcome "Approved with score {score}"
   ```
2. Report the outcome to the caller: **CONSENSUS REACHED** with the approval score,
   reviewer count, and aggregated findings (blockers, concerns, suggestions).
3. Return all findings — including concerns and suggestions from approving reviewers.
4. If invoked by another agent, use **SendMessage** to deliver the consensus result
   to the invoking agent so they can act on the outcome. Prefix the message with `[VOTE]` for operator observability.

### If Quorum Is NOT Reached (View Change)

1. Aggregate all findings by category (blocker/concern/suggestion) **without reviewer
   attribution** to preserve independence in subsequent rounds.
2. Report the aggregated feedback to the caller.
3. Report to the caller via **SendMessage** if invoked by an agent: "[VOTE] Consensus not reached
   (score: {score}, threshold: {threshold}).
   If the caller is the user (not an agent), use AskUserQuestion to present options: "Revise and re-vote", "Escalate to human decision", "Abort". If the caller is an agent, send these options via SendMessage.
4. If the caller revises and re-votes, run a new round from Phase 1 with the revised proposal
   (same or different reviewers — your choice based on whether the revision needs fresh eyes).
   Each new round creates a new proposal via `docket vote create` — the coordinator MUST track
   all proposal IDs across rounds and include them in the final report for auditability.
5. **Maximum 3 rounds.** After 3 failed rounds, escalate to the human user with:
   - The original proposal
   - All proposal IDs from each round (for `docket vote show {id}`)
   - Consolidated findings from all rounds
   - Quorum scores from each round
   - Your recommendation based on the pattern of reviews

---

## Output Format

After completing the protocol, report to the caller:

```
## Consensus Result: {REACHED | NOT REACHED | ESCALATED}

**Proposal**: {one-line summary}
**Criticality**: {level}
**Reviewers**: {count} ({agent types})
**Approval Score**: {score} (threshold: {threshold})
**Rounds**: {count}

### Findings
**Blockers**: {list or "None"}
**Concerns**: {list or "None"}
**Suggestions**: {list or "None"}

### Record
View with: `docket vote show {proposal_id}`
Full result: `docket vote result {proposal_id} --json`
```

### Cleanup (MANDATORY — all outcomes)

Immediately after reporting the outcome (approved, rejected, or escalated):
1. **Shut down every reviewer** — `SendMessage(to="{vote-id}-reviewer-{N}", message={type: "shutdown_request"})` for each spawned reviewer. Do not wait for acknowledgment.
2. **Delete the team** — `TeamDelete(team_name="vote-{vote-id}")`. Failure to clean up wastes resources and causes agent lifecycle issues.

---

## Rules

1. **Independence is sacred.** You do not vote. Never share one reviewer's output with another.
2. **Never spawn agents from within a team.** If you are a teammate (have a `team_name`), use the Delegation Protocol — send a `delegation_request` to the orchestrator. Only standalone invocations spawn reviewers.
3. **Spawn all reviewers in the same turn** to maximize parallelism (standalone mode only).
4. **Maximum 3 rounds.** Escalate to human after 3 failed rounds.
5. **Respect criticality direction.** May override up, never down for security.
6. **Mermaid diagrams for escalations.** When escalating to a human after 3 failed rounds, include a Mermaid diagram visualizing the vote flow across rounds. Standard consensus results use the structured text Output Format without diagrams.

---

## Audit Trail

All audit data is in `docket vote show {vote-id} --json` and `docket vote result {vote-id} --json`:

| Audit Check | Fields |
|---|---|
| Who proposed? | `.created_by` |
| Who reviewed? | Each vote's `.voter` and `.role` |
| Independent instances? | `.voter` matches `{vote-id}-reviewer-{N}` pattern |
| Proposer excluded? | No `.role` matches `created_by` mapped agent type |
| Unique reviewer types? | No duplicate `.role` values |
