#!/bin/bash
# Exercise the runtime sweep against an isolated fake CLI: isolation of the
# probe environment, refusal of forbidden argv and trust ordering, the store-
# location assertion, coverage enforcement, capture placeholders, output
# normalization, and the check/write drift semantics.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$REPO_ROOT" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest

SCRIPT = Path(sys.argv[1]) / "src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py"

FAKE = '''\
#!/usr/bin/env python3
"""A docket stand-in: every verb echoes its argv; a few keep state on disk."""
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
log = Path(os.environ["SWEEP_LOG"])
with log.open("a") as handle:
    handle.write(json.dumps({"argv": args, "home": os.environ.get("HOME"),
        "xdg": os.environ.get("XDG_CONFIG_HOME"), "docket_path": os.environ.get("DOCKET_PATH"),
        "cwd": os.getcwd()}) + "\\n")
mode = "json" if "--json" in args else "format" if "--format" in args else "text"
argv = [a for a in args if a not in ("--json", "--format", "json")]
home = Path(os.environ["HOME"])
def emit(data, message="ok", ok=True, code=None, exit_code=0):
    if mode == "text":
        print(message)
    else:
        doc = {"ok": ok, "data": data} if ok else {"ok": False, "error": message, "code": code}
        if ok and message: doc["message"] = message
        if mode == "format" and isinstance(data, dict) and "items" in data: doc["data"]["truncated"] = False
        print(json.dumps(doc))
    sys.exit(exit_code)
if argv == ["--version"]:
    print("docket version fixture-1"); sys.exit(0)
if argv[:1] == ["init"]:
    (home / ".docket").mkdir(parents=True, exist_ok=True)
    (home / ".docket/issues.db").write_text("")
    emit({"db_path": str(home / ".docket/issues.db")}, "Initialized")
if argv[:1] == ["config"]:
    db = os.environ.get("FAKE_ESCAPE_DB") or str(home / ".docket/issues.db")
    emit({"db_path": db, "docket_path_set": bool(os.environ.get("DOCKET_PATH"))}, "config")
if argv[:2] == ["trust", "list"]:
    roster = Path(os.environ["XDG_CONFIG_HOME"]) / "docket/trust.json"
    entries = json.loads(roster.read_text()) if roster.exists() else []
    emit({"entries": entries, "total": len(entries)}, f"{len(entries)} trusted command(s)")
if argv[:2] == ["trust", "add"]:
    roster = Path(os.environ["XDG_CONFIG_HOME"]) / "docket/trust.json"
    roster.parent.mkdir(parents=True, exist_ok=True)
    entries = json.loads(roster.read_text()) if roster.exists() else []
    entries.append({"name": argv[2]})
    roster.write_text(json.dumps(entries))
    emit({"name": argv[2]}, f"trusted {argv[2]}")
if argv[:2] == ["issue", "create"]:
    emit({"id": "DKT-1", "token": "a" * 64, "created_at": "2026-09-17T01:02:03Z", "size_bytes": 4096,
          "path": os.getcwd()}, "Created DKT-1 at 2026-09-17T01:02:03Z")
if argv[:2] == ["issue", "show"]:
    if argv[2:3] == ["DKT-999"]:
        emit(None, f"issue {argv[2]} not found", ok=False, code="NOT_FOUND", exit_code=2)
    emit({"id": argv[2], "echo": os.environ.get("DOCKET_TOKEN", ""), "stdin": sys.stdin.read()}, f"showing {argv[2]}")
if argv[:2] == ["run", "activate"]:
    emit({"run": argv[2], "conductor_token": "b" * 64}, "Activated " + argv[2] + " 3 seconds ago")
if argv[:2] == ["step", "complete"]:
    emit({"step": argv[2]}, "Completed")
if argv[:1] == ["events"]:
    emit({"items": [{"seq": 3}, {"seq": 1}, {"seq": 2}]}, "events")
emit(None, "unknown verb " + " ".join(argv), ok=False, code="VALIDATION_ERROR", exit_code=3)
'''

INVENTORY = {
    "schema_version": 1, "verified_on": "2026-09-17", "binary_version": "docket version fixture-1",
    "probe_contract": "test", "commands": [{"command": c, "usage": [], "aliases": [], "flags": [], "inherited_flags": []} for c in [
        "docket", "docket init", "docket config", "docket trust", "docket trust list", "docket trust add", "docket trust probe",
        "docket issue", "docket issue create", "docket issue show", "docket run", "docket run activate", "docket step", "docket step complete",
        "docket events",
    ]],
}

