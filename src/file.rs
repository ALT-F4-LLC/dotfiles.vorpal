use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::{
    api::artifact::ArtifactSystem,
    artifact::{step, Artifact, ArtifactSource},
    context::ConfigContext,
};

pub struct FileCreate {
    content: String,
    executable: bool,
    name: String,
    systems: Vec<ArtifactSystem>,
}

pub struct FileDownload {
    name: String,
    path: String,
    systems: Vec<ArtifactSystem>,
}

impl FileCreate {
    pub fn new(content: &str, name: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            content: content.to_string(),
            executable: false,
            name: name.to_string(),
            systems,
        }
    }

    pub fn with_executable(mut self, executable: bool) -> Self {
        self.executable = executable;
        self
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let chmod_mode = if self.executable { "755" } else { "644" };

        let step_script = formatdoc! {"
            #!/bin/bash
            set -euo pipefail

            cat << 'EOF' > $VORPAL_OUTPUT/{name}
            {contents}
            EOF

            chmod {chmod_mode} $VORPAL_OUTPUT/{name}
        ",
            chmod_mode = chmod_mode,
            contents = self.content,
            name = self.name,
        };

        let step = step::shell(context, vec![], vec![], step_script, vec![]).await?;

        Artifact::new(&self.name, vec![step], self.systems)
            .build(context)
            .await
    }
}

impl FileDownload {
    pub fn new(name: &str, path: &str, systems: Vec<ArtifactSystem>) -> Self {
        Self {
            name: name.to_string(),
            path: path.to_string(),
            systems,
        }
    }

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let source = ArtifactSource::new(self.name.as_str(), self.path.as_str()).build();

        let step_script = formatdoc! {"
            pushd source/{name}

            cp -rv . $VORPAL_OUTPUT/.
        ",
            name = self.name,
        };

        let step = step::shell(context, vec![], vec![], step_script, vec![]).await?;

        Artifact::new(&self.name, vec![step], self.systems)
            .with_sources(vec![source])
            .build(context)
            .await
    }
}

pub struct FileSource {
    name: String,
    path: String,
    systems: Vec<ArtifactSystem>,
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
        let source = ArtifactSource::new(&self.name, ".")
            .with_includes(vec![self.path.to_string()])
            .build();

        let step_script = formatdoc! {r#"
            #!/bin/bash
            set -euo pipefail
            mkdir -pv $VORPAL_OUTPUT
            cp -rv ./source/{name}/{path}/* $VORPAL_OUTPUT/
        "#,
            name = self.name,
            path = self.path
        };

        let step = step::shell(context, vec![], vec![], step_script, vec![]).await?;

        Artifact::new(&self.name, vec![step], self.systems)
            .with_sources(vec![source])
            .build(context)
            .await
    }
}
