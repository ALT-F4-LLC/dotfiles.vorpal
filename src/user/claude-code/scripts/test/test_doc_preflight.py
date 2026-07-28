#!/usr/bin/env python3
"""Fixture-driven checks for doc_preflight.sh -- the tri-state
exact_path_collision/same_slug_existing/near_dups contract and the
type-scoped field emission across tdd/adr/prd/ux-spec (DKT-167).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_doc_preflight.py``.
Exit 0 = all asserts pass. Drives the real script via subprocess against
disposable tmp git repos (never touches the real docs/tdd|docs/adr|docs/spec|
docs/ux trees).
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "doc_preflight.sh"

OUTPUT_DIRS = {"tdd": "docs/tdd", "adr": "docs/adr", "prd": "docs/spec", "ux-spec": "docs/ux"}


def make_repo():
    repo = Path(tempfile.mkdtemp(prefix="doc_preflight_"))
    subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
    return repo


def run(repo, *args):
    proc = subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True, cwd=str(repo))
    return proc.returncode, proc.stdout, proc.stderr


def parse(out):
    fields = {}
    for line in out.splitlines():
        if "=" in line:
            key, _, value = line.partition("=")
            fields[key] = value
    return fields


def test_skipped_sentinel_when_output_dir_absent():
    repo = make_repo()
    try:
        for doc_type in ("tdd", "adr", "prd", "ux-spec"):
            code, out, err = run(repo, doc_type, "a brand new topic")
            assert code == 0, f"{doc_type}: exit {code}: {out}{err}"
            fields = parse(out)
            dir_ = OUTPUT_DIRS[doc_type]
            if doc_type == "adr":
                assert fields["same_slug_existing"] == f"SKIPPED: {dir_} absent", fields
            else:
                assert fields["exact_path_collision"] == f"SKIPPED: {dir_} absent", fields
            if doc_type == "tdd":
                assert fields["near_dups"] == f"SKIPPED: {dir_} absent", fields
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_checked_and_none_when_dir_exists_no_hit():
    repo = make_repo()
    try:
        for doc_type in ("tdd", "adr", "prd", "ux-spec"):
            (repo / OUTPUT_DIRS[doc_type]).mkdir(parents=True)
            code, out, err = run(repo, doc_type, "a brand new topic")
            assert code == 0, f"{doc_type}: exit {code}: {out}{err}"
            fields = parse(out)
            if doc_type == "adr":
                assert fields["same_slug_existing"] == "", fields
            else:
                assert fields["exact_path_collision"] == "", fields
            if doc_type == "tdd":
                assert fields["near_dups"] == "", fields
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_exact_path_collision_found_for_tdd_prd_ux_spec():
    repo = make_repo()
    try:
        for doc_type in ("tdd", "prd", "ux-spec"):
            dir_ = repo / OUTPUT_DIRS[doc_type]
            dir_.mkdir(parents=True)
            existing = dir_ / "my-new-feature.md"
            existing.write_text("# existing\n")
            code, out, err = run(repo, doc_type, "my new feature")
            assert code == 0, f"{doc_type}: exit {code}: {out}{err}"
            fields = parse(out)
            assert fields["exact_path_collision"] == f"{OUTPUT_DIRS[doc_type]}/my-new-feature.md", fields
            shutil.rmtree(dir_)
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_same_slug_existing_found_for_adr_picks_lowest_via_sort():
    repo = make_repo()
    try:
        adr_dir = repo / "docs" / "adr"
        adr_dir.mkdir(parents=True)
        (adr_dir / "0003-my-decision.md").write_text("# c\n")
        (adr_dir / "0001-my-decision.md").write_text("# a\n")
        code, out, err = run(repo, "adr", "my decision")
        assert code == 0, f"exit {code}: {out}{err}"
        fields = parse(out)
        assert fields["same_slug_existing"] == "docs/adr/0001-my-decision.md", fields
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_near_dups_found_for_tdd_only():
    repo = make_repo()
    try:
        tdd_dir = repo / "docs" / "tdd"
        tdd_dir.mkdir(parents=True)
        near = tdd_dir / "a-sufficiently-long-topic-name-variant.md"
        near.write_text("# near dup\n")
        code, out, err = run(repo, "tdd", "a sufficiently long topic name")
        assert code == 0, f"exit {code}: {out}{err}"
        fields = parse(out)
        assert fields["near_dups"] == "docs/tdd/a-sufficiently-long-topic-name-variant.md", fields
        assert fields["exact_path_collision"] == "", fields
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_type_scoped_field_emission():
    repo = make_repo()
    try:
        for doc_type in ("tdd", "adr", "prd", "ux-spec"):
            code, out, err = run(repo, doc_type, "a topic for scoping")
            assert code == 0, f"{doc_type}: exit {code}: {out}{err}"
            fields = parse(out)
            assert fields.get("slug"), fields
            assert fields.get("today_date"), fields
            assert fields.get("project_name"), fields
            if doc_type == "tdd":
                assert "exact_path_collision" in fields, fields
                assert "near_dups" in fields, fields
                assert "same_slug_existing" not in fields, fields
            elif doc_type == "adr":
                assert "same_slug_existing" in fields, fields
                assert "exact_path_collision" not in fields, fields
                assert "near_dups" not in fields, fields
            else:
                assert "exact_path_collision" in fields, fields
                assert "same_slug_existing" not in fields, fields
                assert "near_dups" not in fields, fields
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_bad_type_usage_error():
    repo = make_repo()
    try:
        code, out, err = run(repo, "bogus-type", "some topic")
        assert code == 2, f"exit {code}: {out}{err}"
        assert "Usage: doc_preflight.sh" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_wrong_arg_count_usage_error():
    repo = make_repo()
    try:
        code, out, err = run(repo, "tdd")
        assert code == 2, f"exit {code}: {out}{err}"
        assert "Usage: doc_preflight.sh" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_slug_error_propagation_no_alphanumeric_survivors():
    repo = make_repo()
    try:
        code, out, err = run(repo, "tdd", "!!!")
        assert code == 1, f"exit {code}: {out}{err}"
        assert "Topic must contain at least one alphanumeric character" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_slug_error_propagation_empty_topic():
    repo = make_repo()
    try:
        code, out, err = run(repo, "tdd", "")
        assert code == 2, f"exit {code}: {out}{err}"
        assert "Usage: slug.sh" in err, err
    finally:
        shutil.rmtree(repo, ignore_errors=True)


def test_not_a_git_repo_error():
    non_repo = Path(tempfile.mkdtemp(prefix="doc_preflight_non_repo_"))
    try:
        code, out, err = run(non_repo, "tdd", "some topic")
        assert code == 1, f"exit {code}: {out}{err}"
        assert "not inside a git repository" in err, err
    finally:
        shutil.rmtree(non_repo, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
