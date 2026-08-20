use crate::user::{
    bat::Bat, claude_code::ClaudeCode, docket::Docket, ghostty::Ghostty, go::Go, k9s::K9s,
    neovim::Neovim,
};
use anyhow::{bail, Result};
use std::collections::BTreeSet;
use vorpal_sdk::{api::artifact::ArtifactSystem, artifact, context::ConfigContext};

mod bat;
mod claude_code;
mod docket;
mod ghostty;
mod go;
mod k9s;
mod neovim;
mod utilities;

pub struct UserEnvironment {
    name: String,
    systems: Vec<ArtifactSystem>,
}

/// Install destinations claimed by more than one artifact, sorted and listed
/// once each. Activation aborts when two symlinks target the same path, so the
/// build stops here instead, naming the collision.
fn duplicate_symlink_targets(symlinks: &[(String, String)]) -> Vec<String> {
    let mut seen = BTreeSet::new();
    let mut duplicates = BTreeSet::new();

    for (_, target) in symlinks {
        if !seen.insert(target) {
            duplicates.insert(target.clone());
        }
    }

    duplicates.into_iter().collect()
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

        let bat = Bat::new(&self.name, self.systems.clone())
            .with_theme("tokyonight")
            .build(context)
            .await?;

        let claude_code = ClaudeCode::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let docket = Docket::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let ghostty = Ghostty::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let go = Go::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let k9s = K9s::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let neovim = Neovim::new(&self.name, self.systems.clone())
            .build(context)
            .await?;

        let artifacts = binaries
            .into_iter()
            .chain(bat.0)
            .chain(claude_code.0)
            .chain(docket.0)
            .chain(ghostty.0)
            .chain(go.0)
            .chain(k9s.0)
            .chain(neovim.0)
            .collect();

        let symlinks_chain: Vec<(String, String)> = bat
            .1
            .into_iter()
            .chain(claude_code.1)
            .chain(docket.1)
            .chain(ghostty.1)
            .chain(go.1)
            .chain(k9s.1)
            .chain(neovim.1)
            .collect();

        let duplicates = duplicate_symlink_targets(&symlinks_chain);

        if !duplicates.is_empty() {
            bail!(
                "activation would abort: more than one artifact links {}",
                duplicates.join(", ")
            );
        }

        let symlinks: Vec<(&str, &str)> = symlinks_chain
            .iter()
            .map(|(a, b)| (a.as_str(), b.as_str()))
            .collect();

        let path = [
            "/Applications/Obsidian.app/Contents/MacOS",
            "/Applications/VMware\\ Fusion.app/Contents/Library",
            "${GOPATH}/bin",
            "${HOME}/.vorpal/bin",
            "${HOME}/.local/bin",
        ];

        let environments = [
            "EDITOR=nvim",
            "GOPATH=${HOME}/Development/language/go",
            "LLAMA_ARG_CACHE_RAM=0",
            "OLLAMA_CONTEXT_LENGTH=32768",
            "OLLAMA_KEEP_ALIVE=30m",
            "OLLAMA_KV_CACHE_TYPE=q8_0",
            "OLLAMA_NUM_PARALLEL=1",
            &format!("PATH={}:${{PATH}}", path.join(":")),
        ];

        artifact::UserEnvironment::new(&self.name, self.systems)
            .with_artifacts(artifacts)
            .with_environments(environments.into_iter().map(|k| k.to_string()).collect())
            .with_symlinks(symlinks)
            .build(context)
            .await
    }
}

#[cfg(test)]
mod tests {
    use super::duplicate_symlink_targets;

    fn symlinks(pairs: &[(&str, &str)]) -> Vec<(String, String)> {
        pairs
            .iter()
            .map(|(source, target)| (source.to_string(), target.to_string()))
            .collect()
    }

    #[test]
    fn distinct_targets_are_not_duplicates() {
        let links = symlinks(&[
            ("/store/output/user/aaa", "${HOME}/.claude/agents"),
            ("/store/output/user/bbb", "${HOME}/.claude/hooks"),
            ("/store/output/user/ccc/bin", "${HOME}/.docket/bin"),
        ]);

        assert!(duplicate_symlink_targets(&links).is_empty());
    }

    #[test]
    fn two_artifacts_claiming_one_target_are_reported() {
        let links = symlinks(&[
            ("/store/output/user/aaa", "${HOME}/.claude/skills"),
            ("/store/output/user/bbb", "${HOME}/.claude/skills"),
        ]);

        assert_eq!(
            duplicate_symlink_targets(&links),
            vec!["${HOME}/.claude/skills".to_string()]
        );
    }

    #[test]
    fn a_repeated_target_is_reported_once_however_many_claim_it() {
        let links = symlinks(&[
            ("/store/output/user/aaa", "${HOME}/.docket/config"),
            ("/store/output/user/bbb", "${HOME}/.docket/config"),
            ("/store/output/user/ccc", "${HOME}/.docket/config"),
        ]);

        assert_eq!(
            duplicate_symlink_targets(&links),
            vec!["${HOME}/.docket/config".to_string()]
        );
    }

    #[test]
    fn several_collisions_are_reported_in_sorted_order() {
        let links = symlinks(&[
            ("/store/output/user/aaa", "${HOME}/.docket/config"),
            ("/store/output/user/bbb", "${HOME}/.claude/agents"),
            ("/store/output/user/ccc", "${HOME}/.docket/config"),
            ("/store/output/user/ddd", "${HOME}/.claude/agents"),
        ]);

        assert_eq!(
            duplicate_symlink_targets(&links),
            vec![
                "${HOME}/.claude/agents".to_string(),
                "${HOME}/.docket/config".to_string(),
            ]
        );
    }

    #[test]
    fn one_artifact_linked_to_two_destinations_is_allowed() {
        let links = symlinks(&[
            ("/store/output/user/aaa/bin", "${HOME}/.docket/bin"),
            ("/store/output/user/aaa/config", "${HOME}/.docket/config"),
        ]);

        assert!(duplicate_symlink_targets(&links).is_empty());
    }
}
