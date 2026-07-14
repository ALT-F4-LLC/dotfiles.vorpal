#!/usr/bin/env python3
"""Fixture-driven checks for pitfalls_distill.sh — the CLI contract, the
§4.2a file grammar (ledger section / entry boundary / writer layout
invariant), and the atomic-write mechanics.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_pitfalls_distill.py``.
Exit 0 = all asserts pass. Each case builds a throwaway git repo (via
``git init`` in a temp dir, gpgsign disabled) with a tracked --encoded-in
target and pitfalls fixtures, then drives the real CLI via subprocess.
"""
import glob
import hashlib
import os
import re
import shutil
import stat
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "pitfalls_distill.sh"

HEADING = "## Harvested ledger (compacted)"


def new_repo():
    # realpath: git rev-parse --show-toplevel canonicalizes symlinks (e.g.
    # macOS /tmp -> /private/tmp), so resolve here to keep path comparisons
    # against the script's own stdout consistent.
    d = os.path.realpath(tempfile.mkdtemp(prefix="pitfalls_distill_repo_"))
    subprocess.run(["git", "init", "-q"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.email", "t@t.com"], cwd=d, check=True)
    subprocess.run(["git", "config", "user.name", "t"], cwd=d, check=True)
    subprocess.run(["git", "config", "commit.gpgsign", "false"], cwd=d, check=True)
    return d


def new_home_dir():
    return os.path.realpath(tempfile.mkdtemp(prefix="pitfalls_distill_home_"))


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)


def read_text(path):
    with open(path) as f:
        return f.read()


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def commit_all(repo, msg="commit"):
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-q", "-m", msg], cwd=repo, check=True)


def run_distill(repo, args, env_overrides=None):
    env = dict(os.environ)
    if env_overrides:
        env.update(env_overrides)
    proc = subprocess.run(
        ["bash", str(SCRIPT), *args], cwd=repo, capture_output=True, text=True, env=env
    )
    return proc.returncode, proc.stdout, proc.stderr


def pitfalls_path(repo, role, home="in-repo", home_dir=None):
    if home == "in-repo":
        return os.path.join(repo, ".claude", "agent-memory", role, "pitfalls.md")
    return os.path.join(home_dir, ".claude", "agent-memory", role, "pitfalls.md")


def base_encoded_in(repo, rel="src/user/claude-code/skills/team-doctrine/references/foo.md",
                     content="This doc encodes the lesson now.\n"):
    write(os.path.join(repo, rel), content)
    return rel


def leftover_temps(target_dir):
    return glob.glob(os.path.join(target_dir, ".pitfalls_distill.*"))


# ---------------------------------------------------------------------------
# 1. Happy path, in-repo, bullet-style entries with H1 (staff shape)
# ---------------------------------------------------------------------------
def test_happy_path_bullet_with_h1():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n"
          "- symptom: In an evolve-* skill review, recommended TRIM edits that turned out to be parity-bound.\n"
          "- symptom: Reviewing a skill-script extraction, invoked via bare repo path.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: In an evolve-* skill review",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    assert "--- REMOVED ENTRY (mirror into your change record) ---" in out, out
    assert "In an evolve-* skill review" in out, out
    assert "RECOVERY-CHANNEL: git-history" in out, out
    assert "PARITY: entries 2->1, ledger 0->1" in out, out
    assert out.strip().splitlines()[-1] == pf, out

    content = read_text(pf)
    expected = (
        "# Pitfalls: staff-engineer\n\n"
        "## Harvested ledger (compacted)\n\n"
        "- [2026-07-14] symptom: In an evolve-* skill review, recommended TRIM edits that turned out to be parity-bound. → encoded in src/user/claude-code/skills/team-doctrine/references/foo.md (the lesson now)\n\n"
        "- symptom: Reviewing a skill-script extraction, invoked via bare repo path.\n"
    )
    assert content == expected, repr(content)
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 2. Happy path, centralized home (HOME env override)
# ---------------------------------------------------------------------------
def test_happy_path_centralized_home():
    repo = new_repo()
    central = new_home_dir()
    pf = pitfalls_path(repo, "senior-engineer", home="centralized", home_dir=central)
    write(pf,
          "- old lesson about centralized homes needing coverage too\n")
    enc_rel = "src/user/claude-code/scripts/foo_centralized.md"
    write(os.path.join(repo, enc_rel), "Centralized coverage documented here.\n")
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "senior-engineer", "centralized",
        "--entry", "- old lesson about centralized",
        "--encoded-in", enc_rel,
        "--evidence", "Centralized coverage",
        "--date", "2026-07-14",
    ], env_overrides={"HOME": central})
    assert code == 0, f"exit {code}: {err}"
    assert pf in out, out

    content = read_text(pf)
    assert HEADING in content, content
    # The default summary is derived FROM the entry text, so the phrase
    # legitimately survives inside the ledger line — assert the original
    # bare bullet line (no [date]/encoded-in framing) is gone, not the phrase.
    assert "- old lesson about centralized homes needing coverage too\n" not in content, content
    assert "- [2026-07-14] old lesson about centralized homes needing coverage too" in content, content
    assert "encoded in src/user/claude-code/scripts/foo_centralized.md" in content, content
    shutil.rmtree(repo, ignore_errors=True)
    shutil.rmtree(central, ignore_errors=True)


