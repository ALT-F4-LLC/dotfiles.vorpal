#!/bin/bash
# Mechanizes evolve-config's Content Gate Behavioral check ("Does the
# setting change the deployed settings.json (or a script's behavior)?
# Reject: settings that serialize identically to the current output"):
# runs a caller-supplied RENDER COMMAND -- one that prints the full
# serialized config to stdout -- at two git states, and diffs the output.
#
# The builder's real `.build(context)` path (ClaudeCode::build,
# FileCreate::build, ...) hands off to the actual vorpal `Artifact::build`
# pipeline (network/store-backed, `just activate` -> `vorpal build --path
# 'user'`) -- there is no lightweight offline render of the full deployed
# settings.json via that path. `claude_code.rs`'s `build()` DOES already
# call `serde_json::to_string_pretty(&self)` offline (before handing off to
# FileCreate) -- the primitive exists, it just isn't wrapped in anything
# that prints it to stdout on demand today. This script does not assume
# a specific render mechanism; it drives whatever RENDER_COMMAND the caller
# gives it (a `cargo test <name> -- --nocapture` wrapping a test that
# `println!`s its rendered content, a future `cargo run --bin ... --
# render <target>` subcommand, etc.) and diffs its stdout, byte-for-byte,
# net of cargo's own build-process chatter (see normalize() below).
#
# IMPORTANT: as of this writing, NEITHER src/user/codex.rs (whose tests
# only `assert!` on rendered content -- see serializes_current_config_shape
# -- never print it, even under --nocapture) NOR src/user/claude_code.rs
# (no test at all yet) expose a render target that prints the full config.
# This script is the harness; its first real consumer is gated on that
# render-target follow-up landing (tracked as a Discovered comment on
# DKT-309, out of scope for this script-authoring issue). Driving it today
# against an assert-only command like `cargo test
# serializes_current_config_shape -- --nocapture` will correctly detect
# DIFFERS only when the change also breaks that test's own assertion
# (visible failure diff) -- a passing assert-only test prints nothing on
# success, so a lockstep setter+assertion edit is invisible to a stdout
# diff. That's a property of the render command supplied, not a bug in
# this script.
#
# The "before" state is ALWAYS rendered from an isolated `git worktree add`
# checkout -- never a `git stash`/`git checkout` on the shared working tree
# (this repo may have other agents' uncommitted work in it concurrently).
set -euo pipefail

usage() {
    echo "Usage: config_render_diff.sh <render-command> [<before-ref>] [<after-ref-or-worktree>]" >&2
    echo "  <render-command>: a shell command (run via 'bash -c') that prints the" >&2
    echo "    full rendered config to stdout, e.g. a cargo test wrapping" >&2
    echo "    println!(\"{}\", serde_json::to_string_pretty(&self))." >&2
    echo "  Runs <render-command> at two git states and diffs stdout." >&2
    echo "  <before-ref>: git ref for the 'before' state (default: HEAD)" >&2
    echo "  <after-ref-or-worktree>: git ref, or literal 'worktree' for the" >&2
    echo "    current (possibly uncommitted) working tree (default: worktree)" >&2
    echo "  Exit 0 = outputs differ (Content Gate Behavioral check PASSES)." >&2
    echo "  Exit 1 = outputs identical (Behavioral check FAILS -- no-op change)." >&2
    echo "  Exit 2 = usage/precondition error (render command failed, or" >&2
    echo "    produced empty output, at both states)." >&2
    exit 2
}

[ "$#" -ge 1 ] || usage
RENDER_COMMAND="$1"
BEFORE_REF="${2:-HEAD}"
AFTER_REF="${3:-worktree}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "config_render_diff.sh: not inside a git repository" >&2
    exit 2
}
cd "$REPO_ROOT"

CLEANUP_DIRS=()
RENDER_TMP=$(mktemp "${TMPDIR:-/tmp}/config_render_diff_out.XXXXXX")
BEFORE_TXT=$(mktemp "${TMPDIR:-/tmp}/config_render_diff_before.XXXXXX")
AFTER_TXT=$(mktemp "${TMPDIR:-/tmp}/config_render_diff_after.XXXXXX")
cleanup() {
    local d
    rm -f "$RENDER_TMP" "$BEFORE_TXT" "$AFTER_TXT"
    for d in "${CLEANUP_DIRS[@]:-}"; do
        [ -n "$d" ] || continue
        git worktree remove --force "$d" >/dev/null 2>&1 || rm -rf "$d"
    done
}
trap cleanup EXIT

# Strips cargo's own build-process chatter (compile progress, per-binary
# "Running .../deps/<name>-<hash>" lines whose hash suffix is
# build-nondeterministic, and the "finished in N.NNs" wall-clock suffix on
# "test result:" lines) -- a no-op on a non-cargo render command, since
# none of these patterns matches anything else. None of it is render
# OUTPUT, and all of it varies run-to-run even when the actual rendered
# content is byte-identical, which would otherwise make every comparison
# falsely report DIFFERS.
normalize() {
    grep -vE '^\s*(Compiling|Checking|Finished|Running|Fresh|Downloading|Downloaded|Updating|Blocking)\b' \
        | sed -E 's/; finished in [0-9]+(\.[0-9]+)?s$/; finished in N.NNs/'
}

