//! Graph fleet / old fleet basename collision guard (graph-engine M3, TDD §7 G1 AC-1.3).
//!
//! Both fleets merge into the same three `~/.claude/{agents,hooks,skills}` artifacts
//! (`src/user/claude_code.rs`, via `FileSource::with_merge_path`), because the Claude Code
//! harness discovers agents and skills by directory scan — rendering the graph fleet into
//! parallel directories would render but never be invocable.
//!
//! Merging copies the graph subtree *on top of* the old one, so a shared basename would silently
//! overwrite rather than fail. The authoritative guard against that lives in the *emitted build
//! script* (`FileSource::with_merge_path`), which refuses the copy at `vorpal build` /
//! `just activate` — the chokepoint every render passes through. These tests are the fast local
//! signal that catches a clash before a build does; they are deliberately not the last line of
//! defence, because `cargo test` does not run at activation.

use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::PathBuf,
};

/// Sourced from the build guard itself so the two cannot drift: a name exempted here but not in
/// the emitted script would fail the build, and the reverse would let a real clash through the
/// local signal. `guard-tmp-write-hook.sh` is the old fleet's own file, shared rather than copied
/// (TDD §4.5), so it is expected on both sides.
const SHARED_FILE_EXEMPTIONS: &[&str] = dotfiles::file::FileSource::MERGE_COLLISION_EXEMPTIONS;

/// Directories merged into one artifact, and the names the graph fleet may occupy there.
/// A graph file outside its reservation would render, but would also be free to collide with a
/// future old-fleet file — which is the failure AC-1.3 exists to prevent.
const MERGED_DIRS: &[(&str, &[&str])] = &[
    ("agents", &["executor-"]),
    ("hooks", &["docket-"]),
    ("skills", &["plan", "conduct", "bootstrap", "retro"]),
];

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

/// Top-level entry names in `<subtree>/<dir>`, which are exactly the names that collide when the
/// two subtrees are copied into one output. Skills are directories (`skills/plan/SKILL.md`),
/// agents and hooks are files, so this reads entries rather than recursing.
fn entry_names(subtree: &str, dir: &str) -> BTreeSet<String> {
    let path = repo_root().join("src/user").join(subtree).join(dir);

    let Ok(entries) = fs::read_dir(&path) else {
        // A not-yet-populated graph directory is expected mid-arc: `agents` and `hooks` are
        // placeholders until later groups land their files. Absence is not a collision.
        return BTreeSet::new();
    };

    entries
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.file_name().to_string_lossy().into_owned())
        .filter(|name| !name.starts_with('.'))
        .collect()
}

#[test]
fn graph_and_old_fleet_basenames_do_not_collide() {
    let mut collisions: BTreeMap<&str, Vec<String>> = BTreeMap::new();

    for (dir, _) in MERGED_DIRS {
        let old = entry_names("claude-code", dir);
        let graph = entry_names("claude-code-graph", dir);

        let shared: Vec<String> = old
            .intersection(&graph)
            .filter(|name| !SHARED_FILE_EXEMPTIONS.contains(&name.as_str()))
            .cloned()
            .collect();

        if !shared.is_empty() {
            collisions.insert(dir, shared);
        }
    }

    assert!(
        collisions.is_empty(),
        "graph fleet files would silently overwrite old fleet files of the same name when the \
         two subtrees merge into one artifact: {collisions:?}. Rename the graph file into its \
         reserved space (see MERGED_DIRS), or add a deliberate exemption if the file is genuinely \
         shared."
    );
}

#[test]
fn graph_fleet_files_stay_inside_their_reserved_names() {
    let mut violations: BTreeMap<&str, Vec<String>> = BTreeMap::new();

    for (dir, reserved) in MERGED_DIRS {
        let offenders: Vec<String> = entry_names("claude-code-graph", dir)
            .into_iter()
            .filter(|name| {
                !reserved
                    .iter()
                    .any(|prefix| name == prefix || name.starts_with(prefix))
            })
            .collect();

        if !offenders.is_empty() {
            violations.insert(dir, offenders);
        }
    }

    assert!(
        violations.is_empty(),
        "graph fleet files outside their reserved names (TDD §2.2): {violations:?}. These render \
         today but are not protected from a future old-fleet file taking the same name."
    );
}
