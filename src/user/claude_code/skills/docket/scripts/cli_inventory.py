#!/usr/bin/env python3
"""Inventory Docket's public command surface using only --help and --version."""

import argparse
import datetime
import difflib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


DEFAULT_INVENTORY = Path(__file__).resolve().parent.parent / "references/cli-inventory.json"
COMMAND = re.compile(r"[a-z][a-z0-9-]*\Z")
FLAG = re.compile(r"\s*(?:-(?P<short>[^\s,]),\s+)?--(?P<name>[a-z][a-z0-9-]*)(?P<rest>.*)\Z")


class InventoryError(Exception):
    """A CLI probe or inventory document could not be interpreted safely."""


def probe(binary, args, timeout):
    # Never execute a discovered command without --help; do not use a shell.
    if args != ["--version"] and (not args or args[-1] != "--help"):
        raise InventoryError("only --help and --version probes are permitted")
    try:
        result = subprocess.run(
            [binary, *args], capture_output=True, text=True, check=False,
            timeout=timeout, env={**os.environ, "NO_COLOR": "1", "TERM": "dumb"},
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise InventoryError(f"probe {' '.join(args)} failed: {exc}") from exc
    if result.returncode:
        raise InventoryError(f"probe {' '.join(args)} exited {result.returncode}: {result.stderr.strip()}")
    if not result.stdout.strip():
        raise InventoryError(f"probe {' '.join(args)} returned empty output")
    return result.stdout


def parse_help(body, path):
    sections = {}
    section = None
    for line in body.splitlines():
        if line in {"Usage:", "Aliases:", "Available Commands:", "Flags:", "Global Flags:"}:
            section = line[:-1]
            if section in sections:
                raise InventoryError(f"duplicate {section} section: {' '.join(path)}")
            sections[section] = []
        elif not line.strip():
            section = None
        elif section is not None:
            sections[section].append(line)

    usage = [line.strip() for line in sections.get("Usage", [])]
    if not usage or not all(line == "docket" or line.startswith("docket ") for line in usage):
        raise InventoryError(f"missing or unrecognized Usage section: {' '.join(path)}")

    children = []
    for line in sections.get("Available Commands", []):
        parts = line.strip().split(None, 1)
        if len(parts) != 2 or not COMMAND.fullmatch(parts[0]):
            raise InventoryError(f"unrecognized command row: {line!r}")
        children.append(parts[0])
    if len(set(children)) != len(children):
        raise InventoryError(f"duplicate child command: {' '.join(path)}")

    def flags(name):
        parsed = []
        for line in sections.get(name, []):
            match = FLAG.fullmatch(line)
            if not match:
                raise InventoryError(f"unrecognized {name} row: {line!r}")
            rest = match.group("rest")
            # Cobra separates a flag's value type from its description by
            # at least two spaces. A bool has padding but no value type.
            value = ""
            if rest.startswith(" ") and not rest.startswith("  "):
                value = re.split(r"\s{2,}", rest[1:], maxsplit=1)[0]
            row = {"name": "--" + match.group("name")}
            if match.group("short"):
                row["short"] = "-" + match.group("short")
            if value:
                row["value"] = value
            default = re.search(r"\(default (.+)\)\s*$", rest)
            if default:
                row["default"] = default.group(1)
            parsed.append(row)
        if len({row["name"] for row in parsed}) != len(parsed):
            raise InventoryError(f"duplicate {name} flag: {' '.join(path)}")
        return sorted(parsed, key=lambda row: row["name"])

    aliases = []
    for line in sections.get("Aliases", []):
        aliases.extend(part.strip() for part in line.split(","))
    if any(not COMMAND.fullmatch(alias) for alias in aliases):
        raise InventoryError(f"unrecognized aliases: {aliases!r}")
    return {
        "command": " ".join(["docket", *path]),
        "usage": usage,
        "aliases": sorted(set(aliases)),
        "flags": flags("Flags"),
        "inherited_flags": flags("Global Flags"),
    }, children


def collect(binary, timeout):
    version = probe(binary, ["--version"], timeout).strip()
    pending = [()]
    rows = []
    while pending:
        path = pending.pop(0)
        if len(rows) >= 512 or len(path) > 8:
            raise InventoryError("command discovery exceeded its bounds")
        row, children = parse_help(probe(binary, [*path, "--help"], timeout), path)
        rows.append(row)
        pending.extend((*path, child) for child in children)
    return {
        "schema_version": 1,
        "verified_on": datetime.datetime.now(datetime.timezone.utc).date().isoformat(),
        "binary_version": version,
        "probe_contract": "Only --version and command-path --help; no store operations.",
        "commands": sorted(rows, key=lambda row: row["command"]),
    }


def serialized(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def comparable(value):
    # A new calendar day alone is not command drift; a different binary is.
    value = dict(value)
    value.pop("verified_on", None)
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", default="docket", help="Docket executable path (default: docket on PATH)")
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--timeout", type=float, default=10, help="seconds allowed per help/version probe")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="fail if the installed binary or command surface differs")
    mode.add_argument("--write", action="store_true", help="replace the inventory after all read-only probes succeed")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    try:
        actual = collect(args.binary, args.timeout)
        if args.check:
            expected = json.loads(args.inventory.read_text())
            if not isinstance(expected, dict) or expected.get("schema_version") != 1:
                raise InventoryError("unsupported inventory schema")
            before, after = serialized(comparable(expected)), serialized(comparable(actual))
            if before != after:
                print("Docket CLI inventory differs; review the upgrade before using --write.", file=sys.stderr)
                sys.stdout.writelines(difflib.unified_diff(
                    before.splitlines(True), after.splitlines(True),
                    fromfile=str(args.inventory), tofile="installed CLI",
                ))
                return 1
            print(f"Docket CLI inventory matches ({len(actual['commands'])} commands).")
        elif args.write:
            args.inventory.parent.mkdir(parents=True, exist_ok=True)
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=args.inventory.parent, delete=False) as handle:
                    temporary = Path(handle.name)
                    handle.write(serialized(actual))
                temporary.replace(args.inventory)
                temporary = None
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)
            print(f"Wrote {len(actual['commands'])} commands to {args.inventory}.")
        else:
            sys.stdout.write(serialized(actual))
    except (InventoryError, OSError, ValueError) as exc:
        print(f"Docket CLI inventory: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
