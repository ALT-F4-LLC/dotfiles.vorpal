use crate::file::FileCreate;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeMap;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

// ============================================================================
// Enums
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum LogLevel {
    Debug,
    Info,
    Warn,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ShareMode {
    Manual,
    Auto,
    Disabled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum AutoUpdate {
    Boolean(bool),
    Notify(String), // "notify"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AgentMode {
    Subagent,
    Primary,
    All,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PermissionAction {
    Ask,
    Allow,
    Deny,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PolicyEffect {
    Allow,
    Deny,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum McpType {
    Local,
    Remote,
}

// ============================================================================
// Nested Configuration Structures
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ServerConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub port: Option<u16>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hostname: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mdns: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "mdnsDomain")]
    pub mdns_domain: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub cors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct CommandConfig {
    pub template: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subtask: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct WatcherConfig {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub ignore: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct AttachmentImageConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_resize: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_width: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_height: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_base64_bytes: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct AttachmentConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub image: Option<AttachmentImageConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum PermissionRule {
    Simple(PermissionAction),
    Object(BTreeMap<String, PermissionAction>),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum PermissionConfig {
    Simple(PermissionAction),
    Detailed(PermissionDetailed),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct PermissionDetailed {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub read: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub edit: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub glob: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub grep: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub list: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bash: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub task: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external_directory: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub todowrite: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub todoread: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub question: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub webfetch: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub websearch: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub codesearch: Option<PermissionAction>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub lsp: Option<PermissionRule>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub doom_loop: Option<PermissionAction>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct AgentConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub variant: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mode: Option<AgentMode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hidden: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<BTreeMap<String, Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub steps: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub permission: Option<PermissionConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ModelCost {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_read: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cache_write: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context_over_200k: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ModelLimit {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ModelModalities {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub input: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub output: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ModelConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub family: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub release_date: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attachment: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reasoning: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_call: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub interleaved: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cost: Option<ModelCost>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub limit: Option<ModelLimit>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub modalities: Option<ModelModalities>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub experimental: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<BTreeMap<String, Value>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub headers: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub provider: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub variants: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ProviderOptions {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "apiKey")]
    pub api_key: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "baseURL")]
    pub base_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "enterpriseUrl")]
    pub enterprise_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "setCacheKey")]
    pub set_cache_key: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout: Option<Value>, // Can be integer or false
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ProviderConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub env: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub npm: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    pub models: BTreeMap<String, ModelConfig>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub whitelist: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub blacklist: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<ProviderOptions>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct McpLocalConfig {
    #[serde(rename = "type")]
    pub mcp_type: McpType,
    pub command: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub environment: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct OAuthConfig {
    #[serde(rename = "clientId")]
    pub client_id: String,
    #[serde(rename = "clientSecret")]
    pub client_secret: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub scope: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct McpRemoteConfig {
    #[serde(rename = "type")]
    pub mcp_type: McpType,
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub headers: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub oauth: Option<OAuthConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum McpConfig {
    Local(McpLocalConfig),
    Remote(McpRemoteConfig),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum FormatterConfig {
    Disabled(bool), // false
    Enabled(FormatterEnabledConfig),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct FormatterEnabledConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disabled: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub command: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub environment: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub extensions: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum LspConfigMap {
    Disabled(bool), // false
    Enabled(BTreeMap<String, LspServerConfig>),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct LspServerConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disabled: Option<bool>,
    pub command: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub extensions: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub env: Option<BTreeMap<String, String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub initialization: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct EnterpriseConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct CompactionConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prune: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reserved: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct PolicyConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub effect: Option<PolicyEffect>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub action: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub resource: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct HookCommand {
    pub command: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub environment: Option<BTreeMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct HookConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub file_edited: Option<BTreeMap<String, Vec<HookCommand>>>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub session_completed: Vec<HookCommand>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct SkillsConfig {
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub paths: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub urls: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ToolOutputConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_lines: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_bytes: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct ReferenceGitConfig {
    pub repository: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hidden: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct ReferenceLocalConfig {
    pub path: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hidden: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum ReferenceValue {
    String(String),
    Git(ReferenceGitConfig),
    Local(ReferenceLocalConfig),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ExperimentalConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hook: Option<HookConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "chatMaxRetries")]
    pub chat_max_retries: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disable_paste_summary: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub batch_tool: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "openTelemetry")]
    pub open_telemetry: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub primary_tools: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub continue_loop_on_deny: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mcp_timeout: Option<u32>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub policies: Vec<PolicyConfig>,
}

// ============================================================================
// Main Opencode Configuration Struct
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Config {
    // Metadata (not serialized to JSON)
    #[serde(skip)]
    name: String,
    #[serde(skip)]
    systems: Vec<ArtifactSystem>,

    // Core settings
    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "$schema")]
    schema: Option<String>,
    #[serde(rename = "logLevel")]
    #[serde(skip_serializing_if = "Option::is_none")]
    log_level: Option<LogLevel>,
    #[serde(skip_serializing_if = "Option::is_none")]
    server: Option<ServerConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    shell: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tools: Option<BTreeMap<String, bool>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    attachment: Option<AttachmentConfig>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    command: BTreeMap<String, CommandConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    watcher: Option<WatcherConfig>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    plugin: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    snapshot: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    share: Option<ShareMode>,
    #[serde(skip_serializing_if = "Option::is_none")]
    autoupdate: Option<AutoUpdate>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    disabled_providers: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    enabled_providers: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    small_model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    default_agent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    username: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    agent: BTreeMap<String, AgentConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    permission: Option<PermissionConfig>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    provider: BTreeMap<String, ProviderConfig>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    mcp: BTreeMap<String, McpConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    formatter: Option<BTreeMap<String, FormatterConfig>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    lsp: Option<LspConfigMap>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    instructions: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    enterprise: Option<EnterpriseConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    compaction: Option<CompactionConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    experimental: Option<ExperimentalConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    skills: Option<SkillsConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    tool_output: Option<ToolOutputConfig>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    references: BTreeMap<String, ReferenceValue>,
}

impl Config {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            agent: BTreeMap::new(),
            attachment: None,
            autoupdate: None,
            command: BTreeMap::new(),
            compaction: None,
            default_agent: None,
            disabled_providers: Vec::new(),
            enabled_providers: Vec::new(),
            enterprise: None,
            experimental: None,
            formatter: None,
            instructions: Vec::new(),
            log_level: None,
            lsp: None,
            mcp: BTreeMap::new(),
            model: None,
            name: name.to_string(),
            permission: None,
            plugin: Vec::new(),
            provider: BTreeMap::new(),
            references: BTreeMap::new(),
            schema: None,
            server: None,
            share: None,
            shell: None,
            skills: None,
            small_model: None,
            snapshot: None,
            systems,
            tool_output: None,
            tools: None,
            username: None,
            watcher: None,
        }
    }

    // ========================================================================
    // Core Settings Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_schema(mut self, schema: &str) -> Self {
        self.schema = Some(schema.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_log_level(mut self, level: LogLevel) -> Self {
        self.log_level = Some(level);
        self
    }

    #[allow(dead_code)]
    pub fn with_snapshot(mut self, enabled: bool) -> Self {
        self.snapshot = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_share(mut self, mode: ShareMode) -> Self {
        self.share = Some(mode);
        self
    }

    #[allow(dead_code)]
    pub fn with_autoupdate(mut self, update: AutoUpdate) -> Self {
        self.autoupdate = Some(update);
        self
    }

    #[allow(dead_code)]
    pub fn with_disabled_provider(mut self, provider: &str) -> Self {
        self.disabled_providers.push(provider.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_enabled_provider(mut self, provider: &str) -> Self {
        self.enabled_providers.push(provider.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_model(mut self, model: &str) -> Self {
        self.model = Some(model.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_small_model(mut self, model: &str) -> Self {
        self.small_model = Some(model.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_default_agent(mut self, agent: &str) -> Self {
        self.default_agent = Some(agent.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_username(mut self, username: &str) -> Self {
        self.username = Some(username.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_plugin(mut self, plugin: &str) -> Self {
        self.plugin.push(plugin.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_instruction(mut self, instruction: &str) -> Self {
        self.instructions.push(instruction.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_shell(mut self, shell: &str) -> Self {
        self.shell = Some(shell.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_tool(mut self, name: &str, enabled: bool) -> Self {
        let mut tools = self.tools.unwrap_or_default();
        tools.insert(name.to_string(), enabled);
        self.tools = Some(tools);
        self
    }

    // ========================================================================
    // Server Settings Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_server_port(mut self, port: u16) -> Self {
        let mut server = self.server.unwrap_or_default();
        server.port = Some(port);
        self.server = Some(server);
        self
    }

    #[allow(dead_code)]
    pub fn with_server_hostname(mut self, hostname: &str) -> Self {
        let mut server = self.server.unwrap_or_default();
        server.hostname = Some(hostname.to_string());
        self.server = Some(server);
        self
    }

    #[allow(dead_code)]
    pub fn with_server_mdns(mut self, enabled: bool) -> Self {
        let mut server = self.server.unwrap_or_default();
        server.mdns = Some(enabled);
        self.server = Some(server);
        self
    }

    #[allow(dead_code)]
    pub fn with_server_mdns_domain(mut self, domain: &str) -> Self {
        let mut server = self.server.unwrap_or_default();
        server.mdns_domain = Some(domain.to_string());
        self.server = Some(server);
        self
    }

    #[allow(dead_code)]
    pub fn with_server_cors(mut self, domain: &str) -> Self {
        let mut server = self.server.unwrap_or_default();
        server.cors.push(domain.to_string());
        self.server = Some(server);
        self
    }

    // ========================================================================
    // Command Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_command(mut self, name: &str, config: CommandConfig) -> Self {
        self.command.insert(name.to_string(), config);
        self
    }

    // ========================================================================
    // Watcher Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_watcher_ignore(mut self, pattern: &str) -> Self {
        let mut watcher = self.watcher.unwrap_or_default();
        watcher.ignore.push(pattern.to_string());
        self.watcher = Some(watcher);
        self
    }

    // ========================================================================
    // Attachment Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_attachment_image_auto_resize(mut self, enabled: bool) -> Self {
        let mut attachment = self.attachment.unwrap_or_default();
        let mut image = attachment.image.unwrap_or_default();
        image.auto_resize = Some(enabled);
        attachment.image = Some(image);
        self.attachment = Some(attachment);
        self
    }

    #[allow(dead_code)]
    pub fn with_attachment_image_max_width(mut self, max_width: u32) -> Self {
        let mut attachment = self.attachment.unwrap_or_default();
        let mut image = attachment.image.unwrap_or_default();
        image.max_width = Some(max_width);
        attachment.image = Some(image);
        self.attachment = Some(attachment);
        self
    }

    #[allow(dead_code)]
    pub fn with_attachment_image_max_height(mut self, max_height: u32) -> Self {
        let mut attachment = self.attachment.unwrap_or_default();
        let mut image = attachment.image.unwrap_or_default();
        image.max_height = Some(max_height);
        attachment.image = Some(image);
        self.attachment = Some(attachment);
        self
    }

    #[allow(dead_code)]
    pub fn with_attachment_image_max_base64_bytes(mut self, max_bytes: u64) -> Self {
        let mut attachment = self.attachment.unwrap_or_default();
        let mut image = attachment.image.unwrap_or_default();
        image.max_base64_bytes = Some(max_bytes);
        attachment.image = Some(image);
        self.attachment = Some(attachment);
        self
    }

    // ========================================================================
    // Agent Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_agent(mut self, name: &str, config: AgentConfig) -> Self {
        self.agent.insert(name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_model(mut self, agent_name: &str, model: &str) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.model = Some(model.to_string());
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_variant(mut self, agent_name: &str, variant: &str) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.variant = Some(variant.to_string());
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_temperature(mut self, agent_name: &str, temperature: f64) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.temperature = Some(temperature);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_top_p(mut self, agent_name: &str, top_p: f64) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.top_p = Some(top_p);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_prompt(mut self, agent_name: &str, prompt: &str) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.prompt = Some(prompt.to_string());
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_steps(mut self, agent_name: &str, steps: u32) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.steps = Some(steps);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_color(mut self, agent_name: &str, color: &str) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.color = Some(color.to_string());
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_mode(mut self, agent_name: &str, mode: AgentMode) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.mode = Some(mode);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_description(mut self, agent_name: &str, description: &str) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.description = Some(description.to_string());
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_hidden(mut self, agent_name: &str, hidden: bool) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.hidden = Some(hidden);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_permission(mut self, agent_name: &str, permission: PermissionConfig) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.permission = Some(permission);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_agent_disable(mut self, agent_name: &str, disabled: bool) -> Self {
        let mut config = self.agent.get(agent_name).cloned().unwrap_or_default();
        config.disable = Some(disabled);
        self.agent.insert(agent_name.to_string(), config);
        self
    }

    // ========================================================================
    // Permission Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_permission(mut self, permission: PermissionConfig) -> Self {
        self.permission = Some(permission);
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_read(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.read = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_edit(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.edit = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_glob(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.glob = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_grep(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.grep = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_list(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.list = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_bash(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.bash = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_task(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.task = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_external_directory(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.external_directory = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_todowrite(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.todowrite = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_todoread(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.todoread = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_question(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.question = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_webfetch(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.webfetch = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_websearch(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.websearch = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_codesearch(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.codesearch = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_lsp(mut self, rule: PermissionRule) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.lsp = Some(rule);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_permission_doom_loop(mut self, action: PermissionAction) -> Self {
        let mut config = match self.permission {
            Some(PermissionConfig::Detailed(c)) => c,
            _ => PermissionDetailed::default(),
        };
        config.doom_loop = Some(action);
        self.permission = Some(PermissionConfig::Detailed(config));
        self
    }

    /// Helper method to configure bash permissions with multiple command patterns
    ///
    /// # Example
    /// ```ignore
    /// Opencode::new("config", systems)
    ///     .with_bash_permissions(vec![
    ///         ("*", PermissionAction::Ask),
    ///         ("cat*", PermissionAction::Allow),
    ///         ("git log*", PermissionAction::Allow),
    ///     ])
    /// ```
    #[allow(dead_code)]
    pub fn with_bash_permissions(self, perms: Vec<(&str, PermissionAction)>) -> Self {
        let mut bash_permissions = BTreeMap::new();
        for (cmd, action) in perms {
            bash_permissions.insert(cmd.to_string(), action);
        }
        self.with_permission_bash(PermissionRule::Object(bash_permissions))
    }

    // ========================================================================
    // Provider Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_provider(mut self, name: &str, config: ProviderConfig) -> Self {
        self.provider.insert(name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_provider_api(mut self, provider_name: &str, api: &str) -> Self {
        let mut config = self
            .provider
            .get(provider_name)
            .cloned()
            .unwrap_or_default();
        config.api = Some(api.to_string());
        self.provider.insert(provider_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_provider_model(
        mut self,
        provider_name: &str,
        model_name: &str,
        model_config: ModelConfig,
    ) -> Self {
        let mut config = self
            .provider
            .get(provider_name)
            .cloned()
            .unwrap_or_default();
        config.models.insert(model_name.to_string(), model_config);
        self.provider.insert(provider_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_provider_whitelist(mut self, provider_name: &str, model: &str) -> Self {
        let mut config = self
            .provider
            .get(provider_name)
            .cloned()
            .unwrap_or_default();
        config.whitelist.push(model.to_string());
        self.provider.insert(provider_name.to_string(), config);
        self
    }

    #[allow(dead_code)]
    pub fn with_provider_blacklist(mut self, provider_name: &str, model: &str) -> Self {
        let mut config = self
            .provider
            .get(provider_name)
            .cloned()
            .unwrap_or_default();
        config.blacklist.push(model.to_string());
        self.provider.insert(provider_name.to_string(), config);
        self
    }

    // ========================================================================
    // MCP Server Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_mcp_local(mut self, name: &str, command: Vec<String>) -> Self {
        self.mcp.insert(
            name.to_string(),
            McpConfig::Local(McpLocalConfig {
                mcp_type: McpType::Local,
                command,
                environment: None,
                enabled: None,
                timeout: None,
            }),
        );
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_local_full(mut self, name: &str, config: McpLocalConfig) -> Self {
        self.mcp.insert(name.to_string(), McpConfig::Local(config));
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_remote(mut self, name: &str, url: &str) -> Self {
        self.mcp.insert(
            name.to_string(),
            McpConfig::Remote(McpRemoteConfig {
                mcp_type: McpType::Remote,
                url: url.to_string(),
                enabled: None,
                headers: None,
                oauth: None,
                timeout: None,
            }),
        );
        self
    }

    #[allow(dead_code)]
    pub fn with_mcp_remote_full(mut self, name: &str, config: McpRemoteConfig) -> Self {
        self.mcp.insert(name.to_string(), McpConfig::Remote(config));
        self
    }

    // ========================================================================
    // Formatter Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_formatter_disabled(mut self) -> Self {
        self.formatter = None;
        self
    }

    #[allow(dead_code)]
    pub fn with_formatter(mut self, name: &str, config: FormatterConfig) -> Self {
        let mut formatters = self.formatter.unwrap_or_default();
        formatters.insert(name.to_string(), config);
        self.formatter = Some(formatters);
        self
    }

    // ========================================================================
    // LSP Configuration Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_lsp_disabled(mut self) -> Self {
        self.lsp = Some(LspConfigMap::Disabled(false));
        self
    }

    #[allow(dead_code)]
    pub fn with_lsp(mut self, name: &str, config: LspServerConfig) -> Self {
        let mut lsp_map = match self.lsp {
            Some(LspConfigMap::Enabled(map)) => map,
            _ => BTreeMap::new(),
        };
        lsp_map.insert(name.to_string(), config);
        self.lsp = Some(LspConfigMap::Enabled(lsp_map));
        self
    }

    // ========================================================================
    // Enterprise Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_enterprise_url(mut self, url: &str) -> Self {
        let mut enterprise = self.enterprise.unwrap_or_default();
        enterprise.url = Some(url.to_string());
        self.enterprise = Some(enterprise);
        self
    }

    // ========================================================================
    // Compaction Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_compaction_auto(mut self, enabled: bool) -> Self {
        let mut compaction = self.compaction.unwrap_or_default();
        compaction.auto = Some(enabled);
        self.compaction = Some(compaction);
        self
    }

    #[allow(dead_code)]
    pub fn with_compaction_prune(mut self, enabled: bool) -> Self {
        let mut compaction = self.compaction.unwrap_or_default();
        compaction.prune = Some(enabled);
        self.compaction = Some(compaction);
        self
    }

    #[allow(dead_code)]
    pub fn with_compaction_reserved(mut self, tokens: u32) -> Self {
        let mut compaction = self.compaction.unwrap_or_default();
        compaction.reserved = Some(tokens);
        self.compaction = Some(compaction);
        self
    }

    // ========================================================================
    // Experimental Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_experimental_chat_max_retries(mut self, retries: u32) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.chat_max_retries = Some(retries);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_disable_paste_summary(mut self, disabled: bool) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.disable_paste_summary = Some(disabled);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_batch_tool(mut self, enabled: bool) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.batch_tool = Some(enabled);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_open_telemetry(mut self, enabled: bool) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.open_telemetry = Some(enabled);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_primary_tools(mut self, tool: &str) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.primary_tools.push(tool.to_string());
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_continue_loop_on_deny(mut self, enabled: bool) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.continue_loop_on_deny = Some(enabled);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_mcp_timeout(mut self, timeout: u32) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.mcp_timeout = Some(timeout);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_hook_file_edited(
        mut self,
        pattern: &str,
        commands: Vec<HookCommand>,
    ) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        let mut hook = experimental.hook.unwrap_or_default();
        let mut file_edited = hook.file_edited.unwrap_or_default();
        file_edited.insert(pattern.to_string(), commands);
        hook.file_edited = Some(file_edited);
        experimental.hook = Some(hook);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_hook_session_completed(mut self, command: HookCommand) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        let mut hook = experimental.hook.unwrap_or_default();
        hook.session_completed.push(command);
        experimental.hook = Some(hook);
        self.experimental = Some(experimental);
        self
    }

    #[allow(dead_code)]
    pub fn with_experimental_policy(
        mut self,
        effect: PolicyEffect,
        action: &str,
        resource: &str,
    ) -> Self {
        let mut experimental = self.experimental.unwrap_or_default();
        experimental.policies.push(PolicyConfig {
            effect: Some(effect),
            action: Some(action.to_string()),
            resource: Some(resource.to_string()),
        });
        self.experimental = Some(experimental);
        self
    }

    // ========================================================================
    // Skills Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_skill_path(mut self, path: &str) -> Self {
        let mut skills = self.skills.unwrap_or_default();
        skills.paths.push(path.to_string());
        self.skills = Some(skills);
        self
    }

    #[allow(dead_code)]
    pub fn with_skill_url(mut self, url: &str) -> Self {
        let mut skills = self.skills.unwrap_or_default();
        skills.urls.push(url.to_string());
        self.skills = Some(skills);
        self
    }

    // ========================================================================
    // Tool Output Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_tool_output_max_lines(mut self, max_lines: u64) -> Self {
        let mut tool_output = self.tool_output.unwrap_or_default();
        tool_output.max_lines = Some(max_lines);
        self.tool_output = Some(tool_output);
        self
    }

    #[allow(dead_code)]
    pub fn with_tool_output_max_bytes(mut self, max_bytes: u64) -> Self {
        let mut tool_output = self.tool_output.unwrap_or_default();
        tool_output.max_bytes = Some(max_bytes);
        self.tool_output = Some(tool_output);
        self
    }

    // ========================================================================
    // References Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_reference(mut self, name: &str, value: ReferenceValue) -> Self {
        self.references.insert(name.to_string(), value);
        self
    }

    // ========================================================================
    // Build Method
    // ========================================================================

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let json_content = serde_json::to_string_pretty(&self)
            .map_err(|e| anyhow::anyhow!("Failed to serialize Opencode settings: {}", e))?;

        FileCreate::new(&json_content, &self.name, self.systems)
            .build(context)
            .await
    }
}
