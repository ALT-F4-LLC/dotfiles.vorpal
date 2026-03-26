---
project: "dotfiles.vorpal"
maturity: "draft"
last_updated: "2026-03-22"
updated_by: "@staff-engineer"
scope: "Enforce reviewer independence in the vote skill: proposer exclusion, unique agents per vote, deterministic naming, and auditable participation records"
owner: "@staff-engineer"
dependencies:
  - agent-delegation-protocol.md
  - ../spec/architecture.md
---

# Vote Reviewer Independence

## 1. Problem Statement

### What

The `/vote` skill spawns independent sub-agents as reviewers for consensus decisions. However, the current skill instructions contain no explicit mechanism to:

1. **Prevent the proposing agent from reviewing its own proposal.** The `--created-by` field in `docket vote create` records who created the proposal, but nothing in the reviewer selection or spawning logic checks this field before selecting reviewers. A coordinator could inadvertently select the same agent type as the proposer for review.

2. **Prevent duplicate agent types in a single vote round.** The Agent Selection table maps proposal domains to reviewer types, but there is no explicit constraint preventing the same agent type from appearing twice in one round. The criticality table allows 3-4 reviewers for critical votes, but there are only 5 agent types total -- if the proposer is excluded, that leaves 4 available types. The edge case where criticality demands more reviewers than available unique types is undocumented.

3. **Provide a verifiable audit trail of reviewer independence.** The `docket vote cast` command records `--voter` and `--role`, but the current naming convention (`reviewer-{N}`) is a simple incrementing counter that does not encode which vote a reviewer belongs to. Nothing prevents naming collisions across concurrent or sequential votes. The docket record does not explicitly capture that each reviewer was a freshly spawned, independent agent instance.

4. **Enforce a deterministic naming convention.** Reviewer names (`reviewer-{N}`) are not tied to the vote ID, making it impossible to audit from the name alone whether an agent was scoped to a specific vote or reused across votes.

### Why Now

The `/vote` skill is a hard gate for TDD approval (`@staff-engineer` MUST invoke `/vote`), design spec approval (`@ux-designer` MUST invoke `/vote`), and is available to all five agents for high-stakes decisions. Independence is described as "sacred" in the current rules (Rule 2), but the instructions rely on implicit trust rather than explicit enforcement. As the team scales its use of consensus voting, implicit independence becomes insufficient -- a single instance of a proposer reviewing their own TDD would undermine the credibility of the entire consensus mechanism.

### Constraints

- Changes are confined to `skills/vote/SKILL.md` and `skills/dev/SKILL.md` (the delegation handler). No Rust code, no docket CLI changes, no new tooling.
- The existing `docket vote cast` fields (`--voter`, `--role`, `--confidence`, `--domain-relevance`, `--summary`, `--findings`) must be sufficient for the audit trail, or the TDD must document exactly what additional metadata is needed and how to encode it within existing fields.
- The solution must work for both direct execution (coordinator has `Agent`/`TeamCreate`) and delegated execution (orchestrator spawns reviewers on behalf of a sub-agent).
- Out of scope: PBFT quorum logic, weighting, consensus thresholds, and docket CLI commands/internals. Only the vote skill's reviewer spawning and management is in scope.

### Acceptance Criteria

1. The vote skill instructions contain an explicit **proposer exclusion check** that compares the `--created-by` value against the reviewer selection list and removes matching agent types before spawning.
2. The vote skill instructions contain an explicit **uniqueness constraint** that prevents the same agent type from being selected more than once per vote round, with a documented fallback for the edge case where criticality requires more reviewers than available unique types.
3. The vote skill instructions define a **reviewer naming convention** that encodes the vote ID and a sequence number (e.g., `{vote-id}-reviewer-1`), making it impossible to accidentally reuse an agent name across votes.
4. The docket vote record (viewable via `docket vote show`) contains sufficient information to verify: (a) which sub-agents participated as reviewers, (b) their agent types, (c) the proposer identity, (d) that each reviewer was independently spawned. This verification must be achievable using existing `docket vote cast` fields (`--voter`, `--role`) plus the `--created-by` field from `docket vote create`.
5. The team name for vote teams encodes the vote ID (e.g., `vote-{vote-id}-{timestamp}`), scoping the team lifecycle to that specific vote.
6. All changes work correctly in both direct execution and delegated execution paths.

