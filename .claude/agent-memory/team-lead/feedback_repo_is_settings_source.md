---
name: repo-is-settings-source
description: Never read/edit deployed ~/.claude/settings.json, ~/.claude/agents, or ~/.claude/skills — this dotfiles repo (src/user.rs ClaudeCode builder, agents/, skills/) is the source of truth
metadata:
  type: feedback
---

All settings in `~/.claude/settings.json`, `~/.claude/skills`, and `~/.claude/agents` are generated/deployed FROM this repository — investigate and change them at the source: `src/user.rs` (`ClaudeCode` builder → settings.json, env vars, hooks, permissions, model), `agents/` (agent definitions), `skills/` (team skills).

**Why:** operator rejected a read of `~/.claude/settings.json` (2026-06-09) and stated the repo defines those files — deployed copies are build outputs of vorpal; editing or reasoning from them bypasses the real config and gets overwritten on rebuild.

**How to apply:** any "change Claude Code config" request routes to `src/user.rs` builder calls (`with_env`, `with_model`, `with_permission_*`, etc.) as a normal repo code change (Direct Task usually) — no sandbox overrides or update-config flow needed. Changes take effect only after the vorpal rebuild/deploy. Related: [[project-model-routing]], [[agent-effort-settings]].
