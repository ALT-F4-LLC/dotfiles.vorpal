#!/usr/bin/env python3
"""Fixture-driven checks for secret_scan.sh — the 16-pattern regex battery,
redaction, and entropy/placeholder guards.

Standalone (no pytest): ``python3 .claude/scripts/test/test_secret_scan.py``.
Exit 0 = all asserts pass. Builds a throwaway git repo under $TMPDIR per test
using plumbing commands only (write-tree/commit-tree/update-ref) — never
`git add`/`git commit`, which this repo's commit-guard hook blocks in
non-interactive permission modes — so it never touches real repo history.
Drives the real CLI via subprocess.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "secret_scan.sh"

GIT_IDENTITY_ENV = {
    "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "t@example.com",
    "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "t@example.com",
}


def make_repo():
    """Empty git repo with a single empty root commit, built via plumbing only."""
    repo = Path(tempfile.mkdtemp(prefix="secret_scan_test_"))
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    empty_tree = subprocess.run(["git", "write-tree"], cwd=repo, capture_output=True,
                                text=True, check=True).stdout.strip()
    commit = subprocess.run(["git", "commit-tree", empty_tree, "-m", "baseline"], cwd=repo,
                            capture_output=True, text=True, check=True,
                            env={**__import__("os").environ, **GIT_IDENTITY_ENV}).stdout.strip()
    subprocess.run(["git", "update-ref", "refs/heads/main", commit], cwd=repo, check=True)
    subprocess.run(["git", "symbolic-ref", "HEAD", "refs/heads/main"], cwd=repo, check=True)
    return repo


def run(cwd, *args):
    proc = subprocess.run(["bash", str(SCRIPT), *args], cwd=cwd, capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def scan(repo, files):
    """Write untracked files {relpath: content} into repo, then scan 'uncommitted'."""
    for relpath, content in files.items():
        p = repo / relpath
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
    code, out, err = run(repo, "uncommitted")
    assert code == 0, f"secret_scan.sh must always exit 0 (report-only): {code}: {err}"
    return json.loads(out)


def test_aws_access_key_detected_high_confidence_and_value_redacted():
    repo = make_repo()
    try:
        result = scan(repo, {"secrets.txt": "export KEY = AKIAABCDEFGHIJKLMNOP\n"})
        finding = next(f for f in result["findings"] if f["pattern_name"] == "aws_access_key_id")
        assert finding["confidence"] == "high", finding
        assert finding["redacted"] == "AKIA...(len=20)", finding
        assert "AKIAABCDEFGHIJKLMNOP" not in json.dumps(result), "raw secret value must never be emitted"
        assert result["high_confidence_count"] == 1, result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_placeholder_value_not_flagged():
    repo = make_repo()
    try:
        result = scan(repo, {"placeholder.txt": "token = 'changemechangeme1234'\n"})
        assert result["findings"] == [], result
        assert result["added_lines_scanned"] == 1, result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_low_entropy_value_not_flagged():
    repo = make_repo()
    try:
        result = scan(repo, {"entropy.txt": 'token = "aaaaaaaaaaaaaaaaaaaa"\n'})
        assert result["findings"] == [], result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_pragma_allowlist_line_excluded_from_scan_and_count():
    repo = make_repo()
    try:
        baseline = scan(repo, {"a.txt": "harmless\n"})
        assert baseline["added_lines_scanned"] == 1, baseline
        # pragma-tagged lines are skipped before both the finding scan AND the
        # added_lines_scanned counter, so the count stays at 1 (only a.txt's line).
        result = scan(repo, {"pragma.txt": "export KEY = AKIAZZZZZZZZZZZZZZZZ  # pragma: allowlist secret\n"})
        assert result["added_lines_scanned"] == 1, result
        assert result["findings"] == [], result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_fixtures_prefix_self_excluded():
    repo = make_repo()
    try:
        result = scan(repo, {".claude/scripts/test/dummy.sh": "export KEY = AKIAABCDEFGHIJKLMNOP\n"})
        assert result["added_lines_scanned"] == 0, result
        assert result["findings"] == [], result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_site_detection_flags_echoed_secret_var_by_name_not_value():
    repo = make_repo()
    try:
        result = scan(repo, {"site.txt": 'echo "$MY_SECRET_TOKEN"\n'})
        finding = next(f for f in result["findings"] if f["pattern_name"] == "env_var_echo_shell")
        assert finding["confidence"] == "advisory", finding
        assert finding["redacted"] == "var=MY_SECRET_TOKEN", finding
        assert result["advisory_count"] == 1, result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_generic_assignment_and_jwt_and_bearer_patterns():
    repo = make_repo()
    try:
        result = scan(repo, {
            "dq.txt": 'password: "SuperSecretValue1234"\n',
            "sq.txt": "credential = 'AnotherSecretValue99'\n",
            "jwt.txt": "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0."
                       "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c\n",
        })
        names = {f["pattern_name"] for f in result["findings"]}
        assert names == {"generic_secret_assignment_dq", "generic_secret_assignment_sq",
                         "jwt_triple", "bearer_token"}, names
        assert result["high_confidence_count"] == 1, result  # jwt_triple is the only high-tier match
        assert result["advisory_count"] == 3, result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_usage_error_on_bad_arg_count():
    code, out, err = run(HERE)
    assert code == 1, f"exit {code}"
    assert "Usage: secret_scan.sh" in err, err
    code, out, err = run(HERE, "a", "b")
    assert code == 1, f"exit {code}"
    assert "Usage: secret_scan.sh" in err, err


def test_not_inside_git_repo_exits_one():
    outside = Path(tempfile.mkdtemp(prefix="secret_scan_notgit_"))
    try:
        code, out, err = run(outside, "uncommitted")
        assert code == 1, f"exit {code}: {out}{err}"
        assert "not inside a git repository" in err, err
    finally:
        shutil.rmtree(outside, ignore_errors=True)


def commit_file(repo, relpath, content, message="seed"):
    """Commit `content` at `relpath` onto refs/heads/main via plumbing only
    (hash-object/update-index/write-tree/commit-tree/update-ref) — same
    no-add/no-commit convention as make_repo()."""
    blob = subprocess.run(["git", "hash-object", "-w", "--stdin"], cwd=repo, input=content,
                          capture_output=True, text=True, check=True).stdout.strip()
    subprocess.run(["git", "update-index", "--add", "--cacheinfo", f"100644,{blob},{relpath}"],
                   cwd=repo, check=True)
    tree = subprocess.run(["git", "write-tree"], cwd=repo, capture_output=True, text=True,
                          check=True).stdout.strip()
    parent = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True,
                            text=True, check=True).stdout.strip()
    commit = subprocess.run(["git", "commit-tree", tree, "-p", parent, "-m", message], cwd=repo,
                            capture_output=True, text=True, check=True,
                            env={**os.environ, **GIT_IDENTITY_ENV}).stdout.strip()
    subprocess.run(["git", "update-ref", "refs/heads/main", commit], cwd=repo, check=True)


def test_self_path_excluded_from_scan():
    """Guardrail: self-exclusion. Existing fixtures-prefix test only covers the
    FIXTURES_PREFIX branch — this covers the separate exact-match SELF_PATH branch."""
    repo = make_repo()
    try:
        result = scan(repo, {".claude/scripts/secret_scan.sh": "export KEY = AKIAABCDEFGHIJKLMNOP\n"})
        assert result["added_lines_scanned"] == 0, result
        assert result["findings"] == [], result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_added_lines_only_scope_context_and_removed_secrets_ignored():
    """Guardrail: added-lines-only scope. A secret already committed must never
    be flagged as unchanged context, nor when a line containing it is removed."""
    repo = make_repo()
    try:
        secret_line = "export SECRET_KEY = AKIAABCDEFGHIJKLMNOP\n"
        commit_file(repo, "config.txt", secret_line)

        (repo / "config.txt").write_text(secret_line + "NEW_HARMLESS_LINE\n")
        code, out, err = run(repo, "uncommitted")
        assert code == 0, err
        result = json.loads(out)
        assert result["findings"] == [], f"context line must not be scanned: {result}"
        assert result["added_lines_scanned"] == 1, result

        (repo / "config.txt").write_text("NEW_HARMLESS_LINE\n")
        code, out, err = run(repo, "uncommitted")
        assert code == 0, err
        result = json.loads(out)
        assert result["findings"] == [], f"removed line must not be scanned: {result}"
        assert result["added_lines_scanned"] == 1, result
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_no_disk_cache_persisted_between_runs():
    """Guardrail: no disk cache. Consecutive runs must reflect current content
    (no stale memoized result), and no secret_scan_*-prefixed temp file may
    survive past the script's own trap-based cleanup."""
    repo = make_repo()
    tmp_root = Path(os.environ.get("TMPDIR", "/tmp"))
    try:
        before = {p.name for p in tmp_root.iterdir() if p.name.startswith("secret_scan_")}

        result1 = scan(repo, {"cache1.txt": "export KEY = AKIAABCDEFGHIJKLMNOP\n"})
        assert result1["high_confidence_count"] == 1, result1

        (repo / "cache1.txt").write_text("harmless line\n")
        code, out, err = run(repo, "uncommitted")
        assert code == 0, err
        result2 = json.loads(out)
        assert result2["findings"] == [], f"stale/cached result returned: {result2}"

        after = {p.name for p in tmp_root.iterdir() if p.name.startswith("secret_scan_")}
        assert after == before, f"secret_scan.sh must not persist cache files: {after - before}"
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_redaction_never_leaks_raw_secret_value_across_pattern_types():
    """Guardrail: redaction-only output, broadened beyond the single AWS-pattern
    check in test_aws_access_key_detected... to 4 distinct pattern families."""
    repo = make_repo()
    try:
        raw_values = {
            "aws": "AKIAABCDEFGHIJKLMNOP",
            "dq": "SuperSecretValue1234",
            "sq": "AnotherSecretValue99",
            "bearer": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0."
                      "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
        }
        result = scan(repo, {
            "aws.txt": "export KEY = AKIAABCDEFGHIJKLMNOP\n",
            "dq.txt": 'password: "SuperSecretValue1234"\n',
            "sq.txt": "credential = 'AnotherSecretValue99'\n",
            "jwt.txt": "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0."
                       "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c\n",
        })
        assert len(result["findings"]) >= 4, result
        dumped = json.dumps(result)
        for label, raw in raw_values.items():
            assert raw not in dumped, f"raw secret leaked for {label}: {raw}"
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