---

## 2. Context & Prior Art

### Current State

**Vote skill (`skills/vote/SKILL.md`):**
- The coordinator creates a team named `vote-{slug}-{timestamp}` and spawns reviewers named `reviewer-{N}` with `subagent_type="{agent-type}"`.
- `docket vote create` accepts `--created-by` (defaults to git user.name). In the delegation path, the sub-agent sets `--created-by "{your-agent-name}"`. In the direct path, the coordinator sets `--created-by "consensus-coordinator"`.
- `docket vote cast` records `--voter "reviewer-{N}"` and `--role "{agent-type}"` per vote.
- Rule 2 states "Independence is sacred. You do not vote. Never share one reviewer's output with another." but does not address proposer-as-reviewer or duplicate agent types.
- The Agent Selection table maps domains to reviewer types but does not reference `--created-by` for exclusion.

**Delegation protocol (`docs/tdd/agent-delegation-protocol.md`):**
- When a sub-agent (e.g., `@staff-engineer`) invokes `/vote`, it creates the proposal via `docket vote create --created-by "{your-agent-name}"` and delegates reviewer spawning to the orchestrator.
- The orchestrator reads the proposal via `docket vote show {vote_id} --json`, which includes the `created_by` field.
- The orchestrator then follows the `/vote` protocol for spawning reviewers, meaning any independence enforcement in the vote skill applies equally to the delegation path.

**Existing docket fields available for audit:**

| Field | Source | Content |
|-------|--------|---------|
| `created_by` | `docket vote create --created-by` | Proposer identity (agent name or "consensus-coordinator") |
| `voter` | `docket vote cast --voter` | Reviewer instance name |
| `role` | `docket vote cast --role` | Agent type (e.g., "staff-engineer", "senior-engineer") |
| `confidence` | `docket vote cast --confidence` | Self-assessed confidence |
| `domain_relevance` | `docket vote cast --domain-relevance` | Self-assessed domain relevance |
| `summary` | `docket vote cast --summary` | One-line review summary |
| `findings` | `docket vote cast --findings` | Full review findings |

**Historical vote record (`.docket/consensus/consensus-agents-user-space-1710892800.json`):**
- Records `reviewer` (e.g., `"@staff-engineer"`) and `verdict`, `confidence`, `domain_relevance`, `effective_weight`, and `findings` per review.
- Does not record the `voter` instance name (only the role/type). This is the older consensus format -- the current `docket vote cast` CLI does record both `--voter` and `--role` separately.

### How This Is Solved Elsewhere

**Jury selection (legal system):** Jurors with a relationship to the parties or case are excluded for cause. The selection process is documented and challengeable. The analogue: the proposer has a "relationship" to the proposal and must be excluded.

**Peer review (academic journals):** Reviewers are assigned by an editor (coordinator), must declare conflicts of interest, and are anonymized to each other. Double-blind review prevents authors from knowing reviewers and vice versa. The `/vote` skill already prevents reviewers from seeing each other's output (Rule 2) -- the missing piece is conflict-of-interest exclusion.

**Byzantine fault tolerance (distributed systems):** PBFT requires that faulty replicas are a minority. A proposer reviewing their own proposal is equivalent to a single node controlling two votes -- it undermines the quorum assumption. The BFT solution: distinct replica identities with verifiable independence.

---

## 3. Alternatives Considered

### Alternative A: Implicit Trust (Status Quo)

Rely on the coordinator's judgment to select appropriate reviewers and trust that it will not select the proposer.

**Strengths:**
- Zero implementation effort.
- Flexible -- coordinator can adapt to unusual situations.

**Weaknesses:**
- Relies on LLM judgment, which can fail under complex prompts or context pressure.
- No audit trail of independence decisions -- impossible to verify after the fact.
- No documented policy for edge cases (more reviewers needed than types available).
- As vote frequency increases, probability of accidental violation increases.

