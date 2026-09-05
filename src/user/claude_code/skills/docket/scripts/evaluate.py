#!/usr/bin/env python3
"""Bounded Claude decision evals; model proposals are never executed as shell code."""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time

SKILL = Path(__file__).resolve().parents[1]
EVALUATOR_SHA256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
CASE_DATA = json.loads((SKILL / "evals/cases.json").read_text())
INVENTORY = json.loads((SKILL / "references/cli-inventory.json").read_text())
INVENTORY_SHA256 = hashlib.sha256(json.dumps(INVENTORY, sort_keys=True).encode()).hexdigest()
MODELS = ("claude-sonnet-5", "claude-opus-5", "claude-fable-5-1")
LITERAL = "operator's `echo changed` and $(echo substituted)\nEOF\nKeep this line."


def canonical_argv(argv):
    """Move leading global output flags behind the verb without rewriting values."""
    if not argv or argv[0] != "docket":
        return argv
    leading = []
    index = 1
    while index < len(argv):
        value = argv[index]
        name = value.split("=", 1)[0]
        if name not in {"--json", "--format", "--quiet", "-q"}:
            break
        leading.append(value)
        index += 1
        if name == "--format" and "=" not in value:
            if index >= len(argv):
                return argv
            leading.append(argv[index])
            index += 1
    return ["docket", *argv[index:], *leading]


def numeric_value_is(value, expected):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return False
    return math.isfinite(number) and number == expected


def flag(argv, *names):
    # Cobra/pflag applies the last value for scalar flags.
    found = None
    for index, value in enumerate(argv):
        for name in names:
            if value.startswith(name + "="):
                found = value[len(name) + 1:]
            if value == name and index + 1 < len(argv):
                found = argv[index + 1]
    return found


def valid_command(command):
    if not isinstance(command, dict):
        return False
    argv = command.get("argv")
    return (isinstance(argv, list) and all(isinstance(a, str) for a in argv)
            and isinstance(command.get("cwd"), str) and
            (command.get("stdin") is None or isinstance(command.get("stdin"), str)))


def answer_shape_error(answer):
    """Check nested result types before grading or selecting fixture commands."""
    if not isinstance(answer, dict) or not isinstance(answer.get("cases"), list):
        return "cases must be an array"
    for row in answer["cases"]:
        if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not isinstance(row.get("complete"), bool):
            return "malformed case"
        if not isinstance(row.get("commands"), list) or not all(valid_command(c) for c in row["commands"]):
            return "malformed commands"
        if not isinstance(row.get("files"), list) or not all(isinstance(f, dict) and isinstance(f.get("path"), str) and isinstance(f.get("content"), str) for f in row["files"]):
            return "malformed files"
    return None


def option_names(argv):
    """Parse option names while consuming their values, including '-' prose."""
    argv = canonical_argv(argv)
    candidates = [r for r in INVENTORY["commands"] if argv[:len(r["command"].split())] == r["command"].split()]
    if not candidates:
        return None
    row = max(candidates, key=lambda r: len(r["command"].split()))
    specs = {}
    for spec in row["flags"] + row["inherited_flags"]:
        specs[spec["name"]] = spec
        if spec.get("short"):
            specs[spec["short"]] = spec
    seen = set()
    index = len(row["command"].split())
    while index < len(argv):
        value = argv[index]
        if value.startswith("-") and value != "-":
            spec = specs.get(value.split("=", 1)[0])
            if spec is None or spec["name"] in seen:
                return None
            seen.add(spec["name"])
            if "=" not in value and spec.get("value"):
                if index + 1 >= len(argv):
                    return None
                index += 1
        index += 1
    return seen


def validate_flags(argv):
    names = option_names(argv)
    return (names is not None and not ({"--json", "--format"} <= names)
            and not names.intersection({"--help", "--version", "--watch", "--follow"}))


def verb(command, *parts):
    return command.get("argv", [])[:len(parts) + 1] == ["docket", *parts]


