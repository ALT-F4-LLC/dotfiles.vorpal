# Non-Vote Decisions — durable record without a quorum

Not every documented decision needs a formal quorum vote. Use `vote_record.sh --non-vote`
instead of the full protocol when ALL hold: the decision is reversible, single-owner, and
stays within an already-approved plan/epic; none of the "When to invoke (high bar)"
criteria apply; and you still want a durable, auditable record of *what* was decided and
*why* without paying for reviewer spawns or quorum math. The moment any high-bar criterion
applies, run a formal vote instead.

**Recording mechanism.** `vote_record.sh --non-vote` parses a Decision/Rationale/Summary
report (same `### <heading>` convention as the vote-cast path) and records it as a
`docket doc` (type `decision`) — NOT a `docket vote` proposal — so it can never be mistaken
for a quorum outcome. It streams the body through `docket doc create -d "@<tmpfile>"`
rather than interpolating prose into argv.

```bash
~/.claude/scripts/vote_record.sh --non-vote "{decision-id}" "{recorder}" "{role}" "{report-file}" ["{issue-id}"]
```

- `decision-id`: a short label (e.g. `DKT-95-caching-approach`) used in the doc title — NOT a docket vote-id.
- `recorder` / `role`: identity recording the decision and its agent type.
- `report-file`: a file with `### Decision` and `### Rationale` sections (both required) and an optional `### Summary`.
- `issue-id` (optional): a Docket issue to link the resulting doc to.

Report format:

```
### Decision
One-line statement of what was decided.

### Rationale
The constraint, judgment call, or prior-approval context that settles it without a quorum.

### Summary
One paragraph summarizing the outcome (optional).
```

View recorded decisions with `docket doc list --json` (filter `type: decision`) or
`docket doc show {doc-id}` — distinct from `docket vote list`'s quorum records by design.
