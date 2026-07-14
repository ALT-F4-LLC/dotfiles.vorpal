#!/usr/bin/env python3
"""Fixture-driven checks for symmetry_check.py — the drift-detection core.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_symmetry_check.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/symmetry/ so it never
touches the peer signals fixtures. Drives the real CLI via subprocess.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "symmetry_check.py"
FIXTURES = HERE / "fixtures" / "symmetry"
AGENTS_SYMMETRIC = FIXTURES / "agents_symmetric.md"
SKILLS_SYMMETRIC = FIXTURES / "skills_symmetric.md"
CONFIG_SYMMETRIC = FIXTURES / "config_symmetric.md"
SKILLS_DRIFTED = FIXTURES / "skills_drifted.md"
AGENTS_IMPACT_CLASS = FIXTURES / "agents_impact_class.md"
SKILLS_IMPACT_CLASS_SYMMETRIC = FIXTURES / "skills_impact_class_symmetric.md"
SKILLS_IMPACT_CLASS_DRIFTED = FIXTURES / "skills_impact_class_drifted.md"
AGENTS_TRIAL_PROTOCOL = FIXTURES / "agents_trial_protocol.md"
SKILLS_TRIAL_PROTOCOL_SYMMETRIC = FIXTURES / "skills_trial_protocol_symmetric.md"
CONFIG_TRIAL_PROTOCOL_SYMMETRIC = FIXTURES / "config_trial_protocol_symmetric.md"
CONFIG_TRIAL_PROTOCOL_DRIFTED = FIXTURES / "config_trial_protocol_drifted.md"
AGENTS_DISAMBIGUATION_CHARTER = FIXTURES / "agents_disambiguation_charter.md"
SKILLS_DISAMBIGUATION_CHARTER_SYMMETRIC = FIXTURES / "skills_disambiguation_charter_symmetric.md"
CONFIG_DISAMBIGUATION_CHARTER_SYMMETRIC = FIXTURES / "config_disambiguation_charter_symmetric.md"
SKILLS_DISAMBIGUATION_CHARTER_DRIFTED = FIXTURES / "skills_disambiguation_charter_drifted.md"
AGENTS_PHASE3_BOUNDARY = FIXTURES / "agents_phase3_boundary.md"
SKILLS_PHASE3_BOUNDARY_SYMMETRIC = FIXTURES / "skills_phase3_boundary_symmetric.md"
CONFIG_PHASE3_BOUNDARY_SYMMETRIC = FIXTURES / "config_phase3_boundary_symmetric.md"
SKILLS_PHASE3_BOUNDARY_DRIFTED = FIXTURES / "skills_phase3_boundary_drifted.md"
AGENTS_GENETIC_DRIFT = FIXTURES / "agents_genetic_drift.md"
SKILLS_GENETIC_DRIFT_SYMMETRIC = FIXTURES / "skills_genetic_drift_symmetric.md"
CONFIG_GENETIC_DRIFT_SYMMETRIC = FIXTURES / "config_genetic_drift_symmetric.md"
SKILLS_GENETIC_DRIFT_DRIFTED = FIXTURES / "skills_genetic_drift_drifted.md"
AGENTS_SECOND_FAILURE_RECOVERY = FIXTURES / "agents_second_failure_recovery.md"
SKILLS_SECOND_FAILURE_RECOVERY_SYMMETRIC = FIXTURES / "skills_second_failure_recovery_symmetric.md"
CONFIG_SECOND_FAILURE_RECOVERY_SYMMETRIC = FIXTURES / "config_second_failure_recovery_symmetric.md"
SKILLS_SECOND_FAILURE_RECOVERY_DRIFTED = FIXTURES / "skills_second_failure_recovery_drifted.md"
AGENTS_OPERATOR_PROMPTS = FIXTURES / "agents_operator_prompts.md"
SKILLS_OPERATOR_PROMPTS_SYMMETRIC = FIXTURES / "skills_operator_prompts_symmetric.md"
CONFIG_OPERATOR_PROMPTS_SYMMETRIC = FIXTURES / "config_operator_prompts_symmetric.md"
SKILLS_OPERATOR_PROMPTS_DRIFTED = FIXTURES / "skills_operator_prompts_drifted.md"
PHASE0_TEMPLATES_MIMIR_PRESENT = FIXTURES / "phase0_templates_mimir_present.md"
PHASE0_TEMPLATES_MIMIR_MISSING = FIXTURES / "phase0_templates_mimir_missing.md"


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args],
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_symmetric_pair_exits_zero():
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_SYMMETRIC),
                         "--config-file", str(CONFIG_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out


def test_drifted_fixture_exits_nonzero_with_diff():
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    # Only the innovation-scanner MISSION line drifts (improvements -> refinements);
    # impact-class stays symmetric, so `--check all` reports exactly one drift.
    assert "innovation-scanner: DRIFT" in out, out


def test_drifted_single_check_exits_nonzero():
    code, out, err = run("--check", "innovation-scanner", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(SKILLS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"


def test_impact_class_symmetric_pair_exits_zero():
    code, out, err = run("--check", "impact-class", "--agents-file", str(AGENTS_IMPACT_CLASS),
                         "--skills-file", str(SKILLS_IMPACT_CLASS_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out


def test_impact_class_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "impact-class", "--agents-file", str(AGENTS_IMPACT_CLASS),
                         "--skills-file", str(SKILLS_IMPACT_CLASS_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "impact-class: DRIFT" in out, out


def test_trial_protocol_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "trial-protocol", "--agents-file", str(AGENTS_TRIAL_PROTOCOL),
                         "--skills-file", str(SKILLS_TRIAL_PROTOCOL_SYMMETRIC),
                         "--config-file", str(CONFIG_TRIAL_PROTOCOL_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "trial-protocol: OK (symmetric)" in out, out


def test_trial_protocol_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "trial-protocol", "--agents-file", str(AGENTS_TRIAL_PROTOCOL),
                         "--skills-file", str(SKILLS_TRIAL_PROTOCOL_SYMMETRIC),
                         "--config-file", str(CONFIG_TRIAL_PROTOCOL_DRIFTED))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "trial-protocol: DRIFT" in out, out


def test_disambiguation_charter_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "disambiguation-charter", "--agents-file", str(AGENTS_DISAMBIGUATION_CHARTER),
                         "--skills-file", str(SKILLS_DISAMBIGUATION_CHARTER_SYMMETRIC),
                         "--config-file", str(CONFIG_DISAMBIGUATION_CHARTER_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "disambiguation-charter: OK (symmetric)" in out, out


def test_disambiguation_charter_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "disambiguation-charter", "--agents-file", str(AGENTS_DISAMBIGUATION_CHARTER),
                         "--skills-file", str(SKILLS_DISAMBIGUATION_CHARTER_DRIFTED),
                         "--config-file", str(CONFIG_DISAMBIGUATION_CHARTER_SYMMETRIC))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "disambiguation-charter: DRIFT" in out, out


def test_phase3_boundary_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "phase3-boundary", "--agents-file", str(AGENTS_PHASE3_BOUNDARY),
                         "--skills-file", str(SKILLS_PHASE3_BOUNDARY_SYMMETRIC),
                         "--config-file", str(CONFIG_PHASE3_BOUNDARY_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "phase3-boundary: OK (symmetric)" in out, out


def test_phase3_boundary_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "phase3-boundary", "--agents-file", str(AGENTS_PHASE3_BOUNDARY),
                         "--skills-file", str(SKILLS_PHASE3_BOUNDARY_DRIFTED),
                         "--config-file", str(CONFIG_PHASE3_BOUNDARY_SYMMETRIC))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "phase3-boundary: DRIFT" in out, out


def test_genetic_drift_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "genetic-drift", "--agents-file", str(AGENTS_GENETIC_DRIFT),
                         "--skills-file", str(SKILLS_GENETIC_DRIFT_SYMMETRIC),
                         "--config-file", str(CONFIG_GENETIC_DRIFT_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "genetic-drift: OK (symmetric)" in out, out


def test_genetic_drift_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "genetic-drift", "--agents-file", str(AGENTS_GENETIC_DRIFT),
                         "--skills-file", str(SKILLS_GENETIC_DRIFT_DRIFTED),
                         "--config-file", str(CONFIG_GENETIC_DRIFT_SYMMETRIC))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "genetic-drift: DRIFT" in out, out


def test_second_failure_recovery_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "second-failure-recovery", "--agents-file", str(AGENTS_SECOND_FAILURE_RECOVERY),
                         "--skills-file", str(SKILLS_SECOND_FAILURE_RECOVERY_SYMMETRIC),
                         "--config-file", str(CONFIG_SECOND_FAILURE_RECOVERY_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "second-failure-recovery: OK (symmetric)" in out, out


def test_second_failure_recovery_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "second-failure-recovery", "--agents-file", str(AGENTS_SECOND_FAILURE_RECOVERY),
                         "--skills-file", str(SKILLS_SECOND_FAILURE_RECOVERY_DRIFTED),
                         "--config-file", str(CONFIG_SECOND_FAILURE_RECOVERY_SYMMETRIC))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "second-failure-recovery: DRIFT" in out, out


def test_operator_prompts_symmetric_triplet_exits_zero():
    code, out, err = run("--check", "operator-prompts", "--agents-file", str(AGENTS_OPERATOR_PROMPTS),
                         "--skills-file", str(SKILLS_OPERATOR_PROMPTS_SYMMETRIC),
                         "--config-file", str(CONFIG_OPERATOR_PROMPTS_SYMMETRIC))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "DRIFT" not in out, out
    assert "operator-prompts: OK (symmetric)" in out, out


def test_operator_prompts_drifted_exits_nonzero_with_diff():
    code, out, err = run("--check", "operator-prompts", "--agents-file", str(AGENTS_OPERATOR_PROMPTS),
                         "--skills-file", str(SKILLS_OPERATOR_PROMPTS_DRIFTED),
                         "--config-file", str(CONFIG_OPERATOR_PROMPTS_SYMMETRIC))
    assert code != 0, f"expected non-zero exit, got {code}"
    diff_lines = [line for line in out.splitlines() if line.startswith(("+", "-"))]
    assert len(diff_lines) > 0, "expected a non-empty unified diff in stdout"
    assert "operator-prompts: DRIFT" in out, out


def test_mimir_note_present_exits_zero():
    code, out, err = run("--check", "mimir-note",
                         "--phase0-templates-file", str(PHASE0_TEMPLATES_MIMIR_PRESENT))
    assert code == 0, f"exit {code}: {out}{err}"
    assert "mimir-note: OK (present)" in out, out


def test_mimir_note_missing_section_exits_nonzero():
    code, out, err = run("--check", "mimir-note",
                         "--phase0-templates-file", str(PHASE0_TEMPLATES_MIMIR_MISSING))
    assert code != 0, f"expected non-zero exit, got {code}"
    assert "mimir-note: MISSING" in out, out
    assert "missing: 3c" in out, out


def test_missing_file_exits_two():
    missing = FIXTURES / "does-not-exist.md"
    code, out, err = run("--check", "all", "--agents-file", str(missing),
                         "--skills-file", str(SKILLS_SYMMETRIC))
    assert code == 2, f"expected exit 2 for missing --agents-file, got {code}"
    code, out, err = run("--check", "all", "--agents-file", str(AGENTS_SYMMETRIC),
                         "--skills-file", str(missing))
    assert code == 2, f"expected exit 2 for missing --skills-file, got {code}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
