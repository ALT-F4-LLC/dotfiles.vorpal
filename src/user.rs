use crate::{
    file::{FileCreate, FileDownload, FileSource},
    get_output_path,
};
use anyhow::Result;
use bat::BatConfig;
use claude_code::Config as ClaudeCodeConfig;
use codex::{AgentRole, Codex, Otel, SkillConfig, TuiNotifications};
use ghostty::GhosttyConfig;
use k9s::K9sSkin;
pub use opencode::ModelLimit;
use opencode::{
    AgentConfig, AgentMode, AutoUpdate, Config as OpenCodeConfig, LspServerConfig, ModelConfig,
    PermissionAction, PermissionRule, ProviderConfig, ProviderOptions,
};
use opencode_tui::Config as OpenCodeTuiConfig;
use std::collections::BTreeMap;
use vorpal_artifacts::artifact::{
    abtop::Abtop, awscli2::Awscli2, bash_language_server::BashLanguageServer, bat::Bat, cue::Cue,
    delta::Delta, direnv::Direnv, doppler::Doppler, fd::Fd, fzf::Fzf, gum::Gum, herdr::Herdr,
    hunk::Hunk, jj::Jj, jq::Jq, just::Just, k9s::K9s, kubectl::Kubectl, lazygit::Lazygit,
    lua_language_server::LuaLanguageServer, neovim::Neovim, nnn::Nnn, op::Op, opencode::Opencode,
    pi::Pi, ripgrep::Ripgrep, sesh::Sesh, starship::Starship, terraform::Terraform, tmux::Tmux,
    tree_sitter::TreeSitter, typescript::Typescript,
    typescript_language_server::TypescriptLanguageServer,
    vscode_langservers_extracted::VscodeLangserversExtracted,
    yaml_language_server::YamlLanguageServer, zoxide::Zoxide,
};
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact,
    artifact::{gh::Gh, git::Git, gopls::Gopls, nodejs::NodeJS},
    context::ConfigContext,
};

mod bat;
mod claude_code;
mod codex;
mod ghostty;
mod k9s;
mod opencode;
mod opencode_tui;

//    OPENCODE - MODEL RANKINGS    //
// Benchmarks @ https://benchlm.ai //

// Gemini 3.1 Pro (89 benchmark): (https://benchlm.ai/models/gemini-3-pro) - Low, Medium, High
// Provider: Google Vertex (metered, per-token API).
// Price: ~$2 input / $12 output per 1M tokens (BenchLM fallback 2026-07-07; official
// https://cloud.google.com/vertex-ai/pricing was obscured by dynamic rendering).
const OPENCODE_MODEL_GOLD: &str = "google-vertex/gemini-3.1-pro-preview"; // Closest to Fable 5
                                                                          // in relative comparison

// GLM 5.2 (83 benchmark): (https://benchlm.ai/models/glm-5-2) - High, Max
// Provider: Z.AI via `zai-coding-plan` key (operator subscription-flat billing form).
// Price: per-token fallback ~$1.40 input / $4.40 output per 1M tokens (BenchLM fallback
// 2026-07-07; official https://z.ai/pricing returned HTTP 404).
const OPENCODE_MODEL_SILVER: &str = "zai-coding-plan/glm-5.2"; // Closest to Opus 4.8
                                                               // in relative comparison

// GPT 5.5 (80 benchmark): (https://benchlm.ai/models/gpt-5-5) - None, Low, Medium, High, XHigh
// Provider: OpenAI (metered, per-token API).
// Price: ~$5 input / $30 output per 1M tokens (BenchLM fallback 2026-07-07; official
// https://openai.com/api/pricing/ blocked by HTTP 403).
const OPENCODE_MODEL_BRONZE: &str = "openai/gpt-5.5"; // Closest to Sonnet 5
                                                      // in relative comparison

// const OPENCODE_MODEL_VARIANT_LOW: &str = "low";
// const OPENCODE_MODEL_VARIANT_MEDIUM: &str = "medium";
const OPENCODE_MODEL_VARIANT_HIGH: &str = "high";
const OPENCODE_MODEL_VARIANT_XHIGH: &str = "xhigh";
const OPENCODE_MODEL_VARIANT_MAX: &str = "max";

const OTEL_LOGS_ENDPOINT_LOKI: &str = "https://loki.bulbasaur.altf4.domains/otlp/v1/logs";
const OTEL_METRICS_ENDPOINT_ALLOY: &str = "https://alloy-otlp.bulbasaur.altf4.domains/v1/metrics";
const OTEL_METRICS_ENDPOINT_MIMIR: &str = "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";

pub struct UserEnvironment {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl UserEnvironment {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        UserEnvironment {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        // Dependencies

        let abtop = Abtop::new().build(context).await?;
        let awscli2 = Awscli2::new().build(context).await?;
        let bash_language_server = BashLanguageServer::new().build(context).await?;
        let bat = Bat::new().build(context).await?;
        let cue = Cue::new().build(context).await?;
        let delta = Delta::new().build(context).await?;
        let direnv = Direnv::new().build(context).await?;
        let doppler = Doppler::new().build(context).await?;
        let fd = Fd::new().build(context).await?;
        let fzf = Fzf::new().build(context).await?;
        let gh = Gh::new().build(context).await?;
        let git = Git::new().build(context).await?;
        let gopls = Gopls::new().build(context).await?;
        let gum = Gum::new().build(context).await?;
        let herdr = Herdr::new().build(context).await?;
        let hunk = Hunk::new().build(context).await?;
        let jj = Jj::new().build(context).await?;
        let jq = Jq::new().build(context).await?;
        let just = Just::new().build(context).await?;
        let k9s = K9s::new().build(context).await?;
        let kubectl = Kubectl::new().build(context).await?;
        let lazygit = Lazygit::new().build(context).await?;
        let lua_language_server = LuaLanguageServer::new().build(context).await?;
        let neovim = Neovim::new().build(context).await?;
        let nnn = Nnn::new().build(context).await?;
        let nodejs = NodeJS::new().build(context).await?;
        let op = Op::new().build(context).await?;
        let pi = Pi::new().build(context).await?;
        let opencode = Opencode::new().build(context).await?;
        let ripgrep = Ripgrep::new().build(context).await?;
        let sesh = Sesh::new().build(context).await?;
        let starship = Starship::new().build(context).await?;
        let terraform = Terraform::new().build(context).await?;
        let tmux = Tmux::new().build(context).await?;
        let tree_sitter = TreeSitter::new().build(context).await?;
        let typescript = Typescript::new().build(context).await?;
        let typescript_language_server = TypescriptLanguageServer::new().build(context).await?;
        let vscode_langservers_extracted = VscodeLangserversExtracted::new().build(context).await?;
        let yaml_language_server = YamlLanguageServer::new().build(context).await?;
        let zoxide = Zoxide::new().build(context).await?;

