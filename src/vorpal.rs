use anyhow::Result;
use dotfiles::{user::UserEnvironment, SYSTEMS};
use vorpal_sdk::{
    artifact::{
        get_env_key, protoc::Protoc, rust_toolchain, rust_toolchain::RustToolchain,
        ProjectEnvironment,
    },
    context::get_context,
};

#[tokio::main]
async fn main() -> Result<()> {
    let context = &mut get_context().await?;

    // Dependencies

    let protoc = Protoc::new().build(context).await?;
    let rust_toolchain = RustToolchain::new().build(context).await?;
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

    ProjectEnvironment::new("dev", SYSTEMS.to_vec())
        .with_artifacts(vec![protoc, rust_toolchain.clone()])
        .with_environments(vec![
            format!("PATH={}", rust_toolchain_bin),
            format!("RUSTUP_HOME={}", get_env_key(&rust_toolchain)),
            format!("RUSTUP_TOOLCHAIN={}", rust_toolchain_name),
        ])
        .build(context)
        .await?;

    UserEnvironment::new("user", SYSTEMS.to_vec())
        .build(context)
        .await?;

    context.run().await
}
