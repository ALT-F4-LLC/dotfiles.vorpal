use crate::file::FileSource;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct Zsh {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Zsh {
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
        // The tracked files are the source of truth: aliases and functions
        // are edited in src/user/zsh/.zshrc and shipped verbatim. A source
        // copy, not a generated file, because the kindc function carries its
        // own EOF line, which would end a heredoc-based file step early.
        let config = FileSource::new(&format!("{}-zsh", self.name), "src/user/zsh", self.systems)
            .build(context)
            .await?;

        let symlinks = vec![
            (
                format!("{}/.zprofile", get_env_key(&config)),
                "${HOME}/.zprofile".to_string(),
            ),
            (
                format!("{}/.zshrc", get_env_key(&config)),
                "${HOME}/.zshrc".to_string(),
            ),
        ];

        Ok((vec![config], symlinks))
    }
}
