use crate::file::FileSource;
use anyhow::{bail, Result};
use indoc::formatdoc;
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact::{get_env_key, step, Artifact, ArtifactSource},
    context::ConfigContext,
};

/// Directory under `${HOME}` that holds one symlink per plugin, each pointing
/// at the plugin's store path. `.zshrc` sources from here; keep the two in
/// step. It is a flat `.config` entry because activation links without
/// creating parent directories, and `.config` already exists.
const PLUGIN_LINK_DIR: &str = "${HOME}/.config";

/// A zsh plugin built from a GitHub repository at one commit.
///
/// The commit is the pin: the source URL names the full 40-hex commit, so the
/// fetched archive cannot move, and `Vorpal.lock` records the content digest of
/// what that URL returned. Nothing is fetched when a shell starts.
struct ZshPlugin {
    name: &'static str,
    repo: &'static str,
    rev: &'static str,
}

/// Plugins in load order after `compinit`: `zsh-completions` only adds to
/// `fpath` (so it is read by `compinit`), `fzf-tab` must come after `compinit`,
/// and `zsh-autosuggestions` goes last because it wraps widgets the others
/// bind.
const PLUGINS: [ZshPlugin; 3] = [
    ZshPlugin {
        name: "zsh-completions",
        repo: "zsh-users/zsh-completions",
        // 0.36.0
        rev: "28c5bdcaf81bb89e56d0df8267d822c3b8aed9e0",
    },
    ZshPlugin {
        name: "fzf-tab",
        repo: "Aloxaf/fzf-tab",
        // v1.3.0
        rev: "d7e0234614dbe5369fdd760907d12c0e05a4dccc",
    },
    ZshPlugin {
        name: "zsh-autosuggestions",
        repo: "zsh-users/zsh-autosuggestions",
        // v0.7.1
        rev: "e52ee8ca55bcc56a17c828767a3f98f22a68d4eb",
    },
];

impl ZshPlugin {
    /// The archive of the repository at the pinned commit.
    fn archive_url(&self) -> String {
        format!(
            "https://github.com/{}/archive/{}.tar.gz",
            self.repo, self.rev
        )
    }

    /// The one top-level directory GitHub puts in a commit archive:
    /// `<repository>-<full commit>`.
    fn archive_dir(&self) -> String {
        let repository = self.repo.rsplit('/').next().unwrap_or(self.repo);

        format!("{repository}-{}", self.rev)
    }

    /// Where `.zshrc` finds the plugin once activated.
    fn link_target(&self) -> String {
        format!("{PLUGIN_LINK_DIR}/{}", self.name)
    }

    /// A pin is a full commit hash: a branch, tag or short hash can move or
    /// collide, and would defeat the point of building the plugin in-repo.
    fn check_pin(&self) -> Result<()> {
        let pinned = self.rev.len() == 40
            && self
                .rev
                .chars()
                .all(|c| c.is_ascii_digit() || ('a'..='f').contains(&c));

        if !pinned {
            bail!(
                "zsh plugin {} must be pinned to a full lowercase 40-hex commit, got {:?}",
                self.name,
                self.rev
            );
        }

        Ok(())
    }

    async fn build(
        &self,
        prefix: &str,
        systems: Vec<ArtifactSystem>,
        context: &mut ConfigContext,
    ) -> Result<String> {
        self.check_pin()?;

        let name = format!("{prefix}-zsh-plugin-{}", self.name);
        let url = self.archive_url();

        let source = ArtifactSource::new(&name, &url).build();

        let step_script = formatdoc! {r#"
            pushd source/{name}
            cp -R {dir}/. ${{VORPAL_OUTPUT}}
            # compinit (never -u) prompts on every shell start when an fpath
            # directory is group-writable, and archives can carry 0775 modes.
            chmod -R go-w ${{VORPAL_OUTPUT}}
        "#,
            dir = self.archive_dir(),
        };

        let step = step::shell(context, &[], &[], step_script, &[]).await?;

        Artifact::new(&name, vec![step], systems)
            .with_sources(vec![source])
            .build(context)
            .await
    }
}

