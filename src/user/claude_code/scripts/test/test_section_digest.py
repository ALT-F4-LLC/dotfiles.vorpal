#!/usr/bin/env python3
"""Checks for section_digest.sh.

Standalone (no pytest):
``python3 src/user/claude-code/scripts/test/test_section_digest.py``
"""

import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "section_digest.sh"

DOC = """# Title

## Alpha

Alpha body line one.
Alpha body line two.

## Beta

Beta body line one.
"""

DOC_ALPHA_CHANGED = """# Title

## Alpha

Alpha body line one CHANGED.
Alpha body line two.

## Beta

Beta body line one.
"""

DOC_BETA_CHANGED = """# Title

## Alpha

Alpha body line one.
Alpha body line two.

## Beta

Beta body line one CHANGED.
"""


def run(doc_path, heading):
    p = subprocess.run(
        [str(SCRIPT), str(doc_path), heading], capture_output=True, text=True
    )
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def write_doc(tmp_dir, content):
    path = Path(tmp_dir) / "doc.md"
    path.write_text(content)
    return path


def test_deterministic():
    with tempfile.TemporaryDirectory() as tmp:
        doc = write_doc(tmp, DOC)
        code1, out1, _ = run(doc, "Alpha")
        code2, out2, _ = run(doc, "Alpha")
        assert code1 == 0, f"expected exit 0, got {code1}"
        assert code2 == 0, f"expected exit 0, got {code2}"
        assert out1 == out2, f"digest not deterministic: {out1!r} != {out2!r}"
        assert len(out1) == 12, f"expected 12 hex chars, got {out1!r}"


def test_digest_changes_when_section_body_changes():
    with tempfile.TemporaryDirectory() as tmp:
        doc_before = write_doc(tmp, DOC)
        _, digest_before, _ = run(doc_before, "Alpha")

    with tempfile.TemporaryDirectory() as tmp2:
        doc_after = write_doc(tmp2, DOC_ALPHA_CHANGED)
        _, digest_after, _ = run(doc_after, "Alpha")

    assert digest_before != digest_after, "digest should change when section body changes"


def test_digest_stable_when_different_section_changes():
    with tempfile.TemporaryDirectory() as tmp:
        doc_before = write_doc(tmp, DOC)
        _, digest_before, _ = run(doc_before, "Alpha")

    with tempfile.TemporaryDirectory() as tmp2:
        doc_after = write_doc(tmp2, DOC_BETA_CHANGED)
        _, digest_after, _ = run(doc_after, "Alpha")

    assert digest_before == digest_after, "digest should be stable when a different section changes"


def test_missing_heading_exits_2():
    with tempfile.TemporaryDirectory() as tmp:
        doc = write_doc(tmp, DOC)
        code, out, err = run(doc, "Gamma")
        assert code == 2, f"expected exit 2, got {code}"
        assert err, "expected a stderr message on missing heading"


DOC_NEAR_MISS = """# Title

## Phase 10 — Something

Phase 10 body line one.
"""


def test_near_miss_heading_exits_2():
    with tempfile.TemporaryDirectory() as tmp:
        doc = write_doc(tmp, DOC_NEAR_MISS)
        code, out, err = run(doc, "Phase 1")
        assert code == 2, f"expected exit 2 for near-miss substring heading, got {code}"
        assert err, "expected a stderr message on near-miss heading"


TESTS = [
    test_deterministic,
    test_digest_changes_when_section_body_changes,
    test_digest_stable_when_different_section_changes,
    test_missing_heading_exits_2,
    test_near_miss_heading_exits_2,
]


def main():
    failures = 0
    for test in TESTS:
        try:
            test()
            print(f"PASS {test.__name__}")
        except AssertionError as e:
            failures += 1
            print(f"FAIL {test.__name__}: {e}")
    if failures:
        print(f"{failures}/{len(TESTS)} tests failed")
        sys.exit(1)
    print(f"{len(TESTS)}/{len(TESTS)} tests passed")


if __name__ == "__main__":
    main()
