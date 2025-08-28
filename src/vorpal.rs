use anyhow::Result;
use dotfiles::{dev::DevEnvBuilder, user::UserEnvBuilder, SYSTEMS};
use vorpal_sdk::context::get_context;

#[tokio::main]
async fn main() -> Result<()> {
    let context = &mut get_context().await?;

    DevEnvBuilder::new("dev", SYSTEMS.to_vec())
        .build(context)
        .await?;

    UserEnvBuilder::new("user", SYSTEMS.to_vec())
        .build(context)
        .await?;

    context.run().await
}
