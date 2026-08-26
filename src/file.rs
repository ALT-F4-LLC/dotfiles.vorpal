use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact::{step, Artifact, ArtifactSource},
    context::ConfigContext,
};

pub struct FileCreate {
    artifacts: Vec<String>,
    content: String,
    executable: bool,
    name: String,
    systems: Vec<ArtifactSystem>,
}

pub struct FileSource {
    name: String,
    path: String,
    systems: Vec<ArtifactSystem>,
}

/// Where a `FileSource` fetches from and what it copies into the artifact
/// output. A local subtree is fetched include-filtered and copied out of its
/// own directory inside `source/`; an `http` path fetches the whole remote
/// artifact and copies from its root.
#[derive(Debug, Eq, PartialEq)]
pub struct SourceLayout {
    pub includes: Vec<String>,
    pub path: String,
    pub source_path: String,
}

/// Directory names that must never be captured into an artifact output.
///
/// A Claude Code session leaves a `.claude/.cc-writes` write-tracking directory
/// wherever its cwd lands, including inside `src/user/**`. Git never reports
/// one -- the directory is always empty, and git does not track empty
/// directories -- but vorpal walks the filesystem, so the debris gets baked
/// into a content-addressed artifact and shipped to every install (DOT-823).
///
/// This cannot be expressed as an `ArtifactSource` exclude. Vorpal matches
/// excludes as literal path prefixes relative to the artifact context
/// (`path.strip_prefix(source_path).starts_with(exclude)` in
/// `cli/src/command/store/paths.rs::get_file_paths`) with no glob support, so
/// an exclude list would have to name every directory that might ever host a
/// session -- and the observed debris sits at four different depths. The copy
/// step prunes by name instead, which is depth-independent.
pub const HARNESS_DIRS: [&str; 1] = [".claude"];

/// Shell fragment that removes every `HARNESS_DIRS` entry from `output`, at any
/// depth. `-depth` visits children before parents so removing a directory never
/// invalidates the rest of the walk, and `-exec ... +` batches into one `rm`.
/// `find` is on PATH for both step backends: `/usr/bin` on darwin, and
/// findutils inside the linux sandbox.
pub fn prune_harness_dirs(output: &str) -> String {
    let names = HARNESS_DIRS
        .iter()
        .map(|name| format!("-name '{name}'"))
        .collect::<Vec<String>>()
        .join(" -o ");

    format!(r#"find "{output}" -depth -type d \( {names} \) -exec rm -rf {{}} +"#)
}

impl SourceLayout {
    pub fn for_path(path: &str) -> Self {
        if path.starts_with("http") {
            return Self {
                includes: vec![],
                path: path.to_string(),
                source_path: ".".to_string(),
            };
        }

        Self {
            includes: vec![path.to_string()],
            path: ".".to_string(),
            source_path: format!("{path}/."),
        }
    }
}

impl FileCreate {
    pub fn new(name: &str, systems: Vec<ArtifactSystem>, content: &str) -> Self {
        Self {
            artifacts: vec![],
            content: content.to_string(),
            executable: false,
            name: name.to_string(),
            systems,
        }
    }

    pub fn with_artifacts(mut self, artifacts: Vec<String>) -> Self {
        self.artifacts = artifacts;
        self
    }

    pub fn with_executable(mut self, executable: bool) -> Self {
        self.executable = executable;
        self
    }

    /// Path of the single file this artifact holds. `build` writes
    /// `$VORPAL_OUTPUT/{name}`, so the file is always named after the
    /// artifact: a symlink must point here, not at the output directory.
    pub fn output_file_path(output: &str, name: &str) -> String {
        format!("{output}/{name}")
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let chmod_mode = if self.executable { "755" } else { "644" };

        let step_script = formatdoc! {"
            cat << 'EOF' > $VORPAL_OUTPUT/{name}
            {contents}
            EOF

            chmod {chmod_mode} $VORPAL_OUTPUT/{name}
        ",
            chmod_mode = chmod_mode,
            contents = self.content,
            name = self.name,
        };

        let step = step::shell(context, self.artifacts, vec![], step_script, vec![]).await?;

        Artifact::new(
            &format!("{}-file-create", self.name),
            vec![step],
            self.systems,
        )
        .build(context)
        .await
    }
}

impl FileSource {
    pub fn new(name: &str, path: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            path: path.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let layout = SourceLayout::for_path(&self.path);

        let step_script = formatdoc! {r#"
            pushd source/{name}-file-source
            cp -r {source_path} ${{VORPAL_OUTPUT}}
            {prune}
        "#,
            name = self.name,
            prune = prune_harness_dirs("${VORPAL_OUTPUT}"),
            source_path = layout.source_path,
        };

        let step = step::shell(context, vec![], vec![], step_script, vec![]).await?;

        let source = ArtifactSource::new(&format!("{}-file-source", self.name), &layout.path)
            .with_includes(layout.includes)
            .build();

        Artifact::new(
            &format!("{}-file-source", self.name),
            vec![step],
            self.systems,
        )
        .with_sources(vec![source])
        .build(context)
        .await
    }
}

#[cfg(test)]
mod tests {
    use super::{prune_harness_dirs, FileCreate, SourceLayout, HARNESS_DIRS};

    #[test]
    fn local_source_copies_the_declared_subtree_from_its_own_directory() {
        let layout = SourceLayout::for_path("src/user/docket");

        assert_eq!(layout.includes, vec!["src/user/docket".to_string()]);
        assert_eq!(layout.path, ".");
        assert_eq!(layout.source_path, "src/user/docket/.");
    }

    #[test]
    fn remote_source_fetches_everything_and_copies_from_the_fetch_root() {
        let url = "https://raw.githubusercontent.com/folke/tokyonight.nvim/v4.14.1/theme.tmTheme";

        let layout = SourceLayout::for_path(url);

        assert!(layout.includes.is_empty());
        assert_eq!(layout.path, url);
        assert_eq!(layout.source_path, ".");
    }

    #[test]
    fn plain_http_source_is_treated_as_remote() {
        assert_eq!(
            SourceLayout::for_path("http://example.com/x.txt").source_path,
            "."
        );
    }

    #[test]
    fn harness_debris_is_pruned_from_the_copied_output_at_any_depth() {
        let script = prune_harness_dirs("${VORPAL_OUTPUT}");

        assert_eq!(
            script,
            r#"find "${VORPAL_OUTPUT}" -depth -type d \( -name '.claude' \) -exec rm -rf {} +"#
        );
    }

    #[test]
    fn every_harness_dir_is_named_in_the_prune_expression() {
        let script = prune_harness_dirs("/out");

        for name in HARNESS_DIRS {
            assert!(
                script.contains(&format!("-name '{name}'")),
                "{name} not pruned"
            );
        }
    }

    #[test]
    fn created_file_is_addressed_by_the_artifact_name_inside_the_output() {
        assert_eq!(
            FileCreate::output_file_path("/store/output/user/abc123", "user-claude-code-settings"),
            "/store/output/user/abc123/user-claude-code-settings"
        );
    }
}
