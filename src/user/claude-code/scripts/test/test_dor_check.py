#!/usr/bin/env python3
"""Fixture-driven checks for dor_check.py — the Definition-of-Ready heuristic
checklist and tree-completeness check.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_dor_check.py``.
Exit 0 = all asserts pass. Stubs the `docket` binary per test with a small
routing-table dispatcher (env-var-driven) so it never touches the real
Docket board. Drives the real CLI via subprocess.
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
SCRIPT = HERE.parent / "dor_check.py"

STUB_SOURCE = '''#!/usr/bin/env python3
import json, os, sys
routes = json.loads(os.environ["DOR_STUB_ROUTES"])
args = sys.argv[1:]
if args and args[-1] == "--json":
    args = args[:-1]
key = " ".join(args)
if key not in routes:
    print(json.dumps({"ok": False, "error": f"no stub route for: {key}"}))
    sys.exit(1)
print(json.dumps({"ok": True, "data": routes[key]}))
'''


def run(root_id, routes, *extra_args):
    stub_dir = Path(tempfile.mkdtemp(prefix="dor_check_stub_"))
    stub = stub_dir / "docket"
    stub.write_text(STUB_SOURCE)
    stub.chmod(stub.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    try:
        env = dict(os.environ)
        env["PATH"] = f"{stub_dir}:{env['PATH']}"
        env["DOR_STUB_ROUTES"] = json.dumps(routes)
        proc = subprocess.run([sys.executable, str(SCRIPT), root_id, *extra_args],
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout, proc.stderr
    finally:
        shutil.rmtree(stub_dir, ignore_errors=True)


def leaf_tree(issue):
    """Routing table for a root with exactly one leaf child DKT-2."""
    return {
        "issue list --parent DKT-1 --all": {"issues": [{"id": "DKT-2"}]},
        "issue list --parent DKT-2 --all": {"issues": []},
        "issue show DKT-2": issue,
    }


def test_all_dor_criteria_pass():
    issue = {"id": "DKT-2", "title": "Do the thing", "description": "A" * 50,
              "labels": ["should-have"], "files": ["some/file.py"], "comments": []}
    code, out, err = run("DKT-1", leaf_tree(issue))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DKT-2: PASS" in out, out
    assert "0 FAIL finding(s), 0 WARN finding(s)" in out, out


def test_all_dor_criteria_fail():
    issue = {"id": "DKT-2", "title": "", "description": "short",
              "labels": [], "files": [], "comments": []}
    code, out, err = run("DKT-1", leaf_tree(issue))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "FAIL title: empty" in out, out
    assert "FAIL description: below heuristic length threshold (5 < 40 chars)" in out, out
    assert "FAIL scope-label: none of" in out, out
    assert "FAIL files: none attached" in out, out
    assert "4 FAIL finding(s)" in out, out


def test_blocking_question_comment_is_warn_not_fail():
    issue = {"id": "DKT-2", "title": "Do the thing", "description": "A" * 50,
              "labels": ["should-have"], "files": ["some/file.py"],
              "comments": [{"body": "This is still unresolved, needs decision on X."}]}
    code, out, err = run("DKT-1", leaf_tree(issue))
    assert code == 0, f"exit {code}: {out}{err}"  # WARN alone does not fail the run
    assert "WARN blocking-question: 1 comment(s)" in out, out
    assert "0 FAIL finding(s), 1 WARN finding(s)" in out, out


def test_completeness_check_mismatch_fails_even_when_dor_passes():
    issue = {"id": "DKT-2", "title": "Do the thing", "description": "A" * 50,
              "labels": ["should-have"], "files": ["some/file.py"], "comments": []}
    code, out, err = run("DKT-1", leaf_tree(issue), "--expected-count", "3")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "DKT-2: PASS" in out, out  # DoR itself passed
    assert "Completeness check: direct children under DKT-1 = 1, expected = 3 [MISMATCH]" in out, out


def test_completeness_check_match_exits_zero():
    issue = {"id": "DKT-2", "title": "Do the thing", "description": "A" * 50,
              "labels": ["should-have"], "files": ["some/file.py"], "comments": []}
    code, out, err = run("DKT-1", leaf_tree(issue), "--expected-count", "1")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "[OK]" in out, out


def test_no_children_found_exits_two():
    code, out, err = run("DKT-1", {"issue list --parent DKT-1 --all": {"issues": []}})
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no child issues found under root DKT-1" in err, err


def test_min_desc_length_override_relaxes_threshold():
    issue = {"id": "DKT-2", "title": "Do the thing", "description": "A" * 10,
              "labels": ["should-have"], "files": ["some/file.py"], "comments": []}
    code, out, err = run("DKT-1", leaf_tree(issue), "--min-desc-length", "5")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DKT-2: PASS" in out, out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