        // Configuration files

        let bat_theme_name = format!("{}-bat-theme", &self.name);
        let bat_theme = FileDownload::new(
            bat_theme_name.as_str(),
            "https://raw.githubusercontent.com/folke/tokyonight.nvim/refs/tags/v4.14.1/extras/sublime/tokyonight_night.tmTheme",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let bat_theme_path = format!(
            "{}/tokyonight_night.tmTheme",
            get_output_path("library", &bat_theme)
        );

        let bat_config_name = format!("{}-bat-config", &self.name);
        let bat_config = BatConfig::new(bat_config_name.as_str(), self.systems.clone())
            .with_theme("tokyonight")
            .build(context)
            .await?;
        let bat_config_path = format!(
            "{}/{bat_config_name}",
            get_output_path("library", &bat_config)
        );

        let claude_code_config_name = format!("{}-claude-code", &self.name);
        let claude_code_config =
            ClaudeCodeConfig::new(claude_code_config_name.as_str(), self.systems.clone())
                .with_agent("team-lead")
                .with_always_thinking_enabled(true)
                .with_attribution_commit("")
                .with_attribution_pr("")
                .with_auto_updates_channel("latest")
                .with_away_summary_enabled(false)
                .with_cleanup_period_days(14)
                .with_effort_level("xhigh")
                .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
                .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
                .with_enabled_plugin("typescript-lsp@claude-plugins-official", true)
                .with_env("CLAUDE_CODE_ENABLE_AUTO_MODE", "1")
                .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
                .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
                .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0")
                .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5")
                .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
                .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-4-8[1m]")
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
                    "TeammateIdle",
                    None,
                    "bash ~/.claude/teammate-idle-hook.sh",
                    "command",
                )
                .with_include_git_instructions(false)
                .with_model("claude-sonnet-5")
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
                .with_permission_allow("Bash(git add:*)")
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
                .with_permission_ask("Bash(git commit:*)")
                .with_permission_ask("Bash(git push:*)")
                .with_permission_ask("Bash(rm:*)")
                .with_permission_deny("Bash(git checkout:*)")
                .with_permission_deny("Bash(git reset:*)")
                .with_permission_deny("Edit(/Applications/**)")
                .with_permission_deny("Edit(/Library/**)")
                .with_permission_deny("Edit(/System/**)")
                .with_permission_deny("Edit(~/.claude.json)")
                .with_permission_deny("Edit(~/.codex/**)")
                .with_permission_deny("Edit(~/.doppler/**)")
                .with_permission_deny("Edit(~/.gemini/**)")
                .with_permission_deny("Edit(~/.gnupg/**)")
                .with_permission_deny("Edit(~/.kube/**)")
                .with_permission_deny("Edit(~/.netrc)")
                .with_permission_deny("Edit(~/.opencode/**)")
                .with_permission_deny("Edit(~/.ssh/**)")
                .with_permission_deny("Edit(~/.talos/**)")
                .with_permission_deny("Edit(~/Desktop/**)")
                .with_permission_deny("Edit(~/Downloads/**)")
                .with_permission_deny("Read(.env)")
                .with_permission_deny("Read(.env.*)")
                .with_permission_deny("Read(/Applications/**)")
                .with_permission_deny("Read(/Library/**)")
                .with_permission_deny("Read(/System/**)")
                .with_permission_deny("Read(~/.aws/**)")
                .with_permission_deny("Read(~/.claude.json)")
                .with_permission_deny("Read(~/.codex/**)")
                .with_permission_deny("Read(~/.doppler/**)")
                .with_permission_deny("Read(~/.gemini/**)")
                .with_permission_deny("Read(~/.gnupg/**)")
                .with_permission_deny("Read(~/.kube/**)")
                .with_permission_deny("Read(~/.netrc)")
                .with_permission_deny("Read(~/.opencode/**)")
                .with_permission_deny("Read(~/.ssh/**)")
                .with_permission_deny("Read(~/.talos/**)")
                .with_permission_deny("Read(~/Desktop/**)")
                .with_permission_deny("Read(~/Downloads/**)")
                .with_permission_deny("Write(/Applications/**)")
                .with_permission_deny("Write(/Library/**)")
                .with_permission_deny("Write(/System/**)")
                .with_permission_deny("Write(~/.claude.json)")
                .with_permission_deny("Write(~/.codex/**)")
                .with_permission_deny("Write(~/.doppler/**)")
                .with_permission_deny("Write(~/.gemini/**)")
                .with_permission_deny("Write(~/.gnupg/**)")
                .with_permission_deny("Write(~/.kube/**)")
                .with_permission_deny("Write(~/.netrc)")
                .with_permission_deny("Write(~/.opencode/**)")
                .with_permission_deny("Write(~/.ssh/**)")
                .with_permission_deny("Write(~/.talos/**)")
                .with_permission_deny("Write(~/Desktop/**)")
                .with_permission_deny("Write(~/Downloads/**)")
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
                ])
                .with_sandbox_filesystem_deny_read(vec![
                    "~/.ssh".to_string(),
                    "~/.gnupg".to_string(),
                    "~/.aws".to_string(),
                    "~/.netrc".to_string(),
                    "~/.talos".to_string(),
                    "~/.claude.json".to_string(),
                    "~/.codex".to_string(),
                    "~/.gemini".to_string(),
                    "~/.opencode".to_string(),
                    ".env".to_string(),
                    ".env.*".to_string(),
                ])
                .with_sandbox_network_allowed_domains(vec![
                    "crates.io".to_string(),
                    "static.crates.io".to_string(),
                    "github.com".to_string(),
                    "api.github.com".to_string(),
                ])
                .with_sandbox_network_allow_local_binding(false)
                .with_teammate_mode("in-process")
                .with_tui("fullscreen")
                .build(context)
                .await?;
        let claude_code_config_path = format!(
            "{}/{claude_code_config_name}",
            get_output_path("library", &claude_code_config)
        );

