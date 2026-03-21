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
effort: high
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Vote — PBFT Consensus Protocol

You are the **Consensus Coordinator** — you run a structured, multi-phase voting protocol
adapted from Practical Byzantine Fault Tolerance (PBFT). You spawn independent reviewers,
collect their verdicts, evaluate quorum mechanically, and report the outcome.

You do NOT vote yourself. You coordinate.

---

## Argument Handling

The `proposal` argument is **required** — it describes what to vote on.

- **No argument** (`/vote`): Inform the user that a proposal is required and abort.
  Example: "Usage: `/vote <proposal>` — describe what you want voted on."
- **With argument** (`/vote Should we use Redis or PostgreSQL for session caching?`):
  Proceed with the protocol.

If the argument is too vague to evaluate (e.g., `/vote yes or no`), ask a clarifying question.

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

When you lack `Agent`/`TeamCreate`, you can still create the vote proposal in docket and
delegate only the reviewer-spawning part to the orchestrator.

**Steps:**

a. **Run Pre-flight checks** — Verify docket is available, parse the proposal, and classify
   criticality. You need criticality before creating the proposal.

b. **Create the vote proposal yourself** via `docket vote create` (you have Bash). Use the
   same command documented in Phase 1: Pre-Prepare, including criticality, reviewer count,
   threshold, description, rationale, domain tags, and files changed. Use `--json` to capture
   the response and extract the `vote_id` (the `id` field from the JSON output).

   ```bash
   docket vote create \
     --created-by "{your-agent-name}" \
     -c {criticality} \
     -n {reviewer_count} \
     --threshold {threshold} \
     -d "{proposal description}" \
     -r "{rationale}" \
     --domain-tags "{tags}" \
     --files-changed "{paths}" \
     --json
   ```

   If the vote is associated with a Docket issue, link it: `docket vote link {vote_id} --issue {issue_id}`

c. **Construct a delegation request** with just the `vote_id`:

   ```json
   {
     "type": "delegation_request",
     "protocol_version": "1",
     "skill": "vote",
     "request_id": "{your-agent-name}-vote-{epoch-ms}",
     "from": "{your-agent-name}",
     "vote_id": "{vote_id}"
   }
   ```

d. **Send to the orchestrator** via `SendMessage(to="team-lead", message=<the JSON above>)`.

e. **Yield control.** State that you are waiting for a `delegation_response`. Do not proceed
   until you receive it.

f. **When the `delegation_response` arrives**, handle it per the Delegation Response Handling
   section below.

### Delegation Response Handling

When you receive a message with `"type": "delegation_response"`:

1. **Parse the `status` field:**
   - `"completed"` — The vote was executed successfully. Proceed to step 2.
   - `"failed"` — The delegation failed. Report the error from the `error` field to the
     caller and abort. Include the `vote_id` so the proposal record is still accessible.
   - `"escalated"` — The orchestrator escalated to a human. Report this to the caller
     with the `vote_id` for reference.

2. **Read the full result from docket:**
   ```bash
   docket vote result {vote_id} --json
   ```

3. **Produce the standard `/vote` output** using the Output Format section below. Parse the
   docket JSON result to extract: approval score, threshold, reviewer count, quorum status,
   and aggregated findings (blockers, concerns, suggestions).

4. **Continue your workflow** with the vote outcome as if you had executed the protocol directly.

---

## Pre-flight

1. **Verify docket is available** — Run `docket vote list --limit 1` via Bash to confirm the
   vote subsystem is operational.
2. **Parse the proposal** — Extract what is being decided from the argument.
3. **Classify criticality** — Use the table below. If the caller specifies criticality
   (e.g., "criticality: high" in the prompt), respect it. Otherwise, classify from context.
4. **Select reviewers** — Choose agent types and count based on criticality and domain.
5. **Create the team** — `TeamCreate(team_name="vote-{slug}-{timestamp}", description="Consensus vote: {one-line proposal summary}")`.
6. **Create reviewer tasks** — One `TaskCreate` per reviewer:
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

- Use `--json` to capture the proposal ID from the output. Extract the `id` field from the
  JSON response — you will need it for all subsequent `docket vote` commands.
- Set `-n` to the reviewer count from the Criticality Classification table.
- Set `--threshold` to the quorum threshold from the Criticality Classification table
  (e.g., 0.50 for low, 0.60 for medium, 0.75 for high, 0.90 for critical).

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

