use crate::SYSTEMS;
use anyhow::Result;
use indoc::formatdoc;
use vorpal_sdk::{
    artifact::{step::shell, ArtifactBuilder},
    context::ConfigContext,
};

pub async fn build_file(context: &mut ConfigContext, name: &str, contents: &str) -> Result<String> {
    let step_script = formatdoc! {"
        #!/bin/bash
        set -euo pipefail

        cat << 'EOF' > $VORPAL_OUTPUT/{name}
        {contents}
        EOF

        chmod 644 $VORPAL_OUTPUT/{name}
    "};

    let step = shell(context, vec![], vec![], step_script, vec![]).await?;

    ArtifactBuilder::new(name, vec![step], SYSTEMS.to_vec())
        .build(context)
        .await
}
