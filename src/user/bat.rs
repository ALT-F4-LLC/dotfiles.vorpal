use crate::file::{FileCreate, FileSource};
use anyhow::Result;
use vorpal_artifacts::artifact::bat;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

struct BatConfig {
    name: String,
    systems: Vec<ArtifactSystem>,
    theme: Option<String>,
}

struct BatTheme {
    name: String,
    path: String,
    systems: Vec<ArtifactSystem>,
}

pub struct Bat {
    name: String,
    systems: Vec<ArtifactSystem>,
    theme: Option<String>,
}

impl Bat {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
            theme: None,
        }
    }

    pub fn with_theme(mut self, theme: &str) -> Self {
        self.theme = Some(theme.to_string());
        self
    }

    pub async fn build(
        self,
        context: &mut ConfigContext,
    ) -> Result<(Vec<String>, Vec<(String, String)>)> {
        let mut artifacts = vec![];
        let mut symlinks = vec![];

        let mut config_builder = BatConfig::new(&self.name, self.systems.clone());

        if let Some(theme_name) = self.theme {
            let config_theme_path = "https://raw.githubusercontent.com/folke/tokyonight.nvim/refs/tags/v4.14.1/extras/sublime/tokyonight_night.tmTheme";
            let config_theme = BatTheme::new(&self.name, config_theme_path, self.systems.clone())
                .build(context)
                .await?;

            artifacts.push(config_theme.clone());

            config_builder = config_builder.with_theme(&theme_name);

            symlinks.push((
                format!("{}/tokyonight_night.tmTheme", get_env_key(&config_theme)),
                "${HOME}/.config/bat/themes/tokyonight.tmTheme".to_string(),
            ));
        }

        let binary = bat::Bat::new().build(context).await?;
        let config = config_builder.build(context).await?;

        symlinks.push((
            format!("{}/{}-bat-config", get_env_key(&config), self.name),
            "${HOME}/.config/bat/config".to_string(),
        ));

        artifacts.push(binary);
        artifacts.push(config);

        Ok((artifacts, symlinks))
    }
}

impl BatConfig {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
            theme: None,
        }
    }

    pub fn with_theme(mut self, theme: &str) -> Self {
        self.theme = Some(theme.to_string());
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let mut content = String::new();

        if let Some(theme) = self.theme {
            let content_theme = format!("--theme={theme}");

            content.push_str(&content_theme);
        }

        FileCreate::new(&format!("{}-bat-config", self.name), self.systems, &content)
            .build(context)
            .await
    }
}

impl BatTheme {
    pub fn new(name: &str, path: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            path: path.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        FileSource::new(
            &format!("{}-bat-theme", &self.name),
            &self.path,
            self.systems.clone(),
        )
        .build(context)
        .await
    }
}
