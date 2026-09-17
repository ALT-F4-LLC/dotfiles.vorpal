#!/usr/bin/env python3
"""Exercise Docket's command surface against a throwaway store and record what each verb emits.

The sweep is the runtime half of the audit. `cli_inventory.py` (docket skill)
records what `--help` advertises; this script records what the commands do:
exit code, human output, and both JSON dialects (`--json`, `--format json`),
for every command the inventory lists, driven by a scripted scenario.

Isolation is the script's responsibility, not the caller's. Every probe runs
with HOME, XDG_*_HOME and the git config pointed at a scratch directory, so
the operator's ~/.docket store and ~/.config/docket/trust.toml are never
opened. After `docket init` the script asserts the store it will write lives
under the scratch root and aborts otherwise. With an empty trust roster no
gate command can run; the scenario's own `trust add` steps are refused unless
they come after every run- and step-level verb.
"""

import argparse
import datetime
import difflib
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


SKILL_DIR = Path(__file__).resolve().parent.parent
DEFAULT_SCENARIO = SKILL_DIR / "references/sweep-scenario.json"
DEFAULT_FIXTURES = SKILL_DIR / "references/cli-fixtures.json"
DEFAULT_INVENTORY = SKILL_DIR.parent / "docket/references/cli-inventory.json"
DEFAULT_CORPUS = SKILL_DIR.parent.parent.parent / "docket/config"

MODES = {"text": [], "json": ["--json"], "format": ["--format", "json"]}
# Flags that block on a terminal, and the one verb that executes trusted
# commands. Refused here so a scenario edit cannot reintroduce them.
BLOCKING_FLAGS = {"--watch", "-w", "--follow", "--interval"}
FORBIDDEN_PREFIXES = (("trust", "probe"),)
# Verbs after which gate execution could happen if the roster held an entry.
GATE_VERBS = {("run", "activate"), ("step", "complete"), ("step", "record"), ("step", "fail"), ("step", "resolve")}
ENGINE_GROUPS = {"run", "step", "dispatch", "gate", "guard", "next", "vote", "policy"}
PLACEHOLDER = re.compile(r"\{([a-z][a-z0-9_]*)\}")
INT_KEY = re.compile(r"(_ms|_bytes|_at|size|duration|elapsed)$")


class SweepError(Exception):
    """The scenario, the inventory, or the isolation could not be trusted."""


def sha256(data):
    return hashlib.sha256(data if isinstance(data, bytes) else data.encode("utf-8")).hexdigest()


# --- normalization -----------------------------------------------------------

def normalizer(scratch, checkout):
    roots = [(p, "<SCRATCH>") for p in {str(scratch), str(Path(scratch).resolve())}]
    roots += [(p, "<CHECKOUT>") for p in {str(checkout), str(Path(checkout).resolve())}]
    roots.sort(key=lambda pair: len(pair[0]), reverse=True)
    rules = [
        (re.compile(r"\b[0-9a-f]{64}\b"), "<HEX64>"),
        (re.compile(r"\b[0-9a-f]{40}\b"), "<HEX40>"),
        (re.compile(r"\b[0-9a-f]{12}\b"), "<HEX12>"),
        (re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})"), "<TIMESTAMP>"),
        (re.compile(r"\b\d{4}-\d{2}-\d{2}\b"), "<DATE>"),
        (re.compile(r"\b\d{2}:\d{2}:\d{2}\b"), "<CLOCK>"),
        (re.compile(r"\b\d+(?:\.\d+)? ?(?:B|KB|MB|GB|KiB|MiB)\b"), "<SIZE>"),
        (re.compile(r"\b\d+(?:\.\d+)?(?:ms|µs|us|ns|s|m|h)\b"), "<DURATION>"),
        (re.compile(r"\b\d+ (?:second|minute|hour|day|week|month|year)s? ago\b"), "<AGO>"),
        # A relative age renders as "now" under a second and "N seconds ago"
        # after it; only the column/label forms are rewritten, not prose.
        (re.compile(r"(?m)(?<=: )now\b|^(\s*)now(?=\s)|(?<=\s)now(?=\s*$)|(?<=\s)now(?=\s*│)"), r"\1<AGO>"),
        (re.compile(r"\b1[6-9]\d{11}\b"), "<MS>"),
        # Table columns are padded to their widest cell, so a placeholder of a
        # different length would shift every row; alignment is not behavior.
        (re.compile(r"(?m)(?<=\S) {2,}"), " "),
        (re.compile(r"(?m)[ \t]+$"), ""),
    ]

    # The operator's login name can surface as a default author; it is not
    # part of the CLI's behavior and must not land in a committed fixture.
    user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""

    def text(value):
        for root, token in roots:
            value = value.replace(root, token)
        if user:
            value = value.replace(user, "<USER>")
        for pattern, token in rules:
            value = pattern.sub(token, value)
        return value

    def tree(value, key=""):
        if isinstance(value, dict):
            return {k: tree(v, k) for k, v in value.items()}
        if isinstance(value, list):
            return [tree(v, key) for v in value]
        if isinstance(value, str):
            return text(value)
        if isinstance(value, bool) or value is None:
            return value
        if isinstance(value, (int, float)) and (INT_KEY.search(key) or abs(value) >= 10**9):
            return "<N>"
        return value

    return text, tree


