#!/usr/bin/env python3
"""Fixture-driven checks for changelog_normalize.py -- the Changelog Format
Normalization step (fix H1, strip H2 suffix, rename/delete H3 sections,
truncate to 20 lines, diff-guard against touching prior entries).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_changelog_normalize.py``.
Exit 0 = all asserts pass. Scoped entirely to fixtures/changelog_normalize/ so
it never touches the peer fixtures. Drives the real CLI via subprocess for
end-to-end checks, and imports the module directly to exercise the
diff-guard's failure path (mocked corruption -- the real pipeline never
produces one, so this is the only way to prove the guard actually fires).
"""
import importlib.util
import shutil
import subprocess
import sys
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "changelog_normalize.py"
FIXTURES = HERE / "fixtures" / "changelog_normalize"
MESSY_INPUT = FIXTURES / "messy_input.md"
MESSY_EXPECTED = FIXTURES / "messy_expected.md"
SINGLE_ENTRY = FIXTURES / "single_entry.md"
OVERSIZED_ENTRY = FIXTURES / "oversized_entry.md"
NO_H2 = FIXTURES / "no_h2.md"

spec = importlib.util.spec_from_file_location("changelog_normalize", SCRIPT)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def run(*args):
    proc = subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True)
    return proc.returncode, proc.stdout, proc.stderr


def test_dry_run_fixes_h1_h2_h3_and_deletes_extras():
    code, out, err = run(str(MESSY_INPUT), "--artifact-name", "evolve-agents", "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out == MESSY_EXPECTED.read_text(), out


def test_prior_entry_and_compacted_history_untouched():
    code, out, err = run(str(MESSY_INPUT), "--artifact-name", "evolve-agents", "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "## 2026-07-10" in out, out
    assert "Prior entry, should be untouched." in out, out
    assert "## Compacted history" in out, out
    assert "2026-06-01: earlier fossil record, untouched." in out, out


def test_oversized_entry_truncated_to_20_lines_prior_entry_intact():
    code, out, err = run(str(OVERSIZED_ENTRY), "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    idx = out.index("## 2026-07-10")
    entry_start = out.index("## 2026-07-13")
    topmost = out[entry_start:idx]
    assert len(topmost.splitlines()) <= 20, topmost
    assert "### Rename" not in topmost, topmost  # truncated away past line 20
    prior = out[idx:]
    assert "Prior entry, should be untouched even though the new one above is truncated." in prior, prior
    assert "### Rename" in prior, prior
    assert "No rename." in prior, prior


def test_single_entry_no_prior_region_normalizes_cleanly():
    code, out, err = run(str(SINGLE_ENTRY), "--artifact-name", "evolve-config", "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out.startswith("# Changelog: evolve-config\n"), out
    assert "## 2026-07-13\n" in out, out
    assert "(first ever entry)" not in out, out


def test_already_normalized_file_is_a_noop():
    code, out, err = run(str(MESSY_EXPECTED), "--artifact-name", "evolve-agents", "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    assert "already normalized" in out, out


def test_default_artifact_name_is_file_stem():
    code, out, err = run(str(SINGLE_ENTRY), "--dry-run")
    assert code == 0, f"exit {code}: {out}{err}"
    assert out.startswith("# Changelog: single_entry\n"), out


def test_missing_file_exits_two():
    code, out, err = run(str(FIXTURES / "does-not-exist.md"), "--dry-run")
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"


def test_malformed_no_h2_heading_exits_two():
    code, out, err = run(str(NO_H2), "--dry-run")
    assert code == 2, f"expected exit 2, got {code}: {out}{err}"
    assert "no '## YYYY-MM-DD' entry heading found" in err, err


def test_cli_writes_file_in_place_and_leaves_prior_entries_byte_identical():
    tmp = FIXTURES / "_write_target.md"
    shutil.copy(MESSY_INPUT, tmp)
    try:
        before_prior = MESSY_INPUT.read_text().split("## 2026-07-10", 1)[1]
        code, out, err = run(str(tmp), "--artifact-name", "evolve-agents")
        assert code == 0, f"exit {code}: {out}{err}"
        assert "normalized topmost entry" in out, out
        after_text = tmp.read_text()
        assert after_text == MESSY_EXPECTED.read_text(), after_text
        after_prior = after_text.split("## 2026-07-10", 1)[1]
        assert after_prior == before_prior, "prior entry region changed byte-for-byte"
    finally:
        tmp.unlink(missing_ok=True)


def test_diff_guard_blocks_a_corrupted_normalization_from_touching_prior_entries():
    """Prove the diff-guard actually fires: mock a normalization step to leak
    a spurious '## ' heading into the topmost entry (simulating a bug), which
    shifts where the prior-entry boundary is redetected in the new text --
    and confirm normalize_changelog refuses to return, raising DiffGuardError
    instead of silently producing output that would touch the prior entry."""
    original_text = MESSY_INPUT.read_text()
    real_truncate = mod.truncate_entry

    def corrupting_truncate(entry_text, max_lines):
        result = real_truncate(entry_text, max_lines)
        return result + "\n## 9999-99-99 INJECTED-BY-TEST\n"

    with mock.patch.object(mod, "truncate_entry", side_effect=corrupting_truncate):
        try:
            mod.normalize_changelog(original_text, "evolve-agents")
            raised = False
        except mod.DiffGuardError as exc:
            raised = True
            message = str(exc)

    assert raised, "expected DiffGuardError when a normalization step corrupts the topmost entry"
    assert "modify content below the topmost entry" in message, message
    assert "## 2026-07-10" in message or "9999-99-99" in message, message


def test_diff_guard_trip_surfaces_as_exit_3_through_the_cli():
    """Same corruption, driven through main() so the CLI's exit-code contract
    (3 = diff-guard tripped, distinct from 2 = malformed input) is verified too."""
    import contextlib
    import io

    real_truncate = mod.truncate_entry

    def corrupting_truncate(entry_text, max_lines):
        return real_truncate(entry_text, max_lines) + "\n## 9999-99-99 INJECTED-BY-TEST\n"

    tmp = FIXTURES / "_diffguard_target.md"
    shutil.copy(MESSY_INPUT, tmp)
    stderr = io.StringIO()
    try:
        with mock.patch.object(mod, "truncate_entry", side_effect=corrupting_truncate):
            with contextlib.redirect_stderr(stderr):
                code = mod.main([str(tmp), "--artifact-name", "evolve-agents"])
        assert code == 3, f"expected exit 3, got {code}"
        assert "diff-guard tripped" in stderr.getvalue(), stderr.getvalue()
        # The file on disk must be untouched -- the guard must block the write.
        assert tmp.read_text() == original_text_for_guard_cli(), "file was written despite diff-guard trip"
    finally:
        tmp.unlink(missing_ok=True)


def original_text_for_guard_cli():
    return MESSY_INPUT.read_text()


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
