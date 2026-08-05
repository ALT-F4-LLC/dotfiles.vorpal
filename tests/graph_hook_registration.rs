//! Graph hook registration ↔ file correspondence (graph-engine M3, TDD §7 G4 AC-4.1/4.5/4.6).
//!
//! G1 deferred graph-hook registration with a stated invariant: "registration follows the files,
//! not the other way around", because a `.with_hook` pointing at a path that renders nothing
//! breaks every session in the fleet. These tests hold that invariant in both directions —
//! a registered `docket-*` hook must have a file, and a `docket-*.sh` file must be registered.
//!
//! Both sides read source text rather than a rendered `settings.json`: the registrations live in
//! `claude_code.rs` as `.with_hook` calls and the files live on disk, so the correspondence is
//! checkable without a build. That also means these tests fail fast on a typo'd filename, which is
//! the specific mistake that would otherwise surface only at `just activate`.

use std::{
    collections::BTreeSet,
    fs,
    path::{Path, PathBuf},
};

/// `heartbeat` is dropped by decision, not omission: environment check E1 failed (shared `$TMPDIR`
/// across subagents), so D11's decided fallback cuts markers and drops the hook (AC-4.5). Its
/// record carries a `.dropped` extension precisely so it is not discoverable as a hook body, and
/// the `.sh` name stays unclaimed so re-instatement is a visible rename. If E1 ever passes AND the
/// engine grows a marker-reading entry point, that rename is what makes this test demand the
/// registration.
const DROPPED_RECORD: &str = "docket-heartbeat-hook.sh.dropped";

/// The old fleet's three teams-runtime hooks stay registered for the old fleet; deletion is M5's,
/// not M3's (AC-4.6). Asserted positively below so an over-eager cleanup during this arc fails
/// here rather than silently degrading the default fleet.
const TEAMS_RUNTIME_HOOKS: &[&str] = &[
    "task-completed-hook.sh",
    "subagent-report-hook.sh",
    "teammate-idle-hook.sh",
];

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

fn claude_code_rs() -> String {
    let path = repo_root().join("src/user/claude_code.rs");
    fs::read_to_string(&path).unwrap_or_else(|error| panic!("read {}: {error}", path.display()))
}

fn graph_hooks_dir() -> PathBuf {
    repo_root().join("src/user/claude-code-graph/hooks")
}

/// Executable `docket-*.sh` bodies in the graph hooks subtree. The `.dropped` record is excluded
/// by the `.sh` suffix test, which is the point of that extension.
fn graph_hook_files() -> BTreeSet<String> {
    let Ok(entries) = fs::read_dir(graph_hooks_dir()) else {
        return BTreeSet::new();
    };

    entries
        .filter_map(|entry| entry.ok())
        .map(|entry| entry.file_name().to_string_lossy().into_owned())
        .filter(|name| name.starts_with("docket-") && name.ends_with(".sh"))
        .collect()
}

/// Hook basenames referenced by a `~/.claude/hooks/<name>` command string in the settings builder.
fn registered_hook_names(source: &str, prefix: &str) -> BTreeSet<String> {
    let needle = "~/.claude/hooks/";

    source
        .match_indices(needle)
        .map(|(index, _)| {
            source[index + needle.len()..]
                .split(['"', ' ', '\n'])
                .next()
                .unwrap_or_default()
                .to_string()
        })
        .filter(|name| name.starts_with(prefix))
        .collect()
}

#[test]
fn every_graph_hook_file_is_registered() {
    let source = claude_code_rs();
    let registered = registered_hook_names(&source, "docket-");

    let unregistered: Vec<String> = graph_hook_files()
        .difference(&registered)
        .cloned()
        .collect();

    assert!(
        unregistered.is_empty(),
        "graph hook files exist but are never registered via `.with_hook`, so they render into \
         `~/.claude/hooks/` and never fire: {unregistered:?}. Register them in \
         `src/user/claude_code.rs`, or give a dropped hook the `.dropped` extension with its \
         reason recorded (see {DROPPED_RECORD})."
    );
}

#[test]
fn every_registered_graph_hook_has_a_file() {
    let source = claude_code_rs();

    let missing: Vec<String> = registered_hook_names(&source, "docket-")
        .difference(&graph_hook_files())
        .cloned()
        .collect();

    assert!(
        missing.is_empty(),
        "`.with_hook` registers graph hooks with no file behind them: {missing:?}. A hook command \
         pointing at a nonexistent path fails on every matching event in every session — this is \
         exactly what G1's \"registration follows the files\" deferral existed to prevent."
    );
}

#[test]
fn dropped_heartbeat_hook_is_recorded_but_not_registered() {
    let source = claude_code_rs();

    assert!(
        graph_hooks_dir().join(DROPPED_RECORD).is_file(),
        "the dropped heartbeat hook's record is missing. AC-4.5 drops the hook when E1 fails, but \
         the measurement and the re-instatement conditions must travel with the artifact."
    );

    assert!(
        !Path::new(&graph_hooks_dir().join("docket-heartbeat-hook.sh")).exists(),
        "docket-heartbeat-hook.sh exists as a hook body. E1 failed, so D11's fallback drops the \
         hook rather than leaving it firing against a SHARED marker — where one executor's \
         heartbeat can renew another executor's lease. Re-instating it requires E1 to pass first."
    );

    // Tests the REGISTRATION, not any mention: `claude_code.rs` names the `.dropped` record in a
    // comment so the reason is readable at the wiring site, and that comment must not trip this.
    assert!(
        !registered_hook_names(&source, "docket-").contains("docket-heartbeat-hook.sh"),
        "docket-heartbeat-hook.sh is registered in claude_code.rs. See AC-4.5 and D11: the hook is \
         dropped, not merely unimplemented."
    );
}

#[test]
fn teams_runtime_hooks_stay_registered_for_the_old_fleet() {
    let source = claude_code_rs();
    let registered = registered_hook_names(&source, "");

    let removed: Vec<&str> = TEAMS_RUNTIME_HOOKS
        .iter()
        .copied()
        .filter(|name| !registered.contains(*name))
        .collect();

    assert!(
        removed.is_empty(),
        "teams-runtime hooks were unregistered during the graph arc: {removed:?}. AC-4.6 keeps \
         them for the old fleet, which stays default until M5; their deletion is M5's single \
         dotfiles change, not this arc's."
    );
}

#[test]
fn both_stop_hooks_are_registered_for_coexistence() {
    let source = claude_code_rs();

    for hook in ["stop-guard-hook.sh", "docket-run-guard-hook.sh"] {
        assert!(
            source.contains(hook),
            "{hook} is not registered. AC-4.7 requires BOTH Stop hooks live simultaneously: the \
             old fleet's guard serves the old fleet and is inert without a team config, while \
             run-guard enforces engine truth for graph sessions."
        );
    }
}
