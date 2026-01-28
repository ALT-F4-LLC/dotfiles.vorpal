use crate::file::FileCreate;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

// Supporting types for nested configuration structures

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
    pub disable_bypass_permissions_mode: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct SandboxNetwork {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_unix_sockets: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_local_binding: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Sandbox {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_allow_bash_if_sandboxed: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub excluded_commands: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network: Option<SandboxNetwork>,
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

// Main ClaudeCode configuration struct

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ClaudeCode {
    // Metadata (not serialized to JSON)
    #[serde(skip)]
    name: String,
    #[serde(skip)]
    systems: Vec<ArtifactSystem>,

    // Core settings
    #[serde(skip_serializing_if = "Option::is_none")]
    model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    output_style: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    api_key_helper: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    cleanup_period_days: Option<u32>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    env: BTreeMap<String, String>,

    // Authentication
    #[serde(skip_serializing_if = "Option::is_none")]
    force_login_method: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    force_login_org_uuid: Option<String>,

    // Permissions
    #[serde(skip_serializing_if = "Option::is_none")]
    permissions: Option<Permissions>,

    // Sandbox
    #[serde(skip_serializing_if = "Option::is_none")]
    sandbox: Option<Sandbox>,

    // Attribution
    #[serde(skip_serializing_if = "Option::is_none")]
    attribution: Option<Attribution>,
    #[serde(skip_serializing_if = "Option::is_none")]
    include_co_authored_by: Option<bool>,

    // MCP Servers
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

    // Additional Features
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    company_announcements: Vec<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    hooks: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    status_line: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    file_suggestion: Option<String>,
    #[serde(skip_serializing_if = "BTreeMap::is_empty", default)]
    enabled_plugins: BTreeMap<String, bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    always_thinking_enabled: Option<bool>,
}

impl ClaudeCode {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,

            // Core settings - all None by default
            model: None,
            output_style: None,
            api_key_helper: None,
            cleanup_period_days: None,
            env: BTreeMap::new(),

            // Authentication
            force_login_method: None,
            force_login_org_uuid: None,

            // Permissions
            permissions: None,

            // Sandbox
            sandbox: None,

            // Attribution
            attribution: None,
            include_co_authored_by: None,

            // MCP Servers
            enable_all_project_mcp_servers: None,
            enabled_mcpjson_servers: Vec::new(),
            disabled_mcpjson_servers: Vec::new(),
            allowed_mcp_servers: Vec::new(),
            denied_mcp_servers: Vec::new(),

            // Additional Features
            company_announcements: Vec::new(),
            hooks: BTreeMap::new(),
            status_line: None,
            file_suggestion: None,
            enabled_plugins: BTreeMap::new(),
            always_thinking_enabled: None,
        }
    }

    // Core settings builder methods

    #[allow(dead_code)]
    pub fn with_model(mut self, model: &str) -> Self {
        self.model = Some(model.to_string());
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

    // Authentication builder methods

    #[allow(dead_code)]
    pub fn with_force_login_method(mut self, method: &str) -> Self {
        self.force_login_method = Some(method.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_force_login_org_uuid(mut self, uuid: &str) -> Self {
        self.force_login_org_uuid = Some(uuid.to_string());
        self
    }

    // Permissions builder methods

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

    // Sandbox builder methods

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
    pub fn with_sandbox_auto_allow_bash(mut self, auto_allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        sandbox.auto_allow_bash_if_sandboxed = Some(auto_allow);
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
    pub fn with_sandbox_network_allow_unix_sockets(mut self, allow: bool) -> Self {
        let mut sandbox = self.sandbox.unwrap_or_default();
        let mut network = sandbox.network.unwrap_or_default();
        network.allow_unix_sockets = Some(allow);
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

    // Attribution builder methods

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

    // MCP Servers builder methods

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

    // Additional Features builder methods

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

    #[allow(dead_code)]
    pub fn with_hook(mut self, hook_name: &str, command: &str) -> Self {
        self.hooks
            .insert(hook_name.to_string(), command.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_status_line(mut self, command: &str) -> Self {
        self.status_line = Some(command.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_file_suggestion(mut self, command: &str) -> Self {
        self.file_suggestion = Some(command.to_string());
        self
    }

    #[allow(dead_code)]
    pub fn with_enabled_plugin(mut self, plugin: &str, enabled: bool) -> Self {
        self.enabled_plugins.insert(plugin.to_string(), enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_always_thinking_enabled(mut self, enabled: bool) -> Self {
        self.always_thinking_enabled = Some(enabled);
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let json_content = serde_json::to_string_pretty(&self)
            .map_err(|e| anyhow::anyhow!("Failed to serialize Claude Code settings: {}", e))?;

        FileCreate::new(&json_content, &self.name, self.systems)
            .build(context)
            .await
    }
}
