# Vorpal-Managed Tool Inventory — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
each carrying a compact `CANONICAL:VORPAL-TOOLS-LOCAL` copy. Relocated from
`src/user/opencode/agents/team-lead.md` §Vorpal Tools (DKT-59/60 doctrine-home migration).
Deployed at `~/.config/opencode/skills/team-doctrine/references/vorpal-tools.md` — repo:
`src/user/opencode/skills/team-doctrine/references/vorpal-tools.md`. Read on demand only —
never `skill({ name: "team-doctrine" })`.

---

<!-- CANONICAL:VORPAL-TOOLS:BEGIN -->
**Maintained master.** The vorpal-managed inventory for this deployment IS the toolset built by `src/user.rs` → `UserEnvironment::build` (the canonical build manifest). Versions are NOT hardcoded here — they drift on every bump, so per-tool pins in doctrine are a known drift source. Resolve the `<version>` for any tool below via `vorpal inspect <tool>` or the `Vorpal.lock` lockfile at decision time. Each agent carries a compact LOCAL copy (`CANONICAL:VORPAL-TOOLS-LOCAL`) maintained from this block; tool-invoking skills are a planned follow-up (not yet covered).

**Prefer `vorpal run <tool>:<version> <args>` when the tool is in the inventory below; fall back to natively installed tools when no vorpal-managed equivalent exists.**

| Category | Vorpal-managed tools (`vorpal run <tool>:<version>`) |
|---|---|
| CLI / shell | `awscli2`, `bat`, `direnv`, `doppler`, `fd`, `fzf`, `gum`, `herdr`, `hunk`, `jj`, `jq`, `just`, `k9s`, `kubectl`, `lazygit`, `neovim`, `nnn`, `op`, `pi`, `ripgrep`, `sesh`, `starship`, `terraform`, `tmux`, `zoxide`, `abtop` |
| Runtime | `nodejs` |
| App platform | `opencode` |
| Language servers (LSP) | `gopls`, `bash-language-server`, `lua-language-server`, `typescript-language-server`, `vscode-languages-extracted`, `yaml-language-server` |
| Tooling / formatters | `cue`, `delta`, `tree-sitter`, `typescript` |

**Exempted (use natively, never via vorpal):**
- `docket` — not vorpal-managed by this deployment (externally installed issue tracker); `vorpal run docket:latest` must NOT appear as guidance.
- `git` — although `src/user.rs` DOES build `git` as a Vorpal artifact, direct-`git` command conventions are woven throughout all agent files, so prefer native `git`; `vorpal run git:latest` must NOT appear as guidance.
<!-- CANONICAL:VORPAL-TOOLS:END -->