# ---------------------------------------------------------------------------
# 3. Heading-style entries (senior shape)
# ---------------------------------------------------------------------------
def test_heading_style_entries():
    repo = new_repo()
    pf = pitfalls_path(repo, "senior-engineer")
    write(pf,
          "# Senior Engineer Pitfalls (in-repo)\n\n"
          "## vorpal build does not relink symlinks\n\n"
          "Symptom: after building the artifact digest still resolves old.\n\n"
          "Resolution: run just activate after any build.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "senior-engineer", "in-repo",
        "--entry", "## vorpal build does not relink",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    assert HEADING in content, content
    assert "## vorpal build does not relink symlinks" not in content, content
    assert "- [2026-07-14] vorpal build does not relink symlinks" in content, content
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 4. No-H1 file (distinguished-engineer shape): section lands at top-of-file
# ---------------------------------------------------------------------------
def test_no_h1_file_section_at_top():
    repo = new_repo()
    pf = pitfalls_path(repo, "distinguished-engineer")
    write(pf,
          "\n"
          "- **Symptom:** a Phase-1 reviewer fixes a migrated path in its own file.\n"
          "\n"
          "- **Symptom:** prose enumerations of blocks go stale over time.\n"
          "\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "distinguished-engineer", "in-repo",
        "--entry", "- **Symptom:** a Phase-1 reviewer",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    expected = (
        "## Harvested ledger (compacted)\n\n"
        "- [2026-07-14] **Symptom:** a Phase-1 reviewer fixes a migrated path in its own file. "
        "→ encoded in src/user/claude-code/skills/team-doctrine/references/foo.md (the lesson now)\n\n"
        "- **Symptom:** prose enumerations of blocks go stale over time.\n\n"
    )
    assert content == expected, repr(content)
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 5. Second ledgering appends after the last existing ledger line
# ---------------------------------------------------------------------------
def test_second_ledgering_appends_no_dup_heading():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n"
          "## Harvested ledger (compacted)\n\n"
          "- [2026-01-01] first distilled lesson → encoded in path/a.md (evidence a)\n\n"
          "- symptom: a surviving entry positioned below the section that must stay classified as an entry.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: a surviving entry",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    assert "PARITY: entries 1->0, ledger 1->2" in out, out
    content = read_text(pf)
    expected = (
        "# Pitfalls: staff-engineer\n\n"
        "## Harvested ledger (compacted)\n\n"
        "- [2026-01-01] first distilled lesson → encoded in path/a.md (evidence a)\n"
        "- [2026-07-14] symptom: a surviving entry positioned below the section that must stay classified as an entry. → encoded in src/user/claude-code/skills/team-doctrine/references/foo.md (the lesson now)\n\n"
    )
    assert content == expected, repr(content)
    assert content.count(HEADING) == 1, content
    assert "\n\n- [2026-07-14]" not in content, "inter-line blank between ledger lines: " + repr(content)
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 5b. Date-bracket-entry collision (observed centralized DE shape)
# ---------------------------------------------------------------------------
def test_date_bracket_collision_no_section():
    repo = new_repo()
    pf = pitfalls_path(repo, "distinguished-engineer")
    write(pf,
          "- [2026-07-09] Dispatch briefs citation inventory undercounted the real closure set.\n\n"
          "- [2026-07-09] Same-cycle re-fire of the widest-root lesson above, missed two more trees.\n\n"
          "- [2026-07-14] TDD round-1 reject about a worked example never dry-run.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "distinguished-engineer", "in-repo",
        "--entry", "- [2026-07-09] Same-cycle re-fire",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    # The other two date-bracket entries must remain ordinary entries, never
    # absorbed into a ledger run (there was no section to begin with).
    assert "- [2026-07-09] Dispatch briefs citation inventory" in content, content
    assert "- [2026-07-14] TDD round-1 reject" in content, content
    assert content.count(HEADING) == 1, content
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 5c. Malformed pre-existing ledger section -> exit 7, file byte-identical
# ---------------------------------------------------------------------------
def test_malformed_section_refused():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "## Harvested ledger (compacted)\n\n"
          "- [2026-01-01] first real ledger line → encoded in path/a.md (evidence a)\n"
          "- [2020-05-05] a date-bracket entry jammed directly against the ledger run with no separating blank\n"
          "- **Symptom:** a real entry directly following with no terminating blank at all\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- **Symptom:** a real entry",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 7, f"exit {code}: {out}{err}"
    assert sha(pf) == before, "file mutated on malformed-section refusal"
    assert not leftover_temps(os.path.dirname(pf)), "leftover temp file after refusal"
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 6 / 6b. --entry prefix matches no entry / matches two entries
# ---------------------------------------------------------------------------
def test_entry_prefix_no_match():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: only entry present here.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: nothing matches this prefix",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 3, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)


def test_entry_prefix_ambiguous():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n"
          "- symptom: shared prefix case one with distinct tail text alpha.\n"
          "- symptom: shared prefix case two with distinct tail text beta.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: shared prefix case",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 4, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 7. --encoded-in untracked / --evidence no hit / centralized outside tree
# ---------------------------------------------------------------------------
def test_encoded_in_untracked_exit5():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for untracked encoded-in case.\n")
    commit_all(repo)
    write(os.path.join(repo, "src/user/claude-code/scripts/untracked.md"), "not added to git\n")
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for untracked",
        "--encoded-in", "src/user/claude-code/scripts/untracked.md",
        "--evidence", "not added",
    ])
    assert code == 5, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)


