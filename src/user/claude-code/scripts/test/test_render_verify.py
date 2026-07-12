#!/usr/bin/env python3
"""Fixture-driven checks for render_verify.sh — scoped to its deterministic
surface only: arg validation, the git-repo guard, the dependency-free `cli`
arm, and the `html` arm's browser-detection/invocation with a stubbed
browser binary (via a PATH-prepended temp dir).

The real `html`/`tui` arms are runtime-detected against actual browser
binaries / pty allocation and are explicitly framed by the script's own
header comments as environment-dependent, not a script defect — testing
"no browser found" is skipped here since it cannot be made hermetic (the
script also probes hardcoded /Applications bundle paths that a PATH stub
cannot suppress, so the result would depend on what's actually installed
on the machine running this suite).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_render_verify.py``.
Exit 0 = all asserts pass. Drives the real CLI via subprocess.
"""
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "render_verify.sh"

BROWSER_STUB_SUCCESS = '''#!/bin/bash
for a in "$@"; do
  case "$a" in
    --screenshot=*) OUT="${a#--screenshot=}" ;;
  esac
done
printf 'FAKE-PNG-BYTES' > "$OUT"
exit 0
'''

BROWSER_STUB_EMPTY_OUTPUT = '''#!/bin/bash
for a in "$@"; do
  case "$a" in
    --screenshot=*) OUT="${a#--screenshot=}" ;;
  esac
done
: > "$OUT"
exit 0
'''


def run(cwd, *args, path_prepend=None):
    import os
    env = dict(os.environ)
    if path_prepend is not None:
        env["PATH"] = f"{path_prepend}:{env['PATH']}"
    proc = subprocess.run(["bash", str(SCRIPT), *args], cwd=cwd, capture_output=True, text=True, env=env)
    return proc.returncode, proc.stdout, proc.stderr


def make_stub(source):
    stub_dir = Path(tempfile.mkdtemp(prefix="render_verify_stub_"))
    stub = stub_dir / "chrome-headless-shell"
    stub.write_text(source)
    stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    return stub_dir


def test_usage_error_on_too_few_args():
    code, out, err = run(HERE, "cli")
    assert code == 1, f"exit {code}"
    assert "Usage:" in err, err


def test_usage_error_on_unknown_arm():
    code, out, err = run(HERE, "foo", "echo hi")
    assert code == 1, f"exit {code}"
    assert "Usage:" in err, err


def test_not_inside_git_repo_exits_one():
    outside = Path(tempfile.mkdtemp(prefix="render_verify_notgit_"))
    try:
        code, out, err = run(outside, "cli", "echo hi")
        assert code == 1, f"exit {code}: {out}{err}"
        assert "not inside a git repository" in err, err
    finally:
        shutil.rmtree(outside, ignore_errors=True)


def test_cli_arm_captures_output_and_always_reports_exit_zero():
    d = Path(tempfile.mkdtemp(prefix="render_verify_cli_"))
    try:
        out_file = d / "out.txt"
        code, out, err = run(HERE, "cli", "echo hello-world", str(out_file))
        # cli arm is report-only: it always exits 0 and embeds the wrapped
        # command's exit status in its own message, mirroring secret_scan.sh's
        # report-only contract.
        assert code == 0, f"exit {code}: {out}{err}"
        assert "hello-world" in out, out
        assert "command exit 0" in out, out
        assert out_file.read_text().strip() == "hello-world", out_file.read_text()
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_cli_arm_reports_nonzero_wrapped_exit_but_still_exits_zero():
    d = Path(tempfile.mkdtemp(prefix="render_verify_cli_"))
    try:
        out_file = d / "out.txt"
        code, out, err = run(HERE, "cli", "echo boom; exit 3", str(out_file))
        assert code == 0, f"exit {code}: {out}{err}"
        assert "command exit 3" in out, out
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_html_arm_finds_stubbed_browser_and_reports_ok():
    d = Path(tempfile.mkdtemp(prefix="render_verify_html_"))
    stub_dir = make_stub(BROWSER_STUB_SUCCESS)
    try:
        out_file = d / "out.png"
        code, out, err = run(HERE, "html", "https://example.com", str(out_file), path_prepend=str(stub_dir))
        assert code == 0, f"exit {code}: {out}{err}"
        assert "Using browser:" in out, out
        assert f"OK: screenshot written to {out_file}" in out, out
        assert out_file.read_text() == "FAKE-PNG-BYTES", out_file.read_text()
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


def test_html_arm_empty_output_file_is_reported_as_failure():
    d = Path(tempfile.mkdtemp(prefix="render_verify_html_"))
    stub_dir = make_stub(BROWSER_STUB_EMPTY_OUTPUT)
    try:
        out_file = d / "out.png"
        code, out, err = run(HERE, "html", "https://example.com", str(out_file), path_prepend=str(stub_dir))
        assert code == 1, f"exit {code}: {out}{err}"
        assert "produced an empty file" in err, err
    finally:
        shutil.rmtree(d, ignore_errors=True)
        shutil.rmtree(stub_dir, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
