#!/usr/bin/env python3
"""Regression fixtures for two coherence_xref.py false-signal gaps (DKT-139):

- Gap A: build_skill_refs() must exclude Claude-Code-bundled skill tokens
  (BUNDLED_SKILLS) from the emitted refs — they have no project skill
  directory by design and would otherwise look like dead/unregistered refs
  to a Phase 1 reviewer comparing skill_refs against registry.
- Gap C: build_rule_presence() must not count an R-token as present when its
  only occurrence is inside a "(...omitted...)" parenthetical.

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_coherence_xref.py``.
Exit 0 = all asserts pass. Imports coherence_xref.py directly and monkeypatches
agent_files() to point at throwaway fixture files — the two builders under
test only depend on agent_files() + read_text(), not on cwd/git-root.
"""
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import coherence_xref  # noqa: E402


def write_fixture(text):
    fd, path = tempfile.mkstemp(prefix="coherence_xref_fixture_", suffix=".md")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    return path


def test_bundled_skill_ref_excluded():
    path = write_fixture(
        "# fixture-agent\n\n"
        "Invoke via Skill(claude-in-chrome) for browser automation.\n"
        "Invoke via Skill(commit) for commits.\n"
        "Invoke via Skill(totally-fake-unregistered) for nonsense.\n"
    )
    orig = coherence_xref.agent_files
    coherence_xref.agent_files = lambda: [path]
    try:
        refs = coherence_xref.build_skill_refs()
    finally:
        coherence_xref.agent_files = orig
        os.remove(path)
    tokens = {r["token"] for r in refs}
    assert "claude-in-chrome" not in tokens, tokens
    # Bundled-only exclusion, not blanket filtering: a real project skill and
    # a genuinely unregistered one are still recorded as signals-to-verify.
    assert "commit" in tokens, tokens
    assert "totally-fake-unregistered" in tokens, tokens


def test_verify_and_code_review_bundled_refs_excluded():
    path = write_fixture(
        "# fixture-agent\n\n"
        "Run Skill(verify) then Skill(code-review) before merging.\n"
    )
    orig = coherence_xref.agent_files
    coherence_xref.agent_files = lambda: [path]
    try:
        refs = coherence_xref.build_skill_refs()
    finally:
        coherence_xref.agent_files = orig
        os.remove(path)
    tokens = {r["token"] for r in refs}
    assert "verify" not in tokens, tokens
    assert "code-review" not in tokens, tokens


def test_rule_omission_parenthetical_not_counted_present():
    # Mirrors project-manager.md's live phrasing: R4 + R5 only ever occur
    # inside the omission clause, so post-fix neither should surface.
    path = write_fixture(
        "# fixture-agent\n\n"
        "## Communication Discipline\n"
        "You apply **R1, R2, R3, R6, R7** (R4 + R5 omitted — fixture does not "
        "verify and is not a persistent advisor). One-line reminders:\n"
    )
    orig = coherence_xref.agent_files
    coherence_xref.agent_files = lambda: [path]
    try:
        out = coherence_xref.build_rule_presence()
    finally:
        coherence_xref.agent_files = orig
        os.remove(path)
    assert len(out) == 1, out
    present = out[0]["rules_present"]
    assert present == ["R1", "R2", "R3", "R6", "R7"], present
    assert "R4" not in present, present
    assert "R5" not in present, present


def test_rule_present_outside_omission_paren_still_detected():
    # Regression guard on the fix itself: a rule token that legitimately
    # appears outside any omission parenthetical must still be detected —
    # the strip must not over-match beyond the single non-nested paren group.
    path = write_fixture(
        "# fixture-agent\n\n"
        "## Communication Discipline\n"
        "You apply **R1, R2, R3, R4, R6, R7** (R5 omitted — fixture is not a "
        "persistent advisor). Some unrelated parenthetical (see R4 docs) too.\n"
    )
    orig = coherence_xref.agent_files
    coherence_xref.agent_files = lambda: [path]
    try:
        out = coherence_xref.build_rule_presence()
    finally:
        coherence_xref.agent_files = orig
        os.remove(path)
    present = out[0]["rules_present"]
    assert present == ["R1", "R2", "R3", "R4", "R6", "R7"], present
    assert "R5" not in present, present


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
