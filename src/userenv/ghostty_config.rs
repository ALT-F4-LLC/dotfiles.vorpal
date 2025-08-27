use crate::make;
use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::context::ConfigContext;

pub struct GhosttyConfigBuilder {
    background_opacity: f32,
    font_family: String,
    font_size: u8,
    macos_option_as_alt: bool,
    name: String,
    theme: String,
}

impl GhosttyConfigBuilder {
    pub fn new(name: &str) -> Self {
        Self {
            background_opacity: 1.0,
            font_family: "".to_string(),
            font_size: 13,
            macos_option_as_alt: false,
            name: name.to_string(),
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
        make::build_file(
            context,
            &self.name,
            formatdoc! {"
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
            }
            .as_str(),
        )
        .await
    }
}
