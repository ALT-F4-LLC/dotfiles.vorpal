#!/bin/bash
# Exercise command discovery and drift checks against an isolated fake CLI.
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

SCRIPT = Path(sys.argv[1]) / "src/user/claude_code/skills/docket/scripts/cli_inventory.py"


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="docket-cli-inventory-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.binary = self.root / "fake docket"
        self.fixture = self.root / "help.json"
        self.log = self.root / "calls.jsonl"
        self.inventory = self.root / "inventory.json"
        self.env = {**os.environ, "INVENTORY_FIXTURE": str(self.fixture), "INVENTORY_LOG": str(self.log)}
        self.binary.write_text(textwrap.dedent('''\
            #!/usr/bin/env python3
            import json, os, sys
            from pathlib import Path
            args = sys.argv[1:]
            with open(os.environ["INVENTORY_LOG"], "a") as log:
                log.write(json.dumps(args) + "\\n")
            fixture = json.loads(Path(os.environ["INVENTORY_FIXTURE"]).read_text())
            if args == ["--version"]:
                print(fixture["version"])
            elif args and args[-1] == "--help":
                key = " ".join(args[:-1])
                if key not in fixture["help"]:
                    sys.exit(7)
                print(fixture["help"][key])
            else:
                sys.exit(99)
        '''))
        self.binary.chmod(0o755)
        self.data = {
            "version": "docket version fixture-1",
            "help": {
                "": """Usage:
  docket [command]

Available Commands:
  issue  Manage issues
  step   Manage steps

Flags:
  -h, --help   help for docket
""",
                "issue": """Usage:
  docket issue [command]

Available Commands:
  show Show one or more issues

Flags:
  -h, --help   help for issue
""",
                "issue show": """Usage:
  docket issue show id... [flags]

Flags:
  -h, --help         help for show
      --limit int    Result limit (default 50)
      --with-body    Include full bodies

Global Flags:
      --json string[=\"v1\"]   JSON format
  -q, --quiet                Quiet output
""",
                "step": """Usage:
  docket step [command]

Available Commands:
  complete  Record a step

Flags:
  -h, --help   help for step
""",
                "step complete": """Usage:
  docket step complete STEP-N [flags]

Aliases:
  complete, record

Flags:
      --artifact-file string   Artifact path
  -h, --help                   help for complete
""",
            },
        }
        self.save()

    def save(self):
        self.fixture.write_text(json.dumps(self.data))

    def run_tool(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--binary", str(self.binary),
             "--inventory", str(self.inventory), *args],
            env=self.env, capture_output=True, text=True,
        )

    def write(self):
        result = self.run_tool("--write")
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(self.inventory.read_text())

    def test_discovers_nested_commands_and_never_runs_them(self):
        inventory = self.write()
        commands = {row["command"]: row for row in inventory["commands"]}
        self.assertEqual(set(commands), {"docket", "docket issue", "docket issue show", "docket step", "docket step complete"})
        self.assertEqual(commands["docket step complete"]["aliases"], ["complete", "record"])
        row = commands["docket issue show"]
        self.assertIn({"name": "--limit", "value": "int", "default": "50"}, row["flags"])
        self.assertIn({"name": "--with-body"}, row["flags"])
        self.assertIn({"name": "--json", "value": 'string[="v1"]'}, row["inherited_flags"])
        self.assertIn({"name": "--quiet", "short": "-q"}, row["inherited_flags"])
        self.assertEqual(self.run_tool("--check").returncode, 0)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        self.assertTrue(all(call == ["--version"] or call[-1:] == ["--help"] for call in calls))

    def test_default_is_read_only_and_date_alone_is_not_drift(self):
        result = self.run_tool()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.inventory.exists())
        inventory = json.loads(result.stdout)
        inventory["verified_on"] = "2000-01-01"
        self.inventory.write_text(json.dumps(inventory))
        self.assertEqual(self.run_tool("--check").returncode, 0)

    def test_flags_aliases_and_version_changes_are_drift(self):
        self.write()
        for old, new in [("--limit int", "--limit string"),
                         ("(default 50)", "(default 20)"),
                         ("complete, record", "complete, record, finish")]:
            with self.subTest(change=new):
                original = json.dumps(self.data)
                self.data = json.loads(original.replace(old, new))
                self.save()
                result = self.run_tool("--check")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.data = json.loads(original)
        self.data["version"] = "docket version fixture-2"
        self.save()
        self.assertEqual(self.run_tool("--check").returncode, 1)

    def test_new_and_removed_commands_are_drift(self):
        self.write()
        self.data["help"]["issue"] = self.data["help"]["issue"].replace(
            "  show Show one or more issues", "  show Show one or more issues\n  list List issues")
        self.data["help"]["issue list"] = "Usage:\n  docket issue list [flags]\n"
        self.save()
        self.assertEqual(self.run_tool("--check").returncode, 1)
        self.data["help"][""] = self.data["help"][""].replace("  step   Manage steps\n", "")
        self.save()
        self.assertEqual(self.run_tool("--check").returncode, 1)

    def test_failed_or_malformed_probe_cannot_replace_inventory(self):
        self.write()
        original = self.inventory.read_bytes()
        for bad_help in ["", "Unexpected output without usage", "Usage:\n  docket issue show [flags]\n\nFlags:\n  unsupported flag format"]:
            with self.subTest(output=bad_help):
                self.data["help"]["issue show"] = bad_help
                self.save()
                self.assertEqual(self.run_tool("--write").returncode, 2)
                self.assertEqual(self.inventory.read_bytes(), original)
        del self.data["help"]["issue show"]
        self.save()
        self.assertEqual(self.run_tool("--write").returncode, 2)
        self.assertEqual(self.inventory.read_bytes(), original)

    def test_missing_binary_and_invalid_inventory_fail(self):
        self.inventory.write_text("not json")
        self.assertEqual(self.run_tool("--check").returncode, 2)
        result = self.run_tool("--binary", str(self.root / "missing"))
        self.assertEqual(result.returncode, 2)


unittest.main(argv=[sys.argv[0]], verbosity=2)
PY
