#!/usr/bin/env python3
"""Checks for doc_validate.py — the shared "Validation Before Save" checker for
the doc-authoring skills (adr, prd, tdd, ux-spec).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_doc_validate.py``.
Exit 0 = all asserts pass. Drives the real CLI via subprocess.

Each type has one minimal PASSING fixture under fixtures/doc_validate/. Every
mechanized check gets a dedicated RED case produced by a one-line documented
mutation of that passing fixture (written to a temp file) — behaviourally the
"one fixture per failing check" §9 contract, kept maintainable per the repo's
inline-input test convention (test_dor_check.py). A guard asserts each mutation
actually changed the text so a stale replace() cannot silently pass.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "doc_validate.py"
FIX = HERE / "fixtures" / "doc_validate"


def load(name):
    return (FIX / name).read_text()


def run_text(doc_type, text):
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as fh:
        fh.write(text)
        path = fh.name
    try:
        proc = subprocess.run([sys.executable, str(SCRIPT), "--type", doc_type, path],
                              capture_output=True, text=True)
        return proc.returncode, proc.stdout, proc.stderr
    finally:
        Path(path).unlink(missing_ok=True)


def mutate(text, old, new):
    assert old in text, f"mutation anchor not found: {old!r}"
    return text.replace(old, new, 1)


def assert_pass(doc_type, text):
    code, out, err = run_text(doc_type, text)
    assert code == 0, f"expected pass, got exit {code}: {err}"
    assert out.startswith("OK:"), out


def assert_fail(doc_type, text, check):
    code, out, err = run_text(doc_type, text)
    assert code == 1, f"expected validation failure, got exit {code}: {out}{err}"
    assert f"validation failed: {check}" in err, f"missing check '{check}' in: {err}"


# ---------------------------------------------------------------- passing docs
def test_adr_ok_passes():
    assert_pass("adr", load("adr_ok.md"))


def test_prd_ok_passes():
    assert_pass("prd", load("prd_ok.md"))


def test_tdd_ok_passes():
    assert_pass("tdd", load("tdd_ok.md"))


def test_tdd_security_ok_passes():
    assert_pass("tdd", load("tdd_security_ok.md"))


def test_ux_ok_passes():
    assert_pass("ux-spec", load("ux-spec_ok.md"))


# ------------------------------------------------------------------- adr (5)
def test_adr_frontmatter_missing_field():
    t = mutate(load("adr_ok.md"), 'updated_by: "@staff-engineer"\n', "")
    assert_fail("adr", t, "frontmatter")


def test_adr_frontmatter_superseded_without_successor():
    t = mutate(load("adr_ok.md"), 'status: "proposed"', 'status: "superseded"')
    assert_fail("adr", t, "frontmatter")


def test_adr_status_value():
    t = mutate(load("adr_ok.md"), 'status: "proposed"', 'status: "bogus"')
    assert_fail("adr", t, "status")


def test_adr_section_order():
    t = mutate(load("adr_ok.md"), "## Decision", "## Choice")
    assert_fail("adr", t, "section-order")


def test_adr_alternatives_empty():
    t = mutate(load("adr_ok.md"), "- Approach Y — rejected because it duplicates state.\n", "")
    assert_fail("adr", t, "alternatives")


def test_adr_placeholder():
    t = mutate(load("adr_ok.md"), "## Context\n", "## Context\n\nTODO fill this in.\n")
    assert_fail("adr", t, "placeholder")


# ------------------------------------------------------------------- prd (7)
def test_prd_frontmatter_missing_field():
    t = mutate(load("prd_ok.md"), 'scope: "A sample product surface for fixture testing"\n', "")
    assert_fail("prd", t, "frontmatter")


def test_prd_status_present():
    t = mutate(load("prd_ok.md"), 'maturity: "draft"\n', 'maturity: "draft"\nstatus: "draft"\n')
    assert_fail("prd", t, "no-status")


def test_prd_maturity_value():
    t = mutate(load("prd_ok.md"), 'maturity: "draft"', 'maturity: "bogus"')
    assert_fail("prd", t, "maturity")


def test_prd_section_order():
    t = mutate(load("prd_ok.md"), "## Goals", "## Objectives")
    assert_fail("prd", t, "section-order")


def test_prd_mermaid():
    t = mutate(load("prd_ok.md"), "```mermaid\ngraph LR\n    A --> B\n```\n", "")
    assert_fail("prd", t, "mermaid")


def test_prd_placeholder():
    t = mutate(load("prd_ok.md"), "## Goals\n", "## Goals\n\n{slug} placeholder.\n")
    assert_fail("prd", t, "placeholder")


def test_prd_success_metrics_non_numeric():
    t = mutate(load("prd_ok.md"),
               "- p95 latency under 800ms measured via /metrics endpoint.",
               "- Improve the user experience overall.")
    assert_fail("prd", t, "success-metrics")


# ------------------------------------------------------------------- tdd (8)
def test_tdd_frontmatter_missing_field():
    t = mutate(load("tdd_ok.md"), 'owner: "@staff-engineer"\n', "")
    assert_fail("tdd", t, "frontmatter")


def test_tdd_status_value():
    t = mutate(load("tdd_ok.md"), 'status: "draft"', 'status: "bogus"')
    assert_fail("tdd", t, "status")


def test_tdd_section_order():
    t = mutate(load("tdd_ok.md"), "## API Contracts", "## Interfaces")
    assert_fail("tdd", t, "section-order")


def test_tdd_alternatives_below_two():
    t = mutate(load("tdd_ok.md"),
               "### B. Second option\n\nShape, strengths, weaknesses, verdict.\n\n", "")
    assert_fail("tdd", t, "alternatives")


def test_tdd_mermaid():
    t = mutate(load("tdd_ok.md"), "```mermaid\ngraph LR\n    A --> B\n```\n\n", "")
    assert_fail("tdd", t, "mermaid")


def test_tdd_placeholder():
    t = mutate(load("tdd_ok.md"), "## Problem Statement\n", "## Problem Statement\n\nTBD.\n")
    assert_fail("tdd", t, "placeholder")


def test_tdd_security_subsections_missing():
    t = mutate(load("tdd_security_ok.md"),
               "### Threat Model\n\nAdversary capabilities and goals.\n\n", "")
    assert_fail("tdd", t, "security-subsections")


def test_tdd_security_abuse_cases_missing():
    t = mutate(load("tdd_security_ok.md"),
               "### Abuse Cases\n\nAdversarial-input tests enumerated here.\n\n", "")
    assert_fail("tdd", t, "security-abuse-cases")


# ---------------------------------------------------------------- ux-spec (6)
def test_ux_frontmatter_missing_field():
    t = mutate(load("ux-spec_ok.md"), 'owner: "@ux-designer"\n', "")
    assert_fail("ux-spec", t, "frontmatter")


def test_ux_status_present():
    t = mutate(load("ux-spec_ok.md"), 'maturity: "draft"\n', 'maturity: "draft"\nstatus: "draft"\n')
    assert_fail("ux-spec", t, "no-status")


def test_ux_maturity_value():
    t = mutate(load("ux-spec_ok.md"), 'maturity: "draft"', 'maturity: "bogus"')
    assert_fail("ux-spec", t, "maturity")


def test_ux_section_order():
    t = mutate(load("ux-spec_ok.md"), "## Accessibility", "## A11y")
    assert_fail("ux-spec", t, "section-order")


def test_ux_mermaid():
    t = mutate(load("ux-spec_ok.md"),
               "```mermaid\njourney\n    title Invoke\n    section Run\n      Invoke: 5: User\n```\n", "")
    assert_fail("ux-spec", t, "mermaid")


def test_ux_placeholder():
    t = mutate(load("ux-spec_ok.md"), "## Overview\n", "## Overview\n\nTODO.\n")
    assert_fail("ux-spec", t, "placeholder")


# ------------------------------------------------------------- usage / infra
def test_unreadable_file_exits_two():
    proc = subprocess.run([sys.executable, str(SCRIPT), "--type", "adr",
                           str(FIX / "does-not-exist.md")], capture_output=True, text=True)
    assert proc.returncode == 2, f"exit {proc.returncode}: {proc.stderr}"
    assert "cannot read" in proc.stderr, proc.stderr


def test_bad_type_exits_two():
    proc = subprocess.run([sys.executable, str(SCRIPT), "--type", "bogus",
                           str(FIX / "adr_ok.md")], capture_output=True, text=True)
    assert proc.returncode == 2, f"exit {proc.returncode}: {proc.stderr}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
