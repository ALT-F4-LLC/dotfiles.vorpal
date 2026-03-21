---
project: "dotfiles.vorpal"
maturity: "draft"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
vote_approval: "DKT-V1 — score 1.00, threshold 0.75, 3 reviewers, round 1"
scope: "Delegation protocol enabling sub-agents to request agent spawning from the orchestrator"
owner: "@staff-engineer"
dependencies:
  - ../spec/architecture.md
---

# Agent Delegation Protocol

## 1. Problem Statement

### What

When the `/dev` skill orchestrates a multi-agent team, it spawns sub-agents (@staff-engineer, @project-manager, @senior-engineer, @sdet, @ux-designer) that have access to skills like `/vote` via the `Skill` tool. The `/vote` skill's instructions direct the executor to create agent teams and spawn independent reviewer agents using `Agent()` and `TeamCreate()`.

However, sub-agents do NOT have `Agent` or `TeamCreate` in their tool sets. Their available tools are limited to: `Read, Grep, Glob, Bash, Write, Edit, SendMessage, Skill`. When a sub-agent invokes `/vote`, the skill's instructions to spawn agents **fail silently** because the required tools are unavailable in the sub-agent's sandbox.

This is not a `/vote`-specific problem. Any future skill that requires agent spawning will encounter the same limitation when invoked by a sub-agent.

### Why Now

The `/vote` skill is a hard requirement for TDD approval (`@staff-engineer` MUST invoke `/vote` before any TDD handoff), design spec approval (`@ux-designer` MUST invoke `/vote`), and is available to all five agents for high-stakes decisions. Today, this entire flow is broken when agents are spawned by the `/dev` orchestrator.

### Constraints

- Sub-agents communicate with teammates via `SendMessage` and have `Bash` access (can run `docket` CLI commands directly).
- The orchestrator (Team Lead / `/dev` skill executor) has `Agent`, `TeamCreate`, and `TeamDelete` -- these are the only tools sub-agents lack.
- The protocol must not require changes to Claude Code's tool permission system -- it must work within the existing tool allocation model.
- Results must flow back to the requesting sub-agent so it can continue its work (e.g., @staff-engineer needs the `/vote` result to decide whether to hand off a TDD).
- The protocol should be generic enough for any skill that needs agent spawning, not just `/vote`.
- Docket is accessible to all agents (via Bash) and should be used as the shared data store rather than passing large payloads through `SendMessage`.

### Acceptance Criteria

1. A sub-agent can detect that it lacks `Agent`/`TeamCreate` tools by checking its system prompt tool list.
2. A sub-agent can create a vote proposal via `docket vote create` and send a lightweight delegation request (containing only the `vote_id`) to the orchestrator via `SendMessage`.
3. The orchestrator can read the proposal from docket via the `vote_id`, spawn reviewer agents, cast votes, and evaluate quorum.
4. A minimal completion signal is delivered back to the requesting sub-agent via `SendMessage`.
5. The sub-agent can read the full vote result from docket via `docket vote result <vote_id> --json`.
6. The protocol handles the `/vote` skill end-to-end: sub-agent creates proposal in docket, orchestrator spawns reviewers and casts votes, sub-agent reads result from docket.
7. The protocol message format is generic -- a new skill requiring agent spawning can use the same `delegation_request`/`delegation_response` envelope with a skill-specific resource ID field. The orchestrator requires a skill-specific handler for each delegatable skill.
8. Failed delegations (orchestrator unavailable, spawn failures) produce clear error signals to the requesting sub-agent.

---

## 2. Context & Prior Art

### Current Architecture

**Tool allocation by role:**

| Role | Has `Agent`/`TeamCreate` | Has `Skill` | Has `SendMessage` |
|------|--------------------------|-------------|-------------------|
| Team Lead (`/dev` executor) | Yes | Yes | Yes |
| @staff-engineer | No | Yes (`/vote`) | Yes |
| @project-manager | No | Yes (`/vote`) | Yes |
| @senior-engineer | No | Yes (`/vote`, `/commit`) | Yes |
| @sdet | No | Yes (`/vote`) | Yes |
| @ux-designer | No | Yes (`/vote`) | Yes |

**Current `/vote` flow (broken in sub-agent context):**

1. Sub-agent calls `Skill(vote, "proposal...")`.
2. The `/vote` skill instructions tell the executor to call `TeamCreate(...)`, then `Agent(...)` for each reviewer.
3. These calls fail because the sub-agent's tool set lacks `Agent` and `TeamCreate`.
4. The failure is silent -- the sub-agent has no fallback path.