# Runs RENDER_COMMAND in $1, returning its normalized stdout+stderr on
# stdout, with a trailing sentinel line carrying the command's real exit
# code -- captured explicitly rather than relied on through `set -e` across
# a subshell/pipe/command-substitution chain, which would otherwise abort
# the whole script on a failing render command before it can report
# anything useful (observed: an assert-only render command that fails its
# assertion at one state kills the script with a bare "exit 101" and no
# diagnostic).
RC_SENTINEL="__CONFIG_RENDER_DIFF_RC__"

render() {
    local dir="$1"
    local rc=0
    ( cd "$dir" && bash -c "$RENDER_COMMAND" ) >"$RENDER_TMP" 2>&1 || rc=$?
    normalize <"$RENDER_TMP"
    printf '%s=%d\n' "$RC_SENTINEL" "$rc"
}

# extract_rc/extract_body each independently derive ONE value from a
# render() capture via their own command substitution -- never a single
# function setting two "return values" (one via stdout, one via a global),
# since the global would only be visible inside that call's own
# command-substitution subshell (the same class of bug fixed above for
# CLEANUP_DIRS).
#
# extract_body's `grep -v` legitimately produces ZERO output lines (exit 1)
# when the render command's own output was empty -- filtering out the sole
# sentinel line leaves nothing. Because this pipe is the ENTIRE body of a
# function invoked via a bare `X=$(extract_body ...)` assignment, that
# exit 1 is `set -e`-fatal here (unlike a mid-function pipeline stage
# followed by more statements, which is not) -- `|| true` makes "empty
# render output" a legitimate, non-aborting outcome instead of a silent
# whole-script abort with no diagnostic.
extract_rc() {
    printf '%s\n' "$1" | grep "^${RC_SENTINEL}=" | tail -1 | cut -d= -f2
}

extract_body() {
    printf '%s\n' "$1" | grep -v "^${RC_SENTINEL}=" || true
}

# Creates the worktree and returns its path on stdout ONLY -- never called
# via command substitution together with CLEANUP_DIRS mutation. `$(...)`
# runs in a subshell, so an array append inside a function invoked as
# `X=$(fn)` would mutate only that subshell's copy of CLEANUP_DIRS and
# never reach the parent shell's EXIT trap -- silently leaking the worktree
# on every run. Keeping worktree creation and CLEANUP_DIRS append in the
# top-level shell (below) avoids that trap.
create_worktree() {
    local ref="$1"
    local wt
    wt=$(mktemp -d "${TMPDIR:-/tmp}/config_render_diff.XXXXXX")
    git worktree add --detach -q "$wt" "$ref" >&2
    printf '%s' "$wt"
}

BEFORE_WT=$(create_worktree "$BEFORE_REF")
CLEANUP_DIRS+=("$BEFORE_WT")
BEFORE_RAW=$(render "$BEFORE_WT")
BEFORE_RC=$(extract_rc "$BEFORE_RAW")
BEFORE_OUT=$(extract_body "$BEFORE_RAW")

if [ "$AFTER_REF" = "worktree" ]; then
    AFTER_RAW=$(render "$REPO_ROOT")
else
    AFTER_WT=$(create_worktree "$AFTER_REF")
    CLEANUP_DIRS+=("$AFTER_WT")
    AFTER_RAW=$(render "$AFTER_WT")
fi
AFTER_RC=$(extract_rc "$AFTER_RAW")
AFTER_OUT=$(extract_body "$AFTER_RAW")

# Diffed via plain temp files, never `diff <(...) <(...)` process
# substitution -- that relies on /dev/fd, which is not guaranteed
# available (observed: sandboxed environments can deny it outright with
# "Operation not permitted", silently degrading `diff` to report no
# differences even when the captured text differs).
printf '%s\n' "$BEFORE_OUT" >"$BEFORE_TXT"
printf '%s\n' "$AFTER_OUT" >"$AFTER_TXT"

if [ "$BEFORE_RC" -ne 0 ] && [ "$AFTER_RC" -ne 0 ]; then
    echo "config_render_diff.sh: render command failed at BOTH states (before rc=${BEFORE_RC}, after rc=${AFTER_RC}) -- nothing to compare" >&2
    echo "--- before output ---" >&2
    printf '%s\n' "$BEFORE_OUT" >&2
    echo "--- after output ---" >&2
    printf '%s\n' "$AFTER_OUT" >&2
    exit 2
fi

if [ -z "$BEFORE_OUT" ] && [ -z "$AFTER_OUT" ]; then
    echo "config_render_diff.sh: render command produced empty output at both states -- nothing to compare" >&2
    exit 2
fi

if [ "$BEFORE_RC" -ne 0 ] || [ "$AFTER_RC" -ne 0 ]; then
    echo "config_render_diff.sh: render command exit code differs (before rc=${BEFORE_RC}, after rc=${AFTER_RC}) -- treated as DIFFERS (Behavioral check PASSES; a broken/newly-passing assertion is itself a behavioral delta)"
    diff -u "$BEFORE_TXT" "$AFTER_TXT" || true
    exit 0
fi

if [ "$BEFORE_OUT" = "$AFTER_OUT" ]; then
    echo "config_render_diff.sh: IDENTICAL output for render command -- fails the Content Gate Behavioral check (settings serialize identically; likely a no-op with_* call)"
    exit 1
fi

diff -u "$BEFORE_TXT" "$AFTER_TXT" || true
echo "config_render_diff.sh: DIFFERS -- passes the Content Gate Behavioral check"
exit 0
