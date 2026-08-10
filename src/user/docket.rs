use crate::file::FileSource;
use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact::get_env_key, context::ConfigContext};

pub struct Docket {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Docket {
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
        // One artifact holding the whole shared corpus. The source tree
        // mirrors the installed tree: config/{contracts,fragments,schemas,
        // workflows,policy.toml} is what the engine scans as its shared
        // config root, and bin/ holds the corpus-shipped action scripts
        // trust entries bind to at their absolute ~/.docket path. The
        // engine canonicalizes the config-root symlink before walking, so
        // everything behind it must be real files — one merged artifact,
        // not per-entry links.
        let corpus = FileSource::new(
            &format!("{}-docket", self.name),
            "src/user/docket",
            self.systems,
        )
        .build(context)
        .await?;

        let symlinks = vec![
            (
                format!("{}/bin", get_env_key(&corpus)),
                "${HOME}/.docket/bin".to_string(),
            ),
            (
                format!("{}/config", get_env_key(&corpus)),
                "${HOME}/.docket/config".to_string(),
            ),
        ];

        Ok((vec![corpus], symlinks))
    }
}