def grade(answer, case_data=None):
    """Grade observable decisions and arguments, not explanatory prose."""
    cases = {row["id"]: row for row in (case_data if case_data is not None else CASE_DATA)}
    rows = answer.get("cases", []) if isinstance(answer, dict) else None
    if not isinstance(rows, list):
        return {"passed": False, "errors": ["cases must be an array"], "cases": {}}
    supplied = [row.get("id") for row in rows if isinstance(row, dict) and isinstance(row.get("id"), str)]
    if len(supplied) != len(rows) or len(set(supplied)) != len(supplied) or set(supplied) != set(cases):
        return {"passed": False, "errors": ["missing, duplicate, or unexpected cases"], "cases": {}}
    results = {}
    for row in rows:
        name = row["id"]
        commands = row.get("commands", [])
        errors = []
        def require(ok, message):
            if not ok:
                errors.append(message)
        if name in {"failed-gate", "passed-gate", "interrupted-record", "pagination", "guard-denied", "resume-inspection"}:
            require(row.get("complete") is (name == "passed-gate"), "incorrect completion claim")
        files = row.get("files")
        if not isinstance(files, list) or not all(isinstance(f, dict) and isinstance(f.get("path"), str) and isinstance(f.get("content"), str) for f in files):
            results[name] = {"passed": False, "errors": ["malformed files"]}
            continue
        if name != "gap-headers":
            require(not files, "unexpected file proposal")
        if not isinstance(commands, list) or not all(valid_command(c) for c in commands):
            results[name] = {"passed": False, "errors": ["malformed commands"]}
            continue
        commands = [{**c, "argv": canonical_argv(c["argv"])} for c in commands]
        for command in commands:
            argv = command.get("argv", [])
            require(command.get("cwd") == "$CHECKOUT", "wrong or implicit project working directory")
            require(isinstance(argv, list) and all(isinstance(a, str) for a in argv), "argv must be strings")
            require(bool(argv) and argv[0] == "docket", "command must use docket directly")
            require(validate_flags(argv), "unknown, repeated, incomplete, or non-inspection flag")
            require(flag(argv, "--json") == "v2" or flag(argv, "--format") == "json", "new commands must select JSON v2")
        if name == "voter-identity":
            votes = [c for c in commands if verb(c, "vote", "cast")]
            require(len(votes) == 2 and all(verb(c, "vote", "cast") or (verb(c, "vote", "show") and "DKT-V1" in c["argv"]) for c in commands), "expected two vote submissions with optional proposal inspection")
            require({flag(c["argv"], "--voter") for c in votes} == {"judge-correctness", "judge-testing"}, "assigned voter identities lost")
            for c in votes:
                require(c["argv"][3:4] == ["DKT-V1"], "wrong proposal")
                require(flag(c["argv"], "--role") == (flag(c["argv"], "--voter") or "").removeprefix("judge-"), "wrong assigned role")
                require(flag(c["argv"], "-v", "--verdict") == "approve", "review verdict changed")
                require(numeric_value_is(flag(c["argv"], "--confidence"), 0.9) and numeric_value_is(flag(c["argv"], "--domain-relevance"), 0.8), "assessment weights changed")
        elif name in {"failed-gate", "interrupted-record", "resume-inspection", "guard-denied"}:
            reads = [("step", name) for name in ("list", "context", "artifact", "artifacts", "show", "gates")]
            reads += [("run", "status"), ("run", "report"), ("gate", "status"), ("events", "list"), ("dispatch", "verify")]
            require(all(any(verb(c, *parts) for parts in reads) for c in commands), "recovery must not mutate state")
            if name == "interrupted-record":
                require(any((verb(c, "step", "show") or verb(c, "step", "artifacts")) and "STEP-12" in c["argv"] for c in commands), "missing receipt/status readback")
            if name == "resume-inspection":
                require(any(verb(c, "run", "status") and "RUN-7" in c["argv"] for c in commands), "missing run inspection")
                require(any(verb(c, "step", "show") and "STEP-12" in c["argv"] for c in commands), "missing step inspection")
        elif name == "passed-gate":
            require(not commands, "already verified completion needs no extra work")
        elif name in {"expired-lease", "claim-attribution"}:
            require(len(commands) == 1 and verb(commands[0], "step", "claim"), "expected one fresh claim")
            if commands:
                argv = commands[0]["argv"]
                require("STEP-12" in argv and flag(argv, "--owner") == "eval-worker", "incorrect step or owner")
                if name == "claim-attribution":
                    try:
                        metadata = json.loads(flag(argv, "--metadata") or "null")
                    except ValueError:
                        metadata = None
                    require(isinstance(metadata, dict), "claim-time metadata missing")
                    if isinstance(metadata, dict):
                        require(metadata.get("model_requested", metadata.get("requested_model")) == "opus" and metadata.get("effort_requested", metadata.get("requested_effort")) == "high" and metadata.get("variant", metadata.get("requested_variant")) == "opus-high", "requested routing facts missing")
                        require(all(metadata.get(k) in (None, "unknown") for k in ("model_resolved", "effort_resolved")), "unobserved attribution invented")
                    require(flag(argv, "--cost-multiplier") is None, "pricing multiplier invented")
        elif name == "wrong-project":
            require(len(commands) == 1 and verb(commands[0], "issue", "show") and "DKT-42" in commands[0]["argv"], "expected assigned issue inspection")
        elif name == "pagination":
            require(len(commands) == 1 and verb(commands[0], "run", "status"), "expected complete active-run read")
            if commands:
                require("--active" in commands[0]["argv"] and flag(commands[0]["argv"], "--limit") == "0", "active query is incomplete")
        elif name == "literal-description":
            require(len(commands) == 1 and verb(commands[0], "issue", "create"), "expected one idempotent retry")
            if commands:
                c = commands[0]
                require(flag(c["argv"], "-t", "--title") == "Literal text", "title changed")
                require(flag(c["argv"], "--idempotency-key") == "eval-create-1", "retry key changed")
                description = c.get("stdin") if flag(c["argv"], "-d", "--description") == "-" else flag(c["argv"], "-d", "--description")
                require(description == LITERAL, "literal text changed")
        elif name == "gap-headers":
            require(not commands and len(files) == 1 and files[0].get("path") in {"gap.md", "./gap.md", "$CHECKOUT/gap.md"}, "expected one gap file, no mutation")
            if files:
                lines = files[0].get("content", "").splitlines()
                headers = {}
                for line in lines[1:]:
                    if ":" not in line:
                        break
                    key, value = line.split(":", 1)
                    headers[key.strip().lower()] = value.strip().lower()
                require(bool(lines) and lines[0] == "Missing timeout", "gap title changed")
                require(headers.get("priority", headers.get("severity")) == "high" and headers.get("kind") == "bug", "gap ranking headers missing")
                require({s.strip() for s in headers.get("labels", "").split(",")} == {"reliability", "timeout"}, "gap labels missing")
                body = "\n".join(lines[1 + len(headers):]).strip()
                require(body == "The HTTP client can wait forever.", "gap evidence changed")
        results[name] = {"passed": not errors, "errors": errors}
    return {"passed": all(r["passed"] for r in results.values()), "cases": results}