**Current `/dev` orchestrator flow:**

The Team Lead (the entity executing `/dev`) already handles complex multi-agent coordination: spawning agents sequentially by phase, monitoring task completion, routing results between agents. It has all the tools needed to execute delegated work.

### How This Is Solved Elsewhere

**Message-passing delegation** is a well-established pattern in distributed systems:

- **Actor model (Akka, Erlang/OTP)**: Actors that cannot perform an action delegate to a supervisor actor via messages. The supervisor performs the privileged operation and sends the result back. This is the closest analogue.
- **Capability-based security**: Processes request capabilities they lack from a trusted broker. The broker validates the request and either grants the capability or performs the action on behalf of the requester.
- **Kubernetes admission webhooks**: When a pod cannot perform a privileged operation, it sends a request to an admission controller that evaluates and executes on its behalf.

The common pattern: **the unprivileged entity sends a structured request to a privileged entity, which executes and returns results via the same communication channel.**

A refinement of this pattern uses a **shared data store** (database, queue, filesystem) rather than passing payloads through messages. The request contains only a resource ID; the executor reads inputs from and writes outputs to the shared store. This is the pattern used by job queues (Celery, Sidekiq), CI systems (GitHub Actions -- the workflow references a commit SHA, not the code), and database-backed task systems. This is the approach adopted here, with docket as the shared store.

---

## 3. Alternatives Considered

### Alternative A: Grant `Agent`/`TeamCreate` to All Sub-Agents

Give every agent the `Agent` and `TeamCreate` tools so they can spawn agents directly.

**Strengths:**
- Zero protocol overhead -- skills work as written.
- No orchestrator changes needed.
- Simplest possible solution.

**Weaknesses:**
- Violates the architectural principle that the orchestrator controls agent lifecycle. If any sub-agent can spawn agents, the Team Lead loses visibility into what agents exist and what they are doing.
- Creates resource sprawl risk -- sub-agents spawning agents that spawn agents.
- The Claude Code agent framework may not support nested agent spawning well (sub-agents spawning sub-sub-agents), leading to unpredictable context and tool inheritance.
- Breaks the clean separation of concerns in the current architecture.

**Verdict:** Rejected. The architectural cost of decentralized agent spawning outweighs the simplicity benefit.

### Alternative B: Orchestrator Delegation via SendMessage with Docket as Shared Store (Recommended)

Sub-agents create the vote proposal themselves via `docket vote create` (they have `Bash`), then send a lightweight delegation request containing only the `vote_id` to the orchestrator via `SendMessage`. The orchestrator reads the proposal from docket, spawns reviewer agents, casts votes, and sends back a minimal completion signal. The sub-agent reads the full result from docket.

**Strengths:**
- Uses only existing communication primitives (`SendMessage`) and existing shared store (`docket`).
- Preserves the orchestrator's control over agent lifecycle.
- Minimal message payloads -- no large context/result blobs in `SendMessage`. Docket is the source of truth.
- Sub-agents do all the docket CLI work they can (create proposal, read result), only delegating the part they cannot do (spawning agents).
- Full auditability through docket vote records (the proposal exists in docket before the orchestrator even sees the request).
- Reduces coupling -- the orchestrator does not need to understand proposal construction, and the sub-agent does not depend on the orchestrator to format results.
- Generic message envelope -- a future skill with its own shared store can use the same pattern (pass a resource ID, not a payload).

**Weaknesses:**
- Adds a request/response round-trip between sub-agent and orchestrator.
- Requires changes to skill documents (to detect sub-agent context and delegate).
- The sub-agent must yield and wait for a response while the orchestrator executes.
- Adds a delegation handler section to the orchestrator's instructions.
- Requires that the shared store (docket) is accessible to both sub-agent and orchestrator (true today since both have Bash).

**Verdict:** Recommended. This is a refinement of pure message-passing delegation that leverages the existing docket infrastructure. The round-trip cost is acceptable for operations like `/vote` that are inherently async. The docket-native approach is simpler, more auditable, and produces smaller messages.

### Alternative C: Dedicated Delegation Agent

Spawn a persistent "delegation broker" agent that sits between sub-agents and the orchestrator, managing all spawn requests.

**Strengths:**
- Decouples delegation from the orchestrator's main workflow.
- Could handle concurrent delegation requests from multiple sub-agents.

