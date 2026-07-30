# Shutdown Protocol — Maintained Master

Binds every spawned agent; each carries a compact `CANONICAL:SHUTDOWN-PROTOCOL-LOCAL` copy
(team-lead's copy is intentionally divergent — it operates the other side of the handshake).
Deployed at `~/.claude/skills/team-doctrine/references/shutdown-protocol.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/shutdown-protocol.md`.

---

<!-- CANONICAL:SHUTDOWN-PROTOCOL:BEGIN -->
**Shutdown protocol (maintained master).** `shutdown_response` is ALWAYS addressed to
`team-lead`. **Precondition:** this handshake — and all `SendMessage` routing — exists ONLY
when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; without that var
there is no `SendMessage` tool and no team to shut down.

- **SP-1 — Approve carries NO reason.** `approve: true` is a SILENT confirmation — the
  `reason` key must be ABSENT from the object entirely (`reason: null` and `reason: ""` fail
  validation exactly like text does). `reason` (+ETA) is delivered ONLY on a rejection
  (`approve: false`).
- **SP-1b — Nest `type` inside `message`.** Valid top-level `SendMessage` params are ONLY
  `to`/`message`/`summary`; `type`, `request_id`, `approve`, `reason` live exclusively inside
  the `message` object — never duplicated at, or moved to, the top level. `request_id` is
  REQUIRED inside `message` for both `shutdown_response` and `plan_approval_response`; a
  reply omitting it cannot be matched to its request. Canonical shape:
  ```json
  {"to": "team-lead",
   "message": {"type": "shutdown_response", "request_id": "abc-123", "approve": true}}
  ```
  **String-message `summary` is REQUIRED:** when `message` is a plain STRING, the top-level
  `summary` field is mandatory (harness-rejected otherwise); object-form `message` needs no
  `summary`.
- **SP-2 — Foreground teammate vs background/report-only subagent.** `name=` IS the
  discriminator, and the two modes are mutually exclusive at spawn: a NAMED spawn
  (`Agent(name=...)`) is a FOREGROUND TEAMMATE; an UNNAMED spawn (background-by-default
  since v2.1.198) is a REPORT-ONLY SUBAGENT. Never combine `name=` with
  `run_in_background=true` — a named background agent can fail structured shutdown yet keep
  its roster entry, leaving de-listing unconfirmed. Foreground teammate: await
  `shutdown_request` and reply with a structured `shutdown_response` to `team-lead` (SP-1
  shape). Report-only subagent: structured shutdown/plan messages are acts of the session
  itself and CANNOT be sent by a background subagent — deliver the result as PLAIN TEXT and
  END; the same plain-text fallback applies whenever a structured `shutdown_response` is
  harness-rejected as a background-subagent act. Nested-context caveat: when this lead is
  itself a teammate/subagent (the harness rejects its named spawns — "roster is flat"), its
  children may be treated as background regardless of `name=`, and SESSION-END may be the
  only de-list path. Cross-check with the brief's Done-state: await-`shutdown_request` ⇒
  foreground; return-a-summary-and-end ⇒ report-only; default to teammate when the brief is
  silent. Ack type is not termination evidence — the lead relies on `teammate_terminated` or
  cleanup/reap output before reporting shutdown complete.
- **SP-3 — Positive death evidence.** Exactly three forms of evidence prove a teammate name
  is dead/free: **D1** a `teammate_terminated` system event for that name; **D2** explicit
  harness cleanup/reap output naming it; **D3** a SendMessage to that name that ERRORS as
  unreachable/unknown. Every other signal proves alive-or-indeterminate, never death —
  shutdown acks/rejections, saturation messages, operator-stop refusals, and name-collision
  refusals prove ALIVE; `idle_notification`s (with ANY `idleReason`, including `"failed"`),
  session/usage-limit messages, and probe silence of any length are indeterminate. Two
  ALIVE-shaped tool-call errors are routinely misread as D3: an operator-stopped subagent's
  refusal (`x` in `/tasks`, SDK `stop_task` — proves a pause), and a name-collision refusal
  naming a different CURRENT holder. Probe-outcome contract: (i) error reporting the name
  itself unreachable/unknown → D3, name free; (ii) delivered + reply → OCCUPIED; (iii)
  delivered + no reply → INDETERMINATE. D1/D2 are reliable and always available; D3 is
  sufficient when observed but never required and never waited for (resume-on-send means a
  probe typically resumes a dormant name rather than erroring). `idle_notification` delivery
  is UNORDERED relative to the same teammate's own SendMessages (observed in the field;
  anthropics/claude-code#24246 closed as not planned) — a bare idle is a turn-end signal
  only, never evidence a report was sent or lost; disambiguate via team-lead.md §Teammate
  Stall & Crash Recovery, which is also the operational home of the Liveness-Confirmation
  Gate built on this vocabulary.
- **SP-4 — Crossed-in-flight duplicate.** A SendMessage that contradicts or duplicates your
  own already-in-flight action is a stale crossed-in-flight duplicate — state that, take no
  action, continue.
<!-- CANONICAL:SHUTDOWN-PROTOCOL:END -->
