"""Render one lane script per workflow definition.

Usage: python3 lane_scripts.py [--root DIR] [--out DIR] [--check] [--list]

Every workflow definition under <root>/src/user/docket/config/workflows gets
its own Workflow script, <out>/<pipeline name>.js, which the docket-run
conductor launches for the issue lanes the run bound to that workflow. A
script is a rendered header followed by lane_body.js (beside this file)
verbatim:

  export const meta = {...}   name = the pipeline name, which is what the
                              run's roster (lane_roster.sh, or an
                              activation's bound_issues[].workflow) binds
                              each issue to, so it names the script to
                              launch for that issue
  // RENDERED FILE ...        the marker this script and the test key on
  const LANE = {workflow}     the pipeline name, read by the body's lane
                              fence (assertLane); nothing else, so a TOML
                              edit that keeps the name changes no script
  <lane_body.js>              the wave machinery, identical in every script

A Workflow script cannot import a file and nests at most one level, so the
shared machinery cannot live in one place at run time; it lives in one place
at render time instead. Edit lane_body.js, or add, remove or rename a
workflow, run `just lanes`, and commit the rendered scripts. A rendered
script is never edited by hand. The TOML's version and steps are read only
to validate the definition: a paused run keeps the workflow version it
pinned while the installed script moves on, so the script carries nothing
that would make one version's rows wrong under it.

Defaults: <root> is this checkout (six directories above this file), <out>
is <root>/src/user/claude_code/workflows. --out renders elsewhere, for a
test. --check renders in memory and compares: a script whose bytes differ
(drift), a workflow with no script (missing), and a rendered script whose
name matches no workflow (stray) are each listed on stderr, and the exit is
1 when any is found; nothing is written. --list prints the pipeline name
and script path per workflow, one per line, and writes nothing.

A file under <out> that is not a rendered script (no marker in its first
lines) is never overwritten: a pipeline whose name collides with another
workflow script is an error, not a clobber. The Workflow tool refuses a
script over 524,288 bytes, so a rendered script past that is an error too.

This file exists because an inline heredoc (`python3 - <<'PY'`) is an
interpreter code argument the auto-mode deny rule refuses before it runs.
"""

import os
import sys
import tomllib

MARKER = "// RENDERED FILE: lane_scripts.py wrote it from"
SCRIPT_SIZE_CAP = 524_288
BODY = "lane_body.js"
TOML_DIR = os.path.join("src", "user", "docket", "config", "workflows")
OUT_DIR = os.path.join("src", "user", "claude_code", "workflows")
BODY_REL = os.path.join("src", "user", "claude_code", "skills", "docket-run", "scripts", BODY)

# The cost sentences tests/docket-workflow-vote-retry-report.test.sh reads
# off meta.description, verbatim across every rendered script.
COST_TEXT = (
    "Per executor row it spends 1 haiku claim agent, which claims the step and writes "
    "the packet the executor then receives verbatim in its brief. Per vote row it spends "
    "3 read-only haiku probes on the normal path (gate status before, the proposal body, "
    "gate status after), 1 on a gate that was already decided, and 4 when a re-seat is "
    "needed. Budget, launch, lane, argument and return contract in the header comment; "
    "the reply-tail contract is THE REPLY-TAIL CONTRACT comment beside the park signals."
)


def js_str(value):
    """A single-quoted JS string literal."""
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n") + "'"


def default_root():
    here = os.path.dirname(os.path.abspath(__file__))
    root = here
    for _ in range(6):
        root = os.path.dirname(root)
    return root


def load_definition(path):
    with open(path, "rb") as handle:
        doc = tomllib.load(handle)
    pipeline = doc.get("pipeline")
    if not isinstance(pipeline, dict) or not isinstance(pipeline.get("name"), str):
        raise SystemExit(f"lane_scripts: {path} declares no [pipeline].name")
    name = pipeline["name"]
    if not name or any(ch not in "abcdefghijklmnopqrstuvwxyz0123456789-" for ch in name):
        raise SystemExit(f"lane_scripts: {path} pipeline name {name!r} is not a plain lowercase "
                         "slug, so it cannot name a script")
    version = pipeline.get("version")
    if not isinstance(version, int) or isinstance(version, bool):
        raise SystemExit(f"lane_scripts: {path} declares no integer [pipeline].version")
    steps = doc.get("step")
    if not isinstance(steps, list) or not steps:
        raise SystemExit(f"lane_scripts: {path} declares no [[step]] tables")
    for step in steps:
        if not isinstance(step, dict) or not isinstance(step.get("name"), str) or not step["name"]:
            raise SystemExit(f"lane_scripts: {path} has a [[step]] with no name")
    return {"name": name}


