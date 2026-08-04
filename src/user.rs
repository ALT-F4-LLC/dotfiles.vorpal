use anyhow::Result;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact, context::ConfigContext};

mod bat;
mod claude_code;
mod claude_code_settings;
mod ghostty;
mod k9s;
mod neovim;
mod utilities;

pub struct UserEnvironment {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl UserEnvironment {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        UserEnvironment {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let binaries = utilities::build(context).await?;

        let bat = bat::Bat::new(&self.name, self.systems.clone())
            .with_theme("tokyonight")
            .build(context)
            .await?;

        let claude_code = claude_code::ClaudeCode::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let ghostty = ghostty::Ghostty::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let k9s = k9s::K9s::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let neovim = neovim::Neovim::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let artifacts = binaries
            .into_iter()
            .chain(bat.0)
            .chain(claude_code.0)
            .chain(ghostty.0)
            .chain(k9s.0)
            .chain(neovim.0)
            .collect();

        let symlinks_chain: Vec<(String, String)> = bat
            .1
            .into_iter()
            .chain(claude_code.1)
            .chain(ghostty.1)
            .chain(k9s.1)
            .chain(neovim.1)
            .collect();

        let symlinks: Vec<(&str, &str)> = symlinks_chain
            .iter()
            .map(|(a, b)| (a.as_str(), b.as_str()))
            .collect();

        artifact::UserEnvironment::new(&self.name, self.systems)
            .with_artifacts(artifacts)
            .with_environments(vec![
                "EDITOR=nvim".to_string(),
                "GOPATH=${HOME}/Development/language/go".to_string(),
                "PATH=/Applications/Obsidian.app/Contents/MacOS:/Applications/VMware\\ Fusion.app/Contents/Library:${GOPATH}/bin:${HOME}/.vorpal/bin:${HOME}/.local/bin:${PATH}".to_string(),
            ])
            .with_symlinks(symlinks)
            .build(context)
            .await
    }
}
