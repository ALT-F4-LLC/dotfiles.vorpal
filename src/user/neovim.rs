use crate::file::FileCreate;
use anyhow::Result;
use vorpal_artifacts::artifact::{
    bash_language_server::BashLanguageServer, cue::Cue, lua_language_server::LuaLanguageServer,
    neovim, tree_sitter::TreeSitter, typescript::Typescript,
    typescript_language_server::TypescriptLanguageServer,
    vscode_langservers_extracted::VscodeLangserversExtracted,
    yaml_language_server::YamlLanguageServer,
};
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact::{get_env_key, gopls::Gopls},
    context::ConfigContext,
};

pub struct Neovim {
    name: String,
    systems: Vec<ArtifactSystem>,
}

impl Neovim {
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
        let binaries = vec![neovim::Neovim::new().build(context).await?];

        let language_servers = vec![
            BashLanguageServer::new().build(context).await?,
            Cue::new().build(context).await?,
            Gopls::new().build(context).await?,
            LuaLanguageServer::new().build(context).await?,
            TreeSitter::new().build(context).await?,
            Typescript::new().build(context).await?,
            TypescriptLanguageServer::new().build(context).await?,
            VscodeLangserversExtracted::new().build(context).await?,
            YamlLanguageServer::new().build(context).await?,
        ];

        let markdown_vim_name = format!("{}-neovim-ftplugin-markdown-vim", self.name);

        let markdown_vim = FileCreate::new(&markdown_vim_name, self.systems, "setlocal wrap")
            .build(context)
            .await?;

        let symlinks = vec![(
            format!("{}/{markdown_vim_name}", get_env_key(&markdown_vim)),
            "${HOME}/.config/nvim/after/ftplugin/markdown.vim".to_string(),
        )];

        let artifacts = binaries
            .into_iter()
            .chain([markdown_vim])
            .chain(language_servers)
            .collect();

        Ok((artifacts, symlinks))
    }
}
