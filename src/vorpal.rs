use anyhow::Result;
use dotfiles::{dev::ProjectEnvironment, user::UserEnvironment, SYSTEMS};
use vorpal_sdk::context::get_context;

#[tokio::main]
async fn main() -> Result<()> {
    let context = &mut get_context().await?;

    ProjectEnvironment::new("dev", SYSTEMS.to_vec())
        .build(context)
        .await?;

    UserEnvironment::new("user", SYSTEMS.to_vec())
        .build(context)
        .await?;

    context.run().await
}
