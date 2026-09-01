use crate::file::{FileCreate, FileSource};
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

mod settings;

const GIT_ALLOWED_SIGNERS_CONFIG_PATH: &str = "~/.config/git/allowed_signers";
const GIT_ALLOWED_SIGNERS_INSTALL_PATH: &str = "${HOME}/.config/git/allowed_signers";
const OTEL_LOGS_ENDPOINT_LOKI: &str = "https://loki.bulbasaur.altf4.domains/otlp/v1/logs";
const OTEL_METRICS_ENDPOINT_MIMIR: &str = "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";
const SANDBOX_AGENT_MEMORY_PATH: &str = "~/.claude/agent-memory";
const SANDBOX_BARE_REPO_ROOT: &str = "~/Development/repository/github.com/ALT-F4-LLC";
const SANDBOX_CLAUDE_SCRATCH_ROOT: &str = "/tmp/claude-501";
const SANDBOX_CLAUDE_SCRATCH_ROOT_PRIVATE: &str = "/private/tmp/claude-501";
const SANDBOX_DARWIN_TEMP_ROOT: &str = "/var/folders";
const SANDBOX_DOCKET_STORE_PATH: &str = "~/.docket";
const SANDBOX_DOCKET_TRUST_LOCK_PATH: &str = "~/.config/docket/trust.toml.lock";
const SANDBOX_DOCS_CACHE_PATH: &str = "~/.claude/cache/docs";
const SANDBOX_FRICTION_LEDGER_PATH: &str = "~/.claude/friction";
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &["~/.aws/**"];

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

const SENSITIVE_PATHS_DENY_EDIT_ONLY: &[&str] = &[
    "/Applications/**",
    "/Library/**",
    "/System/**",
    "~/.config/docket/trust.toml",
];

const AUTO_MODE_ENVIRONMENT_CONTEXT: &[&str] = &[
    "### Org-wide",
    "**Organization**: ALT-F4 LLC (solo operator)",
    "**Cloud provider(s)**: none — self-hosted Talos homelab (the bulbasaur cluster)",
    "**Repository visibility**: ALT-F4-LLC repositories are mostly public — treat any push as publishing unless the working repo is confirmed private",
    "**Internal sharing / snippet hosting**: None configured — treat public paste/gist services as outside the trust boundary",
    "**Secrets management**: Doppler and 1Password are the secret stores — secrets live there and are injected via `doppler run` / `op run` / `op read`; never copy a secret out of them into repos, files, or external destinations",
    "**CI/CD deploy targets**: None configured",
    "**Network posture**: None configured",
    "**Source control**: All repositories under the github.com/ALT-F4-LLC organization — many are public, so only a repo's own work should be pushed to it and public visibility never clears sensitive data into it",
    "**Trusted internal domains**: *.altf4.domains (the bulbasaur homelab services) and vorpal.build",
    "**Trusted cloud buckets**: None configured",
    "**Key internal services**: bulbasaur cluster services under *.altf4.domains — mimir, loki, coder, argocd, knative, agentgateway — plus registry.altf4.domains",
    "**Internal package registry**: registry.altf4.domains",
    "**Sensitive data locations & audiences**: any file or store holding personal data, confidential business data, credentials, regulated data, or similarly sensitive material; preserve exact handles when known and share only with audiences cleared at the [named+specifics] bar; treat `.env` files, `.envrc`, and anything a repo's secret-scan tooling flags as sensitive-data locations",
    "**Data retention / declassification**: None configured",
    "**Sensitive remote targets**: the bulbasaur Kubernetes cluster (Talos/flux-managed homelab) is production — deploys, remote shells, and destructive operations against it require the operator's explicit ask; also any namespace, host, or container whose name carries `prod` or `production` as a whole word or name segment (hyphen/underscore/dot-delimited)",
    "**Protected deployment namespaces / environments**: None configured — fall back to the Sensitive remote targets heuristic",
    "**Protected IaC scopes**: IAM, RBAC, networking, quota, and node-pool resources; anything whose name or tag carries `prod` or `production` as a whole word or name segment",
    "### User-specific",
    "**Primary use of Claude Code**: software development across ALT-F4-LLC projects (Vorpal build tooling, Claude Code agent configuration, homelab GitOps)",
    "**Trusted repos**: any github.com/ALT-F4-LLC repository checked out as the working directory, with its origin remote; most are public, so only a repo's own work is committed/pushed there and secrets/sensitive data are never cleared into it by visibility alone",
    "**Org-specific CLIs**: docket (high-frequency usage across projects; also present in shell history with a bundled secret-scan script) — routine under ALT-F4-LLC repos",
    "**routine under ~/.claude/ prefix**: fixes and edits under `~/.claude` are governed by the working agreement there (source-only edits, install via `just activate`, never edit installed tree directly)",
];

