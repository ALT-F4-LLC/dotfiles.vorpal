# Shutdown Protocol — Maintained Master

**LOCAL-copy consumers:** all 7 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`,
`distinguished-engineer.md`) plus `team-lead.md`,
each carrying a compact `CANONICAL:SHUTDOWN-PROTOCOL-LOCAL` copy — `team-lead.md` retains its
own LOCAL copy because it operates the handshake every cycle and needs SP-1/SP-2 in-context.
Relocated from `src/user/claude-code/agents/team-lead.md` §Shutdown Protocol (DKT-59/60
doctrine-home migration). Deployed at
`~/.claude/skills/team-doctrine/references/shutdown-protocol.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/shutdown-protocol.md`. Read on demand
only — never `Skill(team-doctrine)`.

---

<!-- CANONICAL:SHUTDOWN-PROTOCOL:BEGIN -->
**Shutdown protocol (maintained master).** Two rules bind every spawned agent; each
worker carries a compact `CANONICAL:SHUTDOWN-PROTOCOL-LOCAL` copy maintained from this
block. Routing is unchanged: `shutdown_response` is ALWAYS addressed to `team-lead`. **Precondition:** this entire handshake — and all `SendMessage` routing — exists ONLY when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`; without that var there is no `SendMessage` tool and no team to shut down.

- **SP-1 — Approve carries NO reason.** A `shutdown_response` with `approve: true` is a
  SILENT confirmation — it MUST NOT carry `reason` text. `reason` (+ETA) is delivered
  ONLY on a rejection (`approve: false`). Grant shutdown → `approve: true`, omit `reason`.
  Decline → `approve: false` with `reason`. An approval carrying `reason` is harness-rejected.
- **SP-2 — Foreground teammate vs background/report-only subagent.** `name=` IS the discriminator, and the two modes are mutually exclusive at spawn (enforced at spawn time per the **Name/background exclusivity (mandatory)** rule under §Spawning Templates): a NAMED spawn (`Agent(name=...)`, no `run_in_background`) is a FOREGROUND TEAMMATE; an UNNAMED background spawn (`run_in_background=true`, no `name=`) is a REPORT-ONLY SUBAGENT. NEVER `name=` + `run_in_background=true` together — a named background agent can fail structured shutdown yet keep its roster entry, so de-listing remains unconfirmed until the lead observes termination/reap evidence. **Nested-context caveat:** when THIS lead is itself a teammate/subagent (the harness rejects its named spawns with "teammates cannot spawn other teammates — roster is flat"), every child it spawns may be treated as harness-"background" for session-protocol regardless of `name=`, so even a named teammate's structured `shutdown_response` may be rejected and require plain-text fallback; active cleanup is also unavailable to a nested lead, so SESSION-END may be the only de-list path. If you are a foreground teammate (named): await `shutdown_request` and reply with a structured `shutdown_response` to `team-lead` (SP-1 shape). If you are a report-only subagent (unnamed, background): you have NO structured shutdown/plan protocol — structured `shutdown_response`/`shutdown_request`/plan-protocol messages are acts of the session itself and CANNOT be sent by a background subagent — deliver the result as a PLAIN-TEXT message and END. Cross-check with the brief's Done-state (Canonical ephemeral-brief schema item 4): await-`shutdown_request` ⇒ foreground; return-a-summary-and-end ⇒ report-only; default to teammate when the brief is silent (role spawns default to named teammate mode per §Spawning Templates Common scaffolding). Fallback: if a structured `shutdown_response` is ever harness-rejected as a background-subagent act, resend the result as a PLAIN-TEXT message and END. Ack type is not termination evidence: DKT-20 showed persisted-vs-reaped behavior did not map cleanly to structured `shutdown_response` vs plain-text ack type, so the lead must rely on `teammate_terminated` or cleanup/reap output before reporting shutdown complete.
- **SP-3 — Positive death evidence & the Liveness-Confirmation Gate.** Exactly three forms of
  evidence prove a teammate name is dead/free. **D1** (a `teammate_terminated` system event for
  that name) and **D2** (explicit harness cleanup/reap output naming that teammate) are already
  defined by SP-2's closing termination-evidence sentence above — SP-3 cites that sentence for
  D1/D2 rather than restating it. SP-3's additive content: **D3** — a SendMessage to that name
  that ERRORS as unreachable/unknown (a tool-call failure, not a delivered-but-unanswered send);
  the not-death negative list — any `idle_notification`/`TeammateIdle` with ANY `idleReason`
  (including `"failed"`), session/usage-limit messages, probe silence or timeout of any length, a
  `shutdown_response` or any shutdown acknowledgement, or a shutdown-rejection or "context
  saturated" SendMessage — these mean alive-or-indeterminate — never death (the last two — shutdown ack/rejection and saturation — prove ALIVE; idle reasons/session-limit messages/probe silence are indeterminate, not proof of death). Reliability ordering:
  D1/D2 are reliable and always-available; D3 is sufficient when observed but never required and
  never waited for (resume-on-send means a probe typically resumes a dormant name rather than
  erroring). The exhaustive probe-outcome contract: (i) tool-call error → D3, name free; (ii)
  delivered + reply at any latency → name OCCUPIED; (iii) delivered + no reply → INDETERMINATE,
  never death. The Liveness-Confirmation Gate that operates on this vocabulary lives in
  `team-lead.md` §Teammate Stall & Crash Recovery — its operational home, not this master.
<!-- CANONICAL:SHUTDOWN-PROTOCOL:END -->
