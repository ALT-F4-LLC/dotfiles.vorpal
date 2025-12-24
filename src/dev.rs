use anyhow::Result;
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact,
    artifact::{get_env_key, protoc, rust_toolchain},
    context::ConfigContext,
};

pub struct ProjectEnvironment {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl ProjectEnvironment {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        ProjectEnvironment {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        // Dependencies

        let protoc = protoc::build(context).await?;
        let rust_toolchain = rust_toolchain::build(context).await?;
        let rust_toolchain_target = rust_toolchain::target(context.get_system())?;
        let rust_toolchain_version = rust_toolchain::version();

        // Environment variables

        let rust_toolchain_name = format!("{}-{}", rust_toolchain_version, rust_toolchain_target);
        let rust_toolchain_bin = format!(
            "{}/toolchains/{}/bin",
            get_env_key(&rust_toolchain),
            rust_toolchain_name
        );

        // Artifact

        artifact::ProjectEnvironment::new(&self.name, self.systems)
            .with_artifacts(vec![protoc, rust_toolchain.clone()])
            .with_environments(vec![
                format!("PATH={}", rust_toolchain_bin),
                format!("RUSTUP_HOME={}", get_env_key(&rust_toolchain)),
                format!("RUSTUP_TOOLCHAIN={}", rust_toolchain_name),
            ])
            .build(context)
            .await
    }
}