        let codex_team_lead_profile_name = format!("{}-codex-team-lead-profile", &self.name);
        let codex_team_lead_profile =
            Codex::new(codex_team_lead_profile_name.as_str(), self.systems.clone())
                .with_developer_instructions(include_str!("user/codex/personas/team-lead.md"))
                .with_model_reasoning_effort("xhigh")
                .with_plan_mode_reasoning_effort("xhigh")
                .build(context)
                .await?;
        let codex_team_lead_profile_path = format!(
            "{}/{}",
            get_output_path("library", &codex_team_lead_profile),
            codex_team_lead_profile_name
        );

        let codex_config_name = format!("{}-codex", &self.name);
        let codex_config = Codex::new(codex_config_name.as_str(), self.systems.clone())
            .with_agent_limits(Some(12), Some(2), Some(3600))
            .with_agent_role(
                "project-manager",
                codex_agent_role(
                    "Plans Docket issue decomposition, phase order, dependencies, and acceptance criteria.",
                    "./agents/project-manager.toml",
                    &["pm", "planner", "tpm"],
                ),
            )
            .with_agent_role(
                "staff-engineer",
                codex_agent_role(
                    "Authors technical designs and ADRs, evaluates architecture, and performs general code review.",
                    "./agents/staff-engineer.toml",
                    &["architect", "staff", "advisor"],
                ),
            )
            .with_agent_role(
                "security-engineer",
                codex_agent_role(
                    "Owns threat modeling, security design, and security-focused review.",
                    "./agents/security-engineer.toml",
                    &["security", "sec", "security-advisor"],
                ),
            )
            .with_agent_role(
                "senior-engineer",
                codex_agent_role(
                    "Implements scoped code changes, follows local patterns, and reports verification evidence.",
                    "./agents/senior-engineer.toml",
                    &["implementer", "senior", "impl"],
                ),
            )
            .with_agent_role(
                "sdet",
                codex_agent_role(
                    "Verifies acceptance criteria, writes tests, and reports quality evidence.",
                    "./agents/sdet.toml",
                    &["tester", "qa", "verifier"],
                ),
            )
            .with_agent_role(
                "ux-designer",
                codex_agent_role(
                    "Designs and reviews user-facing workflows, UX specs, and design QA.",
                    "./agents/ux-designer.toml",
                    &["ux", "designer", "ux-advisor"],
                ),
            )
            .with_skill_config(SkillConfig {
                path: Some("$HOME/.codex/skills".to_string()),
                enabled: Some(true),
            })
            .with_allow_login_shell(true)
            .with_analytics_enabled(true)
            .with_approval_policy("on-request")
            .with_approvals_reviewer("auto_review")
            .with_check_for_update_on_startup(true)
            .with_cli_auth_credentials_store("keyring")
            .with_default_permissions(":workspace")
            .with_disable_paste_burst(false)
            .with_feature_enabled("apps", false)
            .with_feature_enabled("codex_git_commit", false)
            .with_feature_enabled("fast_mode", true)
            .with_feature_enabled("hooks", true)
            .with_feature_enabled("memories", true)
            .with_feature_enabled("multi_agent", true)
            .with_feature_enabled("personality", true)
            .with_feature_enabled("shell_snapshot", true)
            .with_feature_enabled("shell_tool", true)
            .with_feature_enabled("undo", false)
            .with_feature_enabled("unified_exec", true)
            .with_feedback_enabled(false)
            .with_file_opener("none")
            .with_hide_agent_reasoning(false)
            .with_history_persistence("save-all")
            .with_mcp_oauth_credentials_store("auto")
            .with_model("gpt-5.5")
            .with_model_context_window(1_000_000)
            .with_model_provider("openai")
            .with_model_reasoning_effort("xhigh")
            .with_model_reasoning_summary("auto")
            .with_model_verbosity("medium")
            .with_otel(Otel {
                log_user_prompt: Some(false),
                environment: Some("dev".to_string()),
                exporter: codex_otlp_exporter(OTEL_LOGS_ENDPOINT_LOKI),
                metrics_exporter: codex_otlp_exporter(OTEL_METRICS_ENDPOINT_ALLOY),
                trace_exporter: codex_otlp_exporter(OTEL_METRICS_ENDPOINT_ALLOY),
            })
            .with_personality("pragmatic")
            .with_plan_mode_reasoning_effort("xhigh")
            .with_project_doc_max_bytes(32768)
            .with_sandbox_mode("workspace-write")
            .with_sandbox_workspace_writable_roots(vec!["$HOME/.cache/uv".to_string()])
            .with_sandbox_workspace_network_access(false)
            .with_shell_environment_exclude(vec![
                "AWS_*".to_string(),
                "AZURE_*".to_string(),
                "GCP_*".to_string(),
            ])
            .with_shell_environment_inherit("all")
            .with_show_raw_agent_reasoning(false)
            .with_tool_enabled("view_image", true)
            .with_tui_notifications(TuiNotifications::Enabled(false))
            .with_tui_status_line(vec![
                "model-with-reasoning".to_string(),
                "context-remaining".to_string(),
                "current-dir".to_string(),
                "git-branch".to_string(),
            ])
            .with_tui_terminal_title(vec!["spinner".to_string(), "project".to_string()])
            .with_tui_theme("tokyonight")
            .with_web_search("cached")
            .build(context)
            .await?;
        let codex_config_path = format!(
            "{}/{codex_config_name}",
            get_output_path("library", &codex_config)
        );

