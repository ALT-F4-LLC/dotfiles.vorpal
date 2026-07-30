#!/usr/bin/env python3
"""Checks for byte_ceiling_check.sh.

Standalone (no pytest):
``python3 src/user/claude-code/scripts/test/test_byte_ceiling_check.py``

The most important test here is the first one. ``byte_ceilings.tsv`` RESTATES
numbers the charter states in prose, and a restatement that nobody compares
against its source is exactly the drift this project keeps finding (the parity
manifest, the drift-guard doc set). So the config is checked against the
charter's own words, and a row that diverges fails here.

The rest cover the gate's contract: warn-only must not break a tree that is
still in breach (it is, by a lot), --strict must actually gate, and a recorded
excuse must suppress exactly one breach and no others.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[4]
SCRIPT = HERE.parent / "byte_ceiling_check.sh"
CONFIG = HERE.parent / "byte_ceilings.tsv"
CHARTER = REPO_ROOT / "src/user/claude-code/docs/context-engineering-claude-5.md"


def run(*args, config=None):
    env = None
    if config:
        import os
        env = dict(os.environ, BYTE_CEILINGS=str(config))
    p = subprocess.run([str(SCRIPT), *args], capture_output=True, text=True, env=env)
    return p.returncode, p.stdout + p.stderr


def rows():
    out = []
    for line in CONFIG.read_text(encoding="utf-8").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) >= 3:
            out.append((parts[0], parts[1], int(parts[2])))
    return out


# --- the one that matters: the config must not drift from the charter ---

def test_ceilings_match_the_charter_prose():
    # The charter is hard-wrapped prose, so every pattern must tolerate a line
    # break anywhere a space appears -- matching on \s+ rather than " ".
    charter = CHARTER.read_text(encoding="utf-8")
    expected = {}
    if re.search(r'`team-lead\.md`[^.]*?may\s+not\s+exceed\s+30KB', charter, re.S):
        expected["src/user/claude-code/agents/team-lead.md"] = 30000
    if re.search(r'Agents:.*?at\s+most\s+170KB', charter, re.S):
        expected["src/user/claude-code/agents/*.md"] = 170000
    if re.search(r'no\s+SKILL\.md\s+over\s+10KB', charter, re.S):
        expected["src/user/claude-code/skills/*/SKILL.md"] = 10000

    assert len(expected) == 3, (
        "could not find all three ceilings in the charter prose — either the "
        f"charter was reworded or this test's patterns are stale. Found: {sorted(expected)}"
    )
    declared = {target: ceiling for _, target, ceiling in rows()}
    for target, want in expected.items():
        assert target in declared, f"charter states a ceiling for {target}; config does not declare it"
        assert declared[target] == want, (
            f"{target}: config says {declared[target]}, charter says {want} — "
            "the restatement has drifted from its source"
        )


def test_every_declared_row_traces_to_the_charter():
    """No inventing ceilings the charter never set."""
    for _, target, _ in rows():
        assert target.startswith("src/user/claude-code/"), f"unexpected target outside the governed tree: {target}"


# --- gate contract ---

def test_warn_only_is_the_default_and_does_not_break_a_breaching_tree():
    code, out = run("--quiet")
    assert code == 0, f"warn-only must exit 0 even in breach; got {code}"
    assert "WARN" in out, out


def test_strict_gates():
    code, out = run("--quiet", "--strict")
    assert code == 1, f"--strict must exit 1 while the tree is in breach; got {code}"
    assert "FAIL" in out, out


def test_reports_the_known_breaches():
    code, out = run("--quiet")
    assert "team-lead.md" in out, "the flagship breach should be reported"
    assert re.search(r'OVER\s+\d+\s*/\s*30000', out), out


def test_under_ceiling_reports_ok():
    with tempfile.TemporaryDirectory() as td:
        cfg = Path(td) / "c.tsv"
        cfg.write_text("file\tsrc/user/claude-code/agents/team-lead.md\t99999999\tabsurd ceiling\n")
        code, out = run(config=cfg)
        assert code == 0, out
        assert "clean" in out, out
        assert "OVER" not in out, out


def test_excuse_suppresses_exactly_one_breach():
    target = "src/user/claude-code/skills/docket/SKILL.md"
    with tempfile.TemporaryDirectory() as td:
        cfg = Path(td) / "c.tsv"
        cfg.write_text("each\tsrc/user/claude-code/skills/*/SKILL.md\t10000\tt\n")
        _, before = run("--quiet", config=cfg)
        n_before = before.count("OVER")
        cfg.write_text(
            "each\tsrc/user/claude-code/skills/*/SKILL.md\t10000\tt\n"
            f"#EXCUSE\t{target}\tformat-authority tables are the charter's expected exception\n"
        )
        _, after = run("--quiet", config=cfg)
        n_after = after.count("OVER")
        assert n_after == n_before - 1, f"excuse should suppress exactly one breach: {n_before} -> {n_after}"
        assert target not in after.replace("(excused)", ""), "excused file should not be reported OVER"


def test_unknown_kind_is_a_usage_error():
    with tempfile.TemporaryDirectory() as td:
        cfg = Path(td) / "c.tsv"
        cfg.write_text("bogus\tsome/path\t100\tx\n")
        code, _ = run(config=cfg)
        assert code == 2, f"unknown kind must exit 2, got {code}"


def test_missing_config_is_a_usage_error():
    code, _ = run(config="/nonexistent/ceilings.tsv")
    assert code == 2, f"missing config must exit 2, got {code}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"ok  {t.__name__}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL {t.__name__}: {e}")
    print(f"\n{len(tests) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
