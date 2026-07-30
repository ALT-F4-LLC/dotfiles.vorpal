use crate::{
    file::{FileCreate, FileDownload, FileSource},
    get_output_path,
};
use anyhow::Result;
use bat::BatConfig;
use claude_code::Config as ClaudeCodeConfig;
use ghostty::GhosttyConfig;
use k9s::K9sSkin;
use vorpal_artifacts::artifact::{
    abtop::Abtop, awscli2::Awscli2, bash_language_server::BashLanguageServer, bat::Bat, cue::Cue,
    delta::Delta, direnv::Direnv, doppler::Doppler, fd::Fd, fzf::Fzf, gum::Gum, herdr::Herdr,
    hunk::Hunk, jj::Jj, jq::Jq, just::Just, k9s::K9s, kubectl::Kubectl, lazygit::Lazygit,
    lua_language_server::LuaLanguageServer, neovim::Neovim, nnn::Nnn, op::Op, pi::Pi,
    ripgrep::Ripgrep, sesh::Sesh, starship::Starship, terraform::Terraform, tmux::Tmux,
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
mod ghostty;
mod k9s;

const OTEL_LOGS_ENDPOINT_LOKI: &str = "https://loki.bulbasaur.altf4.domains/otlp/v1/logs";
const OTEL_METRICS_ENDPOINT_MIMIR: &str = "https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics";
const OTEL_OTLP_PROTOCOL: &str = "http/protobuf";

const SENSITIVE_PATHS: &[&str] = &[
    "/Applications/**",
    "/Library/**",
    "/System/**",
    "~/.claude.json",
    "~/.doppler/**",
    "~/.gemini/**",
    "~/.gnupg/**",
    // kubeconfig may hold long-lived inline credentials (e.g. Talos-generated), so this stays
    // deny-read rather than allowlisted; kubectl work requires `dangerouslyDisableSandbox=true`.
    "~/.kube/**",
    "~/.netrc",
    "~/.ssh/**",
    "~/.talos/**",
    "~/Desktop/**",
    "~/Downloads/**",
];

const SANDBOX_AGENT_MEMORY_PATH: &str = "~/.claude/agent-memory";
const SANDBOX_DOCS_CACHE_PATH: &str = "~/.claude/cache/docs";
const SANDBOX_DENY_READ_EXCLUDED: &[&str] = &["/Applications/**", "/Library/**", "/System/**"];
const SANDBOX_TOOLCHAIN_CACHE_PATHS: &[&str] = &[
    "~/.cache/uv",
    "~/.cargo/git",
    "~/.cargo/registry",
    "~/Library/Caches/pip",
];
const SENSITIVE_PATHS_DENY_READ_ONLY: &[&str] = &[".env", ".env.*", "~/.aws/**"];

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
            build_claude_code_config(claude_code_config_name.as_str(), self.systems.clone())
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

        // Claude hooks directory
        let claude_hooks_name = format!("{}-claude-code-hooks", &self.name);
        let claude_hooks = FileSource::new(
            &claude_hooks_name,
            "src/user/claude-code/hooks",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let claude_hooks_path = get_output_path("library", &claude_hooks);

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

        // Claude scripts directory
        let claude_scripts_name = format!("{}-claude-code-scripts", &self.name);
        let claude_scripts = FileSource::new(
            &claude_scripts_name,
            "src/user/claude-code/scripts",
            self.systems.clone(),
        )
        .build(context)
        .await?;
        let claude_scripts_path = get_output_path("library", &claude_scripts);

        // User environment

        let claude_agents_path = format!("{claude_agents_path}/src/user/claude-code/agents");
        let claude_hooks_path = format!("{claude_hooks_path}/src/user/claude-code/hooks");
        let claude_scripts_path = format!("{claude_scripts_path}/src/user/claude-code/scripts");
        let claude_skills_path = format!("{claude_skills_path}/src/user/claude-code/skills");

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
                claude_hooks,
                claude_scripts,
                claude_skills,
                claude_statusline,
                ghostty_config,
                k9s_skin_config,
                markdown_vim_config,
            ])
            .with_environments(vec![
                "EDITOR=nvim".to_string(),
                "GOPATH=${HOME}/Development/language/go".to_string(),
                "PATH=/Applications/VMware\\ Fusion.app/Contents/Library:${GOPATH}/bin:${HOME}/.vorpal/bin:${HOME}/.local/bin:${PATH}".to_string(),
            ])
            .with_symlinks(vec![
                (&claude_agents_path, "$HOME/.claude/agents"),
                (&claude_hooks_path, "$HOME/.claude/hooks"),
                (&claude_scripts_path, "$HOME/.claude/scripts"),
                (&claude_skills_path, "$HOME/.claude/skills"),
                (bat_config_path.as_str(), "$HOME/.config/bat/config"),
                (bat_theme_path.as_str(), "$HOME/.config/bat/themes/tokyonight.tmTheme"),
                (claude_code_config_path.as_str(), "$HOME/.claude/settings.json"),
                (claude_statusline_path.as_str(), "$HOME/.claude/statusline.sh"),
                (ghostty_config_path.as_str(), "$HOME/Library/Application\\ Support/com.mitchellh.ghostty/config"),
                (k9s_skin_config_path.as_str(), "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml"),
                (markdown_vim_config_path.as_str(), "$HOME/.config/nvim/after/ftplugin/markdown.vim"),
            ])
            .build(context)
            .await
    }
}

