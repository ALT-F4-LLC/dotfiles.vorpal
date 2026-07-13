#!/usr/bin/env python3
"""Fixture-driven checks for report_lint.py — the report-emission validator.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_report_lint.py``.
Exit 0 = all asserts pass. Drives the real CLI via subprocess. Each passing
fixture under fixtures/report_lint/ is a minimal valid report; every mechanized
check has a dedicated red case (a targeted mutation of the passing fixture) that
must exit 1 naming that check. Mode-gating and infra (exit-2) paths are covered
too. Temp mutations go under $TMPDIR (honoured by the harness sandbox)."""
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "report_lint.py"
FIX = HERE / "fixtures" / "report_lint"


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args],
                          capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def base(name):
    return (FIX / name).read_text()


def red(skill, mutated, expect_check, *extra):
    """Write a mutated report to a temp file, run the linter, assert exit 1 and
    that `expect_check` appears in stderr."""
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
        fh.write(mutated)
        path = fh.name
    code, out, err = run("--skill", skill, *extra, path)
    Path(path).unlink()
    assert code == 1, f"{skill}/{expect_check}: expected exit 1, got {code}: {out}{err}"
    assert f"validation failed: {expect_check}" in err, \
        f"{skill}/{expect_check}: missing check in stderr:\n{err}"


# ---- passing fixtures (exit 0) ----

def test_passing_fixtures():
    cases = [
        ("code-review-verdict", "crv_general_pass.md", ()),
        ("code-review-verdict", "crv_security_pass.md", ()),
        ("code-review-verdict", "crv_round_n_pass.md", ("--mode", "round-n")),
        ("verify-ac", "verify_ac_pass.md", ()),
        ("design-review", "design_review_pass.md", ()),
        ("design-qa", "design_qa_pass.md", ()),
    ]
    for skill, fixture, extra in cases:
        code, out, err = run("--skill", skill, *extra, str(FIX / fixture))
        assert code == 0, f"{fixture}: expected exit 0, got {code}: {out}{err}"
        assert out.startswith(f"OK: {skill} report"), out


# ---- mode gating (P3-AC4) ----

def test_light_short_circuits_verify_ac_exit0():
    code, out, err = run("--skill", "verify-ac", "--mode", "light", str(FIX / "verify_ac_pass.md"))
    assert code == 0 and "light" in out, f"{code}: {out}{err}"


def test_light_rejected_for_non_verify_ac_exit2():
    code, out, err = run("--skill", "design-qa", "--mode", "light", str(FIX / "design_qa_pass.md"))
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def test_round_n_rejected_for_non_crv_exit2():
    code, out, err = run("--skill", "design-review", "--mode", "round-n", str(FIX / "design_review_pass.md"))
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def test_unknown_skill_exit2():
    code, out, err = run("--skill", "nope", str(FIX / "design_qa_pass.md"))
    assert code == 2, f"expected exit 2, got {code}"


def test_unreadable_file_exit2():
    code, out, err = run("--skill", "design-qa", str(FIX / "does_not_exist.md"))
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def test_crv_lgtm_shortform_exit0():
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
        fh.write("LGTM - trivial rename, no behavior change\n")
        path = fh.name
    code, out, err = run("--skill", "code-review-verdict", path)
    Path(path).unlink()
    assert code == 0, f"expected exit 0 for LGTM short-form, got {code}: {out}{err}"


# ---- red cases: one per mechanized check ----

def test_crv_heading():
    t = base("crv_general_pass.md").replace(
        "## Review (general — @staff-engineer)", "## Some Other Heading")
    red("code-review-verdict", t, "heading")


def test_crv_section_order():
    t = base("crv_general_pass.md").replace(
        "### Next Steps\nRoute the Blocker to @senior-engineer for the fix.\n", "")
    red("code-review-verdict", t, "section-order")


def test_crv_empty_bucket():
    t = base("crv_general_pass.md").replace("**Concerns** (0):\n- None", "**Concerns** (0):")
    red("code-review-verdict", t, "empty-bucket")


def test_crv_recommendation_allowlist():
    t = base("crv_general_pass.md").replace("Code review emitted (Block).",
                                            "Code review emitted (Yolo).")
    red("code-review-verdict", t, "recommendation")


def test_crv_trailing_confirmation():
    t = base("crv_general_pass.md").replace("\nCode review emitted (Block).\n", "\n")
    red("code-review-verdict", t, "trailing-confirmation")


def test_crv_placeholder():
    t = base("crv_general_pass.md").replace(
        "Confidence: high — covered by the new table test", "Confidence: {count}")
    red("code-review-verdict", t, "placeholder")


def test_crv_banned_phrase():
    t = base("crv_general_pass.md").replace(
        "must be returned before merge.", "should work after merge.")
    red("code-review-verdict", t, "banned-phrase")


def test_crv_hard_gate_consistency():
    t = base("crv_general_pass.md").replace(
        "**G1 (swallowed error):** uploader.go:42 — discarded retry error — return it",
        "**G1 (swallowed error):** None")
    red("code-review-verdict", t, "hard-gate-consistency")


def test_verify_ac_verdict_consistency():
    t = base("verify_ac_pass.md").replace(
        "**High** (0):\n- None",
        "**High** (1):\n- uploader.go:9 — data loss on retry — repro: ...")
    red("verify-ac", t, "verdict-consistency")


def test_design_review_blocker_dimension_tag():
    t = base("design_review_pass.md").replace(
        "[Error Handling] the spec has no failed-upload",
        "[Bogus] the spec has no failed-upload")
    red("design-review", t, "blocker-dimension-tag")


