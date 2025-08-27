use crate::SYSTEMS;
use anyhow::Result;
use vorpal_sdk::{
    artifact::{devenv::DevenvBuilder, get_env_key, protoc, rust_toolchain},
    context::ConfigContext,
};

pub async fn build(context: &mut ConfigContext) -> Result<String> {
    // Dependencies

    let protoc = protoc::build(context).await?;
    let rust_toolchain = rust_toolchain::build(context).await?;

    // Environments

    let rust_toolchain_target = rust_toolchain::target(context.get_system())?;
    let rust_toolchain_version = rust_toolchain::version();
    let rust_toolchain_name = format!("{}-{}", rust_toolchain_version, rust_toolchain_target);
    let rust_toolchain_bin = format!(
        "{}/toolchains/{}/bin",
        get_env_key(&rust_toolchain),
        rust_toolchain_name
    );

    // Artifact

    DevenvBuilder::new("devenv", SYSTEMS.to_vec())
        .with_artifacts(vec![protoc, rust_toolchain.clone()])
        .with_environments(vec![
            format!("PATH={}", rust_toolchain_bin),
            format!("RUSTUP_HOME={}", get_env_key(&rust_toolchain)),
            format!("RUSTUP_TOOLCHAIN={}", rust_toolchain_name),
        ])
        .build(context)
        .await
}
