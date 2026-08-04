use crate::file::FileCreate;
use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

struct GhosttyConfig {
    background_opacity: f32,
    font_family: String,
    font_size: u8,
    macos_option_as_alt: bool,
    name: String,
    systems: Vec<ArtifactSystem>,
    theme: String,
}

pub struct Ghostty {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl GhosttyConfig {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            background_opacity: 1.0,
            font_family: "".to_string(),
            font_size: 13,
            macos_option_as_alt: false,
            name: name.to_string(),
            systems,
            theme: "tokyonight".to_string(),
        }
    }

    pub fn with_background_opacity(mut self, opacity: f32) -> Self {
        self.background_opacity = opacity;
        self
    }

    pub fn with_font_family(mut self, family: &str) -> Self {
        self.font_family = family.to_string();
        self
    }

    pub fn with_font_size(mut self, size: u8) -> Self {
        self.font_size = size;
        self
    }

    pub fn with_macos_option_as_alt(mut self, as_alt: bool) -> Self {
        self.macos_option_as_alt = as_alt;
        self
    }

    pub fn with_theme(mut self, theme: &str) -> Self {
        self.theme = theme.to_string();
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let content = formatdoc! {"
            background-opacity = {background_opacity}
            font-family = {font_family}
            font-size = {font_size}
            macos-option-as-alt = {macos_option_as_alt}
            theme = {theme}
        ",
            background_opacity = self.background_opacity,
            font_family = self.font_family.as_str(),
            font_size = self.font_size,
            macos_option_as_alt = self.macos_option_as_alt,
            theme = self.theme
        };

        FileCreate::new(
            &format!("{}-ghostty-config", self.name),
            self.systems,
            content.as_str(),
        )
        .build(context)
        .await
    }
}

impl Ghostty {
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
        let mut artifacts = vec![];

        let config = GhosttyConfig::new(&self.name, self.systems.clone())
            .with_background_opacity(0.95)
            .with_font_family("GeistMono NFM")
            .with_font_size(16)
            .with_macos_option_as_alt(true)
            .with_theme("TokyoNight")
            .build(context)
            .await?;

        let symlinks = vec![(
            format!("{}/{}-ghostty-config", get_env_key(&config), self.name),
            "${HOME}/Library/Application\\ Support/com.mitchellh.ghostty/config".to_string(),
        )];

        artifacts.push(config);

        Ok((artifacts, symlinks))
    }
}