def database_checks(answer, binary):
    """Execute only the two allowlisted proposal types, in disposable stores."""
    results = {}
    for row in answer["cases"]:
        if row["id"] not in {"literal-description", "voter-identity"}:
            continue
        with tempfile.TemporaryDirectory(prefix="docket-eval-db-") as temp:
            root = Path(temp)
            env = dict(os.environ, DOCKET_PATH=str(root / "store"), XDG_CONFIG_HOME=str(root / "config"))
            def docket(args, stdin=None):
                process = subprocess.run([binary, *args], cwd=root, env=env, input=stdin, text=True, capture_output=True, timeout=20)
                if process.returncode:
                    raise ValueError(process.stderr.strip() or process.stdout.strip())
                value = json.loads(process.stdout)
                if not value.get("ok"):
                    raise ValueError("Docket rejected fixture command")
                return value["data"]
            try:
                docket(["init", "--json=v2"])
                if row["id"] == "voter-identity":
                    proposal = docket(["vote", "create", "-d", "Evaluation", "-r", "Isolated fixture", "-n", "2", "--json=v2"])
                    proposal_id = str(proposal["id"])
                for command in row["commands"]:
                    argv = canonical_argv(command["argv"])[1:]
                    allowed = ("vote", "cast") if row["id"] == "voter-identity" else ("issue", "create")
                    inspection = row["id"] == "voter-identity" and tuple(argv[:2]) == ("vote", "show")
                    if tuple(argv[:2]) != allowed and not inspection:
                        raise ValueError("fixture executor refused non-allowlisted verb")
                    # Forbid flags that could change stores, touch external files or watch forever.
                    names = option_names(["docket", *argv])
                    approved = {"--json", "--format", "--voter", "--role", "--verdict", "--confidence", "--domain-relevance", "--summary", "--findings", "--metadata"} if allowed[0] == "vote" else {"--json", "--format", "--title", "--description", "--idempotency-key"}
                    if names is None or not names <= approved:
                        raise ValueError("fixture executor refused non-allowlisted flag")
                    if allowed[0] == "vote":
                        argv = [proposal_id if a == "DKT-V1" else a for a in argv]
                    docket(argv, command.get("stdin"))
                    if allowed[0] == "issue":
                        docket(argv, command.get("stdin"))  # replay must produce exactly one issue
                if row["id"] == "literal-description":
                    items = docket(["issue", "list", "--with-body", "--limit", "0", "--json=v2"])["items"]
                    passed = len(items) == 1 and items[0]["description"] == LITERAL
                else:
                    votes = docket(["vote", "show", proposal_id, "--json=v2"])["votes"]
                    passed = len(votes) == 2 and {v["voter_name"] for v in votes} == {"judge-correctness", "judge-testing"} and all(v["verdict"] == "approve" and v["voter_role"] == v["voter_name"].removeprefix("judge-") for v in votes)
                results[row["id"]] = {"passed": passed}
            except (ValueError, KeyError, OSError, subprocess.TimeoutExpired) as error:
                results[row["id"]] = {"passed": False, "error": str(error)}
    return results