**Verdict:** Rejected. The current system's Rule 2 ("independence is sacred") contradicts relying on implicit trust for enforcement.

### Alternative B: Explicit Exclusion Rules in Skill Instructions (Recommended)

Add explicit instructions to the vote skill that:
1. Extract `created_by` from the proposal and exclude that agent type from reviewer selection.
2. Enforce unique agent types per round.
3. Use a naming convention that encodes the vote ID.
4. Document how existing docket fields constitute the audit trail.

**Strengths:**
- Enforced by explicit instructions, not coordinator judgment.
- Uses existing docket fields -- no CLI changes needed.
- Deterministic naming makes audit trivial.
- Covers both direct and delegated execution paths.

**Weaknesses:**
- Instruction-level enforcement depends on the LLM following instructions. Not cryptographically enforced.
- Adds complexity to the vote skill instructions.

**Verdict:** Recommended. Instruction-level enforcement is the strongest mechanism available in a prompt-driven agent system. The alternative (code-level enforcement) would require docket CLI changes, which are out of scope.

### Alternative C: Docket CLI Enforcement

Add `--exclude-proposer` flag to `docket vote cast` that rejects votes where the `--role` matches `created_by`.

**Strengths:**
- Hard enforcement at the CLI level -- cannot be bypassed by instruction drift.
- Clean separation of policy and mechanism.

**Weaknesses:**
- Requires changes to docket internals (out of scope).
- Docket would need to understand agent types, creating coupling between the vote system and the agent team structure.
- Over-engineering for the current scale -- the bottleneck is instruction quality, not policy enforcement.

**Verdict:** Rejected. Out of scope per constraints, and the instruction-level approach is sufficient for the current agent team size and vote frequency.

---

## 4. Architecture & System Design

### Design Principle: Encode Independence in Names and Records

The core insight is that **independence is verifiable when reviewer identity encodes vote scope**. If a reviewer's name contains the vote ID, you can verify from the docket record alone that:
- Each reviewer was spawned for this specific vote (not reused from another vote or existing team).
- No two reviewers share the same name (Claude Code agent names are unique within a team).
- The proposer's agent type does not appear in the reviewer list.

### Proposer Exclusion Mechanism

The coordinator (or delegation handler) must perform this check before selecting reviewers:

```
1. Read the proposal's `created_by` field.
2. Map `created_by` to an agent type:
   - "consensus-coordinator" -> no exclusion (coordinator is not an agent type)
   - "@staff-engineer" or "staff-engineer" or agent names containing "staff-engineer" -> exclude staff-engineer type
   - Similarly for all agent types: senior-engineer, project-manager, sdet, ux-designer
3. Remove the matched agent type from the available reviewer pool.
4. Select reviewers from the remaining pool using the Agent Selection table.
```

**Mapping `created_by` to agent type:**

In the delegation path, `created_by` is set to the sub-agent's name (e.g., `"staff-engineer"`, `"tdd-author"`, `"advisor"`). These names may not directly match agent type identifiers. The mapping rule is:

| `created_by` value | Excluded agent type |
|---|---|
| Contains "staff-engineer" or is "tdd-author" or is "advisor" or is "reviewer" | `staff-engineer` |
| Contains "senior-engineer" or starts with "impl-" | `senior-engineer` |
| Contains "project-manager" or is "planner" | `project-manager` |
| Contains "sdet" or starts with "verifier-" | `sdet` |
| Contains "ux-designer" or is "ux-spec-author" | `ux-designer` |
| Is "consensus-coordinator" or "team-lead" | No exclusion (these are coordinator roles, not reviewers) |

This mapping covers all names used in the `/dev` spawning templates (`agents/staff-engineer.md` through `agents/ux-designer.md`) and the vote skill itself.

In practice, the most common case is `@staff-engineer` invoking `/vote` for TDD approval, where `created_by` will be one of `"staff-engineer"`, `"tdd-author"`, or `"advisor"`. All three map to the `staff-engineer` agent type for exclusion.

### Uniqueness Constraint

**Rule:** Each reviewer in a single vote round MUST be a unique agent type. No `subagent_type` value may appear more than once in the `Agent()` calls for a single round.

