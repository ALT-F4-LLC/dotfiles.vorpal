use crate::file::FileCreate;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct Go {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Go {
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
        // Go consults this file (`go env GOENV`) on EVERY invocation, shell or
        // not. The GOPATH shell export in user.rs reaches only processes
        // descended from a profile-sourcing shell; anything else — a daemon's
        // subprocess, an engine gate — silently falls back to ~/go and
        // resolves the wrong module cache (DOT-329). Env files expand no
        // variables, so the value must be the literal absolute path: resolved
        // from the invoking user's HOME when this config is evaluated.
        let home = std::env::var("HOME")?;
        let content = format!("GOPATH={home}/Development/language/go");

        let env = FileCreate::new(&format!("{}-go-env", self.name), self.systems, &content)
            .build(context)
            .await?;

        let symlinks = vec![(
            format!("{}/{}-go-env", get_env_key(&env), self.name),
            "$HOME/Library/Application\\ Support/go/env".to_string(),
        )];

        Ok((vec![env], symlinks))
    }
}
