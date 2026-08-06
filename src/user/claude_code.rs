use crate::file::{FileCreate, FileSource};
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

mod settings;

const OTEL_LOGS_ENDPOINT_LOKI: &str = "https://loki.bulbasaur.altf4.domains/otlp/v1/logs";
const OTEL_METRICS_ENDPOINT_MIMIR: &str = "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";

// `SENSITIVE_PATHS` feeds two different absolute-path prefix dialects depending on which
// consumer reads it: `Edit(...)`/`Read(...)` permission rules (see `deny_sensitive_paths`
// below) anchor an absolute path with a *double* leading slash (`//path`; a single `/path`
// instead anchors at the settings source, e.g. `~/.claude` for this user-level config) —
// code.claude.com/docs/en/permissions#read-and-edit. `sandbox.filesystem.*` settings (see
// `sandbox_filesystem_deny_read_paths` below) instead anchor an absolute path with a single
// leading slash (`/path`) — code.claude.com/docs/en/sandboxing#configure-sandboxing. A future
// entry that gets this backwards silently misfires exactly the way the pre-fix `/Applications`
// form did here.
const SENSITIVE_PATHS: &[&str] = &[
    "~/.claude.json",
    "~/.doppler/**",
    "~/.gemini/**",
    "~/.gnupg/**",
    // kubeconfig may hold long-lived inline credentials (e.g. Talos-generated), so this stays
    // deny-read rather than allowlisted; kubectl work requires `dangerouslyDisableSandbox=true`.
    "~/.kube/**",
    "~/.netrc",
    "~/.ssh/**",
    "~/.talos/**",
    "~/Desktop/**",
    "~/Downloads/**",
];

// /Applications, /Library, /System are integrity-sensitive (no writes/edits), not
// confidentiality-sensitive: toolchains need real read access under them (the dyld shared
// cache under /System, /Library/Developer/CommandLineTools, and this repo's own
// /Applications/Obsidian.app/Contents/MacOS PATH entry below). They're deliberately kept out
// of `SENSITIVE_PATHS` (which also generates `Read` denies) rather than added there:
// `Read`/`Edit` permission-rule paths and `sandbox.filesystem` settings are merged into the
// final sandbox configuration (code.claude.com/docs/en/sandboxing#permission-rules), so a
// `Read(//Applications/**)` deny here would inject the real `/Applications` into the
// OS-level sandbox's `denyRead` set and regress those toolchain reads. `Edit` denies don't
// have that problem — subprocess writes under these 3 paths should stay blocked either way.
const SENSITIVE_PATHS_DENY_EDIT_ONLY: &[&str] =
    &["//Applications/**", "//Library/**", "//System/**"];

const SANDBOX_AGENT_MEMORY_PATH: &str = "~/.claude/agent-memory";
const SANDBOX_DOCS_CACHE_PATH: &str = "~/.claude/cache/docs";
const SANDBOX_TOOLCHAIN_CACHE_PATHS: &[&str] = &[
    "~/.cache/uv",
    "~/.cargo/git",
    "~/.cargo/registry",
    "~/Library/Caches/pip",
];
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &[".env", ".env.*", "~/.aws/**"];

pub struct ClaudeCode {
    name: String,
    systems: Vec<ArtifactSystem>,
}

// Applies a `deny` permission rule for each sensitive path, formatted via `wrap` (e.g.
// `Edit({path})`), in sorted order to match the existing deny-list convention.
fn deny_sensitive_paths(
    builder: settings::ClaudeCodeSettings,
    wrap: impl Fn(&str) -> String,
    paths: impl IntoIterator<Item = &'static str>,
) -> settings::ClaudeCodeSettings {
    let mut paths: Vec<&str> = paths.into_iter().collect();
    paths.sort_unstable();
    paths
        .into_iter()
        .fold(builder, |b, p| b.with_permission_deny(&wrap(p)))
}

// Bare-path form (no `Edit(...)`/`Read(...)` wrapper, no `/**` suffix) of every path denied for
// Read, for the OS-level sandbox's confidentiality-only `with_sandbox_filesystem_deny_read`.
// `SENSITIVE_PATHS_DENY_EDIT_ONLY` never feeds Read denies in the first place (see its comment
// above), so no exclusion filter is needed here.
fn sandbox_filesystem_deny_read_paths() -> Vec<String> {
    let mut paths: Vec<String> = SENSITIVE_PATHS
        .iter()
        .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
        .map(|p| p.strip_suffix("/**").unwrap_or(p).to_string())
        .collect();
    paths.sort_unstable();
    paths
}