**Edge case -- more reviewers needed than available types:**

With the proposer excluded, the available pool has at most 4 agent types (out of 5 total). The criticality table requires:
- Low/Medium: 2 reviewers -- always satisfiable (4 available).
- High: 3 reviewers -- always satisfiable (4 available).
- Critical: 3-4 reviewers -- satisfiable (4 available), but only just. If the critical domain requires a specific type that was excluded as the proposer, the selection table may not have enough domain-relevant types.

**Fallback for critical votes requiring 4 reviewers with proposer excluded:**

When 4 reviewers are required and the proposer is excluded (leaving exactly 4 available types), all 4 remaining types must be used. If the domain normally requires a type that was excluded, substitute the closest available type and document the substitution in the docket proposal description (via a comment or updated rationale).

**Fallback if fewer unique types exist than reviewers needed (future-proofing):**

If the team ever shrinks below 4 agent types (unlikely), reduce the reviewer count to the number of available unique types and add `--escalation-reason "Reduced reviewer count: only N unique agent types available after proposer exclusion"` to the `docket vote commit`.

### Reviewer Naming Convention

**Current:** `reviewer-{N}` (e.g., `reviewer-1`, `reviewer-2`)

**Proposed:** `{vote-id}-reviewer-{N}` (e.g., `DKT-V5-reviewer-1`, `DKT-V5-reviewer-2`)

Where:
- `{vote-id}` is the docket proposal ID (e.g., `DKT-V5`), extracted from the `docket vote create --json` response.
- `{N}` is a 1-indexed sequence number assigned at spawn time.

**Properties of this convention:**
- **Vote-scoped:** The name contains the vote ID, so it is impossible to confuse a reviewer from vote DKT-V5 with one from DKT-V6.
- **Unique within a team:** Claude Code enforces unique agent names within a team. Combined with the vote-scoped team name (below), this prevents any name collision.
- **Auditable:** Given a docket vote record, the `--voter` field directly links to a specific vote and sequence.

### Team Naming Convention

**Current:** `vote-{slug}-{timestamp}`

**Proposed:** `vote-{vote-id}` (e.g., `vote-DKT-V5`)

Rationale: The vote ID already contains enough uniqueness (docket assigns monotonically increasing IDs). Using the vote ID directly makes team-to-vote correlation trivial. The timestamp is redundant since the docket record already has timestamps.

### Audit Trail Design

The audit trail is composed entirely of existing docket fields. No new fields or metadata are needed.

**What the docket record already captures:**

| Audit Question | Field | Source |
|---|---|---|
| Who proposed this vote? | `created_by` | `docket vote create --created-by` |
| Which agents reviewed? | `voter` per vote | `docket vote cast --voter "{vote-id}-reviewer-{N}"` |
| What agent type was each reviewer? | `role` per vote | `docket vote cast --role "{agent-type}"` |
| Were reviewers independent instances? | `voter` naming convention | Name encodes `{vote-id}`, proving vote-scoped spawning |
| Was the proposer excluded? | `created_by` vs. all `role` values | Verify that no `role` matches the `created_by` agent type |
| Were all reviewers unique types? | All `role` values in the round | Verify no duplicate `role` values in the same round |

**Verification procedure (human or automated):**

```bash
# 1. Show the proposal to see created_by
docket vote show {vote-id} --json
# -> Check .created_by field

# 2. Show the result to see all votes
docket vote result {vote-id} --json
# -> For each vote, check:
#    a. .voter matches pattern "{vote-id}-reviewer-{N}"
#    b. .role does not match the agent type of .created_by
#    c. No two votes have the same .role
```

No additional metadata fields are needed. The combination of `created_by`, `voter` (with vote-ID-encoded naming), and `role` is sufficient to verify all four independence properties.

### Integration with Delegation Path

When the orchestrator handles a delegation request:

1. Read the proposal via `docket vote show {vote-id} --json`.
2. Extract the `created_by` field from the response.
3. Apply the proposer exclusion mapping to determine which agent type to exclude.
4. Select reviewers from the remaining pool.
5. Create the team as `vote-{vote-id}`.
6. Spawn reviewers as `{vote-id}-reviewer-{N}` with `subagent_type` set to the selected agent types.
7. Cast votes using the same naming convention.

