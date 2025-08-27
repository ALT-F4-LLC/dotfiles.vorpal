use crate::SYSTEMS;
use anyhow::Result;
use file_builder::FileBuilder;
use ghostty_config::GhosttyConfigBuilder;
use k9s_skin::K9sSkinBuilder;
use vorpal_sdk::{
    artifact::{gh, userenv::UserenvBuilder},
    context::ConfigContext,
};

mod file_builder;
mod ghostty_config;
mod k9s_skin;

pub async fn build(context: &mut ConfigContext) -> Result<String> {
    // Dependencies

    let github_cli = gh::build(context).await?;

    // Configuration files

    let ghostty_config = GhosttyConfigBuilder::new("ghostty-config")
        .with_background_opacity(0.95)
        .with_font_family("GeistMono NFM")
        .with_font_size(18)
        .with_macos_option_as_alt(true)
        .with_theme("TokyoNight")
        .build(context)
        .await?;

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

    let k9s_skin = K9sSkinBuilder::new("k9s-skin")
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

    let markdown_vim = FileBuilder::new("markdown-vim")
        .with_line("setlocal wrap")
        .build(context)
        .await?;

    // User environment paths

    let output_path = "/var/lib/vorpal/store/artifact/output";
    let ghosty_config_path = format!("{output_path}/{ghostty_config}/ghostty-config");
    let k9s_skin_path = format!("{output_path}/{k9s_skin}/k9s-skin");
    let markdown_vim_path = format!("{output_path}/{markdown_vim}/markdown-vim");

    // User environment

    UserenvBuilder::new("userenv", SYSTEMS.to_vec())
        .with_artifacts(vec![github_cli, ghostty_config, k9s_skin, markdown_vim])
        .with_environments(vec![
            "EDITOR=nvim".to_string(),
            "GOPATH=$HOME/Development/language/go".to_string(),
            "PATH=$GOPATH/bin:$HOME/.vorpal/bin:/Applications/VMware\\ Fusion.app/Contents/Library:$PATH".to_string(),
        ])
        .with_symlinks(vec![
            (ghosty_config_path.as_str(), "$HOME/.config/ghostty/config"),
            (k9s_skin_path.as_str(), "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml"),
            (markdown_vim_path.as_str(), "$HOME/.config/nvim/after/ftplugin/markdown.vim"),
            ("$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal", "$HOME/.vorpal/bin/vorpal"),
        ])
        .build(context)
        .await
}
