#!/usr/bin/env python3
"""Fixture-driven checks for findings_ledger_init.py — generates the initial
Findings Ledger skeleton from the six Phase 0 auditor output files and
verifies its output is well-formed per findings_ledger_check.py's grammar.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_findings_ledger_init.py``.
Exit 0 = all asserts pass. Drives both CLIs via subprocess against a temp dir.
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
INIT_SCRIPT = HERE.parent / "findings_ledger_init.py"
CHECK_SCRIPT = HERE.parent / "findings_ledger_check.py"


def run_init(phase0_files, output_name="findings-ledger.md"):
    """Caller owns cleanup of the returned tmp dir (output_path.parent)."""
    tmp = tempfile.mkdtemp()
    phase0_dir = Path(tmp) / "phase0"
    phase0_dir.mkdir()
    for filename, content in phase0_files.items():
        (phase0_dir / filename).write_text(content)
    output_path = Path(tmp) / output_name
    proc = subprocess.run(
        [sys.executable, str(INIT_SCRIPT), str(phase0_dir), str(output_path)],
        capture_output=True, text=True,
    )
    ledger_text = output_path.read_text() if output_path.exists() else None
    return proc.returncode, proc.stdout, proc.stderr, ledger_text, output_path


def run_check(output_path):
    proc = subprocess.run(
        [sys.executable, str(CHECK_SCRIPT), str(output_path)], capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


def test_historical_focus_areas_become_entries():
    text = (
        "### Skill: docket\n"
        "- Invocations (window): 3 (transcripts) + 1 (history.jsonl)\n"
        "- Suggested focus areas: tighten the vote subcommand example\n"
        "### Skill: commit\n"
        "- Suggested focus areas: none\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "- H1: [docket] tighten the vote subcommand example", ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_bug_and_repetition_markers_become_entries_benign_race_dropped():
    bug_text = (
        "FIX 1: docket vote create silently drops --threshold\n"
        "CLASS: BAD-PARAM\n"
        "SESSIONS: 2 sessions (a1b2, c3d4)\n"
        "SUGGESTION: document the flag's default explicitly\n"
    )
    rep_text = (
        "PREVENT 1: same grep pipeline re-typed across three skills / "
        "SESSIONS: 3 / SUGGESTION: extract a shared script\n"
        "BENIGN-RACE 2: crossed-in-flight ack, correctly dismissed / "
        "SESSIONS: 1 / SUGGESTION: None — correct behavior\n"
    )
    code, out, err, ledger, output_path = run_init({
        "bug-auditor.md": bug_text,
        "repetition-auditor.md": rep_text,
    })
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        lines = ledger.strip().splitlines()
        assert len(lines) == 2, ledger
        assert lines[0].startswith("- B1: [FIX] docket vote create silently drops --threshold"), lines[0]
        assert "CLASS=BAD-PARAM" in lines[0], lines[0]
        assert lines[1].startswith("- R1: [PREVENT] same grep pipeline re-typed across three skills"), lines[1]
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_innovation_lenses_skip_none():
    text = (
        "### Skill: evolve-skills\n"
        "- Rethink: none\n"
        "- Refactor & Automate: findings_ledger_init.py — Change: auto-generate the skeleton — Impact: removes hand-authoring\n"
        "- Retire: none\n"
        "- Cross-Skill Leverage: none\n"
    )
    code, out, err, ledger, output_path = run_init({"innovation-scanner.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().startswith("- I1: [evolve-skills/Refactor & Automate]"), ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_model_routing_recommendations_become_entries():
    text = (
        "### Skill: evolve-agents\n"
        "- Routing recommendations: none — no improvement opportunity grounded in data\n"
        "### Skill: evolve-skills\n"
        "- Routing recommendations: downgrade disambiguation-reviewer fable to opus\n"
    )
    code, out, err, ledger, output_path = run_init({"model-routing-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "- M1: [evolve-skills] downgrade disambiguation-reviewer fable to opus", ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_docs_research_recommendations_only():
    text = (
        "## New Capabilities\n"
        "- **Agent Teams v2**: adopt the new lifecycle hook\n"
        "## Recommendations\n"
        "- **Cache-first fetching**: adopt the 24h mtime-gate pattern for docs pages\n"
    )
    code, out, err, ledger, output_path = run_init({"docs-researcher-phase0.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "- D1: Cache-first fetching: adopt the 24h mtime-gate pattern for docs pages", ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_sentinel_and_missing_files_contribute_nothing():
    code, out, err, ledger, output_path = run_init({
        "historical-auditor.md": "SKIPPED: no transcripts in window",
        "bug-auditor.md": "No bug findings.",
        # repetition-auditor.md, innovation-scanner.md, model-routing-auditor.md,
        # docs-researcher-phase0.md intentionally absent (missing file)
    })
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "", repr(ledger)
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_zero_findings_skeleton_passes_checker():
    code, out, err, ledger, output_path = run_init({
        "historical-auditor.md": "SKIPPED: no transcripts in window",
        "bug-auditor.md": "No bug findings.",
        # repetition-auditor.md, innovation-scanner.md, model-routing-auditor.md,
        # docs-researcher-phase0.md intentionally absent (missing file)
    })
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        check_code, check_out, check_err = run_check(output_path)
        assert check_code == 0, f"exit {check_code}: {check_out}{check_err}"
        assert "0/0 dispositioned" in check_out, check_out
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_generated_skeleton_is_parseable_by_checker_and_reports_open():
    """The AC's compatibility requirement: findings_ledger_check.py (unmodified)
    must parse every emitted entry (never exit 2). Entries carry no
    disposition yet (added during Phase 1), so the correct pre-Phase-1 exit
    is 1 with every entry reported OPEN — never exit 2 (unparseable)."""
    text = (
        "### Skill: docket\n"
        "- Suggested focus areas: tighten the vote subcommand example\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        check_code, check_out, check_err = run_check(output_path)
        assert check_code == 1, f"expected OPEN (exit 1), got exit {check_code}: {check_out}{check_err}"
        assert "[FAIL] H1: OPEN" in check_out, check_out
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_missing_phase0_dir_fails_instead_of_silent_empty_ledger():
    tmp = tempfile.mkdtemp()
    phase0_dir = Path(tmp) / "does-not-exist"
    output_path = Path(tmp) / "findings-ledger.md"
    try:
        proc = subprocess.run(
            [sys.executable, str(INIT_SCRIPT), str(phase0_dir), str(output_path)],
            capture_output=True, text=True,
        )
        assert proc.returncode == 2, f"expected exit 2, got {proc.returncode}: {proc.stdout}"
        assert "does not exist" in proc.stderr, proc.stderr
        assert not output_path.exists(), "ledger should not be written on validation failure"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_phase0_dir_with_no_known_auditor_files_fails():
    tmp = tempfile.mkdtemp()
    phase0_dir = Path(tmp) / "phase0"
    phase0_dir.mkdir()
    (phase0_dir / "unrelated-file.md").write_text("not an auditor file")
    output_path = Path(tmp) / "findings-ledger.md"
    try:
        proc = subprocess.run(
            [sys.executable, str(INIT_SCRIPT), str(phase0_dir), str(output_path)],
            capture_output=True, text=True,
        )
        assert proc.returncode == 2, f"expected exit 2, got {proc.returncode}: {proc.stdout}"
        assert "no auditor files found" in proc.stderr, proc.stderr
        assert not output_path.exists(), "ledger should not be written on validation failure"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def test_ids_sequential_per_auditor_letter():
    text = (
        "### Skill: a\n"
        "- Suggested focus areas: first finding\n"
        "### Skill: b\n"
        "- Suggested focus areas: second finding\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        lines = ledger.strip().splitlines()
        assert lines[0].startswith("- H1:"), lines
        assert lines[1].startswith("- H2:"), lines
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
