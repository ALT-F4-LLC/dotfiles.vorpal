use crate::file::{FileCreate, FileSource};
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

mod settings;

const OTEL_LOGS_ENDPOINT_LOKI: &str = "https://loki.bulbasaur.altf4.domains/otlp/v1/logs";
const OTEL_METRICS_ENDPOINT_MIMIR: &str = "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";

const SENSITIVE_PATHS: &[&str] = &[
    "~/.claude.json",
    "~/.doppler/**",
    "~/.gemini/**",
    "~/.gnupg/**",
    "~/.kube/**",
    "~/.netrc",
    "~/.ssh/**",
    "~/.talos/**",
    "~/Desktop/**",
    "~/Downloads/**",
];
const SENSITIVE_PATHS_DENY_EDIT_ONLY: &[&str] = &["/Applications/**", "/Library/**", "/System/**"];
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &[".env", ".env.*", "~/.aws/**"];

const SANDBOX_AGENT_MEMORY_PATH: &str = "~/.claude/agent-memory";
// Bare-repo layouts keep the git common dir (objects/, refs/, worktrees/)
// BESIDE each checkout, outside its sandbox write allowlist — so index
// writes, `git worktree remove`, and branch cleanup were all denied from
// checkout and subdirectory seats, and executors responded by disabling the
// sandbox themselves (2026-08-18/19 fleet review). Allowing the org root
// closes that gap; permission rules and hooks still gate every write.
const SANDBOX_BARE_REPO_ROOT: &str = "~/Development/repository/github.com/ALT-F4-LLC";
const SANDBOX_DOCS_CACHE_PATH: &str = "~/.claude/cache/docs";
// The docket global store: every docket verb opens ~/.docket/issues.db
// read-write (WAL + auto-migrate), so without this every sandboxed docket
// invocation fails with "unable to open database file (14)". The corpus
// symlink targets stay in the read-only Vorpal store and are not covered.
const SANDBOX_DOCKET_STORE_PATH: &str = "~/.docket";
// The docket trust store: `docket trust` verbs take a lock at
// ~/.config/docket/trust.toml.lock and fail sandboxed without this, forcing
// a lift per invocation. The verbs themselves stay permission-gated (the
// `Bash(docket trust add/rm:*)` ask rules below), so this only removes the
// sandbox noise, not the human gate.
const SANDBOX_DOCKET_TRUST_PATH: &str = "~/.config/docket";
const SANDBOX_TOOLCHAIN_CACHE_PATHS: &[&str] = &[
    "~/.cache/uv",
    "~/.cargo/git",
    "~/.cargo/registry",
    "~/Library/Caches/go-build",
    "~/go/pkg/mod",
    "~/Library/Caches/golangci-lint",
    "~/Library/Caches/pip",
    "~/Library/Caches/staticcheck",
];

pub struct ClaudeCode {
    name: String,
    systems: Vec<ArtifactSystem>,
}

/// Artifact name for one Claude Code component. `FileCreate` writes its single
/// file under the artifact name, so the same string names the artifact and the
/// file a symlink has to point at.
fn component_name(user: &str, component: &str) -> String {
    format!("{user}-claude-code-{component}")
}

/// Install destination for one entry under the user's Claude Code directory.
fn claude_home(entry: &str) -> String {
    format!("${{HOME}}/.claude/{entry}")
}

/// Permission patterns in a stable order, so the generated settings file does
/// not churn when a path is added in the middle of a list.
fn sorted_permission_patterns(
    wrap: impl Fn(&str) -> String,
    paths: impl IntoIterator<Item = &'static str>,
) -> Vec<String> {
    let mut paths: Vec<&str> = paths.into_iter().collect();
    paths.sort_unstable();
    paths.into_iter().map(wrap).collect()
}

