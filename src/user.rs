use crate::{
    file::{FileCreate, FileDownload, FileSource},
    get_output_path,
};
use anyhow::Result;
use bat::BatConfig;
use claude_code::ClaudeCode;
use ghostty::GhosttyConfig;
use k9s::K9sSkin;
use opencode::{AutoUpdate, Opencode, PermissionAction, PermissionRule};
use vorpal_artifacts::artifact::{
    awscli2::Awscli2, bat::Bat, direnv::Direnv, doppler::Doppler, fd::Fd, jj::Jj, jq::Jq, k9s::K9s,
    kubectl::Kubectl, lazygit::Lazygit, nnn::Nnn, ripgrep::Ripgrep, tmux::Tmux,
};
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact,
    artifact::{gh::Gh, git::Git, gopls::Gopls},
    context::ConfigContext,
};

mod bat;
mod claude_code;
mod ghostty;
mod k9s;
mod opencode;

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

        let awscli2 = Awscli2::new().build(context).await?;
        let bat = Bat::new().build(context).await?;
        let direnv = Direnv::new().build(context).await?;
        let doppler = Doppler::new().build(context).await?;
        let fd = Fd::new().build(context).await?;
        let gh = Gh::new().build(context).await?;
        let git = Git::new().build(context).await?;
        let gopls = Gopls::new().build(context).await?;
        let jj = Jj::new().build(context).await?;
        let jq = Jq::new().build(context).await?;
        let k9s = K9s::new().build(context).await?;
        let kubectl = Kubectl::new().build(context).await?;
        let lazygit = Lazygit::new().build(context).await?;
        let nnn = Nnn::new().build(context).await?;
        let ripgrep = Ripgrep::new().build(context).await?;
        let tmux = Tmux::new().build(context).await?;

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
            ClaudeCode::new(claude_code_config_name.as_str(), self.systems.clone())
                .with_always_thinking_enabled(true)
                .with_attribution_commit("")
                .with_attribution_pr("")
                .with_enabled_plugin("gopls-lsp@claude-plugins-official", true)
                .with_enabled_plugin("rust-analyzer-lsp@claude-plugins-official", true)
                .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
                .with_permission_allow("Bash(cargo build:*)")
                .with_permission_allow("Bash(cargo check:*)")
                .with_permission_allow("Bash(cargo clippy:*)")
                .with_permission_allow("Bash(cargo fmt:*)")
                .with_permission_allow("Bash(cargo outdated:*)")
                .with_permission_allow("Bash(cargo search:*)")
                .with_permission_allow("Bash(cargo test:*)")
                .with_permission_allow("Bash(cargo tree:*)")
                .with_permission_allow("Bash(cargo update:*)")
                .with_permission_allow("Bash(cat:*)")
                .with_permission_allow("Bash(cue export:*)")
                .with_permission_allow("Bash(cue vet:*)")
                .with_permission_allow("Bash(curl:*)")
                .with_permission_allow("Bash(find:*)")
                .with_permission_allow("Bash(gh pr list:*)")
                .with_permission_allow("Bash(git add:*)")
                .with_permission_allow("Bash(git branch --show-current)")
                .with_permission_allow("Bash(git remote get-url:*)")
                .with_permission_allow("Bash(go build:*)")
                .with_permission_allow("Bash(go list:*)")
                .with_permission_allow("Bash(go mod tidy:*)")
                .with_permission_allow("Bash(go test:*)")
                .with_permission_allow("Bash(go version:*)")
                .with_permission_allow("Bash(go vet:*)")
                .with_permission_allow("Bash(gofmt:*)")
                .with_permission_allow("Bash(grep:*)")
                .with_permission_allow("Bash(make build:*)")
                .with_permission_allow("Bash(make lint:*)")
                .with_permission_allow("Bash(make test:*)")
                .with_permission_allow("Bash(make:*)")
                .with_permission_allow("Bash(sort:*)")
                .with_permission_allow("Bash(tar:*)")
                .with_permission_allow("Bash(test:*)")
                .with_permission_allow("Bash(tree:*)")
                .with_permission_allow("Bash(vorpal build:*)")
                .with_permission_allow("Bash(vorpal inspect:*)")
                .with_permission_allow("Bash(wc:*)")
                .with_permission_allow("Bash(xargs:*)")
                .with_permission_allow("WebFetch(domain:crates.io)")
                .with_permission_allow("WebFetch(domain:github.com)")
                .with_permission_allow("WebSearch")
                .with_permission_allow("mcp__linear-server__create_attachment")
                .with_permission_allow("mcp__linear-server__create_comment")
                .with_permission_allow("mcp__linear-server__create_document")
                .with_permission_allow("mcp__linear-server__create_issue")
                .with_permission_allow("mcp__linear-server__create_issue_label")
                .with_permission_allow("mcp__linear-server__create_milestone")
                .with_permission_allow("mcp__linear-server__create_project")
                .with_permission_allow("mcp__linear-server__delete_attachment")
                .with_permission_allow("mcp__linear-server__extract_images")
                .with_permission_allow("mcp__linear-server__get_attachment")
                .with_permission_allow("mcp__linear-server__get_document")
                .with_permission_allow("mcp__linear-server__get_issue")
                .with_permission_allow("mcp__linear-server__get_issue_status")
                .with_permission_allow("mcp__linear-server__get_milestone")
                .with_permission_allow("mcp__linear-server__get_project")
                .with_permission_allow("mcp__linear-server__get_team")
                .with_permission_allow("mcp__linear-server__get_user")
                .with_permission_allow("mcp__linear-server__list_comments")
                .with_permission_allow("mcp__linear-server__list_cycles")
                .with_permission_allow("mcp__linear-server__list_documents")
                .with_permission_allow("mcp__linear-server__list_issue_labels")
                .with_permission_allow("mcp__linear-server__list_issue_statuses")
                .with_permission_allow("mcp__linear-server__list_issues")
                .with_permission_allow("mcp__linear-server__list_milestones")
                .with_permission_allow("mcp__linear-server__list_project_labels")
                .with_permission_allow("mcp__linear-server__list_projects")
                .with_permission_allow("mcp__linear-server__list_teams")
                .with_permission_allow("mcp__linear-server__list_users")
                .with_permission_allow("mcp__linear-server__search_documentation")
                .with_permission_allow("mcp__linear-server__update_document")
                .with_permission_allow("mcp__linear-server__update_issue")
                .with_permission_allow("mcp__linear-server__update_milestone")
                .with_permission_allow("mcp__linear-server__update_project")
                .with_permission_deny("Read(./**/*.key)")
                .with_permission_deny("Read(./**/*.pem)")
                .with_permission_deny("Read(./.env)")
                .with_permission_deny("Read(./.env*)")
                .with_permission_deny("Read(./.secrets/**)")
                .with_permission_deny("Read(./secrets/**)")
                .with_permission_default_mode("acceptEdits")
                .with_status_line("bash ~/.claude/statusline.sh")
                .with_status_line_padding(2)
                .build(context)
                .await?;
        let claude_code_config_path = format!(
            "{}/{claude_code_config_name}",
            get_output_path("library", &claude_code_config)
        );

        let opencode_config_name = format!("{}-opencode", &self.name);
        let opencode_config = Opencode::new(opencode_config_name.as_str(), self.systems.clone())
            .with_schema("https://opencode.ai/config.json")
            .with_autoupdate(AutoUpdate::Boolean(false))
            .with_bash_permissions(vec![
                ("*", PermissionAction::Ask),
                ("cat*", PermissionAction::Allow),
                ("echo*", PermissionAction::Allow),
                ("file*", PermissionAction::Allow),
                ("find*", PermissionAction::Allow),
                ("git branch*", PermissionAction::Allow),
                ("git log*", PermissionAction::Allow),
                ("grep*", PermissionAction::Allow),
                ("head*", PermissionAction::Allow),
                ("ls*", PermissionAction::Allow),
                ("sort*", PermissionAction::Allow),
                ("test*", PermissionAction::Allow),
                ("tree*", PermissionAction::Allow),
                ("wc*", PermissionAction::Allow),
            ])
            .with_permission_edit(PermissionRule::Simple(PermissionAction::Ask))
            .with_permission_glob(PermissionRule::Simple(PermissionAction::Allow))
            .with_permission_list(PermissionRule::Simple(PermissionAction::Allow))
            .with_permission_lsp(PermissionRule::Simple(PermissionAction::Allow))
            .with_permission_read(PermissionRule::Simple(PermissionAction::Allow))
            .with_permission_webfetch(PermissionAction::Allow)
            .with_theme("tokyonight")
            .build(context)
            .await?;
        let opencode_config_path = format!(
            "{}/{opencode_config_name}",
            get_output_path("library", &opencode_config)
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

        // Claude agents directory
        let claude_agents_name = format!("{}-claude-agents", &self.name);
        let claude_agents = FileSource::new(&claude_agents_name, "agents", self.systems.clone())
            .build(context)
            .await?;
        let claude_agents_path = get_output_path("library", &claude_agents);

        // Claude skills directory
        let claude_skills_name = format!("{}-claude-skills", &self.name);
        let claude_skills = FileSource::new(&claude_skills_name, "skills", self.systems.clone())
            .build(context)
            .await?;
        let claude_skills_path = get_output_path("library", &claude_skills);

        // User environment

        artifact::UserEnvironment::new(&self.name, self.systems)
            .with_artifacts(vec![
                // Dependencies
                awscli2,
                bat,
                direnv,
                doppler,
                fd,
                gh,
                git,
                gopls,
                jj,
                jq,
                k9s,
                kubectl,
                lazygit,
                nnn,
                ripgrep,
                tmux,
                // Dependencies configurations
                bat_config,
                bat_theme,
                claude_agents,
                claude_code_config,
                claude_skills,
                claude_statusline,
                ghostty_config,
                k9s_skin_config,
                markdown_vim_config,
                opencode_config,
            ])
            .with_environments(vec![
                "EDITOR=nvim".to_string(),
                "GOPATH=$HOME/Development/language/go".to_string(),
                "PATH=/Applications/VMware\\ Fusion.app/Contents/Library:$GOPATH/bin:$HOME/.opencode/bin:$HOME/.vorpal/bin:$HOME/.local/bin:$PATH".to_string(),
            ])
            .with_symlinks(vec![
                ("$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal", "$HOME/.vorpal/bin/vorpal"),
                (bat_config_path.as_str(), "$HOME/.config/bat/config"),
                (bat_theme_path.as_str(), "$HOME/.config/bat/themes/tokyonight.tmTheme"),
                (claude_agents_path.as_str(), "$HOME/.claude/agents"),
                (claude_code_config_path.as_str(), "$HOME/.claude/settings.json"),
                (claude_skills_path.as_str(), "$HOME/.claude/skills"),
                (claude_statusline_path.as_str(), "$HOME/.claude/statusline.sh"),
                (ghosty_config_path.as_str(), "$HOME/Library/Application\\ Support/com.mitchellh.ghostty/config"),
                (k9s_skin_config_path.as_str(), "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml"),
                (markdown_vim_config_path.as_str(), "$HOME/.config/nvim/after/ftplugin/markdown.vim"),
                (opencode_config_path.as_str(), "$HOME/.config/opencode/opencode.json"),
            ])
            .build(context)
            .await
    }
}