**Weaknesses:**
- Adds another long-running agent consuming resources.
- The orchestrator already handles this coordination -- a broker is redundant.
- More moving parts for marginal benefit.
- The broker itself would need `Agent`/`TeamCreate`, so it must be spawned by the orchestrator anyway.

**Verdict:** Rejected. Over-engineering for the current scale. The orchestrator can handle delegation directly.

---

## 4. Architecture & System Design

### Design Principle: Docket as Shared Data Store

The key architectural insight is that **docket is already the shared data store** for vote proposals and results. Sub-agents have `Bash` access and can run `docket vote create` and `docket vote result` directly. The only capability they lack is spawning reviewer agents.

This means delegation messages do NOT need to carry proposal context or result payloads. Instead, **messages are lightweight coordination signals** that reference docket vote IDs. Docket is the source of truth; `SendMessage` is the coordination channel.

### Protocol Overview

```
Sub-Agent                         Docket                    Orchestrator (Team Lead)
    |                                |                              |
    |  1. docket vote create ...     |                              |
    |------------------------------->|                              |
    |  (gets back vote_id DKT-VN)   |                              |
    |                                |                              |
    |  2. delegation_request         |                              |
    |     {vote_id: "DKT-VN"}       |                              |
    |-------------------------------------------------------------->|
    |                                |                              |
    |                                |  3. docket vote show DKT-VN  |
    |                                |<-----------------------------|
    |                                |                              |
    |                                |  4. Spawns reviewer agents   |
    |                                |     Casts votes via          |
    |                                |     docket vote cast DKT-VN  |
    |                                |<-----------------------------|
    |                                |                              |
    |  5. delegation_response        |                              |
    |     {vote_id: "DKT-VN",       |                              |
    |      status: "completed"}      |                              |
    |<--------------------------------------------------------------|
    |                                |                              |
    |  6. docket vote result DKT-VN  |                              |
    |------------------------------->|                              |
    |  (reads full result)           |                              |
    |                                |                              |
    |  7. Continues work             |                              |
```

### Message Format

Messages are minimal coordination signals. All substantive data lives in docket.

#### Delegation Request

Sent by a sub-agent to the orchestrator via `SendMessage(to="team-lead", message=...)`:

```json
{
  "type": "delegation_request",
  "protocol_version": "1",
  "skill": "vote",
  "request_id": "<agent-name>-vote-<epoch-ms>",
  "from": "<agent-name>",
  "vote_id": "<docket-vote-id>"
}
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Always `"delegation_request"` |
| `protocol_version` | Yes | Always `"1"` (for forward compatibility) |
| `skill` | Yes | The skill that needs agent spawning (e.g., `"vote"`) |
| `request_id` | Yes | Unique identifier for correlating request/response. Use `"{agent-name}-vote-{epoch-ms}"` (millisecond timestamp to avoid collisions) |
| `from` | Yes | The requesting agent's name (for response routing) |
| `vote_id` | Yes (for `skill: "vote"`) | The docket vote proposal ID created by the sub-agent (e.g., `"DKT-V2"`) |

#### Delegation Response

Sent by the orchestrator back to the requesting sub-agent via `SendMessage(to="<from>", message=...)`:

```json
{
  "type": "delegation_response",
  "protocol_version": "1",
  "request_id": "<matching-request-id>",
  "status": "completed",
  "vote_id": "<docket-vote-id>"
}
```

**Fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Always `"delegation_response"` |
| `protocol_version` | Yes | Always `"1"` |
| `request_id` | Yes | Matches the request's `request_id` |
| `status` | Yes | `"completed"`, `"failed"`, or `"escalated"` |
| `vote_id` | Yes (for `skill: "vote"`) | The same docket vote ID, confirming which vote was processed |
| `error` | If failed | Error description when `status` is `"failed"` |

Note the absence of `context`, `result`, or `findings` fields. The sub-agent reads the full result from docket after receiving the response:

```bash
docket vote result <vote_id> --json
```

### Detection Mechanism

A sub-agent determines it is in a "sub-agent context" (lacking `Agent`/`TeamCreate`) by checking its system prompt tool list. The system prompt enumerates available tools at the start of every agent session.

The `/vote` skill (and any future delegatable skill) includes a conditional section:

```
## Execution Mode Detection

Before beginning the protocol, determine your execution mode:

