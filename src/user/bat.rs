use crate::file::FileCreate;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, context::ConfigContext};

pub struct BatConfig {
    name: String,
    systems: Vec<ArtifactSystem>,
    theme: Option<String>,
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

        FileCreate::new(content.as_str(), &self.name, self.systems)
            .build(context)
            .await
    }
}
