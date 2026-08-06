#!/usr/bin/env python3
"""Fixture-driven checks for cycle_metrics.py — the rolling-window threshold
math over the dispatch ledger.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_cycle_metrics.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/cycle_metrics/ so it
never touches the real dispatch ledger. Drives the real CLI via subprocess.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "cycle_metrics.py"
FIXTURES = HERE / "fixtures" / "cycle_metrics"


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_all_thresholds_ok_exits_zero():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_ok.md"))
    assert code == 0, f"exit {code}: {err}"
    assert "fix_rounds rate: 0/5" in out and "[OK]" in out, out
    assert "MANDATORY EVOLVE-* REVIEW: NO" in out, out


def test_fix_rounds_rate_blown_exits_one():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_fix_rounds_blown.md"))
    assert code == 1, f"exit {code}: {err}"
    assert "fix_rounds rate: 3/5 cycles had fix_rounds>=1 (0.60" in out, out
    assert "[BLOWN]" in out, out
    assert "MANDATORY EVOLVE-* REVIEW: YES — blown threshold(s): fix_rounds rate" in out, out


def test_review_spawns_avg_blown_exits_one():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_review_spawns_blown.md"))
    assert code == 1, f"exit {code}: {err}"
    assert "review_spawns_total avg: 3.20" in out, out
    assert "review_spawns_total avg" in out.split("blown threshold(s): ")[-1], out


def test_degraded_count_blown_exits_one():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_degraded_blown.md"))
    assert code == 1, f"exit {code}: {err}"
    assert "DEGRADED-fallback count: 2 in window" in out, out
    assert "DEGRADED-fallback count" in out.split("blown threshold(s): ")[-1], out


def test_insufficient_sample_skips_threshold_evaluation():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_insufficient.md"))
    assert code == 0, f"exit {code}: {err}"
    assert "insufficient data (window=3 < MIN_SAMPLE_SIZE=5) — not evaluated" in out, out
    assert "MANDATORY EVOLVE-* REVIEW: NO" in out, out


def test_rolling_window_truncates_to_most_recent_entries():
    # 12 total entries; only the last 10 form the window. The first 2 entries
    # carry fix_rounds=1 but fall OUTSIDE the window, so the windowed rate
    # must read 0/10, not 2/12 -- proving recency truncation, not full-history
    # aggregation.
    code, out, err = run("--ledger", str(FIXTURES / "ledger_rolling_window.md"))
    assert code == 0, f"exit {code}: {err}"
    assert "Rolling window: last 10 of 12 cycle(s)" in out, out
    assert "fix_rounds rate: 0/10 cycles had fix_rounds>=1" in out, out


def test_unparseable_line_skipped_with_warning_but_run_continues():
    code, out, err = run("--ledger", str(FIXTURES / "ledger_unparseable.md"))
    assert code == 0, f"exit {code}: {err}"
    assert "skipping unparseable line 2" in err, err
    assert "5 total cycle(s) recorded" in out, out


def test_missing_ledger_file_exits_zero_with_stderr_note():
    code, out, err = run("--ledger", str(FIXTURES / "does-not-exist.md"))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "no ledger found at" in err, err
    assert out == "", out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
