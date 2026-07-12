# Vorpal-Managed Tool Inventory — Maintained Master

**LOCAL-copy consumers:** all 7 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`,
`distinguished-engineer.md`) plus `team-lead.md`,
each carrying a compact `CANONICAL:VORPAL-TOOLS-LOCAL` copy. Relocated from
`src/user/claude-code/agents/team-lead.md` §Vorpal Tools (DKT-59/60 doctrine-home migration).
Deployed at `~/.claude/skills/team-doctrine/references/vorpal-tools.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/vorpal-tools.md`. Read on demand only —
never `Skill(team-doctrine)`.

---

<!-- CANONICAL:VORPAL-TOOLS:BEGIN -->
**Maintained master.** Inventory derives from observed `vorpal run` invocations in session transcripts (`bun:1.3.10` seen 4521×; `bun:1.3.13` seen once — 1.3.10 is canonical). Each agent carries a compact LOCAL copy (`CANONICAL:VORPAL-TOOLS-LOCAL`) maintained from this block; tool-invoking skills are a planned follow-up (not yet covered).

**Prefer `vorpal run <tool>:<version> <args>` when the tool is in the inventory below; fall back to natively installed tools when no vorpal-managed equivalent exists.**

| Tool | Pinned version | Vorpal invocation |
|---|---|---|
| bun | 1.3.10 | `vorpal run bun:1.3.10 <args>` |
| go | 1.26.0 | `vorpal run go:1.26.0 <args>` |
| uv | 0.10.11 | `vorpal run uv:0.10.11 <args>` |
| kind | 0.31.0 | `vorpal run kind:0.31.0 <args>` |
| eksctl | 0.227.0 | `vorpal run eksctl:0.227.0 <args>` |
| kubeseal | 0.34.0 | `vorpal run kubeseal:0.34.0 <args>` |
| talosctl | 1.13.4 | `vorpal run talosctl:1.13.4 <args>` |
| gofmt | 1.26.0 | `vorpal run gofmt:1.26.0 <args>` |

**Exempted (use natively, never via vorpal):** `docket` and `git` — direct command conventions are woven throughout all agent files; `vorpal run docket:latest` / `vorpal run git:latest` must NOT appear as guidance.

**Availability caveat.** This inventory is a PREFERENCE list, not an availability guarantee — a pinned tool may not be published for every platform. If `vorpal run <tool>:<ver>` fails with `artifact alias not found`, fall back to the natively installed tool or a covering vorpal tool: e.g. `gofmt` is covered by `vorpal run go:1.26.0 fmt`.
<!-- CANONICAL:VORPAL-TOOLS:END -->