This is identical to the direct execution path. The delegation handler in `/dev` already reads the proposal from docket (step 2) and follows the `/vote` protocol for spawning (steps 3-7). The only change is adding the exclusion check and updated naming.

---

## 5. Risks & Open Questions

### Known Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Coordinator ignores exclusion instructions under context pressure | Low | High (undermines independence guarantee) | The exclusion check is a numbered step early in the protocol, before reviewer selection. Hard to skip accidentally. The audit trail provides post-hoc verification. |
| `created_by` value does not match any known agent type pattern | Low | Medium (no exclusion applied) | The mapping table covers all current names from `/dev` templates. Add a fallback: if `created_by` does not match any known type, log a warning in the docket rationale but proceed (conservative -- better to have an extra-independent reviewer than to block). |
| Vote-ID-encoded names make prompts longer | Very Low | Very Low | Vote IDs are short (e.g., `DKT-V5`). Adding ~8 characters to agent names has negligible impact. |
| Multiple rounds of the same vote reuse reviewer names | Low | Medium (name collision if same team name) | Each round creates a new proposal via `docket vote create` (per existing skill instructions), getting a new vote ID. New round = new team = new names. No collision possible. |

### Open Questions

1. **Should the coordinator verify exclusion in the docket record after casting?** That is, after all votes are cast, should it run the verification procedure above and abort if independence was violated? **Recommendation:** No. Post-hoc verification is valuable for human auditors but adds complexity to the coordinator's flow. The exclusion check before spawning is sufficient for instruction-level enforcement. Post-hoc verification is a future enhancement if trust in instruction compliance degrades.

2. **Should `created_by` normalization be case-sensitive?** The mapping table uses lowercase patterns. If an agent sets `--created-by "Staff-Engineer"`, the contains-check might miss it. **Recommendation:** The skill instructions should specify case-insensitive comparison explicitly. In practice, all agent names in the current system are lowercase.

### Assumptions

- The docket vote ID (`DKT-V{N}`) is stable, monotonically increasing, and unique across the project. This is guaranteed by docket's SQLite-backed ID generation.
- Agent names in Claude Code teams must be unique within a team. If two agents have the same name in the same team, the framework prevents or errors. This is assumed based on the `Agent()` tool's behavior.
- The `docket vote show {vote-id} --json` output includes the `created_by` field. This is assumed based on the CLI help showing `--created-by` as a create-time field.

---

## 6. Testing Strategy

### Key Scenarios

1. **Proposer exclusion -- direct path:** Invoke `/vote` directly (coordinator has `Agent`/`TeamCreate`). Verify that the reviewer selection excludes the proposer's agent type. Check `docket vote result` to confirm no `role` matches `created_by`.

2. **Proposer exclusion -- delegation path:** Have `@staff-engineer` invoke `/vote` via delegation. Verify the orchestrator reads `created_by` from the proposal and excludes `staff-engineer` type from reviewers.

3. **Unique agent types:** For a high-criticality vote requiring 3 reviewers, verify all three have distinct `role` values in the docket record.

4. **Critical vote with proposer excluded (4 reviewers needed, 4 available):** Verify all 4 remaining types are selected and no duplicates exist.

5. **Naming convention:** Verify `--voter` values in docket follow `{vote-id}-reviewer-{N}` pattern and team name follows `vote-{vote-id}`.

6. **Audit trail completeness:** Run `docket vote show` and `docket vote result` after a completed vote. Verify that `created_by`, `voter`, and `role` fields are sufficient to answer all four audit questions from the Audit Trail Design section.

### Verification Approach

Since all changes are markdown instruction changes, testing is done by running `/vote` end-to-end (both direct and delegated) and inspecting the docket records. The SDET verifies:

- Reviewer `--voter` names match the `{vote-id}-reviewer-{N}` pattern.
- Reviewer `--role` values are all distinct within a single vote round.
- No reviewer `--role` matches the proposer's agent type (mapped from `created_by`).
- Team name follows `vote-{vote-id}`.
- The docket record is self-contained for independence verification (no external data needed).

