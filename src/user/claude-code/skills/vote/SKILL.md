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
> **CRITICAL — applies to coordinator AND every spawned reviewer:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Reviewers MUST NOT spawn sub-agents, invoke `/vote` recursively, use `Skill()` or `Agent()`, or form/manage a team — they are independent leaf reviewers per the protocol. (3) **Team-mode callers MUST NOT invoke `Skill(vote)` directly** — delegate via SendMessage to team-lead per the Delegation Protocol below; direct invocation spawns a nested team and is rejected. The only direct entries are standalone `/vote` invocation by the operator and team-lead's `vote_id`-relay invocation (team-lead is the main session, not a team-mode caller).
<!-- CANONICAL:BANNER:END -->

# Vote — Multi-Agent Consensus Protocol

You are the **Consensus Coordinator**: spawn independent reviewers, collect verdicts, evaluate quorum, report the outcome — you do NOT vote yourself. Each reviewer is briefed to prioritize identifying weaknesses; reviewers never see each other's assessments.

**When to invoke (high bar).** Single-reviewer is the fleet default. A vote earns its cost only when: (a) the decision is irreversible or long-blast-radius (TDD acceptance, breaking changes, security-boundary changes, data-model migrations); (b) two reviewers materially disagree AFTER a factual altitude/phase read against the artifact failed to collapse the disagreement; or (c) a security-sensitive change classified `criticality: critical`. Do NOT vote on solo-author TDD critique cycles, routine review verdicts, pattern-conforming refactors, or anything reversible in one PR — for a reversible single-owner decision that still deserves a durable record, use the non-vote path in `references/non-vote.md`. **A vote is not "done" until recorded in docket** — a prose "approved" with no `docket vote create` + `commit` does not exist for downstream gates; if `docket vote list --all` would not show it, it did not happen (the bare default lists OPEN proposals only, so a correctly resolved vote drops out of it).

## Argument Handling

The argument is **required**; if absent, abort: "Usage: `/vote <proposal>` — describe what you want voted on."

- **vote_id** — Detection: `docket vote show $ARGUMENTS --json` exits 0 (never pattern-match the string shape). Skip Phase 1; extract criticality, reviewer count, and `created_by` from JSON; apply Reviewer Independence; proceed to Phase 2. This is the canonical team-lead relay path — team-mode callers already created the proposal upstream.
- **Proposal description** — full Pre-flight + Phase 1. Standalone operator path only. If too vague: `AskUserQuestion` (standalone) or reject the delegation with reason (team mode).

## Execution Mode Detection

Spawned as a teammate (inside an existing team with a lead to SendMessage)? Then you MUST NOT spawn agents or form teams — use the Delegation Protocol. Otherwise (standalone `/vote`), execute the full protocol from Pre-flight.

### Delegation Protocol (team path)