fn deny_sensitive_paths(
    builder: settings::ClaudeCodeSettings,
    wrap: impl Fn(&str) -> String,
    paths: impl IntoIterator<Item = &'static str>,
) -> settings::ClaudeCodeSettings {
    sorted_permission_patterns(wrap, paths)
        .iter()
        .fold(builder, |b, p| b.with_permission_deny(p))
}

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
            &component_name(&self.name, "agents"),
            "src/user/claude_code/agents",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let hooks = FileSource::new(
            &component_name(&self.name, "hooks"),
            "src/user/claude_code/hooks",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let settings_builder = settings::ClaudeCodeSettings::new(&self.name, self.systems.clone())
            .with_always_thinking_enabled(true)
            .with_attribution_commit("")
            .with_attribution_pr("")
            // Defaults to true upstream, which appends a `Claude-Session`
            // trailer to commits and a session link to PR descriptions from
            // cloud and Remote Control sessions. Both attribution strings above
            // are deliberately empty; a session trailer would put harness
            // vocabulary back into commit messages by the side door.
            .with_attribution_session_url(false)
            .with_auto_updates_channel("latest")
            .with_away_summary_enabled(false)
            .with_cleanup_period_days(14)
            // LOWERED from xhigh 2026-08-19 on mined evidence, not taste. A
            // 7-day census of 163 main sessions (scripts/session-census) found
            // 45% of all output tokens were thinking, with a floor of ~39% at
            // every task size -- no task was ever cheap. The only quasi-
            // controlled comparison available, same model and same skill with
            // effort as the sole variable, put xhigh well above high in three
            // of four cells: shadow 18.7% -> 60.2%, loop 40.4% -> 56.4%,
            // conduct 25.7% -> 38.2%; docket dissented (56.1% -> 52.6%) on the
            // thinnest cell (32 msgs, 1 session).
            //
            // Deliberately the ONLY reasoning dial moved in this change.
            // always_thinking_enabled stays true so the next census can
            // attribute any movement to this line alone; changing both would
            // make the before/after unreadable. Re-run session-census after a
            // week and decide the next step from the diff.
            .with_effort_level("high")
            .with_feedback_survey_rate(0.0)
            .with_include_git_instructions(false)
            .with_model("sonnet")
            .with_output_style("Proactive")
            .with_permission_default_mode("auto")
            .with_permission_disable_bypass_permissions_mode("disable")
            .with_preferred_notif_channel("ghostty")
            .with_sandbox_enabled(true)
            .with_show_thinking_summaries(true)
            .with_skill_listing_budget_fraction(0.02)
            .with_spinner_tips_enabled(false)
            .with_status_line("bash ~/.claude/statusline.sh")
            .with_status_line_padding(0)
            .with_teammate_mode("in-process")
            .with_tui("fullscreen")
            .with_worktree_base_ref("head");

        let settings_builder = settings_builder
            .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
            .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
            .with_enabled_plugin("typescript-lsp@claude-plugins-official", true);

        let settings_builder = settings_builder
            .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
            .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
            .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
            .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5")
            .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
            .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5[1m]")
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
            .with_env("OTEL_METRIC_EXPORT_INTERVAL", "15000");

        let settings_builder = settings_builder
            .with_hook(
                "PreToolUse",
                Some("Workflow|Agent"),
                "bash ~/.claude/hooks/docket-spawn-guard-hook.sh",
                "command",
            )
            .with_hook(
                "PreToolUse",
                Some("Workflow"),
                "bash ~/.claude/hooks/docket-policy-guard-hook.sh",
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
                "PreToolUse",
                Some("Bash"),
                "bash ~/.claude/hooks/sandbox-bypass-ask-hook.sh",
                "command",
            )
            .with_hook(
                "SessionStart",
                None,
                "bash ~/.claude/hooks/docket-session-start-hook.sh",
                "command",
            );

        let settings_builder = settings_builder
            .with_permission_allow("Bash(docket config get:*)")
            .with_permission_allow("Bash(docket events list:*)")
            .with_permission_allow("Bash(docket issue list:*)")
            .with_permission_allow("Bash(docket issue show:*)")
            .with_permission_allow("Bash(docket project list:*)")
            .with_permission_allow("Bash(docket run report:*)")
            .with_permission_allow("Bash(docket run status:*)")
            .with_permission_allow("Bash(docket step artifact:*)")
            .with_permission_allow("Bash(docket step artifacts:*)")
            .with_permission_allow("Bash(docket step render:*)")
            .with_permission_allow("Bash(docket step show:*)")
            .with_permission_allow("Bash(docket trust list:*)")
            .with_permission_allow("Bash(docket vote show:*)")
            .with_permission_allow("Bash(docket workflow list:*)")
            .with_permission_allow("Bash(docket workflow show:*)")
            .with_permission_allow("Bash(git branch:*)")
            .with_permission_allow("Bash(git diff:*)")
            .with_permission_allow("Bash(git log:*)")
            .with_permission_allow("Bash(git show:*)")
            .with_permission_allow("Bash(git status:*)")
            .with_permission_allow("Bash(git worktree list:*)")
            .with_permission_allow("Bash(go build:*)")
            .with_permission_allow("Bash(go test:*)")
            .with_permission_allow("Bash(go tool golangci-lint:*)")
            .with_permission_allow("Bash(go vet:*)")
            .with_permission_allow("Bash(gofmt:*)")
            .with_permission_allow("Bash(~/.claude/scripts/shadow-transcript-summary.sh:*)")
            .with_permission_allow("Bash(~/.claude/scripts/wave-usage:*)")
            .with_permission_allow("WebFetch(domain:api.github.com)")
            .with_permission_allow("WebFetch(domain:claude.ai)")
            .with_permission_allow("WebFetch(domain:code.claude.com)")
            .with_permission_allow("WebFetch(domain:crates.io)")
            .with_permission_allow("WebFetch(domain:docs.claude.ai)")
            .with_permission_allow("WebFetch(domain:github.com)")
            .with_permission_allow("WebFetch(domain:mimir.bulbasaur.altf4.domains)")
            .with_permission_allow("WebFetch(domain:raw.githubusercontent.com)")
            .with_permission_allow("WebSearch")
            // The conduct loop's own mandated launches (wave.js, tribunal.js):
            // the auto-mode classifier denied these after ~15 identical
            // approvals and stalled a run 3.7 hours (2026-08-19 fleet review).
            // There is no documented per-script specifier for this tool, so
            // the rule is tool-wide; launch CONTENT is still screened by the
            // always-on harness spawn classifier and the docket spawn-guard /
            // policy-guard / wave-audit hooks, and every subagent's own tool
            // calls remain individually permission-gated.
            .with_permission_allow("Workflow");

        let settings_builder = settings_builder
            .with_permission_ask("Bash(docket trust add:*)")
            .with_permission_ask("Bash(docket trust rm:*)")
            .with_permission_ask("Bash(git push:*)");

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
            .with_sandbox_allow_unsandboxed_commands(true)
            .with_sandbox_auto_allow_bash(true)
            .with_sandbox_fail_if_unavailable(true)
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
                    .chain(std::iter::once(&SANDBOX_BARE_REPO_ROOT))
                    .chain(std::iter::once(&SANDBOX_DOCS_CACHE_PATH))
                    .chain(std::iter::once(&SANDBOX_DOCKET_STORE_PATH))
                    .chain(std::iter::once(&SANDBOX_DOCKET_TRUST_PATH))
                    .map(|p| p.to_string())
                    .collect(),
            )
            .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
            // Kept alphabetical, and every entry carries the gate it unblocks:
            // a domain whose reason is not written down is one nobody can
            // safely remove later. Both Go entries were added after a sandboxed
            // gate DNS-failed and was misread as a code finding — the failure
            // mode this list exists to prevent.
            .with_sandbox_network_allowed_domains(vec![
                "api.github.com".to_string(),
                "crates.io".to_string(),
                "github.com".to_string(),
                // The Go module proxy. `go tool <x>` resolves from GOMODCACHE
                // with no network only once that module is already there; an
                // executor whose cache is cold downloads instead, and the
                // self-hygiene gate then fails on `lookup proxy.golang.org: no
                // such host` rather than on the code. Measured 4x in one run
                // before this entry, each costing a manual override-pass
                // (DOT-173). The cache itself is shared, not per-agent —
                // ~/go/pkg/mod is in SANDBOX_TOOLCHAIN_CACHE_PATHS above.
                "proxy.golang.org".to_string(),
                "static.crates.io".to_string(),
                // govulncheck's vulnerability DB — without it, sandboxed
                // vuln-scan gates DNS-fail and misread as findings (RUN-2: 25
                // starved spawns).
                "vuln.go.dev".to_string(),
            ])
            .with_sandbox_network_allow_unix_sockets(vec![
                "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock".to_string(),
            ])
            .with_sandbox_network_allow_local_binding(true)
            .build(context)
            .await?;

        let scripts = FileSource::new(
            &component_name(&self.name, "scripts"),
            "src/user/claude_code/scripts",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let skills = FileSource::new(
            &component_name(&self.name, "skills"),
            "src/user/claude_code/skills",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        // Declared before `statusline` because that binding moves `self.systems`;
        // every FileSource above clones it and this one must too.
        let workflows = FileSource::new(
            &component_name(&self.name, "workflows"),
            "src/user/claude_code/workflows",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        // The main conversation was the one surface with no definition at all:
        // agents/, skills/, and workflows/ all govern spawned work, while the
        // session the operator actually talks to had nothing. That is where the
        // 2026-08-19 census found the unaddressed half of the cost -- 82
        // interrupts and 217 stopped agents in a week, none of which any
        // subagent brief can reach.
        let memory = FileCreate::new(
            &component_name(&self.name, "memory"),
            self.systems.clone(),
            include_str!("claude_code_memory.md"),
        )
        .build(context)
        .await?;

        let statusline = FileCreate::new(
            &component_name(&self.name, "statusline"),
            self.systems,
            include_str!("claude_code_statusline.sh"),
        )
        .with_executable(true)
        .build(context)
        .await?;

        let symlinks = vec![
            (get_env_key(&agents), claude_home("agents")),
            (get_env_key(&hooks), claude_home("hooks")),
            (
                FileCreate::output_file_path(
                    &get_env_key(&memory),
                    &component_name(&self.name, "memory"),
                ),
                claude_home("CLAUDE.md"),
            ),
            (get_env_key(&scripts), claude_home("scripts")),
            (
                FileCreate::output_file_path(
                    &get_env_key(&settings),
                    &component_name(&self.name, "settings"),
                ),
                claude_home("settings.json"),
            ),
            (get_env_key(&skills), claude_home("skills")),
            (
                FileCreate::output_file_path(
                    &get_env_key(&statusline),
                    &component_name(&self.name, "statusline"),
                ),
                claude_home("statusline.sh"),
            ),
            (get_env_key(&workflows), claude_home("workflows")),
        ];

        let artifacts = vec![
            agents, hooks, memory, scripts, settings, skills, statusline, workflows,
        ];

        Ok((artifacts, symlinks))
    }
}

#[cfg(test)]
mod tests {
    use super::{
        claude_home, component_name, sandbox_filesystem_deny_read_paths,
        sorted_permission_patterns, SENSITIVE_PATHS, SENSITIVE_PATHS_DENY_EDIT_ONLY,
        SENSITIVE_PATHS_DENY_READ_ONLY,
    };
    use crate::file::FileCreate;

    #[test]
    fn component_artifacts_are_namespaced_by_user_and_component() {
        assert_eq!(
            component_name("user", "settings"),
            "user-claude-code-settings"
        );
        assert_eq!(
            component_name("user", "statusline"),
            "user-claude-code-statusline"
        );
    }

    #[test]
    fn install_destinations_live_under_the_home_claude_directory() {
        assert_eq!(
            claude_home("settings.json"),
            "${HOME}/.claude/settings.json"
        );
        assert_eq!(claude_home("agents"), "${HOME}/.claude/agents");
    }

    #[test]
    fn single_file_components_link_to_the_file_not_the_artifact_directory() {
        let output = "/var/lib/vorpal/store/artifact/output/user/abc123";

        let source = FileCreate::output_file_path(output, &component_name("user", "settings"));

        assert_eq!(
            source,
            "/var/lib/vorpal/store/artifact/output/user/abc123/user-claude-code-settings"
        );
        assert_ne!(source, output);
    }

    #[test]
    fn permission_patterns_are_wrapped_and_sorted() {
        let patterns = sorted_permission_patterns(
            |p| format!("Edit({p})"),
            ["~/.ssh/**", ".env", "/Applications/**"],
        );

        assert_eq!(
            patterns,
            vec![
                "Edit(.env)".to_string(),
                "Edit(/Applications/**)".to_string(),
                "Edit(~/.ssh/**)".to_string(),
            ]
        );
    }

    #[test]
    fn sandbox_read_denials_cover_every_sensitive_path() {
        let denied = sandbox_filesystem_deny_read_paths();

        for path in SENSITIVE_PATHS.iter().chain(SENSITIVE_PATHS_DENY_READ_ONLY) {
            let expected = path.strip_suffix("/**").unwrap_or(path);

            assert!(
                denied.contains(&expected.to_string()),
                "sandbox read denials are missing {expected}"
            );
        }
    }

    #[test]
    fn sandbox_read_denials_carry_no_directory_glob_suffix() {
        for path in sandbox_filesystem_deny_read_paths() {
            assert!(
                !path.ends_with("/**"),
                "{path} keeps a glob suffix the sandbox reads literally"
            );
        }
    }

    #[test]
    fn sandbox_read_denials_exclude_the_edit_only_system_paths() {
        let denied = sandbox_filesystem_deny_read_paths();

        for path in SENSITIVE_PATHS_DENY_EDIT_ONLY {
            let stripped = path.strip_suffix("/**").unwrap_or(path);

            assert!(
                !denied.contains(&stripped.to_string()),
                "{stripped} is edit-denied only and must stay readable"
            );
        }
    }

    #[test]
    fn sandbox_read_denials_are_sorted_and_unique() {
        let denied = sandbox_filesystem_deny_read_paths();
        let mut expected = denied.clone();

        expected.sort_unstable();
        expected.dedup();

        assert_eq!(denied, expected);
    }
}
