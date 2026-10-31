use crate::file::FileCreate;
use anyhow::Result;
use indoc::formatdoc;
use vorpal_artifacts::artifact::k9s;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct K9s {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl K9s {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(
        self,
        context: &mut ConfigContext,
    ) -> Result<(Vec<String>, Vec<(String, String)>)> {
        let mut artifacts = vec![k9s::K9s::new().build(context).await?];

        // Define TokyoNight color palette
        let theme_background = "default";
        let theme_comment = "#6272a4";
        let theme_current_line = "#44475a";
        let theme_cyan = "#8be9fd";
        let theme_foreground = "#f8f8f2";
        let theme_green = "#50fa7b";
        let theme_orange = "#ffb86c";
        let theme_pink = "#ff79c6";
        let theme_purple = "#bd93f9";
        let theme_red = "#ff5555";
        let theme_selection = "#44475a";
        let theme_yellow = "#f1fa8c";

        let content = formatdoc! {r#"
            k9s:
              # General K9s styles
              body:
                fgColor: '{theme_foreground}'
                bgColor: '{theme_background}'
                logoColor: '{theme_purple}'
              prompt:
                fgColor: '{theme_foreground}'
                bgColor: '{theme_background}'
                suggestColor: '{theme_purple}'
              info:
                fgColor: '{theme_pink}'
                sectionColor: '{theme_foreground}'
              dialog:
                fgColor: '{theme_foreground}'
                bgColor: '{theme_background}'
                buttonFgColor: '{theme_foreground}'
                buttonBgColor: '{theme_purple}'
                buttonFocusFgColor: '{theme_yellow}'
                buttonFocusBgColor: '{theme_pink}'
                labelFgColor: '{theme_orange}'
                fieldFgColor: '{theme_foreground}'
              frame:
                border:
                  fgColor: '{theme_selection}'
                  focusColor: '{theme_current_line}'
                menu:
                  fgColor: '{theme_foreground}'
                  keyColor: '{theme_pink}'
                  numKeyColor: '{theme_pink}'
                crumbs:
                  fgColor: '{theme_foreground}'
                  bgColor: '{theme_current_line}'
                  activeColor: '{theme_current_line}'
                status:
                  newColor: '{theme_cyan}'
                  modifyColor: '{theme_purple}'
                  addColor: '{theme_green}'
                  errorColor: '{theme_red}'
                  highlightcolor: '{theme_orange}'
                  killColor: '{theme_comment}'
                  completedColor: '{theme_comment}'
                title:
                  fgColor: '{theme_foreground}'
                  bgColor: '{theme_current_line}'
                  highlightColor: '{theme_orange}'
                  counterColor: '{theme_purple}'
                  filterColor: '{theme_pink}'
              views:
                charts:
                  bgColor: '{theme_background}'
                  defaultDialColors:
                    - '{theme_purple}'
                    - '{theme_red}'
                  defaultChartColors:
                    - '{theme_purple}'
                    - '{theme_red}'
                table:
                  fgColor: '{theme_foreground}'
                  bgColor: '{theme_background}'
                  cursorFgColor: '{theme_foreground}'
                  cursorBgColor: '{theme_current_line}'
                  header:
                    fgColor: '{theme_foreground}'
                    bgColor: '{theme_background}'
                    sorterColor: '{theme_cyan}'
                xray:
                  fgColor: '{theme_foreground}'
                  bgColor: '{theme_background}'
                  cursorColor: '{theme_current_line}'
                  graphicColor: '{theme_purple}'
                  showIcons: false
                yaml:
                  keyColor: '{theme_pink}'
                  colonColor: '{theme_purple}'
                  valueColor: '{theme_foreground}'
                logs:
                  fgColor: '{theme_foreground}'
                  bgColor: '{theme_background}'
                  indicator:
                    fgColor: '{theme_foreground}'
                    bgColor: '{theme_purple}'
            "#
        };

        let theme = FileCreate::new(&format!("{}-k9s-theme", self.name), self.systems, &content)
            .build(context)
            .await?;

        let symlinks = vec![(
            format!("{}/{}-k9s-theme", get_env_key(&theme), self.name),
            "$HOME/Library/Application\\ Support/k9s/skins/tokyo_night.yaml".to_string(),
        )];

        artifacts.push(theme);

        Ok((artifacts, symlinks))
    }
}
