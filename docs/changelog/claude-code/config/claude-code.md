# Changelog: claude-code

## 2026-07-12

### Summary
AMPLIFY: adopt the SubagentStop hook (DKT-253) — nudges the report-emission skill family's #1 defect (verdict emitted in-context, never SendMessage'd). Kept DKT-253's literal "emitted-line" framing; rejected the generalized "any silent SubagentStop" framing (unsound — fires every turn-end).

### Changes
- AMPLIFY: `with_hook("SubagentStop", None, "bash ~/.claude/subagent-report-hook.sh", "command")` + new src/user/subagent-report-hook.sh (FileCreate + symlink). Gates on the four skills' `... emitted (...)` confirmation line in last_assistant_message, then transcript index-scan for a same-turn SendMessage; additionalContext nudge; fail-open. Behavioral: `hooks` map gains a `SubagentStop` key. No new setter (with_hook is additive).

### Dimensions Evaluated
Hooks&scripts (AMPLIFY); Core&model-routing / Permissions / Sandbox / Skills&auto-mode / Plugins-UI-governance (RETAIN). Deferred → tracking issues: read-only Bash allowlist, TMPDIR/build-cache sandbox, hook-packaging refactor, transcript_scan.sh extraction, auto-mode env retire, sensitive-path deny-list drift.

### Rename
No rename.

## 2026-06-17

### Summary
Added `uv` + `vorpal` to the sandbox `excludedCommands` — the dominant audit friction signal. Trial: sandbox uv/vorpal exclusion → adopted. Drift: 2 neutral rewordings of the SKILL.md historical-auditor output-format prose → adopted.

### Changes
- AMPLIFY: added `uv` (194× sandbox-blocked) + `vorpal` (67×) to `with_sandbox_excluded_commands` (src/user.rs) — both on the canonical vorpal-tools inventory; isolation forced .venv/system fallbacks. Behavioral: non-empty excludedCommands vec gains 2 entries → serialized `excludedCommands` output changes.

### Dimensions Evaluated
Sandbox (AMPLIFY); Core&model-routing / Permissions / Hooks&scripts / Skills&auto-mode / Plugins-UI-governance (RETAIN). Deferred → DKT-19: `.env.example` allowRead (verify layer first), OTEL endpoint split (operator decision), env-var-first idiom doc, `~/.kube` layer; CLAUDE_CODE_SUBAGENT_MODEL rejected (routing regression).

### Rename
No rename.

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
