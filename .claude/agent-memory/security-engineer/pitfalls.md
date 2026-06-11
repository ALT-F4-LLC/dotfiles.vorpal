# Security-engineer recurring pitfalls

Append-only. `symptom → root cause → resolution` form. Harvested by evolve-* cycles.

---

- **symptom**: Rated an env-secret-exposure change (`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=0`) MEDIUM in an early-phase assessment, then had to downgrade to LOW at review time after reading more of the same file.
  → **root cause**: Assessed one security control (subprocess env scrubbing) in isolation. The Claude Code `ClaudeCode` builder in src/user.rs layers controls that only make sense together: env scrub, `with_sandbox_enabled` + `fail_if_unavailable`, `with_sandbox_network_allowed_domains` (egress allowlist), `with_sandbox_filesystem_deny_read`, and `with_permission_ask/deny` tiers. Secret *inheritance* into a subprocess is only dangerous if there is an *exfiltration* channel — the sandbox network allowlist removes that channel for sandboxed commands, so scrub=0 is far less severe than inheritance-alone reasoning suggests.
  → **resolution**: For any Claude Code settings-builder review, read the ENTIRE config block (env + sandbox + permission tiers, ~L100-305 in src/user.rs) before assigning severity to any single setting. Specifically pair env-scrub with: (a) `with_sandbox_network_allowed_domains` (is egress allowlisted?), (b) `with_sandbox_excluded_commands` (which commands run UNSANDBOXED and thus bypass the egress allowlist while inheriting full env — `aws/docker/gh/git/kubectl` are the live residual surface), (c) `fail_if_unavailable` (does sandbox fail closed?). The exfiltration-channel question, not the inheritance question, drives the severity.
