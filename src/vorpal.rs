use anyhow::Result;
use vorpal_sdk::{
    api::artifact::{
        ArtifactSystem,
        ArtifactSystem::{Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux},
    },
    artifact::{get_env_key, gh, protoc, rust_toolchain, script},
    context::get_context,
};

const SYSTEMS: [ArtifactSystem; 4] = [Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux];

#[tokio::main]
async fn main() -> Result<()> {
    let context = &mut get_context().await?;

    // Dependencies

    let gh = gh::build(context).await?;
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

    // Artifacts

    script::devenv(
        context,
        vec![protoc, rust_toolchain.clone()],
        vec![
            format!("PATH={}", rust_toolchain_bin),
            format!("RUSTUP_HOME={}", get_env_key(&rust_toolchain)),
            format!("RUSTUP_TOOLCHAIN={}", rust_toolchain_name),
        ],
        "devenv",
        vec![],
        SYSTEMS.to_vec(),
    )
    .await?;

    script::userenv(
        context,
        vec![gh],
        vec![],
        "userenv",
        vec![],
        SYSTEMS.to_vec(),
    )
    .await?;

    context.run().await
}