const AUTO_MODE_ALLOW_RULES: &[&str] = &[
    "$defaults",
    "Bash(docket:*) in ALT-F4-LLC repositories — high-frequency org CLI",
    "Bash(cargo:*) in ALT-F4-LLC repositories — build/test/fmt/check/clippy, including invocations prefixed with CARGO_HOME/CARGO_TARGET_DIR/GOCACHE-style cache overrides; writes only to build caches",
    "Local git operations in trusted repositories — add, commit, worktree, cherry-pick, cat-file, rev-parse, and other repo-local verbs; `git push` publishes and stays outside this rule",
    "Bash(vorpal:*) in ALT-F4-LLC repositories — the org's own build tool, same standing as docket",
    "Read-only cluster reads against bulbasaur — kubectl get/describe/logs, flux get; mutations against the cluster stay outside this rule (production)",
];

const SANDBOX_TOOLCHAIN_CACHE_PATHS: &[&str] = &[
    "~/.cache/golangci-lint-harness",
    "~/.cache/uv",
    "~/.cargo/git",
    "~/.cargo/registry",
    "~/.docker/buildx",
    "~/Development/language/go/pkg/mod",
    "~/Library/Application Support/go",
    "~/Library/Caches/go-build",
    "~/Library/Caches/golangci-lint",
    "~/Library/Caches/pip",
    "~/Library/Caches/pip-audit",
    "~/Library/Caches/staticcheck",
    "~/go/pkg/mod",
];

pub struct ClaudeCode {
    name: String,
    systems: Vec<ArtifactSystem>,
}

fn component_name(user: &str, component: &str) -> String {
    format!("{user}-claude-code-{component}")
}

fn claude_home(entry: &str) -> String {
    format!("${{HOME}}/.claude/{entry}")
}

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
            .with_agent_push_notif_enabled(true)
            .with_always_thinking_enabled(true)
            .with_attribution_commit("")
            .with_attribution_pr("")
            .with_attribution_session_url(false)
            .with_auto_memory_enabled(false)
            .with_auto_updates_channel("latest")
            .with_away_summary_enabled(false)
            .with_cleanup_period_days(7)
            .with_effort_level("high")
            .with_feedback_survey_rate(0.0)
            .with_include_git_instructions(false)
            .with_input_needed_notif_enabled(true)
            .with_model("sonnet")
            .with_output_style("Concise")
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
            .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5-1")
            .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
            .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5")
            .with_env("ANTHROPIC_DEFAULT_SONNET_MODEL", "claude-sonnet-5")
            .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
            .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
            .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
            .with_env("GIT_CONFIG_COUNT", "4")
            .with_env("GIT_CONFIG_KEY_0", "user.signingkey")
            .with_env("GIT_CONFIG_KEY_1", "gpg.ssh.program")
            .with_env("GIT_CONFIG_KEY_2", "gpg.format")
            .with_env("GIT_CONFIG_KEY_3", "gpg.ssh.allowedSignersFile")
            .with_env("GIT_CONFIG_VALUE_0", "~/.ssh/agent-signing.pub")
            .with_env("GIT_CONFIG_VALUE_1", "ssh-keygen")
            .with_env("GIT_CONFIG_VALUE_2", "ssh")
            .with_env("GIT_CONFIG_VALUE_3", GIT_ALLOWED_SIGNERS_CONFIG_PATH)
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
                "bash ~/.claude/hooks/docket-trust-guard-hook.sh",
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
            .with_hook_timeout(
                "SessionStart",
                Some("*"),
                "bash ~/.claude/hooks/herdr-agent-state.sh session",
                "command",
                10,
            )
            .with_hook(
                "PostToolUse",
                Some("Bash"),
                "bash ~/.claude/hooks/sandbox-friction-hook.sh",
                "command",
            )
            .with_hook(
                "PermissionDenied",
                Some("Bash"),
                "bash ~/.claude/hooks/sandbox-friction-hook.sh",
                "command",
            );

        let settings_builder = settings_builder.with_auto_mode(settings::AutoMode {
            allow: AUTO_MODE_ALLOW_RULES
                .iter()
                .map(|s| s.to_string())
                .collect(),
            environment: AUTO_MODE_ENVIRONMENT_CONTEXT
                .iter()
                .map(|s| s.to_string())
                .collect(),
            classify_all_shell: None,
            hard_deny: Vec::new(),
            soft_deny: Vec::new(),
        });

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
            .with_permission_allow("Bash(git add:*)")
            .with_permission_allow("Bash(git branch:*)")
            .with_permission_allow("Bash(git commit:*)")
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
            .with_permission_allow("Bash(~/.claude/scripts/*)")
            .with_permission_allow("Bash(~/.claude/workflows/*)")
            .with_permission_allow("WebFetch(domain:api.github.com)")
            .with_permission_allow("WebFetch(domain:claude.ai)")
            .with_permission_allow("WebFetch(domain:code.claude.com)")
            .with_permission_allow("WebFetch(domain:crates.io)")
            .with_permission_allow("WebFetch(domain:docs.claude.ai)")
            .with_permission_allow("WebFetch(domain:github.com)")
            .with_permission_allow("WebFetch(domain:mimir.bulbasaur.altf4.domains)")
            .with_permission_allow("WebFetch(domain:raw.githubusercontent.com)")
            .with_permission_allow("WebSearch")
            .with_permission_allow("Workflow");

        // DOT-952: Workflow scriptPath requires the directory to be readable as an
        // added directory; the Bash(~/.claude/workflows/*) allow above covers only
        // Bash invocations.
        let settings_builder = settings_builder
            .with_permission_additional_directories(vec!["~/.claude/workflows".to_string()]);

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
                "docker *".to_string(),
                "gh *".to_string(),
                "git *".to_string(),
                "vorpal *".to_string(),
            ])
            .with_sandbox_filesystem_allow_write(
                SANDBOX_TOOLCHAIN_CACHE_PATHS
                    .iter()
                    .chain(std::iter::once(&SANDBOX_AGENT_MEMORY_PATH))
                    .chain(std::iter::once(&SANDBOX_BARE_REPO_ROOT))
                    .chain(std::iter::once(&SANDBOX_CLAUDE_SCRATCH_ROOT))
                    .chain(std::iter::once(&SANDBOX_CLAUDE_SCRATCH_ROOT_PRIVATE))
                    .chain(std::iter::once(&SANDBOX_DARWIN_TEMP_ROOT))
                    .chain(std::iter::once(&SANDBOX_DOCS_CACHE_PATH))
                    .chain(std::iter::once(&SANDBOX_DOCKET_STORE_PATH))
                    .chain(std::iter::once(&SANDBOX_DOCKET_TRUST_LOCK_PATH))
                    .chain(std::iter::once(&SANDBOX_FRICTION_LEDGER_PATH))
                    .map(|p| p.to_string())
                    .collect(),
            )
            .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
            .with_sandbox_network_allowed_domains(vec![
                "api.github.com".to_string(),
                "crates.io".to_string(),
                "github.com".to_string(),
                "proxy.golang.org".to_string(),
                "static.crates.io".to_string(),
                "vuln.go.dev".to_string(),
            ])
            .with_sandbox_network_allow_unix_sockets(vec![
                "~/.orbstack/run/docker.sock".to_string(),
                "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock".to_string(),
            ])
            .with_sandbox_network_allow_mach_lookup(vec!["com.apple.trustd.agent".to_string()])
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

        let workflows = FileSource::new(
            &component_name(&self.name, "workflows"),
            "src/user/claude_code/workflows",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let memory = FileCreate::new(
            &component_name(&self.name, "memory"),
            self.systems.clone(),
            include_str!("claude_code_memory.md"),
        )
        .build(context)
        .await?;

        let allowed_signers = FileCreate::new(
            &component_name(&self.name, "allowed-signers"),
            self.systems.clone(),
            include_str!("claude_code_allowed_signers"),
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
            (
                FileCreate::output_file_path(
                    &get_env_key(&allowed_signers),
                    &component_name(&self.name, "allowed-signers"),
                ),
                GIT_ALLOWED_SIGNERS_INSTALL_PATH.to_string(),
            ),
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
            agents,
            allowed_signers,
            hooks,
            memory,
            scripts,
            settings,
            skills,
            statusline,
            workflows,
        ];

        Ok((artifacts, symlinks))
    }
}

