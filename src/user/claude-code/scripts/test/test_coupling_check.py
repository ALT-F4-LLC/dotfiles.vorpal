#!/usr/bin/env python3
"""Fixture-driven checks for coupling_check.py — the two sibling-list
grammars (self-inclusive parenthetical, siblings-only "sync with" clause),
count-vs-roster validation, and reciprocity across a synthetic skill family.
Also a real-repo smoke assertion (the 8 actual COUPLING notes today parse
clean).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_coupling_check.py``.
Exit 0 = all asserts pass.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "coupling_check.py"
REPO_ROOT = HERE.parent.parent.parent.parent.parent


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def run(*extra_args):
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), *extra_args], capture_output=True, text=True
    )
    return proc.returncode, proc.stdout, proc.stderr


def skill_md(tmpdir, name):
    return os.path.join(tmpdir, "skills", name, "SKILL.md")


def test_self_inclusive_family_consistent():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    note = (
        "<!-- COUPLING: this skill is part of the widget family "
        "(alpha, beta, gamma) — update all 3 in lockstep when adding/removing "
        "a sibling skill. -->\n"
    )
    for name in ("alpha", "beta", "gamma"):
        write(skill_md(tmp, name), f"# {name}\n\n{note}")
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "3/3 family-membership notes consistent" in out, out
    assert "[OK]" in out, out


def test_siblings_only_family_consistent():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    def note(others):
        return (
            "<!-- COUPLING: this skill is part of the gadget family. The "
            "\"When NOT to Use\" delegation routes below MUST stay in sync with "
            f"src/user/claude-code/skills/{others} — update all 3 in lockstep "
            "when adding/removing a sibling skill. -->\n"
        )
    write(skill_md(tmp, "alpha"), "# alpha\n\n" + note("beta, and gamma"))
    write(skill_md(tmp, "beta"), "# beta\n\n" + note("alpha, and gamma"))
    write(skill_md(tmp, "gamma"), "# gamma\n\n" + note("alpha, and beta"))
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "3/3 family-membership notes consistent" in out, out


def test_count_mismatch_detected():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    note = (
        "<!-- COUPLING: this skill is part of the widget family "
        "(alpha, beta) — update all 3 in lockstep. -->\n"
    )
    write(skill_md(tmp, "alpha"), "# alpha\n\n" + note)
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[COUNT-MISMATCH]" in out, out


def test_reciprocity_mismatch_missing_sibling_note():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    note = (
        "<!-- COUPLING: this skill is part of the widget family "
        "(alpha, beta) — update all 2 in lockstep. -->\n"
    )
    write(skill_md(tmp, "alpha"), "# alpha\n\n" + note)
    write(skill_md(tmp, "beta"), "# beta\n\nNo coupling note here at all.\n")
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[RECIPROCITY-MISMATCH]" in out, out
    assert "beta carries no reciprocal family note" in out, out


def test_reciprocity_mismatch_divergent_roster():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    write(
        skill_md(tmp, "alpha"),
        "# alpha\n\n<!-- COUPLING: this skill is part of the widget family "
        "(alpha, beta) — update all 2 in lockstep. -->\n",
    )
    write(
        skill_md(tmp, "beta"),
        "# beta\n\n<!-- COUPLING: this skill is part of the widget family "
        "(beta, gamma) — update all 2 in lockstep. -->\n",
    )
    write(skill_md(tmp, "gamma"), "# gamma\n\nNo note.\n")
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 1, f"exit {code}: {out}{err}"
    assert "[RECIPROCITY-MISMATCH]" in out, out


def test_bridge_clause_not_mistaken_for_family_roster():
    # Mirrors the real ux-spec note shape: a later "bridges the X family
    # (...)" clause after "— update all N in lockstep" must never be parsed
    # as this note's own roster.
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    bridge_note = (
        "<!-- COUPLING: this skill is part of the doc-authoring family. The "
        "\"When NOT to Use\" delegation routes below MUST stay in sync with "
        "src/user/claude-code/skills/beta, and gamma — update all 3 in "
        "lockstep when adding/removing a sibling skill. Also bridges the "
        "other family (zzz, yyy) which brackets the lifecycle. -->\n"
    )
    write(skill_md(tmp, "alpha"), "# alpha\n\n" + bridge_note)
    write(
        skill_md(tmp, "beta"),
        "# beta\n\n<!-- COUPLING: this skill is part of the doc-authoring "
        "family. Stay in sync with src/user/claude-code/skills/alpha, and "
        "gamma — update all 3 in lockstep. -->\n",
    )
    write(
        skill_md(tmp, "gamma"),
        "# gamma\n\n<!-- COUPLING: this skill is part of the doc-authoring "
        "family. Stay in sync with src/user/claude-code/skills/alpha, and "
        "beta — update all 3 in lockstep. -->\n",
    )
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "3/3 family-membership notes consistent" in out, out
    assert "zzz" not in out and "yyy" not in out, out


def test_non_family_coupling_notes_ignored():
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    write(
        skill_md(tmp, "alpha"),
        "# alpha\n\n<!-- COUPLING: scope-resolution — Keep all four in sync "
        "across both files. -->\n",
    )
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no family-membership COUPLING notes found" in err, err


def test_prose_mention_of_marker_not_a_note():
    # A line like "- COUPLING: `grep -rn '<!-- COUPLING' ...`" mentions the
    # marker string but does not START the line with it -- must be excluded.
    tmp = tempfile.mkdtemp(prefix="coupling_check_")
    write(
        skill_md(tmp, "alpha"),
        "# alpha\n\n- COUPLING: `grep -rn '<!-- COUPLING' src` finds family "
        "(alpha, beta) — update all 2 in lockstep notes.\n",
    )
    code, out, err = run("--glob", f"{tmp}/skills/*/SKILL.md")
    assert code == 2, f"exit {code}: {out}{err}"


def test_no_files_matched_exits_two():
    code, out, err = run("--glob", "/definitely/not/a/real/dir/*/SKILL.md")
    assert code == 2, f"exit {code}: {out}{err}"
    assert "no files matched" in err, err


def test_real_repo_families_consistent():
    code, out, err = run(
        "--glob", "src/user/claude-code/skills/*/SKILL.md",
        "--glob", ".claude/skills/*/SKILL.md",
    )
    proc_cwd_note = f"(ran from {os.getcwd()}, expected repo root {REPO_ROOT})"
    assert code == 0, f"exit {code} {proc_cwd_note}: {out}{err}"
    assert "8/8 family-membership notes consistent" in out, out


def main():
    os.chdir(REPO_ROOT)
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
