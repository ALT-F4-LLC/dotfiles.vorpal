---
name: vote
description: >
  PBFT-inspired consensus voting protocol for multi-agent decision validation. Spawns independent
  reviewer agents to evaluate a proposal, computes weighted quorum, and creates an auditable
  consensus record via docket. Use when a decision needs independent validation from multiple perspectives —
  architectural approvals, code reviews, security-sensitive changes, scope decisions, or any
  prompt where you want structured multi-agent agreement before proceeding. Any agent or user
  can invoke this skill.
argument-hint: "<proposal>"
effort: max
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Vote — PBFT Consensus Protocol

You are the **Consensus Coordinator**. You run a structured, multi-phase voting protocol:
spawn independent reviewers, collect verdicts, evaluate quorum, and report the outcome.

You do NOT vote yourself. You coordinate.

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

Before proceeding to the full protocol, determine your execution mode:

1. **Check your system prompt** for the list of tools available to you.
2. **If `Agent` AND `TeamCreate` appear in your tool list:**
   You are the orchestrator (or have spawn capability). Continue with the full protocol
   below — execute directly starting from Criticality Classification.
3. **If `Agent` and `TeamCreate` do NOT appear in your tool list:**
   You are running inside a sub-agent context. Use the **Delegation Protocol** below instead
   of the direct-execution flow.

### Delegation Protocol (Sub-Agent Path)

When you lack `Agent`/`TeamCreate`, create the proposal yourself and delegate reviewer spawning.

**Steps:**

a. **Pre-flight** — Verify docket, parse the proposal, confirm goal-alignment (in team mode, trust the orchestrator's verified goal), classify criticality.

b. **Create the proposal** via `docket vote create` using the same command from Phase 1: Pre-Prepare. Use `--created-by "{your-agent-name}"` and `--json` to extract `vote_id`. Link to a Docket issue if applicable: `docket vote link {vote_id} --issue {issue_id}`.

c. **Delegate** — Send to the orchestrator via SendMessage:

   ```json
   {"type":"delegation_request","protocol_version":"1","skill":"vote","request_id":"{your-agent-name}-vote-{epoch-ms}","from":"{your-agent-name}","vote_id":"{vote_id}"}
   ```

d. **Wait** for `delegation_response`. Do not proceed until received.

e. **Handle response** by `status` field:

   | Status | Action |
   |---|---|
   | `completed` | Read result: `docket vote result {vote_id} --json`. Produce standard output per Output Format section. |
   | `failed` | Report error and `vote_id` to caller. Abort. |
   | `escalated` | Report escalation and `vote_id` to caller. |

f. **Continue your workflow** with the vote outcome.

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
5. **Select reviewers** — After classifying criticality, read the `created_by` value and apply the proposer exclusion mapping from the Reviewer Independence Enforcement section before selecting reviewers. Choose agent types and count based on criticality and domain from the remaining pool.
6. **Create the team** — `TeamCreate(team_name="vote-{vote-id}", description="Consensus vote: {one-line proposal summary}")`. The `{vote-id}` is the docket proposal ID from `docket vote create --json` (e.g., `DKT-V5`).
7. **Create reviewer tasks** — One `TaskCreate` per reviewer:
   `TaskCreate(subject="Review: {reviewer-type}", description="Independent consensus review of proposal")`.

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

> **Note:** The proposer's agent type is always excluded from the reviewer pool before selection.
> See the Reviewer Independence Enforcement section below.

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

> **Mapping freshness:** Cross-check this table against `/dev` spawning templates
> (`agents/*.md`) when agent names change to keep mappings current.

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

Extract `id` from the `--json` response — needed for all subsequent commands. Use `-n` and `--threshold` values from the Criticality Classification table.

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

### Reviewer Prompt Template

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
and you MUST NOT attempt to infer or coordinate with other reviewers.

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
2. **Delete the team** — `TeamDelete()`. Failure to clean up wastes resources and causes agent lifecycle issues.

---

## Rules

1. **Independence is sacred.** You do not vote. Never share one reviewer's output with another.
2. **Spawn all reviewers in the same turn** to maximize parallelism.
3. **Maximum 3 rounds.** Escalate to human after 3 failed rounds.
4. **Respect criticality direction.** May override up, never down for security.
5. **Mermaid diagrams for escalations.** When escalating to a human after 3 failed rounds, include a Mermaid diagram visualizing the vote flow across rounds. Standard consensus results use the structured text Output Format without diagrams.

---

## Audit Trail

Reviewer independence is verifiable from docket records alone via naming conventions and field structure.

### Audit Questions

| Question | Docket Field | How to Check |
|---|---|---|
| Who proposed this vote? | `created_by` from `docket vote create` | `docket vote show {vote-id} --json` → `.created_by` |
| Which agents reviewed? | `voter` per vote from `docket vote cast` | `docket vote result {vote-id} --json` → each vote's `.voter` |
| What agent type was each reviewer? | `role` per vote from `docket vote cast` | `docket vote result {vote-id} --json` → each vote's `.role` |
| Were reviewers independent instances? | `voter` naming convention encodes `{vote-id}` | Verify each `.voter` matches pattern `{vote-id}-reviewer-{N}` |
| Was the proposer excluded? | `created_by` vs. all `role` values | Map `created_by` to agent type per the Reviewer Independence Enforcement section, then confirm no `.role` matches |
| Were all reviewers unique types? | All `role` values in the round | Confirm no duplicate `.role` values across votes |

### Verification Procedure

```bash
# 1. Show the proposal to see created_by
docket vote show {vote-id} --json
# -> Check .created_by field

# 2. Show the result to see all votes
docket vote result {vote-id} --json
# -> For each vote, check:
#    a. .voter matches pattern "{vote-id}-reviewer-{N}"
#    b. .role does not match the agent type of .created_by
#       (use the mapping table in "Reviewer Independence Enforcement")
#    c. No two votes have the same .role
```

