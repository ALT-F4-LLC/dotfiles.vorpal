use crate::{make, SYSTEMS};
use anyhow::Result;
use ghostty_config::GhosttyConfigBuilder;
use indoc::formatdoc;
use vorpal_sdk::{
    artifact::{gh, userenv::UserenvBuilder},
    context::ConfigContext,
};

mod ghostty_config;

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

    let k9s_skin = make::build_file(
        context,
        "k9s-skin",
        formatdoc! {"
            # Styles...
            foreground: &foreground \"#f8f8f2\"
            background: &background \"default\"
            current_line: &current_line \"#44475a\"
            selection: &selection \"#44475a\"
            comment: &comment \"#6272a4\"
            cyan: &cyan \"#8be9fd\"
            green: &green \"#50fa7b\"
            orange: &orange \"#ffb86c\"
            pink: &pink \"#ff79c6\"
            purple: &purple \"#bd93f9\"
            red: &red \"#ff5555\"
            yellow: &yellow \"#f1fa8c\"

            # Skin...
            k9s:
              # General K9s styles
              body:
                fgColor: *foreground
                bgColor: *background
                logoColor: *purple
              # Command prompt styles
              prompt:
                fgColor: *foreground
                bgColor: *background
                suggestColor: *purple
              # ClusterInfoView styles.
              info:
                fgColor: *pink
                sectionColor: *foreground
              # Dialog styles.
              dialog:
                fgColor: *foreground
                bgColor: *background
                buttonFgColor: *foreground
                buttonBgColor: *purple
                buttonFocusFgColor: *yellow
                buttonFocusBgColor: *pink
                labelFgColor: *orange
                fieldFgColor: *foreground
              frame:
                # Borders styles.
                border:
                  fgColor: *selection
                  focusColor: *current_line
                menu:
                  fgColor: *foreground
                  keyColor: *pink
                  # Used for favorite namespaces
                  numKeyColor: *pink
                # CrumbView attributes for history navigation.
                crumbs:
                  fgColor: *foreground
                  bgColor: *current_line
                  activeColor: *current_line
                # Resource status and update styles
                status:
                  newColor: *cyan
                  modifyColor: *purple
                  addColor: *green
                  errorColor: *red
                  highlightcolor: *orange
                  killColor: *comment
                  completedColor: *comment
                # Border title styles.
                title:
                  fgColor: *foreground
                  bgColor: *current_line
                  highlightColor: *orange
                  counterColor: *purple
                  filterColor: *pink
              views:
                # Charts skins...
                charts:
                  bgColor: default
                  defaultDialColors:
                    - *purple
                    - *red
                  defaultChartColors:
                    - *purple
                    - *red
                # TableView attributes.
                table:
                  fgColor: *foreground
                  bgColor: *background
                  cursorFgColor: *foreground
                  cursorBgColor: *current_line
                  # Header row styles.
                  header:
                    fgColor: *foreground
                    bgColor: *background
                    sorterColor: *cyan
                # Xray view attributes.
                xray:
                  fgColor: *foreground
                  bgColor: *background
                  cursorColor: *current_line
                  graphicColor: *purple
                  showIcons: false
                # YAML info styles.
                yaml:
                  keyColor: *pink
                  colonColor: *purple
                  valueColor: *foreground
                # Logs styles.
                logs:
                  fgColor: *foreground
                  bgColor: *background
                  indicator:
                    fgColor: *foreground
                    bgColor: *purple
        "}
        .as_str(),
    )
    .await?;

    let markdown_vim = make::build_file(
        context,
        "markdown-vim",
        formatdoc! {"
            setlocal wrap
        "}
        .as_str(),
    )
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
            (
                ghosty_config_path.as_str(),
                "$HOME/.config/ghostty/config",
            ),
            (
                k9s_skin_path.as_str(),
                "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml",
            ),
            (
                markdown_vim_path.as_str(),
                "$HOME/.config/nvim/after/ftplugin/markdown.vim",
            ),
            (
                "$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal",
                "$HOME/.vorpal/bin/vorpal",
            ),
        ])
        .build(context)
        .await
}