pub struct Zsh {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Zsh {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            systems,
        }
    }

    pub async fn build(
        self,
        context: &mut ConfigContext,
    ) -> Result<(Vec<String>, Vec<(String, String)>)> {
        // The tracked files are the source of truth: aliases and functions
        // are edited in src/user/zsh/.zshrc and shipped verbatim. A source
        // copy, not a generated file, because the kindc function carries its
        // own EOF line, which would end a heredoc-based file step early.
        let config = FileSource::new(
            &format!("{}-zsh", self.name),
            "src/user/zsh",
            self.systems.clone(),
        )
        .build(context)
        .await?;

        let mut artifacts = vec![config.clone()];

        let mut symlinks = vec![
            (
                format!("{}/.zprofile", get_env_key(&config)),
                "${HOME}/.zprofile".to_string(),
            ),
            (
                format!("{}/.zshrc", get_env_key(&config)),
                "${HOME}/.zshrc".to_string(),
            ),
        ];

        for plugin in &PLUGINS {
            let artifact = plugin
                .build(&self.name, self.systems.clone(), context)
                .await?;

            symlinks.push((get_env_key(&artifact), plugin.link_target()));
            artifacts.push(artifact);
        }

        Ok((artifacts, symlinks))
    }
}

#[cfg(test)]
mod tests {
    use super::{ZshPlugin, PLUGINS};
    use std::collections::BTreeSet;

    fn plugin(name: &'static str) -> &'static ZshPlugin {
        PLUGINS.iter().find(|p| p.name == name).expect("plugin")
    }

    #[test]
    fn every_plugin_is_pinned_to_a_full_commit() {
        for plugin in &PLUGINS {
            plugin.check_pin().expect(plugin.name);
        }
    }

    #[test]
    fn a_branch_tag_or_short_hash_is_not_a_pin() {
        for rev in [
            "main",
            "v0.7.1",
            "e52ee8c",
            "E52EE8CA55BCC56A17C828767A3F98F22A68D4EB",
            "",
        ] {
            let loose = ZshPlugin {
                name: "loose",
                repo: "owner/loose",
                rev,
            };

            assert!(loose.check_pin().is_err(), "{rev:?} accepted as a pin");
        }
    }

    #[test]
    fn the_source_url_names_the_pinned_commit() {
        assert_eq!(
            plugin("zsh-autosuggestions").archive_url(),
            "https://github.com/zsh-users/zsh-autosuggestions/archive/e52ee8ca55bcc56a17c828767a3f98f22a68d4eb.tar.gz"
        );
    }

    #[test]
    fn the_archive_directory_is_repository_and_full_commit() {
        assert_eq!(
            plugin("fzf-tab").archive_dir(),
            "fzf-tab-d7e0234614dbe5369fdd760907d12c0e05a4dccc"
        );
    }

    #[test]
    fn plugins_link_under_config_by_name() {
        assert_eq!(
            plugin("zsh-completions").link_target(),
            "${HOME}/.config/zsh-completions"
        );
    }

    #[test]
    fn plugin_names_and_link_targets_are_distinct() {
        let names: BTreeSet<_> = PLUGINS.iter().map(|p| p.name).collect();
        let targets: BTreeSet<_> = PLUGINS.iter().map(ZshPlugin::link_target).collect();

        assert_eq!(names.len(), PLUGINS.len());
        assert_eq!(targets.len(), PLUGINS.len());
    }

    #[test]
    fn zshrc_sources_the_plugins_from_the_linked_names_in_order() {
        let zshrc = include_str!("zsh/.zshrc");
        let at = |needle: &str| {
            zshrc
                .find(needle)
                .unwrap_or_else(|| panic!("{needle} missing"))
        };

        assert!(zshrc.contains("ZSH_PLUGIN_ROOT:-${HOME}/.config}"));
        assert!(super::PLUGIN_LINK_DIR.ends_with("/.config"));
        assert!(
            at("${ZSH_PLUGIN_ROOT}/zsh-completions/src") < at("compinit -d"),
            "zsh-completions must be on fpath before compinit"
        );
        assert!(at("compinit -d") < at("zoxide init zsh"));
        assert!(
            at("${ZSH_PLUGIN_ROOT}/fzf-tab/fzf-tab.plugin.zsh")
                < at("${ZSH_PLUGIN_ROOT}/zsh-autosuggestions/zsh-autosuggestions.zsh")
        );
        assert!(!zshrc.contains("compinit -u"));
    }
}
