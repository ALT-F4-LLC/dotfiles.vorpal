use crate::file::FileCreate;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

// ============================================================================
// Enums
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DiffStyle {
    Auto,
    Stacked,
}

// ============================================================================
// Nested Configuration Structures
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct KeybindsConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub leader: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub app_exit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub editor_open: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub theme_list: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sidebar_toggle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub scrollbar_toggle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub status_view: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_export: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_new: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_list: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_timeline: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_fork: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_rename: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_share: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_unshare: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_interrupt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_compact: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_page_up: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_page_down: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_half_page_up: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_half_page_down: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_first: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_last: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_next: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_previous: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_last_user: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_copy: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_undo: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_redo: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub messages_toggle_conceal: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tool_details: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_list: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_cycle_recent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_cycle_recent_reverse: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_cycle_favorite: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_cycle_favorite_reverse: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub command_list: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_list: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_cycle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub agent_cycle_reverse: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub variant_cycle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_clear: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_paste: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_submit: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_newline: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_move_left: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_move_right: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_move_up: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_move_down: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_left: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_right: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_up: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_down: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_line_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_line_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_line_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_line_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_visual_line_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_visual_line_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_visual_line_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_visual_line_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_buffer_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_buffer_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_buffer_home: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_buffer_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete_line: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete_to_line_end: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete_to_line_start: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_backspace: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_undo: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_redo: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_word_forward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_word_backward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_word_forward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_select_word_backward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete_word_forward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub input_delete_word_backward: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub history_previous: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub history_next: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_child_cycle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_child_cycle_reverse: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_parent: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub terminal_suspend: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub terminal_title_toggle: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tips_toggle: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct ScrollAcceleration {
    pub enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct AttentionConfig {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub notifications: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sound: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub volume: Option<f64>,
}

// ============================================================================
// Main Opencode TUI Configuration Struct (tui.json)
// ============================================================================

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Config {
    // Metadata (not serialized to JSON)
    #[serde(skip)]
    name: String,
    #[serde(skip)]
    systems: Vec<ArtifactSystem>,

    #[serde(skip_serializing_if = "Option::is_none")]
    #[serde(rename = "$schema")]
    schema: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    theme: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    keybinds: Option<KeybindsConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    scroll_speed: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    scroll_acceleration: Option<ScrollAcceleration>,
    #[serde(skip_serializing_if = "Option::is_none")]
    diff_style: Option<DiffStyle>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mouse: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    attention: Option<AttentionConfig>,
}

impl Config {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            attention: None,
            diff_style: None,
            keybinds: None,
            mouse: None,
            name: name.to_string(),
            schema: None,
            scroll_acceleration: None,
            scroll_speed: None,
            systems,
            theme: None,
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
    pub fn with_theme(mut self, theme: &str) -> Self {
        self.theme = Some(theme.to_string());
        self
    }

    // ========================================================================
    // Keybinds Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_keybind_leader(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.leader = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_app_exit(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.app_exit = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_editor_open(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.editor_open = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_theme_list(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.theme_list = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_sidebar_toggle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.sidebar_toggle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_scrollbar_toggle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.scrollbar_toggle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_status_view(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.status_view = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_export(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_export = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_new(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_new = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_list(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_list = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_timeline(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_timeline = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_fork(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_fork = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_rename(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_rename = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_share(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_share = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_unshare(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_unshare = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_interrupt(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_interrupt = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_compact(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_compact = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_page_up(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_page_up = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_page_down(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_page_down = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_half_page_up(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_half_page_up = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_half_page_down(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_half_page_down = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_first(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_first = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_last(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_last = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_next(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_next = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_previous(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_previous = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_last_user(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_last_user = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_copy(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_copy = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_undo(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_undo = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_redo(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_redo = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_messages_toggle_conceal(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.messages_toggle_conceal = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_tool_details(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.tool_details = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_model_list(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.model_list = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_model_cycle_recent(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.model_cycle_recent = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_model_cycle_recent_reverse(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.model_cycle_recent_reverse = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_model_cycle_favorite(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.model_cycle_favorite = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_model_cycle_favorite_reverse(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.model_cycle_favorite_reverse = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_command_list(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.command_list = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_agent_list(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.agent_list = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_agent_cycle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.agent_cycle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_agent_cycle_reverse(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.agent_cycle_reverse = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_variant_cycle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.variant_cycle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_clear(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_clear = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_paste(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_paste = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_submit(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_submit = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_newline(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_newline = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_move_left(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_move_left = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_move_right(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_move_right = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_move_up(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_move_up = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_move_down(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_move_down = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_left(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_left = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_right(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_right = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_up(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_up = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_down(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_down = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_line_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_line_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_line_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_line_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_line_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_line_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_line_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_line_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_visual_line_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_visual_line_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_visual_line_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_visual_line_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_visual_line_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_visual_line_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_visual_line_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_visual_line_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_buffer_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_buffer_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_buffer_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_buffer_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_buffer_home(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_buffer_home = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_buffer_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_buffer_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete_line(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete_line = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete_to_line_end(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete_to_line_end = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete_to_line_start(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete_to_line_start = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_backspace(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_backspace = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_undo(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_undo = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_redo(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_redo = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_word_forward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_word_forward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_word_backward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_word_backward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_word_forward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_word_forward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_select_word_backward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_select_word_backward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete_word_forward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete_word_forward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_input_delete_word_backward(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.input_delete_word_backward = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_history_previous(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.history_previous = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_history_next(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.history_next = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_child_cycle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_child_cycle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_child_cycle_reverse(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_child_cycle_reverse = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_session_parent(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.session_parent = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_terminal_suspend(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.terminal_suspend = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_terminal_title_toggle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.terminal_title_toggle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    #[allow(dead_code)]
    pub fn with_keybind_tips_toggle(mut self, keys: &str) -> Self {
        let mut keybinds = self.keybinds.unwrap_or_default();
        keybinds.tips_toggle = Some(keys.to_string());
        self.keybinds = Some(keybinds);
        self
    }

    // ========================================================================
    // TUI Settings Builder Methods
    // ========================================================================

    #[allow(dead_code)]
    pub fn with_scroll_speed(mut self, speed: f64) -> Self {
        self.scroll_speed = Some(speed);
        self
    }

    #[allow(dead_code)]
    pub fn with_scroll_acceleration(mut self, enabled: bool) -> Self {
        self.scroll_acceleration = Some(ScrollAcceleration { enabled });
        self
    }

    #[allow(dead_code)]
    pub fn with_diff_style(mut self, style: DiffStyle) -> Self {
        self.diff_style = Some(style);
        self
    }

    #[allow(dead_code)]
    pub fn with_mouse(mut self, enabled: bool) -> Self {
        self.mouse = Some(enabled);
        self
    }

    #[allow(dead_code)]
    pub fn with_attention_enabled(mut self, enabled: bool) -> Self {
        let mut attention = self.attention.unwrap_or_default();
        attention.enabled = Some(enabled);
        self.attention = Some(attention);
        self
    }

    #[allow(dead_code)]
    pub fn with_attention_notifications(mut self, enabled: bool) -> Self {
        let mut attention = self.attention.unwrap_or_default();
        attention.notifications = Some(enabled);
        self.attention = Some(attention);
        self
    }

    #[allow(dead_code)]
    pub fn with_attention_sound(mut self, enabled: bool) -> Self {
        let mut attention = self.attention.unwrap_or_default();
        attention.sound = Some(enabled);
        self.attention = Some(attention);
        self
    }

    #[allow(dead_code)]
    pub fn with_attention_volume(mut self, volume: f64) -> Self {
        let mut attention = self.attention.unwrap_or_default();
        attention.volume = Some(volume);
        self.attention = Some(attention);
        self
    }

    // ========================================================================
    // Build Method
    // ========================================================================

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let json_content = serde_json::to_string_pretty(&self)
            .map_err(|e| anyhow::anyhow!("Failed to serialize Opencode TUI settings: {}", e))?;

        FileCreate::new(&json_content, &self.name, self.systems)
            .build(context)
            .await
    }
}