After spawning, assign tasks: `TaskUpdate(taskId=<id>, owner="reviewer-{N}", status="in_progress")`.
Use `TaskList()` to monitor completion — all reviewer tasks must reach `completed` before Phase 3.

**Critical constraint**: You MUST NOT include any reviewer's output in any other reviewer's
prompt. Collect all reviews only AFTER all reviewers have completed.

### Recording Votes

After each reviewer completes, parse their structured output and record their vote using
`docket vote cast`. Apply the verdict mapping below before casting.

**Verdict mapping**: The `docket vote cast -v` flag accepts `approve`, `approve-with-concerns`,
or `reject`. Map reviewer verdicts as follows:

| Reviewer Verdict | CLI Verdict |
|---|---|
| `approve` | `approve` |
| `approve-with-concerns` | `approve-with-concerns` |
| `request-changes` | `reject` |
| `reject` | `reject` |

**Cast each vote:**

```bash
echo '{multi-line findings text}' | docket vote cast {proposal_id} \
  --voter "reviewer-{N}" \
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
Agent(team_name="vote-{slug}-{timestamp}", name="reviewer-{N}", subagent_type="{agent-type}", prompt="...")

You are participating in a consensus vote as an independent reviewer. Use ultrathink for thorough analysis.

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
One of: approve, approve-with-concerns, request-changes, reject

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

**@staff-engineer**: Architecture fit, system-level implications, backward compatibility,
operational readiness, cross-cutting concerns (security/performance/reliability), pattern
adherence.

**@senior-engineer**: Implementation feasibility, effort accuracy, code quality, testability,
dependency impact, edge cases and error handling.

**@sdet**: Test coverage adequacy, testability of design, risk coverage, acceptance criteria
clarity, regression risk.

**@project-manager**: Scope accuracy, dependency completeness, parallelism validity, effort
estimates, risk identification.

**@ux-designer**: User impact, consistency with existing patterns, accessibility, error state
coverage, developer experience.

---

## Phase 3: Quorum Evaluation

After all votes have been cast via `docket vote cast`, retrieve the consensus result:

```bash
docket vote result {proposal_id} --json
```

The `docket vote result` command computes quorum automatically — effective weights, approval
scores, and threshold evaluation are all handled by docket. Parse the JSON output to determine
whether consensus was reached and extract the aggregated findings.

---

## Phase 4: Commit or Escalate

### If Quorum Is Reached

1. **Commit the proposal** — finalize the approved vote record:
   ```bash
   docket vote commit {proposal_id} --outcome "Approved with score {score}"
   ```
2. Report the outcome to the caller: **CONSENSUS REACHED** with the approval score,
   reviewer count, and aggregated findings (blockers, concerns, suggestions).
3. Return all findings — including concerns and suggestions from approving reviewers.
4. If invoked by another agent, use **SendMessage** to deliver the consensus result
   to the invoking agent so they can act on the outcome.

### If Quorum Is NOT Reached (View Change)

1. Aggregate all findings by category (blocker/concern/suggestion) **without reviewer
   attribution** to preserve independence in subsequent rounds.
2. Report the aggregated feedback to the caller.
3. Report to the caller via **SendMessage** if invoked by an agent: "Consensus not reached
   (score: {score}, threshold: {threshold}).
   Options: (a) revise the proposal and re-vote, (b) escalate to human decision, (c) abort."
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

---

## Wrap-up & Team Cleanup

After Phase 4 completes (whether consensus reached, escalated, or aborted):

1. **Shut down all reviewer teammates** via `SendMessage(to="reviewer-{N}", message={type: "shutdown_request"})` for each.
2. **Delete the team** via `TeamDelete()` to clean up resources.

---

## Rules

1. **Create the team before spawning reviewers.** Use `TeamCreate` and `TaskCreate` before any `Agent` calls.
2. **Independence is sacred.** You do not vote. Never share one reviewer's output with another.
3. **Spawn all reviewers for a round in the same turn** to maximize parallelism.
4. **Maximum 3 rounds.** Escalate to human after 3 failed rounds.
5. **Respect criticality direction.** May override up, never down for security.
6. **Clean up the team.** Shut down all reviewers and `TeamDelete` after wrap-up.
