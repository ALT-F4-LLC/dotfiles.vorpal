#!/usr/bin/env python3
"""Fixture-driven checks for pitfalls_compactable.sh — HEAD-containment
candidacy, ledger-section exclusion, malformed-ledger refusal, and the
centralized-home no-op.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_pitfalls_compactable.py``.
Exit 0 = all asserts pass. Each case builds a throwaway git repo (via
``git init`` in a temp dir, gpgsign disabled), commits a pitfalls.md fixture,
optionally appends uncommitted content, then drives the real CLI via
subprocess.
"""
import os
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "pitfalls_compactable.sh"

ROLE = "testrole"


def new_repo():
    d = os.path.realpath(tempfile.mkdtemp(prefix="pitfalls_compactable_repo_"))
    subprocess.run(["git", "init", "-q"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.com"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=d, check=True)
    subprocess.run(["git", "config", "commit.gpgsign", "false"], cwd=d, check=True)
    return d


def pitfalls_path(repo):
    return os.path.join(repo, ".claude", "agent-memory", ROLE, "pitfalls.md")


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def commit_all(repo, msg="commit"):
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-q", "-m", msg], cwd=repo, check=True)


def run_script(repo, *args):
    proc = subprocess.run(
        ["bash", str(SCRIPT), *args], cwd=repo, capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


def test_committed_entries_are_candidates():
    repo = new_repo()
    write(
        pitfalls_path(repo),
        "# testrole pitfalls\n\n"
        "## Entry one\nSymptom -> cause -> resolution.\n\n"
        "## Entry two\nSymptom -> cause -> resolution.\n",
    )
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "## Entry one" in out, out
    assert "## Entry two" in out, out


def test_uncommitted_entry_is_not_a_candidate():
    repo = new_repo()
    path = pitfalls_path(repo)
    write(path, "# testrole pitfalls\n\n## Entry one\nSymptom -> cause -> resolution.\n")
    commit_all(repo)
    with open(path, "a") as f:
        f.write("\n## Entry two uncommitted\nShould not be flagged.\n")
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "## Entry one" in out, out
    assert "Entry two uncommitted" not in out, out


def test_already_ledgered_entry_excluded():
    repo = new_repo()
    write(
        pitfalls_path(repo),
        "# testrole pitfalls\n\n"
        "## Harvested ledger (compacted)\n\n"
        "- [2026-01-01] some distilled lesson -> encoded in foo.py (bar)\n\n"
        "## Live entry\nSymptom -> cause -> resolution.\n",
    )
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "## Live entry" in out, out
    assert "Harvested ledger" not in out, out
    assert "2026-01-01" not in out, out


def test_no_committed_file_reports_clean():
    repo = new_repo()
    write(pitfalls_path(repo), "# testrole pitfalls\n\n## Entry one\nNot committed at all.\n")
    # No commit_all() -- entire file is untracked.
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out == "", out


def test_no_pitfalls_file_at_all_reports_clean():
    repo = new_repo()
    commit_all_readme = os.path.join(repo, "README.md")
    write(commit_all_readme, "placeholder\n")
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "nothing to compact" in err, err


def test_centralized_home_is_always_a_noop():
    repo = new_repo()
    code, out, err = run_script(repo, ROLE, "centralized")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out == "", out
    assert "never part of the evolve-agents Phase-4" in err, err


def test_malformed_ledger_refused():
    repo = new_repo()
    write(
        pitfalls_path(repo),
        "# testrole pitfalls\n\n"
        "## Harvested ledger (compacted)\n\n"
        "- [2026-01-01] a ledger line\n"
        "not a properly blank-terminated section\n",
    )
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 7, f"exit {code}: {out}{err}"
    assert "malformed" in err, err


def test_usage_errors():
    repo = new_repo()
    code, out, err = run_script(repo)
    assert code == 2, f"exit {code}: {out}{err}"
    code, out, err = run_script(repo, ROLE, "not-a-real-home")
    assert code == 2, f"exit {code}: {out}{err}"


# ---------------------------------------------------------------------------
# DKT-126 fix-round: pitfalls_compactable.sh's enumerate loop must absorb a
# `## ` heading's immediately-following contiguous `- ` bullet run (with or
# without one intervening blank line) into ONE candidate, matching
# pitfalls_distill.sh's enumerate_entries -- the Blocker this port closes.
# ---------------------------------------------------------------------------
def test_heading_with_bullets_is_one_candidate():
    repo = new_repo()
    write(
        pitfalls_path(repo),
        "# testrole pitfalls\n\n"
        "## Background-task exit code masked\n"
        "- **Symptom:** launched a long test in the background.\n"
        "- **Root cause:** the reported exit code was the trailing echo, not the real command.\n"
        "- **Resolution:** capture the real exit in the same subshell as the command.\n\n"
        "## a heading with one blank line before its bullet\n\n"
        "- **Symptom:** one blank line is tolerated before the bullet run too.\n",
    )
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 1, f"exit {code}: {out}{err}"
    candidate_lines = [l for l in out.splitlines() if l]
    assert len(candidate_lines) == 2, out
    assert candidate_lines[0] == "## Background-task exit code masked", out
    assert candidate_lines[1] == "## a heading with one blank line before its bullet", out


def test_interior_blank_entry_committed_is_candidate():
    repo = new_repo()
    write(
        pitfalls_path(repo),
        "# testrole pitfalls\n\n"
        "## a heading with one blank line before its bullet\n\n"
        "- **Symptom:** committed together with its heading, interior blank included.\n",
    )
    commit_all(repo)
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "## a heading with one blank line before its bullet" in out, out


def test_interior_blank_entry_edited_after_commit_not_candidate():
    repo = new_repo()
    path = pitfalls_path(repo)
    write(
        path,
        "# testrole pitfalls\n\n"
        "## a heading with one blank line before its bullet\n\n"
        "- **Symptom:** original bullet text before the post-commit edit.\n",
    )
    commit_all(repo)
    # Edit the bullet in place (uncommitted) -- the absorbed span's FULL
    # text (heading + blank + bullet) no longer byte-matches HEAD, so it
    # must not be reported as a compaction candidate.
    write(
        path,
        "# testrole pitfalls\n\n"
        "## a heading with one blank line before its bullet\n\n"
        "- **Symptom:** EDITED bullet text after commit.\n",
    )
    code, out, err = run_script(repo, ROLE, "in-repo")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out == "", out


DISTILL_SCRIPT = HERE.parent / "pitfalls_distill.sh"


def run_distill_script(repo, args):
    proc = subprocess.run(
        ["bash", str(DISTILL_SCRIPT), *args], cwd=repo, capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


def test_cross_script_entry_count_parity():
    """The Blocker this port closes: pitfalls_compactable.sh's candidate
    count and pitfalls_distill.sh's ENTRIES_BEFORE count must agree for an
    identical fixture mixing all three absorbed shapes (no-blank
    heading+bullets, one-blank heading+bullets, bare bullet)."""
    fixture = (
        "# testrole pitfalls (in-repo)\n\n"
        "## no-blank heading with bullets\n"
        "- **Symptom:** immediate bullet run, no blank.\n"
        "- **Resolution:** absorbed as one entry.\n\n"
        "## one-blank heading with bullets\n\n"
        "- **Symptom:** one blank tolerated before the bullet run.\n"
        "- **Resolution:** absorbed as one entry too.\n\n"
        "- symptom: a bare bullet entry with no owning heading.\n"
    )

    repo_c = new_repo()
    write(pitfalls_path(repo_c), fixture)
    commit_all(repo_c)
    code_c, out_c, err_c = run_script(repo_c, ROLE, "in-repo")
    assert code_c == 1, f"exit {code_c}: {out_c}{err_c}"
    candidate_lines = [l for l in out_c.splitlines() if l]
    assert len(candidate_lines) == 3, out_c

    repo_d = new_repo()
    pf_d = pitfalls_path(repo_d)
    write(pf_d, fixture)
    enc_rel = "src/user/claude-code/scripts/parity_check.md"
    write(os.path.join(repo_d, enc_rel), "Parity check encoded lesson.\n")
    commit_all(repo_d)
    code_d, out_d, err_d = run_distill_script(repo_d, [
        ROLE, "in-repo",
        "--entry", "## no-blank heading with bullets",
        "--encoded-in", enc_rel,
        "--evidence", "Parity check encoded",
        "--date", "2026-07-25",
    ])
    assert code_d == 0, f"exit {code_d}: {err_d}"
    assert "PARITY: entries 3->2" in out_d, out_d


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
