#!/usr/bin/env python3
"""Checks for next_doc_number.sh — {NNNN} allocation, citation-hijack skip,
and the atomic --claim mode that closes the ADR/TDD numbering race (DKT-307).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_next_doc_number.py``.
Exit 0 = all asserts pass. Drives the real script via subprocess against
disposable tmp git repos (never touches the real docs/tdd|docs/adr trees).
"""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "next_doc_number.sh"


def make_repo():
    repo = Path(tempfile.mkdtemp(prefix="next_doc_number_"))
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    return repo


def run(repo, *args):
    proc = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True, cwd=str(repo))
    return proc.returncode, proc.stdout, proc.stderr


def test_first_number_is_0001():
    repo = make_repo()
    try:
        code, out, err = run(repo, "docs/adr")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0001", out
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_max_plus_one_over_existing_files():
    repo = make_repo()
    try:
        adr_dir = repo / "docs" / "adr"
        adr_dir.mkdir(parents=True)
        (adr_dir / "0001-foo.md").write_text("x")
        (adr_dir / "0003-bar.md").write_text("x")
        code, out, err = run(repo, "docs/adr")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0004", out
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_malformed_filename_aborts():
    repo = make_repo()
    try:
        adr_dir = repo / "docs" / "adr"
        adr_dir.mkdir(parents=True)
        (adr_dir / "not-numbered.md").write_text("x")
        code, out, err = run(repo, "docs/adr")
        assert code == 1, f"exit {code}: {out}"
        assert "could not determine next doc number" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_citation_hijack_skips_candidate():
    repo = make_repo()
    try:
        # Built via concatenation (not a contiguous literal) so this test's
        # own source text can't be picked up as a real citation-hijack hit
        # against the actual docs/adr/ tree by a plain repo-wide grep.
        cited = "docs/adr/" + "0001-planned.md"
        (repo / "notes.md").write_text(f"see {cited} for context")
        code, out, err = run(repo, "docs/adr")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0002", out
        assert "already cited (citation-hijack)" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_invalid_dir_usage_error():
    repo = make_repo()
    try:
        code, out, err = run(repo, "docs/prd")
        assert code == 1, f"exit {code}: {out}"
        assert "Usage: next_doc_number.sh" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_non_claiming_call_signature_unchanged():
    # Additive-only guarantee: a plain `<dir>` invocation never reserves a
    # stub file on disk, so existing adr/tdd skill call sites are unaffected.
    repo = make_repo()
    try:
        code, out, err = run(repo, "docs/tdd")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0001", out
        assert list((repo / "docs" / "tdd").glob("*.md")) == []
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_claim_creates_stub_and_returns_number():
    repo = make_repo()
    try:
        code, out, err = run(repo, "--claim", "docs/adr", "my-decision")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0001", out
        stub = repo / "docs" / "adr" / "0001-my-decision.md"
        assert stub.exists(), "claim mode must create the numbered stub file"
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_claim_advances_past_existing_claim():
    repo = make_repo()
    try:
        run(repo, "--claim", "docs/adr", "first-decision")
        code, out, err = run(repo, "--claim", "docs/adr", "second-decision")
        assert code == 0, f"exit {code}: {err}"
        assert out.strip() == "0002", out
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_claim_bad_slug_rejected():
    repo = make_repo()
    try:
        code, out, err = run(repo, "--claim", "docs/adr", "Bad Slug!")
        assert code != 0, f"exit {code}: {out}"
        assert "slug" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_claim_missing_slug_usage_error():
    repo = make_repo()
    try:
        code, out, err = run(repo, "--claim", "docs/adr")
        assert code == 1, f"exit {code}: {out}"
        assert "Usage: next_doc_number.sh" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_concurrent_claims_never_collide():
    # Regression test for the numbering race (DKT-307): N concurrent
    # --claim invocations for the SAME slug must each receive a distinct
    # number rather than silently computing the same "next" number. Since
    # every proc here shares one slug, they'd also serialize correctly on
    # the pre-fix-1 number+slug keying (identical claim_path per candidate)
    # — this test alone does NOT exercise the different-slug race; see
    # test_concurrent_claims_different_slugs_never_collide for that.
    repo = make_repo()
    n = 8
    try:
        procs = [
            subprocess.Popen(
                ["bash", str(SCRIPT), "--claim", "docs/adr", "race-decision"],
                cwd=str(repo), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            )
            for _ in range(n)
        ]
        results = [p.communicate() for p in procs]
        codes = [p.returncode for p in procs]
        assert all(c == 0 for c in codes), list(zip(codes, results))
        numbers = [out.strip() for out, _ in results]
        assert len(set(numbers)) == n, f"duplicate numbers assigned: {numbers}"
        adr_dir = repo / "docs" / "adr"
        stubs = sorted(p.name for p in adr_dir.glob("*.md"))
        assert len(stubs) == n, stubs
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_concurrent_claims_different_slugs_never_collide():
    # Regression test for DKT-307 fix-1: advisor reproduced 8 concurrent
    # --claim invocations with 8 DIFFERENT slugs all returning 0001,
    # because the original reservation was keyed on {NNNN}-{SLUG}.md
    # (number+slug), so different-slug claimants for the same candidate
    # number never contended on the same atomic-create path. The fix keys
    # the atomic reservation on the number alone (a number-only lock),
    # closing that gap. This is the exact scenario advisor reproduced —
    # distinct slugs per proc, not the shared-slug case above.
    repo = make_repo()
    n = 8
    try:
        procs = [
            subprocess.Popen(
                ["bash", str(SCRIPT), "--claim", "docs/adr", f"decision-{i}"],
                cwd=str(repo), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            )
            for i in range(n)
        ]
        results = [p.communicate() for p in procs]
        codes = [p.returncode for p in procs]
        assert all(c == 0 for c in codes), list(zip(codes, results))
        numbers = [out.strip() for out, _ in results]
        assert len(set(numbers)) == n, f"duplicate numbers assigned across different slugs: {numbers}"
        adr_dir = repo / "docs" / "adr"
        stubs = sorted(p.name for p in adr_dir.glob("*.md"))
        assert len(stubs) == n, stubs
        # Lock files are deliberately left in place (not cleaned up): removing
        # a lock after its winner claims the number would let a slower
        # claimant that computed the same candidate before the winner's stub
        # existed re-win the freed lock and mint a duplicate number.
        locks = sorted(p.name for p in adr_dir.glob(".claim-*.lock"))
        assert len(locks) == n, locks
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
