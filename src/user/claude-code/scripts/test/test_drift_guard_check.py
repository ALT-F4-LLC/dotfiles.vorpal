#!/usr/bin/env python3
"""Fixture-driven checks for drift_guard_check.py -- the "skip `--help`"
inlined-block-vs-script-Usage drift guard (DKT-118).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_drift_guard_check.py``.
Exit 0 = all asserts pass. Synthetic doc/script fixtures are written to a
temp dir per test (never the real repo tree) so a deliberately-broken
fixture can never be mistaken for real drift; the one exception is the
real-repo integration test, which drives the actual CLI against the live
team-lead.md + scripts/ tree to satisfy DKT-118's "verify it currently
passes" acceptance criterion.
"""
import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "drift_guard_check.py"
REPO_ROOT = HERE.parents[4]

spec = importlib.util.spec_from_file_location("drift_guard_check", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def run_cli(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def make_fixture(doc_text, scripts):
    """Write `doc_text` and a {basename: content} map of scripts into a
    fresh temp dir; returns (doc_path, scripts_dir)."""
    tmp = Path(tempfile.mkdtemp(prefix="drift_guard_test_"))
    doc_path = tmp / "team-lead.md"
    doc_path.write_text(doc_text)
    scripts_dir = tmp / "scripts"
    scripts_dir.mkdir()
    for basename, content in scripts.items():
        (scripts_dir / basename).write_text(content)
    return doc_path, scripts_dir


POSITIONAL_SCRIPT = (
    "#!/bin/bash\n"
    "# Usage: widget.sh <key> <count>\n"
)

FLAG_SCRIPT = (
    "#!/bin/bash\n"
    "usage() {\n"
    '    echo "Usage: widget.sh append --cycle=<slug> --pattern=<pattern> \\\\" >&2\n'
    '    echo "         --votes=<votes>" >&2\n'
    "    exit 1\n"
    "}\n"
)


def test_extract_script_usage_comment_style():
    tmp = Path(tempfile.mkdtemp(prefix="drift_guard_test_"))
    script_path = tmp / "widget.sh"
    script_path.write_text(POSITIONAL_SCRIPT)
    assert mod.extract_script_usage(script_path) == "widget.sh <key> <count>"


def test_extract_script_usage_echo_style_with_continuation():
    tmp = Path(tempfile.mkdtemp(prefix="drift_guard_test_"))
    script_path = tmp / "widget.sh"
    script_path.write_text(FLAG_SCRIPT)
    usage = mod.extract_script_usage(script_path)
    assert usage == "widget.sh append --cycle=<slug> --pattern=<pattern> --votes=<votes>", usage


def test_find_inlined_blocks_extracts_content_after_marker():
    doc_text = (
        "some prose (skip `--help` -- this is the complete, current syntax):\n"
        "```\n"
        "~/.claude/scripts/widget.sh <key> <count>\n"
        "```\n"
        "more prose, no marker here\n"
        "```\n"
        "not-a-drift-guard-block\n"
        "```\n"
    )
    blocks = mod.find_inlined_blocks(doc_text)
    assert len(blocks) == 1, blocks
    assert blocks[0][1] == "~/.claude/scripts/widget.sh <key> <count>", blocks[0]


def test_compare_usage_positional_match():
    ok, detail = mod.compare_usage("widget.sh <key> <count>", "~/.claude/scripts/widget.sh <key> <count>", "widget.sh")
    assert ok is True, detail


def test_compare_usage_positional_drift_on_arg_change():
    ok, detail = mod.compare_usage("widget.sh <key> <count> <extra>", "~/.claude/scripts/widget.sh <key> <count>", "widget.sh")
    assert ok is False, detail


def test_compare_usage_flags_tolerates_elaborated_placeholders():
    script_usage = "widget.sh append --cycle=<slug> --pattern=<pattern> --votes=<votes>"
    block = "~/.claude/scripts/widget.sh append --cycle=<goal-slug> --pattern=<A|B|C>[hint] --votes=<crit>:<n>[,...]"
    ok, detail = mod.compare_usage(script_usage, block, "widget.sh")
    assert ok is True, detail


def test_compare_usage_flags_drift_on_renamed_flag():
    script_usage = "widget.sh append --cycle=<slug> --pattern=<pattern> --votes=<votes> --extra=<x>"
    block = "~/.claude/scripts/widget.sh append --cycle=<slug> --pattern=<pattern> --votes=<votes>"
    ok, detail = mod.compare_usage(script_usage, block, "widget.sh")
    assert ok is False, detail


def test_compare_usage_flags_drift_on_reordered_flag():
    script_usage = "widget.sh append --votes=<votes> --cycle=<slug>"
    block = "~/.claude/scripts/widget.sh append --cycle=<slug> --votes=<votes>"
    ok, detail = mod.compare_usage(script_usage, block, "widget.sh")
    assert ok is False, detail


def test_compare_usage_flags_drift_on_hyphenated_flag_variant():
    """`--dry-run` vs `--dry-clean` must not both normalize to `--dry`."""
    script_usage = "widget.sh --dry-run"
    block = "~/.claude/scripts/widget.sh --dry-clean"
    ok, detail = mod.compare_usage(script_usage, block, "widget.sh")
    assert ok is False, detail
    assert "--dry-run" in detail and "--dry-clean" in detail, detail


def test_cli_passes_on_in_sync_fixture():
    doc_text = (
        "Run it (skip `--help` -- this is the complete, current syntax):\n"
        "```\n"
        "~/.claude/scripts/widget.sh <key> <count>\n"
        "```\n"
    )
    doc_path, scripts_dir = make_fixture(doc_text, {"widget.sh": POSITIONAL_SCRIPT})
    code, out, err = run_cli("--doc", str(doc_path), "--scripts-dir", str(scripts_dir))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "drift-guard: OK" in out, out


def test_cli_fails_on_drifted_fixture():
    doc_text = (
        "Run it (skip `--help` -- this is the complete, current syntax):\n"
        "```\n"
        "~/.claude/scripts/widget.sh <key>\n"
        "```\n"
    )
    doc_path, scripts_dir = make_fixture(doc_text, {"widget.sh": POSITIONAL_SCRIPT})
    code, out, err = run_cli("--doc", str(doc_path), "--scripts-dir", str(scripts_dir))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "drift-guard: FAIL" in out, out
    assert "DRIFT" in out, out


def test_cli_unresolved_on_ambiguous_script_match():
    """A block whose content substring-matches two known basenames must be
    reported UNRESOLVED, not silently resolved to matched[0]."""
    doc_text = (
        "Run it (skip `--help` -- this is the complete, current syntax):\n"
        "```\n"
        "~/.claude/scripts/model_census.sh <key> <count>\n"
        "```\n"
    )
    doc_path, scripts_dir = make_fixture(
        doc_text,
        {"census.sh": POSITIONAL_SCRIPT, "model_census.sh": POSITIONAL_SCRIPT},
    )
    code, out, err = run_cli("--doc", str(doc_path), "--scripts-dir", str(scripts_dir))
    assert code == 1, f"exit {code}: {out}{err}"
    assert "UNRESOLVED  ambiguous script match" in out, out


def test_cli_no_marker_exits_zero():
    doc_path, scripts_dir = make_fixture("nothing to see here\n", {"widget.sh": POSITIONAL_SCRIPT})
    code, out, err = run_cli("--doc", str(doc_path), "--scripts-dir", str(scripts_dir))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "drift-guard: none found" in out, out


def test_cli_missing_doc_exits_two():
    _, scripts_dir = make_fixture("x", {"widget.sh": POSITIONAL_SCRIPT})
    code, out, err = run_cli("--doc", "/nonexistent/team-lead.md", "--scripts-dir", str(scripts_dir))
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def test_real_repo_team_lead_blocks_currently_pass():
    """Integration check against the live tree -- DKT-118's own acceptance
    criterion: the 3 blocks DKT-112 landed must currently be in sync."""
    doc_path = REPO_ROOT / "src/user/claude-code/agents/team-lead.md"
    scripts_dir = REPO_ROOT / "src/user/claude-code/scripts"
    assert doc_path.is_file(), doc_path
    assert scripts_dir.is_dir(), scripts_dir
    code, out, err = run_cli("--doc", str(doc_path), "--scripts-dir", str(scripts_dir))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "drift-guard: OK (3 inlined block(s)" in out, out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