def render(definition, toml_rel, body):
    name = definition["name"]
    # crossref-check caps meta.description at 1000 characters.
    description = (
        f"Internal: the {name} lane. Launched through scriptPath by docket-run, once per issue "
        f"the run bound to {name}, to run that issue's lane of a dispatched manifest end to end "
        f"(executors, vote panels, staged rows). " + COST_TEXT
    )
    when = (
        f"Never by name. Launch it for the issue lane whose launches.json entry names {name}.js, "
        "passing lane_units.py's generated args-<i>.json unedited; the argument contract is in "
        "the header comment."
    )
    header = (
        "export const meta = {\n"
        f"    name: {js_str(name)},\n"
        f"    description: {js_str(description)},\n"
        f"    whenToUse: {js_str(when)},\n"
        "}\n"
        "\n"
        f"{MARKER}\n"
        f"// {toml_rel} and {BODY_REL}.\n"
        "// Edit the body and run `just lanes`; tests/docket-run-lane-scripts.test.sh fails on a\n"
        "// hand edit here. The header ends at LANE; the body follows verbatim.\n"
        f"const LANE = {{ workflow: {js_str(name)} }}\n"
        "\n"
    )
    return header + body


def is_rendered(path):
    try:
        with open(path, encoding="utf-8") as handle:
            head = handle.read(4096)
    except OSError:
        return False
    return MARKER in head


def parse_args(argv):
    root, out, check, listing = None, None, False, False
    rest = list(argv[1:])
    while rest:
        arg = rest.pop(0)
        if arg in ("--root", "--out"):
            if not rest:
                raise SystemExit("usage: lane_scripts.py [--root DIR] [--out DIR] [--check] [--list]")
            value = rest.pop(0)
            if arg == "--root":
                root = value
            else:
                out = value
        elif arg == "--check":
            check = True
        elif arg == "--list":
            listing = True
        else:
            raise SystemExit("usage: lane_scripts.py [--root DIR] [--out DIR] [--check] [--list]")
    root = os.path.abspath(root or default_root())
    out = os.path.abspath(out or os.path.join(root, OUT_DIR))
    return root, out, check, listing


def main(argv):
    root, out, check, listing = parse_args(argv)
    toml_dir = os.path.join(root, TOML_DIR)
    if not os.path.isdir(toml_dir):
        raise SystemExit(f"lane_scripts: no workflow definitions at {toml_dir}")
    body_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), BODY)
    try:
        with open(body_path, encoding="utf-8") as handle:
            body = handle.read()
    except OSError as err:
        raise SystemExit(f"lane_scripts: cannot read {body_path} ({err})")
    if not body.endswith("\n"):
        body += "\n"

    definitions = []
    for entry in sorted(os.listdir(toml_dir)):
        if entry.endswith(".toml"):
            definitions.append((entry, load_definition(os.path.join(toml_dir, entry))))
    if not definitions:
        raise SystemExit(f"lane_scripts: no *.toml under {toml_dir}")
    names = {}
    for entry, definition in definitions:
        if definition["name"] in names:
            raise SystemExit(f"lane_scripts: {entry} and {names[definition['name']]} both declare "
                             f"pipeline {definition['name']!r}")
        names[definition["name"]] = entry

    if listing:
        for entry, definition in definitions:
            print(f"{definition['name']} {os.path.join(out, definition['name'] + '.js')}")
        return 0

    rendered = {}
    for entry, definition in definitions:
        toml_rel = os.path.join(TOML_DIR, entry)
        text = render(definition, toml_rel, body)
        if len(text.encode("utf-8")) > SCRIPT_SIZE_CAP:
            raise SystemExit(f"lane_scripts: {definition['name']}.js would be "
                             f"{len(text.encode('utf-8'))} bytes, over the Workflow tool's "
                             f"{SCRIPT_SIZE_CAP}-byte cap")
        rendered[definition["name"]] = text

    problems = []
    for name, text in rendered.items():
        path = os.path.join(out, name + ".js")
        if os.path.exists(path) and not is_rendered(path):
            problems.append(f"collision: {path} exists and is not a rendered lane script; "
                            f"pipeline {name!r} cannot take its name")
    if os.path.isdir(out):
        for entry in sorted(os.listdir(out)):
            if entry.endswith(".js") and entry[:-3] not in rendered and is_rendered(os.path.join(out, entry)):
                problems.append(f"stray: {os.path.join(out, entry)} is a rendered lane script "
                                f"with no workflow definition; delete it")
    if problems:
        for line in problems:
            print(f"lane_scripts: {line}", file=sys.stderr)
        return 1

    if check:
        for name, text in rendered.items():
            path = os.path.join(out, name + ".js")
            if not os.path.exists(path):
                problems.append(f"missing: {path}")
                continue
            with open(path, encoding="utf-8") as handle:
                if handle.read() != text:
                    problems.append(f"drift: {path} differs from its rendering")
        for line in problems:
            print(f"lane_scripts: {line}", file=sys.stderr)
        if problems:
            print(f"lane_scripts: {len(problems)} problem(s); run `just lanes` and commit the result",
                  file=sys.stderr)
            return 1
        print(f"lane_scripts: {len(rendered)} lane script(s) match their rendering", file=sys.stderr)
        return 0

    os.makedirs(out, exist_ok=True)
    written = 0
    for name, text in rendered.items():
        path = os.path.join(out, name + ".js")
        if os.path.exists(path):
            with open(path, encoding="utf-8") as handle:
                if handle.read() == text:
                    continue
        partial = path + ".partial"
        with open(partial, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.replace(partial, path)
        written += 1
        print(f"lane_scripts: wrote {path}", file=sys.stderr)
    print(f"lane_scripts: {len(rendered)} lane script(s), {written} written", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
