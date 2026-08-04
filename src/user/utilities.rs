use anyhow::Result;
use vorpal_artifacts::artifact::{
    awscli2::Awscli2, delta::Delta, direnv::Direnv, doppler::Doppler, fd::Fd, fzf::Fzf, gum::Gum,
    herdr::Herdr, hunk::Hunk, jj::Jj, jq::Jq, just::Just, kubectl::Kubectl, lazygit::Lazygit,
    nnn::Nnn, op::Op, pi::Pi, ripgrep::Ripgrep, sesh::Sesh, starship::Starship,
    terraform::Terraform, tmux::Tmux, zoxide::Zoxide,
};
use vorpal_sdk::{
    artifact::{gh::Gh, git::Git, nodejs::NodeJS},
    context::ConfigContext,
};

pub async fn build(context: &mut ConfigContext) -> Result<Vec<String>> {
    let harnesses = vec![Pi::new().build(context).await?];

    let languages = vec![NodeJS::new().build(context).await?];

    let providers = vec![
        Awscli2::new().build(context).await?,
        Doppler::new().build(context).await?,
        Gh::new().build(context).await?,
        Kubectl::new().build(context).await?,
        Op::new().build(context).await?,
        Terraform::new().build(context).await?,
    ];

    let utilities = vec![
        Delta::new().build(context).await?,
        Direnv::new().build(context).await?,
        Fd::new().build(context).await?,
        Fzf::new().build(context).await?,
        Git::new().build(context).await?,
        Gum::new().build(context).await?,
        Herdr::new().build(context).await?,
        Hunk::new().build(context).await?,
        Jj::new().build(context).await?,
        Jq::new().build(context).await?,
        Just::new().build(context).await?,
        Lazygit::new().build(context).await?,
        Nnn::new().build(context).await?,
        Ripgrep::new().build(context).await?,
        Sesh::new().build(context).await?,
        Starship::new().build(context).await?,
        Tmux::new().build(context).await?,
        Zoxide::new().build(context).await?,
    ];

    Ok(harnesses
        .into_iter()
        .chain(languages)
        .chain(providers)
        .chain(utilities)
        .collect())
}
