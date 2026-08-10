use crate::file::{FileCreate, FileSource};
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
        let contracts = FileSource::new(
            &format!("{}-docket-contracts", self.name),
            "src/user/docket/contracts",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let fragments = FileSource::new(
            &format!("{}-docket-fragments", self.name),
            "src/user/docket/fragments",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let policy = FileCreate::new(
            &format!("{}-docket-policy", self.name),
            self.systems.clone(),
            include_str!("docket/policy.toml"),
        )
        .build(context)
        .await?;

        let schemas = FileSource::new(
            &format!("{}-docket-schemas", self.name),
            "src/user/docket/schemas",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let workflows = FileSource::new(
            &format!("{}-docket-workflows", self.name),
            "src/user/docket/workflows",
            self.systems,
        )
        .build(context)
        .await?;

        let symlinks = vec![
            (
                get_env_key(&contracts),
                "${HOME}/.docket/contracts".to_string(),
            ),
            (
                get_env_key(&fragments),
                "${HOME}/.docket/fragments".to_string(),
            ),
            (
                format!("{}/{}-docket-policy", get_env_key(&policy), self.name),
                "${HOME}/.docket/policy.toml".to_string(),
            ),
            (get_env_key(&schemas), "${HOME}/.docket/schemas".to_string()),
            (
                get_env_key(&workflows),
                "${HOME}/.docket/workflows".to_string(),
            ),
        ];

        let artifacts = vec![contracts, fragments, policy, schemas, workflows];

        Ok((artifacts, symlinks))
    }
}
