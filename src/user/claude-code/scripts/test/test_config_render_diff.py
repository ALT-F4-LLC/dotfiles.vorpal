#!/usr/bin/env python3
"""Fixture-driven checks for config_render_diff.sh — worktree isolation,
exit-code capture across the render command, the IDENTICAL/DIFFERS/
precondition branches, and one honest real-repo integration case
documenting the script's stated assert-only-test caveat.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_config_render_diff.py``.
Exit 0 = all asserts pass. Most cases use a throwaway synthetic git repo
with a plain `cat`-based render command (no cargo/Rust dependency, fast).
One slower case (skippable via --fast) drives the real dotfiles repo's
existing src/user/codex.rs test via a real `cargo test` render command.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "config_render_diff.sh"
REPO_ROOT = HERE.parent.parent.parent.parent.parent

FAST_ONLY = "--fast" in sys.argv


def new_repo():
    d = os.path.realpath(tempfile.mkdtemp(prefix="config_render_diff_repo_"))
    subprocess.run(["git", "init", "-q"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.com"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=d, check=True)
    subprocess.run(["git", "config", "commit.gpgsign", "false"], cwd=d, check=True)
    return d


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def commit_all(repo, msg="commit"):
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-q", "-m", msg], cwd=repo, check=True)


def run(repo, *args):
    proc = subprocess.run(
        ["bash", str(SCRIPT), *args], cwd=repo, capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


def test_usage_with_no_args_exits_two():
    repo = new_repo()
    code, out, err = run(repo)
    assert code == 2, f"exit {code}: {out}{err}"


def test_not_a_git_repo_exits_two():
    tmp = tempfile.mkdtemp(prefix="config_render_diff_nogit_")
    code, out, err = run(tmp, "cat config.txt")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "not inside a git repository" in err, err


def test_identical_when_content_unchanged():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    code, out, err = run(repo, "cat config.txt", "HEAD", "worktree")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "IDENTICAL" in out, out
    assert "fails the Content Gate Behavioral check" in out, out


def test_differs_when_content_changed_uncommitted():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    write(os.path.join(repo, "config.txt"), "v2\n")
    code, out, err = run(repo, "cat config.txt", "HEAD", "worktree")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DIFFERS" in out, out
    assert "-v1" in out and "+v2" in out, out


def test_differs_between_two_refs():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo, "v1")
    write(os.path.join(repo, "config.txt"), "v2\n")
    commit_all(repo, "v2")
    code, out, err = run(repo, "cat config.txt", "HEAD~1", "HEAD")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DIFFERS" in out, out


def test_both_render_commands_fail_exits_two():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    code, out, err = run(repo, "cat nonexistent-file.txt", "HEAD", "worktree")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "render command failed at BOTH states" in err, err


def test_empty_output_both_states_exits_two():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    code, out, err = run(repo, "printf ''", "HEAD", "worktree")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "produced empty output at both states" in err, err


def test_rc_differs_with_identical_output_is_still_differs():
    # config.txt stays "v1" at both states; only a marker file's presence
    # (which flips the render command's own exit code, output text
    # unchanged) differs between HEAD and the uncommitted worktree.
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    write(os.path.join(repo, "marker.txt"), "present\n")
    cmd = "cat config.txt; test -f marker.txt"
    code, out, err = run(repo, cmd, "HEAD", "worktree")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "render command exit code differs" in out, out
    assert "treated as DIFFERS" in out, out


def test_worktrees_cleaned_up_after_run():
    repo = new_repo()
    write(os.path.join(repo, "config.txt"), "v1\n")
    commit_all(repo)
    write(os.path.join(repo, "config.txt"), "v2\n")
    run(repo, "cat config.txt", "HEAD", "worktree")
    listing = subprocess.run(
        ["git", "worktree", "list"], cwd=repo, capture_output=True, text=True, check=True
    ).stdout
    # Only the main worktree (repo itself) should remain.
    assert listing.count("\n") == 1, f"leaked worktree(s):\n{listing}"


def test_real_repo_codex_assert_only_test_is_identical_when_unchanged():
    # Honest integration case per the script's own documented caveat: an
    # assert-only render command (codex.rs's existing test, no println!)
    # correctly reports IDENTICAL for a truly unchanged state -- it cannot
    # demonstrate a true DIFFERS without a println!-based render target,
    # which does not exist yet (tracked as a Discovered follow-up).
    if FAST_ONLY:
        return
    code, out, err = run(
        str(REPO_ROOT),
        "cargo test serializes_current_config_shape -- --nocapture",
        "HEAD", "worktree",
    )
    assert code == 1, f"exit {code}: {out}{err}"
    assert "IDENTICAL" in out, out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
