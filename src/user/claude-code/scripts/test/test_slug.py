#!/usr/bin/env python3
"""Checks for slug.sh — the 8-step deterministic slug derivation shared by the
doc-authoring skills (adr, prd, tdd, ux-spec).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_slug.py``.
Exit 0 = all asserts pass. Drives the real script via subprocess.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "slug.sh"


def run(*args):
    proc = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_simple_topic():
    code, out, err = run("Hello World Example")
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "hello-world-example", out


def test_punctuation_collapse():
    # Runs of non-alphanumerics collapse to a single '-', edges stripped.
    code, out, err = run("Foo!!!  ---  Bar")
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "foo-bar", out


def test_uppercase_and_mixed():
    code, out, err = run("CamelCase And UPPER")
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "camelcase-and-upper", out


def test_sixty_char_word_boundary_cut():
    # The §9 pinned case: boundary cut at index 49 (after 'skill'), never
    # mid-word at 60.
    topic = "coordinated shared-extraction of duplicated skill mechanisms (DKT-247/248/249/250)"
    code, out, err = run(topic)
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "coordinated-shared-extraction-of-duplicated-skill", out
    assert len(out.strip()) <= 60, out


def test_no_boundary_hard_cut_at_sixty():
    # A single long run with no '-' in [40,60) is hard-cut at 60 (rfind -> -1).
    topic = "a" * 80
    code, out, err = run(topic)
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "a" * 60, out


def test_all_punctuation_aborts():
    code, out, err = run("!!!___###")
    assert code == 1, f"exit {code}: {out}"
    assert "at least one alphanumeric character" in err, err


def test_empty_topic_usage_error():
    code, out, err = run("")
    assert code == 2, f"exit {code}: {out}"
    assert "Usage: slug.sh" in err, err


def test_missing_topic_usage_error():
    code, out, err = run()
    assert code == 2, f"exit {code}: {out}"
    assert "Usage: slug.sh" in err, err


def test_extra_args_ignored():
    code, out, err = run("Hello World", "ignored", "also-ignored")
    assert code == 0, f"exit {code}: {err}"
    assert out.strip() == "hello-world", out


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
