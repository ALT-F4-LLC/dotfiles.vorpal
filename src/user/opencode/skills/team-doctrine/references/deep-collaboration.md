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
**Hub-relayed under Opencode.** Opencode has no peer-to-peer messaging, no persistent teammates, and no shared task list — subagents are one-shot `task`-tool dispatches that return a summary and cannot message each other. So deep collaboration cannot run peer-to-peer; it runs **hub-only through team-lead**, sequentially: dispatch worker A, fold its finding into worker B's brief as an explicit challenge to answer, then fold B's response back into a resumed A (via `task_id`). Every phase is hub-relayed on Opencode; the peer-to-peer mechanics below are retained as a historical reference for when peer messaging is ported.

**Deep valuable collaboration (master definition).** When an L111 trigger fires, run the team *deeply collaborative*, not isolated. Three mechanics define it (each agent carries a `CANONICAL:DEEP-COLLABORATION-LOCAL` pointer to this master); under Opencode each is relayed through team-lead rather than executed peer-to-peer: (1) **Peer challenge/critique** — within a declared collaborative phase, team-lead folds one worker's challenge/critique/counter-hypothesis into another worker's brief (rather than each worker reporting in isolation); a worker addresses the relayed challenge in its returned summary. (2) **Shared task list** — `todowrite` is owned by team-lead (the only persistent context); workers read their assigned task from the brief and report state back, and team-lead carries cross-worker state between dispatches. (3) **Cross-examination** — paired reviewers/diagnosers answer each other's findings (agree/refute with evidence) via team-lead relaying each summary into the next dispatch, before team-lead reconciles, rather than each reporting in isolation. This is the value an L111 trigger pays for; isolated hub-only delivery loses it.
<!-- CANONICAL:DEEP-COLLABORATION:END -->