        let opencode_config_name = format!("{}-opencode", &self.name);
        let opencode_config =
            OpenCodeConfig::new(opencode_config_name.as_str(), self.systems.clone())
                .with_schema("https://opencode.ai/config.json")
                .with_autoupdate(AutoUpdate::Boolean(false))
                .with_default_agent("team-lead")
                .with_model(OPENCODE_MODEL_BRONZE)
                .with_skill_path("$HOME/.config/opencode/skills")
                .with_bash_permissions(vec![
                    // Default: ask for anything not explicitly allowed or denied
                    ("*", PermissionAction::Ask),
                    // Allow — CC full bash allowlist parity (src/user.rs:170-231)
                    ("bun run*", PermissionAction::Allow),
                    ("bun test*", PermissionAction::Allow),
                    ("cargo build*", PermissionAction::Allow),
                    ("cargo check*", PermissionAction::Allow),
                    ("cargo clippy*", PermissionAction::Allow),
                    ("cargo fmt*", PermissionAction::Allow),
                    ("cargo outdated*", PermissionAction::Allow),
                    ("cargo run*", PermissionAction::Allow),
                    ("cargo search*", PermissionAction::Allow),
                    ("cargo test*", PermissionAction::Allow),
                    ("cargo tree*", PermissionAction::Allow),
                    ("cargo update*", PermissionAction::Allow),
                    ("cat*", PermissionAction::Allow),
                    ("chmod*", PermissionAction::Allow),
                    ("cue*", PermissionAction::Allow),
                    ("docker images*", PermissionAction::Allow),
                    ("docker logs*", PermissionAction::Allow),
                    ("docker ps*", PermissionAction::Allow),
                    ("docket*", PermissionAction::Allow),
                    ("echo*", PermissionAction::Allow),
                    ("file*", PermissionAction::Allow),
                    ("find*", PermissionAction::Allow),
                    ("gh pr diff*", PermissionAction::Allow),
                    ("gh pr list*", PermissionAction::Allow),
                    ("gh pr view*", PermissionAction::Allow),
                    ("git add*", PermissionAction::Allow),
                    ("git branch*", PermissionAction::Allow),
                    ("git diff*", PermissionAction::Allow),
                    ("git log*", PermissionAction::Allow),
                    ("git remote get-url*", PermissionAction::Allow),
                    ("git show*", PermissionAction::Allow),
                    ("git status*", PermissionAction::Allow),
                    ("go build*", PermissionAction::Allow),
                    ("go doc*", PermissionAction::Allow),
                    ("go list*", PermissionAction::Allow),
                    ("go mod tidy*", PermissionAction::Allow),
                    ("go test*", PermissionAction::Allow),
                    ("go version*", PermissionAction::Allow),
                    ("go vet*", PermissionAction::Allow),
                    ("gofmt*", PermissionAction::Allow),
                    ("grep*", PermissionAction::Allow),
                    ("head*", PermissionAction::Allow),
                    ("jq*", PermissionAction::Allow),
                    ("ls*", PermissionAction::Allow),
                    ("make*", PermissionAction::Allow),
                    ("npm run build*", PermissionAction::Allow),
                    ("npm run lint*", PermissionAction::Allow),
                    ("npm run test*", PermissionAction::Allow),
                    ("npx tsc*", PermissionAction::Allow),
                    ("rg*", PermissionAction::Allow),
                    ("sort*", PermissionAction::Allow),
                    ("staticcheck*", PermissionAction::Allow),
                    ("tail*", PermissionAction::Allow),
                    ("tar*", PermissionAction::Allow),
                    ("test*", PermissionAction::Allow),
                    ("tree*", PermissionAction::Allow),
                    ("vorpal build*", PermissionAction::Allow),
                    ("vorpal inspect*", PermissionAction::Allow),
                    ("vorpal run*", PermissionAction::Allow),
                    ("wc*", PermissionAction::Allow),
                    ("xargs*", PermissionAction::Allow),
                    ("yarn build*", PermissionAction::Allow),
                    ("yarn lint*", PermissionAction::Allow),
                    ("yarn test*", PermissionAction::Allow),
                    // Deny — CC bash deny rules (src/user.rs:245-246)
                    ("git checkout*", PermissionAction::Deny),
                    ("git reset*", PermissionAction::Deny),
                ])
                .with_permission_edit(PermissionRule::Object({
                    let mut m = BTreeMap::new();
                    m.insert("*".to_string(), PermissionAction::Ask);
                    // CC Edit deny rules approximated (src/user.rs:247-263)
                    m.insert("/Applications/**".to_string(), PermissionAction::Deny);
                    m.insert("/Library/**".to_string(), PermissionAction::Deny);
                    m.insert("/System/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.claude.json".to_string(), PermissionAction::Deny);
                    m.insert("~/.codex/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.doppler/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.gemini/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.gnupg/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.kube/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.netrc".to_string(), PermissionAction::Deny);
                    m.insert("~/.ssh/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.talos/**".to_string(), PermissionAction::Deny);
                    m.insert("~/Desktop/**".to_string(), PermissionAction::Deny);
                    m.insert("~/Downloads/**".to_string(), PermissionAction::Deny);
                    m
                }))
                .with_permission_glob(PermissionRule::Simple(PermissionAction::Allow))
                .with_permission_list(PermissionRule::Simple(PermissionAction::Allow))
                .with_permission_lsp(PermissionRule::Simple(PermissionAction::Allow))
                .with_permission_read(PermissionRule::Object({
                    let mut m = BTreeMap::new();
                    m.insert("*".to_string(), PermissionAction::Allow);
                    // CC Read deny rules approximated (src/user.rs:264-283)
                    m.insert(".env".to_string(), PermissionAction::Deny);
                    m.insert(".env.*".to_string(), PermissionAction::Deny);
                    m.insert("/Applications/**".to_string(), PermissionAction::Deny);
                    m.insert("/Library/**".to_string(), PermissionAction::Deny);
                    m.insert("/System/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.aws/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.claude.json".to_string(), PermissionAction::Deny);
                    m.insert("~/.codex/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.doppler/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.gemini/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.gnupg/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.kube/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.netrc".to_string(), PermissionAction::Deny);
                    m.insert("~/.ssh/**".to_string(), PermissionAction::Deny);
                    m.insert("~/.talos/**".to_string(), PermissionAction::Deny);
                    m.insert("~/Desktop/**".to_string(), PermissionAction::Deny);
                    m.insert("~/Downloads/**".to_string(), PermissionAction::Deny);
                    m
                }))
                .with_permission_webfetch(PermissionAction::Ask)
                .with_permission_websearch(PermissionAction::Allow)
                .with_lsp(
                    "gopls",
                    LspServerConfig {
                        command: vec!["gopls".to_string()],
                        extensions: vec![".go".to_string()],
                        ..Default::default()
                    },
                )
                .with_lsp(
                    "rust-analyzer",
                    LspServerConfig {
                        command: vec!["rust-analyzer".to_string()],
                        extensions: vec![".rs".to_string()],
                        ..Default::default()
                    },
                )
                .with_lsp(
                    "typescript-language-server",
                    LspServerConfig {
                        command: vec!["typescript-language-server".to_string()],
                        extensions: vec![".ts".to_string(), ".tsx".to_string()],
                        ..Default::default()
                    },
                )
                .with_experimental_open_telemetry(true)
                .with_agent(
                    "build",
                    AgentConfig {
                        model: Some(OPENCODE_MODEL_SILVER.to_string()), // follows `team-lead`
                        variant: Some(OPENCODE_MODEL_VARIANT_MAX.to_string()),
                        ..Default::default()
                    },
                )
                .with_agent(
                    "plan",
                    AgentConfig {
                        model: Some(OPENCODE_MODEL_SILVER.to_string()), // follows `team-lead`
                        variant: Some(OPENCODE_MODEL_VARIANT_MAX.to_string()),
                        ..Default::default()
                    },
                )
                .with_agent(
                    "team-lead",
                    AgentConfig {
                        model: Some(OPENCODE_MODEL_SILVER.to_string()), // better at directions
                        variant: Some(OPENCODE_MODEL_VARIANT_MAX.to_string()), // meant to think
                        mode: Some(AgentMode::Primary),
                        color: None,
                        description: Some(
                            "The operator's single entry point — a task-to-subagent prompt-engineering and routing layer that turns each request into recipient-optimized briefs/relays and model/effort/mechanism dispatch decisions across the specialist agents (@staff-engineer, @security-engineer, @project-manager, @ux-designer, @senior-engineer, @sdet). MUST BE USED PROACTIVELY for any multi-step software task that benefits from upfront design, planning, implementation, review, and verification. Coordinates only: never writes code, never creates issues, never commits; read-only on the working tree.".to_string(),
                        ),
                        prompt: Some(
                            include_str!("user/opencode/agents/team-lead.md").to_string(),
                        ),
                        ..Default::default()
                    },
                )
                .with_agent(
                    "distinguished-engineer",
                    opencode_agent(
                        "A beyond-staff-level engineer: TDD authoring, persistent advisory on TDD-bearing cycles, open-ended investigation/innovation scanning, and >1-day-horizon deep implementation. Mode is fixed by the spawn brief; writes code ONLY in deep-impl mode. Never takes security-sensitive work (that pins security-engineer deterministically).",
                        include_str!("user/opencode/agents/distinguished-engineer.md"),
                        OPENCODE_MODEL_GOLD, // highest benchmarks
                        Some(OPENCODE_MODEL_VARIANT_HIGH), // meant to think
                    ),
                )
                .with_agent(
                    "staff-engineer",
                    opencode_agent(
                        "Staff-level technical architect and code reviewer. Produces TDDs in `docs/tdd/` and ADRs in `docs/tdd/adr/`. Reviews all @senior-engineer changes. MUST BE USED PROACTIVELY for architectural decisions, system design, technical planning, design review, dependency evaluation, and code reviews. Never writes implementation code.",
                        include_str!("user/opencode/agents/staff-engineer.md"),
                        OPENCODE_MODEL_SILVER, // second highest benchmarks
                        Some(OPENCODE_MODEL_VARIANT_MAX), // meant to think
                    ),
                )
                .with_agent(
                    "senior-engineer",
                    opencode_agent(
                        "Senior Software Engineer focused on implementation quality. Executes pre-planned Docket issues and ad-hoc work — writing code, editing source files, and producing working software. Handles both routine and deep implementation work. Checks `docs/tdd/`, `docs/ux/`, and `docs/spec/` for context before implementing. All changes reviewed by @staff-engineer and verified by @sdet. Does not produce design documents or perform code reviews.",
                        include_str!("user/opencode/agents/senior-engineer.md"),
                        OPENCODE_MODEL_BRONZE, // better at directions
                        Some(OPENCODE_MODEL_VARIANT_XHIGH), // meant to think
                    ),
                )
                .with_agent(
                    "security-engineer",
                    opencode_agent(
                        "Staff-level Security Engineer — owns security architecture, threat modeling, and risk management. Authors security TDDs in `docs/tdd/` and security ADRs in `docs/tdd/adr/`. Performs security-focused review of code, designs, dependencies, and configurations alongside @staff-engineer's general review. MUST BE USED PROACTIVELY for trust-boundary changes, authn/authz design, secret handling, cryptography, supply-chain decisions, sandbox/permission models, and any change touching security-sensitive surfaces. Aligns security posture with business goals and risk tolerance. Never writes implementation code.",
                        include_str!("user/opencode/agents/security-engineer.md"),
                        OPENCODE_MODEL_SILVER, // second highest benchmarks
                        Some(OPENCODE_MODEL_VARIANT_MAX), // meant to put in full effort
                    ),
                )
                .with_agent(
                    "project-manager",
                    opencode_agent(
                        "Technical project manager that breaks down problems and tasks into well-structured Docket issues. MUST BE USED PROACTIVELY when the user describes a problem, feature request, project, migration, or any body of work that needs to be planned and decomposed before execution begins. This agent ONLY plans — it creates issues, subtasks, dependencies, and priorities in Docket. It NEVER writes code or edits source files. It uses Read, Grep, and Glob to explore the codebase and surfaces deeper technical investigation needs to the user or team lead. Aware of @staff-engineer (TDDs in `docs/tdd/`), @ux-designer (design specs in `docs/ux/`), @senior-engineer (implementation), and @sdet (testing). The primary agent that creates Docket issues — @senior-engineer may create single ad-hoc tracking issues for unplanned work.",
                        include_str!("user/opencode/agents/project-manager.md"),
                        OPENCODE_MODEL_BRONZE, // better at directions
                        Some(OPENCODE_MODEL_VARIANT_XHIGH), // meant to think
                    ),
                )
                .with_agent(
                    "ux-designer",
                    opencode_agent(
                        "UX designer and developer experience specialist. Produces design specs in `docs/ux/` — does NOT write implementation code. Use PROACTIVELY for designing interfaces (web, mobile, CLI, TUI), evaluating usability, defining interaction patterns, reviewing existing UX, or designing APIs, SDKs, config formats, and developer-facing surfaces. Hands off to @project-manager for task decomposition and @senior-engineer for implementation.",
                        include_str!("user/opencode/agents/ux-designer.md"),
                        OPENCODE_MODEL_SILVER, // second highest intellegence
                        Some(OPENCODE_MODEL_VARIANT_MAX), // meant to think
                    ),
                )
                .with_agent(
                    "sdet",
                    opencode_agent(
                        "Software Development Engineer in Test — owns test infrastructure, automation, and quality engineering. Writes test code and tooling, verifies Docket issues against acceptance criteria, performs defect triage and quality analysis. Checks `docs/tdd/`, `docs/ux/`, and `docs/spec/` for context. Does not write production code, design documents, or perform production code reviews.",
                        include_str!("user/opencode/agents/sdet.md"),
                        OPENCODE_MODEL_BRONZE, // better at directions
                        Some(OPENCODE_MODEL_VARIANT_XHIGH), // meant to think
                    ),
                )
                // Provider: Ollama local (self-hosted, OpenAI-compatible). No per-token provider
                // price; infrastructure compute cost only. Models: devstral-small-2, qwen3.6,
                // qwen3-coder-next, ornith.
                .with_provider(
                    "ollama-local",
                    ProviderConfig {
                        npm: Some("@ai-sdk/openai-compatible".to_string()),
                        name: Some("Ollama - Local".to_string()),
                        options: Some(ProviderOptions {
                            base_url: Some("http://localhost:11434/v1".to_string()),
                            ..Default::default()
                        }),
                        models: [
                            (
                                "devstral-small-2:24b-instruct-2512-q8_0".to_string(),
                                ModelConfig {
                                    name: Some("devstral-small-2".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3.6:27b-q8_0".to_string(),
                                ModelConfig {
                                    name: Some("qwen3.6:27b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3.6:35b-a3b-q8_0".to_string(),
                                ModelConfig {
                                    name: Some("qwen3.6:35b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3-coder-next:q4_K_M".to_string(),
                                ModelConfig {
                                    name: Some("qwen3-coder-next".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "ornith:35b".to_string(),
                                ModelConfig {
                                    name: Some("ornith:35b".to_string()),
                                    ..Default::default()
                                },
                            ),
                        ]
                        .into_iter()
                        .collect(),
                        ..Default::default()
                    },
                )
                // Provider: Ollama remote (self-hosted, OpenAI-compatible). No per-token provider
                // price; infrastructure compute cost only. Models: qwen3-embedding, glm-ocr,
                // phi4-mini-reasoning, deepseek-r1, lfm2.5, granite4.1, ministral-3, qwen3-vl,
                // ornith, qwen3.5, gemma4.
                .with_provider(
                    "ollama-remote",
                    ProviderConfig {
                        npm: Some("@ai-sdk/openai-compatible".to_string()),
                        name: Some("Ollama - Remote".to_string()),
                        options: Some(ProviderOptions {
                            base_url: Some("http://192.168.0.180:11434/v1".to_string()),
                            ..Default::default()
                        }),
                        models: [
                            (
                                "qwen3-embedding:8b".to_string(),
                                ModelConfig {
                                    name: Some("qwen3-embedding:8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "glm-ocr:latest".to_string(),
                                ModelConfig {
                                    name: Some("glm-ocr:latest".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "phi4-mini-reasoning:3.8b".to_string(),
                                ModelConfig {
                                    name: Some("phi4-mini-reasoning:3.8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "deepseek-r1:14b".to_string(),
                                ModelConfig {
                                    name: Some("deepseek-r1:14b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "lfm2.5:8b".to_string(),
                                ModelConfig {
                                    name: Some("lfm2.5:8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "granite4.1:8b".to_string(),
                                ModelConfig {
                                    name: Some("granite4.1:8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "ministral-3:8b".to_string(),
                                ModelConfig {
                                    name: Some("ministral-3:8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3-vl:8b".to_string(),
                                ModelConfig {
                                    name: Some("qwen3-vl:8b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "ornith:9b".to_string(),
                                ModelConfig {
                                    name: Some("ornith:9b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3.5:9b".to_string(),
                                ModelConfig {
                                    name: Some("qwen3.5:9b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "gemma4:12b".to_string(),
                                ModelConfig {
                                    name: Some("gemma4:12b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "gemma4:e4b".to_string(),
                                ModelConfig {
                                    name: Some("gemma4:e4b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "qwen3.5:4b".to_string(),
                                ModelConfig {
                                    name: Some("qwen3.5:4b".to_string()),
                                    ..Default::default()
                                },
                            ),
                            (
                                "gemma4:latest".to_string(),
                                ModelConfig {
                                    name: Some("gemma4:latest".to_string()),
                                    ..Default::default()
                                },
                            ),
                        ]
                        .into_iter()
                        .collect(),
                        ..Default::default()
                    },
                )
                .build(context)
                .await?;
        let opencode_config_path = format!(
            "{}/{opencode_config_name}",
            get_output_path("library", &opencode_config)
        );

        let opencode_tui_config_name = format!("{}-opencode-tui", &self.name);
        let opencode_tui_config =
            OpenCodeTuiConfig::new(opencode_tui_config_name.as_str(), self.systems.clone())
                .with_schema("https://opencode.ai/tui.json")
                .with_theme("tokyonight")
                .build(context)
                .await?;
        let opencode_tui_config_path = format!(
            "{}/{opencode_tui_config_name}",
            get_output_path("library", &opencode_tui_config)
        );

        let ghostty_config_name = format!("{}-ghostty-config", &self.name);
        let ghostty_config = GhosttyConfig::new(ghostty_config_name.as_str(), self.systems.clone())
            .with_background_opacity(0.95)
            .with_font_family("GeistMono NFM")
            .with_font_size(16)
            .with_macos_option_as_alt(true)
            .with_theme("TokyoNight")
            .build(context)
            .await?;
        let ghostty_config_path = format!(
            "{}/{ghostty_config_name}",
            get_output_path("library", &ghostty_config)
        );

        // Define TokyoNight color palette

        let background = "default";
        let comment = "#6272a4";
        let current_line = "#44475a";
        let cyan = "#8be9fd";
        let foreground = "#f8f8f2";
        let green = "#50fa7b";
        let orange = "#ffb86c";
        let pink = "#ff79c6";
        let purple = "#bd93f9";
        let red = "#ff5555";
        let selection = "#44475a";
        let yellow = "#f1fa8c";

        let k9s_skin_name = format!("{}-k9s-skin", &self.name);
        let k9s_skin_config = K9sSkin::new(k9s_skin_name.as_str(), self.systems.clone())
            .with_body_bg_color(background)
            .with_body_fg_color(foreground)
            .with_body_logo_color(purple)
            .with_dialog_bg_color(background)
            .with_dialog_button_bg_color(purple)
            .with_dialog_button_fg_color(foreground)
            .with_dialog_button_focus_bg_color(pink)
            .with_dialog_button_focus_fg_color(yellow)
            .with_dialog_fg_color(foreground)
            .with_dialog_field_fg_color(foreground)
            .with_dialog_label_fg_color(orange)
            .with_frame_border_fg_color(selection)
            .with_frame_border_focus_color(current_line)
            .with_frame_crumbs_active_color(current_line)
            .with_frame_crumbs_bg_color(current_line)
            .with_frame_crumbs_fg_color(foreground)
            .with_frame_menu_fg_color(foreground)
            .with_frame_menu_key_color(pink)
            .with_frame_menu_num_key_color(pink)
            .with_frame_status_add_color(green)
            .with_frame_status_completed_color(comment)
            .with_frame_status_error_color(red)
            .with_frame_status_highlight_color(orange)
            .with_frame_status_kill_color(comment)
            .with_frame_status_modify_color(purple)
            .with_frame_status_new_color(cyan)
            .with_frame_title_bg_color(current_line)
            .with_frame_title_counter_color(purple)
            .with_frame_title_fg_color(foreground)
            .with_frame_title_filter_color(pink)
            .with_frame_title_highlight_color(orange)
            .with_info_fg_color(pink)
            .with_info_section_color(foreground)
            .with_prompt_bg_color(background)
            .with_prompt_fg_color(foreground)
            .with_prompt_suggest_color(purple)
            .with_views_charts_bg_color(background)
            .with_views_charts_default_chart_colors(vec![purple.to_string(), red.to_string()])
            .with_views_charts_default_dial_colors(vec![purple.to_string(), red.to_string()])
            .with_views_logs_bg_color(background)
            .with_views_logs_fg_color(foreground)
            .with_views_logs_indicator_bg_color(purple)
            .with_views_logs_indicator_fg_color(foreground)
            .with_views_table_bg_color(background)
            .with_views_table_cursor_bg_color(current_line)
            .with_views_table_cursor_fg_color(foreground)
            .with_views_table_fg_color(foreground)
            .with_views_table_header_bg_color(background)
            .with_views_table_header_fg_color(foreground)
            .with_views_table_header_sorter_color(cyan)
            .with_views_xray_bg_color(background)
            .with_views_xray_cursor_color(current_line)
            .with_views_xray_fg_color(foreground)
            .with_views_xray_graphic_color(purple)
            .with_views_xray_show_icons(false)
            .with_views_yaml_colon_color(purple)
            .with_views_yaml_key_color(pink)
            .with_views_yaml_value_color(foreground)
            .build(context)
            .await?;
        let k9s_skin_config_path = format!(
            "{}/{k9s_skin_name}",
            get_output_path("library", &k9s_skin_config)
        );

        let markdown_vim_name = format!("{}-markdown-vim", &self.name);
        let markdown_vim_config = FileCreate::new(
            "setlocal wrap",
            markdown_vim_name.as_str(),
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let markdown_vim_config_path = format!(
            "{}/{markdown_vim_name}",
            get_output_path("library", &markdown_vim_config)
        );

        // Claude Code status line script
        let claude_statusline_name = format!("{}-claude-statusline", &self.name);
        let claude_statusline = FileCreate::new(
            include_str!("user/statusline.sh"),
            claude_statusline_name.as_str(),
            self.systems.clone(),
        )
        .with_executable(true)
        .build(context)
        .await?;
        let claude_statusline_path = format!(
            "{}/{claude_statusline_name}",
            get_output_path("library", &claude_statusline)
        );

        // Claude Code TeammateIdle hook script
        let claude_teammate_idle_hook_name = format!("{}-claude-teammate-idle-hook", &self.name);
        let claude_teammate_idle_hook = FileCreate::new(
            include_str!("user/teammate-idle-hook.sh"),
            claude_teammate_idle_hook_name.as_str(),
            self.systems.clone(),
        )
        .with_executable(true)
        .build(context)
        .await?;
        let claude_teammate_idle_hook_path = format!(
            "{}/{claude_teammate_idle_hook_name}",
            get_output_path("library", &claude_teammate_idle_hook)
        );

        // Claude agents directory
        let claude_agents_name = format!("{}-claude-code-agents", &self.name);
        let claude_agents = FileSource::new(
            &claude_agents_name,
            "src/user/claude-code/agents",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let claude_agents_path = get_output_path("library", &claude_agents);

        // Codex agents directory
        let codex_agents_name = format!("{}-codex-agents", &self.name);
        let codex_agents = FileSource::new(
            &codex_agents_name,
            "src/user/codex/agents",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let codex_agents_path = get_output_path("library", &codex_agents);

        // Codex personas directory
        let codex_personas_name = format!("{}-codex-personas", &self.name);
        let codex_personas = FileSource::new(
            &codex_personas_name,
            "src/user/codex/personas",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let codex_personas_path = get_output_path("library", &codex_personas);

        // Claude skills directory
        let claude_skills_name = format!("{}-claude-skills", &self.name);
        let claude_skills = FileSource::new(
            &claude_skills_name,
            "src/user/claude-code/skills",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let claude_skills_path = get_output_path("library", &claude_skills);

        // Codex skills directory
        let codex_skills_name = format!("{}-codex-skills", &self.name);
        let codex_skills = FileSource::new(
            &codex_skills_name,
            "src/user/codex/skills",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let codex_skills_path = get_output_path("library", &codex_skills);

        // Opencode skills directory
        let opencode_skills_name = format!("{}-opencode-skills", &self.name);
        let opencode_skills = FileSource::new(
            &opencode_skills_name,
            "src/user/opencode/skills",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let opencode_skills_path = get_output_path("library", &opencode_skills);

        // User environment

        let claude_agents_path = format!("{claude_agents_path}/src/user/claude-code/agents");
        let claude_skills_path = format!("{claude_skills_path}/src/user/claude-code/skills");
        let codex_agents_path = format!("{codex_agents_path}/src/user/codex/agents");
        let codex_personas_path = format!("{codex_personas_path}/src/user/codex/personas");
        let codex_skills_path = format!("{codex_skills_path}/src/user/codex/skills");
        let opencode_skills_path = format!("{opencode_skills_path}/src/user/opencode/skills");

        artifact::UserEnvironment::new(&self.name, self.systems)
            .with_artifacts(vec![
                // Dependencies
                abtop,
                awscli2,
                bat,
                delta,
                direnv,
                doppler,
                fd,
                fzf,
                gh,
                git,
                gum,
                herdr,
                hunk,
                jj,
                jq,
                just,
                k9s,
                kubectl,
                lazygit,
                neovim,
                nnn,
                nodejs,
                op,
                pi,
                opencode,
                ripgrep,
                sesh,
                starship,
                terraform,
                tmux,
                zoxide,
                // Neovim
                bash_language_server,
                cue,
                gopls,
                lua_language_server,
                tree_sitter,
                typescript,
                typescript_language_server,
                vscode_langservers_extracted,
                yaml_language_server,
                // Tools
                bat_config,
                bat_theme,
                claude_agents,
                claude_code_config,
                claude_skills,
                claude_statusline,
                claude_teammate_idle_hook,
                codex_agents,
                codex_config,
                codex_personas,
                codex_team_lead_profile,
                codex_skills,
                ghostty_config,
                k9s_skin_config,
                markdown_vim_config,
                opencode_config,
                opencode_skills,
                opencode_tui_config,
            ])
            .with_environments(vec![
                "EDITOR=nvim".to_string(),
                "GOPATH=$HOME/Development/language/go".to_string(),
                "OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1".to_string(),
                "OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1".to_string(),
                "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative".to_string(),
                "OTEL_LOGS_EXPORTER=otlp".to_string(),
                "OTEL_METRICS_EXPORTER=otlp".to_string(),
                "PATH=/Applications/VMware\\ Fusion.app/Contents/Library:$GOPATH/bin:$HOME/.opencode/bin:$HOME/.vorpal/bin:$HOME/.local/bin:$PATH".to_string(),
                format!("OTEL_EXPORTER_OTLP_LOGS_ENDPOINT={OTEL_LOGS_ENDPOINT_LOKI}"),
                format!("OTEL_EXPORTER_OTLP_LOGS_PROTOCOL={OTEL_OTLP_PROTOCOL}"),
                format!("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT={OTEL_METRICS_ENDPOINT_MIMIR}"),
                format!("OTEL_EXPORTER_OTLP_METRICS_PROTOCOL={OTEL_OTLP_PROTOCOL}"),
            ])
            .with_symlinks(vec![
                ("$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal", "$HOME/.vorpal/bin/vorpal"),
                (bat_config_path.as_str(), "$HOME/.config/bat/config"),
                (bat_theme_path.as_str(), "$HOME/.config/bat/themes/tokyonight.tmTheme"),
                (&claude_agents_path, "$HOME/.claude/agents"),
                (claude_code_config_path.as_str(), "$HOME/.claude/settings.json"),
                (&claude_skills_path, "$HOME/.claude/skills"),
                (claude_statusline_path.as_str(), "$HOME/.claude/statusline.sh"),
                (claude_teammate_idle_hook_path.as_str(), "$HOME/.claude/teammate-idle-hook.sh"),
                (&codex_agents_path, "$HOME/.codex/agents"),
                (codex_config_path.as_str(), "$HOME/.codex/config.toml"),
                (&codex_personas_path, "$HOME/.codex/personas"),
                (codex_team_lead_profile_path.as_str(), "$HOME/.codex/team-lead.config.toml"),
                (&codex_skills_path, "$HOME/.codex/skills"),
                (ghostty_config_path.as_str(), "$HOME/Library/Application\\ Support/com.mitchellh.ghostty/config"),
                (k9s_skin_config_path.as_str(), "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml"),
                (markdown_vim_config_path.as_str(), "$HOME/.config/nvim/after/ftplugin/markdown.vim"),
                (opencode_config_path.as_str(), "$HOME/.config/opencode/opencode.json"),
                (&opencode_skills_path, "$HOME/.config/opencode/skills"),
                (opencode_tui_config_path.as_str(), "$HOME/.config/opencode/tui.json"),
            ])
            .build(context)
            .await
    }
}

fn codex_otlp_exporter(endpoint: &str) -> Option<toml::Value> {
    Some(
        toml::Value::try_from(serde_json::json!({
            "otlp-http": { "endpoint": endpoint, "protocol": "binary" }
        }))
        .expect("Codex OTLP exporter config must be TOML-serializable"),
    )
}

fn codex_agent_role(
    description: &str,
    config_file: &str,
    nickname_candidates: &[&str],
) -> AgentRole {
    AgentRole {
        description: Some(description.to_string()),
        config_file: Some(config_file.to_string()),
        nickname_candidates: nickname_candidates
            .iter()
            .map(|candidate| candidate.to_string())
            .collect(),
    }
}

fn opencode_agent(
    description: &str,
    prompt: &str,
    model: &str,
    variant: Option<&str>,
) -> AgentConfig {
    AgentConfig {
        model: Some(model.to_string()),
        variant: variant.map(|v| v.to_string()),
        mode: Some(AgentMode::Subagent),
        color: None,
        description: Some(description.to_string()),
        prompt: Some(prompt.to_string()),
        ..Default::default()
    }
}
