use crate::{file::File, get_output_path};
use anyhow::Result;
use claude_code::ClaudeCode;
use ghostty::GhosttyConfig;
use k9s::K9sSkin;
use vorpal_artifacts::artifact::tmux;
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact,
    artifact::{gh, gopls},
    context::ConfigContext,
};

mod claude_code;
mod ghostty;
mod k9s;

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

        let github_cli = gh::build(context).await?;
        let gopls = gopls::build(context).await?;
        let tmux = tmux::build(context).await?;

        // Configuration files

        let claude_code_config_name = format!("{}-claude-code", &self.name);

        let claude_code_config =
            ClaudeCode::new(claude_code_config_name.as_str(), self.systems.clone())
                .with_always_thinking_enabled(true)
                .with_attribution_commit("")
                .with_attribution_pr("")
                .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
                .with_permission_allow("Bash(cargo check:*)")
                .with_permission_allow("Bash(cargo test:*)")
                .with_permission_allow("Bash(cat:*)")
                .with_permission_allow("WebSearch")
                .build(context)
                .await?;

        let claude_code_config_path = format!(
            "{}/{claude_code_config_name}",
            get_output_path("library", &claude_code_config)
        );

        let ghostty_config_name = format!("{}-ghostty-config", &self.name);

        let ghostty_config = GhosttyConfig::new(ghostty_config_name.as_str(), self.systems.clone())
            .with_background_opacity(0.95)
            .with_font_family("GeistMono NFM")
            .with_font_size(18)
            .with_macos_option_as_alt(true)
            .with_theme("TokyoNight")
            .build(context)
            .await?;

        let ghosty_config_path = format!(
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

        let k9s_skin = K9sSkin::new(k9s_skin_name.as_str(), self.systems.clone())
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

        let k9s_skin_path = format!("{}/{k9s_skin_name}", get_output_path("library", &k9s_skin));

        let markdown_vim_name = format!("{}-markdown-vim", &self.name);

        let markdown_vim = File::new(markdown_vim_name.as_str(), self.systems.clone())
            .with_content("setlocal wrap")
            .build(context)
            .await?;

        let markdown_vim_path = format!(
            "{}/{markdown_vim_name}",
            get_output_path("library", &markdown_vim)
        );

        // User environment

        artifact::UserEnvironment::new(&self.name, self.systems)
            .with_artifacts(vec![
                claude_code_config,
                ghostty_config,
                github_cli,
                gopls,
                k9s_skin,
                markdown_vim,
                tmux,
            ])
            .with_environments(vec![
                "EDITOR=nvim".to_string(),
                "GOPATH=$HOME/Development/language/go".to_string(),
                "PATH=$GOPATH/bin:$HOME/.vorpal/bin:/Applications/VMware\\ Fusion.app/Contents/Library:$PATH".to_string(),
            ])
            .with_symlinks(vec![
                ("$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal", "$HOME/.vorpal/bin/vorpal"),
                (claude_code_config_path.as_str(), "$HOME/.claude/settings.json"),
                (ghosty_config_path.as_str(), "$HOME/Library/Application\\ Support/com.mitchellh.ghostty/config"),
                (k9s_skin_path.as_str(), "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml"),
                (markdown_vim_path.as_str(), "$HOME/.config/nvim/after/ftplugin/markdown.vim"),
            ])
            .build(context)
            .await
    }
}
