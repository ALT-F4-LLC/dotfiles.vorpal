#!/usr/bin/env python3
"""Fixture-driven checks for g5_check.sh — scope resolution (staged,
uncommitted, branch), regex-command extraction from added docs/tdd|
docs/spec diff lines, real execution + hit-count reporting, the
BRE-`\\|`-under-`-E` static false-negative flag, and the argv-validation
attack cases (command injection, path confinement, -f/-R hard rejects,
ReDoS timeout) that replaced the original `bash -c` execution.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_g5_check.py``.
Exit 0 = all asserts pass. Each case builds a throwaway git repo (via
``git init`` in a temp dir, gpgsign disabled), commits a docs/tdd/ baseline,
then drives the real CLI via subprocess against uncommitted/staged/branch
diffs.
"""
import os
import subprocess
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "g5_check.sh"


def new_repo():
    d = os.path.realpath(tempfile.mkdtemp(prefix="g5_check_repo_"))
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


def run_script(repo, *args):
    proc = subprocess.run(
        ["bash", str(SCRIPT), *args], cwd=repo, capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


TDD_PATH = "docs/tdd/test.md"
OTHER_PATH = "docs/tdd/other.md"


def base_repo():
    repo = new_repo()
    write(os.path.join(repo, TDD_PATH), "# Test TDD\n\nBaseline content.\n")
    write(os.path.join(repo, OTHER_PATH), "# Other\n\nUnrelated fixed content.\n")
    commit_all(repo)
    return repo


def test_clean_regex_runs_and_reports_hits():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -E 'Baseline|content' " + TDD_PATH + "` and expect hits.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[RAN" in out, out
    assert "BRE-PIPE-WARNING" not in out, out
    assert "1/1 clean" in out, out


def test_bre_pipe_false_negative_flagged():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -E 'foo\\|bar' " + TDD_PATH + "`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[BRE-PIPE-WARNING]" in out, out
    assert "literal pipe, not alternation" in out, out


def test_failing_regex_reported_as_fail():
    # Target OTHER_PATH (fixed baseline content, untouched by this diff) so
    # the search pattern -- which necessarily appears verbatim in TDD_PATH's
    # own new line -- cannot self-match; the pattern genuinely has zero
    # hits in the file it searches.
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -E 'nonexistent-pattern-xyz' " + OTHER_PATH + "`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[FAIL" in out, out


def test_staged_scope():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -E 'Baseline' " + TDD_PATH + "`.\n")
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    code, out, err = run_script(repo, "staged")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[RAN" in out, out


def test_branch_scope():
    # Base branch stays checked out with no changes; "feature" carries the
    # added AC-regex line. Exercises the branch-name resolution path
    # (primary `main...{scope}` form, or its `{scope}`-only fallback when
    # no local "main" ref exists in this throwaway repo).
    repo = base_repo()
    subprocess.run(["git", "checkout", "-q", "-b", "feature"], cwd=repo, check=True)
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -E 'Baseline' " + TDD_PATH + "`.\n")
    commit_all(repo, "on feature")
    base_branch = subprocess.run(
        ["git", "rev-list", "--max-parents=0", "HEAD"], cwd=repo, check=True,
        capture_output=True, text=True,
    ).stdout.strip()
    subprocess.run(["git", "checkout", "-q", base_branch], cwd=repo, check=True)
    code, out, err = run_script(repo, "feature")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[RAN" in out, out


def test_no_docs_tdd_or_spec_diff_exits_two():
    repo = base_repo()
    other = os.path.join(repo, "README.md")
    write(other, "# readme\n\nRun `grep -E 'x' README.md`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 2, f"exit {code}: {out}{err}"


def test_no_grep_commands_in_diff_exits_two():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nJust more prose, no backticked grep commands.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no backtick-quoted 'grep" in err, err


def test_unresolvable_scope_exits_two():
    repo = base_repo()
    code, out, err = run_script(repo, "not-a-branch-or-file")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "could not resolve scope" in err, err


def test_usage_with_no_args_exits_two():
    repo = base_repo()
    code, out, err = run_script(repo)
    assert code == 2, f"exit {code}: {out}{err}"


def test_command_injection_semicolon_blocked():
    repo = base_repo()
    marker = os.path.join(repo, "injected_marker")
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep Baseline {TDD_PATH} ; touch {marker}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out
    assert not os.path.exists(marker), "injected command executed -- marker file was created"


def test_argv0_exact_match_required():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grepper -x {TDD_PATH}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out


def test_absolute_path_outside_repo_root_blocked():
    outside_dir = tempfile.mkdtemp(prefix="g5_check_outside_")
    canary = os.path.join(outside_dir, "secret.txt")
    write(canary, "TOP-SECRET-CANARY-VALUE\n")
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep -r TOP-SECRET {canary}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out
    assert "TOP-SECRET-CANARY-VALUE" not in out, out


def test_parent_traversal_outside_repo_root_blocked():
    repo = base_repo()
    outside_dir = os.path.dirname(repo)
    canary = os.path.join(outside_dir, "traversal_canary_" + os.path.basename(repo) + ".txt")
    write(canary, "TRAVERSAL-CANARY-VALUE\n")
    try:
        rel = os.path.relpath(canary, repo)
        with open(os.path.join(repo, TDD_PATH), "a") as f:
            f.write(f"\nRun `grep TRAVERSAL-CANARY {rel}`.\n")
        code, out, err = run_script(repo, "uncommitted")
        assert code == 1, f"exit {code}: {out}{err}"
        assert "[REJECTED" in out, out
        assert "TRAVERSAL-CANARY-VALUE" not in out, out
    finally:
        os.remove(canary)


def test_dash_f_pattern_file_rejected():
    repo = base_repo()
    secret_patterns = os.path.join(repo, "secret_patterns.txt")
    write(secret_patterns, "Baseline\n")
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep -f {secret_patterns} {TDD_PATH}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out


def test_dash_dash_file_long_form_rejected():
    repo = base_repo()
    secret_patterns = os.path.join(repo, "secret_patterns.txt")
    write(secret_patterns, "Baseline\n")
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep --file={secret_patterns} {TDD_PATH}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out


def test_dereference_recursive_symlink_escape_blocked():
    outside_dir = tempfile.mkdtemp(prefix="g5_check_outside_")
    canary = os.path.join(outside_dir, "secret.txt")
    write(canary, "SYMLINK-ESCAPE-CANARY\n")
    repo = base_repo()
    os.makedirs(os.path.join(repo, "src"), exist_ok=True)
    os.symlink(outside_dir, os.path.join(repo, "src", "evil"))
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write("\nRun `grep -R SYMLINK-ESCAPE src/`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out
    assert "SYMLINK-ESCAPE-CANARY" not in out, out


def test_dereference_recursive_short_flag_blocked_anywhere_in_cluster():
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep -nR Baseline {TDD_PATH}`.\n")
    code, out, err = run_script(repo, "uncommitted")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[REJECTED" in out, out


def test_timeout_kills_slow_grep():
    # A real PCRE catastrophic-backtracking payload (-P '(a+)+$') isn't a
    # portable way to exercise the timeout: this sandbox's system grep is
    # BSD grep 2.6.0-FreeBSD, which rejects -P outright ("invalid option")
    # and whose -E engine doesn't backtrack at all (verified empirically --
    # 36 'a's still runs in ~2ms). -P itself stays ALLOWED in the script
    # (relying on the timeout as the sole ReDoS mitigation, per plan), but
    # testing the timeout mechanism itself must not depend on a specific
    # grep build's regex-engine performance. Instead, prepend a fake
    # "grep" that just sleeps to PATH -- this deterministically exercises
    # the real subprocess.run(..., timeout=...) code path regardless of
    # platform.
    repo = base_repo()
    with open(os.path.join(repo, TDD_PATH), "a") as f:
        f.write(f"\nRun `grep -P '(a+)+$' {TDD_PATH}`.\n")
    fake_bin_dir = tempfile.mkdtemp(prefix="g5_check_fakebin_")
    fake_grep = os.path.join(fake_bin_dir, "grep")
    write(fake_grep, "#!/bin/bash\nsleep 5\necho should-never-print\n")
    os.chmod(fake_grep, 0o755)
    env = os.environ.copy()
    env["PATH"] = fake_bin_dir + os.pathsep + env["PATH"]
    env["G5_CHECK_TIMEOUT"] = "1"
    start = time.monotonic()
    proc = subprocess.run(
        ["bash", str(SCRIPT), "uncommitted"], cwd=repo, capture_output=True,
        text=True, env=env, timeout=15,
    )
    elapsed = time.monotonic() - start
    assert proc.returncode == 1, f"exit {proc.returncode}: {proc.stdout}{proc.stderr}"
    assert "[TIMEOUT" in proc.stdout, proc.stdout
    assert "should-never-print" not in proc.stdout, proc.stdout
    assert elapsed < 4, f"script did not honor the 1s timeout override, took {elapsed:.1f}s (fake grep sleeps 5s)"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
