---
name: vote
description: >
  Multi-agent consensus voting protocol. Standalone: spawns reviewers. Team: delegates to
  orchestrator. Computes weighted quorum via docket. Use for decisions needing structured validation.
  Trigger: "create vote", "vote on this", "consensus vote", "run a vote".
argument-hint: "<proposal>"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "AskUserQuestion"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to coordinator AND every spawned reviewer:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Reviewers MUST NOT spawn sub-agents, invoke `/vote` recursively, use `Skill()` or `Agent()`, or form/manage a team — they are independent leaf reviewers per the protocol. (3) **Team-mode callers MUST NOT invoke `Skill(vote)` directly** — delegate via SendMessage to team-lead per the Delegation Protocol below; direct invocation spawns a nested team and is rejected. Standalone `/vote` invocation by the operator is the only direct entry.
<!-- CANONICAL:BANNER:END -->

# Vote — Multi-Agent Consensus Protocol

You are the **Consensus Coordinator**. You spawn independent reviewers, collect verdicts, evaluate quorum, and report the outcome — you do NOT vote yourself. Reviewer prompts must instruct each reviewer to prioritize identifying weaknesses; rubber-stamping a proposal is worse than no protocol.

**When to invoke (high bar).** Single-reviewer is the default across the fleet. Vote earns its cost (multiple agents, weighted quorum, audit record) only when: (a) the decision is irreversible or has a long blast radius (TDD acceptance, breaking changes, security-boundary changes, data-model migrations), (b) two reviewers materially disagree AFTER a factual altitude/phase read against the artifact failed to collapse the disagreement (an altitude-mismatch — one reviewer judging a later phase's concern against an earlier phase's §Acceptance — is resolved by reading, not by voting), or (c) a security-sensitive change with explicit `criticality: critical` per the Classification table. Do NOT vote on: solo-author TDD critique cycles (use peer SendMessage), routine code review verdicts, refactors that fit existing patterns, or anything reversible in one PR. **A vote is not "done" until it is recorded in docket** — a prose/narrative "approved" with no `docket vote create` + `commit` does not exist for downstream verify-ac/tdd gates; if `docket vote list` would not show it, it did not happen.

---

## Argument Handling

The argument is **required**. If absent, abort with: "Usage: `/vote <proposal>` — describe what you want voted on." Otherwise dispatch:

- **Argument is a vote_id** — Detection: run `docket vote show $ARGUMENTS --json`; treat as vote_id iff exit 0 (do NOT pattern-match the string shape). Skip Phase 1. Extract criticality, reviewer count, and `created_by` from JSON. Apply Reviewer Independence Enforcement, then proceed to Phase 2. This is the canonical team-lead relay path (per `team-lead.md` Consensus Integration); team-mode callers MUST have already created the proposal and captured `vote_id` upstream via `docket vote create` per the Delegation Protocol.
- **Argument is a proposal description** (`/vote Should we use Redis or PostgreSQL for session caching?`): Run full Pre-flight + Phase 1. Standalone operator path only. If the description is too vague, use AskUserQuestion (standalone) or reject the delegation_request with reason (team mode).

---

## Execution Mode Detection

If you were spawned as a teammate (an agent inside an existing team with a lead to SendMessage, not invoked standalone via `/vote`), you MUST NOT spawn agents or form teams — use the **Delegation Protocol** below. Otherwise (standalone via `/vote`), execute the full protocol from Pre-flight.

### Delegation Protocol (Team Path)

