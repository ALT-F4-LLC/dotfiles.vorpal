"""The grader must distinguish observed success from plausible-looking mistakes."""

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import subprocess
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "src/user/claude_code/skills/docket/scripts/evaluate.py"
SPEC = importlib.util.spec_from_file_location("docket_evaluate", PATH)
EVAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EVAL)


def command(*args, stdin=None):
    return {"argv": ["docket", *args, "--json=v2"], "cwd": "$CHECKOUT", "stdin": stdin}


def control():
    rows = [{"id": case["id"], "complete": case["id"] == "passed-gate", "commands": [], "files": []} for case in json.loads((EVAL.SKILL / "evals/cases.json").read_text())]
    by_id = {row["id"]: row for row in rows}
    by_id["voter-identity"]["commands"] = [command("vote", "cast", "DKT-V1", "--voter", "judge-" + role, "--role", role, "-v", "approve", "--confidence", "0.9", "--domain-relevance", "0.8", "--summary", "Reviewed") for role in ("correctness", "testing")]
    by_id["interrupted-record"]["commands"] = [command("step", "show", "STEP-12"), command("step", "artifacts", "STEP-12")]
    by_id["expired-lease"]["commands"] = [command("step", "claim", "STEP-12", "--owner", "eval-worker")]
    by_id["wrong-project"]["commands"] = [command("issue", "show", "DKT-42")]
    by_id["pagination"]["commands"] = [command("run", "status", "--active", "--limit", "0")]
    by_id["literal-description"]["commands"] = [command("issue", "create", "-t", "Literal text", "-d", "-", "--idempotency-key", "eval-create-1", stdin=EVAL.LITERAL)]
    by_id["claim-attribution"]["commands"] = [command("step", "claim", "STEP-12", "--owner", "eval-worker", "--metadata", json.dumps({"model_requested": "opus", "effort_requested": "high", "variant": "opus-high"}))]
    by_id["gap-headers"]["files"] = [{"path": "gap.md", "content": "Missing timeout\nSeverity: high\nKind: bug\nLabels: reliability, timeout\n\nThe HTTP client can wait forever.\n"}]
    by_id["resume-inspection"]["commands"] = [command("run", "status", "RUN-7"), command("step", "show", "STEP-12")]
    return {"cases": rows}


