use crate::file::FileCreate;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

// =========================================================================
// Supporting types for nested configuration structures
// =========================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookCommand {
    pub command: String,
    #[serde(rename = "type")]
    pub hook_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub matcher: Option<String>,
    pub hooks: Vec<HookCommand>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Permissions {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allow: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub ask: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub deny: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub additional_directories: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable_bypass_permissions_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub skip_dangerous_mode_permission_prompt: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct SandboxFilesystem {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allow_write: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub deny_write: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub deny_read: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allow_read: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_managed_read_paths_only: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct SandboxNetwork {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allowed_domains: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub denied_domains: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_managed_domains_only: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_all_unix_sockets: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_unix_sockets: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allow_mach_lookup: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_local_binding: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub http_proxy_port: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub socks_proxy_port: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Sandbox {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fail_if_unavailable: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_allow_bash_if_sandboxed: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_unsandboxed_commands: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub excluded_commands: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub filesystem: Option<SandboxFilesystem>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network: Option<SandboxNetwork>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enable_weaker_nested_sandbox: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enable_weaker_network_isolation: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bwrap_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub socat_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Attribution {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub commit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pr: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct McpServerRule {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_command: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatusLine {
    #[serde(rename = "type")]
    pub status_type: String,
    pub command: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub padding: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileSuggestion {
    #[serde(rename = "type")]
    pub kind: String,
    pub command: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum OrgUuids {
    Single(String),
    Multiple(Vec<String>),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Voice {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_submit: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct SpinnerTipsOverride {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub tips: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exclude_default: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SpinnerVerbs {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub verbs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct AutoMode {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub environment: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub allow: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub soft_deny: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub hard_deny: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Worktree {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub base_ref: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub symlink_directories: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub sparse_paths: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SshConfig {
    pub id: String,
    pub name: String,
    pub ssh_host: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ssh_port: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ssh_identity_file: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub start_directory: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PolicyHelper {
    pub path: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub refresh_interval_ms: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChannelPlugin {
    pub marketplace: String,
    pub plugin: String,
}

// =========================================================================
// Main ClaudeCode configuration struct
// =========================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    // Metadata (not serialized to JSON)
    #[serde(skip)]
    name: String,
    #[serde(skip)]
    systems: Vec<ArtifactSystem>,

    // ---- Core settings ----
    #[serde(skip_serializing_if = "Option::is_none")]
    agent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    model_overrides: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    available_models: Vec<String>,
    #[serde(
        rename = "fallbackModel",
        skip_serializing_if = "Vec::is_empty",
        default
    )]
    fallback_model: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    output_style: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    api_key_helper: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cleanup_period_days: Option<u32>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    env: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    language: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    effort_level: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    minimum_version: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    auto_updates_channel: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    include_git_instructions: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    plans_directory: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    default_shell: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pr_url_template: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    respect_gitignore: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    skip_web_fetch_preflight: Option<bool>,

    // ---- Memory ----
    #[serde(skip_serializing_if = "Option::is_none")]
    auto_memory_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    auto_memory_directory: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    claude_md: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    claude_md_excludes: Vec<String>,

    // ---- Authentication ----
    #[serde(skip_serializing_if = "Option::is_none")]
    force_login_method: Option<String>,
    #[serde(rename = "forceLoginOrgUUID", skip_serializing_if = "Option::is_none")]
    force_login_org_uuid: Option<OrgUuids>,
    #[serde(skip_serializing_if = "Option::is_none")]
    aws_auth_refresh: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    aws_credential_export: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    gcp_auth_refresh: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    otel_headers_helper: Option<String>,

    // ---- Permissions ----
    #[serde(skip_serializing_if = "Option::is_none")]
    permissions: Option<Permissions>,

    // ---- Sandbox ----
    #[serde(skip_serializing_if = "Option::is_none")]
    sandbox: Option<Sandbox>,

    // ---- Attribution ----
    #[serde(skip_serializing_if = "Option::is_none")]
    attribution: Option<Attribution>,
    /// Deprecated by upstream — use [`attribution`] instead.
    #[serde(skip_serializing_if = "Option::is_none")]
    include_co_authored_by: Option<bool>,

    // ---- MCP servers ----
    #[serde(skip_serializing_if = "Option::is_none")]
    enable_all_project_mcp_servers: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    enabled_mcpjson_servers: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    disabled_mcpjson_servers: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    allowed_mcp_servers: Vec<McpServerRule>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    denied_mcp_servers: Vec<McpServerRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    allow_managed_mcp_servers_only: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    allow_managed_permission_rules_only: Option<bool>,

    // ---- Hooks ----
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    hooks: BTreeMap<String, Vec<HookConfig>>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    allowed_http_hook_urls: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    http_hook_allowed_env_vars: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    allow_managed_hooks_only: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_all_hooks: Option<bool>,

    // ---- Plugins & marketplaces ----
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    enabled_plugins: BTreeMap<String, bool>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    extra_known_marketplaces: BTreeMap<String, Value>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    strict_known_marketplaces: Vec<Value>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    blocked_marketplaces: Vec<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    plugin_trust_message: Option<String>,

    // ---- Channels ----
    #[serde(skip_serializing_if = "Option::is_none")]
    channels_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    allowed_channel_plugins: Vec<ChannelPlugin>,

    // ---- Skills ----
    #[serde(skip_serializing_if = "Option::is_none")]
    max_skill_description_chars: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    skill_listing_budget_fraction: Option<f64>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    skill_overrides: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_skill_shell_execution: Option<bool>,

    // ---- Auto mode ----
    #[serde(skip_serializing_if = "Option::is_none")]
    auto_mode: Option<AutoMode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_auto_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    use_auto_mode_during_plan: Option<bool>,

    // ---- Status line / file suggestion ----
    #[serde(skip_serializing_if = "Option::is_none")]
    status_line: Option<StatusLine>,
    #[serde(skip_serializing_if = "Option::is_none")]
    file_suggestion: Option<FileSuggestion>,

    // ---- UI / display ----
    #[serde(skip_serializing_if = "Option::is_none")]
    editor_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    view_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tui: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    auto_scroll_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    show_turn_duration: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    teammate_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    terminal_progress_bar_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    preferred_notif_channel: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    away_summary_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    prefers_reduced_motion: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    syntax_highlighting_disabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    show_thinking_summaries: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    show_clear_context_on_plan_accept: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    spinner_tips_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    spinner_tips_override: Option<SpinnerTipsOverride>,
    #[serde(skip_serializing_if = "Option::is_none")]
    spinner_verbs: Option<SpinnerVerbs>,
    #[serde(skip_serializing_if = "Option::is_none")]
    feedback_survey_rate: Option<f64>,

    // ---- Voice ----
    #[serde(skip_serializing_if = "Option::is_none")]
    voice: Option<Voice>,
    /// Legacy alias for `voice.enabled`.
    #[serde(skip_serializing_if = "Option::is_none")]
    voice_enabled: Option<bool>,

    // ---- Worktree ----
    #[serde(skip_serializing_if = "Option::is_none")]
    worktree: Option<Worktree>,

    // ---- SSH ----
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    ssh_configs: Vec<SshConfig>,

    // ---- Disable / kill switches ----
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_agent_view: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_deep_link_registration: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_remote_control: Option<bool>,

    // ---- Thinking / fast mode ----
    #[serde(skip_serializing_if = "Option::is_none")]
    always_thinking_enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    fast_mode_per_session_opt_in: Option<bool>,

    // ---- Announcements ----
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    company_announcements: Vec<String>,

    // ---- Managed-only governance ----
    #[serde(skip_serializing_if = "Option::is_none")]
    parent_settings_behavior: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    policy_helper: Option<PolicyHelper>,
    #[serde(skip_serializing_if = "Option::is_none")]
    force_remote_settings_refresh: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    wsl_inherits_windows_settings: Option<bool>,
}

impl Config {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,

            // Core
            agent: None,
            model: None,
            model_overrides: BTreeMap::new(),
            available_models: Vec::new(),
            fallback_model: Vec::new(),
            output_style: None,
            api_key_helper: None,
            cleanup_period_days: None,
            env: BTreeMap::new(),
            language: None,
            effort_level: None,
            minimum_version: None,
            auto_updates_channel: None,
            include_git_instructions: None,
            plans_directory: None,
            default_shell: None,
            pr_url_template: None,
            respect_gitignore: None,
            skip_web_fetch_preflight: None,

            // Memory
            auto_memory_enabled: None,
            auto_memory_directory: None,
            claude_md: None,
            claude_md_excludes: Vec::new(),

            // Authentication
            force_login_method: None,
            force_login_org_uuid: None,
            aws_auth_refresh: None,
            aws_credential_export: None,
            gcp_auth_refresh: None,
            otel_headers_helper: None,

            // Permissions / sandbox
            permissions: None,
            sandbox: None,

            // Attribution
            attribution: None,
            include_co_authored_by: None,

            // MCP servers
            enable_all_project_mcp_servers: None,
            enabled_mcpjson_servers: Vec::new(),
            disabled_mcpjson_servers: Vec::new(),
            allowed_mcp_servers: Vec::new(),
            denied_mcp_servers: Vec::new(),
            allow_managed_mcp_servers_only: None,
            allow_managed_permission_rules_only: None,

            // Hooks
            hooks: BTreeMap::new(),
            allowed_http_hook_urls: Vec::new(),
            http_hook_allowed_env_vars: Vec::new(),
            allow_managed_hooks_only: None,
            disable_all_hooks: None,

            // Plugins / marketplaces
            enabled_plugins: BTreeMap::new(),
            extra_known_marketplaces: BTreeMap::new(),
            strict_known_marketplaces: Vec::new(),
            blocked_marketplaces: Vec::new(),
            plugin_trust_message: None,

            // Channels
            channels_enabled: None,
            allowed_channel_plugins: Vec::new(),

            // Skills
            max_skill_description_chars: None,
            skill_listing_budget_fraction: None,
            skill_overrides: BTreeMap::new(),
            disable_skill_shell_execution: None,

            // Auto mode
            auto_mode: None,
            disable_auto_mode: None,
            use_auto_mode_during_plan: None,

            // Status line / file suggestion
            status_line: None,
            file_suggestion: None,

            // UI / display
            editor_mode: None,
            view_mode: None,
            tui: None,
            auto_scroll_enabled: None,
            show_turn_duration: None,
            teammate_mode: None,
            terminal_progress_bar_enabled: None,
            preferred_notif_channel: None,
            away_summary_enabled: None,
            prefers_reduced_motion: None,
            syntax_highlighting_disabled: None,
            show_thinking_summaries: None,
            show_clear_context_on_plan_accept: None,
            spinner_tips_enabled: None,
            spinner_tips_override: None,
            spinner_verbs: None,
            feedback_survey_rate: None,

            // Voice
            voice: None,
            voice_enabled: None,

            // Worktree
            worktree: None,

            // SSH
            ssh_configs: Vec::new(),

            // Disable / kill switches
            disable_agent_view: None,
            disable_deep_link_registration: None,
            disable_remote_control: None,

            // Thinking / fast mode
            always_thinking_enabled: None,
            fast_mode_per_session_opt_in: None,

            // Announcements
            company_announcements: Vec::new(),

            // Managed-only governance
            parent_settings_behavior: None,
            policy_helper: None,
            force_remote_settings_refresh: None,
            wsl_inherits_windows_settings: None,
        }
    }

    // =====================================================================
    // Core settings
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_agent(mut self, agent: &str) -> Self {
        self.agent = Some(agent.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model(mut self, model: &str) -> Self {
        self.model = Some(model.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_override(mut self, model: &str, target: &str) -> Self {
        self.model_overrides
            .insert(model.to_string(), target.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_available_models(mut self, models: Vec<String>) -> Self {
        self.available_models = models;
        self
    }

    #[allow(dead_code)]
    pub fn with_fallback_model(mut self, models: Vec<String>) -> Self {
        self.fallback_model = models;
        self
    }

    #[allow(dead_code)]
    pub fn with_output_style(mut self, style: &str) -> Self {
        self.output_style = Some(style.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_api_key_helper(mut self, helper: &str) -> Self {
        self.api_key_helper = Some(helper.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_cleanup_period_days(mut self, days: u32) -> Self {
        self.cleanup_period_days = Some(days);
        self
    }

    #[allow(dead_code)]
    pub fn with_env(mut self, key: &str, value: &str) -> Self {
        self.env.insert(key.to_string(), value.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_env_vars(mut self, vars: BTreeMap<String, String>) -> Self {
        self.env = vars;
        self
    }

    #[allow(dead_code)]
    pub fn with_language(mut self, language: &str) -> Self {
        self.language = Some(language.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_effort_level(mut self, level: &str) -> Self {
        self.effort_level = Some(level.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_minimum_version(mut self, version: &str) -> Self {
        self.minimum_version = Some(version.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_auto_updates_channel(mut self, channel: &str) -> Self {
        self.auto_updates_channel = Some(channel.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_include_git_instructions(mut self, enabled: bool) -> Self {
        self.include_git_instructions = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_plans_directory(mut self, dir: &str) -> Self {
        self.plans_directory = Some(dir.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_default_shell(mut self, shell: &str) -> Self {
        self.default_shell = Some(shell.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_pr_url_template(mut self, template: &str) -> Self {
        self.pr_url_template = Some(template.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_respect_gitignore(mut self, enabled: bool) -> Self {
        self.respect_gitignore = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_skip_web_fetch_preflight(mut self, enabled: bool) -> Self {
        self.skip_web_fetch_preflight = Some(enabled);
        self
    }

    // =====================================================================
    // Memory
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_auto_memory_enabled(mut self, enabled: bool) -> Self {
        self.auto_memory_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_auto_memory_directory(mut self, dir: &str) -> Self {
        self.auto_memory_directory = Some(dir.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_claude_md(mut self, contents: &str) -> Self {
        self.claude_md = Some(contents.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_claude_md_excludes(mut self, excludes: Vec<String>) -> Self {
        self.claude_md_excludes = excludes;
        self
    }

    // =====================================================================
    // Authentication
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_force_login_method(mut self, method: &str) -> Self {
        self.force_login_method = Some(method.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_force_login_org_uuid(mut self, uuid: &str) -> Self {
        self.force_login_org_uuid = Some(OrgUuids::Single(uuid.to_string()));
        self
    }

    #[allow(dead_code)]
    pub fn with_force_login_org_uuids(mut self, uuids: Vec<String>) -> Self {
        self.force_login_org_uuid = Some(OrgUuids::Multiple(uuids));
        self
    }

    #[allow(dead_code)]
    pub fn with_aws_auth_refresh(mut self, script: &str) -> Self {
        self.aws_auth_refresh = Some(script.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_aws_credential_export(mut self, script: &str) -> Self {
        self.aws_credential_export = Some(script.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_gcp_auth_refresh(mut self, script: &str) -> Self {
        self.gcp_auth_refresh = Some(script.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_otel_headers_helper(mut self, helper: &str) -> Self {
        self.otel_headers_helper = Some(helper.to_string());
        self
    }

    // =====================================================================
    // Permissions
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_permissions(mut self, permissions: Permissions) -> Self {
        self.permissions = Some(permissions);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_allow(mut self, rule: &str) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.allow.push(rule.to_string());
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_ask(mut self, rule: &str) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.ask.push(rule.to_string());
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_deny(mut self, rule: &str) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.deny.push(rule.to_string());
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_additional_directories(mut self, dirs: Vec<String>) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.additional_directories = dirs;
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_default_mode(mut self, mode: &str) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.default_mode = Some(mode.to_string());
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_disable_bypass_permissions_mode(mut self, value: &str) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.disable_bypass_permissions_mode = Some(value.to_string());
        self.permissions = Some(perms);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_skip_dangerous_mode_prompt(mut self, skip: bool) -> Self {
        let mut perms = self.permissions.unwrap_or_default();
        perms.skip_dangerous_mode_permission_prompt = Some(skip);
        self.permissions = Some(perms);
        self
    }

    // =====================================================================
    // Sandbox
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_sandbox(mut self, sandbox: Sandbox) -> Self {
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_enabled(mut self, enabled: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.enabled = Some(enabled);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_fail_if_unavailable(mut self, fail: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.fail_if_unavailable = Some(fail);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_auto_allow_bash(mut self, auto_allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.auto_allow_bash_if_sandboxed = Some(auto_allow);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_allow_unsandboxed_commands(mut self, allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.allow_unsandboxed_commands = Some(allow);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_excluded_commands(mut self, commands: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.excluded_commands = commands;
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem(mut self, filesystem: SandboxFilesystem) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.filesystem = Some(filesystem);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem_allow_write(mut self, paths: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut fs = sandbox.filesystem.unwrap_or_default();
        fs.allow_write = paths;
        sandbox.filesystem = Some(fs);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem_deny_write(mut self, paths: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut fs = sandbox.filesystem.unwrap_or_default();
        fs.deny_write = paths;
        sandbox.filesystem = Some(fs);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem_deny_read(mut self, paths: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut fs = sandbox.filesystem.unwrap_or_default();
        fs.deny_read = paths;
        sandbox.filesystem = Some(fs);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem_allow_read(mut self, paths: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut fs = sandbox.filesystem.unwrap_or_default();
        fs.allow_read = paths;
        sandbox.filesystem = Some(fs);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_filesystem_allow_managed_read_paths_only(mut self, only: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut fs = sandbox.filesystem.unwrap_or_default();
        fs.allow_managed_read_paths_only = Some(only);
        sandbox.filesystem = Some(fs);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allowed_domains(mut self, domains: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allowed_domains = domains;
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_denied_domains(mut self, domains: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.denied_domains = domains;
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allow_managed_domains_only(mut self, only: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_managed_domains_only = Some(only);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allow_unix_sockets(mut self, sockets: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_unix_sockets = Some(sockets);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allow_all_unix_sockets(mut self, allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_all_unix_sockets = Some(allow);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allow_mach_lookup(mut self, names: Vec<String>) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_mach_lookup = names;
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_allow_local_binding(mut self, allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_local_binding = Some(allow);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_http_proxy_port(mut self, port: u32) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.http_proxy_port = Some(port);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_network_socks_proxy_port(mut self, port: u32) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.socks_proxy_port = Some(port);
        sandbox.network = Some(network);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_enable_weaker_nested_sandbox(mut self, enable: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.enable_weaker_nested_sandbox = Some(enable);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_enable_weaker_network_isolation(mut self, enable: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.enable_weaker_network_isolation = Some(enable);
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_bwrap_path(mut self, path: &str) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.bwrap_path = Some(path.to_string());
        self.sandbox = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_socat_path(mut self, path: &str) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.socat_path = Some(path.to_string());
        self.sandbox = Some(sandbox);
        self
    }

    // =====================================================================
    // Attribution
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_attribution(mut self, attribution: Attribution) -> Self {
        self.attribution = Some(attribution);
        self
    }

    #[allow(dead_code)]
    pub fn with_attribution_commit(mut self, commit: &str) -> Self {
        let mut attr = self.attribution.unwrap_or_default();
        attr.commit = Some(commit.to_string());
        self.attribution = Some(attr);
        self
    }

    #[allow(dead_code)]
    pub fn with_attribution_pr(mut self, pr: &str) -> Self {
        let mut attr = self.attribution.unwrap_or_default();
        attr.pr = Some(pr.to_string());
        self.attribution = Some(attr);
        self
    }

    #[allow(dead_code)]
    pub fn with_include_co_authored_by(mut self, enabled: bool) -> Self {
        self.include_co_authored_by = Some(enabled);
        self
    }

    // =====================================================================
    // MCP servers
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_enable_all_project_mcp_servers(mut self, enabled: bool) -> Self {
        self.enable_all_project_mcp_servers = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_enabled_mcpjson_server(mut self, server: &str) -> Self {
        self.enabled_mcpjson_servers.push(server.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_disabled_mcpjson_server(mut self, server: &str) -> Self {
        self.disabled_mcpjson_servers.push(server.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_allowed_mcp_server(mut self, rule: McpServerRule) -> Self {
        self.allowed_mcp_servers.push(rule);
        self
    }

    #[allow(dead_code)]
    pub fn with_denied_mcp_server(mut self, rule: McpServerRule) -> Self {
        self.denied_mcp_servers.push(rule);
        self
    }

    #[allow(dead_code)]
    pub fn with_allow_managed_mcp_servers_only(mut self, only: bool) -> Self {
        self.allow_managed_mcp_servers_only = Some(only);
        self
    }

    #[allow(dead_code)]
    pub fn with_allow_managed_permission_rules_only(mut self, only: bool) -> Self {
        self.allow_managed_permission_rules_only = Some(only);
        self
    }

    // =====================================================================
    // Hooks
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_hook(
        mut self,
        hook_name: &str,
        matcher: Option<&str>,
        command: &str,
        hook_type: &str,
    ) -> Self {
        let hook_command = HookCommand {
            command: command.to_string(),
            hook_type: hook_type.to_string(),
        };
        let hook_config = HookConfig {
            matcher: matcher.map(|m| m.to_string()),
            hooks: vec![hook_command],
        };
        self.hooks
            .entry(hook_name.to_string())
            .or_default()
            .push(hook_config);
        self
    }

    #[allow(dead_code)]
    pub fn with_allowed_http_hook_url(mut self, url: &str) -> Self {
        self.allowed_http_hook_urls.push(url.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_http_hook_allowed_env_var(mut self, name: &str) -> Self {
        self.http_hook_allowed_env_vars.push(name.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_allow_managed_hooks_only(mut self, only: bool) -> Self {
        self.allow_managed_hooks_only = Some(only);
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_all_hooks(mut self, disable: bool) -> Self {
        self.disable_all_hooks = Some(disable);
        self
    }

    // =====================================================================
    // Plugins & marketplaces
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_enabled_plugin(mut self, plugin: &str, enabled: bool) -> Self {
        self.enabled_plugins.insert(plugin.to_string(), enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_extra_known_marketplace(mut self, name: &str, definition: Value) -> Self {
        self.extra_known_marketplaces
            .insert(name.to_string(), definition);
        self
    }

    #[allow(dead_code)]
    pub fn with_strict_known_marketplace(mut self, source: Value) -> Self {
        self.strict_known_marketplaces.push(source);
        self
    }

    #[allow(dead_code)]
    pub fn with_blocked_marketplace(mut self, source: Value) -> Self {
        self.blocked_marketplaces.push(source);
        self
    }

    #[allow(dead_code)]
    pub fn with_plugin_trust_message(mut self, message: &str) -> Self {
        self.plugin_trust_message = Some(message.to_string());
        self
    }

    // =====================================================================
    // Channels
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_channels_enabled(mut self, enabled: bool) -> Self {
        self.channels_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_allowed_channel_plugin(mut self, marketplace: &str, plugin: &str) -> Self {
        self.allowed_channel_plugins.push(ChannelPlugin {
            marketplace: marketplace.to_string(),
            plugin: plugin.to_string(),
        });
        self
    }

    // =====================================================================
    // Skills
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_max_skill_description_chars(mut self, chars: u32) -> Self {
        self.max_skill_description_chars = Some(chars);
        self
    }

    #[allow(dead_code)]
    pub fn with_skill_listing_budget_fraction(mut self, fraction: f64) -> Self {
        self.skill_listing_budget_fraction = Some(fraction);
        self
    }

    #[allow(dead_code)]
    pub fn with_skill_override(mut self, skill: &str, visibility: &str) -> Self {
        self.skill_overrides
            .insert(skill.to_string(), visibility.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_skill_shell_execution(mut self, disable: bool) -> Self {
        self.disable_skill_shell_execution = Some(disable);
        self
    }

    // =====================================================================
    // Auto mode
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_auto_mode(mut self, mode: AutoMode) -> Self {
        self.auto_mode = Some(mode);
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_auto_mode(mut self, value: &str) -> Self {
        self.disable_auto_mode = Some(value.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_use_auto_mode_during_plan(mut self, enabled: bool) -> Self {
        self.use_auto_mode_during_plan = Some(enabled);
        self
    }

    // =====================================================================
    // Status line / file suggestion
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_status_line(mut self, command: &str) -> Self {
        self.status_line = Some(StatusLine {
            status_type: "command".to_string(),
            command: command.to_string(),
            padding: None,
        });
        self
    }

    #[allow(dead_code)]
    pub fn with_status_line_padding(mut self, padding: u32) -> Self {
        if let Some(ref mut sl) = self.status_line {
            sl.padding = Some(padding);
        }
        self
    }

    #[allow(dead_code)]
    pub fn with_file_suggestion(mut self, command: &str) -> Self {
        self.file_suggestion = Some(FileSuggestion {
            kind: "command".to_string(),
            command: command.to_string(),
        });
        self
    }

    // =====================================================================
    // UI / display
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_editor_mode(mut self, mode: &str) -> Self {
        self.editor_mode = Some(mode.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_view_mode(mut self, mode: &str) -> Self {
        self.view_mode = Some(mode.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_tui(mut self, renderer: &str) -> Self {
        self.tui = Some(renderer.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_auto_scroll_enabled(mut self, enabled: bool) -> Self {
        self.auto_scroll_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_show_turn_duration(mut self, enabled: bool) -> Self {
        self.show_turn_duration = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_teammate_mode(mut self, mode: &str) -> Self {
        self.teammate_mode = Some(mode.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_terminal_progress_bar_enabled(mut self, enabled: bool) -> Self {
        self.terminal_progress_bar_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_preferred_notif_channel(mut self, channel: &str) -> Self {
        self.preferred_notif_channel = Some(channel.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_away_summary_enabled(mut self, enabled: bool) -> Self {
        self.away_summary_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_prefers_reduced_motion(mut self, enabled: bool) -> Self {
        self.prefers_reduced_motion = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_syntax_highlighting_disabled(mut self, disabled: bool) -> Self {
        self.syntax_highlighting_disabled = Some(disabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_show_thinking_summaries(mut self, enabled: bool) -> Self {
        self.show_thinking_summaries = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_show_clear_context_on_plan_accept(mut self, enabled: bool) -> Self {
        self.show_clear_context_on_plan_accept = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_spinner_tips_enabled(mut self, enabled: bool) -> Self {
        self.spinner_tips_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_spinner_tips_override(mut self, override_cfg: SpinnerTipsOverride) -> Self {
        self.spinner_tips_override = Some(override_cfg);
        self
    }

    #[allow(dead_code)]
    pub fn with_spinner_verbs(mut self, verbs: SpinnerVerbs) -> Self {
        self.spinner_verbs = Some(verbs);
        self
    }

    #[allow(dead_code)]
    pub fn with_feedback_survey_rate(mut self, rate: f64) -> Self {
        self.feedback_survey_rate = Some(rate);
        self
    }

    // =====================================================================
    // Voice
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_voice(mut self, voice: Voice) -> Self {
        self.voice = Some(voice);
        self
    }

    #[allow(dead_code)]
    pub fn with_voice_enabled(mut self, enabled: bool) -> Self {
        self.voice_enabled = Some(enabled);
        self
    }

    // =====================================================================
    // Worktree
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_worktree(mut self, worktree: Worktree) -> Self {
        self.worktree = Some(worktree);
        self
    }

    #[allow(dead_code)]
    pub fn with_worktree_base_ref(mut self, base_ref: &str) -> Self {
        let mut wt = self.worktree.unwrap_or_default();
        wt.base_ref = Some(base_ref.to_string());
        self.worktree = Some(wt);
        self
    }

    #[allow(dead_code)]
    pub fn with_worktree_symlink_directories(mut self, dirs: Vec<String>) -> Self {
        let mut wt = self.worktree.unwrap_or_default();
        wt.symlink_directories = dirs;
        self.worktree = Some(wt);
        self
    }

    #[allow(dead_code)]
    pub fn with_worktree_sparse_paths(mut self, paths: Vec<String>) -> Self {
        let mut wt = self.worktree.unwrap_or_default();
        wt.sparse_paths = paths;
        self.worktree = Some(wt);
        self
    }

    // =====================================================================
    // SSH
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_ssh_config(mut self, config: SshConfig) -> Self {
        self.ssh_configs.push(config);
        self
    }

    // =====================================================================
    // Disable / kill switches
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_disable_agent_view(mut self, disable: bool) -> Self {
        self.disable_agent_view = Some(disable);
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_deep_link_registration(mut self, value: &str) -> Self {
        self.disable_deep_link_registration = Some(value.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_remote_control(mut self, disable: bool) -> Self {
        self.disable_remote_control = Some(disable);
        self
    }

    // =====================================================================
    // Thinking / fast mode
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_always_thinking_enabled(mut self, enabled: bool) -> Self {
        self.always_thinking_enabled = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_fast_mode_per_session_opt_in(mut self, enabled: bool) -> Self {
        self.fast_mode_per_session_opt_in = Some(enabled);
        self
    }

    // =====================================================================
    // Announcements
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_company_announcements(mut self, announcements: Vec<String>) -> Self {
        self.company_announcements = announcements;
        self
    }

    #[allow(dead_code)]
    pub fn with_company_announcement(mut self, announcement: &str) -> Self {
        self.company_announcements.push(announcement.to_string());
        self
    }

    // =====================================================================
    // Managed-only governance
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_parent_settings_behavior(mut self, behavior: &str) -> Self {
        self.parent_settings_behavior = Some(behavior.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_policy_helper(mut self, helper: PolicyHelper) -> Self {
        self.policy_helper = Some(helper);
        self
    }

    #[allow(dead_code)]
    pub fn with_force_remote_settings_refresh(mut self, force: bool) -> Self {
        self.force_remote_settings_refresh = Some(force);
        self
    }

    #[allow(dead_code)]
    pub fn with_wsl_inherits_windows_settings(mut self, inherit: bool) -> Self {
        self.wsl_inherits_windows_settings = Some(inherit);
        self
    }

    // =====================================================================
    // Build
    // =====================================================================

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let json_content = serde_json::to_string_pretty(&self)
            .map_err(|e| anyhow::anyhow!("Failed to serialize Claude Code settings: {}", e))?;

        FileCreate::new(&json_content, &self.name, self.systems)
            .build(context)
            .await
    }
}
