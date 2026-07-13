#!/usr/bin/env python3
"""Fixture-driven checks for symmetry_check.py — the drift-detection core.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_symmetry_check.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/symmetry/ so it never
touches the peer signals fixtures. Drives the real CLI via subprocess.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "symmetry_check.py"
FIXTURES = HERE / "fixtures" / "symmetry"
AGENTS_SYMMETRIC = FIXTURES / "agents_symmetric.md"
SKILLS_SYMMETRIC = FIXTURES / "skills_symmetric.md"
SKILLS_DRIFTED = FIXTURES / "skills_drifted.md"
AGENTS_IMPACT_CLASS = FIXTURES / "agents_impact_class.md"
SKILLS_IMPACT_CLASS_SYMMETRIC = FIXTURES / "skills_impact_class_symmetric.md"
SKILLS_IMPACT_CLASS_DRIFTED = FIXTURES / "skills_impact_class_drifted.md"


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args],
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_symmetric_pair_exits_zero():
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out


def test_drifted_fixture_exits_nonzero_with_diff():
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    # Only the innovation-scanner MISSION line drifts (improvements -> refinements);
    # impact-class stays symmetric, so `--check all` reports exactly one drift.
    assert "innovation-scanner: DRIFT" in out, out


def test_drifted_single_check_exits_nonzero():
    code, out, err = run("--check", "innovation-scanner", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"


def test_impact_class_symmetric_pair_exits_zero():
    code, out, err = run("--check", "impact-class", "--agents-file", str(AGENTS_IMPACT_CLASS),
                         "--skills-file", str(SKILLS_IMPACT_CLASS_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out


def test_impact_class_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "impact-class", "--agents-file", str(AGENTS_IMPACT_CLASS),
                         "--skills-file", str(SKILLS_IMPACT_CLASS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "impact-class: DRIFT" in out, out


def test_missing_file_exits_two():
    missing = FIXTURES / "does-not-exist.md"
    code, out, err = run("--check", "all", "--agents-file", str(missing),
                         "--skills-file", str(SKILLS_SYMMETRIC))
    assert code == 2, f"expected exit 2 for missing --agents-file, got {code}"
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(missing))
    assert code == 2, f"expected exit 2 for missing --skills-file, got {code}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
