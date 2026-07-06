# Changelog: codex
## 2026-07-05
### Summary
Report-only review accepted one sandbox-workspace trial and three disambiguation findings; no Rust config source or deployed TOML file changed.
### Changes
- Trial: implemented targeted `sandbox_workspace_write.writable_roots = ["$HOME/.cache/uv"]` via existing setter while keeping network closed; Go cache remains deferred pending verified `GOCACHE` evidence.
- Clarify future evolve-config wording for `skills` ownership and `config genome` vs `workflow genome` scope.
### Dimensions Evaluated
- Core/model/providers; approvals/permissions; sandbox/shell; agents/hooks/lifecycle; skills/memories/history; TUI/auth/apps/governance.
### Rename
No rename.