def test_evidence_no_hit_exit6():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for evidence-no-hit case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for evidence-no-hit",
        "--encoded-in", enc,
        "--evidence", "this exact string is not present anywhere in the target",
    ])
    assert code == 6, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)


def test_centralized_encoded_in_outside_tree_exit8():
    repo = new_repo()
    central = new_home_dir()
    pf = pitfalls_path(repo, "senior-engineer", home="centralized", home_dir=central)
    write(pf, "- old lesson for the outside-tree centralized guard case.\n")
    write(os.path.join(repo, "docs/spec/outside.md"), "outside src/user/claude-code entirely\n")
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "senior-engineer", "centralized",
        "--entry", "- old lesson for the outside-tree",
        "--encoded-in", "docs/spec/outside.md",
        "--evidence", "outside src",
    ], env_overrides={"HOME": central})
    assert code == 8, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)
    shutil.rmtree(central, ignore_errors=True)


# ---------------------------------------------------------------------------
# 8. Trial:/Drift: lines appended verbatim (E4)
# ---------------------------------------------------------------------------
def test_trial_drift_lines_verbatim():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n"
          "- symptom: entry carrying trial and drift annotations for E4 coverage.\n"
          "Trial: attempted the naive fix, regressed a sibling case.\n"
          "Drift: definition now covers both cases explicitly.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry carrying trial and drift",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    ledger_line = [l for l in content.splitlines() if l.startswith("- [2026-07-14]")][0]
    assert "Trial: attempted the naive fix, regressed a sibling case." in ledger_line, ledger_line
    assert "Drift: definition now covers both cases explicitly." in ledger_line, ledger_line
    prefix_part = ledger_line.split(" → encoded in ")[0]
    assert len(prefix_part) - len("- [2026-07-14] ") <= 160, prefix_part
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 9. RECOVERY-CHANNEL: committed at HEAD -> git-history; uncommitted -> record-mirror-only
# ---------------------------------------------------------------------------
def test_recovery_channel_git_history():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry committed at HEAD for recovery channel case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry committed at HEAD",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 0, f"exit {code}: {err}"
    assert "RECOVERY-CHANNEL: git-history" in out, out
    shutil.rmtree(repo, ignore_errors=True)


