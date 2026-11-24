use crate::file::FileCreate;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct Rex {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Rex {
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
            &format!("{}-rex-config", self.name),
            self.systems,
            include_str!("rex/init.lua"),
        )
        .build(context)
        .await?;

        let symlinks = vec![(
            format!("{}/{}-rex-config", get_env_key(&config), self.name),
            "${HOME}/.config/rex/init.lua".to_string(),
        )];

        Ok((vec![config], symlinks))
    }
}
