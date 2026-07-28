#!/usr/bin/env python3
"""Fixture-driven checks for findings_ledger_init.py — generates the initial
Findings Ledger skeleton from the seven Phase 0 auditor output files and
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


def test_evolve_agents_shaped_agent_blocks_preserve_tag_attribution():
    """evolve-agents-cycle historical-auditor/model-routing-auditor templates
    emit `### Agent: <name>` blocks (per evolve-phase0-templates.md §3a/§6a),
    not `### Skill: <name>` -- H/M findings must still get their per-agent
    `[agent-name]` tag."""
    historical_text = (
        "### Agent: team-lead\n"
        "- Suggested focus areas: tighten the shutdown-rejection grammar\n"
    )
    routing_text = (
        "### Agent: sdet\n"
        "- Routing recommendations: downgrade flaky-confirm passes to haiku\n"
    )
    code, out, err, ledger, output_path = run_init({
        "historical-auditor.md": historical_text,
        "model-routing-auditor.md": routing_text,
    })
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        lines = ledger.strip().splitlines()
        assert lines[0] == "- H1: [team-lead] tighten the shutdown-rejection grammar", lines
        assert lines[1] == "- M1: [sdet] downgrade flaky-confirm passes to haiku", lines
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_evolve_agents_shaped_innovation_scanner_cross_agent_leverage_captured():
    """evolve-agents innovation-scanner emits `Cross-Agent Leverage` (not
    `Cross-Skill Leverage`) as its 4th lens, per evolve-phase0-templates.md
    §7's `{TARGET_NOUN_CAP} Leverage` substitution -- must not be silently
    dropped."""
    text = (
        "### Agent: distinguished-engineer\n"
        "- Rethink: none\n"
        "- Refactor & Automate: none\n"
        "- Retire: none\n"
        "- Cross-Agent Leverage: edit_baton.sh orphan-script wiring -- Impact: closes a coordination gap\n"
    )
    code, out, err, ledger, output_path = run_init({"innovation-scanner.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == (
            "- I1: [distinguished-engineer/Cross-Agent Leverage] "
            "edit_baton.sh orphan-script wiring -- Impact: closes a coordination gap"
        ), ledger
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


def test_nested_bullet_focus_areas_yield_one_entry_per_sub_bullet():
    """DKT-170: a bare `- Suggested focus areas:` label followed by indented
    sub-bullets must not silently drop those findings -- one ledger entry per
    sub-bullet, alongside the existing inline-value shape staying one entry."""
    text = (
        "### Skill: evolve-skills\n"
        "- Suggested focus areas:\n"
        "  - sub bullet one\n"
        "  - sub bullet two\n"
        "  - sub bullet three\n"
        "### Skill: adr\n"
        "- Suggested focus areas: inline value here\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().splitlines() == [
            "- H1: [evolve-skills] sub bullet one",
            "- H2: [evolve-skills] sub bullet two",
            "- H3: [evolve-skills] sub bullet three",
            "- H4: [adr] inline value here",
        ], ledger
        assert err == "", err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_nested_bullet_asterisk_marker_and_deep_indentation_accepted():
    text = (
        "### Skill: docket\n"
        "- Suggested focus areas:\n"
        "    * deeply indented asterisk bullet\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "- H1: [docket] deeply indented asterisk bullet", ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_bare_label_with_no_sub_bullets_trips_zero_yield_tripwire():
    """Falsifier direction: a bare label with no sub-bullets and no literal
    "none" is a template violation -- must warn loudly on stderr and continue
    (warn-and-proceed, not exit 2) rather than silently reporting success."""
    text = (
        "### Skill: docket\n"
        "- Suggested focus areas:\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "", repr(ledger)
        assert "field 'Suggested focus areas' present with no value" in err, err
        assert "### Skill: docket" in err, err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_nested_bullets_with_leading_blank_line_yield_all_entries():
    """DKT-170 fix-1 (advisor Phase-3 Concern 1, shape a): a blank line
    between the bare label and its indented sub-bullets must not defeat the
    nested-bullet scan -- must yield 2 entries, not 0 + tripwire."""
    text = (
        "### Skill: evolve-skills\n"
        "- Suggested focus areas:\n"
        "\n"
        "  - sub bullet one\n"
        "  - sub bullet two\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().splitlines() == [
            "- H1: [evolve-skills] sub bullet one",
            "- H2: [evolve-skills] sub bullet two",
        ], ledger
        assert err == "", err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_nested_bullets_with_interior_blank_line_yield_all_entries():
    """DKT-170 fix-1 (advisor Phase-3 Concern 1, shape b): a blank line
    between two indented sub-bullets must not silently truncate the scan --
    must yield 2 entries, not 1 with no warning (the exact silent-partial-
    data-loss shape DKT-170 exists to eliminate)."""
    text = (
        "### Skill: evolve-skills\n"
        "- Suggested focus areas:\n"
        "  - sub bullet one\n"
        "\n"
        "  - sub bullet two\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().splitlines() == [
            "- H1: [evolve-skills] sub bullet one",
            "- H2: [evolve-skills] sub bullet two",
        ], ledger
        assert err == "", err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_nested_bullets_trailing_blank_before_next_block_still_terminates():
    """Block-boundary regression: a trailing blank line between the last
    sub-bullet and the next `### Skill:` header must still terminate the
    sub-bullet scan for the current block -- no bleed into the next block."""
    text = (
        "### Skill: evolve-skills\n"
        "- Suggested focus areas:\n"
        "  - sub bullet one\n"
        "\n"
        "### Skill: adr\n"
        "- Suggested focus areas: inline value here\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().splitlines() == [
            "- H1: [evolve-skills] sub bullet one",
            "- H2: [adr] inline value here",
        ], ledger
        assert err == "", err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_bare_label_blank_then_next_header_no_over_consumption():
    """Advisor's 7-case truth table, case 4: a bare label followed only by a
    blank line and then the NEXT block's header (no sub-bullets at all) must
    trip the tripwire for the bare label AND leave the next block's own
    field intact -- the blank-line lookahead must not consume past the
    header."""
    text = (
        "### Skill: a\n"
        "- Suggested focus areas:\n"
        "\n"
        "### Skill: b\n"
        "- Suggested focus areas: value b\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "- H1: [b] value b", ledger
        assert "field 'Suggested focus areas' present with no value" in err, err
        assert "### Skill: a" in err, err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_bare_label_blank_then_sibling_field_no_over_consumption():
    """Advisor's 7-case truth table, case 5: a bare label followed by a
    blank line and then an unindented sibling field line (same block) must
    trip the tripwire for the bare label without swallowing the sibling
    field line as a sub-bullet."""
    text = (
        "### Skill: a\n"
        "- Suggested focus areas:\n"
        "\n"
        "- Other field: value\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "", repr(ledger)
        assert "field 'Suggested focus areas' present with no value" in err, err
        assert "### Skill: a" in err, err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_inline_none_yields_zero_entries_no_warning():
    """Advisor's 7-case truth table, case 7 (unchanged baseline): an inline
    `none` value must contribute zero entries and must NOT trip the
    zero-yield tripwire -- it's a valid, explicit "empty category" per the
    template, not a template violation."""
    text = (
        "### Skill: a\n"
        "- Suggested focus areas: none\n"
    )
    code, out, err, ledger, output_path = run_init({"historical-auditor.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip() == "", repr(ledger)
        assert err == "", err
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


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


def test_sdlc_summary_recommendations_only_sibling_sections_ignored():
    """Summary Recommendations (ranked) is §9's own rollup of the sibling
    Candidate(s)/Other-Functions sections — parsing those too would double-count."""
    text = (
        "## Higher-Level Candidate(s)\n"
        "CANDIDATE: principal-engineer | SUGGESTED TIER: gold | DISPOSITION: ADD\n"
        "1. numbered line outside the summary section\n"
        "## Lower-Level Candidate(s)\n"
        "2. another numbered line outside the summary section\n"
        "## Other SDLC Functions Evaluated\n"
        "3. a third numbered line outside the summary section\n"
        "## Summary Recommendations (ranked)\n"
        "1. ADD principal-engineer/gold - no seat owns multi-year direction - evidence: gap analysis\n"
        "2. CHANGE ux-designer/silver->bronze - template-shaped tasks - evidence: model-routing-auditor.md\n"
    )
    code, out, err, ledger, output_path = run_init({"sdlc-role-researcher.md": text})
    try:
        assert code == 0, f"exit {code}: {out}{err}"
        assert ledger.strip().splitlines() == [
            "- S1: ADD principal-engineer/gold - no seat owns multi-year direction - evidence: gap analysis",
            "- S2: CHANGE ux-designer/silver->bronze - template-shaped tasks - evidence: model-routing-auditor.md",
        ], ledger
    finally:
        shutil.rmtree(output_path.parent, ignore_errors=True)


def test_auditor_letter_with_no_parser_branch_exits_two_without_traceback():
    """AUDITOR_LETTERS and build_entries() are two places that must agree. A
    letter with no parse branch still counts toward main()'s found>0 guard, so
    without this it would silently drop that auditor's findings."""
    tmp = tempfile.mkdtemp()
    try:
        source = INIT_SCRIPT.read_text()
        mutated_source = source.replace(
            '"sdlc-role-researcher.md": "S",',
            '"sdlc-role-researcher.md": "S",\n    "eighth-auditor.md": "Z",',
        )
        assert mutated_source != source, "mutation anchor not found in findings_ledger_init.py"
        mutated = Path(tmp) / "findings_ledger_init_mutated.py"
        mutated.write_text(mutated_source)

        phase0_dir = Path(tmp) / "phase0"
        phase0_dir.mkdir()
        (phase0_dir / "eighth-auditor.md").write_text("1. ADD an eighth auditor's finding\n")
        output_path = Path(tmp) / "findings-ledger.md"

        proc = subprocess.run(
            [sys.executable, str(mutated), str(phase0_dir), str(output_path)],
            capture_output=True, text=True,
        )
        assert proc.returncode == 2, f"expected exit 2, got {proc.returncode}: {proc.stdout}{proc.stderr}"
        assert "Traceback" not in proc.stderr, proc.stderr
        assert "no parser branch for auditor letter 'Z'" in proc.stderr, proc.stderr
        assert not output_path.exists(), "ledger should not be written when a letter is unhandled"
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