def test_recovery_channel_record_mirror_only_uncommitted():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n")
    enc = base_encoded_in(repo)
    commit_all(repo, "base commit without the entry")
    # Append the entry to the working tree only, AFTER the commit, so HEAD
    # never contains it — recovery channel must fall back to mirror-only.
    write(pf, read_text(pf) + "\n- symptom: entry not yet committed for recovery channel case.\n")

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry not yet committed",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 0, f"exit {code}: {err}"
    assert "RECOVERY-CHANNEL: record-mirror-only" in out, out
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 10. Phase-4 non-collision: only remaining un-ledgered entries are selectable
# ---------------------------------------------------------------------------
def test_phase4_non_collision_remaining_entries_selectable():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n"
          "## Harvested ledger (compacted)\n\n"
          "- [2026-01-01] already distilled lesson one → encoded in path/a.md (evidence a)\n"
          "- [2026-01-02] already distilled lesson two → encoded in path/b.md (evidence b)\n\n"
          "- symptom: remaining entry alpha still awaiting distillation.\n"
          "- symptom: remaining entry beta still awaiting distillation.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: remaining entry alpha",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    assert "PARITY: entries 2->1, ledger 2->3" in out, out

    code2, out2, err2 = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: remaining entry beta",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code2 == 0, f"exit {code2}: {err2}"
    assert "PARITY: entries 1->0, ledger 3->4" in out2, out2
    content = read_text(pf)
    assert content.count(HEADING) == 1, content
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 11. Re-run after success -> exit 3 (idempotence-by-refusal)
# ---------------------------------------------------------------------------
def test_rerun_after_success_is_refused():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for idempotence re-run case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for idempotence",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 0, f"exit {code}: {err}"

    code2, out2, err2 = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for idempotence",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code2 == 3, f"exit {code2}: {out2}{err2}"
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 12. Summary semantics: explicit 161 chars -> exit 1; default derivation
#     from a >160-char first line -> stripped/collapsed/truncated to 160.
# ---------------------------------------------------------------------------
def test_explicit_summary_too_long_exit1():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for summary length case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for summary length",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--summary", "x" * 161,
    ])
    assert code == 1, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    shutil.rmtree(repo, ignore_errors=True)


