#!/usr/bin/env python3
"""Integration test for the evolve_preflight.sh -> drift_target.sh seam
(DKT-290/292 fix-loop round 1): evolve_preflight.sh's --drift output must be
immediately usable as drift_target.sh's decimal-only drift-seed argument with
no caller-side conversion. Guards the reproduced hex/decimal validation
mismatch and the leading-zero-decimal/bash-octal caveat named in the BLOCK
verdict.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_preflight_drift_seam.py``.
Drives both real CLIs via subprocess; scoped to a fixture target file so it
never touches real SKILL.md content.
"""
import hashlib
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
PREFLIGHT = HERE.parent / "evolve_preflight.sh"
DRIFT_TARGET = HERE.parent / "drift_target.sh"
REPO_ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout.strip())
FIXTURE = "src/user/claude-code/scripts/test/fixtures/preflight_drift_seam/target.md"


def run_preflight(*args):
    proc = subprocess.run(["bash", str(PREFLIGHT), *args], cwd=str(REPO_ROOT),
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def run_drift_target(*args):
    proc = subprocess.run(["bash", str(DRIFT_TARGET), *args], cwd=str(REPO_ROOT),
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def parse_kv(stdout):
    kv = {}
    for line in stdout.splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            kv[k] = v
    return kv


def test_preflight_drift_seed_is_decimal_not_hex():
    code, out, err = run_preflight("--cycle", "dkt290-292-seam-test", "--drift", "1")
    assert code == 0, f"exit {code}: {out}{err}"
    kv = parse_kv(out)
    assert "drift_seed" in kv, out
    assert re.fullmatch(r"[0-9]+", kv["drift_seed"]), f"drift_seed not decimal: {kv['drift_seed']!r}"


def test_preflight_drift_seed_matches_hex_digest_conversion():
    code, out, err = run_preflight("--cycle", "dkt290-292-seam-test", "--drift", "1")
    assert code == 0, f"exit {code}: {out}{err}"
    kv = parse_kv(out)
    today = kv["today_date"]
    expected_hex = hashlib.sha1(f"dkt290-292-seam-test-{today}".encode()).hexdigest()[:8]
    assert int(kv["drift_seed"]) == int(expected_hex, 16), (kv["drift_seed"], expected_hex)


def test_preflight_output_feeds_drift_target_end_to_end():
    code, out, err = run_preflight("--cycle", "dkt290-292-seam-test", "--drift", "1")
    assert code == 0, f"exit {code}: {out}{err}"
    kv = parse_kv(out)
    code, out, err = run_drift_target(FIXTURE, kv["drift_seed"], kv["drift_rate"])
    assert code == 0, f"exit {code}: {out}{err}"
    assert out.strip() != "", "expected a selected trait line, got empty stdout"


def test_reproduced_regression_seed_066c255f_now_succeeds():
    # advisor's reproduced BLOCKER: evolve-agents/2026-07-13's hex digest 066c255f
    # (decimal 107750751) previously failed drift_target.sh's decimal-only regex.
    decimal_seed = str(int("066c255f", 16))
    code, out, err = run_drift_target(FIXTURE, decimal_seed, "1")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out.strip() != "", out


def test_leading_zero_decimal_seed_is_not_reinterpreted_as_octal():
    # Guards the caveat: a leading-zero all-digit seed fed into bash $(( )) is
    # interpreted as OCTAL unless explicitly parsed with base 10 (10#$var).
    # "010" as octal = 8, as decimal = 10 -- against this 12-candidate fixture
    # the two interpretations select different traits, so a regression here
    # changes the pick.
    code_dec, out_dec, err_dec = run_drift_target(FIXTURE, "10", "1")
    assert code_dec == 0, f"exit {code_dec}: {out_dec}{err_dec}"
    code_lz, out_lz, err_lz = run_drift_target(FIXTURE, "010", "1")
    assert code_lz == 0, f"exit {code_lz}: {out_lz}{err_lz}"
    assert out_lz == out_dec, (
        f"leading-zero seed '010' picked a different trait than decimal '10' -- "
        f"octal reinterpretation regression: {out_lz!r} != {out_dec!r}"
    )


def test_hex_seed_still_rejected_with_clear_error():
    # drift_target.sh's own arg is decimal-only by contract; a raw hex digest
    # passed directly (bypassing the preflight conversion) must still fail
    # loudly rather than silently misbehaving.
    code, out, err = run_drift_target(FIXTURE, "066c255f", "1")
    assert code == 1, f"expected exit 1, got {code}: {out}{err}"
    assert "must be a non-negative decimal integer" in err, err


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