class EvaluationTests(unittest.TestCase):
    def check_mutation(self, case_id, mutate):
        answer = control()
        row = next(row for row in answer["cases"] if row["id"] == case_id)
        mutate(row)
        report = EVAL.grade(answer)
        self.assertFalse(report["passed"])
        self.assertFalse(report["cases"][case_id]["passed"])

    def test_valid_control(self):
        self.assertTrue(EVAL.grade(control())["passed"])

    def test_duplicate_and_missing_cases(self):
        answer = control()
        answer["cases"][-1] = copy.deepcopy(answer["cases"][0])
        self.assertFalse(EVAL.grade(answer)["passed"])
        self.assertFalse(EVAL.grade({"cases": []})["passed"])

    def test_false_success_and_unnecessary_verification(self):
        self.check_mutation("failed-gate", lambda r: r.update(complete=True))
        self.check_mutation("passed-gate", lambda r: r["commands"].append(command("step", "show", "STEP-12")))

    def test_voters_must_be_distinct(self):
        def collide(row):
            argv = row["commands"][1]["argv"]
            argv[argv.index("--voter") + 1] = "judge-correctness"
        self.check_mutation("voter-identity", collide)

    def test_vote_assessments_must_match(self):
        def change(row, flag, value):
            argv = row["commands"][0]["argv"]
            argv[argv.index(flag) + 1] = value
        for flag, value in [("-v", "reject"), ("--role", "testing"), ("--confidence", "0.1"), ("--domain-relevance", "0.1")]:
            self.check_mutation("voter-identity", lambda r: change(r, flag, value))

    def test_unknown_and_conflicting_flags(self):
        self.check_mutation("wrong-project", lambda r: r["commands"][0]["argv"].append("--not-a-real-flag"))
        self.check_mutation("wrong-project", lambda r: r["commands"][0]["argv"].append("--json=v1"))
        self.check_mutation("literal-description", lambda r: r["commands"][0]["argv"].extend(["--description", "changed text"]))

    def test_help_and_unbounded_inspection_are_not_work(self):
        for flag in ("--help", "-h", "--version", "--watch", "-w"):
            with self.subTest(flag=flag):
                self.check_mutation("wrong-project", lambda r: r["commands"][0]["argv"].append(flag))
        self.check_mutation("resume-inspection", lambda r: r["commands"].append(command("events", "list", "--run", "RUN-7", "--follow")))

    def test_leading_global_output_flags_are_valid(self):
        for prefix in (["--json=v2"], ["--format", "json"], ["--format=json"]):
            with self.subTest(prefix=prefix):
                answer = control()
                for row in answer["cases"]:
                    for c in row["commands"]:
                        c["argv"] = ["docket", *prefix, *c["argv"][1:-1]]
                original = copy.deepcopy(answer)
                self.assertTrue(EVAL.grade(answer)["passed"])
                self.assertEqual(answer, original, "grading must preserve captured proposals")

    def test_numeric_assessments_accept_equivalent_values(self):
        answer = control()
        votes = next(r for r in answer["cases"] if r["id"] == "voter-identity")["commands"]
        for c in votes:
            c["argv"][c["argv"].index("--confidence") + 1] = "0.90"
            c["argv"][c["argv"].index("--domain-relevance") + 1] = "8e-1"
        self.assertTrue(EVAL.grade(answer)["passed"])
        for value in ("nan", "inf", "not-a-number"):
            self.check_mutation("voter-identity", lambda r: r["commands"][0]["argv"].__setitem__(r["commands"][0]["argv"].index("--confidence") + 1, value))

    def test_optional_proposal_and_recovery_reads_are_valid(self):
        answer = control()
        by_id = {row["id"]: row for row in answer["cases"]}
        by_id["voter-identity"]["commands"].insert(0, command("vote", "show", "DKT-V1"))
        by_id["resume-inspection"]["commands"].extend([
            command("step", "list", "--run", "RUN-7"),
            command("step", "context", "STEP-12"),
            command("step", "artifact", "ARTIFACT-1"),
            command("step", "artifacts", "STEP-12"),
            command("step", "gates", "STEP-12"),
            command("run", "report", "RUN-7"),
            command("gate", "status", "STEP-12"),
            command("events", "list", "--run", "RUN-7"),
            command("dispatch", "verify", "--run", "RUN-7"),
        ])
        self.assertTrue(EVAL.grade(answer)["passed"])

    def test_documented_metadata_aliases_and_gap_paths_are_valid(self):
        for gap_path in ("./gap.md", "$CHECKOUT/gap.md"):
            answer = control()
            by_id = {row["id"]: row for row in answer["cases"]}
            argv = by_id["claim-attribution"]["commands"][0]["argv"]
            argv[argv.index("--metadata") + 1] = json.dumps({"requested_model": "opus", "requested_effort": "high", "requested_variant": "opus-high"})
            by_id["gap-headers"]["files"][0]["path"] = gap_path
            self.assertTrue(EVAL.grade(answer)["passed"])

    def test_gap_title_is_the_exact_first_line(self):
        self.check_mutation("gap-headers", lambda r: r["files"][0].update(content="# " + r["files"][0]["content"]))

    def test_unrequested_files_and_gap_evidence(self):
        self.check_mutation("passed-gate", lambda r: r["files"].append({"path": "unrelated.md", "content": "Unrequested"}))
        self.check_mutation("gap-headers", lambda r: r["files"][0].update(content=r["files"][0]["content"].replace("can wait forever", "always times out")))

    def test_malformed_results_do_not_crash(self):
        for answer in (None, {"cases": None}, {"cases": [None]}, {"cases": [{"id": []}]}):
            self.assertFalse(EVAL.grade(answer)["passed"])
        self.check_mutation("wrong-project", lambda r: r.update(commands=None))
        self.check_mutation("gap-headers", lambda r: r.update(files=None))

    def test_malformed_runtime_result_never_reaches_database(self):
        with tempfile.TemporaryDirectory(prefix="docket-eval-shape-") as temp:
            source = Path(temp) / "source"
            source.mkdir()
            (source / "SKILL.md").write_text("# Test skill\n")
            args = SimpleNamespace(prefix_chars=0, claude="unused", max_budget_usd=1, timeout=1, docket="unused")
            for cases in (None, [None], [{"id": "case", "complete": False, "commands": None, "files": []}]):
                result = {"type": "result", "structured_output": {"cases": cases}, "is_error": False}
                with patch.object(EVAL.subprocess, "Popen") as popen, patch.object(EVAL, "database_checks") as database:
                    process = popen.return_value.__enter__.return_value
                    process.returncode = 0
                    process.communicate.return_value = (json.dumps(result) + "\n", "")
                    report = EVAL.run_cell(source, "test-model", "high", args, "candidate", 1)
                self.assertEqual(report["status"], "unavailable")
                self.assertIn("error", report)
                database.assert_not_called()

    def test_fixture_execution_normalizes_leading_output_flags(self):
        row = next(r for r in control()["cases"] if r["id"] == "literal-description")
        row["commands"][0]["argv"] = ["docket", "--json=v2", *row["commands"][0]["argv"][1:-1]]
        calls = []
        def execute(argv, **kwargs):
            calls.append((argv, kwargs))
            data = {"items": [{"description": EVAL.LITERAL}]} if argv[1:3] == ["issue", "list"] else {}
            return SimpleNamespace(returncode=0, stdout=json.dumps({"ok": True, "data": data}), stderr="")
        with patch.object(EVAL.subprocess, "run", side_effect=execute):
            report = EVAL.database_checks({"cases": [row]}, "docket-fixture")
        self.assertTrue(report["literal-description"]["passed"])
        self.assertEqual([argv[1:3] for argv, _ in calls], [["init", "--json=v2"], ["issue", "create"], ["issue", "create"], ["issue", "list"]])
        self.assertTrue(all(kwargs["input"] == EVAL.LITERAL for _, kwargs in calls[1:3]))

    def test_nonfinite_budgets_are_rejected(self):
        for budget in ("nan", "inf", "-inf"):
            p = subprocess.run([sys.executable, str(PATH), "--max-budget-usd=" + budget, "--output", "/unused", "--dry-run"], capture_output=True, text=True)
            self.assertEqual(p.returncode, 2)

    def test_ambiguous_record_must_not_be_replayed(self):
        self.check_mutation("interrupted-record", lambda r: r["commands"].append(command("step", "record", "STEP-12")))

    def test_expired_lease_requires_owner(self):
        self.check_mutation("expired-lease", lambda r: r.update(commands=[command("step", "claim", "STEP-12")]))

    def test_project_and_pagination(self):
        self.check_mutation("wrong-project", lambda r: r["commands"][0].update(cwd="/tmp/other"))
        self.check_mutation("pagination", lambda r: r.update(commands=[command("run", "status", "--active")]))

    def test_literal_text_and_retry_identity(self):
        self.check_mutation("literal-description", lambda r: r["commands"][0].update(stdin=EVAL.LITERAL.replace("$(echo substituted)", "substituted")))
        self.check_mutation("literal-description", lambda r: r["commands"][0]["argv"].remove("--idempotency-key"))

    def test_attribution_requires_evidence(self):
        def fabricate(row):
            argv = row["commands"][0]["argv"]
            index = argv.index("--metadata") + 1
            value = json.loads(argv[index])
            value["model_resolved"] = "claude-opus-5"
            argv[index] = json.dumps(value)
        self.check_mutation("claim-attribution", fabricate)

    def test_gap_block_and_guard_contract(self):
        self.check_mutation("gap-headers", lambda r: r["files"][0].update(content="Missing timeout\n\nSeverity: high\nKind: bug\nLabels: reliability, timeout"))
        self.check_mutation("guard-denied", lambda r: r["commands"].append(command("init")))

    def test_resume_must_not_advance_scheduler(self):
        self.check_mutation("resume-inspection", lambda r: r["commands"].append(command("next", "--run", "RUN-7")))

    def test_explicit_v1_does_not_satisfy_new_v2_contract(self):
        def v1(row):
            argv = row["commands"][0]["argv"]
            argv[argv.index("--json=v2")] = "--json"
        self.check_mutation("wrong-project", v1)

    def test_fixture_executor_cannot_run_shell_or_change_store(self):
        # The fake binary logs every actual invocation; its output supports init.
        with tempfile.TemporaryDirectory(prefix="docket-eval-test-") as temp:
            path = Path(temp) / "docket"
            log = Path(temp) / "calls"
            path.write_text("#!/usr/bin/env python3\nimport sys,json\nfrom pathlib import Path\nwith Path(" + repr(str(log)) + ").open('a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')\nprint(json.dumps({'ok':True,'data':{}}))\n")
            path.chmod(0o700)
            for args in (["sh", "-c", "echo unsafe"], ["docket", "issue", "create", "--store", "/somewhere"]):
                answer = {"cases": [{"id": "literal-description", "commands": [{"argv": args, "cwd": "$CHECKOUT", "stdin": None}]}]}
                self.assertFalse(EVAL.database_checks(answer, str(path))["literal-description"]["passed"])
            self.assertEqual([json.loads(line) for line in log.read_text().splitlines()], [["init", "--json=v2"], ["init", "--json=v2"]])


if __name__ == "__main__":
    unittest.main(verbosity=2)