#[cfg(test)]
mod tests {
    use super::{
        claude_home, component_name, sandbox_filesystem_deny_read_paths,
        sorted_permission_patterns, GIT_ALLOWED_SIGNERS_CONFIG_PATH,
        GIT_ALLOWED_SIGNERS_INSTALL_PATH, SENSITIVE_PATHS, SENSITIVE_PATHS_DENY_EDIT_ONLY,
        SENSITIVE_PATHS_DENY_READ_ONLY,
    };
    use crate::file::FileCreate;

    #[test]
    fn allowed_signers_install_and_config_paths_name_the_same_file() {
        // Activation expands `${HOME}`; git expands only a leading `~/`. The
        // spellings must differ and still resolve to one file, or the symlink
        // lands somewhere git never looks and %G? goes back to N.
        assert_eq!(
            GIT_ALLOWED_SIGNERS_INSTALL_PATH.replace("${HOME}", "~"),
            GIT_ALLOWED_SIGNERS_CONFIG_PATH
        );
        assert!(GIT_ALLOWED_SIGNERS_CONFIG_PATH.starts_with("~/"));
    }

    #[test]
    fn allowed_signers_roster_carries_the_agent_signing_key() {
        let roster = include_str!("claude_code_allowed_signers");

        // The key ~/.ssh/agent-signing.pub holds, scoped to git's namespace.
        // Drop this line and every agent-signed commit verifies as U instead
        // of G, silently.
        assert!(roster.contains(
            "namespaces=\"git\" ssh-ed25519 \
             AAAAC3NzaC1lZDI1NTE5AAAAIDAUWPpoXS64HKvi6LIuEdhWkmAaMBB7XNB8QGmfYejg"
        ));
    }

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