def test_default_summary_derivation_truncated_160():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    long_tail = "this   has  irregular    internal   spacing and repeats " * 4
    first_line = "- symptom: " + long_tail
    write(pf, "# Pitfalls: staff-engineer\n\n" + first_line + "\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: this   has",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"

    stripped = first_line[len("- "):]
    collapsed = re.sub(r"\s+", " ", stripped).strip()
    expected_summary = collapsed[:160]
    assert len(expected_summary) == 160, len(expected_summary)

    content = read_text(pf)
    ledger_line = [l for l in content.splitlines() if l.startswith("- [2026-07-14]")][0]
    assert expected_summary in ledger_line, (expected_summary, ledger_line)
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 13. Atomicity mechanics: no leftover temp (incl. after a forced nonzero
#     exit that exercises the pre-rename trap); mode preserved; content ok.
# ---------------------------------------------------------------------------
def test_atomicity_no_leftover_temp_and_mode_preserved():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for atomicity mode-preservation case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    os.chmod(pf, 0o640)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for atomicity",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    mode = stat.S_IMODE(os.stat(pf).st_mode)
    assert mode == 0o640, oct(mode)
    assert not leftover_temps(os.path.dirname(pf)), "leftover temp file after success"
    assert HEADING in read_text(pf)


def test_atomicity_trap_cleans_temp_on_forced_failure():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf, "# Pitfalls: staff-engineer\n\n- symptom: entry for forced-failure trap case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)
    before = sha(pf)

    # Select succeeds (unique match), but evidence has no hit -> exit 6,
    # occurring AFTER the same-directory temp file has already been created.
    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for forced-failure",
        "--encoded-in", enc,
        "--evidence", "definitely absent evidence string xyz123",
    ])
    assert code == 6, f"exit {code}: {out}{err}"
    assert sha(pf) == before
    assert not leftover_temps(os.path.dirname(pf)), "trap did not clean up temp file"
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 13b. Seam normalization: both live seam shapes produce exactly one blank
#      at each §4.2a seam position post-insert, regardless of original count.
# ---------------------------------------------------------------------------
def test_seam_normalization_h1_shape_extra_blanks():
    repo = new_repo()
    pf = pitfalls_path(repo, "staff-engineer")
    write(pf,
          "# Pitfalls: staff-engineer\n\n\n"
          "- symptom: entry preceded by two blank lines after the H1.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry preceded by two blank",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    expected = (
        "# Pitfalls: staff-engineer\n\n"
        "## Harvested ledger (compacted)\n\n"
        "- [2026-07-14] symptom: entry preceded by two blank lines after the H1. "
        "→ encoded in src/user/claude-code/skills/team-doctrine/references/foo.md (the lesson now)\n"
    )
    assert content == expected, repr(content)
    shutil.rmtree(repo, ignore_errors=True)


def test_seam_normalization_no_h1_shape_extra_blanks():
    repo = new_repo()
    pf = pitfalls_path(repo, "distinguished-engineer")
    write(pf,
          "\n\n"
          "- **Symptom:** entry preceded by two leading blank lines with no H1.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "distinguished-engineer", "in-repo",
        "--entry", "- **Symptom:** entry preceded by two leading",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
        "--date", "2026-07-14",
    ])
    assert code == 0, f"exit {code}: {err}"
    content = read_text(pf)
    expected = (
        "## Harvested ledger (compacted)\n\n"
        "- [2026-07-14] **Symptom:** entry preceded by two leading blank lines with no H1. "
        "→ encoded in src/user/claude-code/skills/team-doctrine/references/foo.md (the lesson now)\n"
    )
    assert content == expected, repr(content)
    shutil.rmtree(repo, ignore_errors=True)


# ---------------------------------------------------------------------------
# 14. pitfalls_check.sh path resolution exercised transitively; one dedicated
#     case asserts the in-repo/centralized path split it prints.
# ---------------------------------------------------------------------------
def test_pitfalls_check_path_split():
    repo = new_repo()
    pf_in_repo = pitfalls_path(repo, "staff-engineer")
    write(pf_in_repo, "# Pitfalls: staff-engineer\n\n- symptom: entry for path-split case.\n")
    enc = base_encoded_in(repo)
    commit_all(repo)

    code, out, err = run_distill(repo, [
        "staff-engineer", "in-repo",
        "--entry", "- symptom: entry for path-split",
        "--encoded-in", enc,
        "--evidence", "the lesson now",
    ])
    assert code == 0, f"exit {code}: {err}"
    resolved = out.strip().splitlines()[-1]
    assert resolved == os.path.join(repo, ".claude", "agent-memory", "staff-engineer", "pitfalls.md"), resolved

    central = new_home_dir()
    pf_central = pitfalls_path(repo, "senior-engineer", home="centralized", home_dir=central)
    write(pf_central, "- old lesson for the path-split centralized case.\n")
    write(os.path.join(repo, "src/user/claude-code/scripts/path_split.md"), "central path split evidence\n")
    commit_all(repo)

    code2, out2, err2 = run_distill(repo, [
        "senior-engineer", "centralized",
        "--entry", "- old lesson for the path-split",
        "--encoded-in", "src/user/claude-code/scripts/path_split.md",
        "--evidence", "central path split",
    ], env_overrides={"HOME": central})
    assert code2 == 0, f"exit {code2}: {err2}"
    resolved2 = out2.strip().splitlines()[-1]
    assert resolved2 == os.path.join(central, ".claude", "agent-memory", "senior-engineer", "pitfalls.md"), resolved2
    shutil.rmtree(repo, ignore_errors=True)
    shutil.rmtree(central, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
