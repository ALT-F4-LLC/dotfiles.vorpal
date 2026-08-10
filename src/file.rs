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
        let mut includes = vec![self.path.to_string()];
        let mut path = ".".to_string();
        let mut source_path = format!("{}/.", self.path);

        if self.path.starts_with("http") {
            includes = vec![]; // everything
            path = self.path.clone(); // url
            source_path = ".".to_string(); // root
        }

        let step_script = formatdoc! {r#"
            pushd source/{name}-file-source
            cp -r {source_path} ${{VORPAL_OUTPUT}}
        "#,
            name = self.name,
        };

        let step = step::shell(context, vec![], vec![], step_script, vec![]).await?;

        let source = ArtifactSource::new(&format!("{}-file-source", self.name), &path)
            .with_includes(includes)
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