def test_design_review_blocker_fix_fragment():
    t = base("design_review_pass.md").replace(
        "[Error Handling] the spec has no failed-upload state — add a retry affordance with error copy",
        "[Error Handling] the spec has no failed-upload state")
    red("design-review", t, "blocker-fix-fragment")


def test_design_review_dimension_checklist():
    t = base("design_review_pass.md").replace("| Accessibility | concern |\n", "")
    red("design-review", t, "dimension-checklist")


def test_design_review_verdict_consistency():
    t = base("design_review_pass.md").replace(
        "Design review emitted (Block).", "Design review emitted (Approve).")
    red("design-review", t, "verdict-consistency")


def test_design_qa_spec_section():
    t = base("design_qa_pass.md").replace(
        "| 1 | Concern | Error States |", "| 1 | Concern |  |")
    red("design-qa", t, "spec-section")


def test_design_qa_evidence():
    t = base("design_qa_pass.md").replace(
        '| 1 | Concern | Error States | spec requires retry copy; implementation at Upload.tsx:88 shows a bare "failed" string |',
        "| 1 | Concern | Error States |  |")
    red("design-qa", t, "evidence")


def test_design_qa_verdict_consistency():
    t = base("design_qa_pass.md").replace(
        "**Pass with Issues**", "**Pass**").replace(
        "Design QA report emitted (Pass with Issues).", "Design QA report emitted (Pass).")
    red("design-qa", t, "verdict-consistency")


# ---- fix-round red cases (DKT-249 review findings) ----

def test_design_review_blocker_with_none_substring_not_dropped():
    # A real Blocker whose text contains the substring "None" must still be
    # counted — bucket_counts must not treat substring "None" as the marker.
    t = base("design_review_pass.md").replace(
        "**Blockers** (1):\n"
        "- [Error Handling] the spec has no failed-upload state — add a retry affordance with error copy",
        "**Blockers** (1):\n"
        "- [Error Handling] submit flow returns None on error — add explicit error handling"
    ).replace(
        "**Concerns** (1):\n"
        "- [Usability] the cancel control at the Layout section is not keyboard-reachable — add a focus order note",
        "**Concerns** (0):\n- None"
    ).replace("Design review emitted (Block).", "Design review emitted (Approve).")
    red("design-review", t, "verdict-consistency")


def test_verify_ac_block_requires_issues_found():
    t = base("verify_ac_pass.md").replace(
        "- [x] PASS — wrapper retries on transient error — ran `go test ./...`, saw PASS at uploader_test.go:10",
        "- [ ] FAIL — wrapper retries on transient error — ran `go test ./...`, saw failure at uploader_test.go:10"
    ).replace(
        "**APPROVE** — tests pass and both criteria met with cited evidence.",
        "**BLOCK** — the retry wrapper fails under transient errors."
    ).replace("Verification report emitted (APPROVE).", "Verification report emitted (BLOCK).")
    red("verify-ac", t, "verdict-consistency")


def test_design_review_block_requires_blocker():
    t = base("design_review_pass.md").replace(
        "**Blockers** (1):\n"
        "- [Error Handling] the spec has no failed-upload state — add a retry affordance with error copy",
        "**Blockers** (0):\n- None"
    )
    red("design-review", t, "verdict-consistency")


def test_design_review_dimension_checklist_invalid_status():
    t = base("design_review_pass.md").replace(
        "| Accessibility | concern |", "| Accessibility | maybe |")
    red("design-review", t, "dimension-checklist")


def test_crv_overrides_recognized_bucket():
    t = base("crv_general_pass.md").replace(
        "**Overrides Recognized** (0):\n- None\n\n", "")
    red("code-review-verdict", t, "empty-bucket")


def test_crv_hard_gate_enumeration():
    t = base("crv_general_pass.md").replace(
        "- **G3 (unparsed boundary input):** None\n", "")
    red("code-review-verdict", t, "hard-gate-enumeration")


def test_verify_ac_multi_marker_line_classified_by_first_token():
    # A criterion line carrying two markers ("OUT-OF-SCOPE ... the PASS path")
    # must be classified by the first-occurring marker (OUT-OF-SCOPE), not
    # dropped — otherwise ACCEPT WITH CAVEATS' OUT-OF-SCOPE bypass never fires.
    t = base("verify_ac_pass.md").replace(
        "- [x] PASS — wrapper retries on transient error — ran `go test ./...`, saw PASS at uploader_test.go:10",
        "- [ ] OUT-OF-SCOPE — this environment does not exercise the PASS path; deferred to integration suite"
    ).replace(
        "**APPROVE** — tests pass and both criteria met with cited evidence.",
        "**ACCEPT WITH CAVEATS** — one criterion deferred out of scope; no other issues found."
    ).replace("Verification report emitted (APPROVE).", "Verification report emitted (ACCEPT WITH CAVEATS).")
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
        fh.write(t)
        path = fh.name
    code, out, err = run("--skill", "verify-ac", path)
    Path(path).unlink()
    assert code == 0, \
        f"expected exit 0 (OUT-OF-SCOPE marker classified despite embedded PASS token), got {code}: {out}{err}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"ok   {t.__name__}")
        except AssertionError as exc:
            failed += 1
            print(f"FAIL {t.__name__}: {exc}")
    if failed:
        print(f"\n{failed}/{len(tests)} failed")
        raise SystemExit(1)
    print(f"\nall {len(tests)} passed")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