def unordered(value):
    """Sort every list recursively, for output whose order ties on the clock."""
    if isinstance(value, dict):
        return {k: unordered(v) for k, v in value.items()}
    if isinstance(value, list):
        return sorted((unordered(v) for v in value), key=lambda v: json.dumps(v, sort_keys=True, ensure_ascii=False))
    return value


# --- scenario ----------------------------------------------------------------

def load_scenario(path):
    scenario = json.loads(path.read_text())
    if not isinstance(scenario, dict) or scenario.get("schema_version") != 1:
        raise SweepError("unsupported scenario schema")
    steps = scenario.get("steps")
    if not isinstance(steps, list) or not steps:
        raise SweepError("scenario declares no steps")
    seen = set()
    for step in steps:
        if not isinstance(step, dict) or not isinstance(step.get("id"), str) or not isinstance(step.get("argv"), list):
            raise SweepError(f"malformed step: {step!r}")
        if step["id"] in seen:
            raise SweepError(f"duplicate step id: {step['id']}")
        seen.add(step["id"])
        for mode in step.get("modes", ["text", "json", "format"]):
            if mode not in MODES:
                raise SweepError(f"step {step['id']}: unknown mode {mode!r}")
        forbid(step)
    check_trust_order(steps)
    skipped = scenario.get("skipped", [])
    for row in skipped:
        if not isinstance(row, dict) or not row.get("command") or not row.get("reason"):
            raise SweepError(f"skip row needs command and reason: {row!r}")
    return scenario


def forbid(step):
    argv = step["argv"]
    tokens = {tok.split("=", 1)[0] for tok in argv if isinstance(tok, str)}
    hit = tokens & BLOCKING_FLAGS
    if hit:
        raise SweepError(f"step {step['id']}: {sorted(hit)} block on a terminal and are refused")
    words = tuple(positional(argv))
    for prefix in FORBIDDEN_PREFIXES:
        if words[: len(prefix)] == prefix:
            raise SweepError(f"step {step['id']}: 'docket {' '.join(prefix)}' executes trusted commands and is refused")


def positional(argv):
    out = []
    for tok in argv:
        if tok.startswith("-"):
            break
        out.append(tok)
    return out


def check_trust_order(steps):
    first_add = next((i for i, s in enumerate(steps) if positional(s["argv"])[:2] == ["trust", "add"]), None)
    if first_add is None:
        return
    last_engine = max((i for i, s in enumerate(steps) if positional(s["argv"])[:1] and positional(s["argv"])[0] in ENGINE_GROUPS), default=-1)
    if last_engine > first_add:
        raise SweepError(
            f"step {steps[first_add]['id']} adds a trust entry before engine step {steps[last_engine]['id']}; "
            "trust steps must come after every run, step, dispatch, gate, guard, next, vote and policy step"
        )


