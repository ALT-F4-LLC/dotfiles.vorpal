use crate::file::FileCreate;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct Git {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Git {
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
        let config = FileCreate::new(
            &format!("{}-git-config", self.name),
            self.systems,
            include_str!("git/config"),
        )
        .build(context)
        .await?;

        let symlinks = vec![(
            format!("{}/{}-git-config", get_env_key(&config), self.name),
            "${HOME}/.config/git/config".to_string(),
        )];

        Ok((vec![config], symlinks))
    }
}
