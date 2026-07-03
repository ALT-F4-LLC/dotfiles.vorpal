# Deep Collaboration — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
each carrying a `CANONICAL:DEEP-COLLABORATION-LOCAL` pointer to this master. Relocated from
`src/user/opencode/agents/team-lead.md` §Distribution-Mechanism Gate (DKT-59/60
doctrine-home migration). Deployed at
`~/.config/opencode/skills/team-doctrine/references/deep-collaboration.md` — repo:
`src/user/opencode/skills/team-doctrine/references/deep-collaboration.md`. Read on demand
only — never `skill({ name: "team-doctrine" })`.

---

<!-- CANONICAL:DEEP-COLLABORATION:BEGIN -->
**[NO OPENCODE EQUIVALENT — deferred]** — deep collaboration requires peer-to-peer messaging, persistent teammates, and a shared task list, none of which Opencode has (subagents are one-shot `task`-tool dispatches that return a summary and cannot message each other). The mechanics below are preserved as the maintained master for when peer messaging is ported; on Opencode every phase is hub-only.

**Deep valuable collaboration (master definition).** When an L111 trigger fires, run the team *deeply collaborative*, not hub-only. Three mechanics define it; each agent carries a `CANONICAL:DEEP-COLLABORATION-LOCAL` pointer to this master: (1) **Peer challenge/critique** — within a declared collaborative phase a teammate MAY message a peer to challenge a claim, propose a counter-hypothesis, or critique an approach on technical merits, not just ask a clarifying question. (2) **Shared task list** — collaborating teammates read/update a shared task list (`todowrite`) so each sees the others' state and can pick up cross-examination threads. (3) **Cross-examination** — paired reviewers/diagnosers respond to each other's findings (agree/refute with evidence) before the lead reconciles, rather than each reporting in isolation to the hub. This is the value an L111 trigger pays for; hub-only delivery loses it.
<!-- CANONICAL:DEEP-COLLABORATION:END -->