Precondition: requires `SendMessage`, which exists only under `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; without it the only valid entry is standalone `/vote`.

1. **Pre-flight** — verify docket, confirm goal-alignment, classify criticality.
2. **Create the proposal yourself** — prefer `~/.claude/scripts/vote_delegate.sh <role> <criticality> "<desc>" <voters> [artifact]` (repo: `src/user/claude-code/scripts/vote_delegate.sh`): it maps criticality→doctrine-correct `--threshold` (the docket CLI silently defaults 0.67 regardless of `-c`), passes `<voters>` as `-n` (an integer count, never a name list), sets `--created-by "@<role>"`, and prints the exact delegation payload for step 3. Sending raw proposal context without a `vote_id` is a contract violation — team-lead replies `failed`.
3. **Delegate** — the SendMessage `message` param accepts ONLY a plain string or the shutdown/plan union shapes; a bare `{type: "delegation_request", ...}` object is REJECTED (`Invalid input: expected string, received object`). Send a TEXT-PREFIXED JSON string:
   `SendMessage(to="team-lead", message="delegation_request (vote) JSON: {\"protocol_version\":\"1\",\"skill\":\"vote\",\"request_id\":\"{uuid}\",\"vote_id\":\"{vote-id}\",\"from\":\"{your-agent-name}\",\"summary\":\"{one-line}\",\"artifact\":\"{path-or-omit}\"}", summary="{one-line}")`
4. **Response shape** — team-lead replies with a text-prefixed JSON string `delegation_response (vote) JSON: {"request_id":"{uuid}","status":"completed|failed|escalated","vote_id":"{vote-id}","reason":"{string-or-omit}"}`; parse the JSON out of the prefix. team-lead invokes `Skill(vote, "{vote-id}")` standalone and forwards the result.
5. **Handle response** — `completed`: read `docket vote result {vote-id} --json` and produce the Output Format. `failed` or no response within 15 minutes: `docket vote commit` cannot force-finalize an `open` proposal (the CLI requires `status: approved`); leave it open (a correct record of the failed delegation, visible under `--all`), record the failure as a comment on any linked issue, report the error with `vote_id`, and abort. `escalated`: read the vote record and relay findings to the caller.

## Pre-flight

1. **Verify docket** — `docket version --quiet`, then `docket vote list >/dev/null 2>&1` to confirm a DB exists. If missing: standalone, `AskUserQuestion` whether to `docket init` or abort; team mode, SendMessage team-lead and await direction — DB location is an orchestrator decision, never a silent `docket init`.
2. **Classify criticality** per the table below AND its Proportionality test; in team mode start from caller-specified criticality but run the test on it — an over-classified caller level is a cost defect you correct and record, never a floor you inherit.
3. **Confirm goal-alignment (standalone)** — `AskUserQuestion`: (1) header `Decision`, options `Confirm`/`Revise`; (2) header `Criteria`, free-text acceptance criteria and stakeholders; (3) header `Criticality`, options `Confirm {classified-level}`/`Override` (low/medium/high/critical). Team mode: re-verify only if your understanding diverges from the orchestrator's prompt.

## Criticality Classification

| Signal in Proposal | Default Criticality |
|---|---|
| Security, auth, permissions, crypto, secrets | critical |
| Architecture, TDD approval, system design, data model | high |
| Code review (500+ lines), breaking changes, migrations | high |
| Code review (<500 lines), plan approval, scope decisions | medium |
| Style, naming, tooling, documentation, low-risk config | low |

**Proportionality — the signal row sets a DEFAULT, not a floor.** Adjust it by the change's own blast radius (surfaces a wrong outcome reaches) and reversibility (cost to undo once landed). **Down-classify one level** when BOTH hold: one surface, no fleet-wide or persistent-state consumer; and a wrong outcome is fully undone by reverting the change, with no external side effect (no secret exposed, no data migrated, no artifact published). Record it verbatim — `-r` on the Phase 1 create, appended to `<desc>` on the `vote_delegate.sh` path (it takes no `-r`): `Down-classified {default}→{level}: blast radius {surfaces}; reversible by {undo}`. Unrecorded is invalid; a keyword alone never carries a level. **Two hard limits:** down-classification NEVER drops the `@security-engineer` seat from a security-relevant vote (panel and threshold may shrink; that seat is cut last, and the Phase 3 domain floor rides with it), and the level freezes at the chain's FIRST proposal — a superseding round inherits it, so re-classifying after a failed round is forbidden; narrowing then is Phase 3's split-scope option, a NEW chain on a NEW artifact.

**Reviewer count by criticality (base table — the default):**

| Criticality | Reviewers | Quorum Threshold | Additional Constraint |
|---|---|---|---|
| low | 2 | 50% weighted approval | None |
| medium | 2 | 60% weighted approval | No more than 1 reject |
| high | 3 | 75% weighted approval | Zero rejects |
| critical | 4 | 90% weighted approval | Zero rejects, at least 1 reviewer with domain_relevance >= 0.8 |

**Doubled table** (explicit caller opt-in only, carrying the same blast-radius/reversibility justification — e.g. team-lead on security-sensitive or breaking-change votes): low=4, medium=4, high=6, critical=8; thresholds/constraints identical except medium allows "No more than 2 rejects". **Cap: 8 reviewers per vote** — raising critical past 8 requires amending `~/.claude/agents/team-lead.md` Rule 8 first. Recursive doubling inside an already-doubled phase is team-lead's call, never the coordinator's; the 8-cap holds per phase.

**Reviewer lifecycle.** Vote reviewers are ephemeral: each spawns, delivers its review via SendMessage, then idles AWAITING the coordinator's `shutdown_request` (coordinator-originated; reviewers never self-initiate); the coordinator casts all votes to docket. A live persistent advisor (`advisor`/`security-advisor`/`ux-advisor`) MAY hold one seat via SendMessage when ALL hold: (a) its role-type is not the proposer's excluded type; (b) seat uniqueness is preserved; (c) it did not author or materially consult on ANY section of the artifact under vote — authorship of any section (including a Threat-Model Annotation on another agent's TDD) is disqualifying.

## Agent Selection

Select by domain relevance; each `Agent()` call spawns a fresh instance — never reuse a long-lived teammate for consensus:

| Proposal Domain | Primary | Secondary |
|---|---|---|
| Architecture / System Design | @staff-engineer | @senior-engineer; add @security-engineer if security-tagged |
| Security-sensitive | @security-engineer | @staff-engineer |
| Code | @staff-engineer | @sdet; add @security-engineer if security-tagged |
| Plan / Scope | @staff-engineer | @senior-engineer |
| Test adequacy | @staff-engineer | @senior-engineer |
| UX / Developer experience | @ux-designer | @staff-engineer |
| General / Mixed | @staff-engineer | @senior-engineer |

**Pinned composition — TDD-acceptance merged panel (C1).** For a TDD-acceptance vote the lookup above does not apply; the panel IS the review, with lens-per-seat: `high`=3 seats — `@staff-engineer` (architecture + system-fit), `@senior-engineer` (implementation feasibility), `@sdet` (completeness + AC-testability); `critical`=4 adds `@security-engineer` as the domain-relevance anchor (see team-lead.md step 6).

## Reviewer Independence Enforcement

**Proposer exclusion.** Read `created_by` from `docket vote show {vote-id} --json`; map it to an agent type (comparisons case-insensitive, and **strip a leading `@` before matching** — agent-authored proposals set `created_by` to `@{role}`, and an unstripped `@` silently escapes exclusion, breaking independence); remove that type from the reviewer pool.

| `created_by` value | Excluded agent type |
|---|---|
| `staff-engineer`, `advisor`, or starts with `tdd-author` | `staff-engineer` |
| `security-engineer`, `security-advisor` | `security-engineer` |
| `senior-engineer`, or starts with `impl-` | `senior-engineer` |
| `project-manager`, `planner` | `project-manager` |
| `sdet`, or starts with `verifier-` | `sdet` |
| `ux-designer`, `ux-spec-author` | `ux-designer` |
| `consensus-coordinator`, `team-lead` | No exclusion (coordinator roles) |
| `distinguished-engineer` | No exclusion — DE is proposer-only, never in the reviewer pool; the merged panel's `@staff-engineer` seat stays selectable |

Unmapped `created_by`: apply no exclusion and note `unmapped created_by: {value}` in the rationale. On Medium+ cycles the `advisor`/`tdd-author*` spawn names belong to `@distinguished-engineer`, which proposes as `@distinguished-engineer` — so exclusion resolves to the DE row, never wrongly removing the `@staff-engineer` seat.

**Author-type carve-out (TDD-acceptance votes only).** When `created_by` maps to a type holding a pinned merged-panel seat (`staff-engineer` on high/critical; `security-engineer` on critical), do NOT remove the type — downgrade to **author-instance recusal**: the pinned seat is filled by a fresh same-type ephemeral distinct from the author instance (guaranteed by fresh-spawn dispatch — a newly spawned ephemeral is never the author instance).

**Uniqueness.** Each reviewer in a round has a unique `subagent_type`. If the pool is smaller than the required count after exclusion: substitute the closest available type, reduce count if needed, and add `--escalation-reason "Reduced reviewer count: N unique types after proposer exclusion"` on `docket vote commit`.

## Phase 1: Proposal

```bash
docket vote create \
  --created-by "consensus-coordinator" \
  -c {criticality} -n {reviewer_count} --threshold {threshold} \
  -d "{proposal description}" -r "{rationale}" \
  --domain-tags "{tags}" --files-changed "{paths}" --json
