use anyhow::Result;
use dotfiles::{user::UserEnvironment, SYSTEMS};
use vorpal_sdk::{artifact::language::rust::RustDevelopmentEnvironment, context::get_context};

#[tokio::main]
async fn main() -> Result<()> {
    let mut context = get_context().await?;

    RustDevelopmentEnvironment::new("dev", SYSTEMS.to_vec())
        .build(&mut context)
        .await?;

    UserEnvironment::new("user", SYSTEMS.to_vec())
        .build(&mut context)
        .await?;

    context.run().await
}
