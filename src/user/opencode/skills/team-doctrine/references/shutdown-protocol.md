# Shutdown Protocol — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
each carrying a compact `CANONICAL:SHUTDOWN-PROTOCOL-LOCAL` pointer to this master. Relocated from
`src/user/opencode/agents/team-lead.md` §Shutdown Protocol (DKT-59/60
doctrine-home migration). Deployed at
`~/.config/opencode/skills/team-doctrine/references/shutdown-protocol.md` — repo:
`src/user/opencode/skills/team-doctrine/references/shutdown-protocol.md`. Read on
demand only — never `skill({ name: "team-doctrine" })`. **Under Opencode this protocol is inert**
(subagents are one-shot `task` dispatches that return a summary and end); the SP-1/SP-2 bodies below
are retained as a historical reference for a future persistent-team port.

---

<!-- CANONICAL:SHUTDOWN-PROTOCOL:BEGIN -->
**No shutdown protocol under Opencode.** Opencode subagents are one-shot `task`-tool dispatches: each runs to completion, returns a single summary to the dispatcher (team-lead), and ends. There is no `shutdown_request`/`shutdown_response` handshake, no peer messaging, no `name=`/`run_in_background` foreground/background discriminator, no idle, and no `TeammateIdle` — so SP-1 and SP-2 below have no object to act on and are obsolete under this model. A dispatch's "shutdown" is simply its return.

The SP-1/SP-2 prose is retained purely as a historical reference for a future persistent-team port (the prior Claude Code agent-teams handshake, which existed only under `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`); on Opencode it is inert and should not be invoked.

- **SP-1 — Approve carries NO reason (historical).** A `shutdown_response` with `approve: true` was a SILENT confirmation (omit `reason`); `reason` (+ETA) was delivered ONLY on `approve: false`. N/A on Opencode — no handshake exists.
- **SP-2 — Foreground teammate vs background/report-only subagent (historical).** `name=` WAS the discriminator under Claude Code: a NAMED spawn (`Agent(name=...)`) was a foreground teammate (awaited `shutdown_request`, replied a structured `shutdown_response`); an UNNAMED `run_in_background=true` spawn was a report-only subagent (delivered a plain-text result and ended). N/A on Opencode — every dispatch is a one-shot return-and-end; the distinction collapses. `teammate_terminated`/reap evidence has no equivalent (a `task` call's return IS completion).
<!-- CANONICAL:SHUTDOWN-PROTOCOL:END -->
