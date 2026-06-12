# Changelog: claude-code

## 2026-06-12

### Summary
Trial: allowing `vorpal run`/`git branch` cuts recurring permission prompts → applied (measure next cycle).
Drift: re-worded §Argument Handling lead-in + No-argument bullet (seed 12a169e6) → applied.
First config-genome cycle: two permission allows added; env-scrub posture decided; bundled-skills setter declined.

### Changes
- AMPLIFY: allow `Bash(vorpal run:*)` — agent specs mandate vorpal-run; 17× talosctl prompts in 2-day audit.
- AMPLIFY: allow `Bash(git branch:*)` — read-only; closes opencode↔claude allow-list asymmetry.
- Flagged: CLAUDE_CODE_SUBPROCESS_ENV_SCRUB stays 0 (operator decision; 44f5cb0 auto-mode flip) — security.md amendment routed to @security-engineer via tracking issue.
- Declined (operator): with_disable_bundled_skills follow-up; sandbox-excluded egress audit; SOCKS-proxy env scrub — noted only, no tracking issues.

### Dimensions Evaluated
Core & model routing; Permissions; Sandbox; Hooks & scripts; Skills & auto-mode; Plugins, UI & governance.

### Rename
No rename.
