#!/usr/bin/env python3
"""Fixture-driven checks for check_citations.py — extraction and existence core.

Standalone (no pytest): ``python3 .claude/scripts/test/test_check_citations.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/citations/ so it never
touches the peer symmetry/signals fixtures. Drives the real CLI via subprocess.
"""
import importlib.util
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "check_citations.py"
FIXTURES = HERE / "fixtures" / "citations"
ARTIFACT = FIXTURES / "artifact.md"
REPO = FIXTURES / "repo"

spec = importlib.util.spec_from_file_location("check_citations", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_extract_citations_finds_paths_and_strips_line_suffix():
    text = ARTIFACT.read_text()
    citations = mod.extract_citations(text)
    assert ("docs/tdd/", None) in citations, citations
    assert ("docs/tdd/*.md", None) in citations, citations
    assert ("src/inner/main.rs", "1") in citations, citations
    assert ("src/inner/main.rs", "1-2") in citations, citations
    assert ("docs/nowhere.md", None) in citations, citations
    assert ("src/**/*.py", None) in citations, citations


def test_extract_citations_ignores_prose_and_fenced_blocks():
    text = ARTIFACT.read_text()
    citations = mod.extract_citations(text)
    paths = [p for p, _ in citations]
    assert "and/or" not in paths, paths
    assert "he/she" not in paths, paths
    assert "3/4" not in paths, paths
    # Only the fenced block's copy is suppressed; the real citation still counts once.
    assert paths.count("docs/tdd/foo.md") == 0, paths


def test_extract_citations_dedupes_in_first_seen_order():
    text = "`docs/tdd/` and again `docs/tdd/` then `docs/adr/`"
    citations = mod.extract_citations(text)
    assert citations == [("docs/tdd/", None), ("docs/adr/", None)], citations


def test_citation_exists_literal_glob_and_home():
    assert mod.citation_exists("docs/tdd/", REPO) is True
    assert mod.citation_exists("src/inner/main.rs", REPO) is True
    assert mod.citation_exists("docs/nowhere.md", REPO) is False
    assert mod.citation_exists("docs/tdd/*.md", REPO) is True   # glob match
    assert mod.citation_exists("src/**/*.py", REPO) is False    # glob, no match
    assert mod.citation_exists(str(Path.home()) + "/", Path(".")) is True
    assert mod.citation_exists("~/", REPO) is True


def test_cli_reports_missing_and_exits_nonzero():
    code, out, err = run(str(ARTIFACT), "--base", str(REPO))
    assert code == 1, f"exit {code}: {out}{err}"
    lines = out.splitlines()
    assert any("MISSING" in l and "docs/nowhere.md" in l for l in lines), out
    assert any("MISSING" in l and "src/**/*.py" in l for l in lines), out
    assert any(l.strip().startswith("OK") and l.strip().endswith("docs/tdd/") for l in lines), out
    assert any("OK" in l and "src/inner/main.rs:1" in l and "1-2" not in l for l in lines), out
    assert any("OK" in l and "src/inner/main.rs:1-2" in l for l in lines), out
    assert "citations: MISSING (2 of 6 not found)" in out, out


def test_cli_all_resolved_exits_zero():
    text = "See `docs/tdd/` and `src/inner/main.rs:1`."
    tmp = FIXTURES / "_all_resolved.md"
    tmp.write_text(text)
    try:
        code, out, err = run(str(tmp), "--base", str(REPO))
        assert code == 0, f"exit {code}: {out}{err}"
        assert "citations: OK (2 found, all resolved)" in out, out
    finally:
        tmp.unlink()


def test_cli_no_citations_exits_zero():
    tmp = FIXTURES / "_no_citations.md"
    tmp.write_text("Nothing path-like here, just `and/or` prose.")
    try:
        code, out, err = run(str(tmp), "--base", str(REPO))
        assert code == 0, f"exit {code}: {out}{err}"
        assert "citations: none found" in out, out
    finally:
        tmp.unlink()


def test_cli_missing_artifact_exits_two():
    code, out, err = run(str(FIXTURES / "does-not-exist.md"), "--base", str(REPO))
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
