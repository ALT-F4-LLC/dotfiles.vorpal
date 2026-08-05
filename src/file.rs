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
    merge_paths: Vec<String>,
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
            merge_paths: vec![],
            name: name.to_string(),
            path: path.to_string(),
            systems,
        }
    }

    // Copies an additional source directory into the same output, on top of `path`.
    //
    // The SDK's `UserEnvironment` emits one `ln -s {source} {target}` per symlink with no `-f`,
    // under `set -euo pipefail` — so two artifacts cannot both symlink one target directory; the
    // second `ln` aborts activation. Merging at the artifact level is therefore the only way to
    // land two source subtrees in a single `~/.claude/<dir>`, which the Claude Code harness
    // requires because it discovers agents and skills by directory scan.
    //
    // A merge is `cp -r` layered onto what is already there, so a shared relative path would
    // *silently overwrite* rather than fail. The emitted script therefore refuses the copy
    // first: it compares the merge subtree against the target tree recursively and exits 1
    // naming the colliding path. That check runs at `vorpal build` / `just activate` — the
    // chokepoint every render passes through — rather than only in `cargo test`, which does not
    // run at activation and so cannot stop a clash introduced between test runs from shipping.
    // `tests/graph_fleet_collision.rs` remains the fast local signal, not the last line.
    //
    // Callers that do not merge are unaffected: with `merge_paths` empty no guard and no copy is
    // emitted, so the script is byte-identical to the single-source form and existing artifacts
    // keep their digests.
    pub fn with_merge_path(mut self, path: &str) -> Self {
        self.merge_paths.push(path.to_string());
        self
    }

    // Relative paths allowed to appear in both a base and a merged subtree. `guard-tmp-write-hook.sh`
    // is the old fleet's own file, shared rather than copied (graph-engine TDD §4.5), so it is
    // expected on both sides. Kept in sync with `tests/graph_fleet_collision.rs`, which asserts
    // this list and the guard's list agree.
    pub const MERGE_COLLISION_EXEMPTIONS: &'static [&'static str] = &["guard-tmp-write-hook.sh"];

    pub async fn build(self, context: &mut ConfigContext) -> Result<String> {
        let mut includes = vec![self.path.to_string()];
        let mut path = ".".to_string();
        let mut source_path = format!("{}/.", self.path);

        if self.path.starts_with("http") {
            includes = vec![]; // everything
            path = self.path.clone(); // url
            source_path = ".".to_string(); // root
        }

        includes.extend(self.merge_paths.iter().cloned());

        // Guard, then copy, per merge path. The guard walks the merge subtree recursively and
        // aborts before `cp` if anything already exists at the same relative path in
        // `$VORPAL_OUTPUT` (which holds the base tree plus any earlier merges).
        //
        // It walks **files and directories both**, because `cp -r` clobbers at either
        // granularity: merging a file `adr/SKILL.md` onto an existing *directory* `adr/` is a
        // real collision even though no file path matches, and a files-only walk would miss it.
        //
        // Collisions are counted into a marker file rather than signalled by `exit` from inside
        // the loop. `find | while read` puts the loop body in a subshell, so an `exit` there
        // terminates only the subshell; the script would continue to the `cp` it was supposed to
        // prevent. Testing the marker afterwards keeps the failure in the parent shell where
        // `exit 1` actually fails the step. Verified: a plain `exit 1` in this step script does
        // surface as `vorpal build` exit 1, so failing here fails the build.
        let merge_copies = self
            .merge_paths
            .iter()
            .map(|p| {
                formatdoc! {r#"

                    merge_src="{name}-file-source/{merge_path}"
                    # Kept next to the source tree rather than in $TMPDIR: the build sandbox does
                    # not reliably permit mktemp, and this path is writable by definition. Not
                    # under $VORPAL_OUTPUT, which would ship the marker inside the artifact.
                    merge_collisions="../merge-collisions.txt"
                    : > "$merge_collisions"

                    (cd "$merge_src" && find . -mindepth 1) | sed 's|^\./||' | while read -r rel; do
                        case " {exemptions} " in
                            *" $rel "*) continue ;;
                        esac

                        if [ -e "$VORPAL_OUTPUT/$rel" ]; then
                            echo "$rel" >> "$merge_collisions"
                        fi
                    done

                    if [ -s "$merge_collisions" ]; then
                        echo "ERROR: merge collision in artifact '{name}'" >&2
                        echo "  merging: {merge_path}" >&2
                        echo "  the following paths already exist in the artifact and would be" >&2
                        echo "  silently overwritten:" >&2
                        sed 's|^|    |' "$merge_collisions" >&2
                        echo "  Rename them into the merged tree's reserved namespace, or add them to" >&2
                        echo "  FileSource::MERGE_COLLISION_EXEMPTIONS if they are genuinely shared." >&2
                        rm -f "$merge_collisions"
                        exit 1
                    fi

                    rm -f "$merge_collisions"

                    cp -r "$merge_src/." $VORPAL_OUTPUT
                "#,
                    exemptions = Self::MERGE_COLLISION_EXEMPTIONS.join(" "),
                    merge_path = p,
                    name = self.name,
                }
            })
            .collect::<Vec<String>>()
            .join("");

        let step_script = formatdoc! {r#"
            pushd source

            cp -r {name}-file-source/{source_path} $VORPAL_OUTPUT
        "#,
            name = self.name,
        } + &merge_copies;

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