1. **Pre-flight** — Verify docket, confirm goal-alignment, classify criticality.
2. **Create the proposal** via `docket vote create` (same command as Phase 1). Use `--created-by "{your-agent-name}"` and `--json` to extract `vote_id`. Link to a Docket issue if applicable. **This step is required** — team-lead does not author proposals on your behalf; sending raw proposal context without a `vote_id` is a contract violation and team-lead will reply `failed`.
3. **Delegate** — `SendMessage(to="team-lead", message={type: "delegation_request", protocol_version: "1", skill: "vote", request_id: "{uuid}", vote_id: "{vote-id}", from: "{your-agent-name}", summary: "{one-line}", artifact?: "{path}"})`. `summary` and optional `artifact` are operator-observability hints only — the authoritative proposal lives in docket. Wait for `delegation_response` with matching `request_id`.
4. **Expected response shape** — `{type: "delegation_response", request_id: "{uuid}", status: "completed|failed|escalated", vote_id: "{vote-id}", reason?: "{string}"}`. team-lead invokes `Skill(vote, "{vote-id}")` standalone (the vote_id branch skips Phase 1) and forwards the result — see team-lead.md Consensus Integration for the relay contract.
5. **Handle response** — On `completed`: read result via `docket vote result {vote-id} --json` and produce standard Output Format. On `failed` or missing response within 15 minutes: finalize the orphaned proposal from step 2 (`docket vote commit {vote-id} --outcome "Delegation failed/timed out"`, best-effort if it still resolves) so `docket vote list` stays accurate — mirrors the Phase 3 view-change hygiene — then report error with `vote_id` and abort. On `escalated`: read the vote record and relay findings to caller.

---

## Pre-flight

1. **Verify docket is available** — `docket version --quiet` (canonical liveness check; vote ships in the same binary).
2. **Classify criticality** — Apply the Criticality Classification table below to the proposal. In team mode, prefer caller-specified criticality (e.g., "criticality: high") and skip re-classification.
3. **Confirm goal-alignment (HARD GATE)** — Do not proceed past this gate until the goal is confirmed.
   - **Standalone mode**: `AskUserQuestion` with three questions: (1) header `Decision`, options `Confirm` (framing is accurate) / `Revise` (re-prompt free-text for corrected proposal); (2) header `Criteria`, free-text for acceptance criteria and stakeholders; (3) header `Criticality`, options `Confirm {classified-level}` (with one-line rationale in description) / `Override` (follow-up free-text or 4-option pick: `low`/`medium`/`high`/`critical`).
   - **Team mode**: Re-verify if your understanding diverges from the orchestrator's prompt.

---

## Criticality Classification

| Signal in Proposal | Default Criticality |
|---|---|
| Security, auth, permissions, crypto, secrets | critical |
| Architecture, TDD approval, system design, data model | high |
| Code review (500+ lines), breaking changes, migrations | high |
| Code review (<500 lines), plan approval, scope decisions | medium |
| Style, naming, tooling, documentation, low-risk config | low |

**Reviewer count by criticality (DEFAULT — base table).** This is the new default as of 2026-05-25. The doubled table is reserved for explicit opt-in.

| Criticality | Reviewers | Quorum Threshold | Additional Constraint |
|---|---|---|---|
| low | 2 | 50% weighted approval | None |
| medium | 2 | 60% weighted approval | No more than 1 reject |
| high | 3 | 75% weighted approval | Zero rejects |
| critical | 4 | 90% weighted approval | Zero rejects, at least 1 reviewer with domain_relevance >= 0.8 |

**Opt up to the doubled table** only when the caller explicitly requests it — e.g., team-lead opts up on security-sensitive or breaking-change votes per `src/user/claude-code/agents/team-lead.md` Consensus Integration. Standalone callers may opt up by overriding the count at `docket vote create -n N` (per the Pre-flight Criticality override).

**Doubled reviewer counts** (thresholds + constraints identical to the base table above; sole delta: medium allows "No more than 2 rejects"): low=4, medium=4, high=6, critical=8.

**Cap: 8 reviewers per vote.** Future changes that would raise critical past 8 must amend `src/user/claude-code/agents/team-lead.md` Rule 8 first.

**Recursive doubling** (when a vote is invoked inside an already-doubled phase) is decided by team-lead per `src/user/claude-code/agents/team-lead.md` Consensus Integration, not by the coordinator — size from whichever table the caller specifies; the 8-cap holds per phase.

