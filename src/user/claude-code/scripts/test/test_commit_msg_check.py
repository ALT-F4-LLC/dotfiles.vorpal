#!/usr/bin/env python3
"""Checks for commit_msg_check.sh's four forbidden-content gates.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_commit_msg_check.py``.

The regression these start from: the issue-ID gate ran an upper-case-only
pattern under ``grep -niE``. The ``-i`` widened it to every lower-case
``word-number``, so ordinary messages naming a model version or a ranking were
rejected as issue references. The gate is now case-sensitive, with the local
tracker prefix spelled out so dropping ``-i`` costs no real coverage.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "commit_msg_check.sh"


def run_msg(text):
    """Run the checker over `text`; return (exit_code, stdout+stderr)."""
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / "draft.txt"
        p.write_text(text, encoding="utf-8")
        proc = subprocess.run(
            [str(SCRIPT), str(p)], capture_output=True, text=True
        )
        return proc.returncode, proc.stdout + proc.stderr


# --- the R28 regression: false positives on lower-case word-number ---

def test_model_version_is_not_an_issue_id():
    code, out = run_msg("fix: bump the default to sonnet-5\n")
    assert code == 0, f"model version rejected as an issue ID: {out}"


def test_ranking_is_not_an_issue_id():
    code, out = run_msg("perf: cover the top-10 hot paths\n")
    assert code == 0, f"ranking rejected as an issue ID: {out}"


def test_ordinary_hyphenated_numerals_pass():
    for msg in ("refactor: split the step-16 wrap-up\n",
                "docs: describe the base-64 encoding path\n",
                "fix: correct the utf-8 fallback\n"):
        code, out = run_msg(msg)
        assert code == 0, f"rejected {msg!r}: {out}"


# --- coverage that must survive the fix ---

def test_upper_case_issue_id_still_rejected():
    code, out = run_msg("feat: close DKT-1 and ship it\n")
    assert code == 1, f"expected rejection, got {code}: {out}"
    assert "Docket issue ID" in out, out


def test_lower_case_tracker_id_still_rejected():
    """Dropping -i must not lose the lower-cased spelling of a real ID."""
    code, out = run_msg("feat: close dkt-12 and ship it\n")
    assert code == 1, f"lower-case tracker ID slipped through: {out}"


def test_mixed_case_tracker_id_still_rejected():
    code, out = run_msg("feat: close Dkt-3\n")
    assert code == 1, f"mixed-case tracker ID slipped through: {out}"


def test_generic_upper_case_tracker_id_rejected():
    code, out = run_msg("feat: implements JIRA-4021\n")
    assert code == 1, f"generic tracker ID slipped through: {out}"


def test_standards_exclusions_still_pass():
    for msg in ("fix: handle UTF-8 input\n", "chore: pin to SHA-256\n",
                "docs: cite RFC-2119\n", "fix: patch CVE-2024\n"):
        code, out = run_msg(msg)
        assert code == 0, f"excluded standard rejected: {msg!r}: {out}"


# --- the other three gates are unaffected and still case-insensitive ---

def test_agent_reference_rejected_any_case():
    for msg in ("fix: per @senior-engineer review\n",
                "fix: per @SENIOR-ENGINEER review\n"):
        code, out = run_msg(msg)
        assert code == 1, f"agent reference slipped through: {msg!r}: {out}"


def test_assistant_reference_rejected_any_case():
    for msg in ("chore: update Claude settings\n",
                "chore: update CLAUDE settings\n",
                "chore: update anthropic settings\n"):
        code, out = run_msg(msg)
        assert code == 1, f"assistant reference slipped through: {msg!r}: {out}"


def test_harness_metadata_rejected_any_case():
    for msg in ("chore: bump the Docket schema\n",
                "chore: note the teammate lifecycle\n"):
        code, out = run_msg(msg)
        assert code == 1, f"harness metadata slipped through: {msg!r}: {out}"


def test_clean_message_passes():
    code, out = run_msg(
        "refactor: move end-of-cycle mechanics behind progressive disclosure\n"
        "\n"
        "The orchestrator carried its full mechanics inline on every turn.\n"
    )
    assert code == 0, f"clean message rejected: {out}"


def test_missing_file_exits_two():
    proc = subprocess.run(
        [str(SCRIPT), "/nonexistent/draft.txt"], capture_output=True, text=True
    )
    assert proc.returncode == 2, proc.stdout + proc.stderr


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"ok  {t.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL {t.__name__}: {e}")
    print(f"\n{len(tests) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