def covered_command(argv, commands):
    words = positional(argv)
    while words:
        name = " ".join(["docket", *words])
        if name in commands:
            return name
        words.pop()
    return "docket"


def check_coverage(scenario, inventory):
    commands = {row["command"] for row in inventory["commands"]}
    covered = {}
    for step in scenario["steps"]:
        names = [covered_command(step["argv"], commands), *step.get("covers", [])]
        for name in names:
            covered.setdefault(name, []).append(step["id"])
    skipped = {row["command"]: row["reason"] for row in scenario.get("skipped", [])}
    problems = []
    for name in sorted(commands - set(covered) - set(skipped)):
        problems.append(f"uncovered: {name} (add a step or a skip row with a reason)")
    for name in sorted(set(skipped) & set(covered)):
        problems.append(f"stale skip: {name} is exercised by {covered[name]}")
    for name in sorted((set(skipped) | set(covered)) - commands):
        problems.append(f"not in inventory: {name} (removed upstream? refresh cli-inventory.json first)")
    if problems:
        raise SweepError("coverage check failed:\n  " + "\n  ".join(problems))
    return {"exercised": sorted(covered), "skipped": [{"command": k, "reason": skipped[k]} for k in sorted(skipped)]}


# --- execution ---------------------------------------------------------------

class Runner:
    def __init__(self, binary, scratch, corpus, timeout):
        self.binary = binary
        self.scratch = Path(scratch)
        self.corpus = corpus
        self.timeout = timeout
        self.repo = self.scratch / "repo"
        self.captures = {
            "scratch": str(self.scratch), "repo": str(self.repo), "corpus": str(corpus),
            "checkout": str(Path(corpus).resolve().parents[2]),
        }
        self.norm_text, self.norm_tree = normalizer(self.scratch, self.captures["checkout"])
        self.env = self.isolated_env()
        # A second repository so project-level verbs have something other than
        # the main project to name, list and delete.
        self.prepare_repo(self.repo)
        self.prepare_repo(self.scratch / "repo2")

    def isolated_env(self):
        home = self.scratch / "home"
        for sub in ("home", "config", "data", "state", "cache"):
            (self.scratch / sub).mkdir(parents=True, exist_ok=True)
        env = {k: v for k, v in os.environ.items() if not k.startswith("DOCKET_")}
        env.update({
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(self.scratch / "config"),
            "XDG_DATA_HOME": str(self.scratch / "data"),
            "XDG_STATE_HOME": str(self.scratch / "state"),
            "XDG_CACHE_HOME": str(self.scratch / "cache"),
            "GIT_CONFIG_GLOBAL": str(self.scratch / "gitconfig"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "sweep", "GIT_AUTHOR_EMAIL": "sweep@example.invalid",
            "GIT_COMMITTER_NAME": "sweep", "GIT_COMMITTER_EMAIL": "sweep@example.invalid",
            "NO_COLOR": "1", "TERM": "dumb", "COLUMNS": "120", "TZ": "UTC", "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8",
        })
        (self.scratch / "gitconfig").write_text("[user]\n\tname = sweep\n\temail = sweep@example.invalid\n")
        return env

    def prepare_repo(self, path):
        path.mkdir(parents=True, exist_ok=True)
        git = ["git", "-c", "init.defaultBranch=main"]
        subprocess.run([*git, "init", "-q", "."], cwd=path, env=self.env, check=True, capture_output=True)
        (path / "README.md").write_text("scratch repository for the docket CLI sweep\n")
        subprocess.run(["git", "add", "README.md"], cwd=path, env=self.env, check=True, capture_output=True)
        subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=path, env=self.env, check=True, capture_output=True)

    def substitute(self, value):
        def repl(match):
            name = match.group(1)
            if name not in self.captures:
                raise SweepError(f"placeholder {{{name}}} was never captured")
            return self.captures[name]
        return PLACEHOLDER.sub(repl, value)

    def run(self, argv, cwd, stdin=None, extra_env=None):
        env = dict(self.env)
        if extra_env:
            env.update({k: self.substitute(v) for k, v in extra_env.items()})
        # A verb that accepts a token on stdin blocks on an inherited terminal;
        # a probe with no scripted stdin gets a closed one.
        stream = {"input": stdin} if stdin is not None else {"stdin": subprocess.DEVNULL}
        try:
            result = subprocess.run(
                [self.binary, *argv], cwd=cwd, env=env, capture_output=True, text=True,
                check=False, timeout=self.timeout, **stream,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise SweepError(f"docket {' '.join(argv)} failed to run: {exc}") from exc
        return result

    def assert_isolated(self):
        result = self.run(["config", "--json"], self.repo)
        try:
            data = json.loads(result.stdout)["data"]
            db_path = Path(data["db_path"]).resolve()
        except (ValueError, KeyError, TypeError) as exc:
            raise SweepError(f"could not read the store path after init: {result.stdout!r} {result.stderr!r}") from exc
        root = self.scratch.resolve()
        if root not in db_path.parents:
            raise SweepError(f"REFUSING TO CONTINUE: docket opened {db_path}, outside the scratch root {root}")
        if data.get("docket_path_set"):
            raise SweepError("REFUSING TO CONTINUE: DOCKET_PATH leaked into the probe environment")

    def assert_trust_empty(self, step_id):
        result = self.run(["trust", "list", "--json"], self.repo)
        try:
            entries = json.loads(result.stdout)["data"]["entries"]
        except (ValueError, KeyError, TypeError) as exc:
            raise SweepError(f"could not read the trust roster before {step_id}: {result.stdout!r}") from exc
        if entries:
            raise SweepError(f"REFUSING TO CONTINUE: trust roster holds {len(entries)} entries before {step_id}")

    def execute(self, step):
        cwd = self.repo / step.get("cwd", ".")
        for rel, content in step.get("files", {}).items():
            target = cwd / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            if content.startswith("@corpus/"):
                target.write_bytes((Path(self.corpus) / content[len("@corpus/"):]).read_bytes())
            else:
                target.write_text(self.substitute(content))
        argv = [self.substitute(tok) for tok in step["argv"]]
        words = tuple(positional(argv)[:2])
        if words in GATE_VERBS:
            self.assert_trust_empty(step["id"])
        stdin = self.substitute(step["stdin"]) if "stdin" in step else None
        records = []
        parsed = None
        for mode in step.get("modes", ["text", "json", "format"]):
            # A verb that takes `--` needs the output flag before it.
            at = step.get("mode_at", len(argv))
            full = [*argv[:at], *MODES[mode], *argv[at:]]
            result = self.run(full, cwd, stdin, step.get("env"))
            expect = step.get("expect_exit")
            if expect is not None and result.returncode != expect:
                raise SweepError(
                    f"step {step['id']} ({mode}) exited {result.returncode}, expected {expect}\n"
                    f"stdout: {result.stdout[-2000:]}\nstderr: {result.stderr[-2000:]}"
                )
            record = {"id": step["id"], "mode": mode, "argv": ["docket", *(self.norm_text(tok) for tok in full)], "exit": result.returncode}
            if mode == "text" or step.get("body") == "text":
                if step.get("body") == "hash":
                    record["stdout_sha256"] = sha256(result.stdout)
                    record["stdout_lines"] = result.stdout.count("\n")
                elif step.get("unordered"):
                    record["stdout_lines_sorted"] = sorted(self.norm_text(result.stdout).splitlines())
                else:
                    record["stdout"] = self.norm_text(result.stdout)
            else:
                try:
                    document = json.loads(result.stdout) if result.stdout.strip() else None
                except ValueError:
                    document = None
                if document is None:
                    record["stdout"] = self.norm_text(result.stdout)
                else:
                    record["json"] = self.norm_tree(document)
                    if step.get("unordered"):
                        record["json"] = unordered(record["json"])
                    if parsed is None or mode == "json":
                        parsed = document
            record["stderr"] = self.norm_text(result.stderr)
            records.append(record)
        for name, path in step.get("capture", {}).items():
            self.captures[name] = capture(parsed, path, step["id"])
        return records


def capture(document, path, step_id):
    if document is None:
        raise SweepError(f"step {step_id}: nothing to capture from; a JSON mode must run first")
    node = document
    for part in path.split("."):
        if isinstance(node, list):
            try:
                node = node[int(part)]
            except (ValueError, IndexError) as exc:
                raise SweepError(f"step {step_id}: capture path {path} does not resolve") from exc
        elif isinstance(node, dict) and part in node:
            node = node[part]
        else:
            raise SweepError(f"step {step_id}: capture path {path} does not resolve")
    return node if isinstance(node, str) else json.dumps(node, separators=(",", ":"))


def collect(args, scenario, inventory):
    coverage = check_coverage(scenario, inventory)
    scratch = Path(tempfile.mkdtemp(prefix="docket-cli-sweep-", dir=os.environ.get("TMPDIR")))
    results = []
    try:
        runner = Runner(args.binary, scratch, args.corpus, args.timeout)
        version = runner.run(["--version"], runner.repo)
        if version.returncode or not version.stdout.strip():
            raise SweepError(f"--version probe failed: {version.stderr.strip()}")
        initialized = False
        for step in scenario["steps"]:
            words = positional(step["argv"])
            if not initialized and words[:1] != ["init"] and words[:1] not in (["version"], ["help"], ["completion"], []):
                raise SweepError(f"step {step['id']} runs before 'docket init'; the store must be created and checked first")
            results.extend(runner.execute(step))
            if words[:1] == ["init"] and not initialized:
                runner.assert_isolated()
                initialized = True
    finally:
        if args.keep:
            print(f"Scratch kept at {scratch}", file=sys.stderr)
        else:
            shutil.rmtree(scratch, ignore_errors=True)
    return {
        "schema_version": 1,
        "verified_on": datetime.datetime.now(datetime.timezone.utc).date().isoformat(),
        "binary_version": version.stdout.strip(),
        "inventory_version": inventory.get("binary_version"),
        "scenario_sha256": sha256(args.scenario.read_bytes()),
        "probe_contract": (
            "Every probe runs against a scratch HOME, XDG config and git repository; "
            "the trust roster is empty for every run- and step-level verb; "
            "--watch, --follow, --interval and 'trust probe' are refused."
        ),
        "coverage": coverage,
        "results": results,
    }


def digest(fixtures, inventory):
    """One Markdown line per record: what a reader needs before grepping the fixtures."""
    commands = {row["command"] for row in inventory["commands"]}
    by_command = {}
    for record in fixtures["results"]:
        name = covered_command(record["argv"][1:], commands)
        by_command.setdefault(name, []).append(record)
    lines = [
        f"# Docket CLI digest: {fixtures['binary_version']}",
        "",
        f"Help surface: {fixtures.get('inventory_version')}. Sweep verified {fixtures['verified_on']}.",
        f"Skipped: {', '.join(row['command'] + ' (' + row['reason'] + ')' for row in fixtures['coverage']['skipped']) or 'none'}.",
        "",
        "Per record: `id/mode exit=N` then the JSON `data` keys (or `error`+`code`), or the first text line.",
        "",
    ]
    for name in sorted(by_command):
        lines.append(f"## {name}")
        for record in by_command[name]:
            body = record.get("json")
            if isinstance(body, dict):
                data = body.get("data")
                if body.get("ok") is False:
                    head = f"error={body.get('error')!r} code={body.get('code')}"
                elif isinstance(data, dict):
                    head = "data keys: " + ", ".join(data.keys())
                elif isinstance(data, list):
                    inner = data[0].keys() if data and isinstance(data[0], dict) else []
                    head = f"data: list[{len(data)}]" + (" of {" + ", ".join(inner) + "}" if inner else "")
                else:
                    head = f"data: {json.dumps(data)}"
            elif "stdout_sha256" in record:
                head = f"{record['stdout_lines']} lines (hashed)"
            elif "stdout_lines_sorted" in record:
                head = (record["stdout_lines_sorted"] or ["<empty>"])[0]
            else:
                text = (record.get("stdout") or "").strip()
                head = text.splitlines()[0] if text else "<empty>"
                if not text and record.get("stderr", "").strip():
                    head = "stderr: " + record["stderr"].strip().splitlines()[0]
            lines.append(f"- {record['id']}/{record['mode']} exit={record['exit']}: {head[:160]}")
        lines.append("")
    return "\n".join(lines) + "\n"


def serialized(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def comparable(value):
    value = dict(value)
    value.pop("verified_on", None)
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--binary", default="docket", help="Docket executable path (default: docket on PATH)")
    parser.add_argument("--scenario", type=Path, default=DEFAULT_SCENARIO)
    parser.add_argument("--fixtures", type=Path, default=DEFAULT_FIXTURES)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--corpus", type=Path, default=DEFAULT_CORPUS, help="src/user/docket/config checkout the scenario may read from (never written)")
    parser.add_argument("--timeout", type=float, default=30, help="seconds allowed per probe")
    parser.add_argument("--keep", action="store_true", help="keep the scratch directory for inspection")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="fail if the recorded fixtures differ from what the installed binary emits")
    mode.add_argument("--write", action="store_true", help="replace the fixtures after a complete sweep")
    mode.add_argument("--coverage", action="store_true", help="only check that the scenario covers the inventory; run nothing")
    mode.add_argument("--digest", action="store_true", help="print a Markdown digest of the recorded fixtures; run nothing")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    try:
        scenario = load_scenario(args.scenario)
        inventory = json.loads(args.inventory.read_text())
        if not isinstance(inventory, dict) or inventory.get("schema_version") != 1:
            raise SweepError("unsupported inventory schema")
        if args.coverage:
            coverage = check_coverage(scenario, inventory)
            print(f"Scenario covers {len(coverage['exercised'])} commands; {len(coverage['skipped'])} skipped with a reason.")
            return 0
        if args.digest:
            fixtures = json.loads(args.fixtures.read_text())
            if not isinstance(fixtures, dict) or fixtures.get("schema_version") != 1:
                raise SweepError("unsupported fixtures schema")
            sys.stdout.write(digest(fixtures, inventory))
            return 0
        actual = collect(args, scenario, inventory)
        if args.check:
            expected = json.loads(args.fixtures.read_text())
            if not isinstance(expected, dict) or expected.get("schema_version") != 1:
                raise SweepError("unsupported fixtures schema")
            before, after = serialized(comparable(expected)), serialized(comparable(actual))
            if before != after:
                print("Docket CLI fixtures differ; review the upgrade before using --write.", file=sys.stderr)
                sys.stdout.writelines(difflib.unified_diff(
                    before.splitlines(True), after.splitlines(True),
                    fromfile=str(args.fixtures), tofile="installed CLI",
                ))
                return 1
            print(f"Docket CLI fixtures match ({len(actual['results'])} records over {len(actual['coverage']['exercised'])} commands).")
        elif args.write:
            args.fixtures.parent.mkdir(parents=True, exist_ok=True)
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.fixtures.parent, delete=False) as handle:
                    temporary = Path(handle.name)
                    handle.write(serialized(actual))
                temporary.replace(args.fixtures)
                temporary = None
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)
            print(f"Wrote {len(actual['results'])} records over {len(actual['coverage']['exercised'])} commands to {args.fixtures}.")
        else:
            sys.stdout.write(serialized(actual))
    except (SweepError, OSError, ValueError) as exc:
        print(f"Docket CLI sweep: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