1. Check your system prompt for the list of tools available to you.
2. If `Agent` AND `TeamCreate` appear in your tool list:
   --> You are the orchestrator (or have spawn capability).
   --> Execute the full protocol directly.
3. If `Agent` and `TeamCreate` do NOT appear in your tool list:
   --> You are running inside a sub-agent context.
   --> Use the Delegation Protocol:
     a. Run the Pre-flight checks (verify docket, parse proposal, classify criticality).
     b. Create the vote proposal yourself via `docket vote create` (you have Bash).
        Extract the vote_id from the JSON response.
     c. Construct a delegation_request with the vote_id.
     d. Send it to "team-lead" via SendMessage.
     e. Yield control and state that you are waiting for a delegation_response.
        You do not have a blocking primitive -- the response will arrive as a
        subsequent message in your conversation.
     f. When the delegation_response arrives, read the result via
        `docket vote result <vote_id> --json`.
     g. Produce the standard /vote output format from the docket result.
```

This is a documentation-level change -- no code modification is needed. The sub-agent performs all the docket CLI work it can (proposal creation, result reading) and only delegates the part it cannot do (spawning reviewer agents).

### Orchestrator Handling

The `/dev` skill's orchestrator instructions are extended with a delegation handler section:

```
## Handling Delegation Requests

When you receive a SendMessage with `type: "delegation_request"`:

1. Parse the request to identify the skill and vote_id.
2. Read the proposal details from docket:
   `docket vote show <vote_id> --json`
3. Execute the reviewer-spawning portion of the /vote protocol:
   - Create the vote team via TeamCreate.
   - Spawn independent reviewer agents via Agent (one per reviewer).
   - Collect verdicts and cast votes via `docket vote cast <vote_id> ...`.
   - Evaluate quorum via `docket vote result <vote_id> --json`.
   - If quorum reached, commit: `docket vote commit <vote_id> --outcome "..."`.
   - Clean up the vote team.
4. Send a delegation_response back to the requesting agent:
   SendMessage(to=request.from, message={type: "delegation_response",
     protocol_version: "1", request_id: request.request_id,
     status: "completed"|"failed"|"escalated", vote_id: request.vote_id})
5. Resume your orchestration workflow.
```

The orchestrator does NOT need to re-create the vote proposal or parse proposal context from the message -- it reads everything from docket via the `vote_id`.

### Component Boundaries

```
┌──────────────────────────────────────────────────────────────┐
│ Orchestrator (Team Lead / /dev executor)                     │
│ Tools: Agent, TeamCreate, TeamDelete, SendMessage, Bash, ... │
│                                                              │
│  ┌────────────────────────────────────────────────┐          │
│  │ Delegation Handler (new section in /dev)       │          │
│  │ - Parses delegation_request (extracts vote_id) │          │
│  │ - Reads proposal from docket vote show         │          │
│  │ - Spawns reviewers, casts votes, eval quorum   │          │
│  │ - Returns delegation_response (vote_id+status) │          │
│  └────────────────────────────────────────────────┘          │
│                                                              │
│  Spawns & manages:                                           │
│  ┌──────────────────────────────────────────────────┐        │
│  │ Vote reviewer agents (spawned per delegation)    │        │
│  │ - Independent, short-lived                       │        │
│  │ - Results cast to docket by orchestrator         │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
        ▲                              │
        │ delegation_request           │ delegation_response
        │ {vote_id: "DKT-VN"}         │ {vote_id: "DKT-VN", status: "completed"}
        │ (SendMessage)                │ (SendMessage)
        │                              ▼
┌──────────────────────────────────────────────────────────────┐
│ Sub-Agent (e.g., @staff-engineer)                            │
│ Tools: Read, Grep, Glob, Bash, Write, SendMessage, Skill    │
│                                                              │
│  Invokes /vote via Skill tool                                │
│  --> Skill detects no Agent/TeamCreate in tool list           │
│  --> Runs docket vote create (gets DKT-VN)                   │
│  --> Sends delegation_request {vote_id: "DKT-VN"}            │
│  --> Yields, waits for delegation_response                   │
│  --> Reads result: docket vote result DKT-VN --json          │
│  --> Continues workflow with vote outcome                    │
└──────────────────────────────────────────────────────────────┘

         ┌──────────────────────────────────────┐
         │           Docket (shared store)      │
         │                                      │
         │  Sub-agent writes:                   │
         │    docket vote create --> DKT-VN     │
         │                                      │
         │  Orchestrator reads/writes:          │
         │    docket vote show DKT-VN           │
         │    docket vote cast DKT-VN           │
         │    docket vote commit DKT-VN         │
         │                                      │
         │  Sub-agent reads:                    │
         │    docket vote result DKT-VN         │
         └──────────────────────────────────────┘