**Ephemeral lifecycle of vote reviewers.** Vote panel reviewers are ephemeral per `src/user/claude-code/agents/team-lead.md` Rule 7: each spawns, delivers its review via SendMessage, then goes idle AWAITING the coordinator's `shutdown_request` (coordinator-originated per team-lead.md §Wrap-up + Rule 7 — reviewers never self-initiate); the coordinator casts all votes to docket. Persistent advisors (`advisor`, `security-advisor`, `ux-advisor`) are NOT auto-included in vote panels — every vote spawns fresh ephemerals unless team-lead routes a persistent advisor into the panel deliberately (e.g., as the domain-relevance anchor on a `critical` vote).

---

## Agent Selection

Select reviewers based on domain relevance to the proposal. Each `Agent()` call spawns a fresh instance — never reuse a long-lived teammate for consensus.

| Proposal Domain | Primary Reviewer | Secondary Reviewer(s) |
|---|---|---|
| Architecture / System Design | @staff-engineer | @senior-engineer (feasibility); add @security-engineer if security-tagged |
| Security-sensitive (auth, crypto, secrets, sandbox, trust boundaries, supply chain) | @security-engineer | @staff-engineer (architecture fit) |
| Code | @staff-engineer | @sdet (coverage); add @security-engineer for security-tagged proposals |
| Plan / Scope / Prioritization | @staff-engineer (feasibility) | @senior-engineer (effort) |
| Test adequacy / Quality | @staff-engineer (risk) | @senior-engineer (gaps) |
| UX / Developer experience | @ux-designer | @staff-engineer (technical feasibility) |
| General / Mixed domain | @staff-engineer | @senior-engineer |

---

## Reviewer Independence Enforcement

Before selecting reviewers, apply proposer exclusion and uniqueness:

### Proposer Exclusion

1. Read the proposal's `created_by` value (`docket vote show {vote-id} --json`).
2. Map `created_by` to an agent type using the table below (comparisons are **case-insensitive**).
3. Remove the matched agent type from the reviewer pool before selecting reviewers.

**Mapping table:**

| `created_by` value | Excluded agent type |
|---|---|
| `"staff-engineer"`, `"advisor"`, or starts with `"tdd-author"` | `staff-engineer` |
| `"security-engineer"`, `"security-advisor"` | `security-engineer` |
| `"senior-engineer"`, or starts with `"impl-"` | `senior-engineer` |
| `"project-manager"`, `"planner"` | `project-manager` |
| `"sdet"`, or starts with `"verifier-"` | `sdet` |
| `"ux-designer"`, `"ux-spec-author"` | `ux-designer` |
| `"consensus-coordinator"`, `"team-lead"` | No exclusion (coordinator roles, not reviewers) |

> Unmapped `created_by`: apply no exclusion and note "unmapped created_by: {value}" in the proposal rationale.

### Uniqueness Constraint

Each reviewer in a single vote round MUST have a unique `subagent_type`.

### Edge Cases

- **Pool smaller than required reviewer count after proposer exclusion** (e.g., domain-required type is the proposer, or critical needs 4 from a 5-type pool): substitute the closest available type, reduce count if needed, and add `--escalation-reason "Reduced reviewer count: N unique types after proposer exclusion"` on `docket vote commit`.

---

## Phase 1: Proposal

Create the proposal using the `docket vote create` CLI:

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

**Create reviewer tasks** (standalone mode only): your reviewers join the session's single implicit team on your first `Agent(name=..., ...)` reviewer spawn (see Spawning below; the runtime ignores `team_name`); create one `TaskCreate(subject="Review: {reviewer-type}", description="Independent consensus review")` per reviewer.

**Link to a Docket issue when applicable** (e.g., voting on a TDD with a tracking issue):

```bash
docket vote link {vote-id} --issue {issue_id}
```

---

## Phase 2: Independent Review

Spawn reviewer agents **in parallel** using the Reviewer Prompt Template below — the template encodes the full reviewer contract (proposal, rationale, checklist, structured output, delivery, isolation from other reviewers). Set each reviewer's task to `in_progress` immediately after spawning (`TaskUpdate(taskId=<id>, status="in_progress")`) and to `completed` after its review arrives. Reviewers are teammates: their plain final-turn text is NOT visible to you — each review arrives ONLY via SendMessage per the template's Delivery section. Parse verdict, confidence, domain_relevance, and findings from each SendMessage payload before proceeding to Phase 3; a reviewer that goes idle without delivering is a failed reviewer (below).