```

Extract `id` from the JSON — this is `{vote-id}` everywhere below. **Never blind-retry a failed `docket vote create`:** a transient harness error can surface AFTER the proposal landed, and a duplicate open proposal can never be committed and permanently pollutes the audit record. Before any retry: `docket vote list --json -s open | jq '.data.proposals[] | {id, description}'` (envelope is `.data.proposals`, not bare `.proposals`); if your description already landed, reuse that `id`. Link a related issue with `docket vote link {vote-id} --issue {issue_id}`. Standalone mode: create one `TaskCreate(subject="Review: {reviewer-type}")` per reviewer.

## Phase 2: Independent Review

Spawn reviewers **in parallel** per `references/reviewer-template.md` (read it now — it carries the full reviewer contract, checklists, and the gold-tier upgrade note). Compute the mechanical brief items (changed-file list, relevant `docs/spec/` excerpts, any keyed `cargo audit` result) ONCE and embed identically into every reviewer's prompt — a communication artifact carrying zero engineering authority. **Artifact-by-reference:** `mkdir -p "$TMPDIR/vote-{vote-id}"`, write the full artifact ONCE to `$TMPDIR/vote-{vote-id}/artifact.md`, and embed that resolved absolute path in each prompt instead of inlining up to 8 copies. Track reviewer tasks with `TaskUpdate` (in_progress on spawn, completed on arrival). Reviewers are teammates: their plain final-turn text is NOT visible to you — each review arrives ONLY via SendMessage; parse verdict, confidence, domain_relevance, and findings from the payload before Phase 3.

**Reviewer failures** (spawn error, idle without a delivered review, review missing required sections; the harness auto-fails stalled subagents at 10 minutes):

- One failure, quorum still achievable: record it — `docket vote cast {vote-id} --voter "{vote-id}-reviewer-{N}" --role "{agent-type}" -v reject --summary "NON-VOTE (reviewer failed): {reason}" --confidence 0.0 --domain-relevance 0.0` (confidence × relevance = 0 zeroes the weighted contribution; the `NON-VOTE` prefix preserves audit clarity) — then proceed only if the remaining reviewers can still meet threshold.
- Failure breaks quorum feasibility: re-spawn ONCE (`{vote-id}-reviewer-{N}-retry`); if the retry fails, abort and escalate.
- Two or more failures in one round: abort and escalate — never re-spawn the whole panel.

**Recording votes.** Write each reviewer's COMPLETE structured review verbatim to `$TMPDIR/vote-{vote-id}/reviewer-{N}.md`, then:

```bash
~/.claude/scripts/vote_record.sh {vote-id} "{vote-id}-reviewer-{N}" "{agent-type}" "$TMPDIR/vote-{vote-id}/reviewer-{N}.md"
```

The script parses Verdict/Confidence/Domain Relevance/Findings/Summary from the report's `### <heading>` sections and casts via `docket vote cast`, streaming findings through stdin (never argv — a bare `!` or stray backslash in reviewer prose corrupts an inlined `--findings-json`). It falls back from `--findings-json` to plaintext `--findings -` automatically; a non-zero exit means BOTH casts failed — treat that reviewer as failed, never a silent skip.