impl ClaudeCode {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(
        self,
        context: &mut ConfigContext,
    ) -> Result<(Vec<String>, Vec<(String, String)>)> {
        let agents = FileSource::new(
            &format!("{}-claude-code-agents", self.name),
            "src/user/claude_code/agents",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let hooks = FileSource::new(
            &format!("{}-claude-code-hooks", self.name),
            "src/user/claude_code/hooks",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let graph_config = FileSource::new(
            &format!("{}-claude-code-graph-config", self.name),
            "src/user/claude_code/config",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let workflows = FileSource::new(
            &format!("{}-claude-code-graph-workflows", self.name),
            "src/user/claude_code/workflows",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let settings_builder = settings::ClaudeCodeSettings::new(&self.name, self.systems.clone())
            .with_always_thinking_enabled(false)
            .with_attribution_commit("")
            .with_attribution_pr("")
            .with_auto_updates_channel("latest")
            .with_away_summary_enabled(false)
            .with_cleanup_period_days(14)
            .with_effort_level("high")
            .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
            .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
            .with_enabled_plugin("typescript-lsp@claude-plugins-official", true)
            .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
            .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
            .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
            .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5")
            .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
            .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5")
            .with_env("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-5")
            .with_env("OTEL_EXPORTER_OTLP_LOGS_ENDPOINT", OTEL_LOGS_ENDPOINT_LOKI)
            .with_env("OTEL_EXPORTER_OTLP_LOGS_PROTOCOL", OTEL_OTLP_PROTOCOL)
            .with_env(
                "OTEL_EXPORTER_OTLP_METRICS_ENDPOINT",
                OTEL_METRICS_ENDPOINT_MIMIR,
            )
            .with_env("OTEL_EXPORTER_OTLP_METRICS_PROTOCOL", OTEL_OTLP_PROTOCOL)
            .with_env(
                "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE",
                "cumulative",
            )
            .with_env("OTEL_LOGS_EXPORTER", "otlp")
            .with_env("OTEL_LOGS_EXPORT_INTERVAL", "15000")
            .with_env("OTEL_METRICS_EXPORTER", "otlp")
            .with_env("OTEL_METRIC_EXPORT_INTERVAL", "15000")
            .with_feedback_survey_rate(0.0)
            .with_hook(
                "PreToolUse",
                Some("Bash"),
                "bash ~/.claude/hooks/guard-no-commit-hook.sh",
                "command",
            )
            .with_hook(
                "PreToolUse",
                Some("Bash"),
                "bash ~/.claude/hooks/guard-tmp-write-hook.sh",
                "command",
            )
            .with_hook(
                "TaskCompleted",
                None,
                "bash ~/.claude/hooks/task-completed-hook.sh",
                "command",
            )
            .with_hook(
                "TeammateIdle",
                None,
                "bash ~/.claude/hooks/teammate-idle-hook.sh",
                "command",
            )
            .with_hook(
                "SubagentStop",
                None,
                "bash ~/.claude/hooks/subagent-report-hook.sh",
                "command",
            )
            .with_hook(
                "Stop",
                None,
                "bash ~/.claude/hooks/stop-guard-hook.sh",
                "command",
            )
            // Graph fleet hooks (M3/G4, TDD §4.5). Each is a shim over an engine guard verb; the
            // predicates live in the engine. All are global to the session tree — per-executor
            // scoping comes from engine state, never from hook configuration (03 §5) — so each one
            // no-ops when no active run exists, including in the operator's own sessions and the
            // old fleet's.
            //
            // BOTH Stop hooks stay registered, deliberately (AC-4.7). `stop-guard-hook.sh` above
            // serves the old fleet and is inert in a graph session: both of its dimensions gate on
            // a per-session team config that a graph session does not have (verified live — a
            // graph session with pending engine work got `{}`/exit 0 from it). Deleting it is M5's
            // one dotfiles change, not M3's (§9).
            //
            // `heartbeat` is absent by decision, not omission — see the FileSource comment above.
            .with_hook(
                "PreToolUse",
                Some("Workflow|Agent"),
                "bash ~/.claude/hooks/docket-spawn-guard-hook.sh",
                "command",
            )
            .with_hook(
                "PostToolUse",
                Some("Workflow"),
                "bash ~/.claude/hooks/docket-wave-audit-hook.sh",
                "command",
            )
            .with_hook(
                "Stop",
                None,
                "bash ~/.claude/hooks/docket-run-guard-hook.sh",
                "command",
            )
            .with_hook(
                "PreToolUse",
                Some("Bash"),
                "bash ~/.claude/hooks/docket-commit-guard-hook.sh",
                "command",
            )
            .with_hook(
                "SessionStart",
                None,
                "bash ~/.claude/hooks/docket-session-start-hook.sh",
                "command",
            )
            .with_include_git_instructions(false)
            .with_model("opus")
            .with_output_style("Proactive")
            .with_permission_allow("Bash(bun run:*)")
            .with_permission_allow("Bash(bun test:*)")
            .with_permission_allow("Bash(cargo build:*)")
            .with_permission_allow("Bash(cargo check:*)")
            .with_permission_allow("Bash(cargo clippy:*)")
            .with_permission_allow("Bash(cargo fmt:*)")
            .with_permission_allow("Bash(cargo outdated:*)")
            .with_permission_allow("Bash(cargo run:*)")
            .with_permission_allow("Bash(cargo search:*)")
            .with_permission_allow("Bash(cargo test:*)")
            .with_permission_allow("Bash(cargo tree:*)")
            .with_permission_allow("Bash(cargo update:*)")
            .with_permission_allow("Bash(cat:*)")
            .with_permission_allow("Bash(chmod:*)")
            .with_permission_allow("Bash(cue:*)")
            .with_permission_allow("Bash(docker images:*)")
            .with_permission_allow("Bash(docker logs:*)")
            .with_permission_allow("Bash(docker ps:*)")
            .with_permission_allow("Bash(docket:*)")
            .with_permission_allow("Bash(find:*)")
            .with_permission_allow("Bash(gh pr diff:*)")
            .with_permission_allow("Bash(gh pr list:*)")
            .with_permission_allow("Bash(gh pr view:*)")
            .with_permission_allow("Bash(git branch:*)")
            .with_permission_allow("Bash(git diff:*)")
            .with_permission_allow("Bash(git log:*)")
            .with_permission_allow("Bash(git remote get-url:*)")
            .with_permission_allow("Bash(git show:*)")
            .with_permission_allow("Bash(git status:*)")
            .with_permission_allow("Bash(go build:*)")
            .with_permission_allow("Bash(go doc:*)")
            .with_permission_allow("Bash(go list:*)")
            .with_permission_allow("Bash(go mod tidy:*)")
            .with_permission_allow("Bash(go test:*)")
            .with_permission_allow("Bash(go version:*)")
            .with_permission_allow("Bash(go vet:*)")
            .with_permission_allow("Bash(gofmt:*)")
            .with_permission_allow("Bash(grep:*)")
            .with_permission_allow("Bash(head:*)")
            .with_permission_allow("Bash(jq:*)")
            .with_permission_allow("Bash(ls:*)")
            .with_permission_allow("Bash(make:*)")
            .with_permission_allow("Bash(npm run build:*)")
            .with_permission_allow("Bash(npm run lint:*)")
            .with_permission_allow("Bash(npm run test:*)")
            .with_permission_allow("Bash(npx tsc:*)")
            .with_permission_allow("Bash(rg:*)")
            .with_permission_allow("Bash(sort:*)")
            .with_permission_allow("Bash(staticcheck:*)")
            .with_permission_allow("Bash(tail:*)")
            .with_permission_allow("Bash(tar:*)")
            .with_permission_allow("Bash(test:*)")
            .with_permission_allow("Bash(tree:*)")
            .with_permission_allow("Bash(vorpal build:*)")
            .with_permission_allow("Bash(vorpal inspect:*)")
            .with_permission_allow("Bash(vorpal run:*)")
            .with_permission_allow("Bash(wc:*)")
            .with_permission_allow("Bash(xargs:*)")
            .with_permission_allow("Bash(yarn build:*)")
            .with_permission_allow("Bash(yarn lint:*)")
            .with_permission_allow("Bash(yarn test:*)")
            .with_permission_allow("WebFetch(domain:api.github.com)")
            .with_permission_allow("WebFetch(domain:claude.ai)")
            .with_permission_allow("WebFetch(domain:code.claude.com)")
            .with_permission_allow("WebFetch(domain:crates.io)")
            .with_permission_allow("WebFetch(domain:docs.claude.ai)")
            .with_permission_allow("WebFetch(domain:github.com)")
            .with_permission_allow("WebFetch(domain:mimir.bulbasaur.altf4.domains)")
            .with_permission_allow("WebFetch(domain:raw.githubusercontent.com)")
            .with_permission_allow("WebSearch")
            .with_permission_ask("Bash(chown:*)")
            // `docket trust` writes the trust store that gates which commands the engine may run
            // unattended, so it is the one docket verb a session must not be able to grant itself
            // (graph-engine D14's human-confirmation backstop). The broader
            // `Bash(docket:*)` allow above stays — this narrower `ask` is expected to take
            // precedence over it. That precedence is the load-bearing assumption; if it ever
            // stops holding, the fix is to narrow the allow by enumerating the non-trust verbs
            // rather than to rely on this line.
            .with_permission_ask("Bash(docket trust:*)")
            .with_permission_ask("Bash(git add:*)")
            .with_permission_ask("Bash(git commit:*)")
            .with_permission_ask("Bash(git push:*)")
            .with_permission_ask("Bash(rm:*)")
            // Deny whole subcommand families, not just destructive flag combos: deny rules can't
            // carry allowlist exceptions, and narrow rules here are still bypassable via global
            // options (e.g. `git -C`) or argument variants. See DKT-190.
            .with_permission_deny("Bash(git checkout:*)")
            .with_permission_deny("Bash(git clean:*)")
            .with_permission_deny("Bash(git reset:*)")
            .with_permission_deny("Bash(git restore:*)")
            .with_permission_deny("Bash(git rm:*)")
            .with_permission_deny("Bash(git switch:*)");

        let settings_builder = deny_sensitive_paths(
            settings_builder,
            |p| format!("Edit({p})"),
            SENSITIVE_PATHS
                .iter()
                .chain(SENSITIVE_PATHS_DENY_EDIT_ONLY)
                .copied(),
        );

        let settings_builder = deny_sensitive_paths(
            settings_builder,
            |p| format!("Read({p})"),
            SENSITIVE_PATHS
                .iter()
                .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
                .copied(),
        );

        let settings = settings_builder
            .with_permission_default_mode("auto")
            .with_permission_disable_bypass_permissions_mode("disable")
            .with_preferred_notif_channel("ghostty")
            .with_show_thinking_summaries(true)
            .with_skill_listing_budget_fraction(0.02)
            .with_spinner_tips_enabled(false)
            .with_status_line("bash ~/.claude/statusline.sh")
            .with_status_line_padding(0)
            .with_sandbox_enabled(true)
            .with_sandbox_fail_if_unavailable(true)
            .with_sandbox_auto_allow_bash(true)
            .with_sandbox_allow_unsandboxed_commands(true)
            .with_sandbox_excluded_commands(vec![
                "aws".to_string(),
                "docker".to_string(),
                "gh".to_string(),
                "git".to_string(),
                "kubectl".to_string(),
                "uv".to_string(),
                "vorpal".to_string(),
                "xcrun".to_string(),
            ])
            .with_sandbox_filesystem_allow_write(
                SANDBOX_TOOLCHAIN_CACHE_PATHS
                    .iter()
                    .chain(std::iter::once(&SANDBOX_AGENT_MEMORY_PATH))
                    .chain(std::iter::once(&SANDBOX_DOCS_CACHE_PATH))
                    .map(|p| p.to_string())
                    .collect(),
            )
            .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
            .with_sandbox_network_allowed_domains(vec![
                "crates.io".to_string(),
                "static.crates.io".to_string(),
                "github.com".to_string(),
                "api.github.com".to_string(),
            ])
            // 1Password requires per-use approval for SSH-agent signing operations, so
            // allowlisting only this socket (not `allow_all_unix_sockets`) keeps that
            // approval prompt as the safety gate for sandboxed `git commit` signing.
            .with_sandbox_network_allow_unix_sockets(vec![
                "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock".to_string(),
            ])
            .with_sandbox_network_allow_local_binding(false)
            .with_teammate_mode("in-process")
            .with_tui("fullscreen")
            .build(context)
            .await?;

        let scripts = FileSource::new(
            &format!("{}-claude-code-scripts", self.name),
            "src/user/claude_code/scripts",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let skills = FileSource::new(
            &format!("{}-claude-code-skills", self.name),
            "src/user/claude_code/skills",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let statusline = FileCreate::new(
            &format!("{}-claude-code-statusline", self.name),
            self.systems,
            include_str!("claude_code_statusline.sh"),
        )
        .with_executable(true)
        .build(context)
        .await?;

        let symlinks = vec![
            (get_env_key(&agents), "${HOME}/.claude/agents".to_string()),
            (
                get_env_key(&graph_config),
                "${HOME}/.claude/docket-config".to_string(),
            ),
            (
                get_env_key(&workflows),
                "${HOME}/.claude/workflows".to_string(),
            ),
            (get_env_key(&hooks), "${HOME}/.claude/hooks".to_string()),
            (get_env_key(&scripts), "${HOME}/.claude/scripts".to_string()),
            (
                format!(
                    "{}/{}-claude-code-settings",
                    get_env_key(&settings),
                    self.name
                ),
                "${HOME}/.claude/settings.json".to_string(),
            ),
            (get_env_key(&skills), "${HOME}/.claude/skills".to_string()),
            (
                format!(
                    "{}/{}-claude-code-statusline",
                    get_env_key(&statusline),
                    self.name
                ),
                "${HOME}/.claude/statusline.sh".to_string(),
            ),
        ];

        let artifacts = vec![
            agents,
            graph_config,
            hooks,
            scripts,
            settings,
            skills,
            statusline,
            workflows,
        ];

        Ok((artifacts, symlinks))
    }
}