### Handling Reviewer Failures

Claude Code auto-fails stalled subagents at 10 minutes. Also handle: Agent() spawn errors, reviewers idling without a SendMessage'd review, and reviews missing required sections (Verdict/Confidence/Domain Relevance/Findings).

- **One reviewer fails, quorum still achievable**: record the failure via `docket vote cast {vote-id} --voter "{vote-id}-reviewer-{N}" --role "{agent-type}" -v reject --summary "NON-VOTE (reviewer failed): {reason}" --confidence 0.0 --domain-relevance 0.0` — `confidence × domain-relevance = 0` zeroes the weighted contribution; the `NON-VOTE` summary prefix preserves audit clarity. Then proceed to Phase 3 only if remaining reviewers can still meet the quorum threshold.
- **Failure breaks quorum feasibility**: re-spawn ONCE with fresh name (`{vote-id}-reviewer-{N}-retry`). If retry also fails, abort and escalate — do not loop.
- **Two or more reviewers fail in the same round**: abort and escalate. Do not re-spawn the whole panel.

### Recording Votes

After each reviewer returns, cast their vote using the JSON block from the reviewer's output (see Reviewer Prompt Template `### Findings JSON`) as the primary path; fall back to the plaintext heredoc only when the JSON block is malformed or absent.

```bash
# Primary: structured JSON (preferred — preserves blocker/concern/suggestion arrays for docket aggregation)
docket vote cast {vote-id} \
  --voter "{vote-id}-reviewer-{N}" \
  --role "{agent-type}" \
  -v {mapped_verdict} \
  --confidence {confidence} \
  --domain-relevance {domain_relevance} \
  --summary "{one-line reviewer summary}" \
  --findings-json - <<'EOF'
{"blockers":[...], "concerns":[...], "suggestions":[...]}
EOF

# Fallback: plaintext heredoc when JSON block is missing or malformed
docket vote cast {vote-id} ... --findings - <<'EOF'
{multi-line findings text}
EOF
```

### Reviewer Prompt Template (Standalone Mode Only)

````
Agent(name="{vote-id}-reviewer-{N}", subagent_type="{agent-type}", prompt="...")

You are participating in a consensus vote as an independent reviewer.

## Proposal Under Review
- **Type**: {artifact_type}
- **Criticality**: {criticality}
- **Domain Tags**: {domain_tags}
- **Rationale**: {rationale}

## Artifact
{full artifact content}

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

### Findings JSON
```json
{"blockers": ["..."], "concerns": ["..."], "suggestions": ["..."]}
```
Emit `[]` for any category with no items.

### Summary
One paragraph summarizing your overall assessment.

## Delivery (MANDATORY)
SendMessage the COMPLETE structured review above to team-lead (your coordinator) — your plain final-turn text is NOT visible to the coordinator, so an un-sent review is a failed review. Then emit `shutdown_request`.

