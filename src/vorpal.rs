use anyhow::Result;
use dotfiles::{user::UserEnvironment, SYSTEMS};
use vorpal_sdk::{artifact::language::rust::RustDevelopmentEnvironment, context::get_context};

#[tokio::main]
async fn main() -> Result<()> {
    let context = &mut get_context().await?;

    RustDevelopmentEnvironment::new("dev", SYSTEMS.to_vec())
        .build(context)
        .await?;

    UserEnvironment::new("user", SYSTEMS.to_vec())
        .build(context)
        .await?;

    context.run().await
}