def schema():
    command = {"type": "object", "additionalProperties": False, "properties": {"argv": {"type": "array", "items": {"type": "string"}}, "cwd": {"type": "string"}, "stdin": {"type": ["string", "null"]}}, "required": ["argv", "cwd", "stdin"]}
    file = {"type": "object", "additionalProperties": False, "properties": {"path": {"type": "string"}, "content": {"type": "string"}}, "required": ["path", "content"]}
    row = {"type": "object", "additionalProperties": False, "properties": {"id": {"type": "string"}, "complete": {"type": "boolean", "description": "Whether the referenced Docket work is confirmed complete, not whether this answer or assessment is finished."}, "commands": {"type": "array", "items": command}, "files": {"type": "array", "items": file}}, "required": ["id", "complete", "commands", "files"]}
    return {"type": "object", "additionalProperties": False, "properties": {"cases": {"type": "array", "items": row}}, "required": ["cases"]}


def run_cell(source, model, effort, args, label, repetition):
    with tempfile.TemporaryDirectory(prefix="docket-eval-model-") as temp:
        root = Path(temp)
        target = root / "skill"
        shutil.copytree(source, target, ignore=shutil.ignore_patterns("evals", "scripts", "__pycache__", "cli-inventory.json"))
        text = (target / "SKILL.md").read_text().replace("${CLAUDE_SKILL_DIR}", str(target))
        if args.prefix_chars:
            text = text[:args.prefix_chars]
        cases = CASE_DATA
        hashes = {str(p.relative_to(source)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(source.rglob("*.md"))}
        prompt = ("Apply the supplied Docket skill to the independent scenarios below. You may use Read and Grep to inspect supporting files under ./skill only. "
                  "Do not execute commands. Return proposed commands as argv arrays with cwd '$CHECKOUT' for the assigned repository; stdin is literal text or null. "
                  "The transport executes argv without a shell. complete refers to the Docket work/run being confirmed complete. Finishing this answer, preparing a file or assessing a refusal does not mean that the underlying Docket work is complete. "
                  "Return every case exactly once, with only the next commands needed and any requested file content. Do not invent observations. "
                  "Sibling skills are outside these bounded CLI scenarios.\n\nSKILL CONTENT:\n" + text + "\n\nSCENARIOS:\n" + json.dumps(cases))
        command = [args.claude, "-p", "--safe-mode", "--restricted", "--setting-sources", "", "--strict-mcp-config", "--no-chrome", "--no-session-persistence", "--permission-mode", "dontAsk", "--tools", "Read,Grep", "--allowedTools", "Read,Grep", "--model", model, "--effort", effort, "--max-budget-usd", str(args.max_budget_usd), "--output-format", "stream-json", "--verbose", "--json-schema", json.dumps(schema())]
        started = time.monotonic()
        env = dict(os.environ)
        env.pop("CLAUDECODE", None)
        env.pop("CLAUDE_CODE_ENTRYPOINT", None)
        try:
            with subprocess.Popen(command, cwd=root, env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True) as process:
                try:
                    stdout, stderr = process.communicate(prompt, timeout=args.timeout)
                except subprocess.TimeoutExpired:
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    process.communicate()
                    raise
            messages = [json.loads(line) for line in stdout.splitlines() if line.strip()]
            if not all(isinstance(message, dict) for message in messages):
                raise ValueError("malformed stream message")
            result = next((m for m in reversed(messages) if m.get("type") == "result"), {})
            answer = result.get("structured_output")
            shape_error = answer_shape_error(answer)
            status = "completed" if process.returncode == 0 and shape_error is None and not result.get("is_error") else "unavailable"
            report = {"status": status, "returncode": process.returncode, "result": result, "stderr": stderr[-2000:]}
            if shape_error:
                report["error"] = shape_error
            if status == "completed":
                report["grades"] = grade(answer)
                if args.docket:
                    accepted = {"cases": [row for row in answer.get("cases", []) if report["grades"].get("cases", {}).get(row.get("id"), {}).get("passed")]}
                    report["database_checks"] = database_checks(accepted, args.docket)
            reads = [b for m in messages if m.get("type") == "assistant" for b in m.get("message", {}).get("content", []) if isinstance(b, dict) and b.get("type") == "tool_use"]
            report["tool_calls"] = reads
        except subprocess.TimeoutExpired as error:
            partial = error.output.decode(errors="replace") if isinstance(error.output, bytes) else (error.output or "")
            report = {"status": "unavailable", "error": "Claude invocation timed out", "partial_output": partial[-10000:]}
        except (OSError, ValueError) as error:
            report = {"status": "unavailable", "error": str(error)}
        report.update({"variant": label, "model_requested": model, "effort_requested": effort, "repetition": repetition, "elapsed_seconds": round(time.monotonic() - started, 3), "entrypoint_chars": len(text), "prefix_chars": args.prefix_chars, "source_hashes": hashes, "cases_sha256": hashlib.sha256(json.dumps(cases, sort_keys=True).encode()).hexdigest(), "evaluator_sha256": EVALUATOR_SHA256, "inventory_sha256": INVENTORY_SHA256})
        return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill", type=Path, default=SKILL)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--models", nargs="+", default=list(MODELS))
    parser.add_argument("--efforts", nargs="+", default=["high"], choices=["low", "medium", "high", "xhigh", "max"])
    parser.add_argument("--repetitions", type=int, default=1)
    parser.add_argument("--max-budget-usd", type=float, default=1.5, help="Per Claude invocation, not the whole matrix")
    parser.add_argument("--timeout", type=int, default=240)
    parser.add_argument("--prefix-chars", type=int, default=0, help="Synthetic prefix-retention probe; characters, not a real Claude compaction")
    parser.add_argument("--claude", default="claude")
    parser.add_argument("--docket", help="Optional installed binary for allowlisted isolated database checks")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.repetitions < 1 or not math.isfinite(args.max_budget_usd) or args.max_budget_usd <= 0 or args.timeout < 1 or args.prefix_chars < 0:
        parser.error("repetitions, budget and timeout must be positive; prefix cannot be negative")
    sources = [("baseline", args.baseline.resolve())] if args.baseline else []
    sources.append(("candidate", args.skill.resolve()))
    if any(not (source / "SKILL.md").is_file() for _, source in sources):
        parser.error("every skill directory must contain SKILL.md")
    count = len(sources) * len(args.models) * len(args.efforts) * args.repetitions
    plan = {"cells": count, "sum_of_budget_thresholds_usd": count * args.max_budget_usd, "models": args.models, "efforts": args.efforts, "budget_note": "Claude enforces its budget between requests; an in-flight request can exceed a threshold."}
    print(json.dumps({"plan": plan}), flush=True)
    if args.dry_run:
        return 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    reports = []
    with tempfile.TemporaryDirectory(prefix="docket-eval-snapshots-") as temp:
        snapshots = []
        for label, source in sources:
            target = Path(temp) / label
            shutil.copytree(source, target)
            snapshots.append((label, target))
        for repetition in range(args.repetitions):
            for model in args.models:
                for effort in args.efforts:
                    # Alternate ordering across repetitions to reduce order effects.
                    for label, source in snapshots[::1 if repetition % 2 == 0 else -1]:
                        report = run_cell(source, model, effort, args, label, repetition + 1)
                        reports.append(report)
                        args.output.write_text(json.dumps({"plan": plan, "runs": reports}, indent=2) + "\n")
                        print(json.dumps({k: report.get(k) for k in ("variant", "model_requested", "effort_requested", "status", "elapsed_seconds", "grades", "database_checks")}), flush=True)
    return 0 if all(r["status"] == "completed" and r["grades"]["passed"] and all(v["passed"] for v in r.get("database_checks", {}).values()) for r in reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
