#!/usr/bin/env python3
"""Regression fixture pinning self_review_scan.sh's COMMENTED_RE behavior.

self_review_scan.sh:69 is the canonical (only) definition of the
commented-out-code heuristic repo-wide. This test pins its current matching
behavior against representative known-good/known-bad samples across the
comment-leader styles it scans (#, //, -- ) so future edits to the regex
can be verified against fixed expectations rather than hand-derived intent.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_self_review_scan.py``.
Exit 0 = all asserts pass. Builds a throwaway git repo under $TMPDIR per test
using plumbing commands only (write-tree/commit-tree/update-ref) — never
`git add`/`git commit`, which this repo's commit-guard hook blocks in
non-interactive permission modes. Drives the real CLI via subprocess.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "self_review_scan.sh"

GIT_IDENTITY_ENV = {
    "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "t@example.com",
    "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "t@example.com",
}

# Lines COMMENTED_RE is expected to flag as commented-out code (heuristic
# hit: leading comment leader, payload ending in ;{} or an assignment/call
# shape). Verified against the live regex in self_review_scan.sh:69.
KNOWN_BAD = [
    "# result = compute();",
    "// counter++;",
    "-- local config = {",
    "# doStuff(",
    "// value =",
    "    // helper(x, y);",
    # Documented accepted false positive (self_review_scan.sh:69 comment):
    # prose that happens to end in a semicolon is expected to match.
    "# Keep this simple for now;",
]

# Lines COMMENTED_RE is expected to leave unflagged: ordinary prose comments,
# shebangs, and comment-shaped code whose payload doesn't end in the tracked
# shape (e.g. a trailing close-paren, which the heuristic does not cover —
# a known limitation pinned here deliberately).
KNOWN_GOOD = [
    "# This is a regular comment.",
    "// Explains why this branch exists",
    "# Explains the WHY behind a workaround.",
    "-- Lua-style prose comment explaining behavior.",
    "# def helper():",
    "// See https://example.com/docs for details",
    "#!/bin/bash",
    "# NOTE: this is a heuristic, false positives expected.",
    "# self.value = compute()",
    # Payload-shape exclusion: no trailing ;{} and no alnum+space+=/( before
    # EOL, so this is unflagged regardless of leader (self_review_scan.sh:69
    # comment's payload-shape rule, not the trailing-space rule below).
    "    --flag)",
    # The -- leader requires a trailing space specifically so shell
    # case-statement patterns like this are not mistaken for a SQL/Lua
    # comment (self_review_scan.sh:69 comment). Unlike "--flag)" above, this
    # line's payload DOES end in ";" (satisfies the ending-shape rule), so it
    # isolates the trailing-space requirement: it is only unflagged because
    # "--pre" (no space after "--") fails the leader match.
    "        --pre) PRE=1 ;;",
]


def make_repo():
    """Empty git repo with a single empty root commit, built via plumbing only."""
    repo = Path(tempfile.mkdtemp(prefix="self_review_scan_test_"))
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    empty_tree = subprocess.run(["git", "write-tree"], cwd=repo, capture_output=True,
                                text=True, check=True).stdout.strip()
    commit = subprocess.run(["git", "commit-tree", empty_tree, "-m", "baseline"], cwd=repo,
                            capture_output=True, text=True, check=True,
                            env={**os.environ, **GIT_IDENTITY_ENV}).stdout.strip()
    subprocess.run(["git", "update-ref", "refs/heads/main", commit], cwd=repo, check=True)
    subprocess.run(["git", "symbolic-ref", "HEAD", "refs/heads/main"], cwd=repo, check=True)
    return repo


def run(cwd, *args):
    proc = subprocess.run(["bash", str(SCRIPT), "--all", *args], cwd=cwd,
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def commented_findings(stdout):
    """Return the free-text content of each 'commented' category finding line."""
    findings = []
    for line in stdout.splitlines():
        m = re.match(r"^commented\s+\S+: (.*)$", line)
        if m:
            findings.append(m.group(1))
    return findings


def test_known_bad_lines_are_flagged_commented():
    repo = make_repo()
    try:
        fixture = repo / "fixture_bad.txt"
        fixture.write_text("\n".join(KNOWN_BAD) + "\n")
        code, out, err = run(repo, str(fixture))
        assert code == 1, f"expected findings (exit 1), got {code}: {err}"
        findings = commented_findings(out)
        assert len(findings) == len(KNOWN_BAD), (
            f"expected {len(KNOWN_BAD)} commented findings, got {len(findings)}\n"
            f"stdout:\n{out}"
        )
        for expected in KNOWN_BAD:
            assert any(expected == f for f in findings), (
                f"expected known-bad line flagged as commented, not found: {expected!r}\n"
                f"stdout:\n{out}"
            )
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_known_good_lines_are_not_flagged_commented():
    repo = make_repo()
    try:
        fixture = repo / "fixture_good.txt"
        fixture.write_text("\n".join(KNOWN_GOOD) + "\n")
        _code, out, _err = run(repo, str(fixture))
        findings = commented_findings(out)
        assert findings == [], (
            f"expected no commented findings among known-good lines, got: {findings}\n"
            f"stdout:\n{out}"
        )
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    failures = 0
    for test in tests:
        try:
            test()
            print(f"PASS: {test.__name__}")
        except AssertionError as e:
            failures += 1
            print(f"FAIL: {test.__name__}: {e}")
    if failures:
        print(f"{failures}/{len(tests)} tests failed")
        sys.exit(1)
    print(f"{len(tests)}/{len(tests)} tests passed")
    sys.exit(0)


if __name__ == "__main__":
    main()
