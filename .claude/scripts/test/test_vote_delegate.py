#!/usr/bin/env python3
"""Fixture-driven checks for vote_delegate.sh — the criticality-to-threshold
mapping and delegation_request payload construction.

Standalone (no pytest): ``python3 .claude/scripts/test/test_vote_delegate.py``.
Exit 0 = all asserts pass. Stubs the `docket` binary per test (a temp dir
prepended to PATH) so it never creates a real Docket vote. Drives the real
CLI via subprocess.
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
SCRIPT = HERE.parent / "vote_delegate.sh"


def run(*args, vote_id="vote-123"):
    payload = json.dumps({"data": {"id": vote_id}})
    stub_dir = Path(tempfile.mkdtemp(prefix="vote_delegate_stub_"))
    stub = stub_dir / "docket"
    stub.write_text("#!/bin/bash\ncat <<'JSONEOF'\n" + payload + "\nJSONEOF\n")
    stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    try:
        env = dict(os.environ)
        env["PATH"] = f"{stub_dir}:{env['PATH']}"
        proc = subprocess.run(["bash", str(SCRIPT), *args], cwd=str(HERE),
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout, proc.stderr
    finally:
        shutil.rmtree(stub_dir, ignore_errors=True)


def payload_of(out):
    line = next(l for l in out.splitlines() if l.startswith("delegation_request"))
    return json.loads(line.split("JSON: ", 1)[1])


def test_criticality_threshold_mapping():
    cases = {"low": "0.50", "medium": "0.60", "high": "0.75", "critical": "0.90"}
    for criticality, threshold in cases.items():
        code, out, err = run("senior-engineer", criticality, "desc", "3")
        assert code == 0, f"{criticality} exit {code}: {err}"
        assert f"Threshold: {threshold}" in out, out


def test_unknown_criticality_rejected():
    code, out, err = run("senior-engineer", "urgent", "desc", "3")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "unknown criticality 'urgent'" in err, err


def test_role_leading_at_sign_normalized():
    code, out, err = run("senior-engineer", "low", "desc", "3")
    assert code == 0, f"exit {code}: {err}"
    assert payload_of(out)["from"] == "@senior-engineer", out
    code, out, err = run("@senior-engineer", "low", "desc", "3")
    assert code == 0, f"exit {code}: {err}"
    assert payload_of(out)["from"] == "@senior-engineer", out


def test_artifact_field_included_only_when_given():
    code, out, err = run("senior-engineer", "high", "desc", "3", "docs/tdd/foo.md")
    assert code == 0, f"exit {code}: {err}"
    assert payload_of(out)["artifact"] == "docs/tdd/foo.md", out

    code, out, err = run("senior-engineer", "high", "desc", "3")
    assert code == 0, f"exit {code}: {err}"
    assert "artifact" not in payload_of(out), out


def test_payload_carries_lowercase_request_id_and_vote_id():
    code, out, err = run("senior-engineer", "low", "desc", "3", vote_id="vote-abc-999")
    assert code == 0, f"exit {code}: {err}"
    p = payload_of(out)
    assert p["vote_id"] == "vote-abc-999", p
    assert p["protocol_version"] == "1", p
    assert p["type"] == "delegation_request", p
    assert p["skill"] == "vote", p
    assert p["request_id"] == p["request_id"].lower(), p


def test_null_vote_id_from_docket_exits_nonzero():
    code, out, err = run("senior-engineer", "low", "desc", "3", vote_id=None)
    assert code == 1, f"exit {code}: {out}{err}"
    assert "could not extract vote id" in err, err


def test_usage_on_help_flag_and_bad_arg_count():
    code, out, err = run("-h")
    assert code == 1, f"exit {code}"
    assert "Usage: vote_delegate.sh" in err, err
    code, out, err = run("senior-engineer", "low")
    assert code == 1, f"exit {code}"
    assert "Usage: vote_delegate.sh" in err, err


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
