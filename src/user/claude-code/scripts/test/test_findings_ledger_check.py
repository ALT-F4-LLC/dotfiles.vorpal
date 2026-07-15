#!/usr/bin/env python3
"""Fixture-driven checks for findings_ledger_check.py — the ledger grammar
(column-0 `- <ID>: ` entries, terminal disposition + parenthesized evidence)
and its exit-code contract.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_findings_ledger_check.py``.
Exit 0 = all asserts pass. Drives the real CLI via subprocess against a
temp ledger file — no git repo needed (the script is a pure file parser).
"""
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "findings_ledger_check.py"


def run(text):
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as f:
        f.write(text)
        path = f.name
    try:
        proc = subprocess.run(
            [sys.executable, str(SCRIPT), path], capture_output=True, text=True
        )
        return proc.returncode, proc.stdout, proc.stderr
    finally:
        Path(path).unlink(missing_ok=True)


def test_all_dispositioned_with_evidence_passes():
    text = (
        "- H1: some finding — APPLIED-SUBSTANTIVE (CHANGE 3, team-lead.md:210)\n"
        "- B2: another finding — REJECTED (Non-redundant: already covered elsewhere)\n"
        "- I3: yet another — DEFERRED (DKT-341)\n"
    )
    code, out, err = run(text)
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[OK] H1" in out and "[OK] B2" in out and "[OK] I3" in out, out
    assert "3/3 dispositioned" in out, out


def test_open_entry_with_no_disposition_fails():
    text = "- H1: some finding, no disposition yet\n"
    code, out, err = run(text)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[FAIL] H1: OPEN" in out, out
    assert "0/1 dispositioned" in out, out


def test_disposition_with_empty_evidence_fails():
    text = "- H1: some finding — REJECTED ()\n"
    code, out, err = run(text)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "EVIDENCE-LESS" in out, out


def test_disposition_with_no_evidence_paren_is_open():
    text = "- H1: some finding — REJECTED but no evidence span at all\n"
    code, out, err = run(text)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[FAIL] H1: OPEN" in out, out


def test_mixed_open_and_valid_reports_both():
    text = (
        "- H1: valid — ALREADY-ENCODED (Execution Workflow step 5)\n"
        "- B2: still open\n"
    )
    code, out, err = run(text)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[OK] H1" in out, out
    assert "[FAIL] B2: OPEN" in out, out
    assert "1/2 dispositioned" in out, out


def test_multiline_entry_disposition_found_anywhere_in_entry():
    text = (
        "- H1: a finding whose summary\n"
        "  spans multiple lines before the disposition —\n"
        "  APPLIED-COSMETIC (rewording only, no behavioral delta)\n"
        "- B2: next entry, open\n"
    )
    code, out, err = run(text)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[OK] H1" in out, out
    assert "[FAIL] B2: OPEN" in out, out


def test_no_entries_found_exits_two():
    text = "Just prose, no ledger entries here.\n"
    code, out, err = run(text)
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no `- <ID>: ` entries found" in err, err


def test_missing_file_exits_two():
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), "/definitely/not/a/real/path.md"],
        capture_output=True, text=True,
    )
    assert proc.returncode == 2, f"exit {proc.returncode}: {proc.stdout}{proc.stderr}"
    assert "cannot read" in proc.stderr, proc.stderr


def test_usage_with_no_args_exits_two():
    proc = subprocess.run([sys.executable, str(SCRIPT)], capture_output=True, text=True)
    assert proc.returncode == 2, f"exit {proc.returncode}: {proc.stdout}{proc.stderr}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