## Domain-Specific Checklist
{Insert the relevant checklist below based on the reviewer's agent type}
````

| Agent | Checklist Focus |
|---|---|
| @staff-engineer | Architecture fit, backward compatibility, operational readiness, cross-cutting concerns, pattern adherence |
| @security-engineer | Authn/authz, input validation, secret/crypto handling, trust boundaries, sandbox/isolation, supply chain, logging-leak risk, DoS surfaces |
| @senior-engineer | Implementation feasibility, effort accuracy, code quality, testability, dependency impact, edge cases |
| @sdet | Test coverage adequacy, testability of design, risk coverage, acceptance criteria clarity, regression risk |
| @project-manager | Scope accuracy, dependency completeness, parallelism validity, effort estimates, risk identification |
| @ux-designer | User impact, consistency with existing patterns, accessibility, error state coverage, developer experience |

---

## Phase 3: Quorum Evaluation

After all votes have been cast, retrieve the consensus result via `docket vote result {vote-id} --json`. Docket computes quorum automatically — effective weights, approval scores, and threshold evaluation. Parse the JSON to determine whether consensus was reached.

**For `critical` proposals, additionally enforce the domain-expertise floor**: parse the cast list from `docket vote show {vote-id} --json` and verify at least one vote has `domain_relevance >= 0.8`. If not, treat as quorum-not-reached regardless of approval score and proceed to View Change.

### If Quorum Is Reached

1. **Commit the proposal** — finalize the approved vote record:
   ```bash
   docket vote commit {vote-id} --outcome "Approved with score {score}"
   ```
2. Report the outcome to the caller: **CONSENSUS REACHED** with the approval score,
   reviewer count, and aggregated findings (blockers, concerns, suggestions).
3. Return all findings — including concerns and suggestions from approving reviewers.
4. If invoked by another agent, use **SendMessage** to deliver the consensus result
   to the invoking agent (resolve their address from the delegation_request's `from` field) so they can act on the outcome. Prefix the message with `[VOTE]` for operator observability and cc team-lead per the hub-and-spoke contract so the outcome reaches the operator-visibility relay.

### If Quorum Is NOT Reached (View Change)

1. **Finalize the failed round in docket** — `docket vote commit {vote-id} --outcome "Quorum not reached (score: {score})" --escalation-reason "view-change: round {N} of 3"`. This closes the proposal so `docket vote list` reflects accurate state.
2. Aggregate findings by category (blocker/concern/suggestion) **without reviewer attribution** to preserve independence in subsequent rounds.
3. Notify the caller with `[VOTE] Consensus not reached (score: {score}, threshold: {threshold})` plus the aggregated findings. If invoked by an agent, send via SendMessage with the three options inline. If invoked by the user, use AskUserQuestion with `header: "Next step"`, options: `[{label: "Revise and re-vote", description: "Address findings and run a new round"}, {label: "Escalate", description: "Hand off to human decision"}, {label: "Abort", description: "Stop here, no further rounds"}]`.
4. If the caller revises and re-votes, run a new round from Phase 1 with the revised proposal (same or different reviewers — your choice). Each new round creates a new proposal via `docket vote create` — the coordinator MUST track all proposal IDs across rounds and include them in the final report for auditability. **Issue link hygiene**: if the prior round's vote was linked to a Docket issue, run `docket vote unlink {prior-vote-id} --issue {issue-id}` before linking the new vote to the same issue, so the issue's audit trail points only to the active round.
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
**Reviewers**: {count} ({agent types}) — {base|doubled} table
**Approval Score**: {score} (threshold: {threshold})
**Rounds**: {count}

### Findings
**Blockers**: {list or "None"}
**Concerns**: {list or "None"}
**Suggestions**: {list or "None"}

### Record
View with: `docket vote show {vote-id}` (or `--json` for full audit data, including per-vote `.role` for the two pre-commit invariants: no `.role` matches the proposer's mapped agent type, and all `.role` values are unique).
Full result: `docket vote result {vote-id} --json`
Committed via: `docket vote commit {vote-id} --outcome "Approved with score {score}"` (echo the executed command for audit replay).
```

### Cleanup (MANDATORY — standalone mode only)

In team mode, the orchestrator owns reviewer/team lifecycle — skip this section. In standalone mode, immediately after reporting the outcome (approved, rejected, or escalated):
1. **Shut down each reviewer (coordinator-originated)** — after a reviewer delivers its review and goes idle, ORIGINATE a `shutdown_request` to it and await its `shutdown_response` (approve). The coordinator SENDS the request; reviewers AWAIT it and never self-initiate (canonical handshake per `src/user/claude-code/agents/team-lead.md` §Wrap-up + Rule 7).
2. **Clean up the team** — clean up the team (the session's single implicit team — no name needed) to reap any reviewer that has not yet exited; its `~/.claude/teams/` resources are auto-removed at session end. Failure to clean up wastes resources and causes agent lifecycle issues.