```

---

## 5. Risks & Open Questions

### Known Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Orchestrator is busy with another phase when delegation arrives | Medium | Medium | The orchestrator processes messages sequentially. Delegation requests queue naturally. Document that delegations may add latency during active phases. |
| Sub-agent context window fills while waiting for delegation response | Low | High | Vote delegations are the primary use case and typically complete within minutes. If a sub-agent's context fills, it fails gracefully and the orchestrator can retry. |
| Malformed delegation requests | Low | Low | The message format is documented and enforced by skill instructions. The orchestrator ignores malformed requests and logs a warning. |
| Concurrent delegation requests from multiple sub-agents | Medium | Medium | The orchestrator handles one delegation at a time. If multiple arrive, process sequentially. Document this as a known limitation. |
| Sub-agent dies after sending delegation request (orphaned delegation) | Low | Low | The orchestrator completes the vote and attempts to send the response. If delivery fails (agent gone), the vote record still exists in docket for auditability. No cleanup needed beyond normal team teardown. |

### Open Questions

1. **Should delegation requests be recorded in Docket?** With the docket-native design, this is resolved: the vote proposal is created in docket by the sub-agent *before* the delegation request is sent. The full audit trail (proposal, votes, result) exists in docket regardless of whether the delegation message succeeds. For future non-vote skills, the same pattern applies if the skill has a docket-backed resource. **Resolved: no additional logging needed.**

2. **Should the orchestrator validate delegation requests against the sub-agent's authorized skills?** For example, should it verify that @staff-engineer is allowed to invoke `/vote`? **Recommendation:** No. The skill's `skills:` field in the agent definition already controls access. If a sub-agent can invoke `/vote` via `Skill`, it can delegate `/vote`. Trust the existing authorization model.

3. **Timeout behavior.** What happens if the orchestrator does not respond? **Recommendation:** Document that sub-agents should include a note in their delegation request that they are waiting. If no response arrives within the skill's execution window, the sub-agent should report the delegation as failed and notify the orchestrator/user.

### Assumptions

- The orchestrator (Team Lead) is always a long-lived entity that persists across phases and can handle incoming messages at any time during the `/dev` workflow.
- `SendMessage` delivery is reliable and ordered within a session.
- Sub-agents can "yield and wait" for a response -- the response arrives as a subsequent message in their conversation. There is no native blocking primitive.
- Docket is accessible to all agents via `Bash` and provides consistent reads (a proposal created by the sub-agent is immediately readable by the orchestrator).

---

## 6. Testing Strategy

### Key Scenarios

1. **Happy path: /vote delegation from @staff-engineer**
   - Staff engineer invokes `/vote` on a TDD.
   - Skill detects sub-agent context (no `Agent` tool in system prompt tool list).
   - Sub-agent creates vote proposal via `docket vote create` -- gets back `DKT-VN`.
   - Delegation request sent to team-lead with `vote_id: "DKT-VN"`.
   - Orchestrator reads proposal via `docket vote show DKT-VN --json`.
   - Orchestrator spawns reviewers, casts votes, evaluates quorum.
   - Orchestrator sends `delegation_response` with `status: "completed"`.
   - Sub-agent reads result via `docket vote result DKT-VN --json`.
   - Staff engineer continues with TDD handoff.

2. **Delegation during active implementation phase**
   - @staff-engineer requests `/vote` while @senior-engineer agents are active.
   - Orchestrator processes the delegation alongside ongoing phase management.
   - Both the delegation and the phase complete correctly.

3. **Failed vote (quorum not reached)**
   - Sub-agent creates proposal, sends delegation request.
   - Orchestrator spawns reviewers, quorum not reached.
   - Orchestrator sends `delegation_response` with `status: "completed"` (vote completed, quorum failed).
   - Sub-agent reads result from docket, sees quorum not reached, can decide to revise or escalate.

4. **Orchestrator unavailable or no response**
   - Sub-agent creates proposal in docket, sends delegation request, but orchestrator is not active (e.g., not running under `/dev`).
   - The vote proposal exists in docket (auditable) but reviewers are never spawned.
   - Sub-agent detects the lack of response and reports that `/vote` cannot be executed in this context.

5. **Non-vote delegation (future skill)**
   - A hypothetical skill that needs agent spawning uses the same delegation envelope with a skill-specific resource ID field (analogous to `vote_id`).
   - Orchestrator receives the request, identifies the skill, and executes the corresponding handler.

### Verification Approach

Since the protocol is entirely in markdown skill/agent instructions, testing is done by running the `/dev` skill end-to-end with a medium task (which triggers TDD creation and `/vote`). The SDET verifies:

- The sub-agent creates a vote proposal in docket before sending the delegation request.
- The delegation request message contains only the `vote_id` (no large payloads).
- The orchestrator reads the proposal from docket (not from the message).
- The orchestrator correctly spawns reviewer agents and casts votes to the same `vote_id`.
- The orchestrator sends a minimal `delegation_response` (status + vote_id).
- The sub-agent reads the full result from docket via `docket vote result`.
- The sub-agent's workflow continues correctly after receiving the result.

---

## 7. Implementation Phases

### Phase 1: Vote Skill Delegation Path (S)

**Changes:** `skills/vote/SKILL.md`

Add an "Execution Mode Detection" section at the top of the protocol (after Pre-flight, before Phase 1):

- Instructions to check the system prompt tool list for `Agent` and `TeamCreate`.
- If present: execute the full protocol directly (existing behavior).
- If absent (sub-agent context):
  - Run Pre-flight checks (verify docket, parse proposal, classify criticality).
  - Create the vote proposal via `docket vote create` -- the sub-agent does this itself since it has Bash.
  - Extract the `vote_id` from the JSON response.
  - Send a `delegation_request` to `"team-lead"` via `SendMessage` containing only `vote_id`.
  - Yield and wait for the `delegation_response`.
  - On response, read the result via `docket vote result <vote_id> --json`.
  - Produce the standard `/vote` output format from the docket result.

### Phase 2: Dev Skill Delegation Handler (S)

**Changes:** `skills/dev/SKILL.md`

Add a "Handling Delegation Requests" section to the orchestrator instructions:

- How to recognize a `delegation_request` message (by `type` field).
- For `skill: "vote"`: read the proposal from docket via `docket vote show <vote_id> --json`. Execute the reviewer-spawning portion of the `/vote` protocol using the orchestrator's `Agent`/`TeamCreate` tools. Cast votes via `docket vote cast <vote_id>`. Evaluate quorum and commit if reached.
- Send a minimal `delegation_response` back to the requesting agent (status + vote_id).

Also update the "Consensus Integration" section to note that when a sub-agent needs `/vote`, it will arrive as a delegation request with a `vote_id` rather than being invoked directly.

### Phase 3: Agent Definition Updates (S)

**Changes:** All 5 agent files in `agents/`

Add a brief "Delegation Protocol" section to each agent that has `/vote` in its skills:

- When invoking `/vote` and the skill instructions indicate delegation is needed, follow the delegation path.
- The `request_id` format and `from` field value to use.
- What to expect in the response and how to read the result from docket.

This is a small addition (5-10 lines per agent) that ensures agents know they participate in the delegation protocol.

**Acceptance criteria for Phase 3:**
- Each agent with `/vote` in its `skills:` list has a "Delegation Protocol" section.
- The section specifies the `request_id` format using the agent's name and millisecond timestamp.
- The section specifies the `from` field value (the agent's team name, e.g., `"advisor"` for @staff-engineer when spawned as the persistent advisor).
- The section documents that after sending a delegation request, the agent should yield and wait for the response message.
- The section documents how to read the vote result from docket via `docket vote result <vote_id> --json`.

### Phase 4: Architecture Spec Update (S)

**Changes:** `docs/spec/architecture.md`

Update the "Agent Team Architecture" section to document the delegation protocol as a formal communication pattern between sub-agents and the orchestrator.

### Dependencies

```
Phase 1 ──┐
           ├──> Phase 3 (agents need to reference the protocol from Phases 1 & 2)
Phase 2 ──┘
           ├──> Phase 4 (spec documents the complete protocol)
```

Phases 1 and 2 are independent and can be implemented in parallel. Phase 3 depends on both (agents reference the protocol defined in Phases 1 and 2). Phase 4 depends on Phases 1 and 2 but can run in parallel with Phase 3 since the spec documents the protocol design, not the agent-specific additions.

**Total estimated effort:** Small (S). All changes are documentation/instruction changes in markdown files. No Rust code, no configuration changes, no new tooling.
