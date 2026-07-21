#!/usr/bin/env python3
"""Fixture-driven checks for ac_check.sh — the AC-extraction heuristic
(fenced-block PRIMARY path, section-scoped inline-backtick SECONDARY path)
and its --pre inversion.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_ac_check.py``.
Exit 0 = all asserts pass. Stubs the `docket` binary per test (a temp dir
prepended to PATH) so it never touches the real Docket board; runs with cwd
inside this repo, which satisfies ac_check.sh's own git-repo check. Drives
the real CLI via subprocess.
"""
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "ac_check.sh"


def run(issue_id, description, *extra_args):
    payload = json.dumps({"data": {"description": description}})
    stub_dir = Path(tempfile.mkdtemp(prefix="ac_check_stub_"))
    stub = stub_dir / "docket"
    stub.write_text("#!/bin/bash\ncat <<'JSONEOF'\n" + payload + "\nJSONEOF\n")
    stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    try:
        env = dict(os.environ)
        env["PATH"] = f"{stub_dir}:{env['PATH']}"
        proc = subprocess.run(["bash", str(SCRIPT), issue_id, *extra_args],
                              cwd=str(HERE), capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout, proc.stderr
    finally:
        shutil.rmtree(stub_dir, ignore_errors=True)


def test_fenced_bash_block_is_primary_unscoped_source():
    # Fenced blocks accept any command (no CMD_WORDS/path-prefix filter),
    # unlike the inline-backtick path below.
    desc = "**Acceptance Criteria**:\n- something\n\n```bash\ntrue\nfalse\n```\n"
    code, out, err = run("FAKE-1", desc)
    assert code != 0, f"expected non-zero exit (one command failed): {out}{err}"
    assert "[PASS] true" in out, out
    assert "[FAIL] false" in out, out
    assert "1/2 passed" in out, out


def test_inline_backtick_scoped_to_acceptance_criteria_section_only():
    desc = ("**Where**: `./should-not-run.sh`\n"
            "**Acceptance Criteria**:\n"
            "- `test -e /`\n"
            "**Design Contracts**: none\n")
    code, out, err = run("FAKE-2", desc)
    assert code == 0, f"exit {code}: {out}{err}"
    assert "./should-not-run.sh" not in out, out
    assert "[PASS] test -e /" in out, out
    assert "1/1 passed" in out, out


def test_placeholder_and_template_spans_excluded():
    desc = ("**Acceptance Criteria**:\n"
            "- `test -f <file>`\n"
            "- `git status {branch}`\n"
            "- `test -e /`\n")
    code, out, err = run("FAKE-3", desc)
    assert code == 0, f"exit {code}: {out}{err}"
    assert "1/1 passed" in out, out
    assert "<file>" not in out and "{branch}" not in out, out


def test_dedupes_identical_inline_commands():
    desc = "**Acceptance Criteria**:\n- `test -e /`\n- `test -e /`\n"
    code, out, err = run("FAKE-4", desc)
    assert code == 0, f"exit {code}: {out}{err}"
    assert out.count("[PASS]") == 1, out
    assert "1/1 passed" in out, out


def test_pre_mode_expected_fail_when_command_fails_naturally():
    desc = "**Acceptance Criteria**:\n- `test -e /definitely-not-a-real-path-xyz`\n"
    code, out, err = run("FAKE-5", desc, "--pre")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[EXPECTED-FAIL]" in out, out
    assert "1/1 expected-fail" in out, out


def test_pre_mode_unexpected_pass_when_command_already_true():
    desc = "**Acceptance Criteria**:\n- `test -e /`\n"
    code, out, err = run("FAKE-6", desc, "--pre")
    assert code != 0, f"expected non-zero exit when a --pre AC unexpectedly passes: {out}{err}"
    assert "[UNEXPECTED-PASS]" in out, out


def test_no_ac_shaped_commands_exits_two():
    desc = "**Acceptance Criteria**:\n- Just prose, no backticks here.\n"
    code, out, err = run("FAKE-7", desc)
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no AC-shaped commands found" in err, err


def test_differently_named_heading_ignored_without_section_flag():
    desc = "**Testable Requirements**:\n- `test -e /`\n"
    code, out, err = run("FAKE-8", desc)
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no AC-shaped commands found" in err, err


def test_section_flag_extracts_from_custom_heading():
    desc = ("**Where**: `./should-not-run.sh`\n"
            "**Testable Requirements**:\n"
            "- `test -e /`\n"
            "**Design Contracts**: none\n")
    code, out, err = run("FAKE-9", desc, "--section", "Testable Requirements")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "./should-not-run.sh" not in out, out
    assert "[PASS] test -e /" in out, out
    assert "1/1 passed" in out, out


def test_section_flag_is_case_insensitive():
    desc = "**testable requirements**:\n- `test -e /`\n"
    code, out, err = run("FAKE-10", desc, "--section", "Testable Requirements")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[PASS] test -e /" in out, out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
