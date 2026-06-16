---
name: vote
description: >
  Run a Codex-native multi-agent consensus vote for high-impact decisions such
  as TDD acceptance, breaking changes, security boundary changes, data-model
  migrations, or unresolved reviewer disagreement. Uses parent-led parallel
  Codex subagents and Docket when available.
---

# Vote

Coordinate a consensus vote. Do not commit changes.

## When To Use

Use voting sparingly:

- Irreversible or high-blast-radius decisions.
- Accepted design gates for TDDs or security-sensitive work.
- Material disagreement between reviewers that remains after checking facts.
- Critical security or data-model decisions.

Do not vote on routine reviews, reversible refactors, or questions a single
owner can decide.

## Workflow

1. Define the proposal in one sentence, the decision owner, criticality, and
   acceptance criteria.
2. If Docket is available, create or update a durable vote record before
   dispatching reviewers.
3. Select reviewers by domain:
   - General architecture: `staff-engineer`.
   - Security-sensitive: `security-engineer`.
   - User-facing: `ux-designer`.
   - Testability or criteria risk: `sdet`.
   - Implementation feasibility: `senior-engineer`.
4. Spawn independent Codex subagents in parallel from the parent session. Each
   reviewer receives only the proposal, relevant artifacts, criticality, and
   required output format.
5. Reviewers return a final report with vote, confidence, domain relevance,
   blockers, concerns, and evidence.
6. Compute the outcome:
   - Critical blocker from a highly relevant reviewer prevents approval.
   - Approval requires a majority of relevant reviewers and no unresolved
     critical blocker.
   - Low-confidence or low-relevance votes are advisory.
7. Record the result in Docket when available.

## Reviewer Prompt Template

```text
Review this proposal independently.

Proposal:
Criticality:
Artifacts:
Decision criteria:

Return:
- Vote: approve | approve-with-caveats | block
- Confidence: low | medium | high
- Domain relevance: low | medium | high
- Blockers:
- Concerns:
- Evidence:
```

## Output

```markdown
Vote Result: APPROVED | APPROVED WITH CAVEATS | NOT APPROVED
Proposal:
Reviewers:
Score:
Blocking Findings:
Conditions:
Evidence:
Next Step:
```
