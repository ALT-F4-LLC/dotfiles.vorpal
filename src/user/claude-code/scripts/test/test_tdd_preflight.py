#!/usr/bin/env python3
"""Fixture-driven checks for tdd_preflight.sh — the check_citations.py chain
plus the numbered cross-reference reconciliation between a TDD and its
companion doc.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_tdd_preflight.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/tdd_preflight/ so it
never touches real docs/tdd content. Runs with cwd inside this repo (needed
for tdd_preflight.sh's own git-repo check) and passes repo-relative fixture
paths. Drives the real CLI via subprocess.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "tdd_preflight.sh"
REPO_ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip())
FIXTURES_REL = "src/user/claude-code/scripts/test/fixtures/tdd_preflight"


def run(*args):
    proc = subprocess.run(["bash", str(SCRIPT), *args], cwd=str(REPO_ROOT),
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def fixture(name):
    return f"{FIXTURES_REL}/{name}"


def test_resolved_citation_no_companion_exits_zero():
    code, out, err = run(fixture("citations_ok.md"))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "citations: OK (1 found, all resolved)" in out, out
    assert "tdd_preflight.sh: OK" in out, out


def test_missing_citation_no_companion_exits_one():
    code, out, err = run(fixture("citations_missing.md"))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "MISSING" in out and "does-not-exist.md" in out, out
    assert "tdd_preflight.sh: FAIL" in out, out


def test_cross_reference_resolves_via_self_anchor_and_companion_anchor():
    # "§3.2" resolves against a's own "### 3.2" heading anchor; "Step 9"
    # resolves against companion b's "**Step 9**" label anchor.
    code, out, err = run(fixture("xref_ok_a.md"), fixture("xref_ok_b.md"))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "OK: all numbered cross-references resolved" in out, out
    assert "tdd_preflight.sh: OK" in out, out


def test_dangling_cross_reference_reported_missing():
    code, out, err = run(fixture("xref_mismatch_a.md"), fixture("xref_mismatch_b.md"))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "MISSING:" in out and "references '4'" in out, out
    assert "no matching numbered anchor found in either doc" in out, out
    assert "tdd_preflight.sh: FAIL" in out, out


def test_usage_error_on_bad_arg_count():
    code, out, err = run()
    assert code == 1, f"exit {code}"
    assert "Usage: tdd_preflight.sh" in err, err
    code, out, err = run("a", "b", "c")
    assert code == 1, f"exit {code}"


def test_missing_artifact_file_exits_one():
    code, out, err = run(fixture("does-not-exist.md"))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "artifact not found" in err, err


def test_missing_companion_file_exits_one():
    code, out, err = run(fixture("citations_ok.md"), fixture("does-not-exist.md"))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "companion not found" in err, err


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