SCENARIO = {
    "schema_version": 1,
    "skipped": [{"command": "docket trust probe", "reason": "executes trusted commands"}],
    "steps": [
        {"id": "root", "argv": [], "modes": ["text"]},
        {"id": "init", "argv": ["init"], "modes": ["json"], "expect_exit": 0},
        {"id": "config", "argv": ["config"]},
        {"id": "trust-group", "argv": ["trust"], "modes": ["text"]},
        {"id": "issue-group", "argv": ["issue"], "modes": ["text"]},
        {"id": "run-group", "argv": ["run"], "modes": ["text"]},
        {"id": "step-group", "argv": ["step"], "modes": ["text"]},
        {"id": "create", "argv": ["issue", "create", "-t", "Alpha"], "modes": ["json"], "expect_exit": 0, "capture": {"token": "data.token", "issue": "data.id"}},
        {"id": "show", "argv": ["issue", "show", "{issue}"], "env": {"DOCKET_TOKEN": "{token}"}, "stdin": "hello"},
        {"id": "show-missing", "argv": ["issue", "show", "DKT-999"]},
        {"id": "activate", "argv": ["run", "activate", "RUN-1"], "modes": ["json", "text"], "expect_exit": 0},
        {"id": "complete", "argv": ["step", "complete", "STEP-1"], "modes": ["json"]},
        {"id": "events", "argv": ["events"], "modes": ["json"], "unordered": True},
        {"id": "trust-list", "argv": ["trust", "list"], "modes": ["json"]},
        {"id": "trust-add", "argv": ["trust", "add", "probe", "--", "true"], "modes": ["json"], "mode_at": 2},
    ],
}


class SweepTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="docket-cli-sweep-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.binary = self.root / "fake docket"
        self.binary.write_text(FAKE)
        self.binary.chmod(0o755)
        self.log = self.root / "calls.jsonl"
        self.inventory = self.root / "inventory.json"
        self.inventory.write_text(json.dumps(INVENTORY))
        self.scenario = self.root / "scenario.json"
        self.scenario.write_text(json.dumps(SCENARIO))
        self.fixtures = self.root / "fixtures.json"
        self.corpus = self.root / "corpus"
        self.corpus.mkdir()
        self.tmpdir = self.root / "tmp"
        self.tmpdir.mkdir()
        self.env = {**os.environ, "SWEEP_LOG": str(self.log), "TMPDIR": str(self.tmpdir), "DOCKET_PATH": "/nowhere/issues.db", "DOCKET_TOKEN": "leaked"}

    def run_tool(self, *args, env=None):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--binary", str(self.binary), "--inventory", str(self.inventory),
             "--scenario", str(self.scenario), "--fixtures", str(self.fixtures), "--corpus", str(self.corpus), *args],
            env=env or self.env, capture_output=True, text=True,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def write(self):
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(self.fixtures.read_text())

    def test_probes_run_isolated_and_scratch_is_removed(self):
        fixtures = self.write()
        calls = self.calls()
        self.assertTrue(calls)
        scratch = self.tmpdir.resolve()
        for call in calls:
            for key in ("home", "xdg", "cwd"):
                self.assertIn(scratch, Path(call[key]).resolve().parents, call)
            self.assertIsNone(call["docket_path"], call)
        self.assertEqual(os.listdir(self.tmpdir), [], "scratch directory was not removed")
        self.assertEqual(fixtures["binary_version"], "docket version fixture-1")
        self.assertEqual(fixtures["coverage"]["skipped"], [{"command": "docket trust probe", "reason": "executes trusted commands"}])

    def test_normalization_captures_and_modes(self):
        fixtures = self.write()
        records = {(r["id"], r["mode"]): r for r in fixtures["results"]}
        self.assertEqual(set(records), {
            ("root", "text"), ("init", "json"), ("config", "text"), ("config", "json"), ("config", "format"),
            ("trust-group", "text"), ("issue-group", "text"), ("run-group", "text"), ("step-group", "text"),
            ("create", "json"), ("show", "text"), ("show", "json"), ("show", "format"),
            ("show-missing", "text"), ("show-missing", "json"), ("show-missing", "format"),
            ("activate", "json"), ("activate", "text"), ("complete", "json"), ("events", "json"),
            ("trust-list", "json"), ("trust-add", "json"),
        })
        create = records[("create", "json")]["json"]["data"]
        self.assertEqual(create["token"], "<HEX64>")
        self.assertEqual(create["created_at"], "<TIMESTAMP>")
        self.assertEqual(create["size_bytes"], "<N>")
        self.assertEqual(create["path"], "<SCRATCH>/repo")
        self.assertNotIn("a" * 64, json.dumps(fixtures))
        self.assertNotIn("b" * 64, json.dumps(fixtures))
        self.assertEqual(records[("activate", "text")]["stdout"], "Activated RUN-1 <AGO>\n")
        show = records[("show", "json")]["json"]["data"]
        self.assertEqual(show["id"], "DKT-1")
        self.assertEqual(show["echo"], "<HEX64>", "the captured token did not reach the probe environment")
        self.assertEqual(show["stdin"], "hello")
        self.assertEqual(records[("show-missing", "json")]["exit"], 2)
        self.assertEqual(records[("show-missing", "json")]["json"]["code"], "NOT_FOUND")
        self.assertEqual(records[("events", "json")]["json"]["data"]["items"], [{"seq": 1}, {"seq": 2}, {"seq": 3}])
        self.assertEqual(records[("trust-add", "json")]["argv"][:4], ["docket", "trust", "add", "--json"])
        self.assertEqual(records[("trust-list", "json")]["json"]["data"]["total"], 0)

    def test_check_write_and_drift(self):
        self.write()
        self.assertEqual(self.run_tool("--check").returncode, 0)
        fixtures = json.loads(self.fixtures.read_text())
        fixtures["verified_on"] = "2000-01-01"
        self.fixtures.write_text(json.dumps(fixtures))
        self.assertEqual(self.run_tool("--check").returncode, 0, "a new date alone is not drift")
        self.binary.write_text(FAKE.replace('"Created DKT-1 at', '"Made DKT-1 at'))
        result = self.run_tool("--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("Made DKT-1", result.stdout)

    def test_coverage_is_enforced(self):
        scenario = json.loads(self.scenario.read_text())
        scenario["steps"] = [s for s in scenario["steps"] if s["id"] != "events"]
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--coverage")
        self.assertEqual(result.returncode, 2)
        self.assertIn("uncovered: docket events", result.stderr)
        scenario = json.loads(self.scenario.read_text())
        scenario["skipped"].append({"command": "docket issue show", "reason": "stale"})
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--coverage")
        self.assertIn("stale skip: docket issue show", result.stderr)
        scenario["skipped"] = [{"command": "docket gone", "reason": "removed"}]
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--coverage")
        self.assertIn("not in inventory: docket gone", result.stderr)
        self.assertFalse(self.log.exists(), "--coverage must not run the binary")

    def test_forbidden_argv_and_trust_order_are_refused_before_any_probe(self):
        scenario = json.loads(self.scenario.read_text())
        base = json.dumps(scenario)
        for step in ([{"id": "watch", "argv": ["events", "--watch"]}],
                     [{"id": "follow", "argv": ["events", "--follow"], "modes": ["text"]}],
                     [{"id": "probe", "argv": ["trust", "probe"], "modes": ["text"]}]):
            scenario = json.loads(base)
            scenario["steps"].extend(step)
            self.scenario.write_text(json.dumps(scenario))
            result = self.run_tool("--write")
            self.assertEqual(result.returncode, 2, step)
            self.assertFalse(self.log.exists(), step)
            self.assertFalse(self.fixtures.exists())
        scenario = json.loads(base)
        add = next(s for s in scenario["steps"] if s["id"] == "trust-add")
        scenario["steps"].remove(add)
        scenario["steps"].insert(1, add)
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 2)
        self.assertIn("trust", result.stderr)
        self.assertFalse(self.log.exists())

    def test_store_outside_scratch_aborts_before_any_store_verb(self):
        result = self.run_tool("--write", env={**self.env, "FAKE_ESCAPE_DB": "/Users/someone/.docket/issues.db"})
        self.assertEqual(result.returncode, 2)
        self.assertIn("REFUSING TO CONTINUE", result.stderr)
        verbs = [call["argv"] for call in self.calls()]
        self.assertEqual(verbs, [["--version"], [], ["init", "--json"], ["config", "--json"]])
        self.assertFalse(self.fixtures.exists())
        self.assertEqual(os.listdir(self.tmpdir), [])

    def test_roster_must_be_empty_before_a_gate_verb(self):
        scenario = json.loads(self.scenario.read_text())
        # A stand-in binary that reports an entry on the roster before activation.
        self.binary.write_text(FAKE.replace('entries = json.loads(roster.read_text()) if roster.exists() else []\n    emit(',
                                            'entries = [{"name": "sneaky"}]\n    emit('))
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 2)
        self.assertIn("trust roster holds 1 entries before activate", result.stderr)
        verbs = [call["argv"] for call in self.calls()]
        self.assertNotIn(["run", "activate", "RUN-1", "--json"], verbs)

    def test_expect_exit_mismatch_and_bad_capture_fail_without_writing(self):
        scenario = json.loads(self.scenario.read_text())
        next(s for s in scenario["steps"] if s["id"] == "init")["expect_exit"] = 7
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 2)
        self.assertIn("expected 7", result.stderr)
        scenario = json.loads(self.scenario.read_text())
        next(s for s in scenario["steps"] if s["id"] == "init")["expect_exit"] = 0
        next(s for s in scenario["steps"] if s["id"] == "create")["capture"] = {"token": "data.nope"}
        self.scenario.write_text(json.dumps(scenario))
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 2)
        self.assertIn("does not resolve", result.stderr)
        self.assertFalse(self.fixtures.exists())

    def test_digest_reads_fixtures_only(self):
        self.write()
        self.log.unlink()
        result = self.run_tool("--digest")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("## docket issue create", result.stdout)
        self.assertIn("show-missing/json exit=2: error='issue DKT-999 not found' code=NOT_FOUND", result.stdout)
        self.assertIn("docket trust probe (executes trusted commands)", result.stdout)
        self.assertFalse(self.log.exists(), "--digest must not run the binary")


unittest.main(argv=[sys.argv[0]], verbosity=2)
PY