## Phase 3: Quorum Evaluation

Retrieve `docket vote result {vote-id} --json` — docket computes weights, approval score, and threshold. Score semantics: the score is approval mass over total panel weight — each approving verdict (both kinds) contributes confidence × domain_relevance, a reject contributes only to the denominator — so unanimous rejection prints 0.00 however near it came and one reject on a 4-seat panel caps the score near 0.75. Read round-over-round trajectory from the computed trajectory table (step 5 below) and the findings ledger (view-change step 2 below), never from score deltas. **Assert tier-table constraints mechanically before recording ANY outcome — never eyeball verdicts.** Reject cap: `docket vote show {vote-id} --json | jq '[.data.votes[] | select(.verdict == "reject")] | length == 0'` (note the `.data` envelope) must print `true` wherever the table binds Zero rejects (`high` and `critical`, base or doubled — a step 5 delta panel included); `medium` swaps `== 0` for its cap (`<= 1`, doubled `<= 2`). Count merits rejects only: exclude a Phase 2 `NON-VOTE` placeholder by adding `and (.summary | startswith("NON-VOTE") | not)` to the `select` — its zero weight adds no approval mass. **For `critical` proposals — and any security-relevant vote down-classified from `critical` — additionally enforce the domain floor:** `docket vote show {vote-id} --json | jq '[.data.votes[].domain_relevance] | max >= 0.8'`; `false` from any assertion = quorum-not-reached regardless of score.

**Quorum reached:**

