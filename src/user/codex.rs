use crate::file::FileCreate;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use toml::Value;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

// =========================================================================
// Supporting types for nested configuration structures
// =========================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookCommand {
    pub command: String,
    #[serde(rename = "type")]
    pub hook_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout: Option<u64>,
    #[serde(rename = "statusMessage", skip_serializing_if = "Option::is_none")]
    pub status_message: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub matcher: Option<String>,
    pub hooks: Vec<HookCommand>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Agents {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_threads: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_depth: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub job_max_runtime_seconds: Option<u64>,
    #[serde(flatten, skip_serializing_if = "BTreeMap::is_empty", default)]
    pub roles: BTreeMap<String, AgentRole>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct AgentRole {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub config_file: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub nickname_candidates: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Skills {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub config: Vec<SkillConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SkillConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SandboxWorkspaceWrite {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub writable_roots: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network_access: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exclude_tmpdir_env_var: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exclude_slash_tmp: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ShellEnvironmentPolicy {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub inherit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ignore_default_excludes: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub exclude: Vec<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub set: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub include_only: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub experimental_use_profile: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum TuiNotifications {
    Enabled(bool),
    Events(Vec<String>),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Tui {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notifications: Option<TuiNotifications>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notification_method: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notification_condition: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub animations: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub show_tooltips: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub alternate_screen: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub status_line: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub terminal_title: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub theme: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub keymap: BTreeMap<String, Value>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub model_availability_nux: BTreeMap<String, i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct History {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub persistence: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_bytes: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Analytics {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Feedback {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Notice {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hide_full_access_warning: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hide_world_writable_warning: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hide_rate_limit_model_nudge: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hide_gpt5_1_migration_prompt: Option<bool>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub model_migrations: BTreeMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Memories {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub generate_memories: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub use_memories: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable_on_external_context: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub no_memories_if_mcp_or_web_search: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Tools {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub view_image: Option<bool>,
    #[serde(flatten, skip_serializing_if = "BTreeMap::is_empty", default)]
    pub extra: BTreeMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Otel {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub log_user_prompt: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub environment: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exporter: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub trace_exporter: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metrics_exporter: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Windows {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sandbox: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Project {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub trust_level: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ModelProvider {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub base_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub wire_api: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub env_key: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub env_key_instructions: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub requires_openai_auth: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub request_max_retries: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stream_max_retries: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stream_idle_timeout_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub supports_websockets: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub experimental_bearer_token: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub http_headers: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub env_http_headers: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub query_params: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auth: Option<CommandAuth>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub aws: Option<AwsProviderConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct CommandAuth {
    pub command: String,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub args: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub refresh_interval_ms: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct AwsProviderConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub profile: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub region: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct McpServer {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub required: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub command: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub args: Vec<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub env: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub env_vars: Vec<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cwd: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub experimental_environment: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bearer_token_env_var: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub http_headers: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub env_http_headers: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub startup_timeout_sec: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub startup_timeout_ms: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_timeout_sec: Option<f64>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub enabled_tools: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub disabled_tools: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub scopes: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub oauth_resource: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default_tools_approval_mode: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub tools: BTreeMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Apps {
    #[serde(flatten, skip_serializing_if = "BTreeMap::is_empty", default)]
    pub apps: BTreeMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ToolSuggest {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub discoverables: Vec<Value>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub disabled_tools: Vec<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Permissions {
    #[serde(flatten, skip_serializing_if = "BTreeMap::is_empty", default)]
    pub profiles: BTreeMap<String, Value>,
}

// =========================================================================
// Main Codex configuration struct
// =========================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Codex {
    // Metadata (not serialized to TOML)
    #[serde(skip)]
    name: String,
    #[serde(skip)]
    systems: Vec<ArtifactSystem>,

    // ---- Core model selection ----
    #[serde(skip_serializing_if = "Option::is_none")]
    model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    personality: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    review_model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_provider: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    oss_provider: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    service_tier: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_context_window: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_auto_compact_token_limit: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_output_token_limit: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_catalog_json: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    background_terminal_max_timeout: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    log_dir: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    sqlite_home: Option<String>,

    // ---- Reasoning & verbosity ----
    #[serde(skip_serializing_if = "Option::is_none")]
    model_reasoning_effort: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    plan_mode_reasoning_effort: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_reasoning_summary: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_verbosity: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_supports_reasoning_summaries: Option<bool>,

    // ---- Instruction overrides ----
    #[serde(skip_serializing_if = "Option::is_none")]
    developer_instructions: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    compact_prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    commit_attribution: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model_instructions_file: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    experimental_compact_prompt_file: Option<String>,

    // ---- Notifications ----
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    notify: Vec<String>,

    // ---- Approval & sandbox ----
    #[serde(skip_serializing_if = "Option::is_none")]
    approval_policy: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    approvals_reviewer: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    allow_login_shell: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    sandbox_mode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    default_permissions: Option<String>,

    // ---- Authentication & login ----
    #[serde(skip_serializing_if = "Option::is_none")]
    cli_auth_credentials_store: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    chatgpt_base_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    openai_base_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    forced_chatgpt_workspace_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    forced_login_method: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mcp_oauth_credentials_store: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mcp_oauth_callback_port: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mcp_oauth_callback_url: Option<String>,

    // ---- Project documentation controls ----
    #[serde(skip_serializing_if = "Option::is_none")]
    project_doc_max_bytes: Option<u64>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    project_doc_fallback_filenames: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    project_root_markers: Vec<String>,

    // ---- History & file opener ----
    #[serde(skip_serializing_if = "Option::is_none")]
    file_opener: Option<String>,

    // ---- UI, notifications, and misc ----
    #[serde(skip_serializing_if = "Option::is_none")]
    hide_agent_reasoning: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    show_raw_agent_reasoning: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    disable_paste_burst: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    windows_wsl_setup_acknowledged: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    check_for_update_on_startup: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    web_search: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    suppress_unstable_features_warning: Option<bool>,

    // ---- Tables ----
    #[serde(skip_serializing_if = "Option::is_none")]
    agents: Option<Agents>,
    #[serde(skip_serializing_if = "Option::is_none")]
    skills: Option<Skills>,
    #[serde(skip_serializing_if = "Option::is_none")]
    sandbox_workspace_write: Option<SandboxWorkspaceWrite>,
    #[serde(skip_serializing_if = "Option::is_none")]
    shell_environment_policy: Option<ShellEnvironmentPolicy>,
    #[serde(skip_serializing_if = "Option::is_none")]
    history: Option<History>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tui: Option<Tui>,
    #[serde(skip_serializing_if = "Option::is_none")]
    analytics: Option<Analytics>,
    #[serde(skip_serializing_if = "Option::is_none")]
    feedback: Option<Feedback>,
    #[serde(skip_serializing_if = "Option::is_none")]
    notice: Option<Notice>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    features: BTreeMap<String, Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    memories: Option<Memories>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    hooks: BTreeMap<String, Vec<HookConfig>>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    mcp_servers: BTreeMap<String, McpServer>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    model_providers: BTreeMap<String, ModelProvider>,
    #[serde(skip_serializing_if = "Option::is_none")]
    apps: Option<Apps>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_suggest: Option<ToolSuggest>,
    #[serde(skip_serializing_if = "Option::is_none")]
    permissions: Option<Permissions>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    projects: BTreeMap<String, Project>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<Tools>,
    #[serde(skip_serializing_if = "Option::is_none")]
    otel: Option<Otel>,
    #[serde(skip_serializing_if = "Option::is_none")]
    windows: Option<Windows>,
}

impl Codex {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,

            model: None,
            personality: None,
            review_model: None,
            model_provider: None,
            oss_provider: None,
            service_tier: None,
            model_context_window: None,
            model_auto_compact_token_limit: None,
            tool_output_token_limit: None,
            model_catalog_json: None,
            background_terminal_max_timeout: None,
            log_dir: None,
            sqlite_home: None,

            model_reasoning_effort: None,
            plan_mode_reasoning_effort: None,
            model_reasoning_summary: None,
            model_verbosity: None,
            model_supports_reasoning_summaries: None,

            developer_instructions: None,
            compact_prompt: None,
            commit_attribution: None,
            model_instructions_file: None,
            experimental_compact_prompt_file: None,

            notify: Vec::new(),

            approval_policy: None,
            approvals_reviewer: None,
            allow_login_shell: None,
            sandbox_mode: None,
            default_permissions: None,

            cli_auth_credentials_store: None,
            chatgpt_base_url: None,
            openai_base_url: None,
            forced_chatgpt_workspace_id: None,
            forced_login_method: None,
            mcp_oauth_credentials_store: None,
            mcp_oauth_callback_port: None,
            mcp_oauth_callback_url: None,

            project_doc_max_bytes: None,
            project_doc_fallback_filenames: Vec::new(),
            project_root_markers: Vec::new(),

            file_opener: None,

            hide_agent_reasoning: None,
            show_raw_agent_reasoning: None,
            disable_paste_burst: None,
            windows_wsl_setup_acknowledged: None,
            check_for_update_on_startup: None,
            web_search: None,
            suppress_unstable_features_warning: None,

            agents: None,
            skills: None,
            sandbox_workspace_write: None,
            shell_environment_policy: None,
            history: None,
            tui: None,
            analytics: None,
            feedback: None,
            notice: None,
            features: BTreeMap::new(),
            memories: None,
            hooks: BTreeMap::new(),
            mcp_servers: BTreeMap::new(),
            model_providers: BTreeMap::new(),
            apps: None,
            tool_suggest: None,
            permissions: None,
            projects: BTreeMap::new(),
            tools: None,
            otel: None,
            windows: None,
        }
    }

    fn value<T: Serialize>(value: T) -> Value {
        Value::try_from(value).expect("Codex config value must be TOML-serializable")
    }

    // =====================================================================
    // Core model selection
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_model(mut self, model: &str) -> Self {
        self.model = Some(model.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_personality(mut self, personality: &str) -> Self {
        self.personality = Some(personality.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_review_model(mut self, model: &str) -> Self {
        self.review_model = Some(model.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_provider(mut self, provider: &str) -> Self {
        self.model_provider = Some(provider.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_oss_provider(mut self, provider: &str) -> Self {
        self.oss_provider = Some(provider.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_service_tier(mut self, tier: &str) -> Self {
        self.service_tier = Some(tier.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_context_window(mut self, tokens: u64) -> Self {
        self.model_context_window = Some(tokens);
        self
    }

    #[allow(dead_code)]
    pub fn with_model_auto_compact_token_limit(mut self, tokens: u64) -> Self {
        self.model_auto_compact_token_limit = Some(tokens);
        self
    }

    #[allow(dead_code)]
    pub fn with_tool_output_token_limit(mut self, tokens: u64) -> Self {
        self.tool_output_token_limit = Some(tokens);
        self
    }

    #[allow(dead_code)]
    pub fn with_model_catalog_json(mut self, path: &str) -> Self {
        self.model_catalog_json = Some(path.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_background_terminal_max_timeout(mut self, timeout_ms: u64) -> Self {
        self.background_terminal_max_timeout = Some(timeout_ms);
        self
    }

    #[allow(dead_code)]
    pub fn with_log_dir(mut self, path: &str) -> Self {
        self.log_dir = Some(path.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_sqlite_home(mut self, path: &str) -> Self {
        self.sqlite_home = Some(path.to_string());
        self
    }

    // =====================================================================
    // Reasoning & verbosity
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_model_reasoning_effort(mut self, effort: &str) -> Self {
        self.model_reasoning_effort = Some(effort.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_plan_mode_reasoning_effort(mut self, effort: &str) -> Self {
        self.plan_mode_reasoning_effort = Some(effort.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_reasoning_summary(mut self, summary: &str) -> Self {
        self.model_reasoning_summary = Some(summary.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_verbosity(mut self, verbosity: &str) -> Self {
        self.model_verbosity = Some(verbosity.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_supports_reasoning_summaries(mut self, supported: bool) -> Self {
        self.model_supports_reasoning_summaries = Some(supported);
        self
    }

    // =====================================================================
    // Instruction overrides
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_developer_instructions(mut self, instructions: &str) -> Self {
        self.developer_instructions = Some(instructions.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_compact_prompt(mut self, prompt: &str) -> Self {
        self.compact_prompt = Some(prompt.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_commit_attribution(mut self, attribution: &str) -> Self {
        self.commit_attribution = Some(attribution.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model_instructions_file(mut self, path: &str) -> Self {
        self.model_instructions_file = Some(path.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_compact_prompt_file(mut self, path: &str) -> Self {
        self.experimental_compact_prompt_file = Some(path.to_string());
        self
    }

    // =====================================================================
    // Notifications
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_notify(mut self, argv: Vec<String>) -> Self {
        self.notify = argv;
        self
    }

    // =====================================================================
    // Approval & sandbox
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_approval_policy(mut self, policy: &str) -> Self {
        self.approval_policy = Some(Value::String(policy.to_string()));
        self
    }

    #[allow(dead_code)]
    pub fn with_granular_approval_policy(mut self, granular: BTreeMap<String, bool>) -> Self {
        let mut table = toml::Table::new();
        table.insert("granular".to_string(), Self::value(granular));
        self.approval_policy = Some(Value::Table(table));
        self
    }

    #[allow(dead_code)]
    pub fn with_approvals_reviewer(mut self, reviewer: &str) -> Self {
        self.approvals_reviewer = Some(reviewer.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_allow_login_shell(mut self, allow: bool) -> Self {
        self.allow_login_shell = Some(allow);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_mode(mut self, mode: &str) -> Self {
        self.sandbox_mode = Some(mode.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_default_permissions(mut self, profile: &str) -> Self {
        self.default_permissions = Some(profile.to_string());
        self
    }

    // =====================================================================
    // Authentication & login
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_cli_auth_credentials_store(mut self, store: &str) -> Self {
        self.cli_auth_credentials_store = Some(store.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_chatgpt_base_url(mut self, url: &str) -> Self {
        self.chatgpt_base_url = Some(url.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_openai_base_url(mut self, url: &str) -> Self {
        self.openai_base_url = Some(url.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_forced_chatgpt_workspace_id(mut self, workspace_id: &str) -> Self {
        self.forced_chatgpt_workspace_id = Some(workspace_id.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_forced_login_method(mut self, method: &str) -> Self {
        self.forced_login_method = Some(method.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_oauth_credentials_store(mut self, store: &str) -> Self {
        self.mcp_oauth_credentials_store = Some(store.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_oauth_callback_port(mut self, port: u16) -> Self {
        self.mcp_oauth_callback_port = Some(port);
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_oauth_callback_url(mut self, url: &str) -> Self {
        self.mcp_oauth_callback_url = Some(url.to_string());
        self
    }

    // =====================================================================
    // Project documentation controls
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_project_doc_max_bytes(mut self, bytes: u64) -> Self {
        self.project_doc_max_bytes = Some(bytes);
        self
    }

    #[allow(dead_code)]
    pub fn with_project_doc_fallback_filenames(mut self, filenames: Vec<String>) -> Self {
        self.project_doc_fallback_filenames = filenames;
        self
    }

    #[allow(dead_code)]
    pub fn with_project_root_markers(mut self, markers: Vec<String>) -> Self {
        self.project_root_markers = markers;
        self
    }

    // =====================================================================
    // UI, history, and misc
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_file_opener(mut self, opener: &str) -> Self {
        self.file_opener = Some(opener.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_hide_agent_reasoning(mut self, hide: bool) -> Self {
        self.hide_agent_reasoning = Some(hide);
        self
    }

    #[allow(dead_code)]
    pub fn with_show_raw_agent_reasoning(mut self, show: bool) -> Self {
        self.show_raw_agent_reasoning = Some(show);
        self
    }

    #[allow(dead_code)]
    pub fn with_disable_paste_burst(mut self, disable: bool) -> Self {
        self.disable_paste_burst = Some(disable);
        self
    }

    #[allow(dead_code)]
    pub fn with_windows_wsl_setup_acknowledged(mut self, acknowledged: bool) -> Self {
        self.windows_wsl_setup_acknowledged = Some(acknowledged);
        self
    }

    #[allow(dead_code)]
    pub fn with_check_for_update_on_startup(mut self, check: bool) -> Self {
        self.check_for_update_on_startup = Some(check);
        self
    }

    #[allow(dead_code)]
    pub fn with_web_search(mut self, mode: &str) -> Self {
        self.web_search = Some(mode.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_suppress_unstable_features_warning(mut self, suppress: bool) -> Self {
        self.suppress_unstable_features_warning = Some(suppress);
        self
    }

    // =====================================================================
    // Tables
    // =====================================================================

    #[allow(dead_code)]
    pub fn with_agents(mut self, agents: Agents) -> Self {
        self.agents = Some(agents);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_limits(
        mut self,
        max_threads: Option<u32>,
        max_depth: Option<u32>,
        job_max_runtime_seconds: Option<u64>,
    ) -> Self {
        let mut agents = self.agents.unwrap_or_default();
        agents.max_threads = max_threads;
        agents.max_depth = max_depth;
        agents.job_max_runtime_seconds = job_max_runtime_seconds;
        self.agents = Some(agents);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_role(mut self, name: &str, role: AgentRole) -> Self {
        let mut agents = self.agents.unwrap_or_default();
        agents.roles.insert(name.to_string(), role);
        self.agents = Some(agents);
        self
    }

    #[allow(dead_code)]
    pub fn with_skill_config(mut self, config: SkillConfig) -> Self {
        let mut skills = self.skills.unwrap_or_default();
        skills.config.push(config);
        self.skills = Some(skills);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_workspace_write(mut self, config: SandboxWorkspaceWrite) -> Self {
        self.sandbox_workspace_write = Some(config);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_workspace_writable_roots(mut self, roots: Vec<String>) -> Self {
        let mut sandbox = self.sandbox_workspace_write.unwrap_or_default();
        sandbox.writable_roots = roots;
        self.sandbox_workspace_write = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_workspace_network_access(mut self, access: bool) -> Self {
        let mut sandbox = self.sandbox_workspace_write.unwrap_or_default();
        sandbox.network_access = Some(access);
        self.sandbox_workspace_write = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_workspace_exclude_tmpdir_env_var(mut self, exclude: bool) -> Self {
        let mut sandbox = self.sandbox_workspace_write.unwrap_or_default();
        sandbox.exclude_tmpdir_env_var = Some(exclude);
        self.sandbox_workspace_write = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_sandbox_workspace_exclude_slash_tmp(mut self, exclude: bool) -> Self {
        let mut sandbox = self.sandbox_workspace_write.unwrap_or_default();
        sandbox.exclude_slash_tmp = Some(exclude);
        self.sandbox_workspace_write = Some(sandbox);
        self
    }

    #[allow(dead_code)]
    pub fn with_shell_environment_policy(mut self, policy: ShellEnvironmentPolicy) -> Self {
        self.shell_environment_policy = Some(policy);
        self
    }

    #[allow(dead_code)]
    pub fn with_shell_environment_inherit(mut self, inherit: &str) -> Self {
        let mut policy = self.shell_environment_policy.unwrap_or_default();
        policy.inherit = Some(inherit.to_string());
        self.shell_environment_policy = Some(policy);
        self
    }

    #[allow(dead_code)]
    pub fn with_shell_environment_include_only(mut self, names: Vec<String>) -> Self {
        let mut policy = self.shell_environment_policy.unwrap_or_default();
        policy.include_only = names;
        self.shell_environment_policy = Some(policy);
        self
    }

    #[allow(dead_code)]
    pub fn with_shell_environment_exclude(mut self, patterns: Vec<String>) -> Self {
        let mut policy = self.shell_environment_policy.unwrap_or_default();
        policy.exclude = patterns;
        self.shell_environment_policy = Some(policy);
        self
    }

    #[allow(dead_code)]
    pub fn with_shell_environment_set(mut self, key: &str, value: &str) -> Self {
        let mut policy = self.shell_environment_policy.unwrap_or_default();
        policy.set.insert(key.to_string(), value.to_string());
        self.shell_environment_policy = Some(policy);
        self
    }

    #[allow(dead_code)]
    pub fn with_history(mut self, history: History) -> Self {
        self.history = Some(history);
        self
    }

    #[allow(dead_code)]
    pub fn with_history_persistence(mut self, persistence: &str) -> Self {
        let mut history = self.history.unwrap_or_default();
        history.persistence = Some(persistence.to_string());
        self.history = Some(history);
        self
    }

    #[allow(dead_code)]
    pub fn with_history_max_bytes(mut self, bytes: u64) -> Self {
        let mut history = self.history.unwrap_or_default();
        history.max_bytes = Some(bytes);
        self.history = Some(history);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui(mut self, tui: Tui) -> Self {
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui_notifications(mut self, notifications: TuiNotifications) -> Self {
        let mut tui = self.tui.unwrap_or_default();
        tui.notifications = Some(notifications);
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui_theme(mut self, theme: &str) -> Self {
        let mut tui = self.tui.unwrap_or_default();
        tui.theme = Some(theme.to_string());
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui_status_line(mut self, items: Vec<String>) -> Self {
        let mut tui = self.tui.unwrap_or_default();
        tui.status_line = items;
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui_terminal_title(mut self, items: Vec<String>) -> Self {
        let mut tui = self.tui.unwrap_or_default();
        tui.terminal_title = items;
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_tui_keymap<T: Serialize>(mut self, section: &str, keymap: T) -> Self {
        let mut tui = self.tui.unwrap_or_default();
        tui.keymap.insert(section.to_string(), Self::value(keymap));
        self.tui = Some(tui);
        self
    }

    #[allow(dead_code)]
    pub fn with_analytics_enabled(mut self, enabled: bool) -> Self {
        let mut analytics = self.analytics.unwrap_or_default();
        analytics.enabled = Some(enabled);
        self.analytics = Some(analytics);
        self
    }

    #[allow(dead_code)]
    pub fn with_feedback_enabled(mut self, enabled: bool) -> Self {
        let mut feedback = self.feedback.unwrap_or_default();
        feedback.enabled = Some(enabled);
        self.feedback = Some(feedback);
        self
    }

    #[allow(dead_code)]
    pub fn with_notice(mut self, notice: Notice) -> Self {
        self.notice = Some(notice);
        self
    }

    #[allow(dead_code)]
    pub fn with_feature<T: Serialize>(mut self, key: &str, value: T) -> Self {
        self.features.insert(key.to_string(), Self::value(value));
        self
    }

    #[allow(dead_code)]
    pub fn with_feature_enabled(self, key: &str, enabled: bool) -> Self {
        self.with_feature(key, enabled)
    }

    #[allow(dead_code)]
    pub fn with_memories(mut self, memories: Memories) -> Self {
        self.memories = Some(memories);
        self
    }

    #[allow(dead_code)]
    pub fn with_hook(
        mut self,
        hook_name: &str,
        matcher: Option<&str>,
        command: &str,
        timeout: Option<u64>,
        status_message: Option<&str>,
    ) -> Self {
        let hook_command = HookCommand {
            command: command.to_string(),
            hook_type: "command".to_string(),
            timeout,
            status_message: status_message.map(|message| message.to_string()),
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
    pub fn with_mcp_server(mut self, name: &str, server: McpServer) -> Self {
        self.mcp_servers.insert(name.to_string(), server);
        self
    }

    #[allow(dead_code)]
    pub fn with_model_provider_config(mut self, name: &str, provider: ModelProvider) -> Self {
        self.model_providers.insert(name.to_string(), provider);
        self
    }

    #[allow(dead_code)]
    pub fn with_app<T: Serialize>(mut self, name: &str, config: T) -> Self {
        let mut apps = self.apps.unwrap_or_default();
        apps.apps.insert(name.to_string(), Self::value(config));
        self.apps = Some(apps);
        self
    }

    #[allow(dead_code)]
    pub fn with_tool_suggest(mut self, tool_suggest: ToolSuggest) -> Self {
        self.tool_suggest = Some(tool_suggest);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_profile<T: Serialize>(mut self, name: &str, profile: T) -> Self {
        let mut permissions = self.permissions.unwrap_or_default();
        permissions
            .profiles
            .insert(name.to_string(), Self::value(profile));
        self.permissions = Some(permissions);
        self
    }

    #[allow(dead_code)]
    pub fn with_project_trust_level(mut self, path: &str, trust_level: &str) -> Self {
        self.projects.insert(
            path.to_string(),
            Project {
                trust_level: Some(trust_level.to_string()),
            },
        );
        self
    }

    #[allow(dead_code)]
    pub fn with_tools(mut self, tools: Tools) -> Self {
        self.tools = Some(tools);
        self
    }

    #[allow(dead_code)]
    pub fn with_tool_enabled(mut self, tool: &str, enabled: bool) -> Self {
        let mut tools = self.tools.unwrap_or_default();
        match tool {
            "view_image" => tools.view_image = Some(enabled),
            other => {
                tools
                    .extra
                    .insert(other.to_string(), Value::Boolean(enabled));
            }
        }
        self.tools = Some(tools);
        self
    }

    #[allow(dead_code)]
    pub fn with_otel(mut self, otel: Otel) -> Self {
        self.otel = Some(otel);
        self
    }

    #[allow(dead_code)]
    pub fn with_otel_exporter<T: Serialize>(mut self, exporter: T) -> Self {
        let mut otel = self.otel.unwrap_or_default();
        otel.exporter = Some(Self::value(exporter));
        self.otel = Some(otel);
        self
    }

    #[allow(dead_code)]
    pub fn with_windows_sandbox(mut self, sandbox: &str) -> Self {
        let mut windows = self.windows.unwrap_or_default();
        windows.sandbox = Some(sandbox.to_string());
        self.windows = Some(windows);
        self
    }

    // =====================================================================
    // Build
    // =====================================================================

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let toml_content = toml::to_string_pretty(&self)
            .map_err(|e| anyhow::anyhow!("Failed to serialize Codex config: {}", e))?;

        FileCreate::new(&toml_content, &self.name, self.systems)
            .build(context)
            .await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serializes_current_config_shape() {
        let content = toml::to_string_pretty(
            &Codex::new("codex", Vec::new())
                .with_model("gpt-5.5")
                .with_default_permissions(":workspace")
                .with_history_persistence("save-all")
                .with_tui_notifications(TuiNotifications::Enabled(false))
                .with_feature_enabled("hooks", true)
                .with_tool_enabled("view_image", true),
        )
        .expect("codex config should serialize to TOML");

        assert!(content.contains("model = \"gpt-5.5\""));
        assert!(content.contains("default_permissions = \":workspace\""));
        assert!(content.contains("[history]"));
        assert!(content.contains("[features]"));
        assert!(content.contains("[tools]"));
    }

    #[test]
    fn serializes_sandbox_workspace_writable_roots() {
        let content = toml::to_string_pretty(
            &Codex::new("codex", Vec::new())
                .with_sandbox_workspace_writable_roots(vec!["$HOME/.cache/uv".to_string()])
                .with_sandbox_workspace_network_access(false),
        )
        .expect("codex config should serialize sandbox workspace write config");
        let value: Value =
            toml::from_str(&content).expect("serialized codex config should parse as TOML");
        let sandbox = value
            .get("sandbox_workspace_write")
            .and_then(Value::as_table)
            .expect("sandbox workspace write table should exist");
        let writable_roots = sandbox
            .get("writable_roots")
            .and_then(Value::as_array)
            .expect("sandbox workspace write roots should serialize as an array")
            .iter()
            .map(|root| {
                root.as_str()
                    .expect("sandbox workspace write roots should be strings")
            })
            .collect::<Vec<_>>();

        assert_eq!(writable_roots, vec!["$HOME/.cache/uv"]);
        assert_eq!(
            sandbox.get("network_access").and_then(Value::as_bool),
            Some(false)
        );
        for disallowed_root in [
            "$HOME",
            "$HOME/.cache",
            "$HOME/.codex",
            "$HOME/.vorpal",
            "/tmp",
            ".git",
        ] {
            assert!(
                !writable_roots.contains(&disallowed_root),
                "sandbox writable roots should not include broad root {disallowed_root:?}"
            );
        }
    }

    #[test]
    fn serializes_otel_metrics_exporter_otlp_http() {
        let content = toml::to_string_pretty(
            &Codex::new("codex", Vec::new()).with_otel(Otel {
                metrics_exporter: Some(
                    toml::Value::try_from(serde_json::json!({
                        "otlp-http": {
                            "endpoint": "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics",
                            "protocol": "binary",
                        },
                    }))
                    .expect("test OTel metrics exporter config should be TOML-serializable"),
                ),
                ..Default::default()
            }),
        )
        .expect("codex config should serialize OTel metrics exporter to TOML");

        assert!(content.contains("[otel.metrics_exporter.otlp-http]"));
        assert!(content
            .contains("endpoint = \"https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics\""));
        assert!(content.contains("protocol = \"binary\""));
    }
}