// Builds the production Claude Code config, minus the final `.build(context)` call. Factoring
// this out of `UserEnvironment::build` lets a plain unit test construct and serialize the exact
// same settings offline (no `ConfigContext`/network needed) — the render target `config_render_diff.sh`
// diffs against (see the `tests` module below).
fn build_claude_code_config(name: &str, systems: Vec<ArtifactSystem>) -> ClaudeCodeConfig {
    let claude_code_config = ClaudeCodeConfig::new(name, systems)
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
        .with_env("CLAUDE_CODE_ENABLE_TELEMETRY", "1")
        .with_env("CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1")
        .with_env("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB", "0") // REASON: Must be 0 for 'with_permission_default_mode('auto')'
        .with_env("ANTHROPIC_DEFAULT_FABLE_MODEL", "claude-fable-5")
        .with_env("ANTHROPIC_DEFAULT_HAIKU_MODEL", "claude-haiku-4-5")
        .with_env("ANTHROPIC_DEFAULT_OPUS_MODEL", "claude-opus-5")
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
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/guard-no-commit-hook.sh",
            "command",
        )
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/guard-tmp-write-hook.sh",
            "command",
        )
        .with_hook(
            "TaskCompleted",
            None,
            "bash ~/.claude/hooks/task-completed-hook.sh",
            "command",
        )
        .with_hook(
            "TeammateIdle",
            None,
            "bash ~/.claude/hooks/teammate-idle-hook.sh",
            "command",
        )
        .with_hook(
            "SubagentStop",
            None,
            "bash ~/.claude/hooks/subagent-report-hook.sh",
            "command",
        )
        .with_hook(
            "Stop",
            None,
            "bash ~/.claude/hooks/stop-guard-hook.sh",
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
        .with_permission_ask("Bash(git add:*)")
        .with_permission_ask("Bash(git commit:*)")
        .with_permission_ask("Bash(git push:*)")
        .with_permission_ask("Bash(rm:*)")
        .with_permission_deny("Bash(git checkout:*)")
        .with_permission_deny("Bash(git reset:*)");
    let claude_code_config = deny_sensitive_paths(
        claude_code_config,
        |p| format!("Edit({p})"),
        SENSITIVE_PATHS.iter().copied(),
    );
    let claude_code_config = deny_sensitive_paths(
        claude_code_config,
        |p| format!("Read({p})"),
        SENSITIVE_PATHS
            .iter()
            .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
            .copied(),
    );
    claude_code_config
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
            "xcrun".to_string(),
        ])
        .with_sandbox_filesystem_allow_write(
            SANDBOX_TOOLCHAIN_CACHE_PATHS
                .iter()
                .chain(std::iter::once(&SANDBOX_AGENT_MEMORY_PATH))
                .chain(std::iter::once(&SANDBOX_DOCS_CACHE_PATH))
                .map(|p| p.to_string())
                .collect(),
        )
        .with_sandbox_filesystem_deny_read(sandbox_filesystem_deny_read_paths())
        .with_sandbox_network_allowed_domains(vec![
            "crates.io".to_string(),
            "static.crates.io".to_string(),
            "github.com".to_string(),
            "api.github.com".to_string(),
        ])
        // 1Password requires per-use approval for SSH-agent signing operations, so
        // allowlisting only this socket (not `allow_all_unix_sockets`) keeps that
        // approval prompt as the safety gate for sandboxed `git commit` signing.
        .with_sandbox_network_allow_unix_sockets(vec![
            "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock".to_string(),
        ])
        .with_sandbox_network_allow_local_binding(false)
        .with_teammate_mode("in-process")
        .with_tui("fullscreen")
}

// Applies a `deny` permission rule for each sensitive path, formatted via `wrap` (e.g.
// `Edit({path})`), in sorted order to match the existing deny-list convention.
fn deny_sensitive_paths(
    builder: ClaudeCodeConfig,
    wrap: impl Fn(&str) -> String,
    paths: impl IntoIterator<Item = &'static str>,
) -> ClaudeCodeConfig {
    let mut paths: Vec<&str> = paths.into_iter().collect();
    paths.sort_unstable();
    paths
        .into_iter()
        .fold(builder, |b, p| b.with_permission_deny(&wrap(p)))
}

// Bare-path form (no `Edit(...)`/`Read(...)` wrapper, no `/**` suffix) of every path denied for
// Read, minus `SANDBOX_DENY_READ_EXCLUDED`, for the OS-level sandbox's confidentiality-only
// `with_sandbox_filesystem_deny_read`.
fn sandbox_filesystem_deny_read_paths() -> Vec<String> {
    let mut paths: Vec<String> = SENSITIVE_PATHS
        .iter()
        .chain(SENSITIVE_PATHS_DENY_READ_ONLY)
        .filter(|p| !SANDBOX_DENY_READ_EXCLUDED.contains(p))
        .map(|p| p.strip_suffix("/**").unwrap_or(p).to_string())
        .collect();
    paths.sort_unstable();
    paths
}

#[cfg(test)]
mod tests {
    use super::*;

    // Render target for `config_render_diff.sh` (DKT-94): prints the exact production Claude
    // Code config's rendered JSON, so a git-worktree byte-diff catches setter changes to
    // `build_claude_code_config` that don't actually change the serialized output. Run via:
    //   cargo test --lib user::tests::prints_rendered_claude_code_config -- --nocapture
    #[test]
    fn prints_rendered_claude_code_config() {
        let content =
            serde_json::to_string_pretty(&build_claude_code_config("claude-code", Vec::new()))
                .expect("claude code config should serialize to JSON");

        println!("{content}");
    }

    #[test]
    fn claude_code_config_serializes_current_settings() {
        let content =
            serde_json::to_string_pretty(&build_claude_code_config("claude-code", Vec::new()))
                .expect("claude code config should serialize to JSON");

        assert!(content.contains("\"model\": \"claude-sonnet-5\""));
        assert!(content.contains("\"defaultMode\": \"auto\""));
        assert!(content.contains("\"tui\": \"fullscreen\""));
    }
}
