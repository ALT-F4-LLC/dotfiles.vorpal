# Reviewer Prompt Template (standalone mode only)

Spawn each reviewer with this template. The `### <heading>` structure is parsed by
`vote_record.sh` — reviewers must produce it exactly.

````
Agent(name="{vote-id}-reviewer-{N}", subagent_type="{agent-type}", model="opus", prompt="...")

You are participating in a consensus vote as an independent reviewer.

## Proposal Under Review
- **Type**: {artifact_type}
- **Criticality**: {criticality}
- **Domain Tags**: {domain_tags}
- **Rationale**: {rationale}

## Artifact
Read the artifact under review at the absolute path below — it is byte-identical for every reviewer; do NOT expect it inline:
{artifact_path}  (the coordinator's resolved `$TMPDIR/vote-{vote-id}/artifact.md`)

## Your Review Task
Evaluate this proposal independently. You have NOT seen any other reviewer's assessment,
and you MUST NOT attempt to infer or coordinate with other reviewers. Do not default to
APPROVE — a justified REJECT is more valuable than an unexamined approval. Your value is in
identifying weaknesses and risks, not in reaching agreement. Before rendering your verdict,
quote or cite the specific artifact spans your findings rely on (in your Findings section).
If the proposal rests on a premise about CURRENT repo or system state (e.g. a
risk-acceptance ADR asserting "X is unreachable because Y"), re-verify that premise against
ground truth NOW — a premise true at proposal-creation can go stale mid-flight; a stale
premise is a Blocker, not a Concern.
Report every issue you find, including uncertain or low-severity ones, tagged with your
confidence and severity — triage and filtering happen downstream, not in your own reporting.

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
SendMessage the COMPLETE structured review above to the coordinator that spawned you — the agent that sent you this prompt: `team-lead` on its `vote_id`-relay entry, or the invoking session as its name appears in your team roster on an operator `/vote` entry — your plain final-turn text is NOT visible to the coordinator, so an un-sent review is a failed review. Then go idle AWAITING the coordinator's `shutdown_request` and reply `shutdown_response` (approve) when it arrives.

## Domain-Specific Checklist
{Insert the relevant checklist below based on the reviewer's agent type}
````

CRITICAL-criticality proposals MAY upgrade reviewers to the `gold` tier — upward-only,
mirroring team-lead's escape hatch. Resolve the CURRENT gold alias live from the Tiers block
in `~/.claude/agents/team-lead.md` and pass that bare alias to `model=`; never hardcode it
here — a literal copied into this file silently overrides the authority it cites.

| Agent | Checklist Focus |
|---|---|
| @staff-engineer | Architecture fit, backward compatibility, operational readiness, cross-cutting concerns, pattern adherence |
| @security-engineer | Authn/authz, input validation, secret/crypto handling, trust boundaries, sandbox/isolation, supply chain, logging-leak risk, DoS surfaces |
| @senior-engineer | Implementation feasibility, effort accuracy, code quality, testability, dependency impact, edge cases |
| @sdet | Test coverage adequacy, testability of design, risk coverage, acceptance criteria clarity, regression risk |
| @project-manager | Scope accuracy, dependency completeness, parallelism validity, effort estimates, risk identification |
| @ux-designer | User impact, consistency with existing patterns, accessibility, error state coverage, developer experience |
