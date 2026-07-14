# Changelog: claude-code

## 2026-07-13 (Phase 3 disambiguation pass)

### Summary
Phase 3 Disambiguation: renamed one confusably-named permission-path constant. Behavior-neutral (identical settings.json output). Also fixed a dangling "six CANONICAL blocks... HARVEST" reference in evolve-config SKILL.md (routed as Coherence-Class, applied directly since mechanical).

### Changes
- Renamed `SENSITIVE_PATHS_READ_ONLY` → `SENSITIVE_PATHS_DENY_READ_ONLY` (src/user.rs, 4 sites). "READ_ONLY" misreads as read-only file mode; actual meaning is "denied for Read only, not Edit/Write."
- Fixed evolve-config SKILL.md's Phase 2 template (2 sites): "six CANONICAL blocks... HARVEST" → "five CANONICAL blocks" — HARVEST is not a SKILL.md-local block in any of the 3 evolve-* siblings, only in evolve-phase0-templates.md §2.

### Dimensions Evaluated
Confusable-name, multi-reading, overlapping-ownership across the four config sources + SKILL.md.

### Rename
`SENSITIVE_PATHS_READ_ONLY` → `SENSITIVE_PATHS_DENY_READ_ONLY` (identifier only; decl comment already accurate).

## 2026-07-13 (Phase 2 coherence pass)

### Summary
Phase 2 coherence: corrected a nonexistent hook source path in the skill spec and drift-prone opencode parity citations; documented a latent AutoMode serde-casing landmine. No settings.json output change.

### Changes
- FIX: corrected `src/user/teammate-idle-hook.sh` → `src/user/claude-code/hooks/teammate-idle-hook.sh` (7×) in evolve-config SKILL.md — nonexistent path was silently under-scoping `wc -l`/`git log` inventory (2>/dev/null hid the miss).
- FIX: replaced stale line-number citations in opencode with_bash_permissions parity comments with relative references (line numbers drift each cycle).
- FIX: added a latent-landmine comment on AutoMode soft_deny/hard_deny (camelCase renames them to softDeny/hardDeny; schema casing unverified).

### Dimensions Evaluated
Core & model routing; Permissions; Sandbox; Hooks & scripts; Skills & auto-mode; Plugins/UI/governance — plus CANONICAL byte-identity across the evolve-* family.

### Rename
No rename.

## 2026-07-13

### Summary
Trial: restore CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1, verify no regression in agent-teams/OTEL/vorpal-run/excluded-commands → proposed. AMPLIFY: DKT-282 PreToolUse guard converts literal /tmp/ Bash write-target denials into actionable pre-call messages (16 sessions/7d). Plus: agent-memory sandbox-write gap closed (35 sessions/7d), ENV_SCRUB history documented, opencode git-add aligned to CC's ask.

### Changes
- AMPLIFY: new guard-tmp-write-hook.sh + 2nd PreToolUse/Bash with_hook registration — unconditional deny (exit 2), allowlists /tmp/claude*+/private/tmp/claude*, write-forms only. Behavioral: hooks map PreToolUse vec gains an entry. No new setter.
- AMPLIFY: added ~/.claude/agent-memory to sandbox filesystem allow-write (new SANDBOX_AGENT_MEMORY_PATH const) — cited signal: 35 sessions/7d bypassed sandbox for doctrine-mandated pitfalls.md writes. Behavioral: allow-write vec gains 1 entry.
- AMPLIFY: WHY-comment at ENV_SCRUB=0 (user.rs) documenting the 44f5cb0 flip; no value change.
- AMPLIFY: removed opencode `git add*` auto-allow → falls to `*`→Ask, matching CC. Behavioral: opencode bash permission map loses one Allow entry.

### Dimensions Evaluated
Hooks&scripts (AMPLIFY); Sandbox (AMPLIFY); Permissions (AMPLIFY, cross-surface); Core&model-routing / Skills&auto-mode / Plugins-UI-governance (RETAIN). Gated → Scientific Trial: ENV_SCRUB=1 restore. Deferred: sandbox.credentials, 1Password socket, auto_mode wiring, advisorModel/enforceAvailableModels/askUserQuestionTimeout/disableSideloadFlags.

### Rename
No rename.

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