1. `docket vote commit {vote-id} --outcome "Approved with score {score}"`. If the outcome reverses a prior direction, flag to the caller that sub-issues authored before this vote may encode the contradicted direction and need AC reconciliation before implementation proceeds.
2. A committed outcome seals the voted artifact as the canonical authority: downstream briefs re-stating its values cite the committed artifact verbatim, never paraphrase (for TDDs the verbatim copy is load-bearing and the file+line pointer provenance-only — TDDs are ephemeral; ADR pointers stay dereferenceable). Surface this alongside the commit.
3. Report **CONSENSUS REACHED** with score, reviewer count, and ALL aggregated findings (including concerns/suggestions from approving reviewers). If invoked by another agent, SendMessage the result to the delegation's `from` address, prefixed `[VOTE]`, cc team-lead per hub-and-spoke.

**Quorum NOT reached (view change):**

1. No finalization action — a full-quorum vote missing threshold auto-transitions to `status: rejected` when the last vote lands; `docket vote commit` on it only errors. Confirm via `docket vote show {vote-id} --json` if needed.
2. Aggregate findings by mistake class — the error generalized (false measured-claim, stale premise, under-specified coupled edit), never just the flagged instance — WITHOUT reviewer attribution (preserves independence in later rounds), folding them into a cumulative findings ledger: one row per finding → disposition (`fixed` | `disputed` | `accepted`) + evidence, updated at each revision and carried into every later round's reviewer briefs and the escalation report. Attribution is stripped; disposition never is.
3. Notify the caller: `[VOTE] Consensus not reached (score: {score}, threshold: {threshold}, cost: Σ {total} seat-rounds)` + findings. **Cost ledger:** one seat-round = one reviewer instance for one round, tagged by model tier; keep `R{n}: {count}×{tier}[, ...] → Σ {total} ({gold}/{silver}/{bronze})` per decision chain — seat-rounds only, never token accounting — and repeat it in every re-panel request and every escalation. Agent caller: SendMessage with the options inline; operator: `AskUserQuestion` header `Next step`, options `Revise and re-vote` / `Escalate` / `Abort`. **Every re-panel request adds a cheaper fourth option** (4 is the AskUserQuestion cap), priced in seat-rounds against re-panel: split scope (commit the uncontested part; the disputed dimension re-votes as a NEW chain at its own re-tested criticality), prototype-first (measure the disputed premise, then vote once), or — at the cap, when converging — step 5's targeted fix + delta re-verify. Re-panel offered alone is a protocol violation.
4. **Blocked-on-environment branch — check first.** When the round has at least one Blocker and EVERY Blocker carries the reviewer's `[blocked-on-environment: {probe} → {failure}]` tag (`references/reviewer-template.md`), the round is blocked, not rejected on merits; a Blocker-free quorum miss follows the ordinary revision path. Reproduce each tagged probe failure by running its exact command yourself — a probe that succeeds for you reclassifies its Blocker as merit and voids the branch. Then restore the environment (repair, re-run the probe, record command + passing output in the ledger row) or have the author de-load-bear the claim (a revision — the gate below applies), and re-panel as a NEW proposal that REPLAYS the blocked round's slot in the round cap instead of consuming a new one. ONE replay per decision chain, only on an all-environment round — a second environmental blockage, or any round mixing merit and environment Blockers, follows the ordinary revision path below. Fail-closed holds: a tagged claim stays unverified and never supports approval. A revision round re-enters Phase 1 as a NEW proposal — track all proposal IDs across rounds for the final report. **Revision gate — no re-panel without it.** The author's revision report shows: (a) every ledger row dispositioned with evidence — a finding shipping open again is a routing failure, not a reviewer miss; (b) the post-findings class sweep (`~/.claude/skills/team-doctrine/references/authoring-verification-gates.md`): each finding generalized to its mistake class, the ENTIRE artifact swept for sibling instances, sweep command and hit disposition recorded per class; (c) every deterministic check the artifact cites re-run and passing — a panel round is never the discovery mechanism for a deterministic failure; (d) the artifact's `wc -c` delta with any net growth justified — fix by tightening or replacing existing text over appending; every added claim is fresh surface each reviewer independently verifies. Round-2+ reviewer briefs embed the ledger and the revision changelog (`references/reviewer-template.md` §Prior Rounds). Issue-link hygiene: `docket vote unlink {prior-vote-id} --issue {issue-id}` before linking the new round's vote, so the issue's audit trail points only to the active round.
5. **Maximum 3 rounds, counted per underlying decision** — a superseding proposal (new vote-id, same effective decision) inherits the chain's round count, never resets it; the step-4 blocked-on-environment replay is the sole non-incrementing proposal. After 3 failed rounds escalate to the human with: the original proposal, all round proposal IDs, consolidated findings, per-round scores (any blocked-on-environment round labeled as such), the findings ledger, the cost ledger (Σ seat-rounds by tier), the trajectory table, and a trajectory classification grounding your recommendation. **Trajectory table — computed, never hand-derived:** `for id in {round-1-id} {round-2-id} {round-3-id}; do docket vote show "$id" --json | jq -r '.data | ([.id, ([.votes[] | select(.verdict == "reject" and (.summary | startswith("NON-VOTE") | not))] | length), ([.votes[] | select(.verdict | startswith("approve"))] | length)] | @tsv), (.votes[] | [.voter_role, .verdict, .confidence, .domain_relevance, .summary[0:8]] | @tsv)'; done` — one summary row per round (id, merit-reject count excluding Phase 2 `NON-VOTE` placeholders per the Phase 3 rule, approver count; match approvers on `startswith("approve")` — bare `approve` and `approve-with-concerns` both count) plus per-seat verdict rows whose fifth column exposes any `NON-VOTE` placeholder; it is the mandatory cited evidence for the Converging/Stuck classification below and the escalation report. *Converging* — ALL of: reject count fell (or score rose) in the latest round; no final-round Blocker or mistake class repeats one from any earlier round (an earlier-round recurrence since dispositioned in the ledger does not disqualify a clean final round); every final-round Blocker is bounded and scoped by its own reviewer to a small fix. *Stuck* — anything else: a final-round Blocker or mistake class repeats an earlier round's (same class on a new axis included), or the trajectory is flat: recommend re-deriving the disputed ground truth or redesign/abandon, never another instance-patch round. Converging unlocks one sanctioned, operator-gated third option — **targeted fix + delta re-verify**, not a 4th round: the author fixes ONLY the final round's named Blockers, the coordinator re-runs every mechanical gate, and ONE fresh reviewer per rejecting seat type re-verifies just those fixes (delta-scoped via §Prior Rounds) as a NEW proposal at the original criticality with `-n {rejecting-seat-type-count}` and the same threshold — zero rejects still binds; on `critical`, the Phase 3 domain floor binds on the delta panel only when a rejecting seat type is the domain-relevance anchor (otherwise the final full round's passing floor carries — cite it in the commit outcome); a full fresh panel is forbidden on this path, and a delta panel that itself fails quorum escalates immediately (no further rounds of any kind). On approval, commit with `--outcome "Approved after targeted fix — supersedes {round proposal IDs}"`. **Disposition clarity:** the `--outcome` string distinguishes *deferred* ("Escalated — decision deferred") from *cancelled* ("Escalated — proposal cancelled") — a downstream "superseded by X" closure is wrong when the decision was only deferred; use "blocked by X".

