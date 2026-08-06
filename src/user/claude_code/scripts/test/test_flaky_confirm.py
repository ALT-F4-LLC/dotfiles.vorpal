#!/usr/bin/env python3
"""Fixture-driven checks for flaky_confirm.sh — the pass/fail tally and
verdict classification (STABLE/FLAKY/DETERMINISTICALLY BROKEN) core.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_flaky_confirm.py``.
Exit 0 = all asserts pass. No external dependencies; synthesizes flaky
behavior via a counter file bumped by the test command itself. Drives the
real CLI via subprocess.
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "flaky_confirm.sh"


def run(*args, env=None):
    proc = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True, env=env)
    return proc.returncode, proc.stdout, proc.stderr


def test_all_pass_verdict_stable():
    code, out, err = run("true", "3")
    assert code == 0, f"exit {code}: {err}"
    assert "Tally: 3 pass, 0 fail (of 3 runs)" in out, out
    assert "Verdict: STABLE (all 3 runs passed)" in out, out


def test_all_fail_verdict_deterministically_broken():
    code, out, err = run("false", "3")
    assert code == 0, f"exit {code}: {err}"
    assert "Tally: 0 pass, 3 fail (of 3 runs)" in out, out
    assert "Verdict: DETERMINISTICALLY BROKEN (all 3 runs failed)" in out, out


def test_alternating_result_verdict_flaky():
    d = Path(tempfile.mkdtemp(prefix="flaky_confirm_test_"))
    try:
        counter = d / "counter"
        counter.write_text("0")
        cmd = f"n=$(cat {counter}); n=$((n+1)); echo $n > {counter}; [ $((n % 2)) -eq 0 ]"
        code, out, err = run(cmd, "4")
        assert code == 0, f"exit {code}: {err}"
        assert "Tally: 2 pass, 2 fail (of 4 runs)" in out, out
        assert "Verdict: FLAKY (intermittent" in out, out
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_distinct_failure_signatures_deduped_with_counts():
    d = Path(tempfile.mkdtemp(prefix="flaky_confirm_test_"))
    try:
        counter = d / "counter"
        counter.write_text("0")
        cmd = f"n=$(cat {counter}); n=$((n+1)); echo $n > {counter}; echo failure-msg-$n; exit 1"
        code, out, err = run(cmd, "3")
        assert code == 0, f"exit {code}: {err}"
        assert "Distinct failure signatures (3):" in out, out
        for i in (1, 2, 3):
            assert f"failure-msg-{i}" in out, out
        assert "(seen 1x)" in out, out
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_repeated_identical_signature_dedupes_to_one_with_occurrence_count():
    code, out, err = run("false", "3")
    assert code == 0, f"exit {code}: {err}"
    assert "Distinct failure signatures (1):" in out, out
    assert "(seen 3x)" in out, out


def test_tail_lines_env_var_limits_signature_capture():
    code, out, err = run("printf 'line1\\nline2\\nline3\\n'; exit 1", "1",
                         env={**__import__("os").environ, "FLAKY_CONFIRM_TAIL_LINES": "1"})
    assert code == 0, f"exit {code}: {err}"
    assert "line3" in out, out
    assert "line1" not in out and "line2" not in out, out


def test_default_n_is_five():
    code, out, err = run("true")
    assert code == 0, f"exit {code}: {err}"
    assert "Tally: 5 pass, 0 fail (of 5 runs)" in out, out


def test_non_integer_n_rejected():
    code, out, err = run("true", "abc")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "n must be a positive integer" in err, err


def test_zero_n_rejected():
    code, out, err = run("true", "0")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "n must be >= 1" in err, err


def test_usage_error_on_bad_arg_count():
    code, out, err = run()
    assert code == 1, f"exit {code}"
    assert "Usage: flaky_confirm.sh" in err, err
    code, out, err = run("true", "3", "extra")
    assert code == 1, f"exit {code}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
