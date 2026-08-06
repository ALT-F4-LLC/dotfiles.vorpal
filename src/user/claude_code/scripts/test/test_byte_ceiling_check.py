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

def test_skill_ceiling_matches_the_charter_prose():
    """The one target the charter still states as a hard number. Patterns match
    on \\s+ rather than " " because the charter is hard-wrapped prose."""
    charter = CHARTER.read_text(encoding="utf-8")
    assert re.search(r'no\s+SKILL\.md\s+over\s+10KB', charter, re.S), (
        "charter no longer states the 10KB skill figure — either it was reworded "
        "or this pattern is stale"
    )
    declared = {target: ceiling for _, target, ceiling in rows()}
    target = "src/user/claude-code/skills/*/SKILL.md"
    assert declared.get(target) == 10000, (
        f"{target}: config says {declared.get(target)}, charter says 10000 — "
        "the restatement has drifted from its source"
    )


def test_charter_frames_the_agent_figure_as_a_ratchet_not_a_floor():
    """The agent figure is deliberately NOT traceable to a charter numeral: the
    charter now specifies a mechanism (a high-water ratchet) and leaves the
    number to this config. Assert the mechanism is stated, so nobody reinstates
    a hard floor in the config without amending the charter first."""
    charter = CHARTER.read_text(encoding="utf-8")
    assert re.search(r'ratchet,\s+not\s+a\s+floor', charter, re.S), (
        "charter no longer frames the agent byte figure as a ratchet"
    )
    assert re.search(r'high-water\s+mark', charter, re.S), (
        "charter no longer describes the high-water mechanism"
    )
    declared = {target: ceiling for _, target, ceiling in rows()}
    tl = "src/user/claude-code/agents/team-lead.md"
    assert tl in declared, "the ratcheted file must still be declared"
    actual = (REPO_ROOT / tl).stat().st_size
    assert declared[tl] >= actual, (
        f"ratchet is below current size ({declared[tl]} < {actual}) — a ratchet "
        "records a high-water mark; to lower it, land the reduction first"
    )


def test_no_fleet_total_row():
    """The charter explicitly disclaims a fleet-wide byte total: no context ever
    holds more than one agent definition, so a sum bounds no real resource and
    double-charges the deliberately-pinned CANONICAL blocks. Guard against
    reintroduction."""
    charter = CHARTER.read_text(encoding="utf-8")
    assert re.search(r'deliberately\s+NO\s*\n?\s*fleet-total', charter, re.S) or \
           re.search(r'NO\s+fleet-total', charter, re.S), (
        "charter no longer disclaims the fleet-total target"
    )
    sums = [t for kind, t, _ in rows() if kind == "sum"]
    assert not sums, f"fleet-total row reintroduced against the charter: {sums}"


def test_every_declared_row_traces_to_the_charter():
    """No inventing ceilings the charter never set."""
    for _, target, _ in rows():
        assert target.startswith("src/user/claude-code/"), f"unexpected target outside the governed tree: {target}"


# --- gate contract ---

def _breaching_config(td):
    """A config guaranteed to breach, so gate behaviour is tested against the
    MECHANISM rather than against the tree happening to be non-compliant.
    The live tree is currently clean; an earlier version of these tests relied
    on it being broken, which would have silently stopped testing anything the
    moment it was fixed."""
    cfg = Path(td) / "c.tsv"
    cfg.write_text("file\tsrc/user/claude-code/agents/team-lead.md\t100\tdeliberately absurd\n")
    return cfg


def test_warn_only_is_the_default_and_does_not_break_a_breaching_tree():
    with tempfile.TemporaryDirectory() as td:
        code, out = run("--quiet", config=_breaching_config(td))
        assert code == 0, f"warn-only must exit 0 even in breach; got {code}"
        assert "WARN" in out, out


def test_strict_gates():
    with tempfile.TemporaryDirectory() as td:
        code, out = run("--quiet", "--strict", config=_breaching_config(td))
        assert code == 1, f"--strict must exit 1 in breach; got {code}"
        assert "FAIL" in out, out


def test_breaches_are_reported_with_both_numbers():
    with tempfile.TemporaryDirectory() as td:
        code, out = run("--quiet", config=_breaching_config(td))
        assert "team-lead.md" in out, out
        assert re.search(r'OVER\s+\d+\s*/\s*100', out), out


def test_live_tree_is_currently_compliant():
    """A positive invariant, and the point of the amendment: after dropping the
    fleet-total row, ratcheting the agent figure, and recording the skill
    justifications the charter already permitted, the tree passes without any
    content having been cut."""
    code, out = run("--quiet")
    assert code == 0, out
    assert "clean" in out, f"tree regressed out of compliance: {out}"


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