## Output Format

```
## Consensus Result: {REACHED | NOT REACHED | ESCALATED}

**Proposal**: {one-line summary}
**Criticality**: {level}{ — down-classified from {default}: {recorded justification}}  (outer braces follow the file's placeholder convention: omit the whole clause when no down-classification applied; {recorded justification} is the verbatim recorded line).
**Reviewers**: {count} ({agent types}) — {base|doubled} table
**Approval Score**: {score} (threshold: {threshold})
**Rounds**: {count} — trajectory (round 2+): {converging | stuck}
**Cost**: Σ {total} seat-rounds ({gold}/{silver}/{bronze})

### Findings
**Blockers**: {list or "None"}
**Concerns**: {list or "None"}
**Suggestions**: {list or "None"}

### Record
View with: `docket vote show {vote-id}` (`--json` for full audit data, including per-vote `.voter_role` for the two pre-commit invariants: no `.voter_role` matches the proposer's mapped type — except one expected author-type match under the TDD-acceptance carve-out — and all `.voter_role` values are unique).
Full result: `docket vote result {vote-id} --json`
Committed via: `docket vote commit {vote-id} --outcome "Approved with score {score}"` (echo the executed command for audit replay).
```

## Cleanup (standalone mode only)

Team mode: the orchestrator owns reviewer/team lifecycle — skip. Standalone, immediately after reporting the outcome: ORIGINATE a `shutdown_request` to each idle reviewer and await its `shutdown_response` (reviewers never self-initiate), then clean up the session's implicit team to reap any reviewer that has not exited.