---

## 7. Implementation Phases

### Phase 1: Proposer Exclusion and Uniqueness Constraint (S)

**Changes:** `skills/vote/SKILL.md`

Add a new section "Reviewer Independence Enforcement" between "Agent Selection" and "Phase 1: Pre-Prepare". This section contains:

a. **Proposer exclusion rule:** After classifying criticality and before selecting reviewers, read the proposal's `created_by` field (or, in the direct path, the value that will be passed to `--created-by`). Map it to an agent type using the mapping table. Remove that type from the available reviewer pool.

b. **Uniqueness constraint:** State explicitly that each reviewer in a round must have a unique `subagent_type`. No agent type may appear twice.

c. **Edge case handling for critical votes:** When 4 reviewers are needed and only 4 types remain after exclusion, use all 4. If fewer types are available than reviewers needed, reduce count and add escalation reason.

d. **Case-insensitive matching:** All `created_by` comparisons must be case-insensitive.

**Also update in this phase:**
- The Agent Selection table: add a note that the proposer's type is always excluded.
- Rule 2: expand from "You do not vote" to "You do not vote. The proposer's agent type is excluded from reviewer selection."

### Phase 2: Naming Convention (S)

**Changes:** `skills/vote/SKILL.md`

Update all references to reviewer and team naming:

a. **Team name:** Change `vote-{slug}-{timestamp}` to `vote-{vote-id}` in the Pre-flight step 6 (`TeamCreate`) and the Reviewer Prompt Template.

b. **Reviewer name:** Change `reviewer-{N}` to `{vote-id}-reviewer-{N}` in:
   - Pre-flight step 7 (TaskCreate)
   - Phase 2: Prepare (TaskUpdate, agent spawning)
   - Recording Votes (docket vote cast `--voter`)
   - Reviewer Prompt Template (`Agent(... name=...)`)
   - Wrap-up (shutdown_request SendMessage `to` field)

c. **Vote cast `--voter` field:** Explicitly document that the `--voter` value MUST be the agent's full name (`{vote-id}-reviewer-{N}`), not a shortened form.

### Phase 3: Audit Trail Documentation (S)

**Changes:** `skills/vote/SKILL.md`

Add a new section "Audit Trail" after the Rules section. This section documents:

a. The four audit questions and which docket fields answer them (from the Audit Trail Design table above).

b. The verification procedure (the three `docket vote` commands and what to check in the output).

c. A statement that no additional metadata is needed beyond the existing `created_by`, `voter`, and `role` fields -- the naming convention makes the audit trail self-contained.

### Phase 4: Delegation Handler Update (S)

**Changes:** `skills/dev/SKILL.md`

Update the "Handling Delegation Requests" section to include:

a. After reading the proposal via `docket vote show`, extract the `created_by` field.

b. Apply the proposer exclusion mapping before selecting reviewers.

c. Use the `vote-{vote-id}` team name and `{vote-id}-reviewer-{N}` naming convention when spawning reviewers.

d. Note that the independence rules from the `/vote` skill apply equally to delegated execution.

### Dependencies

```
Phase 1 ──> Phase 2 (naming convention references the same sections as exclusion rules)
Phase 1 ──> Phase 3 (audit trail documents the exclusion mechanism)
Phase 1 ──> Phase 4 (delegation handler applies the exclusion rules)
Phase 2 ──> Phase 3 (audit trail references the naming convention)
Phase 2 ──> Phase 4 (delegation handler uses the naming convention)
```

Phase 1 must be completed first (it establishes the exclusion mechanism that all other phases reference). Phase 2 must follow (naming convention is used in Phases 3 and 4). Phases 3 and 4 are independent of each other and can be implemented in parallel after Phases 1 and 2.

```
Phase 1 ──> Phase 2 ──┬──> Phase 3
                       └──> Phase 4
```

**Total estimated effort:** Small (S). All changes are documentation/instruction changes in markdown files. No Rust code, no docket CLI changes, no new tooling. Each phase modifies a single file.
